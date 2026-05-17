import os
import json

def get_project_tree(repo_dir):
    tree = {}
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in dirs: dirs.remove('.git')
        if '.codex' in dirs: dirs.remove('.codex')
        
        rel_path = os.path.relpath(root, repo_dir)
        tree[rel_path] = [f for f in files if f.endswith(('.py', '.js', '.ts', '.tsx', '.jsx'))]
    return tree

def get_imports(file_path):
    imports = []
    try:
        with open(file_path, 'r', errors='ignore') as f:
            for line in f:
                if 'import ' in line:
                    imports.append(line.strip())
    except:
        pass
    return imports

if __name__ == "__main__":
    repo = os.environ.get("CODEX_REPO", ".")
    tree = get_project_tree(repo)
    print("## PROJECT ARCHITECTURE MAP")
    for folder, files in tree.items():
        if files:
            print(f"- {folder}/")
            for f in files:
                print(f"  - {f}")
