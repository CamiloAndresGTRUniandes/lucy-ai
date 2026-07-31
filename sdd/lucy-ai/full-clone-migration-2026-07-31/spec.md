# Spec: Full-Clone Export/Import for Server Migration

## Status: Draft

## Context
- **Problem:** When migrating Lucy from one server to another (e.g., Docker container → Ubuntu VM), there is no automated way to replicate the full OpenClaw configuration — agents, models, SDD profiles, workspace files, skills, and lucy-agent state. Users must manually copy files, guess at what's portable, and often lose their SDD agent/model setup in the process. The current `install.sh` only provides fresh template installs, not migration from an existing instance.
- **Business value:** Eliminates the manual, error-prone migration process. Users can export their entire Lucy/OpenClaw configuration from one server and restore it on another in a single command. This is critical for the author's own migration from Docker to a Linux VM, and serves as a reusable tool for any future server changes.
- **Constraints:** Must work on any Linux with bash 4+. Must not require Node.js or any runtime beyond what's already installed. Must be idempotent (safe to run multiple times). Must respect security by excluding auth/tokens/credentials by default, with an opt-in `--include-identity` flag for private full clones.
- **Assumptions:** The target server already has OpenClaw installed. The source server has a working lucy-agent installation at `~/.openclaw/lucy-agent/`. The user can transfer a tar.gz file between servers (scp, USB, URL, etc.). Re-authentication on the target server is expected unless `--include-identity` was used during export.

## Requirements

### Functional

| ID | Category | Requirement |
|----|----------|-------------|
| F1 | Exporter | The exporter script (`scripts/export-full-clone.sh`) MUST create a compressed tar.gz bundle from the current `~/.openclaw` installation. |
| F2 | Exporter | The exporter MUST exclude auth tokens, credentials, device identity, logs, delivery queues, transient runtime state, and media files by default. |
| F3 | Exporter | The exporter MUST support a `--include-identity` flag that additionally includes `~/.openclaw/identity/`, `~/.openclaw/credentials/`, auth profiles, and `.env` files for a private full clone. |
| F3b | Exporter | The exporter MUST support a `--exclude-memories` flag that excludes all session memory data: `~/.openclaw/workspace/memory/`, `~/.openclaw/workspace/MEMORY.md`, and `~/.openclaw/memory/`. This flag is compatible with `--include-identity` (both can be used together). |
| F4 | Exporter | The exporter MUST include: `openclaw.json`, entire `lucy-agent/` directory, and entire `workspace/` directory (excluding .env and secrets). When `--exclude-memories` is used, `workspace/memory/` and `workspace/MEMORY.md` are also excluded from the workspace copy. |
| F5 | Exporter | The exporter MUST print a summary of what was included/excluded and the output file path. When `--exclude-memories` is used, the summary MUST note that session memory data was excluded. When `--include-identity` is used, the summary MUST include the security warning. |
| F6 | Installer | `install.sh` MUST support a new `--full-clone <path-or-url>` flag that restores a previously exported bundle. |
| F7 | Installer | The `--full-clone` flag MUST accept both a local file path and an HTTP/HTTPS URL. |
| F8 | Installer | Before restoring, `--full-clone` MUST create a timestamped backup of the existing `~/.openclaw` directory. |
| F9 | Installer | After restoring, `--full-clone` MUST run `openclaw config validate` and report results. |
| F10 | Installer | After restoring, `--full-clone` MUST run `openclaw models list` to verify model availability. |
| F11 | Installer | After restoring, `--full-clone` MUST remind the user to re-authenticate providers and channels (unless the bundle was created with `--include-identity`). |
| F12 | Installer | `--full-clone` MUST be mutually exclusive with `--clone`, `--template`, and `--skip-workspace` flags. |
| F13 | Safety | The exporter MUST never include raw secrets or API keys in the bundle metadata or logs. |

### Non-Functional

