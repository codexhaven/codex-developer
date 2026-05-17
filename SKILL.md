---
name: codex-developer
description: >
  Autonomous software factory (v12.2). Human-in-the-Loop (HITL) architecture 
  with mandatory approval, hardened path-agnostic operation, and self-healing 
  verification loops.
version: 12.2.0
metadata:
  required_toolsets: [terminal, file, web]
---

## Architecture

### Interface (listen.sh) — The Entry Point
- Takes natural language requests.
- Detects persona (PRODUCT, EXPERT, LEARNER) automatically.
- Routes to specialized modes (NEW, REVIEW, CONTINUATION, EXISTING, FIX).
- Enforces absolute path resolution before execution.
- Verbose orchestration logging for transparency.

### Orchestrator (runcycle.sh) — The Engine
- HITL Model: Mandatory approval (Y/N) before autonomous execution.
- Multi-mode engine: NEW, PATCH (rewrite), SED (targeted).
- Persona-aware prompts for context injection.
- Security: Path containment to $REPODIR.
- Self-Healing: Automatic rollback on syntax failures; kernel-based recovery.
- Global Wisdom: Injects mandatory audit rules (Rule #38) into planning cycles.

## Modes

| Mode | Trigger | Description |
|---|---|---|
| NEW | "Build a..." | Scaffold project, plan structure, HITL generation. |
| REVIEW | "Review/audit" | Full scan, SUMMARY.md generation, inline fix menu. |
| EXISTING | "Add..." | Logic-aware enhancement, plan, HITL commit. |
| CONTINUATION| Implicit | Resumes unfinished work from .codex/ queue. |
| FIX | "Fix..." | Surgical patches via SED/PATCH, verification-loop enabled. |

## Operational Rules (Wisdom)
- Rule #38: **Pre-Flight Audit Rule.** Before proposing code/imports, perform mandatory filesystem audit (ls -R). Match imports to actual file existence. Create missing modules BEFORE importing.
- Standard: Absolute pathing enforced for all module inputs.
- Verification: Mandatory smoke-tester.sh runs after every patch cycle.

## How to Request
- **New Project:** `listen.sh "Build a [thing]" /absolute/path/to/project`
- **Enhancement:** `listen.sh "Add [feature]" /absolute/path/to/project`
- **Surgical Fix:** `listen.sh "Fix [problem]" /absolute/path/to/project`

## Recovery
If factory drift or loop failure occurs:
1. Reset state: `truncate -s 0 ~/.codex/build-queue.txt`
2. Recover: `bash ~/.hermes/skills/codex-developer/kernel.sh recover`
3. Restart: `listen.sh "Continue/Fix [task]" [path]`
