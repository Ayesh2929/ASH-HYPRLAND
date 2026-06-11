#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — CLIPBOARD MANAGER                            ║
# ║           cliphist-based clipboard with image and text support             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/clipboard.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 BACKEND DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_backend() {
    if command -v cliphist &>/dev/null; then
        echo "cliphist"
    elif command -v copyq &>/dev/null; then
        echo "copyq"
    elif command -v xclip &>/dev/null; then
        echo "xclip"
    else
        echo "wl-clipboard"
    fi
}

readonly BACKEND=$(detect_backend)

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 CLIPBOARD OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_history() {
    case "${BACKEND}" in
        cliphist)
            # Show cliphist history in Rofi
            local selected
            selected=$(cliphist list 2>/dev/null \
                | rofi \
                    -dmenu \
                    -i \
                    -p "📋 Clipboard" \
                    -theme-str '
                        window { width: 680px; }
                        listview { columns: 1; lines: 15; }
                        element { font-family: "JetBrainsMono Nerd Font"; font-size: 12px; }
                    ' \
                    2>/dev/null) || {
                log "INFO" "Clipboard picker cancelled"
                return 0
            }

            # Decode and paste selected entry
            echo "${selected}" | cliphist decode | wl-copy 2>/dev/null
            log "INFO" "Clipboard pasted: ${selected:0:50}"
            ;;

        copyq)
            copyq show 2>/dev/null || true
            ;;

        *)
            # Fallback: show last clipboard content
            wl-paste --no-newline 2>/dev/null | head -20
            ;;
    esac
}

clear_history() {
    case "${BACKEND}" in
        cliphist)
            cliphist wipe 2>/dev/null \
                && notify-send "📋 Clipboard" \
                    "History cleared" \
                    --app-name="ASH Clipboard" \
                    --expire-time=2000 \
                    2>/dev/null || true
            log "INFO" "Clipboard history cleared"
            ;;
        copyq)
            copyq remove 0 2>/dev/null || true
            ;;
        *)
            echo "" | wl-copy 2>/dev/null || true
            ;;
    esac
}

start_daemon() {
    # Start cliphist daemon
    if command -v cliphist &>/dev/null; then
        # Text clipboard daemon
        if ! pgrep -x wl-paste &>/dev/null; then
            wl-paste --type text --watch cliphist store &>/dev/null &
            disown
            log "INFO" "cliphist text daemon started"
        fi

        # Image clipboard daemon
        if command -v wl-paste &>/dev/null; then
            wl-paste --type image --watch cliphist store &>/dev/null &
            disown
            log "INFO" "cliphist image daemon started"
        fi
    else
        log "WARN" "cliphist not found — clipboard history unavailable"
    fi
}

get_count() {
    case "${BACKEND}" in
        cliphist)
            cliphist list 2>/dev/null | wc -l || echo "0"
            ;;
        *)
            echo "?"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-history}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        history | h)   show_history ;;
        clear | c)     clear_history ;;
        daemon | d)    start_daemon ;;
        count)         get_count ;;
        backend)       echo "${BACKEND}" ;;
        *)
            echo "Usage: clipboard.sh [history|clear|daemon|count|backend]"
            exit 1
            ;;
    esac
}

main "$@"