#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bluetooth pair                                           ║
# ║  Full pairing wizard: scan → select → PIN entry → trust → connect              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BT_PAIR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BT_PAIR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PAIRING ANIMATION  (heartbeat pulse)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pair_animation() {
    local name="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        local frames=( '🔵' '🔵' '💙' '💙' '🔷' '🔷' '💎' '🔷' '💙' '🔵' )
        for frame in "${frames[@]}"; do
            printf '\r  %s  %sPairing with %s%s%s...' \
                "$frame" "$(_btblue)" "$(_btsky)$(_btbold)" "$name" "$(_btr)"
            sleep 0.15
        done
        printf '\r  %-60s\n' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SCAN FOR UNPAIRED DEVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pair_scan_and_pick() {
    local scan_dur="${1:-8}"

    bt_step "Scanning for devices  (${scan_dur}s)..."

    # Enable scan
    bluetoothctl scan on &>/dev/null &
    local scan_pid=$!

    # Animated countdown
    for (( i=scan_dur; i>0; i-- )); do
        printf '\r  %s◐%s  Discovering devices... %s%d%ss remaining  ' \
            "$(_btblue)" "$(_btr)" "$(_btdim)" "$i" "$(_btr)"
        sleep 1
    done
    printf '\r  %-60s\n' ""

    kill "$scan_pid" 2>/dev/null || true
    bluetoothctl scan off &>/dev/null 2>&1 || true

    # Build list of devices (exclude already paired)
    local -a unpaired_macs=()
    local -a unpaired_names=()

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mac name
        mac="$(printf '%s'  "$line" | awk '{print $2}')"
        name="$(printf '%s' "$line" | awk '{$1=$2=""; print}' | sed 's/^ *//')"

        bt_is_paired "$mac" 2>/dev/null && continue  # skip already paired

        unpaired_macs+=("$mac")
        unpaired_names+=("$name")
    done < <(bluetoothctl devices 2>/dev/null | grep '^Device')

    if [[ ${#unpaired_macs[@]} -eq 0 ]]; then
        bt_info "No unpaired devices found nearby"
        return 1
    fi

    # Display and pick
    if command -v fzf &>/dev/null; then
        local fzf_input=""
        for (( i=0; i<${#unpaired_macs[@]}; i++ )); do
            local icon
            icon="$(bt_device_icon "" "${unpaired_names[$i]}")"
            fzf_input+="${unpaired_macs[$i]}  ${icon} ${unpaired_names[$i]}\n"
        done

        printf '%b' "$fzf_input" | \
            fzf --prompt "  🔗  Select device to pair: " \
                --height=15 \
                --border=rounded \
                --color="hl:$(_btblue | sed 's/\033\[//;s/m//')" \
                --header="↵=pair  ESC=cancel" \
                2>/dev/null | awk '{print $1}'
    else
        printf '\n  %sNearby devices:%s\n\n' "$(_btdim)" "$(_btr)"
        for (( i=0; i<${#unpaired_macs[@]}; i++ )); do
            local icon
            icon="$(bt_device_icon "" "${unpaired_names[$i]}")"
            printf '    %s%d%s  %s  %s%s%s\n' \
                "$(_btpeach)" "$((i+1))" "$(_btr)" \
                "$icon" "$(_btsky)" "${unpaired_names[$i]}" "$(_btr)"
            printf '       %s%s%s\n' "$(_btdim)" "${unpaired_macs[$i]}" "$(_btr)"
        done

        printf '\n  %sEnter number [1-%d]: %s' \
            "$(_btyellow)" "${#unpaired_macs[@]}" "$(_btr)"
        local choice; read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 )) && \
           (( choice <= ${#unpaired_macs[@]} )); then
            printf '%s' "${unpaired_macs[$((choice-1))]}"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PAIRING EXECUTOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pair_execute() {
    local mac="$1"  name="$2"  timeout_s="${BT_TIMEOUT:-30}"

    bt_step "Initiating pairing with: ${name}..."
    _pair_animation "$name"

    # Use expect-free pairing via bluetoothctl
    local pair_output
    pair_output="$(timeout "$timeout_s" bluetoothctl pair "$mac" 2>&1 || true)"

    if printf '%s' "$pair_output" | grep -q 'Pairing successful\|paired\|Already paired'; then
        bt_ok "Pairing successful"
        return 0
    elif printf '%s' "$pair_output" | grep -q 'Confirm passkey\|PIN\|PassKey'; then
        # PIN confirmation required
        local pin
        pin="$(printf '%s' "$pair_output" | grep -oP '\d{6}' | head -1)"
        if [[ -n "$pin" ]]; then
            bt_kv "Passkey" "$pin  (confirm on device)"
        fi

        printf '\n  %sConfirm pairing on device? [Y/n] %s' \
            "$(_btyellow)" "$(_btr)"
        local ans; read -r ans
        if [[ "${ans,,}" != "n" ]]; then
            bluetoothctl confirm-passkey "$pin" &>/dev/null 2>&1 || true
            sleep 1
            bt_is_paired "$mac" && bt_ok "Pairing confirmed" || bt_fail "Pairing failed"
        else
            bt_info "Pairing cancelled"
            return 1
        fi
    else
        bt_fail "Pairing failed"
        printf '%s' "$pair_output" | head -3 | \
            while IFS= read -r line; do
                [[ -n "$line" ]] && printf '  %s%s%s\n' "$(_btdim)" "$line" "$(_btr)"
            done
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bt_pair() {
    local target_mac=""  auto_trust=1  auto_connect=1  scan_dur=8

    for arg in "${@:-}"; do
        case "$arg" in
            --no-trust)      auto_trust=0   ;;
            --no-connect)    auto_connect=0 ;;
            --scan=*)        scan_dur="${arg#*=}" ;;
            [0-9A-Fa-f:]{17}) target_mac="${arg^^}" ;;
        esac
    done

    bt_section "🔗" "Bluetooth Pair" "$(_btblue)"

    # Ensure BT is on
    if ! bt_is_powered; then
        bt_step "Powering on Bluetooth..."
        bt_set_power on
    fi

    # Get target MAC (interactive if not given)
    if [[ -z "$target_mac" ]]; then
        target_mac="$(_pair_scan_and_pick "$scan_dur")"
    fi

    if [[ -z "$target_mac" ]]; then
        bt_info "No device selected"
        printf '\n'; return 0
    fi

    # Validate MAC
    if ! [[ "$target_mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
        bt_fail "Invalid MAC address: ${target_mac}"
        return 1
    fi

    # Get/confirm name
    local device_name
    device_name="$(bluetoothctl info "$target_mac" 2>/dev/null | \
                   grep 'Name:' | head -1 | \
                   awk '{$1=""; print}' | sed 's/^ //')"
    [[ -z "$device_name" ]] && device_name="$target_mac"

    local device_icon
    device_icon="$(bt_device_icon "" "$device_name")"

    bt_kv "Device" "${device_icon}  ${device_name}"
    bt_kv "MAC"    "$target_mac"

    # Already paired?
    if bt_is_paired "$target_mac"; then
        bt_info "Device already paired: ${device_name}"
        if [[ $auto_connect -eq 1 ]] && ! bt_is_connected "$target_mac"; then
            bt_step "Connecting to already-paired device..."
            _bt_load_sub connect &>/dev/null || true
            ash_bt_connect "$target_mac"
        fi
        printf '\n'; return 0
    fi

    # Execute pairing
    if ! _pair_execute "$target_mac" "$device_name"; then
        printf '\n'; return 1
    fi

    # Trust device for auto-connect
    if [[ $auto_trust -eq 1 ]]; then
        bt_step "Trusting device for auto-connect..."
        bluetoothctl trust "$target_mac" &>/dev/null && \
            bt_ok "Device trusted"
    fi

    # Auto-connect
    if [[ $auto_connect -eq 1 ]]; then
        bt_step "Connecting..."
        _bt_load_sub connect &>/dev/null || true
        ash_bt_connect "$target_mac"
    fi

    bt_notify "🔗 Paired" "${device_icon} ${device_name}"

    printf '\n'
}
