# Tasks: release-runtime-orchestration-hardening

## Status: Draft

## Task List

- [ ] **T1: Apply patch-scoped runtime and orchestrator template changes**
  - **Description:** Update the repo-owned runtime/orchestration content that is explicitly approved for the `v1.9.1` patch: lower the bootstrap defaults in `config/agent-fragment.json5` from `24000/80000` to `16000/48000`, and preserve the approved pre-spawn notification wording in both orchestrator doc copies. Keep this task strictly limited to generic shipped behavior and exclude host-local mitigations such as local allowlists, watchdog services, or direct edits under `~/.openclaw/agents/`.
  - **Input:** `spec.md`, `design.md`, `config/agent-fragment.json5`, `sdd/orchestrator-flow.md`, `workspace/sdd/orchestrator-flow.md`
  - **Output:** Updated shipped runtime/orchestration templates aligned to the approved `v1.9.1` scope
  - **Standards:** Follow the approved patch-only design, keep mirrored orchestrator docs synchronized, preserve Bash/template portability, and do not introduce any machine-specific policy
  - **Estimate:** 45 minutes

- [ ] **T2: Reconcile all Lucy-ai versioned release surfaces to 1.9.1**
  - **Description:** Perform a single-pass version bump across the repo-owned release surfaces that still reflect `1.9.0`, updating them to `1.9.1` while keeping the release framing narrow and truthful. This includes installer/update/version checks plus release-facing documentation so users receive a coherent patch release without mismatched metadata or stale verification expectations.
  - **Input:** `spec.md`, `design.md`, `README.md`, `install.sh`, `update.sh`, `verify.sh`, `CHANGELOG.md`, `RELEASE_NOTES.md`
  - **Output:** Repo version surfaces consistently updated from `1.9.0` to `1.9.1`
  - **Standards:** Maintain semantic-versioning patch scope, keep installer/update flows internally consistent, and avoid claims that host-local mitigations or upstream runtime bugs are part of this release
  - **Estimate:** 60 minutes

- [ ] **T3: Validate release coherence and scope boundaries**
  - **Description:** Verify that the patch remains internally consistent after the content updates by checking the new bootstrap defaults, confirming the pre-spawn wording matches across both orchestrator doc copies, and ensuring all `1.9.1` references are aligned with verification expectations. Use targeted checks and the existing verification flow, and fail the release work if any file still implies non-shipped host-local hardening belongs in this patch.
  - **Input:** Updated runtime/orchestration files from T1, updated version/release files from T2, existing `verify.sh`
  - **Output:** Validation evidence that the `v1.9.1` patch is coherent, narrowly scoped, and ready for Apply/Verify follow-through
  - **Standards:** Reuse existing verification discipline, keep checks focused on the approved patch scope, and treat doc/template drift as a defect to fix rather than an excuse to weaken checks
  - **Estimate:** 30 minutes

## Dependencies

```text
T1 -> T2 -> T3
```

- T1 establishes the approved runtime and orchestrator content that the release must ship.
- T2 depends on T1 so versioned docs and release metadata describe the final approved patch behavior.
- T3 depends on T1 and T2 because validation must run against the completed template changes and `1.9.1` release surfaces.

## Estimated Effort

| Task | Estimado |
|------|----------|
| T1 | 45 minutes |
| T2 | 60 minutes |
| T3 | 30 minutes |
| **Total** | **135 minutes** |
