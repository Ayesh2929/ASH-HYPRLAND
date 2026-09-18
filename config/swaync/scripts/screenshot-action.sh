#!/usr/bin/env bash
# ASH DOTFILES v5.0 OMEGA — swaync: screenshot notification action
# Called as `… screenshot-action.sh <copy|open|edit|delete> <file>`
set -euo pipefail
action="${1:-open}"
file="${2:-}"

case "$action" in
    copy)
        [[ -n "$file" && -f "$file" ]] || exit 0
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy < "$file" 2>/dev/null || true
        elif command -v xclip >/dev/null 2>&1; then
            xclip -selection clipboard -t image/png -i "$file" 2>/dev/null || true
        fi
        ;;
    open)
        [[ -n "$file" && -f "$file" ]] || exit 0
        command -v xdg-open >/dev/null 2>&1 && xdg-open "$file" >/dev/null 2>&1 || true
        ;;
    edit)
        [[ -n "$file" && -f "$file" ]] || exit 0
        command -v satty >/dev/null 2>&1 && satty --filename "$file" || \
            command -v xdg-open >/dev/null 2>&1 && xdg-open "$file" >/dev/null 2>&1 || true
        ;;
    delete)
        [[ -n "$file" && -f "$file" ]] || exit 0
        rm -f -- "$file"
        ;;
    '')
        exit 0
        ;;
esac
exit 0
