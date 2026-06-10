#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR VPN STATUS MODULE                     ║
# ║           Multi-VPN detection: WireGuard, OpenVPN, tailscale              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/vpn.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 VPN DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_wireguard() {
    # Check for WireGuard interfaces
    local wg_interfaces=""

    if command -v wg &>/dev/null; then
        wg_interfaces=$(wg show interfaces 2>/dev/null || echo "")
    fi

    if [[ -z "${wg_interfaces}" ]]; then
        # Fallback: check for wg* network interfaces
        wg_interfaces=$(ip link show 2>/dev/null \
            | grep -oP "wg\d+" \
            | head -3 || echo "")
    fi

    if [[ -n "${wg_interfaces}" ]]; then
        local iface
        iface=$(echo "${wg_interfaces}" | head -1)
        local endpoint=""
        if command -v wg &>/dev/null; then
            endpoint=$(wg show "${iface}" endpoints 2>/dev/null \
                | awk '{print $2}' | cut -d: -f1 | head -1 || echo "")
        fi
        echo "wireguard|${iface}|${endpoint}"
        return 0
    fi

    return 1
}

detect_openvpn() {
    # Check for OpenVPN process and tun interface
    if pgrep -x openvpn &>/dev/null; then
        local tun_iface
        tun_iface=$(ip link show 2>/dev/null \
            | grep -oP "tun\d+" | head -1 || echo "tun0")
        local vpn_ip=""
        if [[ -n "${tun_iface}" ]]; then
            vpn_ip=$(ip addr show "${tun_iface}" 2>/dev/null \
                | grep -oP "(?<=inet )[\d.]+" | head -1 || echo "")
        fi
        echo "openvpn|${tun_iface:-tun0}|${vpn_ip}"
        return 0
    fi
    return 1
}

detect_tailscale() {
    if command -v tailscale &>/dev/null; then
        local ts_status
        ts_status=$(tailscale status --json 2>/dev/null \
            | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if d.get('BackendState') == 'Running':
        ip = d.get('TailscaleIPs', [''])[0]
        print(f'running|{ip}')
    else:
        print('off|')
except:
    print('off|')
" 2>/dev/null || echo "off|")

        if [[ "${ts_status}" == "running|"* ]]; then
            local ts_ip="${ts_status##*|}"
            echo "tailscale|tailscale0|${ts_ip}"
            return 0
        fi
    fi
    return 1
}

detect_nordvpn() {
    if command -v nordvpn &>/dev/null; then
        local nord_status
        nord_status=$(nordvpn status 2>/dev/null | grep -i "Status:" | awk '{print $2}' || echo "")
        if [[ "${nord_status,,}" == "connected" ]]; then
            local server
            server=$(nordvpn status 2>/dev/null \
                | grep -i "Server:" | awk '{print $2}' || echo "NordVPN")
            echo "nordvpn|nord|${server}"
            return 0
        fi
    fi
    return 1
}

detect_any_vpn() {
    detect_wireguard 2>/dev/null && return 0
    detect_openvpn   2>/dev/null && return 0
    detect_tailscale 2>/dev/null && return 0
    detect_nordvpn   2>/dev/null && return 0

    # Generic: check for VPN-like interfaces
    local vpn_iface
    vpn_iface=$(ip link show 2>/dev/null \
        | grep -oP "(tun|tap|vpn|wg|ts)\d*" \
        | head -1 || echo "")

    if [[ -n "${vpn_iface}" ]]; then
        echo "unknown|${vpn_iface}|"
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

format_output() {
    local vpn_info=""

    if ! vpn_info=$(detect_any_vpn 2>/dev/null); then
        # No VPN detected
        printf '{"text": "", "tooltip": "No VPN active", "class": "disconnected"}\n'
        return 0
    fi

    local vpn_type vpn_iface vpn_server
    IFS='|' read -r vpn_type vpn_iface vpn_server <<< "${vpn_info}"

    # Get VPN IP
    local vpn_ip=""
    if [[ -n "${vpn_iface}" ]]; then
        vpn_ip=$(ip addr show "${vpn_iface}" 2>/dev/null \
            | grep -oP "(?<=inet )[\d.]+" | head -1 || echo "")
    fi

    # Get public IP
    local pub_ip=""
    pub_ip=$(curl -s --max-time 3 "https://ipinfo.io/ip" 2>/dev/null || echo "")

    # Type-specific icons
    local icon
    case "${vpn_type}" in
        wireguard)  icon="󰦝" ;;
        openvpn)    icon="󰌿" ;;
        tailscale)  icon="󰖢" ;;
        nordvpn)    icon="󰦝" ;;
        *)          icon="󰦝" ;;
    esac

    # Build tooltip
    local tooltip
    tooltip="🔒 VPN Connected\n"
    tooltip+="────────────────────\n"
    tooltip+="Type:      ${vpn_type^}\n"
    tooltip+="Interface: ${vpn_iface}\n"
    [[ -n "${vpn_ip}" ]]     && tooltip+="VPN IP:    ${vpn_ip}\n"
    [[ -n "${vpn_server}" ]] && tooltip+="Server:    ${vpn_server}\n"
    [[ -n "${pub_ip}" ]]     && tooltip+="Public IP: ${pub_ip}\n"

    printf '{"text": "%s %s", "tooltip": "%s", "class": "connected"}\n' \
        "${icon}" "${vpn_type^}" "${tooltip}"
}

main() {
    local action="${1:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        "" | status) format_output ;;
        type)
            detect_any_vpn 2>/dev/null | cut -d'|' -f1 || echo "none"
            ;;
        active)
            detect_any_vpn &>/dev/null && echo "true" || echo "false"
            ;;
        *)
            echo "Usage: vpn.sh [status|type|active]"
            exit 1
            ;;
    esac
}

main "$@"