#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# Import checker - POSIX compliant
FILE="$1"
REPODIR="$2"

# Use a safer regex to avoid subshell confusion
grep -oE "from ['\"](\./|\.\./|@/)[^'\"]+['\"]" "$FILE" 2>/dev/null | while read -r line; do
    # Strip quotes and 'from'
    import_path=$(echo "$line" | sed -E "s/from ['\"]//;s/['\"]//")
    
    if [[ "$import_path" == @/* ]]; then
        resolved_path="${REPODIR}/${import_path#@/}"
    else
        resolved_path="$(dirname "$FILE")/${import_path}"
    fi

    if [[ ! -f "$resolved_path" && ! -f "$resolved_path.ts" && ! -f "$resolved_path.tsx" && ! -f "$resolved_path.js" && ! -f "$resolved_path.jsx" ]]; then
        echo "WARN: Unresolved import: $import_path"
    fi
done
