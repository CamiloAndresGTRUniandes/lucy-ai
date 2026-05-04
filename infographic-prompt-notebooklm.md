# NotebookLM Prompt: Infografía lucy-agent v1.5.0

Genera una infografía de una sola página que explique visualmente qué es lucy-agent, cómo funciona, y qué trae su primera release pública v1.5.0. La infografía debe ser clara, moderna, profesional, y apta para publicar en Instagram, LinkedIn y X.

---

## Estilo Visual

- **Paleta:** Fondo oscuro (#0D1117), texto blanco/verde neón (#00C853), acentos en cian (#30A0FF) para DeepSeek, naranja (#FF6B00) para OpenAI Codex, morado (#8B5CF6) para GitHub Copilot.
- **Tipografía:** Sans-serif limpia (Inter, SF Mono para código).
- **Tono:** Profesional con personalidad. No corporativo frío — cálido, "AI colleague" vibe.
- **Formato:** Vertical (1080×1920 para stories) o apaisado (1920×1080 para posts). Preferiblemente ambos.

---

## Estructura de la Infografía (de arriba hacia abajo)

### 1. HEADER — 15% superior
- **Logo ASCII de LUCY** (5 líneas, bloque):
```
  #       #   #     ###     #   #
  #       #   #    #        # #
  #       #   #    #         #
  #       #   #    #         #
  #####    ###      ###      #
```
- **Tagline:** "Your AI colleague, deployed like your code."
- **Badge:** "🦁 v1.5.0 · Primera Release Pública · MIT"
- **Subtítulo:** "Un ecosistema instalable para OpenClaw con personalidad, skills multi-provider, memoria técnica y CI pipeline."

### 2. INSTALL COMMAND — 8% (franja destacada)
Un bloque de código estilizado como terminal:
```
curl -fsSL https://raw.githubusercontent.com/CamiloAndresGTRUniandes/lucy-ai/main/install.sh | bash
```
Debajo en pequeño: "30 segundos. Sin sudo. Sin dependencias externas."

### 3. ¿QUÉ ES LUCY? — 12% (3 columnas horizontales)
- **Columna 1 — 🧠 Personalidad:** SOUL.md, IDENTITY.md, AGENTS.md. Tu agente tiene carácter, valores y reglas operativas propias.
- **Columna 2 — 🛠️ Skills:** SDD workflow, PR review, Clean Architecture (.NET), TypeScript, Tailwind, C#. Más ClawHub auto-install.
- **Columna 3 — 🪶 Memoria:** Engram (FTS5, detección de conflictos, session tracking). Integración MCP nativa.

### 4. SDD ORCHESTRATOR — 20% (el corazón visual)
**Título:** "Spec-Driven Development Orchestrator"
**Subtítulo:** "8 fases. 3 providers. Cada una con el modelo óptimo."

Una **tabla visual** de 8 filas con íconos por fase:
| Fase | Provider | Modelo | Color |
|------|----------|--------|-------|
| 🔍 Explore | DeepSeek | v4-pro | Cian |
| 💡 Propose | DeepSeek | v4-pro | Cian |
| 📋 Spec | GitHub Copilot | gpt-5.4 | Morado |
| 🏗️ Design | DeepSeek | v4-pro | Cian |
| 📝 Tasks | DeepSeek | v4-flash | Cian |
| ⚡ Apply | OpenAI Codex | gpt-5.4 | Naranja |
| ✅ Verify | OpenAI Codex | gpt-5.3-codex | Naranja |
| 📦 Archive | DeepSeek | v4-flash | Cian |

Debajo un **flujo horizontal**: Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive con flechas entre cada fase y el ícono del provider debajo.

### 5. TUI WIZARD — 15%
**Título:** "🎮 TUI Wizard — Configurá todo sin editar archivos"

Una **secuencia visual de 4 pantallas dialog estilizadas** mostrando el flujo:
1. `[===== SDD Phase Configuration =====]` → ¿Usar defaults o customizar?
2. `[===== Phase 4: Design =====]` → Radiolist: DeepSeek (●) / Codex (○) / Copilot (○)
3. `[===== Component Selection =====]` → Checklist: [x] Engram [x] ClawHub [x] Workspace [ ] Force
4. `[===== Confirm Installation =====]` → Tabla resumen de 8 fases + componentes

### 6. CI PIPELINE — 12%
**Título:** "🔧 GitHub Actions CI — 5 jobs en cada PR"

5 cajas en fila horizontal (tipo pipeline):
- `[shellcheck]` → `✅ 0 warnings`
- `[bash -n]` → `✅ 5/5 scripts`
- `[shfmt]` → `✅ clean`
- `[verify.sh]` → `✅ 48/48 checks`
- `[smoke test]` → `✅ --accept-defaults`

Debajo: "Merge protection activo. Cada cambio validado antes de llegar a main."

### 7. AUTOMATION — 8%
**Título:** "🏃 Zero-Touch Automation"

Dos bloques de código lado a lado:
```
# CI/CD pipeline
curl ... | bash -s -- --clone --accept-defaults
```
```
# Force text mode
curl ... | bash -s -- --no-tui
```

### 8. CRÉDITOS Y FOOTER — 10%
**Título:** "🙏 Construido sobre hombros de gigantes"

- **gentle-ai de Alan Buscaglia (@gentlemanprogramming)** — La visión de agentes instalables y programables que inspiró la arquitectura de Lucy.
- **Engram** — Sistema de memoria técnica con FTS5 y conflict detection, del ecosistema gentleman-programming.

**Footer:**
- 🦁 lucy-agent v1.5.0 · Primera release · MIT License
- 🔗 github.com/CamiloAndresGTRUniandes/lucy-ai
- #OpenClaw #AI #DevTools #SDD #OpenSource #gentleAI #Engram

---

## Notas para generación

- Usá iconografía consistente (preferentemente emojis estilizados o iconos SVG minimalistas).
- El flujo SDD es el centro narrativo — es lo que diferencia a Lucy de otros wrappers de AI.
- La tabla de fases SDD debe ser el elemento visual más prominente después del header.
- El bloque de código del install command debe verse como una terminal real (fondo negro, prompt verde).
- Los créditos a Alan Buscaglia y Engram deben ser visibles y respetuosos, no un footnote minúsculo.
- Si generás para Instagram Stories (1080×1920), priorizá diseño vertical con scroll natural. Si es para post cuadrado (1080×1080), compactá las secciones 3-6 en 2 columnas.
- Incluí los badges: v1.5.0, MIT, OpenClaw Powered.
