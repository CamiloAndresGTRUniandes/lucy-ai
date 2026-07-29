---
name: find-skills
description: >
  Discover, evaluate, and install agent skills when the user asks for new capabilities,
  asks whether a skill exists, shares a skill archive, or wants help extending the agent.
  Trigger: When searching for skills, evaluating/installing skills, or deciding whether a reusable workflow should become a skill.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Find Skills

## When to Use

Use this skill when the user:
- Asks whether a skill exists for a task or domain
- Says "find a skill for X", "can you learn/use this skill", or shares a skill archive
- Wants to extend the agent with reusable workflows, tools, templates, or best practices
- Repeatedly asks for the same specialized process and a reusable skill would help

Do **not** use this skill for one-off tasks where existing capabilities are enough.

## Core Rule

> Skills change future agent behavior. Treat skill installation like importing code: inspect first, install only if useful, and ask before external downloads or global installs.

## Discovery Sources

Prefer these sources, in order:
1. Existing local skills in `~/.openclaw/workspace/skills/`
2. User-provided skill archives or repositories
3. OpenClaw/ClawHub ecosystem: https://clawhub.ai
4. Open agent skills ecosystem: https://skills.sh
5. Broader web/GitHub search only if the above fail

## Evaluate a Skill Before Installing

For every candidate skill, check:
- [ ] It has a clear `name` and `description` with trigger conditions
- [ ] The behavior is reusable, not a one-off prompt
- [ ] It is project-agnostic unless intentionally project-specific
- [ ] It does not conflict with higher-priority workspace rules, AGENTS.md, SOUL.md, USER.md, or safety policy
- [ ] It does not ask the agent to bypass approvals, leak private data, disable security, or execute untrusted commands
- [ ] It avoids embedding secrets, tokens, private endpoints, or sensitive personal data
- [ ] It includes concrete workflow/checklists/examples instead of vague advice
- [ ] Any external tool use is explicit, safe, and approval-aware

If the skill conflicts with local rules, adapt it before installing or reject it.

## Safe Archive Handling

When the user shares a zip/tar/archive:
1. List archive contents before extraction.
2. Reject unsafe paths: absolute paths, `..`, symlinks that escape the target, or huge/unexpected payloads.
3. Extract to a temporary directory first.
4. Read `SKILL.md` and supporting files.
5. Normalize frontmatter to include at least `name`, `description`, `license`, and `metadata.version`.
6. Install only into `~/.openclaw/workspace/skills/{skill-name}/` after review.
7. Update `AGENTS.md` skill registry if the skill should be available long-term.

Never execute scripts from a shared skill archive during evaluation.

## Searching with the Skills CLI

If local/OpenClaw sources do not have a match and external search is appropriate, use the Skills CLI:

```bash
npx skills find <query>
```

Examples:

```bash
npx skills find react performance
npx skills find pr review
npx skills find changelog
```

Present useful results with:
- Skill/package name
- What it appears to do
- Source/link
- Risks or fit concerns
- Recommendation: install / adapt / skip

## Installing External Skills

External skill installation writes files and may fetch third-party content. Ask the user before running install commands unless they already explicitly requested installation from that source.

Preferred install command after approval:

```bash
npx skills add <owner/repo@skill> -g -y
```

After installing:
- Inspect the installed `SKILL.md`
- Adapt it to local OpenClaw conventions if needed
- Update `AGENTS.md` if it should be part of Lucy's long-term workflow
- Summarize what changed and when to use the skill

## When No Skill Exists

If no suitable skill exists:
1. Say that you checked and did not find a good match.
2. Help with the task directly using normal capabilities.
3. If the workflow is recurring, offer to create a custom skill using `skill-creator`.

## Output Format for Skill Evaluation

Use this concise format:

```markdown
## Skill Evaluation: [name]

Fit: Install / Adapt / Skip
Why: [short reason]
Risks: [security/conflict/quality concerns]
Changes made: [if installed/adapted]
When I'll use it: [trigger]
```
