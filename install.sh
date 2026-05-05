#!/usr/bin/env bash
# =============================================================================
# lucy-agent install.sh — Idempotent single-command installer
# =============================================================================
# Usage:
#   # Interactive (asks you to choose config):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash
#
#   # Clone mode (installs Lucy's exact config):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --clone
#
#   # Template mode (generic templates):
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --template
#
#   # Install specific version:
#   curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash -s -- --tag v1.0.0
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
#   --no-tui         Force text prompts even when dialog is available
#   --accept-defaults Accept all defaults non-interactively
#   --version        Show version and exit
#   --help, -h       Show this help
# =============================================================================

set -euo pipefail

# Detect piped execution (curl|bash) — fetch files to temp dir and re-execute
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  curl -fsSL "https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh" -o "$TMP_DIR/install.sh"
  mkdir -p "$TMP_DIR/scripts"
  curl -fsSL "https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/scripts/common.sh" -o "$TMP_DIR/scripts/common.sh"
  exec bash "$TMP_DIR/install.sh" "$@"
fi

# Load shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

LUCY_REPO="https://github.com/CamiloAndresGTRUniandes/lucy-ai"
LUCY_BRANCH="main"
LUCY_DIR="${LHOME:-$HOME}/.openclaw/lucy-agent"
WORKSPACE_DIR="${HOME}/.openclaw/workspace"
SKILLS_DIR="${WORKSPACE_DIR}/skills"
VERSION_FILE="${LUCY_DIR}/.version"
CURRENT_VERSION="1.6.0"

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
NO_TUI=false
ACCEPT_DEFAULTS=false
TUI_MODE=false

declare -A PHASE_CONFIG
declare -A COMPONENTS
declare -a SDD_PHASES=(Explore Propose Spec Design Tasks Apply Verify Archive)

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
      --clone)
        CLONE_MODE=true
        LUCY_BRANCH="lucy-config"
        NON_INTERACTIVE_FLAGS=true
        shift
        ;;
      --template)
        CLONE_MODE=false
        LUCY_BRANCH="main"
        NON_INTERACTIVE_FLAGS=true
        shift
        ;;
      --tag)
        if [[ -z "${2:-}" ]]; then
          log_fail "--tag requires a value (e.g. --tag v1.5.0)"
          exit 1
        fi
        SPECIFIC_TAG="$2"
        shift 2
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
        echo "Usage: install.sh [--clone|--template|--tag <version>] [flags]"
        exit 1
        ;;
    esac
  done
}

show_help() {
  echo "Usage: install.sh [flags]"
  echo "Flags:"
  echo "  --clone             Clone Lucy's exact config (lucy-config branch)"
  echo "  --template          Use generic templates (default)"
  echo "  --tag <version>     Install a specific release (e.g. v1.5.0)"
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

phase_default_primary() {
  case "$1" in
    Explore | Propose | Design) echo "deepseek/deepseek-v4-pro" ;;
    Spec) echo "github-copilot/gpt-5.4" ;;
    Tasks | Archive) echo "deepseek/deepseek-v4-flash" ;;
    Apply) echo "openai-codex/gpt-5.4" ;;
    Verify) echo "openai-codex/gpt-5.3-codex" ;;
    *) echo "deepseek/deepseek-v4-pro" ;;
  esac
}

phase_default_fallback() {
  case "$1" in
    Explore | Propose | Design) echo "openai-codex/gpt-5.4" ;;
    Spec | Verify) echo "deepseek/deepseek-v4-flash" ;;
    Tasks | Archive) echo "github-copilot/gpt-5.4" ;;
    Apply) echo "deepseek/deepseek-v4-pro" ;;
    *) echo "openai-codex/gpt-5.4" ;;
  esac
}

phase_default_thinking() {
  echo "high"
}

phase_index() {
  case "$1" in
    Explore) echo 1 ;;
    Propose) echo 2 ;;
    Spec) echo 3 ;;
    Design) echo 4 ;;
    Tasks) echo 5 ;;
    Apply) echo 6 ;;
    Verify) echo 7 ;;
    Archive) echo 8 ;;
    *) echo "?" ;;
  esac
}

