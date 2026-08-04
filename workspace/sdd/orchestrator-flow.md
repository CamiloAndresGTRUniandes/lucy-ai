# SDD Orchestrator — Orchestration Flow

## Purpose

Step-by-step guide for Lucy to execute a complete SDD cycle by delegating phases to sub-agents.

---

## Spawn Anatomy

### Base Parameters

```text
{
  "task": "## SDD Phase: {phase}\n... (task string armado con task-string-format.md)",
  "label": "sdd-{project}-{phase}-{attempt}",
  "agentId": "sdd-{phase}",
  "context": "{isolated|fork}"
}
```

> ⚠️ **Note:** The `agentId` automatically resolves the primary model, fallback, thinking level, and timeout from `config/agent-fragment.json5` → `agents.list[]`. Do NOT pass `model`, `thinking`, or `runTimeoutSeconds` manually. The profile has everything.

### ⚠️ Pre-spawn: Agent Profile Validation (MANDATORY)

**BEFORE each spawn, Lucy MUST:**
1. Verify the `agentId` exists in `agents.list[]` (e.g., `sdd-design`, `sdd-apply`)
2. Validate that the phase uses the canonical `agentId` (see delegated phases table)
3. Report the resolved profile to Camilo: primary model, provider, thinking
4. If the primary fails (timeout/error), re-spawn — the profile's fallback applies automatically

**Non-negotiable rule:** Do NOT pass `model` manually in the spawn. The `agentId` is the single source of truth. OpenClaw resolves the model from `agents.list[]`.

### Notification to Camilo (MANDATORY)

Every time Lucy spawns a sub-agent, she MUST inform Camilo with:

```
📋 **SDD Phase: {phase}**
🧠 Primary: `{provider/model}` (thinking: {mode})
⏱️ Timeout: {N}s
🆘 Fallback: `{fallback_model}`
```

Ejemplo:
```
📋 **SDD Phase: Design**
🧠 Primary: `openai-codex/gpt-5.5` (thinking: high)
⏱️ Timeout: 1200s
🆘 Fallback: `deepseek/deepseek-v4-pro`

📋 **SDD Phase: Apply**
🧠 Primary: `deepseek/deepseek-v4-pro` (thinking: high)
⏱️ Timeout: 1200s
🆘 Fallback: `openai-codex/gpt-5.4`
```

Camilo needs to know which resolved profile is used in each phase to:
- Monitor costs (DeepSeek pay-per-token vs $0 subscriptions)
- Verify that the fixed profiles from `agents.list[]` are respected
- Quickly diagnose if a provider fails

### Phases to Delegate and Phases Not To

**Source of truth for models:** `config/agent-fragment.json5` → `agents.list[]`.
This table defines only delegation, context, and canonical agentId.

| Phase | Delegate? | Context | agentId |
|------|----------|--------|---------|
| Explore | **Yes** | isolated | `sdd-explore` |
| Propose | **No, Lucy directly** | — | `sdd-propose` |
| Spec | **Yes** | isolated | `sdd-spec` |
| Design | **Yes** | **fork** | `sdd-design` |
| Tasks | **Yes** | isolated | `sdd-tasks` |
| Apply | **Yes** | isolated | `sdd-apply` |
| Verify | **Yes** | isolated | `sdd-verify` |
| PR Review | **No, Camilo human review** | — | — |
| Address changes | **Lucy directly** | — | — |
| Archive | **No, Lucy directly** | — | `sdd-archive` |

---

## Step-by-Step by Phase

### 0. Pre-flight: Project Standards Loading + Engram Context Assembly

**Trigger:** Camilo starts an SDD cycle ("SDD for X", "explore Y", "implement Z").

**Lucy executes (in order):**

**A. Project Standards Loading (MANDATORY):**
1. Resolve `project_root` = `/workspace/repos/{project}/`
2. Read `{project_root}/docs/STANDARDS.md`
3. If it does NOT exist:
   - If it's a new project → ask Camilo if he wants to create standards first (using `sdd/templates/standards.md.in`)
   - If it's an existing project → abort phase and ask Camilo to create `docs/STANDARDS.md`
4. Extract summary: architecture, commit conventions, code standards, git workflow
5. Inject summary into the task string under `### Standards`

**Exception:** If the current feature is explicitly creating `docs/STANDARDS.md` or `sdd/templates/standards.md.in` for a new project, the task may proceed with a bootstrap template.

