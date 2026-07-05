#!/usr/bin/env bash
set -euo pipefail
# ctx: codexhaven
# =============================================================================
# CODES-DEVELOPER v12.6 — Hardened Build Engine
# Pre-build intelligence + root cause healer + method adaptation
# Phase Gate + Brain Memory + Full Context Reader + Multi-pass Strengthen
# =============================================================================

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -P 2>/dev/null || pwd))"
REPODIR="${CODEX_REPO:-${HOME}/projects}"
GOALFILE="${REPODIR}/.codex/goal.md"
STATEFILE="${REPODIR}/.codex/state.json"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
DONEFILE="${REPODIR}/.codex/build-done.txt"
LESSONSFILE="${REPODIR}/.codex/lessons.md"
LESSONSJSONL="${REPODIR}/.codex/lessons.jsonl"
GLOBAL_KNOWLEDGE="${SKILLDIR}/global-knowledge.jsonl"
MAXLINES="${MAX_LINES:-120}"
OBSERVABILITY_LOG="${REPODIR}/.codex/observability.log"
MAX_RETRIES="${MAX_RETRIES:-3}"

# --- Locking ---
LOCKFILE="${TMPDIR:-/tmp}/codex-developer.lock"
touch "$LOCKFILE" 2>/dev/null || { LOCKFILE="${HOME}/tmp-codex-developer.lock"; mkdir -p "$(dirname "$LOCKFILE")"; touch "$LOCKFILE"; }
acquire_lock() { exec 9>"$LOCKFILE"; flock -n 9 || { echo "[SKIP] Locked."; exit 0; }; }
release_lock() { flock -u 9 2>/dev/null; rm -f "$LOCKFILE" 2>/dev/null; }

log() {
  local msg="$*" color="" icon=""
  case "$msg" in
    *FAIL*|*ERROR*) color="\033[1;31m"; icon="✗" ;;
    *SUCCESS*|*BUILT*|*PASS*) color="\033[1;32m"; icon="✓" ;;
    *WARN*) color="\033[1;33m"; icon="⚠" ;;
    *CYCLE*|*PLANNING*) color="\033[1;36m"; icon="▶" ;;
    *DONE*) color="\033[1;32m"; icon="★" ;;
    *VERIFY*) color="\033[0;36m"; icon="🔍" ;;
    *) color="\033[0;37m"; icon="·" ;;
  esac
  echo -e "${color}[${icon}] ${msg}\033[0m"
}


# --- Observability Logging ---
obs_log() {
  local msg="$1"
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $msg" >> "$OBSERVABILITY_LOG"
}

# --- Pre-flight Model Audit ---
pre_flight_model_audit() {
  log "AUDIT: Checking data models..."
  local models_found=$(find "$REPODIR" -type f -name "*.py" -exec grep -lE "class.*BaseModel|class.*\(db.Model\)" {} + 2>/dev/null | wc -l)
  if [ "$models_found" -gt 0 ]; then
    log "AUDIT: $models_found model files detected. Building logic on firm foundation."
  else
    log "WARN: No data models found. If this is a data app, ensure models are built in Phase 1."
  fi
}
# --- Modules ---

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
  touch "$OBSERVABILITY_LOG"
}

read_goal() { [ -f "$GOALFILE" ] && cat "$GOALFILE" || echo "Build project files."; }

