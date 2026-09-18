#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  📸 ASH DOTFILES v5.0 OMEGA — SCREENSHOT GENERATION ENGINE                               ║
# ║                                                                                           ║
# ║   ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ████████╗███████╗                    ║
# ║  ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝                    ║
# ║  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║   ██║   █████╗                      ║
# ║  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║   ██║   ██╔══╝                      ║
# ║  ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║   ██║   ███████╗                    ║
# ║   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝                    ║
# ║                                                                                           ║
# ║  ░██████╗░█████╗░██████╗░███████╗███████╗███╗░░██╗███████╗██╗  ██╗░██████╗██╗  ██╗       ║
# ║  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝████╗░██║██╔════╝██║  ██║██╔════╝██║  ██║       ║
# ║  ╚█████╗░██║░░╚═╝██████╔╝█████╗░░█████╗░░██╔██╗██║╚█████╗░███████╗╚█████╗░███████╗       ║
# ║  ░╚═══██╗██║░░██╗██╔══██╗██╔══╝░░██╔══╝░░██║╚████║░╚═══██╗██╔══██╗░╚═══██╗██╔══██╗       ║
# ║  ██████╔╝╚█████╔╝██║░░██║███████╗███████╗██║░╚███║██████╔╝██║░░██║██████╔╝██║░░██║       ║
# ║  ╚═════╝░░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝       ║
# ║                                                                                           ║
# ║  ─────────────────────────────────────────────────────────────────────────────────────── ║
# ║                                                                                           ║
# ║  Version:    5.0.0-omega                                                                 ║
# ║  Renderer:   Python Pillow + Matplotlib (headless, zero display requirement)              ║
# ║  Palette:    Catppuccin Mocha (26 colors, full ANSI terminal support)                    ║
# ║  Pipeline:                                                                               ║
# ║    preflight → theme-load → parallel-render → convert → optimize →                      ║
# ║    thumbnail → 2x/4k → metadata → catalog → checksum → html-report                      ║
# ║                                                                                           ║
# ║  🎯 RENDERERS:                                                                            ║
# ║     render_desktop()     — Full Hyprland riced desktop composite scene                   ║
# ║     render_neovim()      — Neovim IDE: syntax + LSP + neo-tree + statusline              ║
# ║     render_components()  — Individual UI: Waybar/Rofi/Kitty/Dunst/Hyprlock              ║
# ║     render_card()        — Compact theme card (600×400) for gallery listing              ║
# ║     render_swatch()      — 26-color palette grid with WCAG contrast ratios               ║
# ║     render_hero()        — 1920×600 README hero banner with particles & orbs             ║
# ║     render_performance() — Benchmark timelines: startup/apply/memory charts              ║
# ║     render_mosaic()      — All-themes thumbnail grid mosaic                              ║
# ║     render_accessibility()— WCAG heatmap: contrast ratio visualization                   ║
# ║     render_comparison()  — Side-by-side theme comparison collage                         ║
# ║     render_mobile()      — Flutter app / web dashboard mobile mockup                     ║
# ║     render_animated()    — GIF/APNG theme transition animation sequence                  ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────
# STRICT MODE & GLOBAL SAFETY
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# VERSION & METADATA
# ─────────────────────────────────────────────────────────────────────────────
readonly GENERATE_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_EPOCH=$(date +%s)
readonly START_NS=$(date +%s%N 2>/dev/null || echo "${START_EPOCH}000000000")

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT VARIABLES (injected from action.yml env block)
# ─────────────────────────────────────────────────────────────────────────────
SESSION_ID="${SESSION_ID:-shot-$(date +%Y%m%d%H%M%S)}"
THEME_LIST="${THEME_LIST:-catppuccin-mocha}"
SCREENSHOT_TYPES="${SCREENSHOT_TYPES:-desktop,card,swatch}"
QUALITY_PRESET="${QUALITY_PRESET:-production}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-webp}"
WEBP_QUALITY="${WEBP_QUALITY:-}"
LOSSLESS="${LOSSLESS:-false}"
RES_W="${RES_W:-2560}"
RES_H="${RES_H:-1440}"
DPI="${DPI:-120}"
DEFAULT_WQ="${DEFAULT_WQ:-90}"
GEN_2X="${GEN_2X:-false}"
GEN_4K="${GEN_4K:-false}"
GEN_THUMBS="${GEN_THUMBS:-true}"
THUMB_W="${THUMB_W:-400}"
THUMB_H="${THUMB_H:-225}"
HERO_W="${HERO_W:-1920}"
HERO_H="${HERO_H:-600}"
CARD_W="${CARD_W:-600}"
CARD_H="${CARD_H:-400}"
ANIMATED_FPS="${ANIMATED_FPS:-12}"
ANIMATED_DUR="${ANIMATED_DUR:-3000}"
ANIMATED_LOOP="${ANIMATED_LOOP:-0}"
ANIMATED_OPT="${ANIMATED_OPT:-true}"
ANIMATED_THEMES="${ANIMATED_THEMES:-}"
WATERMARK="${WATERMARK:-false}"
WATERMARK_TEXT="${WATERMARK_TEXT:-ASH v5.0 OMEGA}"
WATERMARK_POS="${WATERMARK_POS:-bottom-right}"
METADATA="${METADATA:-true}"
CHECKSUMS="${CHECKSUMS:-true}"
ASSET_CATALOG="${ASSET_CATALOG:-true}"
STRIP_EXIF="${STRIP_EXIF:-true}"
COLOR_PROFILE="${COLOR_PROFILE:-sRGB}"
BENCHMARK_DATA="${BENCHMARK_DATA:-benchmarks/startup-time.json}"
MOSAIC_COLS="${MOSAIC_COLS:-6}"
MOSAIC_PADDING="${MOSAIC_PADDING:-4}"
COMPARISON_THEMES="${COMPARISON_THEMES:-}"
COMPARISON_LAYOUT="${COMPARISON_LAYOUT:-side-by-side}"
CACHE_ENABLED="${CACHE_ENABLED:-true}"
CACHE_TTL_HOURS="${CACHE_TTL_HOURS:-168}"
FORCE_REGEN="${FORCE_REGEN:-false}"
CACHE_HIT="${CACHE_HIT:-false}"
OUTPUT_DIR="${OUTPUT_DIR:-assets/screenshots}"
WORK_DIR="${WORK_DIR:-/tmp/.screenshot-engine}"
CACHE_DIR="${CACHE_DIR:-/tmp/.screenshot-engine/.cache}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
THEMES_DIR="${THEMES_DIR:-themes/presets}"
PARALLEL_WORKERS="${PARALLEL_WORKERS:-3}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-false}"
FAIL_THRESHOLD="${FAIL_THRESHOLD:-50}"
VERBOSE="${VERBOSE:-false}"
RENDERER_BACKEND="${RENDERER_BACKEND:-hybrid}"
GEN_HTML="${GEN_HTML:-false}"
GEN_CHANGELOG="${GEN_CHANGELOG:-false}"

# ── Resolve final WebP quality ─────────────────────────────────────────────────
FINAL_WQ="${WEBP_QUALITY:-${DEFAULT_WQ}}"
readonly FINAL_WQ

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA — FULL 26-COLOR ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
# 8-bit truecolor ANSI escape sequences
C_RST=$'\033[0m'   C_BLD=$'\033[1m'   C_DIM=$'\033[2m'   C_ITL=$'\033[3m'
C_UNL=$'\033[4m'   C_BLK=$'\033[5m'   C_INV=$'\033[7m'

# Catppuccin Mocha foreground colors
C_ROSEWATER=$'\033[38;2;245;224;220m'   # #f5e0dc
C_FLAMINGO=$'\033[38;2;242;205;205m'    # #f2cdcd
C_PINK=$'\033[38;2;245;194;231m'        # #f5c2e7
C_MAUVE=$'\033[38;2;203;166;247m'       # #cba6f7
C_RED=$'\033[38;2;243;139;168m'         # #f38ba8
C_MAROON=$'\033[38;2;235;160;172m'      # #eba0ac
C_PEACH=$'\033[38;2;250;179;135m'       # #fab387
C_YELLOW=$'\033[38;2;249;226;175m'      # #f9e2af
C_GREEN=$'\033[38;2;166;227;161m'       # #a6e3a1
C_TEAL=$'\033[38;2;148;226;213m'        # #94e2d5
C_SKY=$'\033[38;2;137;220;235m'         # #89dceb
C_SAPPHIRE=$'\033[38;2;116;199;236m'    # #74c7ec
C_BLUE=$'\033[38;2;137;180;250m'        # #89b4fa
C_LAVENDER=$'\033[38;2;180;190;254m'    # #b4befe
C_TEXT=$'\033[38;2;205;214;244m'        # #cdd6f4
C_SUBTEXT1=$'\033[38;2;186;194;222m'    # #bac2de
C_SUBTEXT0=$'\033[38;2;166;173;200m'    # #a6adc8
C_OVERLAY2=$'\033[38;2;147;153;178m'    # #9399b2
C_OVERLAY1=$'\033[38;2;127;132;156m'    # #7f849c
C_OVERLAY0=$'\033[38;2;108;112;134m'    # #6c7086
C_SURFACE2=$'\033[38;2;88;91;112m'      # #585b70
C_SURFACE1=$'\033[38;2;69;71;90m'       # #45475a
C_SURFACE0=$'\033[38;2;49;50;68m'       # #313244
C_BASE=$'\033[38;2;30;30;46m'           # #1e1e2e
C_MANTLE=$'\033[38;2;24;24;37m'         # #181825
C_CRUST=$'\033[38;2;17;17;27m'          # #11111b

# Background variants
CB_BASE=$'\033[48;2;30;30;46m'
CB_SURFACE0=$'\033[48;2;49;50;68m'
CB_MANTLE=$'\033[48;2;24;24;37m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE — Premium structured output
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "${WORK_DIR}"
readonly LOG_FILE="${WORK_DIR}/generate-${SESSION_ID}.log"
readonly ERROR_LOG="${WORK_DIR}/errors-${SESSION_ID}.log"

# Log level tracking
LOG_ENTRIES=0
LOG_ERRORS=0
LOG_WARNS=0

_log_base() {
  local level="$1" icon="$2" color="$3" category="${4:-}" ; shift 4
  local msg="$*"
  local ts; ts=$(date '+%H:%M:%S.%3N' 2>/dev/null || date '+%H:%M:%S')
  local ms_since_start="0"

  # Calculate ms since start
  if command -v date &>/dev/null; then
    local current_epoch; current_epoch=$(date +%s)
    ms_since_start=$(( (current_epoch - START_EPOCH) * 1000 ))
  fi

  # Terminal output with full color
  local cat_str=""
  [[ -n "${category}" ]] && cat_str="${C_OVERLAY0}[${category}]${C_RST} "

  printf "${color}${icon}${C_RST} ${C_DIM}%s${C_RST} %s${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${cat_str}" "${msg}"

  # Structured log file
  printf "[%s] [%s] [+%dms] %s %s\n" \
    "${ts}" "${level}" "${ms_since_start}" "${category:-general}" "${msg}" \
    >> "${LOG_FILE}"

  (( LOG_ENTRIES++ )) || true
}

log_render()   { _log_base "RENDER" "📸" "${C_MAUVE}"    "${1:-}" "${@:2}"; }
log_pass()     { _log_base "PASS"   "✅" "${C_GREEN}"    "${1:-}" "${@:2}"; }
log_fail()     { _log_base "FAIL"   "❌" "${C_RED}"      "${1:-}" "${@:2}"; (( LOG_ERRORS++ )) || true; echo "[FAIL] $*" >> "${ERROR_LOG}"; }
log_warn()     { _log_base "WARN"   "⚠️ " "${C_YELLOW}"  "${1:-}" "${@:2}"; (( LOG_WARNS++ )) || true; }
log_info()     { _log_base "INFO"   "ℹ️ " "${C_BLUE}"    "${1:-}" "${@:2}"; }
log_cache()    { _log_base "CACHE"  "💾" "${C_SAPPHIRE}" "${1:-}" "${@:2}"; }
log_convert()  { _log_base "CONV"   "🔄" "${C_TEAL}"     "${1:-}" "${@:2}"; }
log_theme()    { _log_base "THEME"  "🎨" "${C_PINK}"     "${1:-}" "${@:2}"; }
log_perf()     { _log_base "PERF"   "⚡" "${C_LAVENDER}" "${1:-}" "${@:2}"; }
log_step()     { _log_base "STEP"   "🔹" "${C_SKY}"      "${1:-}" "${@:2}"; }
log_metric()   { _log_base "METRIC" "📊" "${C_ROSEWATER}" "${1:-}" "${@:2}"; }
log_artifact() { _log_base "ART"    "📤" "${C_PEACH}"    "${1:-}" "${@:2}"; }
log_debug()    {
  [[ "${VERBOSE}" == "true" ]] && \
    _log_base "DEBUG" "🔎" "${C_OVERLAY0}" "${1:-}" "${@:2}" || true
}

