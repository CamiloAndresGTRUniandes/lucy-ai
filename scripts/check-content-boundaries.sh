#!/usr/bin/env bash
# =============================================================================
# check-content-boundaries.sh — Validate locked files are project-agnostic
# =============================================================================
# Usage:
#   check-content-boundaries.sh --staged     Pre-commit mode: inspect staged content
#   check-content-boundaries.sh --worktree   Verify mode: inspect files on disk
#
# Protected files: workspace/AGENTS.md, workspace/TOOLS.md
#
# Detects and rejects:
#   - Known project names (ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board)
#   - Project-specific standards headings
#   - Absolute paths to known project repos
#   - GitHub repo references (CamiloAndresGTRUniandes + project repos)
#   - Symlinks replacing protected files
#
# Allowed:
#   - Generic placeholders: {project}, {repo}, /workspace/repos/{project}
#   - {project_root}/docs/STANDARDS.md
#
# Exit: 0 = clean, non-zero = violations found
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MODE=""
PROTECTED_FILES=("workspace/AGENTS.md" "workspace/TOOLS.md")
VIOLATIONS=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}!${NC} $*" >&2
}

print_violation() {
  local file="$1"
  local line="$2"
  local pattern_desc="$3"
  echo -e "${RED}✗${NC} Content boundary violation in ${YELLOW}$file${NC}" >&2
  echo "  Locked files must stay project-agnostic." >&2
  echo "" >&2
  if [ -n "$line" ] && [ "$line" != "0" ]; then
    echo "  Line $line: matched $pattern_desc" >&2
  else
    echo "  Matched $pattern_desc" >&2
  fi
  echo "" >&2
}

# ---------------------------------------------------------------------------
# Pattern definitions
# ---------------------------------------------------------------------------

# Project names to reject (case-sensitive)
PROJECT_NAMES=(
  "ZENTICALAB"
  "BE_ZENTICALAB"
  "FE_ZENTICALAB"
  "excel-pipeline"
  "ssdp-ai"
  "kudos-board"
)

# Project-specific standards headings
PROJECT_STANDARDS_HEADINGS=(
  "Backend Standards"
  "Frontend Standards"
  "SQL Query Patterns"
  "Controller Patterns"
  "PostgreSQL schema-per-tenant"
)

# Known repo references (CamiloAndresGTRUniandes + project repos)
KNOWN_REPO_PATTERNS=(
  "CamiloAndresGTRUniandes/BE_ZENTICALAB"
  "CamiloAndresGTRUniandes/FE_ZENTICALAB"
  "CamiloAndresGTRUniandes/excel-pipeline"
  "CamiloAndresGTRUniandes/ssdp-ai"
  "CamiloAndresGTRUniandes/kudos-board"
)

# Absolute project paths (specific projects, not placeholders)
KNOWN_PROJECT_PATHS=(
  "/workspace/repos/ZENTICALAB"
  "/workspace/repos/excel-pipeline"
  "/workspace/repos/ssdp-ai"
  "/workspace/repos/kudos-board"
  "/home/node/.openclaw/workspace/ZENTICALAB"
  "/home/node/.openclaw/workspace/excel-pipeline"
  "/home/node/.openclaw/workspace/ssdp-ai"
  "/home/node/.openclaw/workspace/kudos-board"
)

# Placeholder patterns that are always allowed (these should NOT trigger violations)
ALLOWED_PLACEHOLDERS=(
  "/workspace/repos/{project}"
  "/workspace/repos/{repo}"
  "{project}/docs/STANDARDS.md"
  "{project_root}/docs/STANDARDS.md"
)

# ---------------------------------------------------------------------------
# Validation functions
# ---------------------------------------------------------------------------

# Check if a line contains an allowed placeholder
# Returns 0 if the line contains an allowed placeholder (skip violation)
has_allowed_placeholder() {
  local line="$1"
  for placeholder in "${ALLOWED_PLACEHOLDERS[@]}"; do
    if [[ "$line" == *"$placeholder"* ]]; then
      return 0
    fi
  done
  return 1
}

# Scan content for project names
scan_project_names() {
  local file="$1"
  local content="$2"
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Skip lines that contain allowed placeholders
    if has_allowed_placeholder "$line"; then
      continue
    fi

    for name in "${PROJECT_NAMES[@]}"; do
      if [[ "$line" == *"$name"* ]]; then
        print_violation "$file" "$line_num" "project name \"$name\""
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done
  done <<<"$content"
}

