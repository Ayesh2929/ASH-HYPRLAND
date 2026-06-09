#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — BLUETOOTH TOGGLE                             ║
# ║           Bluetooth control with device picker and battery status           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: bluetooth-toggle.sh [ACTION]
#
# ACTIONS:
#   toggle   — Toggle Bluetooth on/off
#   on       — Enable Bluetooth
#   off      — Disable Bluetooth
#   connect  — Rofi device picker
#   devices  — List paired devices
#   status   — JSON status for Waybar
#   scan     — Start scanning for devices
#   manager  — Open blueman-manager

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/bluetooth.log"
readonly WAYBAR_SIGNAL=14

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[91m✗\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔵 BLUETOOTH STATE
# ═══════════════════════════════════════════════════════════════════════════════

is_bluetooth_available() {
    command -v bluetoothctl &>/dev/null && \
        systemctl is-active bluetooth &>/dev/null
}

is_powered() {
    bluetoothctl show 2>/dev/null \
        | grep -q "Powered: yes"
}

is_connected() {
    bluetoothctl info 2>/dev/null \
        | grep -q "Connected: yes"
}

get_connected_device() {
    local devices
    devices=$(bluetoothctl devices Connected 2>/dev/null)

    if [[ -n "${devices}" ]]; then
        echo "${devices}" | head -1 | awk '{print $3}'
    else
        echo ""
    fi
}

get_device_battery() {
    local mac="$1"
    bluetoothctl info "${mac}" 2>/dev/null \
        | grep "Battery Percentage" \
        | grep -oP '\d+' \
        | head -1 \
        || echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 BLUETOOTH CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

enable_bluetooth() {
    info "Enabling Bluetooth..."

    # Start service if not running
    if ! systemctl is-active bluetooth &>/dev/null; then
        sudo systemctl start bluetooth 2>/dev/null || true
        sleep 0.5
    fi

    bluetoothctl power on 2>/dev/null

    notify-send "🔵 Bluetooth Enabled" \
        "Bluetooth is now on" \
        --icon=bluetooth-symbolic \
        --app-name="ASH Bluetooth" \
        --expire-time=2000 \
        2>/dev/null || true

    signal_waybar
    log "INFO" "Bluetooth enabled"
    ok "Bluetooth enabled"
}

disable_bluetooth() {
    info "Disabling Bluetooth..."

    # Disconnect all devices first
    local connected
    connected=$(bluetoothctl devices Connected 2>/dev/null)
    if [[ -n "${connected}" ]]; then
        while IFS= read -r line; do
            local mac
            mac=$(echo "${line}" | awk '{print $2}')
            bluetoothctl disconnect "${mac}" 2>/dev/null || true
        done <<< "${connected}"
    fi

    bluetoothctl power off 2>/dev/null

    notify-send "📵 Bluetooth Disabled" \
        "Bluetooth is now off" \
        --icon=bluetooth-disabled-symbolic \
        --app-name="ASH Bluetooth" \
        --expire-time=2000 \
        2>/dev/null || true

    signal_waybar
    log "INFO" "Bluetooth disabled"
    ok "Bluetooth disabled"
}

toggle_bluetooth() {
    if ! is_bluetooth_available; then
        err "Bluetooth not available"
        notify-send "🔵 Bluetooth" \
            "Bluetooth service not available" \
            --app-name="ASH Bluetooth" \
            --urgency=critical \
            2>/dev/null || true
        return 1
    fi

    if is_powered; then
        disable_bluetooth
    else
        enable_bluetooth
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📱 DEVICE PICKER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_device_picker() {
    if ! is_powered; then
        enable_bluetooth
        sleep 1
    fi

    # Get paired devices
    local devices_raw
    devices_raw=$(bluetoothctl devices Paired 2>/dev/null)

    if [[ -z "${devices_raw}" ]]; then
        notify-send "🔵 Bluetooth" \
            "No paired devices found\nPair a device first with: bluetoothctl" \
            --app-name="ASH Bluetooth" \
            --expire-time=4000 \
            2>/dev/null || true
        return 0
    fi

    # Build device list
    local device_list=""
    declare -A device_map

    while IFS= read -r line; do
        local mac name connected_status icon
        mac=$(echo "${line}" | awk '{print $2}')
        name=$(echo "${line}" | cut -d' ' -f3-)

        # Check connection status
        if bluetoothctl info "${mac}" 2>/dev/null | grep -q "Connected: yes"; then
            icon="🔗"
            connected_status="connected"
        else
            icon="📱"
            connected_status="disconnected"
        fi

        # Get device type icon
        local type_icon="📱"
        local device_type
        device_type=$(bluetoothctl info "${mac}" 2>/dev/null \
            | grep "Icon:" | awk '{print $2}')
        case "${device_type}" in
            audio-headset | audio-headphones) type_icon="🎧" ;;
            audio-card)    type_icon="🔊" ;;
            input-keyboard) type_icon="⌨️" ;;
            input-mouse)   type_icon="🖱️" ;;
            phone)         type_icon="📱" ;;
            computer)      type_icon="💻" ;;
            *)             type_icon="📱" ;;
        esac

        # Battery info
        local battery
        battery=$(get_device_battery "${mac}")
        local bat_str=""
        [[ -n "${battery}" ]] && bat_str=" 🔋${battery}%"

        device_list+="${icon} ${type_icon} ${name}${bat_str}\0info\x1f${connected_status}\n"
        device_map["${icon} ${type_icon} ${name}${bat_str}"]="${mac}"
    done <<< "${devices_raw}"

    # Show picker with action options
    local actions="Connect/Disconnect\nForget Device\nShow Info\n---\n"
    local all_items="${actions}${device_list}"

    local selected
    selected=$(echo -e "${all_items}" | rofi \
        -dmenu \
        -i \
        -p "🔵 Bluetooth Devices" \
        -theme-str 'window { width: 500px; }' \
        -theme-str 'listview { lines: 10; }' \
        2>/dev/null) || {
        info "Picker cancelled"
        return 0
    }

    # Handle selection
    case "${selected}" in
        Connect*)   action="connect" ;;
        Forget*)    action="forget" ;;
        "Show Info") action="info" ;;
        ---)        return 0 ;;
        *)          action="toggle-connection" ;;
    esac

    if [[ "${action}" == "toggle-connection" ]]; then
        # Get MAC for selected device
        local mac="${device_map[${selected}]:-}"

        if [[ -z "${mac}" ]]; then
            err "Device not found: ${selected}"
            return 1
        fi

        local is_conn
        is_conn=$(bluetoothctl info "${mac}" 2>/dev/null | grep "Connected: yes")

        if [[ -n "${is_conn}" ]]; then
            info "Disconnecting: ${selected}"
            bluetoothctl disconnect "${mac}" 2>/dev/null
            notify-send "🔵 Bluetooth" \
                "Disconnected from: $(echo "${selected}" | sed 's/^[🔗📱] [🎧🔊⌨️🖱️💻] //')" \
                --app-name="ASH Bluetooth" --expire-time=2000 2>/dev/null || true
        else
            info "Connecting: ${selected}"
            bluetoothctl connect "${mac}" 2>/dev/null
            sleep 2
            if bluetoothctl info "${mac}" 2>/dev/null | grep -q "Connected: yes"; then
                notify-send "🔵 Bluetooth" \
                    "Connected to: $(echo "${selected}" | sed 's/^[🔗📱] [🎧🔊⌨️🖱️💻] //')" \
                    --app-name="ASH Bluetooth" --expire-time=3000 2>/dev/null || true
                ok "Connected"
            else
                notify-send "🔵 Bluetooth" \
                    "Failed to connect" \
                    --app-name="ASH Bluetooth" --urgency=normal --expire-time=3000 2>/dev/null || true
                err "Connection failed"
            fi
        fi
    fi

    signal_waybar
    log "INFO" "Device action: ${action}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📡 SIGNAL WAYBAR
