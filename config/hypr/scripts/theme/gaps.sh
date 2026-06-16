#!/bin/bash
set -euo pipefail

apply_gaps() {
    local inner="${1:-5}"
    local outer="${2:-10}"
    
    hyprctl keyword general:gaps_in "$inner"
    hyprctl keyword general:gaps_out "$outer"
    echo "Applied gaps: inner=$inner outer=$outer"
}

main() {
    case "${1:-}" in
        apply) apply_gaps "${2:-5}" "${3:-10}" ;;
        toggle)
            current=$(hyprctl getoption general:gaps_in -j | jq -r '.int')
            if [[ "$current" -eq 0 ]]; then
                apply_gaps 5 10
            else
                apply_gaps 0 0
            fi
            ;;
        *) echo "Usage: gaps.sh [apply|toggle]"; exit 1 ;;
    esac
}

main "$@"