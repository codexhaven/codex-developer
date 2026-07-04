#!/usr/bin/env bash
# React/Next.js Stack Assistant
set -euo pipefail
# ctx: codexhaven

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && (pwd -P 2>/dev/null || pwd))"
REPODIR="${CODEX_REPO:-${HOME}/projects}"

log_msg() { echo -e "\033[36m[REACT]\033[0m $1"; }

if [ -f "$REPODIR/package.json" ] && grep -q '"react"' "$REPODIR/package.json" 2>/dev/null; then
  log_msg "React project detected. Ensuring Next.js 16+ configuration..."

  # Ensure tsconfig.json with @/ paths
  if [ ! -f "$REPODIR/tsconfig.json" ]; then
    log_msg "Creating tsconfig.json..."
    cat > "$REPODIR/tsconfig.json" << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG
  fi
fi
