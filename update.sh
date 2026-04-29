#!/usr/bin/env bash
# =============================================================================
# lucy-agent update.sh — In-place update script
# =============================================================================
# Usage:
#   cd ~/.openclaw/lucy-agent && ./update.sh
#   cd ~/.openclaw/lucy-agent && ./update.sh --tag v1.2.3
#   cd ~/.openclaw/lucy-agent && ./update.sh --force
#
# Flags:
#   --tag <version>   Override: pin to a specific semver tag (e.g. v1.0.0)
#   --force           Overwrite conflicting files without prompting
#   --force-stash     Stash local changes before pulling
#   --dry-run         Show what would be done without making changes
#   --version         Show current version and exit
# =============================================================================

set -euo pipefail

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

LUCY_DIR="${HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
VERSION_FILE="${LUCY_DIR}/.version"
CURRENT_VERSION="1.2.0"

TAG=""
FORCE=false
FORCE_STASH=false
DRY_RUN=false
QUIET=false

# Override log_info and log_step to respect --quiet
log_info() {
  if ! $QUIET; then
    echo -e "${BLUE}[INFO]${NC} $*"
  fi
}

log_step() {
  if ! $QUIET; then
    echo -e "\n${GREEN}==>${NC} $*"
  fi
}

# ---------------------------------------------------------------------------
# Helpers (override common.sh for update-specific behavior)
# ---------------------------------------------------------------------------
prompt_skill_conflict() {
  local skill="$1"
  echo ""
  log_warn "Skill was modified locally: $skill"
  echo "  [o] Overwrite (use repo version)"
  echo "  [s] Skip (keep your version)"
  echo ""
  printf "Your choice [o/s]: "
  local answer
  read -r answer
  case "$answer" in
    o|O) return 0 ;;
    s|S) return 1 ;;
    *)   return 1 ;;
  esac
}

prompt_workspace_conflict() {
  local file="$1"
  echo ""
  log_warn "Workspace file was modified locally: $file"
  echo "  [o] Overwrite (use repo version)"
  echo "  [s] Skip (keep your version)"
  echo ""
  printf "Your choice [o/s]: "
  local answer
  read -r answer
  case "$answer" in
    o|O) return 0 ;;
    s|S) return 1 ;;
    *)   return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)
        TAG="$2"; shift 2 ;;
      --force)
        FORCE=true; shift ;;
      --force-stash)
        FORCE_STASH=true; FORCE=true; shift ;;
      --dry-run)
        DRY_RUN=true; shift ;;
      --quiet|-q)
        QUIET=true; shift ;;
      --version)
        show_version; exit 0 ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: update.sh [--tag <version>] [--force] [--dry-run] [--version]"
        exit 1
        ;;
    esac
  done
}

