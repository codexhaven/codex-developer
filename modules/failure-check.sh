#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
check() {
  local filepath="$1"
  [[ -z "$filepath" ]] && return 1
  # Ensure file is inside REPODIR (we need to know what project it belongs to)
  # For now, we allow any path as long as it isn't in SKILLDIR
  local full_path="$(realpath "$filepath")"
  [[ ! -f "$full_path" ]] && echo "File not found." >&2 && return 1

  python3 -c "
import json, sys, os
filepath = sys.argv[1]
patterns_file = os.getenv('PATTERNSFILE')

try:
    with open(patterns_file, 'r') as f:
        p = json.load(f)
    
    with open(filepath, 'r') as f:
        for line in f:
            for n, d in p.get('patterns', {}).items():
                if d['detect'] in line:
                    print(f'WARN: Pattern {n}: {d[\"rule\"][:100]}')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" "$full_path"
}

case "${1:-check}" in
    check) check "${2:-}" ;;
    *) echo "Invalid function"; exit 1 ;;
esac
