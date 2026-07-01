#!/usr/bin/env bash
# Codex Developer v12.4 — Install Script
set -euo pipefail
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven

echo "=== Codex Developer v12.4 Install ==="

SKILLDIR="${HOME}/.hermes/skills/codex-developer"

# Check dependencies
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git required"; exit 1; }
command -v hermes >/dev/null 2>&1 || { echo "WARN: hermes not found — AI features disabled"; }

# Set permissions
chmod +x "$SKILLDIR/listen.sh" "$SKILLDIR/runcycle.sh" 2>/dev/null || true
chmod +x "$SKILLDIR/sandbox/"*.sh 2>/dev/null || true
chmod +x "$SKILLDIR/modules/"*.sh 2>/dev/null || true

# Set git identity
git config --global user.name "Codex Developer" 2>/dev/null || true
git config --global user.email "codex@codexhaven.dev" 2>/dev/null || true
git config --global init.defaultBranch main 2>/dev/null || true
git config --global advice.defaultBranchName false 2>/dev/null || true

# Create .env template if missing
[ -f "$HOME/.hermes/.env" ] || {
  mkdir -p "$HOME/.hermes"
  cat > "$HOME/.hermes/.env" << 'ENV'
# Codex Developer Environment
GITHUB_TOKEN=
GITHUB_USER=codexhaven
OPENROUTER_KEY=
VERCEL_TOKEN=
ENV
  echo "Created ~/.hermes/.env — add your tokens"
}

echo ""
echo "Install complete."
echo "Usage: ~/.hermes/skills/codex-developer/listen.sh 'Build a...' ~/project-name"
echo "Rules active: $(grep -c '"type": "rule"' "$SKILLDIR/global-knowledge.jsonl" 2>/dev/null || echo 0)"
echo "Modules: $(ls "$SKILLDIR/modules" 2>/dev/null | wc -l)"
echo "Sandbox: $(ls "$SKILLDIR/sandbox" 2>/dev/null | wc -l)"
