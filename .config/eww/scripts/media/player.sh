#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — EWW MEDIA PLAYER SCRIPT                      ║
# ║           Media player status for EWW widgets                              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

action="${1:-status}"

if ! command -v playerctl &>/dev/null; then
    echo ""
    exit 0
fi

case "${action}" in
    status)
        playerctl status 2>/dev/null || echo "Stopped"
        ;;
    title)
        playerctl metadata title 2>/dev/null | head -c 40 || echo ""
        ;;
    artist)
        playerctl metadata artist 2>/dev/null | head -c 25 || echo ""
        ;;
    album)
        playerctl metadata album 2>/dev/null | head -c 30 || echo ""
        ;;
    position)
        playerctl position 2>/dev/null | awk '{printf "%.0f", $1}' || echo "0"
        ;;
    length)
        playerctl metadata mpris:length 2>/dev/null \
            | awk '{printf "%.0f", $1/1000000}' || echo "0"
        ;;
    icon)
        status=$(playerctl status 2>/dev/null || echo "Stopped")
        case "${status}" in
            Playing) echo "󰎈" ;;
            Paused)  echo "󰏤" ;;
            *)       echo "󰎊" ;;
        esac
        ;;
    full)
        status=$(playerctl status 2>/dev/null || echo "Stopped")
        if [[ "${status}" == "Stopped" ]]; then
            echo ""
            exit 0
        fi
        title=$(playerctl metadata title 2>/dev/null | head -c 30 || echo "")
        artist=$(playerctl metadata artist 2>/dev/null | head -c 20 || echo "")
        icon_char=""
        case "${status}" in
            Playing) icon_char="󰎈" ;;
            Paused)  icon_char="󰏤" ;;
            *)       icon_char="󰎊" ;;
        esac
        if [[ -n "${artist}" ]]; then
            echo "${icon_char} ${artist} — ${title}"
        elif [[ -n "${title}" ]]; then
            echo "${icon_char} ${title}"
        fi
        ;;
    *)
        echo "Usage: player.sh [status|title|artist|album|position|length|icon|full]"
        exit 1
        ;;
esac