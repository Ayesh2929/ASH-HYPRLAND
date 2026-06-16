#!/bin/bash
set -euo pipefail

apply_gradient() {
    local angle="${1:-45deg}"
    local color1="${2:-rgba(89b4faee)}"
    local color2="${3:-rgba(74c7ecee)}"
    
    hyprctl keyword general:col.active_border "$color1 $color2 $angle"
    echo "Applied gradient: $angle $color1 $color2"
}

presets=(
    "catppuccin:45deg:rgba(89b4faee):rgba(74c7ecee)"
    "tokyo-night:45deg:rgba(7aa2f7ee):rgba(bb9af7ee)"
    "nord:45deg:rgba(88c0d0ee):rgba(81a1c1ee)"
    "dracula:45deg:rgba(bd93f9ee):rgba(ff79c6ee)"
    "gruvbox:45deg:rgba(fabd2fee):rgba(fe8019ee)"
)

list_presets() {
    for preset in "${presets[@]}"; do
        echo "$preset"
    done
}

main() {
    case "${1:-}" in
        apply) apply_gradient "${2:-45deg}" "${3:-rgba(89b4faee)}" "${4:-rgba(74c7ecee)}" ;;
        list) list_presets ;;
        preset)
            for preset in "${presets[@]}"; do
                IFS=':' read -r name angle c1 c2 <<< "$preset"
                [[ "$name" == "${2:-}" ]] && { apply_gradient "$angle" "$c1" "$c2"; return; }
            done
            echo "Preset not found: ${2:-}"
            ;;
        *) echo "Usage: gradient.sh [apply|list|preset]"; exit 1 ;;
    esac
}

main "$@"