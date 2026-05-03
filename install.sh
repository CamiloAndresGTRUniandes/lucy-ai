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
#   curl -fsSL https://raw.githubusercontent.com/camiloAndresGTRUniandes/lucy-agent/main/install.sh | bash -s -- --template
#
#   # Install specific version:
#   curl -fsSL https://raw.githubusercontent.com/camiloandresgtruniandes/lucy-agent/main/install.sh | bash -s -- --tag v1.0.0
#
# Flags:
#   --clone          Clone Lucy's exact config (from lucy-config branch)
#   --template       Use generic templates (default, same as interactive with no flags)
#   --tag <version>  Install a specific release tag (e.g. --tag v1.0.0)
#   --skip-engram    Skip Engram memory system installation
#   --engram-tag     Pin Engram to a specific version (default: latest)
#   --skip-clawhub   Skip ClawHub skill installation
#   --skip-workspace Skip workspace seeding
#   --force          Overwrite conflicting files without prompting
#   --force-stash    Stash local changes before pulling (for existing installs)
#   --quiet, -q      Suppress informational output
#   --dry-run        Show what would be done without making changes
#   --version        Show version and exit
#   --help, -h       Show this help
# =============================================================================

set -euo pipefail

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

LUCY_REPO="https://github.com/camiloandresgtruniandes/lucy-agent"
LUCY_BRANCH="main"
LUCY_DIR="${LHOME:-$HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
VERSION_FILE="${LUCY_DIR}/.version"
CURRENT_VERSION="1.4.0"

# Flags
SKIP_CLAWHUB=false
SKIP_WORKSPACE=false
FORCE=false
FORCE_STASH=false
DRY_RUN=false
QUIET=false
CLONE_MODE=false
NON_INTERACTIVE_FLAGS=false
SPECIFIC_TAG=""
SKIP_ENGRAM=false
ENGRAM_TAG=""

# TTY detection: interactive prompt if terminal, otherwise non-interactive
if [ -t 0 ]; then
  INTERACTIVE_PROMPT=true
else
  INTERACTIVE_PROMPT=false
fi

# ---------------------------------------------------------------------------
# Helpers (override common.sh for install-specific behavior)
# ---------------------------------------------------------------------------

# Override log_info to respect --quiet
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
# Engram helpers
# ---------------------------------------------------------------------------

# Detect the platform in Engram's release naming convention: {os}_{arch}
# Output: linux_amd64, linux_arm64, darwin_amd64, darwin_arm64
# Returns 1 and prints error on unsupported platform
detect_platform() {
  local os arch
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=$(uname -m)

  # Validate OS
  case "$os" in
    linux|darwin) ;;
    *)
      log_warn "Unsupported OS: $os. Engram supports macOS (darwin) and Linux."
      return 1
      ;;
  esac

  # Normalize architecture
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *)
      log_warn "Unsupported architecture: $arch. Engram supports amd64 and arm64."
      return 1
      ;;
  esac

  echo "${os}_${arch}"
  return 0
}

