---
name: sdd
description: >
  Spec-Driven Development workflow for OpenClaw. Triggers when Camilo wants to build something new, implement a feature, make architectural decisions, or plan a change.
  Follows these phases: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive.
  Core principle: Spec before code. Lucy questions, Camilo decides.
metadata:
  author: lucy-camilo
  version: "1.1"
---

## Core Principle

**Spec before code.** No matter how obvious the implementation seems. The spec is our contract about what we're building, why, and how.

**Lucy questions, Camilo decides.** My job is to ensure specs and designs are solid before implementation.

---

## ⛔ PHASE TRANSITION GATE PROTOCOL (NON-NEGOTIABLE)

**Every SDD phase transition requires Camilo's explicit approval. NO EXCEPTIONS.**

### What counts as approval:
- ✅ **Explicit phrase**: "spec approved", "design approved", "tasks approved", "approved", "aprobado"
- ✅ **Recorded in state.json**: `phaseApprovals.{phase}.approved = true` with timestamp

### What does NOT count as approval:
- ❌ "sí", "dale", "ok", "👍", "me gusta", "bien"
- ❌ Silence or moving on to another topic
- ❌ Any emoji reaction
- ❌ "se ve bien", "good", "nice"

### Mandatory steps at EVERY phase transition:
1. **PRESENT** the phase output to Camilo (summary, not raw dump)
2. **ASK** explicitly in the same language as Camilo's message, using the matching approval prompt.
3. **WAIT** for explicit approval (not interpretation, not assumption)
4. **RECORD** approval in `state.phaseApprovals.{phase}` before spawning next phase
5. **Only then** proceed to next phase

### Gate Check (mandatory before executing ANY phase):
1. Read `state.json` → `phaseApprovals`
2. If previous phase `approved !== true` → **ABORT**. Ask Camilo for approval.
3. If `approved === true` → continue normally.

### If Camilo seems to approve but doesn't use explicit phrase:
> "Camilo, please confirm: do you formally approve the {phase}? I need an explicit 'approved' to record it in state.json and continue."

> **🔗 Fuente de verdad operativa:** El flujo paso a paso de cada fase (incluyendo Engram Context Assembly, Memory Prep, y saves post-aprobación) está en `sdd/orchestrator-flow.md`. Este skill define el qué; el orchestrator-flow.md define el cómo exacto.

---

## When to Trigger

**Referencia cruzada:** Ver `sdd/orchestrator-flow.md` § Step-by-Step por Fase para la implementación operativa de cada phase, incluyendo los pasos de Engram Memory Prep y persistencia de decisiones.

Load this skill when Camilo:
- Says "build", "implement", "we should add", "I need"
- Wants to plan a feature or significant change
- Asks to review architecture or design
- Wants to approach a problem but doesn't know where to start

## Templates

| Template | Phase | Output |
|----------|-------|--------|
| `sdd/templates/explore.md.in` | Explore | Codebase overview, patterns found, dependencies & risks, recommendations |
| `sdd/templates/spec.md.in` | Spec | Context, requirements, user scenarios, acceptance criteria |
| `sdd/templates/design.md.in` | Design | Architecture decisions, data model, API design, security, error handling, observability |
| `sdd/templates/tasks.md.in` | Tasks | Task list with titles, descriptions, effort estimates, dependencies |
| `sdd/templates/apply.md.in` | Apply | Files modified, implementation summary, tests |
| `sdd/templates/verify.md.in` | Verify | Spec compliance, acceptance criteria check, code quality, security, final verdict |

## Decision Memory Protocol

