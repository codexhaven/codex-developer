#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
check() {
  local filepath="$1"
  [ ! -f "$filepath" ] && return
  python3 -c "
import json
try:
    p=json.load(open('${SKILLDIR}/failure-patterns.json'))
    c=open('$filepath').read()
    for n,d in p.get('patterns',{}).items():
        if d['detect'] in c: print(f'WARN: Pattern {n}: {d[\"rule\"][:100]}')
except: pass
" 2>/dev/null
}
"${1:-check}" "${2:-}"
