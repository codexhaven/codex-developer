#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# mirror.sh v2 — Feeds build successes into Cod3x training
log_mirror() {
    local buildlog="${REPODIR}/.codex/build.log"
    local training="${HOME}/Cod3x/data/training_data.json"
    
    [ -f "$buildlog" ] || return 0
    
    # Extract successful builds
    local successes=$(grep "NEW:\|PATCH:" "$buildlog" 2>/dev/null | tail -3)
    
    if [ -n "$successes" ] && [ -f "$training" ]; then
        # Log the pattern for future reference
        echo "$successes" >> "${REPODIR}/.codex/lessons.md" 2>/dev/null || true
        
        # Count successes for stats
        local count=$(echo "$successes" | wc -l)
        [ "$count" -gt 0 ] && echo "[MIRROR] $count build patterns captured"
    fi
}

# Also capture the architecture patterns for Cod3x to learn from
capture_architecture() {
    local contract="${REPODIR}/.codex/contract.json"
    local training="${HOME}/Cod3x/data/training_data.json"
    
    [ -f "$contract" ] || return 0
    [ -f "$training" ] || return 0
    
    # Extract interface patterns as training examples
    python3 -c "
import json, os
try:
    contract = json.load(open('$contract'))
    training = json.load(open('$training'))
    
    for fname, mod in contract.get('modules', {}).items():
        for exp in mod.get('exports', []):
            name = exp.get('name', '?')
            etype = exp.get('type', '?')
            training.append({
                'instruction': f'How should a {etype} named {name} be structured in {fname}?',
                'response': f'I am Cod3x, built by Codex Developer. A {etype} named {name} in {fname} should follow the interface contract: it must have the exact signature defined in contract.json and handle all error cases specified in the project brain.'
            })
    
    with open('$training', 'w') as f:
        json.dump(training[-200:], f, indent=2)
except:
    pass
" 2>/dev/null || true
}