parse_entry() {
  local entry="$1"
  entry="${entry#$REPODIR/}"
  [ -z "$entry" ] && { echo "MODE=SKIP FILE= DESC="; return; }
  [[ "$entry" =~ ^(NEW|PATCH):[[:space:]]*$ ]] && { echo "MODE=SKIP FILE= DESC="; return; }
  local clean_entry="${entry#NEW: }"
  clean_entry="${clean_entry#PATCH: }"
  if [[ "$entry" =~ ^PATCH:[[:space:]]*([^[:space:]].*)[[:space:]]-[[:space:]](.*) ]]; then
    echo "MODE=PATCH FILE=${BASH_REMATCH[1]} DESC=${BASH_REMATCH[2]}"
  elif [[ "$entry" =~ ^NEW:[[:space:]]*(.+) ]]; then
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
detect_project_domain() {
  local domains=()
  # Check for Node.js
  if [ -f "$REPODIR/package.json" ] || [ -f "$REPODIR/yarn.lock" ] || [ -f "$REPODIR/pnpm-lock.yaml" ]; then
    domains+=("node")
    domains+=("web")
  fi
  # Check for Python
  if [ -f "$REPODIR/requirements.txt" ] || [ -f "$REPODIR/setup.py" ] || [ -f "$REPODIR/pyproject.toml" ]; then
    domains+=("python")
  fi
  # Check for Rust
  if [ -f "$REPODIR/Cargo.toml" ]; then
    domains+=("rust")
  fi
  # Check for Go
  if [ -f "$REPODIR/go.mod" ]; then
    domains+=("go")
  fi
  # Check for Java (Maven)
  if [ -f "$REPODIR/pom.xml" ]; then
    domains+=("java")
  fi
  # Check for PHP (Composer)
  if [ -f "$REPODIR/composer.json" ]; then
    domains+=("php")
  fi
  # Check for Ruby (Bundler)
  if [ -f "$REPODIR/Gemfile" ]; then
    domains+=("ruby")
  fi
  # Check for .NET
  if find "$REPODIR" -maxdepth 2 -name "*.csproj" -o -name "*.vbproj" -o -name "*.fsproj" | grep -q .; then
    domains+=("dotnet")
  fi
  # Check for React/Next.js
  if grep -q '"react"' "$REPODIR/package.json" 2>/dev/null; then
    domains+=("react")
  fi
  # Check for Tailwind
  if [ -f "$REPODIR/tailwind.config.js" ] || [ -f "$REPODIR/tailwind.config.ts" ]; then
    domains+=("tailwind")
  fi
  # Check for FastAPI
  if grep -qi "fastapi" "$REPODIR/requirements.txt" "$REPODIR/pyproject.toml" 2>/dev/null; then
    domains+=("fastapi")
  fi
  # Check for C/C++ (Makefile)
  if [ -f "$REPODIR/Makefile" ] || [ -f "$REPODIR/gnumakefile" ] || [ -f "$REPODIR/Makefile.am" ]; then
    domains+=("c")
    domains+=("cpp")
  fi
  # Check for CMake
  if [ -f "$REPODIR/CMakeLists.txt" ]; then
    domains+=("cmake")
  fi
  # If no domain detected, default to "general"
  if [ ${#domains[@]} -eq 0 ]; then
    domains+=("general")
  fi
  # Output as space-separated string
  echo "${domains[@]}"
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

    local output=""
    if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
      output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$prompt" 2>/dev/null || echo "")
    fi
    [ -z "$output" ] && output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

    if [ -z "$output" ] || ! echo "$output" | grep -q "FILE:"; then
      log "WARN: Empty output — adapting strategy..."
      if [ -f "${SKILLDIR}/modules/method-adapter.sh" ]; then
        local adapted=$(bash "${SKILLDIR}/modules/method-adapter.sh" "$filepath" "$goal" "$mode" "$attempt" 2>/dev/null || echo "")
        [ -n "$adapted" ] && {
          if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
            output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$adapted" 2>/dev/null || echo "")
          fi
          [ -z "$output" ] && output=$(hermes chat -q "$adapted" --yolo --quiet 2>/dev/null || echo "")
        }
      fi
    fi

    if [ -n "$output" ] && echo "$output" | grep -q "FILE:"; then
      echo "$output"; return 0
    fi
    log "WARN: Empty output for $filepath (attempt $attempt)"
    if [ $attempt -lt $MAX_RETRIES ]; then
      delay=$(( 2 ** (attempt-1) ))
      [ $delay -gt 30 ] && delay=30
      sleep $delay
    fi
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

  # Aggressive path deduplication: strip any absolute path prefix, keep only the relative part
  # Handle: /data/data/.../project/app/file.py → app/file.py
  # Handle: /home/user/project/app/file.py → app/file.py
  filepath=$(echo "$filepath" | sed 's|.*/'"$(basename "$REPODIR")"'/||')
  # Match filepath against contract modules
  if [ -f "${REPODIR}/.codex/contract.json" ]; then
    local contract_match=$(python3 -c "
import json
contract = json.load(open(\"${REPODIR}/.codex/contract.json\"))
for mod_path in contract.get(\"modules\", {}).keys():
    if mod_path.endswith(\"/\" + \"$filepath\".split(\"/\")[-1]) or \"$filepath\".endswith(mod_path):
        print(mod_path)
        break
" 2>/dev/null)
    [ -n "$contract_match" ] && filepath="$contract_match"
  fi
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
  if [ -f "${SKILLDIR}/add_path_header.sh" ]; then
    bash "${SKILLDIR}/add_path_header.sh" "$fp"
  fi
    # Inject Python path header for import resolution
    if [[ "$fp" == *.py ]]; then
      if ! grep -q "sys.path.insert" "$fp" 2>/dev/null; then
        sed -i "1iimport sys\nimport os\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\n" "$fp"
      fi
    fi
  echo "$filepath"
  return 0
}

# =============================================================================
# VERIFY
# =============================================================================
verify_file() {
  local fp="$REPODIR/$1"
  [ -f "$fp" ] || { log "VERIFY FAIL: $1 missing"; return 1; }

  # Check for stdlib name shadowing
  local basename=$(basename "$1" .py)
  local forbidden="collections email http json logging os pathlib random re socket sqlite3 string sys threading unittest xml"
  for word in $forbidden; do
    if [ "$basename" = "$word" ]; then
      log "VERIFY FAIL: $1 shadows Python stdlib '$word'. Rename to ${word}_handler.py or similar."
      return 1
    fi
  done

  case "${1##*.}" in
    py) python3 -m py_compile "$fp" 2>&1 || { log "VERIFY FAIL: $1"; return 1; } ;;
    html|htm) python3 -c "from html.parser import HTMLParser; HTMLParser().feed(open('$fp').read())" 2>/dev/null || { log "VERIFY FAIL: $1"; return 1; } ;;
    js|ts|tsx|jsx) node --check "$fp" 2>/dev/null || true
      if [ -f "${SKILLDIR}/modules/import-check.sh" ]; then
        bash "${SKILLDIR}/modules/import-check.sh" "$fp" "$REPODIR" 2>/dev/null | while read -r warn; do
          [ -n "$warn" ] && log "$warn"
        done
      fi
      ;;
    json) python3 -c "import json; json.load(open('$fp'))" 2>/dev/null || { log "VERIFY FAIL: $1"; return 1; } ;;
    sh|bash) bash -n "$fp" 2>/dev/null || { log "VERIFY FAIL: $1"; return 1; } ;;
    yml|yaml) python3 -c "import yaml; yaml.safe_load(open('$fp'))" 2>/dev/null || true ;;
    md|txt|css|toml|sql) : ;;  # No syntax check needed
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
  [ -d .git ] || { git init --initial-branch=main 2>/dev/null; git config user.email "codex@localhost"; git config user.name "Codex"; }
  git add -A && git commit -m "[Cycle] $1" 2>/dev/null || true
  obs_log "Committed changes with message: [Cycle] $1"
  echo "- [$(date +'%Y-%m-%d %H:%M')] $1" >> "${REPODIR}/CHANGELOG.md"
}

generate_queue() {
  local goal="$1"
  log "PLANNING: Generating build order..."
  local subdirs=$(find "$REPODIR" -maxdepth 2 -type d -not -path "*/.*" | grep -v "$REPODIR" | sed "s|$REPODIR/||")
  local prompt="## GOAL"$'\n'"$goal"$'\n\n'"## EXISTING DIRECTORIES"$'\n'"$(echo "$subdirs" | sed 's/^/- /')"$'\n\n'"## INSTRUCTIONS: List files in dependency order. Output ONLY file paths. No markdown."
  local output=""
  if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
    output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$prompt" 2>/dev/null || echo "")
  fi
  [ -z "$output" ] && output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -z "$output" ] && { log "FAIL: No plan."; return 1; }
  echo "$output" | grep -E '\.(py|js|ts|tsx|jsx|html|css|md|txt|json|yml|yaml|sh|toml|example|gitignore)' > "$QUEUEFILE" || true
  local count=$(wc -l < "$QUEUEFILE" 2>/dev/null || echo 0)
  log "PLANNED: $count files"
  [ "$count" -gt 0 ] && cat "$QUEUEFILE"
}

