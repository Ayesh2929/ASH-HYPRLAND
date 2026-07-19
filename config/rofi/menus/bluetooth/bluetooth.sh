#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Bluetooth Manager Script                          ║
# ║                                                                              ║
# ║  Complete Bluetooth device management via bluetoothctl.                    ║
# ║  Manages: pairing, connecting, disconnecting, trusting, scanning,          ║
# ║  power control and device battery display.                                  ║
# ║                                                                              ║
# ║  ROFI_RETV protocol:                                                         ║
# ║    0 = init (print menu)                                                    ║
# ║    1 = entry selected                                                        ║
# ║    2 = custom input                                                          ║
# ║   10 = Ctrl+R (scan)                                                        ║
# ║   11 = Ctrl+D (disconnect)                                                  ║
# ║   12 = Ctrl+T (toggle power)                                                ║
# ║   13 = Ctrl+P (pair mode)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly SCAN_DURATION=10       # Seconds to scan for devices
readonly CONNECT_TIMEOUT=15     # Seconds to wait for connection
readonly CACHE_DIR="${HOME}/.cache/ash-dotfiles"
readonly SCAN_CACHE="${CACHE_DIR}/bt-scan.cache"
readonly SCAN_CACHE_AGE=30      # Seconds before scan cache expires

# ══════════════════════════════════════════════════════════════════════════════
# §02  DEVICE TYPE → ICON MAP
# ══════════════════════════════════════════════════════════════════════════════

