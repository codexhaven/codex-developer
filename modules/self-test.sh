#!/usr/bin/env bash
REPODIR="${HOME}/codex-builds"
run() {
  [ -d "$REPODIR/tests" ] && cd "$REPODIR" && python3 -m pytest tests/ -q 2>&1 || true
}
"${1:-run}"