**B. Engram Context Assembly:**
1. `engram__mem_current_project()` → detects active project
2. `engram__mem_context(scope="project")` → loads recent project sessions
3. `engram__mem_search("<project>", type="architecture|decision|pattern", limit=10)` → project architecture decisions
4. `engram__mem_search("<feature keywords>", type="architecture|decision|pattern", limit=5)` → feature-specific context
5. Assembles **Pre-loaded Engram Context Block**:
   - If context exists → markdown block with recent sessions, top-5 decisions with IDs, patterns
   - If NO context → mark `contextFound=false`, include collector instruction
6. Updates `state.json`:
   - `state.engram.preflight.ranAt = now()`
   - `state.engram.preflight.contextFound = true|false`
   - `state.engram.preflight.decisionCount = total found`
   - `state.engram.cycleSessionId = "SDD-{feature}-{timestamp}"`

**Error handling:**
- If `docs/STANDARDS.md` does not exist → abort phase, ask Camilo to create standards (or confirm exception)
- If Engram unavailable (tool error):
  - Log warning in state.json: `"engram.preflight.error": "engram_unavailable"`
  - Continue in degraded mode: Explore starts without injected context
  - Notify Camilo: "⚠️ Engram unavailable. Continuing without prior context."

### 1. Explore (delegated)

**Trigger:** Camilo says "explore X" or starts an SDD cycle.

**Lucy does:**
1. Creates `sdd/{project}/{feature}/` directory
2. Writes initial `state.json`
3. Assembles task string from `sdd/task-string-format.md` and template `sdd/templates/explore.md.in`
3a. Includes `Pre-loaded Engram Context Block` as a section of the Explore task string:
   ```markdown
   ## Pre-loaded Engram Context
   (context block assembled in Step 0)
   ```

   If `contextFound=false` → the block includes Context Collector instructions:
   > ⚠️ No prior context found in Engram. You MUST collect the stack, patterns, project structure and save them with `engram__mem_save(type="discovery"|"pattern")`
4. Spawns sub-agent:
   ```
   agentId: sdd-explore
   context: isolated
   label: sdd-{project}-explore-1
   ```
5. Yield / wait
6. **Validates output** according to `sdd/validation-rules.md`
7. If PASS → updates state.json and reports to Camilo
7a. If `contextFound=false` → verify the sub-agent saved context to Engram
7b. Starts Engram session for Explore:
    `engram__mem_session_start(id="SDD-{feature}-explore")`
7c. Saves Explore discoveries to Engram:
    `engram__mem_save(title="Explore: {feature}", type="discovery", content="...", session_id="SDD-{feature}-explore")`
7d. Closes Explore session:
    `engram__mem_session_end(id="SDD-{feature}-explore", summary="...")`
7e. Updates `state.engram.observations.explore` with saved IDs
8. If FAIL → retry (up to 3)

### 2. Propose (Lucy directly)

**Trigger:** Explore completed.

**Lucy does:**
0. Memory Prep: run `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)` to surface related prior art. If conflicting decisions are found, surface them to Camilo during the presentation.
1. Presents findings + 2-3 approaches with trade-offs + recommendation
2. Asks Camilo: "What's the problem?", "What constraints?", "What happens if we don't do it?"
3. Waits for Camilo's decision
3a. Saves approved direction to Engram:
    `engram__mem_save(type="decision", topic_key="sdd-direction/<feature>", content="**What**: Approved direction for {feature}\n**Why**: {Camilo's rationale}")`
3b. Updates `state.engram.observations.propose` with saved ID
4. Updates state.json

### 3. Spec (delegated)

**Trigger:** Camilo approves Propose.

**Lucy does:**
0. Memory Prep: run `engram__mem_context(scope="project")` to load recent project session summaries.
1. Reads template `sdd/templates/spec.md.in`
2. Assembles task string with: inputs (Propose discussion), complete template, validation rules

   ```markdown
   ## Key Context from Prior Sessions
   (recent project session summaries)
   ```
3. Spawns sub-agent:
   ```
   agentId: sdd-spec
   context: isolated
   label: sdd-{project}-spec-1
   ```
4. Yield / wait
5. **Validates output** according to validation-rules.md
6. If PASS → updates state, presents to Camilo for review
7. If FAIL → retry
8. **Waits for Camilo's explicit approval** before continuing
8a. Starts Engram session: `engram__mem_session_start(id="SDD-{feature}-spec")`
8b. Saves Spec summary: `engram__mem_save(type="discovery", title="Spec: {feature}", content="...", session_id="SDD-{feature}-spec")`
8c. Closes session: `engram__mem_session_end(id="SDD-{feature}-spec", summary="...")`
8d. Updates `state.engram.observations.spec`

### 4. Design (delegated)

**Trigger:** Camilo approves Spec.

