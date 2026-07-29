---
name: azure-devops
description: >
  Core Azure DevOps CLI operations for authentication, configuration, projects, teams,
  users, security groups, permissions, service endpoints, wikis, and administration.
  Trigger: when working with Azure DevOps org/project administration or core az devops
  commands.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Azure DevOps CLI - Core DevOps Operations

## OpenClaw Safety Rules

- Prefer read-only/list/show commands first.
- Do not run destructive Azure DevOps commands (`delete`, `destroy`, disabling policies, removing permissions, deleting branches/repos/projects/service endpoints) without explicit user approval.
- Do not complete, merge, approve, or abandon PRs unless the user explicitly asks for that external action.
- Do not install Azure CLI/extensions with `curl | sudo bash` automatically; ask the user or use an approved package manager path.
- Never ask the user to paste PATs/secrets into chat. Prefer existing auth, managed identity, browser/device login, or environment variables configured outside the repo.
- Do not echo tokens, secrets, connection strings, or credentials into shell history, logs, files, PR comments, or work items.
- For external writes to Azure DevOps, summarize the exact target org/project/repo/work item and intended mutation before acting.

Manage core Azure DevOps resources including authentication, projects, teams, users, security, and administration.

**CLI Version:** 2.81.0 (current as of 2025)

## CLI Structure

```
az devops          # Main DevOps commands
├── admin          # Administration (banner)
├── extension      # Extension management
├── project        # Team projects
├── security       # Security operations
│   ├── group      # Security groups
│   └── permission # Security permissions
├── service-endpoint # Service connections
├── team           # Teams
├── user           # Users
├── wiki           # Wikis
├── configure      # Set defaults
├── invoke         # Invoke REST API
├── login          # Authenticate
└── logout         # Clear credentials
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

## Extension Management

### List Extensions

```bash
# List available extensions
az extension list-available --output table

# List installed extensions
az extension list --output table
```

### Manage Azure DevOps Extension

```bash
# Install Azure DevOps extension
az extension add --name azure-devops

# Update Azure DevOps extension
az extension update --name azure-devops

# Remove extension
az extension remove --name azure-devops

# Install from local path
az extension add --source ~/extensions/azure-devops.whl
```

## Projects

### List Projects

```bash
az devops project list --organization https://dev.azure.com/{org}
az devops project list --top 10 --output table
```

### Create Project

```bash
az devops project create \
  --name myNewProject \
  --organization https://dev.azure.com/{org} \
  --description "My new DevOps project" \
  --source-control git \
  --visibility private
```

### Show Project Details

```bash
az devops project show --project {project-name} --org https://dev.azure.com/{org}
```

### Delete Project

```bash
az devops project delete --id {project-id} --org https://dev.azure.com/{org} --yes
```

## Teams

### List Teams

```bash
az devops team list --project {project}
```

### Show Team

```bash
az devops team show --team {team-name} --project {project}
```

### Create Team

```bash
az devops team create \
  --name {team-name} \
  --description "Team description" \
  --project {project}
```

### Update Team

```bash
az devops team update \
  --team {team-name} \
  --project {project} \
  --name "{new-team-name}" \
  --description "Updated description"
```

### Delete Team

```bash
az devops team delete --team {team-name} --project {project} --yes
```

### Show Team Members

```bash
az devops team list-member --team {team-name} --project {project}
```

## Users

### List Users

```bash
az devops user list --org https://dev.azure.com/{org}
az devops user list --top 10 --output table
```

### Show User

```bash
az devops user show --user {user-id-or-email} --org https://dev.azure.com/{org}
```

### Add User

```bash
az devops user add \
  --email user@example.com \
  --license-type express \
  --org https://dev.azure.com/{org}
```

### Update User

```bash
az devops user update \
  --user {user-id-or-email} \
  --license-type advanced \
  --org https://dev.azure.com/{org}
```

### Remove User

```bash
az devops user remove --user {user-id-or-email} --org https://dev.azure.com/{org} --yes
```

## Security Groups

### List Groups

```bash
# List all groups in project
az devops security group list --project {project}

# List all groups in organization
az devops security group list --scope organization

# List with filtering
az devops security group list --project {project} --subject-types vstsgroup
```

### Show Group Details

```bash
az devops security group show --group-id {group-id}
```

### Create Group

```bash
az devops security group create \
  --name {group-name} \
  --description "Group description" \
  --project {project}
```

### Update Group

```bash
az devops security group update \
  --group-id {group-id} \
  --name "{new-group-name}" \
  --description "Updated description"
```

### Delete Group

```bash
az devops security group delete --group-id {group-id} --yes
```

### Group Memberships

```bash
# List memberships
az devops security group membership list --id {group-id}

# Add member
az devops security group membership add \
  --group-id {group-id} \
  --member-id {member-id}

# Remove member
az devops security group membership remove \
  --group-id {group-id} \
  --member-id {member-id} --yes
```

## Security Permissions

### List Namespaces

```bash
az devops security permission namespace list
```

### Show Namespace Details

```bash
# Show permissions available in a namespace
az devops security permission namespace show --namespace "GitRepositories"
```

### List Permissions

```bash
# List permissions for user/group and namespace
az devops security permission list \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project}

