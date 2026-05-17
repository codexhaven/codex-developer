#!/usr/bin/env bash
# HEALER MODULE: Structural Pivot and Traceback Analysis
# Now integrated with state.json persistence

log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

log_msg "Analyzing failure trace..."
# Capture last failed command stderr
# Use a file within the project directory to avoid permission issues in /tmp
HEALER_CONTEXT="${REPODIR}/.codex/healer_context.txt"

# Look in .codex first, then fall back to generic error
if [ -f "${REPODIR}/.codex/last_error.log" ]; then
    tail -n 20 "${REPODIR}/.codex/last_error.log" > "$HEALER_CONTEXT"
elif [ -f "${REPODIR}/.codex/cycle-log.jsonl" ]; then
    tail -n 20 "${REPODIR}/.codex/cycle-log.jsonl" > "$HEALER_CONTEXT"
else
    echo "No recent log found. Forcing structural re-evaluation." > "$HEALER_CONTEXT"
fi

python3 -c "import json, os; s=json.load(open('${REPODIR}/.codex/state.json')); s['failure_count']=0; json.dump(s, open('${REPODIR}/.codex/state.json', 'w'), indent=2)"

log_msg "Injecting context for pivot..."
# Trigger structural repair via Hermes agent
log_msg "Invoking Agent for Structural Repair..."
hermes chat "The build failed. Analyze ${HEALER_CONTEXT} and perform a structural fix for the project. Output only the patch or necessary actions." --quiet >> "${REPODIR}/.codex/cycle-log.jsonl" 2>&1
log_msg "Structural pivot queued and failure state reset."
