Finding | Risk: Critical/High/Medium/Low | Fix
--- | --- | ---
No error handling for failed `cd` | Medium | If `cd "$REPODIR"` fails (e.g., directory deleted), the script runs commands in the current working directory, potentially causing data corruption. Use `cd "$REPODIR" || exit 1`.
`2>&1` loses exit status control | Medium | By piping everything to stdout, the script doesn't cleanly distinguish between shell errors and test failures. Use specific log files or separate stderr redirection.
`command -v` check not robust | Low | `command -v` is good, but `pytest` might be installed but not in `$PATH` if using venv. Consider activating a venv if present.
Shell injection vulnerability | High | `"${1:-run_tests}" "${2:-}"` executes arbitrary functions or commands passed as arguments. If passed user input, this is a remote code execution risk. Use a whitelist of allowed function names.
`python3 -m unittest` hardcoded | Low | Falling back only to `test_api.py` is brittle. Consider scanning for any `test_*.py` files.
Lack of environment cleanup | Low | The script leaves the shell in `$REPODIR`. Use a subshell `(cd "$REPODIR" && ...)` to keep the parent shell environment clean.

Suggested Code Improvements:

#!/usr/bin/env bash
# Self-Test — Run project tests after build
REPODIR="${HOME}/codex-builds"

# Whitelist allowed functions
allowed_functions=("run_tests" "test_file")

run_tests() {
  echo "=== SELF-TEST ==="
  [ ! -d "$REPODIR" ] && { echo "Error: REPODIR not found"; return 1; }
  
  (
    cd "$REPODIR" || exit 1
    if [ -d "tests" ]; then
      echo "Running tests..."
      if command -v pytest >/dev/null 2>&1; then
        python3 -m pytest tests/ -v && echo "TESTS: PASS" || echo "TESTS: FAIL"
      else
        python3 -m unittest discover tests/ && echo "TESTS: PASS" || echo "TESTS: FAIL"
      fi
    else
      echo "No tests directory."
    fi
  )
}

test_file() {
  local filepath="$1"
  [[ -z "$filepath" ]] && return
  (
    cd "$REPODIR" || exit 1
    [ ! -f "$filepath" ] && { echo "File not found: $filepath"; return 1; }
    
    if [[ "$filepath" == tests/*.py ]]; then
      python3 "$filepath" && echo "TEST FILE: PASS" || echo "TEST FILE: FAIL"
    fi
  )
}

# Validate input
cmd="${1:-run_tests}"
if [[ " ${allowed_functions[*]} " =~ " ${cmd} " ]]; then
  $cmd "${2:-}"
else
  echo "Invalid command: $cmd"
  exit 1
fi
