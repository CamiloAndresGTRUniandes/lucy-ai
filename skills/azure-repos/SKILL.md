---
name: azure-repos
description: >
  Manage Azure Repos with CLI including repositories, pull requests, branches, policies,
  imports, and refs. Trigger: when working with Azure Repos, Azure DevOps PRs, branch
  policies, refs, or repo operations.
license: Apache-2.0
context: fork
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Azure DevOps CLI - Repos

## OpenClaw Safety Rules

- Prefer read-only/list/show commands first.
- Do not run destructive Azure DevOps commands (`delete`, `destroy`, disabling policies, removing permissions, deleting branches/repos/projects/service endpoints) without explicit user approval.
- Do not complete, merge, approve, or abandon PRs unless the user explicitly asks for that external action.
- Do not install Azure CLI/extensions with `curl | sudo bash` automatically; ask the user or use an approved package manager path.
- Never ask the user to paste PATs/secrets into chat. Prefer existing auth, managed identity, browser/device login, or environment variables configured outside the repo.
- Do not echo tokens, secrets, connection strings, or credentials into shell history, logs, files, PR comments, or work items.
- For external writes to Azure DevOps, summarize the exact target org/project/repo/work item and intended mutation before acting.

Manage Azure Repos including repositories, pull requests, branches, policies, and branch policies.

## CLI Structure

```
az repos           # Azure Repos
├── import         # Git imports
├── policy         # Branch policies
├── pr             # Pull requests
└── ref            # Git references
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

## Repositories

### List Repositories

```bash
az repos list --org https://dev.azure.com/{org} --project {project}
az repos list --output table
```

### Show Repository Details

```bash
az repos show --repository {repo-name} --project {project}
```

### Create Repository

```bash
az repos create --name {repo-name} --project {project}
```

### Delete Repository

```bash
az repos delete --id {repo-id} --project {project} --yes
```

### Update Repository

```bash
az repos update --id {repo-id} --name {new-name} --project {project}
```

## Repository Import

### Import Git Repository

```bash
# Import from public Git repository
az repos import create \
  --git-source-url https://github.com/user/repo \
  --repository {repo-name}

# Import with authentication
az repos import create \
  --git-source-url https://github.com/user/private-repo \
  --repository {repo-name} \
  --user {username} \
  --password {password-or-pat}
```

## Pull Requests

### Create Pull Request

```bash
# Basic PR creation
az repos pr create \
  --repository {repo} \
  --source-branch {source-branch} \
  --target-branch {target-branch} \
  --title "PR Title" \
  --description "PR description" \
  --open

# PR with work items
az repos pr create \
  --repository {repo} \
  --source-branch {source-branch} \
  --work-items 63 64

# Draft PR with reviewers
az repos pr create \
  --repository {repo} \
  --source-branch feature/new-feature \
  --target-branch main \
  --title "Feature: New functionality" \
  --draft true \
  --reviewers user1@example.com user2@example.com \
  --required-reviewers lead@example.com \
  --labels "enhancement" "backlog"
```

### List Pull Requests

```bash
# All PRs
az repos pr list --repository {repo}

# Filter by status
az repos pr list --repository {repo} --status active

# Filter by creator
az repos pr list --repository {repo} --creator {email}

# Output as table
az repos pr list --repository {repo} --output table
```

### Show PR Details

```bash
az repos pr show --id {pr-id}
az repos pr show --id {pr-id} --open  # Open in browser
```

### Update PR (Complete/Abandon/Draft)

```bash
# Complete PR
az repos pr update --id {pr-id} --status completed

# Abandon PR
az repos pr update --id {pr-id} --status abandoned

# Set to draft
az repos pr update --id {pr-id} --draft true

# Publish draft PR
az repos pr update --id {pr-id} --draft false

# Auto-complete when policies pass
az repos pr update --id {pr-id} --auto-complete true

# Set title and description
az repos pr update --id {pr-id} --title "New title" --description "New description"
```

### Checkout PR Locally

```bash
# Checkout PR branch
az repos pr checkout --id {pr-id}

