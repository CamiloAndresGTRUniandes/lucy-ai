#!/usr/bin/env bash
# =============================================================================
# lucy-agent verify.sh — Post-install/update verification
# =============================================================================
# Exit codes: 0 = all checks pass, 1 = one or more failures
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUCY_DIR="$SCRIPT_DIR"
SKILLS_DIR="$SCRIPT_DIR/skills"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
FAILED_CHECKS=()

check() {
  local description="$1"
  local command="$2"
  local check_name="${3:-$description}"
  if eval "$command"; then
    echo -e "  ${GREEN}✓${NC} $description"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $description"
    FAIL=$((FAIL + 1))
    FAILED_CHECKS+=("$check_name")
  fi
}

# Accumulated summary of failures for end-of-run report
print_failure_report() {
  if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
    return
  fi
  echo ""
  echo -e "${RED}Failed checks:${NC}"
  for failed_check in "${FAILED_CHECKS[@]}"; do
    echo -e "  ${RED}✗${NC} $failed_check"
  done
}

echo ""
echo -e "${BLUE}lucy-agent verification${NC}"
echo ""

# ---------------------------------------------------------------------------
# Check 1: lucy-agent git repo exists
# ---------------------------------------------------------------------------
echo "Repository checks:"
check "lucy-agent directory exists" "[ -d '$LUCY_DIR' ]" "repo-dir-exists"
check "is a git repository" "[ -d '$LUCY_DIR/.git' ]" "repo-is-git"
check "SKILL.md exists" "[ -f '$LUCY_DIR/SKILL.md' ]" "repo-skill-md"
check "install.sh exists" "[ -f '$LUCY_DIR/install.sh' ]" "repo-install-sh"
check "update.sh exists" "[ -f '$LUCY_DIR/update.sh' ]" "repo-update-sh"
check "verify.sh exists" "[ -f '$LUCY_DIR/verify.sh' ]" "repo-verify-sh"
check "uninstall.sh exists" "[ -f '$LUCY_DIR/uninstall.sh' ]" "repo-uninstall-sh"
check "scripts/common.sh exists" "[ -f '$LUCY_DIR/scripts/common.sh' ]" "repo-common-sh"
check ".gitignore exists" "[ -f '$LUCY_DIR/.gitignore' ]" "repo-gitignore"
echo ""

# ---------------------------------------------------------------------------
# Check 2: Workspace seed files
# ---------------------------------------------------------------------------
echo "Workspace seed checks:"
for file in SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md MEMORY.md; do
  check "workspace/$file exists" "[ -f '$LUCY_DIR/workspace/$file' ]" "workspace-$file"
done
echo ""

# ---------------------------------------------------------------------------
# Check 2.0: Workspace agnostic content checks (v1.8.0)
# ---------------------------------------------------------------------------
echo "Workspace agnostic content checks:"
check "AGENTS.md has NON-NEGOTIABLE RULES" "grep -q 'NON-NEGOTIABLE' '$LUCY_DIR/workspace/AGENTS.md'" "agnostic-agents-nonnegotiable"
check "AGENTS.md has Content Boundaries" "grep -q 'Content Boundaries' '$LUCY_DIR/workspace/AGENTS.md'" "agnostic-agents-boundaries"
check "AGENTS.md has no SDD_TABLE sentinels" "! grep -q 'SDD_TABLE' '$LUCY_DIR/workspace/AGENTS.md'" "agnostic-agents-no-sentinels"
check "AGENTS.md has agentId-based spawning" "grep -q 'agentId' '$LUCY_DIR/workspace/AGENTS.md'" "agnostic-agents-agentid"
check "TOOLS.md has CONTENT LOCK" "grep -q 'CONTENT LOCK' '$LUCY_DIR/workspace/TOOLS.md'" "agnostic-tools-contentlock"
check "TOOLS.md has no ZENTICALAB references" "! grep -qi 'ZENTICALAB' '$LUCY_DIR/workspace/TOOLS.md'" "agnostic-tools-no-zenticalab"
check "TOOLS.md has no ZENTICALAB project block" "! grep -qi 'ZENTICALAB.*Project Standards\|ZENTICALAB.*Standards\|Backend Standards\|Frontend Standards\|SQL Query Patterns\|Controller Patterns' '$LUCY_DIR/workspace/TOOLS.md'" "agnostic-tools-no-project-standards"
check "MEMORY.md has privacy notice" "grep -q 'PRIVATE FILE' '$LUCY_DIR/workspace/MEMORY.md'" "agnostic-memory-privacy"
echo ""

