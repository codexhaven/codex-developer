#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${HOME}/codex-builds"
LESSONS_FILE="${REPODIR}/.codex/lessons.jsonl"
PROPOSAL_FILE="${SKILLDIR}/proposals.md"

analyze() {
  echo "=== SELF-ANALYSIS ==="
  if [ ! -f "$LESSONS_FILE" ] || [ ! -s "$LESSONS_FILE" ]; then
    echo "No lessons to analyze."
    return
  fi
  python3 -c "
import json, os
from collections import defaultdict
f_path = os.path.expanduser('~/codex-builds/.codex/lessons.jsonl')
lessons = []
with open(f_path) as f:
    for line in f:
        try: lessons.append(json.loads(line))
        except: pass
successes = [l for l in lessons if l.get('result') == 'SUCCESS']
failures = [l for l in lessons if l.get('result') != 'SUCCESS']
print(f'Total: {len(lessons)}, Success: {len(successes)}, Failures: {len(failures)}')
if failures:
    ftypes = defaultdict(lambda: {'s':0,'f':0})
    for l in lessons:
        for fl in l.get('files',[]):
            ext = fl.split('.')[-1] if '.' in fl else 'unknown'
            if l.get('result') == 'SUCCESS': ftypes[ext]['s'] += 1
            else: ftypes[ext]['f'] += 1
    for ext, c in sorted(ftypes.items()):
        if c['f'] > 0:
            tot = c['s'] + c['f']
            print(f'  .{ext}: {c[\"f\"]}/{tot} failures ({c[\"f\"]/tot*100:.0f}%)')
"
}

approve() {
  local prop_id="$1"
  [ -z "$prop_id" ] && { echo "Usage: self-update.sh --approve <prop-id>"; return 1; }
  [ ! -f "$PROPOSAL_FILE" ] && { echo "No proposals file."; return 1; }
  
  local fix_cmd
  fix_cmd=$(python3 -c "
import re, os
with open(os.path.expanduser('~/.hermes/skills/codex-developer/proposals.md')) as f:
    content = f.read()
pattern = r'### \[' + '$prop_id' + r'\].*?\n- \*\*Auto-fix:\*\* \x60([^\x60]+)\x60'
match = re.search(pattern, content, re.DOTALL)
if match:
    print(match.group(1))
")
  
  [ -z "$fix_cmd" ] && { echo "Proposal $prop_id not found."; return 1; }
  
  echo "Proposed fix: $fix_cmd"
  echo -n "Apply? (y/N): "
  read -r confirm
  
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    eval "$fix_cmd"
    python3 -c "
import os
p = os.path.expanduser('~/.hermes/skills/codex-developer/proposals.md')
c = open(p).read()
c = c.replace('PENDING (run \`self-update.sh --approve $prop_id\` to apply)', 'APPROVED')
open(p,'w').write(c)
"
    echo "Proposal $prop_id APPROVED and applied."
  else
    echo "Cancelled."
  fi
}

case "${1:-}" in
  --analyze) analyze ;;
  --approve) approve "${2:-}" ;;
  *) echo "Usage: self-update.sh --analyze | --approve <id>" ;;
esac
