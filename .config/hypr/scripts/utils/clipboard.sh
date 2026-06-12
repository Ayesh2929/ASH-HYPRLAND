#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ENHANCED CLIPBOARD MANAGER                   ║
# ║           cliphist with image preview, pin, categories, search             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/clipboard.log"
readonly PINNED_FILE="${CACHE_DIR}/clipboard-pinned.txt"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

detect_backend() {
    command -v cliphist &>/dev/null && echo "cliphist" && return
    echo "wl-clipboard"
}

readonly BACKEND=$(detect_backend)

# ═══════════════════════════════════════════════════════════════════════════════
# 📌 PIN MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

add_pin() {
    local content="$1"
    local label="${2:-$(echo "${content}" | head -c 30)}"

    mkdir -p "${CACHE_DIR}"
    echo "${label}|${content}" >> "${PINNED_FILE}"
    ok "Pinned: ${label:0:40}"
    log "INFO" "Pinned: ${label:0:40}"
}

list_pins() {
    if [[ ! -f "${PINNED_FILE}" ]] || [[ ! -s "${PINNED_FILE}" ]]; then
        echo "No pinned items"
        return 0
    fi

    echo ""
    echo -e "  \033[1m\033[95m📌 Pinned Items:\033[0m"
    local i=0
    while IFS='|' read -r label content; do
        ((i++)) || true
        printf "  %2d. %s\n" "${i}" "${label:0:60}"
    done < "${PINNED_FILE}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN PICKER (Rofi)
# ═══════════════════════════════════════════════════════════════════════════════

show_history() {
    case "${BACKEND}" in
        cliphist)
            # Build combined list: pinned first, then history
            local menu=""

            # Add pinned items first
            if [[ -f "${PINNED_FILE}" ]] && [[ -s "${PINNED_FILE}" ]]; then
                while IFS='|' read -r label content; do
                    menu+="📌 ${label}\n"
                done < "${PINNED_FILE}"
                menu+="─────────────────────\n"
            fi

            # Add clipboard history
            while IFS= read -r line; do
                [[ -n "${line}" ]] && menu+="${line}\n"
            done < <(cliphist list 2>/dev/null | head -50)

            if [[ -z "${menu}" ]]; then
                notify-send "📋 Clipboard" "History is empty" \
                    --app-name="ASH" --expire-time=2000 2>/dev/null || true
                return 0
            fi

            local selected
            selected=$(echo -e "${menu}" | rofi \
                -dmenu \
                -i \
                -p "📋 Clipboard" \
                -theme-str '
                    window { width: 700px; }
                    listview { columns: 1; lines: 16; }
                    element { padding: 6px 12px;
                              font-family: "JetBrainsMono Nerd Font";
                              font-size: 12px; }
                ' \
                -kb-custom-1 "ctrl+d"   \
                -kb-custom-2 "ctrl+p"   \
                -kb-custom-3 "ctrl+Del" \
                2>/dev/null)
            local exit_code=$?

            case ${exit_code} in
                0) # Paste
                    if [[ "${selected}" == "📌 "* ]]; then
                        local label="${selected#📌 }"
                        local content
                        content=$(grep "^${label}|" "${PINNED_FILE}" 2>/dev/null \
                            | head -1 | cut -d'|' -f2-)
                        echo -n "${content}" | wl-copy 2>/dev/null
                    elif [[ "${selected}" != "─"* ]]; then
                        echo "${selected}" | cliphist decode | wl-copy 2>/dev/null
                    fi
                    log "INFO" "Clipboard pasted"
                    ;;
                10) # Ctrl+D: Delete
                    echo "${selected}" | cliphist delete 2>/dev/null || true
                    ok "Entry deleted"
                    ;;
                11) # Ctrl+P: Pin
                    local content
                    content=$(echo "${selected}" | cliphist decode 2>/dev/null || echo "${selected}")
                    add_pin "${content}" "${selected:0:30}"
                    ;;
                12) # Ctrl+Del: Clear all
                    cliphist wipe 2>/dev/null
                    ok "Clipboard history cleared"
                    ;;
            esac
            ;;

        wl-clipboard)
            # Fallback: just show current clipboard
            local current
            current=$(wl-paste --no-newline 2>/dev/null | head -c 1000 || echo "Empty")
            echo "${current}"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 SEARCH CLIPBOARD
# ═══════════════════════════════════════════════════════════════════════════════

search_clipboard() {
    local query="${1:-}"

    if [[ "${BACKEND}" != "cliphist" ]]; then
        warn "Search requires cliphist"
        return 1
    fi

    local results
    results=$(cliphist list 2>/dev/null | grep -i "${query}" | head -20)

    if [[ -z "${results}" ]]; then
        echo "No matches for: ${query}"
        return 0
    fi

    local selected
    selected=$(echo "${results}" | rofi \
        -dmenu \
        -i \
        -p "🔍 Search: ${query}" \
        -theme-str 'window { width: 600px; } listview { lines: 10; }' \
        2>/dev/null) || return 0

    [[ -n "${selected}" ]] && echo "${selected}" | cliphist decode | wl-copy 2>/dev/null
    ok "Clipboard set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATS
# ═══════════════════════════════════════════════════════════════════════════════

show_stats() {
    local count=0 pins=0

    [[ "${BACKEND}" == "cliphist" ]] && \
        count=$(cliphist list 2>/dev/null | wc -l || echo "0")
    [[ -f "${PINNED_FILE}" ]] && \
        pins=$(wc -l < "${PINNED_FILE}" 2>/dev/null || echo "0")

    echo ""
    echo -e "  \033[1m📋 Clipboard Stats:\033[0m"
    echo "  History entries: ${count}"
    echo "  Pinned items:    ${pins}"
    echo "  Backend:         ${BACKEND}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 DAEMON
# ═══════════════════════════════════════════════════════════════════════════════

start_daemon() {
    if [[ "${BACKEND}" != "cliphist" ]]; then
        warn "cliphist not installed: paru -S cliphist"
        return 1
    fi

    # Text clipboard
    if ! pgrep -f "wl-paste.*cliphist" &>/dev/null; then
        wl-paste --type text --watch cliphist store &>/dev/null &
        disown
        ok "Text clipboard daemon started"
    fi

    # Image clipboard
    wl-paste --type image --watch cliphist store &>/dev/null &
    disown
    ok "Image clipboard daemon started"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-history}"
    shift || true

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        history | h | "")  show_history ;;
        search | s)        search_clipboard "$@" ;;
        pin | p)           add_pin "${*}" ;;
        pins)              list_pins ;;
        clear | c)
            cliphist wipe 2>/dev/null && ok "Clipboard cleared" || \
                warn "Clear failed"
            ;;
        count)
            cliphist list 2>/dev/null | wc -l || echo "0"
            ;;
        daemon | d)        start_daemon ;;
        stats)             show_stats ;;
        backend)           echo "${BACKEND}" ;;
        *)
            echo "Usage: clipboard.sh [history|search QUERY|pin TEXT|pins|clear|stats|daemon]"
            exit 1
            ;;
    esac
}

main "$@"