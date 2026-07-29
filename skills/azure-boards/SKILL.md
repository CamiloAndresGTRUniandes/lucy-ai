---
name: azure-boards
description: >
  Manage Azure Boards with CLI including work items, queries, areas, iterations, and work
  item relations. Trigger: when working with Azure Boards, work items, WIQL, sprints,
  area paths, or Azure DevOps planning.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Azure DevOps CLI - Boards

## OpenClaw Safety Rules

- Prefer read-only/list/show commands first.
- Do not run destructive Azure DevOps commands (`delete`, `destroy`, disabling policies, removing permissions, deleting branches/repos/projects/service endpoints) without explicit user approval.
- Do not complete, merge, approve, or abandon PRs unless the user explicitly asks for that external action.
- Do not install Azure CLI/extensions with `curl | sudo bash` automatically; ask the user or use an approved package manager path.
- Never ask the user to paste PATs/secrets into chat. Prefer existing auth, managed identity, browser/device login, or environment variables configured outside the repo.
- Do not echo tokens, secrets, connection strings, or credentials into shell history, logs, files, PR comments, or work items.
- For external writes to Azure DevOps, summarize the exact target org/project/repo/work item and intended mutation before acting.

Manage Azure Boards including work items, queries, areas, iterations, and work item relationships.

## CLI Structure

```
az boards          # Azure Boards
├── area           # Area paths
├── iteration      # Iterations
└── work-item      # Work items
```

### Configure Defaults

```bash
# Set default organization and project
az devops configure --defaults organization=https://dev.azure.com/{org} project={project}

# List current configuration
az devops configure --list

# Enable Git aliases
az devops configure --use-git-aliases true
```

## Work Items

### Query Work Items

```bash
# WIQL query
az boards query \
  --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] = 'Active'"

# Query with output format
az boards query --wiql "SELECT * FROM WorkItems" --output table
```

### Show Work Item

```bash
az boards work-item show --id {work-item-id}
az boards work-item show --id {work-item-id} --open
```

### Create Work Item

```bash
# Basic work item
az boards work-item create \
  --title "Fix login bug" \
  --type Bug \
  --assigned-to user@example.com \
  --description "Users cannot login with SSO"

# With area and iteration
az boards work-item create \
  --title "New feature" \
  --type "User Story" \
  --area "Project\\Area1" \
  --iteration "Project\\Sprint 1"

# With custom fields
az boards work-item create \
  --title "Task" \
  --type Task \
  --fields "Priority=1" "Severity=2"

# With discussion comment
az boards work-item create \
  --title "Issue" \
  --type Bug \
  --discussion "Initial investigation completed"

# Open in browser after creation
az boards work-item create --title "Bug" --type Bug --open
```

### Update Work Item

```bash
# Update state, title, and assignee
az boards work-item update \
  --id {work-item-id} \
  --state "Active" \
  --title "Updated title" \
  --assigned-to user@example.com

# Move to different area
az boards work-item update \
  --id {work-item-id} \
  --area "{ProjectName}\\{Team}\\{Area}"

# Change iteration
az boards work-item update \
  --id {work-item-id} \
  --iteration "{ProjectName}\\Sprint 5"

# Add comment/discussion
az boards work-item update \
  --id {work-item-id} \
  --discussion "Work in progress"

# Update with custom fields
az boards work-item update \
  --id {work-item-id} \
  --fields "Priority=1" "StoryPoints=5"
```

### Delete Work Item

```bash
# Soft delete (can be restored)
az boards work-item delete --id {work-item-id} --yes

# Permanent delete
az boards work-item delete --id {work-item-id} --destroy --yes
```

### Work Item Relations

```bash
# List relations
az boards work-item relation list --id {work-item-id}

# List supported relation types
az boards work-item relation list-type

# Add relation
az boards work-item relation add --id {work-item-id} --relation-type parent --target-id {parent-id}

# Remove relation
az boards work-item relation remove --id {work-item-id} --relation-id {relation-id}
```

## Area Paths

### List Areas for Project

```bash
az boards area project list --project {project}
az boards area project show --path "Project\\Area1" --project {project}
```

### Create Area

```bash
az boards area project create --path "Project\\NewArea" --project {project}
```

### Update Area

```bash
az boards area project update \
  --path "Project\\OldArea" \
  --new-path "Project\\UpdatedArea" \
  --project {project}
```

### Delete Area

```bash
az boards area project delete --path "Project\\AreaToDelete" --project {project} --yes
```

### Area Team Management

```bash
# List areas for team
az boards area team list --team {team-name} --project {project}

# Add area to team
az boards area team add \
  --team {team-name} \
  --path "Project\\NewArea" \
  --project {project}

# Remove area from team
az boards area team remove \
  --team {team-name} \
  --path "Project\\AreaToRemove" \
  --project {project}

# Update team area
az boards area team update \
  --team {team-name} \
  --path "Project\\Area" \
  --project {project} \
  --include-sub-areas true
```

## Iterations

### List Iterations for Project

```bash
az boards iteration project list --project {project}
az boards iteration project show --path "Project\\Sprint 1" --project {project}
```

