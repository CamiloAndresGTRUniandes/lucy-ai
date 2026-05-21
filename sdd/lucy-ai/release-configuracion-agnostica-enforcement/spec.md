# Spec: Release Configuración Agnostica + Enforcement

## Status: Draft

## Context

- **Problem:** Los templates del installer lucy-ai (workspace/AGENTS.md, workspace/TOOLS.md, config/agent-fragment.json5) están desactualizados respecto al workspace live que Lucy usa actualmente. Los templates contienen contenido específico de ZENTICALAB, carecen de la sección de reglas no negociables, no incluyen MEMORY.md como template, el config fragment no tiene agents.list[] ni bootstrap limits, no existe un hook pre-commit que proteja archivos locked, y los docs del orquestador SDD todavía describen spawn basado en modelo en vez de agentId. Este drift entre templates y runtime genera inconsistencia en instalaciones fresh y obliga a parches manuales post-instalación.

- **Business value:** Alinear los templates con el workspace live elimina el drift y garantiza que cualquier instalación fresh de lucy-ai produzca un workspace funcional, agnóstico, con enforcement de archivos locked y con la configuración SDD correcta desde el primer momento. Esto reduce fricción en nuevos proyectos, elimina la necesidad de sanitización post-instalación, y establece una base sólida para contribuciones externas.

- **Constraints:**
  - No se puede modificar el comportamiento del runtime OpenClaw — solo los templates que el installer entrega
  - El installer debe seguir siendo un solo script bash, idempotente, portable, sin compilación
  - No se pueden hardcodear secrets, tokens, ni referencias a repositorios específicos en los templates
  - El hook pre-commit debe funcionar sin dependencias externas (solo git + bash)
  - backward compatibility: installs existentes no deben romperse con update.sh
  - Ramas protegidas: main + clone — nunca push directo

- **Assumptions:**
  - El workspace live de Lucy (`/home/node/.openclaw/workspace/`) es la referencia correcta para los templates
  - `config/agent-fragment.json5` será el single source of truth para perfiles SDD, reemplazando la personalización vía TUI
  - El hook pre-commit se materializará desde un source file trackeado (no desde .git/hooks/ directamente)
  - La rama `clone` recibirá los mismos cambios via merge o cherry-pick después del PR a main
  - El TUI wizard de modelos SDD será simplificado o eliminado porque la configuración ahora vive en el fragment
  - `docs/STANDARDS.md` será incluido en el tracking de git en este mismo release

## Requirements

### Functional

| ID | Category | Requirement |
|----|----------|-------------|
| F1 | AGENTS.md | Reemplazar `workspace/AGENTS.md` con el contenido agnóstico del LIVE, incluyendo reglas no negociables, content boundaries, phase-gate protocol y agentId-based spawning |
| F2 | TOOLS.md | Reemplazar `workspace/TOOLS.md` con versión agnóstica, eliminando todo contenido específico de ZENTICALAB y agregando CONTENT LOCK section |
| F3 | MEMORY.md | Crear `workspace/MEMORY.md` como template sanitizado (estructura y guía, sin datos personales ni historial de proyectos) |
| F4 | Config Fragment | Expandir `config/agent-fragment.json5` para incluir: agents.defaults (model, thinking, bootstrap limits, timeout, skills), agents.list[] con 9 perfiles SDD, y Engram MCP |
| F5 | Pre-commit Hook | Agregar source trackeado para hook pre-commit (e.g., `scripts/install-pre-commit-hook.sh` o `hooks/pre-commit.sh`) que materialice el hook en `.git/hooks/pre-commit` y bloquee commits con contenido project-specific en archivos locked (AGENTS.md, TOOLS.md) |
| F6 | Installer Update | Actualizar `install.sh` para: eliminar dependencia de sentinels `<!-- SDD_TABLE_* -->` en AGENTS.md, integrar instalación del hook pre-commit si el usuario elige modo contributor, y alinear TUI con la nueva realidad de perfiles fijos vía agentId |
| F7 | Orchestrator Docs | Actualizar `sdd/orchestrator-flow.md` para usar agentId en lugar de model en spawn anatomy, agregar paso explícito de carga de STANDARDS.md antes de task assembly |
| F8 | Standards.md Template | Crear `sdd/templates/standards.md.in` como template reutilizable para project standards en nuevos proyectos |
| F9 | Standards Tracking | Agregar `docs/STANDARDS.md` al tracking de git (actualmente untracked) y actualizar su file structure tree para reflejar nuevos archivos |
| F10 | README Update | Actualizar `README.md` para documentar: (a) la nueva configuración agnóstica y sus ventajas, (b) por qué la configuración SDD ahora vive en `openclaw.json` vía `config/agent-fragment.json5`, (c) el sistema de enforcement de content boundaries y qué protege

