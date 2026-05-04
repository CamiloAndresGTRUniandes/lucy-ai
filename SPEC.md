# Spec: v1.5.0 — Installer TUI + CI + Config Sync

## Status: Draft

## Context

- **Problem:** The lucy-agent installer ecosystem has four gaps preventing a professional-quality release. First, the lucy-ai repository's configuration files (AGENTS.md, agent-fragment.json5, SDD orchestrator-flow.md, TOOLS.md, skills/sdd/SKILL.md, SPEC.md) are stale — they still reference minimax/MiniMax-M2.7 and a single-provider model strategy, while the live workspace has been running a multi-provider strategy (deepseek, openai-codex, github-copilot) since v1.4.0. Every fresh install or update delivers an outdated configuration that users must manually correct. Second, while the SDD Model Configuration table is powerful, every user has different provider/model preferences and budget constraints — there is no guided way to customize the 8-phase model/provider/effort matrix during installation; users must manually edit AGENTS.md after install, a friction point that leads to stale defaults being used. Third, the installer has only a primitive text-based prompt for install mode selection — there is no guided, user-friendly interactive experience for choosing components, reviewing options, or monitoring progress. Fourth, there is no continuous integration pipeline to validate scripts on push/PR, meaning syntax errors, formatting drift, and stale configs can reach users undetected.

- **Business value:** This release delivers four compounding value layers. Config Sync ensures every new user gets the exact same multi-provider setup that the live workspace has been battle-tested on — no more manual post-install fixes, no more stale minimax references that silently degrade the experience. The SDD Phase TUI wizard lets every user customize their 8-phase model/provider/effort matrix during installation, with Camilo's proven defaults as the suggested starting point — users with budget constraints can swap expensive phases to cheaper models, users with Copilot subscriptions can assign Copilot phases, and everyone gets a working config without editing AGENTS.md manually. The install mode TUI transforms a bare-metal curl-to-bash flow into an approachable wizard that guides users through component selection, confirms choices before installation, and provides progress feedback. The CI pipeline catches syntax errors, formatting drift, config staleness, and runtime failures on every PR, protecting the codebase from regressions and making the project more maintainable for contributors.

- **Constraints:** The installer must remain executable via a single `curl ... | bash` command with no prior setup required. No sudo privileges can be required. No external binary downloads can be added solely for the TUI feature (dialog/whiptail are OS-level packages that may or may not be present — the installer must work without them). The CI pipeline must run on GitHub Actions free-tier (ubuntu-latest, 2000 min/month). All four features (config sync, SDD phase TUI, install mode TUI, CI) must ship in a single atomic PR to prevent partial-staleness where some files reference the new model strategy and others reference the old.

- **Assumptions:** The primary deployment target is Ubuntu/Debian Linux where `dialog` (~300KB) is pre-installed or easily available. macOS and minimal Docker containers may lack dialog/whiptail — the TUI degrades gracefully to text prompts in those environments. GitHub Actions ubuntu-latest runners do not have shellcheck pre-installed but can install it via the ludeeus/action-shellcheck marketplace action. The live workspace files in `/home/node/.openclaw/workspace/` are the canonical source of truth for configuration — the repo copies are stale and must be overwritten, not merged.

## Requirements

### Functional

