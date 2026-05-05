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
  <img src="https://img.shields.io/badge/Version-1.6.0-30%25?style=for-the-badge&logo=semver&logoColor=%2300C853" alt="v1.6.0">
  <img src="https://img.shields.io/github/stars/CamiloAndresGTRUniandes/lucy-ai?style=for-the-badge&logo=github&color=0D1117" alt="GitHub stars">
  <img src="https://img.shields.io/badge/OpenClaw-Powered-30%25?style=for-the-badge&logoColor=%2300C853" alt="OpenClaw">
  <img src="https://img.shields.io/badge/MIT-License-0D1117?style=for-the-badge&logoColor=%2300C853" alt="MIT">
</p>

---

## ⚡ What's New in v1.5.0

- 🎮 **Interactive TUI wizard** — `dialog`-based menus for install mode, component selection, and SDD phase model configuration
- ⚙️ **SDD Phase Configurator** — choose provider, model, and effort level for each of the 8 SDD phases (DeepSeek, OpenAI Codex, GitHub Copilot)
- 🔧 **GitHub Actions CI** — 5 independent validation jobs on every push and PR (shellcheck, bash syntax, shfmt format, verify checks, installer smoke test)
- 🏃 **Automation flags** — `--accept-defaults` for zero-interaction CI installs, `--no-tui` to force text mode
- 🔄 **Config sync** — multi-provider model strategy from live workspace (bye bye stale minimax references)
- 🐛 **Quality** — shellcheck clean (0 warnings), shfmt pass, verify.sh extended with model config checks

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

---

## ⚡ Install in 30 seconds

```bash
# Clone Lucy's exact setup (recommended)
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --clone

# Or start with generic templates
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash

# Install a specific version
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --tag v1.5.0
```

> 💡 **New in v1.5.0!** Run without flags for an **interactive TUI wizard** — configure SDD phase models, pick install mode, and review everything before installing.

---

## What you get

| Component | What's included |
|-----------|----------------|
| 🧠 **Personality** | SOUL.md, IDENTITY.md, AGENTS.md — your agent's character, values, and operating rules |
| 🛠️ **Skills** | SDD Orchestrator, .NET 10/C# 14, Angular 21, TypeScript, Tailwind, OWASP Security, PR review |
| 🌤️ **Superpowers** | Weather, browser automation, coding agent routing |
| ⚙️ **Config** | Agent defaults, multi-provider model config, thinking level — all ready to include |
| ✅ **Verify** | Post-install checks (48/48) so you know everything is wired up |
| 🧹 **Uninstall** | Clean removal when you want to start fresh |
| 🪶 **Engram** | Technical decision memory (FTS5, conflict detection, session tracking) |

### 🆕 v1.5.0 Highlights

| Feature | What it does |
|---------|-------------|
| 🎮 **Interactive TUI** | Dialog-based wizard for install mode, component selection, and **per-SDD-phase model configuration** |
| ⚙️ **SDD Phase Config** | Customize provider, model, and effort for each of the 8 SDD phases during installation |
| 🔧 **GitHub CI** | 5-job pipeline validates every PR — shellcheck, bash syntax, shfmt format, verify checks, installer smoke test |
| 🤖 **Multi-Provider** | Choose from DeepSeek, OpenAI Codex, and GitHub Copilot |
| 🏃 **Automation Ready** | `--accept-defaults` for CI/scripting, `--no-tui` to force text mode |

## Install modes

| Mode | Command | Best for |
|------|---------|----------|
| **Clone** | `curl ... | bash -s -- --clone` | Get Lucy's exact setup — skip the config |
| **Template** | `curl ... | bash -s -- --template` | Fresh start with placeholders |
| **TUI Wizard** | `curl ... | bash` | 🆕 Guided setup with dialog menus (SDD phases, components, confirm) |
| **Automation** | `curl ... | bash -s -- --clone --accept-defaults` | 🆕 CI/CD pipelines — no prompts needed |
| **Specific version** | `curl ... | bash -s -- --tag v1.5.0` | Pin to a known release |

## Post-install

```bash
# 1. Link the config fragment
echo '{ $include: "./lucy-agent/config/agent-fragment.json5" }' >> ~/.openclaw/openclaw.json

# 2. Add your channel tokens to openclaw.json (Telegram, WhatsApp, etc.)

# 3. Restart
openclaw gateway restart
```

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
./update.sh --tag v1.5.0

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
install.sh --tag <version>     # Install specific release (e.g. v1.5.0)
install.sh --no-tui            # 🆕 Force text prompts (skip TUI wizard)
install.sh --accept-defaults   # 🆕 Accept all defaults (CI-friendly)
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
│   └── common.sh              ← Shared helpers (sourced by all scripts)
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
│   ├── SOUL.md
│   ├── IDENTITY.md
│   ├── AGENTS.md
│   └── ...
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
4. Update `config/agent-fragment.json5` for your skills and model
5. Run your fork's install script

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

# Or update a specific install
git checkout upstream/lucy-config   # Get Lucy's latest config
```

## Contributing

Issues and PRs welcome. All changes go through review before merge.

## License

**MIT** — See [LICENSE](LICENSE)

---

🦁 *lucy-agent — because your AI colleague should be just as easy to deploy as your code.*
