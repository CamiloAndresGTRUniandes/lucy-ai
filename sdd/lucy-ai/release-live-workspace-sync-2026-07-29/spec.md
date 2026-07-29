# Spec: v1.8.0 — Live workspace capability sync

## Context

- **Problem:** The `lucy-ai` GitHub repo templates, skills, and config have drifted from the live Lucy workspace. A fresh install from the repo would not reproduce the current Lucy behavior, SDD workflow, or available skills.
- **Business value:** Every new install (including VM-native migration) gets the current Lucy — no manual post-install corrections, no missing orchestration skills, no stale model references.
- **Prior art:** v1.5.0 and v1.7.0 already performed similar config syncs. This is a continuation when new capabilities have accumulated.
- **Constraints:** Do not copy private data, project-specific folders, secrets, or personal artifacts into the repo.

## Requirements

### Functional

| ID | Requirement |
|----|------------|
| F1 | Sync workspace templates: `AGENTS.md`, `SOUL.md`, `USER.md`, `TOOLS.md` from live to repo |
| F2 | Sync SDD core docs: `orchestrator-flow.md`, `task-string-format.md`, `validation-rules.md` |
| F3 | Sync SDD templates: `apply.md.in`, `design.md.in`, `explore.md.in`, `spec.md.in`, `standards.md.in`, `verify.md.in` |
| F4 | Add 32 new bundled skills from live workspace to repo `skills/` |
| F5 | Remove deprecated `zenticalab-pr-review` and `zenticalab-security` from repo `skills/` |
| F6 | Update 7 existing skills that have newer versions in live workspace |
| F7 | Update `config/agent-fragment.json5`: main agent primary model → `openai-codex/gpt-5.5` |
| F8 | Update `README.md`: version badge → `v1.8.0`, what's-new section, install examples |
| F9 | Update `CHANGELOG.md`: v1.8.0 entry with all changes |
| F10 | Rewrite `SPEC.md` from v1.5.0 to v1.8.0 documenting this release |
| F11 | Create `RELEASE_NOTES.md` with v1.8.0 release notes for GitHub Releases |

### Non-functional

| ID | Requirement |
|----|------------|
| NF1 | No secrets, tokens, API keys, or private data in any synced file |
| NF2 | No project-specific references (ZENTICALAB, excel-pipeline, portfolio, ssdp-ai, etc.) in any bundled file |
| NF3 | All existing installer flags (`--clone`, `--tag`, `--force`, `--skip-engram`, `--dry-run`, `--help`, `--version`) continue to work unchanged |
| NF4 | `install.sh`, `update.sh`, `verify.sh` pass syntax checks (`bash -n`) |
| NF5 | `verify.sh` checks updated to reflect new bundled skills count |

## Skill bundle inclusion/exclusion

### Included (new — 32 skills)

| Skill | Rationale |
|-------|-----------|
| `orchestrator-doctrine` | Core routing/orchestration doctrine for SDD |
| `software-architecture` | Architecture/design review guidance |
| `security` | Project-agnostic OWASP security review |
| `find-skills` | Skill discovery and installation |
| `skill-registry` | Skill catalog maintenance |
| `branch-pr` | Branch readiness and PR workflow |
| `git-commit` | Conventional commit workflow |
| `issue-creation` | Structured issue creation |
| `judgment-day` | High-rigor adversarial review |
| `mentoring-juniors` | Socratic mentoring mode |
| `csharp-async` | C# async/await best practices |
| `csharp-docs` | C# XML documentation |
| `csharp-xunit` | xUnit testing patterns |
| `dotnet-best-practices` | .NET/C# best practices review |
| `dotnet-design-pattern-review` | .NET design pattern review |
| `sql-code-review` | SQL security/maintainability review |
| `sql-optimization` | SQL performance optimization |
| `azure-devops` | Core Azure DevOps CLI |
| `azure-devops-cli` | Azure DevOps CLI workflows |
| `azure-boards` | Azure Boards work items |
| `azure-repos` | Azure Repos/PRs/branches |
| `azure-artifacts` | Azure Artifacts packages |
| `azure-sign-in` | Azure CLI authentication |
| `ado-context` | Azure DevOps context for SDD |
| `ado-effort-estimation` | Azure Boards estimation |
| `ado-refinement` | Azure Boards refinement |
| `ado-us-ac-template` | Acceptance criteria template |
| `igniteui-angular-components` | Ignite UI Angular components |
| `igniteui-angular-grids` | Ignite UI Angular grids |
| `igniteui-angular-generate-from-image-design` | Design-to-Ignite UI workflow |
| `igniteui-angular-theming` | Ignite UI Angular theming |
| `angular-forms` | Angular forms (Signal/Reactive) |

