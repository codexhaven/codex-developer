#!/usr/bin/env bash
set -euo pipefail
# ctx: codexhaven
# =============================================================================
# CODES-DEVELOPER v12.6 — Stress-tested — Build Engine
# CODES-DEVELOPER v12.5 — Stress-tested — Build Engine
# Modes: NEW | PATCH (SED fallback for large files)
# Guardrails: Self-protection, path containment, syntax verification, rollback
# Phase Gate: check_module_permission + advance_phase_if_complete
# Brain Memory: project_brain.md injected into every prompt
# =============================================================================

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -P 2>/dev/null || pwd))"
REPODIR="${CODEX_REPO:-${HOME}/projects}"
GOALFILE="${REPODIR}/.codex/goal.md"
STATEFILE="${REPODIR}/.codex/state.json"
QUEUEFILE="${REPODIR}/.codex/build-queue.txt"
DONEFILE="${REPODIR}/.codex/build-done.txt"
LESSONSFILE="${REPODIR}/.codex/lessons.md"
LESSONSJSONL="${REPODIR}/.codex/lessons.jsonl"
GLOBAL_KNOWLEDGE="${SKILLDIR}/global-knowledge.jsonl"
MAXLINES="${MAX_LINES:-120}"
MAX_RETRIES=3

# --- Locking ---
LOCKFILE="${TMPDIR:-/tmp}/codex-developer.lock"
# Use flock directly on file descriptor (avoids touch/flock race condition)
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "[SKIP] Another instance is still running." >&2
    exit 0
fi
release_lock() {
    flock -u 9
    rm -f "$LOCKFILE"
}