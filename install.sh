#!/usr/bin/env bash
# =============================================================================
# lucy-agent install.sh — Idempotent single-command installer
# =============================================================================
# Usage:
#   # Interactive (asks you to choose config):
#   curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash
#
#   # Clone mode (installs Lucy's exact config):
#   curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash -s -- --clone
#
#   # Template mode (generic templates):
#   curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash -s -- --template
#
# Flags:
#   --clone          Clone Lucy's exact config (from lucy-config branch)
#   --template       Use generic templates (default, same as interactive with no)
#   --skip-clawhub   Skip ClawHub skill installation
#   --skip-workspace  Skip workspace seeding
#   --force          Overwrite conflicting files without prompting
#   --dry-run        Show what would be done without making changes
# =============================================================================

set -euo pipefail

LUCY_REPO="https://github.com/camiloandresgtruniandes/lucy-agent"
LUCY_BRANCH="main"
LUCY_DIR="${LHOME:-$HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"

# Files/dirs to NEVER copy — security sensitive
EXCLUDE_FILES="openclaw.json .env credentials/ secrets/ auth-profiles.json *.pem *.key *.crt .DS_Store"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SKIP_CLAWHUB=false
SKIP_WORKSPACE=false
FORCE=false
DRY_RUN=false
CLONE_MODE=false
NON_INTERACTIVE_FLAGS=false
# If stdin is a terminal AND no mode flags → interactive
# If stdin is NOT a terminal (piped) AND no mode flags → default to template
if [ -t 0 ]; then
  INTERACTIVE_PROMPT=true
else
  INTERACTIVE_PROMPT=false
fi

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

is_excluded() {
  local filename="$1"
  # Check against each excluded pattern
  for pattern in $EXCLUDE_FILES; do
    case "$filename" in
      $pattern) return 0 ;;
      *) ;;
    esac
  done
  return 1
}

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
    o|O) return 0 ;;
    s|S) return 1 ;;
    a|A) log_fail "Installation aborted by user."; exit 1 ;;
    *)   log_fail "Invalid choice '$answer'. Aborting."; exit 1 ;;
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
    o|O) return 0 ;;
    s|S) return 1 ;;
    *)   return 1 ;;
  esac
}

