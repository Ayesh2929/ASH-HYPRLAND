#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — CONTEXT-AWARE AUTO THEMING                   ║
# ║           App-based automatic theme switching                              ║
# ║           UNIQUE: Desktop theme changes based on what app is focused       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: context-theme.sh [enable|disable|toggle|status|config]
#
# HOW IT WORKS:
#   1. Watches active window via Hyprland socket
#   2. Matches app class to theme preset
#   3. Smoothly transitions desktop colors
#   4. Restores previous theme when app closes

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/context-theme.log"
readonly PID_FILE="/tmp/ash-context-theme.pid"
readonly STATE_FILE="${CACHE_DIR}/context-theme-state"
readonly CONFIG_FILE="${HOME}/.config/hypr/context-themes.conf"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 APP → THEME MAPPINGS
# ═══════════════════════════════════════════════════════════════════════════════

declare -A APP_THEMES=(
    # Music players → music-reactive colors
    [spotify]="music"
    [ncspot]="music"

    # Gaming → red/aggressive
    [steam]="gaming"
    [lutris]="gaming"

    # Terminal → green matrix
    [kitty]="terminal"
    [alacritty]="terminal"
    [wezterm]="terminal"

    # Browsers → blue/productive
    [firefox]="browser"
    [chromium]="browser"

    # Code → purple/focus
    [code]="coding"
    [code-oss]="coding"

    # Video → dark/cinematic
    [mpv]="cinema"
    [vlc]="cinema"

    # Communication → warm social
    [discord]="social"
    [telegram-desktop]="social"
    [signal]="social"
)