# Resolve the Engram version to install.
# Uses --engram-tag if set, otherwise fetches latest from GitHub API.
# Output: version string without 'v' prefix (e.g. "1.15.4")
# Returns 1 on failure (non-fatal to caller)
resolve_engram_version() {
  local version

  if [ -n "${ENGRAM_TAG:-}" ]; then
    version="${ENGRAM_TAG#v}"
    log_info "Engram: using pinned version $version (--engram-tag)"
    echo "$version"
    return 0
  fi

  log_info "Engram: fetching latest release version..."
  version=$(curl -fsSL \
    "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" \
    2>/dev/null | grep '"tag_name":' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

  if [ -z "$version" ]; then
    log_warn "Engram: could not determine latest version from GitHub API"
    return 1
  fi

  version="${version#v}"
  log_info "Engram latest version: $version"
  echo "$version"
  return 0
}

# ---------------------------------------------------------------------------
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --clone)          CLONE_MODE=true; LUCY_BRANCH="lucy-config"; NON_INTERACTIVE_FLAGS=true; shift ;;
      --template)        CLONE_MODE=false; LUCY_BRANCH="main"; NON_INTERACTIVE_FLAGS=true; shift ;;
      --tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--tag requires a value (e.g. --tag v1.0.0)"
          exit 1
        fi
        SPECIFIC_TAG="$2"; shift 2 ;;
      --skip-clawhub)   SKIP_CLAWHUB=true; shift ;;
      --skip-workspace)  SKIP_WORKSPACE=true; shift ;;
      --skip-engram)    SKIP_ENGRAM=true; shift ;;
      --engram-tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--engram-tag requires a value (e.g. --engram-tag v1.15.4)"
          exit 1
        fi
        ENGRAM_TAG="$2"; shift 2 ;;
      --force)           FORCE=true; shift ;;
      --force-stash)    FORCE_STASH=true; FORCE=true; shift ;;
      --dry-run)         DRY_RUN=true; shift ;;
      --quiet|-q)        QUIET=true; shift ;;
      --version)
        show_version; exit 0 ;;
      --help|-h)
        show_help; exit 0 ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: install.sh [--clone|--template|--tag <version>] [flags]"
        exit 1
        ;;
    esac
  done
}

show_help() {
  echo "Usage: install.sh [flags]"
  echo "Flags:"
  echo "  --clone            Clone Lucy's exact config (lucy-config branch)"
  echo "  --template         Use generic templates (default)"
  echo "  --tag <version>    Install a specific release (e.g. v1.0.0)"
  echo "  --skip-clawhub    Skip ClawHub skill installation"
  echo "  --skip-workspace  Skip workspace seeding"
  echo "  --skip-engram     Skip Engram memory system installation"
  echo "  --engram-tag <ver> Install a specific Engram version (default: latest)"
  echo "  --force            Overwrite conflicting files without prompting"
  echo "  --force-stash      Stash local changes before pulling"
  echo "  --quiet, -q        Suppress informational output"
  echo "  --dry-run          Show what would be done without making changes"
  echo "  --version          Show version and exit"
  echo "  --help, -h         Show this help"
}

