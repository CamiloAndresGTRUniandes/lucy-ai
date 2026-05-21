# Tasks: Release Configuración Agnostica + Enforcement

## Status: Draft

## Task List

- [ ] **T1: Branch preparation + track docs/STANDARDS.md**
  - **Description:** Crear feature branch `feat/release-configuracion-agnostica-enforcement` desde `main` actualizada. Agregar `docs/STANDARDS.md` al tracking de git (actualmente existe en worktree pero es untracked). Actualizar su file structure tree para reflejar los nuevos archivos que este release introduce: `workspace/MEMORY.md`, `scripts/check-content-boundaries.sh`, `scripts/install-pre-commit-hook.sh`, `sdd/templates/standards.md.in`. El tree debe coincidir con el diseño AFTER en el design.md.
  - **Input:** `design.md` (File Structure Design — AFTER tree), `docs/STANDARDS.md`, `git status` actual
  - **Output:** Feature branch creada. `docs/STANDARDS.md` modificado con tree actualizado y añadido al staging area.
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (git workflow: feature branch, no push directo a main), conventional commits (`feat:` prefix)
  - **Estimate:** 30 min

- [ ] **T2: Expandir config/agent-fragment.json5 con agents.list[] completo**
  - **Description:** Reemplazar el fragmento mínimo actual con la versión completa que incluye: `agents.defaults` (model primary `deepseek/deepseek-v4-pro`, fallbacks, `thinkingDefault: "high"`, `bootstrapMaxChars: 24000`, `bootstrapTotalMaxChars: 80000`, `timeoutSeconds: 600`, skills allowlist con 18 skills) y `agents.list[]` con 9 perfiles SDD (main, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive). Preservar el bloque MCP de Engram. NO incluir API keys, tokens, emails, ni secretos. Usar `~/.openclaw/workspace` en lugar de paths hardcodeados.
  - **Input:** `design.md` (Config Fragment Design — tabla agents.list[], agents.defaults block, Engram MCP block), `config/agent-fragment.json5` actual
  - **Output:** `config/agent-fragment.json5` reemplazado con versión completa que incluye agents.defaults + agents.list[] (9 perfiles) + MCP Engram
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (no secrets hardcodeados), JSON5 syntax, SDD model configuration table del spec
  - **Estimate:** 1 hora

- [ ] **T3: Reemplazar workspace/AGENTS.md con template agnóstico locked**
  - **Description:** Reemplazar `workspace/AGENTS.md` con versión derivada del LIVE pero sanitizada: incluir NON-NEGOTIABLE RULES al inicio, repo path rule, SDD mandatory rule, Content Boundaries section (AGENTS.md + TOOLS.md), Phase Gate Protocol, SDD model table (idéntica a `config/agent-fragment.json5`), SDD Orchestrator con agentId-based spawning, Engram/Decision Memory protocol, reglas de git y heartbeats. Eliminar: sentinels `<!-- SDD_TABLE_* -->`, cualquier referencia a ZENTICALAB/excel-pipeline/ssdp-ai/kudos-board, app-specific architecture standards, DTO/SQL/Angular rules, y paths absolutos a proyectos específicos. Mantener ejemplos con placeholders genéricos como `/workspace/repos/{project}`.
  - **Input:** `design.md` (Template Sanitization Strategy — AGENTS.md), LIVE AGENTS.md en workspace, spec.md AC1, `config/agent-fragment.json5` expandido (para que la tabla coincida)
  - **Output:** `workspace/AGENTS.md` reemplazado — sin sentinels, sin referencias project-specific, con todas las secciones locked requeridas
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (workspace file agnostic), content boundary policy, fase-gate protocol
  - **Estimate:** 1.5 horas

- [ ] **T4: Reemplazar workspace/TOOLS.md con template agnóstico locked**
  - **Description:** Reemplazar `workspace/TOOLS.md` con versión agnóstica: incluir CONTENT LOCK header, cross-project tool inventory, General OpenClaw/Gateway/Engram notes (sin secretos), repo path warning, "What goes here" section. Sanitizar sección Email (no decir que el app password está en ZENTICALAB docker-compose — usar wording genérico). Eliminar: bloque completo de ZENTICALAB Project Standards, referencias a backend/frontend paths, identities de proyectos, review checklists, commit conventions específicos. Mantener provider/model capability tables sin exponer secretos ni key fragments.
  - **Input:** `design.md` (Template Sanitization Strategy — TOOLS.md), LIVE TOOLS.md en workspace, spec.md AC2
  - **Output:** `workspace/TOOLS.md` reemplazado — sin referencias project-specific, con CONTENT LOCK, tool inventory sanitizado
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (workspace file agnostic), content boundary policy
  - **Estimate:** 1.5 horas

