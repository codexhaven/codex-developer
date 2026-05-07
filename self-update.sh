#!/usr/bin/env bash
SKILLDIR="${HOME}/.hermes/skills/codex-developer"
REPODIR="${HOME}/codex-builds"
LESSONS_FILE="${REPODIR}/.codex/lessons.jsonl"
PROPOSAL_FILE="${SKILLDIR}/proposals.md"

analyze() {
  echo "=== SELF-ANALYSIS ==="
  if [ ! -f "$LESSONS_FILE" ] || [ ! -s "$LESSONS_FILE"