show_version() {
  echo "lucy-agent installer v${CURRENT_VERSION}"
  echo ""
  if [ -f "$VERSION_FILE" ]; then
    echo "Installed version:"
    # shellcheck source=scripts/common.sh
    source "${SCRIPT_DIR}/scripts/common.sh" 2>/dev/null || true
    local branch tag version
    branch=$(grep '"branch"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    tag=$(grep '"tag"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/' | grep -v 'null' || true)
    version=$(grep '"version"' "$VERSION_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
    echo "  Branch:  ${branch:-unknown}"
    echo "  Tag:    ${tag:-none}"
    echo "  Version: ${version:-unknown}"
  else
    echo "Not installed (or no .version file)"
  fi
  echo ""
  echo "Latest remote:"
  git ls-remote --tags "$LUCY_REPO" 2>/dev/null | awk -F/ '{print $3}' | grep -v '\^{}$' | sort -V | tail -1 | xargs -I{} echo "  Latest tag: {}" || echo "  (could not fetch)"
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
  echo ""
  printf "Your choice [1/2] (default: 2): "
  local answer
  answer=$(read_line "2")
  case "$answer" in
    1|1*) CLONE_MODE=true; LUCY_BRANCH="lucy-config"; log_info "Mode: Clone Lucy's config" ;;
    2|"") CLONE_MODE=false; LUCY_BRANCH="main";        log_info "Mode: Generic templates" ;;
    *)    log_fail "Invalid choice. Aborting."; exit 1 ;;
  esac
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
# Step 2: Install Engram (technical memory)
# ---------------------------------------------------------------------------
step_install_engram() {
  log_step "Step 2: Installing Engram (technical memory)"

  # ---- Guard: --skip-engram ----
  if $SKIP_ENGRAM; then
    log_info "○ Skipped: Engram (--skip-engram)"
    return 0
  fi

  # ---- Guard: --dry-run ----
  if $DRY_RUN; then
    log_info "[DRY-RUN] Would install Engram"
    return 0
  fi

  # ---- Detect platform ----
  local platform
  platform=$(detect_platform) || true
  if [ -z "$platform" ]; then
    log_warn "Engram installation skipped: unsupported platform"
    return 0
  fi

  # ---- Resolve version ----
  local version
  version=$(resolve_engram_version) || true
  if [ -z "$version" ]; then
    log_warn "Engram installation skipped: version resolution failed"
    return 0
  fi

  # ---- Check if already installed ----
  local ENGRAM_BIN="${HOME}/.local/bin/engram"
  if [ -f "$ENGRAM_BIN" ] && [ -x "$ENGRAM_BIN" ]; then
    local installed_version
    installed_version=$("$ENGRAM_BIN" --version 2>/dev/null | grep -oP 'v?\K[\d.]+' || echo "unknown")
    if [ "$installed_version" = "$version" ] && ! $FORCE; then
      log_ok "Unchanged: engram v$installed_version"
      return 0
    fi
  fi

  # ---- Ensure target directory exists ----
  mkdir -p "${HOME}/.local/bin"

  # ---- Construct download URL ----
  local asset="engram_v${version}_${platform}.tar.gz"
  local url="https://github.com/Gentleman-Programming/engram/releases/download/v${version}/${asset}"

  # ---- Download ----
  log_info "Engram: downloading v${version} (${platform})..."
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  if ! curl -fsSL --progress-bar -o "$tmpdir/$asset" "$url"; then
    log_warn "Engram download failed for v${version}/${platform}"
    rm -rf "$tmpdir"
    return 0
  fi

  # ---- Extract ----
  log_info "Engram: extracting..."
  if ! tar -xzf "$tmpdir/$asset" -C "$tmpdir"; then
    log_warn "Engram extraction failed"
    rm -rf "$tmpdir"
    return 0
  fi

  # Find the engram binary in extracted files
  local engram_extracted
  engram_extracted=$(find "$tmpdir" -name "engram" -type f | head -1)
  if [ -z "$engram_extracted" ]; then
    log_warn "Engram binary not found in archive"
    rm -rf "$tmpdir"
    return 0
  fi

  # ---- Install binary ----
  cp "$engram_extracted" "$ENGRAM_BIN"
  chmod +x "$ENGRAM_BIN"

  # ---- Initialize database ----
  log_info "Engram: initializing database..."
  if "$ENGRAM_BIN" --version >/dev/null 2>&1; then
    log_ok "Engram v${version} installed to ~/.local/bin/engram"
  else
    log_warn "Engram binary installed but --version check failed"
    log_info "Database will be initialized on first use"
  fi

  # ---- Cleanup ----
  rm -rf "$tmpdir"
  return 0
}

