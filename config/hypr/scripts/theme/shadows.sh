#!/bin/bash
set -euo pipefail

apply_shadows() {
    local enabled="${1:-true}"
    local range="${2:-4}"
    local render_power="${3:-3}"
    local color="${4:-rgba(1a1b26ee)}"
    
    if [[ "$enabled" == "true" ]]; then
        hyprctl keyword decoration:drop_shadow true
        hyprctl keyword decoration:shadow_range "$range"
        hyprctl keyword decoration:shadow_render_power "$render_power"
        hyprctl keyword decoration:col.shadow "$color"
    else
        hyprctl keyword decoration:drop_shadow false
    fi
    echo "Shadows: $enabled (range: $range, power: $render_power)"
}

main() {
    case "${1:-}" in
        apply) apply_shadows "${2:-true}" "${3:-4}" "${4:-3}" "${5:-rgba(1a1b26ee)}" ;;
        toggle)
            current=$(hyprctl getoption decoration:drop_shadow -j | jq -r '.int')
            if [[ "$current" -eq 1 ]]; then
                apply_shadows false
            else
                apply_shadows true
            fi
            ;;
        *) echo "Usage: shadows.sh [apply|toggle]"; exit 1 ;;
    esac
}

main "$@"