#!/bin/bash
set -euo pipefail

apply_colorscheme() {
    local scheme="$1"
    case "$scheme" in
        catppuccin)
            hyprctl keyword general:col.active_border "rgba(89b4faee) rgba(89b4faee) 45deg"
            hyprctl keyword general:col.inactive_border "rgba(313244ee)"
            ;;
        tokyo-night)
            hyprctl keyword general:col.active_border "rgba(7aa2f7ee) rgba(7aa2f7ee) 45deg"
            hyprctl keyword general:col.inactive_border "rgba(24283bee)"
            ;;
        nord)
            hyprctl keyword general:col.active_border "rgba(88c0d0ee) rgba(88c0d0ee) 45deg"
            hyprctl keyword general:col.inactive_border "rgba(3b4252ee)"
            ;;
        dracula)
            hyprctl keyword general:col.active_border "rgba(bd93f9ee) rgba(bd93f9ee) 45deg"
            hyprctl keyword general:col.inactive_border "rgba(44475aee)"
            ;;
        *)
            echo "Unknown scheme: $scheme"
            return 1
            ;;
    esac
    echo "Applied colorscheme: $scheme"
}

main() {
    case "${1:-}" in
        apply) apply_colorscheme "${2:-catppuccin}" ;;
        list) echo -e "catppuccin\ntokyo-night\nnord\ndracula" ;;
        *) echo "Usage: colorscheme.sh [apply|list]"; exit 1 ;;
    esac
}

main "$@"