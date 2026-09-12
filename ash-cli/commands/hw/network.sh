#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗                 ║
# ║  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝                 ║
# ║  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                  ║
# ║  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                  ║
# ║  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗                 ║
# ║  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                 ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw network                                               ║
# ║  Interface details • driver • link speed • RX/TX stats • WiFi signal            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_NETWORK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_NETWORK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERFACE DATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_sysfs() {
    local iface="$1" field="$2"
    cat "/sys/class/net/${iface}/${field}" 2>/dev/null | tr -d '\n' || printf ''
}

_net_sysfs_int() {
    local v
    v="$(_net_sysfs "$1" "$2")"
    printf '%d' "${v:-0}" 2>/dev/null || printf '0'
}

_net_driver() {
    local iface="$1"
    readlink -f "/sys/class/net/${iface}/device/driver" 2>/dev/null | \
        xargs basename 2>/dev/null || echo 'unknown'
}

_net_link_speed_mbps() {
    local iface="$1"
    local spd
    spd="$(_net_sysfs "$iface" "speed")"
    [[ "$spd" =~ ^[0-9]+$ ]] && printf '%s' "$spd" || printf '?'
}

_net_duplex() {
    _net_sysfs "$1" "duplex" || echo '?'
}

_net_mac() {
    _net_sysfs "$1" "address" || echo '?'
}

_net_operstate() {
    _net_sysfs "$1" "operstate" || echo '?'
}

_net_carrier() {
    _net_sysfs_int "$1" "carrier"
}

_net_mtu() {
    _net_sysfs_int "$1" "mtu"
}

_net_rx_bytes() { _net_sysfs_int "$1" "statistics/rx_bytes";   }
_net_tx_bytes() { _net_sysfs_int "$1" "statistics/tx_bytes";   }
_net_rx_pkts()  { _net_sysfs_int "$1" "statistics/rx_packets"; }
_net_tx_pkts()  { _net_sysfs_int "$1" "statistics/tx_packets"; }
_net_rx_errs()  { _net_sysfs_int "$1" "statistics/rx_errors";  }
_net_tx_errs()  { _net_sysfs_int "$1" "statistics/tx_errors";  }

_net_ipv4() {
    ip -4 addr show "$1" 2>/dev/null | awk '/inet /{print $2}' | head -3 | tr '\n' '  '
}

_net_ipv6() {
    ip -6 addr show "$1" 2>/dev/null | awk '/inet6 /{print $2}' | \
        grep -v '^fe80' | head -2 | tr '\n' '  '
}

_net_gw() {
    ip route show dev "$1" 2>/dev/null | awk '/default/{print $3}' | head -1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WIFI-SPECIFIC
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_wifi_info() {
    local iface="$1"
    command -v iw &>/dev/null || return 1
    iw dev "$iface" info 2>/dev/null || true
}

_net_wifi_signal() {
    local iface="$1"
    command -v iw &>/dev/null || return 1
    iw dev "$iface" station dump 2>/dev/null | \
        grep -E 'signal:|tx bitrate:|rx bitrate:' | head -6 || true
}

_net_wifi_signal_bars() {
    local dbm="$1"
    # Convert dBm to bars (0-4)
    local dbm_abs="${dbm#-}"
    if (( dbm_abs <= 50 )); then
        printf '█████  Excellent'
    elif (( dbm_abs <= 60 )); then
        printf '████░  Good'
    elif (( dbm_abs <= 70 )); then
        printf '███░░  Fair'
    elif (( dbm_abs <= 80 )); then
        printf '██░░░  Weak'
    else
        printf '█░░░░  Very Weak'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERFACE TYPE CLASSIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_classify() {
    local iface="$1"
    case "$iface" in
        eth*|enp*|eno*|ens*|enx*) printf 'ethernet' ;;
        wlan*|wlp*|wlx*|wifi*)   printf 'wifi'     ;;
        wg*)                       printf 'wireguard' ;;
        tun*|tap*)                 printf 'vpn'      ;;
        docker*|br-*)              printf 'bridge'   ;;
        veth*)                     printf 'veth'     ;;
        lo)                        printf 'loopback' ;;
        bond*)                     printf 'bond'     ;;
        *)                         printf 'other'    ;;
    esac
}

