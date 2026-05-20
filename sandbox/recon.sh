#!/bin/bash
# sandbox/recon.sh v3 — Deep research with technology selection + interface specificity

recon_main() {
  REPODIR="${1:-${REPODIR:-${CODEX_REPO:-}}}"
  GOALFILE="${REPODIR}/.codex/goal.md"
  RESEARCHFILE="${REPODIR}/.codex/research.md"
  CAPFILE="${REPODIR}/.codex/capabilities.json"
  PHASESFILE="${REPODIR}/.codex/phases.json"
  BRAINFILE="${REPODIR}/.codex/project_brain.md"
  LOGFILE="${REPODIR}/.codex/research.log"

  [ -f "$GOALFILE" ] || { echo "[RECON] No goal.md. Skipping." >&2; return 0; }
  GOAL=$(cat "$GOALFILE")
  
  # Load existing capabilities
  CAP_CONTEXT=""
  [ -f "$CAPFILE" ] && CAP_CONTEXT=$(python3 -c "import json; caps=json.load(open('$CAPFILE')); print('Existing capabilities:', json.dumps({k: list(v.keys()) for k,v in caps.items()}))" 2>/dev/null)

  echo "[RECON] Researching: $GOAL" >&2

  # --- Round 1: Deep technology research ---
  set +euo pipefail 2>/dev/null
  hermes chat -q \
"Research this project for Termux/Android. Provide SPECIFIC technology choices with exact package names, module names, and function signatures.

## PROJECT
$GOAL

## PLATFORM CONSTRAINTS
- Termux on Android (ARM64)
- No GPU available
- No Docker available
- Python 3.10+ available
- Node.js available
- SQLite available (no PostgreSQL/MySQL)
- Root access: likely unavailable
- Storage: $HOME is /data/data/com.termux/files/home

## EXISTING CAPABILITIES
$CAP_CONTEXT

## OUTPUT REQUIREMENTS
Provide:
1. TECHNOLOGY STACK: exact packages with versions (e.g., 'bcrypt==4.1.2', not 'a hashing library')
2. INTERFACE SIGNATURES: actual function signatures with parameter names and types
   Example: 'def hash_password(plaintext: str) -> bytes' not 'password hashing function'
3. FILE STRUCTURE: exactly which files, their paths, and why
4. DATA FLOW: how data moves between modules
5. ERROR HANDLING: specific error types and how they propagate

Be specific. No generic advice. Real code-level detail." \
    --yolo --quiet > "$RESEARCHFILE" 2> "$LOGFILE"
  local R1_EXIT=$?
  set -euo pipefail

  if [ $R1_EXIT -ne 0 ] || [ ! -s "$RESEARCHFILE" ]; then
    echo "[RECON] Research failed." >&2; return 0
  fi

  local RESEARCH=$(cat "$RESEARCHFILE")

  # --- Gap analysis ---
  echo "[RECON] Analyzing gaps..." >&2
  set +euo pipefail 2>/dev/null
  local gaps=$(hermes chat -q \
"Review this research. What critical implementation details are MISSING?
List 3-5 specific gaps. Focus on:
- Missing function signatures
- Unspecified error handling
- Missing import paths
- Platform-specific issues not addressed
- Security considerations not covered

Research:
$RESEARCH

Project: $GOAL" \
    --yolo --quiet 2>> "$LOGFILE")
  set -euo pipefail

  # --- Round 2: Fill gaps ---
  if [ -n "$gaps" ] && [ "$gaps" != "None." ] && [ "$gaps" != "" ]; then
    echo "[RECON] Round 2: filling gaps..." >&2
    set +euo pipefail 2>/dev/null
    hermes chat -q \
"Fill these specific gaps with concrete implementation details. Provide exact code-level answers.

GAPS:
$gaps

Original research:
$RESEARCH

Project: $GOAL" \
      --yolo --quiet >> "$RESEARCHFILE" 2>> "$LOGFILE"
    set -euo pipefail
  fi

  RESEARCH=$(cat "$RESEARCHFILE")
  echo "[RECON] Research complete. Generating phase plan..." >&2

  # --- Complexity detection ---
  local file_count=$(echo "$RESEARCH" | grep -oE '\b[a-zA-Z_/-]+\.(py|js|ts|tsx|sh|json|yaml|toml)\b' | sort -u | wc -l)
  local structure="SIMPLE"
  [ "$file_count" -gt 6 ] && structure="PACKAGE"
  [ "$file_count" -gt 15 ] && structure="COMPLEX"
  echo "[RECON] Detected: $file_count files → $structure structure" >&2

  # --- Generate phases ---
  set +euo pipefail 2>/dev/null
  hermes chat -q \
"Create a development phase plan as JSON with 'phases' array. Each phase: 'id', 'name', 'description', 'files' (array of exact file paths).

## CRITICAL RULES
- Structure type: $structure
- SIMPLE (≤6 files): ALL files at project root. No src/, no lib/, no subdirectories.
- PACKAGE (7-15 files): Use src/ for modules, tests/ for tests.
- COMPLEX (16+ files): Full package structure with submodules.
- Files MUST use exact paths from the research. No invented files.
- No __init__.py unless the structure is COMPLEX.
- No pyproject.toml or setup.py unless the project is a library.
- Every file must appear in the research. No extras.

## RESEARCH
$RESEARCH

## PROJECT
$GOAL

Output ONLY valid JSON. No markdown." \
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
    files = p.get('files', [])
    print(f'  Phase {i+1}: {p.get(\"name\", p.get(\"id\", \"unnamed\"))} ({len(files)} files)')
" >&2
  else
    echo "[RECON] phases.json is invalid JSON." >&2
  fi

  # --- Project brain ---
  {
    echo "# Project Brain — $(date +%Y-%m-%d)"
    echo ""
    echo "## Research (2 rounds with gap analysis)"
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
