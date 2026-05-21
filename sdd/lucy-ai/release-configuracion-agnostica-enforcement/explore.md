# Explore: release-configuracion-agnostica-enforcement

## Status: Draft

## Codebase Overview

`lucy-ai` v1.6.3 is a Bash-based installer/template repo for OpenClaw agents, not an application runtime. The architecture is split across:
- `install.sh` as the idempotent entrypoint that clones/updates the repo, seeds `workspace/*.md`, mirrors `workspace/sdd/**`, installs bundled skills, and prints config-include instructions (`README.md:43-103`, `install.sh:1028-1105`).
- `workspace/` as seed files for `~/.openclaw/workspace/` (`docs/STANDARDS.md:29-34`, `README.md:225-232`).
- `config/agent-fragment.json5` as the OpenClaw config fragment that should be the single source of truth for SDD agent profiles and bootstrap limits (`docs/STANDARDS.md:36-40`).
- `sdd/` as orchestration docs/templates consumed by Lucy’s SDD workflow (`README.md:32-37`, `sdd/orchestrator-flow.md`, `sdd/task-string-format.md`).

The central release gap is that the LIVE workspace already reflects the new agnostic model, but the repo templates still package the older, partially project-specific setup:
- `workspace/AGENTS.md` is still the old “Your Workspace” variant and lacks the new non-negotiable rules/content-boundary framing.
- `workspace/TOOLS.md` still embeds ZENTICALAB standards.
- `workspace/MEMORY.md` is missing entirely.
- `config/agent-fragment.json5` is still a minimal defaults block, while the LIVE `openclaw.json` now carries phase-specific `agents.list[]`, larger bootstrap limits, and a broader skill set.
- `install.sh` still assumes AGENTS table rewriting via `<!-- SDD_TABLE_* -->` sentinels and does nothing for the requested pre-commit guard.

Key files for this release:
- Live reference: `/home/node/.openclaw/workspace/AGENTS.md`, `/home/node/.openclaw/workspace/TOOLS.md`, `/home/node/.openclaw/workspace/MEMORY.md`, `/home/node/.openclaw/openclaw.json`
- Repo templates: `workspace/AGENTS.md`, `workspace/TOOLS.md`, `config/agent-fragment.json5`, `install.sh`, `sdd/orchestrator-flow.md`, `sdd/task-string-format.md`, `docs/STANDARDS.md`

## Patterns Found

- **Workspace seeding copies top-level markdown + full SDD tree** — `install.sh:1028-1105`. Any new `workspace/MEMORY.md` will be auto-seeded once the file exists, but non-workspace assets like hooks are not handled.
- **Installer mutates AGENTS via sentinel replacement** — `install.sh:472-505` and `install.sh:1055-1060`. This assumes `workspace/AGENTS.md` contains `<!-- SDD_TABLE_START -->` / `<!-- SDD_TABLE_END -->`, which the LIVE AGENTS file no longer has.
- **Config fragment is intended as SDD source of truth, but current file is underspecified** — `docs/STANDARDS.md:36-40` versus `config/agent-fragment.json5:1-32`. The standards promise `agents.list[]`, bootstrap limits, and skills allowlist; the actual fragment only has a small defaults block plus Engram MCP.
- **Project-specific content leaked into locked workspace template** — `workspace/TOOLS.md:51-221`. The repo template still includes ZENTICALAB architecture, repo paths, workflows, and review rules.
- **Current orchestrator docs still describe model-based spawn, not agentId-based spawn** — `sdd/orchestrator-flow.md:15-31`, `sdd/orchestrator-flow.md:119-124`, `sdd/orchestrator-flow.md:165-170`, `sdd/orchestrator-flow.md:197-202`, `sdd/orchestrator-flow.md:224-229`, `sdd/orchestrator-flow.md:256-261`, `sdd/orchestrator-flow.md:283-288`.
- **README and installer still advertise per-phase model customization in the TUI** — `README.md:35`, `README.md:62`, `README.md:84`, `install.sh:529-760`. That conflicts with the new direction where SDD phase profiles live in config and should be enforced via `agentId`.

## Dependencies & Risks

