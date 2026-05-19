#!/usr/bin/env python3
"""Full Context Reader — maps project structure, reads imports, builds dependency graph."""
import os, json, sys

def get_project_tree(repo_dir):
    """Build folder/file tree."""
    tree = {}
    for root, dirs, files in os.walk(repo_dir):
        dirs[:] = [d for d in dirs if d not in ('.git', '.codex', '__pycache__', '.pytest_cache', 'node_modules')]
        rel_path = os.path.relpath(root, repo_dir)
        code_files = [f for f in files if f.endswith(('.py', '.js', '.ts', '.tsx', '.jsx', '.sh'))]
        if code_files:
            tree[rel_path] = code_files
    return tree

def get_imports(file_path):
    """Extract import statements from a file."""
    imports = []
    try:
        with open(file_path, 'r', errors='ignore') as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith('import ') or stripped.startswith('from '):
                    imports.append(stripped)
    except:
        pass
    return imports

def get_exports(file_path):
    """Extract class and function definitions from a file."""
    exports = []
    try:
        with open(file_path, 'r', errors='ignore') as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith('def ') or stripped.startswith('class '):
                    # Extract just the name
                    name = stripped.split()[1].split('(')[0].split(':')[0]
                    exports.append(name)
    except:
        pass
    return exports

def build_dependency_graph(repo_dir):
    """Build a map of which files import from which other files, and what they import."""
    graph = {}
    tree = get_project_tree(repo_dir)
    
    for folder, files in tree.items():
        for f in files:
            fpath = os.path.join(repo_dir, folder, f) if folder != '.' else os.path.join(repo_dir, f)
            rel_path = os.path.join(folder, f) if folder != '.' else f
            
            imports = get_imports(fpath)
            exports = get_exports(fpath)
            
            # Find which of these imports reference other project files
            local_imports = []
            for imp in imports:
                for other_folder, other_files in tree.items():
                    for other_file in other_files:
                        mod_name = other_file.replace('.py', '').replace('.js', '').replace('.ts', '')
                        if mod_name in imp:
                            local_imports.append({
                                "imports": mod_name,
                                "from_file": other_file,
                                "statement": imp
                            })
            
            graph[rel_path] = {
                "exports": exports,
                "imports": local_imports
            }
    
    return graph

if __name__ == "__main__":
    repo = os.environ.get("REPODIR", os.environ.get("CODEX_REPO", "."))
    mode = sys.argv[1] if len(sys.argv) > 1 else "full"
    
    if mode == "full":
        graph = build_dependency_graph(repo)
        print("## FULL PROJECT CONTEXT (files + exports + imports)")
        for filepath, info in sorted(graph.items()):
            print(f"\n### {filepath}")
            if info["exports"]:
                print(f"  Exports: {', '.join(info['exports'])}")
            if info["imports"]:
                for imp in info["imports"]:
                    print(f"  Imports: {imp['imports']} from {imp['from_file']} — {imp['statement']}")
            if not info["exports"] and not info["imports"]:
                print("  (no exports or local imports)")
    
    elif mode == "tree":
        tree = get_project_tree(repo)
        print("## PROJECT STRUCTURE")
        for folder, files in sorted(tree.items()):
            display = folder if folder != '.' else 'root'
            print(f"\n- {display}/")
            for f in sorted(files):
                print(f"  - {f}")
    
    elif mode == "mismatches":
        # Find import mismatches
        graph = build_dependency_graph(repo)
        print("## IMPORT MISMATCHES")
        mismatches = 0
        for filepath, info in sorted(graph.items()):
            for imp in info.get("imports", []):
                imported_name = imp["imports"]
                from_file = imp["from_file"]
                # Check if the imported name exists in the target file's exports
                target_exports = graph.get(from_file, {}).get("exports", [])
                # Also check alternative paths
                for other_path, other_info in graph.items():
                    if other_path.endswith(from_file):
                        target_exports = other_info.get("exports", [])
                        break
                
                # Skip module-level imports (import foo) — only check from X import Y
                if imp["statement"].startswith("import ") and not imp["statement"].startswith("from "):
                    continue
                if imported_name not in target_exports and target_exports:
                    print(f"  MISMATCH: {filepath} imports '{imported_name}' from {from_file}")
                    print(f"    Available exports in {from_file}: {', '.join(target_exports)}")
                    mismatches += 1
        
        if mismatches == 0:
            print("  No import mismatches found.")
        else:
            print(f"\n  Total: {mismatches} mismatches")
    
    elif mode == "context":
        # Output full context for a specific file (used before PATCH)
        target_file = sys.argv[2] if len(sys.argv) > 2 else None
        if target_file:
            graph = build_dependency_graph(repo)
            print(f"## CONTEXT FOR: {target_file}")
            
            # Show what this file imports and from where
            if target_file in graph:
                info = graph[target_file]
                print(f"\n### {target_file} imports:")
                for imp in info.get("imports", []):
                    print(f"  - {imp['imports']} from {imp['from_file']}")
                    # Show the actual exports available in that module
                    for other_path, other_info in graph.items():
                        if other_path.endswith(imp['from_file']):
                            print(f"    Available: {', '.join(other_info.get('exports', []))}")
            
            # Show all exports across the project
            print(f"\n### All project exports:")
            for fp, info in sorted(graph.items()):
                if info["exports"]:
                    print(f"  {fp}: {', '.join(info['exports'])}")