# List for specific token (repository)
az devops security permission list \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}"
```

### Show Permissions

```bash
az devops security permission show \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}"
```

### Update Permissions

```bash
# Grant permission
az devops security permission update \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}" \
  --permission-mask "Pull,Contribute"

# Deny permission
az devops security permission update \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}" \
  --permission-mask 0
```

### Reset Permissions

```bash
# Reset specific permission bits
az devops security permission reset \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}" \
  --permission-mask "Pull,Contribute"

# Reset all permissions
az devops security permission reset-all \
  --id {user-or-group-id} \
  --namespace "GitRepositories" \
  --project {project} \
  --token "repoV2/{project}/{repository-id}" --yes
```

## Service Endpoints

### List Service Endpoints

```bash
az devops service-endpoint list --project {project}
az devops service-endpoint list --project {project} --output table
```

### Show Service Endpoint

```bash
az devops service-endpoint show --id {endpoint-id} --project {project}
```

### Create Service Endpoint

```bash
# Using configuration file
az devops service-endpoint create --service-endpoint-configuration endpoint.json --project {project}
```

### Delete Service Endpoint

```bash
az devops service-endpoint delete --id {endpoint-id} --project {project} --yes
```

## Wikis

### List Wikis

```bash
# List all wikis in project
az devops wiki list --project {project}

# List all wikis in organization
az devops wiki list
```

### Show Wiki

```bash
az devops wiki show --wiki {wiki-name} --project {project}
az devops wiki show --wiki {wiki-name} --project {project} --open
```

### Create Wiki

```bash
# Create project wiki
az devops wiki create \
  --name {wiki-name} \
  --project {project} \
  --type projectWiki

# Create code wiki from repository
az devops wiki create \
  --name {wiki-name} \
  --project {project} \
  --type codeWiki \
  --repository {repo-name} \
  --mapped-path /wiki
```

### Delete Wiki

```bash
az devops wiki delete --wiki {wiki-id} --project {project} --yes
```

### Wiki Pages

```bash
# List pages
az devops wiki page list --wiki {wiki-name} --project {project}

# Show page
az devops wiki page show \
  --wiki {wiki-name} \
  --path "/page-name" \
  --project {project}

# Create page
az devops wiki page create \
  --wiki {wiki-name} \
  --path "/new-page" \
  --content "# New Page\n\nPage content here..." \
  --project {project}

# Update page
az devops wiki page update \
  --wiki {wiki-name} \
  --path "/existing-page" \
  --content "# Updated Page\n\nNew content..." \
  --project {project}

# Delete page
az devops wiki page delete \
  --wiki {wiki-name} \
  --path "/old-page" \
  --project {project} --yes
```

## Administration

### Banner Management

```bash
# List banners
az devops admin banner list

# Show banner details
az devops admin banner show --id {banner-id}

# Add new banner
az devops admin banner add \
  --message "System maintenance scheduled" \
  --level info  # info, warning, error

# Update banner
az devops admin banner update \
  --id {banner-id} \
  --message "Updated message" \
  --level warning \
  --expiration-date "2025-12-31T23:59:59Z"

# Remove banner
az devops admin banner remove --id {banner-id}
```

## DevOps Extensions

Manage extensions installed in an Azure DevOps organization (different from CLI extensions).

```bash
# List installed extensions
az devops extension list --org https://dev.azure.com/{org}

# Search marketplace extensions
az devops extension search --search-query "docker"

# Show extension details
az devops extension show --ext-id {extension-id} --org https://dev.azure.com/{org}

# Install extension
az devops extension install \
  --ext-id {extension-id} \
  --org https://dev.azure.com/{org} \
  --publisher {publisher-id}

# Enable extension
az devops extension enable \
  --ext-id {extension-id} \
  --org https://dev.azure.com/{org}

# Disable extension
az devops extension disable \
  --ext-id {extension-id} \
  --org https://dev.azure.com/{org}

# Uninstall extension
az devops extension uninstall \
  --ext-id {extension-id} \
  --org https://dev.azure.com/{org} --yes
```

## Common Parameters

| Parameter                  | Description                                                         |
| -------------------------- | ------------------------------------------------------------------- |
| `--org` / `--organization` | Azure DevOps organization URL (e.g., `https://dev.azure.com/{org}`) |
| `--project` / `-p`         | Project name or ID                                                  |
| `--detect`                 | Auto-detect organization from git config                            |
| `--yes` / `-y`             | Skip confirmation prompts                                           |
| `--open`                   | Open in web browser                                                 |

## Best Practices

### Authentication and Security

```bash
# Use PAT from environment variable (most secure)
# Prefer preconfigured secure environment variables; never paste PATs in chat
az devops login --organization $ORG_URL

# Pipe PAT securely (avoids shell history)
# Avoid echoing PATs; use secure prompt/env configured outside repo

# Set defaults to avoid repetition
az devops configure --defaults organization=$ORG_URL project=$PROJECT

# Clear credentials after use
az devops logout --organization $ORG_URL
```
