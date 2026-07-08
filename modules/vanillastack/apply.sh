#!/usr/bin/env bash
# VanillaStack Plugin — Assists plain HTML/CSS/JS and Bootstrap projects
# Steps aside if not a static web project
set -euo pipefail
# CODES-DEVELOPER v12.6 — Codex Developer
# ctx: codexhaven

GOALFILE="${REPODIR}/.codex/goal.md"

echo "PLUGIN: vanillastack — Checking for static web project..."

IS_STATIC=false

if grep -qiE "html|css|javascript|bootstrap|jquery|static site|landing page|vanilla" "$GOALFILE" 2>/dev/null; then
  # Only if NOT also a Next.js/React/Flask project
  if ! grep -qiE "next\.js|react|flask|django|tailwind|supabase" "$GOALFILE" 2>/dev/null; then
    IS_STATIC=true
  fi
fi
if [ -f "$REPODIR/index.html" ] && [ ! -f "$REPODIR/package.json" ]; then
  IS_STATIC=true
fi

if [ "$IS_STATIC" = false ]; then
  : # silent step-aside
  exit 0
fi

echo "  Static web project detected. Assisting..."

if ! grep -q "VanillaStack Standards" "$GOALFILE" 2>/dev/null; then
  cat >> "$GOALFILE" << 'STANDARDS'

## VanillaStack Standards (AUTO-APPLIED)

1. Structure: index.html + css/ + js/ + assets/
2. Styling: Bootstrap 5 (CDN) or plain CSS
3. JavaScript: Vanilla JS or jQuery (CDN), no build step
4. Responsive: Mobile-first with Bootstrap grid or CSS media queries
5. No server required — works directly in browser
6. Keep dependencies CDN-based, no npm needed

STANDARDS
  echo "  Standards injected into goal.md"
fi

# Create folder structure
mkdir -p "$REPODIR/css" "$REPODIR/js" "$REPODIR/assets" 2>/dev/null
[ ! -f "$REPODIR/css/style.css" ] && touch "$REPODIR/css/style.css" && echo "  Created: css/style.css"
[ ! -f "$REPODIR/js/main.js" ] && touch "$REPODIR/js/main.js" && echo "  Created: js/main.js"

if [ ! -f "$REPODIR/.gitignore" ]; then
  cat > "$REPODIR/.gitignore" << 'GITIGNORE'
.DS_Store
*.log
.env
GITIGNORE
  echo "  Created: .gitignore"
fi

echo "  VanillaStack assistance complete."
