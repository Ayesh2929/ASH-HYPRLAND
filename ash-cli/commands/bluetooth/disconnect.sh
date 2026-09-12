#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bluetooth disconnect                                     ║
# ║  Disconnect device(s) with animated fade-out and optional session save           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BT_DISCONNECT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BT_DISCONNECT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_disconnect_animation() {
    local name="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        local states=( '🔌' '🔵' '📡' '  ' )
        for state in "${states[@]}"; do
            printf '\r  %s  %sDisconnecting %s%s%s...' \
                "$state" \
                "$(_btdim)" "$(_btsky)" "$name" "$(_btr)"
            sleep 0.2
        done
        printf '\r  %-60s\n' ""
    fi
}

ash_bt_disconnect() {
    local target_mac=""  disconnect_all=0

    for arg in "${@:-}"; do
        case "$arg" in
            --all|-a) disconnect_all=1 ;;
            [0-9A-Fa-f:]{17}) target_mac="${arg^^}" ;;
        esac
    done

    bt_section "⛔" "Bluetooth Disconnect" "$(_btred)"

    if [[ $disconnect_all -eq 1 ]]; then
        bt_step "Disconnecting all connected devices..."
        local disconnected=0

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local mac name
            mac="$(printf '%s'  "$line" | awk '{print $2}')"
            name="$(printf '%s' "$line" | awk '{$1=$2=""; print}' | sed 's/^ *//')"

            _disconnect_animation "$name"
            bluetoothctl disconnect "$mac" &>/dev/null && {
                bt_ok "Disconnected: ${name}"
                (( disconnected++ )) || true
            }
        done < <(bluetoothctl devices Connected 2>/dev/null | grep '^Device')

        (( disconnected == 0 )) && bt_info "No connected devices found"
        printf '\n'; return 0
    fi

    # Interactive picker from connected devices
    if [[ -z "$target_mac" ]]; then
        local connected_list=""
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local mac name
            mac="$(printf '%s'  "$line" | awk '{print $2}')"
            name="$(printf '%s' "$line" | awk '{$1=$2=""; print}' | sed 's/^ *//')"
            local icon
            icon="$(bt_device_icon "" "$name")"
            connected_list+="${mac}  ${icon} ${name}\n"
        done < <(bluetoothctl devices Connected 2>/dev/null | grep '^Device')

        if [[ -z "$connected_list" ]]; then
            bt_info "No devices currently connected"
            printf '\n'; return 0
        fi

        if command -v fzf &>/dev/null; then
            target_mac="$(printf '%b' "$connected_list" | \
                fzf --prompt "  ⛔  Disconnect device: " \
                    --height=12 \
                    --border=rounded \
                    --color="hl:$(_btred | sed 's/\033\[//;s/m//')" \
                    --header="ESC=cancel" \
                    2>/dev/null | awk '{print $1}')"
        else
            printf '\n  %sConnected devices:%s\n' "$(_btdim)" "$(_btr)"
            local i=0
            local -a macs=()
            while IFS= read -r dline; do
                [[ -z "$dline" ]] && continue
                local dmac="${dline%% *}"
                local dname="${dline#* }"
                (( i++ )) || true
                macs+=("$dmac")
                printf '    %s%d%s  %s\n' "$(_btpeach)" "$i" "$(_btr)" "$dname"
            done <<< "$(printf '%b' "$connected_list")"

            printf '\n  %sEnter number [1-%d]: %s' "$(_btyellow)" "$i" "$(_btr)"
            local choice; read -r choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && \
               (( choice >= 1 )) && (( choice <= ${#macs[@]} )); then
                target_mac="${macs[$((choice-1))]}"
            fi
        fi
    fi

    [[ -z "$target_mac" ]] && { bt_info "No device selected"; printf '\n'; return 0; }

    local device_name
    device_name="$(bluetoothctl info "$target_mac" 2>/dev/null | \
                   grep 'Name:' | head -1 | awk '{$1=""; print}' | sed 's/^ //')"
    [[ -z "$device_name" ]] && device_name="$target_mac"

    local device_icon
    device_icon="$(bt_device_icon "" "$device_name")"

    bt_kv "Device" "${device_icon}  ${device_name}"
    bt_kv "MAC"    "$target_mac"

    if ! bt_is_connected "$target_mac"; then
        bt_info "Device is not connected: ${device_name}"
        printf '\n'; return 0
    fi

    _disconnect_animation "$device_name"

    if bluetoothctl disconnect "$target_mac" &>/dev/null; then
        bt_ok "Disconnected: ${device_name}"
        bt_notify "⛔ Disconnected" "${device_icon} ${device_name}"
    else
        bt_fail "Failed to disconnect: ${device_name}"
        return 1
    fi

    printf '\n'
}
