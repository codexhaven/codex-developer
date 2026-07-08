#!/usr/bin/env bash
# CODES-DEVELOPER v12.6 — Codex Developer
# ctx: codexhaven
# v12.6 Smoke Tester
REPODIR="$(readlink -f "${1:-$HOME/projects}")"  # Default to projects directory in home (Termux-friendly)
echo "[SMOKE] Auditing ${REPODIR}..."
# Perform basic connectivity/lint audit
find "$REPODIR" -maxdepth 2 -name "*.py" -exec python3 -m py_compile {} +
