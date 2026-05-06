Finding | Risk: High | Fix: Use `with open(..., 'a') as f:` inside the loop, but verify the file existence and handle concurrency. Currently, the script opens and closes `GLOBAL_FILE` inside the loop for every single task, which is inefficient and creates a race condition if multiple processes (or cron jobs) run this concurrently. Use a file lock or consolidate writing.

Finding | Risk: Medium | Fix: The `try...except:` block in the JSON loader is too broad (`pass`). This silently ignores malformed files. Log errors to `stderr` or a log file instead of just ignoring them so you know if data corruption is occurring.

Finding | Risk: Medium | Fix: Hardcoded paths. While `os.path.expanduser` is used, the script assumes the structure of `codex-builds`. Use a config file or environment variables to define paths.

Finding | Risk: Low | Fix: The pattern detection is very loose (`task[:50]`). This might cause false positives where unrelated tasks are grouped together if they happen to share the same prefix. Include more metadata (like error type or tool used) in the JSON check.

Finding | Risk: Low | Fix: No cleanup mechanism. The script adds constraints indefinitely. Over time, `global-knowledge.jsonl` will grow large and slow down processing. Implement a policy to purge expired or low-priority constraints.

Finding | Risk: Low | Fix: Security: The script reads/writes files in the user's home directory. Ensure file permissions are restricted (e.g., `chmod 600`) to prevent unauthorized access or injection into the constraint engine.
