#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Media Player (MPRIS2)             ║
# ║                                                                              ║
# ║  Universal MPRIS2 media player status via playerctl. Supports Spotify,     ║
# ║  mpv, VLC, Firefox, Chromium and any MPRIS2-compatible application.        ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    media-player.sh             — current player status                      ║
# ║    media-player.sh --waybar    — JSON output for Waybar                     ║
# ║    media-player.sh --status    — human readable status                      ║
# ║    media-player.sh --next      — skip to next track                         ║
# ║    media-player.sh --prev      — skip to previous track                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly MAX_TITLE_LEN=45
readonly MAX_ARTIST_LEN=30
readonly MAX_ALBUM_LEN=35
readonly PREFERRED_PLAYERS="spotify,mpd,mpv,firefox,chromium,brave"

# ══════════════════════════════════════════════════════════════════════════════
# §02  PLAYER DETECTION
# ══════════════════════════════════════════════════════════════════════════════

get_active_player() {
    # Prefer players in priority order
    local players
    players=$(playerctl -l 2>/dev/null) || return 1
    [[ -z "$players" ]] && return 1

    # Try preferred order
    local preferred
    IFS=',' read -ra preferred <<< "$PREFERRED_PLAYERS"
    for pref in "${preferred[@]}"; do
        while IFS= read -r player; do
            if [[ "${player,,}" == *"${pref,,}"* ]]; then
                local status
                status=$(playerctl --player="$player" status 2>/dev/null || echo "Stopped")
                if [[ "$status" == "Playing" ]]; then
                    echo "$player"
                    return 0
                fi
            fi
        done <<< "$players"
    done

    # Fall back to first active player
    while IFS= read -r player; do
        local status
        status=$(playerctl --player="$player" status 2>/dev/null || echo "Stopped")
        if [[ "$status" != "Stopped" ]]; then
            echo "$player"
            return 0
        fi
    done <<< "$players"

    # Last resort: any player
    echo "$players" | head -1
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  METADATA EXTRACTION
# ══════════════════════════════════════════════════════════════════════════════

truncate_str() {
    local str="${1:-}"
    local maxlen="${2:-50}"
    if [[ ${#str} -gt $maxlen ]]; then
        echo "${str:0:$((maxlen-1))}…"
    else
        echo "$str"
    fi
}

get_player_icon() {
    local player="${1,,}"
    if   [[ "$player" =~ spotify  ]]; then echo "󰝚"
    elif [[ "$player" =~ mpv      ]]; then echo "󰎈"
    elif [[ "$player" =~ vlc      ]]; then echo "󰀽"
    elif [[ "$player" =~ firefox  ]]; then echo "󰈹"
    elif [[ "$player" =~ chromium|chrome|brave ]]; then echo "󰊯"
    elif [[ "$player" =~ mpd|ncmpcpp ]]; then echo "󰝚"
    elif [[ "$player" =~ rhythmbox ]]; then echo "󰝚"
    else echo "󰎵"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  WAYBAR JSON OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

waybar_output() {
    # Check if any player exists
    if ! playerctl -l &>/dev/null 2>&1 || [[ -z "$(playerctl -l 2>/dev/null)" ]]; then
        echo '{}'
        return 0
    fi

    local PLAYER
    PLAYER=$(get_active_player 2>/dev/null) || { echo '{}'; return 0; }
    [[ -z "$PLAYER" ]] && { echo '{}'; return 0; }

    local STATUS TITLE ARTIST ALBUM DURATION POSITION
    STATUS=$(   playerctl --player="$PLAYER" status        2>/dev/null || echo "Stopped")
    TITLE=$(    playerctl --player="$PLAYER" metadata title 2>/dev/null || echo "")
    ARTIST=$(   playerctl --player="$PLAYER" metadata artist 2>/dev/null || echo "")
    ALBUM=$(    playerctl --player="$PLAYER" metadata album  2>/dev/null || echo "")
    DURATION=$( playerctl --player="$PLAYER" metadata mpris:length 2>/dev/null || echo "0")
    POSITION=$( playerctl --player="$PLAYER" position        2>/dev/null || echo "0")

    # Empty title → no active media
    [[ -z "$TITLE" ]] && { echo '{}'; return 0; }

    # Format duration/position
    local DUR_FMT POS_FMT
    if [[ "$DURATION" -gt 0 ]] 2>/dev/null; then
        local dur_secs=$(( DURATION / 1000000 ))
        DUR_FMT=$(printf "%d:%02d" $((dur_secs / 60)) $((dur_secs % 60)))
    else
        DUR_FMT="?:??"
    fi

    if [[ -n "$POSITION" ]]; then
        local pos_secs
        pos_secs=$(printf "%.0f" "$POSITION" 2>/dev/null || echo 0)
        POS_FMT=$(printf "%d:%02d" $((pos_secs / 60)) $((pos_secs % 60)))
    else
        POS_FMT="0:00"
    fi

    local PLAYER_ICON
    PLAYER_ICON=$(get_player_icon "$PLAYER")

    # Build display text
    local DISPLAY_TITLE DISPLAY_ARTIST
    DISPLAY_TITLE=$(truncate_str "$TITLE" "$MAX_TITLE_LEN")
    DISPLAY_ARTIST=$(truncate_str "$ARTIST" "$MAX_ARTIST_LEN")
    DISPLAY_ALBUM=$(truncate_str "$ALBUM" "$MAX_ALBUM_LEN")

    local TEXT
    if [[ -n "$ARTIST" ]]; then
        TEXT="${DISPLAY_ARTIST} — ${DISPLAY_TITLE}"
    else
        TEXT="$DISPLAY_TITLE"
    fi
    TEXT=$(truncate_str "$TEXT" 50)

    # Build tooltip
    local TOOLTIP
    TOOLTIP="${PLAYER_ICON} $(echo "${PLAYER##*/}" | sed 's/\..*//' | awk '{print toupper(substr($0,1,1))substr($0,2)}')\n\n"
    TOOLTIP+="󰎵  ${TITLE}\n"
    [[ -n "$ARTIST" ]] && TOOLTIP+="󰠃  ${ARTIST}\n"
    [[ -n "$ALBUM"  ]] && TOOLTIP+="󰀼  ${DISPLAY_ALBUM}\n"
    TOOLTIP+="󰔙  ${POS_FMT} / ${DUR_FMT}\n\n"
    TOOLTIP+="Left: play/pause  Right: next  Middle: previous"

    # Escape for JSON
    TEXT=$(echo "$TEXT"       | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/ /g')
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/ /g')

    local CSS_CLASS
    case "$STATUS" in
        Playing) CSS_CLASS="playing"  ;;
        Paused)  CSS_CLASS="paused"   ;;
        *)       CSS_CLASS="stopped"  ;;
    esac

    printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
        "$TEXT" "$TOOLTIP" "$CSS_CLASS" \
        "$(( DURATION > 0 ? (POSITION * 100 / (DURATION / 1000000)) : 0 ))"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  HUMAN READABLE OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

status_output() {
    local PLAYER
    PLAYER=$(get_active_player 2>/dev/null) || { echo "No media player"; return; }

    local STATUS TITLE ARTIST
    STATUS=$(playerctl --player="$PLAYER" status   2>/dev/null || echo "Unknown")
    TITLE=$( playerctl --player="$PLAYER" metadata title 2>/dev/null || echo "Unknown")
    ARTIST=$(playerctl --player="$PLAYER" metadata artist 2>/dev/null || echo "Unknown")

    echo "Player: $PLAYER"
    echo "Status: $STATUS"
    echo "Title:  $TITLE"
    echo "Artist: $ARTIST"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    case "${1:-}" in
        --waybar)   waybar_output   ;;
        --status)   status_output   ;;
        --next)     playerctl next  2>/dev/null || true ;;
        --prev)     playerctl previous 2>/dev/null || true ;;
        --pause)    playerctl play-pause 2>/dev/null || true ;;
        "")         waybar_output   ;;
        *)          waybar_output   ;;
    esac
}

main "$@"