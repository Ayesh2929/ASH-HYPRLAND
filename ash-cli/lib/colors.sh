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

    # Re-derive every token from the new palette. Without this a theme change
    # only affected output that called the ash_c_* helpers directly, while the
    # ~1,100 call sites using ${ASH_PRIMARY} kept the colours they were given at
    # load time.
    ash_colors_init_tokens
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 DESIGN TOKENS
#
# The rest of the codebase writes colour into its output with bare variables:
#
#     printf '%s%s PASS%s\n' "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}"
#
# but nothing ever defined those names. Around 1,100 call sites referenced
# ${RST}, ${ASH_PRIMARY}, ${ICO_SUCCESS} and friends — all of which expanded to
# the empty string (or, under `set -u`, aborted the command with
# "BOLD: unbound variable"). This section is the missing definition layer.
#
# The tokens are initialised at load time and RE-INITIALISED whenever the
# palette changes, so `ash theme apply` recolours everything that uses them
# without a restart. When colour is disabled each token is set to the empty
# string rather than being left unset: unset would trip `set -u`, and escape
# codes in piped output break log parsing and `--json` consumers.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Map a palette role to a foreground escape, or "" when colour is off.
_ash_token() {
    local role="$1"
    _ash_colors_enabled || return 0
    local rgb="${ASH_PALETTE[${role}]:-}"
    [[ -n "${rgb}" ]] || return 0
    # shellcheck disable=SC2086
    set -- ${rgb}
    ash_fg_rgb "$1" "$2" "$3"
}

ash_colors_init_tokens() {
    # ── Text styling ──────────────────────────────────────────────────────────
    if _ash_colors_enabled; then
        RST=$'\033[0m'
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        ITALIC=$'\033[3m'
        UNDERLINE=$'\033[4m'
        REVERSE=$'\033[7m'
        STRIKE=$'\033[9m'
    else
        RST="" BOLD="" DIM="" ITALIC="" UNDERLINE="" REVERSE="" STRIKE=""
    fi

    # ── Semantic colours ──────────────────────────────────────────────────────
    # PRIMARY drives headings, ACCENT drives interactive words, MUTED carries
    # secondary text and hints. The four status colours must stay perceptually
    # distinct from one another; they come from roles chosen for that purpose
    # rather than from the theme's own accent, so a red-themed palette still
    # shows green for success.
    ASH_PRIMARY="$(_ash_token lavender)"
    ASH_ACCENT="$(_ash_token mauve)"
    ASH_MUTED="$(_ash_token overlay1)"
    ASH_SUCCESS="$(_ash_token green)"
    ASH_WARNING="$(_ash_token yellow)"
    ASH_ERROR="$(_ash_token red)"
    ASH_INFO="$(_ash_token sky)"
    FG_BBLACK="$(_ash_token overlay0)"

    # Icons are independent of the colour state; one definition, in one place.
    ash_colors_init_icons

    # Module-level roles shared by snapshot/, config/ and doctor/.
    ash_colors_init_semantic_tokens

    # Every token above is a plain global so that call sites can interpolate it
    # directly; export the ones that are useful to child processes.
    export RST BOLD DIM ITALIC UNDERLINE REVERSE STRIKE
}

# Module-level semantic tokens.
#
# Same story as the tokens above, one layer down: snapshot/, config/ and doctor/
# all render snapshot tables and diffs with ${SNAP_COLOR_*}, and none of them
# defined them. They live here rather than in a module because four modules
# share the vocabulary, and a colour defined in one module is a colour the other
# three cannot see.
#
# DIFF_ADD/DEL/MOD deliberately mirror the git convention (green/red/yellow)
# instead of using the theme accent, because those three are read as a set and
# their meaning is fixed by custom.
ash_colors_init_semantic_tokens() {
    SNAP_COLOR_ID="$(_ash_token sapphire)"
    SNAP_COLOR_NAME="$(_ash_token lavender)"
    SNAP_COLOR_SIZE="$(_ash_token teal)"
    SNAP_COLOR_TAG="$(_ash_token pink)"
    SNAP_COLOR_DATE="$(_ash_token overlay2)"
    SNAP_COLOR_PINNED="$(_ash_token peach)"

    SNAP_COLOR_DIFF_ADD="$(_ash_token green)"
    SNAP_COLOR_DIFF_DEL="$(_ash_token red)"
    SNAP_COLOR_DIFF_MOD="$(_ash_token yellow)"

    export SNAP_COLOR_ID SNAP_COLOR_NAME SNAP_COLOR_SIZE SNAP_COLOR_TAG \
           SNAP_COLOR_DATE SNAP_COLOR_PINNED \
           SNAP_COLOR_DIFF_ADD SNAP_COLOR_DIFF_DEL SNAP_COLOR_DIFF_MOD
}

