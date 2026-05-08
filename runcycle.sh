#!/usr/bin/env bash
set -euo pipefail
# VERSION: 10.0.0 — PATCH mode: reads existing files, makes surgical fixes

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${CODEX_REPO:-${HOME}/codex-builds}"
GOALFILE="${REPODIR}/.codex/goal.md"
STATEFILE="${REPODIR}/.codex/state.json"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
DONEFILE="${REPODIR}/.codex/build-done.txt"
LESSONSFILE="${REPODIR}/.codex/lessons.md"
LESSONSJSONL="${REPODIR}/.codex/lessons.jsonl"
GLOBAL_KNOWLEDGE="${SKILLDIR}/global-knowledge.jsonl"
PATTERNSFILE="${SKILLDIR}/patterns.json"
MAXLINES="${MAX_LINES:-120}"
MAX_RETRIES=3

LOCKFILE="${TMPDIR:-/tmp}/codex-developer.lock"
touch "$LOCKFILE" 2>/dev/null || { LOCKFILE="${HOME}/tmp-codex-developer.lock"; mkdir -p "$(dirname "$LOCKFILE")"; touch "$LOCKFILE"; }

acquire_lock() { exec 9>"$LOCKFILE"; flock -n 9 || { echo "[SKIP] Locked."; exit 0; }; }
release_lock() { flock -u 9 2>/dev/null; rm -f "$LOCKFILE" 2>/dev/null; }
log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')]" "$@"; }

bash "${SKILLDIR}/kernel.sh" check 2>&1 | while read -r l; do [ -n "$l" ] && log "KERNEL: $l"; done
  ensure_files() {
  mkdir -p "$REPODIR" "$(dirname "$STATEFILE")"
  [[ -f "$STATEFILE" ]] || echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$STATEFILE"
  touch "$QUEUEFILE" "$DONEFILE" "$GLOBAL_KNOWLEDGE" "$LESSONSJSONL"
  [[ -f "$LESSONSFILE" ]] || echo "# Lessons" > "$LESSONSFILE"
}

read_goal() { [ -f "$GOALFILE" ] && cat "$GOALFILE" || echo "No goal."; }

# Parse queue entry: supports "PATCH: file - description" and plain "file"
parse_entry() {
  local entry="$1"
  # Strip absolute paths
  entry="${entry#$REPODIR/}"
  [ -z "$entry" ] && { echo "MODE=SKIP FILE= DESC="; return; }
  [[ "$entry" =~ ^(NEW|PATCH|SED):[[:space:]]*$ ]] && { echo "MODE=SKIP FILE= DESC="; return; }
  
  if [[ "$entry" =~ ^SED:[[:space:]]+([^[:space:]].*)[[:space:]]-[[:space:]](.*) ]]; then
    echo "MODE=SED FILE=${BASH_REMATCH[1]} DESC=${BASH_REMATCH[2]}"
  elif [[ "$entry" =~ ^PATCH:[[:space:]]+([^[:space:]].*)[[:space:]]-[[:space:]](.*) ]]; then
    echo "MODE=PATCH FILE=${BASH_REMATCH[1]} DESC=${BASH_REMATCH[2]}"
  elif [[ "$entry" =~ ^NEW:[[:space:]]+(.+) ]]; then
    echo "MODE=NEW FILE=${BASH_REMATCH[1]} DESC="
  else
    echo "MODE=NEW FILE=$entry DESC="
  fi
}

next_file() {
  local done=$(cat "$DONEFILE" 2>/dev/null)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Extract filename for matching (works for both "file.py" and "PATCH: file.py - desc")
    local fn=$(echo "$line" | sed -E 's/^(NEW|PATCH|SED):[[:space:]]+//' | sed -E 's/[[:space:]]+-[[:space:]].*//')
    if ! echo "$done" | grep -qF "$fn"; then
      echo "$line"; return
    fi
  done < "$QUEUEFILE"
  echo ""
}

get_global_knowledge() {
  local knowledge=""
  if [ -f "$GLOBAL_KNOWLEDGE" ] && [ -s "$GLOBAL_KNOWLEDGE" ]; then
    knowledge+="## CRITICAL RULES"$'\n'
    grep '"type": "rule"' "$GLOBAL_KNOWLEDGE" 2>/dev/null | while read -r line; do
      local rule=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('rule',''))" 2>/dev/null || echo "")
      [ -n "$rule" ] && echo "- $rule"
    done
  fi
  echo "$knowledge"
}

