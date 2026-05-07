#!/usr/bin/env bash
set -euo pipefail
REPODIR="${HOME}/codex-builds"

run() {
  if [ -d "$REPODIR/tests" ]; then
    cd "$REPODIR"
    python3 -m pytest tests/ -q
  else
    echo "Test directory not found: $REPODIR/tests" >&2
    exit 1
  fi
}

run
