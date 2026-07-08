---
name: codex-developer
description: >
  Autonomous software factory (v12.6). Domain-aware recon research, phase-gated builds,
  DNA fingerprinting, 4-step self-healing, cross-reference validation, contract enforcement,
  76 global rules, auto GitHub push, stack plugin system.
version: 12.6.0
metadata:
  required_toolsets: [terminal, file, web]
  platforms: [linux, macos, android-termux]
  languages: [bash, python, javascript, typescript]
---

## Architecture

### listen.sh -- Entry Point (500+ lines)
- Natural language request parsing with 8-mode detection
- Mode detection: NEW | GENERATE | EXISTING | DIRECT | REVIEW | CONTINUATION | CHECK | DEPLOY
- Platform-agnostic (Ubuntu/macOS/Android) with dynamic path detection
- Automatic capability matching against project capabilities.json
- GitHub push integration after successful builds
- Unfinished build detection and resume prompts

### runcycle.sh -- Build Engine (840+ lines)
- Phase-gated build loop with automatic phase advancement
- Global wisdom injection: 76 rules from global-knowledge.jsonl with domain filtering
- Brain memory injection from project_brain.md
- Contract enforcement: AST-based function signature validation
- Post-generation strengthening with cross-reference validation
- DNA fingerprint injection (# ctx: codexhaven) on every file
- 4-step healer: trace -> analyze -> fix -> reset (triggered after 3 failures)
- Method adaptation: 4-tier fallback prompt strategies
- Atomic journaling with crash-safe state writes
- Smoke testing, symbol checking, import validation
- Breaking change detection via swarm --guard

### recon.sh -- Research Module (222 lines)
- Domain-aware architecture design
- Real-world workflow analysis before code generation
- Contract generation with function signatures, imports, phases
- Dependency graph generation
- project_brain.md generation
- Auto-alignment of modules and phases

### architect.sh -- Phase Gate Keeper (193 lines)
- Contract validation and alignment
- Phase gate enforcement (blocks out-of-phase files)
- Phase advancement when all files complete
- Resume from previous session
- Class naming validation

### strengthen.sh -- Hardening Engine (195 lines)
- Multi-pass file hardening with LLM
- Import cross-reference validation
- Contract compliance checking
- Quality gate: only accept >5% improvement or import fixes
- Post-build structure audit + flattening

## Swarm Orchestrator (swarm.sh)
- --from-violations: Mine contract violations for new dependencies
- --guard: Breaking change detection and dependent rebuilds
- --expand: Queue unbuilt contract files
- --routes: Auto-generate entry points
- --readme: Queue README generation

## Healer Pipeline (4-step)
| Step | Module | Purpose |
|------|--------|---------|
| 1 | healer_trace.sh | Capture failure context (logs, cycles, queue) |
| 2 | healer_analyze.sh | LLM root cause analysis with retry |
| 3 | healer_fix.sh | Surgical fix application with validation |
| 4 | healer_reset.sh | State reset, mark heal_attempted |

## Stack Plugins
| Plugin | Detects | Assists With |
|--------|---------|-------------|
| vibestack | package.json, Next.js | Next.js 16 + TypeScript + Tailwind + Shadcn + Supabase |
| flaskstack | requirements.txt, Flask | Flask/FastAPI + SQLAlchemy + Pydantic |
| vanillastack | No framework | Static HTML/CSS/JS with patterns.json templates |

## Modules (32 active)
| Category | Modules | Purpose |
|----------|---------|---------|
| Validation | import-check.sh, contract-import-check.sh, failure-check.sh, symbol-check.sh, smoke-tester.sh, self-test.sh | Multi-layer validation |
| Path & Security | enforce_path.py, scan_deps.py, map_project.py | Path containment, dependency scanning, project mapping |
| Build Tools | sed-patcher.sh, template-detect.sh, add_path_header.sh, method-adapter.sh | Fallback patching, template detection, headers |
| Infrastructure | github-push.sh, gitignore-init.sh, vercel-deploy.sh | GitHub push, .gitignore, Vercel deploy |
| Review | review-to-queue.sh | Bridge review findings to build queue |
| Identity | dna-inject.sh | DNA fingerprint injection |

## 8 Modes
| Mode | Trigger | Description |
|------|---------|-------------|
| NEW | "Build a..." | Full recon -> phases -> approve -> build |
| GENERATE | "Generate...", "Create tool..." | Same as NEW, for creative tools |
| EXISTING | "Add...", "PATCH..." | Targeted file modification |
| DIRECT | Explicit file paths | Direct file build with path extraction |
| REVIEW | "Review/audit" | Full scan, bridge to build queue |
| CONTINUATION | Implicit | Resume from .codex/ queue |
| CHECK | Diagnostic keywords | Audit-only, no changes |
| DEPLOY | "Deploy/ship/launch" | Git + Vercel deployment |

## Global Knowledge System
- 76 accumulated rules in global-knowledge.jsonl
- JSON Lines format: {"type": "rule", "rule": "...", "priority": N, "domains": [...]}
- Domain filtering: rules apply only to matching project types
- Priority-based sorting (higher = more important)
- Auto-generated from lesson-analyzer.py and opportunity-analyzer.py

## Key Features
- **DNA Fingerprint**: Every file gets `# ctx: codexhaven` injected
- **Cross-Reference**: Strengthen pass validates imports against actual modules
- **Phase Gate**: Complex projects build in ordered phases
- **Self-Healing**: 4-step root cause tracing, not blind retry
- **Contract Enforcement**: AST validation of function signatures
- **Global Wisdom**: 76 accumulated rules in every prompt
- **Method Adaptation**: 4-tier fallback when LLM returns empty
- **Auto GitHub**: Every project pushed to github.com/codexhaven

## How to Request
```bash
# New project
listen.sh "Build a [thing]" ~/project-name

# Creative tools
listen.sh "Generate [description]" ~/project-name

# Patch existing
listen.sh "PATCH file.py: [change]" ~/project-name

# Review
listen.sh "Review" ~/project-name

# Continue
listen.sh "Continue" ~/project-name
```

## Recovery
```bash
# Clear queue
rm ~/project/.codex/build-queue.txt ~/project/.codex/build-done.txt

# Clear lock
rm -f /tmp/codex-developer.lock ~/tmp-codex-developer.lock

# Retry
listen.sh "Continue" ~/project
```

## Self-Evolution
```bash
# Scan for improvement opportunities
self-update.sh --analyze

# Approve and inject a rule
self-update.sh --approve <proposal-id>
```

- License: MIT (see LICENSE file)
