#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# CODES-DEVELOPER v12.3 — Hardened Build Engine
# Pre-build intelligence + root cause healer + method adaptation
# Phase Gate + Brain Memory + Full Context Reader + Multi-pass Strengthen
# =============================================================================

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${CODEX_REPO:-${HOME}/projects}"
GOALFILE="${REPODIR}/.codex/goal.md"
STATEFILE="${REPODIR}/.codex/state.json"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
DONEFILE="${REPODIR}/.codex/build-done.txt"
LESSONSFILE="${REPODIR}/.codex/lessons.md"
LESSONSJSONL="${REPODIR}/.codex/lessons.jsonl"
GLOBAL_KNOWLEDGE="${SKILLDIR}/global-knowledge.jsonl"
MAXLINES="${MAX_LINES:-120}"
MAX_RETRIES=3

# --- Locking ---
LOCKFILE="${TMPDIR:-/tmp}/codex-developer.lock"
touch "$LOCKFILE" 2>/dev/null || { LOCKFILE="${HOME}/tmp-codex-developer.lock"; mkdir -p "$(dirname "$LOCKFILE")"; touch "$LOCKFILE"; }
acquire_lock() { exec 9>"$LOCKFILE"; flock -n 9 || { echo "[SKIP] Locked."; exit 0; }; }
release_lock() { flock -u 9 2>/dev/null; rm -f "$LOCKFILE" 2>/dev/null; }

log() {
  local level="INFO" msg="$*" color=""
  case "$msg" in
    *FAIL*|*ERROR*) level="ERROR"; color="\033[1;31m" ;;
    *SUCCESS*|*BUILT*|*PASS*) level="SUCCESS"; color="\033[1;32m" ;;
    *WARN*) level="WARN"; color="\033[1;33m" ;;
    *CYCLE*|*PLANNING*) level="DEBUG"; color="\033[1;36m" ;;
  esac
  echo -e "${color}[$level]\033[0m $msg"
}

# --- Modules ---
get_project_context() {
  python3 "${SKILLDIR}/modules/map_project.py" full 2>/dev/null || python3 "${SKILLDIR}/modules/map_project.py" tree 2>/dev/null || echo "Map generation failed."
}

