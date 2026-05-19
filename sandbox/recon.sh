#!/bin/bash
# sandbox/recon.sh - Iterative research + phase planning
# Round 1: Research → Gap analysis → Round 2: Fill gaps → Generate phases

recon_main() {
  REPODIR="${1:-${REPODIR:-${CODEX_REPO:-}}}"
  GOALFILE="${REPODIR}/.codex/goal.md"
  RESEARCHFILE="${REPODIR}/.codex/research.md"
  PHASESFILE="${REPODIR}/.codex/phases.json"
  BRAINFILE="${REPODIR}/.codex/project_brain.md"
  LOGFILE="${REPODIR}/.codex/research.log"

  [ -f "$GOALFILE" ] || { echo "[RECON] No goal.md. Skipping." >&2; return 0; }
  GOAL=$(cat "$GOALFILE")
  echo "[RECON] Researching: $GOAL" >&2

  # --- Round 1: Initial research ---
  set +euo pipefail 2>/dev/null
  hermes chat -q \
    "Research this project thoroughly. Include: specific technologies, real API endpoints if applicable, auth mechanisms, file formats, platform constraints (Termux/Android), and concrete implementation details. Output a technical summary.

Project: $GOAL" \
    --yolo --quiet > "$RESEARCHFILE" 2> "$LOGFILE"
  local R1_EXIT=$?
  set -euo pipefail

  if [ $R1_EXIT -ne 0 ] || [ ! -s "$RESEARCHFILE" ]; then
    echo "[RECON] Research failed." >&2; return 0
  fi

  # --- Gap analysis: what's missing? ---
  local RESEARCH=$(cat "$RESEARCHFILE")
  echo "[RECON] Analyzing gaps..." >&2
  
  set +euo pipefail 2>/dev/null
  local gaps=$(hermes chat -q \
    "What critical details are MISSING from this research? What must be known before building? List 3-5 specific questions that need answers. Be concise.

Research:
$RESEARCH

Project: $GOAL" \
    --yolo --quiet 2>> "$LOGFILE")
  set -euo pipefail

  # --- Round 2: Fill the gaps ---
  if [ -n "$gaps" ] && [ "$gaps" != "None." ]; then
    echo "[RECON] Round 2: filling gaps..." >&2
    set +euo pipefail 2>/dev/null
    hermes chat -q \
      "Answer these questions with specific, concrete details. Include real endpoints, real auth flows, real file paths.

Questions:
$gaps

Original research:
$RESEARCH

Project: $GOAL" \
      --yolo --quiet >> "$RESEARCHFILE" 2>> "$LOGFILE"
    set -euo pipefail
  fi

  RESEARCH=$(cat "$RESEARCHFILE")
  echo "[RECON] Research complete. Generating phase plan..." >&2

  # --- Determine project complexity ---
  local file_count_estimate=$(echo "$GOAL" | grep -oE '\b(file|module|script|component)\b' | wc -l)
  local structure_hint="SIMPLE"
  # If the goal mentions many components, use package structure
  if echo "$GOAL" | grep -qiE "web|saas|full.stack|platform|api.*database|multiple.*module|complex|system"; then
    structure_hint="PACKAGE"
  fi

  # --- Generate phases ---
  set +euo pipefail 2>/dev/null
  hermes chat -q \
    "Create a development phase plan as JSON with 'phases' array. Each phase: 'id', 'name', 'description', 'files' (array).

CRITICAL RULES:
- Project complexity: $structure_hint
- If SIMPLE (≤5 files total): put ALL files at project root. NO subdirectories like src/ or lib/. Just flat files.
- If PACKAGE: use standard src/ structure.
- Files must be PRACTICAL, not theoretical. No __init__.py unless truly needed.
- Total files across ALL phases should match the project scope.

Research:
$RESEARCH

Project: $GOAL

Output ONLY valid JSON, no markdown fences." \
    --yolo --quiet > "$PHASESFILE" 2>> "$LOGFILE"
  local P_EXIT=$?
  set -euo pipefail

  if [ $P_EXIT -ne 0 ] || [ ! -s "$PHASESFILE" ]; then
    echo "[RECON] Phase generation failed." >&2; return 0
  fi

  if python3 -c "import json; json.load(open('$PHASESFILE'))" 2>/dev/null; then
    echo "[RECON] phases.json valid." >&2
    python3 -c "
import json
data = json.load(open('$PHASESFILE'))
for i, p in enumerate(data.get('phases', [])):
    print(f'  Phase {i+1}: {p.get(\"name\", p.get(\"id\", \"unnamed\"))} ({len(p.get(\"files\", []))} files)')
" >&2
  else
    echo "[RECON] phases.json is invalid JSON." >&2
  fi

  # --- Project brain ---
  {
    echo "# Project Brain"
    echo ""
    echo "## Research (2 rounds)"
    cat "$RESEARCHFILE"
    echo ""
    echo "## Phase Plan"
    python3 -c "import json; data=json.load(open('$PHASESFILE')); [print(f'### {p.get(\"name\",p.get(\"id\"))}\n{p.get(\"description\",\"\")}\nFiles: {p.get(\"files\",[])})') for p in data.get('phases',[])]" 2>/dev/null
  } > "$BRAINFILE" 2>/dev/null || true

  echo "[RECON] Done." >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  recon_main "$@"
fi
