---
name: ado-effort-estimation
description: >
  Estimate Azure Boards work with a mandatory clarifying-question gate and story-point
  guardrails. Trigger: when the user asks for effort sizing or story-point estimation.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# ado-effort-estimation

## OpenClaw Usage Notes

- These ADO workflow skills complement SDD; they do not replace SDD phase approvals.
- Ask only for missing Azure DevOps context that cannot be safely discovered.
- Do not create/update Azure Boards items unless the user explicitly asks for that external write.
- Keep project-specific conventions in the repo or ADO project documentation, not in this generic skill.

## When to Use

Use when estimating User Story effort for Azure Boards.

## Rules

- Ask for `ProjectName` and Azure DevOps project link at the start of each session.
- Validate `ProjectName` against the project in the provided link before estimating.
- Ask clarifying questions before assigning points. Do not estimate before clarification is complete.
- Clarifying questions must cover at least: work scope, risk, dependencies, unknowns, and test effort.
- Use the story-point table below as the authoritative sizing guide.
- If required estimation context is missing, ask for missing information and hold the estimate.
- Preserve hard mapping rules: `8 -> Spark` and `13 -> Split`.

## Story Point Sizing Guide

| Story Points | Work | Risk | Dependencies | Unknowns | Explanation |
|-------------|------|------|--------------|----------|-------------|
| 0.5+ | Piece of cake | - | - | - | Trivial work with virtually no risk, dependencies, or uncertainty. |
| 1+ | No-brainer | - | - | - | Very small and straightforward task with low effort. |
| 2 | Some | Little | Could be | - | Small task with minor risk or dependency. |
| 3 | Much | Some | Some | Could be | Medium-sized task with noticeable effort and uncertainty. |
| 5 | A lot | Much | Many | Some | Large task with significant effort and coordination. |
| 8 | Huge | A lot | A lot | Many | Complex task. Run a Spark first to reduce uncertainty. |
| 13 | High | High | High | High | Too large for one story. Split into smaller stories. |

## Threshold Guidance

- 0.5 to 3: ready to build.
- 5: significant story; review carefully.
- 8: Spark required before committing implementation.
- 13: Split required before implementation.
