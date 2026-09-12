#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  net status                                               ║
# ║  Live network interface status • IPs • gateway • DNS • connectivity             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_STATUS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_STATUS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONNECTIVITY TEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_status_ping_test() {
    local host="$1"  label="$2"
    if ping -c 1 -W 1 -q "$host" &>/dev/null 2>&1; then
        local ms
        ms="$(ping -c 2 -W 1 -q "$host" 2>/dev/null | \
              awk -F'/' '/rtt/{printf "%.1f", $5}')"
        printf '  %s✓%s  %-22s %s%s ms%s\n' \
            "$(_ngreen)" "$(_nr)" "$label" "$(_ndim)" "${ms:-?}" "$(_nr)"
        return 0
    else
        printf '  %s✗%s  %-22s %sunreachable%s\n' \
            "$(_nred)" "$(_nr)" "$label" "$(_nred)" "$(_nr)"
        return 1
    fi
}

_status_dns_test() {
    local host="${1:-archlinux.org}"  ns="${2:-}"
    local start_ns end_ns elapsed
    start_ns="$(date +%s%N)"

    local cmd=( "getent" "hosts" "$host" )
    command -v dig &>/dev/null && \
        cmd=( "dig" "+short" "+timeout=3" "+tries=1" ${ns:+@"$ns"} "$host" )

    if "${cmd[@]}" &>/dev/null 2>&1; then
        end_ns="$(date +%s%N)"
        elapsed=$(( (end_ns - start_ns) / 1000000 ))
        printf '  %s✓%s  DNS resolve %-12s %s%d ms%s\n' \
            "$(_ngreen)" "$(_nr)" "${ns:-system}" "$(_ndim)" "$elapsed" "$(_nr)"
    else
        printf '  %s✗%s  DNS resolve %-12s %sfailed%s\n' \
            "$(_nred)" "$(_nr)" "${ns:-system}" "$(_nred)" "$(_nr)"
    fi
}

