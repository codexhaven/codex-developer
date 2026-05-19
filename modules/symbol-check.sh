#!/usr/bin/env bash
# v12.2 Symbol Validator — Hardened
# Cross-file validation: imports, exports, dead code, missing references
set -euo pipefail

REPODIR="$(readlink -f "${1:-${REPODIR:-.}}")"
SKILLDIR="${HOME}/.hermes/skills/codex-developer"

echo "[SYMBOL] Scanning $REPODIR..."

# --- 1. TODOs and placeholders ---
echo "--- TODOs ---"
grep -rn "TODO\|FIXME\|HACK\|XXX" "$REPODIR" --include="*.py" --include="*.js" --include="*.ts" --exclude-dir=.git --exclude-dir=.codex --exclude-dir=__pycache__ 2>/dev/null | head -10

# --- 2. Import mismatch detection using map_project ---
echo ""
echo "--- Import Validation ---"
if [ -f "${SKILLDIR}/modules/map_project.py" ]; then
  python3 "${SKILLDIR}/modules/map_project.py" mismatches 2>/dev/null
fi

# --- 3. Dead code: defined but never used ---
echo ""
echo "--- Dead Code (defined but never imported) ---"
python3 -c "
import os, re

repo = '$REPODIR'
exports = {}  # file -> [names]
imports_used = set()  # all names imported from local files

# Scan all Python files
for root, dirs, files in os.walk(repo):
    dirs[:] = [d for d in dirs if d not in ('.git', '.codex', '__pycache__')]
    for f in files:
        if not f.endswith('.py'):
            continue
        fpath = os.path.join(root, f)
        rel = os.path.relpath(fpath, repo)
        
        with open(fpath, errors='ignore') as fh:
            content = fh.read()
        
        # Collect exports
        file_exports = []
        for match in re.finditer(r'^(def|class)\s+(\w+)', content, re.MULTILINE):
            name = match.group(2)
            if not name.startswith('_'):
                file_exports.append(name)
        if file_exports:
            exports[rel] = file_exports
        
        # Collect what this file imports from other local files
        for match in re.finditer(r'from\s+(\w+)\s+import\s+(.+)', content):
            module = match.group(1)
            imported = [x.strip().split(' as ')[0].strip() for x in match.group(2).split(',')]
            for name in imported:
                if name != '*':
                    imports_used.add(name)

# Check each export: is it imported anywhere?
for filepath, names in sorted(exports.items()):
    unused = [n for n in names if n not in imports_used and n not in ('main',)]
    if unused:
        print(f'  {filepath}: unused exports — {\", \".join(unused)}')
" 2>/dev/null || echo "  Dead code scan skipped"

# --- 4. Missing files referenced in imports ---
echo ""
echo "--- Missing Files ---"
find "$REPODIR" -name "*.py" -not -path "*/.codex/*" -not -path "*/__pycache__/*" | while read -r f; do
  grep -oP 'from\s+(\w+)\s+import' "$f" 2>/dev/null | sed 's/from //;s/ import//' | while read -r mod; do
    # Check if module exists as a .py file
    found=0
    for candidate in "$(dirname "$f")/${mod}.py" "$REPODIR/${mod}.py" "$REPODIR/src/${mod}.py"; do
      [ -f "$candidate" ] && found=1 && break
    done
    if [ "$found" -eq 0 ] && ! python3 -c "import $mod" 2>/dev/null; then
      echo "  $(basename "$f"): imports '$mod' — not found in project or stdlib"
    fi
  done
done

echo ""
echo "[SYMBOL] Scan complete."
