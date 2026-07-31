# Design: Full-Clone Export/Import for Server Migration

## Status: Draft

## Architecture Decisions

| Decision | Choice | Rationale | Alternative Rejected |
|----------|--------|-----------|---------------------|
| Exporter location | `scripts/export-full-clone.sh` — standalone script | Exporter runs on the SOURCE machine, not during install. Keeping it separate from `install.sh` avoids bloating the installer with code that never executes on the target. | Embed exporter logic inside `install.sh` — would make `install.sh` too large and couples source-side logic with target-side logic. |
| Installer integration | New `--full-clone <path>` flag + new `step_restore_full_clone()` function in `install.sh` | Follows existing pattern: each mode/component is a `step_*()` function with a flag guard. Minimal disruption to existing flow. | Separate `restore.sh` script — fragments the UX; user would need two different entry points. |
| Bundle format | `tar.gz` with naming `lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz` | tar.gz is universally available on Linux, preserves permissions, and is compressible. Timestamp in filename prevents collisions and makes bundles sortable. | zip — less reliable with Unix permissions. Plain tar — no compression. |
| Bundle contents (default) | `openclaw.json` + `lucy-agent/` + `workspace/` MINUS known exclusions | Explicit allowlist of what to include, with a denylist of patterns to strip. Safer than a generic "copy everything except secrets" approach which could miss new secret-like files. | Recursive copy with exclusion patterns only — harder to audit, easy to accidentally include new sensitive files. |
| Exclusion mechanism | Explicit `--exclude` tar patterns per mode, built from a list of known paths | tar `--exclude` is the standard, reliable way. Building the list programmatically lets us compose flags (`--include-identity` adds patterns, `--exclude-memories` adds more). | `rsync` with filter rules — not guaranteed available on minimal Linux installs. |
| Identity inclusion | `--include-identity` flag on exporter inverts exclusion of `identity/`, `credentials/`, and `.env` files | Keeps the default safe (no secrets) while allowing opt-in for private clones. Flag is explicit and visible. | Separate "private" export mode — less composable with `--exclude-memories`. |
| Memory exclusion | `--exclude-memories` flag adds `workspace/memory/`, `workspace/MEMORY.md`, `memory/` to exclusion list | Memories are configuration-adjacent but not configuration. Users frequently want a clean config without old conversation history. | Include everything, let user manually delete — defeats the purpose of automation. |
| Backup strategy | `mv ~/.openclaw ~/.openclaw.backup.YYYYMMDD-HHMMSS/` before restore | Atomic move ensures no partial state. Timestamped backups allow multiple restores without losing previous state. | `cp -r` backup — slower, could fail mid-copy leaving incomplete backup. |
| Mutual exclusion | `--full-clone` rejects `--clone`, `--template`, `--skip-workspace` at parse time | These modes serve fundamentally different purposes (fresh template vs restore from bundle). Combining them would produce undefined behavior. | Silently ignore conflicting flags — dangerous, user wouldn't know their intent was ignored. |
| Version | New release `v1.9.0` | Full-clone is a substantial new feature (new script + new installer mode + multiple flags). Deserves its own semver minor bump. Separate from v1.8.0's live-workspace-sync scope. | Bundle into v1.8.0 — muddies the release scope and makes rollback harder. |
| RELEASE_NOTES.md | Overwrite entire file with v1.9.0 content (release notes are per-release, not cumulative) | RELEASE_NOTES.md describes the current release for GitHub Releases. It's replaced on each new release, not appended. | Append to existing — would produce confusing multi-version notes. |

## Data Model

### Exporter Flags Composition

```
FLAG_INCLUDE_IDENTITY=false    # default: exclude auth/identity/credentials/.env
FLAG_EXCLUDE_MEMORIES=false    # default: include memories
```

### Inclusion/Exclusion Matrix

