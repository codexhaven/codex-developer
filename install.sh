#!/usr/bin/env bash
# CODES-DEVELOPER V12.2 INSTALLER
set -euo pipefail

echo "=== CODES-DEVELOPER V12.2 INSTALLER ==="

# Dependency Check
for cmd in git curl python3 bash; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required dependency '$cmd' not found." >&2
        exit 1
    fi
done

# Check for Hermes
if ! command -v hermes &>/dev/null; then
    echo "Note: hermes-agent CLI not detected. Ensure Hermes environment is configured."
fi

# Clone or update
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
read -p "Enter GitHub repository owner (default: codex-builds): " repo_owner
repo_owner="${repo_owner:-codex-builds}"

if [ -d "$SKILLDIR/.git" ]; then
    echo "Updating existing installation to v12.2..."
    cd "$SKILLDIR" && git pull
else
    echo "Installing codex-developer v12.2 from $repo_owner..."
    mkdir -p "$(dirname "$SKILLDIR")"
    git clone "https://github.com/$repo_owner/codex-developer.git" "$SKILLDIR"
fi

# Set permissions
find "$SKILLDIR" -maxdepth 2 -name "*.sh" -exec chmod +x {} +

# Setup Config
mkdir -p "$HOME/.hermes"
if [ ! -f "$HOME/.hermes/.env" ]; then
    touch "$HOME/.hermes/.env"
    echo "Created $HOME/.hermes/.env. Ensure GOOGLE_API_KEY is defined."
fi

# Initialize Kernel with HITL lock
if [ -f "$SKILLDIR/kernel.sh" ]; then
    echo "Initializing v12.2 kernel with HITL enforcement..."
    bash "$SKILLDIR/kernel.sh" lock
else
    echo "Error: kernel.sh missing!" >&2
    exit 1
fi

echo "=== INSTALLATION COMPLETE (v12.2) ==="
echo "Wisdom Rule #38 initialized."
echo "Usage: $SKILLDIR/listen.sh 'your idea' /absolute/path/to/project"
