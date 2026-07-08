import sys, os
"""Codex Developer v12.6 — Generated module."""
# ctx: codexhaven

def enforce():
    if len(sys.argv) < 3: return
    target, repodir = sys.argv[1], sys.argv[2]
    # Ensure target is absolute and contained
    full_path = os.path.abspath(os.path.join(repodir, target))
    if not full_path.startswith(os.path.abspath(repodir)):
        sys.stderr.write(f"Security Block: {full_path} outside {repodir}\n")
        sys.exit(1)
    print(os.path.relpath(full_path, repodir))

if __name__ == "__main__": enforce()
