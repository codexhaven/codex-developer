#!/usr/bin/env bash
# Dependency Guard — validates contract compliance and detects breaking changes
# Runs after each file build, before strengthen

REPODIR="${1:-${REPODIR:-.}}"
CONTRACTFILE="${REPODIR}/.codex/contract.json"
DEPGRAPH="${REPODIR}/.codex/dependency_graph.json"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
CHANGED_FILE="${2:-}"

[ -f "$CONTRACTFILE" ] || exit 0
[ -f "$DEPGRAPH" ] || exit 0

# --- Check: does this file's actual content match its contract? ---
check_contract_compliance() {
  local file="$1"
  local contract_target="${file#$REPODIR/}"
  
  python3 << 'PYEOF'
import json, os, sys, ast

repodir = os.environ.get('REPODIR', '.')
contract_file = os.path.join(repodir, '.codex', 'contract.json')
target = os.environ.get('CONTRACT_TARGET', '')

with open(contract_file) as f:
    contract = json.load(f)

mod = contract.get('modules', {}).get(target)
if not mod:
    print(f"  No contract for {target}")
    sys.exit(0)

filepath = os.path.join(repodir, target)
if not os.path.exists(filepath):
    print(f"  File not built yet: {target}")
    sys.exit(0)

# Parse the actual file
with open(filepath) as f:
    try:
        tree = ast.parse(f.read())
    except SyntaxError as e:
        print(f"  Syntax error in {target}: {e}")
        sys.exit(1)

# Extract actual functions and classes
actual_functions = {}
actual_classes = {}
for node in ast.walk(tree):
    if isinstance(node, ast.FunctionDef):
        params = [f"{a.arg}: {ast.unparse(a.annotation) if a.annotation else 'Any'}" for a in node.args.args]
        actual_functions[node.name] = {
            "params": params,
            "decorators": [ast.unparse(d) for d in node.decorator_list]
        }
    elif isinstance(node, ast.ClassDef):
        methods = {}
        for item in node.body:
            if isinstance(item, ast.FunctionDef):
                mparams = [f"{a.arg}: {ast.unparse(a.annotation) if a.annotation else 'Any'}" for a in item.args.args]
                methods[item.name] = {"params": mparams}
        actual_classes[node.name] = methods

# Check contract compliance
violations = 0
for exp in mod.get('exports', []):
    name = exp.get('name', '')
    etype = exp.get('type', '')
    
    if etype == 'function':
        if name not in actual_functions:
            print(f"  VIOLATION: Function '{name}' required by contract but not found in {target}")
            violations += 1
        else:
            contract_params = [f"{p['name']}: {p['type']}" for p in exp.get('params', [])]
            actual_params = actual_functions[name]['params']
            if contract_params != actual_params:
                print(f"  MISMATCH: {name} params: contract={contract_params} vs actual={actual_params}")
                violations += 1
    
    elif etype == 'class':
        if name not in actual_classes:
            print(f"  VIOLATION: Class '{name}' required by contract but not found in {target}")
            violations += 1
        else:
            for method in exp.get('methods', []):
                mname = method.get('name', '')
                if mname not in actual_classes[name]:
                    print(f"  VIOLATION: Method '{mname}' missing from class '{name}'")
                    violations += 1

if violations == 0:
    print(f"  Contract compliant: {target}")
else:
    print(f"  {violations} contract violations in {target}")
    sys.exit(1)
PYEOF
}

# --- Breaking change detection: find all dependents ---
find_dependents() {
  local changed_file="$1"
  local contract_target="${changed_file#$REPODIR/}"
  
  python3 << 'PYEOF'
import json, os

repodir = os.environ.get('REPODIR', '.')
depgraph_file = os.path.join(repodir, '.codex', 'dependency_graph.json')
target = os.environ.get('CONTRACT_TARGET', '')

with open(depgraph_file) as f:
    deps = json.load(f)

# Find all files that depend on the changed file
dependents = []
for file, imports in deps.items():
    if target in imports:
        dependents.append(file)

if dependents:
    print(f"  BREAKING CHANGE: {target} modified. Dependents must be rebuilt:")
    for d in dependents:
        print(f"    - {d}")
    # Queue dependents for rebuild
    queue_file = os.path.join(repodir, '.codex', 'build-queue.txt')
    with open(queue_file, 'a') as f:
        for d in dependents:
            f.write(f"PATCH: {d} - Update to match new interface of {target}\n")
    print(f"  Queued {len(dependents)} files for rebuild")
else:
    print(f"  No dependents affected")
PYEOF
}

# Main
if [ -n "$CHANGED_FILE" ]; then
  export CONTRACT_TARGET="${CHANGED_FILE#$REPODIR/}"
  
  echo "[GUARD] Checking contract for $CONTRACT_TARGET..."
  check_contract_compliance "$CHANGED_FILE" || true
  
  echo "[GUARD] Scanning for breaking changes..."
  find_dependents "$CHANGED_FILE" || true
fi