prompt_install_mode() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}lucy-agent — Choose your configuration${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
  echo "  [1] Clone Lucy's config — Full replica (recommended)"
  echo "      SOUL.md, IDENTITY.md, AGENTS.md, TOOLS.md, USER.md, HEARTBEAT.md"
  echo "      Installs from the lucy-config branch (no personal data from you)"
  echo ""
  echo "  [2] Use templates — Start with generic files"
  echo "      USER.md will have placeholders for you to fill in"
  echo "      (same as running with --template flag)"
  echo ""
  echo "  [3] Customize — Choose which files to install"
  echo "      Interactive: select each file individually"
  echo ""
  printf "Your choice [1/2/3] (default: 2): "
  local answer
  read -r answer
  case "$answer" in
    1|1*) CLONE_MODE=true; LUCY_BRANCH="lucy-config"; log_info "Mode: Clone Lucy's config" ;;
    2|"") CLONE_MODE=false; LUCY_BRANCH="main";        log_info "Mode: Generic templates" ;;
    3)    CLONE_MODE=false; LUCY_BRANCH="main";        log_info "Mode: Customize" ;;
    *)    log_fail "Invalid choice. Aborting."; exit 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --clone)          CLONE_MODE=true; LUCY_BRANCH="lucy-config"; NON_INTERACTIVE_FLAGS=true; shift ;;
      --template)        CLONE_MODE=false; LUCY_BRANCH="main"; NON_INTERACTIVE_FLAGS=true; shift ;;
      --skip-clawhub)   SKIP_CLAWHUB=true; shift ;;
      --skip-workspace)  SKIP_WORKSPACE=true; shift ;;
      --force)           FORCE=true; shift ;;
      --dry-run)         DRY_RUN=true; shift ;;
      --help|-h)
        echo "Usage: install.sh [flags]"
        echo "Flags:"
        echo "  --clone          Clone Lucy's exact config (lucy-config branch)"
        echo "  --template       Use generic templates (default)"
        echo "  --skip-clawhub   Skip ClawHub skill installation"
        echo "  --skip-workspace Skip workspace seeding"
        echo "  --force          Overwrite conflicting files without prompting"
        echo "  --dry-run        Show what would be done without making changes"
        echo "  --help, -h       Show this help"
        exit 0
        ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: install.sh [--clone|--template] [--skip-clawhub] [--skip-workspace] [--force] [--dry-run]"
        exit 1
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Step 1: Detect environment
# ---------------------------------------------------------------------------
step_detect_openclaw() {
  log_step "Step 1: Checking environment"
  if command -v openclaw &>/dev/null; then
    local ver
    ver=$(openclaw --version 2>/dev/null || echo "unknown")
    log_ok "OpenClaw CLI found (version: $ver)"
  else
    log_fail "OpenClaw CLI not found. Please install OpenClaw first:"
    echo "  curl -fsSL https://openclaw.ai/install.sh | bash"
    echo "  Then run this installer again."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Step 2: Clone or pull repo
# ---------------------------------------------------------------------------
step_clone_or_pull() {
  log_step "Step 2: Fetching lucy-agent repository"
  log_info "Branch: $LUCY_BRANCH"
  if [ -d "$LUCY_DIR/.git" ]; then
    log_info "lucy-agent already installed at $LUCY_DIR"
    log_info "Running git pull to update..."
    if ! $DRY_RUN; then
      cd "$LUCY_DIR" && git pull origin "$LUCY_BRANCH"
    fi
    log_ok "Updated to latest $LUCY_BRANCH"
  else
    log_info "Cloning lucy-agent into $LUCY_DIR"
    if ! $DRY_RUN; then
      mkdir -p "$(dirname "$LUCY_DIR")"
      git clone --branch "$LUCY_BRANCH" --depth 1 "$LUCY_REPO" "$LUCY_DIR"
    fi
    log_ok "Cloned lucy-agent ($LUCY_BRANCH)"
  fi
}

# ---------------------------------------------------------------------------
# Step 3: Seed workspace files
# ---------------------------------------------------------------------------
step_seed_workspace() {
  if $SKIP_WORKSPACE; then
    log_info "Skipping workspace seeding (--skip-workspace)"
    return
  fi

  log_step "Step 3: Seeding workspace files"
  mkdir -p "$WORKSPACE_DIR"

  local ws_src="${LUCY_DIR}/workspace"
  if [ ! -d "$ws_src" ]; then
    log_warn "No workspace/ directory in repo; skipping workspace seed"
    return
  fi

  for file in "$ws_src"/*.md; do
    [ -f "$file" ] || continue
    local filename
    filename="$(basename "$file")"

    # Security: skip excluded files
    if is_excluded "$filename"; then
      log_info "Skipped (excluded): $filename"
      continue
    fi

    local dest="${WORKSPACE_DIR}/${filename}"
    local repo_sum; repo_sum=$(sha256_check "$file")
    local existing_sum; existing_sum=$(sha256_check "$dest")

    if [ -z "$existing_sum" ]; then
      # File doesn't exist — copy
      if ! $DRY_RUN; then
        cp "$file" "$dest"
      fi
      log_ok "Created $filename"
    elif [ "$existing_sum" != "$repo_sum" ]; then
      # File exists and differs
      if $FORCE; then
        if ! $DRY_RUN; then
          cp "$file" "$dest"
        fi
        log_ok "Forced overwrite: $filename"
      else
        if prompt_conflict "overwrite/skip/abort" "$dest"; then
          if ! $DRY_RUN; then
            cp "$file" "$dest"
          fi
          log_ok "Overwrote: $filename"
        else
          log_info "Skipped (kept your version): $filename"
        fi
      fi
    else
      log_info "Unchanged: $filename (matches repo)"
    fi
  done
}

# ---------------------------------------------------------------------------
# Step 4: Install bundled skills
# ---------------------------------------------------------------------------
step_install_bundled_skills() {
  log_step "Step 4: Installing bundled skills"
  mkdir -p "$SKILLS_DIR"

  local skills_src="${LUCY_DIR}/skills"
  if [ ! -d "$skills_src" ]; then
    log_warn "No skills/ directory in repo; skipping bundled skills"
    return
  fi

  for skill_dir in "$skills_src"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local dest="${SKILLS_DIR}/${skill_name}"
    local skill_file="${skill_dir}/SKILL.md"

    if [ ! -f "$skill_file" ]; then
      log_warn "Skipping $skill_name (no SKILL.md)"
      continue
    fi

    if [ -d "$dest" ]; then
      # Skill exists — check if modified
      local existing_sum; existing_sum=$(sha256_check "${dest}/SKILL.md" 2>/dev/null || echo "")
      local repo_sum; repo_sum=$(sha256_check "$skill_file")
      if [ "$existing_sum" != "$repo_sum" ]; then
        if $FORCE; then
          if ! $DRY_RUN; then
            rm -rf "$dest" && cp -r "$skill_dir" "$dest"
          fi
          log_ok "Forced overwrite: skill/$skill_name"
        else
          if prompt_skill_conflict "$skill_name"; then
            if ! $DRY_RUN; then
              rm -rf "$dest" && cp -r "$skill_dir" "$dest"
            fi
            log_ok "Overwrote: skill/$skill_name"
          else
            log_info "Skipped (kept your version): skill/$skill_name"
          fi
        fi
      else
        log_info "Unchanged: skill/$skill_name"
      fi
    else
      if ! $DRY_RUN; then
        cp -r "$skill_dir" "$dest"
      fi
      log_ok "Installed: skill/$skill_name"
    fi
  done
}

# ---------------------------------------------------------------------------
# Step 5: Install ClawHub skills
# ---------------------------------------------------------------------------
step_install_clawhub_skills() {
  if $SKIP_CLAWHUB; then
    log_info "Skipping ClawHub skills (--skip-clawhub)"
    return
  fi

  log_step "Step 5: Installing ClawHub skills"
  local clawhub_file="${LUCY_DIR}/clawhub-skills.txt"
  if [ ! -f "$clawhub_file" ]; then
    log_warn "No clawhub-skills.txt found; skipping ClawHub install"
    return
  fi

  local installed=0
  local failed=0
  while IFS= read -r skill || [ -n "$skill" ]; do
    # Skip empty lines and comments
    [[ -z "$skill" ]] && continue
    [[ "$skill" =~ ^# ]] && continue
    skill=$(echo "$skill" | xargs)
    [[ -z "$skill" ]] && continue

    log_info "Installing from ClawHub: $skill"
    if ! $DRY_RUN; then
      if openclaw skills install "$skill" --force 2>/dev/null; then
        log_ok "Installed: $skill"
      else
        log_warn "Failed to install: $skill (may already be installed)"
        failed=$((failed + 1))
      fi
    fi
    installed=$((installed + 1))
  done < "$clawhub_file"

  log_ok "ClawHub skills processed: $installed ok, $failed skipped/failed"
}

# ---------------------------------------------------------------------------
# Step 6: Config fragment instructions
# ---------------------------------------------------------------------------
step_print_config_instructions() {
  log_step "Step 6: Gateway config"
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}Next step: Link lucy-agent config in your openclaw.json${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
  echo "Add this to your ${HOME}/.openclaw/openclaw.json:"
  echo ""
  echo '  { $include: "./lucy-agent/config/agent-fragment.json5" }'
  echo ""
  echo "Or copy the contents of agent-fragment.json5 directly into"
  echo "the agents.defaults section of your openclaw.json."
  echo ""
  echo "Then restart OpenClaw: openclaw gateway restart"
  echo ""
  echo -e "${YELLOW}NOTE:${NC} You still need to configure your channel tokens,"
  echo "API keys, and secrets manually in openclaw.json."
  echo ""
}

# ---------------------------------------------------------------------------
# Step 7: Verify
# ---------------------------------------------------------------------------
step_verify() {
  log_step "Step 7: Verifying installation"
  if ! $DRY_RUN; then
    cd "$LUCY_DIR" && bash verify.sh
    log_ok "verify.sh passed"
  else
    log_info "[DRY-RUN] Would run verify.sh"
  fi
}

# ---------------------------------------------------------------------------
# Step 8: Report
# ---------------------------------------------------------------------------
step_report() {
  local mode_label="generic templates"
  if $CLONE_MODE; then
    mode_label="Lucy's config (clone mode)"
  fi

  echo ""
  echo -e "${GREEN}================================================================${NC}"
  echo -e "${GREEN}lucy-agent installed successfully!${NC}"
  echo -e "${GREEN}================================================================${NC}"
  echo ""
  echo -e "Mode:         ${BLUE}$mode_label${NC}"
  echo -e "Repo:         ${BLUE}${LUCY_DIR}${NC}"
  echo -e "Workspace:    ${BLUE}${WORKSPACE_DIR}${NC}"
  echo -e "Skills:      ${BLUE}${SKILLS_DIR}${NC}"
  echo ""
  echo -e "Update later:"
  echo -e "  cd ${LUCY_DIR} && ./update.sh"
  echo ""
  echo -e "Verify:"
  echo -e "  cd ${LUCY_DIR} && ./verify.sh"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${GREEN}lucy-agent installer${NC}"
  echo -e "Repo: $LUCY_REPO"
  echo ""
  if $DRY_RUN; then
    log_info "DRY-RUN mode — no changes will be made"
  fi

  parse_flags "$@"

  # Interactive prompt if no mode flags were passed and stdin is a terminal
  if ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && $INTERACTIVE_PROMPT; then
    prompt_install_mode
  elif ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && ! $INTERACTIVE_PROMPT; then
    # Piped install with no mode flags → default to template, non-interactive
    CLONE_MODE=false
    LUCY_BRANCH="main"
    log_info "Mode: Generic templates (non-interactive, use --clone for Lucy's config)"
  elif $CLONE_MODE; then
    log_info "Mode: Clone Lucy's config"
  else
    log_info "Mode: Generic templates"
  fi

  step_detect_openclaw
  step_clone_or_pull
  step_seed_workspace
  step_install_bundled_skills
  step_install_clawhub_skills
  step_print_config_instructions
  step_verify
  step_report
}

main "$@"
