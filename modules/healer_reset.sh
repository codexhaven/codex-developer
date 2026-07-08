#!/usr/bin/env bash
# HEALER RESET — Reset state and clean up
set -euo pipefail
# ctx: codexhaven

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && (pwd -P 2>/dev/null || pwd))"
log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

STATE_FILE="${REPODIR}/.codex/state.json"
TRACE_FILE="${REPODIR}/.codex/healer_trace.txt"
ROOT_CAUSE_FILE="${REPODIR}/.codex/healer_root_cause.txt"

# --- Step 4: Reset state ---
log_msg "Resetting state and cleaning up..."

# Mark that we've attempted a heal so runcycle doesn't loop
if [ -f "$STATE_FILE" ]; then
  python3 -c "
import json
with open('$STATE_FILE', 'r') as f:
    data = json.load(f)
data['heal_attempted'] = True
with open('$STATE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
fi

# Clean up temporary files (keep trace for debugging, remove root cause)
rm -f "$ROOT_CAUSE_FILE"

log_msg "Healer cycle complete."