### Non-Functional

| ID | Category | Requirement |
|----|----------|-------------|
| NF1 | Backward Compatibility | El release no debe romper install.sh, update.sh, ni verify.sh existentes — todas las rutas de instalación existentes deben seguir funcionando |
| NF2 | Security | El hook pre-commit debe inspeccionar el diff de archivos locked (AGENTS.md, TOOLS.md) y rechazar commits que introduzcan referencias a proyectos específicos (nombres de repos, paths absolutos a /workspace/repos/{project}/, etc.) |
| NF3 | Idempotency | Todos los templates deben ser seguros para aplicar múltiples veces sin efectos secundarios — install.sh con --force debe reemplazar archivos limpiamente |
| NF4 | Portability | El hook pre-commit y el installer deben funcionar en Linux y macOS con bash 4+ y git, sin dependencias externas |
| NF5 | Verifiability | Debe existir un mecanismo (verify.sh o script separado) que valide que los templates agnósticos no contengan referencias project-specific después del release |
| NF6 | Single Source of Truth | Los perfiles SDD deben definirse exclusivamente en `config/agent-fragment.json5` — ninguna otra fuente (TUI, docs, AGENTS.md) debe contener definiciones duplicadas que puedan derivar |

## User Scenarios

### Scenario 1: Fresh Install — Workspace completo y agnóstico desde el primer momento

**Given** Un usuario ejecuta `install.sh` en un entorno limpio (sin ~/.openclaw/workspace/)
**When** El installer completa su ejecución
**Then** El workspace contiene:
- AGENTS.md con reglas no negociables, content boundaries y agentId-based spawning (sin sentinels)
- TOOLS.md con CONTENT LOCK section y sin referencias a ZENTICALAB
- MEMORY.md con estructura de template sanitizado
- config/agent-fragment.json5 con agents.list[] completo (9 perfiles SDD)
- docs/STANDARDS.md trackeado en git
- sdd/orchestrator-flow.md actualizado con agentId en lugar de model
- sdd/templates/standards.md.in como nuevo template
- install.sh sin dependencia de sentinels

### Scenario 2: Clone Install — Workspace funcional desde rama clone

**Given** Un usuario hace fork del repo desde la rama `clone` y ejecuta `install.sh`
**When** El installer completa su ejecución
**Then** El workspace es funcional e idéntico en estructura al de una instalación desde `main`
- Todos los templates son agnósticos (sin referencias a CamiloAndresGTRUniandes ni ZENTICALAB)
- El config fragment contiene defaults configurable (user puede sobreescribir agents.defaults.model si desea)
- El hook pre-commit está disponible para instalación opcional

### Scenario 3: Update desde v1.6.3 — Migración limpia sin romper configuración existente

**Given** Un usuario con lucy-ai v1.6.3 instalado ejecuta `update.sh` (o `install.sh` sobre instalación existente)
**When** El installer procesa los nuevos templates
**Then**
- AGENTS.md se actualiza al nuevo formato (pierde sentinels, gana non-negotiable rules y content boundaries)
- TOOLS.md se sanitiza (pierde referencias ZENTICALAB)
- MEMORY.md se crea si no existe (no se sobreescribe si el usuario ya tiene contenido personal)
- config/agent-fragment.json5 se expande con agents.list[] (merged, no overwrite ciego)
- El installer existente no se rompe (mismas flags, mismos entrypoints)
- verify.sh pasa exitosamente después del update

### Scenario 4: Contributor Workflow — Pre-commit hook bloquea contenido project-specific

