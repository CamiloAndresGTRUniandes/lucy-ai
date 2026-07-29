---
name: ado-refinement
description: >
  Guide Azure Boards refinement with mandatory runtime questions, user story constraints,
  and bug hygiene rules. Trigger: when refining or creating ADO User Story, Feature, or
  Bug items.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# ado-refinement

## OpenClaw Usage Notes

- These ADO workflow skills complement SDD; they do not replace SDD phase approvals.
- Ask only for missing Azure DevOps context that cannot be safely discovered.
- Do not create/update Azure Boards items unless the user explicitly asks for that external write.
- Keep project-specific conventions in the repo or ADO project documentation, not in this generic skill.

## When to Use

Use when defining or refining Azure Boards User Story, Feature, and Bug items.

## Rules

- Ask for `ProjectName` and Azure DevOps project link at the start of each session.
- Validate that the link points to the same project named in `ProjectName` before producing item content.
- Use `ado-us-ac-template` format by default for acceptance criteria unless the user asks for another template.
- For User Story, keep Description limited to one statement: `As a ... I want to ... so that ...`.
- Put detailed functional scope and context in Acceptance Criteria sections, not in Description.
- For Feature, require both a related Requirement link and an Epic parent; if missing, ask for them before creation.
- For Bug, ask: environment, release version (if TST/QA), current behavior, and expected behavior.
- For Bug, use the embedded canonical bug template in this skill.
- For Bug, do not use Description and always populate Repro Steps.
- Bug title format is `{ProjectName} - <FE|BE> - <short issue summary>`.
- Tag rules: add `TST` for TST/test; add `release/<version>` for TST/QA.

## Canonical Bug Template

- Work Item Type: Bug
- Title format: `{ProjectName} - <FE|BE> - <short issue summary>`
- Description: empty
- Repro Steps: required
- Required questions:
  1. Environment (TST/QA/PROD/etc.)
  2. Release version (required for TST/QA)
  3. Current behavior and expected behavior
- Repro Steps structure:
  - Environment
  - Release
  - Current behavior
  - Expected behavior
  - Steps to reproduce
  - Impact
