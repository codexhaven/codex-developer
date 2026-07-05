# Codex Developer v12.6

> Autonomous software factory. Builds complete projects from natural language -- researched, phase-planned, DNA-signed, and pushed to GitHub.

## Quick Start

```bash
# Clone the factory
git clone https://github.com/codexhaven/codex-developer.git ~/.hermes/skills/codex-developer

# Set up environment
echo 'GITHUB_TOKEN=ghp_xxx' >> ~/.hermes/.env
echo 'GITHUB_USER=codexhaven' >> ~/.hermes/.env
echo 'OPENROUTER_KEY=sk-or-xxx' >> ~/.hermes/.env

# Install
~/.hermes/skills/codex-developer/install.sh

# Build your first project
~/.hermes/skills/codex-developer/listen.sh "Build a python calculator" ~/calculator
```

## What It Builds

| Project | Description | GitHub |
|---------|------------|--------|
| Cod3x | Self-improving AI with 50K training examples | [github.com/codexhaven/Cod3x](https://github.com/codexhaven/Cod3x) |
| Wilcom | Online embroidery digitizing platform | [github.com/codexhaven/Wilcom](https://github.com/codexhaven/Wilcom) |
| Router Tool | Colorful WiFi router control CLI | [github.com/codexhaven/tool](https://github.com/codexhaven/tool) |
| Twin Tools | Privacy cleanup + AI agent splash | [github.com/codexhaven/twin-tools](https://github.com/codexhaven/twin-tools) |
| Skill | Hermes jailbreak/red-teaming skill | [github.com/codexhaven/skill](https://github.com/codexhaven/skill) |

## Architecture

```
listen.sh -- Entry Point
  |-- 8 modes: NEW, GENERATE, EXISTING, REVIEW, CONTINUATION, CHECK, DEPLOY, DIRECT
  |-- understand() -- detects mode from request
  |-- routes to mode_*() functions
  |
  +-- runcycle.sh -- Build Engine
  |     |-- Phase-gated build loop (max 50 cycles)
  |     |-- Pre-build intelligence + method adaptation
  |     |-- DNA fingerprint injection (# ctx: codexhaven)
  |     |-- Contract enforcement (AST validation)
  |     |-- Cross-reference validation
  |     |-- Self-healing pipeline (4-step healer)
  |     |-- Smoke testing + symbol checking
  |     +-- Auto-push to GitHub
  |
  +-- sandbox/recon.sh -- Research Module
  |     |-- Domain-aware architecture design
  |     |-- Contract generation (functions, imports, phases)
  |     +-- project_brain.md generation
  |
  +-- sandbox/architect.sh -- Phase Gate Keeper
  |     |-- Contract validation
  |     |-- Phase gate enforcement
  |     +-- Phase advancement
  |
  +-- sandbox/strengthen.sh -- Hardening Engine
  |     |-- Multi-pass file hardening
  |     |-- Import cross-reference validation
  |     +-- Structure audit + flattening
  |
  +-- modules/healer.sh -- Self-Healing Pipeline
        |-- healer_trace.sh -- Capture failure context
        |-- healer_analyze.sh -- Root cause analysis
        |-- healer_fix.sh -- Surgical fix application
        +-- healer_reset.sh -- State reset + cleanup
```

## 8 Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| NEW | "Build a..." | Full recon -> phases -> approve -> build |
| GENERATE | "Generate...", "Create tool..." | Same as NEW, for creative tools |
| EXISTING | "Add...", "PATCH..." | Targeted file modification |
| DIRECT | Explicit file paths, "continue" | Direct file build with path extraction |
| REVIEW | "Review/audit" | Full scan, bridge to build queue |
| CONTINUATION | Implicit | Resume from .codex/ queue |
| CHECK | Diagnostic keywords | Audit-only, no changes |
| DEPLOY | "Deploy/ship/launch" | Git + Vercel deployment |

## Key Features

- **Recon Research**: Domain-aware architecture design with real-world workflow analysis
- **Phase-Gated Builds**: Complex projects built in ordered phases (max 3)
- **Strengthen Pass**: Every file hardened with cross-reference validation
- **DNA Fingerprint**: `# ctx: codexhaven` embedded in every generated file
- **76 Global Rules**: Accumulated wisdom in every prompt (global-knowledge.jsonl)
- **Self-Healing**: 4-step healer (trace -> analyze -> fix -> reset) triggered after 3 failures
- **Contract Enforcement**: AST-based validation of function signatures against contract
- **Auto GitHub**: Every project pushed automatically with GITHUB_TOKEN
- **Stack Plugins**: VibeStack (Next.js), FlaskStack, VanillaStack auto-detection
- **Method Adaptation**: Adaptive prompt strategies on LLM failure
- **Cross-File Validation**: Import/export symbol checking across all project files

## Module Inventory (32 active)

| Category | Modules |
|----------|---------|
| Entry Points | listen.sh, runcycle.sh, kernel.sh |
| Stack Assistants | vibestack/apply.sh, flaskstack/apply.sh, vanillastack/apply.sh |
| Validation | import-check.sh, contract-import-check.sh, failure-check.sh, symbol-check.sh, smoke-tester.sh, self-test.sh |
| Path & Security | enforce_path.py, scan_deps.py, map_project.py |
| Build Tools | sed-patcher.sh, template-detect.sh, add_path_header.sh |
| Infrastructure | github-push.sh, gitignore-init.sh, vercel-deploy.sh |
| Review | review-to-queue.sh |
| Identity | dna-inject.sh |
| Healing | healer.sh, healer_trace.sh, healer_analyze.sh, healer_fix.sh, healer_reset.sh |
| Method | method-adapter.sh |
| Analysis | lesson-analyzer.py, opportunity-analyzer.py |
| Research | recon.sh, architect.sh, strengthen.sh, swarm.sh, mirror.sh |
| Deployment | self-update.sh |

## Requirements

- Linux/macOS/Android (Termux)
- Python 3.10+
- Git
- `hermes` CLI (pip install hermes-agent)
- GitHub token (for auto-push)
- Optional: Vercel token (for deployment)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| GITHUB_TOKEN | No | GitHub API authentication for auto-push |
| GITHUB_USER | No | GitHub username (default: codexhaven) |
| VERCEL_TOKEN | No | Vercel deployment token |
| OPENROUTER_KEY | No | LLM API key |
| CODEX_REPO | No | Override project directory |
| MAX_LINES | No | Max file lines (default: 120) |
| MAX_RETRIES | No | Build retry count (default: 3) |
| AUTO_YES | No | Auto-approve phases |
| DRY_RUN | No | Dry run mode |

## Recovery

If factory drift or loop failure occurs:

```bash
# Clear queue
rm ~/project/.codex/build-queue.txt ~/project/.codex/build-done.txt

# Clear lock
rm -f /tmp/codex-developer.lock ~/tmp-codex-developer.lock

# Retry
~/.hermes/skills/codex-developer/listen.sh "Continue" ~/project
```

## Changelog

### v12.6 (2026-07-03)
- Portability: Updated shebangs to `#!/usr/bin/env bash` and implemented dynamic `SKILLDIR` detection.
- Reliability: Fixed several build engine bugs (unbound variables, missing functions, regex issues).
- Improvements: Expanded project domain detection and enhanced healer's root cause analysis.
- Documentation: Updated SKILL.md and added a verification test suite for the core calculator.

### v12.4 (2026-07-02)
- Fixed all CRITICAL bugs (typo in GLOBAL_KNOWLEDGE, double increment, unclosed loop, syntax error)
- Added DNA fingerprints to all 45+ files that were missing them
- Removed duplicate code and artifact files
- Fixed warning issues (dead code, duplicate calls, stray commands)
- Upgraded vercel-deploy.sh with proper grep handling
- Comprehensive README and SKILL.md documentation
- Added self-test validation suite

### v12.3 (2026-05-14)
- 7 modes with GENERATE support
- Self-healing pipeline v2
- Global knowledge with 76 rules
- Phase-gated builds

## License

MIT -- Built by Codex Developer, for Codex Developer.
