#!/usr/bin/env bash
set -euo pipefail
set -euo pipefail
# Reset State Option
if [ "${RESET_STATE:-false}" = "true" ] && [ -n "${REPODIR:-}" ]; then
  > "$REPODIR/.codex/build-queue.txt" 
  > "$REPODIR/.codex/build-done.txt" 
  echo '{"cycle":0}' > "$REPODIR/.codex/state.json"
fi

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
    # Security: Resolve path without eval
case "$local_path" in
  ~/*) REPODIR="${local_path/#\~/$HOME}" ;;
  /*)  REPODIR="$local_path" ;;
  *)   REPODIR="$HOME/$local_path" ;;
esac
REPODIR="$(realpath "$REPODIR")"
[[ "$REPODIR" != "$HOME/"* ]] && { echo "Unsafe path: $REPODIR" >&2; exit 1; }
    [ -d "$REPODIR" ] && { echo "Local project: $REPODIR"; } || REPODIR=""
  fi
  
  # Check for GitHub URL FIRST — overrides everything
  local repo_url=$(echo "$request" | grep -oE "https?://github.com/[^ ]+" | head -1)
  if [ -n "$repo_url" ]; then
    local repo_name=$(basename "$repo_url" .git)
    REPODIR="$HOME/$repo_name"
    if [ ! -d "$REPODIR" ]; then
      echo "Cloning $repo_url ..."
      # Try token-based auth first, fall back to regular clone
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      git clone "https://${GITHUB_TOKEN}@${repo_url#https://}" "$REPODIR" 2>/dev/null && echo "Cloned." || { echo "Clone failed. Check token or repo."; exit 1; }
    elif [ -n "${COPILOT_GITHUB_TOKEN:-}" ]; then
      git clone "https://${COPILOT_GITHUB_TOKEN}@${repo_url#https://}" "$REPODIR" 2>/dev/null && echo "Cloned." || { echo "Clone failed."; exit 1; }
    else
      git clone "$repo_url" "$REPODIR" 2>/dev/null && echo "Cloned." || { echo "Clone failed. Set GITHUB_TOKEN for private repos."; exit 1; }
    fi
    else
      echo "Using existing repo: $REPODIR"
    fi
  fi
  # Fallback if no URL detected
  [ -z "$REPODIR" ] && REPODIR="${project_dir:-$HOME/codex-builds}"
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
    local last_action=$(grep -o '"last_action": "[^"]*"' "$REPODIR/.codex/state.json" 2>/dev/null | cut -d'"' -f4)
    if [[ "$last_action" == *"FAIL"* ]] || { [ -f "$REPODIR/.codex/build-queue.txt" ] && [ ! -s "$REPODIR/.codex/build-queue.txt" ] && [ -s "$REPODIR/.codex/build-done.txt" ]; }; then
      echo "Auto-healing zombie state..."
      echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$REPODIR/.codex/state.json"
      > "$REPODIR/.codex/build-queue.txt"
      > "$REPODIR/.codex/build-done.txt"
    fi
  fi
  
  local code_files=$(find "$REPODIR" -maxdepth 4 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.html" -o -name "*.css" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  if echo "$request" | grep -qiE "(reviews/|security review|bug review|code review|audit|scan for|analyze this|find bugs)"; then
    MODE="REVIEW"
  elif [ "$code_files" -lt 1 ]; then
    MODE="NEW"
  elif [ "$code_files" -eq 0 ]; then
    echo "Fallback task: Generating a README.md as no significant code was found."
    echo "PATCH: README.md - Add project description." > "$REPODIR/.codex/build-queue.txt"
    return
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
  
  local files=$(find "$REPODIR" -maxdepth 10 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.json" -o -name "*.md" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" -o -name "*.toml" -o -name "*.cfg" -o -name "*.ini" \) -not -path "*/.git/*" -not -path "*/.codex/*" -not -path "*/reviews/*" -not -path "*/__pycache__/*" -not -path "*/node_modules/*" 2>/dev/null | grep "^$REPODIR")
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
    [ -n "$review" ] && {
    # Strip diff syntax and code blocks from review output
    local clean_review=$(echo "$review" | grep -vE '^(@@|---|\+\+\+|diff --git|index |new file mode|deleted file mode|^[-+]{3})' | grep -vE '^```')
    echo "$clean_review" > "$REPODIR/$review_file"
    echo "  Saved."
  }
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
  # Show findings and action menu
  echo ""
  echo "=============================================="
  echo "  REVIEW COMPLETE"
  echo "=============================================="
  echo "  Critical: $crit | High: $high | Medium: $med"
  echo "=============================================="
  echo ""
  echo "Review saved to $REPODIR/reviews/"
  echo "To fix issues, use: listen.sh 'Fix [issue]' $REPODIR"
}


# =============================================================================
mode_existing() {
  echo "Analyzing existing project..."
  
  # Check if we have existing reviews to guide fixes
  if [ -d "$REPODIR/reviews" ] && [ -n "$(ls -A "$REPODIR/reviews/" 2>/dev/null)" ]; then
    echo "Found existing reviews. Using them to guide fixes..."
    # Build queue from review findings
    > "$REPODIR/.codex/build-queue.txt"
    local review_count=0
    for rv in "$REPODIR/reviews/"*.md; do
      [ "$rv" = "$REPODIR/reviews/SUMMARY.md" ] && continue
      [ ! -f "$rv" ] && continue
      
      # Get original filename
      local base=$(basename "$rv" .md | sed 's/^[0-9]*-//')
      local orig=""
      for ext in py js ts sh json md; do
        [ -f "$REPODIR/$base.$ext" ] && { orig="$base.$ext"; break; }
      done
      [ -z "$orig" ] && continue
      
      # Extract findings from review
      local in_finding_block=false
      local current_finding=""
      local current_risk=""
      local current_fix=""
      
      while IFS= read -r line; do
        if [[ "$line" =~ ^Finding:[[:space:]]*(.*)$ ]]; then
          # Save previous finding if complete
          if [ -n "$current_finding" ] && [ -n "$current_risk" ] && [ -n "$current_fix" ]; then
            echo "PATCH: $orig - $current_finding" >> "$REPODIR/.codex/build-queue.txt"
            review_count=$((review_count + 1))
          fi
          # Start new finding
          current_finding="${BASH_REMATCH[1]}"
          current_risk=""
          current_fix=""
          in_finding_block=true
        elif [[ "$line" =~ ^Risk:[[:space:]]*(.*)$ ]] && [ "$in_finding_block" = true ]; then
          current_risk="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Fix:[[:space:]]*(.*)$ ]] && [ "$in_finding_block" = true ]; then
          current_fix="${BASH_REMATCH[1]}"
        elif [[ -z "$line" ]] && [ "$in_finding_block" = true ]; then
          # End of finding block (empty line)
          if [ -n "$current_finding" ] && [ -n "$current_risk" ] && [ -n "$current_fix" ]; then
            echo "PATCH: $orig - $current_finding" >> "$REPODIR/.codex/build-queue.txt"
            review_count=$((review_count + 1))
          fi
          current_finding=""
          current_risk=""
          current_fix=""
          in_finding_block=false
        fi
      done < "$rv"
      
      # Handle last finding if file doesn't end with empty line
      if [ -n "$current_finding" ] && [ -n "$current_risk" ] && [ -n "$current_fix" ]; then
        echo "PATCH: $orig - $current_finding" >> "$REPODIR/.codex/build-queue.txt"
        review_count=$((review_count + 1))
      fi
    done
    
    if [ "$review_count" -gt 0 ]; then
      echo "Generated $review_count fix entries from reviews."
      run_build_loop
      return
    else
      echo "No actionable findings in reviews, falling back to standard analysis..."
    fi
  fi
  
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
Output ONLY ONE queue entry.
Format: PATCH: path/to/file.py - change details.
OR: SED: path/to/file.py - 'old_string' 'new_string'.
If no action needed, output: SED: skip - no changes.
Do not include any other text."
  local plan=$(hermes chat -q "$analysis_prompt" --yolo --quiet 2>/dev/null || echo "")
  # Keep only valid queue entries (NEW:, PATCH:, SED:)
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
  
  # Generate build queue from build goal
  local queue_prompt="GOAL:\n$goal\n\nPersona: $PERSONA. List files to build in order. One per line. Output ONLY file paths. 
  Each path can be a new file OR an existing file followed by - edit details if existing."
  [ "$PERSONA" = "PRODUCT" ] && queue_prompt+=". Ensure README.md is the last file in the queue."
  local queue=$(hermes chat -q "$queue_prompt" --yolo --quiet 2>/dev/null || echo "")
  [ -n "$queue" ] && echo "$queue" | grep -E '^[a-zA-Z0-9_/.+-]+' > "$REPODIR/.codex/build-queue.txt" || true
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