**Lucy does:**
0. Memory Prep:
   a. `engram__mem_context(scope="project")` → recent sessions
   b. `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)` → prior decisions
1. Reads template `sdd/templates/design.md.in`
2. Assembles task string: inputs (spec.md), template, validation rules
2a. Include Technical Skills to Load section from task-string-format.md

   ```markdown
   ## Architectural Context (from Engram)
   (prior architecture decisions with observation IDs and established patterns)
   ```
3. Spawns sub-agent:
   ```
   agentId: sdd-design
   context: fork   ← INHERITS the transcript to have context from prior phases
   label: sdd-{project}-design-1
   ```
4. Yield / wait
5. **Validates output**
6. If PASS → presents to Camilo
7. If FAIL → retry
8. **Waits for Camilo's explicit approval** before continuing
8a. Starts Engram session: `engram__mem_session_start(id="SDD-{feature}-design")`
8b. For EACH architecture decision in the approved `design.md`:
    - `engram__mem_suggest_topic_key(type="architecture", title="<decision>")` → `topic_key`
    - `engram__mem_save(type="architecture", topic_key="architecture/<slug>", content="**What**: ...\n**Why**: ...\n**Where**: ...", session_id="SDD-{feature}-design")`
    - If `judgment_required: true` → surface candidates to Camilo BEFORE continuing
8c. If any save fails → retry once, if it continues failing → escalate to Camilo
8d. Closes session: `engram__mem_session_end(id="SDD-{feature}-design", summary="...")`
8e. Updates `state.engram.observations.design` with saved IDs

### 5. Tasks (delegated)

**Trigger:** Camilo approves Design.

**Lucy does:**
1. Reads template `sdd/templates/tasks.md.in`
2. Assembles task string: inputs (spec.md, design.md), template, validation
3. Spawns sub-agent:
   ```
   agentId: sdd-tasks
   context: isolated
   label: sdd-{project}-tasks-1
   ```
4. Yield / wait
5. **Validates output**
6. If PASS → presents to Camilo for review
6a. Starts Engram session: `engram__mem_session_start(id="SDD-{feature}-tasks")`
6b. If there are reusable patterns or novel structure:
    `engram__mem_save(type="pattern", title="Task structure: {feature}", content="...", session_id="SDD-{feature}-tasks")`
6c. Closes session: `engram__mem_session_end(id="SDD-{feature}-tasks", summary="...")`
6d. Updates `state.engram.observations.tasks`
7. If FAIL → retry

### 6. Apply (delegated)

**Trigger:** Tasks ready.

**Lucy does:**
0. Memory Prep:
   a. `engram__mem_context(scope="project")` → recent sessions
   b. `engram__mem_search("<feature>", type="architecture|decision|pattern", limit=5)`
1. Reads template `sdd/templates/apply.md.in`
2. Assembles task string: inputs (spec.md, design.md, tasks.md), template, validation, skills
2a. Include Technical Skills to Load section from task-string-format.md

   ```markdown
   ## Architectural Constraints (from Engram)
   (architectural constraints of the project)
   ```
3. Spawns sub-agent:
   ```
   agentId: sdd-apply
   context: isolated
   label: sdd-{project}-apply-1
   ```
4. Yield / wait
5. **Validates output** — especially that code exists and tests are written
6. If PASS → presents diff/output to Camilo for joint review
6a. Starts Engram session: `engram__mem_session_start(id="SDD-{feature}-apply")`
6b. Saves unforeseen discoveries: `engram__mem_save(type="discovery", content="...", session_id="SDD-{feature}-apply")`
6c. If there was a deviation from Design, save rationale:
    `engram__mem_save(type="decision", topic_key="deviation/<feature>", content="...", session_id="SDD-{feature}-apply")`
6d. Closes session: `engram__mem_session_end(id="SDD-{feature}-apply", summary="...")`
6e. Updates `state.engram.observations.apply`
7. If FAIL → retry

**Note:** Sub-agents do NOT commit. Lucy reviews with Camilo, creates branch, commits, pushes, and creates PR. This triggers the PR Review phase.

### 7. Verify (delegated)

**Trigger:** Apply completed and reviewed with Camilo.

**Lucy does:**
1. Reads template `sdd/templates/verify.md.in`
2. Assembles task string: inputs (spec.md, design.md, apply output), template, validation
2a. Include Technical Skills to Load section from task-string-format.md
3. Spawns sub-agent:
   ```
   agentId: sdd-verify
   context: isolated
   label: sdd-{project}-verify-1
   ```
