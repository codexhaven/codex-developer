#!/bin/bash
# recon.sh v7 — Whole-house mapping before furniture
# Forces concrete capabilities, bans utility files, demands real commands

recon_main() {
  REPODIR="${1:-${REPODIR:-${CODEX_REPO:-}}}"
  GOALFILE="${REPODIR}/.codex/goal.md"
  CONTRACTFILE="${REPODIR}/.codex/contract.json"
  PHASESFILE="${REPODIR}/.codex/phases.json"
  DEPGRAPH="${REPODIR}/.codex/dependency_graph.json"
  BRAINFILE="${REPODIR}/.codex/project_brain.md"
  LOGFILE="${REPODIR}/.codex/research.log"

  [ -f "$GOALFILE" ] || { echo "[RECON] No goal.md." >&2; return 0; }
  GOAL=$(cat "$GOALFILE")

  echo "[RECON] Mapping the whole house first..." >&2

  # Single LLM call — do everything in one shot to avoid misalignment
  set +euo pipefail 2>/dev/null
  hermes chat -q \
"Design a complete, buildable architecture for this project. Think like an architect walking through a house before placing ANY furniture.

## PROJECT REQUEST
$GOAL

## STEP 1: EXTRACT REAL CAPABILITIES
What must this tool actually DO? List concrete, specific actions. 
BAD: 'storage system', 'validation', 'file management'
GOOD: 'scan WiFi networks', 'capture WPA handshake', 'extract saved passwords', 'brute-force PIN'

## STEP 2: GROUP INTO FILES (MAXIMUM 5)
Group related capabilities. Each file = one clear domain.
- Network operations go together
- Credential operations go together  
- Storage/database goes together
- User interface goes together
- NO generic utility files. No 'utils.py', 'config.py', 'helpers.py', 'common.py'
- If a file would only have 1 tiny function, merge it into another file

## STEP 3: DEFINE EVERY FUNCTION
For every capability, write the exact function signature with:
- Function name (verb_noun format)
- Parameters with types
- Return type
- The REAL shell command, HTTP request, or SQL query that implements it

Example:
{\"type\": \"function\", \"name\": \"get_wifi_password\", \"params\": [], \"returns\": \"str\", \"command\": \"dumpsys wifi | grep -A20 mWifiInfo | grep psk | cut -d= -f2\", \"description\": \"Extract current WiFi password from Android\"}

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
- MAX 5 FILES. Fewer is better.
- Every function MUST have a 'command' field with a REAL shell/HTTP/SQL command.
- NO generic utility files (utils, config, helpers, common, validator, file_system).
- NO simulated steps. NO 'echo data > file' as a real command.
- Available tools: python3, curl, wget, timeout, bash, sqlite3, dumpsys, ip, ping, grep, awk, sed
- For Termux/Android ARM64. No root. No Docker. No systemd.
- File paths relative: 'scanner.py' not '/home/user/scanner.py'
- Every file in phases MUST be in modules. Every module in at least one phase.
- If alignment fails, the build will break. Get it right the first time.

Output ONLY valid JSON. No markdown fences. No explanation text." \
    --yolo --quiet > "$CONTRACTFILE" 2> "$LOGFILE"
  local EXIT=$?
  set -euo pipefail

  if [ $EXIT -ne 0 ] || [ ! -s "$CONTRACTFILE" ]; then
    echo "[RECON] Generation failed. Check research.log" >&2; return 0
  fi

  # Validate and extract
  if python3 -c "import json; json.load(open('$CONTRACTFILE'))" 2>/dev/null; then
    python3 << 'PYEOF'
import json, os, sys

repodir = os.environ.get('REPODIR', '.')
cf = os.path.join(repodir, '.codex', 'contract.json')
pf = os.path.join(repodir, '.codex', 'phases.json')
df = os.path.join(repodir, '.codex', 'dependency_graph.json')
bf = os.path.join(repodir, '.codex', 'project_brain.md')

data = json.load(open(cf))
modules = data.get('modules', {})
phases = data.get('phases', [])

# Validate file count
if len(modules) > 5:
    print(f"[RECON] WARNING: {len(modules)} files (max 5). Consider consolidating.", file=sys.stderr)

# Validate commands exist
missing_cmd = []
for fname, mod in modules.items():
    for exp in mod.get('exports', []):
        cmd = exp.get('command', '')
        if not cmd or cmd in ['', '...', 'TODO']:
            missing_cmd.append(f"{fname}.{exp.get('name','?')}")
        # Flag generic commands
        if 'echo' in cmd.lower() and '>/dev/tcp' not in cmd:
            print(f"[RECON] WARNING: Generic echo command in {fname}.{exp.get('name','?')}: {cmd}", file=sys.stderr)

if missing_cmd:
    print(f"[RECON] WARNING: {len(missing_cmd)} functions lack real commands", file=sys.stderr)
    for m in missing_cmd[:5]:
        print(f"  - {m}", file=sys.stderr)

# Validate alignment and auto-fix
module_set = set(modules.keys())
phase_set = set()
for p in phases:
    for f in p.get('files', []):
        phase_set.add(f)

missing = module_set - phase_set
extra = phase_set - module_set

if missing:
    print(f"[RECON] Auto-fix: adding {len(missing)} modules to phase 1", file=sys.stderr)
    if phases:
        phases[0]['files'] = list(set(phases[0].get('files', [])) | missing)
    else:
        phases = [{"id": "phase-1", "name": "All", "files": list(module_set)}]

if extra:
    for p in phases:
        p['files'] = [f for f in p.get('files', []) if f in module_set]

# Remove duplicate files across phases
seen = set()
for p in phases:
    p['files'] = [f for f in p.get('files', []) if f not in seen and not seen.add(f)]

# Write phases
with open(pf, 'w') as f:
    json.dump({"phases": phases, "current_phase": 0}, f, indent=2)

# Write dependency graph
depgraph = {}
for fname, mod in modules.items():
    imports = mod.get('imports', [])
    if imports:
        depgraph[fname] = [i for i in imports if i in module_set]
with open(df, 'w') as f:
    json.dump(depgraph, f, indent=2)

# Write brain
with open(bf, 'w') as f:
    f.write(f"# Project Brain\n\n")
    f.write(f"## Research\n{data.get('research', '')}\n\n")
    f.write(f"## Architecture ({len(modules)} files, {len(phases)} phases)\n")
    for fname, mod in modules.items():
        f.write(f"\n### {fname}\n{mod.get('description', '')}\n")
        for exp in mod.get('exports', []):
            cmd = exp.get('command', 'no command')
            params = ', '.join([f"{p['name']}: {p['type']}" for p in exp.get('params', [])])
            f.write(f"- **{exp['name']}({params}) → {exp.get('returns', 'None')}**\n")
            f.write(f"  `{cmd}`\n")

# Print summary
print(f"[RECON] {len(modules)} files, {len(phases)} phases, aligned")
for fname, mod in modules.items():
    exports = [e['name'] for e in mod.get('exports', [])]
    imports = mod.get('imports', [])
    print(f"  {fname}: {exports}, needs {imports if imports else 'nothing'}")
for i, p in enumerate(phases):
    print(f"  Phase {i+1}: {p.get('name', p.get('id'))} ({len(p.get('files', []))} files)")

PYEOF
    echo "[RECON] Done." >&2
  else
    echo "[RECON] Invalid JSON from LLM." >&2
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  recon_main "$@"
fi
