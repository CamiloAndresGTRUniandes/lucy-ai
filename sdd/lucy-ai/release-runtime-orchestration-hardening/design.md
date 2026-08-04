# Design: Lucy-ai v1.9.1 Runtime + Orchestration Hardening

## Status: Draft

## Architecture Decisions

| Decision | Choice | Rationale | Alternative Rejected |
|----------|--------|-----------|---------------------|
| Release type | Ship as `v1.9.1` patch release | The current `main` branch already reflects published `v1.9.0`, so this work should be a small corrective release on top of that baseline, not a new minor line | Re-open `v1.8.x` or cut `v1.10.0` for a narrow template/runtime tune-up |
| Change scope | Keep the patch narrow and repo-owned | The runtime investigation produced both generic improvements and host-only mitigations. Only the generic, reusable parts belong in Lucy-ai | Bundle local `plugins.allow`, `tools.allow`, watchdog services, or transient runtime-agent patches into the repo |
| Bootstrap tuning | Lower only `agents.defaults.bootstrapMaxChars` and `bootstrapTotalMaxChars` in `config/agent-fragment.json5` from `24000/80000` to `16000/48000` | This is the main generic performance improvement that directly affects fresh installs without changing per-phase model policy or installer architecture | Aggressively prune skills, alter multiple agent profiles, or change the main model again inside this patch |
| Orchestrator notification | Preserve and ship the new pre-spawn SDD notification format in both shipped orchestrator doc copies | The rule is already implemented in the worktree and is a legitimate product behavior change for Lucy-ai users | Leave the older `Phase: ... → agentId ...` wording and keep runtime behavior/docs inconsistent |
| Version reconciliation | Update all repo version surfaces from `1.9.0` to `1.9.1` in one pass | Patch releases in Lucy-ai rely on aligned installer, README, changelog, release notes, and verification checks | Bump only `install.sh` or only `CHANGELOG.md`, leaving verify/docs inconsistent |
| Verification strategy | Reuse existing `verify.sh` checks and update only the version-sensitive assertions that are affected by `1.9.1` | This keeps the patch low-risk and aligned with the repo’s existing release discipline | Introduce new complex verification logic unrelated to this patch |

## Data Model

- **Entities:** No application data model changes.
- **Schema:** No persisted schema or state migrations are required in Lucy-ai itself.
- **Migrations:** N/A. This patch changes shipped templates and release metadata only.

## API Design _(optional)_

- **Endpoints:** None.
- **Auth:** No auth flow changes.
- **Versioning:** Semantic versioning patch release from `1.9.0` to `1.9.1`.

## Security

- **Auth/Authz:** No new authentication or authorization behavior is introduced.
- **Data handling:** No user data migration. The patch touches only repo templates/docs/scripts.
- **Input validation:** Existing installer validation remains the guardrail; no new external input surface is added by this patch.
- **Audit:** Changelog and release notes document the scope; verify checks continue to enforce internal consistency.

## Error Handling

- **Failure modes:**
  - Version strings may be bumped inconsistently across `README.md`, `install.sh`, `update.sh`, `verify.sh`, `CHANGELOG.md`, and `RELEASE_NOTES.md`.
  - The pre-spawn notification wording may drift between `sdd/orchestrator-flow.md` and `workspace/sdd/orchestrator-flow.md`.
  - The bootstrap default reduction may be applied in the repo but not reflected in verification expectations or release docs.

- **Recovery:**
  - Keep the change list small and centered on the known affected files.
  - Validate consistency with targeted grep/diff checks and `verify.sh`.
  - If a release-doc mismatch appears, fix the source file rather than weakening the checks.

- **User feedback:** If validation fails, the release work stops in Verify until the inconsistent file is corrected.

## Observability

- **Logging:** No runtime observability change is shipped in Lucy-ai itself.
- **Metrics:** No new metrics.
- **Alerts:** Existing runtime issues like hook-relay desync and model-catalog regeneration remain operational concerns outside this patch release.

## Migration Plan

- **Breaking changes:** None intended. This is a patch release with lighter bootstrap defaults and documentation/release consistency updates.
- **Rollback:** Revert the `v1.9.1` patch commit(s) or reinstall `v1.9.0` tag if needed.
- **Deployment steps:**
  1. Update repo-owned runtime/orchestration files.
  2. Bump versioned surfaces to `1.9.1`.
  3. Run repo verification.
  4. Open PR from a feature branch; do not push directly to `main`.
  5. After merge, tag `v1.9.1`.

## File-Level Plan

| File | Planned change |
|------|----------------|
| [config/agent-fragment.json5](../../../config/agent-fragment.json5) | Reduce `bootstrapMaxChars` to `16000` and `bootstrapTotalMaxChars` to `48000` |
| [sdd/orchestrator-flow.md](../../orchestrator-flow.md) | Keep the standardized pre-spawn phase/model/timeout/fallback notification wording |
| [workspace/sdd/orchestrator-flow.md](../../../workspace/sdd/orchestrator-flow.md) | Mirror the same notification wording |
| [CHANGELOG.md](../../../CHANGELOG.md) | Add `1.9.1` entry describing the shipped patch scope |
| [RELEASE_NOTES.md](../../../RELEASE_NOTES.md) | Rewrite for `v1.9.1` patch notes |
| [README.md](../../../README.md) | Update version badge/examples and, if needed, mention the runtime/orchestration patch in the current release framing |
| [install.sh](../../../install.sh) | Bump `CURRENT_VERSION` to `1.9.1` |
| [update.sh](../../../update.sh) | Bump `CURRENT_VERSION` to `1.9.1` |
| [verify.sh](../../../verify.sh) | Update version-sensitive checks from `1.9.0` to `1.9.1` |

## Decisions approved by Camilo

| Decision | Value | Rationale |
|----------|-------|-----------|
| Release target | `v1.9.1` | `v1.9.0` is already published, so this work must be a patch release |
| Pre-design sync | Pull latest `main` first | Design/apply work should use the real repo baseline, not a stale local snapshot |