# ---------------------------------------------------------------------------
# Check 2.1: SDD Orchestrator files (added in v1.3.0)
# ---------------------------------------------------------------------------
echo "SDD Orchestrator checks:"
check "workspace/sdd/ directory exists" "[ -d '$LUCY_DIR/workspace/sdd' ]" "sdd-dir-exists"
check "workspace/sdd/templates/ directory exists" "[ -d '$LUCY_DIR/workspace/sdd/templates' ]" "sdd-templates-dir"

for doc in orchestrator-flow.md task-string-format.md validation-rules.md; do
  check "workspace/sdd/$doc exists" "[ -f '$LUCY_DIR/workspace/sdd/$doc' ]" "sdd-$doc"
done

for tmpl in explore.md.in spec.md.in design.md.in tasks.md.in apply.md.in verify.md.in state.json.in standards.md.in; do
  check "workspace/sdd/templates/$tmpl exists" "[ -f '$LUCY_DIR/workspace/sdd/templates/$tmpl' ]" "sdd-tmpl-$tmpl"
done

check "AGENTS.md has SDD Orchestrator reference" "grep -q 'SDD Orchestrator' '$LUCY_DIR/workspace/AGENTS.md'" "sdd-agents-orchestrator"
echo ""

# ---------------------------------------------------------------------------
# Check 2.2: SDD docs sync checks (v1.8.0)
# ---------------------------------------------------------------------------
echo "SDD docs sync checks:"
check "sdd/templates/standards.md.in exists (root)" "[ -f '$LUCY_DIR/sdd/templates/standards.md.in' ]" "sdd-root-standards-tmpl"
check "orchestrator-flow.md uses agentId" "grep -q 'agentId' '$LUCY_DIR/sdd/orchestrator-flow.md'" "sdd-root-agentid"
check "orchestrator-flow.md has Project Standards Loading" "grep -q 'Project Standards Loading' '$LUCY_DIR/sdd/orchestrator-flow.md'" "sdd-root-standards-loading"
check "task-string-format.md uses agentId" "grep -q 'agentId' '$LUCY_DIR/sdd/task-string-format.md'" "sdd-task-agentid"

# Verify root and workspace SDD shipped files are identical
for doc in orchestrator-flow.md task-string-format.md validation-rules.md; do
  check "root/workspace sdd/$doc are in sync" "diff -q '$LUCY_DIR/sdd/$doc' '$LUCY_DIR/workspace/sdd/$doc' >/dev/null 2>&1" "sdd-sync-$doc"
done

for tmpl in explore.md.in spec.md.in design.md.in tasks.md.in apply.md.in verify.md.in state.json.in standards.md.in; do
  check "root/workspace sdd/templates/$tmpl are in sync" "diff -q '$LUCY_DIR/sdd/templates/$tmpl' '$LUCY_DIR/workspace/sdd/templates/$tmpl' >/dev/null 2>&1" "sdd-sync-tmpl-$tmpl"
done
echo ""

# ---------------------------------------------------------------------------
# Check 3: Bundled skills
# ---------------------------------------------------------------------------
echo "Bundled skill checks:"
for skill in sdd github-pr csharp-dotnet dotnet10-csharp14 tailwind-4 typescript angular-core angular-architecture angular-forms angular-performance skill-creator; do
  check "skill/$skill exists" "[ -f '$SKILLS_DIR/$skill/SKILL.md' ]" "skill-$skill"
done
echo ""

# ---------------------------------------------------------------------------
# Check 4: Config fragment (expanded in v1.8.0)
# ---------------------------------------------------------------------------
echo "Config checks:"
check "agent-fragment.json5 exists" "[ -f '$LUCY_DIR/config/agent-fragment.json5' ]" "config-fragment"
check "agent-fragment has agents block" "grep -q 'agents:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-agents"
check "agent-fragment has defaults block" "grep -q 'defaults:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-defaults"
check "agent-fragment has agents.list[]" "grep -q 'list:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-list"

