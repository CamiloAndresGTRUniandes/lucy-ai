#!/usr/bin/env bash
# =============================================================================
# lucy-agent uninstall.sh — Clean removal of lucy-agent installation
# =============================================================================
# Usage:
#   cd ~/.openclaw/lucy-agent && ./uninstall.sh
#   cd ~/.openclaw/lucy-agent && ./uninstall.sh --force
#   cd ~/.openclaw/lucy-agent && ./uninstall.sh --dry-run
#
# Flags:
#   --force         Do not prompt for confirmation
#   --keep-skills   Do not remove bundled skills
#   --keep-workspace Do not remove workspace seed files
#   --dry-run       Show what would be done without making changes
#   --quiet, -q     Suppress informational output
#   --help, -h      Show this help
# =============================================================================

set -euo pipefail

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

LUCY_DIR="${HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
FORCE=false
KEEP_SKILLS=false
KEEP_WORKSPACE=false
DRY_RUN=false
QUIET=false

# Bundled skill names (only these get removed)
BUNDLED_SKILLS="sdd github-pr pr-review csharp-dotnet tailwind-4 typescript skill-creator"

# Workspace seed files
WORKSPACE_SEEDS="SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md"

# Override to respect --quiet
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
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE=true
        shift
        ;;
      --keep-skills)
        KEEP_SKILLS=true
        shift
        ;;
      --keep-workspace)
        KEEP_WORKSPACE=true
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
      --help | -h)
        echo "Usage: uninstall.sh [flags]"
        echo "Flags:"
        echo "  --force            Do not prompt for confirmation"
        echo "  --keep-skills      Do not remove bundled skills"
        echo "  --keep-workspace   Do not remove workspace seed files"
        echo "  --dry-run          Show what would be done"
        echo "  --quiet, -q        Suppress informational output"
        echo "  --help, -h         Show this help"
        exit 0
        ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: uninstall.sh [--force] [--keep-skills] [--keep-workspace] [--dry-run]"
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
    exit 1
  fi
  log_ok "lucy-agent found at $LUCY_DIR"
}

# ---------------------------------------------------------------------------
# Step 2: Confirmation prompt
# ---------------------------------------------------------------------------
step_confirm() {
  log_step "Step 2: Confirmation prompt"
  if $FORCE; then
    log_info "Running in --force mode (no confirmation required)"
    return
  fi

  echo ""
  echo -e "${RED}================================================================${NC}"
  echo -e "${RED}WARNING: This will remove lucy-agent and related files!${NC}"
  echo -e "${RED}================================================================${NC}"
  echo ""
  echo "The following will be REMOVED:"
  echo "  • ${LUCY_DIR}/ (lucy-agent repository)"
  if ! $KEEP_SKILLS; then
    for skill in $BUNDLED_SKILLS; do
      [ -d "${SKILLS_DIR}/${skill}" ] && echo "  • ${SKILLS_DIR}/${skill}/ (skill)"
    done
  fi
  if ! $KEEP_WORKSPACE; then
    for file in $WORKSPACE_SEEDS; do
      [ -f "${WORKSPACE_DIR}/${file}" ] && echo "  • ${WORKSPACE_DIR}/${file} (workspace seed)"
    done
  fi
  echo ""
  echo -e "${YELLOW}NOTE:${NC} Your personal workspace files and modifications are preserved"
  echo "unless listed above. Your openclaw.json is NOT modified."
  echo ""
  printf "Are you sure you want to continue? [yes/no]: "
  local answer
  read -r answer
  if [ "$answer" != "yes" ] && [ "$answer" != "YES" ]; then
    log_info "Uninstall aborted."
    exit 0
  fi
}

# ---------------------------------------------------------------------------
# Step 3: Remove lucy-agent repo
# ---------------------------------------------------------------------------
step_remove_repo() {
  log_step "Step 3: Removing lucy-agent repository"
  if [ -d "$LUCY_DIR" ]; then
    if ! $DRY_RUN; then
      rm -rf "$LUCY_DIR"
    fi
    log_ok "Removed: $LUCY_DIR"
  else
    log_info "Already gone: $LUCY_DIR"
  fi
}

# ---------------------------------------------------------------------------
# Step 4: Remove bundled skills
# ---------------------------------------------------------------------------
step_remove_skills() {
  if $KEEP_SKILLS; then
    log_step "Step 4: Skipping skill removal (--keep-skills)"
    return
  fi

  log_step "Step 4: Removing bundled skills"
  local removed=0
  for skill in $BUNDLED_SKILLS; do
    local skill_path="${SKILLS_DIR}/${skill}"
    if [ -d "$skill_path" ]; then
      if ! $DRY_RUN; then
        rm -rf "$skill_path"
      fi
      log_info "Removed skill: $skill"
      removed=$((removed + 1))
    fi
  done
  log_ok "Removed $removed bundled skill(s)"
}

# ---------------------------------------------------------------------------
# Step 5: Remove workspace seeds
# ---------------------------------------------------------------------------
step_remove_workspace() {
  if $KEEP_WORKSPACE; then
    log_step "Step 5: Skipping workspace seed removal (--keep-workspace)"
    return
  fi

  log_step "Step 5: Removing workspace seed files"
  local removed=0
  for file in $WORKSPACE_SEEDS; do
    local file_path="${WORKSPACE_DIR}/${file}"
    if [ -f "$file_path" ]; then
      if ! $DRY_RUN; then
        rm -f "$file_path"
      fi
      log_info "Removed workspace file: $file"
      removed=$((removed + 1))
    fi
  done
  log_ok "Removed $removed workspace seed file(s)"
}

# ---------------------------------------------------------------------------
# Step 6: Final instructions
# ---------------------------------------------------------------------------
step_final_instructions() {
  log_step "Step 6: Final notes"
  echo ""
  echo -e "${YELLOW}NOTE:${NC} The following were NOT modified:"
  echo "  • Your openclaw.json (you may want to remove the \$include line)"
  echo "  • Personal workspace files not in the seed list"
  echo "  • Any skills you installed manually"
  echo ""
  echo -e "${YELLOW}To fully remove lucy-agent, also remove from openclaw.json:${NC}"
  echo '  { $include: "./lucy-agent/config/agent-fragment.json5" }'
  echo ""
  echo "Then restart OpenClaw: openclaw gateway restart"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${RED}lucy-agent uninstaller${NC}"
  echo ""

  parse_flags "$@"
  step_verify_installed
  step_confirm
  step_remove_repo
  step_remove_skills
  step_remove_workspace
  step_final_instructions

  if ! $DRY_RUN; then
    echo -e "${GREEN}lucy-agent uninstalled successfully!${NC}"
  else
    echo -e "${GREEN}[DRY-RUN] Uninstall complete (no changes made)${NC}"
  fi
}

main "$@"
