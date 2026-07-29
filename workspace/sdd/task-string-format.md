# SDD Orchestrator — Task String Format

## Purpose

Defines the canonical structure Lucy uses to assemble the `task` parameter when spawning a sub-agent.

Each sub-agent receives a self-contained task string that contains EVERYTHING it needs to know.

---

## Canonical Template

```
## SDD Phase: {phase}

### Agent Profile
- agentId: sdd-{phase}
- Resolved model: {primary_model} (fallback: {fallback_model})
- Thinking: {thinking}
- Timeout: {timeoutSeconds}s

### Context: {context}

### Project
- Name: {project}
- Feature: {feature}

### Standards
- {standard 1} — relevant for this phase
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

### Pre-loaded Engram Context (if applicable)
{context block assembled from Step 0 of orchestrator-flow.md}
{includes: recent sessions, architecture decisions, patterns}
{if first cycle: Context Collector instruction}

### Key Context from Prior Sessions (Spec phase)
{recent project session summaries loaded via engram__mem_context}

### Architectural Context from Engram (Design phase)
{prior architecture decisions with observation IDs and established patterns}

### Architectural Constraints from Engram (Apply phase)
{architectural constraints of the project loaded via engram__mem_search}

### Read these inputs:
{sdd/{project}/{feature}/input.md} — outputs from prior phases

### Follow this template:
{full template markdown inline — ALL content from .md.in}

### Write your output to:
{sdd/{project}/{feature}/output.md}

### Output validation rules:
- Each section below must be present and non-empty:
  • {section 1}
  • {section 2}

### Key decisions from previous phases:
{in fork context: include key decisions from prior phases}
{in isolated: sufficient context with the inputs}

### Constraints:
- NO git commits
- NO spawning sub-agents
- Work only on the indicated files
- Follow the project conventions indicated in Standards
```

---

## Example: Task for Spec

```
## SDD Phase: spec

### Agent Profile
- agentId: sdd-spec
- Resolved model: deepseek/deepseek-v4-flash (fallback: openai-codex/gpt-5.4)
- Thinking: high
- Timeout: 900s

### Context: isolated

### Project
- Name: {project}
- Feature: {feature}

### Standards
- Project standards from {project_root}/docs/STANDARDS.md

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
- NO git commits
- NO spawning sub-agents
- Write to the output file exactly as indicated
```

---

## Variables by Phase

| Phase | agentId | Context | Template | Input | Engram Context Injection | Skills |
|------|---------|---------|----------|-------|--------------------------|--------|
| Explore | `sdd-explore` | isolated | explore.md.in | Pre-loaded Engram Context Block | `## Pre-loaded Engram Context` | `sdd` |
| Spec | `sdd-spec` | isolated | spec.md.in | Propose discussion | `## Key Context from Prior Sessions` | — (no technical skills needed) |
| Design | `sdd-design` | fork | design.md.in | spec.md | `## Architectural Context (from Engram)` | `csharp-dotnet`, `dotnet10-csharp14` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Tasks | `sdd-tasks` | isolated | tasks.md.in | spec.md, design.md | — (none) | — (no technical skills needed) |
| Apply | `sdd-apply` | isolated | apply.md.in | spec.md, design.md, tasks.md | `## Architectural Constraints (from Engram)` | `csharp-dotnet`, `dotnet10-csharp14`, `zenticalab-security` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Verify | `sdd-verify` | isolated | verify.md.in | spec.md, design.md, tasks.md, apply output | — (none) | `zenticalab-security`, `zenticalab-pr-review` |

**Note:** The exact model assignment per phase is defined exclusively in `config/agent-fragment.json5` → `agents.list[]`. Each phase has a profile with a fixed agentId. See `sdd/orchestrator-flow.md` for the complete flow including Agent Profile Validation and Project Standards Loading.

---

## Assembly Rules

1. **Every task string starts with "## SDD Phase:"** — it's the first thing the sub-agent sees
2. **The template is injected COMPLETE** — no references, no shortcuts
3. **Inputs are always listed as paths relative to the workspace root** — e.g., `sdd/{project}/{feature}/input.md`; the sub-agent reads them with `read`
4. **Outputs are listed as paths relative to the workspace root** — e.g., `sdd/{project}/{feature}/output.md`; the sub-agent writes them with `write`
5. **Exception:** In the Design fork context, Lucy resolves paths relative to the workspace before passing them to the sub-agent
6. **Validation rules are included** — so the sub-agent can self-verify its output
7. **Constraints are mandatory** — nothing is assumed
