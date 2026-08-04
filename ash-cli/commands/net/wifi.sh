#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  net wifi                                                 ║
# ║  Active WiFi connection details • signal quality • channels • security           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_WIFI_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_WIFI_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WIFI DATA COLLECTORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_find_iface() {
    local iface=""
    for i in /sys/class/net/*/wireless; do
        [[ -d "$i" ]] && iface="${i%/wireless}" && iface="${iface##*/}" && break
    done
    printf '%s' "$iface"
}

_wifi_get_iw_link() {
    local iface="$1"
    command -v iw &>/dev/null && iw dev "$iface" link 2>/dev/null || echo ''
}

_wifi_get_iw_info() {
    local iface="$1"
    command -v iw &>/dev/null && iw dev "$iface" info 2>/dev/null || echo ''
}

_wifi_get_iw_station() {
    local iface="$1"
    command -v iw &>/dev/null && iw dev "$iface" station dump 2>/dev/null || echo ''
}

_wifi_nmcli_info() {
    command -v nmcli &>/dev/null || return 1
    nmcli -t -f GENERAL,WIFI-PROPERTIES,IP4,IP6 \
          dev show "$1" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECURITY TYPE DECODER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_security_badge() {
    local security="$1"
    local sc desc
    case "${security^^}" in
        *WPA3*) sc="$(_ngreen)";  desc="WPA3  🔒🔒🔒" ;;
        *WPA2*) sc="$(_ngreen)";  desc="WPA2  🔒🔒"   ;;
        *WPA*)  sc="$(_nyellow)"; desc="WPA   🔒"     ;;
        *WEP*)  sc="$(_nred)";    desc="WEP   ⚠️ INSECURE" ;;
        *OPEN*|"") sc="$(_nred)"; desc="OPEN  🔓"     ;;
        *)      sc="$(_ndim)";    desc="$security"    ;;
    esac
    printf '%s%s%s' "$sc" "$desc" "$(_nr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SIGNAL HISTORY SPARKLINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -ga _WIFI_SIGNAL_HIST=()

