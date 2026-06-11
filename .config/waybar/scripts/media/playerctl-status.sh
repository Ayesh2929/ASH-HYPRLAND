#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — PLAYERCTL STATUS SCRIPT                      ║
# ║           Simple play/pause icon for Waybar                                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

if ! command -v playerctl &>/dev/null; then
    printf '{"text": "", "class": "none"}\n'
    exit 0
fi

status=$(playerctl status 2>/dev/null || echo "Stopped")

case "${status}" in
    Playing)
        printf '{"text": "󰎈", "tooltip": "Playing — Click to pause", "class": "playing"}\n'
        ;;
    Paused)
        printf '{"text": "󰏤", "tooltip": "Paused — Click to play", "class": "paused"}\n'
        ;;
    *)
        printf '{"text": "", "class": "stopped"}\n'
        ;;
esac