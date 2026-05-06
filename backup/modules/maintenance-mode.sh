#!/usr/bin/env bash
# MAINTENANCE MODE: Auto-scans for TODOs and updates goal.md
# Should be run when the build queue is empty.

REPODIR="${CODEX_REPO:-$HOME/codex-builds}"
GOALFILE="${REPODIR}/.codex/goal.md"
TODOS_FILE="$REPODIR/TODO_COLLECTOR.md"

# 1. Collect all TODOs from the repo
grep -rE "TODO|FIXME" "$REPODIR" --exclude-dir=.git --exclude-dir=.codex > "$TODOS_FILE"

# 2. Ask Hermes to synthesize a new goal based on the TODOs found
PROMPT="I have a project in $REPODIR. Here are the pending tasks found in the code:
$(cat "$TODOS_FILE")

Synthesize these into a prioritized, actionable goal.md file for the codex-developer.
Output ONLY the new goal description. Keep it concise."

NEW_GOAL=$(hermes chat -q "$PROMPT" --yolo --quiet)

if [ -n "$NEW_GOAL" ]; then
    if [ -t 0 ]; then
        echo "--- PROPOSED NEW GOAL ---"
        echo "$NEW_GOAL"
        echo "-------------------------"
        echo -n "Apply this new goal? (y/N): "
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo "$NEW_GOAL" > "$GOALFILE"
            echo "[MAINTENANCE] goal.md updated successfully."
        fi
    else
        echo "$NEW_GOAL" > "$GOALFILE"
        echo "[MAINTENANCE] Cron/Non-interactive: goal.md updated automatically."
    fi
else
    echo "[MAINTENANCE] No new goals generated."
fi
