#!/usr/bin/env bash
# =============================================================================
# lucy-agent scripts/common.sh — Shared helpers for install/update/uninstall
# =============================================================================
# Sourced by: install.sh, update.sh, uninstall.sh
# DO NOT execute directly
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log helpers
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }
log_step() { echo -e "\n${GREEN}==>${NC} $*"; }

# SHA256 check — returns hash of file or empty if file doesn't exist
sha256_check() {
  local file="$1"
  if [ -f "$file" ]; then
    sha256sum "$file" | cut -d' ' -f1
  fi
}

# Prompt helpers
prompt_conflict() {
  local file="$2"
  echo ""
  log_warn "File already exists and was modified: $file"
  echo "  [o] Overwrite with repo version"
  echo "  [s] Skip (keep your version)"
  echo "  [a] Abort installation"
  echo ""
  printf "Your choice [o/s/a]: "
  local answer
  read -r answer
  case "$answer" in
    o | O) return 0 ;;
    s | S) return 1 ;;
    a | A)
      log_fail "Installation aborted by user."
      exit 1
      ;;
    *)
      log_fail "Invalid choice '$answer'. Aborting."
      exit 1
      ;;
  esac
}

prompt_skill_conflict() {
  local skill="$1"
  echo ""
  log_warn "Skill already exists and may be modified: $skill"
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

# Read a line with EOF protection. Returns default if EOF detected.
# Usage: answer=$(read_line "default_value")
read_line() {
  local default="$1"
  local line
  if IFS= read -r line; then
    echo "$line"
  else
    echo "$default"
  fi
}

# Check if a file/directory should be excluded from copy
# Usage: is_excluded "filename"
is_excluded() {
  local filename="$1"
  local EXCLUDE_FILES="openclaw.json .env credentials/ secrets/ auth-profiles.json *.pem *.key *.crt .DS_Store"
  for pattern in $EXCLUDE_FILES; do
    # shellcheck disable=SC2254  # intentional glob patterns for file matching
    case "$filename" in
      $pattern) return 0 ;;
      *) ;;
    esac
  done
  return 1
}

# Check if git repo has uncommitted changes
# Returns 0 if dirty (has changes), 1 if clean
git_is_dirty() {
  if [ -d "$1/.git" ]; then
    if [ -n "$(git -C "$1" status --short 2>/dev/null)" ]; then
      return 0 # dirty
    fi
  fi
  return 1 # clean
}

# Stash git changes if dirty, pop after
# Usage: git_stash_pop /path/to/repo "description"
# Sets STASHED_CHANGES=1 if stashed, 0 otherwise
# shellcheck disable=SC2034  # STASHED_CHANGES used by update.sh which sources this file
git_stash_and_pull() {
  local repo="$1"
  local desc="$2"
  STASHED_CHANGES=0

  if ! git_is_dirty "$repo"; then
    return 0
  fi

  if $FORCE; then
    log_info "Stashing local changes ($desc)..."
    git -C "$repo" stash push -m "lucy-agent pre-update stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    STASHED_CHANGES=1
  else
    log_warn "Local changes detected in $repo"
    echo "  [1] Stash changes, pull, then restore"
    echo "  [2] Skip (keep local version)"
    echo "  [3] Abort"
    echo ""
    printf "Your choice [1/2/3]: "
    local answer
    read -r answer
    case "$answer" in
      1)
        log_info "Stashing and pulling..."
        git -C "$repo" stash push -m "lucy-agent pre-update stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        STASHED_CHANGES=1
        ;;
      2)
        log_info "Skipping pull (keeping local changes)..."
        return 1
        ;;
      *)
        log_fail "Update aborted."
        exit 1
        ;;
    esac
  fi
}

# Read .version file
# Usage: read_version_file "/path/to/.version"
read_version_file() {
  local version_file="$1"
  if [ ! -f "$version_file" ]; then
    echo "{}"
    return
  fi
  # Simple JSON read without jq
  local branch tag version installed_at
  branch=$(grep '"branch"' "$version_file" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
  tag=$(grep '"tag"' "$version_file" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' | grep -v 'null' || true)
  version=$(grep '"version"' "$version_file" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
  installed_at=$(grep '"installed_at"' "$version_file" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
  echo "{"
  [ -n "$branch" ] && echo "  \"branch\": \"$branch\","
  [ -n "$tag" ] && echo "  \"tag\": \"$tag\","
  [ -n "$version" ] && echo "  \"version\": \"$version\","
  [ -n "$installed_at" ] && echo "  \"installed_at\": \"$installed_at\","
  echo "}"
}

# Write .version file
# Usage: write_version_file "/path/to/.version" "lucy-config" "" "1.2.0"
write_version_file() {
  local version_file="$1"
  local branch="$2"
  local tag="${3:-}"
  local version="$4"
  local installed_at
  installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local tag_json
  if [ -n "$tag" ]; then
    tag_json="\"$tag\""
  else
    tag_json="null"
  fi
  cat >"$version_file" <<EOF
{
  "branch": "$branch",
  "tag": $tag_json,
  "version": "$version",
  "installed_at": "$installed_at"
}
EOF
}
