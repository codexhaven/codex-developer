#!/usr/bin/env bash
# github-push.sh — Push built project to GitHub
# Hook: after-all-done
set -euo pipefail

[ -f "$HOME/.hermes/.env" ] && set -a && source "$HOME/.hermes/.env" && set +a

PROJECT="${1:-$REPODIR}"
GITHUB_USER="${GITHUB_USER:-codex-developer}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN not set. Skipping GitHub push."
  exit 0
fi

cd "$PROJECT"
REPO_NAME=$(basename "$PROJECT")

# Init git if needed
[ -d .git ] || git init
git config user.email "codex@github"
git config user.name "Codex Developer"

# Add all files
git add -A
git commit -m "Build $(date +%Y-%m-%d_%H:%M)" 2>/dev/null || true

# Create repo on GitHub and push
echo "Pushing to GitHub: $GITHUB_USER/$REPO_NAME"

# Create remote if not exists
if ! git remote | grep -q origin; then
  git remote add origin "https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
fi

# Push — create repo if it doesn't exist via API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}")

if [ "$HTTP_CODE" = "404" ]; then
  echo "Creating repository: $REPO_NAME"
  curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"${REPO_NAME}\",\"private\":true,\"auto_init\":false}" > /dev/null
fi

git push -u origin master --force 2>&1
echo "LIVE: https://github.com/${GITHUB_USER}/${REPO_NAME}"
