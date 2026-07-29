---
name: software-architecture
description: >
  Project-agnostic software architecture guidance focused on maintainability,
  Clean Architecture, DDD, boundaries, naming, modularity, and code quality tradeoffs.
  Trigger: when designing architecture, reviewing architectural choices, refactoring structure,
  defining module boundaries, or evaluating development tradeoffs. Does not replace SDD.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
  source: community-adapted
---

# Software Architecture Skill

## When to Use

Use this skill when:
- Designing or reviewing architecture
- Defining modules, boundaries, layers, services, or domain models
- Refactoring structure for maintainability
- Evaluating whether to build custom code or use an existing library/service
- Reviewing code for separation of concerns, naming, duplication, complexity, and coupling

Do **not** use this skill as a shortcut around SDD. For code changes, SDD remains mandatory: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive, with explicit Camilo approval at every phase gate.

Always combine this with:
- The repo's `docs/STANDARDS.md`
- Relevant stack skills, such as `csharp-dotnet`, `typescript`, `angular-core`, or `security`
- Existing architecture decisions from Engram/local memory before changing direction

## Core Architecture Principles

- Optimize for clarity, correctness, safety, and evolvability before cleverness.
- Keep business rules independent from frameworks, transport, databases, and UI.
- Make dependencies point inward toward stable domain/application concepts.
- Use domain language for names; avoid generic dumping grounds like `utils`, `helpers`, `misc`, or `common` unless the repo standard explicitly defines them.
- Prefer explicit boundaries over accidental coupling.
- Keep high-risk decisions reversible where practical.
- Question every new abstraction: abstraction must reduce real complexity, not hide it.

## Library vs Custom Code Decision

Prefer existing, well-maintained libraries/services for commodity concerns, but do not adopt dependencies blindly.

Use a library/service when:
- The problem is generic and already solved well: auth, retry policies, validation primitives, date/time, parsing, observability, payments, etc.
- The dependency is maintained, secure, licensed appropriately, and fits the architecture.
- It reduces long-term maintenance burden more than it increases integration risk.

Write custom code when:
- It is domain-specific business logic.
- Existing libraries are overkill, insecure, abandoned, poorly licensed, or too coupled.
- The behavior is security-sensitive and requires full control.
- The code is small, stable, and cheaper to own than a dependency.
- Performance or operational constraints require a tailored implementation.

Before adding a dependency, check:
- [ ] Security/vulnerability posture
- [ ] Maintenance activity
- [ ] License compatibility
- [ ] Transitive dependency weight
- [ ] Operational/runtime cost
- [ ] Testability and replacement path

## Clean Architecture / DDD Checklist

- [ ] Domain model uses ubiquitous language from the business.
- [ ] Domain/application logic is not embedded in controllers, UI components, jobs, or database adapters.
- [ ] Infrastructure implements interfaces/contracts defined inward where appropriate.
- [ ] Use cases/application services are cohesive and focused.
- [ ] Entities/value objects enforce meaningful invariants.
- [ ] Boundaries between bounded contexts are explicit.
- [ ] Cross-context communication uses stable contracts/events/APIs instead of direct model leakage.
- [ ] Persistence concerns do not dictate domain design unless the tradeoff is explicit.

## Separation of Concerns Checklist

- [ ] UI components do not contain business rules.
- [ ] Controllers/endpoints orchestrate; they do not own domain decisions.
- [ ] Database queries stay in repository/query/application/infrastructure areas according to project standards.
- [ ] Validation is located at the correct boundary: input shape, business invariant, or persistence constraint.
- [ ] Logging, telemetry, authorization, caching, and retries are consistent cross-cutting concerns, not scattered one-offs.

## Naming Guidance

Prefer names that describe business responsibility:

| Weak | Better direction |
|---|---|
| `utils` | Domain-specific module, e.g. `invoice-pricing`, `order-numbering` |
| `helpers` | Capability-specific service/function name |
| `common` | Explicit shared kernel/shared contract only if intentional |
| `manager` | More precise role: `Scheduler`, `Policy`, `Calculator`, `Resolver`, `Coordinator` |
| `data` | Specific model/DTO/query/result name |

Ask: “Would a new teammate understand the module’s responsibility from the name alone?”

## Code Quality Heuristics

These are heuristics, not absolute laws. Project standards win.

- Prefer early returns to reduce nesting when they improve readability.
- Avoid deep nesting; more than 3 levels usually deserves extraction or rethinking.
- Keep functions focused; large functions need a reason.
- Keep files cohesive; split large files when they contain multiple responsibilities.
- Remove duplication when it represents shared knowledge; tolerate small duplication when abstraction would be worse.
- Handle errors explicitly and consistently with the project’s error model.
- Avoid hidden side effects in helpers, mappers, computed properties, and extension methods.

## Anti-Patterns to Flag

- Business logic in UI/controller/transport layer
- Database schema leaking across all layers
- Generic helper dumping grounds
- Custom implementations of commodity security/auth/crypto/date/retry behavior without strong justification
- Framework types in domain entities/value objects
- Unbounded service classes doing unrelated orchestration
- Circular dependencies between modules
- Premature abstraction before the second real use case
- “Just one more flag” designs that should be polymorphism, strategy, or separate workflows
- Architecture changes without tests or migration strategy

## Architecture Review Output

Use this format when reviewing a design:

```markdown
## Architecture Review: [topic]

### Verdict
[Sound / Needs changes / Risky / Not enough context]

### What works
- [specific strength]

### Risks
- [risk + impact]

### Tradeoffs
- Option A: [gain/loss]
- Option B: [gain/loss]

### Recommendation
[clear recommendation and why]

### Required follow-up
- [tests/spec/migration/security check/decision record]
```

## Decision Discipline

Before changing architecture, answer:
1. Why change?
2. What do we gain?
3. What do we lose?
4. What existing decision or convention does this replace?
5. Is the gain worth the inconsistency/migration cost?

If the decision is durable, save it to Engram after approval.