get_built_context() {
  local mode="$1" target="$2"
  local done=$(cat "$DONEFILE" 2>/dev/null)
  
  # For PATCH mode: ALWAYS include the target file
  if [ "$mode" = "PATCH" ] && [ -f "$REPODIR/$target" ]; then
    echo "--- PATCH TARGET: $target (COMPLETE FILE) ---"
    cat "$REPODIR/$target"
    echo ""
  fi
  
  # Include other existing/built files as context
  if [ -z "$done" ]; then
    local count=0
    while IFS= read -r f; do
      [ $count -ge 4 ] && break
      [ "$f" = "$REPODIR/$target" ] && continue
      [ -f "$f" ] && [ -s "$f" ] || continue
      local size=$(wc -l < "$f" 2>/dev/null || echo 0)
      [ "$size" -gt 0 ] && [ "$size" -lt 500 ] || continue
      echo "--- CONTEXT: ${f#$REPODIR/} (first 50 lines) ---"
      head -50 "$f"
      echo ""
      count=$((count + 1))
    done < <(find "$REPODIR" -maxdepth 2 -type f -name "*.py" -not -path "*/.git/*" -not -path "*/__pycache__/*" 2>/dev/null | head -10)
  else
    for f in $done; do
      [ "$f" = "$target" ] && continue
      local fp="$REPODIR/$f"
      [ -f "$fp" ] && echo "--- BUILT: $f ---" && cat "$fp" && echo ""
    done
  fi
}

generate_queue() {
  local goal="$1" knowledge="$2"
  log "PLANNING: Generating build order..."
  
  # Detect fix vs new
  local prompt
  if echo "$goal" | grep -qi "fix\|repair\|patch\|fcntl\|sanitize\|refactor\|add lock\|add fcntl\|path traversal"; then
    prompt="## GOAL
$goal

## INSTRUCTIONS
This is a FIX request on an existing project.
Output SED or PATCH entries targeting EXISTING files only.
Format:
SED: path/to/existing.py - brief description of change
PATCH: path/to/existing.py - brief description of change

Do NOT create new files. Target only files that already exist in the project.
One entry per line."
  else
    prompt="## GOAL
$goal

## INSTRUCTIONS
List files to build in dependency order. One per line.
Output ONLY file paths. No markdown."
  fi

  local output
  output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -z "$output" ] && { log "FAIL: No plan."; return 1; }
  echo "$output" | grep -E '^[a-zA-Z0-9_/.+:-]+$' > "$QUEUEFILE" || true
  local count=$(wc -l < "$QUEUEFILE" 2>/dev/null || echo 0)
  log "PLANNED: $count entries"
  [ "$count" -gt 0 ] && cat "$QUEUEFILE"
}

# Persona-based instructions
get_persona_instruction() {
  case "${PERSONA:-LEARNER}" in
    "PRODUCT") echo "You are a product builder. Provide brief, results-oriented updates. Hide complex technical logs." ;;
    "EXPERT") echo "You are a software architect. Focus on logic, dependency chains, and architectural integrity. Provide deep technical reasoning." ;;
    *) echo "You are a helpful assistant. Explain your steps clearly for a learner." ;;
  esac
}

