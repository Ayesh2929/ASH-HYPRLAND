#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bluetooth connect                                        ║
# ║  Connect to paired device with retry logic, fzf picker, and audio profile set   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BT_CONNECT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BT_CONNECT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONNECT ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_connect_animation() {
    local name="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
        local dots=( '📡' '📡' '🔵' '🔵' '🔌' )
        for (( i=0; i<25; i++ )); do
            local frame="${frames[$((i % ${#frames[@]}))]}"
            local dot="${dots[$((i % ${#dots[@]}))]}"
            printf '\r  %s%s%s  %s Connecting to %s%s%s%s...' \
                "$(_btblue)" "$frame" "$(_btr)" \
                "$dot" \
                "$(_btsky)$(_btbold)" "$name" "$(_btr)" ""
            sleep 0.12
        done
        printf '\r  %-60s\n' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PAIRED DEVICE PICKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_connect_pick_device() {
    # Get paired (but not connected) devices
    local device_list=""

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mac name
        mac="$(printf '%s' "$line"  | awk '{print $2}')"
        name="$(printf '%s' "$line" | awk '{$1=$2=""; print}' | sed 's/^ *//')"

        local is_connected
        is_connected="$(bluetoothctl info "$mac" 2>/dev/null | \
                        grep 'Connected:' | awk '{print $2}')"

        [[ "$is_connected" == "yes" ]] && continue  # skip already connected

        local icon
        icon="$(bt_device_icon "" "$name")"
        local conn_mark=" "
        [[ "$is_connected" == "yes" ]] && conn_mark="★"

        device_list+="${mac}  ${icon} ${name}\n"
    done < <(bluetoothctl devices Paired 2>/dev/null | grep '^Device')

    if [[ -z "$device_list" ]]; then
        bt_info "No paired devices available to connect"
        bt_info "Pair first: ash bt pair"
        return 1
    fi

    if command -v fzf &>/dev/null; then
        printf '%b' "$device_list" | \
            fzf --prompt "  🔌  Select device: " \
                --height=15 \
                --border=rounded \
                --color="hl:$(_btmauve | sed 's/\033\[//;s/m//')" \
                --header="↵=connect  ESC=cancel" \
                2>/dev/null | awk '{print $1}'
    else
        printf '\n  %sPaired devices:%s\n\n' "$(_btdim)" "$(_btr)"
        local i=0
        local -a macs=()
        while IFS= read -r dline; do
            [[ -z "$dline" ]] && continue
            local dmac dname
            dmac="$(printf '%s' "$dline" | awk '{print $1}')"
            dname="$(printf '%s' "$dline" | cut -d' ' -f3-)"
            (( i++ )) || true
            macs+=("$dmac")
            printf '    %s%d%s  %s\n' "$(_btpeach)" "$i" "$(_btr)" "$dname  ($dmac)"
        done <<< "$(printf '%b' "$device_list")"

        printf '\n  %sEnter number [1-%d]: %s' "$(_btyellow)" "$i" "$(_btr)"
        local choice; read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 )) && \
           (( choice <= ${#macs[@]} )); then
            printf '%s' "${macs[$((choice-1))]}"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  AUDIO PROFILE SETTER  (for headphones/speakers)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_connect_set_audio_profile() {
    local mac="$1"  name="$2"

    # Detect if it's an audio device
    local icon_str
    icon_str="$(bluetoothctl info "$mac" 2>/dev/null | grep 'Icon:' | awk '{print $2}')"

    [[ "$icon_str" =~ audio|headphone|headset|speaker ]] || return 0

    bt_step "Configuring audio profile for: ${name}..."

    # Wait for PipeWire to register the device
    sleep 1

    # Set A2DP profile (high quality audio) via pactl/wpctl
    if command -v pactl &>/dev/null; then
        local card_name
        card_name="$(pactl list cards short 2>/dev/null | \
                     grep -i "bluez" | head -1 | awk '{print $2}')"

        if [[ -n "$card_name" ]]; then
            pactl set-card-profile "$card_name" \
                "a2dp_sink" 2>/dev/null && \
                bt_ok "Audio profile set: A2DP (high quality)" || \
                bt_info "Using default audio profile"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bt_connect() {
    local target_mac=""  max_retries=3  set_audio=1

    for arg in "${@:-}"; do
        case "$arg" in
            --retries=*)   max_retries="${arg#*=}"   ;;
            --no-audio)    set_audio=0               ;;
            [0-9A-Fa-f:]{17}) target_mac="${arg^^}"  ;;
            *)
                # Try to match by partial name
                if [[ -z "$target_mac" ]]; then
                    local matched
                    matched="$(bluetoothctl devices Paired 2>/dev/null | \
                               grep -i "$arg" | awk '{print $2}' | head -1)"
                    [[ -n "$matched" ]] && target_mac="$matched"
                fi
                ;;
        esac
    done

    bt_section "🔌" "Bluetooth Connect" "$(_btgreen)"

    # Interactive picker if no MAC given
    if [[ -z "$target_mac" ]]; then
        target_mac="$(_connect_pick_device)"
    fi

    if [[ -z "$target_mac" ]]; then
        bt_info "No device selected"
        printf '\n'; return 0
    fi

    # Validate MAC format
    if ! [[ "$target_mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
        bt_fail "Invalid MAC address: ${target_mac}"
        return 1
    fi

    # Get device name
    local device_name
    device_name="$(bluetoothctl info "$target_mac" 2>/dev/null | \
                   grep 'Name:' | head -1 | awk '{$1=""; print}' | sed 's/^ //')"
    [[ -z "$device_name" ]] && device_name="$target_mac"

    local device_icon
    device_icon="$(bt_device_icon "" "$device_name")"

    bt_kv "Device" "${device_icon}  ${device_name}"
    bt_kv "MAC"    "$target_mac"

    # Check if already connected
    if bt_is_connected "$target_mac"; then
        bt_info "Already connected to: ${device_name}"
        printf '\n'; return 0
    fi

    # Check if paired
    if ! bt_is_paired "$target_mac"; then
        bt_warn "Device not paired: ${device_name}"
        bt_info "Pair first: ash bt pair ${target_mac}"
        if [[ "${ASH_FLAG_YES:-0}" -eq 1 ]]; then
            _bt_load_sub pair &>/dev/null || true
            ash_bt_pair "$target_mac"
            return $?
        fi
        return 1
    fi

    # Connection attempt with retries
    local attempt=0  connected=0

    while (( attempt < max_retries )) && [[ $connected -eq 0 ]]; do
        (( attempt++ )) || true

        if (( attempt > 1 )); then
            bt_step "Retry ${attempt}/${max_retries}..."
            sleep 1
        fi

        _connect_animation "$device_name"

        if timeout "${BT_TIMEOUT:-10}" bluetoothctl connect "$target_mac" \
           &>/dev/null 2>&1; then
            sleep 0.5
            if bt_is_connected "$target_mac"; then
                connected=1
            fi
        fi
    done

    if [[ $connected -eq 1 ]]; then
        bt_ok "Connected to: ${device_name}"

        # Battery level if supported
        local battery
        battery="$(bluetoothctl info "$target_mac" 2>/dev/null | \
                   grep 'Battery Percentage:' | grep -oP '\d+%' | head -1)"
        [[ -n "$battery" ]] && bt_kv "Battery" "$battery" "$(_btgreen)"

        # Configure audio profile
        [[ $set_audio -eq 1 ]] && _connect_set_audio_profile "$target_mac" "$device_name"

        bt_notify "🔌 Connected" "${device_icon} ${device_name}"
    else
        bt_fail "Failed to connect after ${max_retries} attempts"
        bt_info "Make sure the device is powered on and in range"
        return 1
    fi

    printf '\n'
}