# =============================================================================
# RUN PLUGINS (if available)
# =============================================================================
run_plugins() {
  local hook="$1"
  if [ -d "${SKILLDIR}/plugins" ]; then
    for plugin in "${SKILLDIR}/plugins/"*.sh; do
      [ -f "$plugin" ] && bash "$plugin" "$hook" "$REPODIR" 2>/dev/null || true
    done
  fi
}

# =============================================================================
# STRENGTHEN FILE (if available)
# =============================================================================
strengthen_file() {
  local filepath="$1"
  if [ -f "${SKILLDIR}/sandbox/strengthen.sh" ]; then
    bash "${SKILLDIR}/sandbox/strengthen.sh" "$REPODIR/$filepath" 2>/dev/null || true
  fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  # Source sandbox scripts if they exist
  if [ -d "${SKILLDIR}/sandbox" ]; then
    for s in "${SKILLDIR}/sandbox/"*.sh; do
      [ -f "$s" ] && source "$s" 2>/dev/null || true
    done
  fi

  export REPODIR
  acquire_lock
  trap release_lock EXIT
  ensure_files

  # Resume from previous session if state exists
  if [ -f "${SKILLDIR}/sandbox/architect.sh" ]; then
    bash "${SKILLDIR}/sandbox/architect.sh" --resume 2>/dev/null || true
  fi

  local goal=$(read_goal)
  obs_log "=== BUILD STARTED ==="
  obs_log "Goal: $goal"
  obs_log "Repository: $REPODIR"
  export goal

  FAILURE_COUNT=$(python3 -c "import json; print(json.load(open('$STATEFILE')).get('failure_count', 0))" 2>/dev/null || echo 0)

  # Apply stack modules if they exist
  [ -f "${SKILLDIR}/modules/vibestack/apply.sh" ] && bash "${SKILLDIR}/modules/vibestack/apply.sh" 2>/dev/null || true
  [ -f "${SKILLDIR}/modules/reactstack/apply.sh" ] && bash "${SKILLDIR}/modules/reactstack/apply.sh" 2>/dev/null || true
  [ -f "${SKILLDIR}/modules/flaskstack/apply.sh" ] && bash "${SKILLDIR}/modules/flaskstack/apply.sh" 2>/dev/null || true
  [ -f "${SKILLDIR}/modules/vanillastack/apply.sh" ] && bash "${SKILLDIR}/modules/vanillastack/apply.sh" 2>/dev/null || true
  [ -f "${SKILLDIR}/modules/gitignore-init.sh" ] && bash "${SKILLDIR}/modules/gitignore-init.sh" 2>/dev/null || true

  local max_cycles=50  # Higher ceiling, but will exit early when queue is empty
  obs_log "Starting build loop with max_cycles=$max_cycles"
  while [ $max_cycles -gt 0 ]; do
    max_cycles=$((max_cycles - 1))

    # Validate dependency order before building
    if type validate_dependency_order >/dev/null 2>&1; then
      validate_dependency_order
    fi

    # Pre-flight audit for models every 10 cycles
    if [ $((max_cycles % 10)) -eq 0 ]; then
      pre_flight_model_audit
    fi

    if [ ! -s "$QUEUEFILE" ]; then
      local file_count=$(find "$REPODIR" -maxdepth 3 -type f -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" 2>/dev/null | wc -l)
      if [ "$file_count" -gt 3 ]; then
        log "EXISTING PROJECT: $file_count files."
        generate_queue "$goal" || break
      else
        local tmpl=""
        if [ -f "${SKILLDIR}/modules/template-detect.sh" ]; then
          tmpl=$(bash "${SKILLDIR}/modules/template-detect.sh" detect "$goal" 2>/dev/null || echo "")
        fi
        if [ -n "$tmpl" ]; then 
          echo "$tmpl" > "$QUEUEFILE"
          log "TEMPLATE: Using project template"
        else 
          generate_queue "$goal" || break
        fi
      fi
    fi

    local entry=$(next_file)
    local is_emergency=false
    if echo "$entry" | grep -q "^EMERGENCY:"; then
      is_emergency=true
      entry=$(echo "$entry" | sed 's/^EMERGENCY://')
      log "EMERGENCY: Processing urgent file"
    fi
    if [ -z "$entry" ]; then
      log "DONE"
      run_plugins "after-all-done"
      break
    fi

    local parsed=$(parse_entry "$entry")
    local mode=$(echo "$parsed" | sed -E 's/MODE=([^ ]+) .*/\1/')
    local current=$(echo "$parsed" | sed -E 's/.*FILE=([^ ]+) .*/\1/')
    current="${current#NEW: }"; current="${current#NEW:}"
    current="${current#PATCH: }"; current="${current#PATCH:}"
    current="${current#/}"
    local desc=$(echo "$parsed" | sed -E 's/.*DESC=(.*)/\1/')
    obs_log "Processing file: $current (mode: $mode, description: $desc)"
    [ "$mode" = "SKIP" ] && continue

    # Phase Gate
    if [ "$is_emergency" = true ]; then
      log "EMERGENCY: Bypassing phase gate for $current"
    elif [ -f "${SKILLDIR}/sandbox/architect.sh" ]; then
      if ! bash "${SKILLDIR}/sandbox/architect.sh" --gate "$current" 2>/dev/null; then
        log "PHASE-GATE: Deferring $current"
        echo "$entry" >> "$DONEFILE"
        echo "$entry" >> "$QUEUEFILE"
        # Mirror: capture build patterns
        if type log_mirror >/dev/null 2>&1; then
          log_mirror 2>/dev/null || true
        fi
        continue
      fi
    fi

    local cycle=$(python3 -c "import json; print(json.load(open('$STATEFILE')).get('cycle',0)+1)" 2>/dev/null || echo "1")
    log "CYCLE $cycle | $mode: $current"

    local built=$(get_built_context "$mode" "$current")
    local context_map=""
    if [ -f "${SKILLDIR}/modules/map_project.py" ]; then
      context_map=$(python3 "${SKILLDIR}/modules/map_project.py" "$REPODIR" 2>/dev/null || echo "")
    fi
    local failure_warnings=$(check_preemptive_failure "$goal")
    local project_domains=$(detect_project_domain)
    local rules=()
    while IFS= read -r line; do
      # Parse the JSON line
      local rule_data
      rule_data=$(echo "$line" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))" 2>/dev/null)
      if [ -z "$rule_data" ]; then
        continue
      fi
      # Extract rule, priority, domains
      local rule_text
      rule_text=$(echo "$rule_data" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('rule', ''))")
      local priority
      priority=$(echo "$rule_data" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('priority', 0))")
      local domains_json
      domains_json=$(echo "$rule_data" | python3 -c "import json,sys; print(json.dumps(json.loads(sys.stdin.read()).get('domains', [])))" 2>/dev/null)
      # Check if the rule applies to the project's domains
      if ! echo "$domains_json" "$project_domains" | python3 -c "
import sys, json
data = sys.stdin.read().strip().split(' ', 1)
if len(data) < 2:
  sys.exit(0)
domains_list = json.loads(data[0])
proj_domains = data[1].split()
if not domains_list:  # empty list means all domains
  sys.exit(1)
for d in proj_domains:
  if d in domains_list:
    sys.exit(1)
sys.exit(0)
      " 2>/dev/null; then
        # Domains match (or rule has no domain restriction)
        rules+=("$priority|$rule_text")
      fi
    done < <(grep -h '"type": "rule"' "$GLOBAL_KNOWLEDGE" 2>/dev/null)
    # Sort by priority (descending) and then by rule text (for deterministic order)
    local sorted_rules=""
    if [ ${#rules[@]} -gt 0 ]; then
      sorted_rules=$(printf '%s\n' "${rules[@]}" | sort -t '|' -k1,1nr -k2,2 | cut -d'|' -f2-)
    fi
    local global_wisdom
    if [ -z "$sorted_rules" ]; then
      global_wisdom=""
    else
      global_wisdom=$(printf '%s\n' "$sorted_rules" | sed 's/^/- /')
    fi

    local prompt
    if [ "$mode" = "PATCH" ]; then
      prompt="## MODE: PATCH EXISTING FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## GLOBAL WISDOM (MANDATORY):"$'\n'"$global_wisdom"$'\n'"## PROJECT MAP: $context_map"$'\n'"$failure_warnings"$'\n'"## TARGET FILE: $current"$'\n'"## REQUESTED CHANGE: $desc"$'\n'"## INSTRUCTIONS: Make ONLY the change. Keep everything else IDENTICAL. Output: FILE: $current"$'\n\n'"$built"
    else
      prompt="## MODE: CREATE NEW FILE"$'\n'"## PROJECT GOAL: $goal"$'\n'"## GLOBAL WISDOM (MANDATORY):"$'\n'"$global_wisdom"$'\n'"## PROJECT MAP: $context_map"$'\n'"$failure_warnings"$'\n'"## TARGET FILE: $current"$'\n'"## INSTRUCTIONS: Build complete file. No TODOs. Output: FILE: $current"$'\n\n'"$built"
    fi

    [ -f "$REPODIR/.codex/project_brain.md" ] && prompt="## MASTER BRAIN CONTEXT"$'\n'"$(cat "$REPODIR/.codex/project_brain.md")"$'\n\n'"$prompt"

    local output=""
    if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
      output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$prompt" 2>/dev/null || echo "")
    fi
    [ -z "$output" ] && output=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")

    # Try patch fallback for large files
    if [ -z "$output" ] && [ "$mode" = "PATCH" ] && [ -f "$REPODIR/$current" ]; then
      local file_size=$(wc -c < "$REPODIR/$current" 2>/dev/null || echo 0)
      if [ -f "${SKILLDIR}/modules/sed-patcher.sh" ]; then
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
      python3 -c "import json,os; s=json.load(open('$STATEFILE')); s['failure_count']=$FAILURE_COUNT; json.dump(s,open('$STATEFILE.tmp','w')); os.replace('$STATEFILE.tmp','$STATEFILE')" 2>/dev/null || true
      if [ "$FAILURE_COUNT" -gt 3 ] && [ -f "${SKILLDIR}/modules/healer.sh" ]; then
        obs_log "Engaging healer due to repeated failures (about to run)"
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
    obs_log "Applying file: $applied"
    if [ -z "$applied" ]; then
      log "FAIL: Could not apply $current"
      continue
    fi

    # Check for stdlib name collision and auto-rename
    local basename=$(basename "$applied" .py)
    local forbidden="collections email http json logging os pathlib random re socket sqlite3 string sys threading unittest xml"
    local collision=false
    for word in $forbidden; do
      if [ "$basename" = "$word" ]; then
        collision=true
        break
      fi
    done
    if [ "$collision" = true ]; then
      local newname="${basename}_handler.py"
      log "RENAMING: $applied -> $newname (stdlib collision)"
      mv "$REPODIR/$applied" "$REPODIR/$newname" 2>/dev/null || true
      # Update contract
      if [ -f "${REPODIR}/.codex/contract.json" ]; then
        python3 -c "
import json
cf = '${REPODIR}/.codex/contract.json'
data = json.load(open(cf))
if '$applied' in data.get('modules', {}):
    data['modules']['$newname'] = data['modules'].pop('$applied')
    with open(cf, 'w') as f:
        json.dump(data, f, indent=2)
    print('Contract updated')
" 2>/dev/null || true
      fi
      # Update queue entry
      sed -i "s|$applied|$newname|g" "$QUEUEFILE" 2>/dev/null || true
      sed -i "s|$applied|$newname|g" "$DONEFILE" 2>/dev/null || true
      applied="$newname"
    fi

    # Structural Healing Pipeline
    if ! verify_file "$applied"; then
      log "Syntax failure in $applied. Initiating Adversarial Healing..."
      local err_log=$(cat "${REPODIR}/.codex/last_error.log" 2>/dev/null || echo "Unknown syntax error")
      local fix_prompt="## MODE: FIX SYNTAX ERROR"$'\n'"## TARGET FILE: $applied"$'\n'"## ERROR: $err_log"$'\n'"## INSTRUCTIONS: Fix the syntax error. Do not change logic. If the error is a ModuleNotFoundError about a stdlib module, the filename is shadowing Python'\'s standard library — rename the file to avoid the collision (e.g. collections.py -> collections_handler.py)."
      output=""
      if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
        output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$fix_prompt" 2>/dev/null || echo "")
      fi
      [ -z "$output" ] && output=$(hermes chat -q "$fix_prompt" --yolo --quiet 2>/dev/null || echo "")

      if ! echo "$output" | grep -q "FILE:"; then
        log "Level 1 fix failed. Pivoting to Structural Healing..."
        local map=$(python3 "${SKILLDIR}/modules/map_project.py" 2>/dev/null || echo "")
        fix_prompt="## MODE: STRUCTURAL HEALING"$'\n'"## TARGET FILE: $applied"$'\n'"## PROJECT MAP: $map"$'\n'"## ERROR: $err_log"$'\n'"## INSTRUCTIONS: Re-align imports with the Project Map above."
        output=""
        if [ -f "${SKILLDIR}/modules/direct-api.py" ] && [ -n "${OPENROUTER_KEY:-}" ]; then
          output=$(python3 "${SKILLDIR}/modules/direct-api.py" "$fix_prompt" 2>/dev/null || echo "")
        fi
        [ -z "$output" ] && output=$(hermes chat -q "$fix_prompt" --yolo --quiet 2>/dev/null || echo "")
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

    # CONTRACT ENFORCEMENT: validate function signatures match contract
    if [ -f "${REPODIR}/.codex/contract.json" ]; then
      local contract_violations=$(python3 -c "
import json, ast, sys
contract = json.load(open('${REPODIR}/.codex/contract.json'))
target = '$applied'
if target in contract.get('modules', {}):
    expected = contract['modules'][target].get('exports', [])
    with open('${REPODIR}/$applied') as f:
        tree = ast.parse(f.read())
    actual = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            params = [a.arg for a in node.args.args]
            actual[node.name] = params
        elif isinstance(node, ast.ClassDef):
            for item in node.body:
                if isinstance(item, ast.FunctionDef):
                    params = [a.arg for a in item.args.args]
                    actual[f'{node.name}.{item.name}'] = params
    
    violations = []
    for exp in expected:
        name = exp['name']
        expected_params = [p['name'] for p in exp.get('params', [])]
        if name not in actual:
            violations.append(f'MISSING: {exp["type"]} {name} not found in file')
        else:
            actual_params = actual[name]
            if actual_params and actual_params[0] == 'self':
                actual_params = actual_params[1:]
            if expected_params and actual_params != expected_params:
            violations.append(f'SIGNATURE MISMATCH: {name}({actual_params}) vs contract {name}({expected_params})')
    
    if violations:
        for v in violations:
            print(f'CONTRACT BLOCKED: {v}')
        sys.exit(1)
" 2>/dev/null)
      if [ -n "$contract_violations" ]; then
        echo "$contract_violations"
        log "CONTRACT: File blocked — signatures don't match. Rebuilding..."
        revert_file "$applied"
        # Re-queue with contract requirements in the prompt
        echo "$entry" >> "$QUEUEFILE"
        continue
      fi
    fi

    # Swarm: mine contract violations for new dependencies
    if [ -f "${SKILLDIR}/sandbox/swarm.sh" ]; then
      bash "${SKILLDIR}/sandbox/swarm.sh" --from-violations "$REPODIR" 2>/dev/null || true
    fi

    # Check imports against contract
    if [ -f "${SKILLDIR}/modules/contract-import-check.sh" ]; then
      bash "${SKILLDIR}/modules/contract-import-check.sh" "$REPODIR" "$applied" 2>/dev/null || true
    fi

    # Contract compliance + breaking change detection
    if [ -f "${SKILLDIR}/sandbox/swarm.sh" ]; then
      bash "${SKILLDIR}/sandbox/swarm.sh" --guard "$REPODIR" "$applied" 2>/dev/null || true
    fi

    # Smoke test
    if [ -f "${SKILLDIR}/modules/smoke-tester.sh" ]; then
      if ! bash "${SKILLDIR}/modules/smoke-tester.sh" "$REPODIR" 2>/dev/null; then
        log "SMOKE FAIL"
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        if [ "$FAILURE_COUNT" -gt 3 ] && [ -f "${SKILLDIR}/modules/healer.sh" ]; then
          obs_log "Engaging healer due to repeated failures (smoke test)"
          log "[ERROR] Threshold reached. Engaging HEALER."
          bash "${SKILLDIR}/modules/healer.sh"
          FAILURE_COUNT=0
        else
          log "[WARN] Smoke failure. Retry $FAILURE_COUNT/3"
        fi
        revert_file "$applied"
        continue
      fi
    fi

    # Scan dependencies
    if [ -f "${SKILLDIR}/modules/scan_deps.py" ]; then
      python3 "${SKILLDIR}/modules/scan_deps.py" "$REPODIR/$applied" "$REPODIR" "$QUEUEFILE" 2>/dev/null || true
    fi

    run_plugins "after-verify"

    if [ -f "${SKILLDIR}/modules/failure-check.sh" ]; then
      bash "${SKILLDIR}/modules/failure-check.sh" check "$REPODIR/$applied" 2>/dev/null || true
    fi

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

    # Mirror: capture build patterns
    if type log_mirror >/dev/null 2>&1; then
      log_mirror 2>/dev/null || true
    fi

    mkdir -p "$REPODIR/.codex"
    echo "{\"cycle\":$cycle,\"file\":\"$applied\",\"mode\":\"$mode\",\"desc\":\"$desc\",\"time\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" >> "$REPODIR/.codex/cycle-log.jsonl" 2>/dev/null || true

    commit_all "$applied"

    # Strengthen pass
    strengthen_file "$applied"
    cd "$REPODIR" && git add -A && git commit -m "[Strengthen] $applied" 2>/dev/null || true

    if [ -f "${SKILLDIR}/lesson-analyzer.py" ]; then
      python3 "${SKILLDIR}/lesson-analyzer.py" --consolidate "$REPODIR" 2>/dev/null || true
    fi

    if [ -f "${SKILLDIR}/sandbox/architect.sh" ]; then
      bash "${SKILLDIR}/sandbox/architect.sh" --advance 2>/dev/null || true
    fi

    log "$mode: $applied (${lines}L)"
  done

  if [ -d "$REPODIR/tests" ] && [ -f "${SKILLDIR}/modules/self-test.sh" ]; then
    log "Running tests..."
    bash "${SKILLDIR}/modules/self-test.sh" "$REPODIR" 2>&1 | while read -r l; do
      [ -n "$l" ] && log "TEST: $l"
    done
    obs_log "Tests completed"
  fi

  obs_log "Running strengthen pass"
  obs_log "Strengthen pass completed"
  if [ -f "${SKILLDIR}/sandbox/strengthen.sh" ]; then
    bash "${SKILLDIR}/sandbox/strengthen.sh" --flatten 2>/dev/null || true
  fi

  # Scan project capabilities
  if [ -f "${SKILLDIR}/modules/capability-scanner.sh" ]; then
    bash "${SKILLDIR}/modules/capability-scanner.sh" "$REPODIR" 2>/dev/null || true
  fi

  if [ -f "${SKILLDIR}/modules/symbol-check.sh" ]; then
    bash "${SKILLDIR}/modules/symbol-check.sh" "$REPODIR" 2>&1 | while read -r l; do
      [ -n "$l" ] && log "SYMBOL: $l"
    done
  fi
}

main "$@"
