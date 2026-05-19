# Codex Developer v12.3

Autonomous software factory for Termux/Android. Builds complete projects from natural language — researched, phase-planned, DNA-signed, and pushed to GitHub.

## Quick Start

```bash
# Clone the factory
git clone https://github.com/codexhaven/codex-developer.git ~/.hermes/skills/codex-developer

# Set up environment
echo 'GITHUB_TOKEN=ghp_xxx' >> ~/.hermes/.env
echo 'GITHUB_USER=codexhaven' >> ~/.hermes/.env

# Build your first project
~/.hermes/skills/codex-developer/listen.sh "Build a python calculator" ~/calculator
```

What It Builds

Project Description GitHub
Cod3x Self-improving AI with 50K training examples github.com/codexhaven/Cod3x
Wilcom Online embroidery digitizing platform github.com/codexhaven/Wilcom
Router Tool Colorful WiFi router control CLI github.com/codexhaven/tool
Twin Tools Privacy cleanup + AI agent splash github.com/codexhaven/twin-tools
Skill Hermes jailbreak/red-teaming skill github.com/codexhaven/skill

Architecture

```
listen.sh → recon.sh (research) → phases.json → approve
    ↓
runcycle.sh → phase gate → build files → strengthen → DNA inject
    ↓
github-push.sh → live on GitHub
```

Key Features

· Recon Research: 2-round LLM research with gap analysis
· Phase-Gated Builds: Complex projects built in ordered phases
· Strengthen Pass: Every file hardened with cross-reference validation
· DNA Fingerprint: # ctx: codexhaven embedded in every file
· 64 Global Rules: Accumulated wisdom in every prompt
· Auto GitHub: Every project pushed automatically
· 7 Modes: NEW, GENERATE, EXISTING, REVIEW, CONTINUATION, CHECK, DEPLOY

Requirements

· Termux on Android
· Hermes AI agent (pip install hermes-agent)
· Python 3.10+
· Git
· GitHub token (for auto-push)

License

MIT — Built by Codex Developer, for Codex Developer.
