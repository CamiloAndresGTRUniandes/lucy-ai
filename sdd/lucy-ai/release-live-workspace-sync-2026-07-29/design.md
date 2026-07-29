# Design: v1.8.0 — Live workspace capability sync

## Architecture decisions

| Decision | Choice | Rationale | Alternative |
|----------|--------|-----------|-------------|
| Sync method | Manual curated copy per file | Full automatic sync risks pulling private/project-specific content. Our 32 excluded skills and project folders need manual curation per file | rsync live → repo directly (risks contamination) |
| Skill copy | New skills from live → repo; zenticalab-* removed; 7 updated | Clean bundle upgrade; no stale project-specific payload shipped | Ship live skills as-is — but that includes deprecated zenticalab references |
| Template conflict resolution | Live version always wins | Drift happened because repo wasn't updated. Live workspace is the source of truth for Lucy behavior | Merge both versions — non-viable since repo versions are plain translations of older live state |
| Release notes | `RELEASE_NOTES.md` at repo root | Keeps notes visible in repo for GitHub Releases; not coupled with CHANGELOG | Put everything in CHANGELOG (mixes changelog with release notes) |
| Config fragment | Copy from live workspace | Live has the main agent model corrected to openai-codex/gpt-5.5 | Keep repo default deepseek-v4-pro for main agent (would silently downgrade users) |

## File-level sync plan

### Workspace templates (F1)
Source: `/home/node/.openclaw/workspace/{file}` → Target: `/workspace/repos/lucy-ai/workspace/{file}`

| File | Action | Notes |
|------|--------|-------|
| AGENTS.md | Replace | Language-matching rule, orchestrator-doctrine preload, English models table, updated skills section |
| SOUL.md | Replace | Added Language section, English security section |
| USER.md | Replace | English principle sections |
| TOOLS.md | Replace | Current model inventory (gpt-5.5, gpt-5.4, gpt-5.4-mini), updated tool tables |
| IDENTITY.md | Skip | Same content |
| MEMORY.md | Skip | Same content |
| HEARTBEAT.md | Skip | Same content |

### SDD core docs (F2)
Source: `/home/node/.openclaw/workspace/sdd/{file}` → Target: `/workspace/repos/lucy-ai/sdd/{file}`

| File | Action | Notes |
|------|--------|-------|
| orchestrator-flow.md | Replace | English version with updated spawn anatomy, step-by-step |
| task-string-format.md | Replace | English canonical template, example, variables by phase |
| validation-rules.md | Replace | English per-phase validation checklists |

### SDD templates (F3)
Source: `/home/node/.openclaw/workspace/sdd/templates/{file}` → Target: `/workspace/repos/lucy-ai/sdd/templates/{file}`

| File | Action | Notes |
|------|--------|-------|
| apply.md.in | Replace | English sections |
| design.md.in | Replace | English sections |
| explore.md.in | Replace | English sections |
| spec.md.in | Replace | English sections |
| standards.md.in | Replace | English version + content updates |
| verify.md.in | Replace | English version |
| tasks.md.in | Skip | Same content |
| state.json.in | Skip | Same content |

### Skills (F4, F5, F6)
Source: `/home/node/.openclaw/workspace/skills/{name}/` → Target: `/workspace/repos/lucy-ai/skills/{name}/`

**32 new skills to copy (F4):**
Copy the entire directory for each skill: `{name}/SKILL.md` and any supporting files.

`ado-context`, `ado-effort-estimation`, `ado-refinement`, `ado-us-ac-template`,
`angular-forms`,
`azure-artifacts`, `azure-boards`, `azure-devops`, `azure-devops-cli`, `azure-repos`, `azure-sign-in`,
`branch-pr`,
`csharp-async`, `csharp-docs`, `csharp-xunit`,
`dotnet-best-practices`, `dotnet-design-pattern-review`,
`find-skills`,
`git-commit`,
`igniteui-angular-components`, `igniteui-angular-grids`, `igniteui-angular-generate-from-image-design`, `igniteui-angular-theming`,
`issue-creation`,
`judgment-day`,
`mentoring-juniors`,
`orchestrator-doctrine`,
`security`, `skill-registry`, `software-architecture`,
`sql-code-review`, `sql-optimization`

