#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR MEDIA PLAYER MODULE                   ║
# ║           MPRIS player with progress bar, album art, rich tooltips         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: player.sh [ACTION]
#
# ACTIONS:
#   status   — JSON output for Waybar (default)
#   toggle   — Play/pause
#   next     — Next track
#   prev     — Previous track
#   stop     — Stop playback
#   info     — Show current track info

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/player.log"
readonly ART_CACHE="${CACHE_DIR}/album-art"
readonly WAYBAR_SIGNAL=7
readonly MAX_TITLE_LEN=35
readonly MAX_ARTIST_LEN=20

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎵 PLAYER DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_active_player() {
    if ! command -v playerctl &>/dev/null; then
        echo ""
        return 0
    fi

    # Get first active (playing) player
    local player
    player=$(playerctl -l 2>/dev/null \
        | while read -r p; do
            local status
            status=$(playerctl -p "${p}" status 2>/dev/null || echo "")
            if [[ "${status}" == "Playing" ]]; then
                echo "${p}"
                break
            fi
          done)

    # If none playing, get first paused
    if [[ -z "${player}" ]]; then
        player=$(playerctl -l 2>/dev/null \
            | while read -r p; do
                local status
                status=$(playerctl -p "${p}" status 2>/dev/null || echo "")
                if [[ "${status}" == "Paused" ]]; then
                    echo "${p}"
                    break
                fi
              done)
    fi

    echo "${player}"
}

get_player_icon() {
    local player_name="${1:-}"
    case "${player_name}" in
        *spotify*)    echo "󰓇" ;;
        *firefox*)    echo "󰈹" ;;
        *chromium*)   echo "󰊯" ;;
        *vlc*)        echo "󰕼" ;;
        *mpv*)        echo "󰎁" ;;
        *rhythmbox*)  echo "󰓻" ;;
        *amarok*)     echo "󰓀" ;;
        *clementine*) echo "󰑀" ;;
        *strawberry*) echo "󰒋" ;;
        *cmus*)       echo "󰤽" ;;
        *mopidy*)     echo "󰓀" ;;
        *ncspot*)     echo "󰓇" ;;
        *)            echo "󰎃" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 TRACK INFO
# ═══════════════════════════════════════════════════════════════════════════════

get_track_info() {
    local player="${1:-}"

    if [[ -z "${player}" ]]; then
        echo ""
        return 0
    fi

    local title artist album status position length
    title=$(playerctl  -p "${player}" metadata title  2>/dev/null || echo "")
    artist=$(playerctl -p "${player}" metadata artist 2>/dev/null || echo "")
    album=$(playerctl  -p "${player}" metadata album  2>/dev/null || echo "")
    status=$(playerctl -p "${player}" status          2>/dev/null || echo "Stopped")

    # Get position and length for progress bar
    position=$(playerctl -p "${player}" position        2>/dev/null || echo "0")
    length=$(playerctl   -p "${player}" metadata mpris:length 2>/dev/null || echo "0")

    # Convert microseconds to seconds
    local length_sec=0
    if [[ "${length}" =~ ^[0-9]+$ ]]; then
        length_sec=$(( length / 1000000 ))
    fi

    local position_sec=0
    if [[ "${position}" =~ ^[0-9.]+$ ]]; then
        position_sec=$(echo "${position}" | awk '{printf "%.0f", $1}')
    fi

    echo "${title}|${artist}|${album}|${status}|${position_sec}|${length_sec}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 PROGRESS BAR
# ═══════════════════════════════════════════════════════════════════════════════

build_progress_bar() {
    local position="$1"
    local length="$2"
    local width=12

    if (( length == 0 )); then
        echo "$(printf '─%.0s' $(seq 1 ${width}))"
        return 0
    fi

    local pct=$(( position * 100 / length ))
    (( pct > 100 )) && pct=100

    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ ));  do bar+="░"; done

    echo "${bar}"
}

# Format time as MM:SS
format_time() {
    local seconds="${1:-0}"
    if (( seconds <= 0 )); then
        echo "0:00"
        return
    fi
    local mins=$(( seconds / 60 ))
    local secs=$(( seconds % 60 ))
    printf "%d:%02d" "${mins}" "${secs}"
}

