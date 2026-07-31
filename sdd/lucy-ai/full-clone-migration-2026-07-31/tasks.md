# Tasks: Full-Clone Export/Import for Server Migration

## Status: Draft

## Task List

- [ ] **T1: Create v1.9.0 branch and preserve SDD artifacts**
  - **Description:** Work from a dedicated feature branch for the new release so v1.8.0 remains clean. Keep the approved SDD artifacts under `sdd/lucy-ai/full-clone-migration-2026-07-31/`.
  - **Input:** `spec.md`, `design.md`, git state
  - **Output:** Branch `feat/v1.9.0-full-clone-migration` with SDD artifacts
  - **Standards:** Git workflow: feature branch → PR → review → merge
  - **Estimate:** 5 min

- [ ] **T2: Implement `scripts/export-full-clone.sh`**
  - **Description:** Add standalone exporter script that sources `scripts/common.sh`, parses `--include-identity`, `--exclude-memories`, `--output <file|dir>` (optional convenience), `--help`, and creates `lucy-full-clone-YYYYMMDD-HHMMSS.tar.gz` from `~/.openclaw`. Default mode excludes identity/auth/credentials/.env and transient runtime data. `--include-identity` includes identity, credentials, auth, and `.env`; `--exclude-memories` excludes `workspace/MEMORY.md`, `workspace/memory/`, and `.openclaw/memory/`.
  - **Input:** `scripts/common.sh`, `design.md`, current `~/.openclaw` structure
  - **Output:** `scripts/export-full-clone.sh`
  - **Standards:** Bash 4+, `set -euo pipefail`, snake_case functions, no secrets printed, explicit exclusions
  - **Estimate:** 1.5 h

- [ ] **T3: Add `--full-clone <path-or-url>` to `install.sh` flag parsing/help**
  - **Description:** Introduce `FULL_CLONE_SOURCE`, parse `--full-clone`, document it in header comments and `show_help()`, and enforce mutual exclusion with `--clone`, `--template`, and `--skip-workspace`.
  - **Input:** `install.sh`, `spec.md`, `design.md`
  - **Output:** Modified `install.sh` flag parsing and help text
  - **Standards:** Existing installer style, clear errors for invalid flag combinations
  - **Estimate:** 45 min

- [ ] **T4: Implement `step_restore_full_clone()` in `install.sh`**
  - **Description:** Add restore function that handles local paths and HTTP/HTTPS URLs, downloads URL bundles to a temp file, validates tar structure has `.openclaw/`, backs up existing `~/.openclaw` to `~/.openclaw.backup.YYYYMMDD-HHMMSS/`, restores bundle files, re-links config fragment, runs config/model checks, and restarts gateway if available.
  - **Input:** `install.sh`, `design.md`, `scripts/common.sh`
  - **Output:** `step_restore_full_clone()` and adjusted `main()` flow for full-clone mode
  - **Standards:** Idempotent, backup before mutation, temp files cleaned up, no sudo, no secret logging
  - **Estimate:** 2 h

- [ ] **T5: Update version metadata for v1.9.0**
  - **Description:** Bump release version references from v1.8.0/current to v1.9.0 where appropriate: `.version`, `install.sh CURRENT_VERSION`, `update.sh CURRENT_VERSION`, README version badge/What's New if present.
  - **Input:** `.version`, `install.sh`, `update.sh`, `README.md`
  - **Output:** Version metadata consistently says v1.9.0
  - **Standards:** SemVer minor release for new feature
  - **Estimate:** 30 min

- [ ] **T6: Update release documentation**
  - **Description:** Add `CHANGELOG.md` v1.9.0 entry and overwrite `RELEASE_NOTES.md` with v1.9.0 GitHub release notes. Include exporter flags, installer `--full-clone`, security defaults, `--include-identity`, `--exclude-memories`, and migration workflow.
  - **Input:** `CHANGELOG.md`, `RELEASE_NOTES.md`, `spec.md`, `design.md`
  - **Output:** v1.9.0 changelog and release notes
  - **Standards:** Keep a Changelog format; release notes are per-release
  - **Estimate:** 45 min

- [ ] **T7: Add installer/exporter smoke tests or CI checks**
  - **Description:** Extend CI or verification scripts to syntax-check the new exporter and validate key behavior. At minimum: `bash -n scripts/export-full-clone.sh install.sh update.sh verify.sh uninstall.sh`; dry-run/export test in a temp HOME verifying default excludes and `--include-identity`/`--exclude-memories` composition if feasible without secrets.
  - **Input:** `.github/workflows/ci.yml`, `verify.sh`, `scripts/export-full-clone.sh`
  - **Output:** CI/verification coverage for the new script and installer flag
  - **Standards:** No real secrets in tests, temp HOME, deterministic assertions
  - **Estimate:** 1 h

- [ ] **T8: Verify implementation against acceptance criteria**
  - **Description:** Run syntax checks, shellcheck/shfmt if available, content-boundary validation, exporter dry-runs in a temp fixture, and installer `--full-clone` restore into an isolated temp HOME where possible. Document results in `apply.md`/`verify.md`.
  - **Input:** Implemented files, AC1–AC17
  - **Output:** Verification evidence and any fixes needed
  - **Standards:** Evidence over vibes; no external destructive actions
  - **Estimate:** 1.5 h

- [ ] **T9: Prepare PR for v1.9.0**
  - **Description:** Review diff, ensure no secrets or local bundles are tracked, push feature branch, and prepare PR body summarizing the feature and verification. Do not merge without Camilo review.
  - **Input:** Final diff, verification output
  - **Output:** PR-ready branch and PR description
  - **Standards:** Feature branch, PR review required, no direct main push
  - **Estimate:** 30 min

## Dependencies

```text
T1
├─ T2 ─┬─ T7 ─ T8 ─ T9
│      └─ T6 ─┘
├─ T3 ─ T4 ─ T7
└─ T5 ─ T6
```

- T1 is already complete once the branch is created.
- T2 and T3 can be implemented independently.
- T4 depends on T3.
- T5 and T6 can run after the feature scope is stable.
- T7/T8 depend on implementation.
- T9 depends on verification.

## Estimated Effort

| Task | Estimado |
|------|----------|
| T1 | 5 min |
| T2 | 1.5 h |
| T3 | 45 min |
| T4 | 2 h |
| T5 | 30 min |
| T6 | 45 min |
| T7 | 1 h |
| T8 | 1.5 h |
| T9 | 30 min |
| **Total** | **8.5 h** |
