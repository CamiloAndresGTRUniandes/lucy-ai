# SDD Orchestrator — Task String Format

## Propósito

Define la estructura canónica que Lucy usa para ensamblar el `task` parameter al spawnear un sub-agente.

Cada sub-agente recibe un task string autónomo que contiene TODO lo que necesita saber.

---

## Template Canónico

```
## SDD Phase: {phase}

### Model: {model}
### Thinking: high
### Context: {context}

### Project
- Name: {project}
- Feature: {feature}

### Standards
- {standard 1} — relevantes para esta fase
- {standard 2}

### Read these inputs:
{sdd/{project}/{feature}/input.md} — outputs de fases previas

### Follow this template:
{full template markdown inline — TODO el contenido del .md.in}

### Write your output to:
{sdd/{project}/{feature}/output.md}

### Output validation rules:
- Each section below must be present and non-empty:
  • {section 1}
  • {section 2}

### Key decisions from previous phases:
{en fork context: incluir decisiones clave de fases anteriores}
{en isolated: contexto suficiente con los inputs}

### Constraints:
- NO hacer git commits
- NO spawnear sub-agentes
- Trabajar solo en los archivos indicados
- Seguir las convenciones del proyecto indicadas en Standards
```

---

## Ejemplo: Task para Spec

```
## SDD Phase: spec

### Model: deepseek/deepseek-v4-flash
### Thinking: high
### Context: isolated

### Project
- Name: zenticalab
- Feature: inventory-alerts-v2

### Standards
- C# .NET: Clean Architecture, SOLID, DRY
- FluentValidation for DTOs

### Read these inputs:
- Proposal discussion (above in this message)

### Follow this template:
# Spec: Inventory Alerts V2
## Status: Draft
## Context
- Problem: ...
- Business value: ...
...

### Write your output to:
sdd/zenticalab/inventory-alerts-v2/spec.md

### Output validation rules:
- Required sections: Context, Requirements, User Scenarios, Acceptance Criteria

### Constraints:
- NO hacer git commits
- NO spawnear sub-agentes
- Escribir en el archivo de output exactamente como se indica
```

---

## Variables por Fase

| Fase | Model | Context | Template | Input |
|------|-------|---------|----------|-------|
| Spec | Flash | isolated | spec.md.in | Propose discussion |
| Design | Pro | fork | design.md.in | spec.md |
| Tasks | Flash | isolated | tasks.md.in | spec.md, design.md |
| Apply | Pro | isolated | apply.md.in | spec.md, design.md, tasks.md |
| Verify | Flash | isolated | verify.md.in | spec.md, design.md, tasks.md, apply output |

---

## Reglas de Ensamblaje

1. **Todo task string empieza con "## SDD Phase:"** — es lo primero que ve el sub-agente
2. **El template se inyecta COMPLETO** — no references, no shortcuts
3. **Los inputs se listan siempre como paths absolutos** — el sub-agente los lee con `read`
4. **Los outputs se listan como paths absolutos** — el sub-agente los escribe con `write`
5. **Las validation rules se incluyen** — para que el sub-agente pueda auto-verificar su output
6. **Constraints son obligatorias** — no se asume nada
