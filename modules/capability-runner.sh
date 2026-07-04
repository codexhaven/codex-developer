#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# Capability Runner — executes project capabilities directly
# Called by listen.sh when a request matches a known capability

REPODIR="${1:-${REPODIR:-.}}"
REQUEST="${2:-}"
CAPFILE="${REPODIR}/.codex/capabilities.json"

[ -f "$CAPFILE" ] || { echo "[CAP] No capabilities file."; exit 1; }
[ -n "$REQUEST" ] || { echo "[CAP] No request."; exit 1; }

# Find matching capability
MATCH=$(python3 -c "
import json, sys

caps = json.load(open('$CAPFILE'))
request = '$REQUEST'.lower()

# Score each capability against the request
best_score = 0
best_run = ''
best_name = ''

for category in ['generators', 'scripts', 'commands']:
    for name, info in caps.get(category, {}).items():
        # Extract keywords from the filename
        keywords = name.replace('.py', '').replace('.sh', '').replace('_', ' ').replace('/', ' ').split()
        # Count matching words
        score = sum(1 for kw in keywords if kw in request)
        if score > best_score:
            best_score = score
            best_run = info.get('run', '')
            best_name = name

if best_score > 0:
    print(f'MATCH: {best_name} (score: {best_score})')
    print(f'RUN: {best_run}')
else:
    print('NO_MATCH')
" 2>/dev/null)

if echo "$MATCH" | grep -q "NO_MATCH"; then
    echo "[CAP] No capability matches. Falling through to normal build."
    exit 1
fi

BEST_NAME=$(echo "$MATCH" | grep "MATCH:" | sed 's/MATCH:\s*//' | sed 's/(.*//' | xargs)
BEST_RUN=$(echo "$MATCH" | grep "RUN:" | sed 's/RUN:\s*//')

echo "[CAP] Matched: $BEST_NAME"
echo "[CAP] Executing: cd $REPODIR && $BEST_RUN"
echo ""

cd "$REPODIR" && eval "$BEST_RUN"
