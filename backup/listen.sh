#!/usr/bin/env bash
set -euo pipefail
# CODES-DEVELOPER v11.0 — Review → Findings → Action → Fix → Verify

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR=""
REQUEST=""
MODE=""

understand() {
  local request="$1" project_dir="$2"
  echo ""
  echo "=============================================="
  echo "  CODES-DEVELOPER v11.0"
  echo "=============================================="
  echo "Request: $request"
  echo ""
  
  # Detect local path in request (e.g., "Review ~/my-project for bugs")
  local local_path=$(echo "$request" | grep -oE "(~/\S+|/data/\S+)" | head -1)
  if [ -n "$local_path" ]; then
    REPODIR=$(eval echo "$local_path" 2>/dev/null || echo "$local_path")
    [ -d "$REPODIR" ] && { echo "Local project: $REPODIR"; } || REPODIR=""
  fi
  
  # If no local path found, check for GitHub URL
  local repo_url=$(echo "$request" | grep -oE "https?://github.com/[^ ]+" | head -1)
  if [ -z "$REPODIR" ] && [ -n "$repo_url" ]; then
    local repo_name=$(basename "$repo_url" .git)
    REPODIR="$HOME/$repo_name"
    if [ ! -d "$REPODIR" ]; then
      echo "Cloning $repo_url ..."
      git clone "$repo_url" "$REPODIR" 2>/dev/null && echo "Cloned." || { echo "Clone failed."; exit 1; }
    fi
  else
    [ -z "$REPODIR" ] && REPODIR="${project_dir:-$HOME/codex-builds}"
  fi
  # Infer Persona
  PERSONA="LEARNER" 
  if echo "$request" | grep -qiE "build|create|I want|need"; then
    PERSONA="PRODUCT"
  elif echo "$request" | grep -qiE "architecture|logic|refactor|modify|debug|fix"; then
    PERSONA="EXPERT"
  fi
  echo "Persona detected: $PERSONA"
  export PERSONA
  
  # Check for zombie state from previous failed runs
  if [ -f "$REPODIR/.codex/state.json" ]; then
    local last_action=$(python3 -c "import json; print(json.load(open('$REPODIR/.codex/state.json')).get('last_action',''))" 2>/dev/null)
    if [[ "$last_action" == *"FAIL"* ]] || [ -f "$REPODIR/.codex/build-queue.txt" ] && [ ! -s "$REPODIR/.codex/build-queue.txt" ]; then
      echo "Auto-healing zombie state..."
      echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$REPODIR/.codex/state.json"
      > "$REPODIR/.codex/build-queue.txt"
      > "$REPODIR/.codex/build-done.txt"
    fi
  fi
  
  local code_files=$(find "$REPODIR" -maxdepth 4 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.html" -o -name "*.css" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l)

  if echo "$request" | grep -qi "review\|audit\|scan\|analyze\|find bug\|check code\|code review"; then
    MODE="REVIEW"
  elif [ "$code_files" -lt 1 ]; then
    MODE="NEW"
  elif [ -f "$REPODIR/.codex/build-queue.txt" ] && [ -s "$REPODIR/.codex/build-queue.txt" ]; then
    local remaining=$(comm -23 "$REPODIR/.codex/build-queue.txt" "$REPODIR/.codex/build-done.txt" 2>/dev/null | wc -l)
    [ "$remaining" -gt 0 ] && MODE="CONTINUATION" || MODE="EXISTING"
  else
    MODE="EXISTING"
  fi
  echo "Mode: $MODE"
  echo ""
}

# =============================================================================
# REVIEW MODE — Per-file analysis → Findings → Action
# =============================================================================
mode_review() {
  echo "Scanning all files..."
  mkdir -p "$REPODIR/reviews" "$REPODIR/.codex"
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"
  
  local files=$(find "$REPODIR" -maxdepth 10 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/reviews/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null | grep "^$REPODIR")
  local total=$(echo "$files" | wc -l) done=0
  
  echo "Files to review: $total"
  echo ""
  
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    done=$((done + 1))
    local rel="${file#$REPODIR/}"
    local review_index=$(printf "%03d" $done)
    local review_name=$(echo "${rel%.*}" | tr '/' '-')
    local review_file="reviews/${review_index}-${review_name}.md"
    
    echo "[$done/$total] $rel"
    [ -f "$REPODIR/$review_file" ] && { echo "  Already reviewed."; continue; }
    
    local content=$(cat "$file" 2>/dev/null)
    [ -z "$content" ] && { echo "  Empty."; continue; }
    
    local prompt="Review this file for bugs, security, and improvements.
File: $rel

$content

Output markdown: Finding | Risk: Critical/High/Medium/Low | Fix"
    
    local review=$(hermes chat -q "$prompt" --yolo --quiet 2>/dev/null || echo "")
    [ -n "$review" ] && { echo "$review" > "$REPODIR/$review_file"; echo "  Saved."; }
  done <<< "$files"
  
  # Summary
  echo ""
  echo "Generating summary..."
  local all_reviews=$(find "$REPODIR/reviews" -name "*.md" -exec cat {} \; 2>/dev/null)
  local summary=$(hermes chat -q "Summarize these reviews. Group by severity. Top 10 fixes.

$all_reviews" --yolo --quiet 2>/dev/null || echo "")
  [ -n "$summary" ] && echo "$summary" > "$REPODIR/reviews/SUMMARY.md"
  
  # Show findings and action menu
  local crit=$(grep -rli "| Critical" "$REPODIR/reviews/" 2>/dev/null | wc -l)
  local high=$(grep -rli "| High" "$REPODIR/reviews/" 2>/dev/null | wc -l)
  local med=$(grep -rli "| Medium" "$REPODIR/reviews/" 2>/dev/null | wc -l)
  
  echo ""
  echo "=============================================="
  echo "  REVIEW COMPLETE"
  echo "=============================================="
  echo "  Critical: $crit | High: $high | Medium: $med"
  echo "=============================================="
  echo ""
  echo "TOP FINDINGS:"
  for sev in "Critical" "High"; do
    local cnt=$(grep -rli "Risk: $sev" "$REPODIR/reviews/" 2>/dev/null | wc -l)
    [ "$cnt" -eq 0 ] && continue
    echo "  [$sev]"
    grep -rl "Risk: $sev" "$REPODIR/reviews/" 2>/dev/null | head -8 | while read -r rv; do
      local nm=$(basename "$rv" .md | sed 's/^[0-9]*-//')
      local fnd=$(tail -n +3 "$rv" | head -n 1 | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      echo "    $nm — $fnd"
    done
    echo ""
  done
  
  echo "What should I fix?"
  echo "  [1] Fix ALL critical"
  echo "  [2] Fix critical + high"
  echo "  [3] Fix everything"
  echo "  [4] Pick specific files"
  echo "  [5] Just the report"
  echo ""
  echo -n "Choice [1-5]: "
  read -r choice
  
  case "$choice" in
    1) fix_from_reviews "Critical" ;;
    2) fix_from_reviews "Critical\|High" ;;
    3) fix_from_reviews "Critical\|High\|Medium" ;;
    4) echo "Reviews in: $REPODIR/reviews/"; echo "Run: listen.sh 'Fix X in file' $REPODIR" ;;
    5) 
       echo "Report details:"
       echo "  Summary: $REPODIR/reviews/SUMMARY.md"
       echo "  Review files:"
       ls -1 "$REPODIR/reviews/" | grep ".md" | sed 's/^/    /'
       echo ""
       echo "To read a report, use 'cat' or your editor:"
       echo "  cat $REPODIR/reviews/FILENAME.md"
       ;;
    *) echo "Invalid choice. Please select 1-5." ;;
  esac
}

