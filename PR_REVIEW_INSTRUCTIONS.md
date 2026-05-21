# PR Review Instructions — lucy-ai #41
## feat: release v1.7.0 — configuracion agnostica + enforcement

> For: Copilot PR review
> PR: https://github.com/CamiloAndresGTRUniandes/lucy-ai/pull/41
> Base: `main` ← `feat/release-configuracion-agnostica-enforcement`
> Files: 29 changed (+3,498 / −1,107)

---

## 1. What This PR Does

Packages the agnostic workspace configuration into the installer templates, replacing old versions that contained ZENTICALAB-specific standards. Adds enforcement mechanisms to keep locked files (AGENTS.md, TOOLS.md) project-agnostic going forward.

## 2. Review Checklist — File by File

### workspace/AGENTS.md (replaced)
- [ ] Starts with `## ⛔ NON-NEGOTIABLE RULES` (not "Your Workspace")
- [ ] Contains Content Boundaries section (§6) explaining AGENTS.md + TOOLS.md are locked
- [ ] Contains Phase Gate Protocol with explicit approval requirements
- [ ] SDD table references `agentId` from `agents.list[]`, not manual model strings
- [ ] No `<!-- SDD_TABLE_START -->` / `<!-- SDD_TABLE_END -->` sentinels
- [ ] No references to: ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board, CamiloAndresGTRUniandes
- [ ] Project paths use placeholders like `/workspace/repos/{project}` not real paths

### workspace/TOOLS.md (replaced)
- [ ] Starts with `⛔️ CONTENT LOCK` header
- [ ] No ZENTICALAB Project Standards block (the entire L51-221 from old version is gone)
- [ ] No references to: Backend Standards, Frontend Standards, SQL Query Patterns, Controller Patterns
- [ ] Email section uses generic wording (no ZENTICALAB docker-compose path)
- [ ] Tool inventory present but without secrets, API keys, or tokens

### workspace/MEMORY.md (new)
- [ ] Privacy notice at top: "PRIVATE FILE — Only load in main sessions"
- [ ] Empty template sections: Identity, Stable Preferences, Key Decisions, Projects, Lessons Learned
- [ ] No personal data, real dates, project history, or references to Camilo
- [ ] Comment explaining MEMORY.md is private (no group/shared contexts)

### config/agent-fragment.json5 (replaced)
- [ ] `agents.defaults` includes: model (primary + fallbacks), thinkingDefault, bootstrapMaxChars, bootstrapTotalMaxChars, timeoutSeconds, skills (18 skills)
- [ ] `agents.list[]` has exactly 9 profiles: main, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive
- [ ] Each profile has: id, model (primary + fallbacks), thinkingDefault, timeoutSeconds
- [ ] Engram MCP block preserved with `args: ["mcp"]`
- [ ] No hardcoded API keys, tokens, OAuth emails, or secrets
- [ ] Uses `~/.openclaw/workspace` not `/home/node/...`

### scripts/check-content-boundaries.sh (new)
- [ ] Shebang: `#!/usr/bin/env bash`
- [ ] `set -euo pipefail` present
- [ ] Two modes: `--staged` (git diff inspection) and `--worktree` (file inspection)
- [ ] Protected files: `workspace/AGENTS.md`, `workspace/TOOLS.md`
- [ ] Detects: ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board, CamiloAndresGTRUniandes, absolute /workspace/repos/ paths
- [ ] Allows placeholders: `{project}`, `{repo}`
- [ ] Exit non-zero on violation with file:line output
- [ ] Handles: merge commits, partial stages (`git show ":$file"`), symlinks

### scripts/install-pre-commit-hook.sh (new)
- [ ] Shebang: `#!/usr/bin/env bash`
- [ ] `set -euo pipefail` present
- [ ] Three cases: no hook exists (create), matching hook (overwrite), different hook (backup + warn)
- [ ] `--force` flag to override existing hook
- [ ] `--dry-run` flag
- [ ] Materialized hook calls `check-content-boundaries.sh --staged`