show_version() {
  echo "lucy-agent updater v${CURRENT_VERSION}"
  echo ""
  if [ -f "$VERSION_FILE" ]; then
    local branch tag version installed_at
    branch=$(grep '"branch"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    tag=$(grep '"tag"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' | grep -v 'null' || true)
    version=$(grep '"version"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    installed_at=$(grep '"installed_at"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    echo "Installed:"
    echo "  Branch:    ${branch:-unknown}"
    echo "  Tag:      ${tag:-none}"
    echo "  Version:  ${version:-unknown}"
    echo "  At:       ${installed_at:-unknown}"
  else
    echo "No .version file found (pre-v1.2.0 install?)"
  fi
  echo ""
  echo "Remote tags:"
  git ls-remote --tags "https://github.com/camiloandresgtruniandes/lucy-agent" 2>/dev/null | \
    awk -F/ '{print $3}' | sort -V | tail -5 | xargs -I{} echo "  {}" || echo "  (could not fetch)"
}

# ---------------------------------------------------------------------------
# Step 1: Verify lucy-agent is installed
# ---------------------------------------------------------------------------
step_verify_installed() {
  log_step "Step 1: Verifying lucy-agent installation"
  if [ ! -d "$LUCY_DIR/.git" ]; then
    log_fail "lucy-agent not found at $LUCY_DIR"
    echo "Run install.sh first: curl -fsSL ... | bash"
    exit 1
  fi
  log_ok "lucy-agent found at $LUCY_DIR"
  cd "$LUCY_DIR"

  # Detect current state
  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null || echo "")
  if [ -z "$current_branch" ]; then
    # Detached HEAD (tag)
    current_branch="(tag: $(git describe --tags 2>/dev/null || 'unknown'))"
  fi
  log_info "Current branch/tag: $current_branch"
}

# ---------------------------------------------------------------------------
# Step 2: Git pull or checkout tag — respects .version branch
# ---------------------------------------------------------------------------
step_git_update() {
  log_step "Step 2: Updating git repository"

  # Determine target branch from .version file or --tag flag
  local target_branch=""
  local target_tag=""

  if [ -n "$TAG" ]; then
    target_tag="$TAG"
    target_branch="tags/$TAG"
    log_info "Override: targeting specific tag $TAG"
  elif [ -f "$VERSION_FILE" ]; then
    # Read branch from .version
    local stored_branch stored_tag
    stored_branch=$(grep '"branch"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    stored_tag=$(grep '"tag"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' | grep -v 'null' || true)
    if [ -n "$stored_tag" ]; then
      target_tag="$stored_tag"
      target_branch="tags/$stored_tag"
      log_info "Version file: targeting tag $stored_tag (from $stored_branch)"
    elif [ -n "$stored_branch" ]; then
      target_branch="$stored_branch"
      log_info "Version file: targeting branch $stored_branch"
    fi
  fi

  # Default to current branch if nothing found
  if [ -z "$target_branch" ]; then
    target_branch=$(git branch --show-current 2>/dev/null || echo "main")
    if [ -z "$target_branch" ]; then
      target_branch="main"
    fi
    log_info "No .version file; targeting current branch: $target_branch"
  fi

  # Handle local changes
  if git_is_dirty "$LUCY_DIR"; then
    if $FORCE_STASH; then
      log_info "Stashing local changes (--force-stash)..."
      git -C "$LUCY_DIR" stash push -m "lucy-agent pre-update stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    elif $FORCE; then
      git_stash_and_pull "$LUCY_DIR" "update"
    else
      log_warn "Local changes detected in $LUCY_DIR"
      echo "  [1] Stash changes, pull, then restore"
      echo "  [2] Skip pull (keep local version)"
      echo "  [3] Abort"
      echo ""
      printf "Your choice [1/2/3]: "
      local answer
      read -r answer
      case "$answer" in
        1)
          log_info "Stashing and pulling..."
          git -C "$LUCY_DIR" stash push -m "lucy-agent pre-update stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
          ;;
        2) log_info "Skipping pull..."; return ;;
        *) log_fail "Update aborted."; exit 1 ;;
      esac
    fi
  fi

  if ! $DRY_RUN; then
    git -C "$LUCY_DIR" fetch --tags origin 2>/dev/null || true
    if [ -n "$target_tag" ]; then
      if ! git -C "$LUCY_DIR" checkout "$target_tag" 2>/dev/null; then
        log_fail "Tag '$target_tag' not found"
        exit 1
      fi
    else
      git -C "$LUCY_DIR" pull origin "$target_branch"
    fi

    # Update .version file
    write_version_file "$VERSION_FILE" "${target_branch#tags/}" "${target_tag:-}" "$CURRENT_VERSION"
  fi
  log_ok "Updated to $target_branch"
}

