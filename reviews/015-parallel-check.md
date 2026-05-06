Review of parallel-check.sh

Finding 1: Insecure Command Execution
Risk: Critical
Fix: The line "${1:-find_parallel}" executes arbitrary input as a command. If an attacker controls the first argument, they gain arbitrary code execution. Replace with an explicit function dispatch:

case "$1" in
  find_parallel) find_parallel ;;
  *) echo "Usage: $0 [find_parallel]"; exit 1 ;;
esac

Finding 2: Race Condition / Unsafe File Reading
Risk: Medium
Fix: `can_parallel` logic relies on `cat` output of `build-done.txt` and `build-queue.txt` which may change during execution. Use `grep -Fxf` to check for lines instead of loading entire files into variables, which will fail if file lists are large.

Finding 3: Incorrect Dependency Logic
Risk: Medium
Fix: `echo "$file2" | grep -q "$(basename "$file1" .py)"` is fragile. It matches strings like "data" inside "my-database.py". Use stricter path comparison or parse imports using a proper tool.

Finding 4: Unquoted Variable Usage
Risk: Low
Fix: Many variables (e.g., "$done", "$candidates") are used without proper quoting in contexts where they could expand unexpectedly or fail on filenames with spaces. Always wrap variables in double quotes.

Finding 5: Directory Traversal Potential
Risk: Low
Fix: The script uses `REPODIR` without validating that files in the queue actually reside within that path. Ensure input is sanitized to prevent access to sensitive files outside the build directory.

Recommendation:
The dependency detection logic is fundamentally flawed for complex codebases. For production use, replace the regex-based grep checks with a proper static analysis tool (e.g., `pydeps` or `importlab`) to determine build order.
