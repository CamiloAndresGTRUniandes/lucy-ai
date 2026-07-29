---
name: skill-registry
description: >
  Maintain registry metadata and compact trigger mapping for available skills.
  Trigger: when the user asks to update the skill registry, refresh skill-to-context mapping, or list/catalog available skills.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Skill Registry

## When to Use

Use when catalog changes require registry synchronization or when the user asks what skills are available.

## Rules

- Scan current skills and map triggers to contexts.
- Keep registry entries concise and actionable.
- Preserve deterministic ordering where practical.
- Update only registry artifacts unless the user asks to edit skill content.
- Do not expose private memory or unrelated workspace context when listing skills.
- Persist durable registry decisions to Engram when the change affects future behavior.

## Registry Sources

- `AGENTS.md` skill table
- `skills/*/SKILL.md` frontmatter
- Imported archive evaluation notes when relevant