# Verify all 9 SDD agent profiles exist
for profile in main sdd-explore sdd-propose sdd-spec sdd-design sdd-tasks sdd-apply sdd-verify sdd-archive; do
  check "agent-fragment has '$profile' profile" "grep -q '\"$profile\"' '$LUCY_DIR/config/agent-fragment.json5'" "config-profile-$profile"
done

check "agent-fragment has bootstrapMaxChars" "grep -q 'bootstrapMaxChars' '$LUCY_DIR/config/agent-fragment.json5'" "config-bootstrap-max"
check "agent-fragment has bootstrapTotalMaxChars" "grep -q 'bootstrapTotalMaxChars' '$LUCY_DIR/config/agent-fragment.json5'" "config-bootstrap-total"
check "agent-fragment has timeoutSeconds" "grep -q 'timeoutSeconds' '$LUCY_DIR/config/agent-fragment.json5'" "config-timeout"
check "agent-fragment removes stale minimax references" "! grep -qi 'minimax' '$LUCY_DIR/config/agent-fragment.json5'" "config-no-minimax"
check "agent-fragment sets thinkingDefault to high" "grep -q 'thinkingDefault: \"high\"' '$LUCY_DIR/config/agent-fragment.json5'" "config-thinking-high"
check "agent-fragment has Engram MCP block" "grep -q 'engram:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-engram-mcp"
check "agent-fragment Engram has 'mcp' arg" "grep -q '\"mcp\"' '$LUCY_DIR/config/agent-fragment.json5'" "config-engram-mcp-arg"
echo ""

# ---------------------------------------------------------------------------
# Check 4.5: Engram technical memory system
# ---------------------------------------------------------------------------
echo "Engram checks:"

ENGRAM_BIN="${HOME}/.local/bin/engram"
# Engram data dir — check multiple possible locations
ENGRAM_DATA_DIR=""
for candidate in "${HOME}/.engram" "${HOME}/.local/share/engram"; do
  if [ -f "$candidate/engram.db" ]; then
    ENGRAM_DATA_DIR="$candidate"
    break
  fi
done

if [ ! -f "$ENGRAM_BIN" ]; then
  echo -e "  ${YELLOW}!${NC} Engram binary not found — skipping Engram checks"
  echo -e "    (run install.sh without --skip-engram to add Engram)"
else
  check "Engram binary exists" \
    "[ -f '$ENGRAM_BIN' ]" \
    "engram-binary-exists"

  check "Engram binary is executable" \
    "[ -x '$ENGRAM_BIN' ]" \
    "engram-binary-executable"

  check "engram --version works" \
    "'$ENGRAM_BIN' --version >/dev/null 2>&1" \
    "engram-version-works"

  check "Engram data directory exists" \
    "[ -d '$ENGRAM_DATA_DIR' ]" \
    "engram-data-dir-exists"

  check "Engram database exists" \
    "[ -f '$ENGRAM_DATA_DIR/engram.db' ]" \
    "engram-db-exists"
fi
echo ""

# ---------------------------------------------------------------------------
# Check 5: Scripts syntax validation
# ---------------------------------------------------------------------------
echo "Script syntax checks:"
for script in install.sh update.sh uninstall.sh verify.sh scripts/common.sh scripts/check-content-boundaries.sh scripts/install-pre-commit-hook.sh; do
  check "$script syntax valid" "bash -n '$LUCY_DIR/$script'" "syntax-$script"
done
echo ""

# ---------------------------------------------------------------------------
# Check 5.5: Content boundary hook scripts (v1.8.0)
# ---------------------------------------------------------------------------
echo "Content boundary hook checks:"
check "check-content-boundaries.sh exists" "[ -f '$LUCY_DIR/scripts/check-content-boundaries.sh' ]" "hook-checker-exists"
check "check-content-boundaries.sh is executable" "[ -x '$LUCY_DIR/scripts/check-content-boundaries.sh' ]" "hook-checker-exec"
check "install-pre-commit-hook.sh exists" "[ -f '$LUCY_DIR/scripts/install-pre-commit-hook.sh' ]" "hook-installer-exists"
check "install-pre-commit-hook.sh is executable" "[ -x '$LUCY_DIR/scripts/install-pre-commit-hook.sh' ]" "hook-installer-exec"

