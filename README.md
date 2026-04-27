# lucy-agent

> 🦁 A fully installable AI agent ecosystem for OpenClaw

**lucy-agent** is a public, open-source agent configuration that turns any OpenClaw instance into a fully operational Lucy-ai — a capable AI colleague with personality, development skills, architecture patterns, and community conventions.

## What you get

- 🧠 **SDD Workflow** — Spec-Driven Development built into the agent
- 🔍 **PR Review** — ZENTICALAB project PR review patterns
- 🛠️ **Development Skills** — C#, TypeScript, Tailwind, Angular 21, .NET 10
- 🌤️ **Auto-installed ClawHub Skills** — weather, browser-automation, acp-router
- 📁 **Workspace Seed** — SOUL.md, IDENTITY.md, AGENTS.md, USER.md, TOOLS.md, HEARTBEAT.md
- ⚙️ **Config Fragment** — agent defaults ready to `$include` in `openclaw.json`

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash
```

That's it. < 10 minutes from zero to operational Lucy on a fresh OpenClaw instance.

## Post-install

1. **Link the config fragment** — Add to `~/.openclaw/openclaw.json`:
   ```json5
   { $include: "./lucy-agent/config/agent-fragment.json5" }
   ```

2. **Configure your channels** — Add your Telegram bot token, WhatsApp credentials, etc. to `openclaw.json`

3. **Restart OpenClaw:**
   ```bash
   openclaw gateway restart
   ```

4. **Configure your USER.md** — Edit `~/.openclaw/workspace/USER.md` with your name and preferences

## Updating

```bash
cd ~/.openclaw/lucy-agent
./update.sh                  # latest from main branch
./update.sh --tag v1.0.0     # pin to a specific version
```

## What's in the box

### Bundled skills (`skills/`)

| Skill | Description |
|---|---|
| `sdd` | Spec-Driven Development workflow (8-phase) |
| `github-pr` | High-quality PR creation with conventional commits |
| `zenticalab-pr-review` | PR review for ZENTICALAB .NET + Angular projects |
| `csharp-dotnet` | C#/.NET Clean Architecture patterns |
| `tailwind-4` | Tailwind CSS 4 patterns and best practices |
| `typescript` | TypeScript strict patterns |
| `skill-creator` | Guide for creating new agent skills |

### ClawHub skills (auto-installed)

- `weather` — Current weather and forecasts
- `browser-automation` — Web browser control
- `acp-router` — Routing for coding agent workflows

### Workspace seed (`workspace/`)

- `SOUL.md` — Lucy-ai's persona, tone, and boundaries
- `IDENTITY.md` — Name (Lucy), emoji (🦁), role (colleague/mentor)
- `AGENTS.md` — Operating rules, memory protocol, git workflow
- `USER.md` — User profile template *(replace with your info)*
- `TOOLS.md` — Tool conventions and notes
- `HEARTBEAT.md` — Heartbeat checklist (empty by default)

### Config (`config/`)

- `agent-fragment.json5` — Lucy-ai agent defaults (skills allowlist, model, thinking level)

## Security

- ✅ **No secrets committed** — API keys, tokens, and credentials are never in the repo
- ✅ **Auditable install script** — Read it with `curl` before running
- ✅ **User-specific files are protected** — Modified `USER.md` and skill files prompt before overwrite

## Flags

```bash
# Installation flags
install.sh --skip-clawhub    # Skip ClawHub skill installation
install.sh --skip-workspace # Skip workspace file seeding
install.sh --force         # Overwrite conflicting files without prompting
install.sh --dry-run        # Show what would be done without making changes

# Update flags
update.sh --tag v1.2.3      # Pin to specific version
update.sh --force          # Overwrite conflicting files without prompting
update.sh --dry-run         # Show what would be done without making changes
```

## Repository structure

```
lucy-agent/
├── install.sh                  ← One-command installer
├── update.sh                   ← In-place updater
├── verify.sh                   ← Post-install verification
├── .gitignore
├── SKILL.md                    ← Meta-skill documentation
├── clawhub-skills.txt         ← Auto-install list
├── skills/                     ← Bundled skills (git-tracked)
│   ├── sdd/
│   ├── github-pr/
│   └── ...
├── workspace/                  ← Seed files (git-tracked)
│   ├── SOUL.md
│   ├── IDENTITY.md
│   └── ...
└── config/
    └── agent-fragment.json5    ← $include fragment for openclaw.json
```

## For developers

### Forking for your own agent

lucy-agent is designed to be forked. To create your own agent based on lucy-agent:

1. Fork this repository
2. Edit `workspace/SOUL.md` and `workspace/IDENTITY.md` to define your persona
3. Edit `workspace/USER.md` — replace Camilo's profile with yours
4. Adjust `config/agent-fragment.json5` to change skills and model
5. Run the install script from your fork:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/lucy-agent/main/install.sh | bash
   ```

### Contributing

Contributions welcome! This is an open-source project. Please note:

- **SDD workflow** — All changes should be discussed via issue before implementation
- **No secrets** — Never commit API keys, tokens, or credentials
- **Community-first** — All skills and patterns shared should be useful to the broader OpenClaw community

## License

**MIT** — See [LICENSE](LICENSE)

---

🦁 *lucy-agent — because your AI colleague should be just as easy to deploy as your code.*