### install.sh (modified)
- [ ] Version: `CURRENT_VERSION="1.7.0"` (not 1.6.3)
- [ ] Functions `tui_generate_sdd_table()` and `apply_sdd_table_to_agents_file()` REMOVED
- [ ] `step_seed_workspace()` no longer special-cases AGENTS.md
- [ ] TUI no longer offers per-phase model customization
- [ ] `--contributor` flag present, calls `install-pre-commit-hook.sh`
- [ ] `--clone` accepted but uses `main` internally with deprecation notice
- [ ] No `lucy-config` references remaining
- [ ] All existing flags preserved (`--template`, `--tag`, `--force`, etc.)
- [ ] Preflight validation: checks AGENTS.md has no sentinels, TOOLS.md has CONTENT LOCK, MEMORY.md exists

### sdd/orchestrator-flow.md (modified)
- [ ] Spawn anatomy uses `"agentId": "sdd-{phase}"` instead of `"model": "deepseek/..."`
- [ ] "Model Validation" renamed to "Agent Profile Validation"
- [ ] "Project Standards Loading" added as mandatory pre-flight step
- [ ] Error handling covers: missing agent profile, missing project standards

### sdd/task-string-format.md (modified)
- [ ] `### Agent Profile` section replaces `### Model: {model}`
- [ ] All phase examples use `agentId` field
- [ ] Per-phase table includes `agentId` column

### sdd/templates/standards.md.in (new)
- [ ] Template with placeholder syntax: `{project_name}`, `{repo_url}`, `{reviewer}`
- [ ] Sections: Project Identity, Architecture Principles, File Structure, Commit Convention, Git Workflow, Environment & Secrets

### workspace/sdd/** (synced)
- [ ] All shipped files identical between root `sdd/` and `workspace/sdd/`:
  - `orchestrator-flow.md`, `task-string-format.md`, `validation-rules.md`
  - All templates in `templates/*.md.in` including new `standards.md.in`
- [ ] `state.json.in` drift fixed (was 543 bytes, now 1031 bytes — full engram block)

### verify.sh (modified)
- [ ] Agnostic content checks: NON-NEGOTIABLE in AGENTS, CONTENT LOCK in TOOLS, no ZENTICALAB, MEMORY.md exists
- [ ] Config profile checks: 9 profiles, bootstrap limits, timeout, Engram MCP arg
- [ ] Hook checks: scripts exist, executable, `bash -n` valid
- [ ] Content boundary runtime check: calls `check-content-boundaries.sh --worktree`
- [ ] SDD sync checks: `diff -rq` between root and workspace
- [ ] README/version checks: v1.7.0 badge, agnostic config section, no lucy-config refs

### README.md (modified)
- [ ] Version badge: 1.7.0
- [ ] "What's New" section updated for v1.7
- [ ] New sections present:
  - Agnostic Configuration (what it means, why it matters)
  - Why Config Lives in openclaw.json (config fragment via $include, 9 fixed profiles)
  - Content Boundary Enforcement (locked files, pre-commit hook, placeholders)
  - Contributor Setup (`--contributor` flag)
- [ ] "What you get" table: includes Memory row, Enforcement row
- [ ] "Install modes" table: includes Contributor mode
- [ ] No `lucy-config` references
- [ ] TUI no longer described as "configure SDD phase models"

### CHANGELOG.md (modified)
- [ ] `[1.7.0]` entry present
- [ ] Added section: agnostic templates, MEMORY.md, enforcement, 9 profiles, standards template, contributor, expanded verify
- [ ] Changed section: AGENTS rewritten, TOOLS sanitized, install.sh, SDD docs, README, sync
- [ ] Removed section: SDD_TABLE sentinels, TUI customization, ZENTICALAB content, lucy-config refs

