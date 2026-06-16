#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 ASH DOTFILES v5.0 OMEGA — THEME VALIDATOR                              ║
# ║  Comprehensive theme validation engine with WCAG, color theory & schema    ║
# ║  Called by pre-commit & pre-push hooks for every staged/pushed theme file  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI MASTER PALETTE ───────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m"      readonly B="${ESC}[1m"
readonly D="${ESC}[2m"      readonly I="${ESC}[3m"
readonly U="${ESC}[4m"

readonly BLACK="${ESC}[30m"     readonly RED="${ESC}[31m"
readonly GREEN="${ESC}[32m"     readonly YELLOW="${ESC}[33m"
readonly BLUE="${ESC}[34m"      readonly MAGENTA="${ESC}[35m"
readonly CYAN="${ESC}[36m"      readonly WHITE="${ESC}[37m"
readonly ORANGE="${ESC}[38;5;208m"  readonly PURPLE="${ESC}[38;5;135m"
readonly PINK="${ESC}[38;5;213m"    readonly LIME="${ESC}[38;5;154m"
readonly GOLD="${ESC}[38;5;220m"    readonly SKY="${ESC}[38;5;117m"
readonly LAVENDER="${ESC}[38;5;183m" readonly MINT="${ESC}[38;5;121m"
readonly PEACH="${ESC}[38;5;217m"   readonly ROSE="${ESC}[38;5;211m"
readonly TEAL="${ESC}[38;5;43m"     readonly CORAL="${ESC}[38;5;203m"
readonly CREAM="${ESC}[38;5;230m"   readonly SLATE="${ESC}[38;5;245m"
readonly AMBER="${ESC}[38;5;214m"   readonly EMERALD="${ESC}[38;5;120m"
readonly VIOLET="${ESC}[38;5;177m"  readonly CRIMSON="${ESC}[38;5;161m"
readonly INDIGO="${ESC}[38;5;105m"

readonly BG_MIDNIGHT="${ESC}[48;5;16m"
readonly BG_DARK="${ESC}[48;5;235m"
readonly BG_DARKER="${ESC}[48;5;232m"
readonly BG_FOREST="${ESC}[48;5;22m"
readonly BG_NAVY="${ESC}[48;5;17m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="validate-theme"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly SCHEMA_FILE="${REPO_ROOT}/themes/schema/theme-schema.json"
readonly COLORS_SCHEMA="${REPO_ROOT}/themes/schema/colors-schema.json"
readonly META_SCHEMA="${REPO_ROOT}/themes/schema/metadata-schema.json"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-theme-validate"
readonly LOG_FILE="${LOG_DIR}/validate-${TIMESTAMP}.log"

# Validation thresholds
readonly MIN_CONTRAST_AA=4.5          # WCAG AA normal text
readonly MIN_CONTRAST_AA_LARGE=3.0    # WCAG AA large text
readonly MIN_CONTRAST_AAA=7.0         # WCAG AAA normal text
readonly MAX_THEME_SIZE_KB=500        # Max theme directory size
readonly MIN_COLORS_REQUIRED=16       # Minimum color palette size
readonly MAX_COLORS_ALLOWED=256       # Maximum palette size

# Required theme fields
readonly -a REQUIRED_METADATA_FIELDS=(
    "name"
    "version"
    "author"
    "description"
    "category"
    "variant"
)

readonly -a REQUIRED_COLOR_FIELDS=(
    "background"
    "foreground"
    "cursor"
    "selection"
    "comment"
    "red"
    "orange"
    "yellow"
    "green"
    "cyan"
    "blue"
    "purple"
    "pink"
    "white"
    "black"
    "accent"
)

readonly -a OPTIONAL_COLOR_FIELDS=(
    "surface0"
    "surface1"
    "surface2"
    "overlay0"
    "overlay1"
    "overlay2"
    "subtext0"
    "subtext1"
    "base"
    "mantle"
    "crust"
    "text"
    "lavender"
    "flamingo"
    "maroon"
    "peach"
    "teal"
    "sapphire"
    "sky"
    "mauve"
)

# Valid categories
readonly -a VALID_CATEGORIES=(
    "dark" "light" "neon" "nature" "space"
    "pastel" "anime" "retro" "gradient"
    "seasonal" "mood" "gaming" "minimal" "special"
)

# Valid variants
readonly -a VALID_VARIANTS=(
    "dark" "light" "mocha" "macchiato" "frappe"
    "latte" "storm" "night" "moon" "hard" "soft"
    "medium" "wave" "dragon" "lotus" "dawn"
    "rose" "pine" "foam" "gold" "iris"
)

# ── STATE ─────────────────────────────────────────────────────────────────────
ERRORS=()
WARNINGS=()
PASSES=()
INFOS=()
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0
CHECKS_SKIPPED=0
THEME_NAME=""
THEME_DIR=""
THEME_CATEGORY=""
COLOR_COUNT=0
VALIDATION_SCORE=0
MAX_SCORE=0

# ── INIT ──────────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

# ── LOGGING ───────────────────────────────────────────────────────────────────
_log() {
    local level="$1" icon="$2" color="$3"
    local msg="${*:4}"
    local ts; ts="$(date '+%H:%M:%S.%3N')"

    printf "%s%s%s %s%s%s %s%s%s\n" \
        "${D}" "$ts" "$R" \
        "${color}${B}" "$icon" "$R" \
        "${color}" "$msg" "$R" >&2

    printf "[%s] [%-7s] %s %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$icon" "$msg" \
        >> "$LOG_FILE"
}

log_pass()    { _log "PASS"    "  ✓" "${GREEN}"    "$*"; }
log_fail()    { _log "FAIL"    "  ✗" "${RED}"      "$*"; }
log_warn()    { _log "WARN"    "  ⚠" "${YELLOW}"   "$*"; }
log_info()    { _log "INFO"    "  ℹ" "${CYAN}"     "$*"; }
log_debug()   { _log "DEBUG"   "  ·" "${D}${SLATE}" "$*"; }
log_section() { _log "SECTION" "▶"   "${GOLD}${B}" "$*"; }
log_metric()  { _log "METRIC"  "  📊" "${VIOLET}"  "$*"; }
log_color()   { _log "COLOR"   "  🎨" "${LAVENDER}" "$*"; }
log_wcag()    { _log "WCAG"    "  ♿" "${TEAL}"    "$*"; }
log_schema()  { _log "SCHEMA"  "  📋" "${INDIGO}"  "$*"; }

# ── RENDERING ─────────────────────────────────────────────────────────────────
hr() {
    local c="${1:-─}" w="${2:-$TERM_WIDTH}" col="${3:-${D}${SLATE}}"
    printf "%s%s%s\n" "$col" "$(printf '%*s' "$w" '' | tr ' ' "$c")" "$R" >&2
}

