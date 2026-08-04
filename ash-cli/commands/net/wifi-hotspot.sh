#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗  ██╗ ██████╗ ████████╗███████╗██████╗  ██████╗ ████████╗                   ║
# ║  ██║  ██║██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗╚══██╔══╝                   ║
# ║  ███████║██║   ██║   ██║   ███████╗██████╔╝██║   ██║   ██║                      ║
# ║  ██╔══██║██║   ██║   ██║   ╚════██║██╔═══╝ ██║   ██║   ██║                      ║
# ║  ██║  ██║╚██████╔╝   ██║   ███████║██║     ╚██████╔╝   ██║                      ║
# ║  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝      ╚═════╝    ╚═╝                      ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net wifi-hotspot                                         ║
# ║  Create WiFi hotspot • QR code • DHCP monitoring • client tracking              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_WIFI_HOTSPOT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_WIFI_HOTSPOT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEFAULTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _HS_DEFAULT_SSID="ASH-Hotspot"
declare -gr _HS_DEFAULT_PASS="ashd0tfiles"
declare -gr _HS_DEFAULT_BAND="bg"      # bg=2.4GHz  a=5GHz
declare -gr _HS_DEFAULT_CHAN="6"
declare -gr _HS_CON_NAME="ash-hotspot"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PRE-FLIGHT CHECKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hs_preflight() {
    local iface="$1"
    local ok=1

    # nmcli required
    if ! command -v nmcli &>/dev/null; then
        printf '  %s✗  nmcli not found — install NetworkManager%s\n' \
            "$(_nred)" "$(_nr)"
        ok=0
    fi

    # WiFi interface
    if [[ -z "$iface" ]]; then
        printf '  %s✗  No WiFi interface found%s\n' "$(_nred)" "$(_nr)"
        ok=0
    fi

    # NetworkManager running
    if ! systemctl is-active NetworkManager &>/dev/null 2>&1; then
        printf '  %s✗  NetworkManager not running%s\n' "$(_nred)" "$(_nr)"
        printf '  %sStart: sudo systemctl start NetworkManager%s\n' \
            "$(_ndim)" "$(_nr)"
        ok=0
    fi

    # AP mode support
    if command -v iw &>/dev/null && [[ -n "$iface" ]]; then
        if ! iw list 2>/dev/null | grep -qA10 'Supported interface modes' | \
             grep -q 'AP'; then
            printf '  %s⚠  WiFi driver may not support AP mode%s\n' \
                "$(_nyellow)" "$(_nr)"
        fi
    fi

    [[ $ok -eq 1 ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  QR CODE GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hs_qr_code() {
    local ssid="$1"  password="$2"  security="${3:-WPA}"

    # WiFi QR string format: WIFI:T:WPA;S:SSID;P:PASSWORD;;
    local wifi_string="WIFI:T:${security};S:${ssid};P:${password};;"

    printf '\n  %sWiFi QR Code:%s\n' "$(_nbold)" "$(_nr)"

    if command -v qrencode &>/dev/null; then
        qrencode -t ANSIUTF8 -m 1 "$wifi_string" 2>/dev/null | \
            sed 's/^/  /'
    elif command -v qr &>/dev/null; then
        qr "$wifi_string" 2>/dev/null
    else
        # Text-based WiFi info box
        printf '\n'
        printf '  %s┌────────────────────────────────────────┐%s\n' \
            "$(_nteal)" "$(_nr)"
        printf '  %s│  📱  Scan to connect  (no qrencode)     │%s\n' \
            "$(_nteal)" "$(_nr)"
        printf '  %s├────────────────────────────────────────┤%s\n' \
            "$(_nteal)" "$(_nr)"
        printf '  %s│  SSID    : %-29s│%s\n' "$(_nteal)" "$ssid"     "$(_nr)"
        printf '  %s│  Password: %-29s│%s\n' "$(_nteal)" "$password"  "$(_nr)"
        printf '  %s│  Security: %-29s│%s\n' "$(_nteal)" "$security"  "$(_nr)"
        printf '  %s└────────────────────────────────────────┘%s\n' \
            "$(_nteal)" "$(_nr)"
        printf '  %sInstall qrencode for QR code: paru -S qrencode%s\n' \
            "$(_ndim)" "$(_nr)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONNECTED CLIENTS MONITOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hs_list_clients() {
    # Try reading ARP table for connected clients
    local clients=0

    printf '\n  %sConnected clients:%s\n' "$(_nbold)" "$(_nr)"
    printf '  %s%-20s  %-18s  %s%s\n' \
        "$(_ndim)" "IP Address" "MAC Address" "Hostname" "$(_nr)"
    printf '  %s%s%s\n' "$(_ndim)" "$(printf '─%.0s' $(seq 1 55))" "$(_nr)"

    # Read from /proc/net/arp
    while IFS=' ' read -r ip hw flags mac mask iface; do
        [[ "$hw" != "0x1" ]] && continue   # only Ethernet
        [[ "$mac" == "00:00:00:00:00:00" ]] && continue
        [[ "$ip" == "IP" ]] && continue    # header

        local hostname
        hostname="$(host "$ip" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//' || echo '?')"
        [[ "$hostname" == "3(NXDOMAIN)" ]] && hostname="?"

        printf '  \033[38;2;137;220;235m%-20s\033[0m  \033[38;2;180;190;254m%-18s\033[0m  \033[38;2;108;112;134m%s\033[0m\n' \
            "$ip" "$mac" "$hostname"
        (( clients++ )) || true
    done < /proc/net/arp 2>/dev/null

    (( clients == 0 )) && \
        printf '  %sNo clients connected yet%s\n' "$(_ndim)" "$(_nr)"

    printf '\n  %s%d client(s)%s\n' "$(_ndim)" "$clients" "$(_nr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HOTSPOT CONTROL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hs_start() {
    local ssid="$1"  password="$2"  iface="$3"  band="$4"  chan="$5"

    printf '\n  %s→  Creating hotspot...%s\n' "$(_nteal)" "$(_nr)"

    # Delete existing connection with same name
    nmcli con delete "$_HS_CON_NAME" &>/dev/null || true

    local cmd=(
        nmcli dev wifi hotspot
        ifname  "$iface"
        ssid    "$ssid"
        password "$password"
        con-name "$_HS_CON_NAME"
    )

    local output exit_code=0
    output="$("${cmd[@]}" 2>&1)" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        printf '  %s✓  Hotspot created successfully%s\n' "$(_ngreen)" "$(_nr)"
        return 0
    else
        printf '  %s✗  Failed to create hotspot%s\n' "$(_nred)" "$(_nr)"
        printf '  %s%s%s\n' "$(_ndim)" "$output" "$(_nr)"
        return 1
    fi
}

_hs_stop() {
    printf '  %s→  Stopping hotspot...%s\n' "$(_nteal)" "$(_nr)"
    if nmcli con down "$_HS_CON_NAME" &>/dev/null && \
       nmcli con delete "$_HS_CON_NAME" &>/dev/null; then
        printf '  %s✓  Hotspot stopped%s\n' "$(_ngreen)" "$(_nr)"
    else
        printf '  %s⚠  Hotspot may not have been running%s\n' \
            "$(_nyellow)" "$(_nr)"
    fi
}

_hs_status() {
    local active
    active="$(nmcli -t -f NAME,ACTIVE con show 2>/dev/null | \
              grep "^${_HS_CON_NAME}:yes" || echo '')"

    if [[ -n "$active" ]]; then
        printf '  %s●  Hotspot is ACTIVE%s\n' "$(_ngreen)" "$(_nr)"
        return 0
    else
        printf '  %s○  Hotspot is NOT running%s\n' "$(_ndim)" "$(_nr)"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HOTSPOT INFO BOX
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hs_info_box() {
    local ssid="$1"  password="$2"  iface="$3"  band="$4"

    local hotspot_ip
    hotspot_ip="$(net_iface_ipv4 "$iface" 2>/dev/null || echo '10.42.0.1')"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n  \033[1;38;2;148;226;213m'
        printf '  ╔══════════════════════════════════════════════╗\n'
        printf '  ║  📡  HOTSPOT ACTIVE                           ║\n'
        printf '  ╠══════════════════════════════════════════════╣\n'
        printf '  ║  SSID     : %-33s║\n' "$ssid"
        printf '  ║  Password : %-33s║\n' "$password"
        printf '  ║  Band     : %-33s║\n' "${band:-2.4GHz}"
        printf '  ║  Gateway  : %-33s║\n' "$hotspot_ip"
        printf '  ║  Interface: %-33s║\n' "$iface"
        printf '  ╚══════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n  HOTSPOT ACTIVE\n'
        printf '  SSID: %s  Password: %s\n' "$ssid" "$password"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_wifi_hotspot() {
    local action="start"
    local ssid="$_HS_DEFAULT_SSID"
    local password="$_HS_DEFAULT_PASS"
    local band="$_HS_DEFAULT_BAND"
    local channel="$_HS_DEFAULT_CHAN"
    local iface=""
    local show_qr=1
    local show_clients=0

    for arg in "${@:-}"; do
        case "$arg" in
            stop|-d|--stop)       action="stop"        ;;
            status|--status)      action="status"      ;;
            clients|--clients)    action="clients"     ;;
            --ssid=*)             ssid="${arg#*=}"     ;;
            --password=*|-p=*)    password="${arg#*=}" ;;
            --band=*)             band="${arg#*=}"     ;;
            --channel=*)          channel="${arg#*=}"  ;;
            --iface=*)            iface="${arg#*=}"    ;;
            --no-qr)              show_qr=0            ;;
            --clients)            show_clients=1       ;;
        esac
    done

    # Auto-detect WiFi iface
    if [[ -z "$iface" ]]; then
        for i in /sys/class/net/*/wireless; do
            [[ -d "$i" ]] && iface="${i%/wireless}" && \
                iface="${iface##*/}" && break
        done
    fi

    net_section "📡" "WiFi Hotspot" "$(_npink)"
    net_kv "Interface" "${iface:-none}"

    case "$action" in
        stop)
            _hs_stop
            ;;

        status)
            net_section "ℹ" "Hotspot Status" "$(_nblue)"
            _hs_status
            _hs_list_clients
            ;;

        clients)
            net_section "👥" "Connected Clients" "$(_nteal)"
            _hs_list_clients
            ;;

        start|*)
            _hs_preflight "$iface" || { net_divider; return 1; }

            # Check if already running
            if _hs_status &>/dev/null; then
                printf '  %s⚠  Hotspot already running. Use --stop to stop it.%s\n' \
                    "$(_nyellow)" "$(_nr)"
            else
                # Validate password length
                if (( ${#password} < 8 )); then
                    printf '  %s✗  Password must be at least 8 characters%s\n' \
                        "$(_nred)" "$(_nr)"
                    net_divider; return 1
                fi

                net_kv "SSID"     "$ssid"
                net_kv "Password" "$(printf '%s' "$password" | sed 's/./*/g')"
                net_kv "Band"     "$band"
                net_kv "Channel"  "$channel"

                if ! _hs_start "$ssid" "$password" "$iface" "$band" "$channel"; then
                    net_divider; return 1
                fi
            fi

            _hs_info_box "$ssid" "$password" "$iface" "$band"

            [[ $show_qr -eq 1 ]] && _hs_qr_code "$ssid" "$password" "WPA"

            # Optionally enable IP forwarding for NAT
            local cur_fwd
            cur_fwd="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 0)"
            if [[ "$cur_fwd" != "1" ]]; then
                printf '\n  %sℹ  Enable internet sharing?%s  [Y/n] ' \
                    "$(_nyellow)" "$(_nr)"
                local ans
                read -r ans
                if [[ "${ans,,}" != "n" ]]; then
                    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward &>/dev/null && \
                        printf '  %s✓  IP forwarding enabled (NAT active)%s\n' \
                            "$(_ngreen)" "$(_nr)"
                fi
            else
                printf '  %s✓  IP forwarding already enabled%s\n' \
                    "$(_ngreen)" "$(_nr)"
            fi

            [[ $show_clients -eq 1 ]] && _hs_list_clients

            # Send notification
            command -v notify-send &>/dev/null && \
                notify-send "📡 WiFi Hotspot Active" \
                    "SSID: ${ssid}  Password: ${password}" \
                    --icon=network-wireless-hotspot 2>/dev/null || true

            printf '\n  %sTo stop: ash net wifi-hotspot stop%s\n' \
                "$(_ndim)" "$(_nr)"
            printf '  %sTo monitor: ash net wifi-hotspot clients%s\n' \
                "$(_ndim)" "$(_nr)"
            ;;
    esac

    net_divider
}
