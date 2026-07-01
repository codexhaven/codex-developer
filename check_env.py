#!/usr/bin/env python3
"""Codex Developer v12.4 -- Environment checker."""
# ctx: codexhaven
import sys
import platform

print(f"Python version: {sys.version}")
print(f"Platform: {platform.platform()}")

try:
    import ccxt
    print("ccxt installed")
except ImportError:
    print("ccxt NOT installed")