| Mode | `openclaw.json` | `lucy-agent/` | `workspace/` | `identity/` | `credentials/` | `.env` | `memory/` | `MEMORY.md` |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Default | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `--include-identity` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `--exclude-memories` | ✅ | ✅ | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ |
| Both flags | ✅ | ✅ | ✅* | ✅ | ✅ | ✅ | ❌ | ❌ |

*workspace/ included but with memory/ and MEMORY.md stripped

### Exporter Output

```
lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz
```

### Bundle Internal Structure

```
lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz
└── .openclaw/
    ├── openclaw.json
    ├── lucy-agent/
    │   ├── .version
    │   ├── config/
    │   ├── skills/
    │   ├── scripts/
    │   ├── workspace/
    │   └── ...
    ├── workspace/
    │   ├── AGENTS.md
    │   ├── TOOLS.md
    │   ├── SOUL.md
    │   ├── IDENTITY.md
    │   ├── USER.md
    │   ├── HEARTBEAT.md
    │   ├── MEMORY.md          ← excluded with --exclude-memories
    │   ├── memory/            ← excluded with --exclude-memories
    │   ├── skills/
    │   ├── sdd/
    │   └── ...
    ├── identity/              ← ONLY with --include-identity
    ├── credentials/           ← ONLY with --include-identity
    ├── .env                   ← ONLY with --include-identity
    └── memory/                ← excluded with --exclude-memories
```

### Exporter Exclusions (Always)

These are NEVER included, even with `--include-identity`:

| Path pattern | Reason |
|-------------|--------|
| `logs/` | Transient runtime logs |
| `delivery-queue/` | Failed message queue |
| `tasks/` | Task run state (sqlite) |
| `subagents/` | Sub-agent run metadata |
| `media/` | Generated images/audio |
| `plugin-runtime-deps/` | Auto-installed deps, version-specific |
| `locks/` | Runtime lock files |
| `flows/` | Flow registry (sqlite) |
| `telegram/update-offset-*` | Channel offset state |
| `*.clobbered.*` | OpenClaw auto-backups |
| `*.bak` `*.bak.*` | Manual backup files |
| `*.backup-*` | Dated backup files |
| `openclaw.json.last-good` | Auto-recovery backup |

## Installer Flow (--full-clone)

### Parse Phase

```
parse_flags():
  --full-clone <path> → FULL_CLONE_SOURCE=$2
  if FULL_CLONE_SOURCE is set AND (--clone, --template, or --skip-workspace):
    log_fail "--full-clone cannot be combined with --clone, --template, or --skip-workspace"
    exit 1
```

### Step Function: `step_restore_full_clone()`

```text
1. VALIDATE source exists (local file) or is reachable (URL)
2. DOWNLOAD if URL (curl to temp file)
3. EXTRACT to temp dir, verify structure has .openclaw/ prefix
4. BACKUP existing ~/.openclaw → ~/.openclaw.backup.YYYYMMDD-HHMMSS/ (mv)
5. RESTORE: cp -r from temp/.openclaw/* → ~/.openclaw/
6. RE-LINK config fragment: ensure $include directive exists in openclaw.json
7. VALIDATE config: run openclaw config validate
8. LIST models: run openclaw models list
9. REMIND: print re-auth reminder (always, since the user should verify)
10. RESTART gateway if running (openclaw gateway restart)
```

### Full Install Sequence with --full-clone

```text
parse_flags()
check_prerequisites()        # OpenClaw CLI exists
step_install_engram()        # Normal (may be skipped)
step_restore_full_clone()    # NEW — replaces step_clone_repo, step_seed_workspace, etc.
step_install_bundled_skills()# Normal (restored bundle may have outdated skills, refresh from repo)
step_install_clawhub_skills()# Normal
step_link_config()           # Normal (ensure $include is present)
step_verify()                # Normal
```

## Security

