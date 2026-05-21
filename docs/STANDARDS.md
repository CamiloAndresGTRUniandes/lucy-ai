# lucy-ai — Project Standards

> Lucy-Agent Installer — shell script, idempotent, no-build, portable
> 
> **Language**: English (code, comments, docs)
> **Repo**: https://github.com/CamiloAndresGTRUniandes/lucy-ai

---

## Project Identity

- **Type**: Bash-based installer + workspace/config templates
- **Branches**: `main` (fresh installs), `clone` (fork/copy existing config)
- **Repo**: `CamiloAndresGTRUniandes/lucy-ai`
- **GitHub user**: `lucygtr` | **Reviewer**: `camiloandresgtruniandes`

---

## Architecture Principles

### Installer Design

- **Single shell script** (`install.sh`) — no compilation, no Node.js dependency for install
- **Idempotent** — safe to run multiple times, `--force` flag for overwrites
- **Portable** — runs on any Linux/macOS with bash 4+
- **Auditable** — plain shell, no binaries, user can read every line
- **No sudo required** — all operations in user space

### Workspace Templates

- `workspace/` — template files copied to `~/.openclaw/workspace/` on install
- All workspace files are **project-agnostic** — no app-specific standards
- Project standards live in each project's `docs/STANDARDS.md` (not in Lucy's workspace)
- Skills bundled for offline resilience (fallback when ClawHub unavailable)

### Config Templates

- `config/agent-fragment.json5` — OpenClaw config fragment ($include'd by openclaw.json)
- Contains: agent profiles (`agents.list[]`), bootstrap limits, skills allowlist
- Model configuration per SDD phase defined here (single source of truth)

---

## File Structure

```
lucy-ai/
├── install.sh          Main installer (single script)
├── update.sh           Update existing install
├── uninstall.sh        Clean removal
├── verify.sh           Post-install verification
├── workspace/          Workspace templates
│   ├── AGENTS.md       Lucy's operating rules (agnostic, locked)
│   ├── TOOLS.md        Tool inventory (agnostic, locked)
│   ├── MEMORY.md       Long-term memory template (sanitized)
│   ├── SOUL.md         Persona template
│   ├── IDENTITY.md     Identity template
│   ├── USER.md         User profile template
│   └── HEARTBEAT.md    Heartbeat template
├── config/             OpenClaw config templates
│   └── agent-fragment.json5
├── skills/             Bundled skills
├── sdd/                SDD workflow files
│   └── templates/      Phase templates
│       └── standards.md.in  Project standards template
├── scripts/            Build/CI scripts
│   ├── common.sh       Shared helpers
│   ├── check-content-boundaries.sh   Content boundary validator
│   └── install-pre-commit-hook.sh    Pre-commit hook installer
└── docs/
    └── STANDARDS.md    This file
```

---

## Shell Script Standards

- **Shebang**: `#!/usr/bin/env bash`
- **Error handling**: `set -euo pipefail` at top
- **Functions**: `snake_case`, descriptive names
- **Variables**: UPPERCASE for constants, lowercase for locals
- **Comments**: explain WHY, not WHAT (the code is the WHAT)
- **No secrets**: no API keys, tokens, or credentials hardcoded

---

## Workspace File Standards

- All template files in `workspace/` must be **project-agnostic**
- No references to specific projects (ZENTICALAB, excel-pipeline, etc.)
- No architecture patterns, naming conventions, or framework specifics
- Tech patterns → bundled skills (`skills/{name}/SKILL.md`)
- Project standards → `/workspace/repos/{project}/docs/STANDARDS.md`
- Pre-commit hook blocks project-specific content in locked files

---

## Commit Convention

Format: `type: short description`

Types:
- `feat`: new feature or capability
- `fix`: bug fix
- `refactor`: internal improvement (no behavior change)
- `docs`: documentation only
- `test`: test-only changes
- `release`: version bump + changelog

Examples:
```
feat: add SDD phase agent profiles to config
fix: prevent workspace template from including project standards
release: v1.4.0 — agnostic workspace with content boundary enforcement
```

---

## Git Workflow

### Protected branches — NO EXCEPTIONS

- `main` — release branch, **never push directly**
- `clone` — fork/clone branch, **never push directly**

### Flow

1. All work on **feature branches** (`feat/description`)
2. **Never** push/merge directly to `main` or `clone`
3. Open PR → assign `camiloandresgtruniandes` as reviewer
4. PR requires approved review before merge

### Release Process

1. Feature branch → PR → merge to `main`
2. Tag release with version: `git tag vX.Y.Z`
3. Cherry-pick or merge relevant changes to `clone`
4. `clone` branch includes user-configurable defaults (not personal config)

---

## Environment & Secrets

- **Never commit**: API keys, tokens, OAuth credentials, bot tokens
- Config fragment uses placeholders, not real values
- `.env` file git-ignored for local development
