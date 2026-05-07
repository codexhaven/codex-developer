#!/usr/bin/env python3
"""Analyze lessons.jsonl for patterns and generate constraints."""
import json
import os
import sys
import fcntl
from collections import Counter

# Use environment variables for path configuration
REPODIR = os.getenv('CODEX_REPO', os.path.expanduser('~/codex-builds'))
SKILLDIR = os.getenv('SKILLDIR', os.path.expanduser('~/.hermes/skills/codex-developer'))
LESSONS_FILE = os.path.join(REPODIR, '.codex', 'lessons.jsonl')
GLOBAL_FILE = os.path.join(SKILLDIR, 'global-knowledge.jsonl')

def analyze():
    if not os.path.exists(LESSONS_FILE):
        print("No lessons to analyze.")
        return
    
    lessons = []
    try:
        with open(LESSONS_FILE, 'r') as f:
            for line in f:
                try:
                    lessons.append(json.loads(line))
                except json.JSONDecodeError as e:
                    print(f"Error parsing lesson line: {e}", file=sys.stderr)
    except Exception as e:
        print(f"Error reading lessons file: {e}", file=sys.stderr)
        return
    
    if len(lessons) < 3:
        print(f"Only {len(lessons)} lessons — need at least 3.")
        return
    
    failures = [l for l in lessons if l.get('result') != 'SUCCESS']
    successes = [l for l in lessons if l.get('result') == 'SUCCESS']
    
    print(f"Analyzed {len(lessons)} lessons: {len(successes)} success, {len(failures)} failures")
    
    if len(failures) >= 2:
        fail_tasks = [f.get('task', '') for f in failures]
        task_counts = Counter(fail_tasks)
        
        # Open GLOBAL_FILE with locking
        if not os.path.exists(GLOBAL_FILE):
            os.mknod(GLOBAL_FILE)
            os.chmod(GLOBAL_FILE, 0o600)
            
        with open(GLOBAL_FILE, 'r+') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            try:
                existing = [json.loads(line) for line in f if line.strip()]
            except json.JSONDecodeError:
                existing = []
            
            for task, count in task_counts.items():
                if count >= 2:
                    already_exists = any(e.get('type') == 'rule' and task[:50] in e.get('rule', '') for e in existing)
                    
                    if not already_exists:
                        constraint = {
                            "type": "rule",
                            "rule": f"AUTO-CONSTRAINT: Task '{task[:80]}' failed {count} times. Review before retrying.",
                            "source": "lesson-analyzer",
                            "priority": "high"
                        }
                        f.write(json.dumps(constraint) + '\n')
                        print(f"ADDED CONSTRAINT: {task[:60]}...")
            fcntl.flock(f, fcntl.LOCK_UN)

if __name__ == '__main__':
    analyze()
