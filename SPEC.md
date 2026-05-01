# Spec: lucy-agent v1.3.0 — SDD Orchestrator Integration

## Context
- **Problem:** The SDD Orchestrator infrastructure (templates, flow docs, validation rules) was built and tested in the live workspace but is not part of the lucy-ai installable project.
- **Business value:** Every Lucy installation ships with the complete SDD Orchestrator out of the box.
- **Constraints:** Must not break existing installations; install.sh must remain idempotent.

## Requirements

### Functional
| ID | Requirement |
|----|-------------|
| F1 | install.sh copies sdd/ directory to user workspace |
| F2 | install.sh respects existing sdd/ files with sha256 conflict detection |
| F3 | workspace/AGENTS.md includes SDD Model Configuration table |
| F4 | workspace/AGENTS.md includes SDD Orchestrator section |
| F5 | workspace/AGENTS.md references sdd/ docs |
| F6 | verify.sh checks for sdd/ directory and templates |
| F7 | verify.sh checks AGENTS.md contains orchestrator references |
| F8 | SPEC.md updated to v1.3.0 |
| F9 | CHANGELOG.md documents v1.3.0 |
| F10 | CURRENT_VERSION bumped to 1.3.0 |

### Non-Functional
| ID | Requirement |
|----|-------------|
| NF1 | --skip-workspace flag still works |
| NF2 | Existing installations not broken |
| NF3 | Re-running install.sh is idempotent |
| NF4 | verify.sh passes on clean install |
| NF5 | sdd/ copy adds negligible install time |
| NF6 | Shell scripts follow set -euo pipefail |

## User Scenarios

### S1: Fresh install gets complete SDD Orchestrator
**Given** new user installs Lucy, **When** install.sh completes, **Then** workspace has sdd/ directory with all docs and templates, AGENTS.md has orchestrator sections.

### S2: Existing user updates
**Given** v1.2.0 installation, **When** re-running install.sh, **Then** sdd/ is added, AGENTS.md updated with conflict prompt.

### S3: --skip-workspace skips everything
**Given** user wants no workspace seeding, **When** running install.sh --skip-workspace, **Then** no sdd/ or workspace files are created.

## Out of Scope
- Modifying skills/sdd/SKILL.md
- State tracking to DB (v2)
- Parallel phase execution (v2)

## Acceptance Criteria
- [ ] AC1: Fresh install creates workspace/sdd/ with 9 files
- [ ] AC2: AGENTS.md has SDD Model Configuration table
- [ ] AC3: AGENTS.md has SDD Orchestrator section
- [ ] AC4: install.sh copies sdd/ with sha256 conflict detection
- [ ] AC5: verify.sh includes sdd/ checks
- [ ] AC6: --skip-workspace skips sdd/
- [ ] AC7: --dry-run shows sdd/ file operations
- [ ] AC8: --force overwrites without prompts
- [ ] AC9: SPEC.md at lucy-ai root
- [ ] AC10: CHANGELOG.md has v1.3.0 section
- [ ] AC11: CURRENT_VERSION is 1.3.0
- [ ] AC12: bash -n passes for both install.sh and verify.sh
