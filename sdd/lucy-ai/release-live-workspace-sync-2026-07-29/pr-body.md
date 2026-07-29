## Summary
- Release v1.8.0 live workspace capability sync so fresh installs match the current Lucy configuration.
- Adds 32 reusable bundled skills, removes deprecated `zenticalab-*` skills, and updates 7 existing skills.
- Syncs workspace templates, SDD docs/templates, agent config, version metadata, changelog, and release notes.

## Changes
- Updated `workspace/AGENTS.md`, `SOUL.md`, `TOOLS.md` with language matching, orchestrator doctrine preload, and current model/tool inventory.
- Synced root and workspace SDD docs/templates from the live workspace.
- Added project-agnostic skills for orchestration, architecture, security, Azure DevOps, Ignite UI Angular, .NET, SQL, git/PR workflow, and mentoring.
- Removed `skills/zenticalab-pr-review` and `skills/zenticalab-security` in favor of `pr-review` and `security`.
- Updated `config/agent-fragment.json5` so the main agent defaults to `openai-codex/gpt-5.5` with DeepSeek Pro fallback.
- Bumped `install.sh` to `1.8.0`; updated `README.md`, `CHANGELOG.md`, `SPEC.md`, and added `RELEASE_NOTES.md`.

## Testing
- [x] `./verify.sh` — 116/116 checks passed
- [x] `bash -n install.sh update.sh verify.sh uninstall.sh scripts/*.sh`
- [x] Skill inventory: 43 bundled skills, 0 `zenticalab-*` dirs
- [x] Project-content grep: 0 hits for ZENTICALAB/excel-pipeline/portfolio/ssdp-ai in shipped workspace/config/skills/release notes
- [x] Secret scan reviewed: no secrets; only false positives from `task-string-format.md` / `skill-*` names

## Notes
- `resume-cv-builder` intentionally excluded as personal/niche rather than core Lucy bundle.
- GitHub release notes are prepared in `RELEASE_NOTES.md`.
