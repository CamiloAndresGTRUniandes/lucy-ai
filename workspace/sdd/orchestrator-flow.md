# SDD Orchestrator — Flow de Orquestación

## Propósito

Guía paso a paso para que Lucy ejecute un ciclo SDD completo delegando fases a sub-agentes.

---

## Anatomía de un Spawn

### Parámetros base

```json
{
  "task": "## SDD Phase: {phase}\n... (task string armado con task-string-format.md)",
  "label": "sdd-{project}-{phase}-{attempt}",
  "model": "{según tabla SDD}",
  "thinking": "high",
  "context": "isolated" | "fork",
  "runTimeoutSeconds": 300
}
```

### Fases que delegar, fases que no

| Fase | Delegar? | Modelo | Contexto |
|------|----------|--------|----------|
| Explore | **Sí** | Flash | isolated |
| Propose | **No, Lucy directo** | Pro | — |
| Spec | **Sí** | Flash | isolated |
| Design | **Sí** | Pro | **fork** |
| Tasks | **Sí** | Flash | isolated |
| Apply | **Sí** | Pro | isolated |
| Verify | **Sí** | Flash | isolated |
| Archive | **No, Lucy directo** | Flash | — |

---

## Step-by-Step por Fase

### 1. Explore (delegado)

**Trigger:** Camilo dice "explora X" o inicia un SDD cycle.

**Lucy hace:**
1. Crea directorio `sdd/{project}/{feature}/`
2. Escribe `state.json` inicial
3. Ensambla task string desde `sdd/task-string-format.md` y template `explore.md.in` (no existe como template fijo — es libre)
4. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-flash
   context: isolated
   label: sdd-{project}-explore-1
   ```
5. Yield / espera
6. **Valida output** según `sdd/validation-rules.md`
7. Si PASS → actualiza state.json y reporta a Camilo
8. Si FAIL → retry (hasta 3)

### 2. Propose (Lucy directo)

**Trigger:** Explore completado.

**Lucy hace:**
1. Presenta findings + 2-3 approaches con trade-offs + recomendación
2. Pregunta a Camilo: "¿Cuál es el problema?", "¿Constraints?", "¿Qué pasa si no lo hacemos?"
3. Espera decisión de Camilo
4. Actualiza state.json

### 3. Spec (delegado)

**Trigger:** Camilo aprueba Propose.

**Lucy hace:**
1. Lee template `sdd/templates/spec.md.in`
2. Ensambla task string con: inputs (Propose discussion), template completo, validation rules
3. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-flash
   context: isolated
   label: sdd-{project}-spec-1
   ```
4. Yield / espera
5. **Valida output** según validation-rules.md
6. Si PASS → actualiza state, presenta a Camilo para revisión
7. Si FAIL → retry
8. **Espera aprobación explícita de Camilo** antes de continuar

### 4. Design (delegado)

**Trigger:** Camilo aprueba Spec.

**Lucy hace:**
1. Lee template `sdd/templates/design.md.in`
2. Ensambla task string: inputs (spec.md), template, validation rules
3. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-pro
   context: fork   ← HEREDA el transcript para tener contexto de fases previas
   label: sdd-{project}-design-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo
7. Si FAIL → retry
8. **Espera aprobación explícita de Camilo** antes de continuar

### 5. Tasks (delegado)

**Trigger:** Camilo aprueba Design.

**Lucy hace:**
1. Lee template `sdd/templates/tasks.md.in`
2. Ensambla task string: inputs (spec.md, design.md), template, validation
3. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-flash
   context: isolated
   label: sdd-{project}-tasks-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo para revisión
7. Si FAIL → retry

### 6. Apply (delegado)

**Trigger:** Tasks listo.

**Lucy hace:**
1. Lee template `sdd/templates/apply.md.in`
2. Ensambla task string: inputs (spec.md, design.md, tasks.md), template, validation, skills
3. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-pro
   context: isolated
   label: sdd-{project}-apply-1
   ```
4. Yield / espera
5. **Valida output** — especialmente que el código existe y los tests están escritos
6. Si PASS → presenta diff/output a Camilo para revisión conjunta
7. Si FAIL → retry

**Nota:** Los sub-agentes NO comitean. Lucy revisa con Camilo y solo entonces hace commit via PR.

### 7. Verify (delegado)

**Trigger:** Apply completado.

**Lucy hace:**
1. Lee template `sdd/templates/verify.md.in`
2. Ensambla task string: inputs (spec.md, design.md, apply output), template, validation
3. Spawnea sub-agente:
   ```
   model: deepseek/deepseek-v4-flash
   context: isolated
   label: sdd-{project}-verify-1
   ```
4. Yield / espera
5. **Valida output**
6. Si PASS → presenta a Camilo
7. Si FAIL → informe de issues encontrados

### 8. Archive (Lucy directo)

**Trigger:** Verify aprobado.

**Lucy hace:**
1. Mueve `sdd/{project}/{feature}/` → `sdd/{project}/{feature-dd/MM/YYYY}/`
2. Actualiza `state.json` → `status: completed`
3. Escribe resumen en `memory/YYYY-MM-DD-{project}-{feature}.md`
4. Presenta resumen final a Camilo
5. Pregunta: "¿Archivamos y pasamos al próximo feature?"

---

## Manejo de Errores

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

- [ ] Crear `sdd/{project}/{feature}/` directory
- [ ] Crear `state.json` con estado inicial
- [ ] Verificar que todos los templates existen en `sdd/templates/`
- [ ] Arrancar con la fase correcta según el estado
- [ ] Si es nuevo ciclo: empezar por Explore → Propose