build_file() {
  local filepath="$1" goal="$2" built="$3" knowledge="$4" mode="${5:-NEW}" desc="${6:-}" attempt=0
  local persona_instruction=$(get_persona_instruction)
  
  while [ $attempt -lt $MAX_RETRIES ]; do
    attempt=$((attempt + 1))
    [ $attempt -gt 1 ] && log "RETRY $attempt/$MAX_RETRIES for $filepath"
    
    # Read previous failures for context
    local failure_reason=""
    if [ -f "${REPODIR}/.codex/last_error.log" ]; then
      failure_reason=$(cat "${REPODIR}/.codex/last_error.log")
      rm -f "${REPODIR}/.codex/last_error.log"
    fi

    local prompt
    if [ "$mode" = "PATCH" ]; then
      prompt="## MODE: PATCH EXISTING FILE
## GLOBAL KNOWLEDGE
$knowledge

## PREVIOUS ATTEMPT FAILURE
$failure_reason

## PROJECT GOAL
$goal

## PERSONA: $PERSONA
$persona_instruction

## TARGET FILE: $filepath
## REQUESTED CHANGE: $desc

$built

## INSTRUCTIONS
You are PATCHING an existing file. 
- The COMPLETE current file is shown above as PATCH TARGET.
- Make ONLY the change described in REQUESTED CHANGE.
- Keep EVERYTHING ELSE exactly the same.
- Do NOT rewrite unrelated code.
- Do NOT remove existing functionality.
- Maximum $MAXLINES lines total.
- If previous attempts failed, change your approach (e.g. use full-file rewrite instead of sed).

Output format:
FILE: $filepath
(complete modified file contents)"
    else
      prompt="## MODE: NEW FILE
## GLOBAL KNOWLEDGE
$knowledge

## PROJECT GOAL
$goal

## PERSONA: $PERSONA
$persona_instruction

## FILE TO BUILD: $filepath

$built

## INSTRUCTIONS
Build the COMPLETE file at '$filepath'.
- Write complete working code. No TODOs. No placeholders.
- Maximum $MAXLINES lines.

Output format:
FILE: $filepath
(complete file contents)"
    fi

    local output
    output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
    if [ -n "$output" ] && echo "$output" | grep -q "FILE:"; then
      echo "$output"; return 0
    fi
    log "WARN: Empty output (attempt $attempt)"
  done
  log "FAIL: Could not generate $filepath"
  return 1
}

apply_file() {
  local output="$1"
  local filepath="" content="" found_first=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^FILE:[[:space:]]+(.*) ]] && [ "$found_first" = false ]; then
      filepath="${BASH_REMATCH[1]}"; found_first=true
    elif [ "$found_first" = true ]; then
      content+="$line"$'\n'
    fi
  done <<< "$output"
  [ -n "$filepath" ] && [ -n "$content" ] && {
    # SECURITY: Never write outside REPODIR
    local fp="$REPODIR/$filepath"
    # Resolve to absolute and verify it starts with REPODIR
    fp=$(readlink -f "$fp" 2>/dev/null || echo "$fp")
    if [[ "$fp" != "$REPODIR"* ]]; then
      log "SECURITY: Blocked write outside project: $fp"
      return 1
    fi
    mkdir -p "$(dirname "$fp")"
    printf '%s' "$content" > "$fp"; echo "$filepath"; return 0
  }
  return 1
}

verify_file() {
  local fp="$REPODIR/$1"; [ -f "$fp" ] || { log "VERIFY FAIL: $1 missing"; return 1; }
  case "${1##*.}" in
    py) python3 -m py_compile "$fp" 2>&1 || { log "VERIFY FAIL: $1"; return 1; } ;;
    html|htm) python3 -m html.parser "$fp" 2>/dev/null || { log "VERIFY FAIL: $1"; return 1; } ;;
    js) node --check "$fp" 2>/dev/null || true ;;
  esac
  return 0
}

mark_done() {
  local filepath="$1" lines="$2" mode="$3" entry="$4"
  echo "$entry" >> "$DONEFILE"
  python3 -c "
import json, datetime, os
s=json.load(open('$STATEFILE'))
s['cycle']=s.get('cycle',0)+1
s['last_action']='[$mode] $filepath'
s['successful_changes']=s.get('successful_changes',0)+1
s['total_lines_changed']=s.get('total_lines_changed',0)+$lines
fb=s.get('files_built',[]); fb.append('$entry'); s['files_built']=fb
s['last_success_time']=datetime.datetime.now(datetime.UTC).isoformat()
tmp='$STATEFILE.tmp'; json.dump(s,open(tmp,'w'),indent=2); os.replace(tmp,'$STATEFILE')
" 2>/dev/null || true
}

revert_file() {
  local filepath="$1"
  cd "$REPODIR" && git checkout -- "$filepath" 2>/dev/null || rm -f "$REPODIR/$filepath"
  log "REVERTED: $filepath"
}

