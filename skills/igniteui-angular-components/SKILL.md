---
name: igniteui-angular-components
description: >
  Ignite UI for Angular non-grid UI components: setup, forms, layouts, feedback, data display, directives, charts, Dock/Layout/Tile managers. Trigger: when implementing or reviewing Ignite UI Angular components that are not data grids or theming.
license: MIT
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Ignite UI for Angular — UI Components

## OpenClaw Safety Adapter

This skill has been adapted for Lucy/OpenClaw.

- Do **not** automatically install npm packages, configure MCP servers, edit IDE settings, or write external configuration without Camilo's explicit approval.
- First inspect the project (`package.json`, Angular version, installed Ignite UI package variant, existing theme/config).
- If an Ignite UI MCP server/tool is already available, use it to verify current APIs. If it is unavailable, use the bundled references and say when an answer should be checked against vendor docs.
- Project `docs/STANDARDS.md`, SDD phase gates, and higher-priority workspace rules remain authoritative.
- Never put secrets, license tokens, private registry credentials, or PATs in code, docs, logs, or chat.

## Prerequisites
- Angular 20+ project
- `@angular/cli` installed
- `igniteui-angular` or `@infragistics/igniteui-angular` added to the project via `ng add igniteui-angular` (or the `@infragistics` variant) or `npm install` — see [Package Variants](#package-variants) below.
- A theme applied to the application (see [`igniteui-angular-theming`](../igniteui-angular-theming/SKILL.md)).
- `provideAnimations()` in `app.config.ts` — **required before using any overlay or animated component**
- The **Ignite UI CLI MCP server** (`igniteui-cli`) is available as a tool provider

> ## Optional Ignite UI CLI MCP Server

> **Full setup instructions for VS Code, Cursor, Claude Desktop, and JetBrains IDEs are in [`references/mcp-setup.md`](./references/mcp-setup.md).** Read that file for editor-specific configuration steps and verification.

## MANDATORY AGENT PROTOCOL — YOU MUST FOLLOW THIS BEFORE PRODUCING ANY OUTPUT

**This file is a routing hub only. It contains NO code examples and NO API details.**

> **DO NOT write any component selectors, import paths, input names, output names, or directive names from memory.**
> Component APIs change between versions. Anything generated without reading the reference files will be incorrect.

You are **required** to complete ALL of the following steps before producing any component-related code or answer:

**STEP 1 — Identify every component or feature involved.**
Map the user's request to one or more rows in the Task → Reference File table below. A single request often spans multiple categories (e.g., a form inside a Dialog requires reading both `form-controls.md` AND `feedback.md`).

**STEP 2 — Read every identified reference file in full (PARALLEL).**
Call `read` (or equivalent) on **all** reference files identified in Step 1 **preferably in a small parallel batch when independent** — do NOT read them one at a time sequentially. You must do this even if you believe you already know the answer. Do not skip, skim, or partially read a reference file.

**STEP 3 — Only then produce output.**
Base your code and explanation exclusively on what you read. If the reference files do not cover something, say so explicitly rather than guessing.

### Task → Reference File

| Task | Reference file to read |
|---|---|
| App setup, `app.config.ts` providers, `provideAnimations()`, entry-point imports, convenience directive arrays | [`references/setup.md`](./references/setup.md) |
| Input Group, Combo, Simple Combo, Select, Date Picker, Date Range Picker, Time Picker, Calendar, Checkbox, Radio, Switch, Slider, Autocomplete, reactive/template-driven forms | [`references/form-controls.md`](./references/form-controls.md) |
| Tabs, Bottom Navigation, Stepper, Accordion, Expansion Panel, Splitter, Navigation Drawer | [`references/layout.md`](./references/layout.md) |
| List, Tree, Card, Chips, Avatar, Badge, Icon, Carousel, Paginator, Progress Indicators, Chat | [`references/data-display.md`](./references/data-display.md) |
| Dialog, Snackbar, Toast, Banner | [`references/feedback.md`](./references/feedback.md) |
| Button, Icon Button, Button Group, Ripple, Tooltip, Drag and Drop | [`references/directives.md`](./references/directives.md) |
| Layout Manager (`igxLayout`, `igxFlex` directives), Dock Manager (`igc-dockmanager` web component), Tile Manager (`igc-tile-manager` web component) | [`references/layout-manager.md`](./references/layout-manager.md) |
| Charts (Area, Bar, Column, Stock/Financial, Pie), chart configuration, chart features (animation, tooltips, markers, highlighting, zooming), data binding | [`references/charts.md`](./references/charts.md) |

> **When in doubt, read more rather than fewer reference files.** The cost of an unnecessary file read is negligible; the cost of hallucinated API usage is a broken application.

---

## Package Variants

| Package | Install | Who uses it |
|---|---|---|
| `igniteui-angular` | `npm install igniteui-angular` | Open-source / community |
| `@infragistics/igniteui-angular` | Requires private `@infragistics` registry | Licensed / enterprise users |

Both packages share **identical entry-point paths**. Check `package.json` and use that package name as the prefix for every import. Never import from the root barrel of either package.
Both packages can be added to the project using `@angular/cli` with the following commands: `ng add igniteui-angular` or `ng add @infragistics/igniteui-angular`.

---

## Related Skills

- [`igniteui-angular-grids`](../igniteui-angular-grids/SKILL.md) — Data Grids (Flat Grid, Tree Grid, Hierarchical Grid, Pivot Grid, Grid Lite)
- [`igniteui-angular-theming`](../igniteui-angular-theming/SKILL.md) — Theming & Styling
