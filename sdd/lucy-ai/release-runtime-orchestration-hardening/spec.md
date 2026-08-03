# Spec: Lucy-ai v1.9.1 Runtime + Orchestration Hardening

## Status: Draft

## Context

- **Problem:** Lucy-ai has a set of safe, project-owned runtime and orchestration improvements that currently exist only in the live workspace or in partially synced docs. The repo already contains the SDD pre-spawn notification update in the orchestrator docs, but the shipped template config still uses the older bootstrap defaults, and the release metadata does not yet package these improvements as a new Lucy-ai version. At the same time, some operational fixes we applied are machine-local and should not be released blindly as product behavior.

- **Business value:** Packaging the safe changes into Lucy-ai reduces post-install tuning, makes fresh installs feel faster by default, and keeps the shipped SDD workflow aligned with the operational behavior Lucy now expects. It also creates a clean release boundary between reusable product improvements and host-specific mitigations.

- **Constraints:**
  - Lucy-ai is a Bash-based installer/template repo; changes must remain portable, idempotent, and auditable.
  - Project-agnostic boundaries must be preserved. No personal machine config, no user-specific plugin policy, and no host-only watchdog services should be baked into the repo unless generalized.
  - Existing install/update flows must keep working for current users.
  - The release should improve the shipped defaults without claiming to solve upstream OpenClaw runtime bugs that still need separate root-cause fixes.

- **Assumptions:**
  - The next Lucy-ai release for these changes should be `v1.9.1` as a patch on top of the already-published `v1.9.0`.
  - The local repo version markers currently visible in `README.md`, `install.sh`, and `verify.sh` are stale relative to the published release line and must be reconciled during this release work.
  - The reduced bootstrap defaults validated locally (`16000` / `48000`) are safe to ship as the new generic defaults.
  - The new pre-spawn SDD notification format is already the intended source-of-truth behavior and should remain synchronized in all shipped orchestrator docs.
  - Machine-local mitigations such as `plugins.allow`, `tools.allow`, watchdog timers, and direct edits under `~/.openclaw/agents/` are operational-only unless explicitly productized later.

## Requirements

### Functional

| ID | Category | Requirement |
|----|----------|-------------|
| F1 | Release Scope | Lucy-ai must package the safe, repo-owned runtime/orchestration improvements into a new release without bundling host-specific mitigations. |
| F2 | Bootstrap Defaults | `config/agent-fragment.json5` must ship the reduced bootstrap defaults (`bootstrapMaxChars: 16000`, `bootstrapTotalMaxChars: 48000`) so fresh installs inherit the lighter direct-chat profile. |
| F3 | SDD Orchestrator Docs | The shipped SDD orchestrator docs must require the pre-spawn user notification in this format before every subagent spawn: phase, primary model, timeout, and fallback model. |
| F4 | Doc Sync | The mirrored orchestrator docs under both `sdd/` and `workspace/sdd/` in the Lucy-ai repo must stay consistent for the shipped notification rule. |
| F5 | Release Metadata | Lucy-ai release artifacts must be updated for `v1.9.1`, including changelog and any version references required by the installer/docs. |
| F6 | Installer Surface | If installer or verification logic depends on the older defaults or release version, those repo-owned references must be updated so the shipped behavior stays internally consistent. |
| F7 | Scope Boundary | The release must explicitly exclude host-local operational hardening such as personal `plugins.allow`, local `tools.allow`, watchdog services, and ephemeral agent-state patches. |

### Non-Functional

| ID | Category | Requirement |
|----|----------|-------------|
| NF1 | Portability | All shipped changes must remain Linux/macOS-friendly Bash/template changes with no new mandatory external dependencies. |
| NF2 | Safety | The release must not overwrite or imply user-specific runtime policy that belongs only to a single machine or personal install. |
| NF3 | Consistency | All repo-shipped copies of the same orchestrator/runtime template content must remain synchronized after the release. |
| NF4 | Backward Compatibility | Existing install and update flows must continue to work without requiring users to manually repair their workspace after updating to `v1.9.1`. |
| NF5 | Honest Scope | Release docs must not claim that upstream OpenClaw runtime bugs such as hook-relay desync or regenerated model-catalog schema issues are fully fixed if Lucy-ai is only shipping mitigations or unrelated template improvements. |

## User Scenarios

### Scenario 1: Fresh install gets the lighter runtime defaults

**Given** a user installs Lucy-ai on a clean machine  
**When** the installer seeds `config/agent-fragment.json5` into the OpenClaw config flow  
**Then** the installed Lucy/OpenClaw setup starts with the reduced bootstrap defaults and does not require a manual post-install tuning pass just to get the lighter direct-chat profile.

### Scenario 2: SDD orchestration tells the user what is about to run

**Given** a user starts an SDD cycle in a Lucy-ai-seeded workspace  
**When** Lucy is about to spawn a subagent for an SDD phase  
**Then** the shipped orchestrator instructions tell Lucy to emit the pre-spawn message showing the phase, primary model, timeout, and fallback model in the standardized format.

### Scenario 3: Release does not leak machine-specific operational hacks

**Given** the local machine needed extra runtime hardening during investigation  
**When** Lucy-ai `v1.9.1` is prepared as a reusable release  
**Then** the repo includes only safe generic improvements, while host-only mitigations remain outside the shipped product surface.

### Scenario 4: Update path stays coherent

**Given** an existing Lucy-ai user updates from `v1.9.0`  
**When** they receive the `v1.9.1` repo state  
**Then** version references, verification expectations, and shipped defaults are aligned, without broken checks caused by stale version strings or mismatched template content.

## Out of Scope

- ❌ Fixing the upstream OpenClaw `pre_tool_use` relay lifecycle bug at the source.
- ❌ Shipping the local relay watchdog service/timer as a generic Lucy-ai feature in this release.
- ❌ Shipping personal `plugins.allow` or `tools.allow` policy as repo defaults.
- ❌ Shipping direct patches to regenerated runtime agent state such as `~/.openclaw/agents/main/agent/models.json`.
- ❌ Reworking the entire main-agent skill set or solving all event-loop contention inside OpenClaw itself.

## Acceptance Criteria

- [ ] **AC1:** Lucy-ai defines a `v1.9.1` release scope that includes only safe, project-owned runtime/orchestration improvements.
- [ ] **AC2:** [`config/agent-fragment.json5`](/home/lucygtr/.openclaw/workspace/lucy-ai/config/agent-fragment.json5) ships `bootstrapMaxChars: 16000` and `bootstrapTotalMaxChars: 48000`.
- [ ] **AC3:** [`sdd/orchestrator-flow.md`](/home/lucygtr/.openclaw/workspace/lucy-ai/sdd/orchestrator-flow.md) documents the pre-spawn message format with phase, primary, timeout, and fallback.
- [ ] **AC4:** [`workspace/sdd/orchestrator-flow.md`](/home/lucygtr/.openclaw/workspace/lucy-ai/workspace/sdd/orchestrator-flow.md) matches the same pre-spawn notification rule.
- [ ] **AC5:** Release/version references in Lucy-ai are updated consistently so the repo reflects the published `1.9.0` baseline and this patch release as `1.9.1`.
- [ ] **AC6:** Changelog entry for `1.9.1` explains the shipped runtime/orchestration improvements and clearly separates them from non-shipped host-local mitigations.
- [ ] **AC7:** No repo change in this release introduces personal machine policy such as local plugin allowlists, local tool allowlists, watchdog services, or direct runtime-agent-state patches.
- [ ] **AC8:** Installer/verification/docs that depend on the shipped defaults remain internally coherent after the release changes.
