#!/bin/bash
# sandbox/mirror.sh - Captures lesson data without breaking the loop
log_mirror() {
    if [ -f "$REPODIR/.codex/build.log" ]; then
        # Extract last 5 lines and append to lessons
        tail -n 5 "$REPODIR/.codex/build.log" >> "$REPODIR/.codex/lessons.md" 2>/dev/null || true
    fi
}
