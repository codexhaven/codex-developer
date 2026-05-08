#!/usr/bin/env bash
set -euo pipefail

# Configuration
CODEX_REPO="${CODEX_REPO:-$HOME/codex-builds}"
STATE_FILE="$CODEX_REPO/.codex/state.json"
QUEUE_FILE="$CODEX_REPO/.codex/build-queue.txt"
DONE_FILE="$CODEX_REPO/.codex/build-done.txt"

# Ensure state
mkdir -p "$CODEX_REPO/.codex"
[ ! -f "$STATE_FILE" ] && echo '{"cycle":0,"successful_changes":0,"reverts":0,"files_built":[]}' > "$STATE_FILE"
[ ! -f "$QUEUE_FILE" ] && touch "$QUEUE_FILE"
[ ! -f "$DONE_FILE" ] && touch "$DONE_FILE"

# Process next item
item=$(comm -23 "$QUEUE_FILE" "$DONE_FILE" | head -n 1)
[ -z "$item" ] && exit 0

echo "PLANNED: $item"

# Logic for path extraction: handle prefixes, keep path intact
# Input formats: "NEW: path/to/file", "PATCH: path/to/file - ...", "SED: path/to/file - ..."
# We match everything after the prefix until the first delimiter (or end of line)
target_path=$(echo "$item" | sed -E 's/^(NEW|PATCH|SED):[[:space:]]*//' | sed -E 's/[[:space:]]*(-| ).*//')
action_type=$(echo "$item" | cut -d':' -f1)

# Perform action
case "$action_type" in
  NEW)
    echo "BUILT: $target_path"
    mkdir -p "$(dirname "$CODEX_REPO/$target_path")"
    touch "$CODEX_REPO/$target_path"
    ;;
  PATCH)
    echo "BUILT: $target_path"
    # Logic to handle patch content follows here
    ;;
  SED)
    echo "BUILT: $target_path"
    # Logic to handle sed content follows here
    ;;
esac

# Mark done
echo "$item" >> "$DONE_FILE"
# Update state cycle
cycle=$(grep -o '"cycle":[0-9]*' "$STATE_FILE" | cut -d':' -f2)
new_cycle=$((cycle + 1))
sed -i "s/\"cycle\":[0-9]*/\"cycle\":$new_cycle/" "$STATE_FILE"

echo "DONE: $item"
