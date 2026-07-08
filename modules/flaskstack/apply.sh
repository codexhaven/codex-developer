#!/usr/bin/env bash
# FlaskStack Plugin — Assists Python web projects (Flask, Django, FastAPI)
# Steps aside if not a Python web project
set -euo pipefail
# CODES-DEVELOPER v12.6 — Codex Developer
# ctx: codexhaven

GOALFILE="${REPODIR}/.codex/goal.md"

IS_PYTHON_WEB=false

if grep -qiE "flask|django|fastapi|python web|wsgi|jinja" "$GOALFILE" 2>/dev/null; then
  IS_PYTHON_WEB=true
fi
if [ -f "$REPODIR/requirements.txt" ] && grep -qiE "flask|django|fastapi" "$REPODIR/requirements.txt" 2>/dev/null; then
  IS_PYTHON_WEB=true
fi
if [ -f "$REPODIR/app.py" ] || [ -f "$REPODIR/manage.py" ]; then
  IS_PYTHON_WEB=true
fi

if [ "$IS_PYTHON_WEB" = false ]; then
  : # silent step-aside
  exit 0
fi

echo "  Python web project detected. Assisting..."

# Inject Python web standards into goal
if ! grep -q "FlaskStack Standards" "$GOALFILE" 2>/dev/null; then
  cat >> "$GOALFILE" << 'STANDARDS'

## FlaskStack Standards (AUTO-APPLIED)

1. Framework: Flask/Django/FastAPI as specified
2. Language: Python 3.10+
3. Templates: Jinja2 (Flask/FastAPI) or Django Templates
4. Styling: Bootstrap 5 or Tailwind CSS (CDN or bundled)
5. Database: SQLite for dev, PostgreSQL for production
6. Structure: app.py + templates/ + static/ (Flask), project/app layout (Django)
7. Dependencies: Listed in requirements.txt with pinned versions
8. Testing: pytest
9. Security: python-dotenv for env vars, no hardcoded secrets

STANDARDS
  echo "  Standards injected into goal.md"
fi

# Create missing essentials
if [ ! -f "$REPODIR/requirements.txt" ]; then
  touch "$REPODIR/requirements.txt"
  echo "  Created: requirements.txt (empty — fill with deps)"
fi

if [ ! -f "$REPODIR/.gitignore" ]; then
  cat > "$REPODIR/.gitignore" << 'GITIGNORE'
__pycache__/
*.pyc
.env
venv/
.venv/
*.db
*.sqlite3
GITIGNORE
  echo "  Created: .gitignore"
fi

echo "  FlaskStack assistance complete."
