<div align="center">

```
  #       #   #     ###     #   #
  #       #   #    #        # #
  #       #   #    #         #
  #       #   #    #         #
  #####    ###      ###      #
```

**Lucy Under the Coding Yield**

</div>

<p align="center">
  <strong>Your AI colleague, deployed like your code.</strong><br>
  A fully installable agent ecosystem for OpenClaw — with personality, skills,<br>
  and conventions ready to go.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.9.0-30%25?style=for-the-badge&logo=semver&logoColor=%2300C853" alt="v1.9.0">
  <img src="https://img.shields.io/github/stars/CamiloAndresGTRUniandes/lucy-ai?style=for-the-badge&logo=github&color=0D1117" alt="GitHub stars">
  <img src="https://img.shields.io/badge/OpenClaw-Powered-30%25?style=for-the-badge&logoColor=%2300C853" alt="OpenClaw">
  <img src="https://img.shields.io/badge/MIT-License-0D1117?style=for-the-badge&logoColor=%2300C853" alt="MIT">
</p>

---

## ⚡ What's New in v1.9

- 📦 **Full-clone export/import** — migrate your entire Lucy/OpenClaw setup between servers
- 📤 **`export-full-clone.sh`** — new script that bundles `openclaw.json`, `lucy-agent/`, and `workspace/` into a portable `lucy-full-clone-*.tar.gz`
- 🔒 **Safe by default** — auth tokens, credentials, identity, and `.env` are excluded unless you opt in with `--include-identity`
- 🧠 **`--exclude-memories`** — export config without session memory/history
- 📥 **`install.sh --full-clone <path-or-url>`** — restore a bundle on a new server with automatic backup, config validation, and re-auth reminder

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

---

## ⚡ Install in 30 seconds

### Pre-installation

- **OpenClaw** must be installed and the gateway running
- Have your **API keys** ready (at minimum `DEEPSEEK_API_KEY`)
- Choose your install mode: `--clone` for Lucy's exact setup, or no flag for a fresh template

```bash
# Clone Lucy's exact setup (recommended)
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --clone

# Or start with generic templates
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash

# Install a specific version
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --tag v1.9.0

# Restore a full-clone bundle on a new server
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --full-clone ./lucy-full-clone-20260731-150000.tar.gz
```

> 💡 Run without flags for an interactive TUI wizard to choose components and install mode.

---

## 🌍 Agnostic Configuration

Lucy's workspace templates (`AGENTS.md`, `TOOLS.md`, `MEMORY.md`) are **project-agnostic** — they contain only Lucy's operating rules and cross-project tool inventory. No project-specific standards, architecture patterns, or naming conventions.

**Why this matters:**
- **Fork-friendly** — your fork starts with clean, universal templates (no Camilo/ZENTICALAB rules)
- **No drift** — the same templates work for any project, any stack
- **Separation of concerns** — project standards live in each repo's `docs/STANDARDS.md`, not in Lucy's global workspace
- **Skills handle tech** — language-specific patterns belong in bundled skills (e.g., `csharp-dotnet`, `angular-core`)

## ⚙️ Why Config Lives in openclaw.json

SDD agent profiles are defined in `config/agent-fragment.json5` and loaded into `openclaw.json` via `$include`:

```json
{ "$include": "./lucy-agent/config/agent-fragment.json5" }
```

This fragment contains:
- **`agents.defaults`** — primary model, thinking level, bootstrap limits, skills allowlist, timeout
- **`agents.list[]`** — 9 fixed SDD profiles (`sdd-explore`, `sdd-design`, `sdd-apply`, etc.) with per-phase models and timeouts
- **`mcp.servers.engram`** — Engram technical memory integration

The agent profiles are **runtime config**, not generated prose in AGENTS.md. When Lucy spawns sub-agents, she uses `agentId` (e.g. `sdd-design`) — the model, thinking, and timeout are resolved automatically from the profile.

