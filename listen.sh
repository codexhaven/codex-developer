#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# CODES-DEVELOPER v12.2 — Stress-tested — Natural Language Software Factory
# Modes: NEW | EXISTING | REVIEW | CONTINUATION | CHECK | DEPLOY
# Flow: listen → recon (research + phases) → approve → runcycle (phase by phase)
# =============================================================================

[ -f "$HOME/.hermes/.env" ] && set -a && source "$HOME/.hermes/.env" && set +a 2>/dev/null || true
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR=""
REQUEST=""
MODE=""

# =============================================================================
# UNDERSTAND — detect mode, set REPODIR
# =============================================================================
understand() {
  local request="$1" project_dir="$2"
  echo -e "\033[1;36m==============================================\033[0m"
  echo -e "\033[1;32m  CODES-DEVELOPER v12.2 — Stress-tested\033[0m"
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

  if echo "$request" | grep -qiE "deploy|ship|publish|go live|launch|push to production"; then
    MODE="DEPLOY"
  elif echo "$request" | grep -qiE "^generate|^create.*tool|^make.*tool|build.*cli tool|^Generate"; then
    MODE="GENERATE"
  elif echo "$request" | grep -qiE "^(check|scan|audit|diagnose|inspect|verify)( |$)"; then
    MODE="CHECK"
  elif echo "$request" | grep -qiE "(^review|security review|bug review|code review|audit|scan for|analyze this)"; then
    MODE="REVIEW"
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
    echo -n "Approve this phase plan? (y/n): "
    read -r confirm
    if [ "$confirm" != "y" ]; then
      echo "Aborted. Edit phases.json and retry, or re-run with a different request."
      exit 0
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
        f = f.lstrip('/')
        print(f'NEW:{f}')
        count += 1
" > "$REPODIR/.codex/build-queue.txt" 2>/dev/null || true
  fi

  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
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
# MODE: DEPLOY
# =============================================================================
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
  local total=$(echo "$files" | wc -l) done=0
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
    find "$REPODIR" -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.js" \) -not -path "*/node_modules/*" 2>/dev/null | while read -r f; do
      bash "${SKILLDIR}/modules/import-check.sh" "$f" "$REPODIR" 2>/dev/null
    done
  fi
  echo "Check complete."
}

# =============================================================================
# BUILD LOOP
# =============================================================================
run_build_loop() {
  CODEX_REPO="$REPODIR" MODE="$MODE" bash "$SKILLDIR/runcycle.sh" 2>&1 | tee "$REPODIR/.codex/build.log"
  echo ""
  echo "Done. Location: $REPODIR"
  if [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR" 2>/dev/null || true
  fi
  echo "Full log: $REPODIR/.codex/build.log"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  REQUEST="$1"
  REPODIR="${2:-$HOME/projects}"
  [ -z "$REQUEST" ] && { echo "Usage: listen.sh 'request' [directory]"; exit 1; }
  understand "$REQUEST" "$REPODIR"

  case "$MODE" in
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
