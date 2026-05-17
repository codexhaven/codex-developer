#!/bin/bash
# sandbox/recon.sh - Automated research + phase planning module
# Dedicated to listen.sh — only runs when executed directly, not when sourced

recon_main() {
  REPODIR="${1:-${REPODIR:-${CODEX_REPO:-}}}"
  GOALFILE="${REPODIR}/.codex/goal.md"
  RESEARCHFILE="${REPODIR}/.codex/research.md"
  PHASESFILE="${REPODIR}/.codex/phases.json"
  BRAINFILE="${REPODIR}/.codex/project_brain.md"
  LOGFILE="${REPODIR}/.codex/research.log"

  if [ ! -f "$GOALFILE" ]; then
    echo "[RECON] No goal.md found. Skipping." >&2
    return 0
  fi

  GOAL=$(cat "$GOALFILE")
  echo "[RECON] Researching: $GOAL" >&2

  set +euo pipefail 2>/dev/null
  hermes chat -q \
    "Research the architecture, core technologies, algorithms, file formats, and best practices for building: $GOAL. Output a comprehensive technical summary for a software architect." \
    --yolo --quiet \
    > "$RESEARCHFILE" \
    2> "$LOGFILE"
  RESEARCH_EXIT=$?
  set -euo pipefail

  if [ $RESEARCH_EXIT -ne 0 ] || [ ! -s "$RESEARCHFILE" ]; then
    echo "[RECON] Research failed (exit $RESEARCH_EXIT)." >&2
    return 0
  fi

  echo "[RECON] Research complete. Generating phase plan..." >&2
  RESEARCH=$(cat "$RESEARCHFILE")

  set +euo pipefail 2>/dev/null
  hermes chat -q \
    "Based on this technical research, create a development phase plan as a JSON object with 'phases' array. Each phase must have: 'id', 'name', 'description', 'files' (array of file paths). Order phases from foundation to completion. Output ONLY valid JSON, no markdown fences.

Research:
$RESEARCH

Project goal: $GOAL" \
    --yolo --quiet \
    > "$PHASESFILE" \
    2>> "$LOGFILE"
  PHASES_EXIT=$?
  set -euo pipefail

  if [ $PHASES_EXIT -ne 0 ] || [ ! -s "$PHASESFILE" ]; then
    echo "[RECON] Phase generation failed." >&2
    return 0
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

  {
    echo "# Project Brain"
    echo ""
    echo "## Research"
    cat "$RESEARCHFILE"
    echo ""
    echo "## Phase Plan"
    python3 -c "import json; data=json.load(open('$PHASESFILE')); [print(f'### {p.get(\"name\",p.get(\"id\"))}\n{p.get(\"description\",\"\")}\nFiles: {p.get(\"files\",[])})') for p in data.get('phases',[])]" 2>/dev/null
  } > "$BRAINFILE" 2>/dev/null || true

  echo "[RECON] Done." >&2
}

# Only run when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  recon_main "$@"
fi