### Not included

| Skill | Reason |
|-------|--------|
| `resume-cv-builder` | Personal/niche — not a core Lucy capability |

### Removed

| Skill | Reason |
|-------|--------|
| `zenticalab-security` | Replaced by project-agnostic `security` |
| `zenticalab-pr-review` | Replaced by project-agnostic `pr-review` |

### Updated (existing → newer live version)

| Skill | Change |
|-------|--------|
| `angular-architecture` | Newer version in live |
| `angular-core` | Newer version in live |
| `dotnet10-csharp14` | Significant update in live (146/141 lines churn) |
| `pr-review` | Significant update in live (118/82 lines churn) |
| `sdd` | Updated in live (38/1 lines churn) |
| `skill-creator` | Newer version in live |
| `tailwind-4` | Newer version in live |

## Files NOT to touch

These **must not** be modified or copied from live:

- `workspace/MEMORY.md` — same, leave as-is
- `workspace/IDENTITY.md` — same, leave as-is
- `workspace/HEARTBEAT.md` — same, leave as-is
- `sdd/templates/state.json.in` — same, leave as-is
- `sdd/templates/tasks.md.in` — same, leave as-is
- `memory/` — private, never copy
- Project SDD run folders — never copy
- `.clawhub/` — runtime artifact, not bundled

## User scenarios

### Scenario 1: Fresh install gets current Lucy

**Given** a new user runs `curl ... | bash` on a VM  
**When** the installer copies workspace templates and config  
**Then** AGENTS.md contains the language-matching rule, orchestrator-doctrine preload, updated model matrix, and current skill references  
**And** the `main` agent profile points to `openai-codex/gpt-5.5`  
**And** all 44+ bundled skills are available

### Scenario 2: Update from v1.7.0 to v1.8.0

**Given** a user with v1.7.0 installed runs `cd ~/.openclaw/lucy-agent && ./update.sh`  
**When** the updater detects version `1.7.0`  
**Then** workspace templates are updated with the current versions  
**And** new skills are added to `skills/`  
**And** deprecated `zenticalab-*` skills are removed  
**And** existing skills are updated to newer versions  
**And** config fragment is updated  
**And** `.version` is set to `1.8.0`

### Scenario 3: Verify checks pass

**Given** the v1.8.0 release branch  
**When** `verify.sh` runs  
**Then** all workspace template checks pass  
**And** all 44+ bundled skills are detected  
**And** deprecated skill names are not present  
**And** no project-specific content leaks into any template

## Acceptance criteria

- [ ] **AC1:** `workspace/AGENTS.md` contains language-matching rule, orchestrator-doctrine preload, English content, updated model matrix (gpt-5.5 → Verify phase), and current skill references
- [ ] **AC2:** `workspace/SOUL.md` contains language section and English security wording
- [ ] **AC3:** `workspace/USER.md` has English principle sections
- [ ] **AC4:** `workspace/TOOLS.md` reflects current model inventory (gpt-5.5, gpt-5.4, gpt-5.4-mini as primary; deepseek-v4-pro/flash as fallback/specialized)
- [ ] **AC5:** `skills/` contains 44+ bundled skills (14 existing + 32 new - 2 removed)
- [ ] **AC6:** `skills/zenticalab-pr-review/` and `skills/zenticalab-security/` no longer exist
- [ ] **AC7:** All 7 updated skills match their live versions
- [ ] **AC8:** `config/agent-fragment.json5` main agent primary is `openai-codex/gpt-5.5`
- [ ] **AC9:** `README.md` version badge shows `v1.8.0`
- [ ] **AC10:** `CHANGELOG.md` contains v1.8.0 entry
- [ ] **AC11:** `SPEC.md` documents v1.8.0 feature set
- [ ] **AC12:** `RELEASE_NOTES.md` exists with v1.8.0 release notes formatted for GitHub Releases
- [ ] **AC13:** `install.sh`, `update.sh`, `verify.sh` pass `bash -n`
- [ ] **AC14:** No file contains secrets, tokens, or private data
- [ ] **AC15:** No bundled file references ZENTICALAB, excel-pipeline, portfolio, ssdp-ai, or other project-specific names
- [ ] **AC16:** Running `bash install.sh --accept-defaults --version` prints `1.8.0`