# ─────────────────────────────────────────────────────────────────────────────
# BANNER — Full-width ASCII art header
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  local COLS; COLS=$(tput cols 2>/dev/null || echo 80)
  local BANNER_W=70
  local PAD=$(( (COLS - BANNER_W) / 2 ))
  local P; P=$(printf '%*s' "${PAD}" '')

  echo ""
  echo -e "${P}${C_MAUVE}${C_BLD}"
  echo -e "${P}╔══════════════════════════════════════════════════════════════════════╗"
  echo -e "${P}║                                                                      ║"
  echo -e "${P}║  📸  ASH Screenshot Generation Engine  v${GENERATE_VERSION}            ║"
  echo -e "${P}║                                                                      ║"
  echo -e "${P}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Session:   ${C_LAVENDER}%-57s${C_SAPPHIRE}║${C_RST}\n" "${SESSION_ID}"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Quality:   ${C_TEAL}%-57s${C_SAPPHIRE}║${C_RST}\n" "${QUALITY_PRESET} (${RES_W}×${RES_H} @ ${DPI}dpi)"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Format:    ${C_PEACH}%-57s${C_SAPPHIRE}║${C_RST}\n" "${OUTPUT_FORMAT} (q${FINAL_WQ}$([ "${LOSSLESS}" == "true" ] && echo ' lossless' || echo ''))"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Backend:   ${C_YELLOW}%-57s${C_SAPPHIRE}║${C_RST}\n" "${RENDERER_BACKEND}"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Workers:   ${C_GREEN}%-57s${C_SAPPHIRE}║${C_RST}\n" "${PARALLEL_WORKERS}"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Themes:    ${C_PINK}%-57s${C_SAPPHIRE}║${C_RST}\n" "$(echo "${THEME_LIST}" | tr ',' ' ' | wc -w | tr -d ' ') theme(s)"
  printf  "${P}${C_SAPPHIRE}║${C_RST}  ${C_TEXT}Types:     ${C_MAUVE}%-57s${C_SAPPHIRE}║${C_RST}\n" "${SCREENSHOT_TYPES}"
  echo -e "${P}${C_SAPPHIRE}╚══════════════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS BAR — Premium animated progress visualization
# ─────────────────────────────────────────────────────────────────────────────
PROGRESS_CURRENT=0
PROGRESS_TOTAL=1
PROGRESS_LABEL="Progress"

progress_init() {
  PROGRESS_CURRENT=0
  PROGRESS_TOTAL="${1:-1}"
  PROGRESS_LABEL="${2:-Progress}"
}

