#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${HOME}/projects"
PATTERNSFILE="${SKILLDIR}/patterns.json"
add() {
  local filepath="$1"
  [[ -z "$filepath" ]] && return 1
  # Ensure file is inside REPODIR
  local full_path="$(realpath "$REPODIR/$filepath")"
  if [[ "$full_path" != "$REPODIR"* ]]; then
      echo "Traversal attempt blocked." >&2
      return 1
  fi
  local name=$(echo "$filepath" | tr '/' '_' | sed 's/\.[a-z]*$//')
  
  # Delegate to safe python module
  PATTERNSFILE="${PATTERNSFILE:-$PATTERNSFILE}"
  python3 "${SKILLDIR}/modules/pattern_manager.py" add "$name" "$full_path"
}

case "${1:-match}" in
    match) match ;;
    add) add "${2:-}" || exit 1 ;;
    *) echo "Invalid function"; exit 1 ;;
esac
