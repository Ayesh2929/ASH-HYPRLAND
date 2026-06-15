#!/bin/bash
set -euo pipefail

apply_animations() {
    local preset="${1:-smooth}"
    case "$preset" in
        smooth)
            hyprctl keyword animations:enabled true
            hyprctl keyword animations:bezier "myBezier, 0.05, 0.9, 0.1, 1.05"
            hyprctl keyword animations:animation "windows, 1, 7, myBezier"
            hyprctl keyword animations:animation "windowsOut, 1, 7, default, popin 80%"
            hyprctl keyword animations:animation "border, 1, 10, default"
            hyprctl keyword animations:animation "borderangle, 1, 8, default"
            hyprctl keyword animations:animation "fade, 1, 7, default"
            hyprctl keyword animations:animation "workspaces, 1, 6, default"
            ;;
        fast)
            hyprctl keyword animations:enabled true
            hyprctl keyword animations:animation "windows, 1, 3, default"
            hyprctl keyword animations:animation "windowsOut, 1, 3, default"
            hyprctl keyword animations:animation "border, 1, 3, default"
            hyprctl keyword animations:animation "fade, 1, 3, default"
            hyprctl keyword animations:animation "workspaces, 1, 3, default"
            ;;
        none)
            hyprctl keyword animations:enabled false
            ;;
        *) echo "Unknown preset: $preset"; return 1 ;;
    esac
    echo "Applied animations: $preset"
}

main() {
    case "${1:-}" in
        apply) apply_animations "${2:-smooth}" ;;
        list) echo -e "smooth\nfast\nnone" ;;
        *) echo "Usage: animations.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"