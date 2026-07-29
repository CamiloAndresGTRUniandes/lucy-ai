---
name: ado-us-ac-template
description: >
  Reusable acceptance-criteria template based on Azure Boards US 26064 formatting.
  Trigger: when drafting or refining User Story acceptance criteria for Azure Boards.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# ado-us-ac-template

## OpenClaw Usage Notes

- These ADO workflow skills complement SDD; they do not replace SDD phase approvals.
- Ask only for missing Azure DevOps context that cannot be safely discovered.
- Do not create/update Azure Boards items unless the user explicitly asks for that external write.
- Keep project-specific conventions in the repo or ADO project documentation, not in this generic skill.

## When to Use

Use to format User Story acceptance criteria with the same structure validated from Azure Boards US 26064.

## Rules

- Ask for `ProjectName` and Azure DevOps project link each session before drafting acceptance criteria.
- Keep Description as one line in the format `As a ... I want to ... so that ...`.
- Place functional scope and context in Acceptance Criteria sections, not in Description.
- Use numbered section titles in acceptance criteria.
- Under each section, use bullet points for concrete behaviors.
- Separate major sections with horizontal separators.
- Mark optional or deferred sections explicitly when they are intentionally out of current scope.
- Apply this format by default for future user stories and refinements unless the user asks for a different template.

## Template Skeleton

1. <Section Title>
- <Expected behavior 1>
- <Expected behavior 2>

---

2. <Section Title>
- <Expected behavior 1>
- <Expected behavior 2>

---

3. <Section Title>
- <Expected behavior 1>
- <Expected behavior 2>

---

Optional/Deferred Section
- <Marked as optional/deferred>
