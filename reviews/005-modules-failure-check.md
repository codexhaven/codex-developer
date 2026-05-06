Finding | Risk: Critical/High/Medium/Low | Fix
--- | --- | ---
Arbitrary Command/Shell Injection | Critical | The script uses f-strings in `python3 -c` to embed raw file content and paths directly into shell-evaluated strings. If a file name or pattern contains `';`, it allows remote code execution. Use `argparse` or environment variables to pass data to Python, not interpolation.
Missing Error Handling | Medium | The `try...except: pass` block silently swallows all errors (including `FileNotFound`, `PermissionError`, or syntax errors in `failure-patterns.json`), making the tool impossible to debug. Log errors to `stderr`.
Performance/Scalability | Low | The script reads the entire file into memory using `open().read()`. For large files, this will cause memory exhaustion. Use a streaming line-by-line reader.
Insecure Execution | High | Calling `"${1:-check}"` directly allows execution of any function in the script scope if an attacker controls arguments. Use a whitelist of allowed functions.
Dependency Risk | Low | Hardcoding `SKILLDIR` limits portability. Use a configuration file or environment variable with a safe default.
