---
name: lucy-agent
description: >
  Lucy-ai's own agent ecosystem installer, updater, and verifier.
  Use this skill when:
  - Installing lucy-agent on a new OpenClaw instance
  - Updating lucy-agent in-place
  - Verifying the lucy-agent installation
  - Understanding the lucy-agent structure
metadata:
  author: lucy-ai
  version: "1.2"
---

## What is lucy-agent?

lucy-agent is the installable ecosystem for Lucy-ai — a fully configured AI colleague
with personality, skills, conventions, and gateway config fragment.

**Repository:** https://github.com/camiloandresgtruniandes/lucy-agent

## Installation

### One-command install (fresh machine)

```bash
curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash
```

### Flags

- `--skip-clawhub` — Skip ClawHub skill installation
- `--skip-workspace` — Skip workspace file seeding
- `--force` — Overwrite conflicting files without prompting
- `--dry-run` — Show what would be done without making changes

### Post-install (manual)

1. Link the config fragment in `openclaw.json`:
   ```json5
   { $include: "./lucy-agent/config/agent-fragment.json5" }
   ```
2. Configure channel tokens and API keys in `openclaw.json`
3. Restart OpenClaw: `openclaw gateway restart`

## Updating

```bash
cd ~/.openclaw/lucy-agent && ./update.sh
# Or pin to a specific version:
./update.sh --tag v1.0.0
```

## Verification

```bash
cd ~/.openclaw/lucy-agent && ./verify.sh
```

## What's included

- **Bundled skills:** sdd, github-pr, pr-review, csharp-dotnet, tailwind-4, typescript, skill-creator
- **ClawHub skills:** weather (auto-installed)
- **Workspace seed:** SOUL.md, IDENTITY.md, AGENTS.md, USER.md, TOOLS.md, HEARTBEAT.md
- **Config fragment:** agent defaults (skills, model, thinking level)

## Conflict handling

lucy-agent is **idempotent and careful**:
- If a workspace file was modified by the user, it prompts before overwriting
- If a skill was modified by the user, it prompts before overwriting
- Re-running install.sh on an existing installation does a `git pull` (not a fresh clone)

## Security

- No secrets are ever committed (API keys, tokens, credentials)
- The install script is auditable — curl it and read before running
- Config fragment contains only public configuration (skill names, model names, flags)

## Troubleshooting

### "OpenClaw CLI not found"
Install OpenClaw first: `curl -fsSL https://openclaw.ai/install.sh | bash`

### verify.sh fails
Run with verbose output: `bash -x verify.sh`
Check that all skills in `skills/` have a `SKILL.md` file

### git pull fails on existing installation
```bash
cd ~/.openclaw/lucy-agent
git status  # check for uncommitted changes
git stash   # or manually handle conflicts
git pull
```