commit_all() {
  cd "$REPODIR"
  [ -d .git ] || { git init; git config user.email "codex@localhost"; git config user.name "Codex"; }
  git add -A && git commit -m "[Cycle] $1" 2>/dev/null || true
  # Log change to CHANGELOG
  echo "- [$(date +'%Y-%m-%d %H:%M')] $1" >> "${REPODIR}/CHANGELOG.md"
}

main() {
  [ -n "${1:-}" ] && REPODIR="$1"
  acquire_lock
  trap release_lock EXIT
  ensure_files

  local goal=$(read_goal)

  if [ ! -s "$QUEUEFILE" ]; then
    local file_count=$(find "$REPODIR" -maxdepth 3 -type f -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" 2>/dev/null | wc -l)
    if [ "$file_count" -gt 3 ]; then
      log "EXISTING PROJECT: $file_count files. Generating queue from goal..."
      generate_queue "$goal" "$(get_global_knowledge "$goal")" || exit 1
    else
      local tmpl; tmpl=$(bash "${SKILLDIR}/modules/template-detect.sh" detect "$goal" 2>/dev/null || echo "")
      if [ -n "$tmpl" ]; then echo "$tmpl" > "$QUEUEFILE"; log "TEMPLATE: Using project template"
      else generate_queue "$goal" "$(get_global_knowledge "$goal")" || exit 1; fi
    fi
  fi

  local entry=$(next_file)
  if [ -z "$entry" ]; then
    log "QUEUE EMPTY. Running maintenance mode..."
    bash "${SKILLDIR}/modules/maintenance-mode.sh"
    log "MAINTENANCE DONE. Checking for new queue..."
    generate_queue "$(cat "$GOALFILE")" "$(get_global_knowledge)"
    
    entry=$(next_file)
    if [ -z "$entry" ]; then
      log "ALL DONE. Nothing to do."
      exit 0
    fi
  fi

  local parsed=$(parse_entry "$entry")
  local mode=$(echo "$parsed" | sed "s/MODE=//;s/ .*//")
  local current=$(echo "$parsed" | sed "s/.*FILE=//;s/ .*//")
  local desc=$(echo "$parsed" | awk -F'DESC=' '/DESC=/ {print $2}')

  local cycle=$(python3 -c "import json; print(json.load(open('$STATEFILE')).get('cycle',0)+1)" 2>/dev/null || echo "1")
  log "CYCLE $cycle | $mode: $current"

  local built=$(get_built_context "$mode" "$current")

  local output
  if [ "$mode" = "SED" ]; then
    log "DEBUG: SED branch entered, current=$current"
    log "SED PATCH: Applying targeted changes to $current..."
    CODEX_REPO="$REPODIR" bash "${SKILLDIR}/modules/sed-patcher.sh" "$current" "$desc" "$goal" && output="FILE: $current" || output=""
  elif [ "$mode" = "PATCH" ]; then
    log "PATCH MODE: Generating surgical update for $current..."
    output=$(build_file "$current" "$goal" "$built" "$(get_global_knowledge "$goal")" "$mode" "$desc")
  else
    output=$(build_file "$current" "$goal" "$built" "$(get_global_knowledge "$goal")" "$mode" "$desc")
  fi
  if [ $? -ne 0 ] || [ -z "$output" ]; then log "FAIL: SED or Build failed"; revert_file "$current"; exit 1; fi

  local applied
  if [ "$mode" = "SED" ]; then
    log "DEBUG: SED branch entered, current=$current"
    # SED mode already applied changes and verified syntax
    applied="$current"
    log "DEBUG: applied=$applied, about to verify"
  else
    applied=$(apply_file "$output")
    [ -z "$applied" ] && { log "FAIL: Could not parse output"; revert_file "$current"; exit 1; }
  fi

  if ! verify_file "$applied"; then
    log "VERIFY FAIL: $applied"
    echo "Verification failed for $applied" > "${REPODIR}/.codex/last_error.log"
    revert_file "$applied"; exit 1
  fi
  log "VERIFY: PASS"

  local lines=$(wc -l < "$REPODIR/$applied" 2>/dev/null || echo 0)
  mark_done "$applied" "$lines" "$mode" "$entry"
    log "DEBUG: mark_done called"
  commit_all "$applied"

  local next=$(next_file)
  [ -z "$next" ] && next="DONE"
  log "$mode: $applied (${lines}L) | NEXT: $next"
}

main "$@"
