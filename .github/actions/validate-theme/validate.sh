#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🎨 ASH DOTFILES v5.0 OMEGA — THEME VALIDATION ENGINE                                    ║
# ║                                                                                           ║
# ║  ██╗   ██╗ █████╗ ██╗     ██╗██████╗  █████╗ ████████╗███████╗                           ║
# ║  ██║   ██║██╔══██╗██║     ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝                           ║
# ║  ██║   ██║███████║██║     ██║██║  ██║███████║   ██║   █████╗                             ║
# ║  ╚██╗ ██╔╝██╔══██║██║     ██║██║  ██║██╔══██║   ██║   ██╔══╝                             ║
# ║   ╚████╔╝ ██║  ██║███████╗██║██████╔╝██║  ██║   ██║   ███████╗                           ║
# ║    ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝                           ║
# ║                                                                                           ║
# ║  Version:  5.0.0-omega                                                                   ║
# ║  Pipeline: structure → colors → wcag → harmony → metadata → naming → security → perf    ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS & CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
readonly VALIDATOR_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_TIME=$(date +%s%N)

# Input from environment (set by action.yml)
THEME_DIR="${THEME_DIR:?THEME_DIR not set}"
THEME_NAME="${THEME_NAME:-$(basename "${THEME_DIR}")}"
WORK_DIR="${WORK_DIR:-/tmp/ash-validate}"
VALIDATION_LEVEL="${VALIDATION_LEVEL:-standard}"
WCAG_LEVEL="${WCAG_LEVEL:-AA}"
FAIL_ON_WCAG="${FAIL_ON_WCAG:-true}"
MIN_COLORS="${MIN_COLORS:-16}"
MAX_COLORS="${MAX_COLORS:-32}"
REQUIRED_COLOR_KEYS="${REQUIRED_COLOR_KEYS:-base,text,accent,surface0,overlay0,blue,green,red,yellow}"
CHECK_HARMONY="${CHECK_HARMONY:-true}"
CHECK_DUPLICATES="${CHECK_DUPLICATES:-true}"
REQUIRED_META="${REQUIRED_META:-name,version,author,category,description}"
ENFORCE_NAMING="${ENFORCE_NAMING:-true}"
VALIDATE_PREVIEW="${VALIDATE_PREVIEW:-false}"
MIN_PREVIEW_W="${MIN_PREVIEW_W:-1280}"
MIN_PREVIEW_H="${MIN_PREVIEW_H:-720}"
MINIMUM_SCORE="${MINIMUM_SCORE:-70}"
SCORE_WEIGHTS="${SCORE_WEIGHTS:-}"
SECURITY_SCAN="${SECURITY_SCAN:-true}"
MAX_SIZE_KB="${MAX_SIZE_KB:-10240}"
MAX_WP_SIZE_MB="${MAX_WP_SIZE_MB:-20}"
REPORT_FORMAT="${REPORT_FORMAT:-markdown}"
VERBOSE="${VERBOSE:-false}"
SCHEMA_PASSED="${SCHEMA_PASSED:-false}"
SCHEMA_ERRORS="${SCHEMA_ERRORS:-0}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA ANSI COLORS
# ─────────────────────────────────────────────────────────────────────────────
C_R='\033[0m'       C_B='\033[1m'      C_D='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'   C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'   C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'  C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'    C_SAPPHIRE='\033[38;2;116;199;236m'
C_SKY='\033[38;2;137;220;235m'     C_PINK='\033[38;2;245;194;231m'
C_TEXT='\033[38;2;205;214;244m'    C_SUB='\033[38;2;166;173;200m'
C_OVR='\033[38;2;108;112;134m'     C_LAV='\033[38;2;180;190;254m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
LOG_FILE="${WORK_DIR}/validate.log"
mkdir -p "${WORK_DIR}"

_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date +%H:%M:%S)
  echo -e "${color}${icon}${C_R} ${C_D}[${ts}]${C_R} ${C_TEXT}$*${C_R}"
  echo "[${ts}] $*" >> "${LOG_FILE}"
}

