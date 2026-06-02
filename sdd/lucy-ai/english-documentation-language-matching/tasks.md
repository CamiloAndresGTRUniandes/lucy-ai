# Tasks: English Documentation + Language Matching

## Status: Draft

## Task List

- [ ] **T1:** Feature branch setup
  - **Description:** Create the feature branch `feat/english-documentation-language-matching` from `main` in `/workspace/repos/lucy-ai`. Push the branch so it exists on remote. Verify no accidental work is on `main`.
  - **Input:** `/workspace/repos/lucy-ai`
  - **Output:** Branch `feat/english-documentation-language-matching` checked out, `main` untouched
  - **Standards:** `docs/STANDARDS.md` — branch naming (`feat/description`), no direct push to `main`
  - **Estimate:** 10 min

- [ ] **T2:** Add language-matching header to `AGENTS.md`
  - **Description:** Insert `## ⛔ LANGUAGE MATCHING RULE (READ FIRST)` as the first content block of `workspace/AGENTS.md` in the lucy-ai repo. The block must instruct Lucy to match Camilo's latest message language (English → English, Spanish → Spanish). It must appear before all existing content (SDD rules, model config, phase gates) so language matching is established before anything else biases the response.
  - **Input:** `/workspace/repos/lucy-ai/workspace/AGENTS.md`, `/workspace/repos/lucy-ai/sdd/lucy-ai/english-documentation-language-matching/design.md`
  - **Output:** Updated `workspace/AGENTS.md` with the rule header placed at file top, existing content preserved below
  - **Standards:** `docs/STANDARDS.md` — workspace templates must be project-agnostic; `AGENTS.md` is locked content
  - **Estimate:** 30 min

- [ ] **T3:** Translate `workspace/AGENTS.md` Spanish prose to English
  - **Description:** Translate all remaining Spanish prose in `workspace/AGENTS.md` to English: SDD Workflow heading/body, Phase Gate Protocol prompt text (`¿Camilo, aprobás...?`), SDD Model Configuration prose/table labels, provider cost notes, SDD Orchestrator section, sub-agent rules, Decision Memory Protocol questions, criticality/scrutiny notes. **Preserve quoted Spanish literals** that define behavior or accepted/rejected user inputs: `aprobado`, `sí`, `dale`, `se ve bien`, `¿Camilo, aprobás el {phase}?`. Do not alter rules, policies, or architecture content — pure translation only.
  - **Input:** `/workspace/repos/lucy-ai/workspace/AGENTS.md` (after T2)
  - **Output:** `workspace/AGENTS.md` — all Spanish prose replaced with equivalent English, quoted behavioral literals preserved
  - **Standards:** English-only docs per `docs/STANDARDS.md`; `AGENTS.md` is locked (content boundary rules apply)
  - **Estimate:** 2.5 h

- [ ] **T4:** Translate `workspace/SOUL.md` and `workspace/IDENTITY.md`
  - **Description:** SOUL.md: Translate the Language section's Spanish/regionalism guidance (Bogotá-neutral Spanish instructions) to English while preserving the matching policy (match Camilo's language). IDENTITY.md: Verify no Spanish prose remains (expected already English). Both files must remain project-agnostic.
  - **Input:** `/workspace/repos/lucy-ai/workspace/SOUL.md`, `/workspace/repos/lucy-ai/workspace/IDENTITY.md`
  - **Output:** `workspace/SOUL.md` and `workspace/IDENTITY.md` fully English
  - **Standards:** Pure translation — no policy changes; project-agnostic workspace templates
  - **Estimate:** 30 min

- [ ] **T5:** Translate `workspace/TOOLS.md` and `workspace/USER.md`
  - **Description:** TOOLS.md: Translate SDD model config prose, escalation rule, email capability notes, model usage descriptions, web/search notes, communication/plugin notes, and any remaining Spanish labels. No secrets, tokens, or credential values in templates — use placeholders where needed. USER.md: Translate Camilo background, quality/security/git principles, decision-memory questions, engineering mindset notes. Preserve Camilo's identity and preferences; do not soften architecture scrutiny language.
  - **Input:** `/workspace/repos/lucy-ai/workspace/TOOLS.md`, `/workspace/repos/lucy-ai/workspace/USER.md`
  - **Output:** `workspace/TOOLS.md` and `workspace/USER.md` fully English
  - **Standards:** Pure translation — no secrets in templates; project-agnostic; no policy changes
  - **Estimate:** 1.5 h

