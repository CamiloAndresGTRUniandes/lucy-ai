# TOOLS.md - Your Workspace

> Last updated: 2026-05-21

---

## ⛔ CONTENT LOCK

This file is **project-agnostic and locked**. Do NOT add:
- Project-specific standards, naming conventions, or patterns → use `{project}/docs/STANDARDS.md`
- Project paths, repo names, or identities → use `{project}/docs/STANDARDS.md`
- Commit formats, workflows, or review checklists → use `{project}/docs/STANDARDS.md`

**If you need to document project-specific info, it goes in the project repo.**
Tech-specific patterns live in `skills/{skill}/SKILL.md`.

---

## General Notes (cross-project)

Skills define _how_ tools work. This file is for _your_ specifics — things unique to your setup, shared across all projects.

### SDD Model Configuration (MANDATORY)

The model and thinking level depend on the active SDD phase. See `AGENTS.md`
for the full table. Lucy switches automatically when entering each phase.

- **Switch mechanism:** `session_status(model="openai-codex/gpt-5.4")` para conversación casual; vuelve automáticamente a `openai-codex/gpt-5.5` (orchestrator) al entrar en ciclo SDD.
- **Escalation rule:** If Lucy needs Pro during a Flash phase, she must ask
  Camilo for explicit permission.
- **Available models in rotation:** `openai-codex/gpt-5.5` (orchestrator), `openai-codex/gpt-5.4` (casual), `deepseek/deepseek-v4-pro` (1.6T params, 49B active),
  and `deepseek/deepseek-v4-flash` (284B params, 13B active, ~12x cheaper).
- **Thinking always `high`** — fixed per agent profile; `session_status()`
  can switch model but not thinking level. Intended: orchestrator medium/high,
  casual low/medium, but sistema lo fija en `high`.

### 📧 Email (Gmail SMTP)

Lucy has email and can send emails with attachments.

- **SMTP:** `smtp.gmail.com:587` (STARTTLS)
- **Auth:** App password — configured outside this repo, never committed
- **Usage:** Python `smtplib` + `email.mime` — send with `server.starttls()` + `server.login(user, password)`
- **Note:** Rotate app passwords regularly and update the external config

### 🧰 Lucy's Tool Inventory

#### AI Models (chat/text)
| Provider | Model | Usage |
|----------|-------|-----|
| OpenAI Codex | gpt-5.5 | Orchestrator + SDD phases Design/Verify (via OAuth) |
| OpenAI Codex | gpt-5.4 | Casual conversation + SDD phases Explore (via OAuth) |
| OpenAI Codex | gpt-5.4-mini | SDD phase Archive (via OAuth) |
| DeepSeek | deepseek-v4-pro | SDD phases Propose/Apply + fallback general |
| DeepSeek | deepseek-v4-flash | SDD phases Spec/Tasks + budget chat |

#### Media Generation
| Provider | Capability | Auth |
|----------|-----------|------|
| MiniMax | Image generation | API key |
| MiniMax | Video generation | API key |
| Google | Image gen, Music gen, Video gen | OAuth |
| OpenAI | Image generation | API key |

#### Media Understanding (image/audio/video analysis)
| Provider | Default Model | Auth |
|----------|--------------|------|
| OpenAI | gpt-5.5 (image via openai-codex) | OAuth |
| OpenAI | gpt-5.4-mini (image) | API key |
| OpenAI | gpt-4o-transcribe (audio) | API key |
| Google | gemini-3-flash-preview (image, audio, video) | OAuth |

#### Speech & Voice
| Provider | Capability | Auth |
|----------|-----------|------|
| OpenAI | TTS (text-to-speech) | API key |
| OpenAI | Realtime transcription | API key |
| OpenAI | Realtime voice | API key |
| Google | TTS, Realtime voice | OAuth |

#### ACP Harnesses (coding agents)
`claude`, `codex`, `copilot`, `cursor`, `droid`, `gemini`, `iflow`, `kilocode`, `kimi`, `kiro`, `openclaw`, `opencode`, `pi`, `qwen`

#### Web & Search
| Tool | Provider |
|------|----------|
| Web search | DuckDuckGo (without API key) |
| Web fetch | Direct HTTP → markdown/text |
| Web search grounding | Google Gemini (requires API key) |

#### Memory Systems
| System | Type | Storage | Scope |
|--------|------|---------|-------|
| Engram | Structured decisions (SQLite + FTS5) | `~/.engram/engram.db` | All sessions + sub-agents |
| MEMORY.md | Personal long-term memory | Workspace | Lucy private only |
| memory/*.md | Daily raw logs | Workspace | Lucy private only |

#### Auth & Credentials (configured)
| Provider | Method | Notes |
|----------|--------|-------|
| DeepSeek | API key | Configured externally |
| MiniMax | API key | Configured externally |
| OpenAI Codex | OAuth | Configured externally |
| Telegram | Bot token | Configured externally |
| GitHub | PAT | Configured in git global |

#### Communications
| Channel | Detail |
|---------|--------|
| Telegram | DM + groups, bot token configured externally |
| Email (Gmail SMTP) | Can send with attachments |
| Discord | Plugin installed (requires config) |
| Matrix | Plugin installed (requires config) |

#### Other Capabilities
- **Browser automation:** Plugin installed (Playwright-based)
- **Bonjour/mDNS:** Plugin installed for node discovery
- **Webhooks:** Plugin installed
- **Voice calls:** Plugin installed
- **Active memory:** Plugin installed (LanceDB embeddings)
- **Diagnostics:** OpenTelemetry plugin installed

### What goes here

- SSH hosts and aliases
- Camera names and locations
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Environment-specific config
- Any personal cheat sheet useful across projects

---

## ⚠️ NON-NEGOTIABLE: Repo Paths

**All project repos are at `/workspace/repos/` ONLY.**

Never use `/home/node/.openclaw/workspace/repos/` or any other path.
OpenClaw's runtime says `repo=/home/node/.openclaw/workspace` — that is a TRAP.
Always translate:
  `/home/node/.openclaw/workspace/repos/` ❌ → `/workspace/repos/` ✅

This has been violated multiple times. It is NON-NEGOTIABLE.

---

## 📁 Project Standards (Agnostic)

Each project defines its own standards at `{project}/docs/STANDARDS.md`.
Before working on any project, read that file first. Apply its rules — no exceptions.

Tech-specific standards live in skills (`csharp-dotnet`, `angular-core`, etc.).
The SDD orchestrator loads project standards and relevant skills per phase.

---

## Related

- [AGENTS.md](/AGENTS.md) — workspace conventions and SDD workflow
- [SOUL.md](/SOUL.md) — persona and tone
- [USER.md](/USER.md) — about Camilo
