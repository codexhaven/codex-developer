#!/usr/bin/env bash
# =============================================================================
# IMMUTABLE KERNEL — Guardian of the Codex System
# Runs before every cycle. Verifies integrity. Enables recovery.
# Proposals CANNOT modify this file.
# =============================================================================

set -euo pipefail
SCRIPT_PATH="$(readlink -f "$0")"
SKILLDIR="${SKILLDIR:-$(dirname "$SCRIPT_PATH")}" 
VERSION="10.0.0"

# =============================================================================
# 1. INTEGRITY CHECK — Runs before every cycle
# =============================================================================
check() {
  local errors=0
  
  # Check core files exist
  for f in runcycle.sh listen.sh goal.md global-knowledge.jsonl; do
    if [ ! -f "$SKILLDIR/$f" ]; then
      echo "MISSING: $f"
      errors=$((errors + 1))
    fi
  done
  
  # Check modules
  for f in modules/sed-patcher.sh modules/template-detect.sh modules/pattern-match.sh; do
    if [ ! -f "$SKILLDIR/$f" ]; then
      echo "MISSING MODULE: $f"
      errors=$((errors + 1))
    fi
  done
  
  # Check kernel itself hasn't been modified
  local kernel_hash
  kernel_hash=$(sha256sum "$SCRIPT_PATH" 2>/dev/null | cut -d' ' -f1 || true)
  local stored_hash
  stored_hash=$(cat "$SKILLDIR/.kernel-hash" 2>/dev/null || echo "")
  if [ -n "$stored_hash" ] && [ "$kernel_hash" != "$stored_hash" ]; then
    echo "WARNING: kernel.sh has been modified! Hash mismatch."
    echo "  Current: $kernel_hash"
    echo "  Stored:  $stored_hash"
    echo "  Run: kernel.sh lock  to accept changes, or restore from backup."
  fi
  
  if [ $errors -eq 0 ]; then
    echo "KERNEL: OK (v$VERSION)"
    return 0
  else
    echo "KERNEL: $errors errors"
    return 1
  fi
}

# =============================================================================
# 2. LOCK — Accept current kernel state as trusted
# =============================================================================
lock() {
  local hash
  hash=$(sha256sum "$SCRIPT_PATH" | cut -d' ' -f1)
  local tmp_hash
  tmp_hash=$(mktemp)
  echo "$hash" > "$tmp_hash"
  mv "$tmp_hash" "$SKILLDIR/.kernel-hash"
  echo "Kernel locked. Hash: $hash"
}

