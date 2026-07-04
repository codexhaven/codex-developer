#!/usr/bin/env bash
set -euo pipefail
# ctx: codexhaven
# Self-Update Engine — Analyzer → Proposal → Approval → Rule injection

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -P 2>/dev/null || pwd))"
GLOBAL_FILE="${SKILLDIR}/global-knowledge.jsonl"
PROPOSALS_FILE="${SKILLDIR}/proposals.md"

# =============================================================================
# ANALYZE — Run the opportunity analyzer
# =============================================================================
analyze() {
  echo "=== SELF-EVOLVE: Scanning for improvements ==="
  python3 "${SKILLDIR}/opportunity-analyzer.py"
}

# =============================================================================
# APPROVE — Convert a proposal into a rule and inject it
# =============================================================================
approve() {
  local prop_id="$1"
  
  if [ -z "$prop_id" ]; then
    echo "Usage: self-update.sh --approve <proposal-id>"
    echo "Run: self-update.sh --analyze first to see proposals."
    return 1
  fi
  
  if [ ! -f "$PROPOSALS_FILE" ]; then
    echo "No proposals file found. Run --analyze first."
    return 1
  fi
  
  # Extract proposal details
  local title rule_text auto_fix
  
  title=$(python3 -c "
import re, os
with open(os.path.expanduser('$PROPOSALS_FILE')) as f:
    content = f.read()
pattern = r'### \[' + '$prop_id' + r'\] ([^\n]+)'
match = re.search(pattern, content)
print(match.group(1) if match else '')
")
  
  rule_text=$(python3 -c "
import re, os
with open(os.path.expanduser('$PROPOSALS_FILE')) as f:
    content = f.read()
pattern = r'### \[' + '$prop_id' + r'\].*?\n- \*\*Proposed Rule:\*\* ([^\n]+)'
match = re.search(pattern, content, re.DOTALL)
print(match.group(1) if match else '')
")
  
  auto_fix=$(python3 -c "
import re, os
with open(os.path.expanduser('$PROPOSALS_FILE')) as f:
    content = f.read()
pattern = r'### \[' + '$prop_id' + r'\].*?\n- \*\*Auto-fix:\*\* \x60([^\x60]+)\x60'
match = re.search(pattern, content, re.DOTALL)
print(match.group(1) if match else '')
")
  
  if [ -z "$title" ] || [ -z "$rule_text" ]; then
    echo "Proposal $prop_id not found or incomplete."
    return 1
  fi
  
  echo ""
  echo "=============================================="
  echo "  PROPOSAL: $title"
  echo "=============================================="
  echo "  Rule: $rule_text"
  echo "=============================================="
  echo ""
  
  # If there's an auto_fix command, use it. Otherwise, generate one.
  if [ -n "$auto_fix" ]; then
    echo "Auto-fix available."
    echo -n "Apply this fix? (y/N): "
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      eval "$auto_fix"
      echo "Fix applied."
    else
      echo "Cancelled."
      return 0
    fi
  else
    # Generate rule injection using Python
    echo "No auto-fix command. Generating rule injection..."
    echo -n "Add this rule to global-knowledge.jsonl? (y/N): "
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      python3 -c "
import json, datetime, os
rule_text = '''$rule_text'''
entry = {
    'type': 'rule',
    'rule': rule_text,
    'source': '$prop_id',
    'timestamp': datetime.datetime.now(datetime.UTC).isoformat()
}
with open(os.path.expanduser('$GLOBAL_FILE'), 'a') as f:
    f.write(json.dumps(entry) + '\n')
print('Rule injected into global-knowledge.jsonl')
"
    else
      echo "Cancelled."
      return 0
    fi
  fi
  
  # Mark proposal as APPROVED
  python3 -c "
import os
p = os.path.expanduser('$PROPOSALS_FILE')
c = open(p).read()
c = c.replace('PENDING', 'APPROVED')
open(p, 'w').write(c)
print('Proposal marked as APPROVED')
"
  
  echo ""
  echo "Grid strengthened. Rule is now active in all future builds."
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-}" in
  --analyze)
    analyze
    ;;
  --approve)
    approve "${2:-}"
    ;;
  *)
    echo "Self-Update Engine"
    echo ""
    echo "Usage:"
    echo "  self-update.sh --analyze           Scan for improvement opportunities"
    echo "  self-update.sh --approve <id>      Approve and inject a rule"
    echo ""
    echo "Proposals are saved to: $PROPOSALS_FILE"
    ;;
esac
