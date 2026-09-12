#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 — COLORS LIBRARY                                              ║
# ║  ANSI escape codes, true-color support, theme-aware palette                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_COLORS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_COLORS_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 CATPPUCCIN MOCHA PALETTE (Default)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA ASH_PALETTE=(
    # Catppuccin Mocha
    [rosewater]="245 224 220"
    [flamingo]="242 205 205"
    [pink]="245 194 231"
    [mauve]="203 166 247"
    [red]="243 139 168"
    [maroon]="235 160 172"
    [peach]="250 179 135"
    [yellow]="249 226 175"
    [green]="166 227 161"
    [teal]="148 226 213"
    [sky]="137 220 235"
    [sapphire]="116 199 236"
    [blue]="137 180 250"
    [lavender]="180 190 254"
    [text]="205 214 244"
    [subtext1]="186 194 222"
    [subtext0]="166 173 200"
    [overlay2]="147 153 178"
    [overlay1]="127 132 156"
    [overlay0]="108 112 134"
    [surface2]="88 91 112"
    [surface1]="69 71 90"
    [surface0]="49 50 68"
    [base]="30 30 46"
    [mantle]="24 24 37"
    [crust]="17 17 27"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 ESCAPE CODE GENERATORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if colors should be rendered
_ash_colors_enabled() {
    [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 || "${FORCE_COLOR:-0}" -eq 1 ]]
}

# Foreground: true color (R G B)
ash_fg_rgb() {
    _ash_colors_enabled || return 0
    printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"
}

# Background: true color (R G B)
ash_bg_rgb() {
    _ash_colors_enabled || return 0
    printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"
}

# Foreground from palette name
ash_fg() {
    local name="$1"
    _ash_colors_enabled || return 0
    local rgb="${ASH_PALETTE[$name]:-}"
    [[ -z "$rgb" ]] && return 0
    # shellcheck disable=SC2086
    ash_fg_rgb $rgb
}

# Background from palette name
ash_bg() {
    local name="$1"
    _ash_colors_enabled || return 0
    local rgb="${ASH_PALETTE[$name]:-}"
    [[ -z "$rgb" ]] && return 0
    # shellcheck disable=SC2086
    ash_bg_rgb $rgb
}

