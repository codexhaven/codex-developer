#!/usr/bin/env bash
# HEALER MODULE v2 — Orchestrator for split healer modules
# Traces the exact failure chain, fixes the source, re-verifies
set -euo pipefail
# CODES-DEVELOPER v12.4 — Codex Developer
# ctx: codexhaven

SKILLDIR="${HOME}/.hermes/skills/codex-developer"
log_msg() { echo -e "\033[35m[HEALER]\033[0m $1"; }

# Step 1: Capture failure context
log_msg "Starting healing cycle..."
bash "${SKILLDIR}/modules/healer_trace.sh"

# Step 2: Identify root cause
log_msg "Analyzing root cause..."
bash "${SKILLDIR}/modules/healer_analyze.sh"

# Step 3: Apply the fix
log_msg "Applying fix..."
bash "${SKILLDIR}/modules/healer_fix.sh"

# Step 4: Reset state
log_msg "Resetting state..."
bash "${SKILLDIR}/modules/healer_reset.sh"

log_msg "Healing cycle completed."