- **High — installer/runtime drift**: `install.sh` customizes AGENTS documentation, but runtime behavior now belongs in `config/agent-fragment.json5` / `agents.list[]`. If only templates are updated, the TUI can keep producing docs that don’t match runtime. **Mitigation:** either move phase customization into the config fragment or intentionally freeze the phase profiles and simplify/remove the TUI model wizard.
- **High — pre-commit hook packaging**: `.git/hooks/pre-commit` is not tracked by git, and the repo currently has no tracked hook source. **Mitigation:** add a tracked template/script (for example under `scripts/` or `hooks/`) and materialize it into `.git/hooks/pre-commit` during contributor setup/install.
- **Medium — AGENTS sentinel dependency**: replacing `workspace/AGENTS.md` with the LIVE file removes the sentinel markers expected by `apply_sdd_table_to_agents_file()`. **Mitigation:** update or delete that rewrite path before release.
- **Medium — “agnostic” live files still contain leakage**: LIVE `TOOLS.md` still references a ZENTICALAB docker-compose path in the email section (`/home/node/.openclaw/workspace/TOOLS.md:40-44`), and LIVE `MEMORY.md` contains personal/project history. **Mitigation:** sanitize before copying verbatim into release templates.
- **Low — standards not shipped**: `docs/STANDARDS.md` already captures the intended rules but is untracked (`git status --short` shows `?? docs/`). **Mitigation:** add it to git in the same release and verify docs stay aligned with actual installer behavior.

## Gap Analysis: Live vs Template

### 1. `workspace/AGENTS.md`
- **Current state:** Old template starts with `# AGENTS.md - Your Workspace` and focuses on generic startup/memory guidance; it lacks the new top-level non-negotiable rules and content-boundary section (`workspace/AGENTS.md:1-67`). It also carries the old SDD table/orchestrator wording (`workspace/AGENTS.md:250-404`).
- **Target state:** LIVE file starts with `## ⛔ NON-NEGOTIABLE RULES`, adds locked-file boundaries, explicit project-standards loading, phase-gate protocol, newer SDD model/timeouts, and `agentId` enforcement (`/home/node/.openclaw/workspace/AGENTS.md:5-55`, `128-202`).
- **Delta:** Replace the template wholesale, then reconcile installer behavior that still expects table sentinels.
- **Risk level:** High.

### 2. `workspace/TOOLS.md`
- **Current state:** Template lacks the `CONTENT LOCK` section and includes a large ZENTICALAB-specific standards block (`workspace/TOOLS.md:51-221`).
- **Target state:** LIVE file is mostly project-agnostic, adds `CONTENT LOCK`, Lucy’s tool inventory, repo-path warning, and project-standards guidance (`/home/node/.openclaw/workspace/TOOLS.md:7-155`).
- **Delta:** Replace the template, remove all embedded project standards, and optionally sanitize the LIVE email section because it still references `/workspace/repos/ZENTICALAB/docker-compose.yml` (`/home/node/.openclaw/workspace/TOOLS.md:40-44`).
- **Risk level:** Medium.

### 3. `workspace/MEMORY.md`
- **Current state:** File does not exist in the repo template.
- **Target state:** Create a curated long-term memory template modeled after the LIVE structure.
- **Delta:** Add `workspace/MEMORY.md`, but do **not** copy the LIVE file verbatim because it contains personal identity/history, dates, project names, and prior decisions specific to Camilo (`/home/node/.openclaw/workspace/MEMORY.md:1-68`). Build a sanitized template with structure and guidance, not live content.
- **Risk level:** High.

### 4. `config/agent-fragment.json5`
- **Current state:** 32-line fragment with a small defaults skill list, Flash default model, and Engram MCP only (`config/agent-fragment.json5:1-32`). No `agents.list[]`, no bootstrap limits, no timeout, no expanded skills.
- **Target state:** Align with LIVE config shape for agent defaults + nine agent profiles (`main` + `sdd-explore` … `sdd-archive`), plus bootstrap settings and broader skill list (`/home/node/.openclaw/openclaw.json:45-178`).
- **Delta:** Expand the fragment to include:
  - `agents.defaults.model/thinking/workspace/bootstrapMaxChars/bootstrapTotalMaxChars/timeoutSeconds`
  - updated `agents.defaults.skills`
  - `agents.list[]` with the nine SDD profiles from LIVE config
  - keep Engram MCP block
  - decide whether to also mirror `tools.allow` from LIVE config (`openclaw.json:210-220`) or leave that out of scope explicitly.
