#!/bin/bash
set -euo pipefail

case "${1:-}" in
    dwindle) hyprctl keyword general:layout dwindle ;;
    master) hyprctl keyword general:layout master ;;
    toggle)
        current=$(hyprctl getoption general:layout -j | jq -r '.str')
        if [[ "$current" == "dwindle" ]]; then
            hyprctl keyword general:layout master
        else
            hyprctl keyword general:layout dwindle
        fi
        ;;
    split-h) hyprctl dispatch layoutmsg splith ;;
    split-v) hyprctl dispatch layoutmsg splitv ;;
    *) echo "Usage: layout.sh [dwindle|master|toggle|split-h|split-v]"; exit 1 ;;
esac