4. Yield / wait
5. **Validates output**
6. If PASS → presents to Camilo
6a. Starts Engram session: `engram__mem_session_start(id="SDD-{feature}-verify")`
6b. Saves verdict: `engram__mem_save(type="decision", title="Verify: {feature}", content="**What**: Verification result\n**Why**: PASS/FAIL + rationale", session_id="SDD-{feature}-verify")`
6c. Closes session: `engram__mem_session_end(id="SDD-{feature}-verify", summary="...")`
6d. Updates `state.engram.observations.verify`
7. If FAIL → report of issues found

---

### 7.5 PR Review and Address Changes (NON-NEGOTIABLE)

**Trigger:** Verify approved → PR created → Camilo review.

The PR review is part of the SDD cycle. **Do not archive until the PR is merged or Camilo decides to close it.**

#### Feedback Flow

```
Verify → Lucy creates PR → Camilo review
                                ↓
               ┌────────────────┤
               ↓                ↓
          Changes?         Approved?
               │                │
               Yes              Yes
               ↓                ↓
      ┌────────┤          Archive (PR merged)
      │        │
  Scope?      │
      │        │
  Minor ───── Apply fix → Re-verify
      │        │
      ↓        ↓
  Moderate ── Tasks → Apply → Verify
      │
      ↓
  Major ── Spec → Design → Tasks → Apply → Verify
```

#### Classification Rules

| Change Type | Example | Path |
|-------------|--------|------|
| **Minor** | Typos, naming, error msg, log level | Apply fix → Re-verify → Archive |
| **Moderate** | New variable/constant, validation change | Tasks → Apply → Verify |
| **Major** | Behavior change, new endpoint | Spec → Design → Tasks → Apply → Verify |

**Lucy classifies and presents to Camilo:**

> "Camilo, your comments are minor (3 typos) and moderate (1 validation change).
> I'll handle minor ones directly, moderate goes in as a new T1. Cool?"

**NON-NEGOTIABLE:** Archive only occurs when:
- PR merged, OR
- Camilo explicitly decides to close the cycle without merge (with documented rationale)

### 8. Archive (Lucy directly)

**Trigger:** PR merged OR Camilo explicitly decides to close the cycle.

**Lucy does:**
1. **Engram session summary of the complete cycle:**
   `engram__mem_session_summary(session_id=state.engram.cycleSessionId, content="## Goal\n...\n## Discoveries\n...\n## Accomplished\n...\n## Relevant Files\n...")`
2. **Syncs final decisions:**
   - Iterates through all phases in `state.engram.observations`
   - If any phase has pending (unsaved) decisions, save them now
   - Verifies that all architecture decisions are persisted
3. Saves final cycle decisions to `state.engram.observations.archive`
4. Moves `sdd/{project}/{feature}/` → `sdd/{project}/{feature-YYYY-MM-DD}/`
5. Updates `state.json`:
   - `status: completed`
   - Verifies the `engram` block is complete with all observation IDs
6. Writes summary to `memory/YYYY-MM-DD-{project}-{feature}.md`
7. Presents final summary to Camilo
8. Asks: "Archive and move on to the next feature?"

---

## Skill Loading by Phase

| Phase | Skills |
|-------|--------|
| Explore | `sdd` |
| Spec | — (no technical skills needed) |
| Design | `csharp-dotnet`, `dotnet10-csharp14` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Tasks | — (no technical skills needed) |
| Apply | `csharp-dotnet`, `dotnet10-csharp14`, `zenticalab-security` (backend) \|\| `typescript`, `tailwind-4`, `angular-core`, `angular-architecture`, `angular-forms`, `angular-performance` (frontend) |
| Verify | `zenticalab-security`, `zenticalab-pr-review` |

## Error Handling

### Per-Phase Timeout (defined in agent profile)

| Phase | agentId | Timeout | Rationale |
|------|---------|---------|-----------|
| Explore | `sdd-explore` | **1200s** | Pro, large codebase reading, isolated context |
| Spec | `sdd-spec` | 900s | Flash, structured task, <5k tokens output |
| Design | `sdd-design` | **1200s** | Pro, fork, needs to read the entire prior transcript |
| Tasks | `sdd-tasks` | 900s | Flash, structured template |
| Apply | `sdd-apply` | **1200s** | Pro, multiple files, may include tests |
| Verify | `sdd-verify` | 1200s | Codex, needs to read multiple inputs |

> Timeouts are defined in `config/agent-fragment.json5` → `agents.list[].timeoutSeconds`. They are not passed manually in the spawn.

---

### Timeout (exceeds profile timeout)

