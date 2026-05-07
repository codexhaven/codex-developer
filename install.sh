#!/usr/bin/env bash
# CODES-DEVELOPER ONE-COMMAND INSTALL
set -euo pipefail

echo "=== CODES-DEVELOPER INSTALLER ==="

# Dependency Check
for cmd in git curl python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required dependency '$cmd' not found." >&2
        exit 1
    fi
done

# Check for Hermes with confirmation
if ! command -v hermes &>/dev/null; then
    read -p "Hermes not found. Install hermes-agent via uv? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        uv tool install hermes-agent
    else
        echo "Skipping Hermes install. Some features will be disabled."
    fi
fi

# Clone or update
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
read -p "Enter GitHub repository owner (default: codex-builds): " repo_owner
repo_owner="${repo_owner:-codex-builds}"

if [ -d "$SKILLDIR/.git" ]; then
    echo "Updating existing installation..."
    cd "$SKILLDIR" && git pull
else
    echo "Installing codex-developer from $repo_owner..."
    mkdir -p "$(dirname "$SKILLDIR")"
    git clone "https://github.com/$repo_owner/codex-developer.git" "$SKILLDIR"
fi

# Set permissions safely
find "$SKILLDIR" -maxdepth 2 -name "*.sh" -exec chmod +x {} +

# Setup .env
mkdir -p "$HOME/.hermes"
if [ ! -f "$HOME/.hermes/.env" ]; then
    touch "$HOME/.hermes/.env"
    echo "Created $HOME/.hermes/.env. Please add your GOOGLE_API_KEY."
fi

# Initialize kernel
if [ -f "$SKILLDIR/kernel.sh" ]; then
    bash "$SKILLDIR/kernel.sh" lock
else
    echo "Warning: kernel.sh not found. Skipping initialization." >&2
fi

echo "=== INSTALLATION COMPLETE ==="
echo "Usage: $SKILLDIR/listen.sh 'your idea'"
