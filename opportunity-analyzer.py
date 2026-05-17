#!/usr/bin/env python3
"""
Opportunity Analyzer — Finds ways to strengthen the grid, not from failures but from patterns in successful builds.
"""
import json, os, re
from collections import Counter
from datetime import datetime, UTC

HOME = os.path.expanduser('~')
GLOBAL_FILE = os.path.join(HOME, '.hermes', 'skills', 'codex-developer', 'global-knowledge.jsonl')
PROPOSALS_FILE = os.path.join(HOME, '.hermes', 'skills', 'codex-developer', 'proposals.md')

def scan_all_projects():
    """Scan all projects for patterns that could be hardened."""
    findings = []
    
    for item in os.listdir(HOME):
        item_path = os.path.join(HOME, item)
        if not os.path.isdir(item_path) or item.startswith('.'):
            continue
        
        codex_dir = os.path.join(item_path, '.codex')
        if not os.path.exists(codex_dir):
            continue
        
        # Check cycle log
        cycle_log = os.path.join(codex_dir, 'cycle-log.jsonl')
        if os.path.exists(cycle_log):
            with open(cycle_log) as f:
                cycles = [json.loads(line) for line in f if line.strip()]
            
            if len(cycles) >= 3:
                # Pattern: what file types are most common?
                file_types = Counter(c.get('file', '').split('.')[-1] for c in cycles)
                
                # Pattern: what modes are used?
                modes = Counter(c.get('mode', '') for c in cycles)
                
                # Pattern: are there markdown fences in any .tsx/.py files?
                for root, dirs, files in os.walk(item_path):
                    for f in files:
                        if f.endswith(('.tsx', '.ts', '.py', '.js')):
                            fpath = os.path.join(root, f)
                            try:
                                with open(fpath) as fh:
                                    first_line = fh.readline()
                                    if first_line.startswith('```'):
                                        findings.append({
                                            'project': item,
                                            'file': f,
                                            'issue': 'markdown_fence',
                                            'detail': f'{f} starts with ``` — should be stripped'
                                        })
                            except:
                                pass
        
        # Check if package.json exists but no tsconfig.json
        if os.path.exists(os.path.join(item_path, 'package.json')):
            if not os.path.exists(os.path.join(item_path, 'tsconfig.json')):
                findings.append({
                    'project': item,
                    'file': 'tsconfig.json',
                    'issue': 'missing_tsconfig',
                    'detail': 'Next.js project missing tsconfig.json with @/* alias'
                })
    
    return findings

def analyze():
    findings = scan_all_projects()
    
    if not findings:
        print("No opportunities found. Grid is strong.")
        return
    
    # Group by issue type
    by_issue = {}
    for f in findings:
        issue = f['issue']
        if issue not in by_issue:
            by_issue[issue] = []
        by_issue[issue].append(f)
    
    proposals = []
    now = datetime.now(UTC).isoformat()
    
    for issue, items in by_issue.items():
        if issue == 'markdown_fence' and len(items) >= 1:
            proposals.append({
                'id': f'opp-prop-{len(proposals)+1}',
                'type': 'prevention',
                'title': 'Strengthen markdown fence stripping',
                'reason': f'{len(items)} files still have markdown fences',
                'rule': 'MARKDOWN FENCES: Strip ``` from the first and last lines of every generated file. The first line must be code, not a markdown fence.',
                'details': [i['detail'] for i in items[:3]],
                'auto_fix': 'Already implemented in runcycle.sh apply_file — verify it works for all file types.',
                'risk': 'none',
                'timestamp': now
            })
        
        if issue == 'missing_tsconfig' and len(items) >= 1:
            proposals.append({
                'id': f'opp-prop-{len(proposals)+1}',
                'type': 'auto-generate',
                'title': 'Auto-generate tsconfig.json for Next.js projects',
                'reason': f'{len(items)} Next.js projects missing tsconfig.json',
                'rule': 'For Next.js projects, always create tsconfig.json with @/* path alias to ./*',
                'details': [i['project'] for i in items[:3]],
                'auto_fix': 'Add tsconfig.json generation to mode_new when PROJECT_TYPE is nextjs',
                'risk': 'low',
                'timestamp': now
            })
    
    if not proposals:
        print("No actionable proposals.")
        return
    
    with open(PROPOSALS_FILE, 'a') as f:
        f.write(f'\n## Opportunity Analysis at {now}\n\n')
        for p in proposals:
            f.write(f"### [{p['id']}] {p['title']}\n")
            f.write(f"- **Type:** {p['type']}\n")
            f.write(f"- **Reason:** {p['reason']}\n")
            f.write(f"- **Proposed Rule:** {p['rule']}\n")
            f.write(f"- **Risk:** {p['risk']}\n")
            if p.get('details'):
                for d in p['details']:
                    f.write(f"- **Found in:** {d}\n")
            f.write(f"- **Status:** PENDING\n\n")
    
    print(f'Generated {len(proposals)} improvement proposals from opportunities, not failures.')
    for p in proposals:
        print(f"  [{p['id']}] {p['title']}")

if __name__ == '__main__':
    analyze()
