#!/usr/bin/env bash
# v12.2 Smoke Tester
REPODIR="$(readlink -f "${1:-/data/data/com.termux/files/home/projects}")"
echo "[SMOKE] Auditing ${REPODIR}..."
# Perform basic connectivity/lint audit
find "$REPODIR" -maxdepth 2 -name "*.py" -exec python3 -m py_compile {} +
