# Changelog

All notable changes to lucy-agent are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-04-28

### Added

- **`--tag` / `--version` flags** — Install or pin to specific releases on both `install.sh` and `update.sh`
- **`--quiet` / `-q` flag** — Suppress informational output, show only warnings and errors (CI-friendly)
- **`--force-stash` flag** — Stash local changes before pulling, then restore automatically
- **`--version` on install.sh and update.sh** — Show installed version and latest remote tag
- **`uninstall.sh`** — Clean removal script: removes repo, bundled skills, and workspace seeds with confirmation
- **`scripts/common.sh`** — Shared helpers extracted from install.sh/update.sh for DRY compliance
- **`verify.sh` failure report** — Failed checks are now listed by name at the end of the summary
- **Fork sync documentation** — README now includes `git remote add upstream` instructions

### Fixed

- **`update.sh` now respects install branch** — After `--clone` install, `update.sh` pulls from `lucy-config`, not `main` (tracked via `.version` file)
- **`install.sh` local changes handling** — Prompts or stashes before `git pull` instead of failing on uncommitted changes
- **AGENTS.md no longer references non-existent `angular/*` skills**

### Changed

- **Shared helpers via `scripts/common.sh`** — Color/log/sha256 helpers now sourced from one file (DRY)
- **Git clone uses `--progress`** — Visible progress on slow connections

### Security

- Version tracking via `.version` file in `${LUCY_DIR}/`

## [1.1.0] - 2026-04-28

### Added

- **`--clone` flag** — Replicate Lucy's exact configuration from `lucy-config` branch
- **`--template` flag** — Explicit generic templates mode
- **Interactive install prompt** — Choose between clone or template when stdin is a TTY
- **`is_excluded()` helper** — Security-sensitive files never copied in any mode

### Changed

- **`install.sh` is now mode-aware** — Detects TTY vs pipe to choose interactive or silent mode
- **Non-interactive install defaults to `--template`** — Safe default for CI/CD
- **Help text expanded** — Full flag documentation with `--help`

### Security

- Sensitive files always excluded: `openclaw.json`, `.env`, `credentials/`, `secrets/`, `*.pem`, `*.key`, `*.crt`, `auth-profiles.json`

## [1.0.0] - 2026-04-28

### Added

- **Generic `pr-review` skill** — Project-agnostic PR review skill applicable to any codebase
- **`sdd` skill** — Spec-Driven Development 8-phase workflow
- **`github-pr` skill** — High-quality PR creation with conventional commits
- **`csharp-dotnet` skill** — C#/.NET Clean Architecture patterns
- **`tailwind-4` skill** — Tailwind CSS 4 patterns and best practices
- **`typescript` skill** — TypeScript strict patterns
- **`skill-creator` skill** — Guide for creating new agent skills
- **`verify.sh`** — Post-install verification script (25/25 checks)
- **`install.sh`** — One-command installer with idempotent re-run behavior
- **`update.sh`** — In-place updater with version pinning support
- **Workspace seed** — `SOUL.md`, `IDENTITY.md`, `AGENTS.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`
- **Config fragment** — `agent-fragment.json5` for `openclaw.json` `$include`

### Changed

- **Project is now generic** — All project-specific content removed
- **USER.md is a template** — No personal data in the repo; users fill their own info post-install
- **README with badges** — License and version badges added

### Removed

- **`[project]-pr-review` skill** — Project-specific skills removed; use a generic pr-review skill instead

### Security

- No secrets, API keys, or credentials ever committed
- Install script is auditable via `curl` before execution
- `.gitignore` excludes all sensitive files (`openclaw.json`, `.env`, `credentials/`, etc.)

## [0.0.0] - 2026-04-27

### Added

- Initial commit (LICENSE only)
