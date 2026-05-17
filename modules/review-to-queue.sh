#!/usr/bin/env bash
# review-to-queue.sh — Bridge between REVIEW mode and BUILD loop
# Searches project for files matching review entries
set -euo pipefail

REVIEW_DIR="${1:-${REPODIR:-.}/reviews}"
QUEUEFILE="${REPODIR:-.}/.codex/build-queue.txt"
DONEFILE="${REPODIR:-.}/.codex/build-done.txt"

[ -d "$REVIEW_DIR" ] || { echo "[BRIDGE] No reviews directory."; exit 0; }
> "$QUEUEFILE"
> "$DONEFILE"

count=0
for review_file in "$REVIEW_DIR"/*.md; do
  [ -f "$review_file" ] || continue

  # Extract base filename from review — the last segment before .md
  # "001-SKILL" → "SKILL", "005-home-godmode-lib-parsers" → "parsers"
  base=$(basename "$review_file" .md)
  base=$(echo "$base" | sed 's/^[0-9]*-//')   # remove number prefix
  search_name=$(echo "$base" | sed 's/.*-//')  # last segment = filename (no ext)
  
  # Extract folder hint from review filename
  # "005-home-godmode-lib-parsers" → "home/godmode/lib"
  folder_hint=$(echo "$base" | sed "s/-${search_name}\$//" | tr '-' '/')
  [ "$folder_hint" = "$search_name" ] && folder_hint=""

  # Search project for a file matching this name (any extension)
  found=""
  if [ -n "$folder_hint" ]; then
    # Search within the hinted folder
    found=$(find "${REPODIR:-.}/$folder_hint" -maxdepth 1 -name "${search_name}.*" -type f 2>/dev/null | head -1)
  fi
  
  # If not found in hinted folder, search entire project
  if [ -z "$found" ]; then
    found=$(find "${REPODIR:-.}" -name "${search_name}.*" -not -path "*/.codex/*" -not -path "*/reviews/*" -not -path "*/.git/*" -not -path "*/__pycache__/*" -type f 2>/dev/null | head -1)
  fi

  if [ -z "$found" ]; then
    # Still not found — use the review filename as-is for NEW entries
    # Try to guess extension from review content
    ext=$(grep -m1 "File:" "$review_file" 2>/dev/null | grep -oE '\.[a-zA-Z0-9]+' | head -1)
    target="${folder_hint:+$folder_hint/}${search_name}${ext:-}"
    [ -z "$target" ] && continue
  else
    target="${found#${REPODIR:-.}/}"
  fi

  # Extract findings
  findings=$(grep -E "Risk:|Fix:|Finding:" "$review_file" 2>/dev/null | head -5 | tr '\n' '; ')

  if [ -n "$findings" ]; then
    if [ -f "${REPODIR:-.}/$target" ]; then
      echo "PATCH: $target - Review: $findings" >> "$QUEUEFILE"
    else
      echo "NEW: $target - Review: $findings" >> "$QUEUEFILE"
    fi
    count=$((count + 1))
  fi
done

echo "[BRIDGE] Generated $count entries from reviews."
[ "$count" -gt 0 ] && echo "Run: listen.sh 'apply review fixes'"
