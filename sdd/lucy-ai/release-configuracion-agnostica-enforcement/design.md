# Design: Release Configuración Agnostica + Enforcement

## Status: Draft

## Architecture Decisions

| Decision | Choice | Rationale | Alternative Rejected |
|----------|--------|-----------|---------------------|
| Release shape | Ship as one atomic v1.7.0 release | The feature is a consistency release across templates, config, installer, docs, and verification. Shipping only one surface leaves users with drift and weak enforcement. | Split into multiple PRs/releases; rejected because enforcement and config would lag behind template changes. |
| Template source | Use LIVE workspace as reference, but sanitize into repo templates instead of copying verbatim | LIVE AGENTS/TOOLS/MEMORY contain the target structure, but TOOLS still has a ZENTICALAB email-path leak and MEMORY contains personal/project history. | Blind copy from LIVE workspace; rejected due to personal data and project-specific leakage. |
| SDD config source of truth | `config/agent-fragment.json5` owns fixed SDD profiles via `agents.list[]` | Runtime behavior should be in OpenClaw config, not generated prose inside AGENTS.md. This makes `agentId` profiles enforceable and avoids duplicated model tables. | Continue installer-generated SDD table in AGENTS.md; rejected because it is documentation-only and depends on sentinels no longer present. |
| Installer SDD customization | Remove AGENTS sentinel rewriting and simplify TUI to install-mode/components only | The new AGENTS template has no `<!-- SDD_TABLE_* -->` markers, and phase model customization conflicts with fixed `agentId` profiles. | Keep TUI phase picker and update AGENTS text; rejected because it produces drift between docs and runtime config. |
| Hook packaging | Add tracked checker + installer script: `scripts/check-content-boundaries.sh` and `scripts/install-pre-commit-hook.sh` | `.git/hooks/pre-commit` cannot be versioned. A tracked checker keeps hook and CI verification DRY; the installer script materializes the local hook. | Commit `.git/hooks/pre-commit` directly; rejected because git will not ship hooks. |
| Hook install mode | Install hook only for contributors via `install.sh --contributor` or manual `scripts/install-pre-commit-hook.sh` | End users do not need repo contributor hooks. Contributors need enforcement before commits. Optional install preserves normal install UX. | Always install hook during every user install; rejected because non-contributors may not have/need a writable repo hook. |
| SDD docs drift | Treat root `sdd/` as authoring source of truth and sync `workspace/sdd/` from it before release, excluding active cycle outputs | `install.sh` ships `workspace/sdd/**`, but contributors edit root `sdd/**`. Root-as-source preserves normal authoring while ensuring installed workspace receives current docs/templates. | Edit both trees manually; rejected because it caused current drift and will regress. |
| README scope | README is in-scope for v1.7.0 | Camilo explicitly requested documenting agnostic config, why config lives in `openclaw.json`, and enforcement benefits. | Leave README mostly untouched; rejected because users would not understand the major release value. |
| Verification | Expand `verify.sh` and reuse `scripts/check-content-boundaries.sh` for agnostic checks | Verification must catch the exact regressions this release fixes: stale templates, sentinels, missing profiles, and project-specific locked content. | Rely on manual review only; rejected because content-boundary drift is easy to reintroduce. |
| Branch naming | `main` como única rama de instalación. `clone` y `lucy-config` deprecados con migración silenciosa a `main`. | Con templates agnósticos, `main` entrega el mismo workspace que usaba `clone` — mantener dos ramas idénticas es overhead innecesario. `install.sh` acepta `--clone` por compatibilidad pero usa `main` internamente. `update.sh` migra `.version` de `clone`/`lucy-config` → `main`. | Mantener `clone` como rama separada; rechazado porque con la release agnóstica ambos branches entregarían contenido idéntico. |

## File Structure Design

### BEFORE

