#!/bin/bash
set -euo pipefail

case "${1:-}" in
    in) hyprctl keyword general:gaps_in "${2:-5}" ;;
    out) hyprctl keyword general:gaps_out "${2:-10}" ;;
    toggle)
        current_in=$(hyprctl getoption general:gaps_in -j | jq -r '.int')
        if [[ "$current_in" -eq 0 ]]; then
            hyprctl keyword general:gaps_in 5
            hyprctl keyword general:gaps_out 10
        else
            hyprctl keyword general:gaps_in 0
            hyprctl keyword general:gaps_out 0
        fi
        ;;
    *) echo "Usage: gaps.sh [in|out|toggle]"; exit 1 ;;
esac