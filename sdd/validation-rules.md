# SDD Orchestrator — Validation Rules

## Propósito

Lucy valida el output de cada sub-agente delegado ANTES de avanzar a la siguiente fase.
**Validación estricta:** si una sección requerida falta o está vacía, se considera fail → retry.

---

## Algoritmo General

```
1. ¿El archivo de output existe?
   → No → FAIL (retry)
2. Parsear secciones markdown (## SectionName)
3. ¿Todas las secciones requeridas están presentes?
   → No → FAIL (retry), reportar secciones faltantes
4. ¿Cada sección tiene contenido > 10 caracteres de texto?
   → No → FAIL (retry), reportar secciones vacías
5. Validaciones específicas de la fase (ver tabla por fase)
6. → PASS
```

---

## Por Fase

### Explore

**Archivo esperado:** `sdd/{project}/{feature}/explore.md`

**Secciones requeridas:**
- [ ] `## Codebase Overview` — debe contener descripción de la arquitectura
- [ ] `## Patterns Found` — debe contener al menos 1 patrón
- [ ] `## Dependencies & Risks` — debe contener al menos 1 ítem
- [ ] `## Recommendations` — debe contener al menos 1 recomendación accionable

**Validación extra:**
- Cada patrón en Patterns Found debe tener un nombre y una ubicación fuente (archivo:línea)

### Spec

**Archivo esperado:** `sdd/{project}/{feature}/spec.md`

**Secciones requeridas:**
- [ ] `## Context` — no vacío, contener al menos Problem + Business value
- [ ] `## Requirements` — con subtablas Functional y/o Non-Functional (al menos 1 requirement)
- [ ] `## User Scenarios` — al menos 1 escenario con Given/When/Then
- [ ] `## Acceptance Criteria` — al menos 1 criterio con formato checklist (aceptar tanto `[ ] AC1:` como `- [ ] **AC1:**`)
- [ ] `## Out of Scope` (opcional pero recomendado)

**Validación extra:**
- Las tablas Requirements deben tener al menos 1 fila de datos
- Cada Acceptance Criterion debe ser una proposición verificable (no ambigua)

### Design

**Archivo esperado:** `sdd/{project}/{feature}/design.md`

**Secciones requeridas:**
- [ ] `## Architecture Decisions` — tabla con al menos 1 decisión
- [ ] `## Data Model` — descripción de entidades/schemas
- [ ] `## API Design` — endpoints o interfaces _(opcional)_ — no causa fail si ausente
- [ ] `## Security` — auth, data handling, input validation
- [ ] `## Error Handling` — failure modes + recovery
- [ ] `## Observability` — logging, metrics
- [ ] `## Decisiones aprobadas por Camilo` _(opcional)_ — no causa fail si ausente
- [ ] `## Migration Plan` _(opcional)_ — no causa fail si ausente

**Validación extra:**
- Cada Architecture Decision debe tener: Decision, Choice, Rationale, Alternative Rejected
- Si `## Decisiones aprobadas por Camilo` está presente, validar que tenga al menos 1 fila de datos

### Tasks

**Archivo esperado:** `sdd/{project}/{feature}/tasks.md`

**Secciones requeridas:**
- [ ] `## Task List` — al menos 1 tarea con title + description
- [ ] `## Dependencies` — grafo de dependencias entre tareas
- [ ] `## Estimated Effort` — tabla con estimados por tarea

**Validación extra:**
- Cada tarea debe tener: Título, Descripción, Output
- Cada tarea estimada en tiempo (minutos u horas)

### Apply

**Archivo esperado:** `sdd/{project}/{feature}/apply.md`

**Secciones requeridas:**
- [ ] `## Files Modified` — tabla con File, Action, Description
- [ ] `## What Was Implemented` — resumen no trivial
- [ ] `## Tests` — tabla con test file, type, coverage
- [ ] `## Notes` _(opcional)_ — no causa fail si ausente
- [ ] `## Verification Instructions` _(opcional)_ — no causa fail si ausente

**Validación extra:**
- Al menos 1 archivo modificado
- Al menos 1 test file listado
- Si hay desviación del design, debe haber `Reason for deviation`

### Verify

**Archivo esperado:** `sdd/{project}/{feature}/verification.md`

**Secciones requeridas:**
- [ ] `## Spec Compliance` — checklist con requirements
- [ ] `## Acceptance Criteria` — checklist con criterios del spec
- [ ] `## Code Quality` — checklist
- [ ] `## Security` — checklist
- [ ] `## Integration` — checklist
- [ ] `## Final Verdict` — ✅ o ❌ con rationale
- [ ] `## Issues Found` _(opcional)_ — no causa fail si ausente

**Validación extra:**
- Cada checklist debe tener al menos 1 item con ✅ o ❌
- Final Verdict debe ser explícito (✅ Aprobado / ❌ Rechazado)

### PR Review (post-Verify, antes de Archive)

**NO NEGOCIABLE:** Esta fase no se delega. Lucy maneja el feedback directo.

**Validación de feedback de Camilo:**
1. Leer comments de la PR (Lucy lo hace manual)
2. Clasificar cada comment:
   - **Minor** → fix directo sin re-delegar
   - **Moderate** → Tasks → Apply → Verify (delegado)
   - **Major** → Spec → Design → Tasks → Apply → Verify (ciclo completo)
3. Proponer clasificación a Camilo antes de actuar
4. Documentar cada comment resuelto en ARCHIVE.md

**Condición para Archive:**
- [ ] PR mergeada en main/develop, O
- [ ] Camilo decide explícitamente cerrar el ciclo (con rationale en state.json)

---

## Formato de Reporte de Validación

Cuando Lucy valida y encuentra problemas:

```
### Validación: {phase}
- [✅] Output file exists
- [❌] Missing sections: {list}
- [✅] All sections have content
- [❌] Phase-specific: {detail}
→ **FAIL** — retry #{n}/3
```

Cuando pasa:

```
### Validación: {phase}
- [✅] Output file exists
- [✅] All required sections present
- [✅] All sections have content
- [✅] Phase-specific checks pass
→ **PASS**
```