# Truncate string
truncate_str() {
    local str="$1"
    local max="$2"
    local suffix="${3:-…}"

    if (( ${#str} > max )); then
        echo "${str:0:$((max-1))}${suffix}"
    else
        echo "${str}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 FORMAT STATUS
# ═══════════════════════════════════════════════════════════════════════════════

format_status() {
    local player="${1:-}"

    # No player found
    if [[ -z "${player}" ]]; then
        printf '{"text": "", "class": "stopped", "tooltip": "No media player active"}\n'
        return 0
    fi

    # Get track info
    local info
    info=$(get_track_info "${player}")

    local title artist album status position_sec length_sec
    IFS='|' read -r title artist album status position_sec length_sec <<< "${info}"

    # Handle stopped/no track
    if [[ -z "${title}" ]] || [[ "${status}" == "Stopped" ]]; then
        printf '{"text": "", "class": "stopped", "tooltip": "Player: %s\nStatus: Stopped"}\n' \
            "${player}"
        return 0
    fi

    # Truncate for display
    local short_title short_artist
    short_title=$(truncate_str "${title}" "${MAX_TITLE_LEN}")
    short_artist=$(truncate_str "${artist}" "${MAX_ARTIST_LEN}")

    # Status icon
    local status_icon
    case "${status}" in
        Playing) status_icon="󰎈" ;;
        Paused)  status_icon="󰎊" ;;
        *)       status_icon="󰎊" ;;
    esac

    # Player icon
    local player_icon
    player_icon=$(get_player_icon "${player}")

    # Progress bar
    local progress_bar
    progress_bar=$(build_progress_bar "${position_sec}" "${length_sec}")
    local pos_fmt fmt_len
    pos_fmt=$(format_time "${position_sec}")
    fmt_len=$(format_time "${length_sec}")

    # Build display text
    local display_text
    if [[ -n "${short_artist}" ]]; then
        display_text="${player_icon} ${status_icon} ${short_artist} — ${short_title}"
    else
        display_text="${player_icon} ${status_icon} ${short_title}"
    fi

    # Build tooltip
    local tooltip
    tooltip="🎵 Now Playing\n"
    tooltip+="───────────────────────\n"
    tooltip+="Title:  ${title}\n"
    [[ -n "${artist}" ]] && tooltip+="Artist: ${artist}\n"
    [[ -n "${album}" ]]  && tooltip+="Album:  ${album}\n"
    tooltip+="───────────────────────\n"
    tooltip+="${progress_bar}  ${pos_fmt} / ${fmt_len}\n"
    tooltip+="───────────────────────\n"
    tooltip+="Player: ${player}\n"
    tooltip+="Status: ${status}\n"
    tooltip+="\n"
    tooltip+="🖱️ Click: Play/Pause\n"
    tooltip+="🖱️ Right-click: Next\n"
    tooltip+="🖱️ Scroll: Seek"

    # Class based on status
    local class
    case "${status}" in
        Playing) class="playing" ;;
        Paused)  class="paused" ;;
        *)       class="stopped" ;;
    esac

    # Percentage for progress
    local pct=0
    (( length_sec > 0 )) && pct=$(( position_sec * 100 / length_sec ))

    printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' \
        "${display_text}" \
        "${tooltip}" \
        "${class}" \
        "${pct}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs" "${ART_CACHE}"

    if ! command -v playerctl &>/dev/null; then
        printf '{"text": "", "class": "unavailable", "tooltip": "playerctl not installed"}\n'
        exit 0
    fi

    case "${action}" in
        status | "")
            local player
            player=$(get_active_player)
            format_status "${player}"
            ;;

        toggle)
            playerctl play-pause 2>/dev/null || true
            pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
            ;;

        next)
            playerctl next 2>/dev/null || true
            ;;

        prev | previous)
            playerctl previous 2>/dev/null || true
            ;;

        stop)
            playerctl stop 2>/dev/null || true
            pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
            ;;

        info)
            local player
            player=$(get_active_player)
            if [[ -z "${player}" ]]; then
                echo "No active player"
                exit 0
            fi
            local info
            info=$(get_track_info "${player}")
            IFS='|' read -r title artist album status pos len <<< "${info}"
            echo "Player:   ${player}"
            echo "Status:   ${status}"
            echo "Title:    ${title}"
            echo "Artist:   ${artist}"
            echo "Album:    ${album}"
            echo "Position: $(format_time "${pos}") / $(format_time "${len}")"
            ;;

        list)
            playerctl -l 2>/dev/null || echo "No players found"
            ;;

        *)
            echo "Usage: player.sh [status|toggle|next|prev|stop|info|list]"
            exit 1
            ;;
    esac
}

main "$@"