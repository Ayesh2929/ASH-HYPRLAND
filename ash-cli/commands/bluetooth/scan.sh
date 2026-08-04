#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bluetooth scan                                           ║
# ║  Discover nearby BT devices with animated radar, RSSI bars, and type detection  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BT_SCAN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BT_SCAN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RADAR ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_radar() {
    local duration="$1"  # scan duration in seconds
    local frames=( '◜' '◝' '◞' '◟' '◌' )
    local dots=( '·' '·' '·' '·' '·' '·' '·' '·' )
    local i=0  dot_count=0

    printf '\n'

    local end_time=$(( $(date +%s) + duration ))

    while (( $(date +%s) < end_time )); do
        local remaining=$(( end_time - $(date +%s) ))
        local frame="${frames[$((i % ${#frames[@]}))]}"

        # Build dot animation
        local dot_str=""
        for (( d=0; d<dot_count; d++ )); do
            dot_str+="·"
        done

        printf '\r  %s%s%s  %sScanning%s%s  %s%ds remaining%s  ' \
            "$(_btblue)$(_btbold)" "$frame" "$(_btr)" \
            "$(_btsapph)" "$dot_str" "$(_btr)" \
            "$(_btdim)" "$remaining" "$(_btr)"

        i=$(( i + 1 ))
        dot_count=$(( (dot_count + 1) % 4 ))
        sleep 0.2
    done

    printf '\r  %-60s\n' ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SCAN RESULT PARSER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_parse_devices() {
    # Get all devices seen during scan (paired + new)
    local -a macs=()
    mapfile -t macs < <(
        bluetoothctl devices 2>/dev/null | \
        awk '{print $2}' | \
        grep -E '^([0-9A-F]{2}:){5}[0-9A-F]{2}$'
    )

    local count=0
    for mac in "${macs[@]}"; do
        [[ -z "$mac" ]] && continue

        local dev_info
        dev_info="$(bluetoothctl info "$mac" 2>/dev/null || echo '')"

        local name paired connected trusted rssi
        name="$(      printf '%s' "$dev_info" | grep 'Name:' | \
                      head -1 | awk '{$1=""; print}' | sed 's/^ //')"
        paired="$(    printf '%s' "$dev_info" | grep 'Paired:' | awk '{print $2}')"
        connected="$( printf '%s' "$dev_info" | grep 'Connected:' | awk '{print $2}')"
        trusted="$(   printf '%s' "$dev_info" | grep 'Trusted:' | awk '{print $2}')"
        rssi="$(      printf '%s' "$dev_info" | grep 'RSSI:' | awk '{print $2}')"

        [[ -z "$name" ]] && name="Unknown Device"

        # Device icon
        local icon
        icon="$(bt_device_icon "" "$name")"

        # Status badges
        local status_badges=""
        [[ "$connected" == "yes" ]] && \
            status_badges+="$(bt_badge " ●CONN " "$(_btgreen)")  "
        [[ "$paired" == "yes" ]] && \
            status_badges+="$(bt_badge " PAIRED " "$(_btblue)")  "
        [[ "$trusted" == "yes" ]] && \
            status_badges+="$(bt_badge " TRUSTED " "$(_btteal)")  "

        printf '\n  %s  %s%s%s\n' \
            "$icon" "$(_btsky)$(_btbold)" "$name" "$(_btr)"
        printf '  %s    %s%s%s\n' \
            "" "$(_btdim)" "$mac" "$(_btr)"

        if [[ -n "$rssi" ]]; then
            printf '  %s    Signal: %s%s\n' \
                "" "$(bt_rssi_bars "$rssi")" "$(_btr)"
        fi

        [[ -n "$status_badges" ]] && \
            printf '  %s    %s\n' "" "$status_badges"

        (( count++ )) || true
    done

    printf '\n  %s%d device(s) discovered%s\n' "$(_btdim)" "$count" "$(_btr)"
    printf '%s' "$count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  JSON OUTPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_scan_json_output() {
    local ts
    ts="$(date -Iseconds)"

    command -v python3 &>/dev/null || {
        bluetoothctl devices 2>/dev/null | \
            awk '{print "{\"mac\":\""$2"\",\"name\":\""$3"\"}"}'
        return 0
    }

    python3 - << PYEOF
import subprocess, json, re, sys

result = subprocess.run(['bluetoothctl', 'devices'],
    capture_output=True, text=True)
devices = []
for line in result.stdout.splitlines():
    m = re.match(r'Device\s+([0-9A-F:]{17})\s+(.*)', line)
    if m:
        mac, name = m.group(1), m.group(2)
        # Get device info
        info_result = subprocess.run(
            ['bluetoothctl', 'info', mac],
            capture_output=True, text=True)
        info = info_result.stdout

        def parse(pattern, default=''):
            m2 = re.search(pattern, info)
            return m2.group(1) if m2 else default

        devices.append({
            'mac': mac,
            'name': name,
            'paired': 'Paired: yes' in info,
            'connected': 'Connected: yes' in info,
            'trusted': 'Trusted: yes' in info,
            'rssi': parse(r'RSSI:\s*(-?\d+)'),
            'icon': parse(r'Icon:\s*(\S+)'),
        })

print(json.dumps({'timestamp': '${ts}', 'devices': devices}, indent=2))
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bt_scan() {
    local duration="${BT_TIMEOUT:-10}"
    local connect_after=0  pair_after=0

    for arg in "${@:-}"; do
        case "$arg" in
            --duration=*|-d=*) duration="${arg#*=}" ;;
            --connect|-c)      connect_after=1      ;;
            --pair|-p)         pair_after=1         ;;
            [0-9]*)            duration="$arg"      ;;
        esac
    done

    bt_section "🔍" "Bluetooth Scan" "$(_btsapph)"
    bt_kv "Duration"  "${duration}s"
    bt_kv "Adapter"   "${BT_ADAPTER:-default}"

    # Ensure BT is powered
    if ! bt_is_powered; then
        bt_step "Powering on Bluetooth..."
        bt_set_power on
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        bt_spin_start "Scanning ${duration}s..."
        {
            printf 'scan on\n'
            sleep "$duration"
            printf 'scan off\n'
        } | bluetoothctl &>/dev/null
        bt_spin_stop "ok" "Scan complete"
        _scan_json_output
        return 0
    fi

    bt_step "Starting discovery..."
    bluetoothctl scan on &>/dev/null &
    local scan_pid=$!

    trap 'kill "$scan_pid" 2>/dev/null; bluetoothctl scan off &>/dev/null' EXIT INT TERM

    _scan_radar "$duration"

    kill "$scan_pid" 2>/dev/null || true
    bluetoothctl scan off &>/dev/null 2>&1 || true

    trap - EXIT INT TERM

    bt_section "📋" "Discovered Devices" "$(_btlav)"
    local count
    count="$(_scan_parse_devices | tail -1)"

    # Save scan cache
    {
        printf '{"timestamp":"%s","count":%s}\n' \
            "$(date -Iseconds)" "${count:-0}"
    } > "$_BT_SCAN_CACHE" 2>/dev/null || true

    # Post-scan actions
    if [[ $pair_after -eq 1 ]] && (( ${count:-0} > 0 )); then
        _bt_load_sub pair &>/dev/null || true
        ash_bt_pair
    fi
}
