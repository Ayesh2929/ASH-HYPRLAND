#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — LIGHT/DARK MODE TOGGLE                       ║
# ║           Switch between light and dark themes with auto-detection         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/theme-mode.log"
readonly MODE_FILE="${CACHE_DIR}/theme-mode"
readonly CONFIG_DIR="${HOME}/.config"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 LIGHT PALETTE (Catppuccin Latte)
# ═══════════════════════════════════════════════════════════════════════════════

readonly -A LIGHT_PALETTE=(
    [base]="eff1f5"
    [mantle]="e6e9ef"
    [crust]="dce0e8"
    [surface0]="ccd0da"
    [surface1]="bcc0cc"
    [surface2]="acb0be"
    [overlay0]="9ca0b0"
    [overlay1]="8c8fa1"
    [overlay2]="7c7f93"
    [primary]="8839ef"
    [secondary]="1e66f5"
    [tertiary]="179299"
    [text]="4c4f69"
    [subtext1]="5c5f77"
    [subtext0]="6c6f85"
    [muted]="9ca0b0"
    [success]="40a02b"
    [warning]="df8e1d"
    [error]="d20f39"
    [info]="1e66f5"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🌙 DARK PALETTE (Catppuccin Mocha — default)
# ═══════════════════════════════════════════════════════════════════════════════

readonly -A DARK_PALETTE=(
    [base]="1e1e2e"
    [mantle]="181825"
    [crust]="11111b"
    [surface0]="313244"
    [surface1]="45475a"
    [surface2]="585b70"
    [overlay0]="6c7086"
    [overlay1]="7f849c"
    [overlay2]="9399b2"
    [primary]="cba6f7"
    [secondary]="89b4fa"
    [tertiary]="94e2d5"
    [text]="cdd6f4"
    [subtext1]="bac2de"
    [subtext0]="a6adc8"
    [muted]="7f849c"
    [success]="a6e3a1"
    [warning]="f9e2af"
    [error]="f38ba8"
    [info]="89b4fa"
)

get_current_mode() {
    [[ -f "${MODE_FILE}" ]] && cat "${MODE_FILE}" || echo "dark"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 APPLY MODE
# ═══════════════════════════════════════════════════════════════════════════════

apply_mode() {
    local mode="$1"  # light or dark

    info "Applying ${mode} mode..."

    # Save theme history first
    "${HOME}/.config/hypr/scripts/theme/theme-undo.sh" save "${mode}-mode" \
        &>/dev/null || true

    # Select palette
    local -n palette
    if [[ "${mode}" == "light" ]]; then
        declare -n palette=LIGHT_PALETTE
    else
        declare -n palette=DARK_PALETTE
    fi

    # ── Generate color files ──────────────────────────────────────────────────
    mkdir -p "${CACHE_DIR}/colors"

    # Generate JSON
    python3 - << EOF 2>/dev/null
import json
from datetime import datetime

palette = {
    "base":      "${palette[base]}",
    "mantle":    "${palette[mantle]}",
    "crust":     "${palette[crust]}",
    "surface0":  "${palette[surface0]}",
    "surface1":  "${palette[surface1]}",
    "surface2":  "${palette[surface2]}",
    "overlay0":  "${palette[overlay0]}",
    "overlay1":  "${palette[overlay1]}",
    "overlay2":  "${palette[overlay2]}",
    "primary":   "${palette[primary]}",
    "secondary": "${palette[secondary]}",
    "tertiary":  "${palette[tertiary]}",
    "text":      "${palette[text]}",
    "subtext1":  "${palette[subtext1]}",
    "subtext0":  "${palette[subtext0]}",
    "muted":     "${palette[muted]}",
    "success":   "${palette[success]}",
    "warning":   "${palette[warning]}",
    "error":     "${palette[error]}",
    "info":      "${palette[info]}",
}

data = {
    "_meta": {"mode": "${mode}", "generated": datetime.now().isoformat()},
    "backgrounds": {
        "base":   "#" + palette["base"],
        "mantle": "#" + palette["mantle"],
        "crust":  "#" + palette["crust"],
    },
    "surfaces": {
        "surface0": "#" + palette["surface0"],
        "surface1": "#" + palette["surface1"],
        "surface2": "#" + palette["surface2"],
    },
    "overlays": {
        "overlay0": "#" + palette["overlay0"],
        "overlay1": "#" + palette["overlay1"],
        "overlay2": "#" + palette["overlay2"],
    },
    "accents": {
        "primary":   "#" + palette["primary"],
        "secondary": "#" + palette["secondary"],
        "tertiary":  "#" + palette["tertiary"],
    },
    "text": {
        "text":     "#" + palette["text"],
        "subtext1": "#" + palette["subtext1"],
        "subtext0": "#" + palette["subtext0"],
        "muted":    "#" + palette["muted"],
    },
    "states": {
        "success": "#" + palette["success"],
        "warning": "#" + palette["warning"],
        "error":   "#" + palette["error"],
        "info":    "#" + palette["info"],
    }
}

with open("${CACHE_DIR}/colors/current.json", "w") as f:
    json.dump(data, f, indent=2)
print("Colors JSON generated")
EOF

    # Generate shell file
    cat > "${CACHE_DIR}/colors/current.sh" << EOF
# ASH ${mode^} Theme — Generated $(date)
ASH_BASE="${palette[base]}"
ASH_MANTLE="${palette[mantle]}"
ASH_CRUST="${palette[crust]}"
ASH_SURFACE0="${palette[surface0]}"
ASH_SURFACE1="${palette[surface1]}"
ASH_SURFACE2="${palette[surface2]}"
ASH_OVERLAY0="${palette[overlay0]}"
ASH_OVERLAY1="${palette[overlay1]}"
ASH_OVERLAY2="${palette[overlay2]}"
ASH_PRIMARY="${palette[primary]}"
ASH_SECONDARY="${palette[secondary]}"
ASH_TERTIARY="${palette[tertiary]}"
ASH_TEXT="${palette[text]}"
ASH_SUBTEXT1="${palette[subtext1]}"
ASH_SUBTEXT0="${palette[subtext0]}"
ASH_MUTED="${palette[muted]}"
ASH_SUCCESS="${palette[success]}"
ASH_WARNING="${palette[warning]}"
ASH_ERROR="${palette[error]}"
ASH_INFO="${palette[info]}"
ASH_MODE="${mode}"
export ASH_BASE ASH_MANTLE ASH_CRUST ASH_SURFACE0 ASH_SURFACE1 ASH_SURFACE2
export ASH_OVERLAY0 ASH_OVERLAY1 ASH_OVERLAY2 ASH_PRIMARY ASH_SECONDARY
export ASH_TERTIARY ASH_TEXT ASH_SUBTEXT1 ASH_SUBTEXT0 ASH_MUTED
export ASH_SUCCESS ASH_WARNING ASH_ERROR ASH_INFO ASH_MODE
EOF

    ok "Color palette generated"

    # ── Apply Hyprland theme ──────────────────────────────────────────────────
    local P="${palette[primary]}"
    local S="${palette[secondary]}"
    local T="${palette[tertiary]}"
    local BASE="${palette[base]}"
    local SURF="${palette[surface0]}"

    cat > "${CONFIG_DIR}/hypr/themes/active.conf" << EOF
# ASH ${mode^} Theme — Generated $(date)
general {
    col.active_border   = rgba(${P}ff) rgba(${S}ff) rgba(${T}ff) 60deg
    col.inactive_border = rgba(${SURF}aa)
    col.group_border_active = rgba(${P}ff)
    col.group_border        = rgba(${SURF}ee)
}
decoration {
    shadow {
        color          = rgba(${BASE}cc)
        color_inactive = rgba(${BASE}88)
    }
}
group {
    col.border_active   = rgba(${P}ff)
    col.border_inactive = rgba(${SURF}ee)
    groupbar {
        col.active   = rgba(${P}ff)
        col.inactive = rgba(${SURF}ee)
    }
}
EOF

    # ── Apply Waybar colors ───────────────────────────────────────────────────
    cat > "${CONFIG_DIR}/waybar/styles/colors.css" << EOF
/* ASH ${mode^} Theme — Generated $(date) */
@define-color base       #${palette[base]};
@define-color mantle     #${palette[mantle]};
@define-color crust      #${palette[crust]};
@define-color surface0   #${palette[surface0]};
@define-color surface1   #${palette[surface1]};
@define-color surface2   #${palette[surface2]};
@define-color overlay0   #${palette[overlay0]};
@define-color overlay1   #${palette[overlay1]};
@define-color overlay2   #${palette[overlay2]};
@define-color primary    #${palette[primary]};
@define-color secondary  #${palette[secondary]};
@define-color tertiary   #${palette[tertiary]};
@define-color text       #${palette[text]};
@define-color subtext1   #${palette[subtext1]};
@define-color subtext0   #${palette[subtext0]};
@define-color muted      #${palette[muted]};
@define-color success    #${palette[success]};
@define-color warning    #${palette[warning]};
@define-color error      #${palette[error]};
@define-color info       #${palette[info]};
@define-color bg         @base;
@define-color fg         @text;
@define-color accent     @primary;
@define-color border     @overlay0;
@define-color base-alpha  alpha(#${palette[base]}, 0.88);
EOF

    ok "Waybar colors generated"

    # ── Apply Kitty colors ────────────────────────────────────────────────────
    cat > "${CONFIG_DIR}/kitty/themes/current.conf" << EOF
# ASH ${mode^} Theme — Generated $(date)
background              #${palette[base]}
foreground              #${palette[text]}
cursor                  #${palette[primary]}
cursor_text_color       #${palette[base]}
selection_background    #${palette[surface1]}
selection_foreground    #${palette[text]}
active_border_color     #${palette[primary]}
inactive_border_color   #${palette[surface0]}
tab_bar_background      #${palette[mantle]}
active_tab_background   #${palette[primary]}
active_tab_foreground   #${palette[base]}
inactive_tab_background #${palette[surface0]}
inactive_tab_foreground #${palette[subtext0]}
color0   #${palette[crust]}
color8   #${palette[surface1]}
color1   #${palette[error]}
color9   #${palette[error]}
color2   #${palette[success]}
color10  #${palette[success]}
color3   #${palette[warning]}
color11  #${palette[warning]}
color4   #${palette[info]}
color12  #${palette[secondary]}
color5   #${palette[primary]}
color13  #${palette[tertiary]}
color6   #${palette[tertiary]}
color14  #${palette[tertiary]}
color7   #${palette[subtext0]}
color15  #${palette[text]}
EOF

    ok "Kitty theme generated"

    # ── Apply Fish colors ─────────────────────────────────────────────────────
    cat > "${CONFIG_DIR}/fish/themes/current.fish" << EOF
# ASH ${mode^} Theme — Generated $(date)
set -g fish_color_normal           ${palette[text]}
set -g fish_color_command          ${palette[primary]}
set -g fish_color_keyword          ${palette[primary]}
set -g fish_color_quote            ${palette[success]}
set -g fish_color_redirection      ${palette[tertiary]}
set -g fish_color_end              ${palette[text]}
set -g fish_color_error            ${palette[error]}
set -g fish_color_param            ${palette[subtext1]}
set -g fish_color_comment          ${palette[overlay0]}
set -g fish_color_autosuggestion   ${palette[overlay0]}
set -g fish_color_operator         ${palette[secondary]}
set -g fish_color_escape           ${palette[tertiary]}
set -g fish_color_cwd              ${palette[info]}
set -g fish_color_user             ${palette[primary]}
set -g fish_color_host             ${palette[secondary]}
set -g fish_color_status           ${palette[error]}
EOF

    ok "Fish colors generated"

    # ── Apply GTK preference ──────────────────────────────────────────────────
    local gtk_scheme
    [[ "${mode}" == "light" ]] && gtk_scheme="prefer-light" || gtk_scheme="prefer-dark"
    gsettings set org.gnome.desktop.interface color-scheme "${gtk_scheme}" 2>/dev/null || true

    local gtk_theme
    if [[ "${mode}" == "light" ]]; then
        gtk_theme="Catppuccin-Latte-Standard-Mauve-Light"
    else
        gtk_theme="Catppuccin-Mocha-Standard-Mauve-Dark"
    fi
    gsettings set org.gnome.desktop.interface gtk-theme "${gtk_theme}" 2>/dev/null || true
    ok "GTK theme: ${gtk_theme}"

    # ── Save mode ─────────────────────────────────────────────────────────────
    echo "${mode}" > "${MODE_FILE}"

    # ── Reload all components ─────────────────────────────────────────────────
    info "Reloading..."
    hyprctl reload 2>/dev/null || true
    sleep 0.2
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -USR1 kitty 2>/dev/null || true

    local mode_emoji
    [[ "${mode}" == "light" ]] && mode_emoji="☀️" || mode_emoji="🌙"

    notify-send "${mode_emoji} ${mode^} Mode" \
        "Switched to ${mode} theme" \
        --app-name="ASH Theme" \
        --expire-time=3000 \
        2>/dev/null || true

    ok "${mode^} mode applied!"
    log "INFO" "Mode applied: ${mode}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 AUTO MODE (based on time)
# ═══════════════════════════════════════════════════════════════════════════════

auto_mode() {
    local hour
    hour=$(date +%H)

    local mode="dark"
    if (( hour >= 7 && hour < 19 )); then
        mode="light"
    fi

    local current
    current=$(get_current_mode)

    if [[ "${mode}" != "${current}" ]]; then
        info "Auto switching to ${mode} mode (hour: ${hour})"
        apply_mode "${mode}"
    else
        info "Already in ${mode} mode — no change needed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"
    local arg="${2:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        light)    apply_mode "light" ;;
        dark)     apply_mode "dark" ;;
        toggle | t)
            local current
            current=$(get_current_mode)
            [[ "${current}" == "light" ]] && apply_mode "dark" || apply_mode "light"
            ;;
        auto)     auto_mode ;;
        status | get)
            local mode
            mode=$(get_current_mode)
            local emoji
            [[ "${mode}" == "light" ]] && emoji="☀️" || emoji="🌙"
            echo "${emoji} Current mode: ${mode}"
            ;;
        schedule)
            # Setup systemd timer for auto mode
            cat > "${HOME}/.config/systemd/user/ash-auto-theme.service" << 'EOF'
[Unit]
Description=ASH Auto Theme Mode Switcher

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/theme/light-theme.sh auto
EOF
            cat > "${HOME}/.config/systemd/user/ash-auto-theme.timer" << 'EOF'
[Unit]
Description=ASH Auto Theme — switch every hour

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
            systemctl --user daemon-reload
            systemctl --user enable --now ash-auto-theme.timer
            ok "Auto theme switching enabled (checks every hour)"
            ;;
        *)
            echo "Usage: light-theme.sh [light|dark|toggle|auto|status|schedule]"
            exit 1
            ;;
    esac
}

main "$@"