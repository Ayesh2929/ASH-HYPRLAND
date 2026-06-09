#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — THEME ENGINE                                  ║
# ║           Wallpaper → 24 Colors → 12 App Targets                           ║
# ║           The core of the entire visual system                              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   theme-engine.sh WALLPAPER [MODE]
#
# MODES:
#   apply   — Extract colors and apply to all apps (default)
#   boot    — Apply last wallpaper on startup
#   reapply — Re-apply current colors without extraction
#   test    — Extract and show colors without applying
#   export  — Export current palette to JSON

set -euo pipefail
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════════════════
# 📌 CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="theme-engine"
readonly SCRIPT_VERSION="3.0.0"
readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly COLORS_DIR="${CACHE_DIR}/colors"
readonly WALL_CACHE="${CACHE_DIR}/wallpaper"
readonly THUMB_CACHE="${CACHE_DIR}/thumbnails"
readonly LOG_DIR="${CACHE_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/theme-engine.log"
readonly LOCK_FILE="/tmp/ash-theme-engine.lock"
readonly HISTORY_FILE="${WALL_CACHE}/history"
readonly LAST_WALL="${WALL_CACHE}/last"

# Output files
readonly COLORS_JSON="${COLORS_DIR}/current.json"
readonly COLORS_SHELL="${COLORS_DIR}/current.sh"
readonly HYPR_THEME="${CONFIG_DIR}/hypr/themes/active.conf"
readonly KITTY_THEME="${CONFIG_DIR}/kitty/themes/current.conf"
readonly WAYBAR_COLORS="${CONFIG_DIR}/waybar/styles/colors.css"
readonly ROFI_THEME="${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi"
readonly FISH_THEME="${CONFIG_DIR}/fish/themes/current.fish"
readonly GTK3_CSS="${CONFIG_DIR}/gtk-3.0/gtk.css"
readonly GTK4_CSS="${CONFIG_DIR}/gtk-4.0/gtk.css"
readonly DUNST_COLORS="${CACHE_DIR}/dunst-colors.sh"
readonly HYPRLOCK_COLORS="${CACHE_DIR}/hyprlock-colors.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLORS & OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly RED='\033[91m'
readonly GREEN='\033[92m'
readonly YELLOW='\033[93m'
readonly BLUE='\033[94m'
readonly MAGENTA='\033[95m'
readonly CYAN='\033[96m'
readonly DIM='\033[2m'

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') [${1}] ${2}" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  ${CYAN}→${RESET} $*"; log "INFO" "$*"; }
ok()      { echo -e "  ${GREEN}✓${RESET} $*"; log "OK" "$*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $*" >&2; log "WARN" "$*"; }
error()   { echo -e "  ${RED}✗${RESET} $*" >&2; log "ERROR" "$*"; }
section() { echo -e "\n  ${BOLD}${MAGENTA}${1}${RESET}"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 LOCK MECHANISM
# ═══════════════════════════════════════════════════════════════════════════════

acquire_lock() {
    local timeout=30
    local waited=0

    while [[ -f "${LOCK_FILE}" ]]; do
        local lock_pid
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "0")

        # Check if process still running
        if ! kill -0 "${lock_pid}" 2>/dev/null; then
            warn "Stale lock file — removing"
            rm -f "${LOCK_FILE}"
            break
        fi

        if (( waited >= timeout )); then
            error "Timeout waiting for lock (another instance running?)"
            exit 1
        fi

        info "Waiting for lock (${waited}s)..."
        sleep 1
        ((waited++)) || true
    done

    echo $$ > "${LOCK_FILE}"
    trap release_lock EXIT INT TERM
}

