#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${HOME}/codex-builds"
PATTERNSFILE="${SKILLDIR}/patterns.json"
match() { :; }
add() {
  local filepath="$1"
  local name=$(echo "$filepath" | tr '/' '_' | sed 's/\.[a-z]*$//')
  python3 -c "
import json
try:
    p=json.load(open('$PATTERNSFILE'))
    p['$name']=open('$REPODIR/$filepath').read()[:500]
    json.dump(p,open('$PATTERNSFILE','w'),indent=2)
except: pass
" 2>/dev/null
}
"${1:-match}" "${2:-}"