provider_from_model() {
  case "${1%%/*}" in
    deepseek) echo "DeepSeek" ;;
    openai-codex) echo "OpenAI Codex" ;;
    github-copilot) echo "GitHub Copilot" ;;
    manual) echo "Manual edit" ;;
    *) echo "$1" ;;
  esac
}

fallback_for_primary() {
  case "$1" in
    deepseek/deepseek-v4-pro) echo "openai-codex/gpt-5.4" ;;
    deepseek/deepseek-v4-flash) echo "github-copilot/gpt-5.4" ;;
    openai-codex/gpt-5.4) echo "deepseek/deepseek-v4-pro" ;;
    openai-codex/gpt-5.3-codex) echo "deepseek/deepseek-v4-flash" ;;
    github-copilot/gpt-5.4) echo "deepseek/deepseek-v4-flash" ;;
    *) echo "deepseek/deepseek-v4-pro" ;;
  esac
}

set_phase_config() {
  local phase="$1"
  local primary="$2"
  local fallback="$3"
  local thinking="$4"
  local mode="$5"

  PHASE_CONFIG["$phase.primary"]="$primary"
  PHASE_CONFIG["$phase.fallback"]="$fallback"
  PHASE_CONFIG["$phase.thinking"]="$thinking"
  PHASE_CONFIG["$phase.mode"]="$mode"
}

compute_tui_mode() {
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

tui_load_sdd_defaults() {
  local phase
  for phase in "${SDD_PHASES[@]}"; do
    set_phase_config \
      "$phase" \
      "$(phase_default_primary "$phase")" \
      "$(phase_default_fallback "$phase")" \
      "$(phase_default_thinking "$phase")" \
      "default"
  done
}

count_mode_phases() {
  local wanted_mode="$1"
  local total=0
  local phase
  for phase in "${SDD_PHASES[@]}"; do
    if [ "${PHASE_CONFIG["$phase.mode"]:-default}" = "$wanted_mode" ]; then
      total=$((total + 1))
    fi
  done
  echo "$total"
}

count_customized_phases() {
  count_mode_phases "customized"
}

render_phase_summary_text() {
  printf "%-9s | %-15s | %-30s | %s\n" "Phase" "Provider" "Model" "Effort"
  printf '%s\n' "----------|-----------------|--------------------------------|--------"

  local phase model provider thinking mode suffix
  for phase in "${SDD_PHASES[@]}"; do
    model="${PHASE_CONFIG["$phase.primary"]:-$(phase_default_primary "$phase")}"
    provider=$(provider_from_model "$model")
    thinking="${PHASE_CONFIG["$phase.thinking"]:-high}"
    mode="${PHASE_CONFIG["$phase.mode"]:-default}"
    suffix=""

    if [ "$mode" = "customized" ]; then
      suffix=" *"
    elif [ "$mode" = "skipped" ]; then
      suffix=" (manual)"
    fi

    printf "%-9s | %-15s | %-30s | %s%s\n" \
      "$phase" "$provider" "$model" "$thinking" "$suffix"
  done
}

log_sdd_configuration() {
  log_info "SDD phase configuration: $(count_customized_phases) customized, $(count_mode_phases "skipped") manual placeholders"
  while IFS= read -r line; do
    log_info "$line"
  done < <(render_phase_summary_text)
}

tui_generate_sdd_table() {
  cat <<EOF
| # | Fase | Modelo Primario | Fallback | Thinking |
|---|------|-----------------|----------|----------|
EOF

  local phase idx primary fallback thinking
  for phase in "${SDD_PHASES[@]}"; do
    idx=$(phase_index "$phase")
    primary="${PHASE_CONFIG["$phase.primary"]:-$(phase_default_primary "$phase")}"
    fallback="${PHASE_CONFIG["$phase.fallback"]:-$(phase_default_fallback "$phase")}"
    thinking="${PHASE_CONFIG["$phase.thinking"]:-high}"
    printf '| %s | %s | `%s` | `%s` | `%s` |\n' \
      "$idx" "$phase" "$primary" "$fallback" "$thinking"
  done

  printf '| — | Lucy Orchestrator | `deepseek/deepseek-v4-pro` | — | `high` |\n'
  printf '| — | Conversación casual | `deepseek/deepseek-v4-flash` | — | `high` |\n'
}

apply_sdd_table_to_agents_file() {
  local agents_file="$1"
  local table_file output_file

  if [ ! -f "$agents_file" ]; then
    log_warn "AGENTS.md source not found: $agents_file"
    return 1
  fi

  if ! grep -q '<!-- SDD_TABLE_START -->' "$agents_file" || ! grep -q '<!-- SDD_TABLE_END -->' "$agents_file"; then
    log_warn "AGENTS.md missing SDD table sentinels; leaving file unchanged"
    return 1
  fi

  if [ -z "${PHASE_CONFIG["Explore.primary"]:-}" ]; then
    tui_load_sdd_defaults
  fi

  table_file=$(mktemp)
  output_file=$(mktemp)
  tui_generate_sdd_table >"$table_file"

  sed -e "/<!-- SDD_TABLE_START -->/,/<!-- SDD_TABLE_END -->/{
    /<!-- SDD_TABLE_START -->/{
      p
      r $table_file
    }
    /<!-- SDD_TABLE_END -->/p
    d
  }" "$agents_file" >"$output_file"

  mv "$output_file" "$agents_file"
  rm -f "$table_file"
}

