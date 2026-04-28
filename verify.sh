#!/usr/bin/env bash
# =============================================================================
# lucy-agent verify.sh — Post-install/update verification
# =============================================================================
# Exit codes: 0 = all checks pass, 1 = one or more failures
# =============================================================================

set -euo pipefail

LUCY_DIR="/home/node/.openclaw/lucy-agent"
WORKSPACE_DIR="/home/node/.openclaw/workspace"
SKILLS_DIR="/home/node/.openclaw/workspace/skills"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
  local description="$1"
  local command="$2"
  if eval "$command"; then
    echo -e "  ${GREEN}✓${NC} $description"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $description"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo -e "${BLUE}lucy-agent verification${NC}"
echo ""

# ---------------------------------------------------------------------------
# Check 1: lucy-agent git repo exists
# ---------------------------------------------------------------------------
echo "Repository checks:"
check "lucy-agent directory exists" "[ -d '$LUCY_DIR' ]"
check "is a git repository" "[ -d '$LUCY_DIR/.git' ]"
check "SKILL.md exists" "[ -f '$LUCY_DIR/SKILL.md' ]"
check "install.sh exists" "[ -f '$LUCY_DIR/install.sh' ]"
check "update.sh exists" "[ -f '$LUCY_DIR/update.sh' ]"
check "verify.sh exists" "[ -f '$LUCY_DIR/verify.sh' ]"
echo ""

# ---------------------------------------------------------------------------
# Check 2: Workspace seed files
# ---------------------------------------------------------------------------
echo "Workspace seed checks:"
for file in SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md; do
  check "workspace/$file exists" "[ -f '$LUCY_DIR/workspace/$file' ]"
done
echo ""

# ---------------------------------------------------------------------------
# Check 3: Bundled skills
# ---------------------------------------------------------------------------
echo "Bundled skill checks:"
for skill in sdd github-pr pr-review csharp-dotnet tailwind-4 typescript skill-creator; do
  check "skill/$skill exists" "[ -f '$SKILLS_DIR/$skill/SKILL.md' ]"
done
echo ""

# ---------------------------------------------------------------------------
# Check 4: Config fragment
# ---------------------------------------------------------------------------
echo "Config checks:"
check "agent-fragment.json5 exists" "[ -f '$LUCY_DIR/config/agent-fragment.json5' ]"
check "agent-fragment has agents block" "grep -q 'agents:' '$LUCY_DIR/config/agent-fragment.json5'"
check "agent-fragment has defaults block" "grep -q 'defaults:' '$LUCY_DIR/config/agent-fragment.json5'"
echo ""

# ---------------------------------------------------------------------------
# Check 5: ClawHub skills installed
# ---------------------------------------------------------------------------
echo "ClawHub skill checks:"
if command -v openclaw &>/dev/null; then
  if [ -f "$LUCY_DIR/clawhub-skills.txt" ]; then
    while IFS= read -r skill || [ -n "$skill" ]; do
      [[ -z "$skill" ]] && continue
      [[ "$skill" =~ ^# ]] && continue
      skill=$(echo "$skill" | xargs)
      [[ -z "$skill" ]] && continue
      check "ClawHub skill '$skill' listed" "openclaw skills list 2>/dev/null | grep -q '$skill'"
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
  echo "================================"
  exit 1
fi
