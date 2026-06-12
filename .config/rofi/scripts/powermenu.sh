#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI POWER MENU                              ║
# ║           Beautiful power menu with confirmation dialogs                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"
readonly LOCK_SCRIPT="${HOME}/.config/hypr/scripts/system/lock.sh"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME
# ═══════════════════════════════════════════════════════════════════════════════

POWER_THEME='
* {
    background-color: transparent;
    text-color:       #cdd6f4;
    font:             "JetBrainsMono Nerd Font Bold 14";
}
window {
    background-color: #1e1e2eee;
    border:           2px solid #f38ba8;
    border-radius:    20px;
    padding:          24px;
    width:            420px;
}
mainbox {
    background-color: transparent;
    spacing:          12px;
}
inputbar {
    enabled: false;
}
listview {
    background-color: transparent;
    columns:          1;
    lines:            7;
    spacing:          8px;
}
element {
    background-color: transparent;
    border-radius:    12px;
    padding:          12px 20px;
    orientation:      horizontal;
    spacing:          14px;
}
element normal.normal {
    background-color: transparent;
    text-color:       #cdd6f4;
}
element selected.normal {
    background-color: #f38ba822;
    text-color:       #f38ba8;
    border:           1px solid #f38ba8;
}
element-icon {
    background-color: transparent;
    size:             28px;
    vertical-align:   0.5;
}
element-text {
    background-color: transparent;
    text-color:       inherit;
    vertical-align:   0.5;
}
'

# ═══════════════════════════════════════════════════════════════════════════════
# ⚡ POWER ACTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Menu options with icons
declare -A ACTIONS
ACTIONS=(
    ["🔒  Lock Screen"]="lock"
    ["💤  Suspend"]="suspend"
    ["⎋   Log Out"]="logout"
    ["🔄  Reboot"]="reboot"
    ["⏻   Shutdown"]="shutdown"
    ["🔁  Reboot to BIOS"]="bios"
    ["❌  Cancel"]="cancel"
)

# Ordered list
MENU_ITEMS=(
    "🔒  Lock Screen"
    "💤  Suspend"
    "⎋   Log Out"
    "🔄  Reboot"
    "⏻   Shutdown"
    "🔁  Reboot to BIOS"
    "❌  Cancel"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔔 CONFIRMATION
# ═══════════════════════════════════════════════════════════════════════════════

confirm_action() {
    local action="$1"
    local message="$2"

    local answer
    answer=$(echo -e "⚠️  Yes, $message\n❌  Cancel" | rofi \
        -dmenu \
        -i \
        -p "Confirm: $message?" \
        -theme-str "${POWER_THEME}" \
        -theme-str 'window { width: 380px; } listview { lines: 2; }' \
        2>/dev/null) || return 1

    [[ "${answer}" == *"Yes"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 EXECUTE ACTION
# ═══════════════════════════════════════════════════════════════════════════════

execute_action() {
    local action="$1"

    case "${action}" in
        lock)
            log "INFO" "Locking screen"
            bash "${LOCK_SCRIPT}" 2>/dev/null &
            ;;

        suspend)
            if confirm_action "suspend" "suspend"; then
                log "INFO" "Suspending"
                bash "${LOCK_SCRIPT}" suspend 2>/dev/null &
            fi
            ;;

        logout)
            if confirm_action "logout" "log out"; then
                log "INFO" "Logging out"
                # Try Hyprland first
                hyprctl dispatch exit 2>/dev/null || \
                loginctl terminate-user "${USER}" 2>/dev/null || \
                pkill -SIGKILL -u "${USER}"
            fi
            ;;

        reboot)
            if confirm_action "reboot" "reboot"; then
                log "INFO" "Rebooting"
                systemctl reboot 2>/dev/null || \
                sudo reboot 2>/dev/null
            fi
            ;;

        shutdown)
            if confirm_action "shutdown" "shut down"; then
                log "INFO" "Shutting down"
                systemctl poweroff 2>/dev/null || \
                sudo poweroff 2>/dev/null
            fi
            ;;

        bios)
            if confirm_action "reboot to BIOS" "reboot to BIOS/UEFI"; then
                log "INFO" "Rebooting to BIOS"
                systemctl reboot --firmware-setup 2>/dev/null || \
                sudo systemctl reboot --firmware-setup 2>/dev/null
            fi
            ;;

        cancel | "")
            log "INFO" "Power menu cancelled"
            return 0
            ;;

        *)
            log "WARN" "Unknown action: ${action}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Show system info in prompt
    local uptime_str
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    local prompt="⏻  ${USER}@$(hostname) · Up: ${uptime_str}"

    # Show menu
    local selected
    selected=$(printf '%s\n' "${MENU_ITEMS[@]}" | rofi \
        -dmenu \
        -i \
        -p "${prompt}" \
        -theme-str "${POWER_THEME}" \
        -selected-row 0 \
        2>/dev/null) || {
        log "INFO" "Power menu dismissed"
        exit 0
    }

    # Get action for selection
    local action="${ACTIONS[${selected}]:-cancel}"

    log "INFO" "Power menu selection: ${selected} → ${action}"
    execute_action "${action}"
}

main "$@"