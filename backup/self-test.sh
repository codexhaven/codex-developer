#!/usr/bin/env bash
# Self-Test — Run project tests after build
REPODIR="${HOME}/codex-builds"

run_tests() {
  echo "=== SELF-TEST ==="
  
  # Check if tests directory exists
  if [ -d "$REPODIR/tests" ]; then
    echo "Running tests..."
    
    # Try pytest first
    if command -v pytest >/dev/null 2>&1; then
      cd "$REPODIR" && python3 -m pytest tests/ -v 2>&1 && echo "TESTS: PASS" || echo "TESTS: FAIL"
    # Fall back to unittest
    elif [ -f "$REPODIR/tests/test_api.py" ]; then
      cd "$REPODIR" && python3 -m unittest tests.test_api 2>&1 && echo "TESTS: PASS" || echo "TESTS: FAIL"
    else
      echo "No test runner available."
    fi
  else
    echo "No tests directory."
  fi
}

# Test a single file
test_file() {
  local filepath="$1"
  [ ! -f "$REPODIR/$filepath" ] && return
  
  if [[ "$filepath" == tests/*.py ]]; then
    cd "$REPODIR" && python3 "$filepath" 2>&1 && echo "TEST FILE: PASS" || echo "TEST FILE: FAIL"
  fi
}

"${1:-run_tests}" "${2:-}"
