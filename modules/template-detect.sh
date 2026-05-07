#!/usr/bin/env bash
set -euo pipefail
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
detect() {
  local goal="$1"
  python3 -c "
import json, sys, os
goal=sys.argv[1].lower()
import json, sys, os
try:
    template_path = os.path.join(os.getenv('HOME'), '.hermes/skills/codex-developer/project-templates.json')
    if not os.path.exists(template_path):
        raise FileNotFoundError("Missing project-templates.json")
    with open(template_path, 'r') as f:
        templates = json.load(f)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

for name,t in templates.items():
    for kw in t['keywords']:
        if kw in goal:
            for f in t['template']: print(f)
            sys.exit(0)
" "$goal" 2>/dev/null
}
case "${1:-detect}" in
    detect) detect "${2:-}" ;;
    *) echo "Invalid function"; exit 1 ;;
esac
