# SDD Orchestrator — Flow de Orquestación

## Propósito

Guía paso a paso para que Lucy ejecute un ciclo SDD completo delegando fases a sub-agentes.

---

## Anatomía de un Spawn

### Parámetros base

```text
{
  "task": "## SDD Phase: {phase}\n... (task string armado con task-string-format.md)",
  "label": "sdd-{project}-{phase}-{attempt}",
  "model": "{según tabla SDD en AGENTS.md}",
  "thinking": "high",
  "context": "{isolated|fork}",
  "runTimeoutSeconds": 300
}
```

### ⚠️ Pre-spawn: Model Validation (OBLIGATORIO)

**ANTES de cada spawn, Lucy DEBE:**
1. Leer `AGENTS.md` § SDD Model Configuration y obtener el **modelo primario** de la fase (columna "Modelo Primario")
2. Usar ESE modelo, NO el default de sesión (`session_status`)
3. Si el primario falla (timeout/error), re-spawnear con el **fallback** indicado en la tabla
4. Notificar a Camilo qué modelo se usó (primario o fallback)

**Regla inquebrantable:** El `session_status(model=...)` de la sesión solo define el modelo de **Lucy Orchestrator**. NO afecta los modelos de sub-agentes. Cada fase tiene su propio modelo primario y fallback definidos en la tabla. No shortcuts, no defaults.

### Notificación a Camilo (OBLIGATORIO)

Cada vez que Lucy spawnea un sub-agente, DEBE informar a Camilo con:

```
Fase: {phase} → {provider/model} (thinking: {mode})
```

Ejemplo:
```
Fase: Explore → deepseek/deepseek-v4-pro (thinking: high)
Fase: Apply → openai-codex/gpt-5.4 (thinking: high)
Fase: Verify → openai-codex/gpt-5.3-codex (thinking: high)
```

Camilo necesita saber qué proveedor, modelo y thinking mode se usa en cada fase para:
- Monitorear costos (DeepSeek pay-per-token vs suscripciones $0)
- Verificar que la tabla de asignación se respeta
- Poder diagnosticar rápidamente si un provider falla

### Fases que delegar, fases que no

**Fuente de verdad para modelos:** `AGENTS.md` → sección SDD Model Configuration.
Esta tabla define solo delegación y contexto, no modelo.

| Fase | Delegar? | Contexto |
|------|----------|----------|
| Explore | **Sí** | isolated |
| Propose | **No, Lucy directo** | — |
| Spec | **Sí** | isolated |
| Design | **Sí** | **fork** |
| Tasks | **Sí** | isolated |
| Apply | **Sí** | isolated |
| Verify | **Sí** | isolated |
| PR Review | **No, Camilo human review** | — |
| Address changes | **Lucy directo** | — |
| Archive | **No, Lucy directo** | — |

---

## Step-by-Step por Fase

### 0. Pre-flight: Engram Context Assembly

**Trigger:** Camilo inicia un ciclo SDD ("SDD para X", "explora Y", "implementa Z").

**Lucy ejecuta (en orden):**
1. `engram__mem_current_project()` → detecta proyecto activo
2. `engram__mem_context(scope="project")` → carga sesiones recientes del proyecto
3. `engram__mem_search("<project>", type="architecture|decision|pattern", limit=10)` → decisiones de arquitectura del proyecto
4. `engram__mem_search("<feature keywords>", type="architecture|decision|pattern", limit=5)` → contexto específico del feature
5. Ensambla **Pre-loaded Engram Context Block**:
   - Si hay contexto → bloque markdown con sesiones recientes, decisiones top-5 con IDs, patrones
   - Si NO hay contexto → marcar `contextFound=false`, incluir instrucción de collector
6. Actualiza `state.json`:
   - `state.engram.preflight.ranAt = now()`
   - `state.engram.preflight.contextFound = true|false`
   - `state.engram.preflight.decisionCount = total encontradas`
   - `state.engram.cycleSessionId = "SDD-{feature}-{timestamp}"`

