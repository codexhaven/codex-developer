#!/usr/bin/env bash
# HEALER ANALYZE — Identify root cause and write to file
set -euo pipefail

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

TRACE_FILE="${REPODIR}/.codex/healer_trace.txt"
HEALER_ROOT_CAUSE_FILE="${REPODIR}/.codex/healer_root_cause.txt"

# --- Step 2: Identify the root cause ---
log_msg "Tracing root cause..."

#Function to attempt hermes call and validate output
get_root_cause() {
  local trace_content
  trace_content=$(cat "$TRACE_FILE")
  local attempt=1
  local max_attempts=3
  while [ $attempt -le $max_attempts ]; do
    local output
    output=$(hermes chat -q \
"Analyze this build failure trace. Identify the ROOT CAUSE — not the symptom, but the underlying issue. 
Output format:
ROOT_FILE: <single file that needs fixing>
ROOT_ISSUE: <brief description>
FIX_ACTION: <what to do>

Trace:
$trace_content" \
      --yolo --quiet 2>/dev/null) || true
    # Check if output contains the expected markers
    if [ -n "$output" ] && echo "$output" | grep -q "ROOT_FILE:" && echo "$output" | grep -q "ROOT_ISSUE:" && echo "$output" | grep -q "FIX_ACTION:"; then
      echo "$output"
      return 0
    fi
    log_msg "Attempt $attempt did not produce valid root cause output."
    attempt=$((attempt+1))
  done
  # If all attempts failed, return a default indicating failure
  echo "ROOT_FILE: unknown
ROOT_ISSUE: Could not analyze after multiple attempts
FIX_ACTION: Retry the last failed file"
}

ROOT_CAUSE=$(get_root_cause)

ROOT_FILE=$(echo "$ROOT_CAUSE" | grep "ROOT_FILE:" | sed 's/ROOT_FILE:\s*//' | head -1 | xargs)
ROOT_ISSUE=$(echo "$ROOT_CAUSE" | grep "ROOT_ISSUE:" | sed 's/ROOT_ISSUE:\s*//' | head -1)
FIX_ACTION=$(echo "$ROOT_CAUSE" | grep "FIX_ACTION:" | sed 's/FIX_ACTION:\s*//' | head -1)

log_msg "Root file: ${ROOT_FILE:-unknown}"
log_msg "Issue: ${ROOT_ISSUE:-unknown}"
log_msg "Action: ${FIX_ACTION:-retry}"

# Write to file for the next step
{
  echo "ROOT_FILE=$ROOT_FILE"
  echo "ROOT_ISSUE=$ROOT_ISSUE"
  echo "FIX_ACTION=$FIX_ACTION"
} > "$HEALER_ROOT_CAUSE_FILE"

log_msg "Root cause written to $HEALER_ROOT_CAUSE_FILE"
