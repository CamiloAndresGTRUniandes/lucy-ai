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
  <img src="https://img.shields.io/badge/SDD-Agent-0D1117?style=for-the-badge&logoColor=%2300C853" alt="SDD Agent">
  <img src="https://img.shields.io/badge/OpenClaw-Powered-30%25?style=for-the-badge&logoColor=%2300C853" alt="OpenClaw">
  <img src="https://img.shields.io/badge/MIT-License-0D1117?style=for-the-badge&logoColor=%2300C853" alt="MIT">
  <img src="https://img.shields.io/badge/Version-1.4.0-30%25?style=for-the-badge&logo=semver&logoColor=%2300C853" alt="v1.4.0">
</p>

---

## ⚡ Install in 30 seconds

```bash
# Clone Lucy's exact setup (recommended)
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --clone

# Or start with generic templates
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash

# Install a specific version
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-ai/main/install.sh | bash -s -- --tag v1.3.0
```

> 💡 **New here?** Run without flags for an interactive setup guide.

---

## What you get

| Component | What's included |
|-----------|----------------|
| 🧠 **Personality** | SOUL.md, IDENTITY.md, AGENTS.md — your agent's character, values, and operating rules |
| 🛠️ **Skills** | SDD workflow + Orchestrator, PR review, Clean Architecture, TypeScript, Tailwind, C#/.NET |
| 🌤️ **Superpowers** | Weather, browser automation, coding agent routing |
| ⚙️ **Config** | Agent defaults, model config, thinking level — all ready to include |
| ✅ **Verify** | Post-install checks so you know everything is wired up
| 🧹 **Uninstall** | Clean removal when you want to start fresh
| 🪶 **Engram** | Technical decision memory (FTS5, conflict detection, session tracking) |

## Install modes

| Mode | Command | Best for |
|------|---------|----------|
| **Clone** | `curl ... | bash -s -- --clone` | Get Lucy's exact setup — skip the config |
| **Template** | `curl ... | bash -s -- --template` | Fresh start with placeholders |
| **Specific version** | `curl ... | bash -s -- --tag v1.3.0` | Pin to a known release |
| **Interactive** | `curl ... | bash` | Guided setup with friendly prompts |

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
| `sdd` | Spec-Driven Development + SDD Orchestrator — sub-agent delegation, phase templates, validation |
| `github-pr` | High-quality PRs with conventional commits |
| `pr-review` | Generic PR review for any codebase |
| `csharp-dotnet` | Clean Architecture patterns for .NET/C# |
| `tailwind-4` | Tailwind CSS 4 patterns and best practices |
| `typescript` | TypeScript strict mode patterns |
| `skill-creator` | Build new skills for your agent |

### ClawHub (auto-installed)

`weather` · `browser-automation` · `acp-router`

## Update your agent

```bash
cd ~/.openclaw/lucy-agent

# Latest version (detects how you installed it)
./update.sh

# Pin to a specific version
./update.sh --tag v1.3.0

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
install.sh --tag <version>     # Install specific release (e.g. v1.0.0)
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
├── clawhub-skills.txt         ← Auto-install list
├── skills/                     ← Bundled skills
│   ├── sdd/
│   ├── github-pr/
│   ├── pr-review/
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