# =============================================================================
# FIX FROM REVIEWS
# =============================================================================
fix_from_reviews() {
  local severity="$1"
  echo ""
  echo "Building fix queue for $severity..."
  
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"
  
  local fix_prompt="Extract all findings with Risk: $severity. Create PATCH queue entries for Python files, SED for others.
Format: PATCH: path/to/file.ext - fix description
Format: SED: path/to/file.ext - fix description
Use original file paths from the reviews.

$(find "$REPODIR/reviews" -name "*.md" -exec cat {} \; 2>/dev/null)"
  
  local queue=$(hermes chat -q "$fix_prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -n "$queue" ] && echo "$queue" | grep -E '^(PATCH|SED):' > "$REPODIR/.codex/build-queue.txt" || true
  
  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
  echo "Fix queue: $entries changes"
  [ "$entries" -eq 0 ] && { echo "Nothing to fix."; return; }
  
  echo -n "Proceed with $entries fixes? (y/N): "
  read -r confirm
  [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { echo "Cancelled."; return; }
  
  run_build_loop
  
  # Re-review
  echo ""
  echo "Re-reviewing..."
  while IFS= read -r line; do
    local type=$(echo "$line" | cut -d':' -f1)
    local f=$(echo "$line" | sed -E 's/^(PATCH|SED): ([^ ]+) - .*/\2/')
    [ -z "$f" ] || [ ! -f "$REPODIR/$f" ] && continue
    local idx=$(printf "%03d" $(( $(ls "$REPODIR/reviews/" 2>/dev/null | wc -l) + 1 )))
    local nm="${idx}-$(echo "${f%.*}" | tr '/' '-')"
    local ct=$(cat "$REPODIR/$f" 2>/dev/null)
    local rr=$(hermes chat -q "Re-review after fix. Resolved? Remaining issues? File: $f
    
$ct" --yolo --quiet 2>/dev/null || echo "")
    [ -n "$rr" ] && echo "$rr" > "$REPODIR/reviews/${nm}-POST-FIX.md"
    echo "  Re-reviewed: $f"
  done < "$REPODIR/.codex/build-queue.txt"
  echo "Post-fix reviews saved."
}

# =============================================================================
# EXISTING MODE
# =============================================================================
mode_existing() {
  echo "Analyzing existing project..."
  mkdir -p "$REPODIR/.codex"
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"
  
  local file_list=$(find "$REPODIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.html" \) -not -path "*/.git/*" -not -path "*/__pycache__/*" 2>/dev/null | head -30 | tr '\n' ' ')
  local persona_instruction=""
  case "$PERSONA" in
    "PRODUCT") persona_instruction="You are a product builder. Provide brief, results-oriented updates. Hide complex technical logs." ;;
    "EXPERT") persona_instruction="You are a software architect. Focus on logic, dependency chains, and architectural integrity. Provide deep technical reasoning." ;;
    *) persona_instruction="You are a helpful assistant. Explain your steps clearly for a learner." ;;
  esac
  
  local analysis_prompt="Project files: $file_list. 
