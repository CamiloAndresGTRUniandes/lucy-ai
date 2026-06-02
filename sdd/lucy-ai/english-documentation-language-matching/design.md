# Design: English Documentation + Language Matching

## Status: Draft

## Architecture Decisions

| Decision | Choice | Rationale | Alternative Rejected |
|----------|--------|-----------|---------------------|
| Language header placement | Insert `## ⛔ LANGUAGE MATCHING RULE (READ FIRST)` as the first line of `AGENTS.md` in both `lucy-ai/workspace/AGENTS.md` and the live workspace `AGENTS.md`. The first content block must instruct Lucy to respond in the same language as Camilo's latest message. | The bug is prompt priming. The fix must appear before SDD, model, and workflow content so language matching is established before any other operating rules bias the response. | Keeping the rule only in `SOUL.md`; adding a generic `LANGUAGE: English` header that would incorrectly force English instead of matching Spanish when Camilo writes Spanish. |
| Header wording | Use a matching rule, not an English-only default: English message → English reply; Spanish message → Spanish reply; check input language before every reply; hard rule. | Camilo requested language matching, not English-only behavior. This preserves the existing bilingual interaction policy while solving the English prompt failure. | Replacing the policy with English-only documentation behavior; relying on implicit style matching. |
| Translation strategy | Translate Spanish prose to English while preserving quoted Spanish literals where they are behavioral examples or accepted user inputs (for example `aprobado`, `sí`, `dale`, `¿Camilo, aprobás...?`). | Pure translation must not alter policies. Some Spanish phrases are not documentation prose; they are literal tokens/examples the workflow recognizes. Removing them would change behavior. | Blindly removing all Spanish words; rewriting approval rules; translating literal examples in a way that changes accepted/invalid phrases. |
| Canonical source | Treat `/workspace/repos/lucy-ai` as the canonical source. Update repo files first, then sync approved workspace templates into the live workspace. | Future installs come from `lucy-ai`; live-only fixes would regress on reinstall/update. Repo-first keeps runtime and installer aligned. | Editing only the live workspace; editing only the repo and leaving current Lucy runtime stale. |
| Template sync | After repo files are translated and approved, copy the approved canonical workspace template content into the live workspace for `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `MEMORY.md`, `USER.md`, and `IDENTITY.md`; then run exact diffs to confirm zero drift. | AC3 and AC8 require runtime and installer templates to match. Exact copy/sync is auditable and avoids manual divergence. | Manual parallel edits in repo and live workspace; partial sync only for `AGENTS.md`. |
| File scope | Translate the specific files from the spec: live workspace core files; `lucy-ai/workspace/*` templates; `README.md`; `docs/STANDARDS.md`; `sdd/orchestrator-flow.md`; `sdd/validation-rules.md`; `sdd/task-string-format.md`; `sdd/templates/design.md.in`, `explore.md.in`, `verify.md.in`, and `apply.md.in`. | This covers the runtime prompt, future installer templates, public docs, and SDD prompts that can re-prime Lucy or sub-agents into Spanish. | Translating only AGENTS.md; translating archived SDD cycle outputs; translating git history or PR text. |
| Verification approach | Use a three-layer verification: `git diff` review for meaning preservation, Spanish-prose scans for remaining untranslated text, and exact live-vs-template diffs for synced workspace files. | Translation accuracy and no drift are both required; no single check proves both. | Only relying on grep; only relying on manual review without automated scans; only checking the repo but not live workspace. |
| Branching strategy | Create/use a feature branch such as `feat/english-documentation-language-matching` before Apply changes. Never push directly to `main`; open a PR for review. | Project standards protect `main`; this is a docs/config-template change that still affects runtime behavior and needs PR review. | Working directly on `main`; bundling this into an unrelated release branch. |
| Change boundaries | Do not modify `install.sh`, runtime behavior, model config semantics, SDD phase order, secrets handling, or project-specific standards. | The approved spec is a language normalization pass plus header placement only. | Opportunistic cleanup or policy rewrites during translation. |

### File-by-file translation targets

| File | Sections / content to translate | Notes |
|------|---------------------------------|-------|
| Live `AGENTS.md` and `lucy-ai/workspace/AGENTS.md` | Add the language header before all existing content. Translate SDD Workflow heading/body, phase gate prompt text, SDD Model Configuration prose/table labels, provider notes, SDD Orchestrator prose, sub-agent rules, Engram-by-phase note, Decision Memory Protocol Spanish questions, and criticality notes. | Preserve literal approval examples such as `approved`/`aprobado` and invalid phrase examples such as `sí`, `dale`, `se ve bien` as quoted examples. |
| Live `SOUL.md` and `lucy-ai/workspace/SOUL.md` | Translate Spanish style guidance under Language, especially regionalism constraints and Bogotá-neutral Spanish instructions. | The policy still says match Camilo's language. |
| Live `MEMORY.md` and `lucy-ai/workspace/MEMORY.md` | Translate Spanish personal/workflow notes, including language preference, SDD no-skip lesson, approval phrase notes, email/tool/memory descriptions. | Do not add project-specific history to repo template. |
| Live `TOOLS.md` and `lucy-ai/workspace/TOOLS.md` | Translate SDD model config prose, escalation rule, email capability notes, model usage descriptions, web/search notes, communication/plugin notes, and any remaining Spanish labels. | No secrets, tokens, or credential values may be added to templates. |
| Live `USER.md` and `lucy-ai/workspace/USER.md` | Translate Camilo background, quality/security/git principles, decision-memory questions, and engineering mindset notes. | Preserve Camilo identity and preferences; do not soften architecture scrutiny. |
| Live `IDENTITY.md` and `lucy-ai/workspace/IDENTITY.md` | Verify no Spanish prose remains; emoji line is not a translation issue. | Likely no substantive change needed. |
| `README.md` | Verify public documentation sections for any Spanish prose; translate any remaining Spanish in install/config/enforcement/project-tree/contributing sections. | Automated scans may flag false positives in URLs or English words; review manually. |
| `docs/STANDARDS.md` | Translate any remaining Spanish prose in project identity, installer/workspace/config standards, workflow, branch/release process, and environment notes. | Must continue to state English-only docs. |
| `sdd/orchestrator-flow.md` | Translate title, purpose, spawn anatomy, validation protocol, notification text, phase delegation table labels, step-by-step phase instructions, Engram handling, approval instructions, retry/fallback, archive, and non-negotiable rules. | Keep command names, JSON keys, agent IDs, and literal user phrases intact. |
| `sdd/validation-rules.md` | Translate purpose, strict validation instructions, per-phase check descriptions, extra validation notes, feedback classification, archive condition, and report format labels. | Keep required heading names and checklist syntax stable. |
| `sdd/task-string-format.md` | Translate purpose, canonical template labels/descriptions, Engram context placeholders, variables-by-phase labels, and rules. | Keep task string structure, placeholders, and agent IDs unchanged. |
| `sdd/templates/design.md.in` | Translate Data Model prompts, API/Auth prompts, Security questions, Error Handling questions, Observability questions, Migration Plan prompts, and approved-decisions heading/table labels. | This template directly affects future Design sub-agent language. |
| `sdd/templates/explore.md.in` | Translate codebase overview prompts, key files prompt, patterns examples, dependency/risk descriptions, and recommendation prompt. | Keep section headings stable unless already English. |
| `sdd/templates/verify.md.in` | Translate final verdict placeholder text and any Spanish status wording; verify checklist prose is already English. | Preserve ✅/❌ markers. |
| `sdd/templates/apply.md.in` | Translate implementation summary prompts, key decisions, deviation/reason text, additional notes, and manual verification steps. | Keep section names expected by validation. |

## Data Model

- **Entities:**
  - **Documentation file:** A markdown/template file in either the live workspace or `lucy-ai` repo that participates in Lucy's prompt/runtime configuration or installer output.
  - **Translation segment:** A Spanish prose block requiring English translation while preserving semantics.
  - **Literal phrase/token:** A quoted Spanish input example or policy token that must remain unchanged because it defines accepted or rejected user language.
  - **Canonical workspace template:** The `lucy-ai/workspace/*` version of a live workspace file after approval.
  - **Verification report:** Evidence from diffs, scans, and live-vs-template comparison.
- **Schema:** No database schema changes. The working structure is file-based: source markdown files, generated diffs, and SDD phase artifacts under `sdd/lucy-ai/english-documentation-language-matching/`.
- **Migrations:** No schema migrations. The migration is documentation/template content replacement plus live workspace sync after approval.

## API Design _(optional)_

- **Endpoints:** None. This feature does not introduce or modify APIs.
- **Auth:** Not applicable. File changes occur locally and PR review controls repository merge authorization.
- **Versioning:** Versioning is handled by Git branch + PR. If the project release process requires it later, changelog/version tagging can be considered after Verify, but it is out of this spec unless Camilo expands scope.

## Security

- **Auth/Authz:** Only local file edits during Apply; repository publication requires PR review. No direct push to `main`.
- **Data handling:** Do not introduce secrets, token fragments, credential values, private project details, or personal environment-only values into `lucy-ai` templates. If live docs contain sensitive setup notes, represent them in templates as placeholders or generic guidance only.
- **Input validation:** Treat Spanish-prose scan results as candidates, not truth. Validate manually so quoted Spanish literals that define behavior are not incorrectly removed.
- **Audit:** Audit with `git diff`, per-file translation review, and final sync diffs. Do not log or persist secrets in SDD artifacts.

## Error Handling

- **Failure modes:**
  - Translation changes meaning or weakens a rule.
  - Literal Spanish approval examples are accidentally translated, changing behavior.
  - Live workspace and repo templates drift after sync.
  - Spanish scans produce false positives or miss unaccented Spanish.
  - Edits are started on `main` instead of a feature branch.
- **Recovery:**
  - Use Git diff to revert individual files or hunks.
  - Restore quoted literals where behavior requires them.
  - Re-copy canonical template files and re-run exact diffs.
  - Use manual review plus multiple scan patterns for accented and unaccented Spanish.
  - Create/switch to the feature branch before Apply changes; if accidental changes exist on `main`, move them with `git switch -c feat/english-documentation-language-matching` before committing.
- **User feedback:** Camilo sees phase summaries, diff-focused review points, and explicit blockers if a translation cannot preserve meaning safely.

## Observability

- **Logging:** SDD artifacts record Explore, Spec, Design, Tasks, Apply, and Verify outputs. Apply should include a file-by-file translation summary. Verify should include scan commands/results and live-vs-template diff status.
- **Metrics:** Count files changed, Spanish-prose candidates before/after, exact live-vs-template diff count, and acceptance criteria pass/fail count.
- **Alerts:** Surface to Camilo if any of these occur: remaining Spanish prose outside quoted literals, template/live drift, secrets detected in templates, branch is `main`, or translation would require a policy/content change.

## Migration Plan

- **Breaking changes:** No intended breaking changes. The only runtime-impacting change is the earlier language-matching instruction in `AGENTS.md`. It should improve behavior without changing SDD semantics.
- **Rollback:** Use Git to revert repo changes; for live workspace, restore from `lucy-ai/workspace/*` previous version or copy back from a backup/diff generated before sync.
- **Deployment steps:**
  1. Confirm/create feature branch `feat/english-documentation-language-matching` in `/workspace/repos/lucy-ai` before Apply modifications.
  2. Translate canonical repo files first: `workspace/*`, `README.md`, `docs/STANDARDS.md`, `sdd/*.md`, and scoped `sdd/templates/*.md.in`.
  3. Add the language-matching header as the first line of `lucy-ai/workspace/AGENTS.md`.
  4. Review `git diff` file-by-file to verify pure translation and no policy drift.
  5. Sync approved canonical workspace templates to the live workspace files.
  6. Add the same language-matching header as the first line of the live `AGENTS.md` through that sync.
  7. Run Spanish-prose scans on both repo and live workspace files, allowing only documented quoted literals and false positives.
  8. Run exact diffs between each live workspace file and its canonical `lucy-ai/workspace/*` counterpart.
  9. Run repo verification checks relevant to docs/templates, including content-boundary checks if available.
  10. Present Apply/Verify results to Camilo and create a PR after approval.

## Approved Decisions

| Decision | Value | Rationale |
|----------|-------|-----------|
| Canonical source | `lucy-ai` repo first, live workspace sync second | Approved Propose option B; prevents installer/runtime drift. |
| Language behavior | Match Camilo's latest message language | User explicitly requested language matching, not English-only responses. |
| Primary fix location | First line of `AGENTS.md` | Earliest loaded operating file must establish language behavior before Spanish-prone SDD content. |
| Translation boundary | Pure translation only | Spec F5 and AC4 require preserving rules, policies, architecture decisions, and process steps. |
| Branching | Feature branch + PR, no direct `main` push | Project standards and workspace rules require PR workflow. |
