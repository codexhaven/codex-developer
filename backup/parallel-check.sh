#!/usr/bin/env bash
# Check if two files can be built in parallel (no cross-dependencies)
REPODIR="${HOME}/codex-builds"

can_parallel() {
  local file1="$1"
  local file2="$2"
  
  # Can't parallel if either depends on the other
  if [[ "$file1" == *.py ]] && echo "$file2" | grep -q "$(basename "$file1" .py)"; then
    return 1
  fi
  if [[ "$file2" == *.py ]] && echo "$file1" | grep -q "$(basename "$file2" .py)"; then
    return 1
  fi
  
  # Different directories = independent
  local dir1=$(dirname "$file1")
  local dir2=$(dirname "$file2")
  [ "$dir1" != "$dir2" ] && return 0
  
  # Same directory but different types = independent
  local ext1="${file1##*.}"
  local ext2="${file2##*.}"
  [ "$ext1" != "$ext2" ] && return 0
  
  return 1
}

# Given a queue, find files that can be built together
find_parallel() {
  local done=$(cat "$REPODIR/.codex/build-done.txt" 2>/dev/null)
  local candidates=""
  
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    echo "$done" | grep -qF "$file" && continue
    
    if [ -z "$candidates" ]; then
      candidates="$file"
    elif can_parallel "$candidates" "$file"; then
      echo "PARALLEL: $candidates + $file"
      return 0
    fi
  done < "$REPODIR/.codex/build-queue.txt"
  
  return 1
}

"${1:-find_parallel}"
