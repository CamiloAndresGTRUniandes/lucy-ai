# Changelog

All notable changes to lucy-agent are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-05-21

### Added

- **Agnostic workspace templates** — AGENTS.md and TOOLS.md are now project-agnostic with content boundary enforcement. No project-specific standards, architecture patterns, or naming conventions leak into global templates.
- **MEMORY.md template** — sanitized long-term memory template with privacy notice and empty sections (Identity, Stable Preferences, Key Decisions, Projects, Lessons Learned, Do Not Forget).
- **Content boundary enforcement** — `scripts/check-content-boundaries.sh` (reusable validator with `--staged` and `--worktree` modes) and `scripts/install-pre-commit-hook.sh` (materializes `.git/hooks/pre-commit` wrapper). The pre-commit hook blocks commits that introduce project-specific content (ZENTICALAB, excel-pipeline, project paths, etc.) into locked files (`workspace/AGENTS.md`, `workspace/TOOLS.md`).
- **9 fixed SDD agent profiles** — `config/agent-fragment.json5` now includes `agents.defaults` (primary model, thinking level, bootstrap limits, timeout, skills allowlist) and `agents.list[]` with profiles: `main`, `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`. Each profile carries its own model, fallbacks, thinking, and timeout.
- **Project standards template** — `sdd/templates/standards.md.in` with placeholders for project identity, architecture, file structure, commit conventions, git workflow, and secrets management.
- **Contributor workflow** — `install.sh --contributor` installs the pre-commit hook. `install.sh` preflight validation checks AGENTS/TOOLS/MEMORY templates before seeding.
- **Expanded verify.sh** — new checks for agnostic content, all 9 agent profiles, bootstrap limits, Engram MCP args, content boundary violations, SDD docs sync, and README/version consistency.

### Changed

- **AGENTS.md rewritten** — NON-NEGOTIABLE RULES, Content Boundaries section (AGENTS.md + TOOLS.md locked), Phase Gate Protocol, agentId-based spawning (no sentinels `<!-- SDD_TABLE_* -->`). All spawn examples use `agentId` instead of manual `model`.
- **TOOLS.md sanitized** — CONTENT LOCK section, no ZENTICALAB project standards block, no hardcoded project paths or identities. Email/auth section uses generic wording.
- **install.sh v1.7.0** — sentinel rewriting removed (`tui_generate_sdd_table`, `apply_sdd_table_to_agents_file`), TUI simplified (no per-phase model picker), `--clone` uses `main` branch (deprecation notice), `--contributor` flag added, preflight template validation.
- **SDD orchestrator docs** — `orchestrator-flow.md` uses `agentId` everywhere, added Project Standards Loading as mandatory pre-flight step, added missing agent profile and missing standards error handling. `task-string-format.md` replaces `### Model: {model}` with `### Agent Profile` section.
- **README.md** — new sections: Agnostic Configuration, Why Config Lives in openclaw.json, Content Boundary Enforcement, Contributor Setup. Version badge updated to v1.7.0. TUI model customization claims removed. Repository structure updated with all new files.
- **SDD docs synced** — `workspace/sdd/` now mirrors root `sdd/` for all shipped docs and templates (excluding active cycle artifacts).

### Removed

- **AGENTS.md SDD_TABLE sentinels** — installer no longer generates SDD model tables into AGENTS.md. Runtime config lives in `config/agent-fragment.json5`.
- **TUI phase model customization** — per-phase model picker screens removed. Fixed profiles in config fragment are the single source of truth.
- **ZENTICALAB-specific content** — all project-specific standards, paths, repo names, and identities removed from AGENTS.md and TOOLS.md templates.
- **lucy-config branch references** — README and installer now use `clone` branch exclusively. `--clone` flag accepted for compatibility but uses `main` internally.

## [1.6.3] - 2026-05-05

### Added

- **Post-install suggestions** — installer now suggests `openclaw gateway restart` and `/new` (for active sessions) after successful installation.

### Fixed

- **Pipe stdin** — interactive prompts now work in `curl | bash` mode by redirecting stdin to `/dev/tty`. Fixes "Invalid choice ''. Aborting." when user can't type responses.

## [1.6.2] - 2026-05-05

### Fixed

