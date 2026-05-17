#!/bin/bash
# sandbox/phase_init.sh - Initializes the current_phase if missing
[ -f "$REPODIR/.codex/phases.json" ] || return 0

# Check if current_phase is already set
if ! grep -q "current_phase" "$REPODIR/.codex/phases.json"; then
    # Set the first phase as the current one
    python3 -c "
import json
try:
    with open('$REPODIR/.codex/phases.json', 'r') as f:
        reg = json.load(f)
    if 'phases' in reg and len(reg['phases']) > 0:
        reg['current_phase'] = reg['phases'][0]['id']
        with open('$REPODIR/.codex/phases.json', 'w') as f:
            json.dump(reg, f, indent=2)
except:
    pass
"
fi
