#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MEDIA PLAYER PICKER                          ║
# ║           Rofi-based MPRIS player selector with actions                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/player.log"
readonly DEFAULT_PLAYER_FILE="${CACHE_DIR}/default-player"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎵 PLAYER DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_players() {
    playerctl -l 2>/dev/null || echo ""
}

get_player_icon() {
    local player="${1,,}"
    case "${player}" in
        *spotify*)   echo "󰓇" ;;
        *firefox*)   echo "󰈹" ;;
        *chromium*)  echo "󰊯" ;;
        *vlc*)       echo "󰕼" ;;
        *mpv*)       echo "󰎁" ;;
        *ncspot*)    echo "󰓇" ;;
        *cmus*)      echo "󰝚" ;;
        *mopidy*)    echo "󰝚" ;;
        *rhythmbox*) echo "󰓻" ;;
        *strawberry*) echo "󰒋" ;;
        *clementine*) echo "󰑀" ;;
        *)           echo "󰎃" ;;
    esac
}

get_player_status() {
    local player="$1"
    local status title artist

    status=$(playerctl -p "${player}" status 2>/dev/null || echo "Stopped")
    title=$(playerctl  -p "${player}" metadata title  2>/dev/null | head -c 30 || echo "")
    artist=$(playerctl -p "${player}" metadata artist 2>/dev/null | head -c 20 || echo "")

    local status_icon
    case "${status}" in
        Playing) status_icon="▶" ;;
        Paused)  status_icon="⏸" ;;
        *)       status_icon="⏹" ;;
    esac

    if [[ -n "${title}" ]]; then
        if [[ -n "${artist}" ]]; then
            echo "${status_icon} ${artist} — ${title}"
        else
            echo "${status_icon} ${title}"
        fi
    else
        echo "${status_icon} ${status}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 PLAYER PICKER
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-pick}"

    mkdir -p "${CACHE_DIR}/logs"

    if ! command -v playerctl &>/dev/null; then
        notify-send "🎵 Player Picker" \
            "playerctl not installed\nparu -S playerctl" \
            --app-name="ASH Media" \
            --urgency=normal \
            2>/dev/null || true
        exit 1
    fi

    case "${action}" in
        pick | "")
            # Get all available players
            local players=()
            while IFS= read -r player; do
                [[ -n "${player}" ]] && players+=("${player}")
            done < <(get_players)

            if (( ${#players[@]} == 0 )); then
                notify-send "🎵 Player Picker" \
                    "No media players detected" \
                    --app-name="ASH Media" \
                    --expire-time=2000 \
                    2>/dev/null || true
                exit 0
            fi

            # Build menu
            local menu=""
            for player in "${players[@]}"; do
                local icon status_text
                icon=$(get_player_icon "${player}")
                status_text=$(get_player_status "${player}")
                menu+="${icon}  ${player}\n    ${status_text}\n"
            done

            # Add actions
            menu+="\n─────────────────────\n"
            menu+="▶  Play All\n"
            menu+="⏸  Pause All\n"
            menu+="⏭  Next Track\n"
            menu+="⏮  Prev Track\n"
            menu+="⏹  Stop All\n"

            local selected
            selected=$(echo -e "${menu}" | grep -v "^$" | rofi \
                -dmenu \
                -i \
                -p "🎵 Media Players" \
                -theme-str '
                    window { width: 520px; }
                    listview { columns: 1; lines: 14; }
                    element { padding: 6px 12px; font-size: 12px; }
                ' \
                2>/dev/null) || {
                log "INFO" "Player picker cancelled"
                exit 0
            }

            # Handle global actions
            case "${selected}" in
                "▶  Play All")
                    playerctl --all-players play 2>/dev/null || true
                    ;;
                "⏸  Pause All")
                    playerctl --all-players pause 2>/dev/null || true
                    ;;
                "⏭  Next Track")
                    playerctl next 2>/dev/null || true
                    ;;
                "⏮  Prev Track")
                    playerctl previous 2>/dev/null || true
                    ;;
                "⏹  Stop All")
                    playerctl --all-players stop 2>/dev/null || true
                    ;;
                *)
                    # Extract player name from selection
                    local chosen_player
                    chosen_player=$(echo "${selected}" | awk '{print $2}')

                    if [[ -n "${chosen_player}" ]]; then
                        # Show actions for selected player
                        local player_action
                        player_action=$(printf '▶  Play/Pause\n⏭  Next\n⏮  Previous\n⏹  Stop\n🔇  Mute\n📌  Set as Default' \
                            | rofi \
                                -dmenu \
                                -i \
                                -p "🎵 ${chosen_player}" \
                                -theme-str 'window { width: 300px; } listview { lines: 6; }' \
                                2>/dev/null) || exit 0

                        case "${player_action}" in
                            "▶  Play/Pause") playerctl -p "${chosen_player}" play-pause ;;
                            "⏭  Next")       playerctl -p "${chosen_player}" next ;;
                            "⏮  Previous")   playerctl -p "${chosen_player}" previous ;;
                            "⏹  Stop")       playerctl -p "${chosen_player}" stop ;;
                            "📌  Set as Default")
                                echo "${chosen_player}" > "${DEFAULT_PLAYER_FILE}"
                                notify-send "🎵 Default Player" \
                                    "Set to: ${chosen_player}" \
                                    --app-name="ASH Media" \
                                    --expire-time=2000 \
                                    2>/dev/null || true
                                ;;
                        esac

                        log "INFO" "Player action: ${chosen_player} → ${player_action}"
                    fi
                    ;;
            esac
            ;;

        default)
            # Get or set default player
            if [[ -f "${DEFAULT_PLAYER_FILE}" ]]; then
                cat "${DEFAULT_PLAYER_FILE}"
            else
                playerctl -l 2>/dev/null | head -1 || echo ""
            fi
            ;;

        list)
            get_players
            ;;

        *)
            echo "Usage: player-picker.sh [pick|default|list]"
            exit 1
            ;;
    esac
}

main "$@"