_wifi_signal_history() {
    local dbm="$1"
    local normalized=$(( (dbm + 100) * 100 / 70 ))
    (( normalized < 0 )) && normalized=0
    (( normalized > 100 )) && normalized=100

    _WIFI_SIGNAL_HIST+=("$normalized")
    (( ${#_WIFI_SIGNAL_HIST[@]} > 20 )) && \
        _WIFI_SIGNAL_HIST=("${_WIFI_SIGNAL_HIST[@]: -20}")

    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )
    local spark=""
    for v in "${_WIFI_SIGNAL_HIST[@]}"; do
        local idx=$(( v * 7 / 100 ))
        (( idx > 7 )) && idx=7
        spark+="${blocks[$idx]}"
    done

    local sc
    (( normalized >= 70 )) && sc="$(_ngreen)"  || \
    (( normalized >= 40 )) && sc="$(_nyellow)" || \
    sc="$(_nred)"

    printf '%s%s%s' "$sc" "$spark" "$(_nr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL SIGNAL METER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_signal_meter() {
    local dbm="$1"
    local dbm_abs="${dbm#-}"
    local bars desc quality sc

    if   (( dbm_abs <= 50 )); then bars=5; sc="$(_ngreen)";   desc="Excellent";  quality=100
    elif (( dbm_abs <= 60 )); then bars=4; sc="$(_ngreen)";   desc="Good";       quality=75
    elif (( dbm_abs <= 70 )); then bars=3; sc="$(_nyellow)";  desc="Fair";       quality=50
    elif (( dbm_abs <= 80 )); then bars=2; sc="$(_npeach)";   desc="Weak";       quality=25
    else                           bars=1; sc="$(_nred)";     desc="Very Weak";  quality=10
    fi

    # ASCII antenna art
    printf '  %s' "$sc"
    case "$bars" in
        5) printf '▁▂▄▆█  %s  %ddBm  (%s)%s\n' "$desc" "$dbm" "$quality%%" "$(_nr)" ;;
        4) printf '▁▂▄▆░  %s  %ddBm  (%s)%s\n' "$desc" "$dbm" "$quality%%" "$(_nr)" ;;
        3) printf '▁▂▄░░  %s  %ddBm  (%s)%s\n' "$desc" "$dbm" "$quality%%" "$(_nr)" ;;
        2) printf '▁▂░░░  %s  %ddBm  (%s)%s\n' "$desc" "$dbm" "$quality%%" "$(_nr)" ;;
        1) printf '▁░░░░  %s  %ddBm  (%s)%s\n' "$desc" "$dbm" "$quality%%" "$(_nr)" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_wifi() {
    local target_iface=""
    for arg in "${@:-}"; do
        case "$arg" in
            --iface=*) target_iface="${arg#*=}" ;;
            *)         [[ -d "/sys/class/net/${arg}/wireless" ]] && \
                           target_iface="$arg" ;;
        esac
    done

    [[ -z "$target_iface" ]] && target_iface="$(_wifi_find_iface)"

    net_section "📶" "WiFi Connection" "$(_nblue)"

    if [[ -z "$target_iface" ]]; then
        printf '\n  %s⚠  No WiFi interface detected%s\n' "$(_nyellow)" "$(_nr)"
        net_divider; return 0
    fi

    net_kv "Interface" "$target_iface"

    local state
    state="$(net_iface_state "$target_iface")"
    local sc
    [[ "$state" == "up" ]] && sc="$(_ngreen)" || sc="$(_nred)"
    net_kv "State" "${sc}${state}$(_nr)"

    # IP addresses
    local ipv4 ipv6
    ipv4="$(net_iface_ipv4 "$target_iface")"
    ipv6="$(net_iface_ipv6 "$target_iface")"
    [[ -n "$ipv4" ]] && net_kv "IPv4" "$ipv4"
    [[ -n "$ipv6" ]] && net_kv "IPv6" "$ipv6"

    # iw link data
    local iw_link
    iw_link="$(_wifi_get_iw_link "$target_iface")"

    if printf '%s' "$iw_link" | grep -q 'Connected to'; then
        local bssid ssid freq channel
        bssid="$(   printf '%s' "$iw_link" | grep 'Connected to'  | awk '{print $3}')"
        ssid="$(    printf '%s' "$iw_link" | grep 'SSID:'         | awk '{print $2}')"
        freq="$(    printf '%s' "$iw_link" | grep -oP '(?<=freq: )\d+')"
        channel="$( printf '%s' "$iw_link" | grep -oP '(?<=\(on )\w+' | head -1)"

        net_kv "SSID"    "$ssid"
        net_kv "BSSID"   "$bssid"
        net_kv "Freq"    "${freq:+${freq} MHz}"
        net_kv "Channel" "${channel:-?}"

        # Band classification
        local band
        if [[ "$freq" =~ ^[56] ]]; then
            band="${freq:0:1} GHz  ($(( freq >= 5000 ? 5 : 6 ))GHz — fast)"
        else
            band="2.4 GHz  (longer range)"
        fi
        net_kv "Band" "$band"
    else
        printf '  %sNot connected to any network%s\n' "$(_nred)" "$(_nr)"
    fi

    # Station dump: signal + rates
    local iw_station
    iw_station="$(_wifi_get_iw_station "$target_iface")"

    if [[ -n "$iw_station" ]]; then
        local signal tx_bitrate rx_bitrate tx_packets rx_packets
        signal="$(      printf '%s' "$iw_station" | grep 'signal:'      | awk '{print $2}' | head -1)"
        tx_bitrate="$(  printf '%s' "$iw_station" | grep 'tx bitrate:'  | awk '{$1="";$2="";print}' | head -1)"
        rx_bitrate="$(  printf '%s' "$iw_station" | grep 'rx bitrate:'  | awk '{$1="";$2="";print}' | head -1)"
        tx_packets="$(  printf '%s' "$iw_station" | grep 'tx packets:'  | awk '{print $3}')"
        rx_packets="$(  printf '%s' "$iw_station" | grep 'rx packets:'  | awk '{print $3}')"

        net_section "📊" "Signal Quality" "$(_ngreen)"

        if [[ -n "$signal" ]]; then
            _wifi_signal_meter "$signal"
            local spark
            spark="$(_wifi_signal_history "$signal")"
            printf '  %sHistory:%s  %s\n' "$(_ndim)" "$(_nr)" "$spark"
        fi

        [[ -n "$tx_bitrate" ]] && net_kv "TX rate"   "$tx_bitrate"
        [[ -n "$rx_bitrate" ]] && net_kv "RX rate"   "$rx_bitrate"
        [[ -n "$tx_packets" ]] && net_kv "TX pkts"   "$tx_packets"
        [[ -n "$rx_packets" ]] && net_kv "RX pkts"   "$rx_packets"
    fi

    # Security info via nmcli
    if command -v nmcli &>/dev/null; then
        local security
        security="$(nmcli -t -f ACTIVE-CONNECTION.SECURITY,ACTIVE-CONNECTION.STATE \
                    con show --active 2>/dev/null | \
                    grep 'SECURITY' | cut -d: -f2 | head -1)"

        net_section "🔒" "Security" "$(_nlav)"
        net_kv "Protocol" "$(_wifi_security_badge "${security:-UNKNOWN}")"
    fi

    net_divider
}
