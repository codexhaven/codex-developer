#!/usr/bin/env bash
# Plugin Runner — Auto-discovers and runs plugins by hook
SKILLDIR="${HOME}/.hermes/skills/codex-developer"

run_plugins() {
  local hook="$1"
  local plugin_file="${SKILLDIR}/modules/plugins.json"
  [ ! -f "$plugin_file" ] && return

  python3 -c "
import json, os, subprocess
hook = '$hook'
manifest = json.load(open('$plugin_file'))
for name, plugin in manifest.get('plugins', {}).items():
    if plugin.get('when') == hook:
        script = os.path.join('$SKILLDIR/modules', plugin['script'])
        if os.path.exists(script):
            print(f'PLUGIN: {name} — {plugin.get(\"description\",\"\")}')
            subprocess.run(['bash', script], check=False)
" 2>/dev/null || true
}

# Run if called directly
[ "${1:-}" = "run" ] && run_plugins "${2:-}"
