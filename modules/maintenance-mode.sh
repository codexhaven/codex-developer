#!/usr/bin/env bash
# MAINTENANCE MODE v12.2: Hardened HITL Audit & TODO Synthesis
set -euo pipefail

# Use absolute path resolution
REPODIR="$(readlink -f "${CODEX_REPO:-$HOME/projects}")"
GOALFILE="${REPODIR}/.codex/goal.md"
TODOS_FILE="${REPODIR}/.codex/TODO_COLLECTOR.md"

echo "[MAINTENANCE] Performing Pre-Flight FS Audit..."
# 1. Audit current FS state
FILES_AUDIT=$(ls -R "$REPODIR" | grep -v ".git" | grep -v ".codex" | grep -v "__pycache__")

# 2. Collect TODOs
grep -rE "TODO|FIXME" "$REPODIR" --exclude-dir=.git --exclude-dir=.codex --exclude-dir=node_modules > "$TODOS_FILE"

if [ ! -s "$TODOS_FILE" ]; then
    echo "[MAINTENANCE] No TODOs found. Clean state."
    exit 0
fi

# 3. Synthesize via Codex Wisdom
TODO_CONTENT=$(cat "$TODOS_FILE")
PROMPT="As a v12.2 factory engine, audit the project using this filesystem:
$FILES_AUDIT

And synthesize these TODOs into a priority-ordered goal.md:
$TODO_CONTENT

Follow Rule #41 (Pre-Flight Audit): Verify all task dependencies exist in the project map."

NEW_GOAL=$(hermes chat -q "$PROMPT" --yolo --quiet 2>/dev/null || echo "")

# 4. Atomic Write
if [ -n "$NEW_GOAL" ]; then
    [ -f "$GOALFILE" ] && cp "$GOALFILE" "${GOALFILE}.bak"
    echo "$NEW_GOAL" > "${GOALFILE}.tmp"
    mv "${GOALFILE}.tmp" "$GOALFILE"
    echo "[MAINTENANCE] goal.md updated. HITL manual review recommended."
else
    echo "[MAINTENANCE] Generation failed."
    exit 1
fi
