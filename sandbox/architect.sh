#!/bin/bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# architect.sh v5 — Pass-through validator
# Recon already produced the contract. Architect just validates and serves.

architect_contract() {
  local REPODIR="${1:-${REPODIR:-.}}"
  local CONTRACTFILE="${REPODIR}/.codex/contract.json"
  local PHASESFILE="${REPODIR}/.codex/phases.json"
  local DEPGRAPH="${REPODIR}/.codex/dependency_graph.json"

  echo "[ARCHITECT] Validating recon's contract..."
  validate_class_names || exit 1

  if [ ! -f "$CONTRACTFILE" ] || [ ! -s "$CONTRACTFILE" ]; then
    echo "[ARCHITECT] No contract found. Recon may have failed."
    return 1
  fi

  python3 << 'PYEOF'
import json, os

repodir = os.environ.get('REPODIR', '.')
cf = os.path.join(repodir, '.codex', 'contract.json')
pf = os.path.join(repodir, '.codex', 'phases.json')
df = os.path.join(repodir, '.codex', 'dependency_graph.json')

data = json.load(open(cf))
modules = data.get('modules', {})
phases = data.get('phases', [])

# Recon already produced phases — use them directly
if not phases:
    print("[ARCHITECT] No phases in contract. Generating from modules...")
    phases = [{"id": "phase-1", "name": "Build", "files": list(modules.keys())}]
    data['phases'] = phases
    with open(cf, 'w') as f:
        json.dump(data, f, indent=2)

# Write phases file
with open(pf, 'w') as f:
    json.dump({"phases": phases, "current_phase": 0}, f, indent=2)

# Write dependency graph
depgraph = {}
for fname, mod in modules.items():
    imports = mod.get('imports', [])
    if imports:
        depgraph[fname] = [i for i in imports if i in modules]
with open(df, 'w') as f:
    json.dump(depgraph, f, indent=2)

# Summary
print(f"[ARCHITECT] Recon's plan: {len(modules)} files, {len(phases)} phases")
for fname, mod in modules.items():
    exports = [e['name'] for e in mod.get('exports', [])]
    imports = mod.get('imports', [])
    print(f"  {fname}: {exports}, needs {imports if imports else 'nothing'}")

# Validate alignment
module_set = set(modules.keys())
phase_set = set()
for p in phases:
    for f in p.get('files', []):
        phase_set.add(f)

missing = module_set - phase_set
extra = phase_set - module_set
if missing:
    print(f"[ARCHITECT] Adding missing to phase 1: {missing}")
    phases[0]['files'] = list(set(phases[0].get('files', [])) | missing)
    with open(pf, 'w') as f:
        json.dump({"phases": phases, "current_phase": 0}, f, indent=2)
if extra:
    print(f"[ARCHITECT] Removing unknown files: {extra}")
    for p in phases:
        p['files'] = [f for f in p.get('files', []) if f in module_set]
    with open(pf, 'w') as f:
        json.dump({"phases": phases, "current_phase": 0}, f, indent=2)

if not missing and not extra:
    print(f"[ARCHITECT] Contract and phases aligned.")
PYEOF
}

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
# Check dependency
if __import__('os').path.exists('$depgraph'):
    dep = json.load(open('$depgraph'))
    for cf in current_files:
        if cf in dep and '$filepath' in dep[cf]:
            exit(0)
exit(1)
" 2>/dev/null
}

architect_advance() {
  local phases="${REPODIR}/.codex/phases.json"
  local donefile="${REPODIR}/.codex/build-done.txt"

  [ -f "$phases" ] || return 0
  [ -f "$donefile" ] || return 0

  python3 -c "
import json
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
    next_name = phase_list[curr+1].get('name','COMPLETE') if curr+1 < len(phase_list) else 'COMPLETE'
    print(f'PHASE {curr+1}->{curr+2}: {current.get(\"name\")} -> {next_name}')
" 2>/dev/null
}

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
    print(f'[ARCHITECT] Resumed from phase {resume+1}')
" 2>/dev/null
}

validate_class_names() {
  local REPODIR="${1:-${REPODIR:-.}}"
  local CONTRACTFILE="${REPODIR}/.codex/contract.json"

  [ ! -f "$CONTRACTFILE" ] && return 0

  python3 -c "
import json, os, sys
repodir = os.environ.get('REPODIR', '.')
cf = os.path.join(repodir, '.codex', 'contract.json')
data = json.load(open(cf))

errors = []
for mod_path, mod_data in data.get('modules', {}).items():
    for exp in mod_data.get('exports', []):
        name = exp.get('name', '')
        if name == 'Manager':
            errors.append(f\"ERROR: Generic class 'Manager' not allowed in {mod_path}. Use specific name like {mod_path.split('/')[-1].replace('.py', '').capitalize()}Manager\")
        if exp.get('type') == 'class' and not name.endswith(('Agent', 'Tool', 'Supervisor', 'Interface', 'Manager')):
            errors.append(f\"WARNING: Class '{name}' should end with Agent/Tool/Supervisor/Interface in {mod_path}\")

if errors:
    print('\n'.join(errors))
    sys.exit(1)
print('[ARCHITECT] Class naming validation passed')
" 2>/dev/null || return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --contract) architect_contract "$2" ;;
    --gate) architect_gate "$2" ;;
    --advance) architect_advance ;;
    --resume) architect_resume ;;
    *) echo "Usage: architect.sh --contract|--gate|--advance|--resume" ;;
  esac
fi
