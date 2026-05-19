#!/usr/bin/env bash
# VibeStack Plugin v3 — Assistant, not Gatekeeper
# Hook: before-build
# If the project uses VibeStack tools → inject standards and config
# If not → step aside silently, let another plugin handle it
set -euo pipefail

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
GOALFILE="${REPODIR}/.codex/goal.md"

: # silent

# --- 1. DETECT if this is a VibeStack-compatible project ---
# VibeStack handles: Next.js, React, Tailwind, Shadcn, Supabase, Clerk, Vercel
IS_VIBESTACK=false

if [ -f "$REPODIR/package.json" ]; then
  # Has package.json — check if it uses VibeStack tools
  if grep -qE '"next"|"react"|"tailwindcss"|"@supabase|"@clerk|"lucide-react"' "$REPODIR/package.json" 2>/dev/null; then
    IS_VIBESTACK=true
  fi
fi

# Also check goal.md for VibeStack keywords
if grep -qiE "next\.js|nextjs|tailwind|shadcn|supabase|clerk|vercel|react" "$GOALFILE" 2>/dev/null; then
  IS_VIBESTACK=true
fi

if [ "$IS_VIBESTACK" = false ]; then
  : # silent step-aside
  : # silent
  exit 0
fi

echo "  VibeStack-compatible project detected. Assisting..."

# --- 2. INJECT STANDARDS INTO GOAL ---
if ! grep -q "VibeStack Standards" "$GOALFILE" 2>/dev/null; then
  cat >> "$GOALFILE" << 'STANDARDS'

## VibeStack Standards (AUTO-APPLIED)

1. Framework: Next.js 16+ with App Router
2. Language: TypeScript (strict)
3. Styling: Tailwind CSS (dark mode default)
4. Components: Shadcn UI
5. Backend/Database: Supabase (use @supabase/supabase-js, NOT bare 'supabase')
6. Auth: Clerk (unless request says no auth)
7. Charts: Recharts
8. Package Manager: pnpm
9. Platform: Android/Termux compatible — Next.js 16.x with WASM fallback
10. Never use bare 'supabase' CLI package — use @supabase/supabase-js

STANDARDS
  echo "  Standards injected into goal.md"
fi

# --- 3. WARN ABOUT BANNED PACKAGES (but don't block) ---
if [ -f "$REPODIR/package.json" ]; then
  if grep -q '"supabase"' "$REPODIR/package.json" 2>/dev/null && ! grep -q '"@supabase/supabase-js"' "$REPODIR/package.json" 2>/dev/null; then
    echo "  WARNING: 'supabase' CLI package detected. Use @supabase/supabase-js instead."
  fi

  NATIVE_BANNED=("canvas" "sharp" "puppeteer" "playwright" "node-gyp" "bcrypt" "sqlite3")
  for pkg in "${NATIVE_BANNED[@]}"; do
    if grep -q "\"$pkg\"" "$REPODIR/package.json" 2>/dev/null; then
      echo "  WARNING: Native package '$pkg' will fail on Android ARM64."
    fi
  done
fi

# --- 4. CREATE MISSING CONFIG FILES ---
if [ -f "$REPODIR/package.json" ]; then
  if [ ! -f "$REPODIR/tsconfig.json" ]; then
    cat > "$REPODIR/tsconfig.json" << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG
    echo "  Created: tsconfig.json"
  fi

  if [ ! -f "$REPODIR/.gitignore" ]; then
    cat > "$REPODIR/.gitignore" << 'GITIGNORE'
node_modules/
.next/
.env.local
.env
*.log
.cache/
dist/
build/
core
.vercel
GITIGNORE
    echo "  Created: .gitignore"
  fi
fi

echo "  VibeStack assistance complete."