| ID | Category | Requirement |
|----|----------|-------------|
| F1 | Config Sync | `workspace/AGENTS.md` in the repo is replaced with the full live workspace content (multi-provider table, provider config, excluded models, fallback strategy, updated Engram protocol, skills table) — all 10 diff items resolved |
| F2 | Config Sync | `config/agent-fragment.json5` has `model.primary` changed from `"minimax/MiniMax-M2.7"` to `"deepseek/deepseek-v4-flash"`, `fallbacks` updated to multi-provider list, `thinkingDefault` changed from `"medium"` to `"high"` |
| F3 | Config Sync | `workspace/sdd/orchestrator-flow.md` removes stale single-model references in 7 locations, fixes duplicate "8. Archive" section, adds Model Validation step, adds Explore template reference, adds notify-on-spawn policy, corrects Archive conditional rule to "conditional on PR merge" |
| F4 | Config Sync | `workspace/TOOLS.md` gains a new "SDD Model Configuration (OBLIGATORIO)" section with switch mechanism, escalation rule, and available models list from the live workspace |
| F5 | Config Sync | `workspace/sdd/validation-rules.md` is synced with live — adds Observability section requirement in Design phase, accepts both AC format variants, adds PR Review validation with conditional Archive rule |
| F6 | Config Sync | `skills/sdd/SKILL.md` version tag updated from `"1.1"` to `"1.2"` and Engram Memory Protocol section updated (sub-agents only load context; Lucy handles all save/start/end operations) |
| F7 | Config Sync | `SPEC.md` rewritten from v1.3.0 to v1.5.0 documenting the four features in this release |
| F8 | Config Sync | `CHANGELOG.md` gains a `[1.5.0] - 2026-05-0X` section at the top documenting Added (TUI, CI, model config validation, --no-tui flag), Changed (config sync, DRY helpers, multi-provider), and Fixed (SPEC.md staleness, agent-fragment minimax ref) |
| F9 | Config Sync | `install.sh` CURRENT_VERSION changed from `"1.4.0"` to `"1.5.0"` (line 53) and `update.sh` CURRENT_VERSION changed from `"1.4.0"` to `"1.5.0"` (line 27) |
| F10 | Config Sync | `README.md` version badge updated from `1.4.0` to `1.5.0` and install examples use `--tag v1.5.0` |
| F11 | SDD Phase TUI | After install mode selection (and before component selection), when TUI is active, a `dialog --menu` presents the 8 SDD phases (Explore, Propose, Spec, Design, Tasks, Apply, Verify, Archive) with 3 options per phase: (1) Use suggested defaults — applies Camilo's proven multi-provider config, (2) Customize this phase — opens sub-dialogs to pick provider, model, and effort per phase, (3) Skip configuration — leaves AGENTS.md template placeholders for manual editing later |
| F12 | SDD Phase TUI | When user selects "Customize this phase", a `dialog --radiolist` presents available providers (deepseek, openai-codex, github-copilot) with the suggested default pre-selected, followed by a model picker and effort level picker (`dialog --menu` for each) |
| F13 | SDD Phase TUI | The "Use suggested defaults" option pre-populates all 8 phases with Camilo's current multi-provider configuration from the live workspace AGENTS.md (Explore→Pro, Propose→Pro, Spec→Copilot, Design→Pro, Tasks→Flash, Apply→Codex, Verify→Codex, Archive→Flash) |
| F14 | SDD Phase TUI | After all 8 phases are configured (or defaults accepted), a `dialog --msgbox` displays the complete 8-phase summary table showing Phase | Provider | Model | Effort for user review before proceeding |
| F15 | SDD Phase TUI | The selected SDD phase configuration is written to `workspace/AGENTS.md` replacing the SDD Model Configuration table section — the rest of AGENTS.md (standards, orchestrator sections, Engram protocol) remains untouched |
| F16 | SDD Phase TUI | When `--no-tui` flag is used, the installer falls back to Camilo's default SDD phase config without prompting — the default config is written to AGENTS.md as if "Use suggested defaults" was selected for all phases |
| F17 | SDD Phase TUI | The `--accept-defaults` flag accepts all SDD phase defaults AND all component defaults non-interactively (CI-friendly shortcut) — equivalent to `--no-tui` + accepting every default |
| F18 | Install TUI | When running interactively (TTY detected) and `dialog` is available, after SDD phase configuration, the installer displays a `dialog --menu` with 3 install-mode options: Clone (default), Template, or Specific tag — replacing the current text-based `prompt_install_mode()` |
| F19 | Install TUI | When `dialog` is selected for the install mode and the user picks "Specific tag", a `dialog --inputbox` prompts for the tag name before proceeding |
| F20 | Install TUI | After install mode selection, when TUI is active, a `dialog --checklist` displays optional components (Engram installation, ClawHub skills sync, Workspace file seeding, Force overwrite mode) with default selections pre-checked |
| F21 | Install TUI | After component selection, when TUI is active, a `dialog --yesno` confirmation dialog shows a summary of all selected options (SDD phase config + install mode + components) before installation begins |
| F22 | Install TUI | A `--no-tui` flag forces text-based prompts even when `dialog` is available and TTY is detected — the installer falls back to the exact same text prompts as the current v1.4.0 behavior |
| F23 | Install TUI | When TTY is detected but `dialog` is not available, the installer falls back to text prompts with no error — `dialog` is never a hard requirement |
| F24 | Install TUI | The TUI widgets use the `dialog` backend when available; `whiptail` is never attempted as a substitute — if `dialog` is absent, the installer falls back to text prompts (only `dialog`'s richer widget set justifies TUI mode) |
| F25 | CI | A `.github/workflows/ci.yml` workflow runs on `push` and `pull_request` to `main` and `develop` branches with 5 jobs: shellcheck-lint, bash-syntax, format-check, verify-check, and test-install |
| F26 | CI | The shellcheck-lint job uses `ludeeus/action-shellcheck@master` to lint `install.sh`, `update.sh`, `verify.sh`, `uninstall.sh`, and `scripts/common.sh` with severity `warning` |
| F27 | CI | The bash-syntax job runs `bash -n` on all 5 shell scripts — exits with code 1 if any file has syntax errors |
| F28 | CI | The format-check job installs `shfmt` via `apt` and runs `shfmt -d -i 2 -ci .` — exits with code 1 if any file has formatting deviations |
| F29 | CI | The verify-check job creates a mock `openclaw` binary, adds it to `PATH`, and runs `bash verify.sh` — validates that all post-install checks pass on clean repo state |
| F30 | CI | The test-install job runs `install.sh --dry-run --accept-defaults --skip-engram`, `install.sh --version`, `install.sh --help`, and `update.sh --version` — validates CLI flags and dry-run mode work without errors |
| F31 | CI | All CI jobs run on `ubuntu-latest` and are independent (no job depends on another) — a single job failure does not block other jobs from reporting |

### Non-Functional

| ID | Category | Requirement |
|----|----------|-------------|
| NF1 | Idempotency | Running the installer twice with identical flags produces identical results — the second run detects existing files via SHA256 comparison, shows "already up-to-date" messages, and exits successfully without reinstalling or replacing unchanged files |
| NF2 | Compatibility | All existing flags (`--clone`, `--template`, `--tag`, `--skip-engram`, `--dry-run`, `--force`, `--help`, `--version`) work identically in v1.5.0 as they did in v1.4.0 — no flag behavior regressions |
| NF3 | Auditability | Every TUI selection (SDD phase picks, install mode, components chosen, confirmed summary) is logged via `log_info` to stderr before execution begins — the text log can be reviewed even when TUI is used |
| NF4 | Config Correctness | When `--accept-defaults` is used, the generated `workspace/AGENTS.md` SDD Model Configuration table is syntactically valid markdown with 8 data rows, 4 columns (Phase, Modelo Primario, Fallback, Thinking), and no empty cells — the file passes a structural grep validation |
| NF5 | Performance | The TUI detection (`command -v dialog`) and TTY check (`[ -t 0 ]`) add less than 50ms to startup time — negligible overhead even when TUI is bypassed |
| NF6 | Security | The CI pipeline never exposes secrets, never runs untrusted scripts with elevated permissions, and the `--no-tui`/`--accept-defaults` flags ensure automation environments never get blocked by an interactive dialog prompt |
| NF7 | Maintainability | The Engram helper functions `detect_platform()` and `resolve_engram_version()` are extracted from `install.sh` and `update.sh` into `scripts/common.sh` — eliminating the ~60-line duplication between the two scripts |
| NF8 | Portability | The installer works correctly on Ubuntu 22.04+, Debian 11+, macOS 13+, and minimal Docker containers — TUI is only available on systems with `dialog` installed, text prompts work everywhere |

## User Scenarios

### Scenario 1: Fresh install with full TUI on Ubuntu

**Given** A user on Ubuntu 24.04 (where `dialog` is pre-installed) runs `curl -fsSL https://lucy.ai/install.sh | bash`
**When** The installer detects a TTY and `dialog` is available
**Then** A welcome messagebox appears, followed by: (1) SDD Phase Configuration — a menu to accept suggested defaults or customize per phase, (2) Summary table of 8-phase config, (3) Install mode menu (Clone/Template/Tag), (4) Component checklist (Engram, ClawHub, Workspace, Force), (5) Final confirmation yes/no dialog — the install completes with the user's customized v1.5.0 multi-provider config

### Scenario 2: Fresh install without TTY (piped stdin)

**Given** A user runs `curl -fsSL https://lucy.ai/install.sh | bash` in a non-interactive shell (no TTY)
**When** The installer detects `[ -t 0 ]` is false
**Then** No TUI is shown, the installer falls back to current text prompts, and `CLONE_MODE` defaults to `template` — the install proceeds with the same behavior as v1.4.0

### Scenario 3: Existing user updates to v1.5.0

**Given** A user with v1.4.0 installed runs `cd ~/.openclaw/lucy-agent && ./update.sh`
**When** The updater detects version `1.4.0` in the `.version` file
**Then** The updater pulls the latest repo, applies all config sync changes (AGENTS.md, agent-fragment.json5, orchestrator-flow.md, TOOLS.md, etc.), overwrites stale configs with SHA256-confirmed replacements, updates `.version` to `1.5.0`, and reports success with a summary of changed files

### Scenario 4: Automation script using --accept-defaults flag

**Given** An administrator runs `curl -fsSL https://lucy.ai/install.sh | bash -s -- --clone --accept-defaults` in a provisioning script
**When** The installer detects `--accept-defaults` in parsed flags
**Then** All SDD phase defaults are applied automatically (Camilo's multi-provider config), all component defaults accepted, install mode is set to `clone` — the installer completes non-interactively without any TUI or text prompts, producing a fully-configured installation

### Scenario 4b: Automation script using --no-tui flag (deprecated prefer --accept-defaults)

**Given** An administrator runs `curl -fsSL https://lucy.ai/install.sh | bash -s -- --clone --no-tui` in a provisioning script
**When** The installer detects `--no-tui` in parsed flags
**Then** `TUI_MODE` is set to `false` even though TTY and `dialog` are available — the installer skips all dialog calls, applies Camilo's default SDD phase config, and uses text prompts for any remaining decisions

### Scenario 5: CI pipeline validates a PR

**Given** A contributor opens a PR against `main` changing `install.sh`
**When** GitHub Actions triggers the CI workflow on PR sync
**Then** All 5 jobs run: shellcheck-lint (0 warnings/errors on all scripts), bash-syntax (bash -n passes on all 5 scripts), format-check (shfmt reports no formatting changes needed), verify-check (verify.sh exits 0 with mock openclaw), test-install (all 4 dry-run/version/help tests pass) — the PR shows green checks for all jobs

### Scenario 6: Re-install with idempotent behavior

**Given** A user who already has v1.5.0 installed runs `curl -fsSL https://lucy.ai/install.sh | bash -s -- --accept-defaults` again
**When** The installer detects existing `.git` directory and compares SHA256 checksums of every workspace and skill file
**Then** All files match the repo versions — the installer shows "Already up-to-date" for each step, skips actual file operations, writes no new `.version` file, and exits successfully without network activity or file modifications

### Scenario 7: User customizes SDD phase models in TUI

**Given** A user on Ubuntu with dialog installed wants to use their own model preferences (e.g., they have a Copilot Pro subscription and want to use it for more phases)
**When** The installer shows the SDD Phase Configuration menu and the user selects "Customize phases"
**Then** For each of the 8 phases, the user picks a provider from a radiolist (with Camilo's default pre-selected), a model from a menu filtered to that provider, and an effort level — after configuring all 8, a summary table is displayed showing Phase | Provider | Model | Effort — the user confirms, and the customized table is written to AGENTS.md

## Out of Scope

- ❌ **gum/whiptail TUI backends:** Only `dialog` is supported as a TUI backend. `whiptail` is never attempted. If `dialog` is absent, the installer falls back to text prompts — no attempt is made to install `dialog` or any other TUI package.
- ❌ **Persistent user preferences or config profiles:** The TUI selections are ephemeral per run. No per-user config file or `~/.lucy-agent/config.json` is created to remember previous selections.
- ❌ **Gauge/progress bar in TUI:** The `dialog --gauge` progress bar is deferred to a future release. The v1.5.0 TUI uses msgbox, menu, radiolist, checklist, inputbox, and yesno — not gauge.
- ❌ **Provider/model validation against live APIs:** The TUI accepts provider/model strings as entered by the user. No validation against provider availability or API key presence is performed — that's a runtime concern for the OpenClaw agent, not the installer.
- ❌ **detect_platform() extraction to common.sh:** The Engram helper DRY cleanup (moving duplicated functions to scripts/common.sh) is deferred to a follow-up or handled as part of the apply phase but not validated in this spec. If done, it's a bonus cleanup, not a spec requirement.
- ❌ **Cross-platform CI runners:** CI uses `ubuntu-latest` only. No macOS or Windows runners are added.
- ❌ **Automated PR merging or release publishing:** The CI pipeline validates code quality only. Auto-merge, semantic-release, or CHANGELOG automation are out of scope.
- ❌ **Changes to verify.sh model config validation beyond grep checks:** No semantic validation of JSON structure or referenced provider availability is added — only grep-based checks for model names, thinking level, and elevated default.

## Acceptance Criteria

- [ ] **AC1:** Running `grep 'CURRENT_VERSION' install.sh | head -1` outputs `CURRENT_VERSION="1.5.0"`
- [ ] **AC2:** Running `grep 'CURRENT_VERSION' update.sh | head -1` outputs `CURRENT_VERSION="1.5.0"`
- [ ] **AC3:** `config/agent-fragment.json5` does NOT contain the string `minimax` anywhere in its content
- [ ] **AC4:** `config/agent-fragment.json5` has `thinkingDefault` set to `"high"`
- [ ] **AC5:** `workspace/AGENTS.md` contains the string `deepseek/deepseek-v4-pro` AND `deepseek/deepseek-v4-flash` in the SDD Model Configuration table
- [ ] **AC6:** `workspace/AGENTS.md` contains an explicit `❌ minimax/*` exclusion line in the excluded-models section
- [ ] **AC7:** `workspace/sdd/orchestrator-flow.md` contains exactly ONE "8. Archive" section (searching returns 1 occurrence of `## 8.`, not 2)
- [ ] **AC8:** `workspace/sdd/orchestrator-flow.md` does NOT contain any line matching `model: deepseek/deepseek-v4-` (all stale single-model references removed)
- [ ] **AC9:** `workspace/TOOLS.md` contains a line starting with `### SDD Model Configuration` or `### Model Configuration`
- [ ] **AC10:** `skills/sdd/SKILL.md` contains `version: "1.2"` (updated from "1.1")
- [ ] **AC11:** `CHANGELOG.md` has a `## [1.5.0]` section at the top with at least the words `Added` and `Changed`
- [ ] **AC12:** `README.md` contains a version badge pointing to `v1.5.0`
- [ ] **AC13:** Running `bash install.sh --accept-defaults --dry-run` exits with code 0 and prints no dialog-related errors
- [ ] **AC14:** Running `bash install.sh --accept-defaults --help` exits with code 0 and shows flag documentation that includes `--no-tui` and `--accept-defaults`
- [ ] **AC15:** Running `bash install.sh --accept-defaults --version` prints `1.5.0` to stdout
- [ ] **AC16:** File `.github/workflows/ci.yml` exists and contains all 5 job names: `shellcheck-lint`, `bash-syntax`, `format-check`, `verify-check`, `test-install`
- [ ] **AC17:** CI workflow triggers on `push` and `pull_request` to both `main` and `develop` branches (grep for `branches: [main, develop]` in ci.yml)
- [ ] **AC18:** Running `bash -n install.sh && bash -n update.sh && bash -n verify.sh && bash -n uninstall.sh && bash -n scripts/common.sh` all exit with code 0
- [ ] **AC19:** Running `shfmt -d -i 2 -ci install.sh update.sh verify.sh uninstall.sh scripts/common.sh` exits with code 0 (no formatting differences)
- [ ] **AC20:** Running `grep -r 'minimax' workspace/AGENTS.md workspace/TOOLS.md workspace/sdd/ config/` from repo root returns no matches — no stale minimax references remain in any synced config file
- [ ] **AC21:** Running `grep -c '## SDD Model Configuration' workspace/AGENTS.md` outputs exactly `1` — the SDD Model Configuration table section exists in AGENTS.md
- [ ] **AC22:** `workspace/AGENTS.md` SDD Model Configuration table contains exactly 8 data rows (one per SDD phase: Explore, Propose, Spec, Design, Tasks, Apply, Verify, Archive) — running `grep -cP '^\| \d+ \|' workspace/AGENTS.md` in the table area outputs `8`
- [ ] **AC23:** Running `bash install.sh --accept-defaults` (non-interactive) produces a `workspace/AGENTS.md` where the SDD Model Configuration table has 8 populated rows with valid provider/model strings (not placeholders or empty cells)
- [ ] **AC24:** `workspace/AGENTS.md` generated by `--accept-defaults` matches Camilo's suggested config: Explore → deepseek-v4-pro, Spec → github-copilot/gpt-5.4, Apply → openai-codex/gpt-5.4, Archive → deepseek-v4-flash (verify with specific grep patterns)
- [ ] **AC25:** Running `bash install.sh --no-tui --help` documents both `--no-tui` and `--accept-defaults` flags with distinct descriptions
- [ ] **AC26:** The installer script function `tui_sdd_phase_config()` or equivalent exists and is called from `main()` before the install mode selection
- [ ] **AC27:** Running `bash -n install.sh` passes — no syntax errors in any new TUI functions
