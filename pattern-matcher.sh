#!/usr/bin/env bash
# ctx: codexhaven
# Pattern Matcher — Finds reusable code before generating new code
SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -P 2>/dev/null || pwd))"
PATTERNSFILE="${SKILLDIR}/patterns.json"

# Given a file purpose from the build plan, find matching patterns
match_patterns() {
  local purpose="$1"
  local file_type="$2"
  local matches=""
  
  if [ ! -f "$PATTERNSFILE" ]; then
    echo ""
    return
  fi
  
  # Use environment variables to avoid command injection
  export PURPOSE="$purpose"
  export FILE_TYPE="$file_type"
  export PATTERNSFILE="$PATTERNSFILE"
  
  python3 -c "
import json, os
purpose = os.environ.get('PURPOSE', '').lower()
file_type = os.environ.get('FILE_TYPE', '')
patterns_file = os.environ.get('PATTERNSFILE', '')

with open(patterns_file) as f:
    patterns = json.load(f)

matches = []
for name, code in patterns.items():
    name_lower = name.lower()
    # Match by file type
    if file_type == 'css' and ('theme' in purpose or 'style' in purpose or 'dark' in purpose):
        if 'theme' in name_lower or 'css' in name_lower or 'style' in name_lower:
            matches.append((name, code[:300]))
    elif file_type == 'html' and ('template' in name_lower or 'boilerplate' in name_lower):
        matches.append((name, code[:300]))
    elif file_type == 'py' and ('flask' in purpose.lower() or 'server' in purpose.lower()):
        if 'flask' in name_lower or 'server' in name_lower:
            matches.append((name, code[:300]))
    elif file_type == 'js' and ('fetch' in name_lower or 'api' in name_lower):
        matches.append((name, code[:300]))

if matches:
    print('## REUSABLE PATTERNS FOUND ##')
    for name, code in matches[:3]:
        print(f'PATTERN [{name}]:')
        print(code)
        print()
else:
    print('')
"
}

# Add a new pattern from a successfully built file
add_pattern() {
  local filepath="$1"
  local purpose="$2"
  
  [ ! -f "$REPODIR/$filepath" ] && return
  
  export NAME=$(echo "$filepath" | sed 's|/|_|g' | sed 's/\.[a-z]*$//')
  export FILEPATH="$REPODIR/$filepath"
  export PATTERNSFILE="$PATTERNSFILE"
  
  # Read file content safely into a variable, then pass to python
  local code_content=$(head -50 "$REPODIR/$filepath" 2>/dev/null)
  export CODE_CONTENT="$code_content"
  
  python3 -c "
import json, os
name = os.environ.get('NAME')
code = os.environ.get('CODE_CONTENT')
patterns_file = os.environ.get('PATTERNSFILE')

with open(patterns_file) as f:
    patterns = json.load(f)
patterns[name] = code
with open(patterns_file, 'w') as f:
    json.dump(patterns, f, indent=2)
"
  echo "Pattern saved: $NAME"
}

"${1:-match}" "${2:-}" "${3:-}"
