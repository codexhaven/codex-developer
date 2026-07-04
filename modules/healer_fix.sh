#!/usr/bin/env bash
# HEALER FIX — Apply surgical fix
set -euo pipefail
# ctx: codexhaven

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && (pwd -P 2>/dev/null || pwd))"
log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

TRACE_FILE="${REPODIR}/.codex/healer_trace.txt"
HEALER_ROOT_CAUSE_FILE="${REPODIR}/.codex/healer_root_cause.txt"
ERROR_LOG="${REPODIR}/.codex/last_error.log"
CYCLE_LOG="${REPODIR}/.codex/cycle-log.jsonl"
STATE_FILE="${REPODIR}/.codex/state.json"

# --- Step 3: Apply the fix ---
log_msg "Applying fix..."

# Source the root cause file if it exists
if [ -f "$HEALER_ROOT_CAUSE_FILE" ]; then
  # shellcheck disable=SC1090
  source "$HEALER_ROOT_CAUSE_FILE"
else
  log_msg "Root cause file not found. Assuming no action needed."
  ROOT_FILE="unknown"
fi

log_msg "Root file: ${ROOT_FILE:-unknown}"
log_msg "Issue: ${ROOT_ISSUE:-unknown}"
log_msg "Action: ${FIX_ACTION:-retry}"

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
      queue_emergency "$ROOT_FILE" "Healer applied surgical fix"
      log_msg "Applied fix to $ROOT_FILE"
    else
      log_msg "Failed to extract fixed content from Hermes response."
    fi
  else
    log_msg "Hermes did not return a valid fix. Skipping file modification."
  fi
else
  log_msg "No specific root file identified. Resetting failure count and continuing."
fi

# Helper function for queueing emergency (same as in original)
queue_emergency() {
  local file="$1"
  local reason="$2"
  if [ -f "${REPODIR}/.codex/build-queue.txt" ]; then
    # Avoid duplicates
    if ! grep -q "^$file$" "${REPODIR}/.codex/build-queue.txt"; then
      echo "$file" >> "${REPODIR}/.codex/build-queue.txt"
      log_msg "Queued $file for rebuild: $reason"
    fi
  fi
}

# Fix missing try/except in functions (not used in main flow, but kept for compatibility)
fix_error_handling() {
  local filepath="$1"
  local content=$(cat "$filepath")
  
  # Check if functions lack try/except
  if grep -q "^def " "$filepath" && ! grep -q "try:" "$filepath"; then
    log_msg "Adding error handling to $filepath"
    
    python3 -c "
import re
with open('$filepath', 'r') as f:
    content = f.read()

# Find functions without try/except
pattern = r'(def \w+\([^)]*\):.*?(?=\\n def |\\nclass |\\Z))'
def add_try_except(match):
    func = match.group(0)
    if 'try:' in func or 'logger' not in func:
        return func
    # Add try/except wrapper
    lines = func.split('\\n')
    indent = len(lines[0]) - len(lines[0].lstrip())
    indentation = ' ' * indent
    new_lines = [lines[0]]
    new_lines.append(f'{indentation}    try:')
    for line in lines[1:]:
        if line.strip():
            new_lines.append(f'{indentation}        {line.lstrip()}')
    new_lines.append(f'{indentation}    except Exception as e:')
    new_lines.append(f'{indentation}        self.logger.error(f\"Function failed: {{e}}\")')
    new_lines.append(f'{indentation}        return None')
    return '\\n'.join(new_lines)

content = re.sub(pattern, add_try_except, content, flags=re.DOTALL)
with open('$filepath', 'w') as f:
    f.write(content)
print(f'[HEALER] Added error handling to $filepath')
" 2>/dev/null || true
  fi
}

# Fix sync functions that should be async (not used in main flow, but kept for compatibility)
fix_async_patterns() {
  local filepath="$1"
  
  # Check if file contains I/O operations without async
  if grep -qE "(requests\\.|subprocess\\.|open\\(|sqlite3\\.|curl)" "$filepath"; then
    if ! grep -q "async def" "$filepath"; then
      log_msg "Adding async patterns to $filepath"
      
      sed -i 's/^def /async def /g' "$filepath"
      sed -i 's/requests\\.get/await asyncio.to_thread(requests.get)/g' "$filepath"
      sed -i 's/subprocess\\.run/await asyncio.to_thread(subprocess.run)/g' "$filepath"
      
      # Add asyncio import if missing
      if ! grep -q "import asyncio" "$filepath"; then
        sed -i '1iimport asyncio' "$filepath"
      fi
      
      echo "[HEALER] Made async: $filepath"
    fi
  fi
}
