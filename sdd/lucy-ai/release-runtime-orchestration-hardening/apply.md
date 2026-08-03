# Apply: release-runtime-orchestration-hardening

## Files Modified

| File | Action | Description |
|------|--------|-------------|
| `config/agent-fragment.json5` | modified | Lowered shipped bootstrap defaults from `24000/80000` to `16000/48000` |
| `sdd/orchestrator-flow.md` | modified | Preserved the approved pre-spawn notification wording in the shipped root orchestrator doc copy |
| `workspace/sdd/orchestrator-flow.md` | modified | Kept the mirrored shipped orchestrator doc copy aligned with the approved pre-spawn notification wording |
| `README.md` | modified | Updated visible release version to `1.9.1` and framed the patch scope accurately |
| `install.sh` | modified | Bumped `CURRENT_VERSION` to `1.9.1` |
| `update.sh` | modified | Bumped `CURRENT_VERSION` to `1.9.1` |
| `verify.sh` | modified | Updated version-sensitive checks from `1.9.0` to `1.9.1` |
| `CHANGELOG.md` | modified | Added the `1.9.1` patch release entry with scope boundary notes |
| `RELEASE_NOTES.md` | modified | Rewrote release notes for the `v1.9.1` runtime/orchestration hardening patch |

## What Was Implemented

- **Feature:** Shipped the approved `v1.9.1` patch scope for Lucy-ai by lowering the generic bootstrap defaults, keeping release/version surfaces aligned, and documenting the narrow runtime/orchestration hardening release honestly.
- **Key decisions:** Left host-local mitigations out of the repo, preserved the existing synchronized pre-spawn notification wording in both orchestrator doc copies without unnecessary edits, and updated only the allowed release-facing/version-sensitive files.
- **Deviation from design:** None.

## Tests

| Test file | Type | What it covers |
|-----------|------|----------------|
| `config/agent-fragment.json5` | Static verification | Confirmed bootstrap defaults are now `16000` / `48000` |
| `sdd/orchestrator-flow.md` + `workspace/sdd/orchestrator-flow.md` | Diff verification | Confirmed both shipped orchestrator doc copies remain in sync with the approved pre-spawn wording |
| `verify.sh` | Script verification | Updated version-sensitive assertions to check for `1.9.1` across README/changelog/install/update |

## Verification Instructions

1. Run `rg -n "16000|48000|1\\.9\\.1" config/agent-fragment.json5 README.md CHANGELOG.md RELEASE_NOTES.md install.sh update.sh verify.sh`.
2. Run `diff -u sdd/orchestrator-flow.md workspace/sdd/orchestrator-flow.md` and confirm no drift.
3. Run `bash verify.sh` from the repo root to validate the version/documentation checks remain coherent.
