#!/usr/bin/env bash
# method-adapter.sh — Adaptive prompt strategy when hermes returns empty
# Called by build_file() when primary prompt fails

METHOD_ADAPT_LOG="${REPODIR}/.codex/method_adapt.log"

adapt_prompt() {
  local filepath="$1"
  local goal="$2"
  local mode="${3:-NEW}"
  local attempt="${4:-1}"
  local last_prompt="${5:-}"

  echo "[ADAPT] Attempt $attempt — adapting strategy..." | tee -a "$METHOD_ADAPT_LOG"

  case $attempt in
    1)
      # Strategy 1: Simplified — strip context, just the essentials
      echo "## MODE: ${mode} FILE
## TARGET: $filepath
## GOAL: $goal
## INSTRUCTIONS: Build this file. Working code only. Output: FILE: $filepath"
      ;;
    2)
      # Strategy 2: Split — ask for structure first, then content
      echo "## MODE: OUTLINE
## TARGET: $filepath
## GOAL: $goal
## INSTRUCTIONS: List ONLY the functions/classes this file needs. One per line. No implementation."
      ;;
    3)
      # Strategy 3: Minimal — bare minimum
      echo "Write a minimal working version of $filepath for: $goal. Output: FILE: $filepath"
      ;;
    *)
      # Strategy 4: Fallback — use template
      local ext="${filepath##*.}"
      echo "Create a basic $ext file at $filepath with placeholder functions for: $goal. Output: FILE: $filepath"
      ;;
  esac
}

# If called directly with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  adapt_prompt "$@"
fi
