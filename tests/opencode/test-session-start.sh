#!/usr/bin/env bash
# Test: SessionStart Hook
# Verifies that duplicate Codex skill names produce a warning in SessionStart context
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Test: SessionStart Hook ==="

source "$SCRIPT_DIR/setup.sh"
trap cleanup_test_env EXIT

mkdir -p "$HOME/.agents/skills/duplicate-skill"
mkdir -p "$HOME/.codex/skills/duplicate-skill"

cat > "$HOME/.agents/skills/duplicate-skill/SKILL.md" <<'EOF'
---
name: duplicate-skill
description: Preferred duplicate fixture
---
# Duplicate Skill
EOF

cat > "$HOME/.codex/skills/duplicate-skill/SKILL.md" <<'EOF'
---
name: duplicate-skill
description: Duplicate fixture
---
# Duplicate Skill
EOF

echo "Test 1: Checking duplicate skill warning..."
output=$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT" "$REPO_ROOT/hooks/session-start")

if echo "$output" | grep -q "Duplicate skill names were detected across Codex discovery roots"; then
    echo "  [PASS] Duplicate-skill warning emitted"
else
    echo "  [FAIL] Duplicate-skill warning missing"
    exit 1
fi

echo "Test 2: Checking preferred and duplicate paths..."
if echo "$output" | grep -q "~/.agents/skills/duplicate-skill/SKILL.md (preferred)" &&
   echo "$output" | grep -q "~/.codex/skills/duplicate-skill/SKILL.md (duplicate)"; then
    echo "  [PASS] Warning identifies preferred and duplicate paths"
else
    echo "  [FAIL] Warning missing path details"
    exit 1
fi

echo ""
echo "=== SessionStart hook tests passed ==="
