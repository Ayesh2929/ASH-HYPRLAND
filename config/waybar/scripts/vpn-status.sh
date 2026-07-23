#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: VPN Status                        ║
# ║                                                                              ║
# ║  Detects: WireGuard (wg0/wg1), OpenVPN (tun0), NetworkManager VPN         ║
# ║  Shows IP, protocol and connection name.                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

check_wireguard() {
    local iface
    for iface in wg0 wg1 wg2; do
        if ip link show "$iface" &>/dev/null 2>&1; then
            local IP
            IP=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)
            echo "WireGuard|$iface|${IP:-unknown}"
            return 0
        fi
    done
    return 1
}

check_openvpn() {
    for iface in tun0 tun1 tap0; do
        if ip link show "$iface" &>/dev/null 2>&1; then
            local IP
            IP=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)
            echo "OpenVPN|$iface|${IP:-unknown}"
            return 0
        fi
    done
    return 1
}

check_nm_vpn() {
    if ! command -v nmcli &>/dev/null; then return 1; fi
    local VPN_NAME
    VPN_NAME=$(nmcli -g NAME,TYPE connection show --active 2>/dev/null | \
        grep ':vpn\|:wireguard' | cut -d: -f1 | head -1)
    if [[ -n "$VPN_NAME" ]]; then
        echo "NM-VPN|$VPN_NAME|connected"
        return 0
    fi
    return 1
}

# ── Detection order ───────────────────────────────────────────────────────────
VPN_INFO=""
if   VPN_INFO=$(check_wireguard 2>/dev/null); then :
elif VPN_INFO=$(check_openvpn   2>/dev/null); then :
elif VPN_INFO=$(check_nm_vpn    2>/dev/null); then :
fi

if [[ -n "$VPN_INFO" ]]; then
    IFS='|' read -r PROTOCOL IFACE IP <<< "$VPN_INFO"

    case "$PROTOCOL" in
        WireGuard) ICON="󰌿" ;;
        OpenVPN)   ICON="󰦝" ;;
        *)         ICON="󰌾" ;;
    esac

    TOOLTIP="${ICON} VPN: CONNECTED\n\n"
    TOOLTIP+="Protocol:  ${PROTOCOL}\n"
    TOOLTIP+="Interface: ${IFACE}\n"
    TOOLTIP+="IP:        ${IP}\n"
    TOOLTIP+="\nLeft: VPN manager  Right: disconnect"

    TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')

    printf '{"text":"%s %s","tooltip":"%s","class":"connected"}\n' \
        "$ICON" "$PROTOCOL" "$TOOLTIP"
else
    printf '{"text":"","tooltip":"VPN: Disconnected\n\nLeft: connect VPN","class":"disconnected"}\n'
fi