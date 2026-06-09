#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — HYPRLOCK PLAYER SCRIPT                       ║
# ║           Now playing info for lock screen                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly MAX_LEN=50

truncate_str() {
    local str="$1"
    local max="$2"
    if (( ${#str} > max )); then
        echo "${str:0:$((max-1))}…"
    else
        echo "${str}"
    fi
}

main() {
    if ! command -v playerctl &>/dev/null; then
        echo ""
        return 0
    fi

    local status
    status=$(playerctl status 2>/dev/null || echo "")

    if [[ -z "${status}" ]] || [[ "${status}" == "Stopped" ]]; then
        echo ""
        return 0
    fi

    local title artist
    title=$(playerctl metadata title  2>/dev/null || echo "")
    artist=$(playerctl metadata artist 2>/dev/null || echo "")

    if [[ -z "${title}" ]]; then
        echo ""
        return 0
    fi

    local status_icon
    case "${status}" in
        Playing) status_icon="󰎈" ;;
        Paused)  status_icon="󰏤" ;;
        *)       status_icon="󰎊" ;;
    esac

    local display=""
    if [[ -n "${artist}" ]]; then
        local short_artist short_title
        short_artist=$(truncate_str "${artist}" 20)
        short_title=$(truncate_str "${title}" 30)
        display="${status_icon}  ${short_artist} — ${short_title}"
    else
        local short_title
        short_title=$(truncate_str "${title}" "${MAX_LEN}")
        display="${status_icon}  ${short_title}"
    fi

    echo "${display}"
}

main "$@"