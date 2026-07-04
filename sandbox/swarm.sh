#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# Swarm Orchestrator — Self-assembling build system

SWARM_from_violations() {
  local REPODIR="${1:-${REPODIR:-.}}"
  local BUILDFILE="${REPODIR}/.codex/build.log"
  local CONTRACTFILE="${REPODIR}/.codex/contract.json"
  local QUEUEFILE="${REPODIR}/.codex/build-queue.txt"

  python3 -c "
import json, os, re
repodir = os.environ.get('REPODIR', '.')
build_log = os.path.join(repodir, '.codex', 'build.log')
contract_file = os.path.join(repodir, '.codex', 'contract.json')
queue_file = os.path.join(repodir, '.codex', 'build-queue.txt')
if not os.path.exists(build_log): exit(0)
log_content = open(build_log).read()
pattern = r'CONTRACT VIOLATION: (\S+) imports from modules not in contract:\n(.*?)Contract modules:'
matches = re.findall(pattern, log_content, re.DOTALL)
violation_modules = set()
for filepath, violation_block in matches:
    imports = re.findall(r'  - (\S+) \(not in contract\)', violation_block)
    for imp in imports:
        if not imp.startswith(('sqlalchemy','fastapi','pydantic','passlib','jose','datetime','typing','os','sys')):
            mod_path = imp.replace('.', '/') + '.py'
            violation_modules.add(mod_path)
            print(f'[SWARM] Violation: {filepath} needs {imp} -> {mod_path}')
if violation_modules:
    contract = json.load(open(contract_file))
    modules = contract.get('modules', {})
    added = 0
    for mod_path in violation_modules:
        if mod_path not in modules:
            modules[mod_path] = {'description': 'Auto-discovered from violations', 'exports': [], 'imports': []}
            with open(queue_file, 'a') as qf: qf.write(f'NEW:{mod_path}\n')
            added += 1
            print(f'[SWARM] Added: {mod_path}')
    if added:
        contract['modules'] = modules
        json.dump(contract, open(contract_file, 'w'), indent=2)
        print(f'[SWARM] {added} modules discovered')
" 2>/dev/null
}

SWARM_guard() {
  local REPODIR="${1:-${REPODIR:-.}}"; local FILEPATH="${2:-}"
  [ -f "$REPODIR/.codex/dependency_graph.json" ] || return 0
  [ -n "$FILEPATH" ] || return 0
  python3 -c "
import json, os
dep = json.load(open(os.path.join(os.environ.get('REPODIR','.'), '.codex', 'dependency_graph.json')))
fp = os.environ.get('FILEPATH', '')
deps = [f for f, imps in dep.items() if fp in imps]
if deps:
    print(f'[SWARM] Breaking change: {fp} -> {len(deps)} dependents')
    with open(os.path.join(os.environ.get('REPODIR','.'), '.codex', 'build-queue.txt'), 'a') as qf:
        for d in deps: qf.write(f'PATCH: {d} - Rebuild after {fp} changed\n')
" 2>/dev/null
}

SWARM_expand() {
  local REPODIR="${1:-${REPODIR:-.}}"
  python3 -c "
import json, os
r = os.environ.get('REPODIR', '.')
c = json.load(open(os.path.join(r, '.codex', 'contract.json')))
modules = c.get('modules', {})
done = open(os.path.join(r, '.codex', 'build-done.txt')).read() if os.path.exists(os.path.join(r, '.codex', 'build-done.txt')) else ''
missing = [m for m in modules if m not in done]
if missing:
    print(f'[SWARM] Queuing {len(missing)} unbuilt files')
    with open(os.path.join(r, '.codex', 'build-queue.txt'), 'a') as qf:
        for m in missing: qf.write(f'NEW:{m}\n')
" 2>/dev/null
}

SWARM_routes() {
  local REPODIR="${1:-${REPODIR:-.}}"
  python3 -c "
import json, os
r = os.environ.get('REPODIR', '.')
c = json.load(open(os.path.join(r, '.codex', 'contract.json')))
modules = c.get('modules', {})
has_main = any('main.py' in m or 'app.py' in m for m in modules)
if not has_main and modules:
    entry = 'src/main.py' if any('/' in m for m in modules) else 'main.py'
    modules[entry] = {'description': 'Auto-generated entry point', 'exports': [], 'imports': list(modules.keys())}
    c['modules'] = modules
    json.dump(c, open(os.path.join(r, '.codex', 'contract.json'), 'w'), indent=2)
    with open(os.path.join(r, '.codex', 'build-queue.txt'), 'a') as qf: qf.write(f'NEW:{entry}\n')
    print(f'[SWARM] Entry point: {entry}')
" 2>/dev/null
}

SWARM_readme() {
  local REPODIR="${1:-${REPODIR:-.}}"
  local QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
  
  if [ ! -f "$REPODIR/README.md" ]; then
    echo "NEW:README.md - Auto-generate project documentation" >> "$QUEUEFILE"
    echo "[SWARM] README.md missing → queued for generation"
  else
    echo "[SWARM] README.md exists"
  fi
}

# === MAIN ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --from-violations) SWARM_from_violations "$2" ;;
    --guard) SWARM_guard "$2" "$3" ;;
    --expand) SWARM_expand "$2" ;;
    --routes) SWARM_routes "$2" ;;
    --readme) SWARM_readme "$2" ;;
    --all) SWARM_expand "$2"; SWARM_routes "$2"; SWARM_readme "$2" ;;
    *) echo "Usage: swarm.sh --from-violations|--guard|--expand|--routes|--readme|--all" ;;
  esac
fi
