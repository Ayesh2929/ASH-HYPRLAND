#!/usr/bin/env python3
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  ♿ ASH DOTFILES v5.0 OMEGA — COLOR CONTRAST ANALYSIS ENGINE                              ║
# ║                                                                                           ║
# ║   ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗    ██████╗ ██╗   ██╗                           ║
# ║  ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝   ██╔══██╗╚██╗ ██╔╝                            ║
# ║  ██║     ███████║█████╗  ██║     █████╔╝    ██████╔╝ ╚████╔╝                             ║
# ║  ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗    ██╔═══╝   ╚██╔╝                              ║
# ║  ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗   ██║        ██║                               ║
# ║   ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝   ╚═╝        ╚═╝                               ║
# ║                                                                                           ║
# ║  Version:   5.0.0-omega                                                                  ║
# ║  Standards: WCAG 2.1 (A/AA/AAA) · WCAG 3.0 APCA · IEC 61966-2-1                        ║
# ║  Algorithms: Relative Luminance · CIE Lab · OKLCH · Delta-E · Dalton                    ║
# ║  Pipeline:  load → pairs → analyze → colorblind → harmony → score → report              ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

from __future__ import annotations

import json
import math
import os
import re
import sys
import time
import hashlib
import colorsys
import sqlite3
import concurrent.futures
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
from enum import Enum

# ─────────────────────────────────────────────────────────────────────────────
# OPTIONAL IMPORTS
# ─────────────────────────────────────────────────────────────────────────────
try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.colors import LinearSegmentedColormap
    HAS_MATPLOTLIB = True
except ImportError:
    HAS_MATPLOTLIB = False

try:
    from colormath.color_objects import sRGBColor, LabColor
    from colormath.color_conversions import convert_color
    from colormath.color_diff import delta_e_cie2000
    HAS_COLORMATH = True
except ImportError:
    HAS_COLORMATH = False

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn
    from rich.text import Text
    HAS_RICH = True
    console = Console()
except ImportError:
    HAS_RICH = False
    class Console:
        def print(self, *a, **kw): print(*a)
    console = Console()

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS & CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
ENGINE_VERSION    = "5.0.0-omega"
START_TIME        = time.perf_counter()
START_EPOCH       = int(time.time())

# WCAG 2.1 contrast ratio thresholds
WCAG_THRESHOLDS = {
    "A":   {"normal": 3.0,  "large": 1.5},
    "AA":  {"normal": 4.5,  "large": 3.0},
    "AAA": {"normal": 7.0,  "large": 4.5},
}

# Large text classification
TEXT_SIZE_LARGE_PX    = float(os.environ.get("TEXT_SIZE_THRESH", "18"))
TEXT_WEIGHT_BOLD      = float(os.environ.get("TEXT_WEIGHT_THRESH", "700"))

# Catppuccin Mocha ANSI palette (for terminal output)
class C:
    RST  = "\033[0m";  BLD  = "\033[1m";  DIM  = "\033[2m"
    MAUVE= "\033[38;2;203;166;247m";  BLUE  = "\033[38;2;137;180;250m"
    GREEN= "\033[38;2;166;227;161m";  RED   = "\033[38;2;243;139;168m"
    YELL = "\033[38;2;249;226;175m";  PEACH = "\033[38;2;250;179;135m"
    TEAL = "\033[38;2;148;226;213m";  SAP   = "\033[38;2;116;199;236m"
    LAV  = "\033[38;2;180;190;254m";  TEXT  = "\033[38;2;205;214;244m"
    SUB  = "\033[38;2;166;173;200m";  OVR   = "\033[38;2;108;112;134m"
    PINK = "\033[38;2;245;194;231m";  MAR   = "\033[38;2;235;160;172m"
    SKY  = "\033[38;2;137;220;235m";  RW    = "\033[38;2;245;224;220m"

