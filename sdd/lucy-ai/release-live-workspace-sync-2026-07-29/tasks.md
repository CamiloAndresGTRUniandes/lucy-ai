# Tasks: v1.8.0 — Live workspace capability sync

## Task List

### T1 — Prepare release branch

- **Description:** Create a feature/release branch from updated `origin/main` for the v1.8.0 sync work.
- **Output:** Branch `feat/v1.8.0-live-workspace-sync` checked out locally.
- **Files:** none initially.
- **Estimate:** 10 minutes.

### T2 — Sync workspace templates

- **Description:** Copy curated live workspace templates into repo templates.
- **Output:** Updated repo workspace templates.
- **Files:**
  - `workspace/AGENTS.md`
  - `workspace/SOUL.md`
  - `workspace/USER.md`
  - `workspace/TOOLS.md`
- **Do not modify:**
  - `workspace/IDENTITY.md`
  - `workspace/MEMORY.md`
  - `workspace/HEARTBEAT.md`
- **Estimate:** 20 minutes.

### T3 — Sync SDD core docs and templates

- **Description:** Copy live SDD core docs/templates into repo, excluding unchanged templates and historical/project-specific SDD run folders.
- **Output:** Updated SDD orchestration docs/templates.
- **Files:**
  - `sdd/orchestrator-flow.md`
  - `sdd/task-string-format.md`
  - `sdd/validation-rules.md`
  - `sdd/templates/apply.md.in`
  - `sdd/templates/design.md.in`
  - `sdd/templates/explore.md.in`
  - `sdd/templates/spec.md.in`
  - `sdd/templates/standards.md.in`
  - `sdd/templates/verify.md.in`
- **Do not modify:**
  - `sdd/templates/tasks.md.in`
  - `sdd/templates/state.json.in`
- **Estimate:** 20 minutes.

### T4 — Sync bundled skills

- **Description:** Add 32 new reusable skills, update 7 existing skills, and remove 2 deprecated zenticalab-specific skills.
- **Output:** `skills/` matches curated v1.8.0 bundle.
- **Add:**
  - `ado-context`
  - `ado-effort-estimation`
  - `ado-refinement`
  - `ado-us-ac-template`
  - `angular-forms`
  - `azure-artifacts`
  - `azure-boards`
  - `azure-devops`
  - `azure-devops-cli`
  - `azure-repos`
  - `azure-sign-in`
  - `branch-pr`
  - `csharp-async`
  - `csharp-docs`
  - `csharp-xunit`
  - `dotnet-best-practices`
  - `dotnet-design-pattern-review`
  - `find-skills`
  - `git-commit`
  - `igniteui-angular-components`
  - `igniteui-angular-generate-from-image-design`
  - `igniteui-angular-grids`
  - `igniteui-angular-theming`
  - `issue-creation`
  - `judgment-day`
  - `mentoring-juniors`
  - `orchestrator-doctrine`
  - `security`
  - `skill-registry`
  - `software-architecture`
  - `sql-code-review`
  - `sql-optimization`
- **Update:**
  - `angular-architecture`
  - `angular-core`
  - `dotnet10-csharp14`
  - `pr-review`
  - `sdd`
  - `skill-creator`
  - `tailwind-4`
- **Remove:**
  - `zenticalab-pr-review`
  - `zenticalab-security`
- **Exclude:**
  - `resume-cv-builder`
- **Estimate:** 45 minutes.

### T5 — Sync config fragment

- **Description:** Replace repo `config/agent-fragment.json5` with live version after confirming it contains no secrets.
- **Output:** Main profile uses `openai-codex/gpt-5.5` with DeepSeek Pro fallback.
- **Files:**
  - `config/agent-fragment.json5`
- **Estimate:** 10 minutes.

### T6 — Update release metadata

- **Description:** Update release-facing documentation for v1.8.0.
- **Output:** Repo docs describe the new release correctly.
- **Files:**
  - `README.md`
  - `CHANGELOG.md`
  - `SPEC.md`
  - `RELEASE_NOTES.md`
- **Estimate:** 35 minutes.

### T7 — Update verification checks if needed

- **Description:** Adjust verification logic to account for the new bundled skill inventory and deprecated skill removals.
- **Output:** `verify.sh` validates v1.8.0 expectations.
- **Files:**
  - `verify.sh`
  - possibly `scripts/check-content-boundaries.sh`
- **Estimate:** 30 minutes.

### T8 — Run verification gates

- **Description:** Run local verification and fix issues found.
- **Output:** Passing verification evidence.
- **Commands:**
  - `bash -n install.sh update.sh verify.sh uninstall.sh scripts/*.sh`
  - `./verify.sh`
  - skill count check
  - deprecated/project-specific grep checks
- **Estimate:** 30 minutes.

### T9 — Prepare PR package

- **Description:** Review diff, summarize changes, and prepare PR description. Do not push/open PR without Camilo's approval if external write confirmation is needed.
- **Output:** PR-ready branch with summary and test evidence.
- **Files:** none required.
- **Estimate:** 20 minutes.

## Dependencies

```text
T1
 ├─ T2
 ├─ T3
 ├─ T4
 └─ T5
      ↓
T6
      ↓
T7
      ↓
T8
      ↓
T9
```

## Estimated Effort

| Task | Estimate |
|------|----------|
| T1 | 10 min |
| T2 | 20 min |
| T3 | 20 min |
| T4 | 45 min |
| T5 | 10 min |
| T6 | 35 min |
| T7 | 30 min |
| T8 | 30 min |
| T9 | 20 min |
| **Total** | **3h 40m** |

## Implementation Notes

- Use curated copy, not broad recursive copy from the live workspace root.
- Never copy `memory/`, `.clawhub/`, project SDD runs, or project repo folders.
- Use `trash`/recoverable moves or git-tracked deletes for deprecated skill directories.
- GitHub writes (`push`, PR creation, release creation) require explicit Camilo confirmation later.
