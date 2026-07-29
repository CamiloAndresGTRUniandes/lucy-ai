# v1.8.0 — Live Workspace Capability Sync

> **Release date:** 2026-07-29

Bring the latest Lucy live workspace capabilities into the installable repository.

---

## What's New

- 🧠 **Orchestrator Doctrine** — New `orchestrator-doctrine` skill provides a master routing layer for SDD, sub-agents, decision critique, mentoring, and specialist skills
- 🛠️ **32 new bundled skills** — covering software architecture, security review, Azure DevOps, Ignite UI Angular, C# best practices, SQL optimization, mentoring, judgment-day, git workflow, issue creation, and skill discovery/registry
- 🌐 **Language-matching enforcement** — Lucy now matches the user's reply language (English/Spanish) as a hard, non-negotiable rule
- 📖 **English-standardized SDD docs** — All workflow docs and phase templates translated to English for broader accessibility
- 📋 **Release notes** — New `RELEASE_NOTES.md` for GitHub-compatible release descriptions

## What's Changed

- **SDD model matrix updated** — Verify phase primary model bumped from `openai-codex/gpt-5.3-codex` to `openai-codex/gpt-5.5`; main orchestrator to `openai-codex/gpt-5.5`
- **Config fragment updated** — Main agent profile defaults to `openai-codex/gpt-5.5` with `deepseek/deepseek-v4-pro` fallback
- **Workspace templates synced** — AGENTS.md, SOUL.md, USER.md, TOOLS.md refreshed from live workspace
- **7 skills updated** — angular-architecture, angular-core, dotnet10-csharp14, pr-review, sdd, skill-creator, tailwind-4
- **README.md** — version badge updated, What's New section rewritten

## What's Removed

- **Deprecated skills** — `zenticalab-pr-review` and `zenticalab-security` removed. Replaced by project-agnostic `pr-review` and `security` skills.

## Upgrade Notes

1. **For existing installations:** Run `cd ~/.openclaw/lucy-agent && ./update.sh` to update to v1.8.0
2. **Breaking change:** `zenticalab-pr-review` and `zenticalab-security` are no longer bundled. If your `openclaw.json` references them, update to use `pr-review` and `security` instead
3. **Config fragment changed:** The main agent now defaults to `opencode-codex/gpt-5.5`. Your local `openclaw.json` overrides this if you have custom agent config