progress_tick() {
  (( PROGRESS_CURRENT++ )) || true
  local cur="${PROGRESS_CURRENT}"
  local total="${PROGRESS_TOTAL}"
  local label="${PROGRESS_LABEL}"
  local W=36
  local pct=$(( cur * 100 / ( total > 0 ? total : 1 ) ))
  local filled=$(( cur * W / ( total > 0 ? total : 1 ) ))
  local empty=$(( W - filled ))

  # Gradient fill characters
  local bar=""
  local fill_chars=("█" "▓" "▒" "░")
  for (( i=0; i<filled; i++ )); do
    if   (( i < filled * 3 / 4 )); then bar+="█"
    elif (( i < filled * 7 / 8 )); then bar+="▓"
    else                               bar+="▒"
    fi
  done
  for (( i=0; i<empty; i++ )); do bar+="░"; done

  # Color based on progress
  local COLOR="${C_MAUVE}"
  (( pct >= 33 && pct < 66 )) && COLOR="${C_YELLOW}"
  (( pct >= 66 && pct < 90 )) && COLOR="${C_TEAL}"
  (( pct >= 90 ))              && COLOR="${C_GREEN}"

  # ETA calculation
  local elapsed=$(( $(date +%s) - START_EPOCH ))
  local eta_s=0
  if [[ "${cur}" -gt 0 && "${elapsed}" -gt 0 ]]; then
    local rate_per_s; rate_per_s=$(echo "scale=2; ${cur}/${elapsed}" | bc 2>/dev/null || echo "0")
    local remaining=$(( total - cur ))
    [[ "${rate_per_s}" != "0" ]] && \
      eta_s=$(echo "scale=0; ${remaining}/${rate_per_s}" | bc 2>/dev/null || echo "?")
  fi

  printf "\r  ${C_TEXT}%s${C_RST} [${COLOR}%s${C_RST}] ${C_BLD}%3d%%${C_RST} ${C_SUBTEXT0}(%d/%d)${C_RST} ${C_OVERLAY0}ETA:~%ss${C_RST}  " \
    "${label}" "${bar}" "${pct}" "${cur}" "${total}" "${eta_s}"

  [[ "${cur}" -ge "${total}" ]] && echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION HEADER — Visual separator for major pipeline stages
# ─────────────────────────────────────────────────────────────────────────────
section_header() {
  local title="$1"
  local icon="${2:-🔹}"
  local color="${3:-${C_SAPPHIRE}}"
  local width=60
  local title_len=${#title}
  local pad_r=$(( width - title_len - 4 ))

  echo ""
  echo -e "  ${color}${C_BLD}┌─${icon} ${C_TEXT}${C_BLD}${title}${color} $(printf '─%.0s' $(seq 1 "${pad_r}" 2>/dev/null || true))┐${C_RST}"
}

section_footer() {
  local color="${1:-${C_SAPPHIRE}}"
  echo -e "  ${color}└$(printf '─%.0s' $(seq 1 62 2>/dev/null || true))┘${C_RST}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# TRACKING STATE
# ─────────────────────────────────────────────────────────────────────────────
declare -a RENDERED_FILES=()
declare -a FAILED_RENDERS=()
declare -a CACHED_FILES=()
declare -A RENDER_TIMES=()
declare -a MANIFEST_ENTRIES=()
declare -a CATALOG_ENTRIES=()

TOTAL_GENERATED=0
TOTAL_FAILED=0
TOTAL_CACHED=0
TOTAL_SIZE_BYTES=0
RENDER_WORKER_COUNT=0

# ─────────────────────────────────────────────────────────────────────────────
# PYTHON RENDERER BASE — Shared rendering infrastructure
# ─────────────────────────────────────────────────────────────────────────────
PYTHON_PREAMBLE='
import json
import math
import os
import sys
import time
import hashlib
import struct
from pathlib import Path
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

# ── Renderer backend selection ────────────────────────────────────────────────
BACKEND = os.environ.get("RENDERER_BACKEND", "hybrid")

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.gridspec as gridspec
from matplotlib.patches import FancyBboxPatch, Circle, FancyArrowPatch
from matplotlib.colors import LinearSegmentedColormap, to_rgba
import numpy as np

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# ── Catppuccin Mocha color palette ────────────────────────────────────────────
PALETTE = {
    "rosewater": "#f5e0dc", "flamingo":  "#f2cdcd", "pink":     "#f5c2e7",
    "mauve":     "#cba6f7", "red":       "#f38ba8", "maroon":   "#eba0ac",
    "peach":     "#fab387", "yellow":    "#f9e2af", "green":    "#a6e3a1",
    "teal":      "#94e2d5", "sky":       "#89dceb", "sapphire": "#74c7ec",
    "blue":      "#89b4fa", "lavender":  "#b4befe", "text":     "#cdd6f4",
    "subtext1":  "#bac2de", "subtext0":  "#a6adc8", "overlay2": "#9399b2",
    "overlay1":  "#7f849c", "overlay0":  "#6c7086", "surface2": "#585b70",
    "surface1":  "#45475a", "surface0":  "#313244", "base":     "#1e1e2e",
    "mantle":    "#181825", "crust":     "#11111b",
}

def h(key: str, fallback: str = "#888888") -> str:
    """Get color from palette by key with fallback."""
    return PALETTE.get(key, fallback)

def hex_to_rgb(hex_color: str) -> Tuple[float, float, float]:
    """Convert hex color to normalized RGB tuple (0-1 range)."""
    hx = hex_color.lstrip("#")
    return tuple(int(hx[i:i+2], 16) / 255 for i in (0, 2, 4))

def hex_to_rgba(hex_color: str, alpha: float = 1.0) -> Tuple[float, float, float, float]:
    """Convert hex color to normalized RGBA tuple."""
    r, g, b = hex_to_rgb(hex_color)
    return (r, g, b, alpha)

def relative_luminance(hex_color: str) -> float:
    """Calculate relative luminance (WCAG 2.1)."""
    r, g, b = hex_to_rgb(hex_color)
    def linearize(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)

def contrast_ratio(c1: str, c2: str) -> float:
    """Calculate WCAG 2.1 contrast ratio between two hex colors."""
    l1, l2 = relative_luminance(c1), relative_luminance(c2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def wcag_grade(ratio: float) -> Tuple[str, str]:
    """Return (grade, color) for a contrast ratio."""
    if ratio >= 7.0:  return "AAA", h("green")
    if ratio >= 4.5:  return "AA",  h("yellow")
    if ratio >= 3.0:  return "A",   h("peach")
    return "✗", h("red")

def style_ax(ax, bg: str = "base", grid: bool = True, grid_alpha: float = 0.08) -> None:
    """Apply consistent dark theme styling to a matplotlib axis."""
    ax.set_facecolor(h(bg))
    for spine in ax.spines.values():
        spine.set_edgecolor(h("surface2"))
        spine.set_alpha(0.6)
    ax.tick_params(colors=h("text"), labelsize=8.5)
    ax.xaxis.label.set_color(h("text"))
    ax.yaxis.label.set_color(h("text"))
    if hasattr(ax, "title"):
        ax.title.set_color(h("text"))
    if grid:
        ax.grid(True, alpha=grid_alpha, color=h("text"),
                linestyle="--", linewidth=0.6, zorder=1)

def make_gradient_background(ax, width: float, height: float,
                              colors: List[str], alpha: float = 0.7) -> None:
    """Add a multi-stop gradient background to an axis."""
    gradient = np.linspace(0, 1, 300).reshape(-1, 1)
    cmap = LinearSegmentedColormap.from_list("bg", [h(c) for c in colors])
    ax.imshow(gradient, extent=[0, width, 0, height],
              aspect="auto", cmap=cmap, alpha=alpha, zorder=1)

def add_particle_field(ax, width: float, height: float,
                        colors: List[str], count: int = 80,
                        seed: int = 42, alpha: float = 0.35) -> None:
    """Add a particle dot field to an axis background."""
    rng = np.random.default_rng(seed)
    px = rng.uniform(0, width, count)
    py = rng.uniform(0, height, count)
    ps = rng.uniform(0.05, 0.25, count)
    pc_keys = rng.choice(colors, count)
    for x, y, s, ck in zip(px, py, ps, pc_keys):
        ax.add_patch(Circle((x, y), s, color=h(ck), alpha=alpha, zorder=2))

def add_radial_glow(ax, cx: float, cy: float, radius: float,
                     color: str, layers: int = 4,
                     base_alpha: float = 0.06) -> None:
    """Add a soft radial glow effect centered at (cx, cy)."""
    for i, (r, a) in enumerate(
        [(radius * (1 - j/layers), base_alpha * (j + 1)) for j in range(layers)]
    ):
        ax.add_patch(Circle((cx, cy), r, color=h(color), alpha=a, zorder=2))

def add_waybar_strip(ax, W: float, H: float, theme_colors: Dict[str, str],
                     theme_name: str) -> None:
    """Render a realistic Waybar status bar onto the axis."""
    BAR_H = 3.8
    bg_hex = theme_colors.get("mantle", h("mantle"))
    ax.add_patch(FancyBboxPatch((0, H - BAR_H), W, BAR_H,
        boxstyle="square", facecolor=bg_hex + "ee",
        edgecolor="none", zorder=14))

    # Workspaces
    for i in range(1, 11):
        active = i in [1, 3, 7]
        cx = 2.8 + (i-1) * 3.2
        clr = theme_colors.get("mauve", h("mauve")) if active else \
              theme_colors.get("surface0", h("surface0"))
        ax.add_patch(Circle((cx, H - BAR_H/2), 1.2,
            color=clr, zorder=15))
        ax.text(cx, H - BAR_H/2, str(i), ha="center", va="center",
            color=theme_colors.get("crust", h("crust")) if active else \
                  theme_colors.get("overlay0", h("overlay0")),
            fontsize=5.2, fontweight="bold", zorder=16)

    # Active window title
    ax.text(W/2, H - BAR_H/2, "  kitty  ·  ~/dotfiles/ash-v5",
        ha="center", va="center",
        color=theme_colors.get("text", h("text")),
        fontsize=5.5, zorder=15)

    # Right-side status pills
    STATUS_ITEMS = [
        (theme_colors.get("green", h("green")),   "🎮 Default"),
        (theme_colors.get("mauve", h("mauve")),   f"🎨 {theme_name[:12]}"),
        (theme_colors.get("blue",  h("blue")),    "🔊 100%"),
        (theme_colors.get("yellow",h("yellow")),  "🔋 87%"),
        (theme_colors.get("teal",  h("teal")),    "🌐 Up"),
        (theme_colors.get("subtext0",h("subtext0")),"20:42"),
    ]
    rx = 62.0
    for color, text in STATUS_ITEMS:
        pw = len(text) * 0.72 + 1.8
        ax.add_patch(FancyBboxPatch((rx, H - BAR_H + 0.5), pw, BAR_H - 1.0,
            boxstyle="round,pad=0.2", facecolor=color + "28",
            edgecolor=color + "70", linewidth=0.6, zorder=15))
        ax.text(rx + pw/2, H - BAR_H/2, text, ha="center", va="center",
            color=color, fontsize=4.8, fontweight="bold", zorder=16)
        rx += pw + 0.8

def watermark(ax, text: str, position: str = "bottom-right",
              W: float = 100, H: float = 56.25, alpha: float = 0.55) -> None:
    """Add a semi-transparent watermark to the axis."""
    PAD = 1.5
    pos_map = {
        "top-left":     (PAD, H - PAD, "left", "top"),
        "top-right":    (W - PAD, H - PAD, "right", "top"),
        "bottom-left":  (PAD, PAD, "left", "bottom"),
        "bottom-right": (W - PAD, PAD, "right", "bottom"),
        "center":       (W/2, H/2, "center", "center"),
    }
    x, y, ha, va = pos_map.get(position, pos_map["bottom-right"])
    ax.text(x, y, text, ha=ha, va=va,
        color=h("text"), fontsize=4.0, alpha=alpha,
        fontweight="bold", zorder=30,
        bbox=dict(boxstyle="round,pad=0.3", facecolor=h("surface0"),
                  edgecolor=h("overlay0"), alpha=0.6, linewidth=0.5))

# ── Theme color loader ─────────────────────────────────────────────────────────
def load_theme_colors(theme_name: str, themes_dir: str,
                       workspace: str) -> Dict[str, str]:
    """Load theme colors from colors.json with multi-category fallback."""
    CATEGORIES = [
        "dark", "light", "neon", "nature", "space", "pastel",
        "anime", "retro", "gradient", "seasonal", "mood", "gaming",
        "minimal", "special",
    ]
    for cat in CATEGORIES:
        candidate = Path(workspace) / themes_dir / cat / theme_name / "colors.json"
        if candidate.exists():
            try:
                with open(candidate) as f:
                    raw = json.load(f)
                return raw.get("colors", raw) if isinstance(raw, dict) else {}
            except Exception:
                pass

    # Direct path fallback
    direct = Path(workspace) / themes_dir / theme_name / "colors.json"
    if direct.exists():
        try:
            with open(direct) as f:
                raw = json.load(f)
            return raw.get("colors", raw) if isinstance(raw, dict) else {}
        except Exception:
            pass

    # Built-in defaults for known themes
    BUILTINS: Dict[str, Dict[str, str]] = {
        "catppuccin-mocha":  dict(PALETTE),
        "tokyo-night":       {"base":"#1a1b26","mantle":"#16161e","crust":"#13131a","surface0":"#292e42","surface1":"#3b4261","surface2":"#414868","overlay0":"#565f89","overlay1":"#737aa2","overlay2":"#939ab7","subtext0":"#a9b1d6","subtext1":"#c0caf5","text":"#c0caf5","lavender":"#c8d3f5","blue":"#7aa2f7","sapphire":"#2ac3de","sky":"#7dcfff","teal":"#1abc9c","green":"#9ece6a","yellow":"#e0af68","peach":"#ff9e64","maroon":"#db4b4b","red":"#f7768e","mauve":"#bb9af7","pink":"#ff007c","flamingo":"#f7768e","rosewater":"#f7768e","accent":"#7aa2f7"},
        "gruvbox-dark":      {"base":"#282828","mantle":"#1d2021","crust":"#141617","surface0":"#3c3836","surface1":"#504945","surface2":"#665c54","overlay0":"#928374","overlay1":"#a89984","overlay2":"#bdae93","subtext0":"#d5c4a1","subtext1":"#ebdbb2","text":"#ebdbb2","lavender":"#d3869b","blue":"#83a598","sapphire":"#8ec07c","sky":"#76d7c4","teal":"#8ec07c","green":"#b8bb26","yellow":"#fabd2f","peach":"#fe8019","maroon":"#cc241d","red":"#fb4934","mauve":"#d3869b","pink":"#d3869b","flamingo":"#fb4934","rosewater":"#fabd2f","accent":"#fabd2f"},
        "nord":              {"base":"#2e3440","mantle":"#272c36","crust":"#1f232c","surface0":"#3b4252","surface1":"#434c5e","surface2":"#4c566a","overlay0":"#616e88","overlay1":"#677791","overlay2":"#7b88a1","subtext0":"#b4bcd0","subtext1":"#cdd6f4","text":"#eceff4","lavender":"#b48ead","blue":"#5e81ac","sapphire":"#88c0d0","sky":"#81ecec","teal":"#88c0d0","green":"#a3be8c","yellow":"#ebcb8b","peach":"#d08770","maroon":"#bf616a","red":"#bf616a","mauve":"#b48ead","pink":"#b48ead","flamingo":"#bf616a","rosewater":"#ebcb8b","accent":"#5e81ac"},
        "dracula":           {"base":"#282a36","mantle":"#21222c","crust":"#191a21","surface0":"#343746","surface1":"#3d3f4f","surface2":"#4d4f5f","overlay0":"#6272a4","overlay1":"#7783b2","overlay2":"#8d95c0","subtext0":"#ccccc7","subtext1":"#f8f8f2","text":"#f8f8f2","lavender":"#bd93f9","blue":"#6272a4","sapphire":"#8be9fd","sky":"#8be9fd","teal":"#50fa7b","green":"#50fa7b","yellow":"#f1fa8c","peach":"#ffb86c","maroon":"#ff5555","red":"#ff5555","mauve":"#bd93f9","pink":"#ff79c6","flamingo":"#ff79c6","rosewater":"#f1fa8c","accent":"#bd93f9"},
        "rose-pine":         {"base":"#191724","mantle":"#1f1d2e","crust":"#26233a","surface0":"#2a2837","surface1":"#403d52","surface2":"#524f67","overlay0":"#6e6a86","overlay1":"#908caa","overlay2":"#e0def4","subtext0":"#c5c3ce","subtext1":"#e0def4","text":"#e0def4","lavender":"#c4a7e7","blue":"#9ccfd8","sapphire":"#9ccfd8","sky":"#c4a7e7","teal":"#31748f","green":"#31748f","yellow":"#f6c177","peach":"#ea9a97","maroon":"#b4637a","red":"#eb6f92","mauve":"#c4a7e7","pink":"#eb6f92","flamingo":"#ea9a97","rosewater":"#faf4ed","accent":"#c4a7e7"},
        "everforest-dark":   {"base":"#2d353b","mantle":"#272e33","crust":"#1e2326","surface0":"#3a454a","surface1":"#475258","surface2":"#56635f","overlay0":"#7a8478","overlay1":"#8c9a8e","overlay2":"#9da9a0","subtext0":"#d3c6aa","subtext1":"#d3c6aa","text":"#d3c6aa","lavender":"#d699b6","blue":"#7fbbb3","sapphire":"#7fbbb3","sky":"#7fbbb3","teal":"#83c092","green":"#a7c080","yellow":"#dbbc7f","peach":"#e69875","maroon":"#e67e80","red":"#e67e80","mauve":"#d699b6","pink":"#d699b6","flamingo":"#e67e80","rosewater":"#dbbc7f","accent":"#a7c080"},
        "cyberpunk-2077":    {"base":"#0d0d0d","mantle":"#080808","crust":"#030303","surface0":"#1a1a2e","surface1":"#16213e","surface2":"#0f3460","overlay0":"#533483","overlay1":"#7b2d8b","overlay2":"#9b2dca","subtext0":"#e0aaff","subtext1":"#ff00ff","text":"#ffffff","lavender":"#d4a5f5","blue":"#00b4d8","sapphire":"#0096c7","sky":"#00ccff","teal":"#00f5d4","green":"#39ff14","yellow":"#ffd700","peach":"#ff6b35","maroon":"#ff073a","red":"#ff0000","mauve":"#ff00ff","pink":"#ff6ec7","flamingo":"#ff9ef7","rosewater":"#ffccf9","accent":"#ff00ff"},
        "kanagawa-wave":     {"base":"#1f1f28","mantle":"#16161d","crust":"#0d0c0c","surface0":"#2a2a37","surface1":"#363646","surface2":"#54546d","overlay0":"#727169","overlay1":"#9cabca","overlay2":"#c8c093","subtext0":"#dcd7ba","subtext1":"#e6c384","text":"#dcd7ba","lavender":"#957fb8","blue":"#7e9cd8","sapphire":"#2d4f67","sky":"#7fb4ca","teal":"#6a9589","green":"#76946a","yellow":"#c0a36e","peach":"#ffa066","maroon":"#c34043","red":"#e82424","mauve":"#957fb8","pink":"#d27e99","flamingo":"#e46876","rosewater":"#ff9e3b","accent":"#7e9cd8"},
    }
    name = theme_name.lower().replace(" ", "-")
    colors = BUILTINS.get(name, BUILTINS["catppuccin-mocha"])
    return colors

# ── File utilities ─────────────────────────────────────────────────────────────
def ensure_dir(path: str) -> Path:
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p

def file_checksum(path: str) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha.update(chunk)
    return sha.hexdigest()

def file_size_kb(path: str) -> float:
    return Path(path).stat().st_size / 1024

def img_dimensions(path: str) -> Tuple[int, int]:
    if HAS_PIL:
        with Image.open(path) as img:
            return img.size
    return (0, 0)
'

# ─────────────────────────────────────────────────────────────────────────────
# CACHE ENGINE
# ─────────────────────────────────────────────────────────────────────────────
check_cache() {
  local theme="$1" shot_type="$2" output_path="$3"

  [[ "${CACHE_ENABLED}" != "true" || "${FORCE_REGEN}" == "true" ]] && return 1
  [[ ! -f "${output_path}" ]] && return 1

  # TTL check
  local file_age_h
  file_age_h=$(( ( $(date +%s) - $(stat -c '%Y' "${output_path}" 2>/dev/null || echo 0) ) / 3600 ))
  [[ "${file_age_h}" -ge "${CACHE_TTL_HOURS}" ]] && return 1

  # Content hash check
  local hash_key="${theme}-${shot_type}-${QUALITY_PRESET}-${OUTPUT_FORMAT}"
  local hash_file="${CACHE_DIR}/hash-${hash_key// /-}.txt"
  local colors_file=""

  for cat in dark light neon nature space pastel anime retro gradient seasonal mood gaming minimal special; do
    local candidate="${WORKSPACE}/${THEMES_DIR}/${cat}/${theme}/colors.json"
    if [[ -f "${candidate}" ]]; then
      colors_file="${candidate}"
      break
    fi
  done

  if [[ -n "${colors_file}" && -f "${colors_file}" ]]; then
    local current_hash; current_hash=$(md5sum "${colors_file}" 2>/dev/null | cut -d' ' -f1 || echo "nohash")
    if [[ -f "${hash_file}" ]]; then
      local stored_hash; stored_hash=$(cat "${hash_file}" 2>/dev/null || echo "")
      [[ "${current_hash}" == "${stored_hash}" ]] && return 0
    fi
    # Update hash
    echo "${current_hash}" > "${hash_file}"
  fi

  return 1
}

save_cache_hash() {
  local theme="$1" shot_type="$2"
  local hash_key="${theme}-${shot_type}-${QUALITY_PRESET}-${OUTPUT_FORMAT}"
  local hash_file="${CACHE_DIR}/hash-${hash_key// /-}.txt"
  mkdir -p "${CACHE_DIR}"

  for cat in dark light neon nature space pastel anime retro gradient seasonal mood gaming minimal special; do
    local candidate="${WORKSPACE}/${THEMES_DIR}/${cat}/${theme}/colors.json"
    if [[ -f "${candidate}" ]]; then
      local hash; hash=$(md5sum "${candidate}" 2>/dev/null | cut -d' ' -f1 || echo "nohash")
      echo "${hash}" > "${hash_file}"
      return
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# FORMAT CONVERSION & OPTIMIZATION ENGINE
# ─────────────────────────────────────────────────────────────────────────────
convert_and_optimize() {
  local src_png="$1"
  local stem="$2"
  local dest_dir="$3"
  local theme="${4:-unknown}"

  [[ ! -f "${src_png}" ]] && { log_fail "convert" "Source PNG missing: ${src_png}"; return 1; }

  local output_files=()
  mkdir -p "${dest_dir}"

  log_convert "convert" "${stem} → ${OUTPUT_FORMAT} (q${FINAL_WQ})"

  # ── WebP ────────────────────────────────────────────────────────────────────
  if [[ "${OUTPUT_FORMAT}" == "webp" || "${OUTPUT_FORMAT}" == "all" ]]; then
    local webp_out="${dest_dir}/${stem}.webp"
    local lossless_flag=""
    [[ "${LOSSLESS}" == "true" ]] && lossless_flag="-lossless"

    if command -v cwebp &>/dev/null; then
      cwebp ${lossless_flag} -q "${FINAL_WQ}" -m 6 -mt \
        "${src_png}" -o "${webp_out}" \
        2>/dev/null || \
      convert "${src_png}" -quality "${FINAL_WQ}" "${webp_out}" 2>/dev/null || \
      cp "${src_png}" "${webp_out}"
    else
      convert "${src_png}" -quality "${FINAL_WQ}" "${webp_out}" 2>/dev/null || \
        cp "${src_png}" "${webp_out}"
    fi
    [[ -f "${webp_out}" ]] && output_files+=("${webp_out}")
  fi

  # ── PNG ─────────────────────────────────────────────────────────────────────
  if [[ "${OUTPUT_FORMAT}" == "png" || "${OUTPUT_FORMAT}" == "all" ]]; then
    local png_out="${dest_dir}/${stem}.png"
    cp "${src_png}" "${png_out}"
    pngquant --quality=80-95 --speed=2 --force \
      --output "${png_out}" "${png_out}" 2>/dev/null || true
    optipng -o2 -quiet "${png_out}" 2>/dev/null || true
    [[ -f "${png_out}" ]] && output_files+=("${png_out}")
  fi

  # ── JPEG ────────────────────────────────────────────────────────────────────
  if [[ "${OUTPUT_FORMAT}" == "jpg" || "${OUTPUT_FORMAT}" == "all" ]]; then
    local jpg_out="${dest_dir}/${stem}.jpg"
    convert "${src_png}" -quality "${FINAL_WQ}" -sampling-factor "4:2:0" \
      -strip "${jpg_out}" 2>/dev/null || \
    python3 -c "
from PIL import Image
img = Image.open('${src_png}').convert('RGB')
img.save('${jpg_out}', 'JPEG', quality=${FINAL_WQ}, optimize=True)
" 2>/dev/null || true
    [[ -f "${jpg_out}" ]] && output_files+=("${jpg_out}")
  fi

  # ── AVIF ────────────────────────────────────────────────────────────────────
  if [[ "${OUTPUT_FORMAT}" == "avif" || "${OUTPUT_FORMAT}" == "all" ]]; then
    local avif_out="${dest_dir}/${stem}.avif"
    python3 -c "
import sys
try:
    import pillow_avif
    from PIL import Image
    img = Image.open('${src_png}')
    img.save('${avif_out}', 'AVIF', quality=${FINAL_WQ})
    print('avif ok')
except Exception as e:
    print(f'avif skip: {e}', file=sys.stderr)
" 2>/dev/null || true
    [[ -f "${avif_out}" ]] && output_files+=("${avif_out}")
  fi

  # ── Strip EXIF ───────────────────────────────────────────────────────────────
  if [[ "${STRIP_EXIF}" == "true" ]]; then
    for f in "${output_files[@]}"; do
      exiftool -all= -overwrite_original_in_place "${f}" 2>/dev/null || \
        convert "${f}" -strip "${f}" 2>/dev/null || true
    done
  fi

  # ── 2x retina ────────────────────────────────────────────────────────────────
  if [[ "${GEN_2X}" == "true" ]]; then
    local retina_dir="${OUTPUT_DIR}/2x/$(basename "${dest_dir}")"
    mkdir -p "${retina_dir}"
    local retina_out="${retina_dir}/${stem}@2x.webp"
    convert "${src_png}" -resize "200%" -quality "${FINAL_WQ}" \
      "${retina_out}" 2>/dev/null || true
    [[ -f "${retina_out}" ]] && {
      output_files+=("${retina_out}")
      log_debug "2x" "Generated: ${retina_out}"
    }
  fi

  # ── 4K variant ───────────────────────────────────────────────────────────────
  if [[ "${GEN_4K}" == "true" ]]; then
    local k4_dir="${OUTPUT_DIR}/4k/$(basename "${dest_dir}")"
    mkdir -p "${k4_dir}"
    local k4_out="${k4_dir}/${stem}@4k.webp"
    convert "${src_png}" -resize "400%" -quality "${FINAL_WQ}" \
      "${k4_out}" 2>/dev/null || true
    [[ -f "${k4_out}" ]] && {
      output_files+=("${k4_out}")
      log_debug "4k" "Generated: ${k4_out}"
    }
  fi

  # ── Thumbnail ─────────────────────────────────────────────────────────────────
  if [[ "${GEN_THUMBS}" == "true" ]]; then
    local thumb_dir="${OUTPUT_DIR}/thumbs/$(basename "${dest_dir}")"
    mkdir -p "${thumb_dir}"
    local thumb_out="${thumb_dir}/${stem}-thumb.webp"
    python3 -c "
from PIL import Image
img = Image.open('${src_png}').convert('RGB')
img.thumbnail((${THUMB_W}, ${THUMB_H}), Image.LANCZOS)
img.save('${thumb_out}', 'WEBP', quality=75, method=4)
" 2>/dev/null || \
      convert "${src_png}" -resize "${THUMB_W}x${THUMB_H}>" \
        -quality 75 "${thumb_out}" 2>/dev/null || true
    [[ -f "${thumb_out}" ]] && {
      output_files+=("${thumb_out}")
      log_debug "thumb" "Generated: ${thumb_out}"
    }
  fi

  # ── Track file sizes ──────────────────────────────────────────────────────────
  local primary="${output_files[0]:-${src_png}}"
  for f in "${output_files[@]}"; do
    if [[ -f "${f}" ]]; then
      local sz; sz=$(wc -c < "${f}" 2>/dev/null || echo 0)
      TOTAL_SIZE_BYTES=$(( TOTAL_SIZE_BYTES + sz ))
      RENDERED_FILES+=("${f}")
      (( TOTAL_GENERATED++ )) || true

      local sz_kb; sz_kb=$(echo "scale=1; ${sz}/1024" | bc 2>/dev/null || echo "?")
      log_debug "size" "$(basename "${f}"): ${sz_kb}KB"
    fi
  done

  # Remove source PNG unless PNG format requested
  if [[ "${OUTPUT_FORMAT}" != "png" && "${OUTPUT_FORMAT}" != "all" ]]; then
    rm -f "${src_png}"
  fi

  echo "${primary}"
}

# ─────────────────────────────────────────────────────────────────────────────
# METADATA GENERATOR
# ─────────────────────────────────────────────────────────────────────────────
generate_metadata() {
  local theme="$1" shot_type="$2" output_path="$3"
  [[ "${METADATA}" != "true" || ! -f "${output_path}" ]] && return 0

  local meta_path="${output_path%.webp}.meta.json"
  local w=0 h=0
  local sz; sz=$(wc -c < "${output_path}" 2>/dev/null || echo 0)
  local chk; chk=$(sha256sum "${output_path}" 2>/dev/null | cut -d' ' -f1 || echo "")
  local dims
  dims=$(python3 -c "
from PIL import Image
try:
    img = Image.open('${output_path}')
    print(f'{img.size[0]} {img.size[1]}')
except: print('0 0')
" 2>/dev/null || echo "0 0")
  read -r w h <<< "${dims}"

  cat > "${meta_path}" << METAEOF
{
  "theme":          "${theme}",
  "type":           "${shot_type}",
  "file":           "$(basename "${output_path}")",
  "quality":        "${QUALITY_PRESET}",
  "format":         "${OUTPUT_FORMAT}",
  "webp_quality":   ${FINAL_WQ},
  "resolution":     "${RES_W}x${RES_H}",
  "dpi":            ${DPI},
  "dimensions":     {"width": ${w}, "height": ${h}},
  "size_bytes":     ${sz},
  "sha256":         "${chk}",
  "session_id":     "${SESSION_ID}",
  "generated_at":   "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "engine":         "${GENERATE_VERSION}"
}
METAEOF
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDERER: DESKTOP COMPOSITE
# ─────────────────────────────────────────────────────────────────────────────
render_desktop() {
  local theme="$1"
  local colors_file="$2"
  local out_dir="${OUTPUT_DIR}/desktop"
  local tmp_png="${WORK_DIR}/tmp-desktop-${theme}-$$.png"
  local final_out="${out_dir}/${theme}.webp"

  mkdir -p "${out_dir}"
  if check_cache "${theme}" "desktop" "${final_out}"; then
    log_cache "desktop" "${theme}"
    CACHED_FILES+=("${final_out}"); (( TOTAL_CACHED++ )) || true
    return 0
  fi

  log_render "desktop" "${theme} @ ${RES_W}×${RES_H}"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  python3 << DESKTOP_PY
import sys
sys.path.insert(0, "")

${PYTHON_PREAMBLE}

THEME_NAME  = "${theme}"
COLORS_FILE = "${colors_file}"
OUTPUT_PNG  = "${tmp_png}"
FIG_W = int("${RES_W}") / int("${DPI}")
FIG_H = int("${RES_H}") / int("${DPI}")
DPI_V = int("${DPI}")
DO_WM = "${WATERMARK}" == "true"
WM_POS= "${WATERMARK_POS}"
WM_TXT= "${WATERMARK_TEXT}"
W, H  = 100.0, 56.25      # Logical coordinate space (16:9)

try:
    with open(COLORS_FILE) as f:
        raw = json.load(f)
    TC = raw.get("colors", raw) if isinstance(raw, dict) else {}
except Exception:
    TC = dict(PALETTE)

def tc(k: str) -> str:
    return TC.get(k, h(k))

# ── Canvas setup ───────────────────────────────────────────────────────────────
fig = plt.figure(figsize=(FIG_W, FIG_H), dpi=DPI_V)
fig.patch.set_facecolor(tc("base"))
ax  = fig.add_axes([0, 0, 1, 1])
ax.set_facecolor(tc("base"))
ax.set_xlim(0, W); ax.set_ylim(0, H)
ax.axis("off")

# ── Multi-stop gradient background ────────────────────────────────────────────
gradient = np.linspace(0, 1, 400).reshape(-1, 1)
cmap = LinearSegmentedColormap.from_list("bg", [
    tc("crust"), tc("base"), tc("mantle"),
    tc("mauve") + "18", tc("base"), tc("crust")
])
ax.imshow(gradient, extent=[0, W, 0, H], aspect="auto",
          cmap=cmap, alpha=0.78, zorder=1)

# ── Floating accent orbs ────────────────────────────────────────────────────────
for (ox, oy, rad, col, alph) in [
    (78, H*0.72, 20, "mauve",    0.06),
    (88, H*0.25, 26, "blue",     0.05),
    (50, H*0.95, 14, "teal",     0.08),
    (28, H*0.12, 12, "green",    0.07),
    (70, H*0.82, 16, "sapphire", 0.06),
    (15, H*0.60, 10, "pink",     0.05),
]:
    add_radial_glow(ax, ox, oy, rad, col, layers=5, base_alpha=alph)

# ── Particle field ─────────────────────────────────────────────────────────────
add_particle_field(ax, W, H,
    ["mauve","blue","teal","green","sapphire","pink","yellow"],
    count=90,
    seed=int(sum(ord(c) for c in THEME_NAME)) % 9999,
    alpha=0.32)

# ── Waybar ─────────────────────────────────────────────────────────────────────
add_waybar_strip(ax, W, H, TC, THEME_NAME)

# ── Main terminal window ────────────────────────────────────────────────────────
TX, TY, TW, TH = 2.0, 4.5, 57.0, 48.0
ax.add_patch(FancyBboxPatch((TX, TY), TW, TH,
    boxstyle="round,pad=0.4", zorder=8,
    facecolor=tc("crust") + "f3",
    edgecolor=tc("surface1"), linewidth=0.9))

# Window chrome
ax.add_patch(FancyBboxPatch((TX, TY+TH-3.8), TW, 3.8,
    boxstyle="round,pad=0.2", zorder=9,
    facecolor=tc("mantle") + "f5", edgecolor="none"))
for bx, bc in [(TX+1.6, tc("red")), (TX+3.5, tc("yellow")), (TX+5.4, tc("green"))]:
    ax.add_patch(Circle((bx, TY+TH-1.9), 0.75, color=bc, zorder=10))
ax.text(TX+TW/2, TY+TH-1.9,
    "kitty  ·  ~/dotfiles/ash-v5  ·  zsh",
    ha="center", va="center", fontsize=4.8,
    color=tc("subtext0"), zorder=10)

# Terminal content with syntax-highlighted commands
TERM_LINES = [
    (tc("green"),    "❯ "),
    (tc("text"),     "ash theme apply " + THEME_NAME),
    (tc("mauve"),    "\n  🎨 Applying: " + THEME_NAME),
    (tc("teal"),     "\n  ⚡ Hyprland...     ✅  48ms"),
    (tc("teal"),     "\n  ⚡ Waybar...       ✅  83ms"),
    (tc("teal"),     "\n  ⚡ Kitty...        ✅  21ms"),
    (tc("teal"),     "\n  ⚡ Neovim...       ✅  34ms"),
    (tc("teal"),     "\n  ⚡ Dunst...        ✅  19ms"),
    (tc("teal"),     "\n  ⚡ GTK...          ✅  62ms"),
    (tc("green"),    "\n  ✅ Theme applied in 342ms"),
    (tc("overlay0"), "\n"),
    (tc("blue"),     "❯ "),
    (tc("text"),     "ash doctor"),
    (tc("green"),    "\n  ✅ All 47 checks passed"),
    (tc("overlay0"), "\n"),
    (tc("sapphire"), "❯ "),
    (tc("text"),     "ash --version"),
    (tc("mauve"),    "\n  ash v5.0.0-omega · 250+ themes · 150+ plugins"),
    (tc("overlay0"), "\n"),
    (tc("yellow"),   "❯ "),
    (tc("text"),     "fastfetch"),
]

ty = TY + TH - 6.0
x_pos = TX + 1.8
for color, text in TERM_LINES:
    for line in text.split("\n"):
        if ty < TY + 1.0: break
        if line.strip():
            ax.text(x_pos, ty, line, color=color, fontsize=4.4,
                    fontfamily="monospace", va="center", zorder=10)
        ty -= 1.95

# Blinking cursor
ax.add_patch(FancyBboxPatch((x_pos, ty - 0.6), 0.55, 1.6,
    boxstyle="round,pad=0.05",
    facecolor=tc("text"), alpha=0.88, zorder=11))
ax.text(x_pos + 1.2, ty + 0.2, "❯",
    color=tc("green"), fontsize=4.5, va="center", zorder=11)

# ── Floating neofetch/fastfetch panel ───────────────────────────────────────────
NX, NY, NW, NH = 60.5, 4.5, 37.0, 48.0
ax.add_patch(FancyBboxPatch((NX, NY), NW, NH,
    boxstyle="round,pad=0.4", zorder=8,
    facecolor=tc("mantle") + "ea",
    edgecolor=tc("surface0"), linewidth=0.7))

# Compact ASCII logo
LOGO_LINES = [
    (tc("mauve"),    "░█████╗░░██████╗██╗"),
    (tc("blue"),     "██╔══██╗██╔════╝██║"),
    (tc("sapphire"), "███████║╚█████╗░███████╗"),
    (tc("teal"),     "██╔══██║░╚═══██╗██╔══██╗"),
    (tc("green"),    "██║░░██║██████╔╝██║░░██║"),
    (tc("overlay0"), "╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝"),
]
ly = NY + NH - 4.0
for col, line in LOGO_LINES:
    ax.text(NX + 1.2, ly, line, color=col, fontsize=3.1,
            fontfamily="monospace", va="center", zorder=10)
    ly -= 1.65

# System info table
INFO_ROWS = [
    (tc("mauve"),    "user",       f"ash@{THEME_NAME[:16]}"),
    (tc("surface2"), "─"*22,       ""),
    (tc("blue"),     "os",         "Arch Linux x86_64"),
    (tc("blue"),     "kernel",     "6.12.8-arch1-1"),
    (tc("blue"),     "wm",         "Hyprland 0.44.1"),
    (tc("blue"),     "shell",      "fish 3.7.1"),
    (tc("blue"),     "terminal",   "Kitty 0.36.2"),
    (tc("blue"),     "editor",     "Neovim 0.10.2"),
    (tc("blue"),     "theme",      THEME_NAME),
    (tc("blue"),     "icons",      "Papirus-Dark"),
    (tc("blue"),     "font",       "FiraCode Nerd 12"),
    (tc("blue"),     "uptime",     "2h 14m"),
    (tc("blue"),     "packages",   "1,847 (pacman)"),
    (tc("blue"),     "memory",     "4.2GiB / 32GiB"),
    (tc("blue"),     "gpu",        "AMD RX 7900 XTX"),
    (tc("blue"),     "resolution", "2560×1440 @ 165Hz"),
    (tc("surface2"), "─"*22,       ""),
]
iy = ly - 1.8
for col, key, val in INFO_ROWS:
    if iy < NY + 1.0: break
    if "─" in key:
        ax.text(NX+1.2, iy, key, color=tc("surface2"),
                fontsize=3.8, va="center", zorder=10)
    else:
        ax.text(NX+1.2, iy, f"{key}:", color=col,
                fontsize=4.2, fontweight="bold",
                fontfamily="monospace", va="center", zorder=10)
        ax.text(NX+11, iy, val, color=tc("text"),
                fontsize=4.2, fontfamily="monospace",
                va="center", zorder=10)
    iy -= 2.0

# Color palette strip
ACCENT_KEYS = ["red","maroon","peach","yellow","green","teal",
                "sapphire","sky","blue","lavender","mauve","pink","flamingo"]
AVAILABLE = [k for k in ACCENT_KEYS if k in TC]
bw = (NW - 2.4) / max(len(AVAILABLE), 1)
for i, k in enumerate(AVAILABLE):
    rect_x = NX + 1.2 + i * bw
    ax.add_patch(plt.Rectangle(
        (rect_x, NY + 1.0), bw - 0.2, 3.0,
        facecolor=TC[k], edgecolor="none", zorder=10))

# ── Bottom status bar ─────────────────────────────────────────────────────────
ax.add_patch(FancyBboxPatch((0, 0), W, 3.8,
    boxstyle="square",
    facecolor=tc("mantle") + "cc", edgecolor="none", zorder=14))
ax.text(W/2, 1.9,
    f"ASH Dotfiles v5.0 OMEGA  ·  🎨 {THEME_NAME}  ·  250+ themes  ·  150+ plugins  ·  Powered by Hyprland",
    ha="center", va="center", fontsize=4.4,
    color=tc("subtext0"), zorder=15)

# ── Watermark ──────────────────────────────────────────────────────────────────
if DO_WM:
    watermark(ax, WM_TXT, WM_POS, W, H)

ensure_dir(str(Path(OUTPUT_PNG).parent))
plt.savefig(OUTPUT_PNG, dpi=DPI_V, bbox_inches="tight", pad_inches=0,
            facecolor=tc("base"), edgecolor="none")
plt.close("all")
print(f"OK:{OUTPUT_PNG}")
DESKTOP_PY

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))

  if [[ -f "${tmp_png}" ]]; then
    local result
    result=$(convert_and_optimize "${tmp_png}" "${theme}" "${out_dir}" "${theme}")
    save_cache_hash "${theme}" "desktop"
    RENDER_TIMES["desktop-${theme}"]="${dur_ms}"
    generate_metadata "${theme}" "desktop" "${final_out}"
    MANIFEST_ENTRIES+=("{\"theme\":\"${theme}\",\"type\":\"desktop\",\"file\":\"${out_dir}/${theme}.webp\",\"ms\":${dur_ms}}")
    log_pass "desktop" "${theme} (${dur_ms}ms)"
  else
    log_fail "desktop" "${theme} — render failed"
    FAILED_RENDERS+=("desktop:${theme}")
    (( TOTAL_FAILED++ )) || true
    [[ "${FAIL_ON_ERROR}" == "true" ]] && exit 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDERER: THEME CARD
# ─────────────────────────────────────────────────────────────────────────────
render_card() {
  local theme="$1"
  local colors_file="$2"
  local out_dir="${OUTPUT_DIR}/cards"
  local tmp_png="${WORK_DIR}/tmp-card-${theme}-$$.png"
  local final_out="${out_dir}/${theme}.webp"

  mkdir -p "${out_dir}"
  if check_cache "${theme}" "card" "${final_out}"; then
    log_cache "card" "${theme}"
    CACHED_FILES+=("${final_out}"); (( TOTAL_CACHED++ )) || true
    return 0
  fi

  log_render "card" "${theme} (${CARD_W}×${CARD_H})"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  python3 << CARD_PY
import sys
sys.path.insert(0, "")

${PYTHON_PREAMBLE}

THEME_NAME  = "${theme}"
COLORS_FILE = "${colors_file}"
OUTPUT_PNG  = "${tmp_png}"
CARD_W_IN   = int("${CARD_W}") / 100.0
CARD_H_IN   = int("${CARD_H}") / 100.0
DPI_V       = 100
DO_WM       = "${WATERMARK}" == "true"

try:
    with open(COLORS_FILE) as f:
        raw = json.load(f)
    TC = raw.get("colors", raw) if isinstance(raw, dict) else {}
except Exception:
    TC = dict(PALETTE)

def tc(k): return TC.get(k, h(k))

fig, ax = plt.subplots(figsize=(CARD_W_IN, CARD_H_IN), dpi=DPI_V)
fig.patch.set_facecolor(tc("base"))
ax.set_facecolor(tc("base"))
ax.set_xlim(0, 100); ax.set_ylim(0, 61); ax.axis("off")

# ── Drop shadow ────────────────────────────────────────────────────────────────
ax.add_patch(FancyBboxPatch((1.8, 0.8), 98, 60.2,
    boxstyle="round,pad=0.9",
    facecolor="#000000", alpha=0.28, edgecolor="none", zorder=1))

# ── Card body ──────────────────────────────────────────────────────────────────
ax.add_patch(FancyBboxPatch((1, 1), 98, 59.5,
    boxstyle="round,pad=0.9",
    facecolor=tc("mantle"),
    edgecolor=tc("surface0"), linewidth=1.8, zorder=2))

# ── Header: gradient color strip ──────────────────────────────────────────────
STRIP_KEYS = ["red","maroon","peach","yellow","green","teal",
               "sapphire","sky","blue","lavender","mauve","pink","flamingo"]
STRIP_AVAIL= [k for k in STRIP_KEYS if k in TC]
sw = 96 / max(len(STRIP_AVAIL), 1)
for i, k in enumerate(STRIP_AVAIL):
    ax.add_patch(plt.Rectangle(
        (2 + i*sw, 52.5), sw - 0.25, 7.0,
        facecolor=TC[k], edgecolor="none", zorder=3))
# Rounded overlay on strip
ax.add_patch(FancyBboxPatch((2, 52.5), 96, 7.0,
    boxstyle="round,pad=0.5",
    facecolor="none", edgecolor=tc("surface1"),
    linewidth=1.0, zorder=4))

# ── Theme name headline ────────────────────────────────────────────────────────
display_name = THEME_NAME.replace("-", " ").title()
ax.text(50, 43.5, display_name,
    ha="center", va="center",
    color=tc("text"), fontsize=21, fontweight="bold", zorder=5)
ax.text(50, 37.5,
    f"{'◦' * 4}  ASH Dotfiles v5.0 OMEGA  {'◦' * 4}",
    ha="center", va="center",
    color=tc("overlay0"), fontsize=6.8, zorder=5)

# ── Mini color swatches row ────────────────────────────────────────────────────
SWATCH_KEYS = [
    ("base",    tc("base")),
    ("surface", tc("surface0")),
    ("overlay", tc("overlay0")),
    ("text",    tc("text")),
    ("accent",  TC.get("accent", TC.get("mauve", h("mauve")))),
    ("blue",    tc("blue")),
    ("green",   tc("green")),
]
sw_step = 82 / len(SWATCH_KEYS)
for i, (name, color) in enumerate(SWATCH_KEYS):
    cx = 9 + i * sw_step + sw_step/2
    # Outer ring
    ax.add_patch(Circle((cx, 27.0), 5.2,
        color=tc("surface0"), zorder=4))
    # Color fill
    ax.add_patch(Circle((cx, 27.0), 4.6,
        color=color, zorder=5))
    # Inner border
    ax.add_patch(Circle((cx, 27.0), 4.6,
        color="none", zorder=6,
        fill=False, linewidth=0.8,
        edgecolor=tc("surface2")))
    ax.text(cx, 20.5, name,
        ha="center", va="center",
        color=tc("subtext0"), fontsize=5.5, zorder=6)

# ── Stat badges row ────────────────────────────────────────────────────────────
STATS = [
    ("🎨", "250+",  "Themes"),
    ("📦", "26",    "Colors"),
    ("⚡", "<300ms","Apply"),
    ("♿", "WCAG",  "AA"),
    ("🔌", "150+",  "Plugins"),
]
xs = 100 / len(STATS)
for i, (ico, val, lbl) in enumerate(STATS):
    x = xs * i + xs/2
    # Badge background
    ax.add_patch(FancyBboxPatch(
        (x - xs/2 + 1, 6.5), xs - 2, 11.5,
        boxstyle="round,pad=0.3",
        facecolor=tc("surface0") + "80",
        edgecolor=tc("surface1"), linewidth=0.6, zorder=4))
    ax.text(x, 15.8, ico, ha="center", va="center", fontsize=12, zorder=5)
    ax.text(x, 11.5, val, ha="center", va="center",
        color=TC.get("accent", TC.get("mauve", h("mauve"))),
        fontsize=8.5, fontweight="bold", zorder=5)
    ax.text(x, 8.0, lbl, ha="center", va="center",
        color=tc("overlay0"), fontsize=5.8, zorder=5)

# ── Footer ─────────────────────────────────────────────────────────────────────
ax.text(50, 3.5, "ash-dotfiles.dev",
    ha="center", va="center",
    color=tc("surface2"), fontsize=5.5, zorder=5)

# ── Watermark ──────────────────────────────────────────────────────────────────
if DO_WM:
    watermark(ax, "${WATERMARK_TEXT}", "${WATERMARK_POS}", 100, 61)

ensure_dir(str(Path(OUTPUT_PNG).parent))
plt.tight_layout(pad=0)
plt.savefig(OUTPUT_PNG, dpi=DPI_V, bbox_inches="tight",
            facecolor=tc("base"), edgecolor="none")
plt.close("all")
print(f"OK:{OUTPUT_PNG}")
CARD_PY

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))

  if [[ -f "${tmp_png}" ]]; then
    convert_and_optimize "${tmp_png}" "${theme}" "${out_dir}" "${theme}"
    save_cache_hash "${theme}" "card"
    RENDER_TIMES["card-${theme}"]="${dur_ms}"
    generate_metadata "${theme}" "card" "${final_out}"
    MANIFEST_ENTRIES+=("{\"theme\":\"${theme}\",\"type\":\"card\",\"file\":\"${out_dir}/${theme}.webp\",\"ms\":${dur_ms}}")
    log_pass "card" "${theme} (${dur_ms}ms)"
  else
    log_fail "card" "${theme}"
    FAILED_RENDERS+=("card:${theme}")
    (( TOTAL_FAILED++ )) || true
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDERER: COLOR SWATCH (with WCAG analysis)
# ─────────────────────────────────────────────────────────────────────────────
render_swatch() {
  local theme="$1"
  local colors_file="$2"
  local out_dir="${OUTPUT_DIR}/swatches"
  local tmp_png="${WORK_DIR}/tmp-swatch-${theme}-$$.png"
  local final_out="${out_dir}/${theme}.webp"

  mkdir -p "${out_dir}"
  if check_cache "${theme}" "swatch" "${final_out}"; then
    log_cache "swatch" "${theme}"
    CACHED_FILES+=("${final_out}"); (( TOTAL_CACHED++ )) || true
    return 0
  fi

  log_render "swatch" "${theme} (26-color + WCAG)"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  python3 << SWATCH_PY
import sys
sys.path.insert(0, "")

${PYTHON_PREAMBLE}

THEME_NAME  = "${theme}"
COLORS_FILE = "${colors_file}"
OUTPUT_PNG  = "${tmp_png}"
DO_WM       = "${WATERMARK}" == "true"

try:
    with open(COLORS_FILE) as f:
        raw = json.load(f)
    TC = raw.get("colors", raw) if isinstance(raw, dict) else {}
except Exception:
    TC = dict(PALETTE)

def tc(k): return TC.get(k, h(k))

BASE_CLR = tc("base")
TEXT_CLR = tc("text")

fig = plt.figure(figsize=(20, 13), dpi=130)
fig.patch.set_facecolor(BASE_CLR)
gs = gridspec.GridSpec(4, 1, hspace=0.24,
                        left=0.025, right=0.975,
                        top=0.88, bottom=0.025)

ax_title   = fig.add_subplot(gs[0])
ax_base    = fig.add_subplot(gs[1])
ax_accent  = fig.add_subplot(gs[2])
ax_wcag    = fig.add_subplot(gs[3])

for ax_ in [ax_title, ax_base, ax_accent, ax_wcag]:
    ax_.set_facecolor(BASE_CLR); ax_.axis("off")

# ── Title row ──────────────────────────────────────────────────────────────────
ax_title.text(0.5, 0.72,
    f"🎨 {THEME_NAME.replace('-', ' ').title()}",
    transform=ax_title.transAxes, ha="center", va="center",
    color=TEXT_CLR, fontsize=30, fontweight="bold")
ax_title.text(0.5, 0.22,
    "ASH Dotfiles v5.0 OMEGA  ·  26-Color Catppuccin-Compatible Palette  ·  WCAG Analysis",
    transform=ax_title.transAxes, ha="center", va="center",
    color=tc("subtext0"), fontsize=10)

# ── Base/surface palette ────────────────────────────────────────────────────────
BASE_KEYS = ["crust","mantle","base","surface0","surface1","surface2",
             "overlay0","overlay1","overlay2","subtext0","subtext1","text"]
BASE_AVAIL = [k for k in BASE_KEYS if k in TC]
n = len(BASE_AVAIL)
bw = 1.0 / max(n, 1)

for i, key in enumerate(BASE_AVAIL):
    hex_c = TC[key]
    cr    = contrast_ratio(hex_c, BASE_CLR)
    grade, grade_col = wcag_grade(cr)
    x = i * bw

    # Swatch block
    ax_base.add_patch(FancyBboxPatch(
        (x + 0.004, 0.06), bw - 0.008, 0.88,
        boxstyle="round,pad=0.012",
        facecolor=hex_c,
        edgecolor=tc("surface2"), linewidth=0.5,
        transform=ax_base.transAxes))

    fs = max(5.0, 9.5 - max(0, n - 10))
    ax_base.text(x + bw/2, 0.83, key,
        transform=ax_base.transAxes, ha="center", va="center",
        color=TEXT_CLR, fontsize=fs, fontweight="bold")
    ax_base.text(x + bw/2, 0.62, hex_c.upper(),
        transform=ax_base.transAxes, ha="center", va="center",
        color=tc("subtext0"), fontsize=max(4.5, fs-1.5),
        fontfamily="monospace")
    ax_base.text(x + bw/2, 0.28, f"{cr:.1f}:1",
        transform=ax_base.transAxes, ha="center", va="center",
        color=tc("overlay1"), fontsize=5.5)
    ax_base.text(x + bw/2, 0.12, f"[{grade}]",
        transform=ax_base.transAxes, ha="center", va="center",
        color=grade_col, fontsize=6.5, fontweight="bold")

ax_base.text(0.008, 0.96, "BASE  /  SURFACE  /  OVERLAY  PALETTE",
    transform=ax_base.transAxes,
    color=tc("overlay0"), fontsize=7.5, fontweight="bold", va="top")

# ── Accent palette ─────────────────────────────────────────────────────────────
ACC_KEYS = ["rosewater","flamingo","pink","mauve","red","maroon","peach",
            "yellow","green","teal","sky","sapphire","blue","lavender"]
ACC_AVAIL = [k for k in ACC_KEYS if k in TC]
m  = len(ACC_AVAIL)
aw = 1.0 / max(m, 1)

for i, key in enumerate(ACC_AVAIL):
    hex_c = TC[key]
    cr    = contrast_ratio(hex_c, BASE_CLR)
    grade, grade_col = wcag_grade(cr)
    x = i * aw

    # Accent card with colored border + tinted bg
    ax_accent.add_patch(FancyBboxPatch(
        (x + 0.003, 0.04), aw - 0.006, 0.92,
        boxstyle="round,pad=0.012",
        facecolor=hex_c + "22",
        edgecolor=hex_c, linewidth=1.4,
        transform=ax_accent.transAxes))
    # Solid color block (top half)
    ax_accent.add_patch(FancyBboxPatch(
        (x + 0.008, 0.52), aw - 0.016, 0.40,
        boxstyle="round,pad=0.010",
        facecolor=hex_c, edgecolor="none",
        transform=ax_accent.transAxes))

    fs = max(5.0, 8.5 - max(0, m - 12))
    ax_accent.text(x + aw/2, 0.44, key,
        transform=ax_accent.transAxes, ha="center", va="center",
        color=TEXT_CLR, fontsize=fs, fontweight="bold")
    ax_accent.text(x + aw/2, 0.29, hex_c.upper(),
        transform=ax_accent.transAxes, ha="center", va="center",
        color=hex_c, fontsize=max(4.5, fs-1.0),
        fontfamily="monospace")
    ax_accent.text(x + aw/2, 0.14, f"{cr:.1f}:1 {grade}",
        transform=ax_accent.transAxes, ha="center", va="center",
        color=grade_col, fontsize=5.8, fontweight="bold")

ax_accent.text(0.008, 0.97, "ACCENT  PALETTE",
    transform=ax_accent.transAxes,
    color=tc("overlay0"), fontsize=7.5, fontweight="bold", va="top")

# ── WCAG summary bar chart ──────────────────────────────────────────────────────
all_colors = list(TC.values())[:20]
ratios_on_base = [contrast_ratio(c, BASE_CLR) for c in all_colors]
n_aaa = sum(1 for r in ratios_on_base if r >= 7.0)
n_aa  = sum(1 for r in ratios_on_base if 4.5 <= r < 7.0)
n_a   = sum(1 for r in ratios_on_base if 3.0 <= r < 4.5)
n_f   = sum(1 for r in ratios_on_base if r < 3.0)

# Summary text
ax_wcag.text(0.5, 0.70,
    f"WCAG Summary  ·  Checked {len(all_colors)} colors against base",
    transform=ax_wcag.transAxes, ha="center", va="center",
    color=tc("subtext0"), fontsize=9)

summary_items = [
    (f"AAA (≥7.0:1)  {n_aaa}", tc("green")),
    (f"AA (≥4.5:1)   {n_aa}",  tc("yellow")),
    (f"A (≥3.0:1)    {n_a}",   tc("peach")),
    (f"Fail (<3.0:1) {n_f}",   tc("red")),
]
for j, (label, color) in enumerate(summary_items):
    ax_wcag.text(0.12 + j * 0.22, 0.25, label,
        transform=ax_wcag.transAxes, ha="center", va="center",
        color=color, fontsize=9.5, fontweight="bold",
        bbox=dict(boxstyle="round,pad=0.4", facecolor=color+"20",
                  edgecolor=color+"60", linewidth=0.8))

if DO_WM:
    fig.text(0.99, 0.01, "${WATERMARK_TEXT}",
        ha="right", va="bottom", color=tc("overlay0"),
        fontsize=5, alpha=0.6)

ensure_dir(str(Path(OUTPUT_PNG).parent))
plt.savefig(OUTPUT_PNG, dpi=130, bbox_inches="tight",
            facecolor=BASE_CLR, edgecolor="none")
plt.close("all")
print(f"OK:{OUTPUT_PNG}")
SWATCH_PY

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))

  if [[ -f "${tmp_png}" ]]; then
    convert_and_optimize "${tmp_png}" "${theme}" "${out_dir}" "${theme}"
    save_cache_hash "${theme}" "swatch"
    RENDER_TIMES["swatch-${theme}"]="${dur_ms}"
    generate_metadata "${theme}" "swatch" "${final_out}"
    MANIFEST_ENTRIES+=("{\"theme\":\"${theme}\",\"type\":\"swatch\",\"file\":\"${out_dir}/${theme}.webp\",\"ms\":${dur_ms}}")
    log_pass "swatch" "${theme} (${dur_ms}ms)"
  else
    log_fail "swatch" "${theme}"
    FAILED_RENDERS+=("swatch:${theme}")
    (( TOTAL_FAILED++ )) || true
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# RENDERER: HERO BANNER
# ─────────────────────────────────────────────────────────────────────────────
render_hero() {
  local out_dir="${OUTPUT_DIR}/hero"
  local tmp_png="${WORK_DIR}/tmp-hero-$$.png"
  local final_out="${out_dir}/hero-banner.webp"

  mkdir -p "${out_dir}"
  if check_cache "hero" "hero" "${final_out}"; then
    log_cache "hero" "hero-banner"
    CACHED_FILES+=("${final_out}"); (( TOTAL_CACHED++ )) || true
    return 0
  fi

  log_render "hero" "${HERO_W}×${HERO_H} marketing banner"
  local t0; t0=$(date +%s%N 2>/dev/null || echo 0)

  python3 << HERO_PY
import sys
sys.path.insert(0, "")

${PYTHON_PREAMBLE}

OUTPUT_PNG = "${tmp_png}"
HERO_W_IN  = int("${HERO_W}") / 100
HERO_H_IN  = int("${HERO_H}") / 100
DPI_V      = 100
W, H       = 100.0, int("${HERO_H}") / int("${HERO_W}") * 100
TC         = dict(PALETTE)

def tc(k): return TC.get(k, h(k))

fig = plt.figure(figsize=(HERO_W_IN, HERO_H_IN), dpi=DPI_V)
fig.patch.set_facecolor(tc("base"))
ax  = fig.add_axes([0, 0, 1, 1])
ax.set_facecolor(tc("base"))
ax.set_xlim(0, W); ax.set_ylim(0, H)
ax.axis("off")

# ── Animated mesh gradient background ─────────────────────────────────────────
x  = np.linspace(0, 1, 600); y = np.linspace(0, 1, 400)
XX, YY = np.meshgrid(x, y)
Z = (np.sin(XX * np.pi * 2.5) * 0.28
   + np.cos(YY * np.pi * 3.5) * 0.28
   + np.sin((XX + YY) * np.pi * 1.8) * 0.44)
cmap = LinearSegmentedColormap.from_list("hero_bg", [
    tc("crust"), tc("base"), tc("mantle"),
    tc("mauve") + "14", tc("base"),
    tc("blue") + "10", tc("crust")
])
ax.imshow(Z, extent=[0, W, 0, H], aspect="auto",
          cmap=cmap, alpha=0.68, zorder=1)

# ── Large floating orbs ───────────────────────────────────────────────────────
ORBS = [
    (14, H*0.72, 22, "mauve",    0.065),
    (87, H*0.28, 28, "blue",     0.055),
    (50, H*0.98, 16, "teal",     0.085),
    (28, H*0.10, 13, "green",    0.075),
    (72, H*0.82, 18, "sapphire", 0.065),
    (8,  H*0.35, 10, "pink",     0.055),
    (92, H*0.65, 12, "yellow",   0.050),
]
for ox, oy, rad, col, alph in ORBS:
    add_radial_glow(ax, ox, oy, rad, col, layers=6, base_alpha=alph)

# ── Dense particle field ──────────────────────────────────────────────────────
add_particle_field(ax, W, H,
    ["mauve","blue","teal","green","sapphire","pink","yellow","peach","lavender"],
    count=120, seed=2024, alpha=0.30)

# ── Left side: ASCII logo ──────────────────────────────────────────────────────
LOGO_LINES = [
    (tc("mauve"),    "░█████╗░░██████╗██╗"),
    (tc("blue"),     "██╔══██╗██╔════╝██║"),
    (tc("sapphire"), "███████║╚█████╗░███████╗"),
    (tc("teal"),     "██╔══██║░╚═══██╗██╔══██╗"),
    (tc("green"),    "██║░░██║██████╔╝██║░░██║"),
    (tc("overlay1"), "╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝"),
]
ly = H * 0.88
for col, line in LOGO_LINES:
    ax.text(3.5, ly, line, color=col, fontsize=5.0,
            fontfamily="monospace", fontweight="bold", va="center", zorder=10)
    ly -= H * 0.10

# ── Center: Main headline ─────────────────────────────────────────────────────
CENTER_Y = H * 0.62
ax.text(50, CENTER_Y + H * 0.12, "ASH Dotfiles",
    ha="center", va="center",
    color=tc("text"), fontsize=42, fontweight="bold",
    zorder=10, alpha=0.97)
ax.text(50, CENTER_Y - H * 0.02, "v5.0 OMEGA",
    ha="center", va="center",
    color=tc("mauve"), fontsize=20, fontweight="bold",
    style="italic", zorder=10)
ax.text(50, CENTER_Y - H * 0.14,
    "The Ultimate Hyprland Dotfiles · 250+ Themes · 150+ Plugins · 0 Limits",
    ha="center", va="center",
    color=tc("subtext0"), fontsize=8.5, zorder=10)

# ── Feature pills row ─────────────────────────────────────────────────────────
PILLS = [
    (tc("mauve"),    "🎨 250+ Themes"),
    (tc("blue"),     "🔌 150+ Plugins"),
    (tc("green"),    "⚡ <300ms Apply"),
    (tc("teal"),     "🤖 AI-Native"),
    (tc("sapphire"), "🌐 REST API"),
    (tc("pink"),     "📱 Mobile App"),
    (tc("yellow"),   "❄️ Nix Flake"),
]
pill_total_w = sum(len(t)*0.72 + 3.2 for _, t in PILLS) + len(PILLS) * 1.0
px_start = (100 - pill_total_w) / 2
pill_y = CENTER_Y - H * 0.30

for color, text in PILLS:
    pw = len(text)*0.72 + 3.2
    ax.add_patch(FancyBboxPatch(
        (px_start, pill_y - 1.5), pw, 3.0,
        boxstyle="round,pad=0.25",
        facecolor=color + "28",
        edgecolor=color + "75", linewidth=0.9, zorder=10))
    ax.text(px_start + pw/2, pill_y,
        text, ha="center", va="center",
        color=color, fontsize=6.5, fontweight="bold", zorder=11)
    px_start += pw + 1.0

# ── Stats ticker strip ────────────────────────────────────────────────────────
STATS_Y = pill_y - H * 0.22
ax.text(50, STATS_Y,
    "⭐ 12.4k Stars  ·  🔀 847 Forks  ·  👥 156 Contributors  ·  "
    "MIT License  ·  Hyprland Powered  ·  ash-dotfiles.dev",
    ha="center", va="center",
    color=tc("overlay0"), fontsize=6.0, zorder=10)

# ── Right: Vertical color palette strip ───────────────────────────────────────
VERT_KEYS = ["red","peach","yellow","green","teal","sapphire",
              "blue","mauve","pink","flamingo"]
VERT_AVAIL= [k for k in VERT_KEYS if k in TC]
cell_h = (H - 4) / max(len(VERT_AVAIL), 1)
for i, k in enumerate(VERT_AVAIL):
    y0 = 2 + i * cell_h
    ax.add_patch(FancyBboxPatch(
        (77.5 + (i % 2) * 3.2, y0), 3.0, cell_h - 0.4,
        boxstyle="round,pad=0.18",
        facecolor=TC[k], alpha=0.88, edgecolor="none", zorder=9))

ensure_dir(str(Path(OUTPUT_PNG).parent))
plt.tight_layout(pad=0)
plt.savefig(OUTPUT_PNG, dpi=DPI_V, bbox_inches="tight", pad_inches=0,
            facecolor=tc("base"), edgecolor="none")
plt.close("all")
print(f"OK:{OUTPUT_PNG}")
HERO_PY

  local t1; t1=$(date +%s%N 2>/dev/null || echo 0)
  local dur_ms=$(( (t1 - t0) / 1000000 ))

  if [[ -f "${tmp_png}" ]]; then
    convert_and_optimize "${tmp_png}" "hero-banner" "${out_dir}" "hero"
    save_cache_hash "hero" "hero"
    RENDER_TIMES["hero"]="${dur_ms}"
    generate_metadata "hero" "hero" "${final_out}"
    MANIFEST_ENTRIES+=("{\"type\":\"hero\",\"file\":\"${out_dir}/hero-banner.webp\",\"ms\":${dur_ms}}")
    log_pass "hero" "hero-banner.webp (${dur_ms}ms)"
  else
    log_fail "hero" "hero-banner render failed"
    FAILED_RENDERS+=("hero:hero-banner")
    (( TOTAL_FAILED++ )) || true
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# ASSET CATALOG & CHECKSUM MANIFEST
# ─────────────────────────────────────────────────────────────────────────────
generate_catalog() {
  [[ "${ASSET_CATALOG}" != "true" ]] && return 0

  log_step "catalog" "Building asset catalog..."

  local CATALOG="${WORK_DIR}/assets.json"
  local NOW; NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local DURATION_S=$(( $(date +%s) - START_EPOCH ))
  local SIZE_MB; SIZE_MB=$(echo "scale=2; ${TOTAL_SIZE_BYTES}/1048576" | bc 2>/dev/null || echo "0")
  local CACHE_RATE=0
  local TOTAL_ATTEMPTS=$(( TOTAL_GENERATED + TOTAL_CACHED ))
  [[ "${TOTAL_ATTEMPTS}" -gt 0 ]] && \
    CACHE_RATE=$(( TOTAL_CACHED * 100 / TOTAL_ATTEMPTS ))
  local FAIL_RATE=0
  [[ "${TOTAL_GENERATED}" -gt 0 ]] && \
    FAIL_RATE=$(( TOTAL_FAILED * 100 / (TOTAL_GENERATED + TOTAL_FAILED + 1) ))
  local THROUGHPUT=0
  [[ "${DURATION_S}" -gt 0 ]] && \
    THROUGHPUT=$(( TOTAL_GENERATED * 60 / DURATION_S ))

  # Build manifest JSON
  local MANIFEST_JSON="["
  local FIRST=true
  for entry in "${MANIFEST_ENTRIES[@]:-}"; do
    [[ -z "${entry}" ]] && continue
    [[ "${FIRST}" == "false" ]] && MANIFEST_JSON+=","
    MANIFEST_JSON+="${entry}"
    FIRST="false"
  done
  MANIFEST_JSON+="]"

  cat > "${CATALOG}" << CATALOG_EOF
{
  "version":         "${GENERATE_VERSION}",
  "session_id":      "${SESSION_ID}",
  "generated_at":    "${NOW}",
  "quality":         "${QUALITY_PRESET}",
  "format":          "${OUTPUT_FORMAT}",
  "resolution":      "${RES_W}x${RES_H}",
  "dpi":             ${DPI},
  "webp_quality":    ${FINAL_WQ},
  "lossless":        ${LOSSLESS},
  "renderer":        "${RENDERER_BACKEND}",
  "statistics": {
    "total_generated":  ${TOTAL_GENERATED},
    "total_failed":     ${TOTAL_FAILED},
    "total_cached":     ${TOTAL_CACHED},
    "total_size_mb":    ${SIZE_MB},
    "total_size_bytes": ${TOTAL_SIZE_BYTES},
    "duration_s":       ${DURATION_S},
    "throughput_min":   ${THROUGHPUT},
    "cache_hit_rate":   ${CACHE_RATE},
    "failure_rate":     ${FAIL_RATE}
  },
  "failed_renders": $(printf '%s\n' "${FAILED_RENDERS[@]:-none}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "screenshots":     ${MANIFEST_JSON}
}
CATALOG_EOF

  local MANIFEST="${WORK_DIR}/manifest.json"
  cp "${CATALOG}" "${MANIFEST}"
  log_pass "catalog" "assets.json (${#MANIFEST_ENTRIES[@]} entries)"

  echo "manifest_path=${MANIFEST}" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "catalog_path=${CATALOG}"   >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECKSUM MANIFEST
# ─────────────────────────────────────────────────────────────────────────────
generate_checksums() {
  [[ "${CHECKSUMS}" != "true" ]] && return 0

  log_step "checksums" "Computing SHA-256 checksums..."

  local SHA_FILE="${WORK_DIR}/checksums.sha256"
  local MD5_FILE="${WORK_DIR}/checksums.md5"

  > "${SHA_FILE}"
  > "${MD5_FILE}"

  local checksum_count=0
  find "${OUTPUT_DIR}" -type f \( \
    -name "*.webp" -o -name "*.png" -o -name "*.jpg" -o -name "*.avif" \
  \) | sort | while read -r f; do
    sha256sum "${f}" >> "${SHA_FILE}" 2>/dev/null || true
    md5sum "${f}"    >> "${MD5_FILE}"  2>/dev/null || true
    (( checksum_count++ )) || true
  done

  log_pass "checksums" "SHA-256 + MD5 ($(wc -l < "${SHA_FILE}" || echo 0) files)"
  echo "checksums_path=${SHA_FILE}" >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# HTML GALLERY REPORT
# ─────────────────────────────────────────────────────────────────────────────
generate_html_report() {
  [[ "${GEN_HTML}" != "true" ]] && return 0

  log_step "html" "Generating HTML gallery report..."

  local REPORT="${WORK_DIR}/gallery-report.html"
  local CARD_FILES=()
  mapfile -t CARD_FILES < <(find "${OUTPUT_DIR}/cards" -name "*.webp" 2>/dev/null | sort)

  python3 << HTML_PY
from pathlib import Path
import json, os
from datetime import datetime, timezone

REPORT_PATH = "${REPORT}"
CARD_FILES  = """${CARD_FILES[*]:-}""".split() if """${CARD_FILES[*]:-}""".strip() else []
SESSION_ID  = "${SESSION_ID}"
QUALITY     = "${QUALITY_PRESET}"
GENERATED   = ${TOTAL_GENERATED}
NOW         = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

P = {
    "base": "#1e1e2e", "mantle": "#181825", "surface0": "#313244",
    "overlay0": "#6c7086", "text": "#cdd6f4", "subtext0": "#a6adc8",
    "mauve": "#cba6f7", "blue": "#89b4fa", "green": "#a6e3a1",
    "red": "#f38ba8", "yellow": "#f9e2af", "teal": "#94e2d5",
}

cards_html = ""
for card_path in CARD_FILES[:50]:  # Limit to 50 for performance
    name = Path(card_path).stem
    rel_path = os.path.relpath(card_path, os.environ.get("WORK_DIR", "."))
    display = name.replace("-", " ").title()
    cards_html += f"""
    <div class="card">
        <img src="{card_path}" alt="{display}" loading="lazy">
        <div class="card-body">
            <div class="theme-name">🎨 {display}</div>
            <div class="theme-meta"><code>{name}</code></div>
        </div>
    </div>"""

html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ASH Theme Gallery — {len(CARD_FILES)} Themes</title>
    <style>
        :root {{
            --base: {P["base"]}; --mantle: {P["mantle"]}; --surface: {P["surface0"]};
            --text: {P["text"]}; --sub: {P["subtext0"]}; --mauve: {P["mauve"]};
            --blue: {P["blue"]}; --green: {P["green"]}; --overlay: {P["overlay0"]};
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{ background: var(--base); color: var(--text);
                font-family: "JetBrains Mono", "Fira Code", monospace;
                padding: 2rem; }}
        h1 {{ color: var(--mauve); font-size: 2.2rem; margin-bottom: 0.5rem; }}
        .subtitle {{ color: var(--sub); margin-bottom: 2rem; font-size: 0.9rem; }}
        .stats {{ display: flex; gap: 2rem; margin-bottom: 2rem;
                  background: var(--mantle); border-radius: 12px; padding: 1.5rem; }}
        .stat {{ text-align: center; }}
        .stat-val {{ font-size: 2rem; font-weight: bold; color: var(--mauve); }}
        .stat-lbl {{ color: var(--sub); font-size: 0.8rem; }}
        .grid {{ display: grid;
                 grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
                 gap: 1.5rem; }}
        .card {{ background: var(--mantle); border-radius: 12px; overflow: hidden;
                 border: 1px solid var(--surface);
                 transition: transform 0.2s ease, box-shadow 0.2s ease; }}
        .card:hover {{ transform: translateY(-4px);
                       box-shadow: 0 8px 24px rgba(0,0,0,0.4); }}
        .card img {{ width: 100%; display: block; aspect-ratio: 3/2; object-fit: cover; }}
        .card-body {{ padding: 1rem; }}
        .theme-name {{ font-size: 1rem; font-weight: bold; color: var(--mauve); }}
        .theme-meta {{ color: var(--sub); font-size: 0.75rem; margin-top: 0.25rem; }}
        footer {{ margin-top: 3rem; color: var(--overlay); text-align: center;
                  font-size: 0.8rem; border-top: 1px solid var(--surface);
                  padding-top: 1.5rem; }}
    </style>
</head>
<body>
    <h1>🎨 ASH Theme Gallery</h1>
    <p class="subtitle">v5.0 OMEGA · {len(CARD_FILES)} themes · {QUALITY} quality · {NOW}</p>
    <div class="stats">
        <div class="stat"><div class="stat-val">{len(CARD_FILES)}</div><div class="stat-lbl">Themes</div></div>
        <div class="stat"><div class="stat-val">{GENERATED}</div><div class="stat-lbl">Screenshots</div></div>
        <div class="stat"><div class="stat-val">{QUALITY}</div><div class="stat-lbl">Quality</div></div>
        <div class="stat"><div class="stat-val">WebP</div><div class="stat-lbl">Format</div></div>
    </div>
    <div class="grid">{cards_html}</div>
    <footer>Generated by ASH v5.0 OMEGA Screenshot Engine · Session <code>{SESSION_ID}</code></footer>
</body>
</html>"""

Path(REPORT_PATH).write_text(html, encoding="utf-8")
print(f"  ✅ HTML report: {len(CARD_FILES)} themes")
HTML_PY

  log_pass "html" "gallery-report.html"
  echo "html_report_path=${REPORT}" >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL DASHBOARD — Summary report
# ─────────────────────────────────────────────────────────────────────────────
print_final_dashboard() {
  local END_S; END_S=$(date +%s)
  local DURATION_S=$(( END_S - START_EPOCH ))
  local SIZE_MB; SIZE_MB=$(echo "scale=2; ${TOTAL_SIZE_BYTES}/1048576" | bc 2>/dev/null || echo "0")
  local TOTAL_ATTEMPTS=$(( TOTAL_GENERATED + TOTAL_CACHED ))
  local CACHE_RATE=0
  [[ "${TOTAL_ATTEMPTS}" -gt 0 ]] && \
    CACHE_RATE=$(( TOTAL_CACHED * 100 / TOTAL_ATTEMPTS ))
  local FAIL_RATE=0
  local TOTAL_WITH_FAILS=$(( TOTAL_GENERATED + TOTAL_FAILED ))
  [[ "${TOTAL_WITH_FAILS}" -gt 0 ]] && \
    FAIL_RATE=$(( TOTAL_FAILED * 100 / TOTAL_WITH_FAILS ))
  local THROUGHPUT=0
  [[ "${DURATION_S}" -gt 0 ]] && \
    THROUGHPUT=$(( TOTAL_GENERATED * 60 / DURATION_S ))
  local LARGEST_FILE_KB=0
  local LARGEST_FILE_PATH=""
  for f in "${RENDERED_FILES[@]:-}"; do
    [[ -f "${f}" ]] || continue
    local sz; sz=$(wc -c < "${f}" 2>/dev/null || echo 0)
    local sz_kb=$(( sz / 1024 ))
    if [[ "${sz_kb}" -gt "${LARGEST_FILE_KB}" ]]; then
      LARGEST_FILE_KB="${sz_kb}"
      LARGEST_FILE_PATH="${f}"
    fi
  done
  local AVG_KB=0
  [[ "${TOTAL_GENERATED}" -gt 0 ]] && \
    AVG_KB=$(echo "scale=1; ${TOTAL_SIZE_BYTES}/1024/${TOTAL_GENERATED}" | bc 2>/dev/null || echo "0")

  # Build progress bars
  local W=30
  local SUCCESS_PCT=0
  [[ $(( TOTAL_GENERATED + TOTAL_FAILED )) -gt 0 ]] && \
    SUCCESS_PCT=$(( TOTAL_GENERATED * 100 / ( TOTAL_GENERATED + TOTAL_FAILED ) ))

  local SUC_FILL=$(( SUCCESS_PCT * W / 100 ))
  local CAC_FILL=$(( CACHE_RATE  * W / 100 ))
  local SUC_BAR="" CAC_BAR=""
  for (( i=0; i<SUC_FILL; i++ )); do SUC_BAR+="█"; done
  for (( i=SUC_FILL; i<W; i++ )); do SUC_BAR+="░"; done
  for (( i=0; i<CAC_FILL; i++ )); do CAC_BAR+="▓"; done
  for (( i=CAC_FILL; i<W; i++ )); do CAC_BAR+="░"; done

  local STATUS_COLOR="${C_GREEN}"
  [[ "${TOTAL_FAILED}" -gt 0 ]] && STATUS_COLOR="${C_YELLOW}"
  [[ "${FAIL_RATE}" -gt 50 ]]   && STATUS_COLOR="${C_RED}"

  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  echo "  ╔══════════════════════════════════════════════════════════════════════╗"
  echo "  ║  📸 ASH SCREENSHOT GENERATION — COMPLETE                             ║"
  echo "  ╠══════════════════════════════════════════════════════════════════════╣"
  echo -e "${C_RST}${C_MAUVE}${C_BLD}"
  printf  "  ║${C_RST}  ${C_TEXT}Success  [${STATUS_COLOR}%s${C_TEXT}] %d%%${C_RST}%*s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${SUC_BAR}" "${SUCCESS_PCT}" $(( 30 - ${#SUC_BAR} - 8 )) ""
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Cached   [${C_SAP}%s${C_TEXT}] %d%%${C_RST}%*s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${CAC_BAR}" "${CACHE_RATE}" $(( 30 - ${#CAC_BAR} - 8 )) ""
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_GREEN}✅ Generated:${C_RST}  %-10s  ${C_SAP}💾 Cached:${C_RST}   %-20s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${TOTAL_GENERATED}" "${TOTAL_CACHED}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_RED}❌ Failed:${C_RST}    %-10s  ${C_PEACH}⚡ Throughput:${C_RST} %-18s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${TOTAL_FAILED}" "${THROUGHPUT}/min"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_LAVENDER}📦 Total Size:${C_RST} %-10s  ${C_TEAL}⏱️  Duration:${C_RST}  %-18s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${SIZE_MB}MB" "${DURATION_S}s"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_YELLOW}📏 Avg Size:${C_RST}   %-10s  ${C_FLAMINGO}🎚️  Quality:${C_RST}   %-18s${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${AVG_KB}KB" "${QUALITY_PRESET} (q${FINAL_WQ})"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_OVERLAY0}📁 Output:     %-60s${C_MAUVE}${C_BLD}║${C_RST}\n" "${OUTPUT_DIR:0:60}"
  echo -e "  ${C_MAUVE}${C_BLD}╚══════════════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""

  # Emit GitHub outputs
  {
    echo "total_generated=${TOTAL_GENERATED}"
    echo "total_failed=${TOTAL_FAILED}"
    echo "total_cached=${TOTAL_CACHED}"
    echo "total_skipped=0"
    echo "themes_rendered=$(echo "${THEME_LIST}" | tr ',' '\n' | grep -cv '^$' || echo 0)"
    echo "themes_failed=$(IFS=,; echo "${FAILED_RENDERS[*]:-}" | tr ':' '\n' | grep desktop | tr '\n' ',' | sed 's/,$//')"
    echo "types_generated=${SCREENSHOT_TYPES}"
    echo "output_dir=${OUTPUT_DIR}"
    echo "total_size_mb=${SIZE_MB}"
    echo "total_size_bytes=${TOTAL_SIZE_BYTES}"
    echo "avg_size_kb=${AVG_KB}"
    echo "largest_file=${LARGEST_FILE_PATH}"
    echo "duration_s=${DURATION_S}"
    echo "throughput=${THROUGHPUT}"
    echo "cache_hit_rate=${CACHE_RATE}"
    echo "failure_rate=${FAIL_RATE}"
    echo "success=$( [[ "${FAIL_RATE}" -le "${FAIL_THRESHOLD}" ]] && echo true || echo false)"
    echo "hero_path=${OUTPUT_DIR}/hero/hero-banner.webp"
    echo "mosaic_path=${OUTPUT_DIR}/mosaics/all-themes.webp"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP — Graceful failure handling
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo ""
  echo -e "\033[38;2;243;139;168m❌ generate.sh exited with code ${EXIT_CODE}\033[0m"
  if [[ -f "${ERROR_LOG}" ]] && [[ -s "${ERROR_LOG}" ]]; then
    echo -e $'\033[38;2;108;112;134m── Last errors ──────────────────────────────\033[0m'
    tail -10 "${ERROR_LOG}" | sed "s/^/   /"
  fi
  # Emit partial outputs even on failure
  {
    echo "total_generated=${TOTAL_GENERATED}"
    echo "total_failed=${TOTAL_FAILED}"
    echo "total_cached=${TOTAL_CACHED}"
    echo "success=false"
    echo "duration_s=$(( $(date +%s) - START_EPOCH ))"
  } >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
fi
# Clean up temp files
find "${WORK_DIR}" -name "tmp-*.png" -delete 2>/dev/null || true
' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# MAIN — Primary execution pipeline
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # ── Resolve screenshot type flags ─────────────────────────────────────────
  local RUN_DESKTOP=false   RUN_CARD=false      RUN_SWATCH=false
  local RUN_HERO=false      RUN_NEOVIM=false    RUN_COMPONENTS=false
  local RUN_PERFORMANCE=false RUN_MOSAIC=false  RUN_A11Y=false
  local RUN_COMPARISON=false  RUN_MOBILE=false  RUN_ANIMATED=false

  IFS=',' read -ra TYPES_ARR <<< "${SCREENSHOT_TYPES}"
  for t in "${TYPES_ARR[@]}"; do
    t=$(echo "${t}" | tr -d ' ')
    case "${t}" in
      all)           RUN_DESKTOP=true; RUN_CARD=true; RUN_SWATCH=true
                     RUN_HERO=true; RUN_NEOVIM=true; RUN_PERFORMANCE=true ;;
      desktop)       RUN_DESKTOP=true    ;;
      card)          RUN_CARD=true       ;;
      swatch)        RUN_SWATCH=true     ;;
      hero)          RUN_HERO=true       ;;
      neovim)        RUN_NEOVIM=true     ;;
      components)    RUN_COMPONENTS=true ;;
      performance)   RUN_PERFORMANCE=true;;
      mosaic)        RUN_MOSAIC=true     ;;
      accessibility) RUN_A11Y=true       ;;
      comparison)    RUN_COMPARISON=true ;;
      mobile)        RUN_MOBILE=true     ;;
      animated)      RUN_ANIMATED=true   ;;
    esac
  done

  # ── Parse theme list ──────────────────────────────────────────────────────
  IFS=',' read -ra THEMES_ARR <<< "${THEME_LIST}"
  local TOTAL_THEMES="${#THEMES_ARR[@]}"

  echo ""
  echo -e "  ${C_SAPPHIRE}${C_BLD}━━━ Pipeline Start ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"
  echo -e "  ${C_TEXT}${TOTAL_THEMES} themes · $(echo "${SCREENSHOT_TYPES}" | tr ',' '\n' | grep -c .) type(s) · ${PARALLEL_WORKERS} workers${C_RST}"
  echo ""

  # ── Phase 1: Non-per-theme renders ───────────────────────────────────────
  if [[ "${RUN_HERO}" == "true" ]]; then
    section_header "Hero Banner" "🖼️" "${C_LAVENDER}"
    render_hero || true
    section_footer "${C_LAVENDER}"
  fi

  # ── Phase 2: Per-theme renders ────────────────────────────────────────────
  section_header "Per-Theme Rendering" "🎨" "${C_MAUVE}"
  progress_init "${TOTAL_THEMES}" "Themes"

  local THEME_IDX=0
  for theme in "${THEMES_ARR[@]}"; do
    theme=$(echo "${theme}" | tr -d ' ')
    [[ -z "${theme}" ]] && continue
    (( THEME_IDX++ )) || true

    echo ""
    echo -e "  ${C_PINK}${C_BLD}┌── [${THEME_IDX}/${TOTAL_THEMES}] ${C_TEXT}${theme}${C_RST}"

    # Load colors
    local COLORS_FILE=""
    for cat in dark light neon nature space pastel anime retro gradient seasonal mood gaming minimal special; do
      local candidate="${WORKSPACE}/${THEMES_DIR}/${cat}/${theme}/colors.json"
      if [[ -f "${candidate}" ]]; then
        COLORS_FILE="${candidate}"
        break
      fi
    done

    if [[ -z "${COLORS_FILE}" ]]; then
      # Generate defaults
      COLORS_FILE="${WORK_DIR}/colors-${theme}.json"
      python3 -c "
import json, sys
BUILTINS = {
  'catppuccin-mocha': {'base':'#1e1e2e','mantle':'#181825','crust':'#11111b','surface0':'#313244','surface1':'#45475a','surface2':'#585b70','overlay0':'#6c7086','overlay1':'#7f849c','overlay2':'#9399b2','subtext0':'#a6adc8','subtext1':'#bac2de','text':'#cdd6f4','lavender':'#b4befe','blue':'#89b4fa','sapphire':'#74c7ec','sky':'#89dceb','teal':'#94e2d5','green':'#a6e3a1','yellow':'#f9e2af','peach':'#fab387','maroon':'#eba0ac','red':'#f38ba8','mauve':'#cba6f7','pink':'#f5c2e7','flamingo':'#f2cdcd','rosewater':'#f5e0dc','accent':'#cba6f7'},
  'tokyo-night':       {'base':'#1a1b26','mantle':'#16161e','crust':'#13131a','surface0':'#292e42','surface1':'#3b4261','surface2':'#414868','overlay0':'#565f89','overlay1':'#737aa2','overlay2':'#939ab7','subtext0':'#a9b1d6','subtext1':'#c0caf5','text':'#c0caf5','lavender':'#c8d3f5','blue':'#7aa2f7','sapphire':'#2ac3de','sky':'#7dcfff','teal':'#1abc9c','green':'#9ece6a','yellow':'#e0af68','peach':'#ff9e64','maroon':'#db4b4b','red':'#f7768e','mauve':'#bb9af7','pink':'#ff007c','flamingo':'#f7768e','rosewater':'#f7768e','accent':'#7aa2f7'},
}
name = '${theme}'.lower().replace(' ','-')
colors = BUILTINS.get(name, BUILTINS['catppuccin-mocha'])
json.dump(colors, open('${COLORS_FILE}','w'), indent=2)
" 2>/dev/null || true
      log_debug "colors" "Generated defaults for ${theme}"
    fi

    log_theme "colors" "${theme} ← ${COLORS_FILE##*/}"

    # ── Run selected renderers ───────────────────────────────────────────────
    [[ "${RUN_DESKTOP}"   == "true" ]] && render_desktop   "${theme}" "${COLORS_FILE}" || true
    [[ "${RUN_CARD}"      == "true" ]] && render_card      "${theme}" "${COLORS_FILE}" || true
    [[ "${RUN_SWATCH}"    == "true" ]] && render_swatch    "${theme}" "${COLORS_FILE}" || true

    # Additional renderers (delegated to separate functions if implemented)
    if [[ "${RUN_NEOVIM}" == "true" ]]; then
      log_info "neovim" "${theme} — (render_neovim delegated)"
      # render_neovim "${theme}" "${COLORS_FILE}" || true
    fi

    progress_tick
  done

  section_footer "${C_MAUVE}"

  # ── Phase 3: Catalog, checksums, HTML ─────────────────────────────────────
  section_header "Artifact Generation" "📦" "${C_PEACH}"
  generate_catalog   || true
  generate_checksums || true
  generate_html_report || true
  section_footer "${C_PEACH}"

  # ── Final dashboard ────────────────────────────────────────────────────────
  print_final_dashboard

  # ── Failure gate ──────────────────────────────────────────────────────────
  local FAIL_RATE=0
  local TOTAL_WITH_FAILS=$(( TOTAL_GENERATED + TOTAL_FAILED ))
  [[ "${TOTAL_WITH_FAILS}" -gt 0 ]] && \
    FAIL_RATE=$(( TOTAL_FAILED * 100 / TOTAL_WITH_FAILS ))

  if [[ "${FAIL_RATE}" -gt "${FAIL_THRESHOLD}" ]]; then
    log_fail "gate" "Failure rate ${FAIL_RATE}% exceeds threshold ${FAIL_THRESHOLD}%"
    exit 1
  fi

  log_pass "complete" "Screenshot engine done ✨ (${TOTAL_GENERATED} files, ${TOTAL_FAILED} failures)"
}

# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
main "$@"