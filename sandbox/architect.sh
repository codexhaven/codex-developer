#!/bin/bash
# Architect v4 — Master contract + recursive sub-contracts + state persistence

architect_contract() {
  local REPODIR="${1:-${REPODIR:-.}}"
  local GOALFILE="${REPODIR}/.codex/goal.md"
  local RESEARCHFILE="${REPODIR}/.codex/research.md"
  local CONTRACTFILE="${REPODIR}/.codex/contract.json"
  local PHASESFILE="${REPODIR}/.codex/phases.json"
  local DEPGRAPH="${REPODIR}/.codex/dependency_graph.json"
  local STATEFILE="${REPODIR}/.codex/state.json"
  local SCOPE="${2:-master}"

  echo "[ARCHITECT] Generating ${SCOPE} contract..."

  GOAL=$(cat "$GOALFILE")
  RESEARCH=$(cat "$RESEARCHFILE" 2>/dev/null || echo "")

  # Determine scope prompt
  local scope_instruction=""
  if [ "$SCOPE" = "master" ]; then
    scope_instruction="Design the MASTER architecture. Modules should be high-level (e.g., 'auth', 'database', 'api', 'ui'). Each module's exports should define the PUBLIC interface only. Internal implementation details go in sub-contracts later."
  else
    scope_instruction="Design the INTERNAL architecture for the '$SCOPE' module. Define ALL internal functions, classes, and their signatures. This is exhaustive — list everything this module needs."
  fi

  hermes chat -q \
"$scope_instruction

## PROJECT
$GOAL

## RESEARCH
${RESEARCH:0:3000}

## OUTPUT
{
  \"project\": \"name\",
  \"scope\": \"$SCOPE\",
  \"modules\": {
    \"path/to/file.py\": {
      \"description\": \"...\",
      \"exports\": [{ \"type\": \"function\", \"name\": \"...\", \"params\": [...], \"returns\": \"...\" }],
      \"imports\": [\"other.py\"]
    }
  },
  \"phases\": [
    { \"id\": \"phase-1\", \"name\": \"...\", \"description\": \"...\", \"files\": [\"file1.py\"] }
  ]
}

## RULES
- File paths relative. No absolute paths.
- Every file in phases MUST exist in modules.
- Dependencies must be acyclic.
- MASTER scope: 3-6 high-level modules, public interfaces only.
- SUB scope: exhaustive — every internal function defined.
- Files per phase: 3-8 (incremental — builds resume safely).
- Output ONLY valid JSON. No markdown." \
    --yolo --quiet > "$CONTRACTFILE" 2>/dev/null

  if python3 -c "import json; json.load(open('$CONTRACTFILE'))" 2>/dev/null; then
    python3 << 'PYEOF'
import json, os

repodir = os.environ.get('REPODIR', '.')
contract_file = os.path.join(repodir, '.codex', 'contract.json')
phases_file = os.path.join(repodir, '.codex', 'phases.json')
depgraph_file = os.path.join(repodir, '.codex', 'dependency_graph.json')
state_file = os.path.join(repodir, '.codex', 'state.json')

with open(contract_file) as f:
    data = json.load(f)

modules = data.get('modules', {})
phases = data.get('phases', [])
scope = data.get('scope', 'master')

# Write phases
with open(phases_file, 'w') as f:
    json.dump({"phases": phases, "current_phase": 0, "scope": scope}, f, indent=2)

# Dependency graph
depgraph = {}
for fname, mod in modules.items():
    imports = mod.get('imports', [])
    if imports:
        depgraph[fname] = imports
with open(depgraph_file, 'w') as f:
    json.dump(depgraph, f, indent=2)

# Initialize state with resume support
state = {
    "cycle": 0,
    "current_phase": 0,
    "scope": scope,
    "files_built": [],
    "phases_completed": [],
    "resume_point": None
}
if os.path.exists(state_file):
    with open(state_file) as f:
        old_state = json.load(f)
    state["cycle"] = old_state.get("cycle", 0)
    state["phases_completed"] = old_state.get("phases_completed", [])
with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

# Summary
print(f"[ARCHITECT] {scope.upper()} contract: {len(modules)} modules, {len(phases)} phases")
for fname, mod in modules.items():
    exports = mod.get('exports', [])
    imports = mod.get('imports', [])
    print(f"  {fname}: {len(exports)} exports, needs {imports}")
for i, p in enumerate(phases):
    print(f"  Phase {i+1}: {p.get('name', p.get('id'))} ({len(p.get('files', []))} files)")

# If master, queue sub-contracts for later phases
if scope == 'master':
    sub_contracts = os.path.join(repodir, '.codex', 'sub_contracts.json')
    subs = {}
    for p in phases:
        pid = p.get('id', '')
        if pid:
            subs[pid] = {"name": p.get('name', ''), "files": p.get('files', []), "built": False}
    with open(sub_contracts, 'w') as f:
        json.dump(subs, f, indent=2)
    print(f"[ARCHITECT] {len(subs)} sub-contracts queued for recursive building")
