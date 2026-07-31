#!/usr/bin/env bash
# =============================================================================
# lucy-agent export-full-clone.sh — Export current OpenClaw setup to a bundle
# =============================================================================
# Usage:
#   bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh
#   bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --include-identity
#   bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --exclude-memories
#   bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --include-identity --exclude-memories
#   bash ~/.openclaw/lucy-agent/scripts/export-full-clone.sh --output /tmp
#
# Flags:
#   --include-identity  Include auth tokens, credentials, device identity, and .env files
#                       (bundle becomes sensitive — keep it private)
#   --exclude-memories  Exclude session memory data: workspace/MEMORY.md,
#                       workspace/memory/, and ~/.openclaw/memory/
#   --output <dir>      Write the bundle to <dir> (default: current directory)
#   --dry-run           Show what would be exported without creating the bundle
#   --help, -h          Show this help
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

OPENCLAW_DIR="${HOME}/.openclaw"
INCLUDE_IDENTITY=false
EXCLUDE_MEMORIES=false
DRY_RUN=false
OUTPUT_DIR="."

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  echo "Usage: export-full-clone.sh [flags]"
  echo "Flags:"
  echo "  --include-identity  Include auth/credentials/identity/.env (sensitive)"
  echo "  --exclude-memories  Exclude session memory data"
  echo "  --output <dir>      Output directory (default: current dir)"
  echo "  --dry-run           Show what would be exported without creating the bundle"
  echo "  --help, -h          Show this help"
}

# ---------------------------------------------------------------------------
# Build exclusion patterns
# ---------------------------------------------------------------------------
build_exclusions() {
  # Always excluded — transient/runtime state and auto-backups
  # NOTE: GNU tar --exclude matches directory trees only when the pattern
  # has NO trailing slash (e.g. .openclaw/logs, not .openclaw/logs/)
  local always=(
    ".openclaw/logs"
    ".openclaw/delivery-queue"
    ".openclaw/tasks"
    ".openclaw/subagents"
    ".openclaw/media"
    ".openclaw/plugin-runtime-deps"
    ".openclaw/locks"
    ".openclaw/flows"
    ".openclaw/telegram/update-offset-*"
    ".openclaw/openclaw.json.last-good"
    ".openclaw/*.clobbered.*"
    ".openclaw/*.bak"
    ".openclaw/*.bak.*"
    ".openclaw/*.backup-*"
  )

  # Identity/security — excluded unless --include-identity
  if ! $INCLUDE_IDENTITY; then
    always+=(
      ".openclaw/identity"
      ".openclaw/credentials"
      ".openclaw/.env"
      ".openclaw/workspace/.env"
      ".openclaw/lucy-agent/.env"
    )
  fi

  # Session memory — excluded with --exclude-memories
  if $EXCLUDE_MEMORIES; then
    always+=(
      ".openclaw/memory"
      ".openclaw/workspace/MEMORY.md"
      ".openclaw/workspace/memory"
    )
  fi

  printf '%s\n' "${always[@]}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --include-identity)
        INCLUDE_IDENTITY=true
        shift
        ;;
      --exclude-memories)
        EXCLUDE_MEMORIES=true
        shift
        ;;
      --output)
        if [[ -z "${2:-}" ]]; then
          log_fail "--output requires a value"
          exit 1
        fi
        OUTPUT_DIR="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help | -h)
        show_help
        exit 0
        ;;
      *)
        log_fail "Unknown flag: $1"
        show_help
        exit 1
        ;;
    esac
  done

  if [ ! -d "$OPENCLAW_DIR" ]; then
    log_fail "No ~/.openclaw directory found at $OPENCLAW_DIR. Nothing to export."
    exit 1
  fi

  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local bundle_name="lucy-full-clone-${timestamp}.tar.gz"
  local bundle_path="${OUTPUT_DIR%/}/${bundle_name}"

  log_info "Exporting full clone from $OPENCLAW_DIR ..."
  if $INCLUDE_IDENTITY; then
    log_info "Mode: --include-identity (auth, credentials, identity, .env INCLUDED)"
  else
    log_info "Mode: default (no auth, no identity, no .env)"
  fi
  if $EXCLUDE_MEMORIES; then
    log_info "Mode: --exclude-memories (session memory data EXCLUDED)"
  else
    log_info "Mode: with memories (session memory data included)"
  fi

  local exclude_args=()
  while IFS= read -r pattern; do
    [ -n "$pattern" ] && exclude_args+=(--exclude="$pattern")
  done < <(build_exclusions)

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would create: $bundle_path"
    log_info "[DRY-RUN] Exclusions:"
    local p
    for p in "${exclude_args[@]}"; do
      log_info "  ${p#--exclude=}"
    done
    return 0
  fi

  # Create output dir if needed
  mkdir -p "$OUTPUT_DIR"

  # Tar from $HOME so the bundle has a .openclaw/ prefix
  # shellcheck disable=SC2068
  if ! tar -czf "$bundle_path" -C "$HOME" "${exclude_args[@]}" .openclaw; then
    log_fail "Export failed. See errors above."
    exit 1
  fi

  local size
  size="$(du -h "$bundle_path" | cut -f1)"
  log_ok "Bundle created: $bundle_path ($size)"

  if $INCLUDE_IDENTITY; then
    log_warn "This bundle contains sensitive authentication material."
    log_warn "Transfer it privately and delete it when no longer needed."
  fi
  if $EXCLUDE_MEMORIES; then
    log_info "Session memory data was excluded from the bundle."
  fi
}

main "$@"
