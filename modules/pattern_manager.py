#!/usr/bin/env python3
"""Pattern manager for codex-developer.
Provides a safe add/match interface for patterns.json with file locking and atomic writes.
"""
import json
import os
import sys
import fcntl
import tempfile


def load_patterns(path):
    if not os.path.exists(path):
        return {}
    try:
        with open(path, 'r') as f:
            return json.load(f) if f.read().strip() else {}
    except Exception as e:
        print(f"Error loading patterns file: {e}", file=sys.stderr)
        return {}


def atomic_write(path, data):
    dirpath = os.path.dirname(path)
    os.makedirs(dirpath, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=dirpath, prefix='patterns.', text=True)
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except Exception:
                pass


def add_pattern(name, filepath, patterns_file):
    # Validate inputs
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}", file=sys.stderr)
        return 1
    # Read snippet
    try:
        with open(filepath, 'r') as f:
            snippet = f.read(500)
    except Exception as e:
        print(f"Error reading target file: {e}", file=sys.stderr)
        return 1

    # Ensure patterns_file dir exists
    os.makedirs(os.path.dirname(patterns_file), exist_ok=True)

    # Lock file and update
    try:
        # Open file descriptor for read/write (create if missing)
        fd = os.open(patterns_file, os.O_RDWR | os.O_CREAT)
    except Exception as e:
        print(f"Error opening patterns file: {e}", file=sys.stderr)
        return 1

    try:
        with os.fdopen(fd, 'r+') as f:
            # acquire exclusive lock
            try:
                fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            except Exception as e:
                print(f"Lock failed: {e}", file=sys.stderr)
                return 1
            try:
                f.seek(0)
                raw = f.read()
                p = json.loads(raw) if raw.strip() else {}
            except Exception:
                p = {}
            p[name] = snippet
            # atomic write via temp file in same dir
            atomic_write(patterns_file, p)
            # release lock
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    except Exception as e:
        print(f"Error updating patterns: {e}", file=sys.stderr)
        return 1
    return 0


def usage():
    print("Usage: pattern_manager.py add <name> <filepath>")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage(); sys.exit(1)
    cmd = sys.argv[1]
    patterns_file = os.environ.get('PATTERNSFILE', os.path.join(os.path.dirname(__file__), '..', 'patterns.json'))
    patterns_file = os.path.abspath(patterns_file)
    if cmd == 'add':
        if len(sys.argv) != 4:
            usage(); sys.exit(1)
        name = sys.argv[2]
        filepath = sys.argv[3]
        sys.exit(add_pattern(name, filepath, patterns_file))
    else:
        usage(); sys.exit(1)