```text
lucy-ai/
├── install.sh                         # v1.6.3, AGENTS sentinel rewrite + SDD TUI model picker
├── update.sh                          # existing updater; may still read installed branch from .version
├── verify.sh                          # smoke checks; no agnostic/enforcement assertions
├── README.md                          # v1.6 docs; advertises TUI phase model customization
├── CHANGELOG.md                       # latest entry v1.6.3
├── config/
│   └── agent-fragment.json5           # minimal defaults + Engram MCP, no agents.list[]
├── docs/
│   └── STANDARDS.md                   # exists locally, currently untracked
├── scripts/
│   └── common.sh                      # shared helpers only
├── sdd/                               # authoring docs/templates
│   ├── orchestrator-flow.md           # model-based spawn examples
│   ├── task-string-format.md          # Model field, no agentId field
│   ├── validation-rules.md
│   └── templates/
│       ├── apply.md.in
│       ├── design.md.in
│       ├── explore.md.in
│       ├── spec.md.in
│       ├── state.json.in
│       ├── tasks.md.in
│       └── verify.md.in
└── workspace/                         # shipped workspace seed
    ├── AGENTS.md                      # old template with SDD_TABLE sentinels
    ├── TOOLS.md                       # contains ZENTICALAB standards block
    ├── SOUL.md
    ├── IDENTITY.md
    ├── USER.md
    ├── HEARTBEAT.md
    └── sdd/                           # shipped SDD docs/templates; drifted from root sdd/
```

### AFTER

```text
lucy-ai/
├── install.sh                         # v1.7.0, no AGENTS sentinel rewrite, optional --contributor hook install
├── update.sh                          # unchanged unless branch alias migration requires lucy-config -> clone mapping
├── verify.sh                          # expanded agnostic/config/hook checks
├── README.md                          # v1.7.0 docs for agnostic config + enforcement + config fragment
├── CHANGELOG.md                       # new [1.7.0] entry
├── config/
│   └── agent-fragment.json5           # agents.defaults + agents.list[] + Engram MCP
├── docs/
│   └── STANDARDS.md                   # tracked, file tree updated
├── scripts/
│   ├── common.sh
│   ├── check-content-boundaries.sh    # NEW: reusable locked-file validator
│   └── install-pre-commit-hook.sh     # NEW: materializes .git/hooks/pre-commit wrapper
├── sdd/                               # authoring source of truth
│   ├── orchestrator-flow.md           # agentId enforcement + Project Standards Loading
│   ├── task-string-format.md          # agentId-aware task format
│   ├── validation-rules.md
│   └── templates/
│       ├── apply.md.in
│       ├── design.md.in
│       ├── explore.md.in
│       ├── spec.md.in
│       ├── standards.md.in            # NEW: project standards template
│       ├── state.json.in
│       ├── tasks.md.in
│       └── verify.md.in
└── workspace/                         # installed workspace seed
    ├── AGENTS.md                      # replaced with agnostic locked template, no sentinels
    ├── TOOLS.md                       # replaced with agnostic locked template, no project standards
    ├── MEMORY.md                      # NEW: sanitized long-term memory template
    ├── SOUL.md
    ├── IDENTITY.md
    ├── USER.md
    ├── HEARTBEAT.md
    └── sdd/                           # synced copy from root sdd/ docs/templates
```

### New files being added

- `workspace/MEMORY.md`
- `scripts/check-content-boundaries.sh`
- `scripts/install-pre-commit-hook.sh`
- `sdd/templates/standards.md.in`
- `workspace/sdd/templates/standards.md.in`

### Files being replaced

- `workspace/AGENTS.md` - replace old sentinel-based template with sanitized live-derived agnostic template.
- `workspace/TOOLS.md` - replace project-specific template with sanitized live-derived agnostic tool inventory.
- `config/agent-fragment.json5` - replace minimal fragment with full agent defaults/profile matrix.

### Files being modified

- `install.sh` - version bump, branch label updates, remove sentinel workflow, simplify TUI, add `--contributor`, call hook installer.
- `verify.sh` - add release invariants and content-boundary checks.
- `README.md` - document v1.7.0, agnostic configuration, config fragment, enforcement, and updated install modes.
- `CHANGELOG.md` - add v1.7.0 entry.
- `docs/STANDARDS.md` - update tree and release standards; add to git tracking.
- `sdd/orchestrator-flow.md` - agentId + Project Standards Loading.
- `sdd/task-string-format.md` - agentId field + standards-loading requirements.
- `workspace/sdd/**` - synced from root `sdd/**` after edits.
- Potentially `update.sh` - only if Apply confirms branch rename from `lucy-config` to `clone` requires migration support for existing `.version` files.

### Resolution for `sdd/` vs `workspace/sdd/` drift

- **Source of truth:** root `sdd/`.
- **Release rule:** after editing root `sdd/`, sync to `workspace/sdd/` using a deterministic copy step.
- **Exclusions:** do not copy active cycle artifacts under `sdd/lucy-ai/**`; only copy root docs and `sdd/templates/**`.
- **Verification:** `verify.sh` should compare root and workspace copies for the shipped files:
  - `orchestrator-flow.md`
  - `task-string-format.md`
  - `validation-rules.md`
  - every file in `sdd/templates/*.md.in`