get_device_icon() {
    local class="${1:-}" name="${2:-}"
    local name_lower="${name,,}"

    # Name-based detection (more reliable than class codes)
    if   [[ "$name_lower" =~ airpod|earbud|pod|buds|galaxy.buds ]]; then echo "󰟗"
    elif [[ "$name_lower" =~ headphone|wh-|wf-|xm[0-9]|h[0-9]+|hd[0-9]+ ]]; then echo "󰋋"
    elif [[ "$name_lower" =~ headset|jabra|plantronics|sennheiser ]]; then echo "󰥰"
    elif [[ "$name_lower" =~ speaker|soundbar|boom|jbl|bose|sonos ]]; then echo "󰓃"
    elif [[ "$name_lower" =~ keyboard|kbd|hhkb|realforce|keychron|anne ]]; then echo "󰌌"
    elif [[ "$name_lower" =~ mouse|mx.master|trackpad|trackball ]]; then echo "󰍽"
    elif [[ "$name_lower" =~ iphone|android|pixel|galaxy.s|oneplus ]]; then echo "󰏲"
    elif [[ "$name_lower" =~ watch|band|ring|fitbit|garmin ]]; then echo "󰐻"
    elif [[ "$name_lower" =~ gamepad|controller|dual.sense|xbox|joy.con ]]; then echo "󰊴"
    elif [[ "$name_lower" =~ car|auto|vehicle ]]; then echo "󰄋"
    elif [[ "$name_lower" =~ laptop|macbook|thinkpad|framework ]]; then echo "󰊠"
    # Class-based fallback
    elif [[ "$class" =~ 0x240[0-9] ]]; then echo "󰏲"   # Phone
    elif [[ "$class" =~ 0x400[0-9] ]]; then echo "󰊠"   # Computer
    elif [[ "$class" =~ 0x200[0-9] ]]; then echo "󰋎"   # Audio/Video
    elif [[ "$class" =~ 0x500[0-9] ]]; then echo "󱅎"   # Peripheral
    else echo "󰴕"                                         # Unknown
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  BLUETOOTHCTL WRAPPERS
# ══════════════════════════════════════════════════════════════════════════════

bt_cmd() {
    bluetoothctl "$@" 2>/dev/null
}

bt_is_powered() {
    bt_cmd show | grep -q "Powered: yes"
}

bt_is_scanning() {
    bt_cmd show | grep -q "Discovering: yes"
}

bt_power_on() {
    bt_cmd power on &>/dev/null
    sleep 0.5
}

bt_power_off() {
    bt_cmd power off &>/dev/null
}

bt_toggle_power() {
    if bt_is_powered; then
        bt_power_off
        notify_bt "󰂲 Bluetooth OFF" "" "normal"
    else
        bt_power_on
        notify_bt "󰂯 Bluetooth ON" "" "normal"
    fi
}

bt_get_controller_info() {
    bt_cmd show 2>/dev/null
}

bt_get_paired_devices() {
    bt_cmd paired-devices 2>/dev/null | grep "^Device" || true
}

bt_get_connected_devices() {
    bt_cmd devices Connected 2>/dev/null | grep "^Device" || true
}

bt_scan_devices() {
    # Start scan, collect for SCAN_DURATION seconds
    (
        bt_cmd scan on &>/dev/null
        sleep "$SCAN_DURATION"
        bt_cmd scan off &>/dev/null
    ) &>/dev/null &
    disown
}

bt_device_info() {
    local mac="$1"
    bt_cmd info "$mac" 2>/dev/null
}

bt_is_connected() {
    local mac="$1"
    bt_cmd info "$mac" 2>/dev/null | grep -q "Connected: yes"
}

bt_is_paired() {
    local mac="$1"
    bt_cmd info "$mac" 2>/dev/null | grep -q "Paired: yes"
}

bt_is_trusted() {
    local mac="$1"
    bt_cmd info "$mac" 2>/dev/null | grep -q "Trusted: yes"
}

bt_get_battery() {
    local mac="$1"
    # Try multiple battery sources
    # 1. UPower
    local upow_path
    upow_path=$(upower -e 2>/dev/null | grep -i "bluetooth_dev_${mac//:/_}" | head -1 || true)
    if [[ -n "$upow_path" ]]; then
        local pct
        pct=$(upower -i "$upow_path" 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%' || true)
        [[ -n "$pct" ]] && echo "$pct" && return
    fi

    # 2. sysfs
    local sysfs_path="/sys/class/power_supply/hid-${mac,,}-battery"
    if [[ -f "${sysfs_path}/capacity" ]]; then
        cat "${sysfs_path}/capacity" 2>/dev/null && return
    fi

    # 3. bluetoothctl battery info
    local bat
    bat=$(bt_cmd info "$mac" 2>/dev/null | grep -i "battery" | grep -oP '\d+' | head -1 || true)
    [[ -n "$bat" ]] && echo "$bat" && return

    echo ""  # Not available
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_bt() {
    local title="$1" msg="$2" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Bluetooth" \
        --icon=bluetooth \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:bluetooth \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  DEVICE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

action_connect() {
    local mac="$1" name="${2:-Device}"

    notify_bt "󰂱 Connecting…" "$name" "low"

    if bt_cmd connect "$mac" &>/dev/null; then
        sleep 1
        if bt_is_connected "$mac"; then
            local bat
            bat=$(bt_get_battery "$mac")
            local bat_str=""
            [[ -n "$bat" ]] && bat_str=" 🔋 ${bat}%"
            notify_bt "󰂱 Connected" "${name}${bat_str}"
        else
            notify_bt "Connection failed" "$name" "critical"
        fi
    else
        notify_bt "Connection failed" "$name — check device is on" "critical"
    fi
}

action_disconnect() {
    local mac="$1" name="${2:-Device}"

    if bt_cmd disconnect "$mac" &>/dev/null; then
        notify_bt "󰂲 Disconnected" "$name"
    else
        notify_bt "Disconnect failed" "$name" "critical"
    fi
}

action_pair() {
    local mac="$1" name="${2:-Device}"

    notify_bt "Pairing…" "$name — accept prompt on device" "normal"

    # Trust first for easier pairing
    bt_cmd trust "$mac" &>/dev/null || true

    if timeout "$CONNECT_TIMEOUT" bt_cmd pair "$mac" &>/dev/null; then
        notify_bt "Paired!" "$name"
        # Auto-connect after pairing
        action_connect "$mac" "$name"
    else
        notify_bt "Pairing failed" "$name — try again or check device" "critical"
    fi
}

action_unpair() {
    local mac="$1" name="${2:-Device}"

    # Disconnect first
    bt_is_connected "$mac" && action_disconnect "$mac" "$name"

    if bt_cmd remove "$mac" &>/dev/null; then
        notify_bt "Removed" "$name unpaired"
    else
        notify_bt "Remove failed" "$name" "critical"
    fi
}

action_trust() {
    local mac="$1" name="${2:-Device}"
    bt_cmd trust "$mac" &>/dev/null && \
        notify_bt "Trusted" "$name"
}

action_untrust() {
    local mac="$1" name="${2:-Device}"
    bt_cmd untrust "$mac" &>/dev/null && \
        notify_bt "Untrusted" "$name"
}

action_toggle() {
    local mac="$1" name="${2:-Device}"

    if bt_is_connected "$mac"; then
        action_disconnect "$mac" "$name"
    else
        action_connect "$mac" "$name"
    fi
}

action_scan() {
    notify_bt "󰓻 Scanning" "Looking for nearby devices (${SCAN_DURATION}s)…" "low"
    bt_scan_devices
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  DEVICE CONTEXT MENU (sub-menu for device actions)
# ══════════════════════════════════════════════════════════════════════════════

show_device_context_menu() {
    local mac="$1" name="${2:-Device}"
    local icon
    icon=$(get_device_icon "" "$name")

    local is_connected is_paired is_trusted
    bt_is_connected "$mac" && is_connected=true || is_connected=false
    bt_is_paired "$mac"    && is_paired=true   || is_paired=false
    bt_is_trusted "$mac"   && is_trusted=true  || is_trusted=false

    local bat
    bat=$(bt_get_battery "$mac")

    # Build context menu
    local entries=()

    $is_connected && \
        entries+=("󰂲  Disconnect") || \
        entries+=("󰂱  Connect")

    $is_paired && \
        entries+=("󰚞  Unpair / Remove")

    $is_trusted && \
        entries+=("  Untrust") || \
        entries+=("  Trust")

    entries+=(
        "󰞇  Device Info"
        "󰆏  Copy MAC Address"
        "───"
        "✖  Cancel"
    )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" | \
        rofi \
            -dmenu \
            -p "${icon} ${name}" \
            -mesg "MAC: <b>${mac}</b>${bat:+  🔋 ${bat}%}" \
            -theme-str "
                window { width: 320px; height: 0px; }
                listview { lines: $(( ${#entries[@]} + 1 )); columns: 1; }
                element { padding: 9px 16px; border-radius: 8px; }
                element selected.normal { background-color: #89b4fa; text-color: #1e1e2e; }
            " \
            2>/dev/null || echo "✖  Cancel")

    case "$choice" in
        "󰂱  Connect")          action_connect    "$mac" "$name" ;;
        "󰂲  Disconnect")       action_disconnect "$mac" "$name" ;;
        "󰚞  Unpair / Remove")  action_unpair     "$mac" "$name" ;;
        "  Trust")             action_trust      "$mac" "$name" ;;
        "  Untrust")           action_untrust    "$mac" "$name" ;;
        "󰞇  Device Info")
            local info
            info=$(bt_device_info "$mac")
            notify_bt "${icon} ${name}" "$info" "low"
            ;;
        "󰆏  Copy MAC Address")
            echo -n "$mac" | wl-copy 2>/dev/null || true
            notify_bt "Copied" "MAC: $mac"
            ;;
        *)  ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_paired_entries() {
    local devices
    devices=$(bt_get_paired_devices)

    if [[ -z "$devices" ]]; then
        printf '  No paired devices — press Ctrl+R to scan\0nonselectable\x1ftrue\n'
        return
    fi

    printf '─── PAIRED DEVICES ──────────────────\0nonselectable\x1ftrue\n'

    while IFS=' ' read -r _ mac name_rest; do
        local name="$name_rest"
        [[ -z "$mac" ]] && continue

        local icon
        icon=$(get_device_icon "" "$name")

        local connected_str=""
        local status_icon=""
        local bat_str=""

        if bt_is_connected "$mac"; then
            connected_str="● Connected"
            status_icon="<span color='#a6e3a1'><b>● Connected</b></span>"
            local bat
            bat=$(bt_get_battery "$mac")
            [[ -n "$bat" ]] && bat_str="  🔋 ${bat}%"
        elif bt_is_trusted "$mac"; then
            status_icon="<span color='#89b4fa'>○ Trusted</span>"
        else
            status_icon="<span color='#6c7086'>○ Paired</span>"
        fi

        # Format: "ICON  NAME                    STATUS       BATTERY"
        local display
        display=$(printf '%s  %-32s  %s%s' \
            "$icon" \
            "${name:0:30}" \
            "$connected_str" \
            "$bat_str")

        printf '%s\0info\x1fdevice-action\x1fmeta\x1f%s|%s\n' \
            "$display" "$mac" "$name"

    done <<< "$devices"
}

build_nearby_entries() {
    # Show recently scanned nearby (non-paired) devices
    local all_devices
    all_devices=$(bt_cmd devices 2>/dev/null | grep "^Device" || true)

    local paired_macs
    paired_macs=$(bt_get_paired_devices | awk '{print $2}')

    local count=0

    while IFS=' ' read -r _ mac name_rest; do
        local name="$name_rest"
        [[ -z "$mac" ]] && continue

        # Skip already paired
        echo "$paired_macs" | grep -q "$mac" && continue

        [[ "$count" -eq 0 ]] && \
            printf '─── NEARBY DEVICES ──────────────────\0nonselectable\x1ftrue\n'

        local icon
        icon=$(get_device_icon "" "$name")

        local display
        display=$(printf '%s  %-32s  %s' \
            "$icon" \
            "${name:0:30}" \
            "$mac")

        printf '%s\0info\x1fdevice-pair\x1fmeta\x1f%s|%s\n' \
            "$display" "$mac" "$name"

        (( count++ )) || true
        [[ $count -ge 8 ]] && break
    done <<< "$all_devices"
}

build_action_entries() {
    printf '─── ACTIONS ─────────────────────────\0nonselectable\x1ftrue\n'

    if bt_is_powered; then
        printf '⏻  Power OFF\0info\x1fpower-off\n'
        if bt_is_scanning; then
            printf '󰓻  Stop Scanning\0info\x1fscan-stop\n'
        else
            printf '󰓻  Scan for Devices  (Ctrl+R)\0info\x1fscan\n'
        fi
        printf '  Discoverable: Toggle\0info\x1fdiscoverable\n'
    else
        printf '⏻  Power ON\0info\x1fpower-on\n'
    fi

    printf '  Open Blueman Manager\0info\x1fblueman\n'
}

build_menu() {
    if ! bt_is_powered; then
        printf '󰂲  Bluetooth is OFF\0nonselectable\x1ftrue\n'
        printf '⏻  Turn Bluetooth ON\0info\x1fpower-on\n'
        return
    fi

    build_paired_entries
    build_nearby_entries
    build_action_entries
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        # ── Device actions ─────────────────────────────────────────────────────
        device-action)
            IFS='|' read -r mac name <<< "$meta"
            [[ -n "$mac" ]] && show_device_context_menu "$mac" "$name"
            ;;

        device-pair)
            IFS='|' read -r mac name <<< "$meta"
            [[ -n "$mac" ]] && action_pair "$mac" "$name"
            ;;

        # ── Power ──────────────────────────────────────────────────────────────
        power-on)   bt_power_on;  notify_bt "󰂯 Bluetooth ON"  "" "normal" ;;
        power-off)  bt_power_off; notify_bt "󰂲 Bluetooth OFF" "" "normal" ;;
        power)      bt_toggle_power ;;

        # ── Scanning ───────────────────────────────────────────────────────────
        scan)       action_scan ;;
        scan-stop)  bt_cmd scan off &>/dev/null; notify_bt "Scan stopped" "" "low" ;;

        # ── Discoverable ───────────────────────────────────────────────────────
        discoverable)
            if bt_cmd show | grep -q "Discoverable: yes"; then
                bt_cmd discoverable off &>/dev/null
                notify_bt "Discoverable: OFF" "" "low"
            else
                bt_cmd discoverable on &>/dev/null
                bt_cmd discoverable-timeout 120 &>/dev/null
                notify_bt "Discoverable: ON" "Visible for 2 minutes" "normal"
            fi
            ;;

        # ── Blueman ────────────────────────────────────────────────────────────
        blueman)
            command -v blueman-manager &>/dev/null && \
                blueman-manager &>/dev/null & disown || \
                notify_bt "Error" "blueman not installed" "critical"
            ;;

        # ── Non-selectable (section headers) ──────────────────────────────────
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --connect)      [[ -n "${2:-}" ]] && action_connect    "$2" "${3:-Device}" ;;
        --disconnect)   [[ -n "${2:-}" ]] && action_disconnect "$2" "${3:-Device}" ;;
        --pair)         [[ -n "${2:-}" ]] && action_pair       "$2" "${3:-Device}" ;;
        --unpair)       [[ -n "${2:-}" ]] && action_unpair     "$2" "${3:-Device}" ;;
        --scan)         action_scan ;;
        --power-on)     bt_power_on  && notify_bt "󰂯 Bluetooth ON"  "" ;;
        --power-off)    bt_power_off && notify_bt "󰂲 Bluetooth OFF" "" ;;
        --toggle)       bt_toggle_power ;;
        --status)
            echo "Powered: $(bt_is_powered && echo yes || echo no)"
            echo "Scanning: $(bt_is_scanning && echo yes || echo no)"
            bt_get_paired_devices
            ;;
        --list)         bt_get_paired_devices ;;
        --help|-h)
            echo "ASH Bluetooth Manager v5.0"
            echo ""
            echo "Usage: bluetooth.sh [OPTION] [MAC] [NAME]"
            echo ""
            echo "Options:"
            echo "  --connect MAC [NAME]     Connect to device"
            echo "  --disconnect MAC [NAME]  Disconnect device"
            echo "  --pair MAC [NAME]        Pair new device"
            echo "  --unpair MAC [NAME]      Remove paired device"
            echo "  --scan                   Scan for nearby devices"
            echo "  --power-on               Enable Bluetooth"
            echo "  --power-off              Disable Bluetooth"
            echo "  --toggle                 Toggle Bluetooth power"
            echo "  --status                 Show controller status"
            echo "  --list                   List paired devices"
            echo ""
            echo "No args: Launch Rofi Bluetooth menu"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

# ── Direct invocation (no Rofi) ───────────────────────────────────────────────
if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" "${3:-}" 2>/dev/null || true

    rofi \
        -show bt \
        -modi "bt:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/bluetooth/bluetooth.rasi" \
        2>/dev/null
    exit 0
fi

# ── Initialization ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_menu
    exit 0
fi

# ── Entry selected ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# ── Ctrl+R: Scan ──────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    action_scan
    build_menu
    exit 0
fi

# ── Ctrl+D: Disconnect all ─────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    bt_get_connected_devices | while IFS=' ' read -r _ mac name_rest; do
        action_disconnect "$mac" "$name_rest"
    done
    build_menu
    exit 0
fi

# ── Ctrl+T: Toggle power ──────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    bt_toggle_power
    build_menu
    exit 0
fi

# ── Ctrl+P: Pairing mode ──────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    action_scan
    build_menu
    exit 0
fi

# ── Re-filter / custom input ──────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_menu
    exit 0
fi