def log(icon: str, color: str, msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    elapsed = int(time.perf_counter() - START_TIME)
    print(f"{color}{icon}{C.RST} {C.DIM}[{ts} +{elapsed}s]{C.RST} {C.TEXT}{msg}{C.RST}")

def log_pass(msg: str)   : log("✅", C.GREEN, msg)
def log_fail(msg: str)   : log("❌", C.RED,   msg)
def log_warn(msg: str)   : log("⚠️ ", C.YELL,  msg)
def log_info(msg: str)   : log("ℹ️ ", C.BLUE,  msg)
def log_check(msg: str)  : log("♿", C.MAUVE, msg)
def log_pair(msg: str)   : log("🎨", C.PINK,  msg)
def log_cb(msg: str)     : log("👓", C.TEAL,  msg)
def log_apca(msg: str)   : log("🔮", C.LAV,   msg)
def log_score(msg: str)  : log("📊", C.SAP,   msg)
def log_report(msg: str) : log("📋", C.PEACH, msg)
def log_debug(msg: str)  :
    if os.environ.get("VERBOSE","false") == "true":
        log("🔎", C.OVR, msg)

# ─────────────────────────────────────────────────────────────────────────────
# DATA MODELS
# ─────────────────────────────────────────────────────────────────────────────

class WCAGLevel(Enum):
    NONE = "none"
    A    = "A"
    AA   = "AA"
    AAA  = "AAA"

class TextSize(Enum):
    NORMAL = "normal"
    LARGE  = "large"
    UI     = "ui"

class Priority(Enum):
    CRITICAL    = "critical"
    HIGH        = "high"
    MEDIUM      = "medium"
    LOW         = "low"
    DECORATIVE  = "decorative"

@dataclass
class RGBColor:
    r: float  # 0-1
    g: float  # 0-1
    b: float  # 0-1

    @classmethod
    def from_hex(cls, hex_color: str) -> "RGBColor":
        h = hex_color.strip().lstrip("#")
        if len(h) == 3:
            h = "".join(c*2 for c in h)
        r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
        return cls(r, g, b)

    def to_hex(self) -> str:
        return f"#{int(self.r*255):02x}{int(self.g*255):02x}{int(self.b*255):02x}"

    def luminance(self) -> float:
        """Relative luminance per WCAG 2.1 / IEC 61966-2-1."""
        def linearize(c: float) -> float:
            return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        rl, gl, bl = linearize(self.r), linearize(self.g), linearize(self.b)
        return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl

    def to_oklch(self) -> Tuple[float, float, float]:
        """Convert sRGB → OKLCH (perceptually uniform)."""
        # sRGB → Linear
        def linearize(c: float) -> float:
            return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        rl, gl, bl = linearize(self.r), linearize(self.g), linearize(self.b)
        # Linear RGB → OKLab (Björn Ottosson 2020)
        l = 0.4122214708*rl + 0.5363325363*gl + 0.0514459929*bl
        m = 0.2119034982*rl + 0.6806995451*gl + 0.1073969566*bl
        s = 0.0883024619*rl + 0.2817188376*gl + 0.6299787005*bl
        l_, m_, s_ = l**(1/3), m**(1/3), s**(1/3)
        L = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
        a = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
        b = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
        # OKLab → OKLCH
        C_val = math.sqrt(a**2 + b**2)
        H_val = math.degrees(math.atan2(b, a)) % 360
        return (round(L,4), round(C_val,4), round(H_val,2))

    def to_hsl(self) -> Tuple[float, float, float]:
        """Convert to HSL (0-360, 0-100, 0-100)."""
        h, l, s = colorsys.rgb_to_hls(self.r, self.g, self.b)
        return (h * 360, s * 100, l * 100)

    def to_lab(self) -> Tuple[float, float, float]:
        """Convert sRGB → CIE L*a*b* (D65 illuminant)."""
        def linearize(c: float) -> float:
            return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
        rl, gl, bl = linearize(self.r), linearize(self.g), linearize(self.b)
        # sRGB → XYZ (D65)
        X = rl*0.4124564 + gl*0.3575761 + bl*0.1804375
        Y = rl*0.2126729 + gl*0.7151522 + bl*0.0721750
        Z = rl*0.0193339 + gl*0.1191920 + bl*0.9503041
        # XYZ → Lab (D65 white point)
        Xn, Yn, Zn = 0.95047, 1.00000, 1.08883
        def f(t: float) -> float:
            return t**(1/3) if t > 0.008856 else 7.787*t + 16/116
        fx, fy, fz = f(X/Xn), f(Y/Yn), f(Z/Zn)
        L = 116*fy - 16
        a = 500*(fx - fy)
        b = 200*(fy - fz)
        return (round(L,3), round(a,3), round(b,3))

    def simulate_colorblind(self, cb_type: str) -> "RGBColor":
        """
        Simulate color blindness using Brettel/Vienot matrices.
        Returns the color as perceived by someone with the given condition.
        """
        # Dalton simulation matrices (linearized sRGB space)
        MATRICES = {
            "deuteranopia": [
                [0.367322, 0.860646, -0.227968],
                [0.280085, 0.672501,  0.047413],
                [-0.011820, 0.042940, 0.968881],
            ],
            "protanopia": [
                [0.152286, 1.052583, -0.204868],
                [0.114503, 0.786281,  0.099216],
                [-0.003882, -0.048116, 1.051998],
            ],
            "tritanopia": [
                [1.255528, -0.076749, -0.178779],
                [-0.078411, 0.930809,  0.147602],
                [0.004733, 0.691367,   0.303900],
            ],
            "deuteranomaly": [
                [0.547494, 0.607765, -0.155259],
                [0.181692, 0.781361,  0.036947],
                [-0.010410, 0.027275,  0.983136],
            ],
            "protanomaly": [
                [0.458064, 0.679578, -0.137642],
                [0.092785, 0.846313,  0.060902],
                [-0.007494, -0.016807, 1.024301],
            ],
            "tritanomaly": [
                [1.017277, 0.027029, -0.044306],
                [-0.006113, 0.958479,  0.047634],
                [0.006379,  0.248708,  0.744913],
            ],
            "achromatopsia": [
                [0.299, 0.587, 0.114],
                [0.299, 0.587, 0.114],
                [0.299, 0.587, 0.114],
            ],
            "achromatomaly": [
                [0.618, 0.320, 0.062],
                [0.163, 0.775, 0.062],
                [0.163, 0.320, 0.516],
            ],
        }

        cb_lower = cb_type.lower()
        matrix = MATRICES.get(cb_lower)
        if not matrix:
            return self

        # Linearize
        def linearize(c: float) -> float:
            return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
        def delinearize(c: float) -> float:
            return 12.92*c if c <= 0.0031308 else 1.055*c**(1/2.4)-0.055

        lr, lg, lb = linearize(self.r), linearize(self.g), linearize(self.b)

        # Apply matrix
        nr = matrix[0][0]*lr + matrix[0][1]*lg + matrix[0][2]*lb
        ng = matrix[1][0]*lr + matrix[1][1]*lg + matrix[1][2]*lb
        nb = matrix[2][0]*lr + matrix[2][1]*lg + matrix[2][2]*lb

        # Delinearize and clamp
        return RGBColor(
            r=max(0.0, min(1.0, delinearize(nr))),
            g=max(0.0, min(1.0, delinearize(ng))),
            b=max(0.0, min(1.0, delinearize(nb))),
        )


@dataclass
class ContrastResult:
    """Result of a single color pair contrast check."""
    # Pair identification
    fg_key:     str
    bg_key:     str
    fg_hex:     str
    bg_hex:     str
    label:      str
    size:       str = "normal"
    priority:   str = "medium"

    # WCAG 2.1
    contrast_ratio: float = 0.0
    fg_luminance:   float = 0.0
    bg_luminance:   float = 0.0
    wcag_aa_pass:   bool  = False
    wcag_aaa_pass:  bool  = False
    wcag_a_pass:    bool  = False
    threshold_used: float = 4.5

    # APCA
    apca_lc:        Optional[float] = None
    apca_pass:      Optional[bool]  = None

    # Delta-E
    delta_e:        Optional[float] = None
    delta_e_pass:   Optional[bool]  = None

    # OKLCH
    fg_oklch:       Optional[Tuple] = None
    bg_oklch:       Optional[Tuple] = None

    # CIE Lab
    fg_lab:         Optional[Tuple] = None
    bg_lab:         Optional[Tuple] = None

    # Color blindness
    cb_results:     Dict[str, Dict] = field(default_factory=dict)
    cb_pass:        bool = True

    # Overall
    overall_pass:   bool  = False
    fail_reason:    str   = ""
    recommendation: str   = ""
    severity:       str   = "info"   # info/warning/error/critical

    def to_dict(self) -> Dict:
        return asdict(self)


@dataclass
class ThemeAnalysis:
    """Complete analysis result for a theme."""
    theme_name:   str
    colors_file:  str
    session_id:   str
    timestamp:    str

    # Results
    results:      List[ContrastResult] = field(default_factory=list)

    # Statistics
    pairs_checked:    int   = 0
    pairs_passed:     int   = 0
    pairs_failed:     int   = 0
    pairs_warned:     int   = 0
    critical_failures:int   = 0
    min_ratio:        float = 999.0
    max_ratio:        float = 0.0
    avg_ratio:        float = 0.0
    min_apca_lc:      float = 999.0

    # Overall
    overall_score:    float = 0.0
    grade:            str   = "F"
    wcag_level:       str   = "none"
    passed:           bool  = False
    colorblind_pass:  bool  = True
    colorblind_fails: int   = 0

    # Trend
    score_delta:         float = 0.0
    regression_detected: bool  = False


# ─────────────────────────────────────────────────────────────────────────────
# COLOR LOADING
# ─────────────────────────────────────────────────────────────────────────────

HEX_PATTERN = re.compile(r'^#?[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$')

def load_colors_from_file(path: str) -> Dict[str, str]:
    """Load color palette from a colors.json file."""
    try:
        with open(path) as f:
            raw = json.load(f)
        # Handle nested {"colors": {...}} or flat {"name": "#hex"}
        colors = raw.get("colors", raw) if isinstance(raw, dict) else {}
        # Filter to valid hex colors
        result = {}
        for k, v in colors.items():
            if isinstance(v, str) and HEX_PATTERN.match(v.strip()):
                result[k] = v.strip() if v.startswith("#") else f"#{v.strip()}"
            elif isinstance(v, dict):
                # Nested: {"hex": "#...", ...}
                for sub_k in ("hex", "color", "value"):
                    sub_v = v.get(sub_k, "")
                    if isinstance(sub_v, str) and HEX_PATTERN.match(sub_v.strip()):
                        result[k] = sub_v.strip()
                        break
        return result
    except Exception as e:
        log_warn(f"Failed to load colors from {path}: {e}")
        return {}


def resolve_color(key_or_hex: str, palette: Dict[str, str]) -> Optional[str]:
    """Resolve a color key name or hex value to a hex string."""
    if HEX_PATTERN.match(key_or_hex.strip()):
        return key_or_hex if key_or_hex.startswith("#") else f"#{key_or_hex}"
    return palette.get(key_or_hex)

# ─────────────────────────────────────────────────────────────────────────────
# AUTO PAIR GENERATION
# ─────────────────────────────────────────────────────────────────────────────

# Critical UI pairs by semantic role
CRITICAL_PAIR_TEMPLATES = {
    "text":      [("base","text","Body text on background","normal","critical"),
                  ("mantle","text","Text on mantle","normal","critical"),
                  ("crust","text","Text on crust","normal","high")],
    "subtext":   [("base","subtext0","Subtext on background","normal","high"),
                  ("base","subtext1","Subtext1 on background","normal","medium"),
                  ("surface0","subtext0","Subtext on surface","normal","medium")],
    "overlay":   [("surface0","overlay0","Overlay on surface","normal","medium"),
                  ("surface1","overlay1","Overlay on surface1","normal","medium"),
                  ("base","overlay2","Deep overlay on base","normal","low")],
    "accents":   [("base","blue","Blue accent on base","normal","high"),
                  ("base","mauve","Mauve/accent on base","normal","high"),
                  ("base","green","Green on base","normal","high"),
                  ("base","red","Red on base","normal","high"),
                  ("base","yellow","Yellow on base","normal","high"),
                  ("base","peach","Peach on base","normal","medium"),
                  ("base","teal","Teal on base","normal","medium"),
                  ("base","sapphire","Sapphire on base","normal","medium"),
                  ("base","lavender","Lavender on base","normal","medium")],
    "surface":   [("surface0","text","Text on surface","normal","high"),
                  ("surface1","text","Text on surface1","normal","high"),
                  ("surface2","text","Text on surface2","normal","medium")],
    "status":    [("base","maroon","Error/maroon","normal","high"),
                  ("base","pink","Pink on base","normal","low"),
                  ("base","flamingo","Flamingo on base","normal","low"),
                  ("base","rosewater","Rosewater on base","large","low")],
}

STANDARD_ADDITIONAL = [
    ("mantle","subtext0","Subtext on mantle","normal","medium"),
    ("crust","subtext0","Subtext on crust","normal","medium"),
    ("surface0","blue","Blue on surface","normal","high"),
    ("surface0","mauve","Mauve on surface","normal","high"),
    ("surface0","green","Green on surface","normal","high"),
    ("surface0","red","Red on surface","normal","high"),
    ("mantle","text","Text on mantle","normal","high"),
    ("crust","blue","Blue on crust","large","medium"),
    ("base","accent","Accent on base","normal","critical"),
]


def generate_auto_pairs(
    palette: Dict[str, str],
    strategy: str = "standard",
) -> List[Dict]:
    """Generate color pair specifications from a theme palette."""
    pairs = []
    seen = set()

    def add_pair(bg: str, fg: str, label: str, size: str, priority: str) -> None:
        key = f"{fg}:{bg}"
        if key in seen: return
        bg_hex = palette.get(bg)
        fg_hex = palette.get(fg)
        if not (bg_hex and fg_hex): return
        seen.add(key)
        pairs.append({
            "fg":       fg,
            "bg":       bg,
            "label":    label,
            "size":     size,
            "priority": priority,
        })

    # Critical pairs (always included)
    for category, templates in CRITICAL_PAIR_TEMPLATES.items():
        for bg, fg, label, size, priority in templates:
            add_pair(bg, fg, label, size, priority)

    if strategy in ("standard", "exhaustive"):
        for bg, fg, label, size, priority in STANDARD_ADDITIONAL:
            add_pair(bg, fg, label, size, priority)

    if strategy == "exhaustive":
        # Generate all fg/bg combinations for text colors vs backgrounds
        fg_keys = [k for k in ["text","subtext0","subtext1","overlay0","overlay1","overlay2",
                                "blue","mauve","green","red","yellow","teal","sapphire"] if k in palette]
        bg_keys = [k for k in ["base","mantle","crust","surface0","surface1","surface2"] if k in palette]

        for bg in bg_keys:
            for fg in fg_keys:
                add_pair(bg, fg, f"{fg} on {bg}", "normal", "low")

    log_debug(f"Auto-generated {len(pairs)} color pairs (strategy={strategy})")
    return pairs

# ─────────────────────────────────────────────────────────────────────────────
# WCAG 2.1 ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

def contrast_ratio(fg: RGBColor, bg: RGBColor) -> float:
    """Calculate WCAG 2.1 contrast ratio."""
    l1 = fg.luminance()
    l2 = bg.luminance()
    lighter = max(l1, l2)
    darker  = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def wcag_grade(ratio: float, size: str = "normal") -> Tuple[str, str, str]:
    """
    Return (level_achieved, aa_status, aaa_status) for a contrast ratio.
    level_achieved: 'AAA' | 'AA' | 'A' | 'none'
    """
    thr = WCAG_THRESHOLDS
    t   = "large" if size in ("large", "ui") else "normal"

    if ratio >= thr["AAA"][t]:  return "AAA", "pass", "pass"
    if ratio >= thr["AA"][t]:   return "AA",  "pass", "warn"
    if ratio >= thr["A"][t]:    return "A",   "fail", "fail"
    return "none", "fail", "fail"

# ─────────────────────────────────────────────────────────────────────────────
# APCA (Advanced Perceptual Contrast Algorithm) — WCAG 3.0
# ─────────────────────────────────────────────────────────────────────────────

def apca_contrast(fg: RGBColor, bg: RGBColor) -> float:
    """
    Compute APCA Lc value (Accessible Perceptual Contrast Algorithm).
    Implementation of APCA W3C 0.98G-4g.
    Returns Lc value (positive = light bg, negative = dark bg).
    Reference: https://www.myndex.com/APCA/
    """
    # APCA exponents
    NORM_BG  = 0.56
    NORM_TXT = 0.57
    REV_BG   = 0.65
    REV_TXT  = 0.62
    SCALE    = 1.14
    CLIP     = 0.022
    FLOOR_W  = 0.1

    def apca_linearize(rgb: RGBColor) -> float:
        """sRGB → APCA Y (luminance)."""
        def to_linear(c: float) -> float:
            return c ** 2.4 if c > 0.04045 else c / 12.92
        return (0.2126729*to_linear(rgb.r) +
                0.7151522*to_linear(rgb.g) +
                0.0721750*to_linear(rgb.b))

    Y_txt = apca_linearize(fg)
    Y_bg  = apca_linearize(bg)

    # Clip
    Y_txt = max(Y_txt, CLIP)
    Y_bg  = max(Y_bg,  CLIP)

    # Determine polarity
    if Y_bg >= Y_txt:
        # Normal polarity (dark text on light bg)
        Sapc = (Y_bg ** NORM_BG - Y_txt ** NORM_TXT) * SCALE
        if Sapc < FLOOR_W: return 0.0
        return Sapc * 100
    else:
        # Reverse polarity (light text on dark bg)
        Sapc = (Y_bg ** REV_BG - Y_txt ** REV_TXT) * SCALE
        if Sapc > -FLOOR_W: return 0.0
        return Sapc * 100


# ─────────────────────────────────────────────────────────────────────────────
# DELTA-E COLOR DIFFERENCE
# ─────────────────────────────────────────────────────────────────────────────

def delta_e_simple(fg: RGBColor, bg: RGBColor) -> float:
    """
    Compute CIE Delta-E 2000 color difference.
    Uses colormath if available, otherwise CIE76 fallback.
    """
    if HAS_COLORMATH:
        try:
            c1 = sRGBColor(fg.r, fg.g, fg.b)
            c2 = sRGBColor(bg.r, bg.g, bg.b)
            lab1 = convert_color(c1, LabColor)
            lab2 = convert_color(c2, LabColor)
            return float(delta_e_cie2000(lab1, lab2))
        except Exception:
            pass

    # CIE76 fallback (simpler)
    L1, a1, b1 = fg.to_lab()
    L2, a2, b2 = bg.to_lab()
    return math.sqrt((L2-L1)**2 + (a2-a1)**2 + (b2-b1)**2)

# ─────────────────────────────────────────────────────────────────────────────
# COLOR HARMONY ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

def analyze_harmony(colors: List[Tuple[str, str]]) -> Dict:
    """
    Analyze color harmony relationships across the palette.
    Returns harmony types, hue distribution, and balance metrics.
    """
    hues = []
    for name, hex_c in colors:
        try:
            rgb = RGBColor.from_hex(hex_c)
            h, s, l = rgb.to_hsl()
            if s > 5:  # Only saturated colors for hue analysis
                hues.append({"name": name, "hue": h, "sat": s, "lum": l})
        except Exception:
            pass

    if len(hues) < 2:
        return {"type": "monochromatic", "hue_range": 0, "balance": "unknown"}

    hue_values = [h["hue"] for h in hues]
    hue_range   = max(hue_values) - min(hue_values)
    hue_std     = (sum((h - sum(hue_values)/len(hue_values))**2
                       for h in hue_values) / len(hue_values)) ** 0.5

    # Classify harmony type
    if hue_range < 30:
        harmony_type = "analogous"
    elif 150 <= hue_range <= 210:
        harmony_type = "complementary"
    elif 110 <= hue_range <= 130:
        harmony_type = "split-complementary"
    elif 110 <= hue_range <= 145 and len(hues) >= 3:
        harmony_type = "triadic"
    elif hue_range > 210:
        harmony_type = "tetradic"
    else:
        harmony_type = "custom"

    return {
        "type":       harmony_type,
        "hue_range":  round(hue_range, 1),
        "hue_std":    round(hue_std, 1),
        "hue_count":  len(hues),
        "hues":       hues[:10],
    }

# ─────────────────────────────────────────────────────────────────────────────
# SATURATION BALANCE CHECK
# ─────────────────────────────────────────────────────────────────────────────

def check_saturation_balance(fg: RGBColor, bg: RGBColor) -> Optional[str]:
    """
    Detect problematic saturation patterns that cause visual fatigue.
    Returns warning message or None if OK.
    """
    _, fg_s, fg_l = fg.to_hsl()
    _, bg_s, bg_l = bg.to_hsl()

    warnings = []
    # Both highly saturated (chromostereopsis / vibration)
    if fg_s > 85 and bg_s > 85:
        warnings.append("Highly saturated fg+bg may cause chromostereopsis")
    # Very high chroma fg on very high chroma bg of opposite hue
    fg_h, _, _ = fg.to_hsl(); bg_h, _, _ = bg.to_hsl()
    hue_diff = abs(fg_h - bg_h) % 360
    if fg_s > 80 and bg_s > 80 and 150 < hue_diff < 210:
        warnings.append("Complementary high-chroma pair — potential vibration effect")

    return "; ".join(warnings) if warnings else None

# ─────────────────────────────────────────────────────────────────────────────
# RECOMMENDATION ENGINE
# ─────────────────────────────────────────────────────────────────────────────

def suggest_fix(
    fg: RGBColor,
    bg: RGBColor,
    target_ratio: float,
    is_dark_mode: bool = True,
) -> str:
    """
    Generate actionable color fix recommendations for failing pairs.
    Suggests adjusted foreground or background to meet target ratio.
    """
    suggestions = []

    # Try darkening/lightening foreground
    for adj in (0.1, 0.15, 0.20, 0.25, 0.30):
        if is_dark_mode:
            # Lighten foreground
            new_r = min(1.0, fg.r + adj)
            new_g = min(1.0, fg.g + adj)
            new_b = min(1.0, fg.b + adj)
        else:
            # Darken foreground
            new_r = max(0.0, fg.r - adj)
            new_g = max(0.0, fg.g - adj)
            new_b = max(0.0, fg.b - adj)

        new_fg  = RGBColor(new_r, new_g, new_b)
        new_cr  = contrast_ratio(new_fg, bg)
        if new_cr >= target_ratio:
            suggestions.append(
                f"Lighten/darken FG to {new_fg.to_hex()} (ratio: {new_cr:.2f}:1)"
            )
            break

    # Try adjusting background
    for adj in (0.05, 0.10, 0.15):
        if is_dark_mode:
            # Darken background further
            new_r = max(0.0, bg.r - adj)
            new_g = max(0.0, bg.g - adj)
            new_b = max(0.0, bg.b - adj)
        else:
            # Lighten background
            new_r = min(1.0, bg.r + adj)
            new_g = min(1.0, bg.g + adj)
            new_b = min(1.0, bg.b + adj)

        new_bg  = RGBColor(new_r, new_g, new_b)
        new_cr  = contrast_ratio(fg, new_bg)
        if new_cr >= target_ratio:
            suggestions.append(
                f"Adjust BG to {new_bg.to_hex()} (ratio: {new_cr:.2f}:1)"
            )
            break

    return suggestions[0] if suggestions else "Increase luminance difference between fg/bg"

# ─────────────────────────────────────────────────────────────────────────────
# CORE PAIR ANALYZER
# ─────────────────────────────────────────────────────────────────────────────

def analyze_pair(
    pair:         Dict,
    palette:      Dict[str, str],
    wcag_level:   str,
    check_apca:   bool,
    check_cb:     bool,
    cb_types:     List[str],
    cb_threshold: float,
    check_delta_e:bool,
    check_oklch:  bool,
    include_recs: bool,
    apca_thresh:  float,
    min_delta_e:  float,
    check_sat_bal:bool,
) -> ContrastResult:
    """Analyze a single color pair and return a ContrastResult."""

    fg_key = str(pair.get("fg","")).strip()
    bg_key = str(pair.get("bg","")).strip()
    label  = str(pair.get("label",  f"{fg_key} on {bg_key}"))
    size   = str(pair.get("size",   "normal"))
    priority = str(pair.get("priority", "medium"))
    weight = str(pair.get("weight", priority))

    # Resolve colors
    fg_hex = resolve_color(fg_key, palette)
    bg_hex = resolve_color(bg_key, palette)

    if not fg_hex or not bg_hex:
        return ContrastResult(
            fg_key=fg_key, bg_key=bg_key,
            fg_hex=fg_hex or "#unknown", bg_hex=bg_hex or "#unknown",
            label=label, size=size, priority=priority,
            fail_reason="Could not resolve color",
            severity="error",
        )

    fg = RGBColor.from_hex(fg_hex)
    bg = RGBColor.from_hex(bg_hex)

    # WCAG 2.1
    cr      = contrast_ratio(fg, bg)
    fg_lum  = fg.luminance()
    bg_lum  = bg.luminance()
    is_dark = bg_lum < fg_lum   # dark background
    t_key   = "large" if size in ("large","ui") else "normal"

    # Determine threshold
    level_map = {"A": "A", "AA": "AA", "AAA": "AAA", "AA+": "AA", "none": "A"}
    eff_level = level_map.get(wcag_level, "AA")
    threshold = WCAG_THRESHOLDS[eff_level][t_key]

    wcag_a   = cr >= WCAG_THRESHOLDS["A"][t_key]
    wcag_aa  = cr >= WCAG_THRESHOLDS["AA"][t_key]
    wcag_aaa = cr >= WCAG_THRESHOLDS["AAA"][t_key]
    main_pass = cr >= threshold

    # Severity
    if not main_pass:
        sev = "critical" if priority in ("critical","high") else "error"
    elif not wcag_aaa:
        sev = "warning"
    else:
        sev = "info"

    # APCA
    apca_lc = apca_pass = None
    if check_apca:
        apca_lc   = apca_contrast(fg, bg)
        apca_pass = abs(apca_lc) >= apca_thresh

    # Delta-E
    delta_e = delta_e_pass = None
    if check_delta_e:
        delta_e   = delta_e_simple(fg, bg)
        delta_e_pass = delta_e >= min_delta_e

    # OKLCH
    fg_oklch = bg_oklch = None
    if check_oklch:
        fg_oklch = fg.to_oklch()
        bg_oklch = bg.to_oklch()

    # CIE Lab
    fg_lab = bg_lab = None
    fg_lab = fg.to_lab()
    bg_lab = bg.to_lab()

    # Color blindness simulation
    cb_results: Dict[str, Dict] = {}
    cb_overall_pass = True
    if check_cb:
        for cb_type in cb_types:
            sim_fg  = fg.simulate_colorblind(cb_type)
            sim_bg  = bg.simulate_colorblind(cb_type)
            sim_cr  = contrast_ratio(sim_fg, sim_bg)
            sim_pass = sim_cr >= cb_threshold
            if not sim_pass:
                cb_overall_pass = False
            cb_results[cb_type] = {
                "contrast_ratio": round(sim_cr, 3),
                "passed":         sim_pass,
                "fg_simulated":   sim_fg.to_hex(),
                "bg_simulated":   sim_bg.to_hex(),
            }

    # Saturation balance
    sat_warning = None
    if check_sat_bal:
        sat_warning = check_saturation_balance(fg, bg)

    # Recommendation
    recommendation = ""
    if not main_pass and include_recs:
        recommendation = suggest_fix(fg, bg, threshold, is_dark)

    # Fail reason
    fail_reason = ""
    if not main_pass:
        fail_reason = (
            f"Ratio {cr:.2f}:1 < {threshold:.1f}:1 (WCAG {eff_level} {t_key} text)"
        )
    elif sat_warning:
        fail_reason = f"Visual comfort: {sat_warning}"

    return ContrastResult(
        fg_key=fg_key, bg_key=bg_key,
        fg_hex=fg_hex, bg_hex=bg_hex,
        label=label, size=size, priority=priority,
        contrast_ratio=round(cr, 3),
        fg_luminance=round(fg_lum, 5),
        bg_luminance=round(bg_lum, 5),
        wcag_a_pass=wcag_a, wcag_aa_pass=wcag_aa, wcag_aaa_pass=wcag_aaa,
        threshold_used=threshold,
        apca_lc=round(apca_lc, 2) if apca_lc is not None else None,
        apca_pass=apca_pass,
        delta_e=round(delta_e, 3) if delta_e is not None else None,
        delta_e_pass=delta_e_pass,
        fg_oklch=fg_oklch, bg_oklch=bg_oklch,
        fg_lab=fg_lab, bg_lab=bg_lab,
        cb_results=cb_results, cb_pass=cb_overall_pass,
        overall_pass=main_pass,
        fail_reason=fail_reason,
        recommendation=recommendation,
        severity=sev,
    )

# ─────────────────────────────────────────────────────────────────────────────
# SCORING ENGINE
# ─────────────────────────────────────────────────────────────────────────────

PRIORITY_WEIGHTS = {
    "critical":   4.0,
    "high":       3.0,
    "medium":     2.0,
    "low":        1.0,
    "decorative": 0.0,  # Excluded from scoring
}

GRADE_THRESHOLDS = [
    (97, "A+"), (93, "A"), (90, "A-"),
    (87, "B+"), (83, "B"), (80, "B-"),
    (77, "C+"), (73, "C"), (70, "C-"),
    (67, "D+"), (63, "D"), (60, "D-"),
    (0,  "F"),
]

def compute_score(results: List[ContrastResult]) -> Tuple[float, str]:
    """
    Compute weighted accessibility score (0-100) and letter grade.
    Decorative pairs are excluded. Critical pairs have 4x weight.
    """
    total_weight = 0.0
    weighted_pass = 0.0

    for r in results:
        w = PRIORITY_WEIGHTS.get(r.priority, 1.0)
        if w == 0.0:  # Decorative — skip
            continue
        total_weight += w
        if r.overall_pass:
            weighted_pass += w
        elif r.contrast_ratio >= WCAG_THRESHOLDS["A"]["normal"]:
            # Partial credit for A-level
            weighted_pass += w * 0.5

    if total_weight == 0:
        return 100.0, "A+"

    score = (weighted_pass / total_weight) * 100
    score = round(score, 2)

    for threshold, grade in GRADE_THRESHOLDS:
        if score >= threshold:
            return score, grade

    return 0.0, "F"


def determine_wcag_level(results: List[ContrastResult], target: str) -> str:
    """Determine the highest WCAG level achieved across all critical/high pairs."""
    # Check each level
    required_priorities = {"critical", "high", "medium"}

    def level_passes(level: str) -> bool:
        threshold_key = {"A": "A", "AA": "AA", "AAA": "AAA"}.get(level, "AA")
        for r in results:
            if r.priority not in required_priorities: continue
            t = "large" if r.size in ("large","ui") else "normal"
            if r.contrast_ratio < WCAG_THRESHOLDS[threshold_key][t]:
                return False
        return True

    if level_passes("AAA"): return "AAA"
    if level_passes("AA"):  return "AA"
    if level_passes("A"):   return "A"
    return "none"

# ─────────────────────────────────────────────────────────────────────────────
# HEATMAP GENERATOR
# ─────────────────────────────────────────────────────────────────────────────

def generate_heatmap(
    results:    List[ContrastResult],
    palette:    Dict[str, str],
    output_dir: Path,
    style:      str = "catppuccin",
    theme_name: str = "Theme",
) -> Optional[str]:
    """Generate a visual contrast ratio heatmap using matplotlib."""
    if not HAS_MATPLOTLIB or not results:
        return None

    # Catppuccin Mocha palette for chart
    P = {
        "bg":      "#1e1e2e", "surface": "#313244", "surface2": "#585b70",
        "text":    "#cdd6f4", "subtext": "#a6adc8",  "overlay":  "#6c7086",
        "green":   "#a6e3a1", "yellow":  "#f9e2af",   "red":     "#f38ba8",
        "blue":    "#89b4fa", "mauve":   "#cba6f7",   "teal":    "#94e2d5",
        "peach":   "#fab387", "sapphire":"#74c7ec",
    }

    fig = plt.figure(figsize=(22, 14))
    fig.patch.set_facecolor(P["bg"])

    # Layout: heatmap + bar chart
    import matplotlib.gridspec as gridspec
    gs = gridspec.GridSpec(
        2, 2,
        figure=fig,
        hspace=0.42, wspace=0.28,
        left=0.05, right=0.97,
        top=0.88, bottom=0.06,
    )

    ax_heat  = fig.add_subplot(gs[:, 0])    # Left: heatmap
    ax_bar   = fig.add_subplot(gs[0, 1])    # Top-right: bar chart
    ax_info  = fig.add_subplot(gs[1, 1])    # Bottom-right: info

    # ── Heatmap ──────────────────────────────────────────────────────────────
    ax_heat.set_facecolor(P["surface"])
    for sp in ax_heat.spines.values():
        sp.set_edgecolor(P["surface2"]); sp.set_alpha(0.5)

    # Sort results by contrast ratio descending
    sorted_results = sorted(results, key=lambda r: r.contrast_ratio, reverse=True)[:30]

    labels    = [f"{r.fg_key}→{r.bg_key}" for r in sorted_results]
    ratios    = [r.contrast_ratio for r in sorted_results]
    priorities= [r.priority for r in sorted_results]
    sizes     = [r.size for r in sorted_results]

    # Color each bar by pass/fail status
    bar_colors = []
    for r in sorted_results:
        if r.contrast_ratio >= 7.0:   bar_colors.append(P["green"])
        elif r.contrast_ratio >= 4.5: bar_colors.append(P["teal"])
        elif r.contrast_ratio >= 3.0: bar_colors.append(P["yellow"])
        else:                          bar_colors.append(P["red"])

    y_pos = range(len(sorted_results))
    bars  = ax_heat.barh(list(y_pos), ratios, color=bar_colors,
                          alpha=0.85, height=0.75, zorder=3,
                          edgecolor=P["bg"], linewidth=0.6)

    # WCAG threshold lines
    for threshold, color, label in [
        (7.0, P["green"],  "AAA (7.0)"),
        (4.5, P["teal"],   "AA  (4.5)"),
        (3.0, P["yellow"], "A   (3.0)"),
    ]:
        ax_heat.axvline(threshold, color=color, linewidth=1.8,
                        linestyle="--", alpha=0.75, zorder=4, label=label)

    # Value labels on bars
    for bar, ratio in zip(bars, ratios):
        ax_heat.text(
            ratio + 0.1, bar.get_y() + bar.get_height()/2,
            f"{ratio:.1f}:1",
            va="center", ha="left",
            color=P["text"], fontsize=7.5, fontweight="bold",
        )

    ax_heat.set_yticks(list(y_pos))
    ax_heat.set_yticklabels(labels, fontsize=8, color=P["text"])
    ax_heat.set_xlabel("Contrast Ratio", color=P["text"], fontsize=9.5)
    ax_heat.set_xlim(0, max(ratios) * 1.18 if ratios else 12)
    ax_heat.tick_params(colors=P["text"], labelsize=8)
    ax_heat.grid(True, alpha=0.08, color=P["text"], axis="x", zorder=1)
    ax_heat.set_title(
        f"Contrast Ratios — {theme_name}",
        color=P["text"], fontsize=12, fontweight="bold", pad=10,
    )
    ax_heat.legend(
        facecolor=P["surface"], labelcolor=P["text"],
        fontsize=8, framealpha=0.85, loc="lower right",
    )

    # ── Bar chart: pass/fail distribution ────────────────────────────────────
    ax_bar.set_facecolor(P["surface"])
    for sp in ax_bar.spines.values():
        sp.set_edgecolor(P["surface2"]); sp.set_alpha(0.5)
    ax_bar.tick_params(colors=P["text"], labelsize=8.5)
    ax_bar.grid(True, alpha=0.08, color=P["text"], axis="y", zorder=1)

    LEVELS = ["AAA (≥7.0)", "AA (≥4.5)", "A (≥3.0)", "Fail (<3.0)"]
    LEVEL_COLORS = [P["green"], P["teal"], P["yellow"], P["red"]]
    LEVEL_COUNTS = [
        sum(1 for r in results if r.contrast_ratio >= 7.0),
        sum(1 for r in results if 4.5 <= r.contrast_ratio < 7.0),
        sum(1 for r in results if 3.0 <= r.contrast_ratio < 4.5),
        sum(1 for r in results if r.contrast_ratio < 3.0),
    ]

    bars_dist = ax_bar.bar(
        LEVELS, LEVEL_COUNTS, color=LEVEL_COLORS,
        alpha=0.85, width=0.6, zorder=3,
        edgecolor=P["bg"], linewidth=0.8,
    )
    for bar, count in zip(bars_dist, LEVEL_COUNTS):
        if count > 0:
            ax_bar.text(
                bar.get_x() + bar.get_width()/2,
                bar.get_height() + max(LEVEL_COUNTS)*0.03,
                str(count),
                ha="center", color=P["text"],
                fontsize=11, fontweight="bold",
            )

    ax_bar.set_xticklabels(LEVELS, color=P["text"], fontsize=8.5, rotation=10, ha="right")
    ax_bar.set_ylabel("Number of Pairs", color=P["text"], fontsize=9.5)
    ax_bar.set_title("WCAG Level Distribution", color=P["text"],
                     fontsize=11, fontweight="bold", pad=8)

    # ── Info panel ────────────────────────────────────────────────────────────
    ax_info.set_facecolor(P["surface"])
    ax_info.axis("off")

    total    = len(results)
    passed   = sum(1 for r in results if r.overall_pass)
    failed   = total - passed
    avg_cr   = sum(r.contrast_ratio for r in results) / max(total, 1)
    min_cr   = min((r.contrast_ratio for r in results), default=0)
    max_cr   = max((r.contrast_ratio for r in results), default=0)
    critical = sum(1 for r in results if r.priority == "critical" and not r.overall_pass)

    info_rows = [
        ("📊 Total Pairs",     str(total)),
        ("✅ Passed",          f"{passed} ({passed*100//max(total,1)}%)"),
        ("❌ Failed",          f"{failed}"),
        ("🚨 Critical Fails",  str(critical)),
        ("📉 Min Ratio",       f"{min_cr:.2f}:1"),
        ("📈 Max Ratio",       f"{max_cr:.2f}:1"),
        ("📊 Avg Ratio",       f"{avg_cr:.2f}:1"),
    ]

    y_start = 0.95
    for label, value in info_rows:
        ax_info.text(0.05, y_start, label,
                     transform=ax_info.transAxes,
                     color=P["subtext"], fontsize=9.5, va="top")
        ax_info.text(0.65, y_start, value,
                     transform=ax_info.transAxes,
                     color=P["text"], fontsize=9.5,
                     fontweight="bold", ha="right", va="top")
        y_start -= 0.125

    ax_info.set_title("Summary Statistics", color=P["text"],
                      fontsize=11, fontweight="bold", pad=8)

    # ── Global title ──────────────────────────────────────────────────────────
    fig.suptitle(
        f"♿ WCAG Contrast Heatmap — {theme_name}\n"
        f"{passed}/{total} pairs passing · Avg: {avg_cr:.2f}:1 · "
        f"Min: {min_cr:.2f}:1",
        color=P["text"], fontsize=13, fontweight="bold", y=0.97,
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    heatmap_path = output_dir / "contrast-heatmap.png"
    plt.savefig(
        heatmap_path, dpi=150,
        bbox_inches="tight",
        facecolor=P["bg"],
        edgecolor="none",
    )
    plt.close("all")
    log_report(f"Heatmap: {heatmap_path}")
    return str(heatmap_path)

# ─────────────────────────────────────────────────────────────────────────────
# REPORT GENERATORS
# ─────────────────────────────────────────────────────────────────────────────

def generate_json_report(analysis: ThemeAnalysis, output_dir: Path) -> str:
    """Generate comprehensive JSON report."""
    report = {
        "meta": {
            "engine_version": ENGINE_VERSION,
            "session_id":     analysis.session_id,
            "timestamp":      analysis.timestamp,
            "theme_name":     analysis.theme_name,
        },
        "summary": {
            "overall_score":    analysis.overall_score,
            "grade":            analysis.grade,
            "passed":           analysis.passed,
            "wcag_level":       analysis.wcag_level,
            "pairs_checked":    analysis.pairs_checked,
            "pairs_passed":     analysis.pairs_passed,
            "pairs_failed":     analysis.pairs_failed,
            "critical_failures":analysis.critical_failures,
            "min_contrast":     analysis.min_ratio,
            "max_contrast":     analysis.max_ratio,
            "avg_contrast":     analysis.avg_ratio,
            "colorblind_pass":  analysis.colorblind_pass,
            "colorblind_fails": analysis.colorblind_fails,
            "score_delta":      analysis.score_delta,
            "regression":       analysis.regression_detected,
        },
        "pairs": [r.to_dict() for r in analysis.results],
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "contrast-report.json"
    json_path.write_text(json.dumps(report, indent=2, default=str))
    log_report(f"JSON: {json_path}")
    return str(json_path)


def generate_markdown_report(analysis: ThemeAnalysis, output_dir: Path) -> str:
    """Generate rich Markdown report."""
    NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    SCORE_INT = int(analysis.overall_score)
    BAR_W    = 30
    BAR_F    = round(SCORE_INT / 100 * BAR_W)
    SCORE_BAR= "█" * BAR_F + "░" * (BAR_W - BAR_F)
    STATUS   = "✅ PASSED" if analysis.passed else "❌ FAILED"

    GRADE_EMOJI = {
        "A+":"🏆","A":"🥇","A-":"🥇",
        "B+":"🥈","B":"🥈","B-":"🥈",
        "C+":"🥉","C":"🥉","C-":"🥉",
        "D+":"📋","D":"📋","D-":"📋",
        "F":"❌",
    }.get(analysis.grade, "📊")

    lines = [
        f"# ♿ {os.environ.get('REPORT_TITLE','WCAG Contrast Analysis')}",
        f"",
        f"> **Theme:** `{analysis.theme_name}`  ·  **{STATUS}**  "
        f"·  `{NOW}`",
        f"",
        f"## 📊 Accessibility Score",
        f"",
        f"```",
        f"Score: [{SCORE_BAR}] {SCORE_INT}/100   Grade: {GRADE_EMOJI} {analysis.grade}",
        f"```",
        f"",
        f"## 🔍 Summary",
        f"",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| ♿ WCAG Level Achieved | `{analysis.wcag_level}` |",
        f"| 📊 Overall Score | `{SCORE_INT}/100` (Grade {analysis.grade}) |",
        f"| ✅ Pairs Passed | `{analysis.pairs_passed}/{analysis.pairs_checked}` |",
        f"| ❌ Pairs Failed | `{analysis.pairs_failed}` |",
        f"| 🚨 Critical Failures | `{analysis.critical_failures}` |",
        f"| 📉 Min Contrast | `{analysis.min_ratio:.2f}:1` |",
        f"| 📈 Max Contrast | `{analysis.max_ratio:.2f}:1` |",
        f"| 📊 Avg Contrast | `{analysis.avg_ratio:.2f}:1` |",
        f"| 👓 Color Blind Pass | `{'✅ Yes' if analysis.colorblind_pass else '❌ No ({} failures)'.format(analysis.colorblind_fails)}` |",
        f"",
    ]

    # Failed pairs (sorted by severity)
    failed = [r for r in analysis.results if not r.overall_pass]
    if failed:
        lines += [
            f"## ❌ Failing Pairs ({len(failed)})",
            f"",
            f"| Priority | Pair | Ratio | Required | APCA Lc | Recommendation |",
            f"|----------|------|------:|--------:|--------:|---------------|",
        ]
        for r in sorted(failed, key=lambda x: (
            {"critical":0,"high":1,"medium":2,"low":3}.get(x.priority,4)
        )):
            priority_icon = {"critical":"🚨","high":"❌","medium":"⚠️","low":"💛"}.get(r.priority,"📋")
            apca_str = f"`{r.apca_lc:.1f}`" if r.apca_lc is not None else "—"
            rec_str  = r.recommendation[:60] + "..." if len(r.recommendation) > 60 else r.recommendation
            lines.append(
                f"| {priority_icon} `{r.priority}` "
                f"| `{r.fg_key}` → `{r.bg_key}` "
                f"| **`{r.contrast_ratio:.2f}:1`** "
                f"| `{r.threshold_used:.1f}:1` "
                f"| {apca_str} "
                f"| {rec_str} |"
            )
        lines.append("")

    # Passing pairs (condensed)
    passed = [r for r in analysis.results if r.overall_pass]
    if passed and os.environ.get("INCLUDE_PASSING","true") == "true":
        lines += [
            f"## ✅ Passing Pairs ({len(passed)})",
            f"",
            f"| Pair | Ratio | WCAG Level | APCA Lc |",
            f"|------|------:|:----------:|--------:|",
        ]
        for r in sorted(passed, key=lambda x: x.contrast_ratio, reverse=True)[:20]:
            lvl = "AAA" if r.wcag_aaa_pass else "AA" if r.wcag_aa_pass else "A"
            apca_str = f"`{r.apca_lc:.1f}`" if r.apca_lc is not None else "—"
            lines.append(
                f"| `{r.fg_key}` → `{r.bg_key}` "
                f"| `{r.contrast_ratio:.2f}:1` "
                f"| `{lvl}` "
                f"| {apca_str} |"
            )
        if len(passed) > 20:
            lines.append(f"\n*... and {len(passed)-20} more passing pairs*")
        lines.append("")

    lines += ["---", f"*♿ ASH v5.0 OMEGA Color Contrast Engine v{ENGINE_VERSION}*"]

    report_content = "\n".join(lines)
    output_dir.mkdir(parents=True, exist_ok=True)
    md_path = output_dir / "contrast-report.md"
    md_path.write_text(report_content, encoding="utf-8")
    log_report(f"Markdown: {md_path}")
    return str(md_path)


def generate_html_report(analysis: ThemeAnalysis, output_dir: Path) -> str:
    """Generate interactive HTML report."""
    NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    P = {
        "bg": "#1e1e2e", "surface": "#313244", "surface2": "#585b70",
        "text": "#cdd6f4", "subtext": "#a6adc8",
        "green": "#a6e3a1", "red": "#f38ba8",
        "yellow": "#f9e2af", "blue": "#89b4fa",
        "mauve": "#cba6f7", "teal": "#94e2d5",
    }

    SCORE_INT = int(analysis.overall_score)
    score_color = (
        P["green"] if SCORE_INT >= 80 else
        P["yellow"] if SCORE_INT >= 60 else
        P["red"]
    )

    pair_rows = ""
    for r in sorted(analysis.results,
                     key=lambda x: (0 if not x.overall_pass else 1, -x.contrast_ratio)):
        status_icon = "✅" if r.overall_pass else "❌"
        lvl = "AAA" if r.wcag_aaa_pass else "AA" if r.wcag_aa_pass else "A" if r.wcag_a_pass else "—"
        row_bg = P["surface2"] + "30" if not r.overall_pass else ""
        apca_val = f"{r.apca_lc:.1f}" if r.apca_lc is not None else "—"

        pair_rows += f"""
        <tr style="background:{row_bg}">
          <td style="font-weight:600">{status_icon} {r.label}</td>
          <td><span style="background:{r.fg_hex};padding:2px 8px;border-radius:4px;
                   color:{'#000' if r.fg_luminance>0.4 else '#fff'};font-family:monospace">
                   {r.fg_hex}</span></td>
          <td><span style="background:{r.bg_hex};padding:2px 8px;border-radius:4px;
                   color:{'#000' if r.bg_luminance>0.4 else '#fff'};font-family:monospace">
                   {r.bg_hex}</span></td>
          <td style="font-weight:bold;color:{P['green'] if r.contrast_ratio>=4.5 else P['yellow'] if r.contrast_ratio>=3.0 else P['red']}">
              {r.contrast_ratio:.2f}:1</td>
          <td><code style="color:{P['blue']}">{lvl}</code></td>
          <td><code>{apca_val}</code></td>
          <td style="font-size:0.8em;color:{P['subtext']}">{r.priority}</td>
          <td style="font-size:0.8em;color:{P['subtext']}">{r.recommendation[:40] or '—'}</td>
        </tr>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>♿ WCAG Contrast Report — {analysis.theme_name}</title>
  <style>
    :root {{
      --bg:{P["bg"]};--surface:{P["surface"]};--surface2:{P["surface2"]};
      --text:{P["text"]};--sub:{P["subtext"]};
      --green:{P["green"]};--red:{P["red"]};--yellow:{P["yellow"]};
      --blue:{P["blue"]};--mauve:{P["mauve"]};--teal:{P["teal"]};
    }}
    *{{box-sizing:border-box;margin:0;padding:0}}
    body{{background:var(--bg);color:var(--text);font-family:'JetBrains Mono',monospace;padding:2rem}}
    h1{{color:var(--mauve);font-size:1.8rem;margin-bottom:.5rem}}
    .subtitle{{color:var(--sub);margin-bottom:2rem;font-size:.9rem}}
    .score-card{{background:var(--surface);border-radius:16px;padding:2rem;
                  margin-bottom:2rem;display:flex;align-items:center;gap:2rem}}
    .score-gauge{{font-size:3.5rem;font-weight:700;color:{score_color};
                   font-family:monospace;min-width:120px;text-align:center}}
    .score-bar{{flex:1}}
    .score-bar-track{{background:var(--surface2);border-radius:8px;height:16px;overflow:hidden}}
    .score-bar-fill{{background:{score_color};height:100%;
                      width:{SCORE_INT}%;border-radius:8px;
                      transition:width 0.5s ease}}
    .stats{{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));
             gap:1rem;margin-bottom:2rem}}
    .stat{{background:var(--surface);border-radius:12px;padding:1rem;
            border-left:3px solid var(--mauve)}}
    .stat-val{{font-size:1.5rem;font-weight:700;color:var(--mauve)}}
    .stat-lbl{{color:var(--sub);font-size:.8rem;margin-top:.25rem}}
    table{{width:100%;border-collapse:collapse;background:var(--surface);
            border-radius:12px;overflow:hidden;margin-bottom:2rem}}
    th{{background:rgba(203,166,247,.15);padding:.75rem 1rem;text-align:left;
         color:var(--mauve);font-size:.85rem}}
    td{{padding:.6rem 1rem;border-bottom:1px solid rgba(255,255,255,.05);font-size:.85rem}}
    tr:last-child td{{border:none}}
    footer{{color:var(--sub);font-size:.75rem;text-align:center;
             margin-top:2rem;border-top:1px solid var(--surface);padding-top:1rem}}
  </style>
</head>
<body>
  <h1>♿ WCAG Contrast Report</h1>
  <p class="subtitle"><strong>{analysis.theme_name}</strong> · {NOW} · Engine v{ENGINE_VERSION}</p>

  <div class="score-card">
    <div class="score-gauge">{SCORE_INT}</div>
    <div class="score-bar">
      <p style="margin-bottom:.5rem;font-weight:700">
        Grade: {analysis.grade} &nbsp;·&nbsp; WCAG {analysis.wcag_level} Achieved
        &nbsp;·&nbsp; {"✅ PASSED" if analysis.passed else "❌ FAILED"}
      </p>
      <div class="score-bar-track"><div class="score-bar-fill"></div></div>
      <p style="margin-top:.5rem;color:var(--sub);font-size:.85rem">
        {analysis.pairs_passed}/{analysis.pairs_checked} pairs passing
      </p>
    </div>
  </div>

  <div class="stats">
    <div class="stat"><div class="stat-val">{analysis.pairs_checked}</div><div class="stat-lbl">Pairs Checked</div></div>
    <div class="stat"><div class="stat-val" style="color:var(--green)">{analysis.pairs_passed}</div><div class="stat-lbl">Pairs Passed</div></div>
    <div class="stat"><div class="stat-val" style="color:var(--red)">{analysis.pairs_failed}</div><div class="stat-lbl">Pairs Failed</div></div>
    <div class="stat"><div class="stat-val">{analysis.critical_failures}</div><div class="stat-lbl">Critical Failures</div></div>
    <div class="stat"><div class="stat-val">{analysis.min_ratio:.2f}:1</div><div class="stat-lbl">Min Contrast</div></div>
    <div class="stat"><div class="stat-val">{analysis.avg_ratio:.2f}:1</div><div class="stat-lbl">Avg Contrast</div></div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Pair</th><th>Foreground</th><th>Background</th>
        <th>Ratio</th><th>WCAG</th><th>APCA</th>
        <th>Priority</th><th>Recommendation</th>
      </tr>
    </thead>
    <tbody>{pair_rows}</tbody>
  </table>

  <footer>♿ ASH Dotfiles v5.0 OMEGA Color Contrast Engine · MIT License</footer>
</body>
</html>"""

    output_dir.mkdir(parents=True, exist_ok=True)
    html_path = output_dir / "contrast-report.html"
    html_path.write_text(html, encoding="utf-8")
    log_report(f"HTML: {html_path}")
    return str(html_path)


def generate_junit_report(analysis: ThemeAnalysis, output_dir: Path) -> str:
    """Generate JUnit XML report for CI test reporting."""
    from xml.etree.ElementTree import Element, SubElement, tostring
    import xml.dom.minidom

    root = Element("testsuites",
                    name=f"WCAG-{analysis.theme_name}",
                    tests=str(analysis.pairs_checked),
                    failures=str(analysis.pairs_failed),
                    errors="0",
                    time=str(int(time.perf_counter() - START_TIME)))

    suite = SubElement(root, "testsuite",
                        name=f"contrast.{analysis.theme_name}",
                        tests=str(analysis.pairs_checked),
                        failures=str(analysis.pairs_failed))

    for r in analysis.results:
        tc = SubElement(suite, "testcase",
                         name=f"contrast.{r.fg_key}_on_{r.bg_key}",
                         classname=f"WCAG.{r.priority}",
                         time=str(round(0.001 * analysis.pairs_checked, 3)))
        if not r.overall_pass:
            failure = SubElement(tc, "failure",
                                  message=r.fail_reason,
                                  type="ContrastViolation")
            failure.text = (
                f"Pair: {r.fg_key} → {r.bg_key}\n"
                f"Ratio: {r.contrast_ratio:.2f}:1 (required {r.threshold_used:.1f}:1)\n"
                f"Fix: {r.recommendation}"
            )

    xml_str = xml.dom.minidom.parseString(tostring(root)).toprettyxml(indent="  ")
    junit_path = output_dir / "contrast-junit.xml"
    junit_path.write_text(xml_str, encoding="utf-8")
    log_report(f"JUnit: {junit_path}")
    return str(junit_path)


def generate_csv_report(analysis: ThemeAnalysis, output_dir: Path) -> str:
    """Generate CSV report for spreadsheet analysis."""
    import csv
    csv_path = output_dir / "contrast-report.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "fg_key","bg_key","fg_hex","bg_hex","label","size","priority",
            "contrast_ratio","wcag_a","wcag_aa","wcag_aaa","apca_lc","delta_e",
            "overall_pass","fail_reason","recommendation",
        ])
        for r in analysis.results:
            writer.writerow([
                r.fg_key, r.bg_key, r.fg_hex, r.bg_hex,
                r.label, r.size, r.priority,
                r.contrast_ratio,
                r.wcag_a_pass, r.wcag_aa_pass, r.wcag_aaa_pass,
                r.apca_lc or "", r.delta_e or "",
                r.overall_pass, r.fail_reason, r.recommendation,
            ])
    log_report(f"CSV: {csv_path}")
    return str(csv_path)


def generate_badges(analysis: ThemeAnalysis, badges_dir: Path) -> None:
    """Generate shields.io compatible badge JSON files."""
    badges_dir.mkdir(parents=True, exist_ok=True)
    SCORE_INT = int(analysis.overall_score)

    def badge(label: str, msg: str, color: str, style: str = "flat-square") -> Dict:
        return {
            "schemaVersion": 1,
            "label":         label,
            "message":       msg,
            "color":         color,
            "style":         style,
            "namedLogo":     "accessibility",
            "logoColor":     "white",
        }

    # WCAG AA badge
    aa_passed = analysis.wcag_level in ("AA","AAA")
    (badges_dir / "wcag-aa.json").write_text(json.dumps(badge(
        "WCAG AA",
        "passing" if aa_passed else "failing",
        "brightgreen" if aa_passed else "red",
    ), indent=2))

    # WCAG AAA badge
    aaa_passed = analysis.wcag_level == "AAA"
    (badges_dir / "wcag-aaa.json").write_text(json.dumps(badge(
        "WCAG AAA",
        "passing" if aaa_passed else "partial",
        "brightgreen" if aaa_passed else "yellow",
    ), indent=2))

    # Score badge
    score_color = "brightgreen" if SCORE_INT >= 80 else "yellow" if SCORE_INT >= 60 else "red"
    (badges_dir / "contrast-score.json").write_text(json.dumps(badge(
        "contrast",
        f"{SCORE_INT}%",
        score_color,
    ), indent=2))

    log_report(f"Badges: {badges_dir}/wcag-aa.json, wcag-aaa.json, contrast-score.json")

# ─────────────────────────────────────────────────────────────────────────────
# TREND TRACKING
# ─────────────────────────────────────────────────────────────────────────────

def init_trend_db(db_path: Path) -> sqlite3.Connection:
    """Initialize SQLite trend tracking database."""
    conn = sqlite3.connect(str(db_path))
    conn.execute("""
        CREATE TABLE IF NOT EXISTS contrast_history (
            id          TEXT PRIMARY KEY,
            session_id  TEXT,
            theme_name  TEXT,
            git_sha     TEXT,
            git_ref     TEXT,
            score       REAL,
            grade       TEXT,
            wcag_level  TEXT,
            pairs_checked INTEGER,
            pairs_failed  INTEGER,
            critical_fails INTEGER,
            min_ratio   REAL,
            avg_ratio   REAL,
            passed      INTEGER,
            timestamp   TEXT
        )
    """)
    conn.commit()
    return conn


def track_trend(analysis: ThemeAnalysis, db_path: Path) -> Tuple[float, bool]:
    """
    Store result and compare against baseline.
    Returns (score_delta, regression_detected).
    """
    conn = init_trend_db(db_path)

    # Get previous score for this theme
    row = conn.execute(
        "SELECT score FROM contrast_history WHERE theme_name=? "
        "AND git_ref=? ORDER BY timestamp DESC LIMIT 1",
        (analysis.theme_name, os.environ.get("BASELINE_REF","main"))
    ).fetchone()

    prev_score   = row[0] if row else analysis.overall_score
    score_delta  = round(analysis.overall_score - prev_score, 2)
    regression   = score_delta < -float(os.environ.get("TREND_REGRESSION","5"))

    # Store current result
    import uuid
    conn.execute("""
        INSERT OR REPLACE INTO contrast_history VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        str(uuid.uuid4()),
        analysis.session_id,
        analysis.theme_name,
        os.environ.get("GITHUB_SHA","")[:8],
        os.environ.get("GITHUB_REF",""),
        analysis.overall_score,
        analysis.grade,
        analysis.wcag_level,
        analysis.pairs_checked,
        analysis.pairs_failed,
        analysis.critical_failures,
        analysis.min_ratio,
        analysis.avg_ratio,
        int(analysis.passed),
        analysis.timestamp,
    ))
    conn.commit()
    conn.close()

    return score_delta, regression

# ─────────────────────────────────────────────────────────────────────────────
# MAIN ENGINE
# ─────────────────────────────────────────────────────────────────────────────

def run_analysis(colors_file: str, config: Dict) -> ThemeAnalysis:
    """Run complete contrast analysis for a single theme file."""

    # Load colors
    palette = load_colors_from_file(colors_file)
    if not palette:
        log_warn(f"No valid colors found in {colors_file}")
        return ThemeAnalysis(
            theme_name=os.path.dirname(colors_file),
            colors_file=colors_file,
            session_id=config["session_id"],
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    # Resolve theme name
    theme_name = config.get("theme_name","").strip()
    if not theme_name:
        # Try metadata.json
        meta_path = Path(colors_file).parent / "metadata.json"
        if meta_path.exists():
            try:
                meta = json.loads(meta_path.read_text())
                theme_name = meta.get("name","")
            except Exception:
                pass
        if not theme_name:
            theme_name = Path(colors_file).parent.name

    log_check(f"Analyzing: {C.BLD}{theme_name}{C.RST} ({len(palette)} colors)")

    # ── Build pair list ──────────────────────────────────────────────────────
    pairs: List[Dict] = []

    # User-provided pairs
    pairs_json = config.get("color_pairs","").strip()
    if pairs_json:
        try:
            user_pairs = json.loads(pairs_json)
            if isinstance(user_pairs, list):
                pairs.extend(user_pairs)
        except json.JSONDecodeError:
            log_warn(f"Could not parse color_pairs JSON")

    # Auto-generated pairs
    if config.get("auto_pairs", True):
        strategy = config.get("auto_pairs_strategy","standard")
        auto = generate_auto_pairs(palette, strategy)
        # Merge: avoid duplicates
        existing_keys = {(p["fg"], p["bg"]) for p in pairs}
        for p in auto:
            if (p["fg"], p["bg"]) not in existing_keys:
                pairs.append(p)

    if not pairs:
        log_warn("No color pairs to analyze — using fallback minimal set")
        pairs = [
            {"fg":"text","bg":"base","label":"Body text","size":"normal","priority":"critical"},
            {"fg":"subtext0","bg":"base","label":"Subtext","size":"normal","priority":"high"},
        ]

    # Mark required pairs as critical
    required_keys = set(config.get("required_pairs","").replace(" ","").split(","))
    for p in pairs:
        if p.get("fg","") in required_keys or p.get("bg","") in required_keys:
            p["priority"] = "critical"

    log_pair(f"Analyzing {len(pairs)} color pairs...")

    # ── Analyze pairs (parallel) ─────────────────────────────────────────────
    cb_types = []
    if config.get("check_colorblind", True):
        cb_raw = config.get("cb_types","deuteranopia,protanopia,tritanopia")
        if cb_raw == "all":
            cb_types = ["deuteranopia","protanopia","tritanopia",
                        "deuteranomaly","protanomaly","tritanomaly",
                        "achromatopsia","achromatomaly"]
        else:
            cb_types = [t.strip() for t in cb_raw.split(",") if t.strip()]

    def analyze_one(pair: Dict) -> ContrastResult:
        return analyze_pair(
            pair           = pair,
            palette        = palette,
            wcag_level     = config["wcag_level"],
            check_apca     = config.get("check_apca", True),
            check_cb       = config.get("check_colorblind", True),
            cb_types       = cb_types,
            cb_threshold   = float(config.get("cb_threshold", 3.0)),
            check_delta_e  = config.get("check_delta_e", True),
            check_oklch    = config.get("check_oklch", True),
            include_recs   = config.get("include_recs", True),
            apca_thresh    = float(config.get("apca_threshold", 60)),
            min_delta_e    = float(config.get("min_delta_e", 2.0)),
            check_sat_bal  = config.get("check_sat_bal", True),
        )

    workers = min(int(config.get("parallel_workers", 4)), len(pairs), 8)
    results: List[ContrastResult] = []

    if workers > 1 and len(pairs) > 10:
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {executor.submit(analyze_one, p): p for p in pairs}
            for future in concurrent.futures.as_completed(futures):
                try:
                    results.append(future.result())
                except Exception as e:
                    log_warn(f"Pair analysis error: {e}")
    else:
        for pair in pairs:
            results.append(analyze_one(pair))

    # ── Compute statistics ────────────────────────────────────────────────────
    all_ratios = [r.contrast_ratio for r in results]
    min_ratio  = min(all_ratios) if all_ratios else 0.0
    max_ratio  = max(all_ratios) if all_ratios else 0.0
    avg_ratio  = sum(all_ratios) / max(len(all_ratios), 1)

    apca_vals    = [r.apca_lc for r in results if r.apca_lc is not None]
    min_apca_lc  = min(apca_vals, key=abs) if apca_vals else 0.0

    pairs_passed = sum(1 for r in results if r.overall_pass)
    pairs_failed = len(results) - pairs_passed
    critical_f   = sum(1 for r in results
                        if r.priority == "critical" and not r.overall_pass)
    warned       = sum(1 for r in results
                        if r.overall_pass and not r.wcag_aaa_pass)

    cb_fails     = sum(1 for r in results if not r.cb_pass)
    cb_pass      = cb_fails == 0

    # Score
    score, grade = compute_score(results)
    wcag_achieved = determine_wcag_level(results, config["wcag_level"])

    # Overall pass
    fail_threshold_pct = float(config.get("fail_threshold_pct", 20))
    fail_pct           = (pairs_failed / max(len(results), 1)) * 100
    overall_passed = (
        (config["wcag_level"] == "none") or
        (not config.get("fail_on_violation", True) and critical_f == 0) or
        (critical_f == 0 and fail_pct <= fail_threshold_pct and
         score >= float(config.get("minimum_score", 75)))
    )

    # Log summary
    pass_col = C.GREEN if overall_passed else C.RED
    log_score(
        f"Score: {pass_col}{score:.1f}/100 ({grade}){C.RST} · "
        f"WCAG: {wcag_achieved} · "
        f"{pairs_passed}/{len(results)} passing"
    )

    if critical_f > 0:
        log_fail(f"Critical failures: {critical_f}")
    if cb_fails > 0:
        log_cb(f"Color blindness failures: {cb_fails}")

    analysis = ThemeAnalysis(
        theme_name=theme_name,
        colors_file=colors_file,
        session_id=config["session_id"],
        timestamp=datetime.now(timezone.utc).isoformat(),
        results=results,
        pairs_checked=len(results),
        pairs_passed=pairs_passed,
        pairs_failed=pairs_failed,
        pairs_warned=warned,
        critical_failures=critical_f,
        min_ratio=round(min_ratio, 3),
        max_ratio=round(max_ratio, 3),
        avg_ratio=round(avg_ratio, 3),
        min_apca_lc=round(min_apca_lc, 2),
        overall_score=round(score, 2),
        grade=grade,
        wcag_level=wcag_achieved,
        passed=overall_passed,
        colorblind_pass=cb_pass,
        colorblind_fails=cb_fails,
    )

    return analysis


# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    """Main entry point — reads environment, runs analysis, writes outputs."""

    print("")
    print(f"{C.MAUVE}{C.BLD}")
    print("  ╔══════════════════════════════════════════════════════════════╗")
    print("  ║  ♿ ASH Color Contrast Analysis Engine v5.0.0-omega            ║")
    print("  ╚══════════════════════════════════════════════════════════════╝")
    print(f"{C.RST}")

    # ── Load configuration from environment ───────────────────────────────────
    SESSION_ID   = os.environ.get("SESSION_ID",   f"contrast-{int(time.time())}")
    WORK_DIR     = Path(os.environ.get("WORK_DIR",   "/tmp/.contrast-engine"))
    OUTPUT_DIR   = Path(os.environ.get("WORKSPACE",  ".")) / \
                   os.environ.get("OUTPUT_DIR", ".contrast-reports")
    THEME_FILES  = [f for f in os.environ.get("THEME_FILES","").split(";") if f]
    DRY_RUN      = os.environ.get("DRY_RUN","false") == "true"

    config = {
        "session_id":         SESSION_ID,
        "wcag_level":         os.environ.get("WCAG_LEVEL",         "AA"),
        "check_apca":         os.environ.get("CHECK_APCA",         "true") == "true",
        "apca_threshold":     float(os.environ.get("APCA_THRESHOLD","60")),
        "color_pairs":        os.environ.get("COLOR_PAIRS",        ""),
        "auto_pairs":         os.environ.get("AUTO_PAIRS",         "true") == "true",
        "auto_pairs_strategy":os.environ.get("AUTO_PAIRS_STRATEGY","standard"),
        "required_pairs":     os.environ.get("REQUIRED_PAIRS",     ""),
        "check_colorblind":   os.environ.get("CHECK_CB",           "true") == "true",
        "cb_types":           os.environ.get("CB_TYPES",           "deuteranopia,protanopia,tritanopia"),
        "cb_threshold":       float(os.environ.get("CB_THRESHOLD", "3.0")),
        "check_delta_e":      os.environ.get("CHECK_DELTA_E",      "true") == "true",
        "check_oklch":        os.environ.get("CHECK_OKLCH",        "true") == "true",
        "check_harmony":      os.environ.get("CHECK_HARMONY",      "true") == "true",
        "check_sat_bal":      os.environ.get("CHECK_SAT_BALANCE",  "true") == "true",
        "min_delta_e":        float(os.environ.get("MIN_DELTA_E",  "2.0")),
        "minimum_score":      float(os.environ.get("MINIMUM_SCORE","75")),
        "fail_on_violation":  os.environ.get("FAIL_ON_VIOLATION",  "true") == "true",
        "fail_on_warning":    os.environ.get("FAIL_ON_WARNING",    "false") == "true",
        "fail_threshold_pct": float(os.environ.get("FAIL_THRESHOLD_PCT","20")),
        "report_formats":     os.environ.get("REPORT_FORMATS",     "json,markdown,summary"),
        "include_passing":    os.environ.get("INCLUDE_PASSING",    "true") == "true",
        "include_recs":       os.environ.get("INCLUDE_RECS",       "true") == "true",
        "gen_heatmap":        os.environ.get("GEN_HEATMAP",        "true") == "true",
        "heatmap_style":      os.environ.get("HEATMAP_STYLE",      "catppuccin"),
        "track_trends":       os.environ.get("TRACK_TRENDS",       "true") == "true",
        "gen_badges":         os.environ.get("GEN_BADGES",         "true") == "true",
        "badges_dir":         os.environ.get("BADGES_DIR",         "assets/badges"),
        "parallel_workers":   int(os.environ.get("PARALLEL_WORKERS","4")),
        "theme_name":         os.environ.get("THEME_NAME",         ""),
        "verbose":            os.environ.get("VERBOSE",            "false") == "true",
    }

    formats = config["report_formats"]
    if formats == "all":
        formats = "json,markdown,html,csv,junit,badge,summary"
    formats_set = set(f.strip() for f in formats.split(","))

    # ── Dry run ────────────────────────────────────────────────────────────────
    if DRY_RUN:
        log_info("Dry run — validation only, no fail conditions")

    # ── Process each theme file ────────────────────────────────────────────────
    all_analyses: List[ThemeAnalysis] = []
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    DB_PATH = WORK_DIR / "contrast-history.db"

    for colors_file in THEME_FILES:
        if not colors_file or not Path(colors_file).exists():
            log_warn(f"Skipping missing file: {colors_file}")
            continue

        log_info(f"File: {colors_file}")
        try:
            analysis = run_analysis(colors_file, config)
            all_analyses.append(analysis)
        except Exception as e:
            log_fail(f"Analysis failed for {colors_file}: {e}")
            if config.get("verbose"):
                import traceback; traceback.print_exc()

    if not all_analyses:
        log_fail("No themes successfully analyzed")
        sys.exit(1)

    # ── Aggregate results (use first/primary theme for single-file runs) ───────
    primary = all_analyses[0]
    if len(all_analyses) > 1:
        # Merge statistics
        total_pairs   = sum(a.pairs_checked   for a in all_analyses)
        total_passed  = sum(a.pairs_passed    for a in all_analyses)
        total_failed  = sum(a.pairs_failed    for a in all_analyses)
        total_critical= sum(a.critical_failures for a in all_analyses)
        avg_score     = sum(a.overall_score   for a in all_analyses) / len(all_analyses)
        min_ratio_all = min(a.min_ratio       for a in all_analyses)
        avg_ratio_all = sum(a.avg_ratio       for a in all_analyses) / len(all_analyses)
        max_ratio_all = max(a.max_ratio       for a in all_analyses)
        cb_fails_all  = sum(a.colorblind_fails for a in all_analyses)

        _, grade = compute_score([r for a in all_analyses for r in a.results])
        primary.pairs_checked     = total_pairs
        primary.pairs_passed      = total_passed
        primary.pairs_failed      = total_failed
        primary.critical_failures = total_critical
        primary.overall_score     = round(avg_score, 2)
        primary.grade             = grade
        primary.min_ratio         = min_ratio_all
        primary.avg_ratio         = round(avg_ratio_all, 3)
        primary.max_ratio         = max_ratio_all
        primary.colorblind_fails  = cb_fails_all
        primary.colorblind_pass   = cb_fails_all == 0
        primary.passed            = all(a.passed for a in all_analyses)
        primary.results           = [r for a in all_analyses for r in a.results]

    # ── Trend tracking ──────────────────────────────────────────────────────
    if config["track_trends"]:
        try:
            score_delta, regression = track_trend(primary, DB_PATH)
            primary.score_delta         = score_delta
            primary.regression_detected = regression
            if regression:
                log_warn(f"Score regression: {score_delta:+.1f} pts vs baseline")
            else:
                log_info(f"Score trend: {score_delta:+.1f} pts vs baseline")
        except Exception as e:
            log_warn(f"Trend tracking failed: {e}")

    # ── Generate reports ────────────────────────────────────────────────────
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = md_path = html_path = heatmap_path = ""

    if "json" in formats_set or True:  # Always generate JSON
        json_path = generate_json_report(primary, OUTPUT_DIR)

    if "markdown" in formats_set or "summary" in formats_set:
        md_path = generate_markdown_report(primary, OUTPUT_DIR)

    if "html" in formats_set:
        html_path = generate_html_report(primary, OUTPUT_DIR)

    if "csv" in formats_set:
        generate_csv_report(primary, OUTPUT_DIR)

    if "junit" in formats_set:
        generate_junit_report(primary, OUTPUT_DIR)

    if config["gen_heatmap"] and HAS_MATPLOTLIB:
        heatmap_path = generate_heatmap(
            primary.results,
            dict(zip(
                [c for a in all_analyses for r in a.results for c in [r.fg_key, r.bg_key]],
                [c for a in all_analyses for r in a.results for c in [r.fg_hex, r.bg_hex]],
            )),
            OUTPUT_DIR,
            style=config["heatmap_style"],
            theme_name=primary.theme_name,
        ) or ""

    if config["gen_badges"]:
        badges_dir = Path(os.environ.get("WORKSPACE",".")) / config["badges_dir"]
        generate_badges(primary, badges_dir)

    # ── Emit GitHub outputs ────────────────────────────────────────────────
    SCORE_INT = int(primary.overall_score)
    outputs = {
        "passed":              str(primary.passed).lower(),
        "overall_score":       str(primary.overall_score),
        "grade":               primary.grade,
        "wcag_level_achieved": primary.wcag_level,
        "pairs_checked":       str(primary.pairs_checked),
        "pairs_passed":        str(primary.pairs_passed),
        "pairs_failed":        str(primary.pairs_failed),
        "pairs_warned":        str(primary.pairs_warned),
        "critical_failures":   str(primary.critical_failures),
        "min_contrast_ratio":  str(primary.min_ratio),
        "max_contrast_ratio":  str(primary.max_ratio),
        "avg_contrast_ratio":  str(round(primary.avg_ratio, 2)),
        "min_apca_lc":         str(primary.min_apca_lc),
        "colorblind_passed":   str(primary.colorblind_pass).lower(),
        "colorblind_failures": str(primary.colorblind_fails),
        "report_json_path":    json_path,
        "report_markdown_path":md_path,
        "report_html_path":    html_path,
        "heatmap_path":        heatmap_path,
        "score_delta":         str(primary.score_delta),
        "regression_detected": str(primary.regression_detected).lower(),
    }

    gh_output = os.environ.get("GITHUB_OUTPUT", "")
    if gh_output:
        with open(gh_output, "a") as f:
            for k, v in outputs.items():
                f.write(f"{k}={v}\n")

    # ── Final terminal summary ────────────────────────────────────────────
    BAR_W   = 35
    BAR_F   = round(SCORE_INT / 100 * BAR_W)
    SCORE_BAR = "█" * BAR_F + "░" * (BAR_W - BAR_F)
    S_COLOR   = C.GREEN if primary.passed else C.RED

    print("")
    print(f"  {C.MAUVE}{C.BLD}╔══════════════════════════════════════════════════════════════════╗{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}║  ♿ WCAG CONTRAST ANALYSIS COMPLETE                               ║{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}╠══════════════════════════════════════════════════════════════════╣{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}║{C.RST}  {S_COLOR}[{SCORE_BAR}] {SCORE_INT}/100 Grade: {primary.grade}{C.RST}" +
          " " * (20 - len(primary.grade)) + f"{C.MAUVE}{C.BLD}║{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}╠══════════════════════════════════════════════════════════════════╣{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}║{C.RST}  {C.TEXT}WCAG Achieved:{C.RST}  {C.BLD}{primary.wcag_level:6s}{C.RST}  "
          f"{C.TEXT}Passed:{C.RST}  {S_COLOR}{primary.pairs_passed}/{primary.pairs_checked}{C.RST}"
          f"  {C.TEXT}Critical:{C.RST}  {C.RED if primary.critical_failures else C.GREEN}{primary.critical_failures}{C.RST}"
          + " " * 5 + f"{C.MAUVE}{C.BLD}║{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}║{C.RST}  {C.TEXT}Min ratio:{C.RST}    {C.BLUE}{primary.min_ratio:.2f}:1{C.RST}   "
          f"{C.TEXT}Avg ratio:{C.RST} {C.BLUE}{primary.avg_ratio:.2f}:1{C.RST}   "
          f"{C.TEXT}CB fails:{C.RST}  {C.RED if primary.colorblind_fails else C.GREEN}{primary.colorblind_fails}{C.RST}"
          + " " * 5 + f"{C.MAUVE}{C.BLD}║{C.RST}")
    print(f"  {C.MAUVE}{C.BLD}╚══════════════════════════════════════════════════════════════════╝{C.RST}")
    print("")

    # Exit code
    if not primary.passed and not DRY_RUN:
        log_fail(f"WCAG {config['wcag_level']} contrast check FAILED")
        sys.exit(1)
    elif primary.passed:
        log_pass(f"WCAG {config['wcag_level']} contrast check PASSED ✨")


if __name__ == "__main__":
    main()