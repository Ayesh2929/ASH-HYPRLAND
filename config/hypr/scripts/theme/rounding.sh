#!/bin/bash
set -euo pipefail

apply_rounding() {
    local rounding="${1:-10}"
    hyprctl keyword decoration:rounding "$rounding"
    echo "Applied rounding: $rounding"
}

main() {
    case "${1:-}" in
        apply) apply_rounding "${2:-10}" ;;
        *) echo "Usage: rounding.sh [apply]"; exit 1 ;;
    esac
}

main "$@"