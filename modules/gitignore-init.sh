#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# gitignore-init.sh — Ensures .gitignore exists with proper exclusions
# Hook: before-build

GITIGNORE="${REPODIR}/.gitignore"

# Always ensure these are ignored
cat > "$GITIGNORE" << 'IGNORE'
# Codex build artifacts
.codex/
reviews/
CHANGELOG.md

# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/

# Node
node_modules/
.next/

# Env
.env
.env.local
*.log
IGNORE

echo "  .gitignore updated (reviews + changelog excluded)"
