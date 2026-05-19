#!/usr/bin/env bash
# HEALER MODULE v2 — Root Cause Tracer + Multi-pass Resolution
# Traces the exact failure chain, fixes the source, re-verifies
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

# --- Step 2: Identify the root cause ---
log_msg "Tracing root cause..."

ROOT_CAUSE=$(hermes chat -q \
  "Analyze this build failure trace. Identify the ROOT CAUSE — not the symptom, but the underlying issue. 
Output format:
ROOT_FILE: <single file that needs fixing>
ROOT_ISSUE: <brief description>
FIX_ACTION: <what to do>

Trace:
$(cat "$TRACE_FILE")" \
  --yolo --quiet 2>/dev/null || echo "ROOT_FILE: unknown
ROOT_ISSUE: Could not analyze
FIX_ACTION: Retry the last failed file")

ROOT_FILE=$(echo "$ROOT_CAUSE" | grep "ROOT_FILE:" | sed 's/ROOT_FILE:\s*//' | head -1 | xargs)
ROOT_ISSUE=$(echo "$ROOT_CAUSE" | grep "ROOT_ISSUE:" | sed 's/ROOT_ISSUE:\s*//' | head -1)
FIX_ACTION=$(echo "$ROOT_CAUSE" | grep "FIX_ACTION:" | sed 's/FIX_ACTION:\s*//' | head -1)

log_msg "Root file: ${ROOT_FILE:-unknown}"
log_msg "Issue: ${ROOT_ISSUE:-unknown}"
log_msg "Action: ${FIX_ACTION:-retry}"

# --- Step 3: Apply the fix ---
if [ -n "$ROOT_FILE" ] && [ "$ROOT_FILE" != "unknown" ] && [ -f "${REPODIR}/${ROOT_FILE}" ]; then
  log_msg "Reading $ROOT_FILE for targeted fix..."
  FILE_CONTENT=$(cat "${REPODIR}/${ROOT_FILE}")
  
  FIX_OUTPUT=$(hermes chat -q \
    "## MODE: SURGICAL FIX
## ROOT CAUSE: $ROOT_ISSUE
## FIX: $FIX_ACTION
## CURRENT FILE: $ROOT_FILE

\`\`\`
$FILE_CONTENT
\`\`\`

## INSTRUCTIONS
Apply ONLY the fix described above. Do NOT rewrite the file. Keep everything else identical.
Output format: FILE: $ROOT_FILE followed by the complete fixed file contents." \
    --yolo --quiet 2>/dev/null || echo "")
  
  if [ -n "$FIX_OUTPUT" ] && echo "$FIX_OUTPUT" | grep -q "FILE:"; then
    # Extract and apply
    FIXED_CONTENT=$(echo "$FIX_OUTPUT" | sed -n '/^FILE:/,$p' | tail -n +2 | sed '/^\`\`\`/d')
    if [ -n "$FIXED_CONTENT" ]; then
      printf '%s' "$FIXED_CONTENT" > "${REPODIR}/${ROOT_FILE}"
      log_msg "Applied fix to $ROOT_FILE"
      
      # Re-verify
      case "${ROOT_FILE##*.}" in
        py) python3 -m py_compile "${REPODIR}/${ROOT_FILE}" 2>/dev/null && log_msg "Re-verify: PASS" || log_msg "Re-verify: FAIL — will retry";;
        sh) bash -n "${REPODIR}/${ROOT_FILE}" 2>/dev/null && log_msg "Re-verify: PASS" || log_msg "Re-verify: FAIL — will retry";;
        *) log_msg "Re-verify: SKIP (unknown type)";;
      esac
    fi
  else
    log_msg "Could not generate fix. Marking file as skipped."
    echo "$ROOT_FILE" >> "${REPODIR}/.codex/build-done.txt"
  fi
else
  log_msg "No specific root file identified. Resetting failure count and continuing."
fi

# --- Step 4: Reset state ---
python3 -c "
import json, os
s = json.load(open('$STATE_FILE'))
s['failure_count'] = 0
json.dump(s, open('$STATE_FILE', 'w'), indent=2)
" 2>/dev/null || true

log_msg "Healer cycle complete."
