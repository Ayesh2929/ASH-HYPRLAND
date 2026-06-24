#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Spotify Status                    ║
# ║                                                                              ║
# ║  Spotify-specific status via playerctl with Spotify color branding,        ║
# ║  track/artist/album display and playback controls.                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly MAX_LEN=40

# Check Spotify is running
if ! pgrep -x "spotify" &>/dev/null && ! pgrep -x "Spotify" &>/dev/null; then
    echo '{}'
    exit 0
fi

# Find Spotify player instance
SPOTIFY_PLAYER=$(playerctl -l 2>/dev/null | grep -i "spotify" | head -1)
if [[ -z "$SPOTIFY_PLAYER" ]]; then
    echo '{}'
    exit 0
fi

STATUS=$(  playerctl --player="$SPOTIFY_PLAYER" status          2>/dev/null || echo "Stopped")
TITLE=$(   playerctl --player="$SPOTIFY_PLAYER" metadata title  2>/dev/null || echo "")
ARTIST=$(  playerctl --player="$SPOTIFY_PLAYER" metadata artist 2>/dev/null || echo "")
ALBUM=$(   playerctl --player="$SPOTIFY_PLAYER" metadata album  2>/dev/null || echo "")

[[ -z "$TITLE" ]] && { echo '{}'; exit 0; }

# Status icon
STATUS_ICON=""
case "$STATUS" in
    Playing) STATUS_ICON="󰎇" ;;
    Paused)  STATUS_ICON="󰏤" ;;
    *)       STATUS_ICON="󰓛" ;;
esac

# Truncate
[[ ${#TITLE}  -gt $MAX_LEN ]] && TITLE="${TITLE:0:$((MAX_LEN-1))}…"
[[ ${#ARTIST} -gt 30 ]] && ARTIST="${ARTIST:0:29}…"

TEXT="${ARTIST:+$ARTIST — }${TITLE}"
[[ ${#TEXT} -gt $MAX_LEN ]] && TEXT="${TEXT:0:$((MAX_LEN-1))}…"

TOOLTIP="󰝚 Spotify\n\n${TITLE}\n"
[[ -n "$ARTIST" ]] && TOOLTIP+="${ARTIST}\n"
[[ -n "$ALBUM"  ]] && TOOLTIP+="${ALBUM}\n"
TOOLTIP+="\nStatus: ${STATUS}\n\nLeft: play/pause  Right: next"

TEXT=$(   echo "$TEXT"    | sed 's/\\/\\\\/g; s/"/\\"/g')
TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

CSS="${STATUS,,}"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CSS"