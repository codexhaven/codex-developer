#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
detect() {
  local goal="$1"
  python3 -c "
import json
goal='''$goal'''.lower()
templates=json.load(open('${SKILLDIR}/project-templates.json'))
for name,t in templates.items():
    for kw in t['keywords']:
        if kw in goal:
            for f in t['template']: print(f)
            exit(0)
" 2>/dev/null
}
"${1:-detect}" "${2:-}"
