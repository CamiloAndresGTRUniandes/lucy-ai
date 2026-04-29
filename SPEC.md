# Spec: lucy-agent v1.2.0 — Stability & Polish Release

## Context

After v1.1.0 (clone mode), a post-release audit identified 11 issues across the installer ecosystem.
This release addresses all high/medium priority issues with targeted fixes.

## Requirements

### High Priority (Bug fixes)

- [R1] **update.sh respects install branch** — When installed via `--clone`, `update.sh` must pull from `lucy-config`, not switch to `main`. Track branch/tag in `${LUCY_DIR}/.version` file.
- [R2] **install.sh handles local git changes before pull** — If the local repo has uncommitted changes, `git pull` would fail. Detect with `git status --short` and `git stash` before pulling (or `--force` flag skips prompt).
- [R3] **AGENTS.md has no dangling skill references** — Remove `angular/*` skills table entry from AGENTS.md since those skills are not bundled in lucy-agent.

### Medium Priority (Usability)

- [R4] **--uninstall / uninstall.sh** — Clean removal script. Removes: `${LUCY_DIR}`, skills in `${SKILLS_DIR}` that match bundled names, workspace seeds. Always prompts for confirmation. Supports `--force` for non-interactive.
- [R5] **DRY: extract shared helpers to scripts/common.sh** — `install.sh` and `update.sh` both define `log_info`, `log_ok`, `log_warn`, `log_fail`, `log_step`, `sha256_check`. Extract to `scripts/common.sh` and source from both scripts.
- [R6] **verify.sh shows which checks failed** — Accumulate failed check names in an array and print them at the end in both summary and exit message.
- [R7] **--version flag on install.sh and update.sh** — Show current installed version (from `${LUCY_DIR}/.version` or git tag/branch) and exit. Also show latest available version via `git ls-remote`.
- [R8] **README: fork sync section** — Add "Keeping your fork updated" section with `git remote add upstream` instructions.

### Low Priority

- [R9] **install.sh --tag/--version for fresh install of specific version** — Add `--tag <version>` support to `install.sh` for fresh installs pinned to a specific release.
- [R10] **git clone --progress** — Add `--progress` flag to `git clone` for visibility on slow connections.
- [R11] **--quiet / -q flag** — Suppress all output except warnings and errors. Useful for CI.

## Out of Scope

- ClawHub skill versioning / pinning (nice-to-have, deferred)
- `--branch` flag for install.sh (nice-to-have, deferred)
- `LHOME` env var support (the code already handles it via `${LHOME:-$HOME}`, no action needed)
- SKILL.md version hardcoding (minor, deferred)
- SHA256 integrity check for install script (nice-to-have, deferred)

## User Scenarios

### S1: User installed with --clone, runs update.sh
- Given: user ran `install.sh --clone`
- When: user runs `update.sh`
- Then: script reads `${LUCY_DIR}/.version`, finds `branch=lucy-config`, pulls from `lucy-config`

### S2: User has modified install.sh locally, runs install again
- Given: user modified `install.sh` in `${LUCY_DIR}`
- When: user runs `install.sh --force`
- Then: script stashes local changes, does git pull, restores stashed changes after

### S3: New user wants to install specific old version
- Given: user wants v1.0.0 specifically
- When: user runs `install.sh --tag v1.0.0`
- Then: script clones/fetches that specific tag

### S4: User wants clean uninstall
- Given: user wants to remove lucy-agent
- When: user runs `uninstall.sh --force`
- Then: removes `${LUCY_DIR}`, bundled skills, workspace seeds (prompts if not --force)

### S5: CI environment runs install
- Given: CI pipeline with no TTY
- When: `curl ... | bash -s -- --clone --quiet`
- Then: runs silently except warnings/errors, exits with appropriate code

## Architecture Decisions

| Decision | Choice | Rationale | Alternative |
|---|---|---|---|
| Version tracking | `${LUCY_DIR}/.version` file with `{branch,tag}` | Simple, durable, branch-agnostic | Git ref parsing |
| Shared helpers | `scripts/common.sh` sourced by both installers | DRY, single source of truth | Copy-paste (current) |
| Uninstall approach | Separate `uninstall.sh` script | Clean separation, easy to review | Inline in install.sh |
| Skill removal on uninstall | Only remove skills that match bundled names | Preserve user-added skills | Remove all in skills/ dir |

## File Changes

| File | Action |
|------|--------|
| `install.sh` | Refactor: source `common.sh`, add `--tag`, `--version`, `--quiet`, `--force-stash`, fix git stash logic |
| `update.sh` | Refactor: source `common.sh`, add `--version`, fix branch detection |
| `verify.sh` | Refactor: accumulate failures, show at end |
| `uninstall.sh` | **New**: clean removal script |
| `scripts/common.sh` | **New**: shared color/log/sha256 helpers |
| `workspace/AGENTS.md` | Remove angular/* from skills table |
| `README.md` | Add fork sync section, update install flags table |
| `CHANGELOG.md` | Update for v1.2.0 |
| `SKILL.md` | Update version to 1.2 |
| `LICENSE` | (unchanged) |
| `config/agent-fragment.json5` | (unchanged) |
| `workspace/*.md` | (unchanged) |
| `skills/*/SKILL.md` | (unchanged) |

## Version File Format

`${LUCY_DIR}/.version`:
```json
{
  "branch": "lucy-config",
  "tag": null,
  "version": "1.1.0",
  "installed_at": "2026-04-28T16:00:00Z"
}
```

## Acceptance Criteria

- [ ] `update.sh` run after `--clone` install pulls from `lucy-config`
- [ ] `install.sh --force` with local changes does stash + pull + stash pop
- [ ] AGENTS.md has no `angular/*` skill reference
- [ ] `uninstall.sh` removes repo, bundled skills, workspace seeds with confirmation
- [ ] `scripts/common.sh` sourced by both install.sh and update.sh (no duplicate helpers)
- [ ] `verify.sh` at end shows list of failed checks by name
- [ ] `install.sh --version` shows installed version and latest remote
- [ ] README has "Keeping your fork updated" section
- [ ] `install.sh --tag v1.0.0` installs that specific tag
- [ ] `install.sh --quiet` suppresses stdout except warnings/errors
- [ ] `git clone` uses `--progress`
- [ ] All scripts pass `bash -n` syntax check
