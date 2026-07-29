---
name: ado-context
description: >
  Unified Azure DevOps context skill for SDD/refinement phases. Trigger: when SDD or
  refinement needs Azure DevOps project, work item, comment, relation, or traceability
  context.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# ADO Context

## OpenClaw Usage Notes

- These ADO workflow skills complement SDD; they do not replace SDD phase approvals.
- Ask only for missing Azure DevOps context that cannot be safely discovered.
- Do not create/update Azure Boards items unless the user explicitly asks for that external write.
- Keep project-specific conventions in the repo or ADO project documentation, not in this generic skill.

Use this skill when a phase requires Azure DevOps context in a dry-run or live mode.

## Depends On

- azure-devops
- azure-boards

## Required Context Capture

For each relevant work item, capture:
- Organization and project
- Work item id, type, title, state
- Description and acceptance criteria
- Comments/discussion and history
- Linked items/relations

## Recommended CLI Flow

```bash
# Set defaults
az devops configure --defaults organization=https://dev.azure.com/{org} project={project}

# Read related items (WIQL)
az boards query --wiql "SELECT [System.Id],[System.Title],[System.State] FROM WorkItems WHERE [System.Id] IN ({ids})"

# Read item details
az boards work-item show --id {id} --output json
```

## Phase Mapping

- Explore: discover and summarize context from related items
- Spec: enrich requirements and AC from item content/comments
- Design: link decisions to related epics/features
- Verify: map AC -> tests -> implementation -> ADO references
