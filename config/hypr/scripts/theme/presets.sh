#!/bin/bash
set -euo pipefail

apply_preset() {
    local preset="${1:-default}"
    case "$preset" in
        default)
            ~/.config/hypr/scripts/theme/animations.sh apply smooth
            ~/.config/hypr/scripts/theme/blur.sh apply true 8 3
            ~/.config/hypr/scripts/theme/shadows.sh apply true 4 3
            ~/.config/hypr/scripts/theme/rounding.sh apply 10
            ~/.config/hypr/scripts/theme/opacity.sh apply 0.95 0.9
            ~/.config/hypr/scripts/theme/colorscheme.sh apply catppuccin
            ;;
        minimal)
            ~/.config/hypr/scripts/theme/animations.sh apply none
            ~/.config/hypr/scripts/theme/blur.sh apply false
            ~/.config/hypr/scripts/theme/shadows.sh apply false
            ~/.config/hypr/scripts/theme/rounding.sh apply 0
            ~/.config/hypr/scripts/theme/opacity.sh apply 1.0 1.0
            ~/.config/hypr/scripts/theme/colorscheme.sh apply nord
            ;;
        gaming)
            ~/.config/hypr/scripts/theme/animations.sh apply fast
            ~/.config/hypr/scripts/theme/blur.sh apply false
            ~/.config/hypr/scripts/theme/shadows.sh apply false
            ~/.config/hypr/scripts/theme/rounding.sh apply 0
            ~/.config/hypr/scripts/theme/opacity.sh apply 1.0 1.0
            ~/.config/hypr/scripts/theme/colorscheme.sh apply tokyo-night
            ;;
        *) echo "Unknown preset: $preset"; return 1 ;;
    esac
    echo "Applied preset: $preset"
}

main() {
    case "${1:-}" in
        apply) apply_preset "${2:-default}" ;;
        list) echo -e "default\nminimal\ngaming" ;;
        *) echo "Usage: presets.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"