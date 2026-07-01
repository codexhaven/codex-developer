import os
import re
import sys
"""Codex Developer v12.4 — Generated module."""
# ctx: codexhaven

def scan_deps(file_path, repo_dir, queue_file):
    filename = os.path.basename(file_path)
    
    # Duplicate Check: Scan project for existing file
    for root, dirs, files in os.walk(repo_dir):
        if filename in files and os.path.join(root, filename) != file_path:
            return # Already exists
            
    with open(file_path, 'r', errors='ignore') as f:
        content = f.read()
    
    # Simple regex for local imports (e.g., import ... from './utils')
    imports = re.findall(r'from\s+[\'"]\./([^\'"]+)', content)
    
    with open(queue_file, 'a') as q:
        for imp in imports:
            # Simple heuristic: if it looks like a py file
            new_file = f"{imp}.py"
            q.write(f"NEW: {new_file}\n")

if __name__ == "__main__":
    scan_deps(sys.argv[1], sys.argv[2], sys.argv[3])
