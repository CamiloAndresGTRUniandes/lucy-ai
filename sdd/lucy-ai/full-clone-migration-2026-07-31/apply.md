# Apply: Full-Clone Export/Import for Server Migration

## Status: Applied

## Files Modified

| File | Change | Purpose |
|------|--------|---------|
| `scripts/export-full-clone.sh` | **New file** | Standalone exporter that creates `lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz` from `~/.openclaw`. Supports `--include-identity`, `--exclude-memories`, `--output <dir>`, `--dry-run`. Sources `scripts/common.sh` for logging. |
| `install.sh` | **Modified** | Added `--full-clone <path-or-url>` flag to `parse_flags()` and `show_help()`. New `step_restore_full_clone()` function (backup, extract, restore, validate, re-auth reminder). Updated `compute_tui_mode()` and `main()` for full-clone flow. Mutual exclusion enforced with `--clone`/`--template`/`--skip-workspace`. Bumped `CURRENT_VERSION` to `1.9.0`. |
| `update.sh` | **Modified** | Bumped `CURRENT_VERSION` to `1.9.0`. |
| `verify.sh` | **Modified** | Updated README/CHANGELOG/version checks to v1.9.0. Added checks for exporter script existence and `--full-clone` flag. |
| `README.md` | **Modified** | Version badge → v1.9.0, What's New section rewritten, added `--full-clone` install example. |
| `CHANGELOG.md` | **Modified** | Added v1.9.0 entry with all new features. |
| `RELEASE_NOTES.md` | **Modified** | Rewritten for v1.9.0 release. |
| `.github/workflows/ci.yml` | **Modified** | Added `scripts/export-full-clone.sh` to bash-syntax and format-check jobs. New `test-full-clone` job: export fixture, verify exclusions, test `--include-identity`, test mutual exclusion. |

## Implementation Summary

### Exporter (`scripts/export-full-clone.sh`)

- **Default mode:** bundles `openclaw.json`, `lucy-agent/`, `workspace/` from `~/.openclaw`, excludes `identity/`, `credentials/`, `.env`, `logs/`, `delivery-queue/`, `tasks/`, `subagents/`, `media/`, `plugin-runtime-deps/`, `locks/`, `flows/`, telemetry offsets, backup files
- **`--include-identity`:** additionally includes `identity/`, `credentials/`, `.env` files. Prints security warning.
- **`--exclude-memories`:** additionally excludes `workspace/MEMORY.md`, `workspace/memory/`, `memory/`
- **`--output <dir>`:** writes bundle to specified directory (default: cwd)
- **`--dry-run`:** prints what would be exported without creating the bundle
- **Gotcha fixed:** GNU tar `--exclude` requires patterns WITHOUT trailing slash to match directories

### Installer (`install.sh --full-clone`)

- **Flag:** `--full-clone <path-or-url>` — accepts local filesystem path or HTTP/HTTPS URL
- **Mutual exclusion:** rejects `--clone`, `--template`, `--skip-workspace` when used with `--full-clone`
- **Flow:**
  1. Download bundle if URL (curl with 600s timeout)
  2. Extract to temp dir, verify structure has `.openclaw/` prefix
  3. Backup existing `~/.openclaw` → `~/.openclaw.backup.YYYYMMDD-HHMMSS/`
  4. Restore bundle files to `~/.openclaw/`
  5. Fall back to cloning lucy-agent if bundle lacked it
  6. Install bundled/clawhub skills from restored lucy-agent
  7. Link config fragment
  8. Run verify
  9. Print re-auth reminder (always shown for `--full-clone`)

## Verification Evidence

| Test | Result |
|------|--------|
| `bash -n` on all 5 scripts | ✅ All pass |
| Dry-run exporter | ✅ Correct exclusions listed |
| Default bundle: no identity/credentials/.env | ✅ Pass |
| `--include-identity`: identity/credentials/.env included | ✅ Pass |
| `--exclude-memories`: no MEMORY.md or memory/ | ✅ Pass |
| `--full-clone <missing-value>` rejected | ✅ Exit 1, clear error |
| `--full-clone` + `--skip-workspace` mutually exclusive | ✅ Exit 1, clear error |
| `--help` shows `--full-clone` | ✅ Present |
| `--version` shows v1.9.0 | ✅ Correct |
| Isolated restore test (temp HOME, mock openclaw) | ✅ Backup, restore, openclaw invoked, re-auth reminder |

## Bugs Found and Fixed During Apply

1. **GNU tar `--exclude` with trailing slash:** patterns like `.openclaw/credentials/` don't match — fixed by removing trailing slashes from all directory exclusion patterns
2. **Trap RETURN + `set -u`:** `trap 'rm -rf "$tmp_dir"' RETURN` fails when `tmp_dir` is a local variable and `set -u` is active — fixed with `cleanup_tmp()` function using `${tmp_dir:-}`
3. **lucy-agent detection check:** `[ ! -d "${LUCY_DIR}/install.sh" ]` was checking if a file is a directory — fixed to `[ ! -d "${LUCY_DIR}" ]`
4. **Mode label in main():** full-clone mode was not shown in the non-TUI mode label — added `FULL_CLONE_SOURCE` checks in both TUI and non-TUI branches

## PR Review Fixes (Copilot)

- Replaced `exit 1` inside `step_restore_full_clone()` post-temp-dir flow with `return 1` plus explicit cleanup, preventing temp extraction/download leaks.
- Removed the `RETURN` trap after discovering it can fire outside the intended local scope under `set -u`; cleanup is now explicit and deterministic.
- Clean up downloaded URL bundles on success and failure.
- Added explicit post-restore validation step: `openclaw config validate` and `openclaw models list` run after config fragment linking in `--full-clone` mode.
- Broadened default exporter exclusions to nested `.env`, `*.env`, `*token*`, `*secret*`, `*api_key*`, and `*apikey*` paths across `.openclaw` unless `--include-identity` is set.
- Added `verify.sh` drift check for `update.sh CURRENT_VERSION=1.9.0`.
- Extended CI full-clone fixture to verify nested workspace secrets are excluded by default.
