#!/bin/bash
set -euo pipefail

case "${1:-}" in
    history) cliphist list ;;
    clear) cliphist wipe ;;
    paste) cliphist list | rofi -dmenu | cliphist decode | wl-copy ;;
    *) echo "Usage: clipboard.sh [history|clear|paste]"; exit 1 ;;
esac