#!/usr/bin/env bash
# CODES-DEVELOPER v12.6 — Codex Developer
# ctx: codexhaven
# Capability Scanner — indexes what a project can do
# Runs after build completes, saves to .codex/capabilities.json

REPODIR="${1:-${REPODIR:-.}}"
CAPFILE="${REPODIR}/.codex/capabilities.json"

echo "[CAP] Scanning project capabilities..."

python3 << 'PYEOF'
import os, json, sys

repodir = os.environ.get('REPODIR', '.')
capfile = os.path.join(repodir, '.codex', 'capabilities.json')

capabilities = {
    "scripts": {},
    "commands": {},
    "generators": {},
    "tests": {}
}

# Scan for Python scripts with argparse or if __name__
for root, dirs, files in os.walk(repodir):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.py'):
            continue
        fpath = os.path.join(root, f)
        rel = os.path.relpath(fpath, repodir)
        try:
            with open(fpath) as fh:
                content = fh.read()
        except:
            continue
        
        # Detect capabilities
        if 'argparse' in content or 'ArgumentParser' in content:
            # Extract --flags
            flags = []
            for line in content.split('\n'):
                if 'add_argument' in line:
                    import re
                    match = re.search(r"'--(\w+)'|\"--(\w+)\"", line)
                    if match:
                        flag = match.group(1) or match.group(2)
                        flags.append(f"--{flag}")
            if flags:
                capabilities['commands'][rel] = {
                    "type": "cli",
                    "flags": flags,
                    "run": f"python3 {rel}"
                }
        
        if 'def generate' in content or 'generator' in f.lower():
            capabilities['generators'][rel] = {
                "type": "generator",
                "run": f"python3 {rel}",
                "description": "Generates data/training content"
            }
        
        if 'if __name__' in content and 'main()' in content:
            if rel not in capabilities['commands']:
                capabilities['scripts'][rel] = {
                    "type": "runnable",
                    "run": f"python3 {rel}"
                }

# Scan shell scripts
for root, dirs, files in os.walk(repodir):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if f.endswith('.sh'):
            fpath = os.path.join(root, f)
            rel = os.path.relpath(fpath, repodir)
            capabilities['scripts'][rel] = {
                "type": "shell",
                "run": f"bash {rel}"
            }

os.makedirs(os.path.dirname(capfile), exist_ok=True)
with open(capfile, 'w') as f:
    json.dump(capabilities, f, indent=2)

print(f"[CAP] Indexed: {len(capabilities['commands'])} commands, {len(capabilities['generators'])} generators, {len(capabilities['scripts'])} scripts")
PYEOF
