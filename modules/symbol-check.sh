#!/usr/bin/env bash
set -euo pipefail
REPODIR="$(realpath "${1:-$HOME/codex-builds}")"
DONEFILE="$REPODIR/.codex/build-done.txt"

# Helper: safe grep for patterns
get_py_exports() {
  grep -hFE "def " "$1" 2>/dev/null | awk '{print $2}' | tr -d '():'
}

get_py_endpoints() {
  grep -hFE "@app.route" "$1" 2>/dev/null | awk -F"'" '{print $2}'
}

get_js_fetch_urls() {
  grep -hFE "fetch(" "$1" 2>/dev/null | awk -F"['\`]" '{print $2}'
}

# Pre-calculate endpoints for O(1) lookup
declare -A ENDPOINTS
if [ -f "$DONEFILE" ]; then
  while IFS= read -r pyfile; do
    [ -z "$pyfile" ] && continue
    [ -f "$REPODIR/$pyfile" ] && while read -r ep; do
      [ -n "$ep" ] && ENDPOINTS["$ep"]=1
    done <<< "$(get_py_endpoints "$REPODIR/$pyfile")"
  done < "$DONEFILE"
fi

echo "=== SYMBOL GRAPH ==="

if [ -f "$DONEFILE" ]; then
  while IFS= read -r built; do
    [ -z "$built" ] && continue
    fp="$(realpath "$REPODIR/$built")"
    [[ "$fp" != "$REPODIR"* ]] && continue
    [ ! -f "$fp" ] && continue
    
    if [[ "$built" == *.py ]]; then
      grep -hFE "from " "$fp" 2>/dev/null | awk '{print $2}' | while read -r imp; do
        [[ "$imp" =~ ^(flask|os|sys|json|subprocess|re|time|math|collections|pathlib|typing|dataclasses|abc|base64|hashlib|logging)$ ]] && continue
        if ! grep -qF "$imp.py" "$DONEFILE" 2>/dev/null; then
          echo "WARN: $built imports '$imp' but $imp.py is missing from build queue"
        fi
      done
    fi
    
    if [[ "$built" == *.js ]]; then
      while read -r url; do
        [[ "$url" =~ ^https?:// && ! "$url" =~ localhost ]] && continue
        path="$(echo "$url" | sed 's|http://localhost:[0-9]*||')"
        if [ -n "$path" ] && [[ -z "${ENDPOINTS[$path]:-}" ]]; then
          echo "WARN: $built fetches '$url' but no matching Flask endpoint found"
        fi
      done <<< "$(get_js_fetch_urls "$fp")"
    fi
  done < "$DONEFILE"
fi

echo "=== SYMBOL CHECK COMPLETE ==="