- [ ] **T5: Crear workspace/MEMORY.md como template sanitizado**
  - **Description:** Crear `workspace/MEMORY.md` como template estructurado con secciones vacías: Identity, Stable Preferences, Key Decisions, Projects, Lessons Learned, Do Not Forget. Incluir comentarios explicando que MEMORY.md es privado y no debe cargarse en contextos compartidos/grupales. NO copiar MEMORY.md live (que contiene historial personal de Camilo). Sin datos personales, fechas reales, project history, ni referencias a terceros.
  - **Input:** `design.md` (Template Sanitization Strategy — MEMORY.md template structure), spec.md AC3
  - **Output:** `workspace/MEMORY.md` creado con estructura de template sanitizado
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (no secrets, project-agnostic)
  - **Estimate:** 30 min

- [ ] **T6: Crear scripts de hook: check-content-boundaries + install-pre-commit-hook**
  - **Description:** Crear dos scripts bash:
    1. `scripts/check-content-boundaries.sh` — validador reutilizable con dos modos: `--staged` (inspecciona staged content via `git diff --cached` + `git show ":$file"` para partial stages) y `--worktree` (inspecciona archivos en disco). Archivos protegidos: `workspace/AGENTS.md`, `workspace/TOOLS.md`. Detecta y rechaza: nombres de proyectos (ZENTICALAB, excel-pipeline, ssdp-ai, kudos-board), project standards headings, paths absolutos a repos conocidos, repo names de CamiloAndresGTRUniandes, symlinks en archivos protegidos. Permite placeholders genéricos (`{project}`, `{repo}`). Output con file/line específico y mensaje de remediación. Salida no-zero en violación.
    2. `scripts/install-pre-commit-hook.sh` — materializa `.git/hooks/pre-commit` como wrapper que llama a `check-content-boundaries.sh --staged`. Maneja: sin hook existente (crea), hook existente que coincide (sobreescribe), hook existente que difiere (backup + warning, `--force` reemplaza). Soportar `--dry-run`.
  - **Input:** `design.md` (Pre-commit Hook Design — logic, error messages, installation mechanism), spec.md AC5
  - **Output:** `scripts/check-content-boundaries.sh` + `scripts/install-pre-commit-hook.sh` creados, ejecutables (`chmod +x`), `bash -n` válido
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (shell script standards: `#!/usr/bin/env bash`, `set -euo pipefail`, snake_case functions, UPPERCASE constants, lowercase locals), portability (bash 4+, Linux/macOS)
  - **Estimate:** 2 horas

- [ ] **T7: Actualizar install.sh — sentinel removal, TUI alignment, --contributor**
  - **Description:** Modificar `install.sh` para:
    - Version bump: `1.6.3` → `1.7.0`
    - Eliminar funciones: `tui_generate_sdd_table()`, `apply_sdd_table_to_agents_file()`, special-case AGENTS temp copy en `step_seed_workspace()`
    - `step_seed_workspace()` copiar AGENTS.md como cualquier otro markdown (sin rewriting)
    - Simplificar TUI: remover per-phase model picker screens; actualizar welcome text de "configure SDD phase models" a "review fixed SDD agent profiles and choose install components"
    - Agregar flag `--contributor` que instala el pre-commit hook
    - En modo contributor: llamar `bash "$LUCY_DIR/scripts/install-pre-commit-hook.sh"` después de workspace seeding
    - Actualizar referencias de rama: `lucy-config` → `clone`
    - `--clone` aceptado por compatibilidad pero usa `main` internamente (con mensaje deprecation warning)
    - Mantener backward compatibility: flags existentes siguen funcionando
    - Preflight validation: verificar que AGENTS.md no tenga `SDD_TABLE_START`, TOOLS.md tenga `CONTENT LOCK`, MEMORY.md exista
  - **Input:** `design.md` (Installer Changes Design — sentinel removal, TUI alignment, hook materialization, backward compat), `install.sh` actual, spec.md AC6
  - **Output:** `install.sh` modificado (v1.7.0) — sin sentinel rewriting, TUI simplificado, flag `--contributor`, branch wording actualizado
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (Bash-based installer, idempotent, portable), shell script standards
  - **Estimate:** 2 horas

