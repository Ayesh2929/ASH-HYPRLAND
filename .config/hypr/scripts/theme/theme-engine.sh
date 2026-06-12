#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.1.0 — THEME ENGINE (COMPLETE FINAL)              ║
# ║           Wallpaper → 24 Colors → 15+ App Targets                         ║
# ║           Supports: Hyprland, Waybar, Kitty, WezTerm, Alacritty,          ║
# ║           Rofi, Dunst, Hyprlock, GTK3/4, Fish, AGS, VSCode, Firefox       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_VERSION="3.1.0"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CONFIG_DIR="${HOME}/.config"
readonly COLORS_DIR="${CACHE_DIR}/colors"
readonly WALL_CACHE="${CACHE_DIR}/wallpaper"
readonly LOG_FILE="${CACHE_DIR}/logs/theme-engine.log"
readonly LOCK_FILE="/tmp/ash-theme-engine.lock"
readonly HISTORY_DIR="${CACHE_DIR}/theme-history"

# Output files — ALL apps
readonly COLORS_JSON="${COLORS_DIR}/current.json"
readonly COLORS_SHELL="${COLORS_DIR}/current.sh"
readonly HYPR_THEME="${CONFIG_DIR}/hypr/themes/active.conf"
readonly KITTY_THEME="${CONFIG_DIR}/kitty/themes/current.conf"
readonly WAYBAR_COLORS="${CONFIG_DIR}/waybar/styles/colors.css"
readonly ROFI_THEME="${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi"
readonly FISH_THEME="${CONFIG_DIR}/fish/themes/current.fish"
readonly GTK3_CSS="${CONFIG_DIR}/gtk-3.0/gtk.css"
readonly GTK4_CSS="${CONFIG_DIR}/gtk-4.0/gtk.css"
readonly ALACRITTY_CONF="${CONFIG_DIR}/alacritty/alacritty.toml"
readonly WEZTERM_COLORS="${CACHE_DIR}/wezterm-colors.json"
readonly VSCODE_THEME="${HOME}/.vscode/extensions/ash-dynamic/themes/ash-dark.json"
readonly FIREFOX_CSS="${HOME}/.mozilla"
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/ash-sddm"