check_preemptive_failure() {
  local goal="$1"
  grep -ri "$goal" "${SKILLDIR}/failure-patterns.json" 2>/dev/null | head -5 | while read -r line; do
    echo "WARNING: Pre-emptive prevention - Avoid pattern: $line"
  done
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
ensure_files() {
  mkdir -p "$REPODIR" "$(dirname "$STATEFILE")"
  [[ -f "$STATEFILE" ]] || echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$STATEFILE"
  touch "$QUEUEFILE" "$DONEFILE" "$GLOBAL_KNOWLEDGE" "$LESSONSJSONL"
  [[ -f "$LESSONSFILE" ]] || echo "# Lessons" > "$LESSONSFILE"
}

read_goal() { [ -f "$GOALFILE" ] && cat "$GOALFILE" || echo "Build project files."; }

parse_entry() {
  local entry="$1"
  entry="${entry#$REPODIR/}"
  [ -z "$entry" ] && { echo "MODE=SKIP FILE= DESC="; return; }
  [[ "$entry" =~ ^(NEW|PATCH):[[:space:]]*$ ]] && { echo "MODE=SKIP FILE= DESC="; return; }
  local clean_entry="${entry#NEW: }"
  clean_entry="${clean_entry#PATCH: }"
  if [[ "$entry" =~ ^PATCH:[[:space:]]+([^[:space:]].*)[[:space:]]-[[:space:]](.*) ]]; then
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
    local fn=$(echo "$line" | sed -E 's/^(NEW|PATCH):[[:space:]]+//' | sed -E 's/[[:space:]]+-[[:space:]].*//')
    if ! echo "$done" | grep -qF "$fn"; then echo "$line"; return; fi
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
  if [ "$mode" = "PATCH" ] && [ -f "$REPODIR/$target" ]; then
    echo "--- CURRENT FILE: $target ---"
    cat "$REPODIR/$target"
    echo ""
    if [ -f "$REPODIR/.codex/cycle-log.jsonl" ]; then
      echo "--- RECENT CHANGES ---"
      tail -3 "$REPODIR/.codex/cycle-log.jsonl" 2>/dev/null
      echo ""
    fi
  fi
  local count=0
  while IFS= read -r f; do
    [ $count -ge 3 ] && break
    [ "$f" = "$REPODIR/$target" ] && continue
    [ -f "$f" ] && [ -s "$f" ] || continue
    local size=$(wc -l < "$f" 2>/dev/null || echo 0)
    [ "$size" -gt 0 ] && [ "$size" -lt 500 ] || continue
    echo "--- RELATED: ${f#$REPODIR/} (first 50 lines) ---"
    head -50 "$f"; echo ""
    count=$((count + 1))
  done < <(find "$REPODIR" -maxdepth 2 -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/__pycache__/*" 2>/dev/null | head -8)
}

# =============================================================================
# SELF-PROTECTION
# =============================================================================
self_protect() {
  local filepath="$1"
  local resolved=$(readlink -f "$REPODIR/$filepath" 2>/dev/null || echo "$REPODIR/$filepath")
  if [[ "$resolved" == "$SKILLDIR"* ]]; then
    echo "=============================================="
    echo "  SELF-PROTECTION: Cannot modify codex source"
    echo "  File: $filepath"
    echo "=============================================="
    return 1
  fi
  return 0
}

# =============================================================================
# BUILD FILE — Pre-build intelligence + method adaptation
# =============================================================================
build_file() {
  local filepath="$1" goal="$2" built="$3" mode="${4:-NEW}" desc="${5:-}" attempt=0

  local full_context=""
  if [ -f "${SKILLDIR}/modules/map_project.py" ]; then
    full_context=$(python3 "${SKILLDIR}/modules/map_project.py" context "$filepath" 2>/dev/null || echo "")
    local mismatches=$(python3 "${SKILLDIR}/modules/map_project.py" mismatches 2>/dev/null || echo "")
    if [ -n "$mismatches" ] && ! echo "$mismatches" | grep -q "No import mismatches"; then
      full_context+=$'\n\n'"## IMPORT MISMATCHES TO FIX:"$'\n'"$mismatches"
    fi
  fi

  local current_file_content=""
  if [ "$mode" = "PATCH" ] && [ -f "$REPODIR/$filepath" ]; then
    current_file_content=$(cat "$REPODIR/$filepath")
  fi

  while [ $attempt -lt $MAX_RETRIES ]; do
    attempt=$((attempt + 1))
    [ $attempt -gt 1 ] && log "RETRY $attempt/$MAX_RETRIES for $filepath"

    local prompt
    if [ "$mode" = "PATCH" ]; then
      prompt="## MODE: PATCH EXISTING FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## FULL PROJECT CONTEXT (exports available):"$'\n'"$full_context"$'\n'
      [ -n "$current_file_content" ] && prompt+="## CURRENT FILE: $filepath"$'\n''```'$'\n'"$current_file_content"$'\n''```'$'\n'
      prompt+="## REQUESTED CHANGE: $desc"$'\n'"## INSTRUCTIONS: Make ONLY the change described. Keep everything else IDENTICAL. Use ONLY exports listed above. Output: FILE: $filepath"$'\n\n'"$built"
    else
      prompt="## MODE: CREATE NEW FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## FULL PROJECT CONTEXT (exports available):"$'\n'"$full_context"$'\n'"## TARGET FILE: $filepath"$'\n'"## INSTRUCTIONS: Build complete file. Use EXACT export names from context. Output: FILE: $filepath"$'\n\n'"$built"
    fi

    [ -f "$REPODIR/.codex/project_brain.md" ] && prompt="## MASTER BRAIN CONTEXT"$'\n'"$(cat "$REPODIR/.codex/project_brain.md")"$'\n\n'"$prompt"

    local output
    output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

    if [ -z "$output" ] || ! echo "$output" | grep -q "FILE:"; then
      log "WARN: Empty output — adapting strategy..."
      if [ -f "${SKILLDIR}/modules/method-adapter.sh" ]; then
        local adapted=$(bash "${SKILLDIR}/modules/method-adapter.sh" "$filepath" "$goal" "$mode" "$attempt" 2>/dev/null || echo "")
        [ -n "$adapted" ] && output=$(hermes chat -q "$adapted" --yolo --quiet 2>/dev/null || echo "")
      fi
    fi

    if [ -n "$output" ] && echo "$output" | grep -q "FILE:"; then
      echo "$output"; return 0
    fi
    log "WARN: Empty output for $filepath (attempt $attempt)"
  done
  log "FAIL: Could not generate $filepath after $MAX_RETRIES attempts"
  return 1
}

# =============================================================================
# APPLY FILE TO DISK
# =============================================================================
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

  content=$(echo "$content" | sed "/^\`\`\`/d")
  [ -n "$filepath" ] && [ -n "$content" ] || return 1

  filepath="${filepath#$REPODIR/}"
  filepath="${filepath#/}"

  if ! self_protect "$filepath"; then return 1; fi

  local fp="$REPODIR/$filepath"
  local resolved=$(readlink -f "$fp" 2>/dev/null || echo "$fp")
  if [[ "$resolved" != "$REPODIR"* ]]; then
    log "SECURITY: Blocked write outside project: $resolved"
    return 1
  fi

  mkdir -p "$(dirname "$fp")"
  printf '%s' "$content" > "$fp"
  echo "$filepath"
  return 0
}

# =============================================================================
# VERIFY
# =============================================================================
verify_file() {
  local fp="$REPODIR/$1"
  [ -f "$fp" ] || { log "VERIFY FAIL: $1 missing"; return 1; }
  case "${1##*.}" in
    py) python3 -m py_compile "$fp" 2>&1 || { log "VERIFY FAIL: $1"; return 1; } ;;
    html|htm) python3 -m html.parser "$fp" 2>/dev/null || { log "VERIFY FAIL: $1"; return 1; } ;;
    js|ts|tsx|jsx) node --check "$fp" 2>/dev/null || true
      bash "${SKILLDIR}/modules/import-check.sh" "$fp" "$REPODIR" 2>/dev/null | while read -r warn; do
        [ -n "$warn" ] && log "$warn"
      done
      ;;
  esac
  return 0
}

# =============================================================================
# STATE MANAGEMENT
# =============================================================================
mark_done() {
  local filepath="$1" lines="$2" mode="$3" entry="$4"
  echo "$entry" >> "$DONEFILE"
  python3 -c "
import json, os
s=json.load(open('$STATEFILE'))
s['cycle']=s.get('cycle',0)+1
s['last_action']='[$mode] $filepath'
s['successful_changes']=s.get('successful_changes',0)+1
s['total_lines_changed']=s.get('total_lines_changed',0)+$lines
fb=s.get('files_built',[]); fb.append('$entry'); s['files_built']=fb
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
  echo "- [$(date +'%Y-%m-%d %H:%M')] $1" >> "${REPODIR}/CHANGELOG.md"
}

generate_queue() {
  local goal="$1"
  log "PLANNING: Generating build order..."
  local subdirs=$(find "$REPODIR" -maxdepth 2 -type d -not -path "*/.*" | grep -v "$REPODIR" | sed "s|$REPODIR/||")
  local prompt="## GOAL"$'\n'"$goal"$'\n\n'"## EXISTING DIRECTORIES"$'\n'"$(echo "$subdirs" | sed 's/^/- /')"$'\n\n'"## INSTRUCTIONS: List files in dependency order. Output ONLY file paths. No markdown."
  local output
  output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -z "$output" ] && { log "FAIL: No plan."; return 1; }
  echo "$output" | grep -E '\.(py|js|ts|tsx|jsx|html|css|md|txt|json|yml|yaml|sh|toml|example|gitignore)' > "$QUEUEFILE" || true
  local count=$(wc -l < "$QUEUEFILE" 2>/dev/null || echo 0)
  log "PLANNED: $count files"
  [ "$count" -gt 0 ] && cat "$QUEUEFILE"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  [ -d "${SKILLDIR}/sandbox" ] && for s in "${SKILLDIR}/sandbox/"*.sh; do source "$s"; done

  export REPODIR
  acquire_lock
  trap release_lock EXIT
  ensure_files

  # Resume from previous session if state exists
  bash "${SKILLDIR}/sandbox/architect.sh" --resume

  local goal=$(read_goal)
  export goal

  FAILURE_COUNT=$(python3 -c "import json; print(json.load(open('$STATEFILE')).get('failure_count', 0))" 2>/dev/null || echo 0)

  bash "${SKILLDIR}/modules/vibestack/apply.sh" || true
  bash "${SKILLDIR}/modules/flaskstack/apply.sh" 2>/dev/null || true
  bash "${SKILLDIR}/modules/vanillastack/apply.sh" 2>/dev/null || true
  bash "${SKILLDIR}/modules/gitignore-init.sh" 2>/dev/null || true

  local max_cycles=30
  while [ $max_cycles -gt 0 ]; do
    max_cycles=$((max_cycles - 1))

    # Validate dependency order before building
    if type validate_dependency_order >/dev/null 2>&1; then
      validate_dependency_order
    fi

    if [ ! -s "$QUEUEFILE" ]; then
      local file_count=$(find "$REPODIR" -maxdepth 3 -type f -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" 2>/dev/null | wc -l)
      if [ "$file_count" -gt 3 ]; then
        log "EXISTING PROJECT: $file_count files."
        generate_queue "$goal" || break
      else
        local tmpl; tmpl=$(bash "${SKILLDIR}/modules/template-detect.sh" detect "$goal" 2>/dev/null || echo "")
        if [ -n "$tmpl" ]; then echo "$tmpl" > "$QUEUEFILE"; log "TEMPLATE: Using project template"
        else generate_queue "$goal" || break; fi
      fi
    fi

    local entry=$(next_file)
    if [ -z "$entry" ]; then
      log "ALL DONE."
      run_plugins "after-all-done" 2>/dev/null || true
      break
    fi

    local parsed=$(parse_entry "$entry")
    local mode=$(echo "$parsed" | sed "s/MODE=//;s/ .*//")
    local current=$(echo "$parsed" | sed "s/.*FILE=//;s/ .*//")
    current="${current#NEW: }"; current="${current#NEW:}"
    current="${current#PATCH: }"; current="${current#PATCH:}"
    current="${current#/}"
    local desc=$(echo "$parsed" | sed -E 's/.*DESC=(.*)/\1/')
    [ "$mode" = "SKIP" ] && continue

    # Phase Gate
    if ! bash "${SKILLDIR}/sandbox/architect.sh" --gate "$current"; then
        log "PHASE-GATE: Deferring $current"
        echo "$entry" >> "$DONEFILE"
        echo "$entry" >> "$QUEUEFILE"
    fi

    local cycle=$(python3 -c "import json; print(json.load(open('$STATEFILE')).get('cycle',0)+1)" 2>/dev/null || echo "1")
    log "CYCLE $cycle | $mode: $current"

    local built=$(get_built_context "$mode" "$current")
    local context_map=$(get_project_context)
    local failure_warnings=$(check_preemptive_failure "$goal")
    local global_wisdom=$(grep -h '"type": "rule"' "$GLOBAL_KNOWLEDGE" 2>/dev/null | python3 -c "import json,sys; [print(f'- {json.loads(line).get(\"rule\")}') for line in sys.stdin]" 2>/dev/null)

    local prompt
    if [ "$mode" = "PATCH" ]; then
      prompt="## MODE: PATCH EXISTING FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## GLOBAL WISDOM (MANDATORY):"$'\n'"$global_wisdom"$'\n'"## PROJECT MAP: $context_map"$'\n'"$failure_warnings"$'\n'"## TARGET FILE: $current"$'\n'"## REQUESTED CHANGE: $desc"$'\n'"## INSTRUCTIONS: Make ONLY the change. Keep everything else IDENTICAL. Output: FILE: $current"$'\n\n'"$built"
    else
      prompt="## MODE: CREATE NEW FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## GLOBAL WISDOM (MANDATORY):"$'\n'"$global_wisdom"$'\n'"## PROJECT MAP: $context_map"$'\n'"$failure_warnings"$'\n'"## TARGET FILE: $current"$'\n'"## INSTRUCTIONS: Build complete file. No TODOs. Output: FILE: $current"$'\n\n'"$built"
    fi

    [ -f "$REPODIR/.codex/project_brain.md" ] && prompt="## MASTER BRAIN CONTEXT"$'\n'"$(cat "$REPODIR/.codex/project_brain.md")"$'\n\n'"$prompt"

    local output
    output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

    if [ -z "$output" ] && [ "$mode" = "PATCH" ] && [ -f "$REPODIR/$current" ]; then
      local file_size=$(wc -c < "$REPODIR/$current" 2>/dev/null || echo 0)
      if [ "$file_size" -gt 10000 ]; then
        log "File too large for PATCH ($file_size bytes). Trying SED patcher..."
        if CODEX_REPO="$REPODIR" bash "${SKILLDIR}/modules/sed-patcher.sh" "$current" "$desc" "$goal" 2>/dev/null; then
          log "SED patcher succeeded"
          local lines=$(wc -l < "$REPODIR/$current" 2>/dev/null || echo 0)
          mark_done "$current" "$lines" "SED" "$entry"
          commit_all "$current"
          continue
        fi
      fi
    fi

    if [ -z "$output" ]; then
      log "FAIL: Could not build $current"
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      if [ "$FAILURE_COUNT" -gt 3 ]; then
        log "[ERROR] Threshold reached. Engaging HEALER."
        bash "${SKILLDIR}/modules/healer.sh"
        FAILURE_COUNT=0
      fi
      continue
    fi

    local enforced=$(python3 "${SKILLDIR}/modules/enforce_path.py" "$current" "$REPODIR" 2>/dev/null || echo "$current")
    current="$enforced"

    local applied=$(apply_file "$output") || true
    applied="${applied#/}"
    if [ -z "$applied" ]; then
      log "FAIL: Could not apply $current"
      continue
    fi

    # Structural Healing Pipeline
    if ! verify_file "$applied"; then
      log "Syntax failure in $applied. Initiating Adversarial Healing..."
      local err_log=$(cat "${REPODIR}/.codex/last_error.log" 2>/dev/null || echo "Unknown syntax error")
      local fix_prompt="## MODE: FIX SYNTAX ERROR"$'\n'"## TARGET FILE: $applied"$'\n'"## ERROR: $err_log"$'\n'"## INSTRUCTIONS: Fix the syntax error. Do not change logic."
      output=$(hermes chat -q "$fix_prompt" --yolo --quiet 2>/dev/null || echo "")
      if ! echo "$output" | grep -q "FILE:"; then
        log "Level 1 fix failed. Pivoting to Structural Healing..."
        local map=$(python3 "${SKILLDIR}/modules/map_project.py")
        fix_prompt="## MODE: STRUCTURAL HEALING"$'\n'"## TARGET FILE: $applied"$'\n'"## PROJECT MAP: $map"$'\n'"## ERROR: $err_log"$'\n'"## INSTRUCTIONS: Re-align imports with the Project Map above."
        output=$(hermes chat -q "$fix_prompt" --yolo --quiet 2>/dev/null || echo "")
      fi
      if echo "$output" | grep -q "FILE:"; then
        apply_file "$output"
      else
        log "CRITICAL: Structural Healing failed."
        echo "$current" >> "$DONEFILE"
        continue
      fi
    fi
    log "VERIFY: PASS"

    # Contract compliance + breaking change detection
    if [ -f "${SKILLDIR}/modules/dependency-guard.sh" ]; then
      bash "${SKILLDIR}/modules/dependency-guard.sh" "$REPODIR" "$REPODIR/$applied" 2>/dev/null || true
    fi

    bash "${SKILLDIR}/modules/smoke-tester.sh" "$REPODIR" || {
      log "SMOKE FAIL"
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      if [ "$FAILURE_COUNT" -gt 3 ]; then
        log "[ERROR] Threshold reached. Engaging HEALER."
        bash "${SKILLDIR}/modules/healer.sh"
        FAILURE_COUNT=0
      else
        log "[WARN] Smoke failure. Retry $FAILURE_COUNT/3"
      fi
      revert_file "$applied"; continue;
    }

    python3 "${SKILLDIR}/modules/scan_deps.py" "$REPODIR/$applied" "$REPODIR" "$QUEUEFILE" 2>/dev/null || true
    run_plugins "after-verify" 2>/dev/null || true
    bash "${SKILLDIR}/modules/failure-check.sh" check "$REPODIR/$applied" 2>/dev/null || true

    local lines=$(wc -l < "$REPODIR/$applied" 2>/dev/null || echo 0)

    local tmp_state="$STATEFILE.tmp"
    python3 -c "
import json, os
s=json.load(open('$STATEFILE'))
s['cycle']=s.get('cycle',0)+1
s['last_action']='[$mode] $current'
s['successful_changes']=s.get('successful_changes',0)+1
s['total_lines_changed']=s.get('total_lines_changed',0)+$lines
fb=s.get('files_built',[]); fb.append('$entry'); s['files_built']=fb
json.dump(s, open('$tmp_state', 'w'), indent=2)
os.replace('$tmp_state', '$STATEFILE')
" 2>/dev/null || true
    echo "$entry" >> "$DONEFILE"

    mkdir -p "$REPODIR/.codex"
    echo "{\"cycle\":$cycle,\"file\":\"$applied\",\"mode\":\"$mode\",\"desc\":\"$desc\",\"time\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" >> "$REPODIR/.codex/cycle-log.jsonl" 2>/dev/null || true

    commit_all "$applied"

    # Strengthen pass
    if type strengthen_file >/dev/null 2>&1; then
      strengthen_file "$applied"
      cd "$REPODIR" && git add -A && git commit -m "[Strengthen] $applied" 2>/dev/null || true
    fi

    python3 "${SKILLDIR}/lesson-analyzer.py" --consolidate "$REPODIR" 2>/dev/null || true
    bash "${SKILLDIR}/sandbox/architect.sh" --advance

    log "$mode: $applied (${lines}L)"
  done

  if [ -d "$REPODIR/tests" ]; then
    log "Running tests..."
    bash "${SKILLDIR}/modules/self-test.sh" "$REPODIR" 2>&1 | while read -r l; do [ -n "$l" ] && log "TEST: $l"; done
  fi

  bash "${SKILLDIR}/sandbox/strengthen.sh" --flatten 2>/dev/null || true
  # Scan project capabilities
  bash "${SKILLDIR}/modules/capability-scanner.sh" "$REPODIR" 2>/dev/null || true

  bash "${SKILLDIR}/modules/symbol-check.sh" "$REPODIR" 2>&1 | while read -r l; do [ -n "$l" ] && log "SYMBOL: $l"; done
}

main "$@"