| ID | Category | Requirement |
|----|----------|-------------|
| NF1 | Security | The default export MUST exclude all authentication material (OAuth tokens, API keys, credentials, device identity). Only `--include-identity` opts in. |
| NF2 | Portability | The exporter and installer MUST run on any Linux with bash 4+ and standard tools (tar, gzip, curl). No external dependencies beyond what OpenClaw already requires. |
| NF3 | Idempotency | `--full-clone` MUST be safe to run multiple times — each run creates a fresh backup and restores from the bundle. |
| NF4 | Observability | Both scripts MUST log each step clearly (what's being exported/restored, warnings, errors) using the existing `log_info`/`log_ok`/`log_warn`/`log_fail` conventions from `scripts/common.sh`. |
| NF5 | Shell Standards | Both scripts MUST follow the project shell standards: `#!/usr/bin/env bash`, `set -euo pipefail`, snake_case functions, UPPERCASE constants. |

## User Scenarios

### Scenario 1: Safe export for server migration (default, no identity)

**Given** Camilo has a fully configured Lucy instance in his Docker container with SDD agent profiles, workspace files, skills, and openclaw.json
**When** he runs `bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh`
**Then** a tar.gz file is created containing `openclaw.json`, `lucy-agent/`, and `workspace/` — but with NO auth tokens, credentials, or device identity. The script prints the output file path and a summary of what was included/excluded.

### Scenario 2: Private full clone with identity

**Given** Camilo wants to clone EVERYTHING to his private VM, including auth tokens so he doesn't need to re-authenticate
**When** he runs `bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --include-identity`
**Then** the tar.gz file additionally includes `identity/`, `credentials/`, `.env` files, and auth profiles. The script prints a clear warning that the bundle contains sensitive authentication material.

### Scenario 3: Export config only, no memories, no identity

**Given** Camilo wants to clone his full configuration (agents, models, workspace structure) to a new server but does NOT want past session memories, personal conversation history, or auth tokens
**When** he runs `bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --exclude-memories`
**Then** the tar.gz file contains `openclaw.json`, `lucy-agent/`, and `workspace/` but WITHOUT `workspace/memory/`, `workspace/MEMORY.md`, `memory/`, and WITHOUT auth/identity. The summary shows that session memories were excluded.

### Scenario 4: Private full clone with identity, but no memories

**Given** Camilo wants auth + config on a private VM but doesn't need old conversation history
**When** he runs `bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --include-identity --exclude-memories`
**Then** the bundle includes identity, credentials, `.env` files, and auth, but excludes all session memory data. Both flags work together.

### Scenario 5: Restore full clone on new server

**Given** Camilo has copied the `lucy-full-clone-*.tar.gz` bundle to his new Ubuntu VM, and OpenClaw is already installed there
**When** he runs `curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --full-clone ./lucy-full-clone-20260731-150000.tar.gz`
**Then** the installer backs up the existing `~/.openclaw`, extracts the bundle, validates the config, lists available models, and reminds him to re-auth providers. The gateway is restarted if running.

### Scenario 6: Restore from URL

**Given** Camilo has uploaded the bundle to a private URL
**When** he runs `bash install.sh --full-clone https://private.example.com/lucy-full-clone.tar.gz`
**Then** the installer downloads the bundle first, then proceeds with the same restore flow as Scenario 5.

### Scenario 7: Idempotent re-run

**Given** Camilo has already restored a full clone once and wants to re-apply it (e.g., after testing something)
**When** he runs `bash install.sh --full-clone ./lucy-full-clone.tar.gz` again
**Then** a new timestamped backup is created and the bundle is restored again. No errors from duplicate files.

## Out of Scope

- ❌ Two-way sync between servers (this is a one-time export → import)
- ❌ Incremental/delta exports (always a full snapshot)
- ❌ Automatic provider re-authentication on the target server
- ❌ Migration of OpenClaw binary/installation itself (assumes OpenClaw already installed on target)
- ❌ Migration of project repos (`/workspace/repos/`) — those live outside `~/.openclaw`
- ❌ Migration of Engram database (in `~/.engram/`, outside the bundle scope)
- ❌ Encryption of the export bundle (user is responsible for secure transfer)
- ❌ GUI or TUI for the export/import process

## Acceptance Criteria

- [ ] **AC1:** Running `bash scripts/export-full-clone.sh` from the lucy-agent directory creates a `lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz` file.
- [ ] **AC2:** The default export bundle does NOT contain any files from `identity/`, `credentials/`, or files matching `.env`, `*token*`, `*secret*`, `*api_key*`.
- [ ] **AC3:** Running with `--include-identity` DOES include `identity/device.json`, `identity/device-auth.json`, `credentials/` directory, and `.env` files that would otherwise be excluded.
- [ ] **AC4:** `--include-identity` prints a visible warning about sensitive content being included in the bundle.
- [ ] **AC5:** Running `bash install.sh --full-clone <bundle.tar.gz>` on a fresh system restores `openclaw.json`, `lucy-agent/`, and `workspace/` to `~/.openclaw/`.
- [ ] **AC6:** `--full-clone` creates a backup at `~/.openclaw.backup.YYYYMMDD-HHMMSS/` before restoring.
- [ ] **AC7:** `--full-clone` runs `openclaw config validate` after restore and prints the result.
- [ ] **AC8:** `--full-clone` runs `openclaw models list` after restore and prints the result.
- [ ] **AC9:** `--full-clone` prints a reminder to re-auth providers and channels at the end of the restore.
- [ ] **AC10:** `--full-clone` accepts a URL and downloads the bundle before restoring.
- [ ] **AC11:** `--full-clone` is rejected (with a clear error) if combined with `--clone`, `--template`, or `--skip-workspace`.
- [ ] **AC12:** Running `--full-clone` twice on the same target produces two separate backups and restores successfully both times.
- [ ] **AC13:** `bash -n` (syntax check) passes on both `scripts/export-full-clone.sh` and the modified `install.sh`.
- [ ] **AC14:** `--include-identity` bundle, when restored with `--full-clone`, allows the gateway to start without re-authentication (auth tokens preserved).
- [ ] **AC15:** Running `bash scripts/export-full-clone.sh --exclude-memories` creates a bundle that does NOT contain `workspace/memory/`, `workspace/MEMORY.md`, or `memory/`.
- [ ] **AC16:** `--exclude-memories` can be combined with `--include-identity` — identity/auth are included but memory data is excluded.
- [ ] **AC17:** The export summary when using `--exclude-memories` explicitly states that session memory data was excluded from the bundle.