- **Future improvement:** add a small `scripts/sync-workspace-sdd.sh` if this copy step becomes frequent. For v1.7.0, Apply can use `rsync`/`cp` and verify with `diff -qr`.

## Template Sanitization Strategy

### AGENTS.md

**Keep:**
- NON-NEGOTIABLE rules at the top.
- Repo path rule and SDD mandatory rule.
- Project Standards rule: standards live in `{project_root}/docs/STANDARDS.md`.
- Content Boundaries section for AGENTS.md + TOOLS.md.
- Phase Gate Protocol.
- SDD model table with fixed phase profiles and timeouts.
- SDD Orchestrator section requiring `agentId` from `agents.list[]`.
- Engram/Decision Memory protocol.
- Group chat, memory, safety, git branching, and heartbeat guidance.

**Change:**
- Replace literal project-owner assumptions with generic wording where possible.
- Keep "Lucy" branding because this repo ships Lucy, but avoid project-specific app standards.
- Ensure the model table matches `config/agent-fragment.json5` exactly.
- Remove references to sentinel generation; AGENTS is a static template now.
- If examples mention project paths, use placeholders like `/workspace/repos/{project}` only.

**Remove:**
- `<!-- SDD_TABLE_START -->` / `<!-- SDD_TABLE_END -->` sentinels.
- Any app-specific architecture standards, DTO rules, SQL rules, Angular component rules, or commit format for a particular project.
- Any references to ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board, backend/frontend repo names, or hardcoded project paths.

### TOOLS.md

**Keep:**
- CONTENT LOCK header.
- Cross-project tool inventory.
- General OpenClaw/Gateway/Engram notes.
- Repo path warning if phrased generically.
- Project Standards guidance pointing to `{project}/docs/STANDARDS.md`.
- "What goes here" list for environment-specific notes.

**Change:**
- Sanitize the live Email section. Do not say the Gmail app password lives in ZENTICALAB docker-compose. Replace with generic wording: "Auth is configured outside this repo; never commit app passwords."
- Avoid embedding real API key prefixes, bot token fragments, or personal OAuth identities in the release template. Use placeholders or capability descriptions instead.
- Keep provider/model capability tables only if they do not expose secrets.

**Remove:**
- Entire ZENTICALAB Project Standards block.
- Project identities, local repo paths, backend/frontend paths, stack-specific architecture standards, review checklists, and commit conventions.
- Any instruction that belongs in project `docs/STANDARDS.md` or a skill.

### MEMORY.md

**Template structure design:**

```markdown
# MEMORY.md - Long-Term Memory

## Identity
- Name:
- Human/User:
- Role:
- Preferred tone:

## Stable Preferences
- Communication preferences
- Workflow preferences
- Safety/security preferences

## Key Decisions
- [Date] Decision title - short rationale

## Projects
- Project name - repo/path/docs pointer

## Lessons Learned
- Date - lesson

## Do Not Forget
- Durable reminders only; no secrets
```

**Rules:**
- Do not copy live MEMORY.md verbatim.
- No Camilo-specific personal history, project list, dates, or private lessons.
- No secrets, tokens, OAuth identities, bot tokens, app passwords, or private emails.
- Include comments explaining that `MEMORY.md` is private and should not be loaded in group/shared contexts.

## Config Fragment Design

Updated `config/agent-fragment.json5` should be the installable config source for OpenClaw via `$include`.