# ---------------------------------------------------------------------------
# Step 3: Sync bundled skills
# ---------------------------------------------------------------------------
step_sync_bundled_skills() {
  log_step "Step 3: Syncing bundled skills"
  local skills_src="${LUCY_DIR}/skills"
  if [ ! -d "$skills_src" ]; then
    log_warn "No skills/ directory in repo; skipping"
    return
  fi

  local installed=0 skipped=0 updated=0
  for skill_dir in "$skills_src"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local dest="${SKILLS_DIR}/${skill_name}"
    local skill_file="${skill_dir}/SKILL.md"

    if [ ! -f "$skill_file" ]; then
      continue
    fi

    if [ ! -d "$dest" ]; then
      if ! $DRY_RUN; then
        mkdir -p "$SKILLS_DIR" && cp -r "$skill_dir" "$dest"
      fi
      log_ok "New skill installed: $skill_name"
      installed=$((installed + 1))
    else
      local existing_sum; existing_sum=$(sha256_check "${dest}/SKILL.md" 2>/dev/null || echo "")
      local repo_sum; repo_sum=$(sha256_check "$skill_file")

      if [ "$existing_sum" != "$repo_sum" ]; then
        if $FORCE; then
          if ! $DRY_RUN; then
            rm -rf "$dest" && cp -r "$skill_dir" "$dest"
          fi
          log_ok "Forced update: $skill_name"
          updated=$((updated + 1))
        else
          if prompt_skill_conflict "$skill_name"; then
            if ! $DRY_RUN; then
              rm -rf "$dest" && cp -r "$skill_dir" "$dest"
            fi
            log_ok "Updated: $skill_name"
            updated=$((updated + 1))
          else
            log_info "Skipped (kept local): $skill_name"
            skipped=$((skipped + 1))
          fi
        fi
      else
        if ! $DRY_RUN; then
          cp -u "$skill_dir"/* "$dest/" 2>/dev/null || true
        fi
        log_info "Unchanged: $skill_name"
      fi
    fi
  done
  log_ok "Skills — new: $installed, updated: $updated, skipped: $skipped"
}

# ---------------------------------------------------------------------------
# Step 4: Update ClawHub skills
# ---------------------------------------------------------------------------
step_update_clawhub() {
  log_step "Step 4: Updating ClawHub skills"
  if ! $DRY_RUN; then
    if openclaw skills update --all 2>/dev/null; then
      log_ok "ClawHub skills updated"
    else
      log_warn "ClawHub update failed (may be normal)"
    fi
  else
    log_info "[DRY-RUN] Would run: openclaw skills update --all"
  fi
}

# ---------------------------------------------------------------------------
# Step 5: Sync workspace files
# ---------------------------------------------------------------------------
step_sync_workspace() {
  log_step "Step 5: Syncing workspace files"
  local ws_src="${LUCY_DIR}/workspace"
  if [ ! -d "$ws_src" ]; then
    log_warn "No workspace/ directory in repo; skipping"
    return
  fi

  mkdir -p "$WORKSPACE_DIR"
  local updated=0 skipped=0
  for file in "$ws_src"/*.md; do
    [ -f "$file" ] || continue
    local filename
    filename="$(basename "$file")"
    local dest="${WORKSPACE_DIR}/${filename}"
    local repo_sum; repo_sum=$(sha256_check "$file")
    local existing_sum; existing_sum=$(sha256_check "$dest")

    if [ -z "$existing_sum" ]; then
      if ! $DRY_RUN; then
        cp "$file" "$dest"
      fi
      log_ok "New file: $filename"
      updated=$((updated + 1))
    elif [ "$existing_sum" != "$repo_sum" ]; then
      if $FORCE; then
        if ! $DRY_RUN; then
          cp "$file" "$dest"
        fi
        log_ok "Forced update: $filename"
        updated=$((updated + 1))
      else
        if prompt_workspace_conflict "$filename"; then
          if ! $DRY_RUN; then
            cp "$file" "$dest"
          fi
          log_ok "Updated: $filename"
          updated=$((updated + 1))
        else
          log_info "Skipped (kept local): $filename"
          skipped=$((skipped + 1))
        fi
      fi
    else
      log_info "Unchanged: $filename"
    fi
  done
  log_ok "Workspace — updated: $updated, skipped: $skipped"
}

# ---------------------------------------------------------------------------
# Step 6: Verify
# ---------------------------------------------------------------------------
step_verify() {
  log_step "Step 6: Verifying"
  if ! $DRY_RUN; then
    cd "$LUCY_DIR" && bash verify.sh
    log_ok "verify.sh passed"
  else
    log_info "[DRY-RUN] Would run verify.sh"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${GREEN}lucy-agent updater${NC}"
  echo ""

  parse_flags "$@"
  step_verify_installed
  step_git_update
  step_sync_bundled_skills
  step_update_clawhub
  step_sync_workspace
  step_verify

  echo ""
  echo -e "${GREEN}lucy-agent updated successfully!${NC}"
  echo ""
}

main "$@"
