#!/usr/bin/env bash
# v12.2 Symbol Validator
REPODIR="$(readlink -f "${1:-/data/data/com.termux/files/home/projects}")"
grep -r "TODO" "$REPODIR" --exclude-dir=.git --exclude-dir=.codex | head -n 5
