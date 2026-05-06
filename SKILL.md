---
name: codex-developer
description: >
  Autonomous software factory (v11.0.0). Natural language interface with
  persona-aware intent detection. Supports NEW generation, REVIEW analysis,
  EXISTING enhancement, PATCH surgical fixes, and SED targeted edits.
version: 11.0.0
metadata:
  required_toolsets: [terminal, file, web]
---

## Architecture

### Interface (listen.sh) — The Entry Point
- Takes natural language requests
- Detects persona (PRODUCT, EXPERT, LEARNER) based on request phrasing
- Routes to REVIEW, NEW, CONTINUATION, EXISTING, or FIX modes
- Clones GitHub repos automatically when URLs detected
- Generates per-file reviews and SUMMARY.md with findings display
- Interactive fix approval workflow

### Orchestrator (runcycle.sh) — The Engine
- Multi-mode: NEW files, PATCH (full file rewrite), SED (targeted edits)
- Persona-aware prompts injected into every Hermes call
- Path containment security — refuses to write outside REPODIR
- Syntax verification with rollback on failure
- Global knowledge injection across projects

## Personas

| Persona | Target | Behavior |
|---|---|---|
| PRODUCT | Non-coders | Brief, results-oriented, hides technical logs |
| EXPERT | Developers | Deep logic, architectural reasoning |
| LEARNER | Beginners | Step-by-step explanations |

Detected automatically from request phrasing. Persists through all cycles.

## Modes

| Mode | Trigger | What It Does |
|---|---|---|
| NEW | Empty project or "build a..." | Plans files, builds from scratch |
| REVIEW | "Review/audit/scan" | Scans every file, per-file reviews, SUMMARY.md, interactive fix menu |
| EXISTING | Has code, wants changes | Understands architecture, plans changes, builds |
| CONTINUATION | Unfinished queue | Resumes where it left off |
| FIX | "Fix the..." | Targeted SED/PATCH on specific files |
| CLONE | GitHub URL in request | Clones repo, then REVIEW or EXISTING |

## How to Request

- **New project:** `listen.sh "Build a [thing]" ~/new-folder`
- **Existing project:** `listen.sh "Add [feature]" ~/existing-project`
- **Fix something:** `listen.sh "Fix [problem]" ~/project`
- **Review:** `listen.sh "Review [project] for [issues]" ~/project`
- **Clone + Review:** `listen.sh "Review https://github.com/user/repo for bugs"`
- **Continue:** Just run on the same project — it auto-resumes

## Recovery

```bash
# Reset state
truncate -s 0 ~/codex-builds/.codex/build-queue.txt
truncate -s 0 ~/codex-builds/.codex/build-done.txt
echo '{"cycle":0}' > ~/codex-builds/.codex/state.json

# Rebuild from kernel
bash ~/.hermes/skills/codex-developer/kernel.sh recover

# Start fresh
~/.hermes/skills/codex-developer/listen.sh "Build a calculator app"
