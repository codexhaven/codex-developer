# Codex-Developer

> Words in. Working software out.

A self-improving autonomous software factory that builds complete applications from natural language. Runs locally on your device. Uses free AI providers.

## What It Does

```
"I need a program to rank students by exam scores"
↓
Working application delivered
```

## Quick Start

```bash
# One-command install
curl -Ls https://raw.githubusercontent.com/USER/codex-developer/main/install.sh | bash

# Get a free API key
# https://aistudio.google.com/app/apikey

# Build something
~/.hermes/skills/codex-developer/listen.sh "Build a password generator CLI tool"
```

## Features

· Natural Language Interface — Describe what you want, get working code
· Three Build Modes — Creates new files, patches existing, or makes surgical edits
· Self-Verifying — Every change is syntax-checked with automatic rollback on failure
· Cross-Project Learning — Remembers patterns and lessons across all projects
· Immutable Kernel — Protected core that watches for tampering and enables recovery
· Self-Improving — Detects failure patterns and proposes fixes (with human approval)
· 100% Local — Runs on your device. No code leaves your machine.
· Free — Uses Google AI Studio (free tier) or GitHub Copilot

## Requirements

· Hermes Agent
· Python 3.13+
· Git
· A free API key from Google AI Studio

## Architecture

```
listen.sh          ← Natural language interface
runcycle.sh        ← Build engine (NEW | PATCH | SED)
kernel.sh          ← Guardian (integrity, recovery, wisdom)
modules/           ← Template detection, pattern matching, failure checking
global-knowledge.jsonl  ← Cross-project memory
```

## Built With Codex

Chat apps, weather apps, system monitors, agentic AI assistants, note-taking apps, password generators, blog engines, exam rankers — all from one-sentence descriptions.

## Story

This project started with a simple question: "Is free Claude Code safe to use?"

Instead of trusting a leaked binary, the answer became building something transparent, local, and more capable. Codex-developer is the result — a self-improving autonomous developer that runs on free AI, on your device, under your control.

No subscriptions. No surveillance. Just words in, software out.
EOF