# ---------------------------------------------------------------------------
# Step 3: Clone or pull repo
# ---------------------------------------------------------------------------
step_clone_or_pull() {
  log_step "Step 3: Fetching lucy-agent repository"

  local skip_pull=false
  local did_stash=false

  # Handle specific tag
  if [ -n "$SPECIFIC_TAG" ]; then
    LUCY_BRANCH="tags/$SPECIFIC_TAG"
    log_info "Target: specific tag $SPECIFIC_TAG"
  else
    log_info "Branch: $LUCY_BRANCH"
  fi

  if [ -d "$LUCY_DIR/.git" ]; then
    log_info "lucy-agent already installed at $LUCY_DIR"

    # Stash local changes if requested/needed
    if git_is_dirty "$LUCY_DIR"; then
      if $FORCE_STASH; then
        log_info "Stashing local changes (--force-stash)..."
        git -C "$LUCY_DIR" stash push -m "lucy-agent pre-install stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        did_stash=true
      elif $FORCE; then
        if ! git_stash_and_pull "$LUCY_DIR" "install"; then
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
            git -C "$LUCY_DIR" stash push -m "lucy-agent pre-install stash $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            did_stash=true
            ;;
          2) log_info "Skipping pull..."; skip_pull=true ;;
          *) log_fail "Installation aborted."; exit 1 ;;
        esac
      fi
    fi

    if ! $DRY_RUN && ! $skip_pull; then
      cd "$LUCY_DIR" && git fetch --tags origin 2>/dev/null || true
      if [ -n "$SPECIFIC_TAG" ]; then
        if ! git checkout "$SPECIFIC_TAG" 2>/dev/null; then
          log_fail "Tag '$SPECIFIC_TAG' not found"
          exit 1
        fi
      else
        git pull origin "${LUCY_BRANCH#tags/}"
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

    log_ok "Updated to $LUCY_BRANCH"
  else
    log_info "Cloning lucy-agent into $LUCY_DIR"
    if ! $DRY_RUN; then
      mkdir -p "$(dirname "$LUCY_DIR")"
      git clone --branch "${LUCY_BRANCH#tags/}" --tags --progress \
        "$LUCY_REPO" "$LUCY_DIR" 2>&1 | \
        while IFS= read -r line; do
          log_info "$line"
        done
    fi
    log_ok "Cloned lucy-agent ($LUCY_BRANCH)"
  fi

  # Write version file
  if ! $DRY_RUN; then
    local installed_branch
    if [ -n "$SPECIFIC_TAG" ]; then
      # When installing a specific tag, we're on detached HEAD;
      # record 'main' as the logical branch for future updates
      installed_branch="main"
    elif [ "$CLONE_MODE" = true ]; then
      installed_branch="lucy-config"
    else
      installed_branch="${LUCY_BRANCH#tags/}"
    fi
    write_version_file "$VERSION_FILE" "$installed_branch" "${SPECIFIC_TAG:-}" "$CURRENT_VERSION"
    log_info "Version file written: $VERSION_FILE"
  fi
}

# ---------------------------------------------------------------------------
# Step 4: Seed workspace files
# ---------------------------------------------------------------------------
step_seed_workspace() {
  if $SKIP_WORKSPACE; then
    log_info "Skipping workspace seeding (--skip-workspace)"
    return
  fi

  log_step "Step 4: Seeding workspace files"
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

    if is_excluded "$filename"; then
      log_info "Skipped (excluded): $filename"
      continue
    fi

    local dest="${WORKSPACE_DIR}/${filename}"
    local repo_sum; repo_sum=$(sha256_check "$file")
    local existing_sum; existing_sum=$(sha256_check "$dest")

    if [ -z "$existing_sum" ]; then
      if ! $DRY_RUN; then
        cp "$file" "$dest"
      fi
      log_ok "Created $filename"
    elif [ "$existing_sum" != "$repo_sum" ]; then
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

  # Seed sdd/ orchestrator files
  if [ -d "${ws_src}/sdd" ]; then
    while IFS= read -r -d '' sdd_file; do
      local sdd_rel="${sdd_file#$ws_src/}"
      local sdd_dest="${WORKSPACE_DIR}/${sdd_rel}"
      local sdd_dest_dir; sdd_dest_dir="$(dirname "$sdd_dest")"
      local repo_sum; repo_sum=$(sha256_check "$sdd_file")
      local existing_sum; existing_sum=$(sha256_check "$sdd_dest")

      mkdir -p "$sdd_dest_dir"

      if [ -z "$existing_sum" ]; then
        if ! $DRY_RUN; then
          cp "$sdd_file" "$sdd_dest"
        fi
        log_ok "Created $sdd_rel"
      elif [ "$existing_sum" != "$repo_sum" ]; then
        if $FORCE; then
          if ! $DRY_RUN; then
            cp "$sdd_file" "$sdd_dest"
          fi
          log_ok "Forced overwrite: $sdd_rel"
        else
          if prompt_conflict "overwrite/skip/abort" "$sdd_dest"; then
            if ! $DRY_RUN; then
              cp "$sdd_file" "$sdd_dest"
            fi
            log_ok "Overwrote: $sdd_rel"
          else
            log_info "Skipped (kept your version): $sdd_rel"
          fi
        fi
      else
        log_info "Unchanged: $sdd_rel (matches repo)"
      fi
    done < <(find "${ws_src}/sdd" -type f -print0)
  fi
}

