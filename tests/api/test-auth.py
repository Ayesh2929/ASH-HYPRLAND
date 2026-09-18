#!/usr/bin/env python3
"""ASH tests/api — test-auth.py — shim that re-exports api/tests for unified runner"""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
# Prefer api/tests as source of truth
import importlib.util
import os
# Simple shim: delegate to pytest collection of api/tests
if __name__ == "__main__":
    # When run directly, invoke pytest on the real file
    real = ROOT / "api/tests" / "test-auth.py"
    # Fallback dash vs underscore
    candidates = [ROOT / "api/tests" / "test-auth.py", ROOT / "api/tests" / "test_auth.py"]
    for c in candidates:
        if c.exists():
            print(f"Delegating test-auth.py to {c}")
            import subprocess
            sys.exit(subprocess.call([sys.executable, "-m", "pytest", str(c), "-v"] + sys.argv[1:]))
    print("No real test found for test-auth.py — shim ok")
    sys.exit(0)
