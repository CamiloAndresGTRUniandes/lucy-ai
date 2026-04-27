#!/usr/bin/env bash
# =============================================================================
# lucy-agent update.sh — In-place update script
# =============================================================================
# Usage:
#   cd ~/.openclaw/lucy-agent && ./update.sh
#   cd ~/.openclaw/lucy-agent && ./update.sh --tag v1.2.3
#   cd ~/.openclaw/lucy-agent && ./update.sh --tag v1.2.3 --force
#
# Flags:
#   --tag <version>   Pin to a specific semver tag (e.g. v1.0.0)
#   --force           Overwrite conflicting files without prompting
#   --dry-run         Show what would be done without making changes
# =============================================================================

set -euo pipefail

LUCY_DIR="${HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TAG=""
FORCE=false
DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC} $*"; }
log_step()  { echo -e "\n${GREEN}==>${NC} $*"; }

sha256_check() {
  local file="$1"
  if [ -f "$file" ]; then
    sha256sum "$file" | cut -d' ' -f1
  fi
}

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
      --dry-run)
        DRY_RUN=true; shift ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: update.sh [--tag <version>] [--force] [--dry-run]"
        exit 1
        ;;
    esac
  done
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
  log_info "Current branch/tag: $(git branch --show-current 2>/dev/null || git describe --tags 2>/dev/null || echo 'unknown')"
}

# ---------------------------------------------------------------------------
# Step 2: Git pull or checkout tag
# ---------------------------------------------------------------------------
step_git_update() {
  log_step "Step 2: Updating git repository"
  if [ -n "$TAG" ]; then
    log_info "Checking out tag: $TAG"
    if ! $DRY_RUN; then
      if ! git checkout "tags/$TAG" 2>/dev/null; then
        log_fail "Tag '$TAG' not found"
        exit 1
      fi
    fi
    log_ok "Checked out: $TAG"
  else
    log_info "Pulling latest from main branch"
    if ! $DRY_RUN; then
      git pull origin main
    fi
    log_ok "Updated to latest main"
  fi
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
      # New skill
      if ! $DRY_RUN; then
        mkdir -p "$SKILLS_DIR" && cp -r "$skill_dir" "$dest"
      fi
      log_ok "New skill installed: $skill_name"
      installed=$((installed + 1))
    else
      # Existing — check if modified
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
        # Unchanged — still sync in case files were added
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
