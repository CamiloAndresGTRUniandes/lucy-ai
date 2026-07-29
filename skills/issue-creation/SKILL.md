---
name: issue-creation
description: >
  Create clear issue drafts with reproducible context, acceptance criteria, and definition of done.
  Trigger: when the user asks to open a bug report, feature request, chore, or tracking issue.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Issue Creation Workflow

## When to Use

Use for drafting or creating actionable backlog items in GitHub, Azure Boards, or another tracker.

## Rules

- Draft issue content first when important details are missing.
- Do not create an external issue unless the user explicitly asks for that write.
- Capture problem statement and expected behavior.
- Include reproducible steps for bugs or concrete scope details for features.
- Add acceptance criteria and definition of done.
- Label issue intent clearly: bug, feature, chore, docs, refactor, security, etc.
- Return created issue URL with a short summary after creation.

## Template

```markdown
## Summary
[One sentence]

## Context / Problem
[What is happening and why it matters]

## Expected Behavior
[What should happen]

## Scope
- [In scope]
- [Out of scope]

## Acceptance Criteria
- [ ] [Concrete, testable criterion]

## Definition of Done
- [ ] Tests/docs/validation updated
- [ ] Security/accessibility/performance considered where relevant

## Evidence
[Logs, screenshots, links, reproduction steps]
```
