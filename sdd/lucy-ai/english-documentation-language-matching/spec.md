# Spec: English Documentation + Language Matching

## Status: Draft

## Context

- **Problem:** Lucy's runtime responses default to Spanish even when Camilo writes in English. The root cause is prompt priming: `AGENTS.md` is loaded early in the system prompt and contains critical SDD workflow sections, model configuration, and phase gate instructions written in Spanish. This biases the model toward Spanish output before the language-matching rule in `SOUL.md` is evaluated. Additionally, several workspace config files and `lucy-ai` installer templates contain Spanish sections that reinforce this bias, both at runtime and on fresh installs.

- **Business value:** Fixing language matching ensures Lucy consistently matches the user's language (English when Camilo writes in English), eliminating silent friction. Translating remaining Spanish content to English across both the live workspace and the canonical `lucy-ai` repo means the fix is permanent — current runtime is corrected and future installs start in English automatically. Non-Spanish-speaking users or collaborators can also read and contribute to the project without a language barrier.

- **Constraints:**
  - Workspace templates in `lucy-ai` must remain project-agnostic — no project-specific paths, names, or content.
  - Installer (`install.sh`) must stay shell-based, idempotent, auditable, and portable.
  - No secrets, tokens, or credentials in any template.
  - All changes are documentation-language normalization only — no policy or content rewrites.
  - Live workspace files must be updated from the same approved content so runtime and installer stay aligned.
  - The language-matching rule header in `AGENTS.md` is the primary mechanism for solving the runtime language-matching issue.

- **Assumptions:**
  - The LLM runtime respects the language-matching rule header when placed at the top of `AGENTS.md` (early in the system prompt).
  - All Spanish content to be translated is pure documentation — no idioms, puns, or cultural references that lose meaning in translation.
  - Camilo will review and approve each translated file before it is synced to the live workspace.
  - The `lucy-ai` installer already copies workspace templates to `~/.openclaw/workspace/` — updating the templates in the repo is sufficient to fix future installs.

## Requirements

### Functional

| ID | Category | Requirement |
|----|----------|-------------|
| F1 | Language matching fix | Add `## ⛔ LANGUAGE MATCHING RULE (READ FIRST)` header block at the very top of `AGENTS.md` to establish language matching before any content loads |
| F2 | Workspace translation | Translate all remaining Spanish sections in live workspace files to English: `AGENTS.md`, `SOUL.md`, `MEMORY.md`, `TOOLS.md`, `USER.md`, `IDENTITY.md` |
| F3 | lucy-ai template translation | Translate all remaining Spanish sections in `lucy-ai` repo files to English: `README.md`, `docs/STANDARDS.md`, SDD orchestrator docs (`orchestrator-flow.md`, `validation-rules.md`, `task-string-format.md`), and SDD templates (`design.md.in`, `explore.md.in`, `verify.md.in`, `apply.md.in`) |
| F4 | Template sync | Ensure workspace templates in `lucy-ai` match the approved English content of their live workspace counterparts (`AGENTS.md`, `SOUL.md`, `TOOLS.md`, `MEMORY.md`, `USER.md`, `IDENTITY.md`) |
| F5 | No content changes | All translations are pure language translations — no changes to rules, policies, process, or architecture content |

### Non-Functional

| ID | Category | Requirement |
|----|----------|-------------|
| NF1 | Correctness | Every translated section preserves the exact meaning, intent, and specificity of the original Spanish text |
| NF2 | Consistency | Terminology (e.g., "SDD", "phase", "gate", "approval") is translated consistently across all files |
| NF3 | Auditability | Each file changed is tracked individually — translators and reviewers can diff against original Spanish to verify no content drift |
| NF4 | Idempotency | Running the installer after the changes produces identical results — no drift introduced by the translation pass |

## User Scenarios

### Scenario 1: Camilo writes in English, Lucy responds in English

**Given** Camilo sends a message in English  
**When** Lucy processes the system prompt  
**Then** The language-matching rule header at the top of `AGENTS.md` primes the model to match Camilo's input, and Lucy responds in English matching Camilo's language

### Scenario 2: Fresh install of lucy-ai on a new machine

**Given** A user clones `lucy-ai` and runs `install.sh` on a new machine  
**When** The installer copies workspace templates to `~/.openclaw/workspace/`  
**Then** All templates (`AGENTS.md`, `SOUL.md`, `TOOLS.md`, `MEMORY.md`, `USER.md`, `IDENTITY.md`) are in English, and Lucy responds in English by default when the user writes in English — no post-install language fix needed

### Scenario 3: Reviewer verifies translation accuracy

**Given** A reviewer compares a translated file against its original Spanish version  
**When** They diff the old (Spanish sections) vs new (English sections) content  
**Then** All Spanish text is replaced by equivalent English text, and no policy, rule, or process content has changed — only the language of documentation

### Scenario 4: Spanish-speaking collaborator reads lucy-ai docs

**Given** A new collaborator reads `README.md` or `docs/STANDARDS.md`  
**When** They encounter sections that were previously in Spanish  
**Then** All content is in English, making the project accessible to non-Spanish-speaking contributors while preserving all technical and process information

## Out of Scope

- ❌ Translation of SDD workflow logic or phase sequencing — only the language of documentation describing the workflow changes
- ❌ Changes to `CHANGELOG.md`, `SPEC.md`, or `SKILL.md` in the `lucy-ai` repo — these are already effectively English
- ❌ Changes to `HEARTBEAT.md` — already English, no translation needed
- ❌ Any behavioral, architectural, or policy changes to Lucy's runtime beyond the language-matching rule header and documentation language
- ❌ Translation of git commit history, issue comments, or PR descriptions — only tracked files
- ❌ Changes to the installer script (`install.sh`) itself — only templates and docs are updated

## Acceptance Criteria

- [ ] **AC1:** `## ⛔ LANGUAGE MATCHING RULE (READ FIRST)` header is present as the first content block of `AGENTS.md` in both the live workspace and the `lucy-ai` template
- [ ] **AC2:** All Spanish sections are translated to English in every file listed in F2 and F3, verified by diff against the original file
- [ ] **AC3:** Live workspace files (`~/.openclaw/workspace/`) are updated from the same approved content used in `lucy-ai` templates — no divergence between runtime and installer
- [ ] **AC4:** Every translated document preserves the original meaning — no rules, policies, architecture decisions, or process steps are altered
- [ ] **AC5:** `README.md` and `docs/STANDARDS.md` in `lucy-ai` are fully English with no remaining Spanish sections
- [ ] **AC6:** SDD orchestrator documentation (`orchestrator-flow.md`, `validation-rules.md`, `task-string-format.md`) is fully English
- [ ] **AC7:** SDD templates (`design.md.in`, `explore.md.in`, `verify.md.in`, `apply.md.in`) in `lucy-ai` have all Spanish content translated to English
- [ ] **AC8:** No drift exists between live workspace templates and `lucy-ai` workspace templates — diff confirms they match