# Display width in terminal COLUMNS, not bytes or characters.
#
# `printf '%-38s'` measures BYTES. An emoji is 3-4 bytes for 2 columns, "│" is
# 3 bytes for 1 column, and a combining accent is 2 bytes for 0 — so every row
# containing one was padded by the wrong amount and the columns wandered.
#
# `wc -L` reports the maximum display width of a line, which for a single-line
# string is exactly what is wanted: it counts leading AND trailing spaces, and
# it resolves character widths the same way Python's east-asian-width does.
# (Verified: "✅"→2, "⚠️"→1, "café"→4, "├─"→2.)
#
# ANSI escape sequences are zero-width and are stripped before measuring.
_ash_display_width() {
    local str="$1"

    # Strip SGR sequences. Done with a bash regex rather than sed: the escape
    # needs \x1b through two layers of quoting, and a single missed backslash
    # makes sed fail silently and return an empty string — which reads as a
    # width of zero and pads every row as if it were blank.
    while [[ "$str" =~ $'\033\[[0-9;]*[a-zA-Z]' ]]; do
        str="${str/"${BASH_REMATCH[0]}"/}"
    done

    local w
    if w="$(printf '%s' "$str" | LC_ALL=C.UTF-8 wc -L 2>/dev/null)" && [[ -n "$w" ]]; then
        printf '%s' "$w"
    else
        # Without a UTF-8 locale, or on a system whose wc has no -L, fall back
        # to a byte count. Alignment is imperfect for wide glyphs but nothing
        # breaks.
        printf '%s' "${#str}"
    fi
}

# Pad a string out to a display width, truncating with an ellipsis if it is
# longer. The cut point is computed in characters, so multi-byte glyphs are
# never sliced in half.
_ash_pad() {
    local str="$1" want="$2"
    local w; w="$(_ash_display_width "$str")"

    if (( w > want )); then
        # Drop one character than the overflow, then add the ellipsis.
        local over=$(( w - want + 1 ))
        local chars=${#str}
        local keep=$(( chars - over ))
        (( keep < 1 )) && keep=1
        str="${str:0:keep}…"
        w="$(_ash_display_width "$str")"
    fi

    printf '%s' "$str"
    local i
    for (( i = w; i < want; i++ )); do printf ' '; done
}

# Icons are only a naming concern, so initialise them independently of the
# colour state — script output without colour still wants its labels.
ash_colors_init_icons() {
    if [[ "${ASH_FLAG_NO_UNICODE:-0}" -eq 1 ]]; then
        ICO_SUCCESS="[OK]" ICO_WARN="[!]"  ICO_ERROR="[X]"  ICO_INFO="[i]"
        ICO_SNAPSHOT="[S]" ICO_CREATE="[+]" ICO_RESTORE="[R]" ICO_DELETE="[-]"
        ICO_LIST="[=]" ICO_FILE="[f]" ICO_FOLDER="[d]" ICO_LOCK="[*]"
        ICO_TAG="[#]" ICO_CLOCK="[t]" ICO_EXPORT="[>]" ICO_DIFF="[~]"
        ICO_PIN="[P]" ICO_SKIP="[~]"
    else
        ICO_SUCCESS="✅" ICO_WARN="⚠️" ICO_ERROR="❌" ICO_INFO="ℹ️"
        ICO_SNAPSHOT="📸" ICO_CREATE="✨" ICO_RESTORE="♻️" ICO_DELETE="🗑️"
        ICO_LIST="📋" ICO_FILE="📄" ICO_FOLDER="📁" ICO_LOCK="🔒"
        ICO_TAG="🏷️ " ICO_CLOCK="🕐" ICO_EXPORT="📤" ICO_DIFF="🔀"
        ICO_PIN="📌" ICO_SKIP="▪️"
    fi
}

# Initialise now, so that a script which sources colours.sh and immediately
# formats output has every token available.
ash_colors_init_tokens