PYEOF
  else
    echo "[ARCHITECT] Generation failed."
  fi
}

# Gate: check file against current phase
architect_gate() {
  local filepath="$1"
  local phases="${REPODIR}/.codex/phases.json"
  local depgraph="${REPODIR}/.codex/dependency_graph.json"

  [ -f "$phases" ] || return 0

  python3 -c "
import json
phases = json.load(open('$phases'))
curr = phases.get('current_phase', 0)
phase_list = phases.get('phases', [])

if curr >= len(phase_list):
    exit(0)

current_files = phase_list[curr].get('files', [])
if '$filepath' in current_files:
    exit(0)

# Check dependency graph
dep = {}
if __import__('os').path.exists('$depgraph'):
    dep = json.load(open('$depgraph'))
for cf in current_files:
    if cf in dep and '$filepath' in dep[cf]:
        exit(0)

exit(1)
" 2>/dev/null
}

# Advance phase + trigger sub-contract if needed
architect_advance() {
  local phases="${REPODIR}/.codex/phases.json"
  local donefile="${REPODIR}/.codex/build-done.txt"
  local subs="${REPODIR}/.codex/sub_contracts.json"

  [ -f "$phases" ] || return 0
  [ -f "$donefile" ] || return 0

  python3 -c "
import json, os

phases = json.load(open('$phases'))
done = open('$donefile').read()
curr = phases.get('current_phase', 0)
phase_list = phases.get('phases', [])

if curr >= len(phase_list):
    exit(0)

current = phase_list[curr]
files = current.get('files', [])

all_done = all(f in done for f in files)
if all_done and files:
    phases['current_phase'] = curr + 1
    with open('$phases', 'w') as f:
        json.dump(phases, f, indent=2)
    
    # Update sub-contracts
    if os.path.exists('$subs'):
        subs = json.load(open('$subs'))
        pid = current.get('id', '')
        if pid in subs:
            subs[pid]['built'] = True
            with open('$subs', 'w') as f:
                json.dump(subs, f, indent=2)
    
    next_name = phase_list[curr+1].get('name', 'COMPLETE') if curr+1 < len(phase_list) else 'COMPLETE'
    print(f'PHASE {curr+1}→{curr+2}: {current.get(\"name\")} → {next_name}')
    
    # Trigger sub-contract expansion for the next phase
    if curr + 1 < len(phase_list):
        next_phase = phase_list[curr + 1]
        next_files = next_phase.get('files', [])
        # Expand sub-contract: generate internal files for this phase
        sub_contract_file = os.path.join(os.environ.get('REPODIR', '.'), '.codex', 'contract.json')
        queue_file = os.path.join(os.environ.get('REPODIR', '.'), '.codex', 'build-queue.txt')
        
        # Append internal files to queue if they exist in the master contract modules
        with open(sub_contract_file) as f:
            contract = json.load(f)
        
        modules = contract.get('modules', {})
        for nf in next_files:
            if nf in modules:
                mod = modules[nf]
                # Queue the file itself
                with open(queue_file, 'a') as qf:
                    qf.write(f'NEW:{nf}\n')
                # Also queue any files this module imports that haven't been built yet
                for imp in mod.get('imports', []):
                    if imp not in done:
                        with open(queue_file, 'a') as qf:
                            qf.write(f'NEW:{imp}\n')
        
        print(f'  Sub-contract expanded: {len(next_files)} files queued for phase {curr+2}')
    
    # Save resume point
    state_file = os.path.join(os.environ.get('REPODIR', '.'), '.codex', 'state.json')
    if os.path.exists(state_file):
        state = json.load(open(state_file))
        state['resume_point'] = curr + 1
        with open(state_file, 'w') as f:
            json.dump(state, f, indent=2)
" 2>/dev/null
}

# Resume: restore state from previous session
architect_resume() {
  local state="${REPODIR}/.codex/state.json"
  local phases="${REPODIR}/.codex/phases.json"
  
  [ -f "$state" ] || return 0
  
  python3 -c "
import json
state = json.load(open('$state'))
resume = state.get('resume_point')
if resume is not None and __import__('os').path.exists('$phases'):
    phases = json.load(open('$phases'))
    phases['current_phase'] = resume
    with open('$phases', 'w') as f:
        json.dump(phases, f, indent=2)
    print(f'[ARCHITECT] Resumed from phase {resume + 1}')
" 2>/dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --contract) architect_contract "$2" "${3:-master}" ;;
    --gate) architect_gate "$2" ;;
    --advance) architect_advance ;;
    --resume) architect_resume ;;
    *) echo "Usage: architect.sh --contract|--gate|--advance|--resume" ;;
  esac
fi
