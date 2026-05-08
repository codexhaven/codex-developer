#!/usr/bin/env python3
"""Analyze lessons.jsonl for patterns and generate constraints.
Upgraded to v11.1.0; implemented platform-agnostic paths (REPODIR/SKILLDIR),
added fallback for empty queues to prevent hard stops, and improved
error logging for queue generation failures.
"""
import json
import os
import sys
from collections import Counter

REPODIR = os.getenv('CODEX_REPO', os.path.expanduser('~/.codex-builds'))
SKILLDIR = os.getenv('SKILLDIR', os.path.dirname(os.path.abspath(__file__)))
LESSONS_FILE = os.path.join(REPODIR, '.codex', 'lessons.jsonl')
GLOBAL_FILE = os.path.join(SKILLDIR, 'global-knowledge.jsonl')

def analyze():
    if not os.path.exists(LESSONS_FILE):
        print(f"ERROR: Lessons file not found at {LESSONS_FILE}", file=sys.stderr)
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
        # Fallback for empty queue in EXISTING mode: avoid stopping hard
        print(f"Queue empty or too small ({len(lessons)} lessons) — skipping generation.")
        return
    
    failures = [l for l in lessons if l.get('result') != 'SUCCESS']
    successes = [l for l in lessons if l.get('result') == 'SUCCESS']
    
    print(f"Analyzed {len(lessons)} lessons: {len(successes)} success, {len(failures)} failures")
    
    if len(failures) >= 2:
        fail_tasks = [f.get('task', '') for f in failures]
        task_counts = Counter(fail_tasks)
        
        # Open GLOBAL_FILE for appending patterns
        try:
            with open(GLOBAL_FILE, 'a') as f:
                for task, count in task_counts.items():
                    if count >= 2:
                        entry = {"task": task, "pattern": "FAIL_THRESHOLD_EXCEEDED"}
                        f.write(json.dumps(entry) + "\n")
        except Exception as e:
            print(f"Error writing to global-knowledge: {e}", file=sys.stderr)

if __name__ == "__main__":
    analyze()