# Theme preset → border color
declare -A THEME_COLORS=(
    [music]="cba6f7"      # Purple — creative
    [gaming]="f38ba8"     # Red — intense
    [terminal]="a6e3a1"   # Green — matrix
    [browser]="89b4fa"    # Blue — web
    [coding]="cba6f7"     # Mauve — focus
    [cinema]="fab387"     # Orange — warm dark
    [social]="94e2d5"     # Teal — friendly
    [default]=""          # Use wallpaper colors
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 APPLY CONTEXT COLOR
# ═══════════════════════════════════════════════════════════════════════════════

apply_context_color() {
    local theme="$1"
    local app_class="$2"

    local color="${THEME_COLORS[${theme}]:-}"

    if [[ -z "${color}" ]]; then
        return 0
    fi

    # Calculate complementary colors
    local r g b
    r=$(( 16#${color:0:2} ))
    g=$(( 16#${color:2:2} ))
    b=$(( 16#${color:4:2} ))

    local r2 g2 b2
    r2=$(( r + 25 > 255 ? 255 : r + 25 ))
    g2=$(( g + 25 > 255 ? 255 : g + 25 ))
    b2=$(( b + 25 > 255 ? 255 : b + 25 ))
    local color2
    color2=$(printf "%02x%02x%02x" "${r2}" "${g2}" "${b2}")

    local r3 g3 b3
    r3=$(( r - 25 < 0 ? 0 : r - 25 ))
    g3=$(( g - 25 < 0 ? 0 : g - 25 ))
    b3=$(( b - 25 < 0 ? 0 : b - 25 ))
    local color3
    color3=$(printf "%02x%02x%02x" "${r3}" "${g3}" "${b3}")

    # Apply to Hyprland (only borders — not full theme)
    hyprctl keyword "general:col.active_border" \
        "rgba(${color}ff) rgba(${color2}ff) rgba(${color3}ff) 60deg" \
        2>/dev/null || true

    # Save current context
    echo "${theme}:${app_class}:${color}" > "${STATE_FILE}"
    log "INFO" "Context: ${app_class} → ${theme} (#${color})"
}

reset_to_wallpaper_theme() {
    # Restore original border color from colors cache
    if [[ -f "${CACHE_DIR}/colors/current.sh" ]]; then
        # shellcheck source=/dev/null
        source "${CACHE_DIR}/colors/current.sh" 2>/dev/null || true
        local primary="${ASH_PRIMARY:-cba6f7}"
        local secondary="${ASH_SECONDARY:-89b4fa}"
        local tertiary="${ASH_TERTIARY:-94e2d5}"

        hyprctl keyword "general:col.active_border" \
            "rgba(${primary}ff) rgba(${secondary}ff) rgba(${tertiary}ff) 60deg" \
            2>/dev/null || true
    fi
    echo "" > "${STATE_FILE}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 👁️ WINDOW WATCHER
# ═══════════════════════════════════════════════════════════════════════════════

watch_windows() {
    local last_theme="default"
    local socket
    socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    if [[ ! -S "${socket}" ]]; then
        warn "Hyprland socket not found — polling mode"
        # Fallback: poll every 2 seconds
        while true; do
            local active_class
            active_class=$(hyprctl activewindow -j 2>/dev/null \
                | jq -r '.class // ""' | tr '[:upper:]' '[:lower:]')

            local theme="${APP_THEMES[${active_class}]:-default}"
            if [[ "${theme}" != "${last_theme}" ]]; then
                if [[ "${theme}" == "default" ]]; then
                    reset_to_wallpaper_theme
                else
                    apply_context_color "${theme}" "${active_class}"
                fi
                last_theme="${theme}"
            fi
            sleep 2
        done
        return
    fi

    # Efficient: listen to socket events
    socat -u "UNIX-CONNECT:${socket}" - 2>/dev/null | \
    while IFS= read -r event; do
        case "${event}" in
            activewindow*)
                local active_class
                active_class=$(hyprctl activewindow -j 2>/dev/null \
                    | jq -r '.class // ""' | tr '[:upper:]' '[:lower:]')

                local theme="${APP_THEMES[${active_class}]:-default}"

                if [[ "${theme}" != "${last_theme}" ]]; then
                    if [[ "${theme}" == "default" ]]; then
                        reset_to_wallpaper_theme
                    else
                        apply_context_color "${theme}" "${active_class}"
                    fi
                    last_theme="${theme}"
                fi
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🗂️ USER CONFIG
# ═══════════════════════════════════════════════════════════════════════════════

create_default_config() {
    cat > "${CONFIG_FILE}" << 'EOF'
# ASH Context Theme Configuration
# Format: app_class=theme_name
# App class (lowercase): run 'hyprctl clients | grep class'
# Available themes: music, gaming, terminal, browser, coding, cinema, social

spotify=music
ncspot=music
firefox=browser
chromium=browser
code=coding
code-oss=coding
kitty=terminal
alacritty=terminal
wezterm=terminal
steam=gaming
lutris=gaming
mpv=cinema
vlc=cinema
discord=social
telegram-desktop=social
signal=social
EOF
    ok "Config created: ${CONFIG_FILE}"
}

load_user_config() {
    [[ ! -f "${CONFIG_FILE}" ]] && create_default_config

    while IFS='=' read -r app_class theme; do
        # Skip comments and empty lines
        [[ "${app_class}" =~ ^# ]] && continue
        [[ -z "${app_class}" ]] && continue
        APP_THEMES["${app_class,,}"]="${theme}"
    done < "${CONFIG_FILE}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

is_running() {
    [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"
    load_user_config

    case "${action}" in
        enable | start)
            is_running && { info "Already running"; return 0; }
            watch_windows &>/dev/null &
            echo $! > "${PID_FILE}"
            disown
            sleep 0.3
            is_running && ok "Context theming ENABLED" || \
                          warn "Failed to start"
            ;;

        disable | stop)
            is_running && {
                kill "$(cat "${PID_FILE}")" 2>/dev/null || true
                rm -f "${PID_FILE}" "${STATE_FILE}"
                reset_to_wallpaper_theme
                ok "Context theming DISABLED"
            } || info "Not running"
            ;;

        toggle)
            is_running && main disable || main enable
            ;;

        status)
            echo ""
            if is_running; then
                echo -e "  \033[92m●\033[0m Context theming: ACTIVE"
                if [[ -f "${STATE_FILE}" ]]; then
                    local state
                    state=$(cat "${STATE_FILE}")
                    local theme="${state%%:*}"
                    local app="${state#*:}"
                    app="${app%%:*}"
                    echo "  Current: ${app} → ${theme} theme"
                fi
            else
                echo -e "  \033[90m○\033[0m Context theming: inactive"
            fi
            echo ""
            echo "  App → Theme mappings:"
            for app in "${!APP_THEMES[@]}"; do
                printf "    %-25s → %s\n" "${app}" "${APP_THEMES[${app}]}"
            done | sort
            echo ""
            ;;

        config | edit)
            create_default_config 2>/dev/null || true
            "${EDITOR:-nvim}" "${CONFIG_FILE}"
            ;;

        *)
            echo "Usage: context-theme.sh [enable|disable|toggle|status|config]"
            exit 1
            ;;
    esac
}

main "$@"