# Spec: v1.8.0 — Live workspace capability sync

## Status: Released

## Context

- **Problem:** The `lucy-ai` repository's workspace templates, SDD workflow docs, bundled skills, and config fragment have drifted from the live Lucy workspace. Users installing v1.7.0 or earlier would not get the current SDD orchestration flow, language-matching behavior, or the full set of reusable skills that Lucy was designed to have.
- **Business value:** Every new install or update to v1.8.0 gets the exact same capabilities that the live Lucy has been running in production. No manual post-install corrections. No missing skills. No stale model references.
- **Prior work:** v1.5.0 was the first config sync release. v1.7.0 added agnostic content enforcement and fixed agent profiles. This release continues the pattern of syncing live workspace improvements into the installer project.
- **Constraints:** No private data, project-specific content, secrets, or personal artifacts may be copied into the repo. The installer must remain a single `curl ... | bash` workflow. All existing installer flags must continue to work unchanged.

## Requirements

- F1 — Sync workspace templates: AGENTS.md, SOUL.md, USER.md, TOOLS.md from live to repo
- F2 — Sync SDD core docs: orchestrator-flow.md, task-string-format.md, validation-rules.md
- F3 — Sync SDD templates: apply.md.in, design.md.in, explore.md.in, spec.md.in, standards.md.in, verify.md.in
- F4 — Add 32 new bundled skills from live workspace to repo skills/
- F5 — Remove deprecated zenticalab-pr-review and zenticalab-security from repo skills/
- F6 — Update 7 existing skills to their live workspace versions
- F7 — Update config/agent-fragment.json5 main agent model to openai-codex/gpt-5.5
- F8 — Update README.md: version badge, what's-new, install examples
- F9 — Update CHANGELOG.md with v1.8.0 entry
- F10 — Rewrite SPEC.md to document v1.8.0 release
- F11 — Create RELEASE_NOTES.md with v1.8.0 release notes

## Skill inventory

- **43 bundled skills** after sync (12 surviving originals + 32 new - 1 duplicate angular-forms + 7 updated)
- 2 deprecated skills removed (zenticalab-pr-review, zenticalab-security)
- 1 personal skill excluded (resume-cv-builder)

## Acceptance criteria

- [ ] AC1: All workspace templates updated with language-matching rule, English content, current model matrix
- [ ] AC2: SDD core docs and templates synced to English-standardized live versions
- [ ] AC3: skills/ contains 43 skills, no zenticalab-* directories
- [ ] AC4: config fragment main agent points to openai-codex/gpt-5.5
- [ ] AC5: README.md version badge shows v1.8.0
- [ ] AC6: CHANGELOG.md has v1.8.0 entry
- [ ] AC7: RELEASE_NOTES.md exists at repo root
- [ ] AC8: All scripts pass bash -n syntax check
- [ ] AC9: No secrets or project-specific content in bundled files
- [ ] AC10: install.sh --version prints 1.8.0
