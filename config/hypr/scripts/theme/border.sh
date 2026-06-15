#!/bin/bash
set -euo pipefail

apply_border() {
    local size="${1:-2}"
    local color="${2:-rgba(89b4faee)}"
    
    hyprctl keyword general:border_size "$size"
    hyprctl keyword general:col.active_border "$color"
    echo "Applied border: size=$size color=$color"
}

main() {
    case "${1:-}" in
        apply) apply_border "${2:-2}" "${3:-rgba(89b4faee)}" ;;
        toggle)
            current=$(hyprctl getoption general:border_size -j | jq -r '.int')
            if [[ "$current" -eq 0 ]]; then
                apply_border 2
            else
                apply_border 0
            fi
            ;;
        *) echo "Usage: border.sh [apply|toggle]"; exit 1 ;;
    esac
}

main "$@"