- [ ] **T8: Actualizar SDD orchestrator docs + crear template standards.md.in**
  - **Description:**
    1. Modificar `sdd/orchestrator-flow.md`:
       - Reemplazar `model: "..."` con `agentId: "sdd-{phase}"` en todos los spawn examples
       - Renombrar "Model Validation" → "Agent Profile Validation"
       - Validar que el perfil existe en `agents.list[]`
       - Agregar "Project Standards Loading" como paso pre-flight obligatorio antes de task assembly (leer `{project_root}/docs/STANDARDS.md`, abortar si falta)
       - Actualizar checklist de inicio con estándares
       - Actualizar error handling: missing agent profile + missing project standards
    2. Modificar `sdd/task-string-format.md`:
       - Reemplazar `### Model: {model}` con `### Agent Profile` section (agentId, resolved model como informativo, thinking/timeout desde perfil)
    3. Crear `sdd/templates/standards.md.in` como template reutilizable para project standards en nuevos proyectos: incluir secciones Project Identity, Architecture Principles, File Structure, Commit Convention, Git Workflow, Environment & Secrets — todo con placeholders `{project_name}`, `{repo_url}`, `{reviewer}`.
  - **Input:** `design.md` (Orchestrator Docs Update Design — spawn anatomy, agentId enforcement, Project Standards Loading), `sdd/orchestrator-flow.md` actual, `sdd/task-string-format.md` actual, spec.md AC7 + AC8
  - **Output:** `sdd/orchestrator-flow.md` actualizado (agentId everywhere + standards loading), `sdd/task-string-format.md` actualizado (agentId field), `sdd/templates/standards.md.in` creado
  - **Standards:** `lucy-ai/docs/STANDARDS.md`, AGENTS.md (agentId-based spawning)
  - **Estimate:** 1.5 horas

- [ ] **T9: Sync root sdd/ → workspace/sdd/ + expandir verify.sh**
  - **Description:**
    1. Sincronizar root `sdd/` a `workspace/sdd/`: copiar archivos de documentación (`orchestrator-flow.md`, `task-string-format.md`, `validation-rules.md`) y templates (`sdd/templates/*.md.in`). Excluir `sdd/lucy-ai/**` (active cycle artifacts). Usar `rsync` o `cp` con confirmación. Verificar con `diff -qr`.
    2. Expandir `verify.sh` con nuevas secciones de chequeo:
       - Workspace agnostic checks (MEMORY.md existe, AGENTS.md tiene NON-NEGOTIABLE y no tiene SDD_TABLE, TOOLS.md tiene CONTENT LOCK y no tiene ZENTICALAB)
       - Config profile checks (agents.list con 9 profiles, bootstrap limits, Engram MCP, sin stale minimax)
       - Hook checks (scripts existen, ejecutables, `bash -n` syntax)
       - SDD docs sync checks (standards.md.in existe en root y workspace, root/workspace shipped files sin diff, orchestrator-flow.md contiene "agentId" y "Project Standards Loading")
       - README/version checks (version badge 1.7.0, mentions agnostic config + enforcement)
       - Llamar `scripts/check-content-boundaries.sh --worktree` como parte de la verificación
  - **Input:** `design.md` (Observability — verify.sh expansion, SDD docs sync resolution, Validating templates), `verify.sh` actual, root `sdd/` modificado en T8, spec.md AC10
  - **Output:** `workspace/sdd/` sincronizado. `verify.sh` expandido con todos los nuevos checks.
  - **Standards:** `lucy-ai/docs/STANDARDS.md`, shell script standards
  - **Estimate:** 1 hora

- [ ] **T10: Actualizar README.md + CHANGELOG.md + version bump**
  - **Description:**
    1. `README.md`: Agregar secciones "What's New in v1.7" (agnostic templates, fixed SDD profiles, enforcement, project standards template), "Agnostic configuration" (explicar que AGENTS/TOOLS son agnósticos, standards por proyecto en `docs/STANDARDS.md`), "Why OpenClaw config lives in openclaw.json" (config fragment + fixed profiles), "Content boundary enforcement" (locked files, pre-commit hook, beneficio), "Contributor setup" (cómo instalar hook). Actualizar: version badge, "What you get" (agregar Enforcement row + MEMORY.md), install modes (TUI ya no configura modelos), post-install (explicar $include, restart gateway), repository structure (agregar nuevos archivos), "Build your own agent" (proyect standards en project repo, no en AGENTS/TOOLS). Remover: referencias a TUI phase model customization, `lucy-config` reemplazar con `clone`, ejemplos de tag v1.6.3 → v1.7.0.
    2. `CHANGELOG.md`: Agregar entrada `[1.7.0]` con resumen de cambios (config fragment, templates agnósticos, content boundary enforcement, hook, SDD docs, README).
    3. `install.sh`: Verificar que version string ya se actualizó en T7.
  - **Input:** `design.md` (README Update Design — new sections, updated sections, remove/correct), `README.md` actual, `CHANGELOG.md` actual, spec.md AC11 + AC13
  - **Output:** `README.md` actualizado (v1.7.0 docs), `CHANGELOG.md` con entrada [1.7.0], version bump confirmado
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (commit format, release process)
  - **Estimate:** 1.5 horas

