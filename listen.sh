#!/usr/bin/env bash
set -euo pipefail
# ctx: codexhaven
# =============================================================================
# CODES-DEVELOPER v12.5 — Stress-tested — Natural Language Software Factory
# Modes: NEW | EXISTING | REVIEW | CONTINUATION | CHECK | DEPLOY
# Flow: listen → recon (research + phases) → approve → runcycle (phase by phase)
# =============================================================================

[ -f "$HOME/.hermes/.env" ] && set -a && source "$HOME/.hermes/.env" && set +a 2>/dev/null || true
SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -P 2>/dev/null || pwd))"
REPODIR=""
REQUEST=""
MODE=""

# =============================================================================
# UNDERSTAND — detect mode, set REPODIR
# =============================================================================
understand() {
  local request="$1" project_dir="$2"
  echo -e "\033[1;36m==============================================\033[0m"
  echo -e "\033[1;32m  CODES-DEVELOPER v12.5 — Stress-tested\033[0m"
  echo -e "\033[1;36m==============================================\033[0m"
  echo -e "\033[1;33mRequest:\033[0m $request"
  echo ""

  local local_path=$(echo "$request" | grep -oE "(~/\S+|/data/\S+)" | head -1)
  if [ -n "$local_path" ]; then
    case "$local_path" in
      ~/*) REPODIR="${local_path/#\~/$HOME}" ;;
      *)   REPODIR="$local_path" ;;
    esac
    REPODIR="$(realpath "$REPODIR" 2>/dev/null || echo "$REPODIR")"
    [ -d "$REPODIR" ] && echo "Local project: $REPODIR" || REPODIR=""
  fi
  [ -z "$REPODIR" ] && REPODIR="${project_dir:-$HOME/projects}"
  export REPODIR

  local code_files=$(find "$REPODIR" -maxdepth 4 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.html" -o -name "*.css" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l)

  if echo "$request" | grep -qiE "deploy to production|deploy to vercel|ship to production|push to production"; then
    MODE="DEPLOY"
  elif echo "$request" | grep -qiE "^generate|^create.*tool|^make.*tool|build.*cli tool|^Generate"; then
    MODE="GENERATE"
  elif echo "$request" | grep -qiE "^(check|scan|audit|diagnose|inspect|verify)( |$)"; then
    MODE="CHECK"
  elif echo "$request" | grep -qiE "(^review|security review|bug review|code review|audit|scan for|analyze this)"; then
    MODE="REVIEW"
  elif echo "$request" | grep -qiE "^direct|^continue.*build|^resume|^pick up where"; then
    MODE="DIRECT"
  elif echo "$request" | grep -qiE '\.(py|js|ts|html|css|sh|json|md|txt)'; then
    MODE="DIRECT"
  elif [ "$code_files" -lt 1 ]; then
    MODE="NEW"
  elif [ -f "$REPODIR/.codex/build-queue.txt" ] && [ -s "$REPODIR/.codex/build-queue.txt" ]; then
    MODE="CONTINUATION"
  else
    MODE="EXISTING"
  fi
  echo -e "\033[1;35mMode:\033[0m $MODE"
  echo ""
  export MODE
}

# =============================================================================
# MODE: NEW — recon researches, you approve phases, runcycle executes
# =============================================================================
mode_new() {
  mkdir -p "$REPODIR/.codex"
  echo "$REQUEST" > "$REPODIR/.codex/goal.md"

  # 1. RECON: research + generate phases.json
  echo "Initiating Discovery Phase..."
  if [ -f "${SKILLDIR}/sandbox/recon.sh" ]; then
    bash "${SKILLDIR}/sandbox/recon.sh" "$REPODIR"
  fi

  # Check if request contains explicit file paths — if so, use them directly
  local explicit_files=$(echo "$REQUEST" | grep -oE '[a-zA-Z0-9_/.-]+\.(py|js|ts|tsx|jsx|html|css|sh|json|yml|yaml|md|txt|toml|sql|ipynb)' | sort -u | wc -l)
  if [ "$explicit_files" -ge 1 ]; then
    MODE="DIRECT"
    echo "[NEW] Detected $explicit_files explicit files in request — using direct mode"
    export MODE
    return
  fi

  # 1.5. Generate interface contract
    # Pass recon's file count to architect
  export RECON_FILE_COUNT=$(python3 -c "import json; phases=json.load(open('$REPODIR/.codex/phases.json')); print(sum(len(p.get('files',[])) for p in phases.get('phases',[])))" 2>/dev/null || echo "unknown")
  export RECON_PHASES=$(python3 -c "import json; phases=json.load(open('$REPODIR/.codex/phases.json')); [print(f'{p.get("name",p.get("id"))}: {p.get("files",[])}') for p in phases.get('phases',[])]" 2>/dev/null || echo "")

  echo "[CONTRACT] Designing interfaces..."
  bash "${SKILLDIR}/sandbox/architect.sh" --contract "$REPODIR"

  # 2. Show phases for approval
  if [ -f "$REPODIR/.codex/phases.json" ] && [ -s "$REPODIR/.codex/phases.json" ]; then
    echo ""
    echo "--- PHASE PLAN ---"
    python3 -c "
import json
data = json.load(open('$REPODIR/.codex/phases.json'))
for i, p in enumerate(data.get('phases', [])):
    print(f\"Phase {i+1}: {p.get('name', p.get('id', 'unnamed'))}\")
    files = p.get('files', p.get('tasks', []))
    for f in files:
        print(f'  - {f}')
    print()
" 2>/dev/null || cat "$REPODIR/.codex/phases.json"
    echo "--------------------"
    # Check contract-phase alignment
  :

  if [ "${AUTO_YES:-false}" = "true" ]; then
    echo "AUTO_YES: Approving phase plan..."
  else
    echo -n "Approve this phase plan? (y/n): "
    read -r confirm
    if [ "$confirm" != "y" ]; then
      echo "Aborted. Edit phases.json and retry, or re-run with a different request."
      exit 0
    fi
  fi
  else
    echo "[RECON] No phases.json produced. Falling back to direct spec generation..."
    local spec=$(hermes chat -q "Create a specification with phases.json containing 'files' arrays for: $REQUEST. Output the spec and a valid JSON phases block." --yolo --quiet 2>/dev/null || echo "")
    if [ -z "$spec" ]; then
      echo "ERROR: Both recon and fallback failed."
      exit 1
    fi
    echo "$spec"
    echo "--------------------"
    echo -n "Approve? (y/n): "
    read -r confirm
    [ "$confirm" != "y" ] && { echo "Aborted."; exit 0; }
    # Extract JSON and write phases.json
    echo "$spec" | python3 -c "
import sys, json
text = sys.stdin.read()
start = text.find('{')
if start != -1:
    depth = 0
    for i, c in enumerate(text[start:], start):
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                try:
                    data = json.loads(text[start:i+1])
                    with open('$REPODIR/.codex/phases.json', 'w') as f:
                        json.dump(data, f, indent=2)
                except: pass
                break
" 2>/dev/null || true
  fi

  # 3. Build queue FROM phases.json in phase order
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"

  if [ -f "$REPODIR/.codex/phases.json" ] && [ -s "$REPODIR/.codex/phases.json" ]; then
    python3 -c "
import json
data = json.load(open('$REPODIR/.codex/phases.json'))
count = 0
for phase in data.get('phases', []):
    for f in phase.get('files', []):
        # Strip leading slash for relative paths
        f = f.lstrip('/')
        print(f'NEW:{f}')
        count += 1
" > "$REPODIR/.codex/build-queue.txt" 2>/dev/null || true
  fi

  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)

  if [ "$entries" -eq 0 ] && [ -d "$REPODIR" ] && [ "$(find "$REPODIR" -name '*.py' | wc -l)" -gt 0 ]; then
    echo "All specified files already exist. Use PATCH to modify existing files."
    echo "Or use: listen.sh 'Continue' $REPODIR to resume from queue."
    exit 0
  fi
  echo "Plan: $entries files in phase order"
  [ "$entries" -gt 0 ] && cat "$REPODIR/.codex/build-queue.txt"
  [ "$entries" -eq 0 ] && { echo "No files in phases.json. Add 'files' arrays to each phase."; exit 1; }

  # 4. Execute
  run_build_loop
}

# =============================================================================
# MODE: EXISTING
# =============================================================================
mode_existing() {
  echo "Analyzing existing project..."
  
  # Check capabilities first
  if [ -f "$REPODIR/.codex/capabilities.json" ]; then
    echo "Project capabilities found."
    python3 -c "
import json, sys
caps = json.load(open('$REPODIR/.codex/capabilities.json'))
# Check if request matches a capability
request = open('$REPODIR/.codex/goal.md').read().lower() if __import__('os').path.exists('$REPODIR/.codex/goal.md') else ''
for cat in ['generators', 'scripts']:
    for name, info in caps.get(cat, {}).items():
        if any(word in request for word in name.replace('.py','').replace('_',' ').split()):
            print(f'CAPABILITY MATCH: {info["run"]}')
            print(f'RUN_THIS={info["run"]}')
" 2>/dev/null
  fi
  mkdir -p "$REPODIR/.codex"
  > "$REPODIR/.codex/build-queue.txt"

  local project_map=$(python3 "${SKILLDIR}/modules/map_project.py" "$REPODIR" 2>/dev/null || echo "")
  local requested_files=$(echo "$REQUEST" | grep -oE '[a-zA-Z0-9_/.-]+\.[a-zA-Z0-9]+' | sort -u)

  for f in $requested_files; do
    local target_path="$f"
    if [[ "$f" != *"/"* ]]; then
      local match=$(echo "$project_map" | grep "/$f$" | head -1 || true)
      [ -n "$match" ] && target_path="${match#$REPODIR/}"
    fi
    if [ -f "$REPODIR/$target_path" ]; then
      echo "PATCH: $target_path - $REQUEST" >> "$REPODIR/.codex/build-queue.txt"
    else
      echo "NEW: $target_path" >> "$REPODIR/.codex/build-queue.txt"
    fi
  done

  local count=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
  echo "Plan: $count changes"
  [ "$count" -gt 0 ] && cat "$REPODIR/.codex/build-queue.txt"
  run_build_loop
}

# =============================================================================
# MODE: DIRECT — Seamless continuation
# =============================================================================
mode_direct() {
  mkdir -p "$REPODIR/.codex"
  echo "$REQUEST" > "$REPODIR/.codex/goal.md"

  # Check for unfinished builds first
  if [ -f "$REPODIR/.codex/build-done.txt" ] && [ -s "$REPODIR/.codex/build-done.txt" ] && \
     [ -f "$REPODIR/.codex/build-queue.txt" ] && [ -s "$REPODIR/.codex/build-queue.txt" ]; then
    local done_count=$(wc -l < "$REPODIR/.codex/build-done.txt" 2>/dev/null || echo 0)
    local queue_count=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
    if [ "$done_count" -lt "$queue_count" ]; then
      echo "Found unfinished build: $done_count/$queue_count files completed."
      echo "Remaining queue:"
      grep -vFf "$REPODIR/.codex/build-done.txt" "$REPODIR/.codex/build-queue.txt" 2>/dev/null || true
      echo -n "Continue? (y/n): "
      read -r confirm
      [ "$confirm" != "y" ] && { echo "Aborted."; exit 0; }
      run_build_loop
      return
    fi
  fi

  # Resume existing completed queue
  if [ -f "$REPODIR/.codex/build-queue.txt" ] && [ -s "$REPODIR/.codex/build-queue.txt" ]; then
    echo "Resuming existing DIRECT build queue..."
    cat "$REPODIR/.codex/build-queue.txt"
    echo -n "Continue? (y/n): "
    read -r confirm
    [ "$confirm" != "y" ] && { echo "Aborted."; exit 0; }
    run_build_loop
    return
  fi

  # DIRECT mode: use exact filenames from request, no recon
  echo "Creating new DIRECT build plan..."
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"
  echo "$REQUEST" | grep -oE '[a-zA-Z0-9_/.-]+\.(py|js|ts|tsx|jsx|html|css|sh|json|yml|yaml|md|txt|toml|sql|ipynb)' | sort -u | while read -r f; do
    [ -z "$f" ] && continue
    if [ -f "$REPODIR/$f" ]; then
      echo "PATCH:$f - $REQUEST" >> "$REPODIR/.codex/build-queue.txt"
    else
      echo "NEW:$f" >> "$REPODIR/.codex/build-queue.txt"
    fi
  done

  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)

  if [ "$entries" -eq 0 ] && [ -d "$REPODIR" ] && [ "$(find "$REPODIR" -name '*.py' | wc -l)" -gt 0 ]; then
    echo "All specified files already exist. Use PATCH to modify existing files."
    echo "Or use: listen.sh 'Continue' $REPODIR to resume from queue."
    exit 0
  fi
  if [ "$entries" -eq 0 ]; then
    echo "All files exist. Nothing to build."
    exit 0
  fi

  # Generate phases.json for phase gate compatibility
  python3 -c "
import json
files = []
with open('$REPODIR/.codex/build-queue.txt') as f:
    for line in f:
        line = line.strip()
        if line.startswith('NEW:') or line.startswith('PATCH:'):
            fname = line.replace('NEW:','').replace('PATCH:','').split(' - ')[0].strip()
            files.append(fname)
phases = {'phases': [{'id': 'phase-1', 'name': 'Direct Build', 'files': files}], 'current_phase': 0}
with open('$REPODIR/.codex/phases.json', 'w') as f:
    json.dump(phases, f, indent=2)
print(f'[DIRECT] Created phases.json with {len(files)} files')
" 2>/dev/null || true

  echo "Plan: $entries files"
  cat "$REPODIR/.codex/build-queue.txt"
  echo -n "Approve? (y/n): "
  read -r confirm
  [ "$confirm" != "y" ] && { echo "Aborted."; exit 0; }
  run_build_loop
}
mode_deploy() {
  echo "Preparing project for deployment..."
  cd "$REPODIR"

  [ ! -f .gitignore ] && cat > .gitignore << 'GITIGNORE'
node_modules/
.next/
.env.local
*.log
.cache/
dist/
build/
core
GITIGNORE

  git rm -r --cached node_modules .next .cache core 2>/dev/null || true
  rm -f core 2>/dev/null
  [ -d .git ] || git init
  git add -A
  git commit -m "Deploy ready $(date +%Y-%m-%d_%H:%M)" 2>/dev/null || true

  echo ""
  echo "=== DEPLOYING TO PRODUCTION ==="
  echo "Project: $REPODIR"

  if [ -f "${SKILLDIR}/modules/vercel-deploy.sh" ]; then
    bash "${SKILLDIR}/modules/vercel-deploy.sh" "$REPODIR"
  else
    echo "Plugin not found. Run: cd $REPODIR && vercel deploy --prod"
  fi
}

# =============================================================================
# MODE: REVIEW
# =============================================================================
mode_review() {
  echo "Scanning all files..."
  mkdir -p "$REPODIR/reviews" "$REPODIR/.codex"
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"

  local files=$(find "$REPODIR" -maxdepth 10 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.json" -o -name "*.md" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/reviews/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null)
  local total=$(echo "$files" | wc -l)
  local done=0
  echo "Files to review: $total"

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    done=$((done + 1))
    local rel="${file#$REPODIR/}"
    local review_file="reviews/$(printf "%03d" $done)-$(echo "${rel%.*}" | tr '/' '-').md"
    echo "[$done/$total] $rel"
    [ -f "$REPODIR/$review_file" ] && { echo "  Already reviewed."; continue; }
    local content=$(cat "$file" 2>/dev/null)
    [ -z "$content" ] && { echo "  Empty."; continue; }
    local review=$(hermes chat -q "Review this file. Output findings as: Finding | Risk: level | Fix: action\nFile: $rel\n\n$content" --yolo --quiet 2>/dev/null || echo "")
    [ -n "$review" ] && { echo "$review" > "$REPODIR/$review_file"; echo "  Saved."; }
  done <<< "$files"

  echo ""
  local crit=$(grep -rli "Critical" "$REPODIR/reviews/" 2>/dev/null | wc -l)
  echo "REVIEW COMPLETE: $crit Critical findings"
  echo "Reviews: $REPODIR/reviews/"

  # Bridge: convert reviews to build queue
  if [ -f "${SKILLDIR}/modules/review-to-queue.sh" ]; then
    bash "${SKILLDIR}/modules/review-to-queue.sh" "$REPODIR/reviews"
  fi
}

# =============================================================================
# MODE: CONTINUATION
# =============================================================================
mode_continuation() {
  echo "Resuming from queue..."
  run_build_loop
}

# =============================================================================
# MODE: CHECK
# =============================================================================
mode_check() {
  echo "Running diagnostics on $REPODIR..."
  if [ -f "${SKILLDIR}/modules/import-check.sh" ]; then
    find "$REPODIR" -type f \( -name "*.py" -o -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.sh" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | while read -r f; do
      bash "${SKILLDIR}/modules/import-check.sh" "$f" "$REPODIR" 2>/dev/null
    done
  fi
  # Also run Python syntax check
  find "$REPODIR" -type f -name "*.py" -not -path "*/.git/*" 2>/dev/null | while read -r f; do
    python3 -m py_compile "$f" 2>/dev/null && echo "OK: $f" || echo "FAIL: $f"
  done
  echo "Check complete."
}

# =============================================================================
# BUILD LOOP
# =============================================================================
run_build_loop() {
  # Queue README before build starts
  if [ ! -f "$REPODIR/README.md" ]; then
    echo "NEW:README.md" >> "$REPODIR/.codex/build-queue.txt"
  fi
  set +e
  CODEX_REPO="$REPODIR" MODE="$MODE" bash "$SKILLDIR/runcycle.sh" 2>&1 | tee "$REPODIR/.codex/build.log"
  local build_exit=$?
  set -e

  echo ""
    # Auto-generate README if missing
  bash "${SKILLDIR}/sandbox/swarm.sh" --readme "$REPODIR" 2>/dev/null || true
  echo "Done. Location: $REPODIR"

  # Push on successful build (exit 0) or clean DONE (empty queue = no error)
  if [ $build_exit -eq 0 ] && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      echo "Pushing to GitHub..."
      bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
    else
      echo "GITHUB_TOKEN not set. Skipping push."
    fi
  elif grep -q "DONE" "$REPODIR/.codex/build.log" 2>/dev/null && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    # Build completed successfully (DONE) even if exit code was non-zero
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      echo "Build complete. Pushing to GitHub..."
      bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
    else
      echo "GITHUB_TOKEN not set. Set it in ~/.hermes/.env to enable auto-push."
    fi
  elif [ $build_exit -ne 0 ]; then
    echo "Build failed. Skipping push to GitHub."
  fi

  echo "Full log: $REPODIR/.codex/build.log"
  return $build_exit
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  # Defaults
  AUTO_YES=false
  DRY_RUN=false

  # Parse options
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes|-y) AUTO_YES=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      *) break ;;
    esac
  done

  # Now, the remaining arguments are: $1 = REQUEST, $2 = REPODIR (optional)
  if [ -z "$1" ]; then
    echo "Usage: listen.sh 'request' [directory] [--yes] [--dry-run]"
    exit 1
  fi

  REQUEST="$1"
  REPODIR="${2:-$HOME/projects}"
  export AUTO_YES
  export DRY_RUN

  understand "$REQUEST" "$REPODIR"

  # Check if request matches a known project capability
  if [ -f "$REPODIR/.codex/capabilities.json" ]; then
    bash "${SKILLDIR}/modules/capability-runner.sh" "$REPODIR" "$REQUEST" && exit 0
  fi

  case "$MODE" in
    DIRECT) mode_direct ;;
    NEW) mode_new ;;
    GENERATE) mode_new ;;
    EXISTING) mode_existing ;;
    DEPLOY) mode_deploy ;;
    REVIEW) mode_review ;;
    CONTINUATION) mode_continuation ;;
    CHECK) mode_check ;;
    *) mode_existing ;;
  esac
}
main "$@"
