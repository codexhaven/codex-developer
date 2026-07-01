#!/usr/bin/env bash
# HEALER CAPTURE — Capture failure trace
set -euo pipefail

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

TRACE_FILE="${REPODIR}/.codex/healer_trace.txt"
ERROR_LOG="${REPODIR}/.codex/last_error.log"
CYCLE_LOG="${REPODIR}/.codex/cycle-log.jsonl"
STATE_FILE="${REPODIR}/.codex/state.json"

# --- Step 1: Capture the full failure context ---
log_msg "Capturing failure trace..."

{
  echo "=== HEALER RUN: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
  echo ""
  
  # Last error
  if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
    echo "--- Last Error Log ---"
    tail -30 "$ERROR_LOG"
    echo ""
  fi
  
  # Recent cycle logs
  if [ -f "$CYCLE_LOG" ] && [ -s "$CYCLE_LOG" ]; then
    echo "--- Recent Cycles ---"
    tail -10 "$CYCLE_LOG"
    echo ""
  fi
  
  # Last 5 files built (from state)
  if [ -f "$STATE_FILE" ]; then
    echo "--- Last Files Built ---"
    python3 -c "
import json
s = json.load(open('$STATE_FILE'))
for f in s.get('files_built', [])[-5:]:
    print(f)
" 2>/dev/null
    echo ""
  fi
  
  # Current queue status
  if [ -f "${REPODIR}/.codex/build-queue.txt" ]; then
    echo "--- Remaining Queue ---"
    head -10 "${REPODIR}/.codex/build-queue.txt"
    echo ""
  fi
} > "$TRACE_FILE"

log_msg "Failure trace captured to $TRACE_FILE"