- **Auth/Authz:** The exporter never sends data over the network. The bundle is a local file; transfer is the user's responsibility. The installer downloads from URL only if the user provides one.
- **Data handling:** Default mode excludes all auth material. `--include-identity` prints a visible warning. No raw secrets are ever logged or printed.
- **Input validation:** Bundle path is validated for existence (local) or reachability (URL). Tar extraction uses `--no-same-owner` to prevent privilege escalation. Bundle structure is verified before restore.
- **Audit:** Both scripts log each step. The exporter prints a summary of what was included/excluded. The installer logs backup path and validation results.

## Error Handling

| Failure | Recovery | User sees |
|---------|----------|-----------|
| Bundle file not found | Exit with error before any changes | `ERROR: Bundle not found: <path>` |
| URL unreachable | Exit after curl timeout | `ERROR: Could not download bundle from <url>` |
| Bundle structure invalid | Exit, temp dir cleaned up | `ERROR: Bundle does not contain expected .openclaw/ structure` |
| Backup fails (disk full) | Abort restore, original state preserved | `ERROR: Could not back up existing ~/.openclaw. Check disk space.` |
| Restore fails mid-copy | Abort, temp dir cleaned up, backup remains | `ERROR: Restore failed. Your original config is at ~/.openclaw.backup.*` |
| config validate fails | Continue anyway, warn user | `WARNING: openclaw config validate reported errors. Review before starting gateway.` |
| models list fails | Continue anyway, warn user | `WARNING: No models available. Check provider authentication.` |
| Gateway restart fails | Warn user, manual restart needed | `WARNING: Gateway restart failed. Run: openclaw gateway restart` |

## Observability

### Exporter Logging

```
[INFO] Exporting full clone...
[INFO] Mode: default (no identity, with memories)
[INFO] Including: openclaw.json, lucy-agent/, workspace/
[INFO] Excluding: identity/, credentials/, .env, logs/, media/, ...
[WARN] --include-identity: bundle WILL contain authentication material
[INFO] --exclude-memories: session memory data excluded
[OK] Bundle created: lucy-full-clone-20260731-150000.tar.gz (4.2 MB)
```

### Installer Logging

```
[INFO] Full-clone mode: restoring from ./lucy-full-clone-20260731-150000.tar.gz
[INFO] Backed up existing ~/.openclaw to ~/.openclaw.backup.20260731-150500/
[INFO] Restoring files...
[OK] Restore complete
[OK] Config validation: passed
[INFO] Available models: openai-codex/gpt-5.5, deepseek/deepseek-v4-pro, ...
[WARN] Remember to re-authenticate your providers and channels
[INFO] Gateway restarted
```

## Migration Plan

- **Breaking changes:** None. `--full-clone` is a new flag. All existing flags continue to work.
- **Rollback:** `mv ~/.openclaw.backup.YYYYMMDD-HHMMSS/ ~/.openclaw/` restores previous state.
- **Deployment:**
  1. Create feature branch `feat/v1.9.0-full-clone-migration`
  2. Add `scripts/export-full-clone.sh`
  3. Modify `install.sh` (parse_flags + step_restore_full_clone)
  4. Update `CHANGELOG.md` with v1.9.0 entry
  5. Update `.version` to `1.9.0`
  6. Write `RELEASE_NOTES.md` for v1.9.0
  7. Bump `CURRENT_VERSION` in both `install.sh` and `update.sh`
  8. PR → review → merge → tag `v1.9.0`

## Decisions approved by Camilo

| Decision | Value | Rationale |
|----------|-------|-----------|
| Option B (exporter + installer) | Approved | Exporter for source, `--full-clone` flag for target |
| `--include-identity` on exporter | Approved | Opt-in for private clones with auth/tokens |
| `--include-identity` includes `.env` | Approved | Private clone = everything, including env files |
| `--exclude-memories` on exporter | Approved | Config without conversation history |
| New release v1.9.0 | Approved | Separate from v1.8.0 scope |
| No identity option on installer | Approved | Identity decision is made at export time, not import time |
