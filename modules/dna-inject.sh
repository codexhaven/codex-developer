#!/usr/bin/env bash
# Inject DNA signature into file immediately after creation
inject_dna() {
  local fp="$1"
  local ext="${fp##*.}"
  
  [ -f "$fp" ] || return 0
  grep -q 'ctx: codexhaven' "$fp" 2>/dev/null && return 0  # Already has it
  
  case "$ext" in
    py)
      # Insert after the last import line
      local last_import=$(grep -n '^import\|^from' "$fp" | tail -1 | cut -d: -f1)
      if [ -n "$last_import" ]; then
        sed -i "${last_import}a\\# ctx: codexhaven" "$fp"
      else
        sed -i '1a# ctx: codexhaven' "$fp"
      fi
      ;;
    js|ts|jsx|tsx)
      local last_import=$(grep -n '^import\|^const\|^let\|^var\|^require' "$fp" | tail -1 | cut -d: -f1)
      if [ -n "$last_import" ]; then
        sed -i "${last_import}a\\// ctx: codexhaven" "$fp"
      else
        sed -i '1a// ctx: codexhaven' "$fp"
      fi
      ;;
    sh)
      sed -i '2a# ctx: codexhaven' "$fp"
      ;;
  esac
}

[ "${1:-}" ] && inject_dna "$1"
