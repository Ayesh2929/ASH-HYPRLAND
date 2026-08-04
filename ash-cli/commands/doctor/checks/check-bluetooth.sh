#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗     ██╗   ██╗███████╗████████╗ ██████╗  ██████╗ ████████╗██╗  ██╗  ║
# ║  ██╔══██╗██║     ██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗╚══██╔══╝██║  ██║  ║
# ║  ██████╔╝██║     ██║   ██║█████╗     ██║   ██║   ██║██║   ██║   ██║   ███████║  ║
# ║  ██╔══██╗██║     ██║   ██║██╔══╝     ██║   ██║   ██║██║   ██║   ██║   ██╔══██║  ║
# ║  ██████╔╝███████╗╚██████╔╝███████╗   ██║   ╚██████╔╝╚██████╔╝   ██║   ██║  ██║  ║
# ║  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝  ╚═╝  ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: BLUETOOTH                                 ║
# ║  BlueZ • kernel modules • rfkill • paired devices • audio codecs • power        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_BLUETOOTH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_BLUETOOTH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — HARDWARE PRESENCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_hardware() {
    _check_header "📡 Bluetooth Hardware"

    # ── USB BT adapters ──────────────────────────────────────────────────────────
    local usb_bt=""
    if command -v lsusb &>/dev/null; then
        usb_bt="$(lsusb 2>/dev/null | grep -i 'bluetooth\|broadcom.*bt\|intel.*bt\|realtek.*bt' || echo '')"
    fi

    # ── PCI BT devices ───────────────────────────────────────────────────────────
    local pci_bt=""
    if command -v lspci &>/dev/null; then
        pci_bt="$(lspci 2>/dev/null | grep -i 'bluetooth\|wireless.*bluetooth' || echo '')"
    fi

    # ── sysfs hci devices ────────────────────────────────────────────────────────
    local -a hci_devs=()
    mapfile -t hci_devs < <(find /sys/class/bluetooth -name 'hci*' \
                             -maxdepth 1 2>/dev/null | sort)

    if [[ ${#hci_devs[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "Bluetooth hardware" \
            "${#hci_devs[@]} HCI device(s) detected"

        for hci_dir in "${hci_devs[@]}"; do
            local hci_name
            hci_name="$(basename "$hci_dir")"

            # Read address
            local bt_addr
            bt_addr="$(cat "${hci_dir}/address" 2>/dev/null || echo '?')"

            # Read type
            local bt_type
            bt_type="$(cat "${hci_dir}/type" 2>/dev/null || echo '?')"

            # Read manufacturer info via modalias
            local modalias
            modalias="$(cat "${hci_dir}/device/modalias" 2>/dev/null || echo '')"

            _check_report $CHECK_INFO \
                "  Device: ${hci_name}" \
                "addr: ${bt_addr}  •  type: ${bt_type}  •  ${modalias}"
        done
    elif [[ -n "$usb_bt" ]] || [[ -n "$pci_bt" ]]; then
        _check_report $CHECK_WARN \
            "Bluetooth hardware" \
            "Hardware found but no HCI device in sysfs" \
            "Check: dmesg | grep -i bluetooth  and ensure btusb module loaded"
    else
        _check_report $CHECK_INFO \
            "Bluetooth hardware" \
            "No Bluetooth hardware detected" \
            "If you have BT, check: lsusb | grep -i bluetooth"
        return $CHECK_SKIP
    fi

    # ── USB BT device detail ─────────────────────────────────────────────────────
    if [[ -n "$usb_bt" ]]; then
        while IFS= read -r uline; do
            [[ -z "$uline" ]] && continue
            _check_report $CHECK_INFO \
                "  USB BT" \
                "$(printf '%s' "$uline" | sed 's/Bus [0-9]* Device [0-9]*: //')"
        done <<< "$usb_bt"
    fi

    # ── btusb kernel module ──────────────────────────────────────────────────────
    if lsmod 2>/dev/null | grep -q '^btusb\b'; then
        _check_report $CHECK_PASS \
            "btusb module" \
            "Loaded  (USB Bluetooth driver)"
    else
        _check_report $CHECK_INFO \
            "btusb module" \
            "Not loaded  (may use different driver for PCIe BT)"
    fi

    # ── Additional BT modules ────────────────────────────────────────────────────
    local -a bt_modules=( "bluetooth" "rfcomm" "bnep" "btbcm" "btintel" "btrtl" "btmtk" )
    local loaded_bt_mods=()
    for mod in "${bt_modules[@]}"; do
        lsmod 2>/dev/null | grep -q "^${mod}\b" && loaded_bt_mods+=("$mod")
    done

    if [[ ${#loaded_bt_mods[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "BT kernel modules" \
            "${loaded_bt_mods[*]}"
    else
        _check_report $CHECK_WARN \
            "BT kernel modules" \
            "No bluetooth modules loaded" \
            "Load: sudo modprobe bluetooth btusb"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — RFKILL (SOFT/HARD BLOCK)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_rfkill() {
    _check_header "🔒 rfkill  (Radio Kill Switch)"

    if ! command -v rfkill &>/dev/null; then
        _check_report $CHECK_INFO \
            "rfkill" \
            "Not found" \
            "Install: paru -S util-linux  (usually pre-installed)"
        return $CHECK_PASS
    fi

    # ── List all BT rfkill entries ───────────────────────────────────────────────
    local rfkill_out
    rfkill_out="$(rfkill list bluetooth 2>/dev/null || echo '')"

    if [[ -z "$rfkill_out" ]]; then
        _check_report $CHECK_INFO \
            "rfkill bluetooth" \
            "No bluetooth rfkill entries found"
        return $CHECK_PASS
    fi

    # ── Parse each BT rfkill device ─────────────────────────────────────────────
    local in_bt_block=0
    local current_idx=""
    local current_name=""

    while IFS= read -r line; do
        # New device entry
        if [[ "$line" =~ ^([0-9]+):[[:space:]]+(.*):$ ]]; then
            current_idx="${BASH_REMATCH[1]}"
            current_name="${BASH_REMATCH[2]}"
            in_bt_block=1
            continue
        fi

        [[ $in_bt_block -eq 0 ]] && continue

        if [[ "$line" =~ Soft[[:space:]]blocked:[[:space:]]+(yes|no) ]]; then
            local soft_block="${BASH_REMATCH[1]}"
            if [[ "$soft_block" == "yes" ]]; then
                _check_report $CHECK_WARN \
                    "rfkill [${current_idx}] ${current_name}" \
                    "SOFT BLOCKED  (disabled by software)" \
                    "Unblock: rfkill unblock bluetooth"
            else
                _check_report $CHECK_PASS \
                    "rfkill [${current_idx}] ${current_name}" \
                    "Soft block: no  (enabled)"
            fi
        fi

        if [[ "$line" =~ Hard[[:space:]]blocked:[[:space:]]+(yes|no) ]]; then
            local hard_block="${BASH_REMATCH[1]}"
            if [[ "$hard_block" == "yes" ]]; then
                _check_report $CHECK_FAIL \
                    "rfkill [${current_idx}] hard block" \
                    "HARD BLOCKED  (physical switch/BIOS disabled)" \
                    "Check physical WiFi/BT switch on laptop, or enable in BIOS"
            else
                _check_report $CHECK_PASS \
                    "rfkill [${current_idx}] hard block" \
                    "No hardware block"
            fi
            in_bt_block=0
        fi

    done <<< "$rfkill_out"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — BLUEZ STACK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_bluez() {
    _check_header "🟦 BlueZ  (Bluetooth Stack)"

    # ── bluetoothd binary ────────────────────────────────────────────────────────
    if ! command -v bluetoothd &>/dev/null; then
        _check_report $CHECK_FAIL \
            "bluetoothd binary" \
            "Not found" \
            "Install: paru -S bluez"
        return $CHECK_FAIL
    fi

    local bluez_ver
    bluez_ver="$(bluetoothd --version 2>/dev/null | head -1 | \
                 grep -oP '[\d.]+' | head -1 || echo 'unknown')"
    _check_report $CHECK_PASS \
        "bluetoothd binary" \
        "v${bluez_ver}"

    # ── BlueZ version validation ─────────────────────────────────────────────────
    local bz_major="${bluez_ver%%.*}"
    if [[ "$bz_major" =~ ^[0-9]+$ ]]; then
        if (( bz_major >= 5 )); then
            local bz_minor
            bz_minor="$(printf '%s' "$bluez_ver" | cut -d. -f2)"
            if (( bz_minor >= 72 )); then
                _check_report $CHECK_PASS \
                    "BlueZ version" \
                    "${bluez_ver}  (current — LE Audio / LC3 support)"
            elif (( bz_minor >= 65 )); then
                _check_report $CHECK_PASS \
                    "BlueZ version" \
                    "${bluez_ver}  (stable)"
            else
                _check_report $CHECK_WARN \
                    "BlueZ version" \
                    "${bluez_ver}  (consider updating)" \
                    "Update: paru -Su bluez"
            fi
        fi
    fi

    # ── systemd service ──────────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local bt_state bt_enabled
        bt_state="$(  systemctl is-active  bluetooth 2>/dev/null || echo 'inactive')"
        bt_enabled="$(systemctl is-enabled bluetooth 2>/dev/null || echo 'disabled')"

        if [[ "$bt_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "bluetooth.service" \
                "active  •  enabled: ${bt_enabled}"
        else
            _check_report $CHECK_FAIL \
                "bluetooth.service" \
                "state=${bt_state}  •  enabled: ${bt_enabled}" \
                "Start: sudo systemctl enable --now bluetooth"
        fi
    fi

    # ── bluetoothd process ───────────────────────────────────────────────────────
    if pgrep -x bluetoothd &>/dev/null; then
        local bt_pid
        bt_pid="$(pgrep -x bluetoothd | head -1)"
        _check_report $CHECK_PASS \
            "bluetoothd process" \
            "Running  (PID: ${bt_pid})"
    else
        _check_report $CHECK_FAIL \
            "bluetoothd process" \
            "Not running" \
            "Start: sudo systemctl start bluetooth"
    fi

    # ── bluetoothctl info via expect-free method ─────────────────────────────────
    if command -v bluetoothctl &>/dev/null; then
        # Use timeout + echo to get controller info without interactive mode
        local btctl_out
        btctl_out="$(timeout 3 bluetoothctl show 2>/dev/null || echo '')"

        if [[ -n "$btctl_out" ]]; then
            local controller_addr
            controller_addr="$(printf '%s' "$btctl_out" | \
                               grep -oP 'Controller [0-9A-F:]+' | head -1)"
            local controller_name
            controller_name="$(printf '%s' "$btctl_out" | \
                               grep 'Name:' | head -1 | awk '{$1=""; print}' | \
                               sed 's/^ //')"
            local controller_power
            controller_power="$(printf '%s' "$btctl_out" | \
                                grep 'Powered:' | awk '{print $2}')"
            local controller_disc
            controller_disc="$(printf '%s' "$btctl_out" | \
                               grep 'Discoverable:' | awk '{print $2}')"
            local controller_pairable
            controller_pairable="$(printf '%s' "$btctl_out" | \
                                   grep 'Pairable:' | awk '{print $2}')"

            _check_report $CHECK_INFO \
                "BT controller" \
                "${controller_addr:-unknown}  ${controller_name:-}"

            if [[ "$controller_power" == "yes" ]]; then
                _check_report $CHECK_PASS \
                    "Controller power" \
                    "On"
            else
                _check_report $CHECK_WARN \
                    "Controller power" \
                    "Off" \
                    "Power on: bluetoothctl power on"
            fi

            _check_report $CHECK_INFO \
                "Discoverable" \
                "${controller_disc:-unknown}"
            _check_report $CHECK_INFO \
                "Pairable" \
                "${controller_pairable:-unknown}"

            # BT version / class
            local bt_class
            bt_class="$(printf '%s' "$btctl_out" | grep 'Class:' | awk '{print $2}')"
            [[ -n "$bt_class" ]] && \
                _check_report $CHECK_INFO "Device class" "$bt_class"

        else
            _check_report $CHECK_WARN \
                "bluetoothctl show" \
                "No response — controller may be off or rfkilled"
        fi
    else
        _check_report $CHECK_WARN \
            "bluetoothctl" \
            "Not found" \
            "Install: paru -S bluez-utils"
    fi

    # ── D-Bus Bluetooth service ──────────────────────────────────────────────────
    if command -v dbus-send &>/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        if dbus-send --system --print-reply \
            --dest=org.bluez / \
            org.freedesktop.DBus.Introspectable.Introspect \
            &>/dev/null 2>&1; then
            _check_report $CHECK_PASS \
                "BlueZ D-Bus API" \
                "Accessible on system bus"
        else
            _check_report $CHECK_WARN \
                "BlueZ D-Bus API" \
                "Not accessible" \
                "Ensure bluetooth.service is running as system service"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — PAIRED DEVICES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_devices() {
    _check_header "🎯 Paired & Connected Devices"

    if ! command -v bluetoothctl &>/dev/null; then
        _check_report $CHECK_SKIP \
            "Device scan" \
            "bluetoothctl not available"
        return $CHECK_SKIP
    fi

    # ── List paired devices ──────────────────────────────────────────────────────
    local paired_out
    paired_out="$(timeout 3 bluetoothctl devices Paired 2>/dev/null || \
                  timeout 3 bluetoothctl devices 2>/dev/null | \
                  grep '^Device' || echo '')"

    if [[ -z "$paired_out" ]]; then
        _check_report $CHECK_INFO \
            "Paired devices" \
            "None paired"
        return $CHECK_PASS
    fi

    local paired_count
    paired_count="$(printf '%s\n' "$paired_out" | grep -c '^Device' || echo 0)"
    _check_report $CHECK_INFO \
        "Paired devices" \
        "${paired_count} device(s) in pairing database"

    # ── Per-device details ───────────────────────────────────────────────────────
    while IFS= read -r device_line; do
        [[ -z "$device_line" ]] && continue
        [[ "$device_line" =~ ^Device ]] || continue

        local bt_mac bt_alias
        bt_mac="$(   printf '%s' "$device_line" | awk '{print $2}')"
        bt_alias="$( printf '%s' "$device_line" | cut -d' ' -f3-)"

        # Fetch detailed info for this device
        local dev_info
        dev_info="$(timeout 2 bluetoothctl info "$bt_mac" 2>/dev/null || echo '')"

        local connected trusted paired bt_icon
        connected="$(printf '%s' "$dev_info" | grep 'Connected:' | awk '{print $2}' || echo 'no')"
        trusted="$(  printf '%s' "$dev_info" | grep 'Trusted:'   | awk '{print $2}' || echo 'no')"
        paired="$(   printf '%s' "$dev_info" | grep 'Paired:'    | awk '{print $2}' || echo 'no')"
        local dev_icon
        dev_icon="$(printf '%s' "$dev_info" | grep 'Icon:' | awk '{print $2}' || echo '')"

        # Choose display icon based on device class
        case "${dev_icon:-}" in
            audio-headphones|audio-headset)  bt_icon="🎧" ;;
            audio-card|audio-speakers)       bt_icon="🔊" ;;
            input-keyboard)                  bt_icon="⌨️ " ;;
            input-mouse)                     bt_icon="🖱️ " ;;
            input-gaming)                    bt_icon="🎮" ;;
            phone)                           bt_icon="📱" ;;
            computer)                        bt_icon="💻" ;;
            *)                               bt_icon="📡" ;;
        esac

        # Status indicators
        local status_str="${bt_icon} ${bt_alias}"
        local status_check=$CHECK_INFO

        if [[ "$connected" == "yes" ]]; then
            status_str+="  •  🟢 CONNECTED"
            status_check=$CHECK_PASS
        else
            status_str+="  •  ⭕ not connected"
        fi

        [[ "$trusted" == "yes" ]] && status_str+="  •  trusted"

        _check_report $status_check \
            "Device: ${bt_mac}" \
            "$status_str"

        # For audio devices, check if profile is set
        if [[ "${dev_icon:-}" =~ audio|headphones|headset ]]; then
            local profiles_out
            profiles_out="$(timeout 2 bluetoothctl info "$bt_mac" 2>/dev/null | \
                            grep -A5 'UUID:' | grep -i 'a2dp\|hsp\|hfp\|le audio' || echo '')"
            if [[ -n "$profiles_out" ]]; then
                local profile_list
                profile_list="$(printf '%s' "$profiles_out" | \
                                awk '{print $NF}' | tr '\n' '  ')"
                _check_report $CHECK_INFO \
                    "  └─ Audio profiles" \
                    "$profile_list"
            fi
        fi

    done <<< "$paired_out"

    # ── Connected device count ───────────────────────────────────────────────────
    local connected_out
    connected_out="$(timeout 3 bluetoothctl devices Connected 2>/dev/null | \
                     grep -c '^Device' || echo 0)"
    _check_report $CHECK_INFO \
        "Currently connected" \
        "${connected_out} device(s) active"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — AUDIO CODEC SUPPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_audio_codecs() {
    _check_header "🎶 Bluetooth Audio Codecs"

    # ── PipeWire BT module ───────────────────────────────────────────────────────
    local pw_bt_plugin
    pw_bt_plugin="$(find /usr/lib/pipewire-* -name '*bluez*' 2>/dev/null | head -1 || echo '')"

    if [[ -n "$pw_bt_plugin" ]]; then
        _check_report $CHECK_PASS \
            "PipeWire BT plugin" \
            "$(basename "$pw_bt_plugin")"
    else
        _check_report $CHECK_FAIL \
            "PipeWire BT plugin" \
            "Not found" \
            "Install: paru -S pipewire-bluetooth"
    fi

    # ── Codec library scan ───────────────────────────────────────────────────────
    # Each entry: "lib_pattern|codec_name|package|quality"
    local -a codec_entries=(
        "libsbc.so*:SBC  (default — always available):libsbc:standard"
        "libldacBT_enc.so*:LDAC  (Sony hi-res 990kbps):libldac:hi-res"
        "libfreeaptx.so*:aptX  (open source):libfreeaptx:CD quality"
        "libaptx.so*:aptX  (Qualcomm proprietary):libaptx:CD quality"
        "libaptXHD.so*:aptX HD  (Qualcomm hi-res):libaptx-hd:hi-res"
        "libaac.so*:AAC  (Apple compatible):libfdk-aac:good"
        "libLC3.so*:LC3  (LE Audio / Bluetooth 5.2):liblc3:bluetooth5"
        "libopus.so*:Opus  (low latency):opus:low-latency"
    )

    for codec_entry in "${codec_entries[@]}"; do
        IFS=':' read -r lib_pattern codec_name pkg quality <<< "$codec_entry"

        local found_lib
        found_lib="$(find /usr/lib /usr/lib64 /usr/local/lib \
                     -name "$lib_pattern" 2>/dev/null | head -1 || echo '')"

        if [[ -n "$found_lib" ]]; then
            _check_report $CHECK_PASS \
                "Codec: ${codec_name}" \
                "Available  [${quality}]  •  ${found_lib##*/}"
        else
            case "$quality" in
                standard)
                    _check_report $CHECK_FAIL \
                        "Codec: ${codec_name}" \
                        "NOT FOUND  (required for any BT audio)" \
                        "Install: paru -S $pkg"
                    ;;
                hi-res|CD\ quality)
                    _check_report $CHECK_INFO \
                        "Codec: ${codec_name}" \
                        "Not installed  [${quality}]" \
                        "Install: paru -S $pkg"
                    ;;
                *)
                    _check_report $CHECK_INFO \
                        "Codec: ${codec_name}" \
                        "Not installed  [${quality}]"
                    ;;
            esac
        fi
    done

    # ── A2DP / HFP profiles via bluez plugins ───────────────────────────────────
    local -a bluez_plugins=(
        "/usr/lib/bluetooth/plugins/a2dp.so:A2DP  (Advanced Audio Distribution)"
        "/usr/lib/bluetooth/plugins/avrcp.so:AVRCP  (Remote Control)"
    )

    for plugin_entry in "${bluez_plugins[@]}"; do
        IFS=':' read -r plugin_path plugin_desc <<< "$plugin_entry"
        if [[ -f "$plugin_path" ]]; then
            _check_report $CHECK_PASS \
                "BlueZ plugin: ${plugin_desc}" \
                "$(basename "$plugin_path")"
        fi
    done

    # ── bluez-plugins (aptX/LDAC registration) ───────────────────────────────────
    if [[ -d /usr/lib/bluetooth/plugins ]]; then
        local plugin_count
        plugin_count="$(find /usr/lib/bluetooth/plugins -name '*.so' | wc -l)"
        _check_report $CHECK_INFO \
            "BlueZ plugins" \
            "${plugin_count} plugin(s) in /usr/lib/bluetooth/plugins"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — FRONTEND TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_tools() {
    _check_header "🛠️  Bluetooth Tools & Frontend"

    # Format: "binary:package:critical:description"
    local -a tools=(
        "bluetoothctl:bluez-utils:1:bluetoothctl  (CLI frontend — required)"
        "btmgmt:bluez-utils:0:btmgmt  (HCI management)"
        "obexctl:bluez-utils:0:obexctl  (file transfer)"
        "btop:bluez-utils:0:btop  (monitoring)"
        "bluetui:bluetui:0:Bluetui  (TUI frontend — ncurses)"
        "blueman-manager:blueman:0:Blueman  (GTK frontend)"
        "blueberry:blueberry:0:Blueberry  (GTK simple frontend)"
        "overskride:overskride:0:Overskride  (GTK4 frontend)"
    )

    for tool_def in "${tools[@]}"; do
        IFS=':' read -r cmd pkg critical desc <<< "$tool_def"

        if command -v "$cmd" &>/dev/null; then
            local ver
            ver="$("$cmd" --version 2>/dev/null | head -1 | \
                   grep -oP '[\d.]+' | head -1 || echo 'installed')"
            _check_report $CHECK_PASS "$desc" "$ver"
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL "$desc" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            else
                _check_report $CHECK_INFO "$desc" \
                    "Not installed  (optional)" \
                    "Install: paru -S $pkg"
            fi
        fi
    done

    # ── ASH bluetooth config ─────────────────────────────────────────────────────
    local ash_bt_conf="${XDG_CONFIG_HOME:-$HOME/.config}/ash/bluetooth.conf"
    if [[ -f "$ash_bt_conf" ]]; then
        _check_report $CHECK_PASS \
            "ASH bluetooth config" \
            "$ash_bt_conf"
    fi

    # ── main.conf ────────────────────────────────────────────────────────────────
    local main_conf="/etc/bluetooth/main.conf"
    if [[ -f "$main_conf" ]]; then
        local auto_enable
        auto_enable="$(grep -i 'AutoEnable' "$main_conf" 2>/dev/null | \
                       tail -1 | grep -oP 'true|false' || echo 'not set')"
        local fast_conn
        fast_conn="$(grep -i 'FastConnectable' "$main_conf" 2>/dev/null | \
                     tail -1 | grep -oP 'true|false' || echo 'not set')"

        _check_report $CHECK_INFO \
            "/etc/bluetooth/main.conf" \
            "AutoEnable=${auto_enable}  •  FastConnectable=${fast_conn}"

        if [[ "$auto_enable" != "true" ]]; then
            _check_report $CHECK_INFO \
                "AutoEnable suggestion" \
                "Set AutoEnable=true in main.conf to auto-power BT on boot"
        fi
    else
        _check_report $CHECK_INFO \
            "/etc/bluetooth/main.conf" \
            "Not found  (using BlueZ defaults)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — KERNEL / DMESG BT MESSAGES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_bt_dmesg() {
    _check_header "📋 Bluetooth Kernel Messages"

    # ── Successful init messages ─────────────────────────────────────────────────
    local bt_init
    bt_init="$(dmesg 2>/dev/null | \
               grep -iE 'bluetooth|btusb|btintel|btbcm|btrtl' | \
               grep -iv 'error\|fail\|warn' | tail -3 || echo '')"

    if [[ -n "$bt_init" ]]; then
        _check_report $CHECK_INFO \
            "BT init messages" \
            "$(printf '%s\n' "$bt_init" | wc -l) lines  (last below)"
        while IFS= read -r line; do
            _check_report $CHECK_INFO \
                "  dmesg" \
                "$(printf '%s' "$line" | sed 's/.*\] //' | cut -c1-70)"
        done <<< "$bt_init"
    fi

    # ── Error messages ───────────────────────────────────────────────────────────
    local bt_errors
    bt_errors="$(dmesg 2>/dev/null | \
                 grep -iE 'bluetooth|btusb|btintel' | \
                 grep -iE 'error|fail|warn' | tail -5 || echo '')"

    if [[ -n "$bt_errors" ]]; then
        local err_count
        err_count="$(printf '%s\n' "$bt_errors" | wc -l)"
        _check_report $CHECK_WARN \
            "BT dmesg errors" \
            "${err_count} error/warning(s)"
        while IFS= read -r err; do
            _check_report $CHECK_WARN \
                "  dmesg" \
                "$(printf '%s' "$err" | sed 's/.*\] //' | cut -c1-70)"
        done <<< "$bt_errors"
    else
        _check_report $CHECK_PASS \
            "BT dmesg errors" \
            "None detected"
    fi

    # ── Firmware load for common adapters ───────────────────────────────────────
    local fw_messages
    fw_messages="$(dmesg 2>/dev/null | \
                   grep -i 'btintel\|btbcm\|btrtl\|btmtk' | \
                   grep -i 'firmware\|loaded\|version' | tail -4 || echo '')"

    if [[ -n "$fw_messages" ]]; then
        _check_report $CHECK_PASS \
            "BT firmware messages" \
            "$(printf '%s\n' "$fw_messages" | wc -l) firmware message(s)"
        while IFS= read -r fwline; do
            _check_report $CHECK_INFO \
                "  firmware" \
                "$(printf '%s' "$fwline" | sed 's/.*\] //' | cut -c1-70)"
        done <<< "$fw_messages"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_bluetooth() {
    local mode="${1:-full}"   # quick | full | devices | codecs

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;180;190;254m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  📡  ASH DOCTOR — BLUETOOTH CHECK                        ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: hw • rfkill • BlueZ • devices • codecs • tools  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — BLUETOOTH CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_bt_hardware
            _chk_bt_rfkill
            _chk_bt_bluez
            ;;
        devices)
            _chk_bt_hardware
            _chk_bt_bluez
            _chk_bt_devices
            ;;
        codecs)
            _chk_bt_audio_codecs
            ;;
        full|*)
            _chk_bt_hardware
            _chk_bt_rfkill
            _chk_bt_bluez
            _chk_bt_devices
            _chk_bt_audio_codecs
            _chk_bt_tools
            _chk_bt_dmesg
            ;;
    esac

    _ash_check_system_summary
}

ash_check_bluetooth_quick() {
    local issues=0

    # Fast gate: no BT hardware → skip gracefully
    if ! (lsmod 2>/dev/null | grep -q '^bluetooth\b' || \
          [[ -d /sys/class/bluetooth ]]); then
        return 0
    fi

    pgrep -x bluetoothd &>/dev/null || (( issues++ )) || true

    local rfk_blocked
    rfk_blocked="$(rfkill list bluetooth 2>/dev/null | \
                   grep 'Soft blocked: yes' | wc -l || echo 0)"
    (( rfk_blocked > 0 )) && (( issues++ )) || true

    if (( issues == 0 )); then
        ash_log_success "Bluetooth: OK"
    else
        ash_log_warn "Bluetooth: ${issues} issue(s) — run 'ash doctor full --bluetooth'"
        return 1
    fi
}