- [ ] **T6:** Translate `workspace/MEMORY.md`
  - **Description:** Translate Spanish personal/workflow notes to English: language preference, SDD no-skip lesson, approval phrase notes, email/tool/memory descriptions. This is the sanitized template version — no project-specific history or personal data in the repo template. Ensure all translated content is generic/placeholer-friendly.
  - **Input:** `/workspace/repos/lucy-ai/workspace/MEMORY.md`
  - **Output:** `workspace/MEMORY.md` fully English, sanitized for repo use
  - **Standards:** Project-agnostic; no personal secrets or project-specific history in templates
  - **Estimate:** 1 h

- [ ] **T7:** Translate SDD orchestrator docs in `workspace/sdd/`
  - **Description:** Translate three files at `workspace/sdd/`: `orchestrator-flow.md` (title, purpose, spawn anatomy, validation protocol, notification text, phase delegation table, step-by-step instructions, Engram handling, approval instructions, retry/fallback, archive, non-negotiable rules), `validation-rules.md` (purpose, per-phase checks, extra validation, feedback classification, archive condition, report format), `task-string-format.md` (purpose, canonical template labels, Engram context placeholders, variables-by-phase labels, rules). Keep command names, JSON keys, agent IDs, and literal user phrases intact.
  - **Input:** `/workspace/repos/lucy-ai/workspace/sdd/orchestrator-flow.md`, `/workspace/repos/lucy-ai/workspace/sdd/validation-rules.md`, `/workspace/repos/lucy-ai/workspace/sdd/task-string-format.md`
  - **Output:** All three files fully English with preserved technical identifiers
  - **Standards:** Pure translation; keep code/JSON/agent IDs unchanged
  - **Estimate:** 2 h

- [ ] **T8:** Translate SDD templates in `workspace/sdd/templates/`
  - **Description:** Translate Spanish prompts in the template `.md.in` files at `workspace/sdd/templates/`: `design.md.in` (Data Model prompts, API/Auth prompts, Security questions, Error Handling, Observability, Migration Plan, approved-decisions table labels), `explore.md.in` (codebase overview prompts, key files prompt, patterns/examples, dependency/risk descriptions, recommendation prompt), `verify.md.in` (final verdict placeholder, any Spanish status wording), `apply.md.in` (implementation summary prompts, key decisions, deviation/reason text, additional notes, manual verification steps), `spec.md.in` (4 Spanish bullet descriptions in Context section). Skip `state.json.in` (JSON, no Spanish). Skip `tasks.md.in` and `standards.md.in` (already English).
  - **Input:** `workspace/sdd/templates/design.md.in`, `explore.md.in`, `verify.md.in`, `apply.md.in`, `spec.md.in`
  - **Output:** All translated template files fully English
  - **Standards:** Keep required heading names, section structure, and placeholder variables stable
  - **Estimate:** 1.5 h

- [ ] **T9:** Translate `README.md` and `docs/STANDARDS.md`
  - **Description:** README.md: Scan all sections for remaining Spanish prose (install/config/enforcement/project-tree/contributing) and translate. Automated scans may flag false positives in URLs or English words — review manually. docs/STANDARDS.md: Translate any remaining Spanish prose in project identity, installer/workspace/config standards, workflow, branch/release process, and environment notes. Must continue to state "English (code, comments, docs)".
  - **Input:** `/workspace/repos/lucy-ai/README.md`, `/workspace/repos/lucy-ai/docs/STANDARDS.md`
  - **Output:** Both files fully English
  - **Standards:** Pure translation only; no policy or project-identity changes
  - **Estimate:** 1 h

