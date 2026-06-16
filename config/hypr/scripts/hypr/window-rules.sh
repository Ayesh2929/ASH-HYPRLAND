#!/bin/bash
set -euo pipefail

RULES_FILE="${HOME}/.config/hypr/windowrules.conf"

add_rule() {
    local rule="${1:-}"
    [[ -z "$rule" ]] && { echo "Usage: window-rules.sh add <rule>"; return 1; }
    echo "$rule" >> "$RULES_FILE"
    echo "Added rule: $rule"
}

remove_rule() {
    local pattern="${1:-}"
    [[ -z "$pattern" ]] && { echo "Usage: window-rules.sh remove <pattern>"; return 1; }
    sed -i "/$pattern/d" "$RULES_FILE"
    echo "Removed rules matching: $pattern"
}

list_rules() {
    cat "$RULES_FILE" 2>/dev/null || echo "No rules"
}

main() {
    case "${1:-}" in
        add) add_rule "${2:-}" ;;
        remove) remove_rule "${2:-}" ;;
        list) list_rules ;;
        *) echo "Usage: window-rules.sh [add|remove|list]"; exit 1 ;;
    esac
}

main "$@"