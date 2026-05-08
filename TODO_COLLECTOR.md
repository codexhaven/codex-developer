/data/data/com.termux/files/home/.hermes/skills/codex-developer/runcycle.sh:- Write complete working code. No TODOs. No placeholders.
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:# MAINTENANCE MODE: Auto-scans for TODOs and updates goal.md
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:TODOS_FILE="${REPODIR}/TODO_COLLECTOR.md"
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:# 1. Collect all TODOs safely
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:grep -rE "TODO|FIXME" "$REPODIR" --exclude-dir=.git --exclude-dir=.codex > "$TODOS_FILE"
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:# 2. Check if TODOs found
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:if [ ! -s "$TODOS_FILE" ]; then
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:    echo "[MAINTENANCE] No TODOs found."
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:TODO_CONTENT=$(cat "$TODOS_FILE")
/data/data/com.termux/files/home/.hermes/skills/codex-developer/modules/maintenance-mode.sh:$TODO_CONTENT"