release_lock() {
    rm -f "${LOCK_FILE}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗂️ INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

init_directories() {
    local dirs=(
        "${COLORS_DIR}"
        "${WALL_CACHE}"
        "${THUMB_CACHE}"
        "${LOG_DIR}"
        "${CONFIG_DIR}/hypr/themes"
        "${CONFIG_DIR}/kitty/themes"
        "${CONFIG_DIR}/waybar/styles"
        "${CONFIG_DIR}/rofi/themes"
        "${CONFIG_DIR}/fish/themes"
        "${CONFIG_DIR}/gtk-3.0"
        "${CONFIG_DIR}/gtk-4.0"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ WALLPAPER VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

validate_wallpaper() {
    local wall="$1"

    # Empty = use last
    if [[ -z "${wall}" ]]; then
        if [[ -f "${LAST_WALL}" ]]; then
            wall=$(cat "${LAST_WALL}")
        else
            warn "No wallpaper specified and no history found"
            wall=""
        fi
    fi

    # Check file exists
    if [[ -n "${wall}" ]] && [[ ! -f "${wall}" ]]; then
        error "Wallpaper not found: ${wall}"
        wall=""
    fi

    # Check it's an image
    if [[ -n "${wall}" ]]; then
        local mime_type
        mime_type=$(file --mime-type -b "${wall}" 2>/dev/null || echo "unknown")
        if [[ "${mime_type}" != image/* ]]; then
            error "Not an image file: ${wall} (${mime_type})"
            wall=""
        fi
    fi

    echo "${wall}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR EXTRACTION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

extract_colors() {
    local wall="$1"

    if [[ -z "${wall}" ]]; then
        warn "No wallpaper — using fallback palette"
        use_fallback_palette
        return 0
    fi

    info "Extracting colors from: $(basename "${wall}")"

    # Check ImageMagick available
    if ! command -v convert &>/dev/null; then
        warn "ImageMagick not found — using fallback palette"
        use_fallback_palette
        return 0
    fi

    # ── Extract dominant colors using ImageMagick ─────────────────────────────
    # Method: quantize to N colors, get hex values
    local raw_colors
    raw_colors=$(convert "${wall}" \
        -filter Lanczos \
        -resize 200x200^ \
        -gravity center \
        -extent 200x200 \
        -quantize transparent \
        -colors 24 \
        -unique-colors \
        -format "%[hex:u]\n" \
        info: 2>/dev/null) || {
        warn "ImageMagick extraction failed — using fallback"
        use_fallback_palette
        return 0
    }

    # ── Parse colors ──────────────────────────────────────────────────────────
    local colors=()
    while IFS= read -r line; do
        # Clean hex value (remove alpha channel if present)
        local hex="${line:0:6}"
        if [[ "${hex}" =~ ^[0-9a-fA-F]{6}$ ]]; then
            colors+=("${hex}")
        fi
    done <<< "${raw_colors}"

    if (( ${#colors[@]} < 8 )); then
        warn "Too few colors extracted (${#colors[@]}) — using fallback"
        use_fallback_palette
        return 0
    fi

    # ── Sort colors by luminance ──────────────────────────────────────────────
    local sorted_colors=()
    while IFS= read -r hex; do
        sorted_colors+=("${hex}")
    done < <(sort_by_luminance "${colors[@]}")

    # ── Assign semantic roles ─────────────────────────────────────────────────
    assign_semantic_roles "${sorted_colors[@]}"

    ok "Color extraction complete (${#colors[@]} colors found)"
}

# Sort colors by perceived luminance (darkest to brightest)
sort_by_luminance() {
    local colors=("$@")
    local color_lum=()

    for hex in "${colors[@]}"; do
        local r g b
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))
        # Relative luminance (ITU-R BT.709)
        local lum=$(( (2126 * r + 7152 * g + 722 * b) / 10000 ))
        color_lum+=("${lum}:${hex}")
    done

    # Sort by luminance
    printf '%s\n' "${color_lum[@]}" | sort -t: -k1 -n | cut -d: -f2
}

# Validate color has sufficient saturation
has_saturation() {
    local hex="$1"
    local min_sat="${2:-30}"
    local r g b max min sat

    r=$(( 16#${hex:0:2} ))
    g=$(( 16#${hex:2:2} ))
    b=$(( 16#${hex:4:2} ))

    max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
    min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))

    if (( max == 0 )); then
        echo "false"
        return
    fi

    sat=$(( (max - min) * 100 / max ))
    (( sat >= min_sat )) && echo "true" || echo "false"
}

# Assign semantic color roles from sorted palette
assign_semantic_roles() {
    local sorted=("$@")
    local n=${#sorted[@]}

    # ── Background Colors (darkest) ───────────────────────────────────────────
    BASE="${sorted[0]}"
    MANTLE="${sorted[1]:-${sorted[0]}}"
    CRUST="${sorted[2]:-${sorted[0]}}"

    # ── Surface Colors (slightly raised) ─────────────────────────────────────
    SURFACE0="${sorted[3]:-${sorted[2]}}"
    SURFACE1="${sorted[4]:-${sorted[3]}}"
    SURFACE2="${sorted[5]:-${sorted[4]}}"

    # ── Overlay Colors (borders, dividers) ───────────────────────────────────
    OVERLAY0="${sorted[6]:-${sorted[5]}}"
    OVERLAY1="${sorted[7]:-${sorted[6]}}"
    OVERLAY2="${sorted[8]:-${sorted[7]}}"

    # ── Accent Colors (most saturated) ────────────────────────────────────────
    # Find most saturated colors for accents
    local sat_colors=()
    for hex in "${sorted[@]}"; do
        if [[ "$(has_saturation "${hex}" 40)" == "true" ]]; then
            sat_colors+=("${hex}")
        fi
    done

    # If not enough saturated colors, use brightest from sorted
    if (( ${#sat_colors[@]} >= 3 )); then
        PRIMARY="${sat_colors[${#sat_colors[@]}-1]}"
        SECONDARY="${sat_colors[${#sat_colors[@]}-2]}"
        TERTIARY="${sat_colors[${#sat_colors[@]}-3]}"
    else
        PRIMARY="${sorted[$((n-1))]}"
        SECONDARY="${sorted[$((n-2))]}"
        TERTIARY="${sorted[$((n-3))]}"
    fi

    # ── Text Colors (brightest) ───────────────────────────────────────────────
    TEXT="${sorted[$((n-1))]}"
    SUBTEXT1="${sorted[$((n-2))]}"
    SUBTEXT0="${sorted[$((n-3))]}"
    MUTED="${sorted[$((n-4))]}"

    # ── State Colors ──────────────────────────────────────────────────────────
    # Try to find semantic state colors; use accents as fallback
    SUCCESS="a6e3a1"  # Soft green (fallback)
    WARNING="f9e2af"  # Soft yellow (fallback)
    ERR="f38ba8"      # Soft red (fallback)
    INFO="89b4fa"     # Soft blue (fallback)

    # Override with extracted colors if they match theme
    for hex in "${sorted[@]}"; do
        local r g b
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))

        # Green-ish color → success
        if (( g > r + 20 && g > b + 20 && g > 100 )); then
            SUCCESS="${hex}"
        fi
        # Red-ish color → error
        if (( r > g + 30 && r > b + 30 && r > 100 )); then
            ERR="${hex}"
        fi
        # Blue-ish → info
        if (( b > r + 20 && b > g + 20 && b > 100 )); then
            INFO="${hex}"
        fi
    done

    # ── Export all colors ──────────────────────────────────────────────────────
    export BASE MANTLE CRUST
    export SURFACE0 SURFACE1 SURFACE2
    export OVERLAY0 OVERLAY1 OVERLAY2
    export PRIMARY SECONDARY TERTIARY
    export TEXT SUBTEXT1 SUBTEXT0 MUTED
    export SUCCESS WARNING ERR INFO

    log "INFO" "Colors: BASE=#${BASE} PRIMARY=#${PRIMARY} TEXT=#${TEXT}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 FALLBACK PALETTE (Catppuccin Mocha-inspired)
# ═══════════════════════════════════════════════════════════════════════════════

use_fallback_palette() {
    warn "Using fallback palette (Catppuccin Mocha)"

    BASE="1e1e2e"
    MANTLE="181825"
    CRUST="11111b"
    SURFACE0="313244"
    SURFACE1="45475a"
    SURFACE2="585b70"
    OVERLAY0="6c7086"
    OVERLAY1="7f849c"
    OVERLAY2="9399b2"
    PRIMARY="cba6f7"    # Mauve
    SECONDARY="89b4fa"  # Blue
    TERTIARY="94e2d5"   # Teal
    TEXT="cdd6f4"
    SUBTEXT1="bac2de"
    SUBTEXT0="a6adc8"
    MUTED="7f849c"
    SUCCESS="a6e3a1"
    WARNING="f9e2af"
    ERR="f38ba8"
    INFO="89b4fa"

    export BASE MANTLE CRUST
    export SURFACE0 SURFACE1 SURFACE2
    export OVERLAY0 OVERLAY1 OVERLAY2
    export PRIMARY SECONDARY TERTIARY
    export TEXT SUBTEXT1 SUBTEXT0 MUTED
    export SUCCESS WARNING ERR INFO
}

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 SAVE COLOR PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

save_palette() {
    local wall="${1:-}"

    # ── Save as JSON ──────────────────────────────────────────────────────────
    cat > "${COLORS_JSON}" << EOF
{
    "_meta": {
        "generated": "$(date -Iseconds)",
        "version": "${SCRIPT_VERSION}",
        "wallpaper": "${wall}",
        "generator": "ash-theme-engine"
    },
    "backgrounds": {
        "base":    "#${BASE}",
        "mantle":  "#${MANTLE}",
        "crust":   "#${CRUST}"
    },
    "surfaces": {
        "surface0": "#${SURFACE0}",
        "surface1": "#${SURFACE1}",
        "surface2": "#${SURFACE2}"
    },
    "overlays": {
        "overlay0": "#${OVERLAY0}",
        "overlay1": "#${OVERLAY1}",
        "overlay2": "#${OVERLAY2}"
    },
    "accents": {
        "primary":   "#${PRIMARY}",
        "secondary": "#${SECONDARY}",
        "tertiary":  "#${TERTIARY}"
    },
    "text": {
        "text":     "#${TEXT}",
        "subtext1": "#${SUBTEXT1}",
        "subtext0": "#${SUBTEXT0}",
        "muted":    "#${MUTED}"
    },
    "states": {
        "success": "#${SUCCESS}",
        "warning": "#${WARNING}",
        "error":   "#${ERR}",
        "info":    "#${INFO}"
    }
}
EOF

    # ── Save as Shell ──────────────────────────────────────────────────────────
    cat > "${COLORS_SHELL}" << EOF
# ASH Theme Engine — Generated $(date '+%Y-%m-%d %H:%M:%S')
# Source this file to get color variables
# Auto-generated — DO NOT EDIT MANUALLY

ASH_BASE="${BASE}"
ASH_MANTLE="${MANTLE}"
ASH_CRUST="${CRUST}"
ASH_SURFACE0="${SURFACE0}"
ASH_SURFACE1="${SURFACE1}"
ASH_SURFACE2="${SURFACE2}"
ASH_OVERLAY0="${OVERLAY0}"
ASH_OVERLAY1="${OVERLAY1}"
ASH_OVERLAY2="${OVERLAY2}"
ASH_PRIMARY="${PRIMARY}"
ASH_SECONDARY="${SECONDARY}"
ASH_TERTIARY="${TERTIARY}"
ASH_TEXT="${TEXT}"
ASH_SUBTEXT1="${SUBTEXT1}"
ASH_SUBTEXT0="${SUBTEXT0}"
ASH_MUTED="${MUTED}"
ASH_SUCCESS="${SUCCESS}"
ASH_WARNING="${WARNING}"
ASH_ERROR="${ERR}"
ASH_INFO="${INFO}"

export ASH_BASE ASH_MANTLE ASH_CRUST
export ASH_SURFACE0 ASH_SURFACE1 ASH_SURFACE2
export ASH_OVERLAY0 ASH_OVERLAY1 ASH_OVERLAY2
export ASH_PRIMARY ASH_SECONDARY ASH_TERTIARY
export ASH_TEXT ASH_SUBTEXT1 ASH_SUBTEXT0 ASH_MUTED
export ASH_SUCCESS ASH_WARNING ASH_ERROR ASH_INFO
EOF

    ok "Palette saved to ${COLORS_DIR}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ GENERATE HYPRLAND THEME
# ═══════════════════════════════════════════════════════════════════════════════

generate_hyprland() {
    info "Generating Hyprland theme..."

    cat > "${HYPR_THEME}" << EOF
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME ENGINE — Hyprland Active Theme                                   ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                    ║
# ║  Auto-generated — DO NOT EDIT MANUALLY                                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ── Gradient Border Colors ─────────────────────────────────────────────────────
general {
    col.active_border   = rgba(${PRIMARY}ff) rgba(${SECONDARY}ff) rgba(${TERTIARY}ff) 60deg
    col.inactive_border = rgba(${SURFACE0}aa)
    col.group_border_active = rgba(${PRIMARY}ff)
    col.group_border        = rgba(${SURFACE1}ee)
}

# ── Window Decorations ─────────────────────────────────────────────────────────
decoration {
    shadow {
        color          = rgba(${BASE}cc)
        color_inactive = rgba(${CRUST}88)
    }
}

# ── Group Bar Colors ───────────────────────────────────────────────────────────
group {
    col.border_active   = rgba(${PRIMARY}ff)
    col.border_inactive = rgba(${SURFACE1}ee)

    groupbar {
        col.active   = rgba(${PRIMARY}ff)
        col.inactive = rgba(${SURFACE0}ee)
    }
}
EOF

    ok "Hyprland theme generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🐱 GENERATE KITTY THEME
# ═══════════════════════════════════════════════════════════════════════════════

generate_kitty() {
    info "Generating Kitty terminal theme..."

    mkdir -p "$(dirname "${KITTY_THEME}")"
    cat > "${KITTY_THEME}" << EOF
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME ENGINE — Kitty Terminal Theme                                    ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Backgrounds
background              #${BASE}
background_opacity      0.92
background_blur         32

# Foreground (text)
foreground              #${TEXT}
selection_background    #${SURFACE2}
selection_foreground    #${TEXT}

# Cursor
cursor                  #${PRIMARY}
cursor_text_color       #${BASE}

# URLs
url_color               #${INFO}

# Window borders
active_border_color     #${PRIMARY}
inactive_border_color   #${SURFACE0}
bell_border_color       #${WARNING}

# Tab bar
tab_bar_background      #${MANTLE}
active_tab_background   #${PRIMARY}
active_tab_foreground   #${BASE}
inactive_tab_background #${SURFACE0}
inactive_tab_foreground #${SUBTEXT0}

# 16 Terminal Colors
# Black
color0  #${CRUST}
color8  #${SURFACE1}

# Red
color1  #${ERR}
color9  #${ERR}

# Green
color2  #${SUCCESS}
color10 #${SUCCESS}

# Yellow
color3  #${WARNING}
color11 #${WARNING}

# Blue
color4  #${INFO}
color12 #${SECONDARY}

# Magenta
color5  #${PRIMARY}
color13 #${TERTIARY}

# Cyan
color6  #${TERTIARY}
color14 #${TERTIARY}

# White
color7  #${SUBTEXT0}
color15 #${TEXT}

# Marks
mark1_background #${PRIMARY}
mark1_foreground #${BASE}
mark2_background #${SECONDARY}
mark2_foreground #${BASE}
mark3_background #${TERTIARY}
mark3_foreground #${BASE}
EOF

    ok "Kitty theme generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 GENERATE WAYBAR COLORS
# ═══════════════════════════════════════════════════════════════════════════════

generate_waybar() {
    info "Generating Waybar CSS colors..."

    mkdir -p "$(dirname "${WAYBAR_COLORS}")"
    cat > "${WAYBAR_COLORS}" << EOF
/* ╔═══════════════════════════════════════════════════════════════════════════╗
   ║  ASH THEME ENGINE — Waybar Color Variables                              ║
   ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                ║
   ║  Auto-generated — DO NOT EDIT MANUALLY                                  ║
   ╚═══════════════════════════════════════════════════════════════════════════╝ */

@define-color base       #${BASE};
@define-color mantle     #${MANTLE};
@define-color crust      #${CRUST};
@define-color surface0   #${SURFACE0};
@define-color surface1   #${SURFACE1};
@define-color surface2   #${SURFACE2};
@define-color overlay0   #${OVERLAY0};
@define-color overlay1   #${OVERLAY1};
@define-color overlay2   #${OVERLAY2};
@define-color primary    #${PRIMARY};
@define-color secondary  #${SECONDARY};
@define-color tertiary   #${TERTIARY};
@define-color text       #${TEXT};
@define-color subtext1   #${SUBTEXT1};
@define-color subtext0   #${SUBTEXT0};
@define-color muted      #${MUTED};
@define-color success    #${SUCCESS};
@define-color warning    #${WARNING};
@define-color error      #${ERR};
@define-color info       #${INFO};

/* Semantic aliases */
@define-color bg         @base;
@define-color bg-alt     @mantle;
@define-color fg         @text;
@define-color fg-alt     @subtext1;
@define-color accent     @primary;
@define-color accent2    @secondary;
@define-color border     @overlay0;

/* Alpha variants */
@define-color base-alpha      alpha(#${BASE}, 0.85);
@define-color surface0-alpha  alpha(#${SURFACE0}, 0.80);
@define-color primary-alpha   alpha(#${PRIMARY}, 0.80);
EOF

    ok "Waybar colors generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 GENERATE ROFI THEME
# ═══════════════════════════════════════════════════════════════════════════════

generate_rofi() {
    info "Generating Rofi dynamic theme..."

    mkdir -p "$(dirname "${ROFI_THEME}")"
    cat > "${ROFI_THEME}" << EOF
/* ╔═══════════════════════════════════════════════════════════════════════════╗
   ║  ASH THEME ENGINE — Rofi Dynamic Theme                                  ║
   ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                ║
   ╚═══════════════════════════════════════════════════════════════════════════╝ */

* {
    /* Color Palette */
    bg0:        #${BASE}e6;
    bg1:        #${MANTLE}cc;
    bg2:        #${SURFACE0}cc;
    bg3:        #${SURFACE1}ee;
    fg0:        #${TEXT}ff;
    fg1:        #${SUBTEXT1}ff;
    fg2:        #${SUBTEXT0}ff;
    accent:     #${PRIMARY}ff;
    accent2:    #${SECONDARY}ff;
    accent3:    #${TERTIARY}ff;
    border-col: #${OVERLAY0}88;
    selected:   #${PRIMARY}22;
    urgent:     #${ERR}ff;

    /* Fonts */
    font: "JetBrainsMono Nerd Font 12";

    /* Global Reset */
    background-color: transparent;
    text-color:       @fg0;
    border-color:     @border-col;
    outline-color:    transparent;
}

/* ── Main Window ────────────────────────────────────────────────────────────── */
window {
    background-color:  @bg0;
    border:            2px solid;
    border-color:      @accent;
    border-radius:     16px;
    padding:           20px;
    width:             680px;
    transparency:      "real";
}

/* ── Main Box ───────────────────────────────────────────────────────────────── */
mainbox {
    background-color:  transparent;
    spacing:           12px;
    children:          [ "inputbar", "message", "listview", "mode-switcher" ];
}

/* ── Input Bar ──────────────────────────────────────────────────────────────── */
inputbar {
    background-color:  @bg1;
    border-radius:     12px;
    padding:           10px 14px;
    spacing:           8px;
    children:          [ "prompt", "entry" ];
}

prompt {
    background-color:  transparent;
    text-color:        @accent;
    font:              "JetBrainsMono Nerd Font Bold 13";
    vertical-align:    0.5;
}

entry {
    background-color:  transparent;
    text-color:        @fg0;
    placeholder:       "Search...";
    placeholder-color: @fg2;
    cursor:            text;
    vertical-align:    0.5;
}

/* ── List View ──────────────────────────────────────────────────────────────── */
listview {
    background-color:  transparent;
    columns:           1;
    lines:             10;
    spacing:           4px;
    scrollbar:         false;
    cycle:             true;
    dynamic:           true;
}

/* ── List Items ─────────────────────────────────────────────────────────────── */
element {
    background-color:  transparent;
    border-radius:     8px;
    padding:           8px 12px;
    spacing:           10px;
    children:          [ "element-icon", "element-text" ];
    orientation:       horizontal;
}

element normal.normal {
    background-color:  transparent;
    text-color:        @fg0;
}

element selected.normal {
    background-color:  @selected;
    text-color:        @accent;
    border:            1px solid;
    border-color:      @accent;
}

element alternate.normal {
    background-color:  transparent;
    text-color:        @fg1;
}

element-icon {
    background-color:  transparent;
    size:              24px;
    vertical-align:    0.5;
}

element-text {
    background-color:  transparent;
    text-color:        inherit;
    vertical-align:    0.5;
}

/* ── Mode Switcher ──────────────────────────────────────────────────────────── */
mode-switcher {
    background-color:  @bg1;
    border-radius:     10px;
    padding:           4px;
    spacing:           4px;
}

button {
    background-color:  transparent;
    border-radius:     8px;
    padding:           6px 14px;
    text-color:        @fg1;
    cursor:            pointer;
}

button selected {
    background-color:  @accent;
    text-color:        #${BASE};
}

/* ── Message ────────────────────────────────────────────────────────────────── */
message {
    background-color:  transparent;
}

textbox {
    background-color:  @bg2;
    border-radius:     8px;
    padding:           8px 12px;
    text-color:        @fg1;
}

/* ── Scrollbar ──────────────────────────────────────────────────────────────── */
scrollbar {
    background-color:  @bg2;
    handle-color:      @accent;
    border-radius:     4px;
    width:             4px;
}
EOF

    ok "Rofi theme generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🐟 GENERATE FISH THEME
# ═══════════════════════════════════════════════════════════════════════════════

generate_fish() {
    info "Generating Fish shell colors..."

    mkdir -p "$(dirname "${FISH_THEME}")"
    cat > "${FISH_THEME}" << EOF
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME ENGINE — Fish Shell Colors                                       ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Fish color variables (set -g = global, persist across sessions)
set -g fish_color_normal           ${TEXT}
set -g fish_color_command          ${PRIMARY}
set -g fish_color_keyword          ${SECONDARY}
set -g fish_color_quote            ${SUCCESS}
set -g fish_color_redirection      ${TERTIARY}
set -g fish_color_end              ${TEXT}
set -g fish_color_error            ${ERR}
set -g fish_color_param            ${SUBTEXT1}
set -g fish_color_comment          ${OVERLAY1}
set -g fish_color_selection        --background=${SURFACE1}
set -g fish_color_search_match     --background=${SURFACE1}
set -g fish_color_operator         ${SECONDARY}
set -g fish_color_escape           ${TERTIARY}
set -g fish_color_autosuggestion   ${OVERLAY0}
set -g fish_color_cancel           ${ERR}
set -g fish_color_cwd              ${INFO}
set -g fish_color_cwd_root         ${ERR}
set -g fish_color_user             ${PRIMARY}
set -g fish_color_host             ${SECONDARY}
set -g fish_color_host_remote      ${TERTIARY}
set -g fish_color_status           ${ERR}

# Pager colors
set -g fish_pager_color_progress   ${MUTED}
set -g fish_pager_color_background
set -g fish_pager_color_prefix     ${PRIMARY}
set -g fish_pager_color_completion ${TEXT}
set -g fish_pager_color_description ${MUTED}
set -g fish_pager_color_selected_background --background=${SURFACE0}
set -g fish_pager_color_selected_prefix     ${PRIMARY}
set -g fish_pager_color_selected_completion ${TEXT}
EOF

    ok "Fish theme generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 GENERATE GTK THEMES
# ═══════════════════════════════════════════════════════════════════════════════

generate_gtk() {
    info "Generating GTK CSS overrides..."

    # GTK 3.0
    mkdir -p "$(dirname "${GTK3_CSS}")"
    cat > "${GTK3_CSS}" << EOF
/* ASH Theme Engine — GTK 3.0 CSS Override
   Generated: $(date '+%Y-%m-%d %H:%M:%S') */

@define-color theme_base_color          #${BASE};
@define-color theme_bg_color            #${MANTLE};
@define-color theme_fg_color            #${TEXT};
@define-color theme_selected_bg_color   #${PRIMARY};
@define-color theme_selected_fg_color   #${BASE};
@define-color theme_tooltip_bg_color    #${SURFACE0};
@define-color theme_tooltip_fg_color    #${TEXT};
@define-color borders                   #${OVERLAY0};
@define-color unfocused_borders         #${SURFACE1};

/* Header bars */
headerbar {
    background-color: #${MANTLE};
    border-bottom:    1px solid #${OVERLAY0};
    color:            #${TEXT};
}

/* Buttons */
button {
    background-color: #${SURFACE0};
    color:            #${TEXT};
    border-radius:    8px;
    border:           1px solid #${OVERLAY0};
    padding:          4px 12px;
}

button:hover {
    background-color: #${SURFACE1};
    border-color:     #${PRIMARY};
}

button:active {
    background-color: #${PRIMARY};
    color:            #${BASE};
}

/* Entries (text input) */
entry {
    background-color: #${SURFACE0};
    color:            #${TEXT};
    border-radius:    8px;
    border:           1px solid #${OVERLAY0};
    padding:          4px 8px;
    caret-color:      #${PRIMARY};
}

entry:focus {
    border-color:     #${PRIMARY};
    box-shadow:       0 0 0 2px alpha(#${PRIMARY}, 0.2);
}

/* Menus */
menu,
.menu,
.context-menu {
    background-color: #${SURFACE0};
    border:           1px solid #${OVERLAY0};
    border-radius:    10px;
    padding:          4px;
    color:            #${TEXT};
}

menuitem:hover {
    background-color: #${SURFACE1};
    border-radius:    6px;
    color:            #${PRIMARY};
}

/* Scrollbars */
scrollbar slider {
    background-color: #${OVERLAY0};
    border-radius:    4px;
    min-width:        6px;
    min-height:       6px;
}

scrollbar slider:hover {
    background-color: #${PRIMARY};
}

/* Tooltips */
tooltip {
    background-color: #${SURFACE0};
    color:            #${TEXT};
    border:           1px solid #${OVERLAY0};
    border-radius:    8px;
    padding:          4px 8px;
}
EOF

    # GTK 4.0
    mkdir -p "$(dirname "${GTK4_CSS}")"
    cp "${GTK3_CSS}" "${GTK4_CSS}"

    ok "GTK CSS generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔔 GENERATE DUNST COLORS
# ═══════════════════════════════════════════════════════════════════════════════

generate_dunst() {
    info "Generating Dunst notification colors..."

    # Save color variables for dunst reload script
    cat > "${DUNST_COLORS}" << EOF
# Dunst color variables — Generated $(date '+%Y-%m-%d %H:%M:%S')
DUNST_BASE="${BASE}"
DUNST_SURFACE="${SURFACE0}"
DUNST_OVERLAY="${OVERLAY0}"
DUNST_TEXT="${TEXT}"
DUNST_PRIMARY="${PRIMARY}"
DUNST_SUCCESS="${SUCCESS}"
DUNST_WARNING="${WARNING}"
DUNST_ERROR="${ERR}"
EOF

    # Reload dunst with new colors via dunstctl
    # The main dunstrc is regenerated by regenerate_dunstrc()
    regenerate_dunstrc
}

regenerate_dunstrc() {
    local dunstrc="${CONFIG_DIR}/dunst/dunstrc"
    mkdir -p "$(dirname "${dunstrc}")"

    cat > "${dunstrc}" << EOF
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME ENGINE — Dunst Configuration                                     ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[global]
    # ── Display ─────────────────────────────────────────────────────────────
    monitor             = 0
    follow              = mouse
    width               = (0, 480)
    height              = (0, 200)
    origin              = top-right
    offset              = 16x52
    scale               = 0
    notification_limit  = 5

    # ── Appearance ──────────────────────────────────────────────────────────
    transparency        = 10
    gap_size            = 8
    separator_height    = 2
    padding             = 14
    horizontal_padding  = 14
    text_icon_padding   = 10
    frame_width         = 2
    frame_color         = #${PRIMARY}
    gap_size            = 8
    corner_radius       = 12
    icon_corner_radius  = 6

    # ── Sorting ─────────────────────────────────────────────────────────────
    sort                = yes

    # ── Text ────────────────────────────────────────────────────────────────
    font                = JetBrainsMono Nerd Font 11
    line_height         = 0
    markup              = full
    format              = "<b>%s</b>\n%b"
    alignment           = left
    vertical_alignment  = center
    show_age_threshold  = 60
    ellipsize           = middle
    ignore_newline      = no
    stack_duplicates    = true
    hide_duplicate_count = false

    # ── Icons ────────────────────────────────────────────────────────────────
    icon_theme          = Papirus-Dark
    enable_recursive_icon_lookup = true
    icon_position       = left
    min_icon_size       = 32
    max_icon_size       = 64

    # ── History ─────────────────────────────────────────────────────────────
    sticky_history      = yes
    history_length      = 50

    # ── Misc ────────────────────────────────────────────────────────────────
    always_run_script   = true
    title               = Dunst
    class               = Dunst
    ignore_dbusclose    = false
    force_xwayland      = false
    force_xinerama      = false

    # ── Mouse ────────────────────────────────────────────────────────────────
    mouse_left_click    = close_current
    mouse_middle_click  = do_action, close_current
    mouse_right_click   = close_all

[urgency_low]
    background          = "#${SURFACE0}ee"
    foreground          = "#${SUBTEXT0}"
    frame_color         = "#${OVERLAY0}"
    timeout             = 6
    default_icon        = dialog-information

[urgency_normal]
    background          = "#${SURFACE0}ee"
    foreground          = "#${TEXT}"
    frame_color         = "#${PRIMARY}"
    timeout             = 8
    default_icon        = dialog-information

[urgency_critical]
    background          = "#${ERR}22"
    foreground          = "#${TEXT}"
    frame_color         = "#${ERR}"
    timeout             = 0
    default_icon        = dialog-error
EOF

    ok "Dunst config generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RELOAD ALL APPLICATIONS
# ═══════════════════════════════════════════════════════════════════════════════

reload_all() {
    section "🔄 Reloading Applications"

    # ── Hyprland ──────────────────────────────────────────────────────────────
    info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null && ok "Hyprland" || warn "Hyprland reload failed"

    # ── Waybar ────────────────────────────────────────────────────────────────
    info "Reloading Waybar..."
    pkill -SIGUSR2 waybar 2>/dev/null \
        || (pkill -x waybar 2>/dev/null; sleep 0.5; waybar &) \
        && ok "Waybar" || warn "Waybar reload failed"

    # ── Dunst ─────────────────────────────────────────────────────────────────
    info "Reloading Dunst..."
    pkill -x dunst 2>/dev/null; sleep 0.3
    dunst &
    disown
    ok "Dunst"

    # ── Kitty ─────────────────────────────────────────────────────────────────
    info "Refreshing Kitty terminals..."
    # Send SIGUSR1 to all kitty instances to reload config
    pkill -USR1 kitty 2>/dev/null && ok "Kitty" || info "No Kitty instances running"

    # ── Fish ──────────────────────────────────────────────────────────────────
    info "Sourcing Fish theme..."
    # Fish picks up theme on next shell open via config.fish sourcing current.fish
    ok "Fish (next open)"

    # ── GTK Settings ──────────────────────────────────────────────────────────
    info "Applying GTK settings..."
    gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha-Standard-Blue-Dark" 2>/dev/null \
        && ok "GTK theme" || warn "GTK settings failed"

    # ── SwayNC ────────────────────────────────────────────────────────────────
    info "Reloading SwayNC..."
    pkill -SIGUSR1 swaync 2>/dev/null \
        && ok "SwayNC" || info "SwayNC not running"

    # ── Rofi ─────────────────────────────────────────────────────────────────
    # Rofi reads theme on launch — no reload needed
    ok "Rofi (reads on launch)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ APPLY WALLPAPER
# ═══════════════════════════════════════════════════════════════════════════════

apply_wallpaper() {
    local wall="$1"

    if [[ -z "${wall}" ]]; then
        return 0
    fi

    info "Applying wallpaper: $(basename "${wall}")"

    if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
        swww img "${wall}" \
            --transition-type grow \
            --transition-pos "0.5,0.5" \
            --transition-duration 2 \
            --transition-fps 60 \
            --transition-bezier "0.34,1.56,0.64,1.0" \
            2>/dev/null \
            && ok "Wallpaper applied via swww" \
            || warn "swww failed to apply wallpaper"
    elif command -v feh &>/dev/null; then
        feh --bg-scale "${wall}" && ok "Wallpaper set via feh"
    elif command -v swaybg &>/dev/null; then
        pkill swaybg 2>/dev/null; swaybg -i "${wall}" -m fill &
        disown
        ok "Wallpaper set via swaybg"
    else
        warn "No wallpaper setter found (install swww)"
    fi

    # Save to history
    echo "${wall}" > "${LAST_WALL}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${wall}" >> "${HISTORY_FILE}"

    # Keep history to 50 entries
    if [[ -f "${HISTORY_FILE}" ]]; then
        local lines
        lines=$(wc -l < "${HISTORY_FILE}")
        if (( lines > 50 )); then
            tail -50 "${HISTORY_FILE}" > "${HISTORY_FILE}.tmp"
            mv "${HISTORY_FILE}.tmp" "${HISTORY_FILE}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 SHOW COLOR PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

show_palette() {
    echo ""
    echo -e "  ${BOLD}🎨 ASH COLOR PALETTE${RESET}"
    echo -e "  $(printf '─%.0s' {1..50})"

    local colors=(
        "BASE:${BASE}" "MANTLE:${MANTLE}" "CRUST:${CRUST}"
        "SURFACE0:${SURFACE0}" "SURFACE1:${SURFACE1}" "SURFACE2:${SURFACE2}"
        "OVERLAY0:${OVERLAY0}" "OVERLAY1:${OVERLAY1}" "OVERLAY2:${OVERLAY2}"
        "PRIMARY:${PRIMARY}" "SECONDARY:${SECONDARY}" "TERTIARY:${TERTIARY}"
        "TEXT:${TEXT}" "SUBTEXT1:${SUBTEXT1}" "SUBTEXT0:${SUBTEXT0}" "MUTED:${MUTED}"
        "SUCCESS:${SUCCESS}" "WARNING:${WARNING}" "ERROR:${ERR}" "INFO:${INFO}"
    )

    for entry in "${colors[@]}"; do
        local name="${entry%%:*}"
        local hex="${entry##*:}"
        local r g b
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))
        printf "  \033[38;2;%d;%d;%dm██\033[0m  %-12s #%s\n" \
            "${r}" "${g}" "${b}" "${name}" "${hex}"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local wall="${1:-}"
    local mode="${2:-apply}"

    # Print header
    echo ""
    echo -e "  ${BOLD}${MAGENTA}🎨 ASH Theme Engine v${SCRIPT_VERSION}${RESET}"
    echo -e "  ${DIM}Mode: ${mode} | Wall: $(basename "${wall:-none}")${RESET}"
    echo ""

    # Acquire lock
    acquire_lock

    # Initialize directories
    init_directories

    case "${mode}" in
        # ── Full apply (default) ────────────────────────────────────────────
        apply | "")
            local validated_wall
            validated_wall=$(validate_wallpaper "${wall}")

            section "🎨 Extracting Colors"
            extract_colors "${validated_wall}"
            save_palette "${validated_wall}"

            section "🎨 Generating Themes"
            generate_hyprland
            generate_kitty
            generate_waybar
            generate_rofi
            generate_fish
            generate_gtk
            generate_dunst

            section "🖼️ Applying Wallpaper"
            apply_wallpaper "${validated_wall}"

            section "🔄 Reloading"
            reload_all

            show_palette

            # Send notification
            notify-send "🎨 ASH Theme" \
                "Theme applied from $(basename "${validated_wall:-wallpaper")" \
                -i "${validated_wall:-dialog-information}" \
                -t 3000 \
                --app-name="ASH Theme Engine" \
                2>/dev/null || true

            echo -e "  ${GREEN}${BOLD}✓ Theme applied successfully!${RESET}"
            ;;

        # ── Boot mode (startup, use last wallpaper) ──────────────────────────
        boot)
            local last_wall=""
            [[ -f "${LAST_WALL}" ]] && last_wall=$(cat "${LAST_WALL}")

            if [[ -n "${last_wall}" ]] && [[ -f "${last_wall}" ]]; then
                info "Boot mode — restoring last wallpaper: $(basename "${last_wall}")"
                main "${last_wall}" "apply"
            else
                warn "Boot mode — no previous wallpaper, using fallback"
                use_fallback_palette
                save_palette ""
                generate_hyprland
                generate_kitty
                generate_waybar
                generate_rofi
                generate_fish
                generate_gtk
                generate_dunst
                reload_all
            fi
            ;;

        # ── Reapply current colors without re-extraction ──────────────────────
        reapply)
            if [[ -f "${COLORS_SHELL}" ]]; then
                # shellcheck source=/dev/null
                source "${COLORS_SHELL}"
                # Map ASH_ prefixed vars back
                BASE="${ASH_BASE:-1e1e2e}"
                MANTLE="${ASH_MANTLE:-181825}"
                CRUST="${ASH_CRUST:-11111b}"
                SURFACE0="${ASH_SURFACE0:-313244}"
                SURFACE1="${ASH_SURFACE1:-45475a}"
                SURFACE2="${ASH_SURFACE2:-585b70}"
                OVERLAY0="${ASH_OVERLAY0:-6c7086}"
                OVERLAY1="${ASH_OVERLAY1:-7f849c}"
                OVERLAY2="${ASH_OVERLAY2:-9399b2}"
                PRIMARY="${ASH_PRIMARY:-cba6f7}"
                SECONDARY="${ASH_SECONDARY:-89b4fa}"
                TERTIARY="${ASH_TERTIARY:-94e2d5}"
                TEXT="${ASH_TEXT:-cdd6f4}"
                SUBTEXT1="${ASH_SUBTEXT1:-bac2de}"
                SUBTEXT0="${ASH_SUBTEXT0:-a6adc8}"
                MUTED="${ASH_MUTED:-7f849c}"
                SUCCESS="${ASH_SUCCESS:-a6e3a1}"
                WARNING="${ASH_WARNING:-f9e2af}"
                ERR="${ASH_ERROR:-f38ba8}"
                INFO="${ASH_INFO:-89b4fa}"
            else
                use_fallback_palette
            fi

            section "🎨 Regenerating Themes"
            generate_hyprland
            generate_kitty
            generate_waybar
            generate_rofi
            generate_fish
            generate_gtk
            generate_dunst

            section "🔄 Reloading"
            reload_all

            ok "Theme reapplied"
            ;;

        # ── Test mode — extract and show without applying ─────────────────────
        test)
            local validated_wall
            validated_wall=$(validate_wallpaper "${wall}")
            extract_colors "${validated_wall}"
            show_palette
            ;;

        # ── Export current palette ────────────────────────────────────────────
        export)
            if [[ -f "${COLORS_JSON}" ]]; then
                cat "${COLORS_JSON}"
            else
                error "No palette found — run 'ash theme pick' first"
                exit 1
            fi
            ;;

        *)
            error "Unknown mode: ${mode}"
            echo "Modes: apply, boot, reapply, test, export"
            exit 1
            ;;
    esac

    log "INFO" "Theme engine complete — mode=${mode}"
}

main "$@"