### agents.defaults block

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "deepseek/deepseek-v4-pro",
        fallbacks: ["deepseek/deepseek-v4-flash"]
      },
      thinkingDefault: "high",
      workspace: "~/.openclaw/workspace",
      bootstrapMaxChars: 24000,
      bootstrapTotalMaxChars: 80000,
      timeoutSeconds: 600,
      skills: [
        "sdd",
        "csharp-dotnet",
        "dotnet10-csharp14",
        "typescript",
        "tailwind-4",
        "angular-core",
        "angular-architecture",
        "angular-forms",
        "angular-performance",
        "zenticalab-security",
        "zenticalab-pr-review",
        "github-pr",
        "github",
        "gh-issues",
        "browser-automation",
        "weather",
        "healthcheck",
        "skill-creator"
      ]
    },
    list: [ /* profiles below */ ]
  },
  mcp: { /* Engram block */ }
}
```

Notes:
- Use `~/.openclaw/workspace` rather than `/home/node/...` in the template for portability.
- If OpenClaw does not expand `~` for `agents.defaults.workspace`, Apply should either omit `workspace` or have installer materialize `${HOME}/.openclaw/workspace` into the fragment. Do not hardcode `/home/node`.
- Do not include API keys, OAuth emails, bot tokens, or provider secrets in the fragment.

### agents.list[] design

The list has 9 profiles:

| id | default | primary | fallbacks | thinkingDefault | timeoutSeconds |
|----|---------|---------|-----------|-----------------|----------------|
| `main` | true | `deepseek/deepseek-v4-pro` | `deepseek/deepseek-v4-flash` | `high` | 600 |
| `sdd-explore` | false | `openai-codex/gpt-5.4` | `deepseek/deepseek-v4-pro` | `high` | 1200 |
| `sdd-propose` | false | `deepseek/deepseek-v4-pro` | `openai-codex/gpt-5.4` | `high` | 900 |
| `sdd-spec` | false | `deepseek/deepseek-v4-flash` | `openai-codex/gpt-5.4` | `high` | 900 |
| `sdd-design` | false | `openai-codex/gpt-5.5` | `deepseek/deepseek-v4-pro` | `high` | 1200 |
| `sdd-tasks` | false | `deepseek/deepseek-v4-flash` | `openai-codex/gpt-5.4` | `high` | 900 |
| `sdd-apply` | false | `deepseek/deepseek-v4-pro` | `openai-codex/gpt-5.4` | `high` | 1200 |
| `sdd-verify` | false | `openai-codex/gpt-5.3-codex` | `deepseek/deepseek-v4-flash` | `high` | 1200 |
| `sdd-archive` | false | `openai-codex/gpt-5.4-mini` | `openai-codex/gpt-5.4` | `low` | 600 |

Each profile should be addressable by `agentId`. AGENTS.md and orchestrator docs must reference these IDs, not manual model strings.

### MCP block - Engram preservation

Use the live runtime shape unless Apply confirms a different fragment shape is required:

```json5
mcp: {
  servers: {
    engram: {
      command: "~/.local/bin/engram",
      args: ["mcp"]
    }
  }
}
```

Preserve Engram because SDD phases depend on technical memory context and decision persistence. Do not include `ENGRAM_HOME` unless needed for compatibility with the installed Engram layout.

## Pre-commit Hook Design

### Source file location

- `scripts/check-content-boundaries.sh` - reusable validator with two modes:
  - `--staged`: inspect staged content for pre-commit.
  - `--worktree`: inspect repository files for verify/CI.
- `scripts/install-pre-commit-hook.sh` - materializes `.git/hooks/pre-commit` as a thin wrapper that calls `scripts/check-content-boundaries.sh --staged`.

### Hook logic

Protected files:
- `workspace/AGENTS.md`
- `workspace/TOOLS.md`

Optional verification-only scan:
- `workspace/MEMORY.md` for secrets/personal placeholders only, not content-boundary standards.

The checker should:
1. Use `git diff --cached --name-only --diff-filter=ACMR` for staged mode.
2. Intersect staged files with protected files.
3. For each protected file, read staged content via `git show ":$file"` so partial stages are handled correctly.
4. Reject symlinked protected files (`git ls-files -s` mode `120000`) because locked templates must be regular files.
5. Scan staged content with explicit regex groups:
   - Project names: `ZENTICALAB`, `BE_ZENTICALAB`, `FE_ZENTICALAB`, `excel-pipeline`, `ssdp-ai`, `kudos-board`.
   - Project standards headings: `Backend Standards`, `Frontend Standards`, `SQL Query Patterns`, `Controller Patterns`, `DTOs`, `PostgreSQL schema-per-tenant`.
   - Project paths: `/workspace/repos/(ZENTICALAB|excel-pipeline|ssdp-ai|kudos-board)[^[:space:]]*`, `/home/node/.openclaw/workspace/(ZENTICALAB|excel-pipeline|ssdp-ai|kudos-board)[^[:space:]]*`.
   - Repo names: `CamiloAndresGTRUniandes/(BE_ZENTICALAB|FE_ZENTICALAB|excel-pipeline|ssdp-ai|kudos-board)`.
6. Allow generic placeholders like `/workspace/repos/{project}` and `{project}/docs/STANDARDS.md`.

### Installation mechanism in install.sh

- Add flag: `--contributor`.
- Add variable: `CONTRIBUTOR_MODE=false`.
- In parse flags: set `CONTRIBUTOR_MODE=true`.
- After `step_clone_or_update_repo` and before/after workspace seeding, call:
  ```bash
  if $CONTRIBUTOR_MODE; then
    bash "$LUCY_DIR/scripts/install-pre-commit-hook.sh"
  fi
  ```
- Also document manual usage:
  ```bash
  ./scripts/install-pre-commit-hook.sh
  ```

The materialized `.git/hooks/pre-commit` should be a wrapper, not duplicated logic:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
exec "$repo_root/scripts/check-content-boundaries.sh" --staged
```

