Refactor codex-developer into a platform-agnostic standalone Python app.
- listen.sh → monitor.py using watchdog
- runcycle.sh → engine.py with native Python
- Replace Hermes tools with pathlib, subprocess, sqlite3
- Use config.yaml instead of hardcoded paths
- Structure: src/monitor.py, src/engine.py, src/db.py, src/utils.py
- Include README.md, requirements.txt, config.yaml