### Create Iteration

```bash
az boards iteration project create --path "Project\\Sprint 1" --project {project}
```

### Update Iteration

```bash
az boards iteration project update \
  --path "Project\\OldSprint" \
  --new-path "Project\\NewSprint" \
  --project {project}
```

### Delete Iteration

```bash
az boards iteration project delete --path "Project\\OldSprint" --project {project} --yes
```

### List Iterations for Team

```bash
az boards iteration team list --team {team-name} --project {project}
```

### Add Iteration to Team

```bash
az boards iteration team add \
  --team {team-name} \
  --path "Project\\Sprint 1" \
  --project {project}
```

### Remove Iteration from Team

```bash
az boards iteration team remove \
  --team {team-name} \
  --path "Project\\Sprint 1" \
  --project {project}
```

### List Work Items in Iteration

```bash
az boards iteration team list-work-items \
  --team {team-name} \
  --path "Project\\Sprint 1" \
  --project {project}
```

### Set Default Iteration for Team

```bash
az boards iteration team set-default-iteration \
  --team {team-name} \
  --path "Project\\Sprint 1" \
  --project {project}
```

### Show Default Iteration

```bash
az boards iteration team show-default-iteration \
  --team {team-name} \
  --project {project}
```

### Set Backlog Iteration for Team

```bash
az boards iteration team set-backlog-iteration \
  --team {team-name} \
  --path "Project\\Sprint 1" \
  --project {project}
```

### Show Backlog Iteration

```bash
az boards iteration team show-backlog-iteration \
  --team {team-name} \
  --project {project}
```

### Show Current Iteration

```bash
az boards iteration team show --team {team-name} --project {project} --timeframe current
```

## Common Workflows

### Create work item on pipeline failure

```bash
az boards work-item create \
  --title "Build $BUILD_BUILDNUMBER failed" \
  --type bug \
  --org $SYSTEM_TEAMFOUNDATIONCOLLECTIONURI \
  --project $SYSTEM_TEAMPROJECT
```

### Bulk update work items

```bash
# Query items and update in loop
for id in $(az boards query --wiql "SELECT ID FROM WorkItems WHERE State='New'" -o tsv); do
  az boards work-item update --id $id --state "Active"
done
```

### Create work item only if doesn't exist

```bash
# Create work item only if doesn't exist with same title
create_work_item_if_new() {
  local title=$1
  local type=$2

  WI_ID=$(az boards query \
    --wiql "SELECT ID FROM WorkItems WHERE [System.WorkItemType]='$type' AND [System.Title]='$title'" \
    --query "[0].id" -o tsv)

  if [[ -z "$WI_ID" ]]; then
    echo "Creating work item: $title"
    WI_ID=$(az boards work-item create --title "$title" --type "$type" --query "id" -o tsv)
  else
    echo "Work item exists: $title (ID: $WI_ID)"
  fi

  echo "$WI_ID"
}
```

### Bulk idempotent work item operations

```bash
# Ensure multiple work items exist
declare -a WORK_ITEMS=(
  "Feature One:User Story"
  "Feature Two:User Story"
  "Bug Fix:Bug"
)

for item in "${WORK_ITEMS[@]}"; do
  IFS=':' read -r title type <<< "$item"
  create_work_item_if_new "$title" "$type"
done
```

## Best Practices

### Query Complex Scenarios

```bash
# Find work items assigned to current user
az boards query --wiql "SELECT ID, Title, State FROM WorkItems WHERE [System.AssignedTo] = @Me"

# Find items in current sprint
az boards query --wiql "SELECT ID, Title, State FROM WorkItems WHERE [System.IterationPath] = @CurrentIteration"

# Find high priority bugs
az boards query --wiql "SELECT ID, Title, State FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [Priority] = 1"

# Find items by area
az boards query --wiql "SELECT ID, Title FROM WorkItems WHERE [System.AreaPath] UNDER 'Project\\Team'"
```

### Work Item State Management

```bash
# Transition work item through states
az boards work-item update --id 123 --state "Active"
az boards work-item update --id 123 --state "Resolved"
az boards work-item update --id 123 --state "Closed"
```

### Team Planning

```bash
# List all areas for team planning
az boards area team list --team "Development" --project "MyProject"

# List upcoming iterations
az boards iteration team list --team "Development" --project "MyProject"

# Add new sprint to team
az boards iteration team add \
  --team "Development" \
  --path "MyProject\\Sprint 10" \
  --project "MyProject"
```

## Output Formats

The work item commands support standard Azure CLI output formats:

```bash
# Table format (human-readable)
az boards work-item show --id 123 --output table

# JSON format (default)
az boards work-item show --id 123 --output json

# TSV format for scripting
az boards query --wiql "SELECT ID FROM WorkItems" --output tsv
```

## JMESPath Queries

Filter and transform work item output:

```bash
# Get specific fields from work item
az boards work-item show --id 123 --query "fields.{Title:'System.Title', State:'System.State'}"

# Format work item data
az boards work-item show --id 123 --query "{ID:id, Title:fields['System.Title']}"
```
