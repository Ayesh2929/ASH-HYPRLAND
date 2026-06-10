# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PYTHON REPL STARTUP                          ║
# ║           Enhanced Python interactive shell                                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

import os
import sys
import atexit
import readline
import rlcompleter

# ═══════════════════════════════════════════════════════════════════════════════
# 📜 HISTORY
# ═══════════════════════════════════════════════════════════════════════════════

HISTORY_FILE = os.path.expanduser("~/.cache/python/repl_history")
os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)

try:
    readline.read_history_file(HISTORY_FILE)
    readline.set_history_length(10000)
except FileNotFoundError:
    pass

atexit.register(readline.write_history_file, HISTORY_FILE)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 TAB COMPLETION
# ═══════════════════════════════════════════════════════════════════════════════

readline.set_completer(rlcompleter.Completer().complete)
readline.parse_and_bind("tab: complete")

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLORS
# ═══════════════════════════════════════════════════════════════════════════════

# Enable colored output in REPL
sys.ps1 = "\001\033[1;35m\002>>> \001\033[0m\002"
sys.ps2 = "\001\033[1;34m\002... \001\033[0m\002"

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 COMMON IMPORTS
# ═══════════════════════════════════════════════════════════════════════════════

# Auto-import commonly used modules
try:
    import math
    import re
    import json
    import pathlib
    from pathlib import Path
    from typing import Any, Dict, List, Optional, Tuple, Union
    from datetime import datetime, timedelta
    from collections import defaultdict, Counter, OrderedDict
    from functools import partial, reduce, wraps
    from itertools import chain, combinations, permutations, product
    import subprocess
    import shutil

    print("\001\033[2m\002Python REPL — ASH Dotfiles v3.0")
    print("Imported: math, re, json, pathlib, typing, datetime,")
    print("          collections, functools, itertools, subprocess\033[0m\002")
    print()

except ImportError as e:
    print(f"Note: Some standard imports unavailable: {e}")

# ═══════════════════════════════════════════════════════════════════════════════
# 🛠️ HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def pp(obj: Any, indent: int = 2) -> None:
    """Pretty-print any object."""
    import pprint
    pprint.pprint(obj, indent=indent, width=100)

def j(obj: Any) -> str:
    """Convert object to pretty JSON string."""
    return json.dumps(obj, indent=2, default=str, ensure_ascii=False)

def jp(obj: Any) -> None:
    """Print object as pretty JSON."""
    print(j(obj))

def sh(cmd: str) -> str:
    """Run shell command and return output."""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0 and result.stderr:
        print(f"\033[91mError: {result.stderr.strip()}\033[0m")
    return result.stdout.strip()

def ls(path: str = ".") -> List[str]:
    """List directory contents."""
    p = Path(path)
    return sorted([str(item.name) for item in p.iterdir()])

def cat(path: str) -> str:
    """Read and return file contents."""
    return Path(path).read_text()

def now() -> str:
    """Return current datetime string."""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def clip(text: str) -> None:
    """Copy text to clipboard (Wayland)."""
    subprocess.run(["wl-copy"], input=text.encode(), check=True)
    print(f"Copied: {text[:50]}{'...' if len(text) > 50 else ''}")

def paste() -> str:
    """Paste from clipboard (Wayland)."""
    result = subprocess.run(["wl-paste"], capture_output=True, text=True)
    return result.stdout

# Make helpers available
__builtins__["pp"]   = pp
__builtins__["j"]    = j
__builtins__["jp"]   = jp
__builtins__["sh"]   = sh
__builtins__["ls"]   = ls
__builtins__["cat"]  = cat
__builtins__["now"]  = now
__builtins__["clip"] = clip
__builtins__["paste"] = paste