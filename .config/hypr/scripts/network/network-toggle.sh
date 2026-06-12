#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — NETWORK TOGGLE                               ║
# ║           Quick toggle for WiFi, Bluetooth, VPN with Rofi menu            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/network.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

get_wifi_status() {
    local state
    state=$(nmcli radio wifi 2>/dev/null || echo "unavailable")
    if [[ "${state}" == "enabled" ]]; then
        local ssid
        ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
            | grep "^yes" | cut -d: -f2 | head -1 || echo "")
        [[ -n "${ssid}" ]] && echo "󰤨 WiFi: ${ssid}" || echo "󰤭 WiFi: On"
    else
        echo "󰖪 WiFi: Off"
    fi
}

get_bt_status() {
    if command -v bluetoothctl &>/dev/null; then
        local powered
        powered=$(bluetoothctl show 2>/dev/null | grep "Powered: yes" || echo "")
        if [[ -n "${powered}" ]]; then
            local connected
            connected=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{print $3}')
            [[ -n "${connected}" ]] && echo "󰂱 BT: ${connected}" || echo "󰂯 BT: On"
        else
            echo "󰂲 BT: Off"
        fi
    else
        echo "󰂲 BT: N/A"
    fi
}

main() {
    local action="${1:-menu}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        menu | "")
            local wifi_status bt_status
            wifi_status=$(get_wifi_status)
            bt_status=$(get_bt_status)

            local selected
            selected=$(printf '%s\n%s\n%s\n%s\n%s\n%s\n%s' \
                "${wifi_status}" \
                "󰀂 WiFi: Connect to network" \
                "${bt_status}" \
                "󰌿 Bluetooth: Pair device" \
                "──────────────────" \
                "󰖩 Open NetworkManager" \
                "❌ Close" \
                | rofi \
                    -dmenu \
                    -i \
                    -p "🌐 Network" \
                    -theme-str 'window { width: 420px; } listview { lines: 7; }' \
                    2>/dev/null) || exit 0

            case "${selected}" in
                *"WiFi:"*"On"* | *"WiFi:"*ssid*)
                    ~/.config/hypr/scripts/network/wifi-toggle.sh toggle
                    ;;
                *"Connect to network"*)
                    ~/.config/hypr/scripts/network/wifi-toggle.sh connect
                    ;;
                *"BT:"*"On"* | *"BT:"*device*)
                    ~/.config/hypr/scripts/network/bluetooth-toggle.sh toggle
                    ;;
                *"Pair device"*)
                    ~/.config/hypr/scripts/network/bluetooth-toggle.sh connect
                    ;;
                *"NetworkManager"*)
                    nm-connection-editor &>/dev/null &
                    disown
                    ;;
            esac
            ;;

        wifi)
            ~/.config/hypr/scripts/network/wifi-toggle.sh toggle
            ;;
        bluetooth)
            ~/.config/hypr/scripts/network/bluetooth-toggle.sh toggle
            ;;
        *)
            echo "Usage: network-toggle.sh [menu|wifi|bluetooth]"
            exit 1
            ;;
    esac
}

main "$@"