- [ ] **T11: Commit, PR, review y post-merge (tag + clone sync)**
  - **Description:**
    1. Hacer commit atómico con todos los cambios del feature branch. Usar mensaje: `feat: release v1.7.0 — configuracion agnostica + enforcement`
    2. Push feature branch a `origin`
    3. Abrir PR contra `main` con descripción completa: qué cambia, por qué, qué archivos, deployment order, breaking changes, rollback strategy. Asignar reviewer `camiloandresgtruniandes`.
    4. Esperar approval y merge.
    5. Post-merge: crear tag `v1.7.0` en `main`.
    6. Merge o cherry-pick relevant commits a `clone`. Mantener legacy `lucy-config` como alias transicional (eliminar en v1.8.0).
  - **Input:** Todos los archivos modificados en T1-T10, spec.md AC12, design.md (Post-merge activities)
  - **Output:** Branch pusheado, PR abierto, merge completado, tag v1.7.0, clone branch actualizado
  - **Standards:** `lucy-ai/docs/STANDARDS.md` (git workflow: feature branch → PR → merge → tag → clone), conventional commits, protected branches
  - **Estimate:** 30 min (sin incluir tiempo de espera de review)

## Dependencies

```
T1 (branch prep + standards tracking)
 ├── T2 (config fragment — SSOT exists before docs)
 │    ├── T3 (AGENTS.md — necesita la tabla de perfiles del fragment)
 │    ├── T4 (TOOLS.md — independiente de T3)
 │    ├── T5 (MEMORY.md — independiente de T3/T4)
 │    └── T7 (install.sh — referencia agent-fragment expandido)
 ├── T6 (hook scripts — independiente de templates)
 │    └── T7 (install.sh — necesita scripts para --contributor)
 ├── T8 (SDD docs — necesita config fragment para agentId profiles)
 │    └── T9 (sync + verify — necesita T8 para tener docs actualizadas)
 ├── T9 (verify.sh — necesita T3/T4/T5/T6/T7/T8 completos)
 ├── T10 (README/CHANGELOG — necesita todo lo anterior)
 └── T11 (PR — necesita TODO listo)

Resumen de orden:
T1 → T2 → T3+T4+T5 (paralelo) → T6 → T7 (tras T3+T4+T5+T6)
T8 → T9 (tras T8) → T10 (tras T9) → T11 (tras T10)
```

## Estimated Effort

| Task | Estimado |
|------|----------|
| T1 — Branch prep + standards tracking | 30 min |
| T2 — Expandir config fragment | 1 hora |
| T3 — Reemplazar AGENTS.md agnóstico | 1.5 horas |
| T4 — Reemplazar TOOLS.md agnóstico | 1.5 horas |
| T5 — Crear MEMORY.md template | 30 min |
| T6 — Hook scripts (check + install) | 2 horas |
| T7 — Actualizar install.sh | 2 horas |
| T8 — SDD docs + standards.md.in | 1.5 horas |
| T9 — Sync workspace/sdd + verify.sh | 1 hora |
| T10 — README + CHANGELOG + version | 1.5 horas |
| T11 — Commit, PR, post-merge | 30 min |
| **Total (implementación)** | **12.5 horas** |

**Notas:**
- T3 y T4 pueden ejecutarse en paralelo si hay suficiente contexto del workspace LIVE.
- T11 excluye tiempo de espera de revisión de PR (depende de Camilo).
- Los estimados asumen que el desarrollador tiene acceso al workspace LIVE como referencia para sanitización.
- T7 (install.sh) es la tarea más riesgosa por el impacto en backward compatibility y la necesidad de entender el flujo actual del TUI.