tui_welcome() {
  dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Installer" \
    --msgbox "Welcome to lucy-agent.\n\nThis wizard lets you review the SDD phase model matrix, choose the install mode, and confirm optional components before installation starts." \
    12 78 >/dev/null
}

tui_phase_picker() {
  local phase="$1"
  local default_primary default_provider default_choice choice provider model thinking fallback

  default_primary=$(phase_default_primary "$phase")
  default_provider="${default_primary%%/*}"

  if ! choice=$(dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "SDD Phase $(phase_index "$phase"): $phase" \
    --default-item default \
    --menu "Choose how to configure $phase." 14 78 3 \
    default "Use Camilo's suggested defaults" \
    customize "Pick provider, model, and thinking" \
    skip "Leave manual placeholders in AGENTS.md"); then
    log_info "Installer cancelled during SDD phase configuration"
    exit 0
  fi

  case "$choice" in
    default)
      set_phase_config \
        "$phase" \
        "$default_primary" \
        "$(phase_default_fallback "$phase")" \
        "$(phase_default_thinking "$phase")" \
        "default"
      return
      ;;
    skip)
      set_phase_config "$phase" "manual/select-primary" "manual/select-fallback" "manual" "skipped"
      return
      ;;
  esac

  if ! provider=$(dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Provider — $phase" \
    --radiolist "Select the primary provider for $phase." 14 78 3 \
    deepseek "DeepSeek" "$([ "$default_provider" = "deepseek" ] && echo on || echo off)" \
    openai-codex "OpenAI Codex" "$([ "$default_provider" = "openai-codex" ] && echo on || echo off)" \
    github-copilot "GitHub Copilot" "$([ "$default_provider" = "github-copilot" ] && echo on || echo off)"); then
    log_info "Installer cancelled during provider selection"
    exit 0
  fi

  case "$provider" in
    deepseek)
      default_choice="$([ "$default_primary" = "deepseek/deepseek-v4-pro" ] && echo pro || echo flash)"
      if ! model=$(dialog --stdout \
        --backtitle "lucy-agent v${CURRENT_VERSION}" \
        --title "Model — $phase" \
        --default-item "$default_choice" \
        --menu "Choose the DeepSeek model for $phase." 14 78 2 \
        pro "deepseek/deepseek-v4-pro" \
        flash "deepseek/deepseek-v4-flash"); then
        log_info "Installer cancelled during model selection"
        exit 0
      fi

      case "$model" in
        pro) model="deepseek/deepseek-v4-pro" ;;
        flash) model="deepseek/deepseek-v4-flash" ;;
      esac
      ;;
    openai-codex)
      default_choice="$([ "$default_primary" = "openai-codex/gpt-5.3-codex" ] && echo codex53 || echo codex54)"
      if ! model=$(dialog --stdout \
        --backtitle "lucy-agent v${CURRENT_VERSION}" \
        --title "Model — $phase" \
        --default-item "$default_choice" \
        --menu "Choose the OpenAI Codex model for $phase." 14 78 2 \
        codex54 "openai-codex/gpt-5.4" \
        codex53 "openai-codex/gpt-5.3-codex"); then
        log_info "Installer cancelled during model selection"
        exit 0
      fi

      case "$model" in
        codex54) model="openai-codex/gpt-5.4" ;;
        codex53) model="openai-codex/gpt-5.3-codex" ;;
      esac
      ;;
    github-copilot)
      model="github-copilot/gpt-5.4"
      ;;
  esac

  if ! thinking=$(dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Thinking — $phase" \
    --default-item high \
    --menu "Choose the thinking level for $phase." 15 78 4 \
    high "High (recommended)" \
    medium "Medium" \
    low "Low" \
    off "Off"); then
    log_info "Installer cancelled during thinking selection"
    exit 0
  fi

  fallback=$(fallback_for_primary "$model")
  if [ "$fallback" = "$model" ]; then
    fallback=$(phase_default_fallback "$phase")
  fi

  set_phase_config "$phase" "$model" "$fallback" "$thinking" "customized"
}

