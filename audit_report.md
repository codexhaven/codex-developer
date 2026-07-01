# Codex Developer v12.4 — Complete Inventory Report

**Repository:** https://github.com/codexhaven/codex-developer.git
**Generated:** 2026-07-02
**Total Files:** 80+ (excluding .git/)
**Languages:** Bash, Python, JSON, Markdown
**DNA Fingerprint:** `# ctx: codexhaven`

---

## Table of Contents

1. [File Inventory](#1-file-inventory)
2. [Call Graph](#2-call-graph)
3. [External References](#3-external-references)
4. [Missing Headers & DNA Fingerprint Flags](#4-missing-headers--dna-fingerprint-flags)
5. [TODO / FIXME / Placeholder Comments](#5-todo--fixme--placeholder-comments)
6. [Severity Summary](#6-severity-summary)

---

## 1. FILE INVENTORY

### Core Scripts (Entry Points)

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 1 | `listen.sh` | Bash | Main entry point — parses request, detects mode, orchestrates flow | `recon.sh`, `runcycle.sh`, `hermes` CLI, Python 3 |
| 2 | `runcycle.sh` | Bash | Build engine — phase-gated file generation loop | All sandbox + module scripts, `hermes` CLI |
| 3 | `kernel.sh` | Bash | Alternative build engine (simpler version) | Same as runcycle.sh |
| 4 | `install.sh` | Bash | Installation script — sets permissions, git config, .env | `python3`, `git`, `hermes` |
| 5 | `self-update.sh` | Bash | Self-evolution engine — analyzes proposals, injects rules | `opportunity-analyzer.py` |

### Sandbox Scripts (Build Pipeline)

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 6 | `sandbox/recon.sh` | Bash | Research module — domain research + contract.json generation | `hermes` CLI, Python 3 |
| 7 | `sandbox/architect.sh` | Bash | Contract validator + phase gate keeper | `contract.json`, Python 3 |
| 8 | `sandbox/strengthen.sh` | Bash | Multi-pass file hardening + cross-reference validation | `hermes` CLI, `map_project.py` |
| 9 | `sandbox/swarm.sh` | Bash | Self-assembling build system — violations, guards, routes | `contract.json`, Python 3 |
| 10 | `sandbox/mirror.sh` | Bash | Build pattern capture for Cod3x training | None (optional) |
| 11 | `sandbox/hello.sh` | Bash | Minimal hello script (test artifact) | None |
| 12 | `sandbox/recon.sh` | Bash | Legacy recon script referenced in backups | None |

### Modules (27 Active)

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 13 | `modules/dna-inject.sh` | Bash | DNA fingerprint injection (`# ctx: codexhaven`) | None |
| 14 | `modules/github-push.sh` | Bash | GitHub repo creation + push | `git`, `curl`, `GITHUB_TOKEN` |
| 15 | `modules/vercel-deploy.sh` | Bash | Vercel deployment plugin | `vercel` CLI, `VERCEL_TOKEN` |
| 16 | `modules/gitignore-init.sh` | Bash | .gitignore generation | None |
| 17 | `modules/healer.sh` | Bash | Healer orchestrator — 4-step healing pipeline | `healer_*.sh` sub-modules |
| 18 | `modules/healer_trace.sh` | Bash | Step 1: Capture failure trace | None |
| 19 | `modules/healer_analyze.sh` | Bash | Step 2: Root cause analysis via LLM | `hermes` CLI |
| 20 | `modules/healer_fix.sh` | Bash | Step 3: Surgical fix application | `hermes` CLI |
| 21 | `modules/healer_reset.sh` | Bash | Step 4: State reset + cleanup | Python 3 |
| 22 | `modules/map_project.py` | Python | Full context reader — imports, exports, dependency graph | `ast`, `json`, `os`, `re` |
| 23 | `modules/enforce_path.py` | Python | Path security enforcement | `sys`, `os` |
| 24 | `modules/scan_deps.py` | Python | Dependency scanner + queue appender | `os`, `re`, `sys` |
| 25 | `modules/import-check.sh` | Bash | Import checker for JS/TS local imports | None |
| 26 | `modules/contract-import-check.sh` | Bash | Contract import validation | Python 3 |
| 27 | `modules/failure-check.sh` | Bash | Pattern-based failure detection | Python 3, `failure-patterns.json` |
| 28 | `modules/symbol-check.sh` | Bash | Cross-file symbol validation + dead code detection | Python 3 |
| 29 | `modules/smoke-tester.sh` | Bash | Python syntax compilation check | `python3 -m py_compile` |
| 30 | `modules/self-test.sh` | Bash | pytest runner for projects with tests/ | `pytest` |
| 31 | `modules/method-adapter.sh` | Bash | Adaptive prompt strategy on LLM failure | None |
| 32 | `modules/sed-patcher.sh` | Bash | SED-based patch fallback for large files | `hermes` CLI |
| 33 | `modules/template-detect.sh` | Bash | Project template detection from keywords | Python 3, `project-templates.json` |
| 34 | `modules/pattern-matcher.sh` | Bash | Reusable code pattern matcher | Python 3, `patterns.json` |
| 35 | `modules/review-to-queue.sh` | Bash | REVIEW mode bridge to build queue | None |
| 36 | `modules/capability-runner.sh` | Bash | Executes matched project capabilities | Python 3, `capabilities.json` |
| 37 | `modules/capability-scanner.sh` | Bash | Indexes project capabilities post-build | Python 3 |
| 38 | `modules/add_path_header.sh` | Bash | Adds shebang/path headers to generated files | None |

### Stack Plugins (3)

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 39 | `modules/vibestack/apply.sh` | Bash | Next.js/React/Tailwind/Shadcn/Supabase assistant | `package.json` |
| 40 | `modules/vibestack/README.md` | Markdown | VibeStack documentation | None |
| 41 | `modules/vibestack/SKILL.md` | Markdown | VibeStack Hermes skill definition | None |
| 42 | `modules/flaskstack/apply.sh` | Bash | Flask/Django/FastAPI assistant | None |
| 43 | `modules/vanillastack/apply.sh` | Bash | Static HTML/CSS/JS assistant | None |

### Python Utilities

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 44 | `lesson-analyzer.py` | Python | Analyzes lessons.jsonl, generates constraints | `json`, `os`, `fcntl`, `collections.Counter` |
| 45 | `opportunity-analyzer.py` | Python | Finds improvement opportunities from patterns | `json`, `os`, `re`, `datetime` |
| 46 | `calc.py` | Python | Simple CLI calculator (test artifact) | `sys` |
| 47 | `check_env.py` | Python | Environment checker (ccxt detection) | `sys`, `platform`, `subprocess` |
| 48 | `do_replace.py` | Python | recon.sh patch utility (one-time use artifact) | `sys` |
| 49 | `replace_recon.py` | Python | recon.sh replacement script (one-time use artifact) | `sys` |
| 50 | `patch_listen.py` | Python | listen.sh patch utility (one-time use artifact) | `sys` |
| 51 | `research_crypto_trading.py` | Python | Crypto trading research stub (incomplete) | `subprocess` |

### Configuration & Data Files

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 52 | `global-knowledge.jsonl` | JSONL | 76 accumulated wisdom rules | None |
| 53 | `failure-patterns.json` | JSON | Known failure patterns for detection | None |
| 54 | `patterns.json` | JSON | Reusable code patterns (CSS, JS, HTML) | None |
| 55 | `project-templates.json` | JSON | Project template definitions (5 types) | None |
| 56 | `package.json` | JSON | Minimal package.json (artifact) | None |
| 57 | `.codex/config.json` | JSON | Runtime configuration flags | None |
| 58 | `.codex/state.json` | JSON | Build state (cycles, files built) | None |
| 59 | `.codex/goal.md` | Markdown | Current refactoring goal | None |
| 60 | `.codex/build-queue.txt` | Text | Empty build queue | None |
| 61 | `.codex/build-done.txt` | Text | Empty build done log | None |
| 62 | `.codex/lessons.md` | Markdown | Empty lessons markdown | None |
| 63 | `.codex/lessons.jsonl` | JSONL | Empty lessons log | None |

### Documentation

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 64 | `README.md` | Markdown | Project documentation + quick start | None |
| 65 | `SKILL.md` | Markdown | Hermes skill definition | None |
| 66 | `LICENSE` | Text | Custom license (not MIT as claimed) | None |
| 67 | `goal.md` | Markdown | Refactoring goal: Python standalone app | None |
| 68 | `proposals.md` | Markdown | Approved improvement proposals | None |
| 69 | `domain_knowledge_healthcare_ehr.txt` | Text | Healthcare EHR domain knowledge | None |

### Backup & Artifact Files

| # | Path | Language | Purpose | Dependencies |
|---|------|----------|---------|--------------|
| 70 | `listen.sh.bak.v12.4_pre_awareness` | Bash | Pre-v12.4 backup | None |
| 71 | `listen.sh.listen_auto_backup` | Bash | Auto-backup | None |
| 72 | `runcycle.sh.obs_backup` | Bash | Observability backup | None |
| 73 | `runcycle.sh.obs2_backup` | Bash | Observability backup v2 | None |
| 74 | `runcycle.sh.obs3_backup` | Bash | Observability backup v3 | None |
| 75 | `runcycle.sh.perf_backup` | Bash | Performance backup | None |
| 76 | `runcycle.sh.retri_backup` | Bash | Retry logic backup | None |
| 77 | `newblock2.txt` | Text | recon.sh patch fragment (artifact) | None |
| 78 | `codex-developer-stable` | Text | Path pointer to stable version | None |
| 79 | `.kernel-hash` | Text | Kernel hash fingerprint | None |
| 80 | `.lock_sha` | Text | Lock file SHA checksum | None |

---

## 2. CALL GRAPH

### Primary Flow

```
listen.sh [ENTRY POINT]
  ├── understand() — detects MODE from request
  │     ├── Checks for explicit file paths (.py, .js, etc.)
  │     ├── Scans existing project files
  │     └── Sets MODE: NEW | GENERATE | EXISTING | REVIEW | CONTINUATION | CHECK | DEPLOY | DIRECT
  │
  ├── Mode: NEW / GENERATE
  │     ├── mode_new()
  │     │     ├── sandbox/recon.sh → generates contract.json + phases.json
  │     │     ├── sandbox/architect.sh --contract → validates contract
  │     │     ├── User approval prompt
  │     │     └── run_build_loop() → calls runcycle.sh
  │     └── run_build_loop()
  │           └── CODEX_REPO=$REPODIR MODE=$MODE bash runcycle.sh
  │
  ├── Mode: EXISTING
  │     ├── mode_existing()
  │     │     ├── modules/map_project.py → project map
  │     │     ├── Extracts requested files from REQUEST
  │     │     └── run_build_loop() → calls runcycle.sh
  │     └── run_build_loop()
  │           └── CODEX_REPO=$REPODIR MODE=$MODE bash runcycle.sh
  │
  ├── Mode: DIRECT
  │     ├── mode_direct()
  │     │     ├── Builds queue from explicit file paths in request
  │     │     └── run_build_loop()
  │     └── run_build_loop() → calls runcycle.sh
  │
  ├── Mode: REVIEW
  │     └── mode_review()
  │           ├── Scans all project files
  │           ├── Calls hermes for each file review
  │           ├── Saves reviews to reviews/*.md
  │           └── modules/review-to-queue.sh → converts to build queue
  │
  ├── Mode: CONTINUATION
  │     └── mode_continuation() → run_build_loop()
  │
  ├── Mode: CHECK
  │     └── mode_check()
  │           ├── modules/import-check.sh (per file)
  │           └── python3 -m py_compile (per .py file)
  │
  └── Mode: DEPLOY
        └── mode_deploy()
              ├── modules/vercel-deploy.sh
              └── git commit + push

runcycle.sh [BUILD ENGINE]
  ├── acquire_lock() — flock-based process lock
  ├── ensure_files() — creates .codex/ state files
  ├── detect_project_domain() — checks package.json, Cargo.toml, etc.
  ├── Stack Plugins (silent step-aside if not matching):
  │     ├── modules/vibestack/apply.sh
  │     ├── modules/flaskstack/apply.sh
  │     └── modules/vanillastack/apply.sh
  ├── modules/gitignore-init.sh
  ├── Main Build Loop (max 50 cycles):
  │     ├── next_file() — reads build-queue.txt, skips done files
  │     ├── Phase Gate:
  │     │     └── sandbox/architect.sh --gate → checks phase ordering
  │     ├── build_file() — calls hermes chat for file generation
  │     ├── modules/enforce_path.py — security path check
  │     ├── apply_file() — writes FILE: block to disk
  │     │     ├── self_protect() — prevents modifying SKILLDIR
  │     │     └── add_path_header.sh — adds shebang/headers
  │     ├── verify_file() — syntax validation
  │     │     ├── python3 -m py_compile (.py)
  │     │     ├── bash -n (.sh)
  │     │     ├── node --check (.js/.ts)
  │     │     └── python3 HTMLParser (.html)
  │     ├── Contract Enforcement:
  │     │     └── python3 AST check against contract.json
  │     ├── Swarm Orchestration:
  │     │     └── sandbox/swarm.sh --guard → breaking change detection
  │     ├── Smoke Test:
  │     │     └── modules/smoke-tester.sh
  │     ├── Dependency Scan:
  │     │     └── modules/scan_deps.py
  │     ├── modules/failure-check.sh
  │     ├── mark_done() — updates state.json
  │     ├── commit_all() — git commit
  │     ├── sandbox/strengthen.sh — post-build hardening
  │     │     ├── Contract compliance check (AST)
  │     │     ├── Import cross-reference validation
  │     │     ├── Multi-pass LLM strengthening
  │     │     └── flatten_simple_project() — structure audit
  │     ├── sandbox/mirror.sh — pattern capture
  │     ├── lesson-analyzer.py — constraint generation
  │     └── sandbox/architect.sh --advance → phase advancement
  ├── Post-Build:
  │     ├── modules/self-test.sh (if tests/ exists)
  │     ├── sandbox/strengthen.sh --flatten
  │     ├── modules/capability-scanner.sh
  │     └── modules/symbol-check.sh
  └── GitHub Push:
        └── modules/github-push.sh (if GITHUB_TOKEN set)

healer.sh [HEALING PIPELINE] — triggered after 3 failures
  ├── modules/healer_trace.sh — capture failure context
  ├── modules/healer_analyze.sh — LLM root cause analysis
  ├── modules/healer_fix.sh — surgical fix application
  └── modules/healer_reset.sh — state reset + cleanup

self-update.sh [SELF-EVOLUTION]
  ├── --analyze → opportunity-analyzer.py → proposals.md
  └── --approve <id> → injects rule into global-knowledge.jsonl
```

### Supporting Call Chains

```
capability-runner.sh
  └── Reads .codex/capabilities.json → eval() matched capability

capability-scanner.sh
  └── Walks project → writes .codex/capabilities.json

pattern-matcher.sh
  └── Reads patterns.json → returns matching code templates

template-detect.sh
  └── Reads project-templates.json → returns file list
```

---

## 3. EXTERNAL REFERENCES

### GitHub Repositories Referenced

| Ref | URL | File(s) | Context |
|-----|-----|---------|---------|
| Self | `https://github.com/codexhaven/codex-developer.git` | `README.md`, `listen.sh` | Clone target |
| Cod3x | `github.com/codexhaven/Cod3x` | `README.md` | Example project |
| Wilcom | `github.com/codexhaven/Wilcom` | `README.md` | Example project |
| Router Tool | `github.com/codexhaven/tool` | `README.md` | Example project |
| Twin Tools | `github.com/codexhaven/twin-tools` | `README.md` | Example project |
| Skill | `github.com/codexhaven/skill` | `README.md` | Example project |

### API Endpoints

| Endpoint | File | Purpose |
|----------|------|---------|
| `https://api.github.com/repos/${GITHUB_USER}/${REPO_NAME}` | `modules/github-push.sh:35` | Check repo existence |
| `https://api.github.com/user/repos` | `modules/github-push.sh:42` | Create new repository |
| `https://generativelanguage.googleapis.com/v1beta/openai/chat/completions` | `global-knowledge.jsonl` | Gemini API endpoint |

### External Commands & System Dependencies

| Command | File(s) | Purpose |
|---------|---------|---------|
| `hermes` CLI | `listen.sh`, `runcycle.sh`, `recon.sh`, `strengthen.sh`, `healer_analyze.sh`, `healer_fix.sh`, `sed-patcher.sh`, `method-adapter.sh` | Core LLM interface (REQUIRED) |
| `python3` | Throughout | JSON parsing, AST analysis, validation |
| `git` | `listen.sh`, `runcycle.sh`, `github-push.sh` | Version control, commit, push |
| `curl` | `modules/github-push.sh` | GitHub API calls |
| `flock` | `runcycle.sh`, `kernel.sh` | Process locking |
| `vercel` CLI | `modules/vercel-deploy.sh` | Vercel deployment |
| `pytest` | `modules/self-test.sh` | Test runner |
| `node` | `runcycle.sh` | JS/TS syntax check |
| `json.load()` | `runcycle.sh` | YAML validation via PyYAML |

### Python Standard Library Imports Used

| Module | File(s) | Purpose |
|--------|---------|---------|
| `json` | Throughout | JSON parsing/writing |
| `os` | `map_project.py`, `enforce_path.py`, `scan_deps.py`, `lesson-analyzer.py`, `opportunity-analyzer.py` | Path operations, env vars |
| `sys` | `enforce_path.py`, `scan_deps.py`, `lesson-analyzer.py`, `check_env.py`, `calc.py` | System operations |
| `re` | `map_project.py`, `scan_deps.py`, `opportunity-analyzer.py` | Regex matching |
| `ast` | `map_project.py` | Python AST parsing for imports/exports |
| `fcntl` | `lesson-analyzer.py` | File locking |
| `collections.Counter` | `lesson-analyzer.py`, `opportunity-analyzer.py` | Counting |
| `datetime` | `opportunity-analyzer.py` | Timestamps |
| `platform` | `check_env.py` | Platform detection |
| `subprocess` | `check_env.py`, `research_crypto_trading.py` | External commands |

### Third-Party pip Packages (Optional/Contextual)

| Package | File | Context |
|---------|------|---------|
| `ccxt` | `check_env.py` | Crypto trading (optional, checked at runtime) |
| `yaml` (PyYAML) | `runcycle.sh` | YAML validation (optional — `2>/dev/null` fallback) |
| `googlesearch` | `research_crypto_trading.py` | Referenced but not functional |

---

## 4. MISSING HEADERS & DNA FINGERPRINT FLAGS

### Files Lacking `# ctx: codexhaven` DNA Fingerprint

| # | File | Severity | Notes |
|---|------|----------|-------|
| 1 | `listen.sh` | [WARNING] | Has version header (`# CODES-DEVELOPER v12.4`) but no DNA fingerprint |
| 2 | `runcycle.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 3 | `kernel.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 4 | `install.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 5 | `self-update.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 6 | `sandbox/recon.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 7 | `sandbox/architect.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 8 | `sandbox/strengthen.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 9 | `sandbox/swarm.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 10 | `sandbox/mirror.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 11 | `sandbox/hello.sh` | [INFO] | Trivial test file — DNA not required |
| 12 | `modules/dna-inject.sh` | [INFO] | The injector itself — DNA not required |
| 13 | `modules/github-push.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 14 | `modules/vercel-deploy.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 15 | `modules/gitignore-init.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 16 | `modules/healer.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 17 | `modules/healer_trace.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 18 | `modules/healer_analyze.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 19 | `modules/healer_fix.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 20 | `modules/healer_reset.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 21 | `modules/import-check.sh` | [WARNING] | No header at all |
| 22 | `modules/contract-import-check.sh` | [WARNING] | No header at all |
| 23 | `modules/failure-check.sh` | [WARNING] | No header at all |
| 24 | `modules/symbol-check.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 25 | `modules/smoke-tester.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 26 | `modules/self-test.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 27 | `modules/method-adapter.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 28 | `modules/sed-patcher.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 29 | `modules/template-detect.sh` | [WARNING] | No header at all |
| 30 | `modules/pattern-matcher.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 31 | `modules/review-to-queue.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 32 | `modules/capability-runner.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 33 | `modules/capability-scanner.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 34 | `modules/add_path_header.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 35 | `modules/vibestack/apply.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 36 | `modules/flaskstack/apply.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 37 | `modules/vanillastack/apply.sh` | [WARNING] | Has version header but no DNA fingerprint |
| 38 | `lesson-analyzer.py` | [WARNING] | Has module docstring but no DNA fingerprint |
| 39 | `opportunity-analyzer.py` | [WARNING] | Has module docstring but no DNA fingerprint |
| 40 | `check_env.py` | [WARNING] | No header at all |
| 41 | `research_crypto_trading.py` | [WARNING] | No header at all |
| 42 | `do_replace.py` | [INFO] | One-time utility — DNA not required |
| 43 | `replace_recon.py` | [INFO] | One-time utility — DNA not required |
| 44 | `patch_listen.py` | [INFO] | One-time utility — DNA not required |
| 45 | `global-knowledge.jsonl` | [INFO] | Data file — DNA not applicable |
| 46 | `failure-patterns.json` | [INFO] | Data file — DNA not applicable |
| 47 | `patterns.json` | [INFO] | Data file — DNA not applicable |
| 48 | `project-templates.json` | [INFO] | Data file — DNA not applicable |
| 49 | `domain_knowledge_healthcare_ehr.txt` | [INFO] | Data file — DNA not applicable |

### Files WITH DNA Fingerprint (Correct)

| # | File | Fingerprint Location |
|---|------|---------------------|
| 1 | `calc.py` | Line 6: `# ctx: codexhaven` |

---

## 5. TODO / FIXME / PLACEHOLDER COMMENTS

### Inline TODO/FIXME Comments

| File | Line | Comment | Severity |
|------|------|---------|----------|
| `runcycle.sh` | 566 | `done < <(grep -h '"type": "rule"' "$GLOBAL_KNOWELDGE" 2>/dev/null)` — **Typo: `$GLOBAL_KNOWELDGE` should be `$GLOBAL_KNOWLEDGE`** | [CRITICAL] |
| `runcycle.sh` | Multiple | Double increment: `FAILURE_COUNT=$((FAILURE_COUNT + 1))` appears twice (lines 606-607) | [CRITICAL] |
| `runcycle.sh` | 820 | Unclosed `while read` loop — `obs_log "Tests completed"` is outside the loop body | [CRITICAL] |
| `runcycle.sh` | 65 | `touch "$OBSERVABILITY_LOG"` appears between functions (line 66, outside any function) | [WARNING] |
| `modules/healer_fix.sh` | 53-55 | `queue_emergency` called twice with same args (duplicate line) | [WARNING] |
| `modules/healer_fix.sh` | 81-143 | `fix_error_handling()` and `fix_async_patterns()` defined but never called | [WARNING] |
| `modules/smoke-tester.sh` | 3 | Unclosed string: `REPODIR="$(readlink -f "${1:-$HOME/projects}")` — missing closing quote | [CRITICAL] |
| `modules/vercel-deploy.sh` | 18 | `NEEDS_CLERK=$(grep -rl "clerk" package.json app/ lib/ 2>/dev/null | wc -l)` — `-r` flag on single file `package.json` | [WARNING] |
| `sandbox/recon.sh` | 61 | Example JSON has typo: `{\"type\": \"function\"...}` — double-escaped | [INFO] |
| `sandbox/swarm.sh` | 24 | Hardcoded package whitelist — may miss legitimate project modules | [INFO] |
| `research_crypto_trading.py` | 4-8 | Mock implementation: `# Mocking result as I don't have direct internet search here` | [WARNING] |
| `calc.py` | 6 | DNA fingerprint is inside `if __name__ == "__main__":` block — not at file top | [INFO] |

### Placeholder / Incomplete Code

| File | Issue | Severity |
|------|-------|----------|
| `check_env.py` | Only checks `ccxt` import — appears to be a fragment | [INFO] |
| `do_replace.py` | Hardcoded paths — single-use script that modifies `sandbox/recon.sh` | [INFO] |
| `replace_recon.py` | Identical to `do_replace.py` — duplicate code | [WARNING] |
| `patch_listen.py` | Hardcoded string replacement for `listen.sh` — fragile | [WARNING] |
| `codex-developer-stable` | Single line pointing to a path — not a real script | [INFO] |

---

## 6. SEVERITY SUMMARY

### [CRITICAL] Issues (4)

1. **`runcycle.sh:566`**: Typo `$GLOBAL_KNOWELDGE` → should be `$GLOBAL_KNOWLEDGE`. Causes global wisdom rules to never be injected into prompts.
2. **`runcycle.sh:606-607`**: `FAILURE_COUNT` incremented twice in succession. Causes healer to trigger at 2 failures instead of 3.
3. **`runcycle.sh:820`**: Unclosed `while read` loop — the `obs_log "Tests completed"` line is outside the loop body, causing syntax/execution issues.
4. **`modules/smoke-tester.sh:3`**: Unclosed quoted string in `REPODIR` assignment — script will fail with syntax error.

### [WARNING] Issues (20+)

- 44 source files lack DNA fingerprint `# ctx: codexhaven` (only `calc.py` has it)
- 37 shell scripts lack proper header comments with DNA fingerprint
- `healer_fix.sh` has dead code (`fix_error_handling`, `fix_async_patterns` never called)
- `healer_fix.sh` has duplicate `queue_emergency` call
- `replace_recon.py` and `do_replace.py` are near-duplicates
- `runcycle.sh` has stray `touch` command outside any function
- `vercel-deploy.sh` uses `grep -r` on single files unnecessarily
- `research_crypto_trading.py` is a non-functional mock
- `patch_listen.py` uses fragile string replacement

### [INFO] Items (15+)

- `calc.py` has DNA fingerprint inside `if __name__` block (not at top)
- 5 backup files of `runcycle.sh` and 2 of `listen.sh` present
- `newblock2.txt` is a patch fragment artifact
- `domain_knowledge_healthcare_ehr.txt` is unused domain data
- `sandbox/hello.sh` is a trivial test artifact
- `.codex/build-queue.txt`, `.codex/build-done.txt`, `.codex/lessons.jsonl` are all empty
- `package.json` appears to be a leftover artifact (references "calculator")
- `opportunity-analyzer.py` references non-existent `training_data.json` in `~/Cod3x/data/`

---

## Appendix A: 7 Modes Detection Logic

```
listen.sh → understand():

1. DEPLOY:   request matches "deploy to production|deploy to vercel|ship to production|push to production"
2. GENERATE: request matches "^generate|^create.*tool|^make.*tool|build.*cli tool|^Generate"
3. CHECK:    request matches "^(check|scan|audit|diagnose|inspect|verify)( |$)"
4. REVIEW:   request matches "^review|security review|bug review|code review|audit|scan for|analyze this"
5. DIRECT:   request matches "^direct|^continue.*build|^resume|^pick up where" OR contains explicit file paths
6. CONTINUATION: build-queue.txt exists and is non-empty
7. NEW:       code_files < 1 (empty project)
8. EXISTING:  fallback — project has existing files
```

## Appendix B: Environment Variables Required

| Variable | Required | File(s) | Purpose |
|----------|----------|---------|---------|
| `GITHUB_TOKEN` | No (optional) | `listen.sh`, `github-push.sh` | GitHub API authentication |
| `GITHUB_USER` | No (default: codexhaven) | `github-push.sh` | GitHub username |
| `VERCEL_TOKEN` | No (optional) | `vercel-deploy.sh` | Vercel deployment |
| `OPENROUTER_KEY` | No | `install.sh` (.env template) | LLM API key |
| `CODEX_REPO` | No | `runcycle.sh`, `kernel.sh` | Override REPODIR |
| `MAX_LINES` | No (default: 120) | `runcycle.sh` | Max file lines |
| `MAX_RETRIES` | No (default: 3) | `runcycle.sh` | Build retry count |
| `AUTO_YES` | No | `listen.sh` | Auto-approve phases |
| `DRY_RUN` | No | `listen.sh` | Dry run mode |

---

*Report generated by Codex Maintainer Agent*
*DNA: # ctx: codexhaven*
