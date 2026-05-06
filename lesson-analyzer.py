#!/usr/bin/env python3
"""Analyze lessons.jsonl for patterns and generate constraints."""
import json
import os
from collections import Counter

HOME = os.path.expanduser('~')
LESSONS_FILE = os.path.join(HOME, 'codex-builds', '.codex', 'lessons.jsonl')
GLOBAL_FILE = os.path.join(HOME, '.hermes', 'skills', 'codex-developer', 'global-knowledge.jsonl')

def analyze():
    if not os.path.exists(LESSONS_FILE):
        print("No lessons to analyze.")
        return
    
    lessons = []
    with open(LESSONS_FILE) as f:
        for line in f:
            try:
                lessons.append(json.loads(line))
            except:
                pass
    
    if len(lessons) < 3:
        print(f"Only {len(lessons)} lessons — need at least 3 for pattern detection.")
        return
    
    # Find failures
    failures = [l for l in lessons if l.get('result') != 'SUCCESS']
    successes = [l for l in lessons if l.get('result') == 'SUCCESS']
    
    print(f"Analyzed {len(lessons)} lessons: {len(successes)} successes, {len(failures)} failures")
    
    # Detect repeated failure patterns
    if len(failures) >= 2:
        fail_tasks = [f.get('task', '') for f in failures]
        task_counts = Counter(fail_tasks)
        
        for task, count in task_counts.items():
            if count >= 2:
                constraint = {
                    "type": "rule",
                    "rule": f"AUTO-CONSTRAINT: Task '{task[:80]}' failed {count} times. Next attempt must use a different approach. Review why it failed before retrying.",
                    "source": "lesson-analyzer",
                    "priority": "high"
                }
                
                # Check if this constraint already exists
                existing = []
                if os.path.exists(GLOBAL_FILE):
                    with open(GLOBAL_FILE) as f:
                        for line in f:
                            try:
                                existing.append(json.loads(line))
                            except:
                                pass
                
                already_exists = any(
                    e.get('type') == 'rule' and task[:50] in e.get('rule', '')
                    for e in existing
                )
                
                if not already_exists:
                    with open(GLOBAL_FILE, 'a') as f:
                        f.write(json.dumps(constraint) + '\n')
                    print(f"ADDED CONSTRAINT: {constraint['rule'][:120]}...")
    
    # Detect successful patterns (keep doing what works)
    if len(successes) >= 3:
        recent_success = successes[-3:]
        patterns = [s.get('task', '') for s in recent_success]
        print(f"Recent successes: {len(patterns)}")
        print("No new constraints needed — pipeline is healthy.")

if __name__ == '__main__':
    analyze()
