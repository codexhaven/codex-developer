#!/usr/bin/env bash
# CODES-DEVELOPER ONE-COMMAND INSTALL

set -e

echo "╔══════════════════════════════════════╗"
echo "║   CODES-DEVELOPER INSTALLER          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check for Hermes
if ! command -v hermes &>/dev/null; then
  echo "Hermes not found. Installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Add uv to path for current session
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
  uv tool install hermes-agent
fi

# Clone or update
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
if [ -d "$SKILLDIR/.git" ]; then
  echo "Updating existing installation..."
  cd "$SKILLDIR" && git pull
else
  echo "Installing codex-developer..."
  mkdir -p "$(dirname "$SKILLDIR")"
  git clone https://github.com/YOUR_USERNAME/codex-developer.git "$SKILLDIR"
fi

# Make executable
chmod +x "$SKILLDIR"/*.sh "$SKILLDIR"/modules/*.sh 2>/dev/null || true

# Create .env template
mkdir -p "$HOME/.hermes"
if [ ! -f "$HOME/.hermes/.env" ]; then
  echo "GOOGLE_API_KEY=***" > "$HOME/.hermes/.env"
fi

# Lock kernel
bash "$SKILLDIR/kernel.sh" lock 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   INSTALLATION COMPLETE              ║"
echo "╚══════════════════════════════════════╝"
echo "Usage: ~/.hermes/skills/codex-developer/listen.sh 'your idea'"