**Given** Un contributor clona el repo, ejecuta `scripts/install-pre-commit-hook.sh` (o `install.sh --contributor`), y el hook se materializa en `.git/hooks/pre-commit`
**When** El contributor intenta hacer commit con un cambio en `workspace/AGENTS.md` que incluye `ZENTICALAB` o cualquier referencia project-specific
**Then** El hook pre-commit rechaza el commit con un mensaje claro indicando qué archivo(s) y qué línea(s) violan la política de archivos locked, y el contributor debe sanitizar antes de reintentar

## Out of Scope

- ❌ Rediseño completo del TUI wizard (solo alineación mínima para reflejar perfiles fijos)
- ❌ Cambios en README.md → **Ahora IN-SCOPE** por solicitud de Camilo: documentar mejora agnóstica, ventajas del enforcement, y explicar config en openclaw.json
- ❌ Actualización de update.sh o uninstall.sh (solo si es necesario para no romper el flujo existente)
- ❌ Migración de datos de workspace existentes (no se toca el contenido live del usuario)
- ❌ Internacionalización o soporte multi-lenguaje
- ❌ Tests automatizados para el hook pre-commit más allá de validación manual
- ❌ Documentación de migración para usuarios de v1.6.3 (el update debe ser transparente)

## Acceptance Criteria

- [ ] **AC1:** `workspace/AGENTS.md` template reemplazado con versión agnóstica que incluya: (a) ⛔ NON-NEGOTIABLE RULES section, (b) content boundary policy, (c) phase-gate protocol, (d) agentId-based spawn instructions, (e) sin sentinels `<!-- SDD_TABLE_* -->`
- [ ] **AC2:** `workspace/TOOLS.md` template sanitizado sin referencias a ZENTICALAB, ningún project standards block, y con CONTENT LOCK section presente
- [ ] **AC3:** `workspace/MEMORY.md` creado como template sanitizado con estructura y guía — sin datos personales, fechas reales, historial de proyectos, ni referencias a Camilo
- [ ] **AC4:** `config/agent-fragment.json5` expandido con: (a) agents.defaults (model, thinking, timeout, bootstrap limits, skills allowlist), (b) agents.list[] con mínimo 9 perfiles (main + sdd-explore/propose/spec/design/tasks/apply/verify/archive), (c) Engram MCP block preservado
- [ ] **AC5:** Hook pre-commit implementado como source trackeado (e.g., `scripts/install-pre-commit-hook.sh`) que se materializa en `.git/hooks/pre-commit` y rechaza commits con contenido project-specific en AGENTS.md y TOOLS.md mediante inspección del diff
- [ ] **AC6:** `install.sh` actualizado: (a) sin dependencia de sentinels en AGENTS.md, (b) con opción `--contributor` o similar para instalar hook pre-commit, (c) TUI alineado con perfiles fijos sin ofrecer personalización de modelos SDD (o delegando al config fragment)
- [ ] **AC7:** `sdd/orchestrator-flow.md` actualizado: todos los spawn examples usan `agentId` en lugar de `"model": ...`, con paso explícito de carga de STANDARDS.md antes de task assembly
- [ ] **AC8:** `sdd/templates/standards.md.in` creado como template reutilizable para project standards en nuevos proyectos
- [ ] **AC9:** `docs/STANDARDS.md` trackeado en git con file structure tree actualizado que incluya MEMORY.md, scripts/hooks, y sdd/templates/standards.md.in
- [ ] **AC10:** `verify.sh` o script de validación de templates (e.g., `scripts/verify-agnostic.sh`) corre sin errores y verifica que ningún template en `workspace/` contenga referencias a nombres de proyectos específicos (ZENTICALAB, excel-pipeline, etc.)
- [ ] **AC11:** Version bump a v1.7.0 en install.sh y docs relevantes
- [ ] **AC12:** Todos los cambios pasan por PR con reviewer asignado (`camiloandresgtruniandes`) — sin push directo a main o clone
- [ ] **AC13:** `README.md` actualizado con sección que documente: (a) qué es la configuración agnóstica, (b) cómo `config/agent-fragment.json5` alimenta `openclaw.json` con perfiles SDD fijos, (c) qué son los content boundaries y qué archivos protege el hook pre-commit