**Error handling:** Si Engram no disponible (tool error):
- Log warning en state.json: `"engram.preflight.error": "engram_unavailable"`
- Continuar en modo degradado: Explore arranca sin contexto inyectado
- Notificar a Camilo: "⚠️ Engram no disponible. Continuamos sin contexto previo."

### 1. Explore (delegado)

**Trigger:** Camilo dice "explora X" o inicia un SDD cycle.

**Lucy hace:**
1. Crea directorio `sdd/{project}/{feature}/`
2. Escribe `state.json` inicial
3. Ensambla task string desde `sdd/task-string-format.md` y template `sdd/templates/explore.md.in`
3a. Incluye `Pre-loaded Engram Context Block` como sección del task string de Explore:
   ```markdown
   ## Pre-loaded Engram Context
   (contenido del bloque ensamblado en Step 0)
   ```

   Si `contextFound=false` → el bloque incluye instrucciones de Context Collector:
   > ⚠️ No se encontró contexto previo en Engram. DEBES recoger stack, patrones, estructura del proyecto y guardarlos con `engram__mem_save(type="discovery"|"pattern")`
4. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: isolated
   label: sdd-{project}-explore-1
   ```
5. Yield / espera
6. **Valida output** según `sdd/validation-rules.md`
7. Si PASS → actualiza state.json y reporta a Camilo
7a. Si `contextFound=false` → verificar que el sub-agente guardó contexto en Engram
7b. Inicia sesión Engram para Explore:
    `engram__mem_session_start(id="SDD-{feature}-explore")`
7c. Guarda descubrimientos de Explore en Engram:
    `engram__mem_save(title="Explore: {feature}", type="discovery", content="...", session_id="SDD-{feature}-explore")`
7d. Cierra sesión Explore:
    `engram__mem_session_end(id="SDD-{feature}-explore", summary="...")`
7e. Actualiza `state.engram.observations.explore` con los IDs guardados
8. Si FAIL → retry (hasta 3)

### 2. Propose (Lucy directo)

**Trigger:** Explore completado.

**Lucy hace:**
0. Memory Prep: ejecutar `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)` para surfear prior art relacionado. Si encuentra decisiones contradictorias, surface a Camilo durante la presentación.
1. Presenta findings + 2-3 approaches con trade-offs + recomendación
2. Pregunta a Camilo: "¿Cuál es el problema?", "¿Constraints?", "¿Qué pasa si no lo hacemos?"
3. Espera decisión de Camilo
3a. Guarda dirección aprobada en Engram:
    `engram__mem_save(type="decision", topic_key="sdd-direction/<feature>", content="**What**: Dirección aprobada para {feature}\n**Why**: {rationale de Camilo}")`
3b. Actualiza `state.engram.observations.propose` con el ID guardado
4. Actualiza state.json

### 3. Spec (delegado)

**Trigger:** Camilo aprueba Propose.

**Lucy hace:**
0. Memory Prep: ejecutar `engram__mem_context(scope="project")` para cargar resúmenes de sesiones recientes del proyecto.
1. Lee template `sdd/templates/spec.md.in`
2. Ensambla task string con: inputs (Propose discussion), template completo, validation rules

   ```markdown
   ## Key Context from Prior Sessions
   (resúmenes de sesiones recientes del proyecto)
   ```
3. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: isolated
   label: sdd-{project}-spec-1
   ```
4. Yield / espera
5. **Valida output** según validation-rules.md
6. Si PASS → actualiza state, presenta a Camilo para revisión
7. Si FAIL → retry
8. **Espera aprobación explícita de Camilo** antes de continuar
8a. Inicia sesión Engram: `engram__mem_session_start(id="SDD-{feature}-spec")`
8b. Guarda summary de Spec: `engram__mem_save(type="discovery", title="Spec: {feature}", content="...", session_id="SDD-{feature}-spec")`
8c. Cierra sesión: `engram__mem_session_end(id="SDD-{feature}-spec", summary="...")`
8d. Actualiza `state.engram.observations.spec`

### 4. Design (delegado)

**Trigger:** Camilo aprueba Spec.

**Lucy hace:**
0. Memory Prep:
   a. `engram__mem_context(scope="project")` → sesiones recientes
   b. `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)` → decisiones previas