### Error messages format

Use actionable, line-oriented output:

```text
✗ Content boundary violation in workspace/TOOLS.md
  Locked files must stay project-agnostic.

  Line 51: matched project name "ZENTICALAB"
  Line 72: matched project standards heading "Backend Standards"

Move project-specific standards to docs/STANDARDS.md in the relevant project repo.
If this is a false positive, use a generic placeholder like {project} or update the checker pattern intentionally.
```

## Installer Changes Design

### Sentinel removal strategy in install.sh

Remove or neutralize these flows:
- `tui_generate_sdd_table()`
- `apply_sdd_table_to_agents_file()`
- AGENTS special-case temp copy in `step_seed_workspace()`
- log line: `AGENTS.md: prepared SDD model table (...)`

`step_seed_workspace()` should copy `AGENTS.md` like any other markdown file. Conflict detection remains checksum-based.

### TUI alignment strategy

Minimal change, not full redesign:
- Keep TUI for install mode and optional components.
- Remove per-phase model picker screens.
- Update welcome text from "configure SDD phase models" to "review fixed SDD agent profiles and choose install components."
- Update confirmation screen to remove "Customized phases" and "Manual placeholders."
- If showing SDD profile info, render a read-only summary from static defaults or from `config/agent-fragment.json5`; do not write AGENTS.md.

Text prompt mode should also remove "lucy-config branch" wording and use `clone`.

### Hook materialization path

- Contributor mode: `install.sh --contributor` installs/updates `.git/hooks/pre-commit` in the cloned lucy-ai repo.
- Manual mode: contributor runs `scripts/install-pre-commit-hook.sh`.
- Dry run: print `[DRY-RUN] Would install pre-commit hook` and do not write.
- Existing hook handling:
  - If no hook exists: create wrapper.
  - If existing hook matches lucy-ai wrapper: overwrite/update.
  - If existing hook differs: write `.git/hooks/pre-commit.lucy-ai` and warn, unless `--force` then replace after backing up to `.git/hooks/pre-commit.backup.<timestamp>`.

### Backward compatibility guarantees

- Existing install flags remain accepted: `--clone`, `--template`, `--tag`, `--no-tui`, `--accept-defaults`, etc.
- `workspace/MEMORY.md` is created only if missing; if a user already has a personal `MEMORY.md`, normal conflict prompt/`--force` behavior applies. For update scenarios, do not silently overwrite personal memory.
- `AGENTS.md` updates are normal template conflicts; no sentinel dependency remains.
- `--clone` should target `clone`. For legacy compatibility, if remote `clone` is unavailable, installer can warn and fall back to `lucy-config` for one release cycle, or fail with a clear migration message. Preferred: create `clone` branch before release and keep `lucy-config` as legacy alias until v1.8.0.
- `update.sh` remains unchanged unless branch migration requires mapping installed `.version` branch `lucy-config` to `clone`.

## Orchestrator Docs Update Design

### Specific sections in `orchestrator-flow.md` to update

1. **Anatomía de un Spawn**
   - Replace `model: "..."` with `agentId: "sdd-{phase}"`.
   - Keep `label`, `context`, and timeout semantics.
   - State that model/fallback/thinking/timeout are resolved from `config/agent-fragment.json5`.

2. **Pre-spawn validation**
   - Rename from "Model Validation" to "Agent Profile Validation."
   - Validate required agent profile exists in `agents.list[]`.
   - Validate phase uses canonical `agentId` mapping.
   - Notify Camilo with resolved model after spawn, but do not pass manual model.

3. **Each delegated phase spawn block**
   - Explore: `agentId: "sdd-explore"`
   - Spec: `agentId: "sdd-spec"`
   - Design: `agentId: "sdd-design"`
   - Tasks: `agentId: "sdd-tasks"`
   - Apply: `agentId: "sdd-apply"`
   - Verify: `agentId: "sdd-verify"`

4. **Pre-flight / Step 0**
   - Add Project Standards Loading before task assembly.