log_pass()  { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()  { _log "❌" "${C_RED}"     "$@"; }
log_warn()  { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()  { _log "ℹ️ " "${C_BLUE}"    "$@"; }
log_check() { _log "🔍" "${C_MAUVE}"   "$@"; }
log_score() { _log "📊" "${C_SAPPHIRE}" "$@"; }
log_debug() { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION STATE
# ─────────────────────────────────────────────────────────────────────────────
declare -a ERRORS=()
declare -a WARNINGS=()
declare -a CHECK_RESULTS=()

# Score tracking
SCORE_STRUCTURE=0
SCORE_COLORS=0
SCORE_WCAG=0
SCORE_METADATA=0
SCORE_NAMING=0
SCORE_SECURITY=0
SCORE_PERFORMANCE=0
SCORE_SCHEMA=0

# Result flags
STRUCT_PASSED="false"
COLORS_PASSED="false"
WCAG_PASSED="false"
META_PASSED="false"
NAMING_PASSED="false"
SECURITY_PASSED="false"
SCHEMA_RESULT="${SCHEMA_PASSED}"

# Color data
ACCENT_COLOR="#888888"
COLOR_COUNT=0
THEME_CATEGORY="unknown"
THEME_VERSION="0.0.0"
WCAG_MIN_RATIO="0.0"
WCAG_PAIRS=0

add_error()   { ERRORS+=("$*");   log_fail   "$*"; }
add_warning() { WARNINGS+=("$*"); log_warn   "$*"; }
add_pass()    { CHECK_RESULTS+=("✅ $*"); log_pass "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_MAUVE}${C_B}"
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  echo "  ║  🎨 ASH Theme Validation Engine v${VALIDATOR_VERSION}              ║"
  echo "  ╠══════════════════════════════════════════════════════════════╣"
  printf  "  ║  🏷️  Theme:   %-49s║\n" "${THEME_NAME}"
  printf  "  ║  🎯 Level:   %-49s║\n" "${VALIDATION_LEVEL}"
  printf  "  ║  ♿ WCAG:    %-49s║\n" "${WCAG_LEVEL}"
  printf  "  ║  📁 Dir:     %-49s║\n" "${THEME_DIR:0:49}"
  echo "  ╚══════════════════════════════════════════════════════════════╝"
  echo -e "${C_R}"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 1 — File Structure
# ─────────────────────────────────────────────────────────────────────────────
check_structure() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 1: File Structure ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  local score=100
  local required_passed=0
  local required_total=0

  # Required files
  declare -A REQUIRED_FILES=(
    ["theme.conf"]="Theme configuration file"
    ["colors.json"]="Color palette definitions"
    ["metadata.json"]="Theme metadata"
  )

  # Optional but recommended files
  declare -A OPTIONAL_FILES=(
    ["preview.webp"]="Theme preview image"
    ["wallpaper.jpg"]="Default wallpaper"
    ["README.md"]="Theme documentation"
  )

  echo "  📋 Required files:"
  for file in "${!REQUIRED_FILES[@]}"; do
    ((required_total++))
    local desc="${REQUIRED_FILES[$file]}"
    if [[ -f "${THEME_DIR}/${file}" ]]; then
      local size; size=$(wc -c < "${THEME_DIR}/${file}" 2>/dev/null || echo 0)
      if [[ "${size}" -gt 0 ]]; then
        add_pass "Required: ${file} (${size} bytes)"
        ((required_passed++))
      else
        add_error "Required file is empty: ${file}"
        score=$((score - 25))
      fi
    else
      add_error "Missing required file: ${file} — ${desc}"
      score=$((score - 30))
    fi
  done

  echo "  📁 Optional files:"
  for file in "${!OPTIONAL_FILES[@]}"; do
    if [[ -f "${THEME_DIR}/${file}" ]]; then
      log_pass "Optional: ${file} ✓"
      score=$((score + 3))
    else
      log_debug "Optional missing: ${file}"
    fi
  done

  # Validate theme.conf syntax
  local CONF="${THEME_DIR}/theme.conf"
  if [[ -f "${CONF}" ]]; then
    echo ""
    echo "  ⚙️ Parsing theme.conf..."

    # Check for required conf keys
    local CONF_KEYS=("name" "category" "version")
    for key in "${CONF_KEYS[@]}"; do
      if grep -qE "^${key}\s*=" "${CONF}" 2>/dev/null; then
        local val; val=$(grep -E "^${key}\s*=" "${CONF}" | head -1 | cut -d= -f2 | tr -d ' "'"'" )
        log_debug "conf.${key} = ${val}"
        case "${key}" in
          category) THEME_CATEGORY="${val}" ;;
          version)  THEME_VERSION="${val}" ;;
        esac
        add_pass "theme.conf.${key}: ${val}"
      else
        add_warning "theme.conf missing key: ${key}"
        score=$((score - 5))
      fi
    done
  fi

  # Calculate score (0-100)
  SCORE_STRUCTURE=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  [[ "${required_passed}" -eq "${required_total}" ]] && STRUCT_PASSED="true"

  log_score "Structure score: ${SCORE_STRUCTURE}/100 (${required_passed}/${required_total} required)"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 2 — Color Validation
# ─────────────────────────────────────────────────────────────────────────────
check_colors() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 2: Color Validation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  local COLORS_FILE="${THEME_DIR}/colors.json"
  if [[ ! -f "${COLORS_FILE}" ]]; then
    add_error "colors.json not found — cannot validate colors"
    SCORE_COLORS=0
    return
  fi

  python3 << PYTHON_EOF
import json
import math
import os
import sys
from pathlib import Path

COLORS_FILE   = "${COLORS_FILE}"
WORK_DIR      = "${WORK_DIR}"
MIN_COLORS    = int("${MIN_COLORS}")
MAX_COLORS    = int("${MAX_COLORS}")
REQ_KEYS_STR  = "${REQUIRED_COLOR_KEYS}"
CHECK_DUPES   = "${CHECK_DUPLICATES}" == "true"
CHECK_HARMONY = "${CHECK_HARMONY}" == "true"
VERBOSE       = "${VERBOSE}" == "true"

REQUIRED_KEYS = [k.strip() for k in REQ_KEYS_STR.split(",") if k.strip()]

# ── ANSI colors ───────────────────────────────────────────────────────────────
GREEN  = "\033[38;2;166;227;161m"
RED    = "\033[38;2;243;139;168m"
YELLOW = "\033[38;2;249;226;175m"
BLUE   = "\033[38;2;137;180;250m"
MAUVE  = "\033[38;2;203;166;247m"
TEXT   = "\033[38;2;205;214;244m"
SUB    = "\033[38;2;166;173;200m"
RST    = "\033[0m"

def p(icon, color, msg):
    print(f"  {color}{icon}{RST} {TEXT}{msg}{RST}")

errors   = []
warnings = []
score    = 100
accent   = "#888888"

# ── Load & parse colors.json ─────────────────────────────────────────────────
try:
    with open(COLORS_FILE) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    errors.append(f"colors.json invalid JSON: {e}")
    score = 0
    data  = {}
except Exception as e:
    errors.append(f"Cannot read colors.json: {e}")
    score = 0
    data  = {}

# Handle nested structure
colors = {}
if "colors" in data and isinstance(data["colors"], dict):
    colors = data["colors"]
elif isinstance(data, dict) and any(v.startswith("#") for v in data.values() if isinstance(v, str)):
    colors = data
else:
    colors = data

# ── Count colors ───────────────────────────────────────────────────────────────
color_count = len(colors)
p("🎨", BLUE, f"Color count: {color_count}")

if color_count < MIN_COLORS:
    errors.append(f"Too few colors: {color_count} (minimum {MIN_COLORS})")
    score -= 20
elif color_count > MAX_COLORS:
    warnings.append(f"Too many colors: {color_count} (maximum {MAX_COLORS})")
    score -= 5
else:
    p("✅", GREEN, f"Color count: {color_count} (in range {MIN_COLORS}-{MAX_COLORS})")

# ── HEX format validation ────────────────────────────────────────────────────
import re
HEX_PATTERN = re.compile(r'^#[0-9A-Fa-f]{6}$')
HEX_PATTERN_8 = re.compile(r'^#[0-9A-Fa-f]{8}$')

invalid_format = []
valid_colors   = {}

for key, val in colors.items():
    if isinstance(val, str):
        v = val.strip()
        if HEX_PATTERN.match(v) or HEX_PATTERN_8.match(v):
            valid_colors[key] = v.upper()
        else:
            invalid_format.append(f"{key}: '{v}'")
    elif isinstance(val, dict):
        # Nested: {hex: "#...", r: 0, g: 0, b: 0}
        hex_val = val.get("hex","") or val.get("color","")
        if HEX_PATTERN.match(str(hex_val)):
            valid_colors[key] = hex_val.upper()

if invalid_format:
    for inv in invalid_format[:5]:
        errors.append(f"Invalid hex color format: {inv}")
    score -= len(invalid_format) * 5
else:
    p("✅", GREEN, f"All {len(valid_colors)} colors have valid hex format")

# ── Required color keys ────────────────────────────────────────────────────────
p("🔑", BLUE, "Required color keys:")
missing_required = []
for req_key in REQUIRED_KEYS:
    if req_key in valid_colors:
        p("  ✅", GREEN, f"{req_key}: {valid_colors[req_key]}")
    else:
        missing_required.append(req_key)
        p("  ❌", RED, f"{req_key}: MISSING")
        score -= 8

if missing_required:
    errors.append(f"Missing required color keys: {', '.join(missing_required)}")
else:
    p("✅", GREEN, f"All {len(REQUIRED_KEYS)} required keys present")

# ── Extract accent color ───────────────────────────────────────────────────────
for key in ("accent", "mauve", "blue", "primary"):
    if key in valid_colors:
        accent = valid_colors[key]
        p("🎯", MAUVE, f"Accent color: {accent} ({key})")
        break

# ── Duplicate detection ────────────────────────────────────────────────────────
if CHECK_DUPES and len(valid_colors) >= 2:
    p("🔍", BLUE, "Checking for visually similar colors (ΔE < 5)...")

    def hex_to_lab(hex_color):
        """Convert hex to CIE Lab color space."""
        h = hex_color.lstrip("#")
        r, g, b = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]

        def linearize(c):
            return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

        r, g, b = linearize(r), linearize(g), linearize(b)

        # sRGB → XYZ (D65)
        X = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
        Y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
        Z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

        # Normalize
        X, Y, Z = X/0.95047, Y/1.00000, Z/1.08883

        def f(t):
            return t**(1/3) if t > 0.008856 else 7.787*t + 16/116

        fx, fy, fz = f(X), f(Y), f(Z)
        L = 116*fy - 16
        a = 500*(fx - fy)
        b_val = 200*(fy - fz)
        return L, a, b_val

    def delta_e(c1, c2):
        """CIE76 ΔE color difference."""
        try:
            L1, a1, b1 = hex_to_lab(c1)
            L2, a2, b2 = hex_to_lab(c2)
            return math.sqrt((L1-L2)**2 + (a1-a2)**2 + (b1-b2)**2)
        except Exception:
            return 100.0

    keys = list(valid_colors.keys())
    similar_pairs = []

    for i in range(len(keys)):
        for j in range(i+1, len(keys)):
            k1, k2 = keys[i], keys[j]
            de = delta_e(valid_colors[k1], valid_colors[k2])
            if de < 5.0:
                similar_pairs.append((k1, k2, round(de, 2)))

    if similar_pairs:
        for k1, k2, de in similar_pairs[:5]:
            warnings.append(
                f"Similar colors (ΔE={de}): '{k1}'={valid_colors[k1]} ≈ "
                f"'{k2}'={valid_colors[k2]}"
            )
        score -= len(similar_pairs) * 2
    else:
        p("✅", GREEN, "No visually identical colors detected")

# ── Color harmony analysis ────────────────────────────────────────────────────
if CHECK_HARMONY and valid_colors:
    p("🌈", BLUE, "Analyzing color harmony...")

    def hex_to_hsl(hex_color):
        h = hex_color.lstrip("#")
        r, g, b = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
        max_c, min_c = max(r,g,b), min(r,g,b)
        l = (max_c + min_c) / 2
        if max_c == min_c:
            return 0, 0, l
        d = max_c - min_c
        s = d / (2 - max_c - min_c) if l > 0.5 else d / (max_c + min_c)
        if max_c == r:   h_val = (g - b) / d + (6 if g < b else 0)
        elif max_c == g: h_val = (b - r) / d + 2
        else:            h_val = (r - g) / d + 4
        return h_val * 60, s * 100, l * 100

    hues = []
    for key, color in valid_colors.items():
        try:
            h_deg, s, l = hex_to_hsl(color)
            if s > 10:  # Only include saturated colors
                hues.append(h_deg)
        except Exception:
            pass

    if len(hues) >= 3:
        hue_range = max(hues) - min(hues)
        hue_std   = (sum((h - sum(hues)/len(hues))**2 for h in hues) / len(hues)) ** 0.5

        if hue_range > 30:
            harmony_type = "diverse"
            p("✅", GREEN, f"Good color diversity (hue range: {hue_range:.0f}°, std: {hue_std:.0f}°)")
            score += 3
        else:
            harmony_type = "monochromatic"
            p("ℹ️ ", BLUE, f"Monochromatic theme (hue range: {hue_range:.0f}°)")

    p("✅", GREEN, "Color harmony analysis complete")

# ── Write results ─────────────────────────────────────────────────────────────
results = {
    "color_count":   color_count,
    "valid_count":   len(valid_colors),
    "accent_color":  accent,
    "required_keys": REQUIRED_KEYS,
    "missing_keys":  missing_required,
    "score":         max(0, min(100, score)),
    "errors":        errors,
    "warnings":      warnings,
    "colors":        valid_colors,
}

Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
with open(f"{WORK_DIR}/colors-result.json", "w") as f:
    json.dump(results, f, indent=2)

# Output for bash
with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as out:
    out.write(f"color_count={color_count}\n")
    out.write(f"accent_color={accent}\n")
    out.write(f"colors_score={max(0, min(100, score))}\n")
    out.write(f"colors_errors={len(errors)}\n")
    out.write(f"colors_passed={'true' if not errors and color_count >= MIN_COLORS else 'false'}\n")

print(f"\n  {MAUVE}📊 Color validation score: {max(0, min(100, score))}/100{RST}")
PYTHON_EOF

  # Load results back to bash
  if [[ -f "${WORK_DIR}/colors-result.json" ]]; then
    COLOR_COUNT=$(jq '.color_count' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo 0)
    ACCENT_COLOR=$(jq -r '.accent_color' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo "#888888")
    SCORE_COLORS=$(jq '.score' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo 0)

    local color_errors
    color_errors=$(jq -r '.errors[]' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo "")
    local color_warnings
    color_warnings=$(jq -r '.warnings[]' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo "")

    while IFS= read -r err; do [[ -n "${err}" ]] && ERRORS+=("${err}"); done <<< "${color_errors}"
    while IFS= read -r wrn; do [[ -n "${wrn}" ]] && WARNINGS+=("${wrn}"); done <<< "${color_warnings}"

    local c_passed; c_passed=$(jq -r 'if (.errors | length) == 0 and .color_count >= '"${MIN_COLORS}"' then "true" else "false" end' "${WORK_DIR}/colors-result.json" 2>/dev/null || echo "false")
    COLORS_PASSED="${c_passed}"
  fi

  log_score "Colors score: ${SCORE_COLORS}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 3 — WCAG Accessibility
# ─────────────────────────────────────────────────────────────────────────────
check_wcag() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 3: WCAG Accessibility (${WCAG_LEVEL}) ━━━━━━━━━━━━━━━━━━${C_R}"

  local COLORS_FILE="${THEME_DIR}/colors.json"
  [[ ! -f "${COLORS_FILE}" ]] && {
    add_error "Cannot run WCAG check — colors.json missing"
    SCORE_WCAG=0
    return
  }

  python3 << 'WCAG_EOF'
import json
import math
import os
import sys
from pathlib import Path

THEME_DIR   = os.environ["THEME_DIR"]
WORK_DIR    = os.environ["WORK_DIR"]
WCAG_LEVEL  = os.environ["WCAG_LEVEL"]
FAIL_WCAG   = os.environ["FAIL_ON_WCAG"] == "true"

# ANSI colors
GREEN  = "\033[38;2;166;227;161m"
RED    = "\033[38;2;243;139;168m"
YELLOW = "\033[38;2;249;226;175m"
BLUE   = "\033[38;2;137;180;250m"
MAUVE  = "\033[38;2;203;166;247m"
TEXT   = "\033[38;2;205;214;244m"
SUB    = "\033[38;2;166;173;200m"
TEAL   = "\033[38;2;148;226;213m"
RST    = "\033[0m"

# WCAG contrast thresholds
THRESHOLDS = {
    "A":   {"normal": 3.0,  "large": 1.5},
    "AA":  {"normal": 4.5,  "large": 3.0},
    "AAA": {"normal": 7.0,  "large": 4.5},
}
THRESHOLD = THRESHOLDS.get(WCAG_LEVEL, THRESHOLDS["AA"])

def hex_to_linear(hex_color):
    h = hex_color.lstrip("#")
    rgb = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return [c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4 for c in rgb]

def relative_luminance(hex_color):
    r, g, b = hex_to_linear(hex_color)
    return 0.2126*r + 0.7152*g + 0.0722*b

def contrast_ratio(c1, c2):
    l1, l2 = relative_luminance(c1), relative_luminance(c2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def wcag_grade(ratio):
    if ratio >= 7.0:  return "AAA", GREEN
    if ratio >= 4.5:  return "AA",  TEAL
    if ratio >= 3.0:  return "A",   YELLOW
    return "Fail", RED

# Load colors
try:
    with open(f"{THEME_DIR}/colors.json") as f:
        data = json.load(f)
    colors = data.get("colors", data) if isinstance(data, dict) else {}
except Exception as e:
    print(f"  {RED}❌ Cannot load colors: {e}{RST}")
    sys.exit(0)

# Extract valid hex colors
valid_colors = {}
import re
HEX = re.compile(r'^#[0-9A-Fa-f]{6}$')
for k, v in colors.items():
    if isinstance(v, str) and HEX.match(v.strip()):
        valid_colors[k] = v.strip()

if len(valid_colors) < 2:
    print(f"  {YELLOW}⚠️  Not enough valid colors for WCAG check{RST}")
    sys.exit(0)

# ── Define critical color pairs (foreground × background) ─────────────────────
CRITICAL_PAIRS = [
    # (foreground_key, background_key, description)
    ("text",     "base",     "Main text on background"),
    ("text",     "mantle",   "Text on mantle"),
    ("text",     "surface0", "Text on surface"),
    ("subtext0", "base",     "Subtext on background"),
    ("overlay0", "surface0", "Overlay on surface"),
    ("blue",     "base",     "Accent blue on background"),
    ("green",    "base",     "Green on background"),
    ("red",      "base",     "Red on background"),
    ("yellow",   "base",     "Yellow on background"),
    ("mauve",    "base",     "Mauve/accent on background"),
    ("accent",   "base",     "Accent on background"),
    ("text",     "crust",    "Text on crust"),
]

results       = []
all_passed    = True
min_ratio     = 999.0
pair_count    = 0
failures      = []
warnings_list = []

print(f"  {BLUE}♿ WCAG Level: {WCAG_LEVEL} (normal text ≥ {THRESHOLD['normal']}:1){RST}")
print(f"  {SUB}Checking {len(CRITICAL_PAIRS)} critical color pairs...{RST}")
print()

for fg_key, bg_key, desc in CRITICAL_PAIRS:
    fg = valid_colors.get(fg_key)
    bg = valid_colors.get(bg_key)
    if not fg or not bg:
        continue

    pair_count += 1
    ratio = contrast_ratio(fg, bg)
    grade, grade_color = wcag_grade(ratio)
    required = THRESHOLD["normal"]
    passed   = ratio >= required
    min_ratio= min(min_ratio, ratio)

    if not passed:
        all_passed = False
        failures.append(f"{fg_key}({fg}) on {bg_key}({bg}): {ratio:.2f}:1 < {required:.1f}:1")

    # Display
    ratio_bar_len = min(20, int(ratio / 21 * 20))
    ratio_bar = "█" * ratio_bar_len + "░" * (20 - ratio_bar_len)
    status_icon = "✅" if passed else "❌"

    print(
        f"  {status_icon} {TEXT}{desc[:35]:<35}{RST}  "
        f"[{grade_color}{ratio_bar}{RST}]  "
        f"{grade_color}{ratio:.2f}:1{RST}  "
        f"{grade_color}[{grade}]{RST}"
    )

    results.append({
        "fg_key": fg_key, "bg_key": bg_key,
        "fg": fg, "bg": bg,
        "ratio": round(ratio, 3),
        "grade": grade, "passed": passed,
        "description": desc,
    })

# ── Overall WCAG result ───────────────────────────────────────────────────────
if min_ratio == 999.0:
    min_ratio = 0.0
    all_passed = False

pass_count   = sum(1 for r in results if r["passed"])
wcag_score   = round(pass_count / max(pair_count, 1) * 100)
wcag_passed  = all_passed

print()
if wcag_passed:
    print(f"  {GREEN}✅ WCAG {WCAG_LEVEL} PASSED — All {pair_count} pairs comply{RST}")
else:
    fail_count = pair_count - pass_count
    print(f"  {RED}❌ WCAG {WCAG_LEVEL} FAILED — {fail_count}/{pair_count} pairs below threshold{RST}")
    for f in failures[:5]:
        print(f"     {RED}• {f}{RST}")

# ── Write results ─────────────────────────────────────────────────────────────
wcag_result = {
    "level":       WCAG_LEVEL,
    "passed":      wcag_passed,
    "score":       wcag_score,
    "pairs_checked": pair_count,
    "pairs_passed":  pass_count,
    "min_ratio":   round(min_ratio, 3),
    "threshold":   THRESHOLD["normal"],
    "failures":    failures,
    "results":     results,
}

Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
with open(f"{WORK_DIR}/wcag-result.json", "w") as f:
    json.dump(wcag_result, f, indent=2)

with open(os.environ.get("GITHUB_OUTPUT", "/dev/null"), "a") as out:
    out.write(f"wcag_passed={'true' if wcag_passed else 'false'}\n")
    out.write(f"wcag_min_ratio={round(min_ratio, 2)}\n")
    out.write(f"wcag_pairs_checked={pair_count}\n")
    out.write(f"wcag_score={wcag_score}\n")

print(f"\n  {MAUVE}📊 WCAG score: {wcag_score}/100 (min ratio: {min_ratio:.2f}:1){RST}")
WCAG_EOF

  # Load WCAG results
  if [[ -f "${WORK_DIR}/wcag-result.json" ]]; then
    WCAG_PASSED=$(jq -r '.passed' "${WORK_DIR}/wcag-result.json" 2>/dev/null || echo "false")
    WCAG_MIN_RATIO=$(jq -r '.min_ratio' "${WORK_DIR}/wcag-result.json" 2>/dev/null || echo "0")
    WCAG_PAIRS=$(jq -r '.pairs_checked' "${WORK_DIR}/wcag-result.json" 2>/dev/null || echo "0")
    SCORE_WCAG=$(jq -r '.score' "${WORK_DIR}/wcag-result.json" 2>/dev/null || echo "0")

    while IFS= read -r f; do
      [[ -n "${f}" ]] && ERRORS+=("WCAG: ${f}")
    done < <(jq -r '.failures[]' "${WORK_DIR}/wcag-result.json" 2>/dev/null || true)
  fi

  log_score "WCAG score: ${SCORE_WCAG}/100 (min contrast: ${WCAG_MIN_RATIO}:1)"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 4 — Metadata Validation
# ─────────────────────────────────────────────────────────────────────────────
check_metadata() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 4: Metadata Validation ━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  local META_FILE="${THEME_DIR}/metadata.json"
  local score=100
  local meta_passed=true

  if [[ ! -f "${META_FILE}" ]]; then
    add_error "metadata.json not found"
    SCORE_METADATA=0
    META_PASSED="false"
    return
  fi

  # Validate JSON syntax
  if ! jq empty "${META_FILE}" 2>/dev/null; then
    add_error "metadata.json contains invalid JSON"
    SCORE_METADATA=0
    META_PASSED="false"
    return
  fi

  # Check required fields
  IFS=',' read -ra META_FIELDS <<< "${REQUIRED_META}"
  for field in "${META_FIELDS[@]}"; do
    field=$(echo "${field}" | tr -d ' ')
    local val
    val=$(jq -r ".${field} // empty" "${META_FILE}" 2>/dev/null || echo "")

    if [[ -z "${val}" || "${val}" == "null" ]]; then
      add_error "metadata.json missing required field: ${field}"
      score=$((score - 15))
      meta_passed=false
    else
      add_pass "metadata.${field}: ${val:0:50}"
      # Version format check
      if [[ "${field}" == "version" ]]; then
        if ! echo "${val}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
          add_warning "metadata.version not semver format: ${val}"
          score=$((score - 5))
        fi
        THEME_VERSION="${val}"
      fi
    fi
  done

  # Check optional but valuable fields
  local OPTIONAL_META=("tags" "license" "homepage" "preview" "wallpaper")
  for field in "${OPTIONAL_META[@]}"; do
    local val; val=$(jq -r ".${field} // empty" "${META_FILE}" 2>/dev/null || echo "")
    if [[ -n "${val}" && "${val}" != "null" ]]; then
      log_debug "metadata.${field}: ${val:0:40}"
      score=$((score + 2))
    fi
  done

  # Validate tags array
  local tags_count
  tags_count=$(jq '.tags | if type == "array" then length else 0 end' "${META_FILE}" 2>/dev/null || echo 0)
  if [[ "${tags_count}" -gt 0 ]]; then
    add_pass "metadata.tags: ${tags_count} tag(s)"
  else
    add_warning "metadata.tags: empty or missing (recommended)"
  fi

  SCORE_METADATA=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  META_PASSED="${meta_passed}"

  log_score "Metadata score: ${SCORE_METADATA}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 5 — Naming Convention
# ─────────────────────────────────────────────────────────────────────────────
check_naming() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 5: Naming Convention ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  [[ "${ENFORCE_NAMING}" != "true" ]] && {
    log_info "Naming convention check disabled"
    SCORE_NAMING=80
    NAMING_PASSED="true"
    return
  }

  local score=100
  local naming_passed=true
  local dir_name; dir_name=$(basename "${THEME_DIR}")

  # Check directory name: must be kebab-case
  if echo "${dir_name}" | grep -qE '^[a-z][a-z0-9-]+$'; then
    add_pass "Directory name: '${dir_name}' (valid kebab-case)"
  elif echo "${dir_name}" | grep -q ' '; then
    add_error "Directory name contains spaces: '${dir_name}' (use kebab-case)"
    score=$((score - 30))
    naming_passed=false
  elif echo "${dir_name}" | grep -qE '[A-Z]'; then
    add_warning "Directory name uses uppercase: '${dir_name}' (use lowercase)"
    score=$((score - 15))
  elif echo "${dir_name}" | grep -qE '[_]'; then
    add_warning "Directory name uses underscores: '${dir_name}' (use hyphens)"
    score=$((score - 10))
  fi

  # Check theme name matches directory
  local conf_name
  conf_name=$(grep -E "^name\s*=" "${THEME_DIR}/theme.conf" 2>/dev/null | \
    head -1 | cut -d= -f2 | tr -d ' "'"'" || echo "")

  if [[ -n "${conf_name}" ]]; then
    if [[ "${conf_name}" == "${dir_name}" ]]; then
      add_pass "Theme name matches directory: '${conf_name}'"
    else
      add_warning "Theme name '${conf_name}' doesn't match directory '${dir_name}'"
      score=$((score - 10))
    fi
  fi

  # Check color key naming
  if [[ -f "${THEME_DIR}/colors.json" ]]; then
    local bad_keys
    bad_keys=$(jq -r '
      (if .colors then .colors else . end) |
      keys[] |
      select(test("[A-Z ]|^[^a-z]"))
    ' "${THEME_DIR}/colors.json" 2>/dev/null | head -5 || echo "")

    if [[ -n "${bad_keys}" ]]; then
      while IFS= read -r key; do
        [[ -n "${key}" ]] && {
          add_warning "Color key not lowercase: '${key}'"
          score=$((score - 3))
        }
      done <<< "${bad_keys}"
    else
      add_pass "All color keys use lowercase naming"
    fi
  fi

  # Theme name length check
  if [[ "${#THEME_NAME}" -gt 50 ]]; then
    add_warning "Theme name too long: ${#THEME_NAME} chars (max 50)"
    score=$((score - 5))
  fi

  SCORE_NAMING=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  NAMING_PASSED="${naming_passed}"

  log_score "Naming score: ${SCORE_NAMING}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 6 — Security Scan
# ─────────────────────────────────────────────────────────────────────────────
check_security() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 6: Security Scan ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  [[ "${SECURITY_SCAN}" != "true" ]] && {
    log_info "Security scan disabled"
    SCORE_SECURITY=100
    SECURITY_PASSED="true"
    return
  }

  local score=100
  local security_passed=true

  # Dangerous patterns to detect
  declare -A DANGER_PATTERNS=(
    ["shell_exec"]='`\|$(|eval\|exec\|system('
    ["script_tags"]='<script\|javascript:'
    ["file_include"]='file://\|php://\|data:'
    ["path_traversal"]='\.\./\.\.'
    ["base64_exec"]='base64.*eval\|eval.*base64'
    ["curl_exec"]='curl.*|\|wget.*|'
    ["sql_injection"]="'\s*OR\s*'1'\s*=\s*'1"
    ["command_inject"]=';\s*rm\s\|-rf\|sudo\s'
  )

  local found_threats=0

  echo "  🔒 Scanning theme files for security threats..."

  for json_file in "${THEME_DIR}"/*.json "${THEME_DIR}"/*.conf; do
    [[ -f "${json_file}" ]] || continue
    local fname; fname=$(basename "${json_file}")

    for threat_name in "${!DANGER_PATTERNS[@]}"; do
      local pattern="${DANGER_PATTERNS[$threat_name]}"
      if grep -qiE "${pattern}" "${json_file}" 2>/dev/null; then
        add_error "Security threat '${threat_name}' in ${fname}"
        score=$((score - 30))
        security_passed=false
        ((found_threats++))
      fi
    done
  done

  # Check for embedded executable content
  local BIN_EXTS=("exe" "sh" "bash" "py" "rb" "js" "php")
  for ext in "${BIN_EXTS[@]}"; do
    local found_files
    found_files=$(find "${THEME_DIR}" -name "*.${ext}" -not -name "*.conf" 2>/dev/null | head -3)
    if [[ -n "${found_files}" ]]; then
      add_warning "Executable files found: ${found_files}"
      score=$((score - 10))
    fi
  done

  # Check file permissions
  local world_writable
  world_writable=$(find "${THEME_DIR}" -perm -o+w -type f 2>/dev/null | head -5)
  if [[ -n "${world_writable}" ]]; then
    add_warning "World-writable files detected"
    score=$((score - 5))
  fi

  # SUID/SGID check
  local suid_files
  suid_files=$(find "${THEME_DIR}" \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | head -3)
  if [[ -n "${suid_files}" ]]; then
    add_error "SUID/SGID bits set on theme files"
    score=$((score - 50))
    security_passed=false
  fi

  if [[ "${found_threats}" -eq 0 ]]; then
    add_pass "No security threats detected"
  fi

  SCORE_SECURITY=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  SECURITY_PASSED="${security_passed}"

  log_score "Security score: ${SCORE_SECURITY}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 7 — Performance / Size
# ─────────────────────────────────────────────────────────────────────────────
check_performance() {
  [[ "${VALIDATION_LEVEL}" == "quick" ]] && return

  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Check 7: Performance & Size ━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  local score=100

  # Total directory size
  local total_size_kb
  total_size_kb=$(du -sk "${THEME_DIR}" 2>/dev/null | cut -f1 || echo 0)

  if [[ "${total_size_kb}" -gt "${MAX_SIZE_KB}" ]]; then
    add_warning "Theme directory too large: ${total_size_kb}KB (max ${MAX_SIZE_KB}KB)"
    score=$((score - 20))
  else
    add_pass "Directory size: ${total_size_kb}KB (≤ ${MAX_SIZE_KB}KB)"
  fi

  # Check individual file sizes
  for file in "${THEME_DIR}"/*.jpg "${THEME_DIR}"/*.png "${THEME_DIR}"/*.webp; do
    [[ -f "${file}" ]] || continue
    local fname; fname=$(basename "${file}")
    local file_size_mb
    file_size_mb=$(du -m "${file}" 2>/dev/null | cut -f1 || echo 0)

    if [[ "${file_size_mb}" -gt "${MAX_WP_SIZE_MB}" ]]; then
      add_warning "Large wallpaper: ${fname} (${file_size_mb}MB > ${MAX_WP_SIZE_MB}MB)"
      score=$((score - 10))
    fi
  done

  # JSON file sizes (should be small)
  for json_file in "${THEME_DIR}"/*.json; do
    [[ -f "${json_file}" ]] || continue
    local json_size_kb; json_size_kb=$(wc -c < "${json_file}" | awk '{printf "%.0f", $1/1024}')
    if [[ "${json_size_kb}" -gt 100 ]]; then
      add_warning "Large JSON file: $(basename "${json_file}") (${json_size_kb}KB)"
      score=$((score - 5))
    fi
  done

  # Preview image validation
  if [[ "${VALIDATE_PREVIEW}" == "true" ]]; then
    for preview_file in "${THEME_DIR}"/preview.webp "${THEME_DIR}"/preview.jpg "${THEME_DIR}"/preview.png; do
      [[ -f "${preview_file}" ]] || continue

      if command -v identify &>/dev/null; then
        local dims; dims=$(identify -format "%wx%h" "${preview_file}" 2>/dev/null || echo "0x0")
        local pw; pw=$(echo "${dims}" | cut -dx -f1)
        local ph; ph=$(echo "${dims}" | cut -dx -f2)

        if [[ "${pw}" -ge "${MIN_PREVIEW_W}" && "${ph}" -ge "${MIN_PREVIEW_H}" ]]; then
          add_pass "Preview image: ${dims} (≥ ${MIN_PREVIEW_W}x${MIN_PREVIEW_H})"
        else
          add_warning "Preview too small: ${dims} (min ${MIN_PREVIEW_W}x${MIN_PREVIEW_H})"
          score=$((score - 15))
        fi
      fi
    done
  fi

  SCORE_PERFORMANCE=$(( score < 0 ? 0 : score > 100 ? 100 : score ))
  log_score "Performance score: ${SCORE_PERFORMANCE}/100"
}

# ─────────────────────────────────────────────────────────────────────────────
# SCORING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
calculate_final_score() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Final Score Calculation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  # Default weights (sum = 100)
  local W_STRUCTURE=20
  local W_COLORS=25
  local W_WCAG=25
  local W_METADATA=15
  local W_NAMING=5
  local W_SECURITY=5
  local W_PERFORMANCE=5

  # Schema adds to colors weight when available
  if [[ "${SCHEMA_PASSED}" == "true" ]]; then
    SCORE_SCHEMA=100
  else
    SCORE_SCHEMA=50
  fi

  # Apply schema adjustment to colors weight
  local EFFECTIVE_COLORS=$(( (SCORE_COLORS * 7 + SCORE_SCHEMA * 3) / 10 ))

  # Weighted sum
  local WEIGHTED_SUM=$(echo "scale=2; \
    (${SCORE_STRUCTURE} * ${W_STRUCTURE} + \
     ${EFFECTIVE_COLORS} * ${W_COLORS} + \
     ${SCORE_WCAG} * ${W_WCAG} + \
     ${SCORE_METADATA} * ${W_METADATA} + \
     ${SCORE_NAMING} * ${W_NAMING} + \
     ${SCORE_SECURITY} * ${W_SECURITY} + \
     ${SCORE_PERFORMANCE} * ${W_PERFORMANCE}) / 100" | bc 2>/dev/null || echo "0")

  local FINAL_SCORE; FINAL_SCORE=$(printf "%.0f" "${WEIGHTED_SUM}" 2>/dev/null || echo "0")
  FINAL_SCORE=$(( FINAL_SCORE < 0 ? 0 : FINAL_SCORE > 100 ? 100 : FINAL_SCORE ))

  # Letter grade
  local GRADE
  if   [[ "${FINAL_SCORE}" -ge 95 ]]; then GRADE="A+"
  elif [[ "${FINAL_SCORE}" -ge 90 ]]; then GRADE="A"
  elif [[ "${FINAL_SCORE}" -ge 80 ]]; then GRADE="B"
  elif [[ "${FINAL_SCORE}" -ge 70 ]]; then GRADE="C"
  elif [[ "${FINAL_SCORE}" -ge 60 ]]; then GRADE="D"
  else GRADE="F"
  fi

  # Overall pass/fail
  local VALIDATION_PASSED="true"
  [[ "${FINAL_SCORE}" -lt "${MINIMUM_SCORE}" ]] && VALIDATION_PASSED="false"
  [[ "${FAIL_ON_WCAG}" == "true" && "${WCAG_PASSED}" != "true" ]] && VALIDATION_PASSED="false"
  [[ "${#ERRORS[@]}" -gt 0 ]] && VALIDATION_PASSED="false"

  # Score bar (40 wide)
  local BAR_FILLED=$(( FINAL_SCORE * 40 / 100 ))
  local BAR_EMPTY=$(( 40 - BAR_FILLED ))
  local SCORE_BAR
  SCORE_BAR="$(printf '█%.0s' $(seq 1 "${BAR_FILLED}" 2>/dev/null || true))"
  SCORE_BAR+="$(printf '░%.0s' $(seq 1 "${BAR_EMPTY}" 2>/dev/null || true))"

  local GRADE_COLOR="${C_GREEN}"
  [[ "${GRADE}" == "B" ]] && GRADE_COLOR="${C_TEAL}"
  [[ "${GRADE}" == "C" ]] && GRADE_COLOR="${C_YELLOW}"
  [[ "${GRADE}" == "D" || "${GRADE}" == "F" ]] && GRADE_COLOR="${C_RED}"

  echo ""
  echo -e "  ${C_MAUVE}${C_B}╔══════════════════════════════════════════════════════════════╗${C_R}"
  echo -e "  ${C_MAUVE}${C_B}║  📊 VALIDATION SCORE                                         ║${C_R}"
  echo -e "  ${C_MAUVE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  ${GRADE_COLOR}${C_B}[%s]${C_R} ${GRADE_COLOR}${C_B}%d/100${C_R} — Grade: ${GRADE_COLOR}${C_B}%s${C_R}%*s${C_MAUVE}${C_B}║${C_R}\n" \
    "${SCORE_BAR}" "${FINAL_SCORE}" "${GRADE}" $((9 - ${#GRADE})) ""
  echo -e "  ${C_MAUVE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  📁 Structure:   [%3d/100]  🎨 Colors:  [%3d/100]          ${C_MAUVE}${C_B}║${C_R}\n" \
    "${SCORE_STRUCTURE}" "${SCORE_COLORS}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  ♿ WCAG:        [%3d/100]  📋 Metadata: [%3d/100]         ${C_MAUVE}${C_B}║${C_R}\n" \
    "${SCORE_WCAG}" "${SCORE_METADATA}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  🔤 Naming:      [%3d/100]  🔒 Security: [%3d/100]         ${C_MAUVE}${C_B}║${C_R}\n" \
    "${SCORE_NAMING}" "${SCORE_SECURITY}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  ⚡ Performance: [%3d/100]  📐 Schema:   [%3d/100]         ${C_MAUVE}${C_B}║${C_R}\n" \
    "${SCORE_PERFORMANCE}" "${SCORE_SCHEMA}"
  echo -e "  ${C_MAUVE}${C_B}╠══════════════════════════════════════════════════════════════╣${C_R}"
  printf  "  ${C_MAUVE}${C_B}║${C_R}  ❌ Errors: %-5d  ⚠️  Warnings: %-5d  🎯 Min: %-3d/100       ${C_MAUVE}${C_B}║${C_R}\n" \
    "${#ERRORS[@]}" "${#WARNINGS[@]}" "${MINIMUM_SCORE}"
  echo -e "  ${C_MAUVE}${C_B}╚══════════════════════════════════════════════════════════════╝${C_R}"

  # Emit GitHub outputs
  {
    echo "validation_passed=${VALIDATION_PASSED}"
    echo "score=${FINAL_SCORE}"
    echo "grade=${GRADE}"
    echo "theme_name=${THEME_NAME}"
    echo "category=${THEME_CATEGORY}"
    echo "version=${THEME_VERSION}"
    echo "color_count=${COLOR_COUNT}"
    echo "accent_color=${ACCENT_COLOR}"
    echo "structure_passed=${STRUCT_PASSED}"
    echo "colors_passed=${COLORS_PASSED}"
    echo "wcag_passed=${WCAG_PASSED}"
    echo "wcag_min_ratio=${WCAG_MIN_RATIO}"
    echo "wcag_pairs_checked=${WCAG_PAIRS}"
    echo "metadata_passed=${META_PASSED}"
    echo "schema_passed=${SCHEMA_RESULT}"
    echo "naming_passed=${NAMING_PASSED}"
    echo "security_passed=${SECURITY_PASSED}"
    echo "error_count=${#ERRORS[@]}"
    echo "warning_count=${#WARNINGS[@]}"
    echo "errors_json=$(printf '%s\n' "${ERRORS[@]:-}" | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
    echo "warnings_json=$(printf '%s\n' "${WARNINGS[@]:-}" | jq -R . | jq -s -c . 2>/dev/null || echo '[]')"
  } >> "${GITHUB_OUTPUT:-/dev/null}"

  # Save errors/warnings for PR comment
  printf '%s\n' "${ERRORS[@]:-}"   | jq -R . | jq -s . > "${WORK_DIR}/errors.json"   2>/dev/null || echo '[]' > "${WORK_DIR}/errors.json"
  printf '%s\n' "${WARNINGS[@]:-}" | jq -R . | jq -s . > "${WORK_DIR}/warnings.json" 2>/dev/null || echo '[]' > "${WORK_DIR}/warnings.json"

  echo "${FINAL_SCORE}" > "${WORK_DIR}/final-score.txt"
  echo "${GRADE}"       > "${WORK_DIR}/grade.txt"
  echo "${VALIDATION_PASSED}" > "${WORK_DIR}/passed.txt"
}

# ─────────────────────────────────────────────────────────────────────────────
# REPORT GENERATION
# ─────────────────────────────────────────────────────────────────────────────
generate_report() {
  echo -e "\n  ${C_SAPPHIRE}${C_B}━━━ Generating Validation Report ━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_R}"

  local FINAL_SCORE; FINAL_SCORE=$(cat "${WORK_DIR}/final-score.txt" 2>/dev/null || echo "0")
  local GRADE; GRADE=$(cat "${WORK_DIR}/grade.txt" 2>/dev/null || echo "F")
  local PASSED; PASSED=$(cat "${WORK_DIR}/passed.txt" 2>/dev/null || echo "false")
  local NOW; NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

  local SCORE_BAR_FILLED=$(( FINAL_SCORE * 30 / 100 ))
  local SCORE_BAR_EMPTY=$(( 30 - SCORE_BAR_FILLED ))
  local SCORE_BAR
  SCORE_BAR="$(printf '█%.0s' $(seq 1 "${SCORE_BAR_FILLED}" 2>/dev/null || true))"
  SCORE_BAR+="$(printf '░%.0s' $(seq 1 "${SCORE_BAR_EMPTY}" 2>/dev/null || true))"

  local REPORT_MD="${WORK_DIR}/validation-report.md"

  cat > "${REPORT_MD}" << REPORT_EOF
# 🎨 ASH Theme Validation Report

> **Theme:** \`${THEME_NAME}\` &nbsp;·&nbsp; **Category:** \`${THEME_CATEGORY}\` &nbsp;·&nbsp; **Version:** \`${THEME_VERSION}\`
> Generated: \`${NOW}\` &nbsp;·&nbsp; Engine: ASH v${VALIDATOR_VERSION} &nbsp;·&nbsp; Level: \`${VALIDATION_LEVEL}\` &nbsp;·&nbsp; WCAG: \`${WCAG_LEVEL}\`

## 📊 Overall Score

\`\`\`
Score: [${SCORE_BAR}] ${FINAL_SCORE}/100   Grade: ${GRADE}
Status: $([[ "${PASSED}" == "true" ]] && echo "✅ PASSED" || echo "❌ FAILED")   Errors: ${#ERRORS[@]}   Warnings: ${#WARNINGS[@]}
\`\`\`

## 🔍 Check Results

| Check | Score | Status | Details |
|-------|------:|:------:|---------|
| 📁 File Structure | \`${SCORE_STRUCTURE}/100\` | $([[ "${STRUCT_PASSED}" == "true" ]] && echo "✅" || echo "❌") | Required files present |
| 🎨 Color Validation | \`${SCORE_COLORS}/100\` | $([[ "${COLORS_PASSED}" == "true" ]] && echo "✅" || echo "❌") | \`${COLOR_COUNT}\` colors · accent \`${ACCENT_COLOR}\` |
| ♿ WCAG ${WCAG_LEVEL} | \`${SCORE_WCAG}/100\` | $([[ "${WCAG_PASSED}" == "true" ]] && echo "✅" || echo "❌") | Min ratio: \`${WCAG_MIN_RATIO}:1\` · \`${WCAG_PAIRS}\` pairs |
| 📋 Metadata | \`${SCORE_METADATA}/100\` | $([[ "${META_PASSED}" == "true" ]] && echo "✅" || echo "❌") | Required fields |
| 📐 Schema | \`${SCORE_SCHEMA}/100\` | $([[ "${SCHEMA_RESULT}" == "true" ]] && echo "✅" || echo "❌") | JSON conformance |
| 🔤 Naming | \`${SCORE_NAMING}/100\` | $([[ "${NAMING_PASSED}" == "true" ]] && echo "✅" || echo "❌") | kebab-case convention |
| 🔒 Security | \`${SCORE_SECURITY}/100\` | $([[ "${SECURITY_PASSED}" == "true" ]] && echo "✅" || echo "❌") | No embedded threats |
| ⚡ Performance | \`${SCORE_PERFORMANCE}/100\` | ✅ | File sizes within limits |

REPORT_EOF

  if [[ "${#ERRORS[@]}" -gt 0 ]]; then
    echo "## ❌ Errors (${#ERRORS[@]})" >> "${REPORT_MD}"
    echo "" >> "${REPORT_MD}"
    for err in "${ERRORS[@]}"; do
      echo "- ❌ ${err}" >> "${REPORT_MD}"
    done
    echo "" >> "${REPORT_MD}"
  fi

  if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
    echo "## ⚠️ Warnings (${#WARNINGS[@]})" >> "${REPORT_MD}"
    echo "" >> "${REPORT_MD}"
    for warn in "${WARNINGS[@]}"; do
      echo "- ⚠️ ${warn}" >> "${REPORT_MD}"
    done
    echo "" >> "${REPORT_MD}"
  fi

  cat >> "${REPORT_MD}" << REPORT_FOOTER

## 🎨 Theme Details

| Property | Value |
|----------|-------|
| 🏷️ Name | \`${THEME_NAME}\` |
| 📁 Category | \`${THEME_CATEGORY}\` |
| 🔖 Version | \`${THEME_VERSION}\` |
| 🎯 Accent | \`${ACCENT_COLOR}\` |
| 🎨 Colors | \`${COLOR_COUNT}\` |
| ♿ Min Contrast | \`${WCAG_MIN_RATIO}:1\` |

---
*🎨 ASH Dotfiles v5.0 OMEGA Theme Validation Engine · [github.com/ash/dotfiles](https://github.com/ash/dotfiles)*
REPORT_FOOTER

  echo "report_path=${REPORT_MD}" >> "${GITHUB_OUTPUT:-/dev/null}"
  log_pass "Report: ${REPORT_MD}"

  # JSON report
  if [[ "${REPORT_FORMAT}" == "json" || "${REPORT_FORMAT}" == "all" ]]; then
    local REPORT_JSON="${WORK_DIR}/validation-report.json"
    cat > "${REPORT_JSON}" << JSON_EOF
{
  "theme_name":   "${THEME_NAME}",
  "category":     "${THEME_CATEGORY}",
  "version":      "${THEME_VERSION}",
  "score":        ${FINAL_SCORE},
  "grade":        "${GRADE}",
  "passed":       ${PASSED},
  "timestamp":    "${NOW}",
  "engine":       "${VALIDATOR_VERSION}",
  "level":        "${VALIDATION_LEVEL}",
  "wcag_level":   "${WCAG_LEVEL}",
  "scores": {
    "structure":  ${SCORE_STRUCTURE},
    "colors":     ${SCORE_COLORS},
    "wcag":       ${SCORE_WCAG},
    "metadata":   ${SCORE_METADATA},
    "naming":     ${SCORE_NAMING},
    "security":   ${SCORE_SECURITY},
    "performance":${SCORE_PERFORMANCE},
    "schema":     ${SCORE_SCHEMA}
  },
  "results": {
    "structure_passed":  ${STRUCT_PASSED},
    "colors_passed":     ${COLORS_PASSED},
    "wcag_passed":       ${WCAG_PASSED},
    "metadata_passed":   ${META_PASSED},
    "schema_passed":     ${SCHEMA_RESULT},
    "naming_passed":     ${NAMING_PASSED},
    "security_passed":   ${SECURITY_PASSED}
  },
  "color_count":  ${COLOR_COUNT},
  "accent_color": "${ACCENT_COLOR}",
  "wcag_min_ratio": ${WCAG_MIN_RATIO},
  "wcag_pairs":   ${WCAG_PAIRS},
  "error_count":  ${#ERRORS[@]},
  "warning_count":${#WARNINGS[@]}
}
JSON_EOF
    log_pass "JSON report: ${REPORT_JSON}"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # Ensure work directory
  mkdir -p "${WORK_DIR}"

  # ── Run validation pipeline ───────────────────────────────────────────────
  check_structure
  check_colors
  check_wcag
  check_metadata
  check_naming
  check_security
  check_performance

  # ── Calculate score ───────────────────────────────────────────────────────
  calculate_final_score

  # ── Generate report ───────────────────────────────────────────────────────
  generate_report

  # ── Timing ───────────────────────────────────────────────────────────────
  local END_TIME; END_TIME=$(date +%s%N)
  local DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
  log_info "Total validation time: ${DURATION_MS}ms"
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo ""
  echo "❌ Validation script failed (exit=${EXIT_CODE})"
  tail -10 "${LOG_FILE}" 2>/dev/null || true
fi' EXIT

main "$@"