tui_phase_summary() {
  dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "SDD phase summary" \
    --msgbox "$(render_phase_summary_text)" 20 110 >/dev/null
}

tui_sdd_phase_config() {
  tui_load_sdd_defaults

  local phase
  for phase in "${SDD_PHASES[@]}"; do
    tui_phase_picker "$phase"
  done

  tui_phase_summary
}

set_component_defaults() {
  COMPONENTS[engram]="$([ "$SKIP_ENGRAM" = false ] && echo true || echo false)"
  COMPONENTS[clawhub]="$([ "$SKIP_CLAWHUB" = false ] && echo true || echo false)"
  COMPONENTS[workspace]="$([ "$SKIP_WORKSPACE" = false ] && echo true || echo false)"
  COMPONENTS[force]="$([ "$FORCE" = true ] && echo true || echo false)"
}

sync_component_flags_from_state() {
  SKIP_ENGRAM=$([ "${COMPONENTS[engram]:-true}" = true ] && echo false || echo true)
  SKIP_CLAWHUB=$([ "${COMPONENTS[clawhub]:-true}" = true ] && echo false || echo true)
  SKIP_WORKSPACE=$([ "${COMPONENTS[workspace]:-true}" = true ] && echo false || echo true)
  FORCE=$([ "${COMPONENTS[force]:-false}" = true ] && echo true || echo false)

  if [ "$FORCE" = false ]; then
    FORCE_STASH=false
  fi
}

tui_install_mode() {
  local selection tag_input

  if ! selection=$(dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Install mode" \
    --default-item clone \
    --menu "Choose how lucy-agent should be installed." 15 84 3 \
    clone "Lucy's config (lucy-config branch)" \
    template "Generic templates" \
    tag "Specific release tag"); then
    log_info "Installer cancelled during install mode selection"
    exit 0
  fi

  case "$selection" in
    clone)
      CLONE_MODE=true
      LUCY_BRANCH="lucy-config"
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
        --inputbox "Enter the release tag to install (example: v1.5.0)." 10 72 "v${CURRENT_VERSION}"); then
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
    --checklist "Toggle optional install components." 16 88 4 \
    engram "Install Engram memory system" "$([ "${COMPONENTS[engram]}" = true ] && echo on || echo off)" \
    clawhub "Sync ClawHub skills" "$([ "${COMPONENTS[clawhub]}" = true ] && echo on || echo off)" \
    workspace "Seed workspace files" "$([ "${COMPONENTS[workspace]}" = true ] && echo on || echo off)" \
    force "Force overwrite conflicts" "$([ "${COMPONENTS[force]}" = true ] && echo on || echo off)"); then
    log_info "Installer cancelled during component selection"
    exit 0
  fi

  COMPONENTS[engram]=false
  COMPONENTS[clawhub]=false
  COMPONENTS[workspace]=false
  COMPONENTS[force]=false

  while IFS= read -r item; do
    case "$item" in
      engram | clawhub | workspace | force) COMPONENTS["$item"]=true ;;
    esac
  done <<<"$selection"

  sync_component_flags_from_state
}

