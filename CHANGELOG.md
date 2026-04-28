# Changelog

All notable changes to lucy-agent are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
