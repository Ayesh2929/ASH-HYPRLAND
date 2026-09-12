#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗                 ║
# ║  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝                 ║
# ║  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝                  ║
# ║  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗                  ║
# ║  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗                 ║
# ║  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝                 ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: NETWORK                                   ║
# ║  Interfaces • DNS • Connectivity • WiFi • VPN • Firewall • Portals              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_NETWORK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_NETWORK_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR PALETTE  (Catppuccin Mocha — inline, no lib dependency)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_nc_bold()  { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[1m'                || true; }
_nc_reset() { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[0m'                || true; }
_nc_blue()  { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[38;2;137;180;250m' || true; }
_nc_green() { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[38;2;166;227;161m' || true; }
_nc_red()   { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[1;38;2;243;139;168m' || true; }
_nc_yellow(){ [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[1;38;2;249;226;175m' || true; }
_nc_dim()   { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[38;2;108;112;134m' || true; }
_nc_teal()  { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[38;2;148;226;213m' || true; }
_nc_sky()   { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '\033[38;2;137;220;235m' || true; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SHARED PROBE HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ping with 1-second timeout, 2 packets, suppress output
_net_ping() {
    local host="${1:-8.8.8.8}"
    ping -c 2 -W 1 -q "$host" &>/dev/null
}

# HTTP GET with 5s timeout, return HTTP status code
_net_curl_status() {
    local url="$1"
    curl -s -o /dev/null -w '%{http_code}' \
         --max-time 5 --connect-timeout 3 "$url" 2>/dev/null || echo '000'
}

# DNS resolution test
_net_resolve() {
    local host="${1:-archlinux.org}"
    if command -v dig &>/dev/null; then
        dig +short +timeout=3 +tries=1 "$host" &>/dev/null
    elif command -v nslookup &>/dev/null; then
        nslookup -timeout=3 "$host" &>/dev/null
    elif command -v host &>/dev/null; then
        host -W 3 "$host" &>/dev/null
    else
        getent hosts "$host" &>/dev/null
    fi
}

# Measure latency to a host (ms)
_net_latency_ms() {
    local host="${1:-8.8.8.8}"
    ping -c 3 -W 1 -q "$host" 2>/dev/null | \
        awk -F'/' '/rtt/{printf "%.1f", $5}' || echo '?'
}

# Get default gateway
_net_default_gw() {
    ip route show default 2>/dev/null | \
        awk '/default via/{print $3; exit}' || echo ''
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — NETWORK INTERFACES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_interfaces() {
    _check_header "🌐 Network Interfaces"

    if ! command -v ip &>/dev/null; then
        _check_report $CHECK_FAIL \
            "ip command" \
            "Not found" \
            "Install: paru -S iproute2"
        return $CHECK_FAIL
    fi

    # ── Enumerate all non-loopback interfaces ────────────────────────────────────
    local -a iface_lines=()
    mapfile -t iface_lines < <(
        ip -br link show 2>/dev/null | grep -v '^lo\s'
    )

    if [[ ${#iface_lines[@]} -eq 0 ]]; then
        _check_report $CHECK_FAIL \
            "Network interfaces" \
            "No non-loopback interfaces found" \
            "Check: ip link show"
        return $CHECK_FAIL
    fi

    local up_count=0 down_count=0 total_count=0

    for iface_line in "${iface_lines[@]}"; do
        [[ -z "$iface_line" ]] && continue

        local iface state mac
        iface="$(printf '%s' "$iface_line" | awk '{print $1}' | tr -d ':')"
        state="$(printf '%s' "$iface_line" | awk '{print $2}')"
        mac="$(  printf '%s' "$iface_line" | awk '{print $3}')"

        (( total_count++ )) || true

        # Classify interface type
        local iface_icon iface_type
        case "$iface" in
            eth*|enp*|eno*|ens*|enx*)
                iface_icon="🔌"; iface_type="Ethernet" ;;
            wlan*|wlp*|wlx*|wifi*)
                iface_icon="📶"; iface_type="WiFi" ;;
            wg*|tun*|tap*)
                iface_icon="🔒"; iface_type="VPN/Tunnel" ;;
            docker*|br-*|virbr*)
                iface_icon="🐳"; iface_type="Bridge/Container" ;;
            veth*)
                iface_icon="🔗"; iface_type="Virtual Ethernet" ;;
            bond*)
                iface_icon="⛓️ "; iface_type="Bond" ;;
            *)
                iface_icon="🔧"; iface_type="Other" ;;
        esac

        # Get IPv4 and IPv6 addresses
        local ipv4 ipv6
        ipv4="$(ip -4 addr show "$iface" 2>/dev/null | \
                awk '/inet /{print $2}' | head -1 || echo '')"
        ipv6="$(ip -6 addr show "$iface" 2>/dev/null | \
                awk '/inet6 /{print $2}' | grep -v 'fe80\|::1' | head -1 || echo '')"

        # Get speed / duplex for ethernet
        local speed_info=""
        if [[ -f "/sys/class/net/${iface}/speed" ]]; then
            local speed
            speed="$(cat "/sys/class/net/${iface}/speed" 2>/dev/null || echo '?')"
            local duplex
            duplex="$(cat "/sys/class/net/${iface}/duplex" 2>/dev/null || echo '?')"
            [[ "$speed" =~ ^[0-9]+$ ]] && speed_info="  •  ${speed}Mbps ${duplex}"
        fi

        # Get RX/TX bytes from sysfs
        local rx_bytes tx_bytes traffic_info=""
        rx_bytes="$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)"
        tx_bytes="$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)"
        if (( rx_bytes > 0 || tx_bytes > 0 )); then
            local rx_mb tx_mb
            rx_mb=$(( rx_bytes / 1048576 ))
            tx_mb=$(( tx_bytes / 1048576 ))
            traffic_info="  •  ↓${rx_mb}MB ↑${tx_mb}MB"
        fi

        # Status logic
        local addr_str="${ipv4:-no IPv4}"
        [[ -n "$ipv6" ]] && addr_str+="  •  ${ipv6}"

        if [[ "$state" == "UP" ]]; then
            (( up_count++ )) || true
            _check_report $CHECK_PASS \
                "${iface_icon} ${iface}  [${iface_type}]" \
                "UP  •  ${addr_str}${speed_info}${traffic_info}"
        elif [[ "$state" == "DORMANT" ]]; then
            _check_report $CHECK_INFO \
                "${iface_icon} ${iface}  [${iface_type}]" \
                "DORMANT  •  ${addr_str}"
        else
            (( down_count++ )) || true
            _check_report $CHECK_INFO \
                "${iface_icon} ${iface}  [${iface_type}]" \
                "DOWN  •  mac: ${mac}"
        fi
    done

    # ── Summary line ─────────────────────────────────────────────────────────────
    _check_report $CHECK_INFO \
        "Interface summary" \
        "${total_count} total  •  ${up_count} up  •  ${down_count} down"

    # ── Default gateway ──────────────────────────────────────────────────────────
    local gw
    gw="$(_net_default_gw)"
    if [[ -n "$gw" ]]; then
        local gw_iface
        gw_iface="$(ip route show default 2>/dev/null | awk '/default/{print $5}' | head -1)"
        _check_report $CHECK_PASS \
            "Default gateway" \
            "${gw}  via  ${gw_iface:-?}"
    else
        _check_report $CHECK_FAIL \
            "Default gateway" \
            "No default route found" \
            "Check: ip route  and reconnect your network"
    fi

    # ── Loopback sanity ──────────────────────────────────────────────────────────
    if ip link show lo 2>/dev/null | grep -q 'state UNKNOWN\|state UP'; then
        _check_report $CHECK_PASS \
            "Loopback (lo)" \
            "Active  (127.0.0.1)"
    else
        _check_report $CHECK_FAIL \
            "Loopback (lo)" \
            "Not up" \
            "Bring up: sudo ip link set lo up"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — CONNECTIVITY & LATENCY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_connectivity() {
    _check_header "🚀 Internet Connectivity & Latency"

    # ── Captive portal / connectivity check ─────────────────────────────────────
    local captive_url="http://connectivitycheck.gstatic.com/generate_204"
    local captive_code
    captive_code="$(_net_curl_status "$captive_url")"

    if [[ "$captive_code" == "204" ]]; then
        _check_report $CHECK_PASS \
            "Captive portal check" \
            "No captive portal  (generate_204 → 204)"
    elif [[ "$captive_code" == "200" ]]; then
        _check_report $CHECK_WARN \
            "Captive portal check" \
            "Possible captive portal  (HTTP 200 on generate_204)" \
            "Open browser and complete captive portal login"
    elif [[ "$captive_code" == "000" ]]; then
        _check_report $CHECK_FAIL \
            "Captive portal check" \
            "No internet connectivity  (curl failed)"
    else
        _check_report $CHECK_INFO \
            "Captive portal check" \
            "HTTP ${captive_code}"
    fi

    # ── Multi-target latency probes ──────────────────────────────────────────────
    declare -A latency_targets=(
        ["Google DNS"]="8.8.8.8"
        ["Cloudflare DNS"]="1.1.1.1"
        ["Gateway"]="$(_net_default_gw)"
    )

    for label in "Gateway" "Cloudflare DNS" "Google DNS"; do
        local target="${latency_targets[$label]:-}"
        [[ -z "$target" ]] && continue

        if _net_ping "$target"; then
            local ms
            ms="$(_net_latency_ms "$target")"

            local lat_status=$CHECK_PASS
            local lat_note=""
            if [[ "$ms" =~ ^[0-9.]+ ]]; then
                local ms_int="${ms%.*}"
                if (( ms_int > 100 )); then
                    lat_status=$CHECK_WARN
                    lat_note="  (high latency)"
                elif (( ms_int > 50 )); then
                    lat_note="  (acceptable)"
                else
                    lat_note="  (excellent)"
                fi
            fi

            _check_report $lat_status \
                "Ping: ${label}" \
                "${target}  •  ${ms}ms${lat_note}"
        else
            _check_report $CHECK_WARN \
                "Ping: ${label}" \
                "${target}  •  unreachable" \
                "Check firewall or connection to ${target}"
        fi
    done

    # ── HTTPS reachability ───────────────────────────────────────────────────────
    local -a https_targets=(
        "https://archlinux.org:Arch Linux"
        "https://github.com:GitHub"
        "https://aur.archlinux.org:AUR"
    )

    for entry in "${https_targets[@]}"; do
        IFS=':' read -r url label <<< "$entry"
        local code
        code="$(_net_curl_status "$url")"
        if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
            _check_report $CHECK_PASS \
                "HTTPS: ${label}" \
                "${url}  →  HTTP ${code}"
        else
            _check_report $CHECK_WARN \
                "HTTPS: ${label}" \
                "${url}  →  HTTP ${code}  (unreachable?)" \
                "Check proxy / firewall settings"
        fi
    done

    # ── IPv6 connectivity ────────────────────────────────────────────────────────
    if ping -6 -c 2 -W 1 -q 2001:4860:4860::8888 &>/dev/null 2>&1; then
        _check_report $CHECK_PASS \
            "IPv6 connectivity" \
            "Working  (Google IPv6 DNS reachable)"
    else
        _check_report $CHECK_INFO \
            "IPv6 connectivity" \
            "Not available  (IPv4-only — usually fine)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — DNS RESOLUTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_dns() {
    _check_header "🔍 DNS Resolution"

    # ── /etc/resolv.conf ─────────────────────────────────────────────────────────
    local resolv="/etc/resolv.conf"
    if [[ -f "$resolv" ]]; then
        # Check if it's a symlink (systemd-resolved / NetworkManager)
        if [[ -L "$resolv" ]]; then
            local target
            target="$(readlink -f "$resolv" 2>/dev/null || echo '?')"
            _check_report $CHECK_INFO \
                "/etc/resolv.conf" \
                "Symlink → ${target}"
        else
            _check_report $CHECK_INFO \
                "/etc/resolv.conf" \
                "Regular file"
        fi

        # Extract nameservers
        local nameservers
        mapfile -t nameservers < <(
            grep '^nameserver' "$resolv" 2>/dev/null | awk '{print $2}'
        )

        if [[ ${#nameservers[@]} -eq 0 ]]; then
            _check_report $CHECK_FAIL \
                "Nameservers" \
                "None configured in /etc/resolv.conf" \
                "Check: cat /etc/resolv.conf"
        else
            for ns in "${nameservers[@]}"; do
                # Identify common DNS providers
                local ns_label
                case "$ns" in
                    8.8.8.8|8.8.4.4)        ns_label="Google DNS"         ;;
                    1.1.1.1|1.0.0.1)        ns_label="Cloudflare DNS"     ;;
                    9.9.9.9|149.112.112.112) ns_label="Quad9 DNS"          ;;
                    208.67.222.222|208.67.220.220) ns_label="OpenDNS"      ;;
                    127.0.0.1|127.0.0.53)   ns_label="Local/Loopback"     ;;
                    ::1)                     ns_label="IPv6 Loopback"      ;;
                    *)                       ns_label="Custom"             ;;
                esac
                _check_report $CHECK_INFO \
                    "Nameserver" \
                    "${ns}  (${ns_label})"
            done
        fi
    else
        _check_report $CHECK_FAIL \
            "/etc/resolv.conf" \
            "Missing!" \
            "This is critical — DNS will not work"
    fi

    # ── systemd-resolved ─────────────────────────────────────────────────────────
    if command -v resolvectl &>/dev/null; then
        local res_state
        res_state="$(systemctl is-active systemd-resolved 2>/dev/null || echo 'inactive')"
        if [[ "$res_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "systemd-resolved" \
                "Active  (local DNS caching)"

            # DNSSEC status
            local dnssec
            dnssec="$(resolvectl status 2>/dev/null | \
                      grep -i 'DNSSEC' | head -1 | awk '{print $NF}')"
            [[ -n "$dnssec" ]] && \
                _check_report $CHECK_INFO \
                    "DNSSEC" \
                    "$dnssec"

            # DNS-over-TLS
            local dot
            dot="$(resolvectl status 2>/dev/null | \
                   grep -i 'DNS over TLS' | head -1 | awk '{print $NF}')"
            [[ -n "$dot" ]] && \
                _check_report $CHECK_INFO \
                    "DNS-over-TLS" \
                    "$dot"
        else
            _check_report $CHECK_INFO \
                "systemd-resolved" \
                "Not running  (using static resolv.conf)"
        fi
    fi

    # ── DNS resolution tests ─────────────────────────────────────────────────────
    local -a dns_test_hosts=(
        "archlinux.org"
        "github.com"
        "aur.archlinux.org"
    )

    for test_host in "${dns_test_hosts[@]}"; do
        local start_ns end_ns elapsed_ms
        start_ns="$(date +%s%N 2>/dev/null || echo 0)"

        if _net_resolve "$test_host"; then
            end_ns="$(date +%s%N 2>/dev/null || echo 0)"
            elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))

            local resolve_status=$CHECK_PASS
            local resolve_note=""
            if (( elapsed_ms > 500 )); then
                resolve_status=$CHECK_WARN
                resolve_note="  (slow DNS — ${elapsed_ms}ms)"
            elif (( elapsed_ms > 200 )); then
                resolve_note="  (${elapsed_ms}ms)"
            else
                resolve_note="  (${elapsed_ms}ms — fast)"
            fi

            _check_report $resolve_status \
                "Resolve: ${test_host}" \
                "OK${resolve_note}"
        else
            _check_report $CHECK_FAIL \
                "Resolve: ${test_host}" \
                "FAILED" \
                "DNS broken — check nameservers in /etc/resolv.conf"
        fi
    done

    # ── mDNS / Avahi ────────────────────────────────────────────────────────────
    if pgrep -x avahi-daemon &>/dev/null; then
        _check_report $CHECK_INFO \
            "mDNS (Avahi)" \
            "Running  (.local hostname resolution active)"
    else
        _check_report $CHECK_INFO \
            "mDNS (Avahi)" \
            "Not running  (optional — for .local domains)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — WIFI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_wifi() {
    _check_header "📶 WiFi"

    # ── Find WiFi interfaces ──────────────────────────────────────────────────────
    local -a wifi_ifaces=()
    mapfile -t wifi_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: (wlan|wlp|wlx|wifi)/{print $2}' | \
        sed 's/@.*//'
    )

    if [[ ${#wifi_ifaces[@]} -eq 0 ]]; then
        _check_report $CHECK_INFO \
            "WiFi interfaces" \
            "None detected  (Ethernet-only or WiFi disabled)"
        return $CHECK_PASS
    fi

    _check_report $CHECK_INFO \
        "WiFi interfaces" \
        "${#wifi_ifaces[@]} interface(s): ${wifi_ifaces[*]}"

    # ── Per-interface detail ──────────────────────────────────────────────────────
    for wif in "${wifi_ifaces[@]}"; do

        # iw dev info
        if command -v iw &>/dev/null; then
            local iw_info
            iw_info="$(iw dev "$wif" info 2>/dev/null || echo '')"

            if [[ -n "$iw_info" ]]; then
                local ssid bssid freq channel txpower
                ssid="$(    printf '%s' "$iw_info" | grep 'ssid'    | awk '{print $2}')"
                bssid="$(   printf '%s' "$iw_info" | grep 'addr'    | awk '{print $2}')"
                freq="$(    printf '%s' "$iw_info" | grep 'channel' | grep -oP '\d{4}' | head -1)"
                channel="$( printf '%s' "$iw_info" | grep 'channel' | awk '{print $2}')"
                txpower="$( printf '%s' "$iw_info" | grep 'txpower' | awk '{print $2,$3}')"

                if [[ -n "$ssid" ]]; then
                    _check_report $CHECK_PASS \
                        "WiFi: ${wif}" \
                        "SSID: ${ssid}  •  CH: ${channel:-?}  •  ${freq:-?}MHz  •  TX: ${txpower:-?}"
                else
                    _check_report $CHECK_INFO \
                        "WiFi: ${wif}" \
                        "Not associated  (no SSID)"
                fi
            fi

            # Signal quality via iw station dump
            local signal_info
            signal_info="$(iw dev "$wif" station dump 2>/dev/null | \
                           grep 'signal:' | head -1 | awk '{print $2,$3}')"

            if [[ -n "$signal_info" ]]; then
                local sig_dbm
                sig_dbm="$(printf '%s' "$signal_info" | awk '{print $1}')"
                local sig_int="${sig_dbm%.*}"
                sig_int="${sig_int#-}"

                local sig_status=$CHECK_PASS
                local sig_desc
                if (( sig_int <= 50 )); then
                    sig_desc="Excellent 📶📶📶📶"
                elif (( sig_int <= 60 )); then
                    sig_desc="Good 📶📶📶"
                elif (( sig_int <= 70 )); then
                    sig_desc="Fair 📶📶"; sig_status=$CHECK_WARN
                else
                    sig_desc="Weak 📶"; sig_status=$CHECK_FAIL
                fi

                _check_report $sig_status \
                    "  └─ Signal strength" \
                    "${signal_info} dBm  •  ${sig_desc}"
            fi

            # TX bitrate
            local bitrate
            bitrate="$(iw dev "$wif" station dump 2>/dev/null | \
                       grep 'tx bitrate' | head -1 | awk '{print $3,$4}')"
            [[ -n "$bitrate" ]] && \
                _check_report $CHECK_INFO \
                    "  └─ TX bitrate" \
                    "${bitrate}"
        fi

        # rfkill state for this interface
        if command -v rfkill &>/dev/null; then
            local wif_rfk
            wif_rfk="$(rfkill list 2>/dev/null | \
                       awk -v iface="$wif" '$0 ~ iface {found=1} found && /blocked/{print; exit}')"
            if printf '%s' "$wif_rfk" | grep -q 'yes'; then
                _check_report $CHECK_WARN \
                    "  └─ rfkill" \
                    "Blocked" \
                    "Unblock: rfkill unblock wifi"
            fi
        fi
    done

    # ── NetworkManager status ────────────────────────────────────────────────────
    if command -v nmcli &>/dev/null; then
        local nm_wifi_state
        nm_wifi_state="$(nmcli radio wifi 2>/dev/null | head -1 || echo 'unknown')"
        _check_report $CHECK_INFO \
            "NetworkManager WiFi radio" \
            "$nm_wifi_state"

        # Active NM connection
        local nm_active
        nm_active="$(nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null | \
                     grep 'wifi:activated' | cut -d: -f1 | head -1 || echo '')"
        [[ -n "$nm_active" ]] && \
            _check_report $CHECK_PASS \
                "NM active WiFi connection" \
                "$nm_active"
    fi

    # ── iwd ─────────────────────────────────────────────────────────────────────
    if pgrep -x iwd &>/dev/null; then
        _check_report $CHECK_INFO \
            "iwd daemon" \
            "Running  (alternative WiFi backend)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — NETWORK MANAGER / WIRED
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_manager() {
    _check_header "⚙️  Network Manager"

    # ── Detect active network manager ────────────────────────────────────────────
    local nm_found=0

    # NetworkManager
    if pgrep -x NetworkManager &>/dev/null; then
        local nm_ver
        nm_ver="$(NetworkManager --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
        _check_report $CHECK_PASS \
            "NetworkManager" \
            "Running  v${nm_ver}"
        nm_found=1

        if command -v nmcli &>/dev/null; then
            local nm_general
            nm_general="$(nmcli general status 2>/dev/null | tail -1 || echo '')"
            local nm_connectivity
            nm_connectivity="$(nmcli networking connectivity 2>/dev/null | head -1 || echo '?')"
            _check_report $CHECK_INFO \
                "  NM connectivity" \
                "$nm_connectivity"
        fi
    fi

    # systemd-networkd
    if systemctl is-active systemd-networkd &>/dev/null 2>&1; then
        _check_report $CHECK_INFO \
            "systemd-networkd" \
            "Active"
        nm_found=1
    fi

    # connman
    if pgrep -x connmand &>/dev/null; then
        _check_report $CHECK_INFO \
            "ConnMan" \
            "Running"
        nm_found=1
    fi

    # dhcpcd
    if pgrep -x dhcpcd &>/dev/null; then
        _check_report $CHECK_INFO \
            "dhcpcd" \
            "Running"
    fi

    if [[ $nm_found -eq 0 ]]; then
        _check_report $CHECK_WARN \
            "Network manager" \
            "No network manager detected" \
            "Install: paru -S networkmanager && sudo systemctl enable --now NetworkManager"
    fi

    # ── Wired connections (ethernet detection) ────────────────────────────────────
    local -a eth_ifaces=()
    mapfile -t eth_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: (eth|enp|eno|ens|enx)/{print $2}' | \
        sed 's/@.*//'
    )

    for eth in "${eth_ifaces[@]}"; do
        [[ -z "$eth" ]] && continue
        local eth_state
        eth_state="$(ip link show "$eth" 2>/dev/null | \
                     grep -oP '(?<=state )\w+')"

        if [[ "$eth_state" == "UP" ]]; then
            local eth_carrier
            eth_carrier="$(cat "/sys/class/net/${eth}/carrier" 2>/dev/null || echo '0')"
            if [[ "$eth_carrier" == "1" ]]; then
                _check_report $CHECK_PASS \
                    "Ethernet: ${eth}" \
                    "Connected  •  carrier detected"
            else
                _check_report $CHECK_WARN \
                    "Ethernet: ${eth}" \
                    "UP but no carrier  (cable disconnected?)"
            fi
        else
            _check_report $CHECK_INFO \
                "Ethernet: ${eth}" \
                "DOWN"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — VPN & TUNNELS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_vpn() {
    _check_header "🔒 VPN & Tunnels"

    # ── WireGuard interfaces ─────────────────────────────────────────────────────
    local -a wg_ifaces=()
    mapfile -t wg_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: wg/{print $2}' | sed 's/@.*//'
    )

    if [[ ${#wg_ifaces[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "WireGuard interfaces" \
            "${#wg_ifaces[@]} active: ${wg_ifaces[*]}"

        if command -v wg &>/dev/null; then
            for wg_if in "${wg_ifaces[@]}"; do
                local wg_info
                wg_info="$(sudo wg show "$wg_if" 2>/dev/null || \
                           wg show "$wg_if" 2>/dev/null || echo '')"
                if [[ -n "$wg_info" ]]; then
                    local peer_count
                    peer_count="$(printf '%s' "$wg_info" | grep -c '^peer:' || echo 0)"
                    _check_report $CHECK_INFO \
                        "  WG: ${wg_if}" \
                        "${peer_count} peer(s)"
                fi
            done
        fi
    else
        _check_report $CHECK_INFO \
            "WireGuard" \
            "No active WireGuard interfaces"
    fi

    # ── OpenVPN ──────────────────────────────────────────────────────────────────
    local -a tun_ifaces=()
    mapfile -t tun_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: tun/{print $2}' | sed 's/@.*//'
    )

    if [[ ${#tun_ifaces[@]} -gt 0 ]]; then
        _check_report $CHECK_PASS \
            "TUN interfaces (OpenVPN?)" \
            "${tun_ifaces[*]}"
    fi

    # ── OpenVPN process ───────────────────────────────────────────────────────────
    if pgrep -x openvpn &>/dev/null; then
        _check_report $CHECK_PASS \
            "OpenVPN process" \
            "Running"
    fi

    # ── VPN tools installed ──────────────────────────────────────────────────────
    local -a vpn_tools=(
        "wg:WireGuard CLI (wg)"
        "wg-quick:WireGuard Quick"
        "openvpn:OpenVPN"
        "mullvad:Mullvad VPN"
        "expressvpn:ExpressVPN"
        "protonvpn-cli:ProtonVPN CLI"
        "nordvpn:NordVPN"
        "openconnect:OpenConnect (Cisco AnyConnect)"
    )

    for tool_entry in "${vpn_tools[@]}"; do
        IFS=':' read -r cmd label <<< "$tool_entry"
        if command -v "$cmd" &>/dev/null; then
            _check_report $CHECK_INFO \
                "VPN tool: ${label}" \
                "Installed"
        fi
    done

    # ── Tor ──────────────────────────────────────────────────────────────────────
    if pgrep -x tor &>/dev/null; then
        _check_report $CHECK_INFO \
            "Tor daemon" \
            "Running  (privacy routing active)"
    fi

    # ── Proxy environment variables ───────────────────────────────────────────────
    for proxy_var in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY SOCKS_PROXY; do
        local proxy_val="${!proxy_var:-}"
        if [[ -n "$proxy_val" ]]; then
            _check_report $CHECK_INFO \
                "Proxy: ${proxy_var}" \
                "$proxy_val"
        fi
    done

    if [[ -z "${http_proxy:-}${https_proxy:-}${HTTP_PROXY:-}${HTTPS_PROXY:-}" ]]; then
        _check_report $CHECK_INFO \
            "Proxy env vars" \
            "Not set  (direct connection)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — FIREWALL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_firewall() {
    _check_header "🛡️  Firewall"

    local fw_found=0

    # ── nftables ─────────────────────────────────────────────────────────────────
    if command -v nft &>/dev/null; then
        local nft_rules
        nft_rules="$(sudo nft list ruleset 2>/dev/null | wc -l || echo 0)"
        if systemctl is-active nftables &>/dev/null 2>&1; then
            _check_report $CHECK_PASS \
                "nftables" \
                "Active  •  ${nft_rules} rule lines"
            fw_found=1
        else
            _check_report $CHECK_INFO \
                "nftables" \
                "Installed but service not active"
        fi
    fi

    # ── ufw ──────────────────────────────────────────────────────────────────────
    if command -v ufw &>/dev/null; then
        local ufw_state
        ufw_state="$(sudo ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo 'unknown')"
        if [[ "$ufw_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "UFW" \
                "Active"
            fw_found=1
        else
            _check_report $CHECK_INFO \
                "UFW" \
                "Installed but inactive"
        fi
    fi

    # ── firewalld ────────────────────────────────────────────────────────────────
    if command -v firewall-cmd &>/dev/null; then
        local fw_state
        fw_state="$(firewall-cmd --state 2>/dev/null || echo 'not running')"
        if [[ "$fw_state" == "running" ]]; then
            local fw_zone
            fw_zone="$(firewall-cmd --get-default-zone 2>/dev/null || echo '?')"
            _check_report $CHECK_PASS \
                "firewalld" \
                "Running  •  default zone: ${fw_zone}"
            fw_found=1
        fi
    fi

    # ── iptables (legacy) ─────────────────────────────────────────────────────────
    if command -v iptables &>/dev/null; then
        local ipt_rules
        ipt_rules="$(sudo iptables -S 2>/dev/null | grep -cv '^-P' || echo 0)"
        if (( ipt_rules > 0 )); then
            _check_report $CHECK_INFO \
                "iptables" \
                "${ipt_rules} non-policy rule(s) active"
        fi
    fi

    if [[ $fw_found -eq 0 ]]; then
        _check_report $CHECK_INFO \
            "Firewall" \
            "No active firewall detected  (acceptable for desktop)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 08 — OPEN PORTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_net_ports() {
    _check_header "🔓 Listening Ports"

    if command -v ss &>/dev/null; then
        local listening_out
        listening_out="$(ss -tlnp 2>/dev/null | tail -n +2 || echo '')"

        local port_count
        port_count="$(printf '%s\n' "$listening_out" | grep -c '^LISTEN' || echo 0)"

        _check_report $CHECK_INFO \
            "Listening TCP ports" \
            "${port_count} port(s) open"

        # Flag known potentially risky ports
        while IFS= read -r port_line; do
            [[ -z "$port_line" ]] && continue
            [[ "$port_line" == *"LISTEN"* ]] || continue

            local local_addr process_info
            local_addr="$(  printf '%s' "$port_line" | awk '{print $4}')"
            process_info="$(printf '%s' "$port_line" | awk '{print $6}' | \
                            grep -oP 'users:\(\(".*?"\)' || echo '')"

            local port_num
            port_num="${local_addr##*:}"

            local risk_note=""
            case "$port_num" in
                22)   risk_note="⚠️  SSH — ensure key-based auth" ;;
                23)   risk_note="🚨 Telnet — insecure!" ;;
                3306) risk_note="MySQL/MariaDB — ensure not exposed" ;;
                5432) risk_note="PostgreSQL — ensure not exposed" ;;
                6379) risk_note="Redis — ensure auth enabled" ;;
                27017)risk_note="MongoDB — ensure auth enabled" ;;
                8080|8443) risk_note="Dev server port" ;;
                *)    risk_note="" ;;
            esac

            if [[ -n "$risk_note" ]]; then
                _check_report $CHECK_WARN \
                    "Port: ${port_num}" \
                    "${local_addr}  ${risk_note}"
            fi
        done <<< "$listening_out"

    else
        _check_report $CHECK_INFO \
            "Port scan" \
            "ss not available  (install iproute2)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_network() {
    local mode="${1:-full}"   # quick | full | wifi | dns | vpn

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;220;235m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🌐  ASH DOCTOR — NETWORK CHECK                          ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: ifaces • connectivity • DNS • WiFi • VPN • fw  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — NETWORK CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_net_interfaces
            _chk_net_connectivity
            _chk_net_dns
            ;;
        wifi)
            _chk_net_interfaces
            _chk_net_wifi
            ;;
        dns)
            _chk_net_dns
            ;;
        vpn)
            _chk_net_vpn
            ;;
        full|*)
            _chk_net_interfaces
            _chk_net_connectivity
            _chk_net_dns
            _chk_net_wifi
            _chk_net_manager
            _chk_net_vpn
            _chk_net_firewall
            _chk_net_ports
            ;;
    esac

    _ash_check_system_summary
}

ash_check_network_quick() {
    local issues=0
    _net_ping "1.1.1.1"    || (( issues++ )) || true
    _net_resolve "archlinux.org" || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Network: OK  (ping + DNS working)"
    else
        ash_log_warn "Network: ${issues} issue(s) — run 'ash doctor full --network'"
        return 1
    fi
}