- [ ] **T10:** Sync approved workspace templates to live environment
  - **Description:** After all repo workspace templates are translated and reviewed, copy the approved canonical content from `lucy-ai/workspace/` into the live workspace at `/home/node/.openclaw/workspace/`. Files to sync: `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `MEMORY.md`, `USER.md`, `IDENTITY.md`, `sdd/orchestrator-flow.md`, `sdd/validation-rules.md`, `sdd/task-string-format.md`, `sdd/templates/design.md.in`, `sdd/templates/explore.md.in`, `sdd/templates/verify.md.in`, `sdd/templates/apply.md.in`, `sdd/templates/spec.md.in`. Use exact file copies, not manual re-editing.
  - **Input:** Approved files in `/workspace/repos/lucy-ai/workspace/`
  - **Output:** Live workspace files at `/home/node/.openclaw/workspace/` match canonical repo templates exactly
  - **Standards:** Exact copy/sync — no manual divergence; verify ownership/permissions match existing live files
  - **Estimate:** 30 min

- [ ] **T11:** Run verification scans and diffs
  - **Description:** Three-layer verification on both repo and live workspace:
    1. **Git diff review:** Run `git diff` on the feature branch vs `main` for each changed file. Verify translations preserve meaning and do not alter policy/architecture content.
    2. **Spanish-prose scan:** Run `grep -n '[áéíóúñ¿¡]'` on all changed files. Allowlist only documented quoted literals (`aprobado`, `sí`, `dale`, `se ve bien`, `¿Camilo, aprobás...?`) and false positives (URLs, code snippets).
    3. **Live-vs-template exact diff:** Run `diff` between each canonical `lucy-ai/workspace/` file and its live counterpart at `/home/node/.openclaw/workspace/`. Confirm zero drift.
  - **Input:** All changed files in both repo and live workspace
  - **Output:** Verification report documenting pass/fail for each AC (AC1 through AC8 per spec) and per-file scan results
  - **Standards:** AC compliance per spec; three-layer check; no Spanish prose outside allowlist
  - **Estimate:** 1 h

- [ ] **T12:** Prepare and submit PR
  - **Description:** Commit changes on `feat/english-documentation-language-matching` with conventional commit message (e.g., `feat: add language-matching header and translate workspace to English`). Push branch. Create a GitHub PR with:
    - Title and description summarizing the change (language-matching fix + translation pass)
    - File-by-file change summary
    - Reference to ACs from spec
    - Verification scan results
    - Assign `camiloandresgtruniandes` as reviewer
  - **Input:** Feature branch with all changes committed and pushed
  - **Output:** Open PR on GitHub, ready for review
  - **Standards:** `docs/STANDARDS.md` — no direct push to `main`, PR requires approved review before merge; conventional commits
  - **Estimate:** 30 min

## Dependencies

```
T1 (branch setup) → all other tasks (T2–T12)
T2 (AGENTS.md header) → T3 (translate AGENTS.md) — header must be placed before translation to avoid re-translating it
T3–T9 (translations) → independently parallel, no cross-dependencies
T10 (sync) → T3–T6 (workspace templates must be translated and approved first)
T10 (sync) → T7–T8 (SDD docs/templates must be translated first)
T11 (verification) → T10 (live-vs-template diffs require sync to have happened)
T11 (verification) → all T2–T9 (git diff review requires all translations complete)
T12 (PR) → T11 (verification results attached to PR description)
```

**Parallel execution groups:**
- Group A (T2 + T3): AGENTS.md — must be sequential (header first, then translate)
- Group B (T4–T9): All other translations — fully parallelizable
- Group C (T10): Sync — depends on A,B
- Group D (T11): Verification — depends on C
- Group E (T12): PR — depends on D

## Estimated Effort

| Task | Estimate |
|------|----------|
| T1 — Branch setup | 10 min |
| T2 — AGENTS.md language header | 30 min |
| T3 — Translate AGENTS.md | 2.5 h |
| T4 — Translate SOUL.md + IDENTITY.md | 30 min |
| T5 — Translate TOOLS.md + USER.md | 1.5 h |
| T6 — Translate MEMORY.md | 1 h |
| T7 — Translate workspace/sdd/ docs | 2 h |
| T8 — Translate workspace/sdd/templates | 1.5 h |
| T9 — Translate README.md + docs/STANDARDS.md | 1 h |
| T10 — Sync to live workspace | 30 min |
| T11 — Verification scans + diffs | 1 h |
| T12 — PR preparation | 30 min |
| **Total** | **12 h 10 min** |

## Notes

- **No implementation in this phase** — only write the task list. Implementation happens in SDD Apply.
- **No git commits** during Tasks phase — all commits happen during Apply.
- **No secrets in templates** — verify MEMORY.md, TOOLS.md, and any other template files contain no tokens, API keys, or credentials.
- **Quoted Spanish literals** — these must be preserved in AGENTS.md, SOUL.md, and USER.md wherever they define accepted/rejected user inputs. The `¿Camilo, aprobás...?` approval question is a workflow token, not documentation prose.
- **HEARTBEAT.md** is already English — excluded from scope (per spec Out of Scope).
- **CHANGELOG.md, SPEC.md, SKILL.md** in repo root — already English (per spec Out of Scope).
- **Archived SDD cycle outputs** (e.g., `release-configuracion-agnostica-enforcement/`) — excluded from scope (per spec Out of Scope).
- **Install script** (`install.sh`) — excluded from scope (per spec Out of Scope; it's behavior, not documentation).