**Two memory systems, one purpose:**
- **Engram** (`engram__*` tools): Technical decisions, architecture, patterns, bugs — structured, searchable, cross-session
- **MEMORY.md + memory/*.md**: Personal context, preferences, relationships — Lucy's long-term memory

**Before making any architectural decision:**
1. Search Engram: `engram__mem_search("<keywords>", type="architecture")` for prior technical decisions
2. Check `memory/` and `MEMORY.md` for personal/project context
3. If a decision exists in Engram, invoke it explicitly with its observation ID
4. Proceed only with full context of what's already been decided

**When changing a prior decision:**
1. State the existing decision clearly (from Engram, with observation ID)
2. Explain why the change is being proposed
3. Compare old vs new with specific trade-offs
4. Camilo decides if the change is worth the cost
5. If approved → `engram__mem_save` with the same `topic_key` (upserts, `revision_count++`)

**When saving decisions to Engram:**
- Use `engram__mem_suggest_topic_key` for stable keys on evolving topics
- Architecture decisions → `topic_key="architecture/<slug>"`
- If `mem_save` returns `judgment_required: true` → surface conflict to Camilo via `engram__mem_judge`
- Conflicts with `confidence < 0.7` or `relation ∈ {supersedes, conflicts_with}` AND `type ∈ {architecture, policy, decision}` → **always ask Camilo** before judging

**Be critical of decisions:**
- Question every new decision: does it really improve things or just add complexity?
- Keep existing decisions unless there's a significant, demonstrable improvement
- Consistency is value — changing for the sake of change is not progress
- If a decision has worked well for a long time, you need strong reasons to change it
- Architecture scrutiny is mandatory, not optional

This applies to: patterns chosen, library selections, architectural approaches, naming conventions, team norms.

## Engram Memory Protocol

Engram is the **technical memory** of the project. Every significant technical decision is saved with structured format.

### When to save

| Trigger | Type | Example |
|---------|------|---------|
| Architecture decision made | `architecture` | "InventoryAlert aggregate root" |
| Trade-off resolved | `decision` | "PostgreSQL over MongoDB for catalog" |
| Pattern established | `pattern` | "Private record Row types for SQL mappings" |
| Bug fixed (non-trivial) | `bugfix` | "N+1 query in lot suggestion" |
| Important discovery | `discovery` | "EF Core doesn't support X with schema-per-tenant" |
| Config/setup change | `config` | "Added Azurite blob storage for local dev" |

### Content format (mandatory)

```
**What**: [concise description of what was done/decided]
**Why**: [reasoning, problem it solves, trade-off rationale]
**Where**: [files/components affected, e.g. src/Application/DTOs/..., features/tenant/...]
**Learned**: [gotchas, edge cases, or insights — omit if none]
```

### Progressive disclosure (token-efficient)

```
1. engram__mem_search "auth middleware"     → compact results with IDs
2. engram__mem_timeline observation_id=42   → what happened before/after
3. engram__mem_get_observation id=42        → full untruncated content
```

### Session lifecycle per SDD phase

Each delegated SDD phase should be tracked as an Engram session:
- Phase start: `engram__mem_session_start(id="SDD-{feature}-{phase}")`
- Phase end: `engram__mem_session_end(summary="...")`
- Full summary: `engram__mem_session_summary(content="Goal/Discoveries/Accomplished/Files")`

---

## SDD Phases

### Phase 1: Explore
Investigate before proposing. Delegado a sub-agente.

**Flujo delegado:**
1. **Pre-flight Engram Context Assembly:** Lucy carga contexto de Engram (sesiones recientes, decisiones de arquitectura) y ensambla el Pre-loaded Engram Context Block.
2. **Spawn sub-agente:** Lucy usa el task string de `sdd/task-string-format.md` con template `explore.md.in`. Contexto `isolated`. Inyecta el Pre-loaded Engram Context Block como sección del task string.
3. **Validación:** Lucy valida el output del sub-agente contra `sdd/validation-rules.md` § Explore.
4. **Persistencia en Engram:** Si pasa validación, Lucy inicia sesión Engram (`engram__mem_session_start`), guarda descubrimientos con `engram__mem_save(type="discovery")`, y cierra sesión (`engram__mem_session_end`). Esto ocurre **post-aprobación de Camilo** (cuando sea parte de un SDD cycle completo).
5. **Retry:** Máximo 3 intentos. Si falla 3 veces, escalar a Camilo.

> **🔗 Detalles operativos:** Ver `sdd/orchestrator-flow.md` § 1. Explore para el flujo completo incluyendo state.json updates, error handling (Engram no disponible, timeout), y edge cases.

**Do:**
- Read existing code related to the problem
- Identify patterns, conventions, dependencies
- Note technical debt or risks

**Ask Camilo:**
- "¿Qué existe hoy que se relaciona con esto?"
- "¿Hay algo similar ya implementado?"

**Do not proceed until Camilo reviews and approves the Explore findings.**

---

### Phase 2: Propose
Present intent, scope, and approach options.

**Memory prep:** `engram__mem_search("<feature keywords>", type="architecture")` — surface prior art.

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

**Memory prep:** `engram__mem_context` — auto-load recent session summaries for continuity.

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

**Memory prep:** `engram__mem_context` + `engram__mem_search("<feature>", type="architecture")`

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

**After approval — save ALL architectural decisions to Engram:**
```
engram__mem_suggest_topic_key(type="architecture", title="<decision title>") → get topic_key
engram__mem_save(
  title="<decision title>",
  type="architecture",
  topic_key="architecture/<slug>",
  content="**What**: ...\n**Why**: ...\n**Where**: ...\n**Learned**: ..."
)
```
If `judgment_required: true` → surface candidates to Camilo before judging.

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

**Memory prep:** `engram__mem_context` — auto-loads Design session summary + decisions.
Then `engram__mem_search("<feature>", type="architecture")` for specific architectural constraints.

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
- Document finding: `engram__mem_save(type="discovery", ...)`

**Do not proceed until Camilo reviews and approves the implementation.**

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

**Do not proceed to Archive until Camilo reviews and approves the verification.**

---

### Phase 7.5: PR Review & Address Changes
Post-Verify: PR review por Camilo y resolución de feedback. **NO NEGOCIABLE.**

**Clasificación de feedback de Camilo:**
| Tipo | Ejemplo | Ruta |
|------|---------|------|
| **Minor** | Typos, naming, error msg, log level | Apply fix → Re-verify → Archive |
| **Moderate** | Nueva variable/constante, cambio de validación | Tasks → Apply → Verify |
| **Major** | Cambio de comportamiento, nuevo endpoint | Spec → Design → Tasks → Apply → Verify |

**Reglas de ruta:**
- Lucy clasifica cada comment y propone la ruta a Camilo antes de actuar
- Minor: Lucy resuelve directo en Apply fix, luego re-verify
- Moderate: nuevo sub-ciclo Tasks → Apply → Verify
- Major: ciclo completo Spec → Design → Tasks → Apply → Verify

**Condición para Archive:**
Archive solo ocurre cuando:
- PR mergeado en `main`/`develop`, **O**
- Camilo decide explícitamente cerrar el ciclo sin merge (con rationale documentado)

> **🔗 Detalles operativos:** Ver `sdd/orchestrator-flow.md` § 7.5 para el flujo completo incluyendo el árbol de decisión de feedback y las reglas NO NEGOCIABLES.

**Ask Camilo:**
- "Camilo, tus comments son minor (N typos) y moderate (1 validation change). Minor los resuelvo directo, moderate entra como T1 nuevo. ¿Dale?"

---

### Phase 8: Archive
Sync results and update memory. Lucy directo (no delegado).

1. **Engram session summary:** `engram__mem_session_summary(session_id=cycleSessionId)` con Goal, Discoveries, Accomplished, Relevant Files.
2. **Sync decisiones finales:** Itera por todas las fases en `state.engram.observations`, guarda decisiones pendientes, verifica que todas las decisiones de arquitectura estén persistidas.
3. **Guardar en state:** `state.engram.observations.archive` con las decisiones finales del ciclo.
4. **Mover directorio:** `sdd/{project}/{feature}/` → `sdd/{project}/{feature-YYYY-MM-DD}/`.
5. **Actualizar state.json:** `status: completed`, bloque `engram` completo con todos los observation IDs.
6. **Escribir resumen en memory/:** `memory/YYYY-MM-DD-{project}-{feature}.md` con resumen del ciclo.
7. **Presentar resumen final a Camilo:** Lo que se construyó, decisiones tomadas, estado del PR.
8. **Preguntar:** "¿Archivamos y pasamos al próximo feature?"

> **🔗 Detalles operativos:** Ver `sdd/orchestrator-flow.md` § 8. Archive para el flujo completo incluyendo edge cases (Camilo decide cerrar sin merge) y reglas NO NEGOCIABLES.

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
