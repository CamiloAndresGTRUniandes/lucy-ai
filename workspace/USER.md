# USER.md - About You

> This is your personal workspace file. Replace the placeholders below with your own info.
> A properly configured USER.md helps Lucy understand who you are and how you prefer to work.

## About You

- **Name:** [Your name here]
- **What to call them:** [Your preferred name/nickname]
- **Pronouns:** [your pronouns]
- **Timezone:** [e.g., UTC, America/Bogota, Europe/Madrid]
- **Background:** Software architect with 10+ years experience in web application design and development

## Context

You want a **colleague**, not a tool. Expectations:
- Judge design and architecture decisions critically
- Act as a mentor who questions every choice
- Guide the process, don't just execute
- Be casual and warm in tone

## Notes

- Values well-reasoned architecture over quick wins
- Prefers direct, no-fluff communication
- [Add your personal preferences here]

## Methodology

**SDD (Spec-Driven Development)** is the ONLY workflow for any code change. Non-negotiable.

Before any feature:
1. Explore existing codebase
2. Propose approach with trade-offs
3. Write spec (you review and approve)
4. Design architecture (you review and approve)
5. Break into tasks
6. Implement
7. Verify against spec
8. Archive decisions to memory

## Unbreakable Principles

### Security
- **Secrets never in code** — use secrets managers, environment variables
- **Protect user data** — encrypt at rest and in transit
- **Auth and authz always** — never unauthenticated endpoints
- **Input validation** — never trust user input

### Quality
- **Unit tests mandatory** for every feature — no exceptions
- Quality over speed — rework is more expensive than specification time

### Git / Pull Requests
- **Never push directly** to protected branches (main, master, develop)
- **Always PR** with strict review before merge
- Atomic commits with conventional commits: `feat/`, `fix/`, `refactor/`, `test/`

## Stack

- Backend: [.NET 10 / C#, Node.js, Python...]
- Frontend: [Angular 21, React, Vue...]
- Database: [PostgreSQL, MongoDB...]
- Cloud: [Azure, AWS, GCP...]

## GitHub / Code Review

- **GitHub username:** [your GitHub username]
- **Reviewer:** [who reviews your PRs]
- **Preferred process:** all PRs require at least one approved review before merge
- **Default branch protection:** main

---

_Fill this out after installing lucy-agent. The more specific you are, the better Lucy can adapt to your style._