Your task: $REQUEST. 
Identify the target file from the list above. 
CRITICAL: Output ONLY ONE single queue entry.
CRITICAL: Use the exact path found in the project list.
Format: SED: path/to/file.py - change details.
Do not include any other text."
  local plan=$(hermes chat -q "$analysis_prompt" --yolo --quiet 2>/dev/null || echo "")
  # Strip absolute paths but preserve the mode prefix (NEW:, PATCH:, SED:)
  plan=$(echo "$plan" | sed -E "s|($REPODIR/)| |g" | sed -E 's/([A-Z]+:)[[:space:]]+ /\1 /')
  [ -n "$plan" ] && echo "$plan" | grep -E '^(NEW:|PATCH:|SED:)' > "$REPODIR/.codex/build-queue.txt" || true
  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
  echo "Plan: $entries changes"
  [ "$entries" -gt 0 ] && cat "$REPODIR/.codex/build-queue.txt"
  [ ! -s "$REPODIR/.codex/build-queue.txt" ] && { echo "Nothing to build."; return; }
  run_build_loop
}

# =============================================================================
# NEW MODE
# =============================================================================
mode_new() {
  echo "Building from scratch..."
  mkdir -p "$REPODIR/.codex"
  echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$REPODIR/.codex/state.json"
  > "$REPODIR/.codex/build-queue.txt"
  > "$REPODIR/.codex/build-done.txt"
  
  # Generate goal in the project directory
  local spec_prompt="Convert this request into a detailed technical specification for codex-developer: $REQUEST"
  [ "$PERSONA" = "PRODUCT" ] && spec_prompt+=". Important: Include a README.md in the project to explain how to use the app."
  
  local goal=$(hermes chat -q "$spec_prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -z "$goal" ] && { echo "Failed."; exit 1; }
  local goal_file="$REPODIR/.codex/goal.md"
  mkdir -p "$(dirname "$goal_file")"
  echo "$goal" > "$goal_file"

  # Manual Approval Step
  echo "--- PLAN PREVIEW ---"
  cat "$REPODIR/.codex/goal.md"
  echo "--------------------"
  echo -n "Approve this plan? (y/n): "
  read -r confirm
  if [ "$confirm" != "y" ]; then
    echo "Aborted."
    rm "$REPODIR/.codex/goal.md"
    exit 0
  fi
  
  # Generate build queue from goal
  local queue_prompt="GOAL:\n$goal\n\nPersona: $PERSONA. List files to build in order. One per line. Output ONLY file paths."
  [ "$PERSONA" = "PRODUCT" ] && queue_prompt+=". Ensure README.md is the last file in the queue."
  local queue=$(hermes chat -q "$queue_prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -n "$queue" ] && echo "$queue" | grep -E '^[a-zA-Z0-9_/.+-]+$' > "$REPODIR/.codex/build-queue.txt" || true
  local entries=$(wc -l < "$REPODIR/.codex/build-queue.txt" 2>/dev/null || echo 0)
  echo "Plan: $entries files"
  [ "$entries" -gt 0 ] && cat "$REPODIR/.codex/build-queue.txt"
  
  run_build_loop
}

# =============================================================================
# CONTINUATION
# =============================================================================
mode_continuation() {
  local remaining=$(comm -23 "$REPODIR/.codex/build-queue.txt" "$REPODIR/.codex/build-done.txt" 2>/dev/null | wc -l)
  echo "Resuming — $remaining tasks."
  run_build_loop
}

# =============================================================================
# BUILD LOOP
# =============================================================================
run_build_loop() {
  local max=30
  local first_run=true
  while [ $max -gt 0 ]; do
    max=$((max - 1))
    # On first run, we allow empty queue because runcycle.sh will generate it
    if [ "$first_run" = false ]; then
      [ ! -s "$REPODIR/.codex/build-queue.txt" ] && break
      local remaining=$(comm -23 "$REPODIR/.codex/build-queue.txt" "$REPODIR/.codex/build-done.txt" 2>/dev/null | wc -l)
      [ "$remaining" -eq 0 ] && break
    fi
    first_run=false
    CODEX_REPO="$REPODIR" bash "$SKILLDIR/runcycle.sh" 2>&1 | grep -E "BUILT|DONE|FAIL|CYCLE|PLANNED" || true
    sleep 1
  done
  echo ""
  echo "Done. Location: $REPODIR"
  [ -f "$REPODIR/backend/server.py" ] && echo "Run: cd $REPODIR/backend && python3 server.py"
  [ -f "$REPODIR/index.html" ] && echo "Open: $REPODIR/index.html"
  [ -d "$REPODIR/reviews" ] && echo "Reviews: $REPODIR/reviews/"
}

main() {
  REQUEST="$1"
  REPODIR="${2:-$HOME/codex-builds}"
  [ -z "$REQUEST" ] && { echo "Usage: listen.sh 'request' [dir]"; exit 1; }
  understand "$REQUEST" "$REPODIR"
  case "$MODE" in
    NEW) mode_new ;;
    REVIEW) mode_review ;;
    EXISTING) mode_existing ;;
    CONTINUATION) mode_continuation ;;
    *) echo "Unknown mode."; exit 1 ;;
  esac
}

main "$@"