_status_public_ip() {
    local ip=""
    local -a services=(
        "https://api4.my-ip.io/ip"
        "https://ipv4.icanhazip.com"
        "https://checkip.amazonaws.com"
    )
    for svc in "${services[@]}"; do
        ip="$(curl -fsSL --max-time 3 --connect-timeout 2 "$svc" 2>/dev/null | tr -d '[:space:]')"
        [[ -n "$ip" ]] && break
    done
    printf '%s' "${ip:-?}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERFACE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_status_render_iface() {
    local iface="$1"
    local state mac ipv4 ipv6 speed rx_b tx_b driver
    state="$(net_iface_state "$iface")"
    mac="$(  net_iface_mac   "$iface")"
    ipv4="$( net_iface_ipv4  "$iface")"
    ipv6="$( net_iface_ipv6  "$iface")"
    rx_b="$( net_iface_rx_bytes "$iface")"
    tx_b="$( net_iface_tx_bytes "$iface")"

    # Type icon
    local type_icon type_label
    if net_is_wifi "$iface"; then
        type_icon="📶"; type_label="WiFi"
    else
        case "$iface" in
            lo)           type_icon="🔄"; type_label="Loopback" ;;
            wg*|tun*|tap*)type_icon="🔒"; type_label="VPN"      ;;
            docker*|br-*) type_icon="🐳"; type_label="Bridge"   ;;
            veth*)        type_icon="🔗"; type_label="vEth"     ;;
            *)            type_icon="🔌"; type_label="Ethernet" ;;
        esac
    fi

    # State color
    local sc
    case "$state" in
        up)       sc="$(_ngreen)"   ;;
        down)     sc="$(_nred)"     ;;
        dormant)  sc="$(_nyellow)"  ;;
        *)        sc="$(_ndim)"     ;;
    esac

    # Header
    printf '\n  %s  %s%s%s  %s%s%s  %s(%s)%s\n' \
        "$type_icon" \
        "$(_nsky)$(_nbold)" "$iface" "$(_nr)" \
        "$sc" "$state" "$(_nr)" \
        "$(_ndim)" "$type_label" "$(_nr)"

    net_kv "MAC"   "$mac"
    [[ -n "$ipv4" ]] && net_kv "IPv4" "$ipv4"
    [[ -n "$ipv6" ]] && net_kv "IPv6" "$ipv6"

    # Speed
    speed="$(net_iface_speed "$iface")"
    if [[ "$speed" =~ ^[0-9]+$ ]] && (( speed > 0 )); then
        local sc2
        (( speed >= 10000 )) && sc2="$(_npink)"  || \
        (( speed >= 1000  )) && sc2="$(_ngreen)" || \
        sc2="$(_nyellow)"
        net_kv "Link speed" "${sc2}${speed} Mbps$(_nr)"
    fi

    # RX / TX
    net_kv "RX  ↓" "$(net_human "$rx_b")"
    net_kv "TX  ↑" "$(net_human "$tx_b")"

    # WiFi extras
    if net_is_wifi "$iface" && command -v iw &>/dev/null; then
        local ssid freq signal bitrate
        local iw_out
        iw_out="$(iw dev "$iface" link 2>/dev/null || echo '')"

        ssid="$(    printf '%s' "$iw_out" | awk '/SSID:/{print $2}')"
        freq="$(    printf '%s' "$iw_out" | grep -oP '(?<=freq: )\d+')"
        signal="$(  printf '%s' "$iw_out" | grep -oP '(?<=signal: )-?\d+')"
        bitrate="$( printf '%s' "$iw_out" | grep 'tx bitrate' | \
                    awk '{print $3,$4}' | head -1)"

        [[ -n "$ssid"    ]] && net_kv "SSID"     "$ssid"
        [[ -n "$freq"    ]] && net_kv "Frequency" "${freq} MHz"
        [[ -n "$signal"  ]] && net_signal_bar "$signal" "Signal"
        [[ -n "$bitrate" ]] && net_kv "TX rate"  "$bitrate"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_status() {
    local target_iface=""  show_public=0  short=0
    for arg in "${@:-}"; do
        case "$arg" in
            --public|-p)     show_public=1 ;;
            --short|-s)      short=1       ;;
            --iface=*)       target_iface="${arg#*=}" ;;
            *)               target_iface="$arg"      ;;
        esac
    done

    net_section "🌐" "Network Status" "$(_nsky)"

    # ── Interfaces ───────────────────────────────────────────────────────────────
    local -a ifaces=()
    if [[ -n "$target_iface" ]]; then
        ifaces=("$target_iface")
    else
        mapfile -t ifaces < <(
            ls /sys/class/net/ 2>/dev/null | sort | while read -r i; do
                [[ "$i" == "lo" ]] && continue
                state="$(cat "/sys/class/net/${i}/operstate" 2>/dev/null)"
                printf '%s %s\n' "$([[ "$state" == "up" ]] && echo 0 || echo 1)" "$i"
            done | sort | awk '{print $2}'
        )
    fi

    for iface in "${ifaces[@]}"; do
        [[ -e "/sys/class/net/${iface}" ]] || continue
        _status_render_iface "$iface"
    done

    # ── Gateway & DNS ─────────────────────────────────────────────────────────────
    net_section "🔀" "Gateway & DNS" "$(_nteal)"

    local gw
    gw="$(net_default_gw)"
    net_kv "Default gateway" "${gw:-none}"

    # Read nameservers
    local -a ns_list=()
    if command -v resolvectl &>/dev/null && \
       systemctl is-active systemd-resolved &>/dev/null 2>&1; then
        mapfile -t ns_list < <(
            resolvectl status 2>/dev/null | \
            grep 'DNS Servers' | awk '{for(i=3;i<=NF;i++)print $i}'
        )
    else
        mapfile -t ns_list < <(
            grep '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}'
        )
    fi

    for ns in "${ns_list[@]:0:3}"; do
        net_kv "Nameserver" "$ns"
    done

    if [[ $short -eq 0 ]]; then
        # ── Connectivity ──────────────────────────────────────────────────────────
        net_section "📡" "Connectivity" "$(_npeach)"

        [[ -n "$gw" ]] && _status_ping_test "$gw" "Gateway"
        _status_ping_test "1.1.1.1"  "Cloudflare (1.1.1.1)"
        _status_ping_test "8.8.8.8"  "Google (8.8.8.8)"
        _status_dns_test  "archlinux.org"

        if [[ $show_public -eq 1 ]]; then
            net_section "🌍" "Public IP" "$(_nlav)"
            printf '  %s' "$(_ndim)Fetching...$(_nr)"
            local pub_ip
            pub_ip="$(_status_public_ip)"
            printf '\r'
            net_kv "Public IPv4" "$pub_ip"
        fi
    fi

    net_divider
}
