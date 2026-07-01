import sys

with open('listen.sh', 'r') as f:
    lines = f.readlines()

# Find the lines we need to replace.
# We'll look for the pattern:
# if [ $build_exit -eq 0 ] && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
#   if [ -n "${GITHUB_TOKEN:-}" ]; then
#     echo "Pushing to GitHub..."
#     bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
#   else
#     echo "GITHUB_TOKEN not set. Skipping push."
#   fi
# fi
#
# and the similar one later.

def replace_block(start_idx, lines):
    # We'll replace from the line with "if [ $build_exit -eq 0 ] && [ -f \"${SKILLDIR}/modules/github-push.sh\" ]; then"
    # up to the corresponding fi after the else block.
    # For simplicity, we'll replace a known chunk.
    # Instead, we'll do a simple string replace for the two occurrences.
    pass

# Since the file is not huge, we can do a string replace for the whole block.
content = ''.join(lines)
# First pattern
pattern1 = '''  if [ $build_exit -eq 0 ] && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      echo "Pushing to GitHub..."
      bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
    else
      echo "GITHUB_TOKEN not set. Skipping push."
    fi
  fi'''
replacement1 = '''  if [ $build_exit -eq 0 ] && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      if [ "${AUTO_YES:-false}" = "true" ]; then
        echo "Warning: AUTO_YES is set, but pushing to GitHub is a destructive action."
        echo -n "Do you want to push to GitHub? (y/n): "
        read -r answer
        if [ "$answer" != "y" ]; then
          echo "Skipping push."
        else
          echo "Pushing to GitHub..."
          bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
        fi
      else
        echo "Pushing to GitHub..."
        bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
      fi
    else
      echo "GITHUB_TOKEN not set. Skipping push."
    fi
  fi'''
content = content.replace(pattern1, replacement1)

# Second pattern
pattern2 = '''  elif grep -q "DONE" "$REPODIR/.codex/build.log" 2>/dev/null && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    # Build completed successfully (DONE) even if exit code was non-zero
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      echo "Build complete. Pushing to GitHub..."
      bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
    else
      echo "GITHUB_TOKEN not set. Set it in ~/.hermes/.env to enable auto-push."
    fi
  elif'''
replacement2 = '''  elif grep -q "DONE" "$REPODIR/.codex/build.log" 2>/dev/null && [ -f "${SKILLDIR}/modules/github-push.sh" ]; then
    # Build completed successfully (DONE) even if exit code was non-zero
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      if [ "${AUTO_YES:-false}" = "true" ]; then
        echo "Warning: AUTO_YES is set, but pushing to GitHub is a destructive action."
        echo -n "Do you want to push to GitHub? (y/n): "
        read -r answer
        if [ "$answer" != "y" ]; then
          echo "Skipping push."
        else
          echo "Build complete. Pushing to GitHub..."
          bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
        fi
      else
        echo "Build complete. Pushing to GitHub..."
        bash "${SKILLDIR}/modules/github-push.sh" "$REPODIR"
      fi
    else
      echo "GITHUB_TOKEN not set. Set it in ~/.hermes/.env to enable auto-push."
    fi
  elif'''
content = content.replace(pattern2, replacement2)

with open('listen.sh', 'w') as f:
    f.write(content)
print('Patched listen.sh')