### docs/STANDARDS.md (modified, now tracked)
- [ ] File structure tree includes new files: `workspace/MEMORY.md`, `scripts/check-content-boundaries.sh`, `scripts/install-pre-commit-hook.sh`, `sdd/templates/standards.md.in`
- [ ] Previously untracked → now in git (`git ls-files docs/STANDARDS.md` should succeed)

## 3. Things That Should NOT Be Flagged

These are intentional design decisions, not bugs:

- **"Project Standards (Agnostic)" heading in TOOLS.md** — this is legitimate agnostic guidance telling users to use `{project}/docs/STANDARDS.md`, not a project-specific leak
- **`--clone` mapped to `main`** — intentional deprecation. Templates are now agnostic on `main`, so `clone` is redundant
- **No per-phase model picker in TUI** — profiles are fixed in `config/agent-fragment.json5`, customization is via the fragment, not the installer TUI
- **MEMORY.md is empty template** — intentional. Should NOT contain live data
- **SDD cycle artifacts in `sdd/lucy-ai/`** — normal. These are excluded from workspace sync

## 4. Security Review Focus

- [ ] No API keys, tokens, or OAuth credentials in any file
- [ ] Pre-commit hook correctly handles partial stages (not just full file diffs)
- [ ] Pre-commit hook guards against symlink attacks on protected files
- [ ] No hardcoded paths to real projects (`/workspace/repos/ZENTICALAB`, etc.)
- [ ] MEMORY.md has privacy notice and empty template (no data leak)
- [ ] Email section in TOOLS.md uses generic wording (no real credentials)

## 5. How to Verify Locally

```bash
cd /path/to/lucy-ai
git checkout feat/release-configuracion-agnostica-enforcement

# Syntax check all scripts
bash -n install.sh && bash -n scripts/check-content-boundaries.sh && \
bash -n scripts/install-pre-commit-hook.sh && bash -n verify.sh && \
echo "SYNTAX OK"

# Run content boundary checker
./scripts/check-content-boundaries.sh --worktree && echo "CONTENT OK"

# Run full verification
./verify.sh
# Expected: 115/115 checks pass

# Check SDD docs sync
diff -rq sdd/ workspace/sdd/ --exclude=lucy-ai
# Expected: no output (all identical)

# Quick grep checks
grep -r "ZENTICALAB" workspace/AGENTS.md workspace/TOOLS.md && echo "FAIL" || echo "CLEAN"
grep "SDD_TABLE_START\|SDD_TABLE_END" workspace/AGENTS.md && echo "FAIL" || echo "CLEAN"
grep "lucy-config" install.sh README.md && echo "FAIL" || echo "CLEAN"
```

## 6. Acceptance Criteria to Validate

| # | Criterion | How to Check |
|---|-----------|-------------|
| AC1 | AGENTS.md agnostic, no sentinels | `grep SDD_TABLE workspace/AGENTS.md` → empty |
| AC2 | TOOLS.md no ZENTICALAB | `grep ZENTICALAB workspace/TOOLS.md` → empty |
| AC3 | MEMORY.md sanitized template | `head -5 workspace/MEMORY.md` → privacy notice |
| AC4 | 9 SDD profiles in config | `grep -c 'id: "sdd-' config/agent-fragment.json5` → 8 |
| AC5 | Hook scripts executable, valid | `bash -n scripts/*.sh && test -x scripts/*.sh` |
| AC6 | install.sh v1.7.0, --contributor | `grep '1.7.0' install.sh && grep 'contributor' install.sh` |
| AC7 | agentId in orchestrator docs | `grep agentId sdd/orchestrator-flow.md` → multiple |
| AC8 | standards.md.in template | `test -f sdd/templates/standards.md.in` |
| AC10 | verify.sh passes | `./verify.sh` → 115/115 |
| AC11 | Version v1.7.0 | `grep '1.7.0' install.sh README.md` |
| AC13 | README documents agnostic config | `grep 'Agnostic' README.md` → present |
