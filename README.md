# 🦁 lucy-agent

<!-- HEADER_START -->
<p align="center">
  <img src="https://img.shields.io/badge/AI%20Agent-Lucy%20&%20Co.-30%25?style=for-the-badge&logo=robot&logoColor=%2300C853" alt="Lucy-ai">
  <img src="https://img.shields.io/badge/OpenClaw-Powered-0D1117?style=for-the-badge&logo=claw&logoColor=%2300C853" alt="OpenClaw">
  <img src="https://img.shields.io/badge/License-MIT-30%25?style=for-the-badge&logo=scroll&logoColor=%2300C853" alt="MIT">
</p>

<p align="center">
  <strong>Your AI colleague, deployed like your code.</strong><br>
  A fully installable agent ecosystem for OpenClaw — with personality, skills, and conventions ready to go.
</p>

---

## ⚡ Install in 30 seconds

```bash
# Clone Lucy's exact setup (recommended)
curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --clone

# Or start with generic templates
curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash
```

> 💡 **New here?** Run without flags for an interactive setup guide.

---

## What you get

| Component | What's included |
|-----------|----------------|
| 🧠 **Personality** | SOUL.md, IDENTITY.md, AGENTS.md — your agent's character, values, and operating rules |
| 🛠️ **Skills** | SDD workflow, PR review, Clean Architecture patterns, TypeScript, Tailwind, C#/.NET |
| 🌤️ **Superpowers** | Weather, browser automation, coding agent routing |
| ⚙️ **Config** | Agent defaults, model config, thinking level — all ready to include |
| ✅ **Verify** | Post-install checks so you know everything is wired up |

## Install modes

| Mode | Command | Best for |
|------|---------|----------|
| **Clone** | `curl ... \| bash -s -- --clone` | Get Lucy's exact setup — skip the config |
| **Template** | `curl ... \| bash -s -- --template` | Fresh start with placeholders |
| **Interactive** | `curl ... \| bash` | Guided setup with friendly prompts |

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
| `sdd` | Spec-Driven Development — spec before code, always |
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

# Latest version
./update.sh

# Pin to a specific version
./update.sh --tag v1.1.0
```

## Verify everything is working

```bash
cd ~/.openclaw/lucy-agent
./verify.sh
```

## All flags

```bash
# Install flags
install.sh --clone          # Clone Lucy's exact config
install.sh --template        # Use generic templates
install.sh --skip-clawhub    # Skip ClawHub skills
install.sh --skip-workspace   # Skip workspace seeding
install.sh --force           # Overwrite without asking
install.sh --dry-run         # Preview without changes
install.sh --help            # Show help

# Update flags
update.sh --tag v1.2.3       # Pin to version
update.sh --force            # Force overwrite
update.sh --dry-run          # Preview
```

## Repository structure

```
lucy-agent/
├── install.sh                  ← One-command installer
├── update.sh                   ← In-place updater
├── verify.sh                   ← Post-install verification
├── SKILL.md                    ← Meta-skill documentation
├── CHANGELOG.md                ← Version history
├── clawhub-skills.txt         ← Auto-install list
├── skills/                     ← Bundled skills
│   ├── sdd/
│   ├── github-pr/
│   ├── pr-review/
│   └── ...
├── workspace/                  ← Seed files
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

## Contributing

Issues and PRs welcome. All changes go through review before merge.

## License

**MIT** — See [LICENSE](LICENSE)

---

🦁 *lucy-agent — because your AI colleague should be just as easy to deploy as your code.*
