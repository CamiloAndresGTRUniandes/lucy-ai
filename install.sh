#!/usr/bin/env bash
# =============================================================================
# lucy-agent install.sh — Idempotent single-command installer
# =============================================================================
# Usage:
#   # Interactive (asks you to choose config):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash
#
#   # Clone mode (project-agnostic since v1.7.0, uses main branch):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --clone
#
#   # Template mode (generic templates):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --template
#
#   # Full-clone mode (restore an exported lucy-full-clone bundle):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --full-clone ./lucy-full-clone-20260731-150000.tar.gz
#   bash install.sh --full-clone https://example.com/lucy-full-clone.tar.gz
#
#   # Install specific version:
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --tag v1.7.0
#
#   # Contributor mode (with pre-commit hook):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --contributor
#
# Flags:
#   --clone          Clone Lucy's exact config (from clone branch, maps to main since v1.7.0)
#   --template       Use generic templates (default, same as interactive with no flags)
#   --full-clone <path-or-url>  Restore a full-clone bundle exported by scripts/export-full-clone.sh
#   --tag <version>  Install a specific release tag (e.g. --tag v1.7.0)
#   --contributor    Install pre-commit hook for content boundary enforcement
#   --skip-engram    Skip Engram memory system installation
#   --engram-tag     Pin Engram to a specific version (default: latest)
#   --skip-clawhub   Skip ClawHub skill installation
#   --skip-workspace Skip workspace seeding
#   --force          Overwrite conflicting files without prompting
#   --force-stash    Stash local changes before pulling (for existing installs)
#   --quiet, -q      Suppress informational output
#   --dry-run        Show what would be done without making changes
#   --no-tui         Force text prompts even when dialog is available
#   --accept-defaults Accept all defaults non-interactively
#   --version        Show version and exit
#   --help, -h       Show this help
# =============================================================================

set -euo pipefail

# Detect piped execution (curl|bash) — download files to temp dir and re-execute
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  curl -fsSL "https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh" -o "$TMP_DIR/install.sh"
  mkdir -p "$TMP_DIR/scripts"
  curl -fsSL "https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/scripts/common.sh" -o "$TMP_DIR/scripts/common.sh"
  exec bash "$TMP_DIR/install.sh" "$@" </dev/tty
fi

# Resolve SCRIPT_DIR and source helpers — works from repo, /tmp, or anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "${SCRIPT_DIR}/scripts/common.sh" ]]; then
  # Running from a non-repo location (e.g. downloaded to /tmp/install.sh)
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  mkdir -p "$TMP_DIR/scripts"
  curl -fsSL "https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/scripts/common.sh" -o "$TMP_DIR/scripts/common.sh"
  SCRIPT_DIR="$TMP_DIR"
fi
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

LUCY_REPO="https://github.com/CamiloAndresGTRUniandes/lucy-ai"
LUCY_BRANCH="main"
LUCY_DIR="${LHOME:-$HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
VERSION_FILE="${LUCY_DIR}/.version"
CURRENT_VERSION="1.9.0"

# Flags
SKIP_CLAWHUB=false
SKIP_WORKSPACE=false
FORCE=false
FORCE_STASH=false
DRY_RUN=false
QUIET=false
CLONE_MODE=false
TEMPLATE_MODE=false
FULL_CLONE_SOURCE=""
NON_INTERACTIVE_FLAGS=false
SPECIFIC_TAG=""
SKIP_ENGRAM=false
ENGRAM_TAG=""
NO_TUI=false
ACCEPT_DEFAULTS=false
TUI_MODE=false
CONTRIBUTOR_MODE=false

declare -A COMPONENTS

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
# Template preflight validation
# ---------------------------------------------------------------------------

