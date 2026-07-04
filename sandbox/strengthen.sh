#!/usr/bin/env bash
# strengthen.sh v2 — Multi-pass hardening + cross-ref + structure audit
set -euo pipefail
# ctx: codexhaven

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && (pwd -P 2>/dev/null || pwd))"

strengthen_file() {
  local filepath="$1"
  local fp="${REPODIR}/${filepath}"
  local brain="${REPODIR}/.codex/project_brain.md"
  local goal="${REPODIR}/.codex/goal.md"

  [ -f "$fp" ] || return 0
  [ -s "$fp" ] || return 0

  log "STRENGTHEN: Reviewing $filepath..."

  # Contract compliance check
  if [ -f "${REPODIR}/.codex/contract.json" ]; then
    log "  Checking contract compliance..."
    python3 -c "
import json, os, ast
contract = json.load(open('${REPODIR}/.codex/contract.json'))
target = '$filepath'
if target in contract.get('modules', {}):
    mod = contract['modules'][target]
    exports = mod.get('exports', [])
    if os.path.exists('${REPODIR}/' + target):
        tree = ast.parse(open('${REPODIR}/' + target).read())
        found = set()
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                found.add(node.name)
        for exp in exports:
            if exp['name'] not in found:
                print(f'  CONTRACT VIOLATION: {exp["type"]} {exp["name"]} required but missing')
" 2>/dev/null || true
  fi

  local brain_context=""
  [ -f "$brain" ] && brain_context=$(head -100 "$brain" 2>/dev/null)

  local file_content=$(cat "$fp")
  local goal_content=""
  [ -f "$goal" ] && goal_content=$(head -50 "$goal" 2>/dev/null)

  # Get full project context for import validation
  local full_context=""
  if [ -f "${SKILLDIR}/modules/map_project.py" ]; then
    full_context=$(python3 "${SKILLDIR}/modules/map_project.py" context "$filepath" 2>/dev/null || echo "")
  fi

  # Find import mismatches for this specific file
  local xref_issues=""
  if [ -f "${SKILLDIR}/modules/map_project.py" ]; then
    while IFS= read -r import_line; do
      [ -z "$import_line" ] && continue
      module=$(echo "$import_line" | sed -E 's/from\s+(\w+)\s+import.*/\1/')
      mod_file=""
      for candidate in "$(dirname "$fp")/${module}.py" "$REPODIR/${module}.py"; do
        [ -f "$candidate" ] && { mod_file="$candidate"; break; }
      done
      [ -z "$mod_file" ] && continue
      
      items=$(echo "$import_line" | sed -E 's/from\s+\w+\s+import\s+(.*)/\1/')
      for item in $(echo "$items" | tr ',' ' '); do
        item=$(echo "$item" | xargs)
        [ -z "$item" ] && continue
        if ! grep -qE "^(class|def)\s+${item}[^a-zA-Z0-9_]" "$mod_file"; then
          xref_issues+="  MISMATCH: imports '$item' from '$module' — not found in ${module}.py"$'\n'
        fi
      done
    done < <(grep -oP 'from\s+\w+\s+import\s+[\w,\s]+' "$fp" 2>/dev/null)
  fi

  local xref_note=""
  [ -n "$xref_issues" ] && xref_note="## IMPORT MISMATCHES TO FIX:"$'\n'"${xref_issues}"$'\n'

  # --- Pass 1: Strengthen with full context ---
  local prompt="## MODE: STRENGTHEN EXISTING FILE
## PROJECT GOAL: $goal_content
## BRAIN CONTEXT: $brain_context
## PROJECT EXPORTS: $full_context
${xref_note}## CURRENT FILE: $filepath

\`\`\`
$file_content
\`\`\`

## INSTRUCTIONS
Review this file for production readiness. Identify and fix:
0. STRING QUOTING: Ensure ALL string literals are quoted. Fix any unquoted strings immediately. 1. Edge cases and input validation (nulls, empty, division by zero, bounds)
2. Error handling (proper error propagation, try/except)
3. Performance issues
4. Missing documentation (docstrings)
5. IMPORT MISMATCHES — fix any listed above to match actual exports
6. NO MARKDOWN in comments — strip any bullet points or markdown formatting

Apply improvements directly. Do NOT rewrite from scratch. Keep existing logic.
Output format: FILE: $filepath followed by COMPLETE strengthened file contents."

  local output
  output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

  # --- Pass 2: If first pass found issues, verify and re-strengthen ---
  local pass=1
  while [ $pass -le 3 ]; do
    if [ -z "$output" ] || ! echo "$output" | grep -q "FILE:"; then
      [ $pass -eq 1 ] && log "STRENGTHEN: No output on pass $pass — retrying with simpler prompt..."
      # Simpler retry
      output=$(hermes chat -q "## MODE: STRENGTHEN $filepath\n## Fix edge cases, error handling, docs, import mismatches.\n## Output: FILE: $filepath\n\n$file_content" --yolo --quiet 2>/dev/null || echo "")
      pass=$((pass + 1))
      continue
    fi
    break
  done

  if [ -z "$output" ] || ! echo "$output" | grep -q "FILE:"; then
    log "STRENGTHEN: No improvements after $pass passes for $filepath"
    [ -n "$xref_issues" ] && log "XREF: Import mismatches remain in $filepath"
    return 0
  fi

  # Extract and apply
  local strengthened="" content="" found_first=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^FILE:[[:space:]]+(.*) ]] && [ "$found_first" = false ]; then
      strengthened="${BASH_REMATCH[1]}"; found_first=true
    elif [ "$found_first" = true ]; then
      content+="$line"$'\n'
    fi
  done <<< "$output"

  if [ -n "$strengthened" ] && [ -n "$content" ]; then
    # Sanitize: strip markdown, bullet points, stray formatting
    content=$(echo "$content" | sed "/^\`\`\`/d")
    content=$(echo "$content" | sed "/^\*.*Improved/d; /^\*.*Memory/d; /^\*.*Robust/d; /^\*.*Production/d")
    
    local old_lines=$(wc -l < "$fp" 2>/dev/null || echo 0)
    local new_lines=$(echo "$content" | wc -l)
    
    # Quality gate: only accept if improvement is meaningful (>5% growth or import fixes)
    local line_gain=$((new_lines - old_lines))
    local gain_pct=$((line_gain * 100 / (old_lines + 1)))
    local has_xref_fix=false
    [ -n "$xref_issues" ] && ! echo "$content" | grep -qF "$xref_issues" && has_xref_fix=true

    if [ "$line_gain" -gt 0 ] && ( [ "$gain_pct" -ge 5 ] || [ "$has_xref_fix" = true ] ); then
      printf '%s' "$content" > "$fp"
      log "STRENGTHEN: $filepath $old_lines→$new_lines lines (+$((new_lines - old_lines)))"
      
      # Re-verify after strengthen
      case "${filepath##*.}" in
        py) python3 -m py_compile "$fp" 2>/dev/null && log "  Re-verify: PASS" || log "  Re-verify: FAIL";;
        sh) bash -n "$fp" 2>/dev/null && log "  Re-verify: PASS" || log "  Re-verify: FAIL";;
      esac
    else
      log "STRENGTHEN: $filepath unchanged (gain: +${line_gain}L / ${gain_pct}% — below threshold)"
    fi
  fi
}

# --- Post-build structure audit ---
flatten_simple_project() {
  local py_count=$(find "$REPODIR" -name "*.py" -not -path "*/.codex/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
  local root_py_count=$(find "$REPODIR" -maxdepth 1 -name "*.py" 2>/dev/null | wc -l)
  
  if [ "$py_count" -gt 0 ] && [ "$root_py_count" -eq 0 ] && [ "$py_count" -le 10 ]; then
    log "STRUCTURE: Simple project ($py_count files) nested — flattening to root"
    
    find "$REPODIR" -name "*.py" -not -path "*/.codex/*" -not -path "*/.git/*" -not -path "*/tests/*" | while read -r f; do
      local basename=$(basename "$f")
      [ ! -f "$REPODIR/$basename" ] && mv "$f" "$REPODIR/$basename" 2>/dev/null && log "  Moved: $f → $basename"
    done
    
    find "$REPODIR" -type d -empty -not -path "*/.git/*" -not -path "*/.codex/*" -delete 2>/dev/null
    
    for f in "$REPODIR"/*.py; do
      [ -f "$f" ] || continue
      sed -i 's/from\s\+src\.\S*\./from /g' "$f" 2>/dev/null
      sed -i 's/from\s\+\w\+\.\w\+\./from /g' "$f" 2>/dev/null
    done
    
    log "STRUCTURE: Flatten complete. $(find "$REPODIR" -maxdepth 1 -name '*.py' | wc -l) files at root."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ "${1:-}" = "--flatten" ]; then
    flatten_simple_project
  else
    strengthen_file "$@"
  fi
fi
