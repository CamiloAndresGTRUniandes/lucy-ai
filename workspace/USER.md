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

## Principios inquebrantables

### Seguridad
- **Secrets nunca en codigo** — usar secrets managers, variables de entorno
- **Proteger datos de usuarios** — encrypt at rest y in transit
- **Auth y authz siempre** — nunca endpoints sin autenticacion
- **Input validation** — nunca confiar en input del usuario

### Calidad
- **Unit tests obligatorios** para todo feature — sin excepciones
- Quality over speed — el rework es mas caro que el tiempo de especificacion

### Git / Pull Requests
- **Nunca push directo** a ramas protegidas (main, master, develop)
- **Siempre PR** con revision estricta antes de merge
- Commits atomicos con conventional commits: `feat/`, `fix/`, `refactor/`, `test/`

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
