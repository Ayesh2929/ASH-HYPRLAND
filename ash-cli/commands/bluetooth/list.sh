#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗     ██╗███████╗████████╗                                                    ║
# ║  ██║     ██║██╔════╝╚══██╔══╝                                                    ║
# ║  ██║     ██║███████╗   ██║                                                       ║
# ║  ██║     ██║╚════██║   ██║                                                       ║
# ║  ███████╗██║███████╗   ██║                                                       ║
# ║  ╚══════╝╚═╝╚══════╝   ╚═╝                                                       ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  bluetooth list                                           ║
# ║  Rich device listing with RSSI, battery, codec, profile, and connection history ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BT_LIST_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BT_LIST_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE DETAIL BLOCK RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_render_device() {
    local mac="$1"  compact="${2:-0}"

    local dev_info
    dev_info="$(bluetoothctl info "$mac" 2>/dev/null || echo '')"
    [[ -z "$dev_info" ]] && return 0

    local name paired connected trusted battery rssi icon_str
    name="$(      printf '%s' "$dev_info" | grep 'Name:'        | head -1 | awk '{$1=""; print}' | sed 's/^ //')"
    paired="$(    printf '%s' "$dev_info" | grep 'Paired:'      | awk '{print $2}')"
    connected="$( printf '%s' "$dev_info" | grep 'Connected:'   | awk '{print $2}')"
    trusted="$(   printf '%s' "$dev_info" | grep 'Trusted:'     | awk '{print $2}')"
    battery="$(   printf '%s' "$dev_info" | grep 'Battery Percentage' | grep -oP '\d+(?=%)' | head -1)"
    rssi="$(      printf '%s' "$dev_info" | grep 'RSSI:'        | awk '{print $2}')"
    icon_str="$(  printf '%s' "$dev_info" | grep 'Icon:'        | awk '{print $2}')"

    [[ -z "$name" ]] && name="Unknown Device"

    local dev_icon
    dev_icon="$(bt_device_icon "$icon_str" "$name")"

    # Status colour
    local name_color
    [[ "$connected" == "yes" ]] && name_color="$(_btgreen)$(_btbold)" || \
        name_color="$(_btsky)"

    printf '\n  %s  %s%s%s\n' "$dev_icon" "$name_color" "$name" "$(_btr)"
    printf '  %s    %s%s%s\n' "" "$(_btdim)" "$mac" "$(_btr)"

    if [[ $compact -eq 0 ]]; then
        # Status badges
        printf '  %s    ' ""
        [[ "$connected" == "yes" ]] && \
            printf '%s' "$(bt_badge " ●  CONNECTED " "$(_btgreen)")  "
        [[ "$paired" == "yes" ]] && \
            printf '%s' "$(bt_badge "  PAIRED  " "$(_btblue)")  "
        [[ "$trusted" == "yes" ]] && \
            printf '%s' "$(bt_badge "  TRUSTED  " "$(_btteal)")  "
        printf '\n'

        # RSSI signal
        if [[ -n "$rssi" ]]; then
            printf '  %s    Signal: %s%s\n' \
                "" "$(bt_rssi_bars "$rssi")" "$(_btr)"
        fi

        # Battery level with visual bar
        if [[ -n "$battery" ]]; then
            local bat_int="$battery"
            local bat_color
            (( bat_int >= 60 )) && bat_color="$(_btgreen)"  || \
            (( bat_int >= 30 )) && bat_color="$(_btyellow)" || \
            bat_color="$(_btred)"

            local bar_w=15
            local filled=$(( bat_int * bar_w / 100 ))
            local empty=$(( bar_w - filled ))
            local bat_icon
            (( bat_int >= 80 )) && bat_icon="🔋" || \
            (( bat_int >= 40 )) && bat_icon="🪫" || bat_icon="🔌"

            printf '  %s    Battery: %s%s%s%s%s%s  %s%d%%%s  %s\n' \
                "" \
                "$bat_color" "$(printf '█%.0s' $(seq 1 $filled))" \
                "$(_btdim)"  "$(printf '░%.0s' $(seq 1 $empty))" \
                "$(_btr)" "" \
                "$bat_color$(_btbold)" "$bat_int" "$(_btr)" \
                "$bat_icon"
        fi

        # UUIDs / profiles (audio codec info)
        local uuids
        uuids="$(printf '%s' "$dev_info" | grep 'UUID:' | head -4)"
        if [[ -n "$uuids" ]]; then
            printf '  %s    Profiles: %s' "" "$(_btdim)"
            printf '%s' "$uuids" | \
                grep -oP '(?<=\().*(?=\))' | \
                head -4 | tr '\n' '  '
            printf '%s\n' "$(_btr)"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  JSON OUTPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_json() {
    command -v python3 &>/dev/null || {
        bluetoothctl devices 2>/dev/null
        return 0
    }

    python3 - << 'PYEOF'
import subprocess, json, re, sys

result = subprocess.run(
    ['bluetoothctl', 'devices'],
    capture_output=True, text=True
)

devices = []
for line in result.stdout.splitlines():
    m = re.match(r'Device\s+([0-9A-F:]{17})\s+(.*)', line)
    if not m:
        continue
    mac, name = m.group(1), m.group(2)

    info_r = subprocess.run(
        ['bluetoothctl', 'info', mac],
        capture_output=True, text=True
    )
    info = info_r.stdout

    def field(pattern, default=''):
        m2 = re.search(pattern, info)
        return m2.group(1).strip() if m2 else default

    bat = field(r'Battery Percentage.*?(\d+)\s*\(')
    devices.append({
        'mac': mac,
        'name': name,
        'paired':    'Paired: yes' in info,
        'connected': 'Connected: yes' in info,
        'trusted':   'Trusted: yes' in info,
        'battery':   int(bat) if bat else None,
        'rssi':      field(r'RSSI:\s*(-?\d+)'),
        'icon':      field(r'Icon:\s*(\S+)'),
    })

print(json.dumps({'devices': devices}, indent=2))
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SUMMARY BAR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_list_summary() {
    local total="$1"  connected="$2"  paired="$3"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n  %s┌──────────────────────────────────────────────┐%s\n' \
            "$(_btmauve)" "$(_btr)"
        printf '  %s│%s  ' "$(_btmauve)" "$(_btr)"
        printf '%s%-6s devices%s  •  ' \
            "$(_btbold)" "$total" "$(_btr)"
        printf '%s%-3s connected%s  •  ' \
            "$(_btgreen)" "$connected" "$(_btr)"
        printf '%s%-3s paired%s' \
            "$(_btblue)" "$paired" "$(_btr)"
        printf '  %s│%s\n' "$(_btmauve)" "$(_btr)"
        printf '  %s└──────────────────────────────────────────────┘%s\n' \
            "$(_btmauve)" "$(_btr)"
    else
        printf '\n  Total: %s  Connected: %s  Paired: %s\n' \
            "$total" "$connected" "$paired"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bt_list() {
    local filter=""   # all | connected | paired
    local compact=0
    local sort_by="name"  # name | connected | rssi

    for arg in "${@:-}"; do
        case "$arg" in
            --connected|-c)     filter="connected" ;;
            --paired|-p)        filter="paired"    ;;
            --all|-a)           filter="all"       ;;
            --compact|-s)       compact=1          ;;
            --sort=*)           sort_by="${arg#*=}" ;;
        esac
    done

    bt_section "📋" "Bluetooth Devices" "$(_btlav)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        _list_json
        return 0
    fi

    bt_kv "Backend"  "bluetoothctl"
    bt_kv "Adapter"  "${BT_ADAPTER:-default}"
    bt_kv "Filter"   "${filter:-all}"

    # Gather device data
    local -a all_macs=()
    local total=0  connected_count=0  paired_count=0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mac
        mac="$(printf '%s' "$line" | awk '{print $2}')"
        [[ -z "$mac" ]] && continue

        case "$filter" in
            connected)
                bt_is_connected "$mac" || continue ;;
            paired)
                bt_is_paired "$mac" || continue ;;
        esac

        all_macs+=("$mac")
        (( total++ )) || true
        bt_is_connected "$mac" && (( connected_count++ )) || true
        bt_is_paired    "$mac" && (( paired_count++ ))    || true
    done < <(bluetoothctl devices 2>/dev/null | grep '^Device')

    if [[ ${#all_macs[@]} -eq 0 ]]; then
        printf '\n  %sNo devices found%s' "$(_btdim)" "$(_btr)"
        if [[ -n "$filter" ]]; then
            printf '  %s(filter: %s)%s' "$(_btdim)" "$filter" "$(_btr)"
        fi
        printf '\n  %sRun: ash bt scan  to discover devices%s\n' \
            "$(_btdim)" "$(_btr)"
        printf '\n'; return 0
    fi

    # Sort
    local -a sorted_macs=()
    case "$sort_by" in
        connected)
            # Connected first
            for mac in "${all_macs[@]}"; do
                bt_is_connected "$mac" && sorted_macs+=("$mac")
            done
            for mac in "${all_macs[@]}"; do
                bt_is_connected "$mac" || sorted_macs+=("$mac")
            done
            ;;
        *)
            sorted_macs=("${all_macs[@]}")
            ;;
    esac

    # Render each device
    for mac in "${sorted_macs[@]}"; do
        _list_render_device "$mac" "$compact"
    done

    _list_summary "$total" "$connected_count" "$paired_count"
    printf '\n'
}