_net_type_icon() {
    case "$1" in
        ethernet)  printf '🔌' ;;
        wifi)      printf '📶' ;;
        wireguard) printf '🔒' ;;
        vpn)       printf '🔒' ;;
        bridge)    printf '🌉' ;;
        veth)      printf '🔗' ;;
        loopback)  printf '🔄' ;;
        *)         printf '🌐' ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER ONE INTERFACE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_net_render_iface() {
    local iface="$1"
    local type
    type="$(_net_classify "$iface")"
    local icon
    icon="$(_net_type_icon "$type")"

    local state
    state="$(_net_operstate "$iface")"
    local state_color
    case "$state" in
        up)       state_color="\033[38;2;166;227;161m" ;;
        down)     state_color="\033[38;2;243;139;168m" ;;
        dormant)  state_color="\033[38;2;249;226;175m" ;;
        *)        state_color="\033[38;2;108;112;134m" ;;
    esac

    printf '\n  %s  \033[1;38;2;137;220;235m%-12s\033[0m  %s%s\033[0m  \033[38;2;108;112;134m(%s)\033[0m\n' \
        "$icon" "$iface" "$state_color" "$state" "$type"

    hw_kv "MAC"          "$(_net_mac "$iface")"
    hw_kv "Driver"       "$(_net_driver "$iface")"
    hw_kv "MTU"          "$(_net_mtu "$iface") bytes"

    local ipv4
    ipv4="$(_net_ipv4 "$iface")"
    [[ -n "$ipv4" ]] && hw_kv "IPv4" "$ipv4"

    local ipv6
    ipv6="$(_net_ipv6 "$iface")"
    [[ -n "$ipv6" ]] && hw_kv "IPv6" "$ipv6"

    local gw
    gw="$(_net_gw "$iface")"
    [[ -n "$gw" ]] && hw_kv "Gateway" "$gw"

    # Speed
    local speed
    speed="$(_net_link_speed_mbps "$iface")"
    if [[ "$speed" != "?" ]]; then
        local duplex
        duplex="$(_net_duplex "$iface")"
        local speed_color
        if   (( speed >= 10000 )); then speed_color="\033[38;2;203;166;247m"
        elif (( speed >= 1000  )); then speed_color="\033[38;2;166;227;161m"
        elif (( speed >= 100   )); then speed_color="\033[38;2;249;226;175m"
        else                           speed_color="\033[38;2;108;112;134m"
        fi
        hw_kv "Link speed" "${speed_color}${speed} Mbps  (${duplex})\033[0m"
    fi

    # RX/TX stats
    local rx_b tx_b rx_e tx_e
    rx_b="$(_net_rx_bytes "$iface")"
    tx_b="$(_net_tx_bytes "$iface")"
    rx_e="$(_net_rx_errs  "$iface")"
    tx_e="$(_net_tx_errs  "$iface")"

    hw_kv "RX" "$(hw_human_bytes "$rx_b")  (errors: $rx_e)"
    hw_kv "TX" "$(hw_human_bytes "$tx_b")  (errors: $tx_e)"

    # WiFi-specific
    if [[ "$type" == "wifi" ]]; then
        local wifi_info
        wifi_info="$(_net_wifi_info "$iface" 2>/dev/null || echo '')"

        if [[ -n "$wifi_info" ]]; then
            local ssid channel freq
            ssid="$(    printf '%s' "$wifi_info" | grep 'ssid'    | awk '{print $2}')"
            channel="$( printf '%s' "$wifi_info" | grep 'channel' | awk '{print $2}')"
            freq="$(    printf '%s' "$wifi_info" | grep 'channel' | grep -oP '\(\K\d+')"
            [[ -n "$ssid"    ]] && hw_kv "SSID"    "$ssid"
            [[ -n "$channel" ]] && hw_kv "Channel" "${channel}  (${freq:-?} MHz)"
        fi

        local wifi_signal
        wifi_signal="$(_net_wifi_signal "$iface" 2>/dev/null || echo '')"
        if [[ -n "$wifi_signal" ]]; then
            local sig_dbm
            sig_dbm="$(printf '%s' "$wifi_signal" | grep 'signal:' | awk '{print $2}')"
            local txrate
            txrate="$( printf '%s' "$wifi_signal" | grep 'tx bitrate:' | awk '{$1="";print}' | sed 's/^ //')"
            local rxrate
            rxrate="$( printf '%s' "$wifi_signal" | grep 'rx bitrate:' | awk '{$1="";print}' | sed 's/^ //')"

            if [[ -n "$sig_dbm" ]]; then
                local bars
                bars="$(_net_wifi_signal_bars "$sig_dbm")"
                hw_kv "Signal" "${sig_dbm} dBm  •  ${bars}"
            fi
            [[ -n "$txrate" ]] && hw_kv "TX rate" "$txrate"
            [[ -n "$rxrate" ]] && hw_kv "RX rate" "$rxrate"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_network() {
    local show_all=0
    local target_iface=""
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --all)    show_all=1     ;;
            --short)  short=1        ;;
            *)        target_iface="$arg" ;;
        esac
    done

    hw_section "🌐" "Network Interfaces" "\033[38;2;137;220;235m"

    local -a ifaces=()

    if [[ -n "$target_iface" ]]; then
        ifaces=("$target_iface")
    else
        mapfile -t ifaces < <(
            ls /sys/class/net/ 2>/dev/null | \
            grep -v '^lo$' | \
            sort
        )
        # Put active interfaces first
        mapfile -t ifaces < <(
            for i in "${ifaces[@]}"; do
                local s
                s="$(_net_operstate "$i")"
                printf '%s %s\n' "$s" "$i"
            done | sort | awk '{print $2}'
        )
    fi

    local rendered=0
    for iface in "${ifaces[@]}"; do
        [[ -e "/sys/class/net/${iface}" ]] || continue

        local itype
        itype="$(_net_classify "$iface")"

        # Skip virtual by default
        if [[ $show_all -eq 0 ]]; then
            case "$itype" in
                bridge|veth|loopback) continue ;;
            esac
        fi

        _net_render_iface "$iface"
        (( rendered++ )) || true
    done

    if (( rendered == 0 )); then
        printf '\n  \033[38;2;249;226;175m⚠  No network interfaces found\033[0m\n'
    fi

    # ── DNS ───────────────────────────────────────────────────────────────────────
    if [[ $short -eq 0 ]]; then
        hw_section "🔍" "DNS Configuration" "\033[38;2;148;226;213m"

        if command -v resolvectl &>/dev/null; then
            local dns_out
            dns_out="$(resolvectl status 2>/dev/null | \
                       grep -E 'DNS Server|DNS Domain|Current DNS' | head -6 || echo '')"
            while IFS= read -r dline; do
                [[ -z "$dline" ]] && continue
                printf '  \033[38;2;108;112;134m%s\033[0m\n' "$dline"
            done <<< "$dns_out"
        else
            grep '^nameserver\|^domain\|^search' /etc/resolv.conf 2>/dev/null | \
            while IFS= read -r rline; do
                printf '  \033[38;2;108;112;134m%s\033[0m\n' "$rline"
            done
        fi
    fi

    hw_divider
}