log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()   { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()     { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn()   { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }
section(){ echo -e "\n  \033[1m\033[95m${1}\033[0m"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 LOCK MECHANISM
# ═══════════════════════════════════════════════════════════════════════════════

acquire_lock() {
    local timeout=30 waited=0
    while [[ -f "${LOCK_FILE}" ]]; do
        local lock_pid
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "0")
        if ! kill -0 "${lock_pid}" 2>/dev/null; then
            warn "Stale lock — removing"
            rm -f "${LOCK_FILE}"
            break
        fi
        (( waited >= timeout )) && { warn "Lock timeout"; exit 1; }
        sleep 1; ((waited++)) || true
    done
    echo $$ > "${LOCK_FILE}"
    trap "rm -f '${LOCK_FILE}'" EXIT INT TERM
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR EXTRACTION
# ═══════════════════════════════════════════════════════════════════════════════

extract_colors() {
    local wall="$1"

    if [[ -z "${wall}" ]] || [[ ! -f "${wall}" ]]; then
        warn "No wallpaper — using fallback"
        use_fallback
        return 0
    fi

    if ! command -v convert &>/dev/null; then
        warn "ImageMagick not found — using fallback"
        use_fallback
        return 0
    fi

    info "Extracting colors from: $(basename "${wall}")"

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
        warn "Extraction failed — using fallback"
        use_fallback
        return 0
    }

    local colors=()
    while IFS= read -r hex; do
        [[ "${hex}" =~ ^[0-9a-fA-F]{6}$ ]] && colors+=("${hex}")
    done <<< "${raw_colors}"

    (( ${#colors[@]} < 6 )) && {
        warn "Too few colors (${#colors[@]}) — using fallback"
        use_fallback
        return 0
    }

    assign_semantic_roles "${colors[@]}"
}

sort_by_luminance() {
    local colors=("$@")
    local weighted=()
    for hex in "${colors[@]}"; do
        local r g b lum
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))
        lum=$(( (2126 * r + 7152 * g + 722 * b) / 10000 ))
        weighted+=("${lum}:${hex}")
    done
    printf '%s\n' "${weighted[@]}" | sort -t: -k1 -n | cut -d: -f2
}

get_saturation() {
    local hex="$1"
    local r g b max min
    r=$(( 16#${hex:0:2} ))
    g=$(( 16#${hex:2:2} ))
    b=$(( 16#${hex:4:2} ))
    max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
    min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))
    (( max == 0 )) && echo "0" && return
    echo $(( (max - min) * 100 / max ))
}

assign_semantic_roles() {
    local sorted=()
    while IFS= read -r hex; do
        sorted+=("${hex}")
    done < <(sort_by_luminance "$@")

    local n=${#sorted[@]}

    # Backgrounds (darkest)
    BASE="${sorted[0]}"
    MANTLE="${sorted[1]:-${sorted[0]}}"
    CRUST="${sorted[2]:-${sorted[0]}}"

    # Surfaces
    SURFACE0="${sorted[3]:-${sorted[2]}}"
    SURFACE1="${sorted[4]:-${sorted[3]}}"
    SURFACE2="${sorted[5]:-${sorted[4]}}"

    # Overlays
    OVERLAY0="${sorted[6]:-${sorted[5]}}"
    OVERLAY1="${sorted[7]:-${sorted[6]}}"
    OVERLAY2="${sorted[8]:-${sorted[7]}}"

    # Find vibrant accents
    local sat_colors=()
    for hex in "${sorted[@]}"; do
        local sat
        sat=$(get_saturation "${hex}")
        (( sat >= 35 )) && sat_colors+=("${hex}")
    done

    if (( ${#sat_colors[@]} >= 3 )); then
        PRIMARY="${sat_colors[${#sat_colors[@]}-1]}"
        SECONDARY="${sat_colors[${#sat_colors[@]}-2]}"
        TERTIARY="${sat_colors[${#sat_colors[@]}-3]}"
    else
        PRIMARY="${sorted[$((n-1))]}"
        SECONDARY="${sorted[$((n-2))]}"
        TERTIARY="${sorted[$((n-3))]}"
    fi

    # Text (brightest)
    TEXT="${sorted[$((n-1))]}"
    SUBTEXT1="${sorted[$((n-2))]}"
    SUBTEXT0="${sorted[$((n-3))]}"
    MUTED="${sorted[$((n-4))]}"

    # State colors (semantic defaults — override if good match found)
    SUCCESS="a6e3a1"
    WARNING="f9e2af"
    ERR="f38ba8"
    INFO="89b4fa"

    for hex in "${sorted[@]}"; do
        local r g b
        r=$(( 16#${hex:0:2} ))
        g=$(( 16#${hex:2:2} ))
        b=$(( 16#${hex:4:2} ))
        (( g > r + 25 && g > b + 25 && g > 80 )) && SUCCESS="${hex}" || true
        (( r > g + 30 && r > b + 30 && r > 80 )) && ERR="${hex}" || true
        (( b > r + 20 && b > g + 20 && b > 80 )) && INFO="${hex}" || true
    done

    export BASE MANTLE CRUST SURFACE0 SURFACE1 SURFACE2
    export OVERLAY0 OVERLAY1 OVERLAY2 PRIMARY SECONDARY TERTIARY
    export TEXT SUBTEXT1 SUBTEXT0 MUTED SUCCESS WARNING ERR INFO
}

use_fallback() {
    BASE="1e1e2e"; MANTLE="181825"; CRUST="11111b"
    SURFACE0="313244"; SURFACE1="45475a"; SURFACE2="585b70"
    OVERLAY0="6c7086"; OVERLAY1="7f849c"; OVERLAY2="9399b2"
    PRIMARY="cba6f7"; SECONDARY="89b4fa"; TERTIARY="94e2d5"
    TEXT="cdd6f4"; SUBTEXT1="bac2de"; SUBTEXT0="a6adc8"; MUTED="7f849c"
    SUCCESS="a6e3a1"; WARNING="f9e2af"; ERR="f38ba8"; INFO="89b4fa"
    export BASE MANTLE CRUST SURFACE0 SURFACE1 SURFACE2
    export OVERLAY0 OVERLAY1 OVERLAY2 PRIMARY SECONDARY TERTIARY
    export TEXT SUBTEXT1 SUBTEXT0 MUTED SUCCESS WARNING ERR INFO
}

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 SAVE PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

save_palette() {
    local wall="${1:-}"
    mkdir -p "${COLORS_DIR}"

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

    cat > "${COLORS_SHELL}" << EOF
# ASH Theme Engine v${SCRIPT_VERSION} — Generated $(date '+%Y-%m-%d %H:%M:%S')
ASH_BASE="${BASE}"; ASH_MANTLE="${MANTLE}"; ASH_CRUST="${CRUST}"
ASH_SURFACE0="${SURFACE0}"; ASH_SURFACE1="${SURFACE1}"; ASH_SURFACE2="${SURFACE2}"
ASH_OVERLAY0="${OVERLAY0}"; ASH_OVERLAY1="${OVERLAY1}"; ASH_OVERLAY2="${OVERLAY2}"
ASH_PRIMARY="${PRIMARY}"; ASH_SECONDARY="${SECONDARY}"; ASH_TERTIARY="${TERTIARY}"
ASH_TEXT="${TEXT}"; ASH_SUBTEXT1="${SUBTEXT1}"; ASH_SUBTEXT0="${SUBTEXT0}"; ASH_MUTED="${MUTED}"
ASH_SUCCESS="${SUCCESS}"; ASH_WARNING="${WARNING}"; ASH_ERROR="${ERR}"; ASH_INFO="${INFO}"
export ASH_BASE ASH_MANTLE ASH_CRUST ASH_SURFACE0 ASH_SURFACE1 ASH_SURFACE2
export ASH_OVERLAY0 ASH_OVERLAY1 ASH_OVERLAY2 ASH_PRIMARY ASH_SECONDARY ASH_TERTIARY
export ASH_TEXT ASH_SUBTEXT1 ASH_SUBTEXT0 ASH_MUTED ASH_SUCCESS ASH_WARNING ASH_ERROR ASH_INFO
EOF

    ok "Palette saved"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 GENERATE THEMES FOR ALL APPS
# ═══════════════════════════════════════════════════════════════════════════════

# ── 1. HYPRLAND ───────────────────────────────────────────────────────────────
generate_hyprland() {
    info "Hyprland..."
    mkdir -p "$(dirname "${HYPR_THEME}")"
    cat > "${HYPR_THEME}" << EOF
# ASH Theme Engine — Hyprland — $(date '+%Y-%m-%d %H:%M:%S')
general {
    col.active_border   = rgba(${PRIMARY}ff) rgba(${SECONDARY}ff) rgba(${TERTIARY}ff) 60deg
    col.inactive_border = rgba(${SURFACE0}aa)
    col.group_border_active = rgba(${PRIMARY}ff)
    col.group_border        = rgba(${SURFACE1}ee)
}
decoration {
    shadow {
        color          = rgba(${BASE}cc)
        color_inactive = rgba(${BASE}88)
    }
}
group {
    col.border_active   = rgba(${PRIMARY}ff)
    col.border_inactive = rgba(${SURFACE1}ee)
    groupbar {
        col.active   = rgba(${PRIMARY}ff)
        col.inactive = rgba(${SURFACE0}ee)
    }
}
EOF
    ok "Hyprland ✓"
}

# ── 2. KITTY ──────────────────────────────────────────────────────────────────
generate_kitty() {
    info "Kitty..."
    mkdir -p "$(dirname "${KITTY_THEME}")"
    cat > "${KITTY_THEME}" << EOF
# ASH Theme Engine — Kitty — $(date '+%Y-%m-%d %H:%M:%S')
background              #${BASE}
foreground              #${TEXT}
cursor                  #${PRIMARY}
cursor_text_color       #${BASE}
selection_background    #${SURFACE1}
selection_foreground    #${TEXT}
active_border_color     #${PRIMARY}
inactive_border_color   #${SURFACE0}
tab_bar_background      #${MANTLE}
active_tab_background   #${PRIMARY}
active_tab_foreground   #${BASE}
inactive_tab_background #${SURFACE0}
inactive_tab_foreground #${SUBTEXT0}
color0   #${CRUST}
color8   #${SURFACE1}
color1   #${ERR}
color9   #${ERR}
color2   #${SUCCESS}
color10  #${SUCCESS}
color3   #${WARNING}
color11  #${WARNING}
color4   #${INFO}
color12  #${SECONDARY}
color5   #${PRIMARY}
color13  #${TERTIARY}
color6   #${TERTIARY}
color14  #${TERTIARY}
color7   #${SUBTEXT0}
color15  #${TEXT}
EOF
    # Live-reload kitty
    pkill -USR1 kitty 2>/dev/null || true
    ok "Kitty ✓"
}

# ── 3. ALACRITTY (DYNAMIC) ────────────────────────────────────────────────────
generate_alacritty() {
    [[ ! -f "${ALACRITTY_CONF}" ]] && return 0
    info "Alacritty..."

    python3 - << PYEOF 2>/dev/null
import re, pathlib

conf = pathlib.Path("${ALACRITTY_CONF}")
content = conf.read_text()

new_colors = """
[colors.primary]
background = "#${BASE}"
foreground = "#${TEXT}"

[colors.cursor]
text   = "#${BASE}"
cursor = "#${PRIMARY}"

[colors.selection]
text       = "#${BASE}"
background = "#${PRIMARY}"

[colors.normal]
black   = "#${CRUST}"
red     = "#${ERR}"
green   = "#${SUCCESS}"
yellow  = "#${WARNING}"
blue    = "#${INFO}"
magenta = "#${PRIMARY}"
cyan    = "#${TERTIARY}"
white   = "#${SUBTEXT0}"

[colors.bright]
black   = "#${SURFACE1}"
red     = "#${ERR}"
green   = "#${SUCCESS}"
yellow  = "#${WARNING}"
blue    = "#${SECONDARY}"
magenta = "#${PRIMARY}"
cyan    = "#${TERTIARY}"
white   = "#${TEXT}"
"""

# Remove old color sections
content = re.sub(r'\[colors.*?(?=\n\[(?!colors)|\Z)', '', content, flags=re.DOTALL)
content = content.rstrip() + '\n' + new_colors

conf.write_text(content)
print("  Alacritty updated")
PYEOF
    ok "Alacritty ✓"
}

# ── 4. WEZTERM ────────────────────────────────────────────────────────────────
generate_wezterm() {
    info "WezTerm..."
    mkdir -p "${CACHE_DIR}"
    cat > "${WEZTERM_COLORS}" << EOF
{
    "generated": "$(date -Iseconds)",
    "background":  "#${BASE}",
    "foreground":  "#${TEXT}",
    "cursor_bg":   "#${PRIMARY}",
    "cursor_fg":   "#${BASE}",
    "selection_bg": "#${SURFACE1}",
    "selection_fg": "#${TEXT}",
    "ansi": [
        "#${CRUST}","#${ERR}","#${SUCCESS}","#${WARNING}",
        "#${INFO}","#${PRIMARY}","#${TERTIARY}","#${SUBTEXT0}"
    ],
    "brights": [
        "#${SURFACE1}","#${ERR}","#${SUCCESS}","#${WARNING}",
        "#${SECONDARY}","#${PRIMARY}","#${TERTIARY}","#${TEXT}"
    ],
    "tab_bar": {
        "background": "#${MANTLE}",
        "active_tab_bg": "#${PRIMARY}",
        "active_tab_fg": "#${BASE}",
        "inactive_tab_bg": "#${SURFACE0}",
        "inactive_tab_fg": "#${SUBTEXT0}"
    }
}
EOF
    ok "WezTerm ✓ (reload with CTRL+SHIFT+R)"
}

# ── 5. WAYBAR CSS ─────────────────────────────────────────────────────────────
generate_waybar() {
    info "Waybar..."
    mkdir -p "$(dirname "${WAYBAR_COLORS}")"
    cat > "${WAYBAR_COLORS}" << EOF
/* ASH Theme Engine — Waybar — $(date '+%Y-%m-%d %H:%M:%S') */
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
@define-color bg         @base;
@define-color fg         @text;
@define-color accent     @primary;
@define-color border     @overlay0;
@define-color base-alpha      alpha(#${BASE}, 0.88);
@define-color surface0-alpha  alpha(#${SURFACE0}, 0.80);
@define-color primary-alpha   alpha(#${PRIMARY}, 0.80);
EOF
    # Signal Waybar to reload CSS
    pkill -SIGUSR2 waybar 2>/dev/null || true
    ok "Waybar ✓"
}

# ── 6. ROFI ───────────────────────────────────────────────────────────────────
generate_rofi() {
    info "Rofi..."
    mkdir -p "$(dirname "${ROFI_THEME}")"
    cat > "${ROFI_THEME}" << EOF
/* ASH Theme Engine — Rofi — $(date '+%Y-%m-%d %H:%M:%S') */
* {
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
    font:       "JetBrainsMono Nerd Font 12";
    background-color: transparent;
    text-color: @fg0;
    border-color: @border-col;
    outline-color: transparent;
}
window {
    background-color: @bg0;
    border: 2px solid;
    border-color: @accent;
    border-radius: 16px;
    padding: 20px;
    width: 680px;
    transparency: "real";
}
mainbox { background-color: transparent; spacing: 12px; }
inputbar {
    background-color: @bg1;
    border-radius: 12px;
    padding: 10px 14px;
    spacing: 8px;
    children: [ "prompt", "entry" ];
}
prompt { background-color: transparent; text-color: @accent; font: "JetBrainsMono Nerd Font Bold 13"; }
entry { background-color: transparent; text-color: @fg0; placeholder: "Search..."; placeholder-color: @fg2; }
listview { background-color: transparent; columns: 1; lines: 10; spacing: 4px; }
element { background-color: transparent; border-radius: 8px; padding: 8px 12px; }
element normal.normal { background-color: transparent; text-color: @fg0; }
element selected.normal { background-color: @selected; text-color: @accent; border: 1px solid; border-color: @accent; }
element-icon { background-color: transparent; size: 24px; }
element-text { background-color: transparent; text-color: inherit; }
EOF
    ok "Rofi ✓"
}

# ── 7. FISH SHELL ─────────────────────────────────────────────────────────────
generate_fish() {
    info "Fish..."
    mkdir -p "$(dirname "${FISH_THEME}")"
    cat > "${FISH_THEME}" << EOF
# ASH Theme Engine — Fish — $(date '+%Y-%m-%d %H:%M:%S')
set -g fish_color_normal           ${TEXT}
set -g fish_color_command          ${PRIMARY}
set -g fish_color_keyword          ${PRIMARY}
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
set -g fish_color_autosuggestion   ${MUTED}
set -g fish_color_cancel           ${ERR}
set -g fish_color_cwd              ${INFO}
set -g fish_color_user             ${PRIMARY}
set -g fish_color_host             ${SECONDARY}
set -g fish_color_status           ${ERR}
set -g fish_pager_color_prefix     ${PRIMARY}
set -g fish_pager_color_completion ${TEXT}
set -g fish_pager_color_description ${MUTED}
set -g fish_pager_color_progress   ${MUTED}
set -g fish_pager_color_selected_background --background=${SURFACE0}
EOF
    ok "Fish ✓"
}

# ── 8. DUNST ──────────────────────────────────────────────────────────────────
generate_dunst() {
    info "Dunst..."
    local dunstrc="${CONFIG_DIR}/dunst/dunstrc"
    mkdir -p "$(dirname "${dunstrc}")"

    cat > "${dunstrc}" << EOF
# ASH Theme Engine — Dunst — $(date '+%Y-%m-%d %H:%M:%S')
[global]
    monitor         = 0
    follow          = mouse
    width           = (300, 500)
    height          = (0, 400)
    origin          = top-right
    offset          = 16 52
    scale           = 0
    notification_limit = 5
    transparency    = 8
    gap_size        = 8
    padding         = 14
    horizontal_padding = 16
    text_icon_padding = 10
    frame_width     = 2
    frame_color     = #${PRIMARY}
    corner_radius   = 12
    icon_corner_radius = 6
    font            = JetBrainsMono Nerd Font 11
    markup          = full
    format          = "<b>%s</b>\n%b"
    alignment       = left
    icon_theme      = Papirus-Dark
    enable_recursive_icon_lookup = true
    icon_position   = left
    min_icon_size   = 32
    max_icon_size   = 64
    sticky_history  = yes
    history_length  = 50
    always_run_script = true
    mouse_left_click   = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click  = close_all
    sort            = yes
    progress_bar    = true
    progress_bar_height = 8
    layer           = top

[urgency_low]
    background  = "#${SURFACE0}ee"
    foreground  = "#${SUBTEXT0}"
    frame_color = "#${OVERLAY0}"
    timeout     = 6000

[urgency_normal]
    background  = "#${SURFACE0}ee"
    foreground  = "#${TEXT}"
    frame_color = "#${PRIMARY}"
    timeout     = 8000

[urgency_critical]
    background  = "#${ERR}22"
    foreground  = "#${TEXT}"
    frame_color = "#${ERR}"
    timeout     = 0
EOF

    # Restart dunst
    pkill -x dunst 2>/dev/null; sleep 0.2
    dunst &>/dev/null &
    disown
    ok "Dunst ✓"
}

# ── 9. SWAYNC ─────────────────────────────────────────────────────────────────
generate_swaync() {
    info "SwayNC..."
    local swaync_css="${CONFIG_DIR}/swaync/style.css"
    mkdir -p "$(dirname "${swaync_css}")"

    cat > "${swaync_css}" << EOF
/* ASH Theme Engine — SwayNC — $(date '+%Y-%m-%d %H:%M:%S') */
@define-color base    #${BASE};
@define-color surface #${SURFACE0};
@define-color primary #${PRIMARY};
@define-color text    #${TEXT};
@define-color muted   #${MUTED};
@define-color error   #${ERR};

* { all: unset; font-family: "JetBrainsMono Nerd Font", sans-serif; }

.notification-row { outline: none; padding: 4px 8px; }
.notification {
    background: alpha(@surface, 0.92);
    border: 1px solid alpha(@primary, 0.4);
    border-radius: 14px;
    padding: 14px;
    margin: 4px 8px;
    color: @text;
}
.notification.urgency-critical {
    border-color: @error;
    border-width: 2px;
}
.app-name { font-weight: bold; color: @primary; font-size: 12px; }
.summary  { font-size: 13px; font-weight: bold; color: @text; }
.body     { font-size: 12px; color: @muted; }
.control-center {
    background: alpha(@base, 0.95);
    border-left: 1px solid alpha(@primary, 0.2);
    padding: 12px;
}
.widget-title > label { font-size: 15px; font-weight: bold; color: @text; }
.widget-dnd > switch:checked { background: @primary; }
.widget-buttons-grid > flowbox > flowboxchild > button {
    background: alpha(@surface, 0.8);
    border-radius: 12px;
    color: @muted;
    padding: 10px 14px;
    margin: 4px;
    min-width: 80px;
}
.widget-buttons-grid > flowbox > flowboxchild > button:hover {
    background: alpha(@primary, 0.2);
    color: @primary;
}
EOF

    # Reload swaync
    pkill -SIGUSR1 swaync 2>/dev/null || true
    ok "SwayNC ✓"
}

# ── 10. HYPRLOCK ──────────────────────────────────────────────────────────────
generate_hyprlock() {
    info "Hyprlock..."
    local hyprlock_conf="${CONFIG_DIR}/hyprlock/hyprlock.conf"
    mkdir -p "$(dirname "${hyprlock_conf}")"

    local wall_path=""
    [[ -f "${WALL_CACHE}/last" ]] && wall_path=$(cat "${WALL_CACHE}/last")

    cat > "${hyprlock_conf}" << EOF
# ASH Theme Engine — Hyprlock — $(date '+%Y-%m-%d %H:%M:%S')

general {
    disable_loading_bar = false
    grace               = 0
    hide_cursor         = true
    fractional_scaling  = 2
}

background {
    monitor     =
    path        = ${wall_path}
    blur_passes = 4
    blur_size   = 10
    noise       = 0.012
    contrast    = 0.90
    brightness  = 0.70
    vibrancy    = 0.18
    color       = rgba(${BASE}ff)
}

input-field {
    monitor     =
    size        = 380, 60
    outline_thickness = 3
    dots_size   = 0.3
    dots_spacing = 0.18
    dots_center = true
    outer_color = rgba(${PRIMARY}ff)
    inner_color = rgba(${BASE}dd)
    font_color  = rgba(${TEXT}ff)
    check_color = rgba(${SUCCESS}ff)
    fail_color  = rgba(${ERR}ff)
    fail_text   = "❌ Wrong password"
    placeholder_text = "<span foreground='##${TEXT}' font_style='italic'>  Password</span>"
    rounding    = 16
    fade_on_empty = true
    position    = 0, -240
    halign      = center
    valign      = center
    capslock_color = rgba(${WARNING}ff)
}

label {
    monitor     =
    text        = cmd[update:1000] echo "<span font='JetBrainsMono Nerd Font Bold 78'>\$(date +'%H:%M')</span>"
    color       = rgba(${TEXT}ff)
    font_size   = 78
    font_family = JetBrainsMono Nerd Font Bold
    shadow_passes = 3
    shadow_size = 4
    shadow_color = rgba(${BASE}99)
    position    = 0, 80
    halign      = center
    valign      = center
}

label {
    monitor     =
    text        = cmd[update:60000] echo "\$(date +'%A, %B %d %Y')"
    color       = rgba(${SUBTEXT1}ee)
    font_size   = 18
    font_family = JetBrainsMono Nerd Font
    position    = 0, -10
    halign      = center
    valign      = center
}

image {
    monitor     =
    path        = \$HOME/.face
    size        = 90
    rounding    = -1
    border_size = 4
    border_color = rgba(${PRIMARY}ff)
    position    = 0, -150
    halign      = center
    valign      = center
}

label {
    monitor     =
    text        = \$USER
    color       = rgba(${PRIMARY}ff)
    font_size   = 16
    font_family = JetBrainsMono Nerd Font Bold
    position    = 0, -200
    halign      = center
    valign      = center
}

label {
    monitor     =
    text        = cmd[update:2000] \$HOME/.config/hyprlock/scripts/player.sh
    color       = rgba(${SUCCESS}ee)
    font_size   = 13
    font_family = JetBrainsMono Nerd Font
    position    = 0, 40
    halign      = center
    valign      = bottom
}

label {
    monitor     =
    text        = cmd[update:30000] \$HOME/.config/hyprlock/scripts/battery.sh
    color       = rgba(${TEXT}dd)
    font_size   = 13
    font_family = JetBrainsMono Nerd Font
    position    = 40, 70
    halign      = left
    valign      = bottom
}

label {
    monitor     =
    text        = cmd[update:10000] \$HOME/.config/hyprlock/scripts/network.sh
    color       = rgba(${TEXT}dd)
    font_size   = 13
    font_family = JetBrainsMono Nerd Font
    position    = 40, 40
    halign      = left
    valign      = bottom
}

label {
    monitor     =
    text        = cmd[update:5000] \$HOME/.config/hyprlock/scripts/sysinfo.sh
    color       = rgba(${TEXT}dd)
    font_size   = 12
    font_family = JetBrainsMono Nerd Font
    position    = -40, 40
    halign      = right
    valign      = bottom
}
EOF
    ok "Hyprlock ✓"
}

# ── 11. GTK 3/4 ───────────────────────────────────────────────────────────────
generate_gtk() {
    info "GTK 3/4..."
    mkdir -p "${CONFIG_DIR}/gtk-3.0" "${CONFIG_DIR}/gtk-4.0"

    local gtk_css
    gtk_css=$(cat << EOF
/* ASH Theme Engine — GTK — $(date '+%Y-%m-%d %H:%M:%S') */
@define-color theme_base_color         #${BASE};
@define-color theme_bg_color           #${MANTLE};
@define-color theme_fg_color           #${TEXT};
@define-color theme_selected_bg_color  #${PRIMARY};
@define-color theme_selected_fg_color  #${BASE};
@define-color borders                  #${OVERLAY0};

headerbar {
    background-color: #${MANTLE};
    border-bottom: 1px solid #${OVERLAY0};
    color: #${TEXT};
}

button {
    background-color: #${SURFACE0};
    color: #${TEXT};
    border-radius: 8px;
    border: 1px solid #${OVERLAY0};
    padding: 4px 12px;
}

button:hover {
    background-color: #${SURFACE1};
    border-color: #${PRIMARY};
}

button:active {
    background-color: #${PRIMARY};
    color: #${BASE};
}

entry {
    background-color: #${SURFACE0};
    color: #${TEXT};
    border-radius: 8px;
    border: 1px solid #${OVERLAY0};
    padding: 4px 8px;
    caret-color: #${PRIMARY};
}

entry:focus {
    border-color: #${PRIMARY};
    box-shadow: 0 0 0 2px alpha(#${PRIMARY}, 0.2);
}

menu, .menu, .context-menu {
    background-color: #${SURFACE0};
    border: 1px solid #${OVERLAY0};
    border-radius: 10px;
    padding: 4px;
    color: #${TEXT};
}

menuitem:hover {
    background-color: #${SURFACE1};
    border-radius: 6px;
    color: #${PRIMARY};
}

scrollbar slider {
    background-color: #${OVERLAY0};
    border-radius: 4px;
    min-width: 6px;
}

scrollbar slider:hover {
    background-color: #${PRIMARY};
}

tooltip {
    background-color: #${SURFACE0};
    color: #${TEXT};
    border: 1px solid #${OVERLAY0};
    border-radius: 8px;
    padding: 4px 8px;
}
EOF
)
    echo "${gtk_css}" > "${GTK3_CSS}"
    echo "${gtk_css}" > "${GTK4_CSS}"

    # Apply via gsettings
    local gtk_theme
    local mode_file="${CACHE_DIR}/theme-mode"
    local mode="dark"
    [[ -f "${mode_file}" ]] && mode=$(cat "${mode_file}")

    if [[ "${mode}" == "light" ]]; then
        gtk_theme="Catppuccin-Latte-Standard-Mauve-Light"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null || true
    else
        gtk_theme="Catppuccin-Mocha-Standard-Mauve-Dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    fi

    gsettings set org.gnome.desktop.interface gtk-theme "${gtk_theme}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "JetBrains Mono 11" 2>/dev/null || true
    ok "GTK 3/4 ✓"
}

# ── 12. VSCODE / VSCODIUM ─────────────────────────────────────────────────────
generate_vscode() {
    info "VSCode..."
    local ext_dir="${HOME}/.vscode/extensions/ash-dynamic-theme"
    local vscodium_ext="${HOME}/.vscode-oss/extensions/ash-dynamic-theme"

    mkdir -p "${ext_dir}/themes" "${vscodium_ext}/themes"

    cat > "${ext_dir}/package.json" << EOF
{
    "name": "ash-dynamic-theme",
    "displayName": "ASH Dynamic Theme",
    "description": "Auto-generated from your wallpaper colors",
    "version": "3.1.0",
    "engines": {"vscode": "^1.0.0"},
    "categories": ["Themes"],
    "contributes": {
        "themes": [{
            "label": "ASH Dynamic Dark",
            "uiTheme": "vs-dark",
            "path": "./themes/ash-dark.json"
        }]
    }
}
EOF

    local theme_json
    theme_json=$(cat << EOF
{
    "name": "ASH Dynamic Dark",
    "type": "dark",
    "colors": {
        "editor.background":                     "#${BASE}",
        "editor.foreground":                     "#${TEXT}",
        "editor.lineHighlightBackground":        "#${SURFACE0}44",
        "editor.selectionBackground":            "#${SURFACE1}",
        "editor.inactiveSelectionBackground":    "#${SURFACE0}",
        "editorCursor.foreground":               "#${PRIMARY}",
        "editorCursor.background":               "#${BASE}",
        "editorWhitespace.foreground":           "#${OVERLAY0}",
        "editorIndentGuide.background":          "#${SURFACE0}",
        "editorIndentGuide.activeBackground":    "#${PRIMARY}44",
        "editorLineNumber.foreground":           "#${OVERLAY0}",
        "editorLineNumber.activeForeground":     "#${PRIMARY}",
        "editorBracketMatch.background":         "#${PRIMARY}22",
        "editorBracketMatch.border":             "#${PRIMARY}",
        "editorError.foreground":                "#${ERR}",
        "editorWarning.foreground":              "#${WARNING}",
        "editorInfo.foreground":                 "#${INFO}",
        "editorHint.foreground":                 "#${SUCCESS}",
        "activityBar.background":                "#${MANTLE}",
        "activityBar.foreground":                "#${TEXT}",
        "activityBar.activeBorder":              "#${PRIMARY}",
        "activityBarBadge.background":           "#${PRIMARY}",
        "activityBarBadge.foreground":           "#${BASE}",
        "sideBar.background":                    "#${MANTLE}",
        "sideBar.foreground":                    "#${TEXT}",
        "sideBarTitle.foreground":               "#${PRIMARY}",
        "sideBarSectionHeader.background":       "#${SURFACE0}",
        "sideBarSectionHeader.foreground":       "#${TEXT}",
        "list.activeSelectionBackground":        "#${SURFACE1}",
        "list.activeSelectionForeground":        "#${TEXT}",
        "list.hoverBackground":                  "#${SURFACE0}",
        "list.highlightForeground":              "#${PRIMARY}",
        "statusBar.background":                  "#${CRUST}",
        "statusBar.foreground":                  "#${TEXT}",
        "statusBar.debuggingBackground":         "#${ERR}",
        "statusBar.noFolderBackground":          "#${MANTLE}",
        "statusBarItem.remoteBackground":        "#${PRIMARY}",
        "statusBarItem.remoteForeground":        "#${BASE}",
        "titleBar.activeBackground":             "#${MANTLE}",
        "titleBar.activeForeground":             "#${TEXT}",
        "titleBar.inactiveBackground":           "#${BASE}",
        "titleBar.inactiveForeground":           "#${MUTED}",
        "tab.activeBackground":                  "#${BASE}",
        "tab.activeForeground":                  "#${TEXT}",
        "tab.activeBorder":                      "#${PRIMARY}",
        "tab.inactiveBackground":                "#${MANTLE}",
        "tab.inactiveForeground":                "#${MUTED}",
        "tab.hoverBackground":                   "#${SURFACE0}",
        "editorGroupHeader.tabsBackground":      "#${MANTLE}",
        "panel.background":                      "#${MANTLE}",
        "panel.border":                          "#${SURFACE0}",
        "panelTitle.activeForeground":           "#${PRIMARY}",
        "panelTitle.activeBorder":               "#${PRIMARY}",
        "input.background":                      "#${SURFACE0}",
        "input.foreground":                      "#${TEXT}",
        "input.border":                          "#${OVERLAY0}",
        "input.placeholderForeground":           "#${MUTED}",
        "inputOption.activeBorder":              "#${PRIMARY}",
        "dropdown.background":                   "#${SURFACE0}",
        "dropdown.foreground":                   "#${TEXT}",
        "dropdown.border":                       "#${OVERLAY0}",
        "button.background":                     "#${PRIMARY}",
        "button.foreground":                     "#${BASE}",
        "button.hoverBackground":                "#${SECONDARY}",
        "badge.background":                      "#${PRIMARY}",
        "badge.foreground":                      "#${BASE}",
        "scrollbarSlider.background":            "#${OVERLAY0}44",
        "scrollbarSlider.hoverBackground":       "#${PRIMARY}44",
        "scrollbarSlider.activeBackground":      "#${PRIMARY}88",
        "progressBar.background":                "#${PRIMARY}",
        "focusBorder":                           "#${PRIMARY}",
        "selection.background":                  "#${PRIMARY}44",
        "widget.shadow":                         "#${BASE}88",
        "notifications.background":              "#${SURFACE0}",
        "notifications.border":                  "#${OVERLAY0}",
        "notificationCenterHeader.background":   "#${MANTLE}",
        "terminal.background":                   "#${BASE}",
        "terminal.foreground":                   "#${TEXT}",
        "terminal.ansiBlack":                    "#${CRUST}",
        "terminal.ansiRed":                      "#${ERR}",
        "terminal.ansiGreen":                    "#${SUCCESS}",
        "terminal.ansiYellow":                   "#${WARNING}",
        "terminal.ansiBlue":                     "#${INFO}",
        "terminal.ansiMagenta":                  "#${PRIMARY}",
        "terminal.ansiCyan":                     "#${TERTIARY}",
        "terminal.ansiWhite":                    "#${SUBTEXT0}",
        "terminal.ansiBrightBlack":              "#${SURFACE1}",
        "terminal.ansiBrightRed":                "#${ERR}",
        "terminal.ansiBrightGreen":              "#${SUCCESS}",
        "terminal.ansiBrightYellow":             "#${WARNING}",
        "terminal.ansiBrightBlue":               "#${SECONDARY}",
        "terminal.ansiBrightMagenta":            "#${PRIMARY}",
        "terminal.ansiBrightCyan":               "#${TERTIARY}",
        "terminal.ansiBrightWhite":              "#${TEXT}",
        "gitDecoration.addedResourceForeground":     "#${SUCCESS}",
        "gitDecoration.modifiedResourceForeground":  "#${INFO}",
        "gitDecoration.deletedResourceForeground":   "#${ERR}",
        "gitDecoration.untrackedResourceForeground": "#${SUCCESS}",
        "gitDecoration.ignoredResourceForeground":   "#${MUTED}"
    },
    "tokenColors": [
        {"scope": ["comment","punctuation.definition.comment"],
         "settings": {"foreground": "#${OVERLAY1}", "fontStyle": "italic"}},
        {"scope": ["keyword","keyword.control","keyword.operator"],
         "settings": {"foreground": "#${PRIMARY}"}},
        {"scope": ["string","string.quoted"],
         "settings": {"foreground": "#${SUCCESS}"}},
        {"scope": ["constant.numeric","constant.language"],
         "settings": {"foreground": "#${TERTIARY}"}},
        {"scope": ["entity.name.function","support.function"],
         "settings": {"foreground": "#${SECONDARY}", "fontStyle": "bold"}},
        {"scope": ["entity.name.type","support.type","entity.name.class"],
         "settings": {"foreground": "#${INFO}"}},
        {"scope": ["variable","variable.other"],
         "settings": {"foreground": "#${TEXT}"}},
        {"scope": ["variable.parameter"],
         "settings": {"foreground": "#${SUBTEXT1}", "fontStyle": "italic"}},
        {"scope": ["entity.name.tag","markup.heading"],
         "settings": {"foreground": "#${PRIMARY}"}},
        {"scope": ["support.class","entity.other.inherited-class"],
         "settings": {"foreground": "#${INFO}"}},
        {"scope": ["punctuation","meta.brace"],
         "settings": {"foreground": "#${SUBTEXT0}"}},
        {"scope": ["storage.type","storage.modifier"],
         "settings": {"foreground": "#${PRIMARY}", "fontStyle": "italic"}},
        {"scope": ["invalid","invalid.illegal"],
         "settings": {"foreground": "#${ERR}"}}
    ],
    "semanticHighlighting": true,
    "semanticTokenColors": {
        "function":       "#${SECONDARY}",
        "method":         "#${SECONDARY}",
        "class":          "#${INFO}",
        "type":           "#${INFO}",
        "variable":       "#${TEXT}",
        "parameter":      {"foreground": "#${SUBTEXT1}", "italic": true},
        "property":       "#${TEXT}",
        "enumMember":     "#${TERTIARY}",
        "keyword":        "#${PRIMARY}",
        "comment":        {"foreground": "#${OVERLAY1}", "italic": true},
        "string":         "#${SUCCESS}",
        "number":         "#${TERTIARY}",
        "operator":       "#${TEXT}",
        "namespace":      "#${INFO}",
        "macro":          "#${PRIMARY}"
    }
}
EOF
)

    echo "${theme_json}" > "${ext_dir}/themes/ash-dark.json"
    cp -r "${ext_dir}"/* "${vscodium_ext}/" 2>/dev/null || true
    ok "VSCode/VSCodium theme ✓"
    log "INFO" "VSCode: Set theme to 'ASH Dynamic Dark' in settings"
}

# ── 13. FIREFOX ───────────────────────────────────────────────────────────────
generate_firefox() {
    info "Firefox..."
    local ff_profiles
    ff_profiles=$(find "${HOME}/.mozilla/firefox" \
        -maxdepth 1 -name "*.default*" -type d 2>/dev/null)

    if [[ -z "${ff_profiles}" ]]; then
        log "INFO" "Firefox profile not found — skipping"
        return 0
    fi

    while IFS= read -r profile_dir; do
        local chrome_dir="${profile_dir}/chrome"
        mkdir -p "${chrome_dir}"

        cat > "${chrome_dir}/userChrome.css" << EOF
/* ASH Dynamic Firefox Theme — $(date '+%Y-%m-%d %H:%M:%S') */
/* Enable: about:config → toolkit.legacyUserProfileCustomizations.stylesheets = true */

:root {
    --ash-base:      #${BASE};
    --ash-mantle:    #${MANTLE};
    --ash-surface0:  #${SURFACE0};
    --ash-surface1:  #${SURFACE1};
    --ash-primary:   #${PRIMARY};
    --ash-secondary: #${SECONDARY};
    --ash-text:      #${TEXT};
    --ash-muted:     #${MUTED};
    --ash-error:     #${ERR};
    --ash-overlay0:  #${OVERLAY0};
}

/* Main toolbar */
#nav-bar {
    background-color: var(--ash-base) !important;
    border-bottom: 1px solid var(--ash-surface0) !important;
}

/* Tab bar */
#TabsToolbar {
    background-color: var(--ash-mantle) !important;
}

.tab-background:is([selected], [multiselected]) {
    background-image: none !important;
    background-color: var(--ash-surface0) !important;
}

.tab-label { color: var(--ash-text) !important; }
.tab-line   { background-color: var(--ash-primary) !important; }

/* URL bar */
#urlbar {
    background-color: var(--ash-surface0) !important;
    color: var(--ash-text) !important;
    border-radius: 8px !important;
}

#urlbar:focus-within {
    outline: 2px solid var(--ash-primary) !important;
    outline-offset: -2px !important;
}

/* Sidebar */
#sidebar-header {
    background-color: var(--ash-mantle) !important;
    color: var(--ash-text) !important;
}

/* Bookmarks toolbar */
#PersonalToolbar {
    background-color: var(--ash-mantle) !important;
    border-bottom: 1px solid var(--ash-surface0) !important;
}

/* Context menus */
menupopup, panel[type="arrow"] {
    --panel-background: var(--ash-surface0) !important;
    --panel-color: var(--ash-text) !important;
    --panel-border-color: var(--ash-overlay0) !important;
    border-radius: 10px !important;
}

menuitem:hover, .subviewbutton:hover {
    background-color: var(--ash-surface1) !important;
    color: var(--ash-primary) !important;
}
EOF

        cat > "${chrome_dir}/userContent.css" << EOF
/* ASH Dynamic Firefox Content Theme */
:root {
    color-scheme: dark !important;
}

/* New tab page */
body[moz-extension] {
    background-color: #${BASE} !important;
    color: #${TEXT} !important;
}
EOF

        ok "Firefox: $(basename "${profile_dir}") ✓"
    done <<< "${ff_profiles}"
}

# ── 14. SDDM LOGIN SCREEN ─────────────────────────────────────────────────────
generate_sddm() {
    info "SDDM..."

    # Check if SDDM directory is writable
    if ! sudo -n test -d /usr/share/sddm/themes 2>/dev/null; then
        log "INFO" "SDDM: skipped (no sudo access)"
        return 0
    fi

    sudo mkdir -p "${SDDM_THEME_DIR}"

    local wall_path=""
    [[ -f "${WALL_CACHE}/last" ]] && wall_path=$(cat "${WALL_CACHE}/last")

    # SDDM theme.conf
    sudo tee "${SDDM_THEME_DIR}/theme.conf" > /dev/null << EOF
[General]
background=${wall_path}
blur=true
recursiveBlurLoops=4
recursiveBlurRadius=8
accentColor=#${PRIMARY}
backgroundColor=#${BASE}
textColor=#${TEXT}
fontSize=14
font=JetBrains Mono
EOF

    # SDDM Main.qml (minimal)
    sudo tee "${SDDM_THEME_DIR}/Main.qml" > /dev/null << EOF
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    color: "#${BASE}"
    width: Screen.width
    height: Screen.height

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: "#${TEXT}"
            font.family: "JetBrains Mono"
            font.pixelSize: 72
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: "#${SUBTEXT1}"
            font.family: "JetBrains Mono"
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextField {
            id: passwordField
            placeholderText: "  Password"
            echoMode: TextInput.Password
            width: 320
            height: 50
            color: "#${TEXT}"
            placeholderTextColor: "#${MUTED}"
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
            background: Rectangle {
                color: "#${SURFACE0}"
                radius: 12
                border.color: passwordField.activeFocus ? "#${PRIMARY}" : "#${OVERLAY0}"
                border.width: passwordField.activeFocus ? 2 : 1
            }
            Keys.onReturnPressed: {
                sddm.login(userModel.data(userModel.index(0, 0), 257), text, sessionIndex)
            }
        }

        Button {
            text: "Unlock"
            width: 120
            height: 40
            anchors.horizontalCenter: parent.horizontalCenter
            background: Rectangle {
                color: parent.pressed ? "#${SECONDARY}" : "#${PRIMARY}"
                radius: 10
            }
            contentItem: Text {
                text: parent.text
                color: "#${BASE}"
                font.family: "JetBrains Mono"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: sddm.login(userModel.data(userModel.index(0, 0), 257),
                                  passwordField.text, sessionIndex)
        }
    }
}
EOF

    ok "SDDM ✓"
    log "INFO" "SDDM: Set theme 'ash-sddm' in /etc/sddm.conf.d/theme.conf"
}

# ── 15. TELEGRAM (via GTK colors) ─────────────────────────────────────────────
generate_telegram() {
    info "Telegram..."
    # Telegram uses system GTK theme — already handled by generate_gtk()
    # Additional: set environment variable for Telegram color scheme
    local telegram_cfg="${HOME}/.config/Telegram Desktop/tdata/settingss"
    # Telegram doesn't support custom CSS easily
    # The GTK theme will apply to its UI elements
    log "INFO" "Telegram: Uses GTK theme (already applied)"
    ok "Telegram via GTK ✓"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ WALLPAPER APPLICATION
# ═══════════════════════════════════════════════════════════════════════════════

apply_wallpaper() {
    local wall="$1"
    [[ -z "${wall}" ]] || [[ ! -f "${wall}" ]] && return 0

    info "Applying wallpaper..."

    # Start swww daemon if needed
    if ! pgrep -x swww-daemon &>/dev/null; then
        swww-daemon --format xrgb &>/dev/null &
        sleep 0.5
    fi

    if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
        swww img "${wall}" \
            --transition-type grow \
            --transition-pos "0.5,0.5" \
            --transition-duration 2.5 \
            --transition-fps 60 \
            --transition-bezier "0.34,1.56,0.64,1.0" \
            2>/dev/null || true
        ok "Wallpaper applied"
    fi

    # Save history
    mkdir -p "${WALL_CACHE}"
    echo "${wall}" > "${WALL_CACHE}/last"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${wall}" >> "${WALL_CACHE}/history"
    tail -100 "${WALL_CACHE}/history" > "${WALL_CACHE}/history.tmp" && \
        mv "${WALL_CACHE}/history.tmp" "${WALL_CACHE}/history" || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RELOAD ALL APPS
# ═══════════════════════════════════════════════════════════════════════════════

reload_all() {
    section "🔄 Reloading Applications"

    # Hyprland
    hyprctl reload 2>/dev/null && ok "Hyprland ✓" || warn "Hyprland reload failed"

    # Waybar (already signaled in generate_waybar)
    sleep 0.2
    pkill -SIGUSR2 waybar 2>/dev/null || {
        pkill -x waybar 2>/dev/null; sleep 0.3; waybar &>/dev/null & disown
    }

    # Kitty (already signaled in generate_kitty)
    sleep 0.2

    # Neovim — signal all instances
    if command -v nvim &>/dev/null; then
        # Write color reload signal
        touch "${CACHE_DIR}/nvim-reload-signal" 2>/dev/null || true
    fi

    # AGS widgets
    if command -v ags &>/dev/null && pgrep -x ags &>/dev/null; then
        ags -r "globalThis.reloadTheme && globalThis.reloadTheme()" 2>/dev/null || true
        ok "AGS ✓"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 SHOW PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

show_palette() {
    echo ""
    echo -e "  \033[1m🎨 Current Color Palette\033[0m"
    echo ""
    local entries=(
        "base:${BASE}" "mantle:${MANTLE}" "crust:${CRUST}"
        "surface0:${SURFACE0}" "surface1:${SURFACE1}" "surface2:${SURFACE2}"
        "primary:${PRIMARY}" "secondary:${SECONDARY}" "tertiary:${TERTIARY}"
        "text:${TEXT}" "success:${SUCCESS}" "warning:${WARNING}"
        "error:${ERR}" "info:${INFO}"
    )
    for entry in "${entries[@]}"; do
        local name="${entry%%:*}" hex="${entry##*:}"
        if [[ ${#hex} -eq 6 ]]; then
            local r g b
            r=$(( 16#${hex:0:2} )); g=$(( 16#${hex:2:2} )); b=$(( 16#${hex:4:2} ))
            printf "  \033[38;2;%d;%d;%dm██\033[0m  %-12s #%s\n" \
                "${r}" "${g}" "${b}" "${name}" "${hex}"
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local wall="${1:-}"
    local mode="${2:-apply}"

    echo ""
    echo -e "  \033[1m\033[95m🎨 ASH Theme Engine v${SCRIPT_VERSION}\033[0m"
    echo -e "  \033[2mMode: ${mode} | Wall: $(basename "${wall:-none}")\033[0m"
    echo ""

    mkdir -p "${COLORS_DIR}" "${WALL_CACHE}" "${HISTORY_DIR}" "${CACHE_DIR}/logs"
    acquire_lock

    case "${mode}" in
        apply | "")
            # Save theme history snapshot
            "${HOME}/.config/hypr/scripts/theme/theme-undo.sh" save "pre-apply" \
                &>/dev/null || true

            section "🎨 Extracting Colors"
            extract_colors "${wall}"
            save_palette "${wall}"

            section "🎨 Generating All Themes"
            generate_hyprland
            generate_kitty
            generate_alacritty
            generate_wezterm
            generate_waybar
            generate_rofi
            generate_fish
            generate_dunst
            generate_swaync
            generate_hyprlock
            generate_gtk
            generate_vscode
            generate_firefox
            generate_sddm 2>/dev/null || true

            section "🖼️ Wallpaper"
            apply_wallpaper "${wall}"

            section "🔄 Reloading"
            reload_all

            show_palette

            notify-send "🎨 ASH Theme Applied" \
                "$(basename "${wall:-wallpaper")" \
                --icon="${wall:-dialog-information}" \
                --app-name="ASH Theme" \
                --expire-time=3000 \
                2>/dev/null || true

            echo -e "  \033[92m\033[1m✓ Theme applied to 14 apps!\033[0m"
            ;;

        boot)
            local last=""
            [[ -f "${WALL_CACHE}/last" ]] && last=$(cat "${WALL_CACHE}/last")
            if [[ -n "${last}" ]] && [[ -f "${last}" ]]; then
                main "${last}" "apply"
            else
                warn "No previous wallpaper — applying fallback"
                use_fallback
                save_palette ""
                generate_hyprland; generate_kitty; generate_waybar
                generate_rofi; generate_fish; generate_dunst
                generate_gtk
                reload_all
            fi
            ;;

        reapply)
            if [[ -f "${COLORS_SHELL}" ]]; then
                # shellcheck source=/dev/null
                source "${COLORS_SHELL}" 2>/dev/null || use_fallback
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
                export BASE MANTLE CRUST SURFACE0 SURFACE1 SURFACE2
                export OVERLAY0 OVERLAY1 OVERLAY2 PRIMARY SECONDARY TERTIARY
                export TEXT SUBTEXT1 SUBTEXT0 MUTED SUCCESS WARNING ERR INFO
            else
                use_fallback
            fi

            section "🎨 Regenerating All Themes"
            generate_hyprland; generate_kitty; generate_alacritty
            generate_wezterm; generate_waybar; generate_rofi
            generate_fish; generate_dunst; generate_swaync
            generate_hyprlock; generate_gtk; generate_vscode
            generate_firefox; generate_sddm 2>/dev/null || true

            section "🔄 Reloading"
            reload_all
            ok "Themes reapplied to 14 apps!"
            ;;

        test)
            extract_colors "${wall}"
            show_palette
            ;;

        export)
            [[ -f "${COLORS_JSON}" ]] && cat "${COLORS_JSON}" || \
                { warn "No palette — run ash theme pick first"; exit 1; }
            ;;
    esac

    log "INFO" "Theme engine complete: mode=${mode} wall=${wall:-none}"
}

main "$@"