5. **Checklist de Inicio**
   - Add: read `{project_root}/docs/STANDARDS.md`.
   - Add: fail/ask if standards file missing.
   - Add: inject standards summary into task string.

6. **Error handling**
   - Add missing agent profile failure.
   - Add missing project standards failure.

### agentId enforcement: spawn call change

Before:

```text
{
  "task": "## SDD Phase: design\n...",
  "label": "sdd-lucy-ai-design-1",
  "model": "openai-codex/gpt-5.5",
  "thinking": "high",
  "context": "fork",
  "runTimeoutSeconds": 1200
}
```

After:

```text
{
  "task": "## SDD Phase: design\n...",
  "label": "sdd-lucy-ai-design-1",
  "agentId": "sdd-design",
  "context": "fork"
}
```

The profile carries model, fallback, thinking, and timeout. Lucy may report the resolved profile to Camilo but should not manually choose model in the spawn request.

### Project Standards Loading

Add a mandatory pre-task step:

```text
project_root = resolve active repo root
standards_path = "$project_root/docs/STANDARDS.md"
if missing:
  abort phase and ask Camilo whether to create standards first
else:
  read standards_path
  inject relevant summary/path in task string under ### Standards
```

Exception: when the current feature is explicitly creating `docs/STANDARDS.md` or `sdd/templates/standards.md.in` for a new project, the task may proceed with a bootstrap standards template.

### `task-string-format.md` companion update

Although the requirement names `orchestrator-flow.md`, this release should update `task-string-format.md` too because it still includes `### Model: {model}`. Replace with:

```markdown
### Agent Profile
- agentId: {agentId}
- resolved model: {provider/model} (informational only)
- thinking: from agent profile
- timeout: from agent profile
```

## README Update Design

### New sections

1. **What's New in v1.7**
   - Agnostic workspace templates.
   - Fixed SDD agent profiles in config fragment.
   - Content-boundary enforcement.
   - Project standards template.

2. **Agnostic configuration**
   - Explain that AGENTS.md and TOOLS.md are project-agnostic.
   - Explain that project-specific standards belong in each repo's `docs/STANDARDS.md`.
   - Explain that fork users start with clean templates instead of Camilo/ZENTICALAB rules.

3. **Why OpenClaw config lives in `openclaw.json`**
   - `config/agent-fragment.json5` is included by `openclaw.json`.
   - Fixed profiles like `sdd-design` and `sdd-apply` make sub-agent routing predictable.
   - The model matrix is runtime config, not prose in AGENTS.md.

4. **Content boundary enforcement**
   - Explain locked files: `workspace/AGENTS.md`, `workspace/TOOLS.md`.
   - Explain pre-commit hook for contributors.
   - Explain benefit: prevents accidental project-specific rules leaking into global templates.

5. **Contributor setup**
   - `./scripts/install-pre-commit-hook.sh`
   - or `install.sh --contributor`

### Updated sections

- Version badge: `1.6.3` → `1.7.0`.
- "What you get":
  - Config row should mention fixed SDD agent profiles and bootstrap limits.
  - Add Enforcement row.
  - Add MEMORY.md template to Personality/Memory row.
- "Install modes":
  - TUI Wizard becomes "Guided install" for mode/components, not phase model customization.
  - Clone mode should reference `clone`, not `lucy-config`.
- "Post-install":
  - Explain `$include` more clearly and why users see config in `openclaw.json`.
  - Add note: restart gateway + `/new` reloads the agent profiles.
- "Repository structure":
  - Add `workspace/MEMORY.md`.
  - Add `scripts/check-content-boundaries.sh`.
  - Add `scripts/install-pre-commit-hook.sh`.
  - Add `sdd/templates/standards.md.in`.
- "Build your own agent":
  - Tell users to put project standards in their project repo, not AGENTS/TOOLS.
  - Mention pre-commit hook if they contribute changes to templates.

### What to remove or correct

- Remove/replace "Interactive TUI wizard - configure SDD phase models during installation."
- Remove/replace "TUI Wizard ... SDD phases, components, confirm."
- Replace `lucy-config` references with `clone`, except in a legacy migration note if needed.
- Replace tag examples from `v1.6.3` to `v1.7.0` after version bump.

## Security

### What the pre-commit hook checks

- Only staged content, not uncommitted working tree, in pre-commit mode.
- Protected files:
  - `workspace/AGENTS.md`
  - `workspace/TOOLS.md`
- Violations:
  - Known project names and repo names.
  - Known project-specific local paths.
  - Project-standard headings that belong in `docs/STANDARDS.md`.
  - Symlink replacement of protected files.