**2 skills to remove (F5):**
- Delete `skills/zenticalab-pr-review/` recursively
- Delete `skills/zenticalab-security/` recursively

**7 skills to update (F6):**
Replace each skill's `SKILL.md` with the live version:
`angular-architecture`, `angular-core`, `dotnet10-csharp14`, `pr-review`, `sdd`, `skill-creator`, `tailwind-4`

### Config fragment (F7)
- Source: `/home/node/.openclaw/workspace/config/agent-fragment.json5` → `config/agent-fragment.json5`
- Key change: main agent `primary: "openai-codex/gpt-5.5"` with fallbacks `["deepseek/deepseek-v4-pro"]`

### Release metadata (F8, F9, F10, F11)

**README.md** — update:
- Version badge → `v1.8.0`
- What's New section for v1.8.0
- Install examples → `--tag v1.8.0`

**CHANGELOG.md** — add entry for v1.8.0:
```
# Changelog

## v1.8.0 (2026-07-29)

### Added
- 32 new bundled skills: orchestrator-doctrine, software-architecture, security, ...
- RELEASE_NOTES.md with GitHub-compatible release notes

### Updated
- 7 skills updated to latest live versions
- workspace templates synchronized with live Lucy (AGENTS.md, SOUL.md, USER.md, TOOLS.md)
- SDD core docs: orchestrator flow, task string format, validation rules
- SDD phase templates (English-standardized)
- Config fragment: main agent → openai-codex/gpt-5.5

### Removed
- Deprecated zenticalab-pr-review and zenticalab-security skills (replaced by generic equivalents)

### Fixed
- Verify phase model: openai-codex/gpt-5.3-codex → openai-codex/gpt-5.5
- Language-matching rule enforced across all workspace templates
```

**SPEC.md** — rewrite to document v1.8.0 feature set.

**RELEASE_NOTES.md** — create at repo root:
- Title: v1.8.0 — Live workspace capability sync
- Sections: What's New, What's Updated, What's Removed, Upgrade Notes
- GitHub Releases format (markdown)

## Skill copy strategy

### Rule set for copying each skill:
1. Copy `skills/{name}/SKILL.md` only (unless the skill has supporting files)
2. Check `SKILL.md` for project-specific names (ZENTICALAB, etc.)
3. If found → abort that skill and flag it
4. Skip `resume-cv-builder` per spec exclusion

### Verification post-copy:
- Count total skills: expect 44 (14 existing + 32 new - 2 removed)
- Confirm zenticalab-* directories no longer exist
- Grep for ZENTICALAB in all new skill files → must be 0 hits

## Release notes format

`RELEASE_NOTES.md` at repo root:

```markdown
# v1.8.0 — Live Workspace Capability Sync

## What's New
- [list of new features]

## What's Updated
- [list of updated components]

## What's Removed
- [list of removed components]

## Upgrade Notes
- `zenticalab-pr-review` and `zenticalab-security` are replaced by project-agnostic `pr-review` and `security`
- Config fragment main agent model updated to `openai-codex/gpt-5.5`
```

## Security

| Area | Check |
|------|-------|
| No secrets | Grep for `$include`, API key patterns, token patterns in all new files |
| No private paths | Grep for `/home/node/`, `CamiloAndres` in all new files |
| No project references | Grep for ZENTICALAB, excel-pipeline, portfolio, ssdp-ai in all new files |
| Config fragment | Only model IDs and profile settings — no secrets |

## Verification plan

1. `bash -n` on install.sh, update.sh, verify.sh
2. `verify.sh` run on repo checkout
3. Skill count assert: 44 skills
4. Grep for deprecated zenticalab* → 0
5. Grep for project-specific names → 0
6. Grep for secrets/paths → 0
7. Confirm `RELEASE_NOTES.md` exists
8. Confirm `.version` concept works with `install.sh --version`

## Error handling

| Scenario | Response |
|----------|----------|
| Skill file contains project-specific text | Flag and skip that skill; continue with others |
| Config fragment has syntax error | Do not replace; use live version verified working |
| verify.sh fails after sync | Identify failing check; fix and re-run |
