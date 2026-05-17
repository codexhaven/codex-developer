#!/usr/bin/env bash
read_manifest() {
  local repodir="$1"
  local manifest=""
  [ -f "$repodir/.codex/phases.json" ] && manifest+=$(cat "$repodir/.codex/phases.json")
  [ -f "$repodir/.codex/project_brain.md" ] && manifest+=$(cat "$repodir/.codex/project_brain.md")
  [ -f "$repodir/.codex/goal.md" ] && manifest+=$(cat "$repodir/.codex/goal.md")
  echo "$manifest"
}
