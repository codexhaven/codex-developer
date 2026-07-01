import sys
import platform
import subprocess

print(f"Python version: {sys.version}")
print(f"Platform: {platform.platform()}")
try:
    import ccxt
    print("ccxt installed")
except ImportError:
    print("ccxt NOT installed")
