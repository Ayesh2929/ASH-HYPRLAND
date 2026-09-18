#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗ ██╗     ██╗   ██╗███████╗████████╗ ██████╗  ██████╗ ████████╗██╗  ██╗  ║
# ║  ██╔══██╗██║     ██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗╚══██╔══╝██║  ██║  ║
# ║  ██████╔╝██║     ██║   ██║█████╗     ██║   ██║   ██║██║   ██║   ██║   ███████║  ║
# ║  ██╔══██╗██║     ██║   ██║██╔══╝     ██║   ██║   ██║██║   ██║   ██║   ██╔══██║  ║
# ║  ██████╔╝███████╗╚██████╔╝███████╗   ██║   ╚██████╔╝╚██████╔╝   ██║   ██║  ██║  ║
# ║  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝  ╚═╝  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw bluetooth                                             ║
# ║  Adapter info • paired devices • signal • codec • battery level                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_BLUETOOTH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_BLUETOOTH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ADAPTER DATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_read_sysfs() {
    local hci_dir="$1" field="$2"
    cat "${hci_dir}/${field}" 2>/dev/null | tr -d '\n' || printf ''
}

_bt_adapter_info() {
    local hci_dir="$1"
    local hci_name
    hci_name="$(basename "$hci_dir")"

    local address type features
    address="$( _bt_read_sysfs "$hci_dir" "address")"
    type="$(    _bt_read_sysfs "$hci_dir" "type")"
    features="$(_bt_read_sysfs "$hci_dir" "features")"

    # Firmware version from rfkill / modalias
    local modalias
    modalias="$(_bt_read_sysfs "${hci_dir}/device" "modalias" 2>/dev/null || echo '')"

    printf 'name=%s\naddress=%s\ntype=%s\nmodalias=%s\n' \
        "$hci_name" "$address" "$type" "$modalias"
}

_bt_get_controller_info() {
    # Use bluetoothctl for richer data
    command -v bluetoothctl &>/dev/null || return 1
    timeout 3 bluetoothctl show 2>/dev/null || return 1
}

_bt_get_devices() {
    command -v bluetoothctl &>/dev/null || return 1
    timeout 3 bluetoothctl devices Paired 2>/dev/null || \
    timeout 3 bluetoothctl devices 2>/dev/null | grep '^Device' || true
}

