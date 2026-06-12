#!/bin/bash
set -euo pipefail

BINDS_FILE="${HOME}/.config/hypr/keybinds.conf"

add_bind() {
    local key="${1:-}"
    local action="${2:-}"
    [[ -z "$key" || -z "$action" ]] && { echo "Usage: keybinds.sh add <key> <action>"; return 1; }
    echo "bind = $mainMod, $key, $action" >> "$BINDS_FILE"
    echo "Added bind: $key -> $action"
}

list_binds() {
    grep "^bind" "$BINDS_FILE" 2>/dev/null || echo "No binds"
}

main() {
    case "${1:-}" in
        add) add_bind "${2:-}" "${3:-}" ;;
        list) list_binds ;;
        *) echo "Usage: keybinds.sh [add|list]"; exit 1 ;;
    esac
}

main "$@"