# Checkout with specific remote
az repos pr checkout --id {pr-id} --remote-name upstream
```

### Vote on PR

```bash
az repos pr set-vote --id {pr-id} --vote approve
az repos pr set-vote --id {pr-id} --vote approve-with-suggestions
az repos pr set-vote --id {pr-id} --vote reject
az repos pr set-vote --id {pr-id} --vote wait-for-author
az repos pr set-vote --id {pr-id} --vote reset
```

### PR Reviewers

```bash
# Add reviewers
az repos pr reviewer add --id {pr-id} --reviewers user1@example.com user2@example.com

# List reviewers
az repos pr reviewer list --id {pr-id}

# Remove reviewers
az repos pr reviewer remove --id {pr-id} --reviewers user1@example.com
```

### PR Work Items

```bash
# Add work items to PR
az repos pr work-item add --id {pr-id} --work-items {id1} {id2}

# List PR work items
az repos pr work-item list --id {pr-id}

# Remove work items from PR
az repos pr work-item remove --id {pr-id} --work-items {id1}
```

### PR Policies

```bash
# List policies for a PR
az repos pr policy list --id {pr-id}

# Queue policy evaluation for a PR
az repos pr policy queue --id {pr-id} --evaluation-id {evaluation-id}
```

## Git References

### List References (Branches)

```bash
az repos ref list --repository {repo}
az repos ref list --repository {repo} --query "[?name=='refs/heads/main']"
```

### Create Reference (Branch)

```bash
az repos ref create --name refs/heads/new-branch --object-type commit --object {commit-sha}
```

### Delete Reference (Branch)

```bash
az repos ref delete --name refs/heads/old-branch --repository {repo} --project {project}
```

### Lock Branch

```bash
az repos ref lock --name refs/heads/main --repository {repo} --project {project}
```

### Unlock Branch

```bash
az repos ref unlock --name refs/heads/main --repository {repo} --project {project}
```

## Repository Policies

### List All Policies

```bash
az repos policy list --repository {repo-id} --branch main
```

### Create Policy Using Configuration File

```bash
az repos policy create --config policy.json
```

### Update/Delete Policy

```bash
# Update
az repos policy update --id {policy-id} --config updated-policy.json

# Delete
az repos policy delete --id {policy-id} --yes
```

### Policy Types

#### Approver Count Policy

```bash
az repos policy approver-count create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --minimum-approver-count 2 \
  --creator-vote-counts true
```

#### Build Policy

```bash
az repos policy build create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --build-definition-id {definition-id} \
  --queue-on-source-update-only true \
  --valid-duration 720
```

#### Work Item Linking Policy

```bash
az repos policy work-item-linking create \
  --blocking true \
  --branch main \
  --enabled true \
  --repository-id {repo-id}
```

#### Required Reviewer Policy

```bash
az repos policy required-reviewer create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --required-reviewers user@example.com
```

#### Merge Strategy Policy

```bash
az repos policy merge-strategy create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --allow-squash true \
  --allow-rebase true \
  --allow-no-fast-forward true
```

#### Case Enforcement Policy

```bash
az repos policy case-enforcement create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id}
```

#### Comment Required Policy

```bash
az repos policy comment-required create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id}
```

#### File Size Policy

```bash
az repos policy file-size create \
  --blocking true \
  --enabled true \
  --branch main \
  --repository-id {repo-id} \
  --maximum-file-size 10485760  # 10MB in bytes
```

## Common Workflows

### Create PR from current branch

```bash
CURRENT_BRANCH=$(git branch --show-current)
az repos pr create \
  --source-branch $CURRENT_BRANCH \
  --target-branch main \
  --title "Feature: $(git log -1 --pretty=%B)" \
  --open
```

### Approve and complete PR

```bash
# Vote approve
az repos pr set-vote --id {pr-id} --vote approve

# Complete PR
az repos pr update --id {pr-id} --status completed
```

### Create PR with work items and reviewers

```bash
# Create PR with work items and reviewers
PR_ID=$(az repos pr create \
  --repository "$REPO_NAME" \
  --source-branch "$FEATURE_BRANCH" \
  --target-branch main \
  --title "Feature: $(git log -1 --pretty=%B)" \
  --description "$(git log -1 --pretty=%B)" \
  --work-items $WORK_ITEM_1 $WORK_ITEM_2 \
  --reviewers "$REVIEWER_1" "$REVIEWER_2" \
  --required-reviewers "$LEAD_EMAIL" \
  --labels "enhancement" "backlog" \
  --open \
  --query "pullRequestId" -o tsv)

