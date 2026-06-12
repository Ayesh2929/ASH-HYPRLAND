#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SCRATCHPAD MANAGER                           ║
# ║           8 scratchpad types with smart toggle and Rofi manager            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/scratchpad.log"
readonly STATE_DIR="${CACHE_DIR}/scratchpads"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🗂️ SCRATCHPAD DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

declare -A SCRATCHPADS=(
    [term]="kitty --class=scratch-term"
    [files]="kitty --class=scratch-files -e yazi"
    [music]="kitty --class=scratch-music -e ncspot"
    [notes]="kitty --class=scratch-notes -e nvim ~/notes/quick.md"
    [calc]="kitty --class=scratch-calc -e python3"
    [monitor]="kitty --class=scratch-monitor -e btop"
    [git]="kitty --class=scratch-git -e lazygit"
    [logs]="kitty --class=scratch-logs -e journalctl -f"
)

declare -A SCRATCHPAD_ICONS=(
    [term]="🖥️"
    [files]="📁"
    [music]="🎵"
    [notes]="📝"
    [calc]="🧮"
    [monitor]="📊"
    [git]="🐙"
    [logs]="📋"
)

declare -A SCRATCHPAD_WORKSPACES=(
    [term]="special:scratch-term"
    [files]="special:scratch-files"
    [music]="special:music"
    [notes]="special:scratch-notes"
    [calc]="special:scratch-calc"
    [monitor]="special:scratch-monitor"
    [git]="special:scratch-git"
    [logs]="special:scratch-logs"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 SCRATCHPAD FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

is_scratchpad_open() {
    local name="$1"
    local ws="${SCRATCHPAD_WORKSPACES[${name}]:-special:${name}}"
    local ws_name="${ws#special:}"

    hyprctl clients -j 2>/dev/null \
        | jq -e --arg ws "${ws_name}" \
            '.[] | select(.workspace.name == $ws)' \
            &>/dev/null
}

scratchpad_exists() {
    local name="$1"
    local class="scratch-${name}"

    hyprctl clients -j 2>/dev/null \
        | jq -e --arg class "${class}" \
            '.[] | select(.class == $class)' \
            &>/dev/null
}

launch_scratchpad() {
    local name="$1"
    local cmd="${SCRATCHPADS[${name}]:-}"

    if [[ -z "${cmd}" ]]; then
        log "WARN" "Unknown scratchpad: ${name}"
        return 1
    fi

    local ws="${SCRATCHPAD_WORKSPACES[${name}]:-special:${name}}"
    log "INFO" "Launching scratchpad: ${name}"

    # Launch in special workspace
    hyprctl dispatch exec "[workspace ${ws} silent] ${cmd}" 2>/dev/null || true
}

toggle_scratchpad() {
    local name="$1"
    local ws="${SCRATCHPAD_WORKSPACES[${name}]:-special:${name}}"

    if is_scratchpad_open "${name}"; then
        # Already visible — hide it
        hyprctl dispatch togglespecialworkspace "${ws#special:}" 2>/dev/null || true
        log "INFO" "Scratchpad hidden: ${name}"
    else
        if scratchpad_exists "${name}"; then
            # Exists but hidden — show it
            hyprctl dispatch togglespecialworkspace "${ws#special:}" 2>/dev/null || true
            log "INFO" "Scratchpad shown: ${name}"
        else
            # Doesn't exist — launch it
            launch_scratchpad "${name}"
            sleep 0.3
            hyprctl dispatch togglespecialworkspace "${ws#special:}" 2>/dev/null || true
            log "INFO" "Scratchpad launched: ${name}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ROFI MANAGER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_manager() {
    local menu=""

    for name in term files music notes calc monitor git logs; do
        local icon="${SCRATCHPAD_ICONS[${name}]:-📋}"
        local cmd="${SCRATCHPADS[${name}]:-}"
        local status=""

        if scratchpad_exists "${name}"; then
            if is_scratchpad_open "${name}"; then
                status=" [VISIBLE]"
            else
                status=" [HIDDEN]"
            fi
        fi

        menu+="${icon}  ${name}${status}\n"
    done

    local selected
    selected=$(echo -e "${menu}" | rofi \
        -dmenu \
        -i \
        -p "🗂️ Scratchpads" \
        -theme-str '
            window { width: 450px; }
            listview { columns: 1; lines: 10; }
            element { padding: 8px 12px; font-size: 13px; }
        ' \
        2>/dev/null) || {
        log "INFO" "Scratchpad manager cancelled"
        return 0
    }

    # Extract name
    local name
    name=$(echo "${selected}" | awk '{print $2}' | cut -d'[' -f1 | tr -d ' ')

    if [[ -n "${name}" ]] && [[ -n "${SCRATCHPADS[${name}]:-}" ]]; then
        toggle_scratchpad "${name}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-manager}"
    local name="${2:-term}"

    mkdir -p "${CACHE_DIR}/logs" "${STATE_DIR}"

    case "${action}" in
        toggle | t)     toggle_scratchpad "${name}" ;;
        launch | l)     launch_scratchpad "${name}" ;;
        manager | m)    rofi_manager ;;
        list)
            for sp in "${!SCRATCHPADS[@]}"; do
                local exists="not running"
                scratchpad_exists "${sp}" 2>/dev/null && exists="running"
                printf "%-15s %s\n" "${sp}" "${exists}"
            done
            ;;
        kill)
            for sp in "${!SCRATCHPADS[@]}"; do
                local class="scratch-${sp}"
                hyprctl dispatch closewindow "class:${class}" 2>/dev/null || true
            done
            ok "All scratchpads closed"
            ;;
        *)
            echo "Usage: scratchpad.sh [toggle|launch|manager|list|kill] [name]"
            echo "Names: ${!SCRATCHPADS[*]}"
            exit 1
            ;;
    esac
}

ok() { echo -e "  \033[92m✓\033[0m $*"; }

main "$@"