- The hook reports exact file and line number when possible.

### Edge cases

- **Merge commits:** Hook still runs. If no protected files are staged, pass. If merge introduces violations in protected files, fail.
- **Partial stages:** Use `git show ":$file"`; inspect the staged blob, not working tree. This avoids both false pass and false fail in partial commits.
- **Renames:** Use `--diff-filter=ACMR`; if a protected path is renamed into place, inspect it. If protected path is deleted, hook does not block deletion but verify/PR review should catch missing required files.
- **Symlinks:** Reject protected file symlinks because they could bypass content checks or point outside repo.
- **Binary files:** Not expected for markdown; if protected file is binary, reject.
- **False positives:** Prefer generic placeholders (`{project}`, `{repo}`, `/workspace/repos/{project}`) over real names. Emergency bypass via `git commit --no-verify` remains possible, but `verify.sh` should catch the violation before PR acceptance.

### What is NOT checked

- README may mention real repo owner/name because it documents this repository publicly.
- `docs/STANDARDS.md` may contain lucy-ai-specific standards by design.
- Skill files may contain technology-specific guidance by design.
- Personal user files outside repo are not scanned.
- Secrets scanning is not the primary hook purpose; existing no-secrets policies and review still apply.

## Error Handling

### 1. `install.sh` encounters a corrupted template

Examples:
- `workspace/AGENTS.md` missing NON-NEGOTIABLE section.
- `workspace/TOOLS.md` missing CONTENT LOCK.
- `workspace/MEMORY.md` missing required template header.

Design:
- Add lightweight preflight validation before seeding workspace:
  - AGENTS contains `NON-NEGOTIABLE RULES` and does not contain `SDD_TABLE_START`.
  - TOOLS contains `CONTENT LOCK` and does not contain `ZENTICALAB`.
  - MEMORY exists and contains template heading.
- If validation fails in official install: abort with clear message. Do not seed known-bad locked templates.
- `--dry-run` reports failure but does not write.

### 2. Pre-commit hook fails during editorial workflow

Design:
- Print exact file/line/pattern and remediation guidance.
- Contributor fixes staged content and retries.
- For intentional checker updates, contributor updates `scripts/check-content-boundaries.sh` and includes rationale in PR.
- Emergency bypass with `git commit --no-verify` is technically possible, but CI/`verify.sh` should fail until fixed.

### 3. `agent-fragment.json5` is malformed

Design:
- `verify.sh` performs structural grep checks at minimum: `agents:`, `defaults:`, `list:`, each required `id`, `bootstrapMaxChars`, `bootstrapTotalMaxChars`, and `engram:`.
- If a JSON5 parser is available in CI, add a parse check; do not make local install depend on Node/Python packages.
- If malformed after install, OpenClaw gateway restart may fail or ignore config. Recovery: restore prior tag (`./update.sh --tag v1.6.3`) or revert config fragment from git.

### 4. Hook materialization fails

Design:
- In `--contributor` mode: fail install with non-zero exit because requested contributor enforcement was not installed.
- In manual `scripts/install-pre-commit-hook.sh`: fail with actionable message: not a git repo, hooks directory unwritable, existing hook conflict.
- In normal install without `--contributor`: no hook install attempted; no failure.

### 5. Legacy branch `lucy-config` no longer exists

Design:
- Prefer creating/maintaining `clone` before releasing v1.7.0.
- Installer `--clone` uses `clone`.
- Optional compatibility: if `clone` fetch fails and `lucy-config` exists, warn and fall back once.
- Existing `.version` with branch `lucy-config` may require `update.sh` mapping to `clone`; decide in Apply after inspecting update behavior.

## Observability

### `verify.sh` expansion

Add checks under new sections:

**Workspace agnostic checks**
- `workspace/MEMORY.md exists`.
- `workspace/AGENTS.md has NON-NEGOTIABLE RULES`.
- `workspace/AGENTS.md has Content Boundaries`.
- `workspace/AGENTS.md has no SDD_TABLE sentinels`.
- `workspace/TOOLS.md has CONTENT LOCK`.
- `workspace/TOOLS.md has no ZENTICALAB/project standards block`.
- `scripts/check-content-boundaries.sh --worktree` passes.

**Config profile checks**
- `config/agent-fragment.json5 has agents.list`.
- Each profile ID exists: `main`, `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`.
- Bootstrap limits exist: `bootstrapMaxChars`, `bootstrapTotalMaxChars`.
- `timeoutSeconds` exists.
- Engram MCP has `engram:` and `args: ["mcp"]`.
- No `minimax` stale references.