tui_install_confirm() {
  local mode_label

  if [ -n "$SPECIFIC_TAG" ]; then
    mode_label="Specific tag ($SPECIFIC_TAG)"
  elif $CLONE_MODE; then
    mode_label="Lucy's config (clone mode)"
  else
    mode_label="Generic templates"
  fi

  dialog --stdout \
    --backtitle "lucy-agent v${CURRENT_VERSION}" \
    --title "Confirm installation" \
    --yesno "Mode: $mode_label\nEngram: $([ "$SKIP_ENGRAM" = false ] && echo yes || echo no)\nClawHub: $([ "$SKIP_CLAWHUB" = false ] && echo yes || echo no)\nWorkspace: $([ "$SKIP_WORKSPACE" = false ] && echo yes || echo no)\nForce overwrite: $([ "$FORCE" = true ] && echo yes || echo no)\nCustomized phases: $(count_customized_phases)\nManual placeholders: $(count_mode_phases skipped)\n\n$(render_phase_summary_text)\n\nProceed with installation?" \
    24 110 >/dev/null
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
    1 | 1*)
      CLONE_MODE=true
      LUCY_BRANCH="lucy-config"
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
        "$LUCY_REPO" "$LUCY_DIR" 2>&1 |
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
    local filename source_file temp_source dest repo_sum existing_sum
    filename="$(basename "$file")"

    if is_excluded "$filename"; then
      log_info "Skipped (excluded): $filename"
      continue
    fi

    source_file="$file"
    temp_source=""
    if [ "$filename" = "AGENTS.md" ]; then
      temp_source=$(mktemp)
      cp "$file" "$temp_source"
      apply_sdd_table_to_agents_file "$temp_source" || true
      source_file="$temp_source"
      log_info "AGENTS.md: prepared SDD model table ($(count_customized_phases) customized phases)"
    fi

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

    if [ -n "$temp_source" ]; then
      rm -f "$temp_source"
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
  compute_tui_mode
  set_component_defaults

  if $TUI_MODE; then
    tui_welcome
    tui_sdd_phase_config

    if ! $NON_INTERACTIVE_FLAGS && [ -z "$SPECIFIC_TAG" ]; then
      tui_install_mode
    elif [ -n "$SPECIFIC_TAG" ]; then
      log_info "Mode: Specific tag ($SPECIFIC_TAG)"
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
    tui_load_sdd_defaults
    log_sdd_configuration

    if $ACCEPT_DEFAULTS; then
      if [ -n "$SPECIFIC_TAG" ]; then
        log_info "Mode: Specific tag ($SPECIFIC_TAG)"
      elif $CLONE_MODE; then
        log_info "Mode: Clone Lucy's config"
      else
        CLONE_MODE=false
        LUCY_BRANCH="main"
        log_info "Mode: Generic templates (--accept-defaults)"
      fi
      log_info "Components: engram=$([ "$SKIP_ENGRAM" = false ] && echo yes || echo no), clawhub=$([ "$SKIP_CLAWHUB" = false ] && echo yes || echo no), workspace=$([ "$SKIP_WORKSPACE" = false ] && echo yes || echo no), force=$([ "$FORCE" = true ] && echo yes || echo no)"
    elif ! $NON_INTERACTIVE_FLAGS && ! $CLONE_MODE && [ -z "$SPECIFIC_TAG" ] && $INTERACTIVE_PROMPT; then
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
