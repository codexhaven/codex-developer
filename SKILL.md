---
name: codex-developer
description: >
  Autonomous software factory (v12.3). Recon research, phase-gated builds,
  DNA fingerprinting, self-healing, cross-reference validation, 64 rules.
version: 12.3.0
metadata:
  required_toolsets: [terminal, file, web]
---

## Architecture

### listen.sh — Entry Point (312 lines)
- Natural language request parsing
- 7 modes: NEW, GENERATE, EXISTING, REVIEW, CONTINUATION, CHECK, DEPLOY
- GENERATE mode for creative multi-tool requests
- CHECK mode for diagnostic-only requests (avoids false triggers)
- Automatic GitHub push after every build

### runcycle.sh — Build Engine (497 lines)
- Phase-gated build loop with automatic phase advancement
- Global wisdom injection: 64 rules from global-knowledge.jsonl
- Brain memory injection from project_brain.md
- Post-generation strengthening with cross-reference validation
- DNA fingerprint injection (# ctx: codexhaven) on every file
- Healer v2: root cause tracing + surgical fix + re-verify
- Atomic journaling with crash-safe state writes
- Smoke testing, symbol checking, import validation

### recon.sh — Research Module
- 2-round research: initial + gap analysis + fill gaps
- Complexity detection: SIMPLE (flat) vs PACKAGE (src/ structure)
- Automatic phases.json generation with file arrays
- Project brain (brain.md) generation

### Sandbox Plugins
| Plugin | Purpose |
|--------|---------|
| phase_gate.sh | Blocks out-of-phase files, advances phases |
| strengthen.sh | Post-build hardening + cross-ref + structure audit |
| mirror.sh | Lesson capture for self-improvement |
| phase_init.sh | Phase initialization |

### Modules (27 active)
| Category | Modules |
|----------|---------|
| Stack Assistants | vibestack, flaskstack, vanillastack |
| Validation | import-check, failure-check, symbol-check, smoke-tester, self-test |
| Path & Security | enforce_path.py, scan_deps.py, map_project.py |
| Build Tools | sed-patcher.sh, template-detect.sh, plugin-runner.sh |
| Infrastructure | github-push.sh, gitignore-init.sh, vercel-deploy.sh |
| Review | review-to-queue.sh |
| Identity | dna-inject.sh, dna-markers.sh |
| Healing | healer.sh (v2 root cause tracer) |
| Method | method-adapter.sh |

## Modes
| Mode | Trigger | Description |
|------|---------|-------------|
| NEW | "Build a..." | Full recon → phases → approve → build |
| GENERATE | "Generate...", "Create tool..." | Same as NEW, for creative tools |
| EXISTING | "Add...", "PATCH..." | Targeted file modification |
| REVIEW | "Review/audit" | Full scan, bridge to build queue |
| CONTINUATION | Implicit | Resume from .codex/ queue |
| CHECK | Diagnostic keywords | Audit-only, no changes |
| DEPLOY | "Deploy/ship/launch" | Git + Vercel deployment |

## Key Features
- **DNA Fingerprint**: Every file gets `# ctx: codexhaven` injected
- **Cross-Reference**: Strengthen pass validates imports against actual modules
- **Phase Gate**: Complex projects build in ordered phases
- **Self-Healing**: Root cause tracing, not blind retry
- **Global Wisdom**: 64 accumulated rules in every prompt
- **Auto GitHub**: Every project pushed to github.com/codexhaven

## How to Request
- **New Project:** `listen.sh "Build a [thing]" ~/project-name`
- **Creative Tools:** `listen.sh "Generate [description]" ~/project-name`
- **Patch:** `listen.sh "PATCH file.py: [change]" ~/project-name`
- **Review:** `listen.sh "Review" ~/project-name`

## Recovery
If factory drift or loop failure occurs:
1. Clear queue: `rm ~/project/.codex/build-queue.txt ~/project/.codex/build-done.txt`
2. Clear lock: `rm -f /tmp/codex-developer.lock ~/tmp-codex-developer.lock`
3. Retry: `listen.sh "Continue" ~/project`