validate_templates() {
  local ws_src="${LUCY_DIR}/workspace"
  local errors=0

  log_info "Validating workspace templates..."

  # AGENTS.md must have NON-NEGOTIABLE RULES and no SDD_TABLE sentinels
  if [ -f "${ws_src}/AGENTS.md" ]; then
    if ! grep -q 'NON-NEGOTIABLE RULES' "${ws_src}/AGENTS.md"; then
      log_warn "AGENTS.md missing NON-NEGOTIABLE RULES section"
      errors=$((errors + 1))
    fi
    if grep -q 'SDD_TABLE_START\|SDD_TABLE_END' "${ws_src}/AGENTS.md"; then
      log_warn "AGENTS.md contains deprecated SDD_TABLE sentinels"
      errors=$((errors + 1))
    fi
  else
    log_warn "AGENTS.md not found in workspace/"
    errors=$((errors + 1))
  fi

  # TOOLS.md must have CONTENT LOCK and no ZENTICALAB references
  if [ -f "${ws_src}/TOOLS.md" ]; then
    if ! grep -q 'CONTENT LOCK' "${ws_src}/TOOLS.md"; then
      log_warn "TOOLS.md missing CONTENT LOCK section"
      errors=$((errors + 1))
    fi
    # Check for known project names (fails if present in locked templates)
    if grep -qE 'ZENTICALAB|excel-pipeline|ssdp-ai|kudos-board' "${ws_src}/TOOLS.md"; then
      log_warn "TOOLS.md contains project-specific references"
      errors=$((errors + 1))
    fi
  else
    log_warn "TOOLS.md not found in workspace/"
    errors=$((errors + 1))
  fi

  # MEMORY.md must exist
  if [ ! -f "${ws_src}/MEMORY.md" ]; then
    log_warn "MEMORY.md not found in workspace/"
    errors=$((errors + 1))
  fi

  if [ "$errors" -gt 0 ]; then
    log_fail "Template validation failed ($errors errors). Templates may be corrupted."
    log_info "This installer expects project-agnostic templates (v1.7.0+)."
    return 1
  fi

  log_ok "All template validations passed"
  return 0
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
    linux | darwin) ;;
    *)
      log_warn "Unsupported OS: $os. Engram supports macOS (darwin) and Linux."
      return 1
      ;;
  esac

  # Normalize architecture
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

  log_info "Engram: fetching latest release version..." >&2
  version=$(curl -fsSL \
    "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" \
    2>/dev/null | grep '"tag_name":' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

  if [ -z "$version" ]; then
    log_warn "Engram: could not determine latest version from GitHub API"
    return 1
  fi

  version="${version#v}"
  log_info "Engram latest version: $version" >&2
  echo "$version"
  return 0
}

# ---------------------------------------------------------------------------
# Flags parsing
# ---------------------------------------------------------------------------
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --clone)
        CLONE_MODE=true
        LUCY_BRANCH="main"
        NON_INTERACTIVE_FLAGS=true
        log_info "--clone is deprecated since v1.7.0: templates are project-agnostic, using 'main' branch"
        shift
        ;;
      --template)
        CLONE_MODE=false
        TEMPLATE_MODE=true
        LUCY_BRANCH="main"
        NON_INTERACTIVE_FLAGS=true
        shift
        ;;
      --full-clone)
        if [[ -z "${2:-}" ]]; then
          log_fail "--full-clone requires a value (path or URL to a lucy-full-clone bundle)"
          exit 1
        fi
        FULL_CLONE_SOURCE="$2"
        NON_INTERACTIVE_FLAGS=true
        shift 2
        ;;
      --tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--tag requires a value (e.g. --tag v1.7.0)"
          exit 1
        fi
        SPECIFIC_TAG="$2"
        shift 2
        ;;
      --contributor)
        CONTRIBUTOR_MODE=true
        shift
        ;;
      --skip-clawhub)
        SKIP_CLAWHUB=true
        shift
        ;;
      --skip-workspace)
        SKIP_WORKSPACE=true
        shift
        ;;
      --skip-engram)
        SKIP_ENGRAM=true
        shift
        ;;
      --engram-tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--engram-tag requires a value (e.g. --engram-tag v1.15.4)"
          exit 1
        fi
        ENGRAM_TAG="$2"
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
      --no-tui)
        NO_TUI=true
        shift
        ;;
      --accept-defaults)
        ACCEPT_DEFAULTS=true
        shift
        ;;
      --quiet | -q)
        QUIET=true
        shift
        ;;
      --version)
        show_version
        exit 0
        ;;
      --help | -h)
        show_help
        exit 0
        ;;
      *)
        log_fail "Unknown flag: $1"
        echo "Usage: install.sh [--clone|--template|--full-clone <bundle>|--tag <version>] [flags]"
        exit 1
        ;;
    esac
  done

  # --full-clone is incompatible with template/clone modes and workspace seeding
  if [ -n "$FULL_CLONE_SOURCE" ]; then
    if $CLONE_MODE || $TEMPLATE_MODE || $SKIP_WORKSPACE; then
      log_fail "--full-clone cannot be combined with --clone, --template, or --skip-workspace"
      exit 1
    fi
  fi
}

