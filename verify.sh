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
for file in SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md; do
  check "workspace/$file exists" "[ -f '$LUCY_DIR/workspace/$file' ]" "workspace-$file"
done
echo ""

# ---------------------------------------------------------------------------
# Check 3: Bundled skills
# ---------------------------------------------------------------------------
echo "Bundled skill checks:"
for skill in sdd github-pr pr-review csharp-dotnet tailwind-4 typescript skill-creator; do
  check "skill/$skill exists" "[ -f '$SKILLS_DIR/$skill/SKILL.md' ]" "skill-$skill"
done
echo ""

# ---------------------------------------------------------------------------
# Check 4: Config fragment
# ---------------------------------------------------------------------------
echo "Config checks:"
check "agent-fragment.json5 exists" "[ -f '$LUCY_DIR/config/agent-fragment.json5' ]" "config-fragment"
check "agent-fragment has agents block" "grep -q 'agents:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-agents"
check "agent-fragment has defaults block" "grep -q 'defaults:' '$LUCY_DIR/config/agent-fragment.json5'" "config-has-defaults"
echo ""

# ---------------------------------------------------------------------------
# Check 5: Scripts syntax validation
# ---------------------------------------------------------------------------
echo "Script syntax checks:"
for script in install.sh update.sh uninstall.sh verify.sh scripts/common.sh; do
  check "$script syntax valid" "bash -n '$LUCY_DIR/$script'" "syntax-$script"
done
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
    done < "$LUCY_DIR/clawhub-skills.txt"
  fi
else
  echo -e "  ${YELLOW}!${NC} OpenClaw CLI not available — skipping ClawHub check"
fi
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