```python
if elapsed > agent_profile.timeoutSeconds:
    retry.count += 1
    if retry.count <= 3:
        spawn()  # same agentId, label + 1 in attempt, same exact task string
    else:
        escalate_to_camilo("Phase X failed after 3 attempts. Last error: {error}")
```

### Invalid Output (validation fails)

```python
if not validation_passed:
    retry.count += 1
    if retry.count <= 3:
        feedback = "Missing sections: {sections}. Re-run with same instructions."
        spawn_feedback = task_string + f"\n\n### Previous attempt feedback:\n{feedback}"
        spawn()  # same label, same model, task with additional feedback
    else:
        escalate_to_camilo(...)
```

**Important:** On retry, the task string is **almost** the same — feedback on missing sections is added to guide the sub-agent, but the failed output is not included (to avoid contamination).

### Camilo Doesn't Respond

```python
if camilo_no_response:  # no message in ~10 min
    state.status = "paused"
    state.feedback.pending = "Waiting for Camilo's response on {phase}"
    # Lucy waits. When Camilo speaks again, resumes from where it left off.
```

### Missing Agent Profile

```python
if agentId not in agents.list[].id:
    abort_spawn()
    notify_camilo(f"Agent profile '{agentId}' not found in config/agent-fragment.json5")
    suggest_fix("Add the missing profile to agents.list[] in config/agent-fragment.json5")
```

### Missing Project Standards

```python
if not exists(f"{project_root}/docs/STANDARDS.md"):
    abort_phase()
    ask_camilo("docs/STANDARDS.md not found for {project}.")
    offer_options:
      1. "Create standards using sdd/templates/standards.md.in as a base"
      2. "If it's a bootstrap feature (creating standards), proceed with exception"
```

---

## Multi-Project

Each project has its own `sdd/{project}/state.json`. Lucy tracks which project is active in the current conversation.

**Mechanism:**
- When Camilo says "SDD for [project1]", Lucy activates that project
- If he says "SDD for [project2]", Lucy pauses project1, activates project2
- Each project maintains its independent state in its `state.json`

---

## Startup Checklist (for Lucy, each new cycle)

- [ ] **Pre-flight: Project Standards Loading**
  - [ ] Resolve `project_root`
  - [ ] Read `{project_root}/docs/STANDARDS.md`
  - [ ] If missing → abort or confirm exception (bootstrap)
  - [ ] Inject standards into task string
- [ ] **Pre-flight Engram Context Assembly**
  - [ ] `engram__mem_current_project()` → detect project
  - [ ] `engram__mem_context(scope="project")` → recent sessions
  - [ ] `engram__mem_search("<project>", type="architecture|decision|pattern")` → prior decisions
  - [ ] `engram__mem_search("<feature>", type="architecture|decision|pattern")` → feature-specific
  - [ ] Assemble Pre-loaded Engram Context Block
  - [ ] If Engram unavailable → degraded mode (notify Camilo)
- [ ] Create `sdd/{project}/{feature}/` directory
- [ ] Create `state.json` with initial state
- [ ] Verify all templates exist in `sdd/templates/`
  - [ ] `spec.md.in`, `design.md.in`, `tasks.md.in`, `apply.md.in`, `verify.md.in`, `explore.md.in`
- [ ] Start with the correct phase according to state
- [ ] If new cycle: start with Explore → Propose

### Pre-flight Validation

Lucy verifies:
- [ ] Project standards loaded and not empty
- [ ] `state.engram.preflight.ranAt` is not `null`
- [ ] `state.engram.preflight.project` matches the active project
- [ ] If `contextFound=true` → `Pre-loaded Engram Context Block` has at least 1 observation
- [ ] If `contextFound=false` → the Explore task string includes the collector instruction

## Finalization Checklist (Conditional Archive)

- [ ] PR created and reviewer assigned
- [ ] Camilo approved the PR (or decided to close the cycle)
- [ ] Address changes loops completed (if there was feedback)
- [ ] `state.json` updated with final result and PR URL
- [ ] Session summary saved to Engram (`engram__mem_session_summary`)
- [ ] Final decisions synced to Engram (`state.engram.observations` complete)
- [ ] `state.json` updated with complete `engram` block
- [ ] Archive only when: PR merged OR Camilo decides to close

## NON-NEGOTIABLE RULES

1. **Archive is conditional on PR merge** — Do not archive until PR is merged or Camilo explicitly decides to close.
2. **Lucy classifies feedback** — State if it's minor/moderate/major and the proposed path.
3. **No PR merged, no closed cycle.**
4. **If Camilo decides to close without merge,** document rationale in ARCHIVE.md.