show_help() {
  echo "Usage: install.sh [flags]"
  echo "Flags:"
  echo "  --clone             Project-agnostic templates (uses main branch since v1.7.0)"
  echo "  --template          Use generic templates (default)"
  echo "  --full-clone <path-or-url>  Restore a full-clone bundle (from export-full-clone.sh)"
  echo "  --tag <version>     Install a specific release (e.g. v1.7.0)"
  echo "  --contributor       Install pre-commit hook for content boundary enforcement"
  echo "  --skip-clawhub      Skip ClawHub skill installation"
  echo "  --skip-workspace    Skip workspace seeding"
  echo "  --skip-engram       Skip Engram memory system installation"
  echo "  --engram-tag <ver>  Install a specific Engram version (default: latest)"
  echo "  --force             Overwrite conflicting files without prompting"
  echo "  --force-stash       Stash local changes before pulling"
  echo "  --dry-run           Show what would be done without making changes"
  echo "  --no-tui            Force text prompts even when dialog is available"
  echo "  --accept-defaults   Accept all defaults non-interactively"
  echo "  --quiet, -q         Suppress informational output"
  echo "  --version           Show version and exit"
  echo "  --help, -h          Show this help"
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

# ---------------------------------------------------------------------------
# TUI functions (simplified — no per-phase model picker)
# ---------------------------------------------------------------------------

compute_tui_mode() {
  if [ -n "$FULL_CLONE_SOURCE" ]; then
    TUI_MODE=false
    return
  fi

  if $NO_TUI || $ACCEPT_DEFAULTS; then
    TUI_MODE=false
    return
  fi

  if $INTERACTIVE_PROMPT && command -v dialog >/dev/null 2>&1; then
    TUI_MODE=true
  else
    TUI_MODE=false
  fi
}

set_component_defaults() {
  COMPONENTS[engram]="$([ "$SKIP_ENGRAM" = false ] && echo true || echo false)"
  COMPONENTS[clawhub]="$([ "$SKIP_CLAWHUB" = false ] && echo true || echo false)"
  COMPONENTS[workspace]="$([ "$SKIP_WORKSPACE" = false ] && echo true || echo false)"
  COMPONENTS[force]="$([ "$FORCE" = true ] && echo true || echo false)"
  COMPONENTS[contributor]="$([ "$CONTRIBUTOR_MODE" = true ] && echo true || echo false)"
}

sync_component_flags_from_state() {
  SKIP_ENGRAM=$([ "${COMPONENTS[engram]:-true}" = true ] && echo false || echo true)
  SKIP_CLAWHUB=$([ "${COMPONENTS[clawhub]:-true}" = true ] && echo false || echo true)
  SKIP_WORKSPACE=$([ "${COMPONENTS[workspace]:-true}" = true ] && echo false || echo true)
  FORCE=$([ "${COMPONENTS[force]:-false}" = true ] && echo true || echo false)
  CONTRIBUTOR_MODE=$([ "${COMPONENTS[contributor]:-false}" = true ] && echo true || echo false)

  if [ "$FORCE" = false ]; then
    FORCE_STASH=false
  fi
}

tui_welcome() {
  dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Installer" \
    --msgbox "Welcome to lucy-agent.\n\nThis wizard lets you choose the install mode and optional components.\nSDD agent profiles are fixed and configured via config/agent-fragment.json5." \
    12 78 >/dev/null
}

tui_install_mode() {
  local selection tag_input

  if ! selection=$(dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Install mode" \
    --default-item clone \
    --menu "Choose how lucy-agent should be installed." 15 84 3 \
    clone "Lucy's config (project-agnostic)" \
    template "Generic templates" \
    tag "Specific release tag"); then
    log_info "Installer cancelled during install mode selection"
    exit 0
  fi

  case "$selection" in
    clone)
      CLONE_MODE=true
      LUCY_BRANCH="main"
      SPECIFIC_TAG=""
      ;;
    template)
      CLONE_MODE=false
      LUCY_BRANCH="main"
      SPECIFIC_TAG=""
      ;;
    tag)
      if ! tag_input=$(dialog --stdout \
        --backtitle "lucy-agent v${CURRENT_VERSION}" \
        --title "Specific tag" \
        --inputbox "Enter the release tag to install (example: v1.9.0)." 10 72 "v${CURRENT_VERSION}"); then
        log_info "Installer cancelled during tag entry"
        exit 0
      fi

      if [ -z "$tag_input" ]; then
        log_fail "Specific tag cannot be empty"
        exit 1
      fi

      CLONE_MODE=false
      LUCY_BRANCH="main"
      SPECIFIC_TAG="$tag_input"
      ;;
  esac
}

