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
#   --skip-engram-update  Skip Engram update check
#   --update-engram   Force Engram reinstall even if same version
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
CURRENT_VERSION="1.9.0"

TAG=""
FORCE=false
FORCE_STASH=false
DRY_RUN=false
QUIET=false
SKIP_ENGRAM_UPDATE=false
UPDATE_ENGRAM=false

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
# Engram helpers (duplicated from install.sh for standalone use)
# ---------------------------------------------------------------------------

# Detect the platform in Engram's release naming convention: {os}_{arch}
detect_platform() {
  local os arch
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=$(uname -m)

  case "$os" in
    linux | darwin) ;;
    *)
      log_warn "Unsupported OS: $os. Engram supports macOS (darwin) and Linux."
      return 1
      ;;
  esac

  case "$arch" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      log_warn "Unsupported architecture: $arch. Engram supports amd64 and arm64."
      return 1
      ;;
  esac

  echo "${os}_${arch}"
  return 0
}

# Resolve the Engram version to check.
# Fetches latest from GitHub API.
# Note: update.sh does not support --engram-tag; use install.sh for pinned versions.
resolve_engram_version() {
  local version

  version=$(curl -fsSL \
    "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" \
    2>/dev/null | grep '"tag_name":' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

  if [ -z "$version" ]; then
    log_warn "Engram: could not determine latest version from GitHub API"
    return 1
  fi

  version="${version#v}"
  echo "$version"
  return 0
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
    o | O) return 0 ;;
    s | S) return 1 ;;
    *) return 1 ;;
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
    o | O) return 0 ;;
    s | S) return 1 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--tag requires a value (e.g. --tag v1.0.0)"
          exit 1
        fi
        TAG="$2"
        shift 2
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --force-stash)
        FORCE_STASH=true
        FORCE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --quiet | -q)
        QUIET=true
        shift
        ;;
      --skip-engram-update)
        SKIP_ENGRAM_UPDATE=true
        shift
        ;;
      --update-engram)
        UPDATE_ENGRAM=true
        shift
        ;;
      --version)
        show_version
        exit 0
        ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: update.sh [--tag <version>] [--force] [--dry-run] [--skip-engram-update] [--update-engram] [--version]"
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
  git ls-remote --tags "https://github.com/camiloandresgtruniandes/lucy-agent" 2>/dev/null |
    awk -F/ '{print $3}' | grep -v '\\^{}$' | sort -V | tail -5 | xargs -I{} echo "  {}" || echo "  (could not fetch)"
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
# Step 1.5: Check Engram updates
# ---------------------------------------------------------------------------
step_check_engram_update() {
  log_step "Step 1.5: Checking Engram updates"

  # ---- Guard: --skip-engram-update ----
  if $SKIP_ENGRAM_UPDATE; then
    log_info "○ Skipped: Engram update check (--skip-engram-update)"
    return 0
  fi

  # ---- Guard: --dry-run ----
  if $DRY_RUN; then
    log_info "[DRY-RUN] Would check for Engram updates"
    return 0
  fi

  # ---- Check if engram is installed ----
  local ENGRAM_BIN="${HOME}/.local/bin/engram"
  if [ ! -x "$ENGRAM_BIN" ]; then
    log_info "Engram not installed or not executable. Run install.sh first."
    return 0
  fi

  # ---- Get current version ----
  local current
  current=$("$ENGRAM_BIN" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")

  # ---- Get latest version ----
  local latest
  latest=$(resolve_engram_version) || true
  if [ -z "$latest" ]; then
    log_warn "Could not check for Engram updates"
    return 0
  fi

  # ---- Compare versions ----
  if [ "$current" = "$latest" ] && ! $UPDATE_ENGRAM; then
    log_ok "Engram is up to date (v${current})"
    return 0
  fi

  if [ "$current" != "$latest" ]; then
    log_info "→ Updating engram: v${current} → v${latest}"
  else
    log_info "→ Reinstalling engram v${latest} (--update-engram)"
  fi

  # ---- Detect platform ----
  local platform
  platform=$(detect_platform) || true
  if [ -z "$platform" ]; then
    log_warn "Engram update skipped: unsupported platform"
    return 0
  fi

  # ---- Download and install ----
  local asset="engram_v${latest}_${platform}.tar.gz"
  local url="https://github.com/Gentleman-Programming/engram/releases/download/v${latest}/${asset}"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  log_info "Engram: downloading v${latest} (${platform})..."
  if ! curl -fsSL --progress-bar -o "$tmpdir/$asset" "$url"; then
    log_warn "Engram update download failed"
    rm -rf "$tmpdir"
    return 0
  fi

  if ! tar -xzf "$tmpdir/$asset" -C "$tmpdir"; then
    log_warn "Engram extraction failed"
    rm -rf "$tmpdir"
    return 0
  fi

  local engram_extracted
  engram_extracted=$(find "$tmpdir" -name "engram" -type f | head -1)
  if [ -z "$engram_extracted" ]; then
    log_warn "Engram binary not found in archive"
    rm -rf "$tmpdir"
    return 0
  fi

  mkdir -p "${HOME}/.local/bin"
  cp "$engram_extracted" "$ENGRAM_BIN"
  chmod +x "$ENGRAM_BIN"

  if "$ENGRAM_BIN" --version >/dev/null 2>&1; then
    log_ok "Engram updated to v${latest}"
  else
    log_warn "Engram update --version check failed"
  fi

  rm -rf "$tmpdir"
  return 0
}

# ---------------------------------------------------------------------------
# Step 2: Git pull or checkout tag — respects .version branch
# ---------------------------------------------------------------------------
step_git_update() {
  log_step "Step 2: Updating git repository"

  local skip_pull=false
  local did_stash=false

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
      did_stash=true
    elif $FORCE; then
      if ! git_stash_and_pull "$LUCY_DIR" "update"; then
        skip_pull=true
      fi
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
          did_stash=true
          ;;
        2)
          log_info "Skipping pull..."
          skip_pull=true
          ;;
        *)
          log_fail "Update aborted."
          exit 1
          ;;
      esac
    fi
  fi

  if ! $DRY_RUN && ! $skip_pull; then
    git -C "$LUCY_DIR" fetch --tags origin 2>/dev/null || true
    if [ -n "$target_tag" ]; then
      if ! git -C "$LUCY_DIR" checkout "$target_tag" 2>/dev/null; then
        log_fail "Tag '$target_tag' not found"
        exit 1
      fi
    else
      # Checkout target branch first to avoid merging into wrong branch
      git -C "$LUCY_DIR" checkout "$target_branch" 2>/dev/null || true
      git -C "$LUCY_DIR" pull origin "$target_branch" 2>/dev/null || log_fail "Failed to pull $target_branch"
    fi
  fi

  # Restore stashed changes if any were stashed
  if $did_stash || [ "${STASHED_CHANGES:-0}" = "1" ]; then
    if git -C "$LUCY_DIR" stash pop 2>/dev/null; then
      log_info "Restored local changes from stash"
    else
      log_warn "Could not pop stash (conflicts may exist). Run: git stash list"
    fi
  fi

  if ! $skip_pull; then
    # Update .version file
    local version_branch
    if [ -n "$target_tag" ]; then
      # When targeting a tag, record the original branch, not the tag name
      version_branch=$(grep '"branch"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "")
      version_branch="${version_branch:-main}"
    elif [ -f "$VERSION_FILE" ]; then
      version_branch=$(grep '"branch"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "")
      version_branch="${version_branch:-main}"
    else
      version_branch="${target_branch#tags/}"
    fi
    write_version_file "$VERSION_FILE" "$version_branch" "${target_tag:-}" "$CURRENT_VERSION"
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
      local existing_sum
      existing_sum=$(sha256_check "${dest}/SKILL.md" 2>/dev/null || echo "")
      local repo_sum
      repo_sum=$(sha256_check "$skill_file")

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
    local repo_sum
    repo_sum=$(sha256_check "$file")
    local existing_sum
    existing_sum=$(sha256_check "$dest")

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

  # Sync sdd/ orchestrator files (same pattern as install.sh)
  local sdd_updated=0 sdd_skipped=0
  if [ -d "${ws_src}/sdd" ]; then
    while IFS= read -r -d '' sdd_file; do
      local sdd_rel="${sdd_file#$ws_src/}"
      local sdd_dest="${WORKSPACE_DIR}/${sdd_rel}"
      local sdd_dest_dir
      sdd_dest_dir="$(dirname "$sdd_dest")"
      local repo_sum
      repo_sum=$(sha256_check "$sdd_file")
      local existing_sum
      existing_sum=$(sha256_check "$sdd_dest")

      mkdir -p "$sdd_dest_dir"

      if [ -z "$existing_sum" ]; then
        if ! $DRY_RUN; then
          cp "$sdd_file" "$sdd_dest"
        fi
        log_ok "New sdd/: $sdd_rel"
        sdd_updated=$((sdd_updated + 1))
      elif [ "$existing_sum" != "$repo_sum" ]; then
        if $FORCE; then
          if ! $DRY_RUN; then
            cp "$sdd_file" "$sdd_dest"
          fi
          log_ok "Forced sdd/: $sdd_rel"
          sdd_updated=$((sdd_updated + 1))
        else
          if prompt_workspace_conflict "$sdd_rel"; then
            if ! $DRY_RUN; then
              cp "$sdd_file" "$sdd_dest"
            fi
            log_ok "Updated sdd/: $sdd_rel"
            sdd_updated=$((sdd_updated + 1))
          else
            log_info "Skipped (kept local): $sdd_rel"
            sdd_skipped=$((sdd_skipped + 1))
          fi
        fi
      else
        log_info "Unchanged sdd/: $sdd_rel"
      fi
    done < <(find "${ws_src}/sdd" -type f -print0)
    log_ok "SDD — updated: $sdd_updated, skipped: $sdd_skipped"
  fi
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
  step_check_engram_update
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
