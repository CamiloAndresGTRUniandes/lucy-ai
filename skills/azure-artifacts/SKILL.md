---
name: azure-artifacts
description: >
  Manage Azure Artifacts with CLI including universal package publishing, downloading,
  and artifact management. Trigger: when working with Azure Artifacts feeds, universal
  packages, package publish/download, or artifact promotion.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Azure DevOps CLI - Artifacts

## OpenClaw Safety Rules

- Prefer read-only/list/show commands first.
- Do not run destructive Azure DevOps commands (`delete`, `destroy`, disabling policies, removing permissions, deleting branches/repos/projects/service endpoints) without explicit user approval.
- Do not complete, merge, approve, or abandon PRs unless the user explicitly asks for that external action.
- Do not install Azure CLI/extensions with `curl | sudo bash` automatically; ask the user or use an approved package manager path.
- Never ask the user to paste PATs/secrets into chat. Prefer existing auth, managed identity, browser/device login, or environment variables configured outside the repo.
- Do not echo tokens, secrets, connection strings, or credentials into shell history, logs, files, PR comments, or work items.
- For external writes to Azure DevOps, summarize the exact target org/project/repo/work item and intended mutation before acting.

Manage Azure Artifacts including publishing and downloading universal packages.

## CLI Structure

```
az artifacts       # Azure Artifacts
└── universal      # Universal Packages
    ├── download   # Download packages
    └── publish    # Publish packages
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

## Universal Packages

Universal Packages are a simple, flexible way to store and manage packages in Azure Artifacts.

### Publish Package

```bash
az artifacts universal publish \
  --feed {feed-name} \
  --name {package-name} \
  --version {version} \
  --path {package-path} \
  --project {project}
```

### Download Package

```bash
az artifacts universal download \
  --feed {feed-name} \
  --name {package-name} \
  --version {version} \
  --path {download-path} \
  --project {project}
