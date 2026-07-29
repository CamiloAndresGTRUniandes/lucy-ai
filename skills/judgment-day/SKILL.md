---
name: judgment-day
description: >
  Run high-rigor adversarial review cycles until implementation quality is accepted or escalated.
  Trigger: when the user requests judgment day, adversarial review, dual review, or extra-rigorous validation.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Judgment Day Review

## When to Use

Use when a change needs more rigor than standard verification, especially for security-sensitive, architectural, data-migration, or high-risk PRs.

## Rules

- Do not replace SDD Verify; this is an additional rigor layer.
- Run two independent review passes with different perspectives.
- Keep evidence traceable to files, tests, commands, and observed behavior.
- Synthesize findings into concrete fix tasks.
- Re-run review after fixes with an explicit delta report.
- Escalate after repeated failures instead of looping forever.

## Review Passes

1. **Correctness reviewer** — spec compliance, edge cases, tests, regressions.
2. **Adversarial reviewer** — security, misuse, data loss, concurrency, operational risks.

## Output Format

```markdown
## Judgment Day Result

### Verdict
Accepted / Fixes required / Escalate

### Evidence
- [test/build/lint/inspection evidence]

### Correctness Findings
- [finding, severity, file:line]

### Adversarial Findings
- [finding, severity, file:line]

### Required Fix Tasks
- [ ] [concrete task]

### Delta After Fixes
- [what changed and what was re-verified]
```
