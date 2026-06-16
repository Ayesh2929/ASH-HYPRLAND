#!/bin/bash
set -euo pipefail

SAVE_DIR="${HOME}/Videos/ytdl"
mkdir -p "$SAVE_DIR"

case "${1:-}" in
    video) yt-dlp -f "bestvideo+bestaudio" -o "$SAVE_DIR/%(title)s.%(ext)s" "$2" ;;
    audio) yt-dlp -x --audio-format mp3 -o "$SAVE_DIR/%(title)s.%(ext)s" "$2" ;;
    playlist) yt-dlp -f "bestvideo+bestaudio" -o "$SAVE_DIR/%(playlist)s/%(title)s.%(ext)s" "$2" ;;
    *) echo "Usage: ytdl.sh [video|audio|playlist] <url>"; exit 1 ;;
esac