# Run content boundary checks if in a git repo
if [ -d "$LUCY_DIR/.git" ]; then
  echo -e "  ${BLUE}→${NC} Running content boundary checks (--worktree)..."
  if bash "$LUCY_DIR/scripts/check-content-boundaries.sh" --worktree 2>&1; then
    echo -e "  ${GREEN}✓${NC} Content boundaries: all locked files are agnostic"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} Content boundaries: violations found in locked files"
    FAIL=$((FAIL + 1))
    FAILED_CHECKS+=("content-boundaries")
  fi
else
  echo -e "  ${YELLOW}!${NC} Not in a git repo — skipping content boundary checks"
fi
echo ""

# ---------------------------------------------------------------------------
# Check 6: ClawHub skills installed
# ---------------------------------------------------------------------------
echo "ClawHub skill checks:"
if command -v openclaw &>/dev/null; then
  if [ -f "$LUCY_DIR/clawhub-skills.txt" ]; then
    while IFS= read -r skill || [ -n "$skill" ]; do
      [[ -z "$skill" ]] && continue
      [[ "$skill" =~ ^# ]] && continue
      skill=$(echo "$skill" | xargs)
      [[ -z "$skill" ]] && continue
      check "ClawHub skill '$skill' listed" "openclaw skills list 2>/dev/null | grep -q '$skill'" "clawhub-$skill"
    done <"$LUCY_DIR/clawhub-skills.txt"
  fi
else
  echo -e "  ${YELLOW}!${NC} OpenClaw CLI not available — skipping ClawHub check"
fi
echo ""

# ---------------------------------------------------------------------------
# Check 6.5: README and version consistency (v1.9.1)
# ---------------------------------------------------------------------------
echo "README / version checks:"
check "README has version 1.9.1 badge" "grep -q '1.9.1' '$LUCY_DIR/README.md'" "readme-version-badge"
check "README mentions agnostic configuration" "grep -qi 'agnostic.configuration\|agnostic.config' '$LUCY_DIR/README.md'" "readme-agnostic-config"
check "README mentions content boundary enforcement" "grep -qi 'content.boundary' '$LUCY_DIR/README.md'" "readme-content-boundary"
check "README mentions config fragment" "grep -q 'agent-fragment.json5\|openclaw.json' '$LUCY_DIR/README.md'" "readme-config-fragment"
check "README mentions contributor setup" "grep -q 'contributor' '$LUCY_DIR/README.md'" "readme-contributor"
check "README no longer says TUI configures SDD models" "! grep -q 'configure SDD phase models' '$LUCY_DIR/README.md'" "readme-no-tui-sdd-models"
check "README doesn't reference lucy-config branch" "! grep -q 'lucy-config' '$LUCY_DIR/README.md'" "readme-no-lucy-config"
check "CHANGELOG has 1.9.1 entry" "grep -q '\\[1.9.1\\]' '$LUCY_DIR/CHANGELOG.md'" "changelog-1.9.1"
check "install.sh version is 1.9.1" "grep -q 'CURRENT_VERSION=\"1.9.1\"' '$LUCY_DIR/install.sh'" "install-version-1.9.1"
check "update.sh version is 1.9.1" "grep -q 'CURRENT_VERSION=\"1.9.1\"' '$LUCY_DIR/update.sh'" "update-version-1.9.1"
check "exporter script exists" "[ -f '$LUCY_DIR/scripts/export-full-clone.sh' ]" "export-script-exists"
check "install.sh supports --full-clone" "grep -q -- '--full-clone' '$LUCY_DIR/install.sh'" "install-full-clone-flag"
check "README mentions Harness Engineering" "grep -qi 'harness.engineering' '$LUCY_DIR/README.md'" "readme-harness-engineering"
check "README has 7-layer harness table" "grep -q '7 layer' '$LUCY_DIR/README.md'" "readme-harness-layers"
check "install.sh auto-injects config fragment" "grep -q 'agent-fragment.json5' '$LUCY_DIR/install.sh' && grep -q 'openclaw.json' '$LUCY_DIR/install.sh'" "install-auto-include"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "================================"
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}All checks passed ($PASS/$PASS)${NC}"
  echo "================================"
  exit 0
else
  echo -e "${RED}FAILURES: $FAIL/$((PASS + FAIL))${NC}"
  echo -e "${RED}Passed: $PASS | Failed: $FAIL${NC}"
  print_failure_report
  echo "================================"
  echo ""
  echo "Tip: Run with 'bash -x' for verbose output on failures"
  exit 1
fi