# Scan content for project standards headings
scan_standards_headings() {
  local file="$1"
  local content="$2"
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Only check lines that look like markdown headings
    if [[ "$line" =~ ^#{1,4}[[:space:]]+ ]]; then
      for heading in "${PROJECT_STANDARDS_HEADINGS[@]}"; do
        if [[ "$line" == *"$heading"* ]]; then
          print_violation "$file" "$line_num" "project standards heading \"$heading\""
          VIOLATIONS=$((VIOLATIONS + 1))
        fi
      done
    fi
  done <<<"$content"
}

# Scan content for known repo references
scan_repo_references() {
  local file="$1"
  local content="$2"
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if has_allowed_placeholder "$line"; then
      continue
    fi

    for pattern in "${KNOWN_REPO_PATTERNS[@]}"; do
      if [[ "$line" == *"$pattern"* ]]; then
        print_violation "$file" "$line_num" "repo reference \"$pattern\""
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done
  done <<<"$content"
}

# Scan content for known project paths (absolute paths)
scan_project_paths() {
  local file="$1"
  local content="$2"
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if has_allowed_placeholder "$line"; then
      continue
    fi

    for path_pattern in "${KNOWN_PROJECT_PATHS[@]}"; do
      if [[ "$line" == *"$path_pattern"* ]]; then
        print_violation "$file" "$line_num" "project path \"$path_pattern\""
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done
  done <<<"$content"
}

# Check that a protected file is not a symlink
check_not_symlink() {
  local file="$1"
  local full_path="${PWD}/${file}"

  if [ -L "$full_path" ]; then
    print_violation "$file" "" "symlink (protected files must be regular files)"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

# Perform all scans on a file's content
scan_file_content() {
  local file="$1"
  local content="$2"

  scan_project_names "$file" "$content"
  scan_standards_headings "$file" "$content"
  scan_repo_references "$file" "$content"
  scan_project_paths "$file" "$content"
}

# ---------------------------------------------------------------------------
# Check modes
# ---------------------------------------------------------------------------

# Pre-commit mode: check staged content only
check_staged() {
  local staged_files

  # Get list of staged files (Added, Copied, Modified, Renamed)
  staged_files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

  if [ -z "$staged_files" ]; then
    echo -e "${GREEN}✓${NC} No staged files to check"
    return 0
  fi

  for protected in "${PROTECTED_FILES[@]}"; do
    if echo "$staged_files" | grep -qxF "$protected"; then
      # Check for symlink by inspecting the index
      local mode
      mode=$(git ls-files -s "$protected" 2>/dev/null | awk '{print $1}' | head -1 || echo "")
      if [[ "$mode" == "120000" ]]; then
        print_violation "$protected" "" "symlink (protected files must be regular files)"
        VIOLATIONS=$((VIOLATIONS + 1))
        continue
      fi

      # Read staged content via git show to handle partial stages
      local staged_content
      staged_content=$(git show ":$protected" 2>/dev/null || echo "")

      if [ -n "$staged_content" ]; then
        scan_file_content "$protected" "$staged_content"
      fi
    fi
  done
}

# Worktree mode: check files on disk
check_worktree() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

  for protected in "${PROTECTED_FILES[@]}"; do
    local full_path="${repo_root}/${protected}"

    if [ ! -f "$full_path" ]; then
      echo -e "${YELLOW}!${NC} Protected file not found: $protected (skipping)"
      continue
    fi

    check_not_symlink "$protected"

    local content
    content=$(cat "$full_path" 2>/dev/null || echo "")
    scan_file_content "$protected" "$content"
  done
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: check-content-boundaries.sh [--staged | --worktree]"
  echo ""
  echo "  --staged     Check staged content (pre-commit mode)"
  echo "  --worktree   Check files on disk (verification mode)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  if [ $# -eq 0 ]; then
    print_usage
    exit 2
  fi

  case "$1" in
    --staged)
      MODE="staged"
      check_staged
      ;;
    --worktree)
      MODE="worktree"
      check_worktree
      ;;
    --help | -h)
      print_usage
      exit 0
      ;;
    *)
      log_error "Unknown mode: $1"
      print_usage
      exit 2
      ;;
  esac

  if [ "$VIOLATIONS" -gt 0 ]; then
    echo ""
    echo -e "${RED}Found $VIOLATIONS content boundary violation(s).${NC}" >&2
    echo "Move project-specific standards to docs/STANDARDS.md in the relevant project repo." >&2
    echo "If this is a false positive, use a generic placeholder like {project} or update the checker pattern intentionally." >&2
    exit 1
  fi

  echo -e "${GREEN}✓${NC} All content boundary checks passed ($MODE mode)"
  exit 0
}

main "$@"