tui_component_checklist() {
  local selection item

  if ! selection=$(dialog --stdout --separate-output \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Optional components" \
    --checklist "Toggle optional install components." 17 88 5 \
    engram "Install Engram memory system" "$([ "${COMPONENTS[engram]}" = true ] && echo on || echo off)" \
    clawhub "Sync ClawHub skills" "$([ "${COMPONENTS[clawhub]}" = true ] && echo on || echo off)" \
    workspace "Seed workspace files" "$([ "${COMPONENTS[workspace]}" = true ] && echo on || echo off)" \
    contributor "Install pre-commit hook (content boundaries)" "$([ "${COMPONENTS[contributor]}" = true ] && echo on || echo off)" \
    force "Force overwrite conflicts" "$([ "${COMPONENTS[force]}" = true ] && echo on || echo off)"); then
    log_info "Installer cancelled during component selection"
    exit 0
  fi

  COMPONENTS[engram]=false
  COMPONENTS[clawhub]=false
  COMPONENTS[workspace]=false
  COMPONENTS[contributor]=false
  COMPONENTS[force]=false

  while IFS= read -r item; do
    case "$item" in
      engram | clawhub | workspace | contributor | force) COMPONENTS["$item"]=true ;;
    esac
  done <<<"$selection"

  sync_component_flags_from_state
}

tui_install_confirm() {
  local mode_label

  if [ -n "$SPECIFIC_TAG" ]; then
    mode_label="Specific tag ($SPECIFIC_TAG)"
  elif $CLONE_MODE; then
    mode_label="Lucy's config (project-agnostic)"
  else
    mode_label="Generic templates"
  fi

  dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Confirm installation" \
    --yesno "Mode: $mode_label\nEngram: $([ "$SKIP_ENGRAM" = false ] && echo yes || echo no)\nClawHub: $([ "$SKIP_CLAWHUB" = false ] && echo yes || echo no)\nWorkspace: $([ "$SKIP_WORKSPACE" = false ] && echo yes || echo no)\nPre-commit hook: $([ "$CONTRIBUTOR_MODE" = true ] && echo yes || echo no)\nForce overwrite: $([ "$FORCE" = true ] && echo yes || echo no)\n\nSDD agent profiles are fixed (see config/agent-fragment.json5).\n\nProceed with installation?" \
    20 100 >/dev/null
}

