#!/usr/bin/env bash
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven
# Plugin: Vercel Deploy
# Hook: after-all-done
# v3 — Scoped vercel.json, real token support
set -e
[ -f "$HOME/.hermes/.env" ] && set -a && source "$HOME/.hermes/.env" && set +a
PROJECT="${1:-$REPODIR}"

echo "PLUGIN: vercel-deploy — Preparing deployment..."
cd "$PROJECT"

# Detect what services the project actually uses
NEEDS_CLERK=$( { grep -l "clerk" package.json 2>/dev/null; grep -rl "clerk" app/ lib/ 2>/dev/null; } | wc -l)
NEEDS_SUPABASE=$( { grep -l "supabase" package.json 2>/dev/null; grep -rl "supabase" app/ lib/ 2>/dev/null; } | wc -l)
NEEDS_STRIPE=$( { grep -l "stripe" package.json 2>/dev/null; grep -rl "stripe" app/ lib/ 2>/dev/null; } | wc -l)

if [ "$NEEDS_CLERK" -gt 0 ] || [ "$NEEDS_SUPABASE" -gt 0 ] || [ "$NEEDS_STRIPE" -gt 0 ]; then
  echo '{ "buildCommand": "next build", "installCommand": "npm install", "framework": "nextjs", "env": {' > vercel.json
  SEP=""
  [ "$NEEDS_CLERK" -gt 0 ] && printf '%s"CLERK_SECRET_KEY": "@clerk-secret-key"' "$SEP" >> vercel.json && SEP="," && printf '\n' >> vercel.json
  [ "$NEEDS_SUPABASE" -gt 0 ] && printf '%s"NEXT_PUBLIC_SUPABASE_URL": "@supabase-url"' "$SEP" >> vercel.json && SEP="," && printf '\n' >> vercel.json
  echo '} }' >> vercel.json
  echo "  vercel.json created (scoped)"
else
  echo "  No services detected — skipping vercel.json"
  rm -f vercel.json
fi

# Deploy
if [ -n "${VERCEL_TOKEN:-}" ]; then
  vercel link --yes --token "$VERCEL_TOKEN" 2>/dev/null || true
  vercel env pull --yes --token "$VERCEL_TOKEN" 2>/dev/null || true
  echo "  Deploying..."
  vercel deploy --prod --yes --token "$VERCEL_TOKEN" 2>&1 | tee /tmp/vercel-out.txt
  LIVE_URL=$(grep -oE 'https://[a-zA-Z0-9._-]+\.vercel\.app' /tmp/vercel-out.txt | head -1)
  [ -n "$LIVE_URL" ] && echo "  LIVE: $LIVE_URL" || echo "  Done. Check dashboard."
else
  echo "  No VERCEL_TOKEN. Run: cd $PROJECT && vercel deploy --prod"
fi