- **Engram download URL corruption** — `log_info` output in `resolve_engram_version()` was captured by command substitution, corrupting the version string and producing malformed download URLs. Fixed by redirecting `log_info` to stderr.
- **tmpdir trap variable scope** — `trap ... EXIT` in `step_install_engram()` referenced a `local` variable that went out of scope, causing `tmpdir: unbound variable` on script abort. Fixed by using `trap ... RETURN`.

## [1.6.1] - 2026-05-05

### Fixed

- **Piped execution (curl|bash)** — install.sh now detects piped invocation and downloads itself + common.sh to a temp directory before re-executing. Fixes `BASH_SOURCE[0]: unbound variable` in Docker containers.
- **Non-repo execution** — running `bash /tmp/install.sh --clone` now works by downloading common.sh from the repo if missing from the script's directory.
- **Repo URL fix** — all GitHub URLs changed from `lucy-agent` (404) to `lucy-ai` (correct repo name).

## [1.6.0] - 2026-05-05

### Added

- **7 new technical skills** — 1,598 lines of previously invisible skill content now discoverable:
  - `dotnet10-csharp14` — .NET 10 + C# 14 best practices (field keyword, params Span)
  - `zenticalab-security` — OWASP Top 10 2025 security guidance (748 lines)
  - `zenticalab-pr-review` — PR review checklist for .NET + Angular
  - `angular-core` — Standalone components, signals, inject, zoneless
  - `angular-architecture` — Scope Rule, project structure, naming
  - `angular-forms` — Signal Forms + Reactive Forms
  - `angular-performance` — NgOptimizedImage, @defer, SSR
- **SDD Orchestrator docs** — `sdd/orchestrator-flow.md`, `sdd/task-string-format.md`, 6 templates, validation rules
- **Technical Skills to Load** — per-phase skill mapping ensures sub-agents load relevant skills

### Fixed

- YAML frontmatter added to `dotnet10-csharp14` and `zenticalab-security` (previously invisible)
- Angular skills flattened from subdirectories to discoverable top-level paths
- 8 Copilot review comments addressed (security, consistency, docs)

## [1.5.0] - 2026-05-04

### Added

- **Installer TUI wizard** — dialog-based welcome, install mode, component checklist, and confirmation screens
- **SDD phase configuration wizard** — 8-phase model/provider defaults with `--accept-defaults` and `--no-tui` support
- **GitHub Actions CI pipeline** — shellcheck, bash syntax, shfmt, verify, and installer smoke tests on push/PR
- **Model config verification** — verify.sh now checks thinking level, Engram MCP, and stale minimax removal

### Changed

- **Config sync sources** — repo workspace docs now mirror the live workspace canonical files
- **Installer defaults** — v1.5.0 seeds the multi-provider SDD matrix used in the live workspace
- **Workspace AGENTS.md seeding** — SDD model table is now generated at install time from selected defaults/customizations

### Fixed

- **SPEC.md staleness** — repo spec now documents the v1.5.0 feature set
- **agent-fragment minimax reference** — default primary model now points to DeepSeek Flash with updated fallbacks

## [1.4.0] - 2026-05-03

### Added

- **Engram technical memory system integration** — install.sh Step 2 installs Engram binary to ~/.local/bin
- **Engram update check** in update.sh
- **Engram verification** — verify.sh validates binary+DB
- **MCP server config** — agent-fragment.json5 includes Engram as an MCP server
- **AGENTS.md Engram protocol** — structured technical memory for all agents and sub-agents
- **SDD skill v1.1** — Engram Memory Protocol for all delegated SDD phases

## [1.3.0] - 2026-05-01

### Added

- **SDD Orchestrator** — orchestrator-flow.md, task-string-format.md, validation-rules.md, and 6 phase templates (spec, design, tasks, apply, verify, state)
- **SDD Model Configuration** in AGENTS.md — 8-phase model/thinking table with escalation rules
- **SDD Orchestrator section** in AGENTS.md — delegation rules, doc references, constraints
- **12 new verify.sh checks** — sdd/ directory, templates, and AGENTS.md orchestrator reference

### Changed

- **install.sh** — extended `step_seed_workspace()` to copy `sdd/` directory recursively with sha256 conflict detection
- **SPEC.md** — updated to v1.3.0 SDD Orchestrator Integration
- **CURRENT_VERSION** — bumped to 1.3.0

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
