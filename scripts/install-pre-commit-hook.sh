#!/usr/bin/env bash
# =============================================================================
# install-pre-commit-hook.sh — Materialize .git/hooks/pre-commit
# =============================================================================
# Installs a thin pre-commit wrapper that calls check-content-boundaries.sh.
#
# Usage:
#   ./scripts/install-pre-commit-hook.sh         Install the hook
#   ./scripts/install-pre-commit-hook.sh --force  Replace existing hook after backup
#   ./scripts/install-pre-commit-hook.sh --dry-run Show what would be done
#
# Behavior:
#   - No hook exists → create wrapper
#   - Existing hook matches lucy-ai wrapper → overwrite/update
#   - Existing hook differs → backup + warn (or --force replaces after backup)
#
# Exit: 0 = hook installed or already matches, non-zero = error
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORCE_MODE=false
DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }

# Generate the hook wrapper content
generate_hook_content() {
  cat <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
exec "$repo_root/scripts/check-content-boundaries.sh" --staged
HOOK
}

# Check if the existing hook matches our wrapper exactly
is_lucy_hook() {
  local hook_path="$1"
  local generated
  generated=$(generate_hook_content)
  if [ -f "$hook_path" ] && [ "$(cat "$hook_path")" = "$generated" ]; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: install-pre-commit-hook.sh [--force] [--dry-run]"
  echo ""
  echo "  --force    Replace existing hook after creating a backup"
  echo "  --dry-run  Show what would be done without making changes"
}

main() {
  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE_MODE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help | -h)
        print_usage
        exit 0
        ;;
      *)
        log_error "Unknown flag: $1"
        print_usage
        exit 1
        ;;
    esac
  done

  # Must be inside a git repo
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not a git repository (or any of the parent directories)"
    exit 1
  fi

  local HOOKS_DIR
  HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
  local HOOK_PATH="${HOOKS_DIR}/pre-commit"

  # Ensure hooks directory exists
  if [ ! -d "$HOOKS_DIR" ]; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would create hooks directory: $HOOKS_DIR"
    else
      mkdir -p "$HOOKS_DIR"
      log_info "Created hooks directory: $HOOKS_DIR"
    fi
  fi

  # Case 1: No hook exists → create
  if [ ! -f "$HOOK_PATH" ]; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would create pre-commit hook at .git/hooks/pre-commit"
    else
      generate_hook_content > "$HOOK_PATH"
      chmod +x "$HOOK_PATH"
      log_ok "Created pre-commit hook: .git/hooks/pre-commit"
      log_info "Hook calls: scripts/check-content-boundaries.sh --staged"
    fi
    return 0
  fi

  # Check if the existing hook is executable
  if [ ! -x "$HOOK_PATH" ]; then
    log_warn "Existing pre-commit hook is not executable, will be replaced"
    if $DRY_RUN; then
      log_info "[DRY-RUN] Would replace non-executable pre-commit hook"
    else
      cp "$HOOK_PATH" "${HOOK_PATH}.backup.$(date +%s)"
      generate_hook_content > "$HOOK_PATH"
      chmod +x "$HOOK_PATH"
      log_ok "Replaced non-executable pre-commit hook"
    fi
    return 0
  fi

  # Case 2: Existing hook matches ours → update/overwrite
  if is_lucy_hook "$HOOK_PATH"; then
    if $DRY_RUN; then
      log_info "[DRY-RUN] Pre-commit hook already matches lucy-ai wrapper (would overwrite)"
    else
      generate_hook_content > "$HOOK_PATH"
      chmod +x "$HOOK_PATH"
      log_ok "Updated pre-commit hook (already matches lucy-ai wrapper)"
    fi
    return 0
  fi

  # Case 3: Existing hook differs → backup + warn or --force replace
  if $FORCE_MODE; then
    local backup_timestamp
    backup_timestamp=$(date +%s)
    local backup_path="${HOOK_PATH}.backup.${backup_timestamp}"

    if $DRY_RUN; then
      log_info "[DRY-RUN] Would backup existing hook to ${HOOK_PATH}.backup.${backup_timestamp}"
      log_info "[DRY-RUN] Would install lucy-ai pre-commit hook (--force)"
    else
      cp "$HOOK_PATH" "$backup_path"
      generate_hook_content > "$HOOK_PATH"
      chmod +x "$HOOK_PATH"
      log_ok "Backed up existing hook to ${backup_path}"
      log_ok "Installed lucy-ai pre-commit hook (--force)"
    fi
  else
    # Write alongside but do not replace
    local sidecar_path="${HOOK_PATH}.lucy-ai"
    if $DRY_RUN; then
      log_info "[DRY-RUN] Different pre-commit hook detected"
      log_info "[DRY-RUN] Would write lucy-ai hook to .git/hooks/pre-commit.lucy-ai"
    else
      generate_hook_content > "$sidecar_path"
      chmod +x "$sidecar_path"
      log_warn "A different pre-commit hook already exists at .git/hooks/pre-commit"
      log_info "Wrote lucy-ai hook to .git/hooks/pre-commit.lucy-ai"
      log_info "To use lucy-ai enforcement:"
      log_info "  1. Review and merge both hooks manually, OR"
      log_info "  2. Run with --force to replace (existing hook will be backed up)"
      exit 1
    fi
  fi
}

main "$@"
