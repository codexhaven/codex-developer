#!/bin/bash
# sandbox/strengthen.sh - Post-generation file hardening
# Called after commit_all to review and strengthen the just-built file
# Uses brain memory for context, applies improvements as a PATCH

strengthen_file() {
  local filepath="$1"
  local fp="${REPODIR}/${filepath}"
  local brain="${REPODIR}/.codex/project_brain.md"
  local goal="${REPODIR}/.codex/goal.md"

  [ -f "$fp" ] || return 0
  [ -s "$fp" ] || return 0

  log "STRENGTHEN: Reviewing $filepath..."

  local brain_context=""
  [ -f "$brain" ] && brain_context=$(head -100 "$brain" 2>/dev/null)

  local file_content=$(cat "$fp")
  local goal_content=""
  [ -f "$goal" ] && goal_content=$(head -50 "$goal" 2>/dev/null)

  local prompt="## MODE: STRENGTHEN EXISTING FILE
## PROJECT GOAL: $goal_content
## BRAIN CONTEXT: $brain_context
## CURRENT FILE: $filepath

\`\`\`
$file_content
\`\`\`

## INSTRUCTIONS
Review this file for production readiness. Identify and fix:
1. Edge cases and input validation (nulls, empty, division by zero, bounds)
2. Error handling (Result types, proper error propagation)
3. Performance issues (unnecessary allocations, O(n²) patterns)
4. Missing documentation (doc comments, examples, panic sections)
5. Test coverage gaps (property-based tests, boundary tests)

Apply improvements directly to the file. Do NOT rewrite from scratch. Keep existing logic intact. Add guards, docs, and tests.

## Output format: FILE: $filepath followed by the COMPLETE strengthened file contents."

  local output
  output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

  if [ -z "$output" ] || ! echo "$output" | grep -q "FILE:"; then
    log "STRENGTHEN: No improvements needed for $filepath"
    return 0
  fi

  # Apply the strengthened version
  local strengthened="" content="" found_first=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^FILE:[[:space:]]+(.*) ]] && [ "$found_first" = false ]; then
      strengthened="${BASH_REMATCH[1]}"; found_first=true
    elif [ "$found_first" = true ]; then
      content+="$line"$'\n'
    fi
  done <<< "$output"

  if [ -n "$strengthened" ] && [ -n "$content" ]; then
    content=$(echo "$content" | sed "/^\`\`\`/d")
    # Only apply if content is meaningfully larger (more than just formatting)
    local old_lines=$(wc -l < "$fp" 2>/dev/null || echo 0)
    local new_lines=$(echo "$content" | wc -l)
    if [ "$new_lines" -gt "$old_lines" ]; then
      printf '%s' "$content" > "$fp"
      log "STRENGTHEN: $filepath $old_lines→$new_lines lines (+$((new_lines - old_lines)))"
    else
      log "STRENGTHEN: $filepath unchanged (no meaningful additions)"
    fi
  fi
}

# Only run when called directly with a filepath argument
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  strengthen_file "$@"
fi
