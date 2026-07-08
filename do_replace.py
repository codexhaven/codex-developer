import sys
"""Codex Developer v12.6 — Generated module."""
# ctx: codexhaven

# Read the file
with open('sandbox/recon.sh', 'r') as f:
    lines = f.readlines()

# Define the new block as a raw string with correct indentation (two spaces)
newblock = r'''  # STEP 1: Architecture design informed by domain research (with retries for valid JSON)
  echo "[RECON] Getting architecture design from LLM (will retry up to 3 times for valid JSON)..." >&2
  local attempt=1
  local max_attempts=3
  local success=0
  while [ $attempt -le $max_attempts ] && [ $success -eq 0 ]; do
    # Build prompt (same each time, but could add emphasis on retry)
    local prompt="Design a complete, buildable architecture for this project. Think like an architect who has studied this domain deeply.

## PROJECT REQUEST
$GOAL

## DOMAIN RESEARCH (READ THIS FIRST)
$DOMAIN_CONTEXT

## STEP 1: EXTRACT REAL CAPABILITIES FROM DOMAIN
Based on the domain research, what must this tool actually DO? List concrete, specific actions tied to real workflows discovered in the research.
BAD: 'storage system', 'validation', 'file management', 'save_data', 'process_request', 'get_items', 'update_record'
GOOD: 'register_new_driver', 'track_daily_collections', 'generate_revenue_report', 'send_bulk_sms', 'verify_driver_license'

## STEP 2: GROUP INTO FILES (MAXIMUM 5)
Group related capabilities. Each file = one clear domain. Use as many files as the domain genuinely needs — don't force too few or too many.
- NO generic utility files. No 'utils.py', 'config.py', 'helpers.py', 'common.py'
- If a file would only have 1 tiny function, merge it into another file
- BUT don't cram unrelated features into one file just to hit a file count
- File names should reflect the domain: 'drivers.py' not 'database.py'

## STEP 3: DEFINE EVERY FUNCTION
For every capability, write the exact function signature with:
- Function name (verb_noun format)
- Parameters with types
- Return type
- The REAL shell command, HTTP request, or SQL query that implements it

Example:
{\"\type\": \"function\", \"name\": \"get_wifi_password\", \"params\": [], \"returns\": \"str\", \"command\": \"dumpsys wifi | grep -A20 mWifiInfo | grep pss | cut -d= -f2\", \"description\": \"Extract current WiFi password from Android\"}

BAD command: 'validate input', 'save data', 'process request'
GOOD command: 'curl -s http://IP/login -d \"user=admin&pass=1234\"', 'sqlite3 db \"SELECT psk FROM passwords\"', 'ip route show default'

## STEP 4: MAP ALL IMPORTS
For every file, list exactly which other files it imports.

## STEP 5: ORDER PHASES
Files with no imports first. Then files that depend on those. Max 3 phases.

## OUTPUT FORMAT — Valid JSON only
{
  \"research\": \"2-3 sentences about implementation approach\",
  \"modules\": {
    \"scanner.py\": {
      \"description\": \"what this file does\",
      \"exports\": [
        {\"type\": \"function\", \"name\": \"func_name\", \"params\": [{\"name\": \"param1\", \"type\": \"str\"}], \"returns\": \"bool\", \"command\": \"real shell command here\", \"description\": \"what this does\"}
      ],
      \"imports\": []
    }
  },
  \"phases\": [
    {\"id\": \"phase-1\", \"name\": \"Foundation\", \"description\": \"...\", \"files\": [\"file1.py\"]}
  ]
}

## ABSOLUTE RULES
- Use the right number of files for the domain. Don't over-consolidate or over-split.
- Every function MUST have a 'command' field with a REAL shell/HTTP/SQL command.
- NO generic utility files (utils, config, helpers, common, validator, file_system).
- NO simulated steps. NO 'echo data > file' as a real command.
- Available tools: python3, curl, wget, timeout, bash, sqlite3, dumpsys, ip, ping, grep, awk, sed
- Target the platform that makes sense for this project. State the target in research.
- File paths relative: 'scanner.py' not '/home/user/scanner.png'
- Every file in phases MUST be in modules. Every module in at least one phase.
- DESIGN FOR THE DOMAIN. A matatu portal should feel like a matapool, not a todo list.
- If alignment fails, the build will break. Get it right the first time.

Output ONLY valid JSON. No markdown fences. No explanation text.
"
    # Optionally, on later attempts, add a note
    if [ $attempt -gt 1 ]; then
      prompt="$prompt

IMPORTANT: You MUST output ONLY a valid JSON object. Do not include any explanatory text, markdown formatting, or additional characters. Your entire response must be parseable as JSON."
    fi
    # Attempt to get output from LLM
    local raw_output
    if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
      raw_output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$prompt" 2>>"$LOGFILE")
    else
      raw_output=$(hermes chat -q "$prompt" --yolo --quiet 2>>"$LOGFILE") || true
    fi
    # Check if output is non-empty and looks like JSON
    if [ -n \"$raw_output\" ]; then
      # Trim whitespace
      local trimmed
      trimmed=$(echo \"$raw_output\" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      # Check if it starts with { and ends with }
      if [[ \"$trimmed\" == \{* && \"$trimmed\" == *\} ]]; then
        # Validate with Python
        if python3 -c \"import json,sys; json.loads(sys.stdin.read())\" <<< \"$trimmed\" 2>/dev/null; then
          echo \"$trimmed\" > \"$CONTRACTFILE\"
          success=1
          echo \"[RECON] Successfully obtained valid JSON on attempt $attempt.\" >&2
          break
        fi
      fi
    fi
    echo "[RECON] Attempt $attempt did not produce valid JSON." >&2
    attempt=$((($attempt+1)))
  done

  if [ $success -eq 0 ]; then
    echo "[RECON] All attempts failed to produce valid JSON. Using empty skeleton." >&2
    # Write a minimal valid JSON to keep the pipeline going
    printf '{\\\\\\\"research\\\\\\\": \\\\\\\"Failed to generate architecture; using fallback.\\\\\\\", \\\\\\\"modules\\\\\\\": {}, \\\\\\\"phases\\\\\\\": []}\\n' > \"$CONTRACTFILE\"
  fi
'''

# Ensure newblock ends with a newline
if not newblock.endswith('\n'):
    newblock += '\n'
# Split into lines
newblock_lines = newblock.splitlines(keepends=True)

# Define start and end indices (0-indexed, inclusive start, exclusive end)
start = 29  # line 30 (0-indexed 29)
end_excl = 106  # up to but not including line 106 (0-indexed 105) -> we want to replace lines 30-106 inclusive? Let's verify.
# We want to replace lines 30-106 inclusive (1-indexed). That's indices 29-105 inclusive.
# So end_excl = 106 (since index 106 is line 107).
new_lines = lines[:start] + newblock_lines + lines[end_excl:]

# Write back
with open('sandbox/recon.sh', 'w') as f:
    f.writelines(new_lines)

print('Replacement completed. Lines replaced:', start, 'to', end_excl-1)