# ═══════════════════════════════════════════════════════════════════════════════

signal_waybar() {
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS JSON
# ═══════════════════════════════════════════════════════════════════════════════

status_json() {
    if ! is_bluetooth_available; then
        echo '{"text": "󰂲", "class": "unavailable", "tooltip": "Bluetooth not available"}'
        return 0
    fi

    if ! is_powered; then
        echo '{"text": "󰂲", "class": "disabled", "tooltip": "Bluetooth disabled"}'
        return 0
    fi

    local connected_device
    connected_device=$(get_connected_device)

    if [[ -n "${connected_device}" ]]; then
        local connected_mac
        connected_mac=$(bluetoothctl devices Connected 2>/dev/null \
            | head -1 | awk '{print $2}')
        local battery
        battery=$(get_device_battery "${connected_mac:-}")

        local tooltip="Connected: ${connected_device}"
        [[ -n "${battery}" ]] && tooltip+="\nBattery: ${battery}%"

        local bat_text=""
        [[ -n "${battery}" ]] && bat_text=" ${battery}%"

        printf '{"text": "󰂱 %s%s", "tooltip": "%s", "class": "connected"}\n' \
            "${connected_device}" "${bat_text}" "${tooltip}"
    else
        echo '{"text": "󰂯", "class": "on", "tooltip": "Bluetooth on, no device connected"}'
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        toggle)    toggle_bluetooth ;;
        on | enable)  enable_bluetooth ;;
        off | disable) disable_bluetooth ;;
        connect)   rofi_device_picker ;;
        devices)
            bluetoothctl devices Paired 2>/dev/null || echo "No paired devices"
            ;;
        status)    status_json ;;
        scan)
            bluetoothctl scan on &
            sleep 10
            bluetoothctl scan off
            ;;
        manager)
            blueman-manager 2>/dev/null &
            disown
            ;;
        *)
            echo "Usage: bluetooth-toggle.sh [toggle|on|off|connect|devices|status|scan|manager]"
            exit 1
            ;;
    esac
}

main "$@"