1. Lee template `sdd/templates/design.md.in`
2. Ensambla task string: inputs (spec.md), template, validation rules

   ```markdown
   ## Architectural Context (from Engram)
   (decisiones de arquitectura previas con observation IDs y patrones establecidos)
   ```
3. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: fork   ← HEREDA el transcript para tener contexto de fases previas
   label: sdd-{project}-design-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo
7. Si FAIL → retry
8. **Espera aprobación explícita de Camilo** antes de continuar
8a. Inicia sesión Engram: `engram__mem_session_start(id="SDD-{feature}-design")`
8b. Para CADA decisión de arquitectura en el `design.md` aprobado:
    - `engram__mem_suggest_topic_key(type="architecture", title="<decisión>")` → `topic_key`
    - `engram__mem_save(type="architecture", topic_key="architecture/<slug>", content="**What**: ...\n**Why**: ...\n**Where**: ...", session_id="SDD-{feature}-design")`
    - Si `judgment_required: true` → surface candidates a Camilo ANTES de continuar
8c. Si algún save falla → reintentar 1 vez, si sigue fallando → escalar a Camilo
8d. Cierra sesión: `engram__mem_session_end(id="SDD-{feature}-design", summary="...")`
8e. Actualiza `state.engram.observations.design` con los IDs guardados

### 5. Tasks (delegado)

**Trigger:** Camilo aprueba Design.

**Lucy hace:**
1. Lee template `sdd/templates/tasks.md.in`
2. Ensambla task string: inputs (spec.md, design.md), template, validation
3. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: isolated
   label: sdd-{project}-tasks-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo para revisión
6a. Inicia sesión Engram: `engram__mem_session_start(id="SDD-{feature}-tasks")`
6b. Si hay patrones reutilizables o estructura novedosa:
    `engram__mem_save(type="pattern", title="Task structure: {feature}", content="...", session_id="SDD-{feature}-tasks")`
6c. Cierra sesión: `engram__mem_session_end(id="SDD-{feature}-tasks", summary="...")`
6d. Actualiza `state.engram.observations.tasks`
7. Si FAIL → retry

### 6. Apply (delegado)

**Trigger:** Tasks listo.

**Lucy hace:**
0. Memory Prep:
   a. `engram__mem_context(scope="project")` → sesiones recientes
   b. `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)`
1. Lee template `sdd/templates/apply.md.in`
2. Ensambla task string: inputs (spec.md, design.md, tasks.md), template, validation, skills

   ```markdown
   ## Architectural Constraints (from Engram)
   (constraints arquitectónicos del proyecto)
   ```
3. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: isolated
   label: sdd-{project}-apply-1
   ```
4. Yield / espera
5. **Valida output** — especialmente que el código existe y los tests están escritos
6. Si PASS → presenta diff/output a Camilo para revisión conjunta
6a. Inicia sesión Engram: `engram__mem_session_start(id="SDD-{feature}-apply")`
6b. Guarda descubrimientos no previstos: `engram__mem_save(type="discovery", content="...", session_id="SDD-{feature}-apply")`
6c. Si hubo desviación del Design, guardar rationale:
    `engram__mem_save(type="decision", topic_key="deviation/<feature>", content="...", session_id="SDD-{feature}-apply")`
6d. Cierra sesión: `engram__mem_session_end(id="SDD-{feature}-apply", summary="...")`
6e. Actualiza `state.engram.observations.apply`
7. Si FAIL → retry

**Nota:** Los sub-agentes NO comitean. Lucy revisa con Camilo, crea branch, commit, push y PR. Esto dispara la fase PR Review.

### 7. Verify (delegado)

**Trigger:** Apply completado y revisado con Camilo.

**Lucy hace:**
1. Lee template `sdd/templates/verify.md.in`
2. Ensambla task string: inputs (spec.md, design.md, apply output), template, validation
3. Spawnea sub-agente:
   ```
   model: según tabla en AGENTS.md § SDD Model Configuration
   context: isolated
   label: sdd-{project}-verify-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo
6a. Inicia sesión Engram: `engram__mem_session_start(id="SDD-{feature}-verify")`
6b. Guarda veredicto: `engram__mem_save(type="decision", title="Verify: {feature}", content="**What**: Verification result\n**Why**: PASS/FAIL + rationale", session_id="SDD-{feature}-verify")`
6c. Cierra sesión: `engram__mem_session_end(id="SDD-{feature}-verify", summary="...")`
6d. Actualiza `state.engram.observations.verify`
7. Si FAIL → informe de issues encontrados

---

### 7.5 PR Review and Address Changes (NO NEGOCIABLE)

**Trigger:** Verify aprobado → PR creado → Camilo review.

La review de la PR es parte del SDD cycle. **No se archive hasta que el PR está mergeado o Camilo decide cerrarlo.**

#### Flujo de feedback

```
Verify → Lucy crea PR → Camilo review
                                ↓
               ┌────────────────┤
               ↓                ↓
         ¿Cambios?          ¿Approved?
               │                │
               Sí                Sí
               ↓                 ↓
      ┌────────┤          Archive (PR mergeado)
      │        │
  ¿Alcance?    │
      │        │
  Minor ───── Apply fix → Re-verify
      │        │
      ↓        ↓
  Moderate ── Tasks → Apply → Verify
      │
      ↓
  Major ── Spec → Design → Tasks → Apply → Verify
```

#### Reglas de clasificación:

| Tipo de cambio | Ejemplo | Ruta |
|---------------|---------|------|
| **Minor** | Typos, naming, error msg, log level | Apply fix → Re-verify → Archive |
| **Moderate** | Nueva variable/constante, cambio de validación | Tasks → Apply → Verify |
| **Major** | Cambio de comportamiento, nuevo endpoint | Spec → Design → Tasks → Apply → Verify |

**Lucy clasifica y presenta a Camilo:**

> "Camilo, tus comments son minor (3 typos) y moderate (1 validation change).
> Minor los resuelvo directo, moderate entra como T1 nuevo. ¿Dale?"

**NO NEGOCIABLE:** Archive solo ocurre cuando:
- PR mergeado, O
- Camilo decide explícitamente cerrar el ciclo sin merge (con rationale documentado)

### 8. Archive (Lucy directo)

**Trigger:** PR mergeado O Camilo decide cerrar ciclo explícitamente.

**Lucy hace:**
1. **Engram session summary del ciclo completo:**
   `engram__mem_session_summary(session_id=state.engram.cycleSessionId, content="## Goal\n...\n## Discoveries\n...\n## Accomplished\n...\n## Relevant Files\n...")`
2. **Sincroniza decisiones finales:**
   - Itera por todas las fases en `state.engram.observations`
   - Si alguna fase tiene decisiones pendientes (no guardadas), guardarlas ahora
   - Verifica que todas las decisiones de arquitectura estén persistidas
3. Guarda decisiones finales del ciclo en `state.engram.observations.archive`
4. Mueve `sdd/{project}/{feature}/` → `sdd/{project}/{feature-YYYY-MM-DD}/`
5. Actualiza `state.json`:
   - `status: completed`
   - Verifica que el bloque `engram` esté completo con todos los observation IDs
6. Escribe resumen en `memory/YYYY-MM-DD-{project}-{feature}.md`
7. Presenta resumen final a Camilo
8. Pregunta: "¿Archivamos y pasamos al próximo feature?"

---

## Manejo de Errores

### Timeout personalizado por fase

| Fase | Timeout | Rationale |
|------|---------|-----------|
| Explore | **600s** | Pro, lectura de codebases grandes, isolated context |
| Spec | 300s | Flash, task estructurada, <5k tokens output |
| Design | **600s** | Pro, fork, requiere leer todo el transcript previo |
| Tasks | 300s | Flash, template estructurado |
| Apply | **600s** | Pro, múltiples archivos, puede incluir tests |
| Verify | 600s | Flash pero requiere leer múltiples inputs |

---

### Timeout (>5 min sin completar)