# Text styles
ash_bold()      { _ash_colors_enabled && printf '\033[1m'  || true; }
ash_dim()       { _ash_colors_enabled && printf '\033[2m'  || true; }
ash_italic()    { _ash_colors_enabled && printf '\033[3m'  || true; }
ash_underline() { _ash_colors_enabled && printf '\033[4m'  || true; }
ash_blink()     { _ash_colors_enabled && printf '\033[5m'  || true; }
ash_reverse()   { _ash_colors_enabled && printf '\033[7m'  || true; }
ash_strike()    { _ash_colors_enabled && printf '\033[9m'  || true; }
ash_reset()     { _ash_colors_enabled && printf '\033[0m'  || true; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 SEMANTIC COLOR SHORTCUTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_c_success()  { ash_bold; ash_fg green;    }
ash_c_error()    { ash_bold; ash_fg red;      }
ash_c_warn()     { ash_bold; ash_fg yellow;   }
ash_c_info()     { ash_bold; ash_fg blue;     }
ash_c_debug()    { ash_dim;  ash_fg overlay0; }
ash_c_accent()   { ash_bold; ash_fg mauve;    }
ash_c_muted()    { ash_dim;  ash_fg subtext0; }
ash_c_heading()  { ash_bold; ash_fg lavender; }
ash_c_code()     { ash_fg sky;                }
ash_c_link()     { ash_underline; ash_fg sapphire; }
ash_c_tag()      { ash_fg pink;               }
ash_c_number()   { ash_fg peach;              }
ash_c_key()      { ash_fg teal;               }
ash_c_value()    { ash_fg green;              }
ash_c_path()     { ash_fg sky;                }
ash_c_time()     { ash_fg overlay2;           }
ash_c_badge()    { ash_bold; ash_fg base; ash_bg mauve; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 COLORED TEXT HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_text_success()  { printf '%s%s%s' "$(ash_c_success)" "$1" "$(ash_reset)"; }
ash_text_error()    { printf '%s%s%s' "$(ash_c_error)"   "$1" "$(ash_reset)"; }
ash_text_warn()     { printf '%s%s%s' "$(ash_c_warn)"    "$1" "$(ash_reset)"; }
ash_text_info()     { printf '%s%s%s' "$(ash_c_info)"    "$1" "$(ash_reset)"; }
ash_text_muted()    { printf '%s%s%s' "$(ash_c_muted)"   "$1" "$(ash_reset)"; }
ash_text_accent()   { printf '%s%s%s' "$(ash_c_accent)"  "$1" "$(ash_reset)"; }
ash_text_code()     { printf '%s%s%s' "$(ash_c_code)"    "$1" "$(ash_reset)"; }
ash_text_heading()  { printf '%s%s%s' "$(ash_c_heading)" "$1" "$(ash_reset)"; }
ash_text_path()     { printf '%s%s%s' "$(ash_c_path)"    "$1" "$(ash_reset)"; }
ash_text_key()      { printf '%s%s%s' "$(ash_c_key)"     "$1" "$(ash_reset)"; }
ash_text_value()    { printf '%s%s%s' "$(ash_c_value)"   "$1" "$(ash_reset)"; }
ash_text_number()   { printf '%s%s%s' "$(ash_c_number)"  "$1" "$(ash_reset)"; }
ash_text_time()     { printf '%s%s%s' "$(ash_c_time)"    "$1" "$(ash_reset)"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 GRADIENT TEXT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Print text with a left-to-right RGB gradient
# Usage: ash_gradient_text "text" R1 G1 B1 R2 G2 B2
ash_gradient_text() {
    local text="$1"
    local r1="$2" g1="$3" b1="$4"
    local r2="$5" g2="$6" b2="$7"

    _ash_colors_enabled || { printf '%s' "$text"; return 0; }

    local len="${#text}"
    [[ $len -eq 0 ]] && return 0
    [[ $len -eq 1 ]] && { ash_fg_rgb "$r1" "$g1" "$b1"; printf '%s' "$text"; ash_reset; return 0; }

    local i char r g b
    for (( i=0; i<len; i++ )); do
        char="${text:$i:1}"

        r=$(( r1 + (r2 - r1) * i / (len - 1) ))
        g=$(( g1 + (g2 - g1) * i / (len - 1) ))
        b=$(( b1 + (b2 - b1) * i / (len - 1) ))

        # Clamp to [0,255]
        r=$(( r < 0 ? 0 : r > 255 ? 255 : r ))
        g=$(( g < 0 ? 0 : g > 255 ? 255 : g ))
        b=$(( b < 0 ? 0 : b > 255 ? 255 : b ))

        printf '\033[38;2;%d;%d;%dm%s' "$r" "$g" "$b" "$char"
    done

    ash_reset
}

# Preset gradients
ash_gradient_mauve_blue() {
    # Mauve → Blue (Catppuccin)
    ash_gradient_text "$1"  203 166 247  137 180 250
}

ash_gradient_green_teal() {
    ash_gradient_text "$1"  166 227 161  148 226 213
}

ash_gradient_peach_yellow() {
    ash_gradient_text "$1"  250 179 135  249 226 175
}

ash_gradient_fire() {
    ash_gradient_text "$1"  243 139 168  250 179 135
}

ash_gradient_ocean() {
    ash_gradient_text "$1"  116 199 236  137 180 250
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 COLOR MANIPULATION UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Hex to RGB
ash_hex_to_rgb() {
    local hex="${1#'#'}"
    local r g b

    if [[ ${#hex} -eq 3 ]]; then
        r=$(( 16#${hex:0:1} * 17 ))
        g=$(( 16#${hex:1:1} * 17 ))
        b=$(( 16#${hex:2:1} * 17 ))
    elif [[ ${#hex} -eq 6 ]]; then
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))
    else
        ash_log_error "Invalid hex color: #${hex}"
        return 1
    fi

    printf '%d %d %d' "$r" "$g" "$b"
}

# RGB to Hex
ash_rgb_to_hex() {
    printf '#%02x%02x%02x' "$1" "$2" "$3"
}

# Calculate relative luminance (for contrast)
ash_luminance() {
    local r="$1" g="$2" b="$3"
    # sRGB linearization + luminance
    local rl gl bl
    rl=$(echo "scale=6; $r / 255" | bc -l 2>/dev/null || echo "0")
    gl=$(echo "scale=6; $g / 255" | bc -l 2>/dev/null || echo "0")
    bl=$(echo "scale=6; $b / 255" | bc -l 2>/dev/null || echo "0")
    printf '%s' "$rl $gl $bl"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 BADGE / CHIP RENDERING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Render a colored badge: [  LABEL  ]
ash_badge() {
    local label="$1"
    local color="${2:-mauve}"     # Palette color name for background
    local text_color="${3:-base}" # Palette color name for text

    _ash_colors_enabled || { printf '[%s]' "$label"; return 0; }

    ash_bold
    ash_fg "$text_color"
    ash_bg "$color"
    printf ' %s ' "$label"
    ash_reset
}

# Status badge variants
ash_badge_ok()      { ash_badge "${1:- OK }"     green   base; }
ash_badge_fail()    { ash_badge "${1:-FAIL}"      red     base; }
ash_badge_warn()    { ash_badge "${1:- WARN}"     yellow  base; }
ash_badge_info()    { ash_badge "${1:- INFO}"     blue    base; }
ash_badge_skip()    { ash_badge "${1:- SKIP}"     overlay0 base; }
ash_badge_new()     { ash_badge "${1:- NEW }"     green   base; }
ash_badge_hot()     { ash_badge "${1:- HOT }"     red     base; }
ash_badge_beta()    { ash_badge "${1:- BETA}"     peach   base; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 PALETTE UPDATE (called when theme changes)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_colors_load_palette() {
    local colors_json="${1:-$ASH_USER_THEME}"

    [[ ! -f "$colors_json" ]] && return 0

    # Parse and load palette from current theme
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        ASH_PALETTE["$key"]="$value"
    done < <(
        grep -oP '"[a-z0-9_]+" *: *"#[0-9a-fA-F]{6}"' "$colors_json" 2>/dev/null | \
        sed 's/"//g; s/ //g; s/#//' | \
        while IFS=':' read -r k v; do
            local r g b
            r=$(( 16#${v:0:2} ))
            g=$(( 16#${v:2:2} ))
            b=$(( 16#${v:4:2} ))
            printf '%s=%d %d %d\n' "$k" "$r" "$g" "$b"
        done
    )
}