- **Risk level:** High.

### 5. `.git/hooks/pre-commit`
- **Current state:** No hook exists (`.git/hooks/pre-commit` missing), and no tracked source file exists anywhere in the repo.
- **Target state:** Content-boundary guard that blocks project-specific standards in locked files.
- **Delta:** Because `.git/hooks/` is not versioned, add a tracked hook source/template and a setup/materialization path; otherwise this deliverable cannot ship reliably.
- **Risk level:** High.

### 6. `docs/STANDARDS.md`
- **Current state:** File already exists and already documents the intended agnostic/template architecture, config fragment responsibility, and pre-commit guard (`docs/STANDARDS.md:29-40`, `81-88`), but git status shows it is untracked.
- **Target state:** Tracked project standards file included in the release.
- **Delta:** Add the existing file to git; optionally update the file structure block to mention `workspace/MEMORY.md`, the hook source/template, and `sdd/templates/standards.md.in` if those are added.
- **Risk level:** Low.

### 7. `sdd/templates/standards.md.in`
- **Current state:** Missing; `sdd/templates/` only contains `apply/design/explore/spec/state/tasks/verify` templates.
- **Target state:** New template for project standards in newly created repos.
- **Delta:** Create `sdd/templates/standards.md.in` and decide where it is referenced (installer, docs, or SDD scaffolding flow), because no current file points to it.
- **Risk level:** Medium.

### 8. `sdd/orchestrator-flow.md`
- **Current state:** Spawn anatomy is still model-driven (`"model": ...`), with no `agentId` requirement, and the pre-flight/phase steps do not explicitly read `{project}/docs/STANDARDS.md` before assembling task strings (`sdd/orchestrator-flow.md:15-31`, `78-124`, `165-202`, `224-288`).
- **Target state:** Orchestrator doc should enforce project-standards loading plus `agentId`-based spawning, matching the new AGENTS rules.
- **Delta:** Update spawn examples/instructions from manual `model` selection to `agentId`, add explicit standards-loading steps before task assembly, and keep task-string guidance consistent.
- **Risk level:** High.

### 9. `install.sh`
- **Current state:** Good news: if `workspace/MEMORY.md` is added, Step 4 will already seed it because it copies every top-level `workspace/*.md` file (`install.sh:1043-1097`). Gaps remain: AGENTS rewriting depends on sentinels (`install.sh:472-505`, `1055-1060`), there is no hook installation, and the TUI model wizard updates docs state rather than config/runtime state (`README.md:35`, `62`, `84`; `install.sh:529-760`).
- **Target state:** Installer should seed the new templates cleanly and, if required by release scope, install/materialize the content-boundary hook and align any phase customization with `config/agent-fragment.json5`.
- **Delta:** Review at least these points:
  - remove/adapt AGENTS sentinel rewriting
  - add hook setup if the hook is meant to exist after install/clone
  - decide whether TUI model customization survives; if yes, it must mutate config, not just AGENTS text
  - confirm no extra change is needed for `workspace/MEMORY.md` seeding
- **Risk level:** High.

## Recommendations

1. **Treat this release as a consistency pass, not only a file copy.** Replacing AGENTS/TOOLS without updating `install.sh` and `agent-fragment.json5` will leave installer behavior and runtime behavior out of sync.
2. **Sanitize before copying LIVE files verbatim.** LIVE `TOOLS.md` and especially LIVE `MEMORY.md` still contain environment-specific or personal references; use them as structure/reference, not as drop-in release templates.
3. **Make `config/agent-fragment.json5` the real source of truth for SDD profiles.** If phase profiles are now enforced through `agents.list[]`, the installer/TUI should update that fragment or stop pretending to customize runtime behavior.
4. **Implement the hook through a tracked source file plus materialization step.** Shipping `.git/hooks/pre-commit` directly is fragile because git will not carry it.
5. **Add `docs/STANDARDS.md` in the same PR and update its file tree.** The file already describes the target architecture; tracking it closes part of the release gap immediately.
6. **Consider a follow-up doc pass on `README.md`.** Not a requested deliverable, but the current README still promises interactive SDD phase model configuration, which may become misleading once the new fixed `agentId` profiles land.