```python
if elapsed > 300:
    retry.count += 1
    if retry.count <= 3:
        spawn()  # mismo label + 1 en attempt, mismo task string exacto
    else:
        escalar_a_camilo("Fase X falló tras 3 intentos. Último error: {error}")
```

### Output inválido (validación falla)

```python
if not validation_passed:
    retry.count += 1
    if retry.count <= 3:
        feedback = "Missing sections: {sections}. Re-run with same instructions."
        spawn_feedback = task_string + f"\n\n### Previous attempt feedback:\n{feedback}"
        spawn()  # mismo label, mismo modelo, task con feedback adicional
    else:
        escalar_a_camilo(...)
```

**Importante:** En el retry, el task string es **casi** el mismo — se agrega feedback de qué secciones faltaron para guiar al sub-agente, pero no se incluye el output fallido (para no contaminar).

### Camilo no responde

```python
if camilo_no_responde:  # no hay mensaje en ~10 min
    state.status = "paused"
    state.feedback.pending = "Esperando respuesta de Camilo sobre {phase}"
    # Lucy espera. Cuando Camilo vuelve a hablar, retoma desde donde quedó.
```

---

## Multi-Proyecto

Cada proyecto tiene su propio `sdd/{project}/state.json`. Lucy mantiene la pista de cuál proyecto está activo en la conversación actual.

**Mecanismo:**
- Cuando Camilo dice "SDD para [proyecto1]", Lucy activa ese proyecto
- Si dice "SDD para [proyecto2]", Lucy pausa proyecto1, activa proyecto2
- Cada proyecto mantiene su estado independiente en su `state.json`

---

## Check-list de Inicio (para Lucy, cada nuevo ciclo)

- [ ] **Pre-flight Engram Context Assembly**
  - [ ] `engram__mem_current_project()` → detectar proyecto
  - [ ] `engram__mem_context(scope="project")` → sesiones recientes
  - [ ] `engram__mem_search("<project>", type="architecture|decision|pattern")` → decisiones previas
  - [ ] `engram__mem_search("<feature>", type="architecture|decision|pattern")` → feature-specific
  - [ ] Ensamblar Pre-loaded Engram Context Block
  - [ ] Si Engram no disponible → modo degradado (notificar a Camilo)
- [ ] Crear `sdd/{project}/{feature}/` directory
- [ ] Crear `state.json` con estado inicial
- [ ] Verificar que todos los templates existen en `sdd/templates/`
  - [ ] `spec.md.in`, `design.md.in`, `tasks.md.in`, `apply.md.in`, `verify.md.in`, `explore.md.in`
- [ ] Arrancar con la fase correcta según el estado
- [ ] Si es nuevo ciclo: empezar por Explore → Propose

### Pre-flight Validation

Lucy verifica:
- [ ] `state.engram.preflight.ranAt` no es `null`
- [ ] `state.engram.preflight.project` coincide con el proyecto activo
- [ ] Si `contextFound=true` → `Pre-loaded Engram Context Block` tiene al menos 1 observación
- [ ] Si `contextFound=false` → el task string de Explore incluye instrucción de collector

## Check-list de Finalización (Archive condicional)

- [ ] PR creado y reviewer asignado
- [ ] Camilo aprobó la PR (o decidió cerrar ciclo)
- [ ] Address changes loops completados (si hubo feedback)
- [ ] `state.json` actualizado con resultado final y PR URL
- [ ] Session summary guardado en Engram (`engram__mem_session_summary`)
- [ ] Decisiones finales sincronizadas en Engram (`state.engram.observations` completo)
- [ ] `state.json` actualizado con bloque `engram` completo
- [ ] Archive solo cuando: PR mergeado O Camilo decide cerrar

## Reglas NO NEGOCIABLES

1. **Archive es condicional al merge de PR** — No archivar hasta que PR esté mergeado o Camilo explícitamente decida cerrar.
2. **Lucy clasifica el feedback** — Decir si es minor/moderate/major y la ruta propuesta.
3. **Sin PR mergeado, no hay ciclo cerrado.**
4. **Si Camilo decide cerrar sin merge,** documentar rationale en ARCHIVE.md.
