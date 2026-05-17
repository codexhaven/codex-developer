#!/usr/bin/env python3
"""Color logger for Codex Developer — ANSI colors for terminal output."""
import sys

# ANSI color codes
COLORS = {
    "DEBUG":    "\033[36m",  # Cyan
    "INFO":     "\033[37m",  # White
    "SUCCESS":  "\033[32m",  # Green
    "WARN":     "\033[33m",  # Yellow
    "ERROR":    "\033[31m",  # Red
    "BOLD":     "\033[1m",
    "RESET":    "\033[0m",
}

# Level badges
BADGES = {
    "DEBUG":    "◉",
    "INFO":     "●",
    "SUCCESS":  "✓",
    "WARN":     "⚠",
    "ERROR":    "✗",
}

def log(msg, level="INFO"):
    color = COLORS.get(level, COLORS["INFO"])
    badge = BADGES.get(level, "●")
    reset = COLORS["RESET"]
    bold = COLORS["BOLD"]
    
    # Format: [BADGE] message
    print(f"{color}{bold}[{badge}]{reset} {color}{msg}{reset}", file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        msg = sys.argv[1]
        level = sys.argv[2] if len(sys.argv) > 2 else "INFO"
        log(msg, level)
