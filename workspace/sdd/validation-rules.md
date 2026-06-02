# SDD Orchestrator — Validation Rules

## Purpose

Lucy validates the output of each delegated sub-agent BEFORE advancing to the next phase.
**Strict validation:** if a required section is missing or empty, it is considered fail → retry.

---

## General Algorithm

```
1. Does the output file exist?
   → No → FAIL (retry)
2. Parse markdown sections (## SectionName)
3. Are all required sections present?
   → No → FAIL (retry), report missing sections
4. Does each section have >10 characters of text content?
   → No → FAIL (retry), report empty sections
5. Phase-specific validations (see per-phase table)
6. → PASS
```

---

## Per Phase

### Explore

**Expected file:** `sdd/{project}/{feature}/explore.md`

**Required sections:**
- [ ] `## Codebase Overview` — must contain an architecture description
- [ ] `## Patterns Found` — must contain at least 1 pattern
- [ ] `## Dependencies & Risks` — must contain at least 1 item
- [ ] `## Recommendations` — must contain at least 1 actionable recommendation

**Extra validation:**
- Each pattern in Patterns Found must have a name and source location (file:line)

### Spec

**Expected file:** `sdd/{project}/{feature}/spec.md`

**Required sections:**
- [ ] `## Context` — not empty, must contain at least Problem + Business value
- [ ] `## Requirements` — with Functional and/or Non-Functional subtables (at least 1 requirement)
- [ ] `## User Scenarios` — at least 1 scenario with Given/When/Then
- [ ] `## Acceptance Criteria` — at least 1 criterion in checklist format (accept both `[ ] AC1:` and `- [ ] **AC1:**`)
- [ ] `## Out of Scope` (optional but recommended)

**Extra validation:**
- Requirements tables must have at least 1 data row
- Each Acceptance Criterion must be a verifiable proposition (not ambiguous)

### Design

**Expected file:** `sdd/{project}/{feature}/design.md`

**Required sections:**
- [ ] `## Architecture Decisions` — table with at least 1 decision
- [ ] `## Data Model` — description of entities/schemas
- [ ] `## API Design` — endpoints or interfaces _(optional)_ — does not cause fail if absent
- [ ] `## Security` — auth, data handling, input validation
- [ ] `## Error Handling` — failure modes + recovery
- [ ] `## Observability` — logging, metrics
- [ ] `## Decisions approved by Camilo` _(optional)_ — does not cause fail if absent
- [ ] `## Migration Plan` _(optional)_ — does not cause fail if absent

**Extra validation:**
- Each Architecture Decision must have: Decision, Choice, Rationale, Alternative Rejected
- If `## Decisions approved by Camilo` is present, validate that it has at least 1 data row

### Tasks

**Expected file:** `sdd/{project}/{feature}/tasks.md`

**Required sections:**
- [ ] `## Task List` — at least 1 task with title + description
- [ ] `## Dependencies` — dependency graph between tasks
- [ ] `## Estimated Effort` — table with estimates per task

**Extra validation:**
- Each task must have: Title, Description, Output
- Each task estimated in time (minutes or hours)

### Apply

**Expected file:** `sdd/{project}/{feature}/apply.md`

**Required sections:**
- [ ] `## Files Modified` — table with File, Action, Description
- [ ] `## What Was Implemented` — non-trivial summary
- [ ] `## Tests` — table with test file, type, coverage
- [ ] `## Notes` _(optional)_ — does not cause fail if absent
- [ ] `## Verification Instructions` _(optional)_ — does not cause fail if absent

**Extra validation:**
- At least 1 file modified
- At least 1 test file listed
- If there is a deviation from design, there must be `Reason for deviation`

### Verify

**Expected file:** `sdd/{project}/{feature}/verification.md`

**Required sections:**
- [ ] `## Spec Compliance` — checklist with requirements
- [ ] `## Acceptance Criteria` — checklist with spec criteria
- [ ] `## Code Quality` — checklist
- [ ] `## Security` — checklist
- [ ] `## Integration` — checklist
- [ ] `## Final Verdict` — ✅ or ❌ with rationale
- [ ] `## Issues Found` _(optional)_ — does not cause fail if absent

**Extra validation:**
- Each checklist must have at least 1 item with ✅ or ❌
- Final Verdict must be explicit (✅ Approved / ❌ Rejected)

### PR Review (post-Verify, before Archive)

**NON-NEGOTIABLE:** This phase is not delegated. Lucy handles feedback directly.

**Camilo's feedback validation:**
1. Read PR comments (Lucy does this manually)
2. Classify each comment:
   - **Minor** → direct fix without re-delegating
   - **Moderate** → Tasks → Apply → Verify (delegated)
   - **Major** → Spec → Design → Tasks → Apply → Verify (full cycle)
3. Propose classification to Camilo before acting
4. Document each resolved comment in ARCHIVE.md

**Archive condition:**
- [ ] PR merged into main/develop, OR
- [ ] Camilo explicitly decides to close the cycle (with rationale in state.json)

---

## Validation Report Format

When Lucy validates and finds problems:

```
### Validation: {phase}
- [✅] Output file exists
- [❌] Missing sections: {list}
- [✅] All sections have content
- [❌] Phase-specific: {detail}
→ **FAIL** — retry #{n}/3
```

When it passes:

```
### Validation: {phase}
- [✅] Output file exists
- [✅] All required sections present
- [✅] All sections have content
- [✅] Phase-specific checks pass
→ **PASS**
```
