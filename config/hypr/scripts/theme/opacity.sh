#!/bin/bash
set -euo pipefail

apply_opacity() {
    local active="${1:-0.95}"
    local inactive="${2:-0.9}"
    hyprctl keyword windowrulev2 "opacity $active,class:^(kitty|alacritty|foot)$"
    hyprctl keyword windowrulev2 "opacity $inactive,class:^(code|Code)$"
    echo "Applied opacity: active=$active inactive=$inactive"
}

main() {
    case "${1:-}" in
        apply) apply_opacity "${2:-0.95}" "${3:-0.9}" ;;
        *) echo "Usage: opacity.sh [apply]"; exit 1 ;;
    esac
}

main "$@"