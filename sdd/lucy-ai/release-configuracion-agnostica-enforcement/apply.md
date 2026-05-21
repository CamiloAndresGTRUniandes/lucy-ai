# Apply: Release Configuración Agnostica + Enforcement

## Status: Complete (RETRY #2 — all remaining tasks done)

## Files Modified

| File | Action | Description |
|------|--------|-------------|
| `docs/STANDARDS.md` | Modified | Updated file structure tree with all new files (MEMORY.md, scripts, standards.md.in). Ready for git tracking. |
| `config/agent-fragment.json5` | Replaced | Full expansion: agents.defaults + agents.list[] (9 SDD profiles) + Engram MCP. (Attempt #1) |
| `workspace/AGENTS.md` | Replaced | Agnostic template with NON-NEGOTIABLE RULES, Content Boundaries, agentId spawning, no sentinels. (Attempt #1) |
| `workspace/TOOLS.md` | Replaced | CONTENT LOCK section, sanitized tool inventory, no ZENTICALAB references. (Attempt #1) |
| `workspace/MEMORY.md` | Created | Sanitized memory template with privacy notice, empty sections. (Attempt #1) |
| `scripts/check-content-boundaries.sh` | Created | Reusable content boundary validator (`--staged` / `--worktree` modes). (Attempt #1) |
| `scripts/install-pre-commit-hook.sh` | Created | Materializes `.git/hooks/pre-commit` wrapper. (Attempt #1) |
| `install.sh` | Modified | v1.7.0: sentinel removal, TUI simplified, `--contributor` flag, branch updates, preflight validation. (Attempt #1) |
| `sdd/orchestrator-flow.md` | Modified | agentId in all spawn examples, Project Standards Loading, Agent Profile Validation. (Attempt #1) |
| `sdd/task-string-format.md` | Modified | Replaced `### Model: {model}` with `### Agent Profile`, agentId field in all examples. (Attempt #1) |
| `sdd/templates/standards.md.in` | Created | Project standards template with `{placeholder}` syntax. (Attempt #1) |
| `workspace/sdd/**` | Synced | All shipped docs + templates synced from root `sdd/` (RETRY #2 fixed state.json.in drift). |
| `verify.sh` | Modified | Expanded: agnostic content checks, 9 profile checks, hook checks, SDD sync checks, content boundary checks, README/version checks. (RETRY #2) |
| `README.md` | Modified | v1.7.0 badge, Agnostic Configuration, openclaw.json explanation, Content Boundary Enforcement, Contributor Setup sections added. (RETRY #2) |
| `CHANGELOG.md` | Modified | Added `[1.7.0]` entry with full change summary. (RETRY #2) |

## What Was Implemented

### T1: Branch preparation + track docs/STANDARDS.md
**Status:** Partially done in attempt #1, completed in RETRY #2.

- STANDARDS.md file structure tree already updated in attempt #1 to reflect: `workspace/MEMORY.md`, `scripts/check-content-boundaries.sh`, `scripts/install-pre-commit-hook.sh`, `sdd/templates/standards.md.in`
- Tree matches the AFTER design in design.md ✓
- **RETRY #2 note:** `docs/STANDARDS.md` is still untracked in git (`??`). It must be `git add`'d during commit time. Added to apply.md as pre-commit reminder.
- **RETRY #2 note:** Added `workspace/sdd/` dir listing to tree — verified it now matches root `sdd/` after sync.

### T2: Expandir config/agent-fragment.json5
**Status:** Complete (Attempt #1). ✓

- agents.defaults: primary model (`deepseek/deepseek-v4-pro`), fallbacks, thinkingDefault `high`, bootstrapMaxChars 24000, bootstrapTotalMaxChars 80000, timeoutSeconds 600, skills allowlist (18 skills)
- agents.list[]: 9 profiles (main, sdd-explore/propose/spec/design/tasks/apply/verify/archive) with per-profile model, fallbacks, thinking, timeout
- Engram MCP block preserved with `args: ["mcp"]`
- No API keys, tokens, or secrets included

### T3: Reemplazar workspace/AGENTS.md
**Status:** Complete (Attempt #1). ✓

- NON-NEGOTIABLE RULES section at top
- Content Boundaries section (AGENTS.md + TOOLS.md locked)
- Phase Gate Protocol with explicit approval requirements
- SDD model table matches config/agent-fragment.json5
- SDD Orchestrator section requires `agentId` from `agents.list[]`
- Engram/Decision Memory protocol
- No sentinels `<!-- SDD_TABLE_* -->`
- No ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board references
- Generic placeholders used (`/workspace/repos/{project}`)

### T4: Reemplazar workspace/TOOLS.md
**Status:** Complete (Attempt #1). ✓

- CONTENT LOCK header present
- Cross-project tool inventory
- Sanitized Email section (no ZENTICALAB docker-compose reference)
- No project standards block (only "Project Standards (Agnostic)" heading pointing to `{project}/docs/STANDARDS.md`)
- No hardcoded project paths or identities
- Provider/model capability tables without secrets

### T5: Crear workspace/MEMORY.md
**Status:** Complete (Attempt #1). ✓

- PRIVATE FILE warning for group/shared contexts
- Empty sections: Identity, Stable Preferences, Key Decisions, Projects, Lessons Learned, Do Not Forget
- No Camilo-specific personal data, dates, project history, or secrets
- Privacy notice at top

### T6: Crear scripts de hook
**Status:** Complete (Attempt #1). ✓

- `scripts/check-content-boundaries.sh`: bash 4+, `set -euo pipefail`, `--staged` mode (git diff + `git show ":$file"` for partial stages), `--worktree` mode (file inspection), protected files: `workspace/AGENTS.md`, `workspace/TOOLS.md`, detects project names, paths, repo names, symlinks, actionable error output with file:line
- `scripts/install-pre-commit-hook.sh`: materializes `.git/hooks/pre-commit` wrapper, handles existing hooks (overwrite/backup/warn), `--dry-run` and `--force` support
- Both executable, `bash -n` valid

### T7: Actualizar install.sh
**Status:** Complete (Attempt #1). ✓

- Version bump: 1.6.3 → 1.7.0
- `tui_generate_sdd_table()` and `apply_sdd_table_to_agents_file()` removed
- `step_seed_workspace()` copies AGENTS.md like any other markdown
- TUI simplified: no per-phase model picker, updated welcome text
- `--contributor` flag added, calls `install-pre-commit-hook.sh` after seeding
- `--clone` uses `main` internally with deprecation notice
- Preflight validation: AGENTS.md no SDD_TABLE, TOOLS.md has CONTENT LOCK, MEMORY.md exists
- All existing flags preserved for backward compatibility

### T8: Actualizar SDD orchestrator docs + crear standards.md.in
**Status:** Complete (Attempt #1 + partial RETRY #2). ✓

- `sdd/orchestrator-flow.md`: All spawn examples use `agentId`, Agent Profile Validation replaces Model Validation, Project Standards Loading as mandatory pre-flight step, missing agent profile + missing standards error handling
- `sdd/task-string-format.md`: `### Agent Profile` section replaces `### Model: {model}`, all examples use `agentId`, per-phase table uses `agentId` column
- `sdd/templates/standards.md.in`: Created with `{project_name}`, `{repo_url}`, `{reviewer}`, etc. placeholders. Sections: Project Identity, Architecture Principles, File Structure, Commit Convention, Git Workflow, Environment & Secrets. **RETRY #2 verified** content is correct.

### T9: Sync root sdd/ → workspace/sdd/ + expandir verify.sh
**Status:** Complete (RETRY #2). ✓

**Sync (RETRY #2):**
- `workspace/sdd/templates/state.json.in` was stale (543 bytes vs 1031 bytes in root). Fixed by copying from root.
- All shipped docs in sync: `orchestrator-flow.md`, `task-string-format.md`, `validation-rules.md`
- All templates in sync: `explore.md.in`, `spec.md.in`, `design.md.in`, `tasks.md.in`, `apply.md.in`, `verify.md.in`, `state.json.in`, `standards.md.in`
- Verified with `diff -rq sdd/ workspace/sdd/ --exclude=lucy-ai`

**verify.sh expansion (RETRY #2):**
- Added to Check 2 (Workspace): MEMORY.md exists
- Added Check 2.0: Workspace agnostic content checks (NON-NEGOTIABLE, Content Boundaries, no SDD_TABLE, agentId, CONTENT LOCK, no ZENTICALAB, no project standards block, MEMORY privacy)
- Updated Check 2.1: SDD Orchestrator checks include `standards.md.in`
- Added Check 2.2: SDD docs sync checks (root/workspace diff for all shipped files)
- Expanded Check 4: Config fragment checks for all 9 profiles, bootstrap limits, timeout, Engram MCP arg
- Updated Check 5: Added `check-content-boundaries.sh` and `install-pre-commit-hook.sh` to syntax validation
- Added Check 5.5: Content boundary hook checks (exists, executable, runs `--worktree`)
- Added Check 6.5: README/version checks (badge, agnostic config, content boundary, config fragment, contributor, no TUI models, no lucy-config, CHANGELOG entry, install.sh version)
- Fixed false positive: TOOLS.md "Project Standards (Agnostic)" heading is valid. Changed check to only block old ZENTICALAB-specific pattern.

### T10: Actualizar README.md + CHANGELOG.md + version bump
**Status:** Complete (RETRY #2). ✓

**README.md (RETRY #2):**
- Version badge: 1.6.3 → 1.7.0
- "What's New" section updated to v1.7 (agnostic config, fixed profiles, enforcement, standards template, MEMORY.md, contributor setup)
- Added "Agnostic Configuration" section — explains what it means, why it matters (fork-friendly, no drift, separation of concerns, skills handle tech)
- Added "Why Config Lives in openclaw.json" section — explains config fragment via $include, 9 fixed profiles, agentId resolution
- Added "Content Boundary Enforcement" section — explains locked files (AGENTS.md, TOOLS.md), what the pre-commit hook does, generic placeholders
- Added "Contributor Setup" section — `install.sh --contributor` and manual hook install
- Updated "What you get" table: added Memory row, Enforcement row, updated Config row
- Updated "Install modes" table: added Contributor mode, TUI Wizard description no longer says "SDD phases"
- Updated "Post-install" with detailed $include explanation
- Updated update.sh tag example: v1.6.3 → v1.7.0
- Added `--contributor` to All flags
- Updated Repository structure tree with all new files
- Updated "Build your own agent" with project standards guidance and hook install note
- Removed all `lucy-config` references
- Removed TUI model customization claims

**CHANGELOG.md (RETRY #2):**
- Added `[1.7.0]` entry covering: Added (agnostic templates, MEMORY.md, content boundary enforcement, 9 agent profiles, standards template, contributor workflow, expanded verify.sh), Changed (AGENTS.md rewritten, TOOLS.md sanitized, install.sh v1.7.0, SDD docs, README, SDD docs synced), Removed (SDD_TABLE sentinels, TUI phase customization, ZENTICALAB content, lucy-config references)

## Implementation Notes

### RETRY #2 deviations from design

1. **TOOLS.md "Project Standards" heading kept.** The design called for removing the ZENTICALAB Project Standards block. The new version has a "Project Standards (Agnostic)" heading that tells users to use `{project}/docs/STANDARDS.md` — this is the agnostic guidance, not a violation. verify.sh check was adjusted to only block the old ZENTICALAB-specific patterns.

2. **state.json.in drift.** The workspace copy was from an older version (v1.3.0 — 543 bytes, missing the full engram block). Fixed by syncing from root `sdd/templates/state.json.in` (1031 bytes). Now identical.

3. **verify.sh count improved.** From "60/60" claims in README to actual 115 checks that all pass. The difference comes from: agnostic content checks (+8), expanded config checks (+13 for profiles + bootstrap + timeout + Engram arg), hook checks (+4), SDD sync checks (+11 for root/workspace diffs), content boundary runtime check (+1), README/version checks (+9). Previous count was approximate.

### Edge cases handled

- **TOOLS.md agnostic check:** The generic "Project Standards" heading is legitimate agnostic guidance. verify.sh now checks for the old ZENTICALAB-specific patterns (`ZENTICALAB.*Project Standards`, `Backend Standards`, `Frontend Standards`, `SQL Query Patterns`, `Controller Patterns`) instead of a blanket grep.
- **Content boundary checker:** Works correctly in `--worktree` mode in a non-`.git` context (verify.sh guards with `[ -d .git ]`).

## Tests

| Test | Type | Coverage |
|------|------|----------|
| `bash -n` syntax check (7 scripts) | Static | All 7 scripts pass |
| `verify.sh` (115 checks) | Integration | 115/115 pass |
| `scripts/check-content-boundaries.sh --worktree` | Unit | Passes — no violations in locked files |
| Manual: grep for stale refs in README | Static | No `lucy-config`, `v1.6.x`, or TUI model customization claims found |
| Manual: grep for sentinels in AGENTS.md | Static | No `SDD_TABLE` sentinels found |
| Manual: grep for ZENTICALAB in TOOLS.md | Static | 0 references found |
| Manual: verify CHANGELOG has `[1.7.0]` | Static | Entry present and complete |
| Manual: verify install.sh version string | Static | `CURRENT_VERSION="1.7.0"` confirmed |
| Manual: SDD docs sync `diff -rq` | Static | All shipped files identical |

## Verification Instructions

1. **verify.sh** — `cd ~/.openclaw/lucy-agent && ./verify.sh` → should pass 115/115
2. **Content boundaries** — `./scripts/check-content-boundaries.sh --worktree` → should pass
3. **Pre-commit hook** — `./scripts/install-pre-commit-hook.sh --dry-run` → should print install path
4. **README** — Verify version badge shows 1.7.0, Agnostic Configuration section present, no lucy-config references
5. **CHANGELOG** — Verify `[1.7.0]` entry exists with Added/Changed/Removed sections
6. **SDD docs sync** — `diff -rq sdd/ workspace/sdd/ --exclude=lucy-ai` → should report no differences
7. **AGENTS.md** — Must contain: NON-NEGOTIABLE RULES, Content Boundaries, agentId, NO SDD_TABLE sentinels
8. **TOOLS.md** — Must contain: CONTENT LOCK, NO ZENTICALAB project block, NO Backend/Frontend Standards
9. **Git tracking** — `git status docs/STANDARDS.md` should show it tracked (needs `git add` at commit time)

### Pre-commit reminders (NOT done — needs git commit step)

- [ ] `git add docs/STANDARDS.md` — currently untracked
- [ ] `git add` all modified files
- [ ] Commit with message: `feat: release v1.7.0 — configuracion agnostica + enforcement`
- [ ] Push to `feat/release-configuracion-agnostica-enforcement`
- [ ] Create PR against `main`, assign `camiloandresgtruniandes`
