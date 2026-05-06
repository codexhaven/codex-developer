Code Review: kernel.sh

Findings:

1. Unsafe File Content Extraction (Risk: Medium)
In `recover()`, the minimal `runcycle.sh` uses `hermes chat` to generate code, then uses bash parsing to save it. If the model output includes malformed `FILE:` markers or malicious content, the script could overwrite arbitrary files (including system files) or execute dangerous code.
Fix: Add a check to validate that `filepath` is within `$REPODIR`.

2. Lack of Atomic Writes (Risk: Low)
The `lock()` function writes the hash directly to the file using `>`. If this is interrupted, `.kernel-hash` could become empty or corrupted.
Fix: Use a temporary file and `mv` for atomic replacement.

3. Brittle Hash Calculation (Risk: Low)
`sha256sum "$SKILLDIR/kernel.sh"` relies on the path. If `SKILLDIR` is modified or the script is executed from a different directory while symlinked, the hash logic can become brittle.
Fix: Use `readlink -f "$0"` inside the script to resolve its own location independently of `SKILLDIR`.

4. Shell Injection Risk in `wisdom()` (Risk: Low)
The `wisdom()` function reads `lessons.jsonl` and uses `wc -l` and `grep` without sanitizing potential shell metacharacters in the filename or contents if they were ever manipulated. While low risk here, it is bad practice.
Fix: Use standard shell quoting and avoid piping file contents directly into evaluable contexts.

5. Insecure `date +%s` backup (Risk: Low)
Using `date +%s` for backups is standard, but in rapid cycle scenarios, files can overwrite each other if `runcycle.sh` is triggered twice in the same second.
Fix: Use `mktemp` for creating unique backups.

6. Missing `shellcheck` compliance (Risk: Low)
The script uses `local` variables and `set -euo pipefail` (in `recover`), but the main kernel script does not have strict error handling.
Fix: Add `set -euo pipefail` to the top of `kernel.sh`.

Recommended Fixes:

- Atomic Lock:
  lock() {
    local tmp_hash=$(mktemp)
    sha256sum "$(readlink -f "$0")" | cut -d' ' -f1 > "$tmp_hash"
    mv "$tmp_hash" "$SKILLDIR/.kernel-hash"
  }

- Path Validation in `recover` (in `runcycle.sh` content):
  # After extraction:
  if [[ "$filepath" != "$REPODIR"* ]]; then
    log "SECURITY ALERT: Attempted path traversal: $filepath"
    exit 1
  fi

- Strict Mode:
  Add `set -euo pipefail` to the top of `kernel.sh` and address any warnings revealed by `shellcheck`.