prompt_install_mode() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}lucy-agent — Choose your configuration${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
  echo "  [1] Clone Lucy's config — Full replica (recommended)"
  echo "      SOUL.md, IDENTITY.md, AGENTS.md, TOOLS.md, MEMORY.md, USER.md, HEARTBEAT.md"
  echo "      Uses the 'main' branch (project-agnostic templates since v1.7.0)"
  echo ""
  echo "  [2] Use templates — Start with generic files"
  echo "      USER.md will have placeholders for you to fill in"
  echo ""
  printf "Your choice [1/2] (default: 2): "
  local answer
  answer=$(read_line "2")
  case "$answer" in
    1 | 1*)
      CLONE_MODE=true
      LUCY_BRANCH="main"
      log_info "Mode: Clone Lucy's config"
      ;;
    2 | "")
      CLONE_MODE=false
      LUCY_BRANCH="main"
      log_info "Mode: Generic templates"
      ;;
    *)
      log_fail "Invalid choice. Aborting."
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Step 1: Detect environment
# ---------------------------------------------------------------------------
step_detect_openclaw() {
  log_step "Step 1: Checking environment"

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would check for OpenClaw CLI"
    return 0
  fi

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
    installed_version=$("$ENGRAM_BIN" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    if [ "$installed_version" = "$version" ] && ! $FORCE; then
      log_ok "Unchanged: engram v$installed_version"
      return 0
    fi
  fi

  # ---- Ensure target directory exists ----
  mkdir -p "${HOME}/.local/bin"

  # ---- Construct download URL ----
  local asset="engram_${version}_${platform}.tar.gz"
  local url="https://github.com/Gentleman-Programming/engram/releases/download/v${version}/${asset}"

  # ---- Download ----
  log_info "Engram: downloading v${version} (${platform})..."
  local tmpdir
  tmpdir=$(mktemp -d)
  # Use RETURN trap instead of EXIT to avoid leaking local variable to global scope
  trap 'rm -rf "$tmpdir"' RETURN

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
  # Run search to verify binary and initialize database at configured path
  log_info "Verifying Engram binary and initializing database..."
  if ENGRAM_DATA_DIR="${ENGRAM_DATA_DIR:-$HOME/.local/share/engram}" "$ENGRAM_BIN" context >/dev/null 2>&1; then
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
      elif $DRY_RUN; then
        log_info "[DRY-RUN] Would prompt to stash or skip local changes in $LUCY_DIR"
        skip_pull=true
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
          2)
            log_info "Skipping pull..."
            skip_pull=true
            ;;
          *)
            log_fail "Installation aborted."
            exit 1
            ;;
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
        git fetch origin "${LUCY_BRANCH#tags/}"
        git checkout -B "${LUCY_BRANCH#tags/}" "origin/${LUCY_BRANCH#tags/}"
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
        "$LUCY_REPO" "$LUCY_DIR" 2>&1 |
        while IFS= read -r line; do
          log_info "$line"
        done
    fi
    log_ok "Cloned lucy-agent ($LUCY_BRANCH)"
  fi

  # Write version file
  if ! $DRY_RUN; then
    local installed_branch="main"
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

  # Validate templates before seeding
  if ! validate_templates; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would abort due to template validation failure"
    else
      log_fail "Aborting: template validation failed. Run with --force to bypass."
      if ! $FORCE; then
        exit 1
      fi
      log_warn "Forcing seed despite template validation failures"
    fi
  fi

  mkdir -p "$WORKSPACE_DIR"

  local ws_src="${LUCY_DIR}/workspace"
  if [ ! -d "$ws_src" ]; then
    log_warn "No workspace/ directory in repo; skipping workspace seed"
    return
  fi

  for file in "$ws_src"/*.md; do
    [ -f "$file" ] || continue
    local filename source_file dest repo_sum existing_sum
    filename="$(basename "$file")"

    if is_excluded "$filename"; then
      log_info "Skipped (excluded): $filename"
      continue
    fi

    source_file="$file"
    dest="${WORKSPACE_DIR}/${filename}"
    repo_sum=$(sha256_check "$source_file")
    existing_sum=$(sha256_check "$dest")

    if [ -z "$existing_sum" ]; then
      if ! $DRY_RUN; then
        cp "$source_file" "$dest"
      fi
      log_ok "Created $filename"
    elif [ "$existing_sum" != "$repo_sum" ]; then
      if $DRY_RUN; then
        log_info "[DRY-RUN] Would resolve conflict for $filename"
      elif $FORCE; then
        if ! $DRY_RUN; then
          cp "$source_file" "$dest"
        fi
        log_ok "Forced overwrite: $filename"
      else
        if prompt_conflict "overwrite/skip/abort" "$dest"; then
          if ! $DRY_RUN; then
            cp "$source_file" "$dest"
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

  if [ -d "${ws_src}/sdd" ]; then
    while IFS= read -r -d '' sdd_file; do
      local sdd_rel="${sdd_file#$ws_src/}"
      local sdd_dest="${WORKSPACE_DIR}/${sdd_rel}"
      local sdd_dest_dir repo_sum existing_sum
      sdd_dest_dir="$(dirname "$sdd_dest")"
      repo_sum=$(sha256_check "$sdd_file")
      existing_sum=$(sha256_check "$sdd_dest")

      mkdir -p "$sdd_dest_dir"

      if [ -z "$existing_sum" ]; then
        if ! $DRY_RUN; then
          cp "$sdd_file" "$sdd_dest"
        fi
        log_ok "Created $sdd_rel"
      elif [ "$existing_sum" != "$repo_sum" ]; then
        if $DRY_RUN; then
          log_info "[DRY-RUN] Would resolve conflict for $sdd_rel"
        elif $FORCE; then
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

  # Install pre-commit hook in contributor mode
  if $CONTRIBUTOR_MODE; then
    log_step "Step 4b: Installing pre-commit hook (contributor mode)"
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would install pre-commit hook"
    else
      if [ -f "$LUCY_DIR/scripts/install-pre-commit-hook.sh" ]; then
        bash "$LUCY_DIR/scripts/install-pre-commit-hook.sh"
        log_ok "Pre-commit hook installed for content boundary enforcement"
      else
        log_error "scripts/install-pre-commit-hook.sh not found — contributor mode requires the hook installer"
        log_error "This is a bug in the release. Please report it."
        exit 1
      fi
    fi
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
      local existing_sum
      existing_sum=$(sha256_check "${dest}/SKILL.md" 2>/dev/null || echo "")
      local repo_sum
      repo_sum=$(sha256_check "$skill_file")
      if [ "$existing_sum" != "$repo_sum" ]; then
        if $DRY_RUN; then
          log_info "[DRY-RUN] Would resolve conflict for skill/$skill_name"
        elif $FORCE; then
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
  done <"$clawhub_file"

  log_ok "ClawHub skills processed: $installed ok, $failed skipped/failed"
}

# ---------------------------------------------------------------------------
# Step 7: Auto-include config fragment in openclaw.json
# ---------------------------------------------------------------------------
step_include_config_fragment() {
  log_step "Step 7: Gateway config"

  local openclaw_json="${HOME}/.openclaw/openclaw.json"
  local include_directive='$include: "./lucy-agent/config/agent-fragment.json5"'
  local include_key="lucy-agent/config/agent-fragment.json5"

  # Check if the include is already present
  if [ -f "$openclaw_json" ] && grep -qF "$include_key" "$openclaw_json" 2>/dev/null; then
    log_ok "Config fragment already linked in openclaw.json"
    echo ""
    echo "  The agent-fragment.json5 is already referenced in your"
    echo "  openclaw.json. No changes needed."
    echo ""
    echo "  Restart OpenClaw to apply: ${BLUE}openclaw gateway restart${NC}"
    echo ""
    return
  fi

  # Create openclaw.json if it doesn't exist
  if [ ! -f "$openclaw_json" ]; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would create ${openclaw_json} with config fragment include"
    else
      echo "{ $include_directive }" >"$openclaw_json"
      log_ok "Created openclaw.json with config fragment"
    fi
  else
    # Backup and inject the include directive
    local backup
    backup="${openclaw_json}.backup.$(date +%s)"
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would backup openclaw.json and inject config fragment include"
    else
      cp "$openclaw_json" "$backup"
      log_info "Backed up existing openclaw.json to $(basename "$backup")"

      # Insert the include directive after the first opening brace (JSON5 property)
      # sed finds first '{' on any line and inserts the directive after it
      local tmp="${openclaw_json}.tmp"
      sed "0,/{/s/{/{\n  ${include_directive},/" "$openclaw_json" >"$tmp" && mv "$tmp" "$openclaw_json"
      log_ok "Config fragment linked in openclaw.json"
    fi
  fi

  echo ""
  echo "  The 9 SDD agent profiles, skills allowlist, and Engram memory"
  echo "  are now configured via config/agent-fragment.json5."
  echo ""
  echo "  Restart OpenClaw to apply: ${BLUE}openclaw gateway restart${NC}"
  echo ""
  echo -e "${YELLOW}NOTE:${NC} You still need to configure your channel tokens,"
  echo "API keys, and secrets manually in openclaw.json."
  echo ""
}

# ---------------------------------------------------------------------------
# Step 7b: Restore full-clone bundle (--full-clone)
# ---------------------------------------------------------------------------
step_restore_full_clone() {
  log_step "Restoring full-clone bundle"

  local bundle_source="$FULL_CLONE_SOURCE"
  local bundle_file=""
  local tmp_dir=""
  local restore_root="${HOME}/.openclaw"

  # Resolve bundle: local file or remote URL
  if [[ "$bundle_source" =~ ^https?:// ]]; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would download bundle from $bundle_source"
      bundle_file="$bundle_source"
    else
      log_info "Downloading bundle from $bundle_source ..."
      bundle_file="$(mktemp)"
      if ! curl -fsSL --connect-timeout 15 --max-time 600 "$bundle_source" -o "$bundle_file"; then
        log_fail "Could not download bundle from $bundle_source"
        rm -f "$bundle_file"
        exit 1
      fi
    fi
  else
    if [ ! -f "$bundle_source" ]; then
      log_fail "Bundle not found: $bundle_source"
      exit 1
    fi
    bundle_file="$bundle_source"
  fi

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would extract bundle and restore to $restore_root"
    return
  fi

  # Extract to temp dir and verify structure
  tmp_dir="$(mktemp -d)"
  cleanup_tmp() { [ -n "${tmp_dir:-}" ] && rm -rf "$tmp_dir"; }
  trap cleanup_tmp RETURN
  if ! tar -xzf "$bundle_file" -C "$tmp_dir" --no-same-owner 2>/dev/null; then
    log_fail "Could not extract bundle (not a valid tar.gz?)"
    exit 1
  fi

  # Bundle may contain .openclaw/ prefix or be the openclaw root directly
  local bundle_root="$tmp_dir"
  if [ -d "$tmp_dir/.openclaw" ]; then
    bundle_root="$tmp_dir/.openclaw"
  fi

  # Verify bundle has expected content
  if [ ! -f "$bundle_root/openclaw.json" ] && [ ! -d "$bundle_root/lucy-agent" ] && [ ! -d "$bundle_root/workspace" ]; then
    log_fail "Bundle does not contain expected .openclaw structure (openclaw.json, lucy-agent/, or workspace/)"
    exit 1
  fi

  # Backup existing ~/.openclaw
  local backup_dir
  backup_dir="${HOME}/.openclaw.backup.$(date +%Y%m%d-%H%M%S)"
  if [ -d "$restore_root" ]; then
    log_info "Backing up existing $restore_root to $backup_dir"
    if ! mv "$restore_root" "$backup_dir"; then
      log_fail "Could not back up existing $restore_root. Check disk space."
      exit 1
    fi
  fi

  # Restore
  log_info "Restoring files..."
  mkdir -p "$restore_root"
  if ! cp -a "$bundle_root/." "$restore_root/"; then
    log_fail "Restore failed. Your original config is at $backup_dir"
    exit 1
  fi
  log_ok "Restore complete (backup: $backup_dir)"

  # If the bundle did not include lucy-agent, ensure it is present for later steps
  if [ ! -d "${LUCY_DIR}" ]; then
    log_warn "Bundle did not contain lucy-agent/ — cloning latest instead"
    step_clone_or_pull
  fi
}

# ---------------------------------------------------------------------------
# Step 8: Verify
# ---------------------------------------------------------------------------
step_verify() {
  log_step "Step 8: Verifying installation"
  if ! $DRY_RUN; then
    cd "$LUCY_DIR" && bash verify.sh || true
    log_ok "verify.sh completed (see output above for results)"
  else
    log_info "[DRY-RUN] Would run verify.sh"
  fi
}

# ---------------------------------------------------------------------------
# Step 9: Report
# ---------------------------------------------------------------------------
step_report() {
  local mode_label="generic templates"
  if [ -n "$FULL_CLONE_SOURCE" ]; then
    mode_label="full-clone restore (bundle: $FULL_CLONE_SOURCE)"
  elif $CLONE_MODE; then
    mode_label="Lucy's config (project-agnostic)"
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
  if $CONTRIBUTOR_MODE; then
    echo -e "Pre-commit:   ${BLUE}installed${NC}"
  fi
  echo ""
  echo -e "Update later:"
  echo -e "  cd ${LUCY_DIR} && ./update.sh"
  echo ""
  echo -e "Verify:"
  echo -e "  cd ${LUCY_DIR} && ./verify.sh"
  echo ""
  echo -e "${GREEN}Next step:${NC} restart OpenClaw to apply the new config"
  echo -e "  ${BLUE}openclaw gateway restart${NC}"
  echo -e "  ${BLUE}/new${NC} (in any active session after restart)"
  echo ""
  if [ -n "$FULL_CLONE_SOURCE" ]; then
    echo -e "${YELLOW}NOTE:${NC} If the bundle was exported WITHOUT --include-identity,"
    echo -e "  re-authenticate your providers and channels:"
    echo -e "  ${BLUE}openclaw configure --section model${NC}"
    echo ""
  fi
  echo -e "${GREEN}After restart, verify Lucy is working:${NC}"
  echo -e "  1. Ask: \"${BLUE}Who are you?${NC}\" → She should introduce herself as your AI colleague"
  echo -e "  2. Say: \"${BLUE}My name is [your name]${NC}\" → She should greet you by name"
  echo -e "  3. Ask: \"${BLUE}What do you know about SDD Orchestrator?${NC}\" → She should explain the 8-phase workflow"
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
  compute_tui_mode
  set_component_defaults

  if $TUI_MODE; then
    tui_welcome

    if ! $NON_INTERACTIVE_FLAGS && [ -z "$SPECIFIC_TAG" ]; then
      tui_install_mode
    elif [ -n "$SPECIFIC_TAG" ]; then
      log_info "Mode: Specific tag ($SPECIFIC_TAG)"
    elif [ -n "$FULL_CLONE_SOURCE" ]; then
      log_info "Mode: Full clone (restore from bundle)"
    elif $CLONE_MODE; then
      log_info "Mode: Clone Lucy's config"
    else
      log_info "Mode: Generic templates"
    fi

    tui_component_checklist
    if ! tui_install_confirm; then
      exit 0
    fi
  else
    if $ACCEPT_DEFAULTS; then
      if [ -n "$SPECIFIC_TAG" ]; then
        log_info "Mode: Specific tag ($SPECIFIC_TAG)"
      elif [ -n "$FULL_CLONE_SOURCE" ]; then
        log_info "Mode: Full clone (restore from bundle)"
      elif $CLONE_MODE; then
        log_info "Mode: Clone Lucy's config"
      else
        CLONE_MODE=false
        LUCY_BRANCH="main"
        log_info "Mode: Generic templates (--accept-defaults)"
      fi
      log_info "Components: engram=$([ "$SKIP_ENGRAM" = false ] && echo yes || echo no), clawhub=$([ "$SKIP_CLAWHUB" = false ] && echo yes || echo no), workspace=$([ "$SKIP_WORKSPACE" = false ] && echo yes || echo no), contributor=$([ "$CONTRIBUTOR_MODE" = true ] && echo yes || echo no), force=$([ "$FORCE" = true ] && echo yes || echo no)"
    elif ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && [ -z "$SPECIFIC_TAG" ] && $INTERACTIVE_PROMPT; then
      prompt_install_mode
    elif ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && [ -z "$SPECIFIC_TAG" ] && ! $INTERACTIVE_PROMPT; then
      CLONE_MODE=false
      LUCY_BRANCH="main"
      log_info "Mode: Generic templates (non-interactive, use --clone for Lucy's config)"
    elif [ -n "$SPECIFIC_TAG" ]; then
      log_info "Mode: Specific tag ($SPECIFIC_TAG)"
    elif [ -n "$FULL_CLONE_SOURCE" ]; then
      log_info "Mode: Full clone (restore from bundle)"
    elif $CLONE_MODE; then
      log_info "Mode: Clone Lucy's config"
    else
      log_info "Mode: Generic templates"
    fi
  fi

  step_detect_openclaw
  step_install_engram
  if [ -n "$FULL_CLONE_SOURCE" ]; then
    step_restore_full_clone
  else
    step_clone_or_pull
    step_seed_workspace
  fi
  step_install_bundled_skills
  step_install_clawhub_skills
  step_include_config_fragment
  step_verify
  step_report
}

main "$@"
