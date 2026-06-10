#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR VPN STATUS MODULE                     ║
# ║           Multi-VPN detection: WireGuard, OpenVPN, NordVPN, ProtonVPN     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/waybar.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 VPN DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_wireguard() {
    # Check for active WireGuard interfaces
    if command -v wg &>/dev/null; then
        local interfaces
        interfaces=$(wg show interfaces 2>/dev/null)
        if [[ -n "${interfaces}" ]]; then
            echo "wireguard:${interfaces}"
            return 0
        fi
    fi

    # Check via ip command
    if ip link show type wireguard &>/dev/null 2>&1; then
        local ifaces
        ifaces=$(ip link show type wireguard 2>/dev/null | grep "^[0-9]" | awk -F: '{print $2}' | tr -d ' ' | tr '\n' ',')
        if [[ -n "${ifaces}" ]]; then
            echo "wireguard:${ifaces}"
            return 0
        fi
    fi

    return 1
}

detect_openvpn() {
    if pgrep -x openvpn &>/dev/null; then
        local tun_iface
        tun_iface=$(ip link show | grep "tun\|tap" | awk -F: '{print $2}' | tr -d ' ' | head -1)
        echo "openvpn:${tun_iface:-tun0}"
        return 0
    fi
    return 1
}

detect_nordvpn() {
    if command -v nordvpn &>/dev/null; then
        local status
        status=$(nordvpn status 2>/dev/null | grep "Status:" | awk '{print $2}')
        if [[ "${status,,}" == "connected" ]]; then
            local server
            server=$(nordvpn status 2>/dev/null | grep "Server:" | awk '{print $2}')
            echo "nordvpn:${server:-NordVPN}"
            return 0
        fi
    fi
    return 1
}

detect_protonvpn() {
    if command -v protonvpn &>/dev/null || command -v protonvpn-cli &>/dev/null; then
        local status
        status=$(protonvpn-cli status 2>/dev/null | grep -i "status" | awk '{print $NF}')
        if [[ "${status,,}" == "connected" ]]; then
            echo "protonvpn:ProtonVPN"
            return 0
        fi
    fi
    return 1
}

detect_generic_vpn() {
    # Check for common VPN tunnel interfaces
    local vpn_ifaces
    vpn_ifaces=$(ip link show 2>/dev/null \
        | grep -E "tun[0-9]|tap[0-9]|vpn|wg[0-9]|ppp[0-9]" \
        | awk -F: '{print $2}' | tr -d ' ' | head -3)

    if [[ -n "${vpn_ifaces}" ]]; then
        echo "generic:${vpn_ifaces}"
        return 0
    fi
    return 1
}

get_public_ip() {
    # Cached public IP (update every 5 minutes)
    local ip_cache="${CACHE_DIR}/public-ip-cache"
    local cache_age=0

    if [[ -f "${ip_cache}" ]]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "${ip_cache}" 2>/dev/null || echo 0) ))
    fi

    if (( cache_age < 300 )) && [[ -f "${ip_cache}" ]]; then
        cat "${ip_cache}"
    else
        local ip
        ip=$(curl -s --max-time 3 "https://ipinfo.io/ip" 2>/dev/null \
            || curl -s --max-time 3 "https://api.ipify.org" 2>/dev/null \
            || echo "")
        if [[ -n "${ip}" ]]; then
            echo "${ip}" > "${ip_cache}"
            echo "${ip}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FORMAT OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        status | "")
            local vpn_type="" vpn_name="" connected=false

            # Try each VPN detection method
            local result=""
            if result=$(detect_wireguard 2>/dev/null); then
                vpn_type="wireguard"
                vpn_name="${result#*:}"
                connected=true
            elif result=$(detect_nordvpn 2>/dev/null); then
                vpn_type="nordvpn"
                vpn_name="${result#*:}"
                connected=true
            elif result=$(detect_protonvpn 2>/dev/null); then
                vpn_type="protonvpn"
                vpn_name="${result#*:}"
                connected=true
            elif result=$(detect_openvpn 2>/dev/null); then
                vpn_type="openvpn"
                vpn_name="${result#*:}"
                connected=true
            elif result=$(detect_generic_vpn 2>/dev/null); then
                vpn_type="vpn"
                vpn_name="${result#*:}"
                connected=true
            fi

            if [[ "${connected}" == "true" ]]; then
                local pub_ip
                pub_ip=$(get_public_ip)
                local short_name
                short_name=$(echo "${vpn_name}" | cut -c1-15)

                local tooltip
                tooltip="🔒 VPN Connected\n"
                tooltip+="─────────────────────\n"
                tooltip+="Type:   ${vpn_type^}\n"
                tooltip+="Server: ${vpn_name}\n"
                [[ -n "${pub_ip}" ]] && tooltip+="IP:     ${pub_ip}\n"
                tooltip+="─────────────────────\n"
                tooltip+="Click to disconnect"

                printf '{"text": "󰦝 %s", "tooltip": "%s", "class": "connected", "percentage": 100}\n' \
                    "${short_name}" "${tooltip}"
            else
                local pub_ip
                pub_ip=$(get_public_ip)

                local tooltip="🔓 VPN Disconnected"
                [[ -n "${pub_ip}" ]] && tooltip+="\nPublic IP: ${pub_ip}"

                printf '{"text": "󰦞", "tooltip": "%s", "class": "disconnected", "percentage": 0}\n' \
                    "${tooltip}"
            fi
            ;;

        connected)
            detect_wireguard 2>/dev/null \
                || detect_nordvpn 2>/dev/null \
                || detect_openvpn 2>/dev/null \
                || detect_generic_vpn 2>/dev/null \
                && echo "true" || echo "false"
            ;;

        ip)
            get_public_ip
            ;;

        *)
            echo "Usage: vpn.sh [status|connected|ip]"
            exit 1
            ;;
    esac
}

main "$@"