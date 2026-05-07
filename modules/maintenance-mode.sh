#!/usr/bin/env bash
# MAINTENANCE MODE: Auto-scans for TODOs and updates goal.md
set -euo pipefail
REPODIR="$(realpath "${CODEX_REPO:-$HOME/codex-builds}")"
GOALFILE="${REPODIR}/.codex/goal.md"
TODOS_FILE="${REPODIR}/TODO_COLLECTOR.md"
TEMP_GOAL="${REPODIR}/.codex/goal.md.tmp"

# 1. Collect all TODOs safely
grep -rE "TODO|FIXME" "$REPODIR" --exclude-dir=.git --exclude-dir=.codex > "$TODOS_FILE"

# 2. Check if TODOs found
if [ ! -s "$TODOS_FILE" ]; then
    echo "[MAINTENANCE] No TODOs found."
    exit 0
fi

# 3. Synthesize via Hermes agent
# Note: Using cat to ensure content is passed as plain string, avoiding injection
TODO_CONTENT=$(cat "$TODOS_FILE")
PROMPT="Prioritize these tasks into a goal.md:
$TODO_CONTENT"

NEW_GOAL=$(hermes chat -q "$PROMPT" --yolo --quiet 2>/dev/null || echo "")

# 4. Write with backup and atomic move
if [ -n "$NEW_GOAL" ]; then
    if [ -f "$GOALFILE" ]; then
        cp "$GOALFILE" "${GOALFILE}.bak"
    fi
    echo "$NEW_GOAL" > "$TEMP_GOAL"
    mv "$TEMP_GOAL" "$GOALFILE"
    echo "[MAINTENANCE] goal.md updated."
else
    echo "[MAINTENANCE] Generation failed."
    exit 1
fi
