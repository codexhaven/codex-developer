#!/usr/bin/env bash
set -euo pipefail

# parallel-check.sh - Check parallel build dependencies

REPODIR="${HOME}/projects"

    echo "Checking parallel build dependencies"; can_parallel; 

    local build_done_file="build-done.txt"
    local build_queue_file="build-queue.txt"

    # Ensure file exists
    if [[ ! -f "$build_done_file" || ! -f "$build_queue_file" ]]; then
        echo "Necessary files not found."
        exit 1
    fi
    
    # Use grep to check for lines instead of loading whole files
    grep -Fxf "$build_queue_file" "$build_done_file" | wc -l
}

case "$1" in
    can_parallel) can_parallel ;;
    *) echo "Usage: $0 [can_parallel]"; exit 1 ;;
 esac
