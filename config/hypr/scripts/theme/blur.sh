#!/bin/bash
set -euo pipefail

apply_blur() {
    local enabled="${1:-true}"
    local size="${2:-8}"
    local passes="${3:-3}"
    
    if [[ "$enabled" == "true" ]]; then
        hyprctl keyword decoration:blur:enabled true
        hyprctl keyword decoration:blur:size "$size"
        hyprctl keyword decoration:blur:passes "$passes"
        hyprctl keyword decoration:blur:new_optimizations true
    else
        hyprctl keyword decoration:blur:enabled false
    fi
    echo "Blur: $enabled (size: $size, passes: $passes)"
}

main() {
    case "${1:-}" in
        apply) apply_blur "${2:-true}" "${3:-8}" "${4:-3}" ;;
        toggle)
            current=$(hyprctl getoption decoration:blur:enabled -j | jq -r '.int')
            if [[ "$current" -eq 1 ]]; then
                apply_blur false
            else
                apply_blur true
            fi
            ;;
        *) echo "Usage: blur.sh [apply|toggle]"; exit 1 ;;
    esac
}

main "$@"