**Hook checks**
- `scripts/check-content-boundaries.sh exists` and executable.
- `scripts/install-pre-commit-hook.sh exists` and executable.
- `bash -n` syntax check for both scripts.

**SDD docs sync checks**
- `sdd/templates/standards.md.in exists`.
- `workspace/sdd/templates/standards.md.in exists`.
- Root/workspace SDD shipped files have no diff.
- `sdd/orchestrator-flow.md` contains `agentId`.
- `sdd/orchestrator-flow.md` contains `Project Standards Loading`.

**README/version checks**
- README version badge mentions `1.7.0`.
- README mentions agnostic configuration.
- README mentions content boundary enforcement.
- README no longer says TUI configures SDD phase models.

### Validating templates are truly agnostic

- `scripts/check-content-boundaries.sh --worktree` is the canonical validator for locked files.
- `verify.sh` calls the same script to avoid duplicated regex logic.
- Additional broad grep for known project leaks across `workspace/AGENTS.md`, `workspace/TOOLS.md`, `workspace/MEMORY.md`:
  - `ZENTICALAB`
  - `BE_ZENTICALAB`
  - `FE_ZENTICALAB`
  - `/workspace/repos/ZENTICALAB`
  - `excel-pipeline`
  - `ssdp-ai`
  - `kudos-board`
- README and `docs/STANDARDS.md` are excluded from generic leak checks because they are allowed to document this repo and lucy-ai standards.

## Migration Plan

### Breaking changes for existing installs

- **AGENTS sentinels removed:** Existing AGENTS templates no longer support installer-generated SDD table replacement. This is intentional because runtime config moves to `agent-fragment.json5`.
- **TUI phase model customization removed/simplified:** Users no longer choose per-phase SDD models during install. Fixed profiles ship in config; users can manually edit `config/agent-fragment.json5` if they intentionally want a forked profile matrix.
- **`workspace/MEMORY.md` introduced:** New installs receive a template. Existing users with personal MEMORY.md should not be silently overwritten.
- **Branch name migration:** `--clone` should move from `lucy-config` language to `clone`. Existing installs may still have `.version` referencing `lucy-config`; support a transition path.
- **Config fragment expands:** Users who included the fragment receive more agent profiles and bootstrap limits after update. This is additive and should be backward-compatible.

### Rollback strategy if v1.7.0 causes issues

- Users can pin the previous stable release:
  ```bash
  cd ~/.openclaw/lucy-agent
  ./update.sh --tag v1.6.3
  ```
- If only config breaks, remove/comment the `$include` line in `~/.openclaw/openclaw.json` or restore the previous `config/agent-fragment.json5` from git.
- If workspace templates were overwritten with `--force`, restore from user git/history/backups if available. Installer should continue checksum conflict prompts by default to reduce accidental overwrites.
- For contributor hook issues, remove `.git/hooks/pre-commit` or run with `git commit --no-verify` temporarily; PR `verify.sh` remains the release gate.

### Deployment order

1. **Branch prep:** create/switch to `feat/release-configuracion-agnostica-enforcement` from updated `main`.
2. **Track standards:** add `docs/STANDARDS.md`; update its file tree for new files.
3. **Config first:** expand `config/agent-fragment.json5` so runtime SSOT exists before docs point to it.
4. **Templates:** replace/sanitize `workspace/AGENTS.md`, `workspace/TOOLS.md`, add `workspace/MEMORY.md`.
5. **Hook scripts:** add `scripts/check-content-boundaries.sh` and `scripts/install-pre-commit-hook.sh`.
6. **Installer:** remove sentinel/TUI phase customization, add `--contributor`, update clone branch wording and hook install path.
7. **SDD docs:** update root `sdd/orchestrator-flow.md`, `sdd/task-string-format.md`, add `sdd/templates/standards.md.in`.
8. **Sync workspace SDD:** copy updated root `sdd/` shipped docs/templates to `workspace/sdd/`.
9. **README/CHANGELOG/version:** update docs and version references to v1.7.0.
10. **Verification:** expand and run `verify.sh`, run `bash -n` on shell scripts, run content-boundary checker in worktree and staged modes.
11. **PR:** commit on feature branch, push, open PR to `main`, assign `camiloandresgtruniandes`.
12. **Post-merge:** tag `v1.7.0`; merge/cherry-pick to `clone`; keep legacy `lucy-config` alias only if needed for one transition cycle.