## 🛡️ Content Boundary Enforcement

Two files are **locked** and must remain project-agnostic:
- `workspace/AGENTS.md` — Lucy's operating rules
- `workspace/TOOLS.md` — tool inventory and cross-project notes

**What the pre-commit hook does:**
- Scans staged changes to locked files for project-specific content
- Blocks commits that introduce project names (ZENTICALAB, excel-pipeline, etc.), project-standard headings, or hardcoded project paths
- Accepts generic placeholders (`{project}`, `{repo}`, `/workspace/repos/{project}`)

This ensures that templates stay clean across all installations and forks.

## 👷 Contributor Setup

If you plan to contribute changes to lucy-ai:

```bash
# Install with the pre-commit hook
./install.sh --contributor

# Or install the hook manually after cloning
./scripts/install-pre-commit-hook.sh
```

The hook prevents accidental commits that would leak project-specific content into locked template files.

## What you get

| Component | What's included |
|-----------|----------------|
| 🧠 **Personality** | SOUL.md, IDENTITY.md, AGENTS.md — your agent's character, values, and operating rules |
| 📝 **Memory** | MEMORY.md — sanitized long-term memory template with privacy guidance |
| 🛠️ **Skills** | SDD Orchestrator, .NET 10/C# 14, Angular 21, TypeScript, Tailwind, OWASP Security, PR review |
| 🌤️ **Superpowers** | Weather, browser automation, coding agent routing |
| ⚙️ **Config** | 9 fixed SDD agent profiles, multi-provider model config, thinking level — all ready to include |
| 🛡️ **Enforcement** | Pre-commit hook blocks project-specific content in locked template files |
| ✅ **Verify** | Post-install checks so you know everything is wired up |
| 🧹 **Uninstall** | Clean removal when you want to start fresh |
| 🪶 **Engram** | Technical decision memory (FTS5, conflict detection, session tracking) |

## 🏗️ Harness Engineering — The Infrastructure Behind Your Agent

**Harness Engineering** is the discipline of building the scaffolding around an LLM to turn it into a reliable, production-grade agent. Research shows the harness design impacts agent performance more than the underlying model itself.

lucy-ai implements all 7 layers of the agent harness:

| Layer | What it does | lucy-ai delivers |
|-------|-------------|-------------------|
| 🧠 **Model & Runtime** | LLM selection, execution environment | 9 fixed SDD agent profiles via `config/agent-fragment.json5`, auto-injected into `openclaw.json` |
| 💾 **Memory** | Short-term and long-term context | MEMORY.md (personal) + Engram (technical, FTS5) + `memory/*.md` (daily logs) |
| 🔧 **Tooling** | APIs, code execution, external systems | 18 bundled skills (SDD, .NET, Angular, Security, GitHub, Weather, Browser) |
| 🎯 **Orchestration** | Multi-step workflows, delegation | SDD Orchestrator: 8-phase workflow with sub-agent delegation, task contracts, and validation |
| 👁️ **Observability** | Monitoring, evaluation, audit | `verify.sh` (118+ checks), content boundary enforcement, CI pipeline (5 jobs) |
| 📚 **Knowledge** | Grounding in trusted data | Engram decision memory with conflict detection, FTS5 search, session tracking |
| 🎭 **Goal Definition** | Agent purpose, values, constraints | SOUL.md (persona), IDENTITY.md (role), AGENTS.md (non-negotiable rules and boundaries) |

