---
name: sdd
description: >
  Spec-Driven Development workflow for OpenClaw. Triggers when Camilo wants to build something new, implement a feature, make architectural decisions, or plan a change.
  Follows 8 phases: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive.
  Core principle: Spec before code. Lucy questions, Camilo decides.
metadata:
  author: lucy-camilo
  version: "1.0"
---

## Core Principle

**Spec before code.** No matter how obvious the implementation seems. The spec is our contract about what we're building, why, and how.

**Lucy questions, Camilo decides.** My job is to ensure specs and designs are solid before implementation.

---

## When to Trigger

Load this skill when Camilo:
- Says "build", "implement", "we should add", "I need"
- Wants to plan a feature or significant change
- Asks to review architecture or design
- Wants to approach a problem but doesn't know where to start

## Decision Memory Protocol

**Before making any architectural decision:**
1. Check `memory/` and `MEMORY.md` for prior decisions on the topic
2. If a decision exists, invoke it explicitly in conversation
3. Proceed only with full context of what's already been decided

**When changing a prior decision:**
1. State the existing decision clearly
2. Explain why the change is being proposed
3. Compare old vs new with specific trade-offs
4. Camilo decides if the change is worth the cost

This applies to: patterns chosen, library selections, architectural approaches, naming conventions, team norms.

---

## SDD Phases

### Phase 1: Explore
Investigate before proposing.

**Do:**
- Read existing code related to the problem
- Identify patterns, conventions, dependencies
- Note technical debt or risks

**Ask Camilo:**
- "¿Qué existe hoy que se relaciona con esto?"
- "¿Hay algo similar ya implementado?"

---

### Phase 2: Propose
Present intent, scope, and approach options.

**Must include:**
1. **Intent** — Problem we're solving, why it matters
2. **Scope** — What's included and explicitly excluded
3. **Approach options** — 2-3 paths with trade-offs
4. **Recommendation** — Mi推荐 y por qué

**Ask Camilo:**
- "¿Cuál es el problema de negocio?"
- "¿Qué pasa si no lo hacemos?"
- "¿Constraints de tiempo o técnica?"

**Do not proceed until Camilo approves direction.**

---

### Phase 3: Spec
Write the specification. Source of truth for the feature.

```markdown
# Spec: [Feature Name]

## Context
- Problem statement
- Business value
- Constraints and assumptions

## Requirements
- Functional (user-facing behaviors)
- Non-functional (performance, security, scalability)

## User Scenarios
1. [Scenario] — Given/When/Then

## Out of Scope
- Explicitly what this does NOT include

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

**Do not write code in this phase.**

**Ask Camilo:**
- "¿Qué pasa cuando X? ¿Y cuando Y?"
- "¿Cómo sabemos que está listo?"
- "¿Edge cases?"

**Do not proceed until Camilo reviews and approves.**

---

### Phase 4: Design
Technical architecture and decisions.

**Must cover:**
1. **Architecture** — Components, modules, layers
2. **Data model** — Entities, relationships
3. **API design** — Endpoints, contracts (if applicable)
4. **Security** — Auth, data handling
5. **Error handling** — Failure management
6. **Observability** — Logging, metrics

```markdown
## Architecture Decisions

| Decision | Choice | Rationale | Alternative |
|---|---|---|---|
| Pattern | Clean Architecture | Separation of concerns | N-layer |
```

**Ask Camilo:**
- "¿Cómo se ve el flujo de datos?"
- "¿Dónde están los puntos de fallo?"
- "¿Qué pasa si servicio X no está disponible?"

**Do not proceed until Camilo approves.**

---

### Phase 5: Tasks
Break implementation into concrete, ordered tasks.

```markdown
## Task List

- [ ] **T1:** Create domain entities
- [ ] **T2:** Implement repository layer
- [ ] **T3:** Build service layer
- [ ] **T4:** Create API endpoints
- [ ] **T5:** Add error handling
- [ ] **T6:** Write unit tests
```

Each task: implementable in 1-4 hours, clear start/end, verifiable partial result.

---

### Phase 6: Apply
Implement following spec and design exactly.

**Rules:**
- Follow spec — if spec is wrong, back to Phase 3
- Follow design — if design is wrong, back to Phase 4
- Apply coding standards from relevant skills (angular/core, csharp-dotnet, etc.)
- **Write tests alongside code, not after**
- **Unit tests are mandatory for every feature — no exceptions**
- Commit with conventional commits

**If new information emerges:**
- Spec wrong → stop, revisit Phase 3
- Design wrong → stop, revisit Phase 4
- Document finding in memory

---

### Phase 7: Verify
Validate implementation against spec.

```markdown
## Verification

### Spec Compliance
- [ ] All requirements implemented
- [ ] All acceptance criteria met
- [ ] All user scenarios work

### Code Quality
- [ ] Follows project conventions
- [ ] No hardcoded values where config is appropriate
- [ ] Error handling complete
- [ ] Tests cover core logic

### Security
- [ ] Auth/authz as designed
- [ ] Input validation in place
- [ ] No sensitive data in logs

### Integration
- [ ] Components compile
- [ ] Tests pass
- [ ] No breaking changes
```

---

### Phase 8: Archive
Sync results and update memory.

1. Create or update `SPEC.md` in project root
2. Save architectural decisions to `memory/`
3. Summarize what was built for future reference

---

## Anti-Patterns

| Anti-pattern | SDD version |
|---|---|
| "Lets just build it" | "Lets spec it first" |
| Design by gut | Documented decisions with rationale |
| Spec that ignores constraints | Realistic spec considering time/capacity |
| Verify after shipping | Verify before moving to next task |

---

## Important Reminders

- **Do not skip phases.** Spec exists so we don't rework code. Rework is expensive.
- **Spec is conversation, not bureaucracy.** If it feels unnecessary, the feature is too small for SDD.
- **Persistence.** Save decisions and specs to `memory/` so future sessions can continue.
- **Lucy speaks up.** If something feels wrong in the spec or design, I say so — that's my job.