_bt_device_info() {
    local mac="$1"
    command -v bluetoothctl &>/dev/null || return 1
    timeout 3 bluetoothctl info "$mac" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE ICON BY CLASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_device_icon() {
    local icon_str="$1"
    case "${icon_str,,}" in
        *headphone*|*headset*) printf '🎧' ;;
        *speaker*|*audio*)     printf '🔊' ;;
        *keyboard*)            printf '⌨️ ' ;;
        *mouse*)               printf '🖱️ ' ;;
        *phone*)               printf '📱' ;;
        *computer*)            printf '💻' ;;
        *gaming*|*gamepad*)    printf '🎮' ;;
        *watch*)               printf '⌚' ;;
        *camera*)              printf '📷' ;;
        *)                     printf '📡' ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER PAIRED DEVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_render_devices() {
    local devices_out
    devices_out="$(_bt_get_devices 2>/dev/null || echo '')"

    [[ -z "$devices_out" ]] && {
        printf '\n  \033[38;2;108;112;134mNo paired devices\033[0m\n'
        return 0
    }

    local count=0
    while IFS= read -r line; do
        [[ "$line" =~ ^Device ]] || continue
        local mac alias
        mac="$(   printf '%s' "$line" | awk '{print $2}')"
        alias="$( printf '%s' "$line" | cut -d' ' -f3-)"

        local dev_info
        dev_info="$(_bt_device_info "$mac" 2>/dev/null || echo '')"

        local connected trusted icon rssi bat
        connected="$(printf '%s' "$dev_info" | grep 'Connected:' | awk '{print $2}')"
        trusted="$(  printf '%s' "$dev_info" | grep 'Trusted:'   | awk '{print $2}')"
        icon_str="$( printf '%s' "$dev_info" | grep 'Icon:'      | awk '{print $2}')"
        rssi="$(     printf '%s' "$dev_info" | grep 'RSSI:'      | awk '{print $2}')"
        bat="$(      printf '%s' "$dev_info" | grep 'Battery:'   | awk '{print $NF}')"

        local dev_icon
        dev_icon="$(_bt_device_icon "${icon_str:-}")"

        local conn_color conn_symbol
        if [[ "$connected" == "yes" ]]; then
            conn_color=$'\033[38;2;166;227;161m'
            conn_symbol="●  CONNECTED"
        else
            conn_color=$'\033[38;2;108;112;134m'
            conn_symbol="○  disconnected"
        fi

        printf '\n  %s%s  \033[1;38;2;137;220;235m%s\033[0m\n' \
            "$dev_icon" " " "$alias"
        printf '  \033[38;2;108;112;134m   MAC:\033[0m \033[38;2;180;190;254m%s\033[0m\n' "$mac"
        printf '  \033[38;2;108;112;134m   Status:\033[0m %s%s\033[0m\n' \
            "$conn_color" "$conn_symbol"
        [[ -n "$rssi" ]] && \
            printf '  \033[38;2;108;112;134m   RSSI:\033[0m  \033[38;2;249;226;175m%s dBm\033[0m\n' "$rssi"
        [[ -n "$bat" ]] && \
            printf '  \033[38;2;108;112;134m   Battery:\033[0m \033[38;2;166;227;161m%s\033[0m\n' "$bat"
        [[ "$trusted" == "yes" ]] && \
            printf '  \033[38;2;108;112;134m   Trusted:\033[0m  ✓\n'

        (( count++ )) || true
    done <<< "$devices_out"

    printf '\n  \033[38;2;108;112;134m%d paired device(s)\033[0m\n' "$count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_bluetooth() {
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--short" ]] && short=1
    done

    hw_section "📡" "Bluetooth" $'\033[38;2;180;190;254m'

    # ── HCI Adapters from sysfs ──────────────────────────────────────────────────
    local -a hci_devs=()
    mapfile -t hci_devs < <(
        find /sys/class/bluetooth -name 'hci*' -maxdepth 1 2>/dev/null | sort
    )

    if [[ ${#hci_devs[@]} -eq 0 ]]; then
        printf '\n  \033[38;2;249;226;175m⚠  No Bluetooth adapters detected\033[0m\n'
        hw_divider
        return 0
    fi

    for hci_dir in "${hci_devs[@]}"; do
        local hci_name
        hci_name="$(basename "$hci_dir")"
        local addr
        addr="$(_bt_read_sysfs "$hci_dir" "address")"

        printf '\n  \033[1;38;2;180;190;254m📡  %s\033[0m  \033[38;2;108;112;134m%s\033[0m\n' \
            "$hci_name" "$addr"
    done

    # ── bluetoothctl controller info ─────────────────────────────────────────────
    local ctrl_info
    ctrl_info="$(_bt_get_controller_info 2>/dev/null || echo '')"

    if [[ -n "$ctrl_info" ]]; then
        printf '\n'
        local fields=( "Name:" "Alias:" "Class:" "Powered:" "Discoverable:" "Pairable:" "UUID" )
        for field in "${fields[@]}"; do
            local val
            val="$(printf '%s' "$ctrl_info" | grep "$field" | head -1 | \
                   sed "s/.*${field}//" | sed 's/^ *//')"
            [[ -z "$val" ]] && continue
            hw_kv "${field%:}" "$val"
        done
    fi

    # ── rfkill state ─────────────────────────────────────────────────────────────
    if command -v rfkill &>/dev/null; then
        local rfk
        rfk="$(rfkill list bluetooth 2>/dev/null | \
               grep -E 'Soft blocked:|Hard blocked:' | head -4)"
        if [[ -n "$rfk" ]]; then
            printf '\n'
            while IFS= read -r rline; do
                [[ -z "$rline" ]] && continue
                printf '  \033[38;2;108;112;134m%s\033[0m\n' "$rline"
            done <<< "$rfk"
        fi
    fi

    if [[ $short -eq 0 ]]; then
        hw_section "🔗" "Paired Devices" $'\033[38;2;148;226;213m'
        _bt_render_devices

        # ── Codec support ─────────────────────────────────────────────────────────
        hw_section "🎵" "Bluetooth Audio Codecs" $'\033[38;2;203;166;247m'
        local -a codecs=( "libsbc.so:SBC (standard)" "libldacBT_enc.so:LDAC (hi-res)" \
                          "libfreeaptx.so:aptX (open)" "libaptx.so:aptX (Qualcomm)" \
                          "libLC3.so:LC3 (LE Audio)" )
        for codec_entry in "${codecs[@]}"; do
            IFS=':' read -r lib label <<< "$codec_entry"
            local found
            found="$(find /usr/lib /usr/lib64 -name "${lib}*" 2>/dev/null | head -1 || echo '')"
            if [[ -n "$found" ]]; then
                hw_kv "$label" "✓  Available"
            else
                hw_kv "$label" "✗  not installed"
            fi
        done
    fi

    hw_divider
}
