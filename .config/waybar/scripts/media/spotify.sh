#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SPOTIFY STATUS MODULE                        ║
# ║           Spotify-specific status with Catppuccin green branding           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly MAX_LEN=40

# Check if Spotify is running
if ! playerctl -l 2>/dev/null | grep -qi "spotify"; then
    printf '{"text": "", "class": "stopped"}\n'
    exit 0
fi

status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")

if [[ "${status}" == "Stopped" ]]; then
    printf '{"text": "", "class": "stopped"}\n'
    exit 0
fi

title=$(playerctl -p spotify metadata title  2>/dev/null | head -c ${MAX_LEN} || echo "")
artist=$(playerctl -p spotify metadata artist 2>/dev/null | head -c 20 || echo "")

if [[ -z "${title}" ]]; then
    printf '{"text": "", "class": "stopped"}\n'
    exit 0
fi

# Status icon
status_icon="󰎈"
[[ "${status}" == "Paused" ]] && status_icon="󰏤"

# Build display text
display=""
if [[ -n "${artist}" ]]; then
    display="󰓇 ${status_icon} ${artist} — ${title}"
else
    display="󰓇 ${status_icon} ${title}"
fi

# Truncate if too long
if (( ${#display} > 55 )); then
    display="${display:0:54}…"
fi

# Get position info for progress
position=$(playerctl -p spotify position 2>/dev/null | awk '{printf "%.0f", $1}' || echo "0")
length=$(playerctl -p spotify metadata mpris:length 2>/dev/null | awk '{printf "%.0f", $1/1000000}' || echo "0")

# Build tooltip
tooltip="🎵 Spotify\n"
tooltip+="─────────────────────\n"
tooltip+="Title:  ${title}\n"
[[ -n "${artist}" ]] && tooltip+="Artist: ${artist}\n"
tooltip+="Status: ${status}\n"

local_pct=0
if (( length > 0 )); then
    local_pct=$(( position * 100 / length ))
fi

class="playing"
[[ "${status}" == "Paused" ]] && class="paused"

printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
    "${display}" "${tooltip}" "${class}" "${local_pct}"