#!/usr/bin/env bash
#!/usr/bin/env bash
# SED PATCHER v2 — accepts any sed-like command from Hermes
set -euo pipefail
REPODIR="$(realpath "${CODEX_REPO:-$HOME/codex-builds}")"

apply_sed_patch() {
  local filepath="$1" desc="$2" goal="$3"
  local fp="$(realpath "$REPODIR/$filepath")"
  [[ "$fp" != "$REPODIR"* ]] && { echo "Traversal blocked."; return 1; }
  [ ! -f "$fp" ] && { echo "File not found: $fp"; return 1; }

  # Find relevant sections safely
  local search_term=$(echo "$desc" | grep -oE 'Replace [a-zA-Z_.]+' | sed 's/Replace //' | head -1)
  [ -z "$search_term" ] && search_term="error"
  local sections=$(grep -n -B3 -A3 "${search_term//./\\.}" "$fp" 2>/dev/null | head -n 80 || head -n 50 "$fp" | cat -n)

  # Secure Temp File for Patch
  local patch_file="$(mktemp)"
  
  # Hermes Prompt with strict instruction for safe output
  local prompt="TARGET: $filepath
CHANGE: $desc
CONTEXT: 
$sections
Output strictly ONLY valid sed commands, one per line. Do NOT use shell features.
Valid patterns: s/pattern/replacement/g , /pattern/s/old/new/g , NUMBER c\text
NO shell backticks or execution operators."

  local sed_output
  sed_output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
  
  # Validate output to only contain allowed sed structure
  # Allows: s/a/b/g, /a/s/b/c/g, #c\text
  echo "$sed_output" | grep -E '^(s/|/[^/]+/[^/]+/|([0-9]+[a-z]\\))' > "$patch_file"
  [ ! -s "$patch_file" ] && { echo "No valid commands found."; rm -f "$patch_file"; return 1; }

  # Secure Backup
  local bak="$(mktemp)"
  cp "$fp" "$bak"

  local ok=0 fail=0
  while IFS= read -r cmd; do
    # Perform patch
    if sed -i "$cmd" "$fp" 2>/dev/null; then
      ok=$((ok+1))
    else
      fail=$((fail+1))
    fi
  done < "$patch_file"

  # Verification
  local clean=0
  if [[ "$filepath" == *.py ]]; then
    python3 -m py_compile "$fp" 2>/dev/null && clean=1
  else
    clean=1
  fi

  if [ $ok -eq 0 ] || [ $clean -eq 0 ]; then
    echo "Patch failed/syntax invalid. Restoring."
    cp "$bak" "$fp"
    rm -f "$bak" "$patch_file"
    return 1
  fi

  rm -f "$bak" "$patch_file"
  echo "PATCHED: $filepath ($ok changes)"
}

apply_sed_patch "$@"