```

## Common Workflows

### Publish application to artifacts

```bash
# Publish application artifacts
publish_app_artifacts() {
  local app_name=$1
  local version=$2
  local feed_name="releases"
  
  # Create package directory
  mkdir -p ./artifacts/$app_name
  
  # Copy application files
  cp -r ./dist/* ./artifacts/$app_name/
  
  # Publish to artifacts
  az artifacts universal publish \
    --feed "$feed_name" \
    --name "$app_name" \
    --version "$version" \
    --path ./artifacts/$app_name \
    --project "$PROJECT"
    
  echo "Published $app_name version $version"
}
```

### Download and deploy application

```bash
# Download and deploy from artifacts
deploy_app_from_artifacts() {
  local app_name=$1
  local version=$2
  local deploy_path=$3
  local feed_name="releases"
  
  # Create deployment directory
  mkdir -p "$deploy_path"
  
  # Download from artifacts
  az artifacts universal download \
    --feed "$feed_name" \
    --name "$app_name" \
    --version "$version" \
    --path "$deploy_path" \
    --project "$PROJECT"
    
  echo "Downloaded $app_name version $version to $deploy_path"
}
```

### Multi-stage artifact pipeline

```bash
# Download build artifacts and publish to artifacts feed
promote_build_artifacts() {
  local pipeline_run_id=$1
  local artifact_name=$2
  local package_name=$3
  local version=$4
  
  # Download from pipeline run
  echo "Downloading artifacts from pipeline run $pipeline_run_id"
  az pipelines runs artifact download \
    --artifact-name "$artifact_name" \
    --path ./build-output \
    --run-id "$pipeline_run_id"
  
  # Publish to artifacts feed
  echo "Publishing to artifacts feed"
  az artifacts universal publish \
    --feed "releases" \
    --name "$package_name" \
    --version "$version" \
    --path ./build-output \
    --project "$PROJECT"
    
  echo "Promoted artifacts to release feed"
}
```

### Artifact versioning strategy

```bash
# Publish with semantic versioning
publish_versioned_artifact() {
  local app_name=$1
  local major=$2
  local minor=$3
  local patch=$4
  local version="$major.$minor.$patch"
  
  echo "Publishing version: $version"
  
  az artifacts universal publish \
    --feed "releases" \
    --name "$app_name" \
    --version "$version" \
    --path ./dist \
    --project "$PROJECT"
}
```

### Release preparation workflow

```bash
# Complete release workflow: build, test, publish
create_release_from_branch() {
  local app_name=$1
  local source_branch=$2
  local major=$3
  local minor=$4
  local patch=$5
  
  local version="$major.$minor.$patch"
  
  # Run build pipeline
  echo "Building version $version..."
  RUN_ID=$(az pipelines run \
    --name "Build-$app_name" \
    --parameters VERSION=$version \
    --query "id" -o tsv)
  
  # Wait for build completion
  while true; do
    STATUS=$(az pipelines runs show --run-id $RUN_ID --query "status" -o tsv)
    if [[ "$STATUS" != "inProgress" ]]; then
      break
    fi
    sleep 10
  done
  
  # Check build result
  RESULT=$(az pipelines runs show --run-id $RUN_ID --query "result" -o tsv)
  if [[ "$RESULT" != "succeeded" ]]; then
    echo "Build failed"
    return 1
  fi
  
  # Download build artifacts
  ARTIFACT_NAME=$(az pipelines runs artifact list --run-id $RUN_ID --query "[0].name" -o tsv)
  az pipelines runs artifact download \
    --artifact-name "$ARTIFACT_NAME" \
    --path ./release-artifacts \
    --run-id $RUN_ID
  
  # Publish to artifacts feed
  az artifacts universal publish \
    --feed "releases" \
    --name "$app_name" \
    --version "$version" \
    --path ./release-artifacts \
    --project "$PROJECT"
    
  echo "Released $app_name version $version successfully"
}
```

### Artifact backup and archival

```bash
# Backup artifacts periodically
backup_artifacts() {
  local feed_name=$1
  local backup_date=$(date +%Y-%m-%d)
  local backup_dir="./artifacts-backup-$backup_date"
  
  mkdir -p "$backup_dir"
  
  # Download all artifacts (this would need to be done per package)
  # This is a placeholder showing the concept
  echo "Backing up artifacts feed: $feed_name"
  
  # Metadata backup
  az artifacts universal list \
    --feed "$feed_name" \
    --project "$PROJECT" \
    --output json > "$backup_dir/feed-metadata.json"
  
  echo "Artifacts backed up to $backup_dir"
}
```

## Best Practices

### Version Management

```bash
# Always use semantic versioning
# Format: MAJOR.MINOR.PATCH
# Example: 1.0.0, 1.2.3, 2.0.0-beta

# For pre-release versions, include suffix
# Example: 1.0.0-alpha, 1.0.0-beta, 1.0.0-rc1
```

### Package Organization

```bash
# Organize packages by application/component
# Example feed structure:
# - webapp-frontend@1.0.0
# - webapp-backend@1.0.0
# - shared-client-lib@2.0.0
# - shared-utils@1.5.2
```

### Download Strategy

```bash
# Always specify exact version to ensure reproducibility
az artifacts universal download \
  --feed "releases" \
  --name "myapp" \
  --version "1.0.0" \  # Never use 'latest' in automation
  --path ./deploy \
  --project "$PROJECT"
```

### Artifact Cleanup

```bash
# Implement retention policies
# Keep only recent versions to manage storage:
# - Keep last 10 releases
# - Keep all LTS versions
# - Archive older releases to separate storage
```

### Feed Organization

```bash
# Create separate feeds for different stages
# - "ci-builds": Intermediate builds (retention: 7 days)
# - "releases": Stable releases (retention: 2 years)
# - "archived": Old releases (retention: 5 years)

# This approach provides:
# - Fast feedback on CI builds
# - Stable release artifacts
# - Historical audit trail
```

## Artifact Management Scenarios

### Development to Production Workflow

```bash
# Developer publishes to CI feed
az artifacts universal publish \
  --feed "ci-builds" \
  --name "myapp" \
  --version "1.0.0-dev.1" \
  --path ./built-artifacts \
  --project "$PROJECT"

# QA tests from CI feed
az artifacts universal download \
  --feed "ci-builds" \
  --name "myapp" \
  --version "1.0.0-dev.1" \
  --path ./qa-test \
  --project "$PROJECT"

# After QA approval, promote to releases feed
az artifacts universal publish \
  --feed "releases" \
  --name "myapp" \
  --version "1.0.0" \
  --path ./approved-artifacts \
  --project "$PROJECT"

# Production deployment from releases feed
az artifacts universal download \
  --feed "releases" \
  --name "myapp" \
  --version "1.0.0" \
  --path ./prod-deploy \
  --project "$PROJECT"
```

### Dependency Management

```bash
# Publish shared library
az artifacts universal publish \
  --feed "libraries" \
  --name "shared-lib" \
  --version "2.0.0" \
  --path ./lib-dist \
  --project "$PROJECT"

# Download dependency in another project
az artifacts universal download \
  --feed "libraries" \
  --name "shared-lib" \
  --version "2.0.0" \
  --path ./dependencies \
  --project "$PROJECT"
```

## Integration Patterns

### CI/CD Pipeline Integration

```bash
# In build pipeline: publish after successful build
if [[ "$BUILD_STATUS" == "succeeded" ]]; then
  az artifacts universal publish \
    --feed "ci-builds" \
    --name "$APP_NAME" \
    --version "$BUILD_VERSION" \
    --path ./dist \
    --project "$PROJECT"
fi
```

### Release Pipeline Integration

```bash
# In release pipeline: download and deploy
az artifacts universal download \
  --feed "releases" \
  --name "$APP_NAME" \
  --version "$RELEASE_VERSION" \
  --path ./deployment \
  --project "$PROJECT"

# Deploy the downloaded artifact
./deployment/install.sh
```

## Output Formats

Artifact commands support standard Azure CLI formats:

```bash
# JSON format (default)
az artifacts universal list --feed {feed-name} --output json

# Table format
az artifacts universal list --feed {feed-name} --output table
```

## Error Handling

### Retry Pattern for Downloads

```bash
# Retry downloading artifact if temporary failure
retry_download() {
  local feed=$1
  local package=$2
  local version=$3
  local path=$4
  local max_attempts=3
  local attempt=1

  while [[ $attempt -le $max_attempts ]]; do
    if az artifacts universal download \
      --feed "$feed" \
      --name "$package" \
      --version "$version" \
      --path "$path" \
      --project "$PROJECT" 2>/dev/null; then
      return 0
    fi
    
    echo "Attempt $attempt failed. Retrying..."
    ((attempt++))
    sleep 5
  done

  echo "Failed to download after $max_attempts attempts"
  return 1
}
```

### Checksum Validation

```bash
# After downloading, validate package integrity
validate_package() {
  local package_path=$1
  local expected_checksum=$2

  if [[ -f "$package_path/checksum.txt" ]]; then
    actual_checksum=$(cat "$package_path/checksum.txt")
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
      echo "Checksum mismatch! Package may be corrupted."
      return 1
    fi
  fi
  
  return 0
}
```
