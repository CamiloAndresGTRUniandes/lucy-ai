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

### Technical Skills to Load

| Phase | Skills |
|-------|--------|
| Explore | `sdd` |
| Spec | — (no technical skills needed) |
| Design | `csharp-dotnet`, `dotnet10-csharp14` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Tasks | — (no technical skills needed) |
| Apply | `csharp-dotnet`, `dotnet10-csharp14`, `zenticalab-security` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Verify | `zenticalab-security`, `zenticalab-pr-review` |

### Pre-loaded Engram Context (si aplica)
{bloque de contexto ensamblado desde Engram en Step 0 del orchestrator-flow.md}
{incluye: sesiones recientes, decisiones de arquitectura, patrones}
{si es primer ciclo: instrucción de Context Collector}

### Key Context from Prior Sessions (Spec phase)
{resúmenes de sesiones recientes del proyecto cargados vía engram__mem_context}

### Architectural Context from Engram (Design phase)
{decisiones de arquitectura previas con observation IDs y patrones establecidos}

### Architectural Constraints from Engram (Apply phase)
{constraints arquitectónicos del proyecto cargados vía engram__mem_search}

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

| Fase | Model | Context | Template | Input | Engram Context Injection | Skills |
|------|-------|---------|----------|-------|--------------------------|--------|
| Explore | Según AGENTS.md | isolated | explore.md.in | Pre-loaded Engram Context Block | `## Pre-loaded Engram Context` | `sdd` |
| Spec | Según AGENTS.md | isolated | spec.md.in | Propose discussion | `## Key Context from Prior Sessions` | — (no technical skills needed) |
| Design | Según AGENTS.md | fork | design.md.in | spec.md | `## Architectural Context (from Engram)` | `csharp-dotnet`, `dotnet10-csharp14` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Tasks | Según AGENTS.md | isolated | tasks.md.in | spec.md, design.md | — (no requiere) | — (no technical skills needed) |
| Apply | Según AGENTS.md | isolated | apply.md.in | spec.md, design.md, tasks.md | `## Architectural Constraints (from Engram)` | `csharp-dotnet`, `dotnet10-csharp14`, `zenticalab-security` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Verify | Según AGENTS.md | isolated | verify.md.in | spec.md, design.md, tasks.md, apply output | — (no requiere) | `zenticalab-security`, `zenticalab-pr-review` |

**Nota:** La asignación exacta de modelo por fase se define exclusivamente en `AGENTS.md` § SDD Model Configuration. El modelo varía según proveedor primario y fallback. Ver `sdd/orchestrator-flow.md` para el flujo completo incluyendo Pre-flight (Step 0) y Memory Prep.

---

## Reglas de Ensamblaje

1. **Todo task string empieza con "## SDD Phase:"** — es lo primero que ve el sub-agente
2. **El template se inyecta COMPLETO** — no references, no shortcuts
3. **Los inputs se listan siempre como paths relativos a la raíz del workspace** — por ejemplo `sdd/{project}/{feature}/input.md`; el sub-agente los lee con `read`
4. **Los outputs se listan como paths relativos a la raíz del workspace** — por ejemplo `sdd/{project}/{feature}/output.md`; el sub-agente los escribe con `write`
5. **Excepción:** En el contexto fork de Design, Lucy resuelve los paths relativos al workspace antes de pasarlos al sub-agente
6. **Las validation rules se incluyen** — para que el sub-agente pueda auto-verificar su output
7. **Constraints son obligatorias** — no se asume nada
