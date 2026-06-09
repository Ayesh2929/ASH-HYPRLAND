#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI WINDOW SWITCHER                        ║
# ║           Switch between open windows with preview and actions             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🪟 WINDOW DATA
# ═══════════════════════════════════════════════════════════════════════════════

get_windows() {
    hyprctl clients -j 2>/dev/null | jq -r '
        .[] |
        select(.mapped == true) |
        {
            address: .address,
            title: (if .title | length > 50 then .title[:50] + "…" else .title end),
            class: .class,
            workspace: .workspace.name,
            floating: .floating,
            fullscreen: .fullscreen,
            pid: .pid
        } |
        "\(.address)|\(.class)|\(.title)|\(.workspace)|\(.floating)|\(.fullscreen)"
    ' 2>/dev/null
}

get_window_icon() {
    local class="${1:-}"
    case "${class,,}" in
        *firefox* | *librewolf*)  echo "🌐" ;;
        *chromium* | *chrome*)    echo "🌐" ;;
        *kitty* | *alacritty* | *wezterm*) echo "🖥️" ;;
        *nvim* | *neovim*)        echo "📝" ;;
        *code* | *vscode*)        echo "💻" ;;
        *discord* | *webcord*)    echo "💬" ;;
        *telegram*)               echo "💬" ;;
        *spotify*)                echo "🎵" ;;
        *vlc* | *mpv*)            echo "🎬" ;;
        *nemo* | *thunar* | *nautilus*) echo "📁" ;;
        *steam*)                  echo "🎮" ;;
        *obs*)                    echo "🔴" ;;
        *gimp* | *inkscape*)      echo "🎨" ;;
        *btop* | *htop*)          echo "📊" ;;
        *)                        echo "🪟" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 WINDOW ACTIONS
# ═══════════════════════════════════════════════════════════════════════════════

focus_window() {
    local address="$1"
    hyprctl dispatch focuswindow "address:${address}" 2>/dev/null
}

close_window() {
    local address="$1"
    hyprctl dispatch closewindow "address:${address}" 2>/dev/null
}

kill_window() {
    local pid="$1"
    kill -9 "${pid}" 2>/dev/null || true
}

move_to_workspace() {
    local address="$1"
    local ws="$2"
    hyprctl dispatch movetoworkspace "${ws},address:${address}" 2>/dev/null
}

toggle_float() {
    local address="$1"
    hyprctl dispatch togglefloating "address:${address}" 2>/dev/null
}

toggle_fullscreen() {
    local address="$1"
    hyprctl dispatch fullscreen "0" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN PICKER
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Get all windows
    local window_list=""
    declare -A window_addresses
    declare -A window_pids

    while IFS='|' read -r address class title workspace floating fullscreen; do
        local icon
        icon=$(get_window_icon "${class}")

        local float_indicator=""
        [[ "${floating}" == "true" ]] && float_indicator=" 🔲"

        local full_indicator=""
        [[ "${fullscreen}" -gt 0 ]] && full_indicator=" ⛶"

        local entry="${icon} [WS:${workspace}]  ${class} — ${title}${float_indicator}${full_indicator}"
        window_list+="${entry}\n"
        window_addresses["${entry}"]="${address}"
        window_pids["${entry}"]=""
    done < <(get_windows)

    if [[ -z "${window_list}" ]]; then
        notify-send "🪟 Window Switcher" "No windows open" \
            --app-name="ASH" --expire-time=2000 2>/dev/null || true
        exit 0
    fi

    # Show window picker
    local selected
    selected=$(echo -e "${window_list}" | rofi \
        -dmenu \
        -i \
        -p "🪟 Windows" \
        -theme-str '
            window { width: 750px; }
            listview { columns: 1; lines: 12; }
            element { padding: 8px 12px; }
        ' \
        -kb-custom-1 "ctrl+k"  \
        -kb-custom-2 "ctrl+f"  \
        -kb-custom-3 "ctrl+w"  \
        2>/dev/null
    )
    local rofi_exit=$?

    local address="${window_addresses[${selected}]:-}"

    if [[ -z "${address}" ]]; then
        log "INFO" "Window switcher: no selection"
        exit 0
    fi

    case ${rofi_exit} in
        0)
            # Default: focus window
            focus_window "${address}"
            log "INFO" "Window focused: ${selected}"
            ;;
        10)
            # Ctrl+K: Kill window
            kill_window "${address}"
            log "INFO" "Window killed: ${selected}"
            ;;
        11)
            # Ctrl+F: Toggle float
            toggle_float "${address}"
            log "INFO" "Window float toggled: ${selected}"
            ;;
        12)
            # Ctrl+W: Close window gracefully
            close_window "${address}"
            log "INFO" "Window closed: ${selected}"
            ;;
    esac
}

main "$@"