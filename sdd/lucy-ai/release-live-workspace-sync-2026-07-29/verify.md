# Verification: v1.8.0 — Live workspace capability sync

## verify.sh

✅ **116/116 checks passed** — zero failures.

## Syntax checks

```
✅ install.sh
✅ update.sh
✅ verify.sh
✅ uninstall.sh
✅ scripts/common.sh
✅ scripts/check-content-boundaries.sh
✅ scripts/install-pre-commit-hook.sh
```

## Acceptance criteria

| AC | Description | Result |
|----|------------|--------|
| AC1 | AGENTS.md: language-matching, orchestrator preload, English, updated models | ✅ |
| AC2 | SOUL.md: language section, English security | ✅ |
| AC3 | USER.md: English principles | ✅ |
| AC4 | TOOLS.md: current model inventory (gpt-5.5, gpt-5.4, etc.) | ✅ |
| AC5 | skills/: 43 skills | ✅ |
| AC6 | zenticalab-pr-review/ removed | ✅ |
| AC7 | zenticalab-security/ removed | ✅ |
| AC8 | config fragment: main → openai-codex/gpt-5.5 | ✅ |
| AC9 | README badge: v1.8.0 | ✅ |
| AC10 | CHANGELOG: v1.8.0 entry | ✅ |
| AC11 | SPEC.md: documents v1.8.0 | ✅ |
| AC12 | RELEASE_NOTES.md: exists | ✅ |
| AC13 | Scripts: bash -n passes | ✅ |
| AC14 | No secrets or private data | ✅ |
| AC15 | No project-specific references | ✅ |
| AC16 | install.sh --version prints 1.8.0 | ✅ |

## Sanitization checks

| Check | Result |
|-------|--------|
| ZENTICALAB references | 0 |
| excel-pipeline references | 0 |
| ssdp-ai references | 0 |
| portfolio references | 0 |
| secrets/API keys | 0 (9 false positives from task-string/skill- names) |
| zenticalab-* directories | 0 |

## Files changed

```
M  workspace/AGENTS.md, SOUL.md, TOOLS.md
M  sdd/orchestrator-flow.md, task-string-format.md, validation-rules.md
M  sdd/templates/apply.md.in, design.md.in, explore.md.in,
   spec.md.in, standards.md.in, verify.md.in
M  workspace/sdd/orchestrator-flow.md, task-string-format.md,
   templates/standards.md.in
D  skills/zenticalab-pr-review/, skills/zenticalab-security/
M  7 skills updated
A  32 new skills
M  config/agent-fragment.json5
M  README.md, CHANGELOG.md, SPEC.md
A  RELEASE_NOTES.md
M  install.sh (version), verify.sh (checks)
```

## Verdict

✅ **PASS** — all 16 acceptance criteria met, 116/116 verify.sh checks pass, zero secrets, zero project leaks, branch ready for PR.
