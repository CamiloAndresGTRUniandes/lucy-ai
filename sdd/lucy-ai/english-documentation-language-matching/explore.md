# Explore: English Documentation + Chat Language Matching

## Status: Approved

## Summary

This cycle covers two linked targets:
1. Lucy live workspace documentation and operating files under `~/.openclaw/workspace/`
2. The `lucy-ai` installer/templates repo under `/workspace/repos/lucy-ai/`

The language-matching bug is caused primarily by prompt priming: `AGENTS.md` is loaded early and contains critical sections in Spanish, which biases runtime responses toward Spanish even when Camilo writes in English.

## Findings

### Workspace files
- `AGENTS.md` includes the highest-impact Spanish content because SDD rules, model config, and workflow enforcement are written largely in Spanish.
- `SOUL.md` is mostly English, but the language-matching rule is not prominent enough to override upstream priming.
- `TOOLS.md`, `USER.md`, and `MEMORY.md` still contain enough Spanish to reinforce that bias.
- `HEARTBEAT.md` is already English and does not need translation.

### lucy-ai repo
- `README.md` and `docs/STANDARDS.md` still contain Spanish sections.
- `SPEC.md`, `SKILL.md`, and `CHANGELOG.md` are already effectively English.
- `sdd/` documentation and some templates still contain substantial Spanish content and would continue reproducing the same prompt bias in future installs.

### Project standards
- `docs/STANDARDS.md` already mandates English for code, comments, and docs.
- Workspace templates must remain project-agnostic.
- Installer architecture must stay shell-based, idempotent, auditable, and portable.

## Risks
- Translating only the live workspace would fix the current runtime but leave installer drift.
- Translating only the repo would keep Lucy’s current runtime inconsistent until manually synced.
- Editing locked workspace files without also updating lucy-ai templates would recreate drift on the next install/update.

## Recommendation

Treat `lucy-ai` as the canonical source of truth, update its templates and SDD docs to English, then sync the same approved content into the live workspace in the same cycle so runtime and installer stay aligned.