# =============================================================================
# 3. RECOVER — Rebuild minimal working orchestrator
# =============================================================================
recover() {
  echo "RECOVERING orchestrator from kernel..."
  
  # Backup current (use mktemp to avoid collisions)
  if [ -f "$SKILLDIR/runcycle.sh" ]; then
    bak=$(mktemp "$SKILLDIR/runcycle.sh.broken.XXXXXX") || bak="$SKILLDIR/runcycle.sh.broken.$(date +%s)"
    cp -- "$SKILLDIR/runcycle.sh" "$bak"
  fi
  
  # Write minimal working orchestrator
  cat > "$SKILLDIR/runcycle.sh" << 'MINIMAL'
#!/usr/bin/env bash
set -euo pipefail
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${CODEX_REPO:-${HOME}/codex-builds}"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
DONEFILE="${REPODIR}/.codex/build-done.txt"
GOALFILE="${REPODIR}/.codex/goal.md"

log() { echo "[$(date +%T)]" "$@"; }

# Minimal build — one file per cycle
main() {
  mkdir -p "$REPODIR/.codex"
  touch "$QUEUEFILE" "$DONEFILE"
  
  # Get next file from queue
  local current=""
  local done
  done=$(cat "$DONEFILE" 2>/dev/null || true)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! echo "$done" | grep -qF "$line"; then
      current="$line"; break
    fi
  done < "$QUEUEFILE"
  
  [ -z "$current" ] && { log "ALL DONE."; exit 0; }
  
  log "BUILDING: $current"
  local goal
  goal=$(cat "$GOALFILE" 2>/dev/null || echo "Build the file.")
  
  local output
  output=$(hermes chat -q "GOAL: $goal. Build $current. Output: FILE: $current followed by complete code." --yolo --quiet 2>/dev/null || echo "")
  
  # Extract and save
  local filepath="" content="" found=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^FILE:[[:space:]]+(.*) ]] && [ "$found" = false ]; then
      filepath="${BASH_REMATCH[1]}"; found=true
    elif [ "$found" = true ]; then
      content+="$line"$'\n'
    fi
  done <<< "$output"
  
  if [ -n "$filepath" ] && [ -n "$content" ]; then
    # Normalize and validate path
    fp_rel="${filepath#/}"
    fp_full="$(realpath -m "$REPODIR/$fp_rel")"
    if [[ "$fp_full" != "$REPODIR"* ]]; then
      log "SECURITY ALERT: blocked write outside REPODIR: $fp_full" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$fp_full")"
    tmpf=$(mktemp "${REPODIR}/.codex/tmpfile.XXXXXX" 2>/dev/null || mktemp)
    printf '%s\n' "$content" > "$tmpf"
    mv "$tmpf" "$fp_full"
    chmod 0644 "$fp_full" || true
    printf '%s\n' "$fp_rel" >> "$DONEFILE"
    log "BUILT: $fp_rel"
  else
    log "FAILED."
  fi
}

main "$@"
MINIMAL
  
  chmod +x "$SKILLDIR/runcycle.sh"
  echo "Orchestrator recovered to minimal working state."
  echo "Run: listen.sh 'your request' to rebuild your project."
}

# =============================================================================
# 4. WISDOM — Analyze lessons and propose self-improvements
# =============================================================================
wisdom() {
  echo "=== SYSTEM WISDOM ==="
  
  # Count successes and failures
  local lessons="$HOME/codex-builds/.codex/lessons.jsonl"
  if [ -f "$lessons" ]; then
    local total
    total=$(wc -l < "$lessons" 2>/dev/null || echo 0)
    local fails
    fails=$(grep -F -c "FAILED" "$lessons" 2>/dev/null || echo 0)
    echo "Total cycles: $total"
    echo "Failures: $fails"
    if [ "$total" -gt 0 ]; then echo "Success rate: $(( 100 - fails * 100 / total ))%"; fi
  fi
  
  # Check global knowledge growth
  local gk="$SKILLDIR/global-knowledge.jsonl"
  if [ -f "$gk" ]; then
    local rules lessons_count
    rules=$(grep -F -c '"type": "rule"' "$gk" 2>/dev/null || echo 0)
    lessons_count=$(grep -F -c '"type": "lesson"' "$gk" 2>/dev/null || echo 0)
    echo "Global rules: $rules"
    echo "Global lessons: $lessons_count"
  fi
  
  # Suggest next action
  echo ""
  echo "Self-improvement status:"
  if [ -f "$SKILLDIR/proposals.md" ]; then
    local pending
    pending=$(grep -F -c "PENDING" "$SKILLDIR/proposals.md" 2>/dev/null || echo 0)
    [ "$pending" -gt 0 ] && echo "  $pending proposals waiting for approval"
  fi
  echo "  Run: listen.sh 'your idea' to build something new"
  echo "  Run: kernel.sh recover to restore minimal system"
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-}" in
  check) check ;;
  lock) lock ;;
  recover) recover ;;
  wisdom) wisdom ;;
  *)
    echo "CODES-DEVELOPER KERNEL v$VERSION"
    echo ""
    echo "Usage:"
    echo "  kernel.sh check    — Verify system integrity"
    echo "  kernel.sh lock     — Lock current kernel as trusted"
    echo "  kernel.sh recover  — Rebuild minimal orchestrator"
    echo "  kernel.sh wisdom   — Show system health and learning"
    ;;
esac