> 💡 Read more: [Harness Engineering: The Infrastructure Layer That Makes AI Agents Actually Work](https://medium.com/@visrow/harness-engineering-the-infrastructure-layer-that-makes-ai-agents-actually-work-598a279c1c5f)

## Install modes

| Mode | Command | Best for |
|------|---------|----------|
| **Clone** | `curl ... | bash -s -- --clone` | Get Lucy's exact setup — skip the config |
| **Template** | `curl ... | bash -s -- --template` | Fresh start with generic placeholders |
| **TUI Wizard** | `curl ... | bash` | Guided setup with dialog menus (install mode, components, confirm) |
| **Contributor** | `curl ... | bash -s -- --contributor` | Like template + installs pre-commit hook for repo contributions |
| **Automation** | `curl ... | bash -s -- --clone --accept-defaults` | CI/CD pipelines — no prompts needed |
| **Specific version** | `curl ... | bash -s -- --tag v1.9.0` | Pin to a known release |

## Post-install

```bash
# 1. Add your channel tokens to openclaw.json (Telegram, WhatsApp, etc.)
#    The config fragment is auto-injected during install — no manual step needed.

# 2. Restart the gateway to load the new agent profiles
openclaw gateway restart

# 3. If you have active sessions, refresh them
#    Type /new in any open chat to load the updated skills and config
```

> 💡 During installation, `install.sh` automatically links `config/agent-fragment.json5` into your `openclaw.json` via `$include` — no manual step required. The fragment defines 9 fixed SDD agent profiles (`sdd-design`, `sdd-apply`, etc.), bootstrap limits, skills allowlist, and the Engram MCP server. You can edit the fragment to customize models for your subscriptions.
>
> After restart, run `./verify.sh` inside `~/.openclaw/lucy-agent/` to confirm everything is wired up (118+ checks).

## Skills included

| Skill | Purpose |
|-------|---------|
| `sdd` | SDD Orchestrator — sub-agent delegation, phase templates, validation, skill auto-loading |
| `csharp-dotnet` | Clean Architecture, SOLID, DRY for .NET/C# |
| `dotnet10-csharp14` | .NET 10 + C# 14 best practices (field keyword, params Span, etc.) |
| `typescript` | TypeScript strict mode patterns |
| `tailwind-4` | Tailwind CSS 4 patterns and best practices |
| `angular-core` | Angular 21 standalone components, signals, inject, zoneless |
| `angular-architecture` | Angular 21 Scope Rule, project structure, naming |
| `angular-forms` | Angular 21 Signal Forms + Reactive Forms |
| `angular-performance` | Angular 21 NgOptimizedImage, @defer, SSR |
| `zenticalab-security` | OWASP Top 10 2025 security guidance |
| `zenticalab-pr-review` | PR review checklist for .NET + Angular projects |
| `github-pr` | High-quality PRs with conventional commits |
| `skill-creator` | Build new skills for your agent |

### ClawHub (auto-installed)

`weather` · `browser-automation` · `acp-router`

## Update your agent

```bash
cd ~/.openclaw/lucy-agent

# Latest version (detects how you installed it)
./update.sh

# Pin to a specific version
./update.sh --tag v1.9.0

# Show version info
./update.sh --version
```

## Verify everything is working

```bash
cd ~/.openclaw/lucy-agent
./verify.sh
```

## Uninstall

```bash
cd ~/.openclaw/lucy-agent
./uninstall.sh

# Non-interactive (CI/automation)
./uninstall.sh --force
```

## All flags

```bash
# Install flags
install.sh --clone             # Clone Lucy's exact config
install.sh --template          # Use generic templates
install.sh --tag <version>     # Install specific release (e.g. v1.9.0)
install.sh --contributor       # Install with pre-commit hook for contributors
install.sh --no-tui            # Force text prompts (skip TUI wizard)
install.sh --accept-defaults   # Accept all defaults (CI-friendly)
install.sh --skip-engram       # Skip Engram memory system
install.sh --engram-tag <ver>  # Pin Engram version (default: latest)
install.sh --skip-clawhub      # Skip ClawHub skills
install.sh --skip-workspace    # Skip workspace seeding
install.sh --force             # Overwrite without asking
install.sh --force-stash        # Stash local changes before pulling
install.sh --quiet, -q         # Suppress info output (show only warnings)
install.sh --dry-run           # Preview without changes
install.sh --version           # Show version and exit
install.sh --help             # Show help

# Update flags
update.sh --tag <version>           # Pin to version
update.sh --skip-engram-update      # Skip Engram version check
update.sh --update-engram           # Force Engram reinstall
update.sh --force                   # Force overwrite / stash local changes
update.sh --force-stash        # Stash local changes before pulling
update.sh --quiet, -q          # Suppress info output
update.sh --dry-run            # Preview
update.sh --version            # Show version and exit

# Uninstall flags
uninstall.sh --force           # No confirmation prompt
uninstall.sh --keep-skills     # Keep bundled skills
uninstall.sh --keep-workspace  # Keep workspace seed files
uninstall.sh --dry-run         # Preview
uninstall.sh --quiet, -q       # Suppress info output
```

## Repository structure

```
lucy-agent/
├── install.sh                  ← One-command installer
├── update.sh                   ← In-place updater
├── verify.sh                   ← Post-install verification
├── uninstall.sh               ← Clean removal
├── scripts/
│   ├── common.sh              ← Shared helpers (sourced by all scripts)
│   ├── check-content-boundaries.sh  ← Locked-file content validator
│   └── install-pre-commit-hook.sh   ← Pre-commit hook installer
├── SKILL.md                    ← Meta-skill documentation
├── CHANGELOG.md                ← Version history
├── SPEC.md                     ← Current release spec
├── .github/                    ← CI workflows
│   └── workflows/
│       └── ci.yml              ← 5-job validation pipeline
├── clawhub-skills.txt         ← Auto-install list
├── skills/                     ← Bundled skills (13 total)
│   ├── sdd/
│   ├── csharp-dotnet/
│   ├── dotnet10-csharp14/
│   ├── angular-core/
│   ├── angular-architecture/
│   ├── angular-forms/
│   ├── angular-performance/
│   ├── zenticalab-security/
│   ├── zenticalab-pr-review/
│   └── ...
├── workspace/                  ← Seed files
│   ├── sdd/                      ← SDD Orchestrator (docs + templates)
│   ├── SOUL.md                   ← Persona template
│   ├── IDENTITY.md               ← Identity template
│   ├── AGENTS.md                 ← Operating rules (agnostic, locked)
│   ├── TOOLS.md                  ← Tool inventory (agnostic, locked)
│   ├── MEMORY.md                 ← Long-term memory template (sanitized)
│   ├── USER.md                   ← User profile template
│   └── HEARTBEAT.md              ← Heartbeat template
└── config/
    └── agent-fragment.json5   ← $include for openclaw.json
```

## Security

- ✅ **No secrets ever** — API keys, tokens, credentials never in the repo
- ✅ **Auditable** — `curl` the install script before running
- ✅ **Safe defaults** — Sensitive files (`openclaw.json`, `.env`, `*.key`) always excluded

## Build your own agent

lucy-agent is fork-friendly. To create your own agent:

1. Fork this repo
2. Edit `workspace/SOUL.md` and `workspace/IDENTITY.md` for your persona
3. Adjust `workspace/USER.md` with your preferences
4. Update `config/agent-fragment.json5` for your model subscriptions and preferred skills
5. **Project standards go in your project repo** — create `docs/STANDARDS.md` in each project (use `sdd/templates/standards.md.in` as a starting point)
6. If contributing template changes back, install the pre-commit hook: `./scripts/install-pre-commit-hook.sh`
7. Run your fork's install script

### Keeping your fork updated

After forking, keep your copy in sync with upstream:

```bash
# Add upstream remote (one-time setup)
git remote add upstream https://github.com/camiloandresgtruniandes/lucy-ai.git

# Fetch latest from upstream
git fetch upstream

# Merge upstream changes into your main
git checkout main
git merge upstream/main
```

## Contributing

Issues and PRs welcome. All changes go through review before merge.

## License

**MIT** — See [LICENSE](LICENSE)

---

🦁 *lucy-agent — because your AI colleague should be just as easy to deploy as your code.*