# Set auto-complete when policies pass
az repos pr update --id $PR_ID --auto-complete true
```

### Create automated PR from feature branch

```bash
# Create PR from feature branch with automation
create_automated_pr() {
  local branch=$1
  local title=$2

  # Get branch info
  LAST_COMMIT=$(git log -1 --pretty=%B "$branch")
  COMMIT_SHA=$(git rev-parse "$branch")

  # Find related work items
  WORK_ITEMS=$(az boards query \
    --wiql "SELECT ID FROM WorkItems WHERE [System.ChangedBy] = @Me AND [System.State] = 'Active'" \
    --query "[].id" -o tsv)

  # Create PR
  PR_ID=$(az repos pr create \
    --source-branch "$branch" \
    --target-branch main \
    --title "$title" \
    --description "$LAST_COMMIT" \
    --work-items $WORK_ITEMS \
    --auto-complete true \
    --query "pullRequestId" -o tsv)

  # Set required reviewers
  az repos pr reviewer add \
    --id $PR_ID \
    --reviewers $(git log -1 --pretty=format:'%ae' "$branch") \
    --required true

  echo "Created PR #$PR_ID"
}
```

### Apply branch policies to all repositories

```bash
# Apply branch policies to all repositories
apply_branch_policies() {
  local branch=$1
  local project=$2

  # Get all repositories
  REPOS=$(az repos list --project "$project" --query "[].id" -o tsv)

  for repo_id in $REPOS; do
    echo "Applying policies to repo: $repo_id"

    # Require minimum approvers
    az repos policy approver-count create \
      --blocking true \
      --enabled true \
      --branch "$branch" \
      --repository-id "$repo_id" \
      --minimum-approver-count 2 \
      --creator-vote-counts true

    # Require work item linking
    az repos policy work-item-linking create \
      --blocking true \
      --branch "$branch" \
      --enabled true \
      --repository-id "$repo_id"

    # Require build validation
    BUILD_ID=$(az pipelines list --query "[?name=='CI'].id" -o tsv | head -1)
    az repos policy build create \
      --blocking true \
      --enabled true \
      --branch "$branch" \
      --repository-id "$repo_id" \
      --build-definition-id "$BUILD_ID" \
      --queue-on-source-update-only true
  done
}
```

## Best Practices

### Script-Safe Output

```bash
# TSV format for shell scripts (clean, no formatting)
az repos pr list --output tsv --query "[].{ID:pullRequestId,Title:title}"

# JSON with specific fields
az repos pr list --output json --query "[].{ID:id, Title:title}"
```

### Check and Handle Errors

```bash
# Check if branch exists
if ! az repos ref list --repository "$REPO" --query "[?name=='refs/heads/$BRANCH']" -o tsv | grep -q .; then
  echo "Error: Branch $BRANCH does not exist"
  exit 1
fi
```

### Idempotent Repository Operations

```bash
# Create repository if doesn't exist
create_repo_if_new() {
  local repo_name=$1
  local project=$2

  REPO=$(az repos list --project "$project" --query "[?name=='$repo_name']" -o tsv)

  if [[ -z "$REPO" ]]; then
    echo "Creating repository: $repo_name"
    az repos create --name "$repo_name" --project "$project"
  else
    echo "Repository exists: $repo_name"
  fi
}
```

## Output Formats

PR and repository commands support standard Azure CLI formats:

```bash
# Table format (human-readable)
az repos pr list --output table

# JSON format (default)
az repos pr list --output json

# TSV format for scripting
az repos pr list --output tsv
```

## JMESPath Queries

Filter and transform repository output:

```bash
# Filter PRs by status
az repos pr list --query "[?status=='active']"

# Get specific PR fields
az repos pr list --query "[].{ID:pullRequestId, Title:title, Status:status}"

# Find PRs from specific creator
az repos pr list --query "[?createdBy.displayName=='John Doe']"
```
