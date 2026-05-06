#!/usr/bin/env bash
# Symbol Graph Checker — Verifies cross-file references
REPODIR="${1:-$HOME/codex-builds}"
DONEFILE="$REPODIR/.codex/build-done.txt"

get_py_exports() {
  grep -oE 'def ([a-zA-Z_][a-zA-Z0-9_]*)' "$1" 2>/dev/null | sed 's/def //' || true
  grep -oE 'class ([a-zA-Z_][a-zA-Z0-9_]*)' "$1" 2>/dev/null | sed 's/class //' || true
}

get_py_endpoints() {
  grep -oE "@app\.route\('([^']+)'" "$1" 2>/dev/null | sed "s/@app.route('//;s/'//" || true
}

get_js_fetch_urls() {
  grep -oE "fetch\('([^']+)'|fetch\(\`([^\`]+)\`" "$1" 2>/dev/null | sed "s/fetch('//;s/'//;s/fetch(\`//;s/\`//" || true
}

get_py_imports() {
  grep -oE "from ([a-zA-Z_][a-zA-Z0-9_]*) import" "$1" 2>/dev/null | sed 's/from //;s/ import//' || true
}

is_stdlib() {
  case "$1" in flask|flask_cors|requests|json|os|sys|datetime|subprocess|urllib|re|time|math|random|collections|io|pathlib|typing|dataclasses|abc|base64|hashlib|logging) return 0 ;; esac
  return 1
}

echo "=== SYMBOL GRAPH ==="

while IFS= read -r built; do
  [ -z "$built" ] && continue
  fp="$REPODIR/$built"
  [ ! -f "$fp" ] && continue
  
  if [[ "$built" == *.py ]]; then
    imports=$(get_py_imports "$fp")
    for imp in $imports; do
      is_stdlib "$imp" && continue
      expected="$imp.py"
      if ! grep -qF "$expected" "$DONEFILE" 2>/dev/null; then
        echo "WARN: $built imports '$imp' but $expected is not in build queue"
      fi
    done
  fi
  
  if [[ "$built" == *.js ]]; then
    urls=$(get_js_fetch_urls "$fp")
    all_endpoints=""
    while IFS= read -r pyfile; do
      [ -z "$pyfile" ] && continue
      [ -f "$REPODIR/$pyfile" ] && all_endpoints+=$(get_py_endpoints "$REPODIR/$pyfile")$'\n'
    done < "$DONEFILE"
    
    for url in $urls; do
      [[ "$url" =~ ^https?:// ]] && ! [[ "$url" =~ localhost ]] && continue
      path=$(echo "$url" | sed 's|http://localhost:[0-9]*||')
      if [ -n "$all_endpoints" ] && ! echo "$all_endpoints" | grep -qF "$path"; then
        echo "WARN: $built fetches '$url' but no matching Flask endpoint found"
      fi
    done
  fi
done < "$DONEFILE"

echo "=== SYMBOL CHECK COMPLETE ==="