box_t()  { printf "%s%s  ╔%s╗  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_d()  { printf "%s%s  ╠%s╣  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_td() { printf "%s%s  ╟%s╢  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '─')" "$R" >&2; }
box_b()  { printf "%s%s  ╚%s╝  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_l()  {
    local content="$1"
    local clean; clean="$(echo "$content" | sed 's/\x1b\[[0-9;]*m//g')"
    local pad=$(( TERM_WIDTH - 4 - ${#clean} ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%s  ║ %s%*s║  %s\n" \
        "$BG_MIDNIGHT$GOLD" "$content" "$pad" "" "$R" >&2
}

section() {
    local icon="$1" title="$2" color="${3:-$CYAN}"
    printf "\n" >&2
    hr "─" "$TERM_WIDTH" "${D}${SLATE}"
    printf "  %s %s%s%s\n" "$icon" "${color}${B}" "$title" "$R" >&2
    hr "─" "$TERM_WIDTH" "${D}${SLATE}"
}

# ── CHECK ENGINE ──────────────────────────────────────────────────────────────
check() {
    local id="$1"
    local name="$2"
    local icon="$3"
    local result="$4"   # pass|fail|warn|skip
    local detail="${5:-}"
    local points="${6:-1}"

    ((CHECKS_TOTAL++))   || true
    ((MAX_SCORE += points)) || true

    local color label
    case "$result" in
        pass)
            ((CHECKS_PASSED++))    || true
            ((VALIDATION_SCORE += points)) || true
            color="${GREEN}${B}";  label="✓ PASS"
            PASSES+=("${name}: ${detail}")
            ;;
        fail)
            ((CHECKS_FAILED++))    || true
            color="${RED}${B}";    label="✗ FAIL"
            ERRORS+=("${name}: ${detail}")
            ;;
        warn)
            ((CHECKS_WARNED++))    || true
            ((VALIDATION_SCORE += points / 2)) || true
            color="${YELLOW}${B}"; label="⚠ WARN"
            WARNINGS+=("${name}: ${detail}")
            ;;
        skip)
            ((CHECKS_SKIPPED++))   || true
            color="${SLATE}${D}";  label="↷ SKIP"
            ;;
    esac

    local name_len=50
    local detail_max=$(( TERM_WIDTH - name_len - 20 ))
    local detail_short="${detail:0:$detail_max}"
    [[ ${#detail} -gt $detail_max ]] && detail_short="${detail_short}…"

    printf "  %s  %s%-*s%s %s%-8s%s %s%s%s\n" \
        "$icon" \
        "${B}${WHITE}" "$name_len" "$name" "$R" \
        "${color}" "$label" "$R" \
        "${D}${SLATE}" "$detail_short" "$R" >&2
}

# ── COLOR MATH ENGINE ─────────────────────────────────────────────────────────

# Parse hex color to R G B (0-255)
hex_to_rgb() {
    local hex="${1#\#}"
    local r=$(( 16#${hex:0:2} ))
    local g=$(( 16#${hex:2:2} ))
    local b=$(( 16#${hex:4:2} ))
    echo "$r $g $b"
}

# sRGB luminance (relative)
srgb_luminance() {
    local r="$1" g="$2" b="$3"

    # Using python3 for floating point precision
    if command -v python3 &>/dev/null; then
        python3 - "$r" "$g" "$b" <<'PYEOF'
import sys
r, g, b = int(sys.argv[1])/255, int(sys.argv[2])/255, int(sys.argv[3])/255
def linearize(c):
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4
R, G, B = linearize(r), linearize(g), linearize(b)
print(f"{0.2126*R + 0.7152*G + 0.0722*B:.6f}")
PYEOF
    else
        # Integer approximation fallback
        local r_norm=$(( r * 1000 / 255 ))
        local g_norm=$(( g * 1000 / 255 ))
        local b_norm=$(( b * 1000 / 255 ))
        echo "$(( (2126 * r_norm + 7152 * g_norm + 722 * b_norm) / 10000000 ))"
    fi
}

# WCAG contrast ratio between two hex colors
contrast_ratio() {
    local hex1="$1" hex2="$2"

    if ! command -v python3 &>/dev/null; then
        echo "1.00"
        return
    fi

    python3 - "$hex1" "$hex2" <<'PYEOF'
import sys, re

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def linearize(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def luminance(r, g, b):
    R, G, B = linearize(r), linearize(g), linearize(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B

def contrast(h1, h2):
    L1 = luminance(*hex_to_rgb(h1))
    L2 = luminance(*hex_to_rgb(h2))
    lighter = max(L1, L2)
    darker  = min(L1, L2)
    return (lighter + 0.05) / (darker + 0.05)

try:
    ratio = contrast(sys.argv[1], sys.argv[2])
    print(f"{ratio:.2f}")
except Exception as e:
    print("1.00")
PYEOF
}

# Validate hex color format
is_valid_hex() {
    local hex="${1#\#}"
    [[ ${#hex} -eq 6 ]] && echo "$hex" | grep -qiP '^[0-9a-f]{6}$'
}

# Generate 24-bit terminal color swatch
color_swatch() {
    local hex="${1#\#}"
    local r=$(( 16#${hex:0:2} ))
    local g=$(( 16#${hex:2:2} ))
    local b=$(( 16#${hex:4:2} ))
    printf "\033[48;2;%d;%d;%dm  \033[0m" "$r" "$g" "$b"
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    local theme_file="$1"
    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  🎨 ASH THEME VALIDATOR v${SCRIPT_VERSION}${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  WCAG Compliance · Color Theory · Schema Validation · Quality Gates${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-16s%s %s%s%s" \
        "${CYAN}${B}" "Theme File:" "$R$BG_MIDNIGHT$GOLD" \
        "${LAVENDER}" "$theme_file" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-16s%s %s%s%s" \
        "${CYAN}${B}" "Validator:" "$R$BG_MIDNIGHT$GOLD" \
        "${MINT}" "ASH Theme Engine v${SCRIPT_VERSION}" "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-16s%s %s%s%s" \
        "${CYAN}${B}" "Timestamp:" "$R$BG_MIDNIGHT$GOLD" \
        "${PEACH}" "$(date '+%Y-%m-%d %H:%M:%S')" "$R$BG_MIDNIGHT$GOLD")"
    box_b
    printf "\n" >&2
}

# ══════════════════════════════════════════════════════════════════════════════
#  VALIDATION FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# ── FILE STRUCTURE ─────────────────────────────────────────────────────────────
validate_file_structure() {
    section "📁" "File Structure Validation" "$CYAN"

    local theme_path="$1"
    THEME_DIR="$(dirname "$theme_path")"

    # Check file exists
    if [[ ! -f "$theme_path" ]]; then
        check "exists" "Theme file exists" "📄" "fail" "File not found: $theme_path" 5
        return 1
    fi
    check "exists" "Theme file exists" "📄" "pass" "$theme_path" 5

    # Check file is not empty
    if [[ ! -s "$theme_path" ]]; then
        check "not_empty" "File not empty" "📏" "fail" "File is empty" 3
        return 1
    fi
    check "not_empty" "File not empty" "📏" "pass" "$(wc -c < "$theme_path") bytes" 3

    # Check file permissions
    local perms
    perms="$(stat -c '%a' "$theme_path" 2>/dev/null || stat -f '%A' "$theme_path" 2>/dev/null || echo "644")"
    if [[ "$perms" == "644" ]] || [[ "$perms" == "664" ]]; then
        check "permissions" "File permissions" "🔐" "pass" "mode: $perms" 1
    else
        check "permissions" "File permissions" "🔐" "warn" "mode: $perms (expected 644)" 1
    fi

    # Check file size
    local size_kb
    size_kb="$(du -k "$theme_path" 2>/dev/null | cut -f1 || echo 0)"
    if [[ $size_kb -gt $MAX_THEME_SIZE_KB ]]; then
        check "size" "File size" "💾" "fail" \
            "${size_kb}KB exceeds ${MAX_THEME_SIZE_KB}KB limit" 2
    else
        check "size" "File size" "💾" "pass" "${size_kb}KB" 2
    fi

    # Check for required companion files
    local -a required_companion=("metadata.json" "preview.webp")
    for companion in "${required_companion[@]}"; do
        local companion_path="${THEME_DIR}/${companion}"
        if [[ -f "$companion_path" ]]; then
            check "companion_${companion}" \
                "Companion: $companion" "📎" "pass" "present" 2
        else
            check "companion_${companion}" \
                "Companion: $companion" "📎" "warn" "missing (recommended)" 1
        fi
    done

    # Optional companion files
    local -a optional_companion=("wallpaper.jpg" "wallpaper.png" "wallpaper.webp" "theme.conf")
    for companion in "${optional_companion[@]}"; do
        if [[ -f "${THEME_DIR}/${companion}" ]]; then
            check "optional_${companion}" \
                "Optional: $companion" "📎" "pass" "present" 1
        fi
    done
}

# ── JSON SYNTAX ────────────────────────────────────────────────────────────────
validate_json_syntax() {
    section "📋" "JSON Syntax Validation" "$INDIGO"

    local theme_path="$1"

    if command -v jq &>/dev/null; then
        local output
        if ! output="$(jq empty < "$theme_path" 2>&1)"; then
            check "json_valid" "JSON syntax" "📋" "fail" "$output" 10
            return 1
        fi
        check "json_valid" "JSON syntax" "📋" "pass" "valid JSON" 10

        # Check JSON depth (no excessively nested structures)
        local max_depth
        max_depth="$(jq '[paths | length] | max' < "$theme_path" 2>/dev/null || echo 0)"
        if [[ "$max_depth" -gt 8 ]]; then
            check "json_depth" "JSON nesting depth" "🏗️" "warn" \
                "depth: $max_depth (max recommended: 8)" 1
        else
            check "json_depth" "JSON nesting depth" "🏗️" "pass" "depth: $max_depth" 1
        fi

        # Check for duplicate keys (jq doesn't error on these by default)
        if command -v python3 &>/dev/null; then
            local dup_check
            dup_check="$(python3 -c "
import json, sys
with open('$theme_path') as f:
    content = f.read()
try:
    seen = {}
    class DupChecker:
        def __init__(self):
            self.dupes = []
        def __call__(self, pairs):
            d = {}
            for k, v in pairs:
                if k in d:
                    self.dupes.append(k)
                d[k] = v
            return d
    checker = DupChecker()
    json.loads(content, object_pairs_hook=checker)
    if checker.dupes:
        print('DUPES:' + ','.join(checker.dupes))
    else:
        print('OK')
except Exception as e:
    print(f'ERROR:{e}')
" 2>/dev/null || echo "SKIP")"

            if echo "$dup_check" | grep -q "^DUPES:"; then
                local dupes; dupes="${dup_check#DUPES:}"
                check "json_dupes" "Duplicate JSON keys" "🔑" "warn" \
                    "duplicates: $dupes" 2
            elif echo "$dup_check" | grep -q "^OK"; then
                check "json_dupes" "Duplicate JSON keys" "🔑" "pass" \
                    "no duplicates" 2
            fi
        fi
    elif command -v python3 &>/dev/null; then
        local output
        if ! output="$(python3 -m json.tool "$theme_path" > /dev/null 2>&1)"; then
            check "json_valid" "JSON syntax" "📋" "fail" \
                "Invalid JSON" 10
            return 1
        fi
        check "json_valid" "JSON syntax" "📋" "pass" "valid JSON" 10
    else
        check "json_valid" "JSON syntax" "📋" "skip" \
            "jq/python3 not available" 10
    fi
}

# ── METADATA VALIDATION ────────────────────────────────────────────────────────
validate_metadata() {
    section "📝" "Metadata Validation" "$LAVENDER"

    local theme_path="$1"

    # Check if metadata.json exists
    local meta_file="${THEME_DIR}/metadata.json"

    if [[ ! -f "$meta_file" ]]; then
        # Try reading metadata from colors.json itself
        meta_file="$theme_path"
    fi

    if ! command -v jq &>/dev/null; then
        check "metadata" "Metadata" "📝" "skip" "jq required" 0
        return 0
    fi

    # Validate required fields
    for field in "${REQUIRED_METADATA_FIELDS[@]}"; do
        local value
        value="$(jq -r --arg f "$field" '.[$f] // empty' "$meta_file" 2>/dev/null || true)"

        if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
            check "meta_${field}" "Metadata: ${field}" "📝" "pass" \
                "\"${value:0:40}\"" 2

            # Store key values
            case "$field" in
                name)        THEME_NAME="$value" ;;
                category)    THEME_CATEGORY="$value" ;;
            esac
        else
            check "meta_${field}" "Metadata: ${field}" "📝" "fail" \
                "missing required field" 2
        fi
    done

    # Validate category value
    if [[ -n "$THEME_CATEGORY" ]]; then
        local valid_cat=false
        for cat in "${VALID_CATEGORIES[@]}"; do
            [[ "$THEME_CATEGORY" == "$cat" ]] && { valid_cat=true; break; }
        done

        if [[ "$valid_cat" == "true" ]]; then
            check "meta_category_val" "Category value" "🏷️" "pass" \
                "$THEME_CATEGORY" 2
        else
            check "meta_category_val" "Category value" "🏷️" "fail" \
                "'${THEME_CATEGORY}' not in: ${VALID_CATEGORIES[*]}" 2
        fi
    fi

    # Validate version format (semver)
    local version
    version="$(jq -r '.version // empty' "$meta_file" 2>/dev/null || true)"
    if [[ -n "$version" ]]; then
        if echo "$version" | grep -qP '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$'; then
            check "meta_version_fmt" "Version format (semver)" "🏷️" "pass" \
                "$version" 2
        else
            check "meta_version_fmt" "Version format (semver)" "🏷️" "warn" \
                "'$version' is not semver" 1
        fi
    fi

    # Validate author format
    local author
    author="$(jq -r '.author // empty' "$meta_file" 2>/dev/null || true)"
    if [[ -n "$author" ]]; then
        if echo "$author" | grep -qP '^.{2,50}$'; then
            check "meta_author_len" "Author name length" "👤" "pass" \
                "$author" 1
        else
            check "meta_author_len" "Author name length" "👤" "warn" \
                "should be 2-50 chars" 1
        fi
    fi

    # Check for license field
    local license
    license="$(jq -r '.license // empty' "$meta_file" 2>/dev/null || true)"
    if [[ -n "$license" ]] && [[ "$license" != "null" ]]; then
        check "meta_license" "License" "⚖️" "pass" "$license" 1
    else
        check "meta_license" "License" "⚖️" "warn" \
            "no license specified (recommended: MIT)" 1
    fi

    # Check tags
    local tag_count
    tag_count="$(jq -r '.tags | length // 0' "$meta_file" 2>/dev/null || echo 0)"
    if [[ "$tag_count" -gt 0 ]]; then
        check "meta_tags" "Theme tags" "🏷️" "pass" "${tag_count} tags" 1
    else
        check "meta_tags" "Theme tags" "🏷️" "warn" \
            "no tags (helps discoverability)" 1
    fi
}

# ── COLOR FIELD VALIDATION ─────────────────────────────────────────────────────
validate_color_fields() {
    section "🎨" "Color Field Validation" "$MAGENTA"

    local theme_path="$1"

    if ! command -v jq &>/dev/null; then
        check "color_fields" "Color fields" "🎨" "skip" "jq required" 0
        return 0
    fi

    # Extract colors object
    local colors_key
    # Support both flat and nested color structures
    if jq -e '.colors' < "$theme_path" &>/dev/null; then
        colors_key=".colors"
    else
        colors_key="."
    fi

    # Validate required color fields
    local missing_required=()
    local invalid_format=()
    local valid_required=()

    for color_field in "${REQUIRED_COLOR_FIELDS[@]}"; do
        local value
        value="$(jq -r --arg f "$color_field" \
            "${colors_key}[\$f] // empty" \
            "$theme_path" 2>/dev/null || true)"

        if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
            missing_required+=("$color_field")
            check "color_${color_field}" \
                "Color: ${color_field}" "🎨" "fail" "missing required field" 2
            continue
        fi

        # Validate hex format
        if is_valid_hex "$value"; then
            valid_required+=("$color_field")
            local swatch; swatch="$(color_swatch "$value")"
            check "color_${color_field}" \
                "Color: ${color_field}" "🎨" "pass" \
                "${swatch} ${value}" 2
        else
            invalid_format+=("$color_field: $value")
            check "color_${color_field}" \
                "Color: ${color_field}" "🎨" "fail" \
                "invalid hex: '$value' (expected #RRGGBB)" 2
        fi
    done

    # Count total colors
    COLOR_COUNT="$(jq "${colors_key} | keys | length" \
        "$theme_path" 2>/dev/null || echo 0)"

    check "color_count" "Total colors in palette" "🎨" \
        "$(if [[ $COLOR_COUNT -ge $MIN_COLORS_REQUIRED ]]; then echo pass; else echo fail; fi)" \
        "${COLOR_COUNT} colors (min: ${MIN_COLORS_REQUIRED})" 3

    log_metric "Required colors valid: ${#valid_required[@]}/${#REQUIRED_COLOR_FIELDS[@]}"
    log_metric "Missing required: ${missing_required[*]:-none}"
    log_metric "Invalid format: ${invalid_format[*]:-none}"
}

# ── HEX FORMAT DEEP VALIDATION ────────────────────────────────────────────────
validate_hex_formats() {
    section "🔬" "Hex Color Format Audit" "$TEAL"

    local theme_path="$1"

    if ! command -v python3 &>/dev/null; then
        check "hex_audit" "Hex format audit" "🔬" "skip" "python3 required" 0
        return 0
    fi

    # Run comprehensive hex audit
    local audit_result
    audit_result="$(python3 - "$theme_path" <<'PYEOF'
import json, sys, re

HEX_PATTERN = re.compile(r'^#[0-9a-fA-F]{6}$')
VALID_FORMATS = ['#RRGGBB']

with open(sys.argv[1]) as f:
    data = json.load(f)

def check_colors(obj, path=""):
    issues = []
    for k, v in obj.items() if isinstance(obj, dict) else enumerate(obj):
        current_path = f"{path}.{k}" if path else str(k)
        if isinstance(v, str) and (v.startswith('#') or v.startswith('0x')):
            if not HEX_PATTERN.match(v):
                if v.startswith('#') and len(v) == 4:
                    # Short hex (#RGB)
                    issues.append(f"SHORT_HEX:{current_path}={v}")
                elif v.startswith('0x'):
                    issues.append(f"WRONG_PREFIX:{current_path}={v}")
                elif len(v) == 9:
                    issues.append(f"HAS_ALPHA:{current_path}={v}")
                else:
                    issues.append(f"INVALID:{current_path}={v}")
        elif isinstance(v, (dict, list)):
            issues.extend(check_colors(v, current_path))
    return issues

issues = check_colors(data)
if issues:
    for issue in issues[:20]:
        print(issue)
else:
    print("OK")
PYEOF
    2>/dev/null || echo "ERROR")"

    if [[ "$audit_result" == "OK" ]]; then
        check "hex_format_all" "All hex colors valid format" "🔬" "pass" \
            "all #RRGGBB format" 5
    elif [[ "$audit_result" == "ERROR" ]]; then
        check "hex_format_all" "Hex format audit" "🔬" "skip" \
            "audit failed" 5
    else
        local issue_count
        issue_count="$(echo "$audit_result" | wc -l | tr -d ' ')"

        check "hex_format_all" "Hex color format issues" "🔬" "fail" \
            "${issue_count} format issue(s) found" 5

        printf "\n" >&2
        echo "$audit_result" | head -10 | while IFS= read -r issue; do
            local type="${issue%%:*}"
            local detail="${issue#*:}"
            local icon color fix_hint
            case "$type" in
                SHORT_HEX)    icon="📏" color="${YELLOW}"
                              fix_hint="expand: #RGB → #RRGGBB" ;;
                WRONG_PREFIX) icon="🔤" color="${ORANGE}"
                              fix_hint="use #RRGGBB format" ;;
                HAS_ALPHA)    icon="💧" color="${CORAL}"
                              fix_hint="remove alpha channel" ;;
                *)            icon="❌" color="${RED}"
                              fix_hint="use #RRGGBB format" ;;
            esac

            printf "     %s%s%s %s%s%s %s→%s %s%s%s\n" \
                "${color}" "$icon" "$R" \
                "${D}" "$detail" "$R" \
                "${SLATE}" "$R" \
                "${D}${MINT}" "$fix_hint" "$R" >&2
        done
        printf "\n" >&2
    fi
}

# ── WCAG CONTRAST VALIDATION ───────────────────────────────────────────────────
validate_wcag_contrast() {
    section "♿" "WCAG Contrast Validation" "$EMERALD"

    if ! command -v python3 &>/dev/null; then
        check "wcag" "WCAG contrast" "♿" "skip" "python3 required" 0
        return 0
    fi

    local theme_path="$1"

    if ! command -v jq &>/dev/null; then
        check "wcag" "WCAG contrast" "♿" "skip" "jq required" 0
        return 0
    fi

    local colors_key=".colors"
    jq -e '.colors' < "$theme_path" &>/dev/null || colors_key="."

    local bg;   bg="$(jq -r "${colors_key}.background // empty" "$theme_path" 2>/dev/null || true)"
    local fg;   fg="$(jq -r "${colors_key}.foreground // empty" "$theme_path" 2>/dev/null || true)"
    local acc;  acc="$(jq -r "${colors_key}.accent // empty"     "$theme_path" 2>/dev/null || true)"
    local cmt;  cmt="$(jq -r "${colors_key}.comment // empty"    "$theme_path" 2>/dev/null || true)"
    local sel;  sel="$(jq -r "${colors_key}.selection // empty"  "$theme_path" 2>/dev/null || true)"

    # Core contrast checks
    if [[ -n "$bg" ]] && [[ -n "$fg" ]] && \
       is_valid_hex "$bg" && is_valid_hex "$fg"; then

        local ratio; ratio="$(contrast_ratio "$bg" "$fg")"
        local ratio_fmt; ratio_fmt="$(printf "%.2f:1" "$ratio")"

        # Main text contrast (WCAG AA minimum 4.5:1)
        local aa_pass; aa_pass="$(python3 -c \
            "print('pass' if float('$ratio') >= $MIN_CONTRAST_AA else 'fail')")"

        local bg_sw; bg_sw="$(color_swatch "$bg")"
        local fg_sw; fg_sw="$(color_swatch "$fg")"

        check "wcag_fg_bg_aa" \
            "Text/Background (WCAG AA ≥4.5:1)" "♿" "$aa_pass" \
            "${bg_sw}${fg_sw} ratio: ${ratio_fmt}" 5

        # WCAG AAA check (7:1)
        local aaa_pass; aaa_pass="$(python3 -c \
            "print('pass' if float('$ratio') >= $MIN_CONTRAST_AAA else 'warn')")"
        check "wcag_fg_bg_aaa" \
            "Text/Background (WCAG AAA ≥7.0:1)" "♿" "$aaa_pass" \
            "ratio: ${ratio_fmt}" 3
    fi

    # Accent contrast on background
    if [[ -n "$bg" ]] && [[ -n "$acc" ]] && \
       is_valid_hex "$bg" && is_valid_hex "$acc"; then
        local acc_ratio; acc_ratio="$(contrast_ratio "$bg" "$acc")"
        local acc_fmt; acc_fmt="$(printf "%.2f:1" "$acc_ratio")"
        local acc_sw; acc_sw="$(color_swatch "$acc")"

        local acc_pass; acc_pass="$(python3 -c \
            "print('pass' if float('$acc_ratio') >= $MIN_CONTRAST_AA_LARGE else 'warn')")"
        check "wcag_accent_bg" \
            "Accent/Background (WCAG AA-Large ≥3.0:1)" "♿" "$acc_pass" \
            "${acc_sw} ratio: ${acc_fmt}" 3
    fi

    # Comment text contrast (should be readable but can be lower)
    if [[ -n "$bg" ]] && [[ -n "$cmt" ]] && \
       is_valid_hex "$bg" && is_valid_hex "$cmt"; then
        local cmt_ratio; cmt_ratio="$(contrast_ratio "$bg" "$cmt")"
        local cmt_fmt; cmt_fmt="$(printf "%.2f:1" "$cmt_ratio")"
        local cmt_sw; cmt_sw="$(color_swatch "$cmt")"

        # Comments require minimum 3.0:1
        local cmt_pass; cmt_pass="$(python3 -c \
            "print('pass' if float('$cmt_ratio') >= 3.0 else 'warn')")"
        check "wcag_comment_bg" \
            "Comment/Background (min 3.0:1)" "♿" "$cmt_pass" \
            "${cmt_sw} ratio: ${cmt_fmt}" 2
    fi

    # Full palette contrast matrix
    if command -v python3 &>/dev/null && [[ -n "$bg" ]] && is_valid_hex "$bg"; then
        local low_contrast_colors=()

        # Test all colors against background
        local all_color_names=("red" "green" "yellow" "blue" "purple" "cyan" \
                               "orange" "pink" "accent")
        for color_name in "${all_color_names[@]}"; do
            local color_val
            color_val="$(jq -r --arg c "$color_name" \
                "${colors_key}[\$c] // empty" \
                "$theme_path" 2>/dev/null || true)"

            [[ -z "$color_val" ]] || [[ "$color_val" == "null" ]] && continue
            is_valid_hex "$color_val" || continue

            local c_ratio; c_ratio="$(contrast_ratio "$bg" "$color_val")"
            local c_aa; c_aa="$(python3 -c \
                "print('yes' if float('$c_ratio') >= $MIN_CONTRAST_AA_LARGE else 'no')")"

            if [[ "$c_aa" == "no" ]]; then
                local c_sw; c_sw="$(color_swatch "$color_val")"
                low_contrast_colors+=("${c_sw} ${color_name}: $(printf '%.1f:1' "$c_ratio")")
            fi
        done

        if [[ ${#low_contrast_colors[@]} -gt 0 ]]; then
            check "wcag_palette_matrix" \
                "Palette contrast matrix" "♿" "warn" \
                "${#low_contrast_colors[@]} colors below 3.0:1" 3

            for lc in "${low_contrast_colors[@]}"; do
                printf "     %s→%s %s%s%s\n" \
                    "${D}${SLATE}" "$R" "${D}" "$lc" "$R" >&2
            done
        else
            check "wcag_palette_matrix" \
                "Palette contrast matrix" "♿" "pass" \
                "all colors ≥ 3.0:1 on background" 3
        fi
    fi
}

# ── COLOR THEORY VALIDATION ────────────────────────────────────────────────────
validate_color_theory() {
    section "🌈" "Color Theory Analysis" "$VIOLET"

    if ! command -v python3 &>/dev/null; then
        check "color_theory" "Color theory" "🌈" "skip" "python3 required" 0
        return 0
    fi

    local theme_path="$1"

    python3 - "$theme_path" <<'PYEOF' 2>/dev/null | while IFS='|' read -r status name detail; do
import json, sys, math

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hsl(r, g, b):
    r, g, b = r/255, g/255, b/255
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    l = (max_c + min_c) / 2
    if max_c == min_c:
        return 0, 0, l
    d = max_c - min_c
    s = d / (2 - max_c - min_c) if l > 0.5 else d / (max_c + min_c)
    if max_c == r:
        h = (g - b) / d + (6 if g < b else 0)
    elif max_c == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return h * 60, s, l

def luminance(r, g, b):
    def lin(c):
        c = c / 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

with open(sys.argv[1]) as f:
    data = json.load(f)

colors = data.get('colors', data)

def get_color(name):
    v = colors.get(name, '')
    if v and v.startswith('#') and len(v) == 7:
        return hex_to_rgb(v)
    return None

bg  = get_color('background')
fg  = get_color('foreground')
acc = get_color('accent')

results = []

# 1. Dark/Light consistency
if bg:
    bg_lum = luminance(*bg)
    is_dark = bg_lum < 0.179  # threshold from WCAG
    category = colors.get('variant', '')
    if is_dark and 'light' in category.lower():
        results.append('WARN|Dark/Light Consistency|Background is dark but variant says light')
    elif not is_dark and 'dark' in category.lower():
        results.append('WARN|Dark/Light Consistency|Background is light but variant says dark')
    else:
        results.append(f'PASS|Dark/Light Consistency|background luminance: {bg_lum:.3f}')

# 2. Sufficient hue variety
hues = []
for name in ['red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'orange']:
    c = get_color(name)
    if c:
        h, s, l = rgb_to_hsl(*c)
        if s > 0.1:  # ignore near-greys
            hues.append(h)

if len(hues) >= 5:
    hue_spread = max(hues) - min(hues)
    results.append(f'PASS|Hue Variety|{len(hues)} saturated colors, spread: {hue_spread:.0f}°')
elif len(hues) >= 3:
    results.append(f'WARN|Hue Variety|only {len(hues)} distinct saturated hues (recommend 5+)')
else:
    results.append(f'FAIL|Hue Variety|insufficient color variety ({len(hues)} saturated hues)')

# 3. Background/Foreground polarity
if bg and fg:
    bg_l = luminance(*bg)
    fg_l = luminance(*fg)
    if (bg_l < 0.5 and fg_l > 0.5) or (bg_l > 0.5 and fg_l < 0.5):
        results.append('PASS|BG/FG Polarity|correct light/dark polarity')
    else:
        results.append('WARN|BG/FG Polarity|background and foreground have similar luminance')

# 4. Saturation balance
sats = []
for name in ['red', 'green', 'yellow', 'blue', 'purple', 'cyan']:
    c = get_color(name)
    if c:
        h, s, l = rgb_to_hsl(*c)
        sats.append(s)

if sats:
    avg_sat = sum(sats) / len(sats)
    sat_std = math.sqrt(sum((s - avg_sat)**2 for s in sats) / len(sats))
    if avg_sat > 0.3 and sat_std < 0.3:
        results.append(f'PASS|Saturation Balance|avg: {avg_sat:.2f}, std: {sat_std:.2f}')
    elif avg_sat < 0.15:
        results.append(f'WARN|Saturation Balance|very low saturation avg: {avg_sat:.2f}')
    else:
        results.append(f'PASS|Saturation Balance|avg: {avg_sat:.2f}')

# 5. Accent visibility
if bg and acc:
    bg_l  = luminance(*bg)
    acc_l = luminance(*acc)
    brighter = max(bg_l, acc_l)
    darker   = min(bg_l, acc_l)
    ratio = (brighter + 0.05) / (darker + 0.05)
    if ratio >= 3.0:
        results.append(f'PASS|Accent Visibility|contrast ratio {ratio:.1f}:1')
    else:
        results.append(f'WARN|Accent Visibility|low contrast {ratio:.1f}:1 (recommend ≥3.0:1)')

for r in results:
    print(r)
PYEOF
        local icon points
        case "$status" in
            PASS) icon="🌈" points=2 ;;
            WARN) icon="🌈" points=1 ;;
            FAIL) icon="🌈" points=0 ;;
            *)    icon="🌈" points=0; status="skip" ;;
        esac
        check "theory_${name// /_}" "$name" "$icon" \
            "$(echo "$status" | tr '[:upper:]' '[:lower:]')" "$detail" "$points"
    done
}

# ── SCHEMA VALIDATION ──────────────────────────────────────────────────────────
validate_schema() {
    section "📐" "Schema Compliance" "$INDIGO"

    local theme_path="$1"

    if [[ ! -f "$SCHEMA_FILE" ]]; then
        check "schema" "Theme schema" "📐" "skip" \
            "schema file not found: $SCHEMA_FILE" 0
        return 0
    fi

    # jsonschema validation
    if command -v python3 &>/dev/null && \
       python3 -c "import jsonschema" &>/dev/null 2>&1; then

        local result
        result="$(python3 - "$theme_path" "$SCHEMA_FILE" <<'PYEOF'
import json, sys
try:
    import jsonschema
    with open(sys.argv[1]) as f:
        instance = json.load(f)
    with open(sys.argv[2]) as f:
        schema = json.load(f)
    errors = list(jsonschema.Draft7Validator(schema).iter_errors(instance))
    if errors:
        for e in errors[:5]:
            print(f"FAIL:{e.path}:{e.message}")
    else:
        print("OK")
except ImportError:
    print("SKIP:no jsonschema")
except Exception as e:
    print(f"ERROR:{e}")
PYEOF
        2>/dev/null || echo "ERROR:validation failed")"

        if [[ "$result" == "OK" ]]; then
            check "schema_valid" "JSON Schema (Draft 7)" "📐" "pass" \
                "schema compliant" 10
        elif echo "$result" | grep -q "^SKIP:"; then
            check "schema_valid" "JSON Schema" "📐" "skip" \
                "jsonschema not installed" 10
        else
            local err_count
            err_count="$(echo "$result" | grep -c "^FAIL:" || echo 1)"
            check "schema_valid" "JSON Schema (Draft 7)" "📐" "fail" \
                "${err_count} schema violation(s)" 10
            echo "$result" | head -5 | grep "^FAIL:" | while IFS= read -r err; do
                printf "     %s→%s %s%s%s\n" \
                    "${D}${RED}" "$R" "${D}" "${err#FAIL:}" "$R" >&2
            done
        fi
    else
        check "schema_valid" "JSON Schema" "📐" "skip" \
            "python3/jsonschema not available" 10
    fi
}

# ── PREVIEW IMAGE VALIDATION ───────────────────────────────────────────────────
validate_preview() {
    section "🖼️" "Preview Image Validation" "$PEACH"

    local preview="${THEME_DIR}/preview.webp"

    if [[ ! -f "$preview" ]]; then
        check "preview_exists" "Preview image" "🖼️" "warn" \
            "missing preview.webp (highly recommended)" 3
        return 0
    fi
    check "preview_exists" "Preview image" "🖼️" "pass" "present" 3

    # Check file type
    if command -v file &>/dev/null; then
        local file_type
        file_type="$(file -b "$preview" 2>/dev/null || true)"
        if echo "$file_type" | grep -qiE "(webp|image)"; then
            check "preview_format" "Preview format" "🖼️" "pass" \
                "valid image: $file_type" 2
        else
            check "preview_format" "Preview format" "🖼️" "warn" \
                "unexpected type: $file_type" 2
        fi
    fi

    # Check preview size (should not be too large)
    local preview_kb
    preview_kb="$(du -k "$preview" 2>/dev/null | cut -f1 || echo 0)"

    if [[ $preview_kb -gt 2048 ]]; then
        check "preview_size" "Preview file size" "💾" "warn" \
            "${preview_kb}KB > 2MB (optimize with cwebp)" 2
    elif [[ $preview_kb -lt 5 ]]; then
        check "preview_size" "Preview file size" "💾" "warn" \
            "${preview_kb}KB too small (corrupt?)" 2
    else
        check "preview_size" "Preview file size" "💾" "pass" \
            "${preview_kb}KB" 2
    fi
}

# ── NAMING CONVENTIONS ─────────────────────────────────────────────────────────
validate_naming() {
    section "✏️" "Naming Conventions" "$CORAL"

    local theme_path="$1"
    local dir_name; dir_name="$(basename "$(dirname "$theme_path")")"

    # Directory name format: kebab-case
    if echo "$dir_name" | grep -qP '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        check "naming_dir" "Directory name (kebab-case)" "✏️" "pass" \
            "$dir_name" 2
    else
        check "naming_dir" "Directory name (kebab-case)" "✏️" "fail" \
            "'$dir_name' must be kebab-case (lowercase, hyphens)" 2
    fi

    # Theme name should match directory
    if [[ -n "$THEME_NAME" ]]; then
        local expected_dir
        expected_dir="$(echo "$THEME_NAME" | \
            tr '[:upper:]' '[:lower:]' | \
            sed 's/ /-/g; s/[^a-z0-9-]//g')"

        if [[ "$dir_name" == "$expected_dir" ]]; then
            check "naming_match" "Name matches directory" "✏️" "pass" \
                "$THEME_NAME → $dir_name" 2
        else
            check "naming_match" "Name matches directory" "✏️" "warn" \
                "name='$THEME_NAME' → dir should be '$expected_dir' not '$dir_name'" 1
        fi
    fi

    # File name should be colors.json or theme.conf
    local file_name; file_name="$(basename "$theme_path")"
    case "$file_name" in
        colors.json|theme.conf|metadata.json)
            check "naming_file" "File naming convention" "📄" "pass" \
                "$file_name" 1 ;;
        *)
            check "naming_file" "File naming convention" "📄" "warn" \
                "'$file_name' (expected: colors.json or theme.conf)" 1 ;;
    esac
}

# ── WALLPAPER VALIDATION ───────────────────────────────────────────────────────
validate_wallpaper() {
    section "🖼️" "Wallpaper Validation" "$SKY"

    local wallpaper=""
    for ext in jpg jpeg png webp avif; do
        if [[ -f "${THEME_DIR}/wallpaper.${ext}" ]]; then
            wallpaper="${THEME_DIR}/wallpaper.${ext}"
            break
        fi
    done

    if [[ -z "$wallpaper" ]]; then
        check "wallpaper_exists" "Theme wallpaper" "🖼️" "warn" \
            "no wallpaper file (optional but recommended)" 2
        return 0
    fi

    check "wallpaper_exists" "Theme wallpaper" "🖼️" "pass" \
        "$(basename "$wallpaper")" 2

    # Check wallpaper size (min 1080p recommended)
    local wall_kb; wall_kb="$(du -k "$wallpaper" 2>/dev/null | cut -f1 || echo 0)"

    if [[ $wall_kb -gt 20480 ]]; then
        check "wallpaper_size" "Wallpaper file size" "💾" "warn" \
            "${wall_kb}KB > 20MB (consider compression)" 2
    elif [[ $wall_kb -lt 50 ]]; then
        check "wallpaper_size" "Wallpaper file size" "💾" "warn" \
            "${wall_kb}KB might be too small (low quality?)" 2
    else
        check "wallpaper_size" "Wallpaper file size" "💾" "pass" \
            "${wall_kb}KB" 2
    fi

    # Check format
    if command -v file &>/dev/null; then
        local file_type; file_type="$(file -b "$wallpaper")"
        if echo "$file_type" | grep -qiE "(JPEG|PNG|WEBP|AVIF|image)"; then
            check "wallpaper_format" "Wallpaper format" "🖼️" "pass" \
                "$file_type" 1
        else
            check "wallpaper_format" "Wallpaper format" "🖼️" "warn" \
                "unusual format: $file_type" 1
        fi
    fi
}

# ── SCORE & GRADE ──────────────────────────────────────────────────────────────
calculate_grade() {
    local score="$1" max="$2"
    [[ $max -eq 0 ]] && { echo "N/A"; return; }

    local pct=$(( score * 100 / max ))

    if   [[ $pct -ge 95 ]]; then echo "S+ 🏆"
    elif [[ $pct -ge 90 ]]; then echo "S  ⭐"
    elif [[ $pct -ge 80 ]]; then echo "A+ 🥇"
    elif [[ $pct -ge 70 ]]; then echo "A  🥈"
    elif [[ $pct -ge 60 ]]; then echo "B+ 🥉"
    elif [[ $pct -ge 50 ]]; then echo "B  ✅"
    elif [[ $pct -ge 40 ]]; then echo "C  ⚠️"
    elif [[ $pct -ge 30 ]]; then echo "D  🔶"
    else                         echo "F  ❌"
    fi
}

# ── SCORE BAR ─────────────────────────────────────────────────────────────────
render_score_bar() {
    local score="$1" max="$2" width="${3:-40}"
    [[ $max -eq 0 ]] && max=1
    local pct=$(( score * 100 / max ))
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    local color
    if   [[ $pct -ge 80 ]]; then color="${GREEN}"
    elif [[ $pct -ge 60 ]]; then color="${YELLOW}"
    elif [[ $pct -ge 40 ]]; then color="${ORANGE}"
    else                         color="${RED}"
    fi

    printf "%s%s%s%s%s%s %s%d%%%s" \
        "${color}${B}" \
        "$(printf '%*s' "$filled" '' | tr ' ' '█')" \
        "${D}" \
        "$(printf '%*s' "$empty"  '' | tr ' ' '░')" \
        "$R" "" \
        "${color}${B}" "$pct" "$R"
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local theme_path="$1"
    local grade; grade="$(calculate_grade "$VALIDATION_SCORE" "$MAX_SCORE")"

    printf "\n" >&2
    box_t
    box_l "${B}${GOLD}  🎨 THEME VALIDATION REPORT${R}${BG_MIDNIGHT}${GOLD}"
    box_td
    box_l "$(printf "  %s%-20s%s %s%s%s" \
        "${CYAN}${B}" "Theme:" "$R$BG_MIDNIGHT$GOLD" \
        "${LAVENDER}${B}" "${THEME_NAME:-$(basename "$(dirname "$theme_path")")}" \
        "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-20s%s %s%s%s" \
        "${CYAN}${B}" "Category:" "$R$BG_MIDNIGHT$GOLD" \
        "${MINT}" "${THEME_CATEGORY:-unknown}" "$R$BG_MIDNIGHT$GOLD")"
    box_td
    box_l "$(printf "  %s%-20s%s %s%s%s" \
        "${CYAN}${B}" "Score:" "$R$BG_MIDNIGHT$GOLD" \
        "" "$(render_score_bar "$VALIDATION_SCORE" "$MAX_SCORE") ${VALIDATION_SCORE}/${MAX_SCORE}" \
        "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-20s%s %s%s%s" \
        "${CYAN}${B}" "Grade:" "$R$BG_MIDNIGHT$GOLD" \
        "${GOLD}${B}" "$grade" "$R$BG_MIDNIGHT$GOLD")"
    box_td
    box_l "$(printf "  %s✓ %-4s%s passed  %s✗ %-4s%s failed  %s⚠ %-4s%s warned  %s↷ %-4s%s skipped" \
        "${GREEN}${B}" "$CHECKS_PASSED"  "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"   "$CHECKS_FAILED"  "$R$BG_MIDNIGHT$GOLD" \
        "${YELLOW}${B}" "$CHECKS_WARNED" "$R$BG_MIDNIGHT$GOLD" \
        "${SLATE}${D}" "$CHECKS_SKIPPED" "$R$BG_MIDNIGHT$GOLD")"

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        box_td
        box_l "${RED}${B}  BLOCKING ERRORS:${R}${BG_MIDNIGHT}${GOLD}"
        for e in "${ERRORS[@]}"; do
            box_l "  ${RED}  ✗ ${e:0:$(( TERM_WIDTH-12 ))}${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        box_td
        box_l "${YELLOW}${B}  WARNINGS:${R}${BG_MIDNIGHT}${GOLD}"
        for w in "${WARNINGS[@]}"; do
            box_l "  ${YELLOW}  ⚠ ${w:0:$(( TERM_WIDTH-12 ))}${R}${BG_MIDNIGHT}${GOLD}"
        done
    fi

    box_td
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        box_l "  ${RED}${B}VALIDATION FAILED — Fix errors before committing${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Log: ${LOG_FILE}${R}${BG_MIDNIGHT}${GOLD}"
    else
        box_l "  ${GREEN}${B}VALIDATION PASSED ✓${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Grade: ${grade} | Score: ${VALIDATION_SCORE}/${MAX_SCORE}${R}${BG_MIDNIGHT}${GOLD}"
    fi
    box_b
    printf "\n" >&2
}

# ── USAGE ─────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${GOLD}${B}Usage:${R} validate-theme.sh <theme-file> [options]

${B}Arguments:${R}
  ${CYAN}theme-file${R}          Path to colors.json or theme.conf

${B}Options:${R}
  ${GREEN}--strict${R}            Treat warnings as errors
  ${GREEN}--no-wcag${R}           Skip WCAG contrast checks
  ${GREEN}--no-theory${R}         Skip color theory checks
  ${GREEN}--json-report${R}       Output JSON report to stdout
  ${GREEN}--help${R}              Show this help

${B}Exit Codes:${R}
  0  Validation passed
  1  Validation failed (has errors)
  2  Validation passed with warnings

EOF
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    init

    # Parse arguments
    local theme_file=""
    local strict=false
    local skip_wcag=false
    local skip_theory=false
    local json_report=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --strict)      strict=true;       shift ;;
            --no-wcag)     skip_wcag=true;    shift ;;
            --no-theory)   skip_theory=true;  shift ;;
            --json-report) json_report=true;  shift ;;
            --help|-h)     usage; exit 0 ;;
            -*)            echo "Unknown option: $1" >&2; usage; exit 1 ;;
            *)             theme_file="$1";   shift ;;
        esac
    done

    if [[ -z "$theme_file" ]]; then
        echo "${RED}Error: theme file argument required${R}" >&2
        usage
        exit 1
    fi

    print_banner "$theme_file"

    validate_file_structure "$theme_file"
    validate_json_syntax    "$theme_file"
    validate_metadata       "$theme_file"
    validate_color_fields   "$theme_file"
    validate_hex_formats    "$theme_file"
    validate_naming         "$theme_file"
    validate_preview
    validate_wallpaper

    [[ "$skip_wcag"   != "true" ]] && validate_wcag_contrast "$theme_file"
    [[ "$skip_theory" != "true" ]] && validate_color_theory  "$theme_file"
    validate_schema "$theme_file"

    print_summary "$theme_file"

    # JSON report
    if [[ "$json_report" == "true" ]] && command -v jq &>/dev/null; then
        jq -n \
            --arg name "$THEME_NAME" \
            --arg cat  "$THEME_CATEGORY" \
            --argjson score "$VALIDATION_SCORE" \
            --argjson max   "$MAX_SCORE" \
            --argjson passed  "$CHECKS_PASSED" \
            --argjson failed  "$CHECKS_FAILED" \
            --argjson warned  "$CHECKS_WARNED" \
            --argjson skipped "$CHECKS_SKIPPED" \
            '{
                name: $name, category: $cat,
                score: $score, max_score: $max,
                grade: (if $score/$max >= 0.95 then "S+"
                        elif $score/$max >= 0.90 then "S"
                        elif $score/$max >= 0.80 then "A+"
                        else "below-A" end),
                checks: {
                    passed:  $passed,
                    failed:  $failed,
                    warned:  $warned,
                    skipped: $skipped
                },
                passed: ($failed == 0)
            }'
    fi

    if [[ $CHECKS_FAILED -gt 0 ]]; then
        exit 1
    fi

    [[ "$strict" == "true" ]] && [[ $CHECKS_WARNED -gt 0 ]] && exit 1

    [[ $CHECKS_WARNED -gt 0 ]] && exit 2

    exit 0
}

main "$@"