# ---------------------------------------------------------------------------
# Step 5: Install bundled skills
# ---------------------------------------------------------------------------
step_install_bundled_skills() {
  log_step "Step 5: Installing bundled skills"
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
# Step 6: Install ClawHub skills
# ---------------------------------------------------------------------------
step_install_clawhub_skills() {
  if $SKIP_CLAWHUB; then
    log_info "Skipping ClawHub skills (--skip-clawhub)"
    return
  fi

  log_step "Step 6: Installing ClawHub skills"
  local clawhub_file="${LUCY_DIR}/clawhub-skills.txt"
  if [ ! -f "$clawhub_file" ]; then
    log_warn "No clawhub-skills.txt found; skipping ClawHub install"
    return
  fi

  local installed=0
  local failed=0
  while IFS= read -r skill || [ -n "$skill" ]; do
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
# Step 7: Config fragment instructions
# ---------------------------------------------------------------------------
step_print_config_instructions() {
  log_step "Step 7: Gateway config"
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
# Step 8: Verify
# ---------------------------------------------------------------------------
step_verify() {
  log_step "Step 8: Verifying installation"
  if ! $DRY_RUN; then
    cd "$LUCY_DIR" && bash verify.sh
    log_ok "verify.sh passed"
  else
    log_info "[DRY-RUN] Would run verify.sh"
  fi
}

# ---------------------------------------------------------------------------
# Step 9: Report
# ---------------------------------------------------------------------------
step_report() {
  local mode_label="generic templates"
  if $CLONE_MODE; then
    mode_label="Lucy's config (clone mode)"
  elif [ -n "$SPECIFIC_TAG" ]; then
    mode_label="specific tag $SPECIFIC_TAG"
  fi

  echo ""
  echo -e "${GREEN}================================================================${NC}"
  echo -e "${GREEN}lucy-agent installed successfully!${NC}"
  echo -e "${GREEN}================================================================${NC}"
  echo ""
  echo -e "Mode:         ${BLUE}$mode_label${NC}"
  echo -e "Version:      ${BLUE}${CURRENT_VERSION}${NC}"
  echo -e "Repo:         ${BLUE}${LUCY_DIR}${NC}"
  echo -e "Workspace:    ${BLUE}${WORKSPACE_DIR}${NC}"
  echo -e "Skills:       ${BLUE}${SKILLS_DIR}${NC}"
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

  parse_flags "$@"

  # Interactive prompt if no mode flags were passed and stdin is a terminal
  if ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && [ -z "$SPECIFIC_TAG" ] && $INTERACTIVE_PROMPT; then
    prompt_install_mode
  elif ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && [ -z "$SPECIFIC_TAG" ] && ! $INTERACTIVE_PROMPT; then
    CLONE_MODE=false
    LUCY_BRANCH="main"
    log_info "Mode: Generic templates (non-interactive, use --clone for Lucy's config)"
  elif [ -n "$SPECIFIC_TAG" ]; then
    log_info "Mode: Specific tag ($SPECIFIC_TAG)"
  elif $CLONE_MODE; then
    log_info "Mode: Clone Lucy's config"
  else
    log_info "Mode: Generic templates"
  fi

  step_detect_openclaw
  step_install_engram
  step_clone_or_pull
  step_seed_workspace
  step_install_bundled_skills
  step_install_clawhub_skills
  step_print_config_instructions
  step_verify
  step_report
}

main "$@"
