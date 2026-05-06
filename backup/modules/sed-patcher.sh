#!/usr/bin/env bash
# SED PATCHER v2 — accepts any sed-like command from Hermes
REPODIR="${CODEX_REPO:-$HOME/codex-builds}"

apply_sed_patch() {
  local filepath="$1" desc="$2" goal="$3"
  local fp="$REPODIR/$filepath"
  [ ! -f "$fp" ] && { echo "File not found: $fp"; return 1; }

  # Find relevant sections
  local search_term=$(echo "$desc" | grep -oE 'Replace [a-zA-Z_.]+' | sed 's/Replace //' | head -1)
  [ -z "$search_term" ] && search_term="error"
  local sections=$(grep -n -B3 -A3 "${search_term//./\\.}" "$fp" 2>/dev/null | head -80)
  [ -z "$sections" ] && sections=$(head -50 "$fp" | cat -n)

  # Ask Hermes for sed commands
  local prompt="TARGET: $filepath
CHANGE: $desc

FILE SECTIONS:
$sections

Output ONLY sed commands. One per line. Nothing else.
Format: NUMBER a\\text  or  NUMBERs/old/new/  or  /pattern/s/old/new/g
Example:
27 a\\import logging
47s/st\\.error(/logging.getLogger(__name__).error(/
/st\\.error/s/st\\.error(/logging.getLogger(__name__).error(/g"

  local sed_output
  sed_output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -z "$sed_output" ] && { echo "FAIL: No output."; return 1; }

  echo "Hermes output:"
  echo "$sed_output"

  # Extract sed commands — anything starting with a number or / or s
  local patch_file="$REPODIR/.codex/patch-$(basename "$filepath").sed"
  # Accept any line starting with a number followed by sed command, or a /pattern/, or s/
echo "$sed_output" | grep -E '^[0-9]|^/|^s/' > "$patch_file"
  [ ! -s "$patch_file" ] && { echo "No valid commands found."; return 1; }

  echo "Commands to apply:"
  cat "$patch_file"

  # Apply
  cp "$fp" "$fp.bak"
  local ok=0 fail=0
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    if sed -i "$cmd" "$fp" 2>/dev/null; then
      echo "OK: $cmd"; ok=$((ok+1))
    else
      echo "FAIL: $cmd"; fail=$((fail+1))
    fi
  done < "$patch_file"

  if [ $ok -eq 0 ]; then
    echo "No commands applied. Restoring."
    cp "$fp.bak" "$fp"; rm -f "$fp.bak"; return 1
  fi

  # Verify
  if [[ "$filepath" == *.py ]]; then
    if python3 -m py_compile "$fp" 2>/dev/null; then
      echo "SYNTAX: PASS"
    else
      echo "SYNTAX: FAIL. Restoring."
      cp "$fp.bak" "$fp"; rm -f "$fp.bak"; return 1
    fi
  fi

  rm -f "$fp.bak"
  echo "PATCHED: $filepath ($ok changes)"
}

apply_sed_patch "$@"
