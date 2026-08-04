#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗   ██╗██████╗ ███╗   ██╗                                                    ║
# ║  ██║   ██║██╔══██╗████╗  ██║                                                    ║
# ║  ██║   ██║██████╔╝██╔██╗ ██║                                                    ║
# ║  ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║                                                    ║
# ║   ╚████╔╝ ██║     ██║ ╚████║                                                    ║
# ║    ╚═══╝  ╚═╝     ╚═╝  ╚═══╝                                                    ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net vpn                                                  ║
# ║  WireGuard • OpenVPN • status • connect • disconnect • kill switch              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_VPN_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_VPN_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _VPN_WG_DIR="/etc/wireguard"
declare -gr _VPN_OVP_DIR="/etc/openvpn"
declare -gr _VPN_NM_DIR="/etc/NetworkManager/system-connections"
declare -gr _VPN_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ash/vpn"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS  (inherit from net.sh or define inline)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_v()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_vr()     { _v '\033[0m';                        }
_vbold()  { _v '\033[1m';                        }
_vdim()   { _v '\033[38;2;108;112;134m';         }
_vgreen() { _v '\033[38;2;166;227;161m';         }
_vred()   { _v '\033[1;38;2;243;139;168m';       }
_vyellow(){ _v '\033[1;38;2;249;226;175m';       }
_vteal()  { _v '\033[38;2;148;226;213m';         }
_vsky()   { _v '\033[38;2;137;220;235m';         }
_vlav()   { _v '\033[38;2;180;190;254m';         }
_vmauve() { _v '\033[1;38;2;203;166;247m';       }
_vpeach() { _v '\033[38;2;250;179;135m';         }
_vpink()  { _v '\033[38;2;245;194;231m';         }

_vpn_section() {
    local icon="$1" title="$2"
    printf '\n%s%s  %s%s\n' "$(_vmauve)" "$icon" "$title" "$(_vr)"
    printf '%s  %s%s\n' "$(_vdim)" "$(printf '─%.0s' $(seq 1 54))" "$(_vr)"
}

_vpn_kv() {
    local key="$1" val="$2" vc="${3:-$(_vgreen)}"
    printf '  %s%-24s%s %s%s%s\n' "$(_vdim)" "${key}:" "$(_vr)" "$vc" "$val" "$(_vr)"
}

_vpn_ok()   { printf '  %s✓%s  %s\n' "$(_vgreen)" "$(_vr)" "$1"; }
_vpn_fail() { printf '  %s✗%s  %s\n' "$(_vred)"   "$(_vr)" "$1"; }
_vpn_info() { printf '  %sℹ%s  %s\n' "$(_vdim)"   "$(_vr)" "$1"; }
_vpn_warn() { printf '  %s⚠%s  %s\n' "$(_vyellow)" "$(_vr)" "$1"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WIREGUARD STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vpn_wg_status() {
    _vpn_section "🔒" "WireGuard"

    # List active WG interfaces from sysfs
    local -a wg_ifaces=()
    mapfile -t wg_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: wg/{print $2}' | sed 's/@.*//'
    )

    if [[ ${#wg_ifaces[@]} -eq 0 ]]; then
        _vpn_info "No active WireGuard tunnels"
    fi

    for wg_if in "${wg_ifaces[@]}"; do
        local endpoint pubkey rx tx last_handshake
        printf '\n  %s🔒 %s%s  %s(active)%s\n' \
            "$(_vgreen)$(_vbold)" "$wg_if" "$(_vr)" "$(_vdim)" "$(_vr)"

        if command -v wg &>/dev/null; then
            local wg_dump
            wg_dump="$(sudo -n wg show "$wg_if" 2>/dev/null || \
                       wg show "$wg_if" 2>/dev/null || echo '')"

            if [[ -n "$wg_dump" ]]; then
                endpoint="$(       printf '%s' "$wg_dump" | grep 'endpoint'       | awk '{print $2}'   | head -1)"
                pubkey="$(         printf '%s' "$wg_dump" | grep 'public key'     | awk '{print $3}'   | head -1)"
                rx="$(             printf '%s' "$wg_dump" | grep 'transfer'       | awk '{print $2,$3}'| head -1)"
                tx="$(             printf '%s' "$wg_dump" | grep 'transfer'       | awk '{print $5,$6}'| head -1)"
                last_handshake="$( printf '%s' "$wg_dump" | grep 'latest handshake' | cut -d: -f2- | sed 's/^ //' | head -1)"

                _vpn_kv "Endpoint"        "${endpoint:-?}"
                _vpn_kv "Public Key"      "${pubkey:0:24}…"
                _vpn_kv "RX"              "${rx:-?}"
                _vpn_kv "TX"              "${tx:-?}"
                _vpn_kv "Last Handshake"  "${last_handshake:-?}"
            fi
        fi

        # IPs on this interface
        local wg_ip
        wg_ip="$(ip addr show "$wg_if" 2>/dev/null | awk '/inet /{print $2}' | head -1)"
        _vpn_kv "Tunnel IP" "${wg_ip:-unknown}"
    done

    # List available configs
    if [[ -d "$_VPN_WG_DIR" ]]; then
        local -a confs=()
        mapfile -t confs < <(
            find "$_VPN_WG_DIR" -name '*.conf' 2>/dev/null | \
            xargs -I{} basename {} .conf | sort
        )
        if [[ ${#confs[@]} -gt 0 ]]; then
            printf '\n  %sAvailable configs:%s\n' "$(_vdim)" "$(_vr)"
            for cfg in "${confs[@]}"; do
                local is_active=0
                for wif in "${wg_ifaces[@]}"; do
                    [[ "$wif" == "$cfg" ]] && is_active=1 && break
                done
                local marker
                [[ $is_active -eq 1 ]] && \
                    marker="${_vgreen}●  (active)${_vr}" || \
                    marker="${_vdim}○  (inactive)${_vr}"
                printf '    %s%-20s%s  %s\n' "$(_vsky)" "$cfg" "$(_vr)" "$marker"
            done
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  OPENVPN STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vpn_ovpn_status() {
    _vpn_section "🌐" "OpenVPN"

    # Check for tun interfaces (OpenVPN)
    local -a tun_ifaces=()
    mapfile -t tun_ifaces < <(
        ip link show 2>/dev/null | \
        awk -F': ' '/^[0-9]+: tun/{print $2}' | sed 's/@.*//'
    )

    if [[ ${#tun_ifaces[@]} -eq 0 ]]; then
        _vpn_info "No active OpenVPN tunnels"
    else
        for tun in "${tun_ifaces[@]}"; do
            local tun_ip
            tun_ip="$(ip addr show "$tun" 2>/dev/null | awk '/inet /{print $2}' | head -1)"
            printf '\n  %s🌐 %s%s  %s(active)%s\n' \
                "$(_vgreen)$(_vbold)" "$tun" "$(_vr)" "$(_vdim)" "$(_vr)"
            _vpn_kv "Tunnel IP" "${tun_ip:-unknown}"
        done
    fi

    # systemd OpenVPN services
    if command -v systemctl &>/dev/null; then
        local ovpn_svcs
        ovpn_svcs="$(systemctl list-units 'openvpn*' --no-legend \
                     2>/dev/null | awk '{print $1,$3}' || echo '')"
        if [[ -n "$ovpn_svcs" ]]; then
            printf '\n  %sOpenVPN services:%s\n' "$(_vdim)" "$(_vr)"
            while IFS=' ' read -r svc state; do
                local sc
                [[ "$state" == "active" ]] && sc="$(_vgreen)" || sc="$(_vdim)"
                printf '    %s%-35s%s  %s%s%s\n' \
                    "$(_vsky)" "$svc" "$(_vr)" "$sc" "$state" "$(_vr)"
            done <<< "$ovpn_svcs"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VPN CONNECT / DISCONNECT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vpn_wg_up() {
    local conf="$1"
    local conf_file="${_VPN_WG_DIR}/${conf}.conf"

    [[ ! -f "$conf_file" ]] && {
        _vpn_fail "Config not found: ${conf_file}"
        return 1
    }

    printf '  %s→  Bringing up WireGuard: %s%s\n' "$(_vteal)" "$conf" "$(_vr)"

    if sudo wg-quick up "$conf" 2>/dev/null; then
        _vpn_ok "WireGuard tunnel up: $conf"

        # Store state
        mkdir -p "$_VPN_STATE" 2>/dev/null
        printf '%s %s\n' "wireguard" "$conf" > "${_VPN_STATE}/active"

        command -v notify-send &>/dev/null && \
            notify-send "🔒 VPN Connected" "WireGuard: $conf" \
                --icon=network-vpn 2>/dev/null || true
    else
        _vpn_fail "Failed to bring up WireGuard: $conf"
        return 1
    fi
}

_vpn_wg_down() {
    local conf="$1"
    printf '  %s→  Taking down WireGuard: %s%s\n' "$(_vteal)" "$conf" "$(_vr)"

    if sudo wg-quick down "$conf" 2>/dev/null; then
        _vpn_ok "WireGuard tunnel down: $conf"
        rm -f "${_VPN_STATE}/active" 2>/dev/null || true
    else
        _vpn_fail "Failed to take down: $conf"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  KILL SWITCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vpn_killswitch_enable() {
    _vpn_section "🔴" "Kill Switch"
    _vpn_warn "This will block ALL traffic if VPN drops!"
    printf '  %sContinue? [y/N] %s' "$(_vyellow)" "$(_vr)"

    local ans
    read -r ans
    [[ "${ans,,}" != "y" ]] && _vpn_info "Cancelled" && return 0

    printf '\n  %s→  Enabling kill switch via nftables...%s\n' \
        "$(_vteal)" "$(_vr)"

    # Store current WG interface
    local wg_if
    wg_if="$(ip link show 2>/dev/null | \
              awk -F': ' '/^[0-9]+: wg/{print $2}' | sed 's/@.*//' | head -1)"

    if [[ -z "$wg_if" ]]; then
        _vpn_fail "No WireGuard interface found — start VPN first"
        return 1
    fi

    # nftables kill switch rules
    sudo nft -f - << NFTEOF 2>/dev/null
table inet ash_killswitch {
    chain output {
        type filter hook output priority 0;
        oifname "lo"     accept
        oifname "${wg_if}" accept
        # Allow WireGuard handshake
        ip protocol udp udp dport 51820 accept
        ip6 nexthdr udp udp dport 51820 accept
        # Drop everything else
        drop
    }
}
NFTEOF

    if [[ $? -eq 0 ]]; then
        _vpn_ok "Kill switch ACTIVE — all non-VPN traffic blocked"
        mkdir -p "$_VPN_STATE"
        printf '%s\n' "$wg_if" > "${_VPN_STATE}/killswitch"
    else
        _vpn_fail "Failed to install kill switch rules (try: sudo)"
        return 1
    fi
}

_vpn_killswitch_disable() {
    printf '  %s→  Removing kill switch rules...%s\n' "$(_vteal)" "$(_vr)"
    sudo nft delete table inet ash_killswitch 2>/dev/null && \
        _vpn_ok "Kill switch disabled" || \
        _vpn_info "Kill switch was not active"
    rm -f "${_VPN_STATE}/killswitch" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LEAK TEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_vpn_leak_test() {
    _vpn_section "🔍" "VPN Leak Test"

    # Public IP
    local pub_ip
    pub_ip="$(curl -fsSL --max-time 5 https://api4.my-ip.io/ip 2>/dev/null | tr -d '[:space:]')"
    _vpn_kv "Public IP" "${pub_ip:-?}"

    # DNS leak test — query multiple resolvers
    printf '\n  %sDNS Resolver Test:%s\n' "$(_vdim)" "$(_vr)"
    local -a test_hosts=( "1.1.1.1" "8.8.8.8" "9.9.9.9" )
    for resolver in "${test_hosts[@]}"; do
        local dns_ip
        dns_ip="$(dig +short +time=3 +tries=1 \
                  myip.opendns.com @"$resolver" 2>/dev/null | head -1 || echo '?')"
        local sc
        [[ "$dns_ip" == "$pub_ip" ]] && sc="$(_vgreen)" || sc="$(_vyellow)"
        printf '    %s%-16s%s → %s%s%s\n' \
            "$(_vdim)" "$resolver" "$(_vr)" "$sc" "$dns_ip" "$(_vr)"
    done

    # IPv6 leak
    local ipv6_pub
    ipv6_pub="$(curl -6 -fsSL --max-time 5 \
                https://api6.my-ip.io/ip 2>/dev/null | tr -d '[:space:]' || echo 'none')"
    _vpn_kv "Public IPv6" "${ipv6_pub:-none}"
    [[ "$ipv6_pub" != "none" ]] && [[ -n "$ipv6_pub" ]] && \
        _vpn_warn "IPv6 leak detected! Disable IPv6 or use VPN with IPv6 support."

    # WebRTC (check STUN)
    _vpn_info "WebRTC leak: test manually at browserleaks.com/webrtc"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_vpn() {
    local action="status"  target=""

    for arg in "${@:-}"; do
        case "$arg" in
            status|up|down|kill|unkill|leak|list) action="$arg" ;;
            --up=*|--connect=*)   action="up";   target="${arg#*=}" ;;
            --down=*|--disconnect=*) action="down"; target="${arg#*=}" ;;
            *)  [[ -z "$target" ]] && target="$arg" ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔒  ASH  ─  VPN Manager                                  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    mkdir -p "$_VPN_STATE" 2>/dev/null || true

    case "$action" in
        status)
            _vpn_wg_status
            _vpn_ovpn_status
            ;;
        up)
            [[ -z "$target" ]] && {
                printf '  %sUsage: ash net vpn up <profile>%s\n' \
                    "$(_vyellow)" "$(_vr)"
                return 1
            }
            _vpn_wg_up "$target"
            ;;
        down)
            [[ -z "$target" ]] && {
                # Find active and bring down
                target="$(ip link show 2>/dev/null | \
                          awk -F': ' '/^[0-9]+: wg/{print $2}' | \
                          sed 's/@.*//' | head -1)"
                [[ -z "$target" ]] && {
                    _vpn_info "No active WireGuard tunnel found"
                    return 0
                }
            }
            _vpn_wg_down "$target"
            ;;
        kill)    _vpn_killswitch_enable  ;;
        unkill)  _vpn_killswitch_disable ;;
        leak)    _vpn_leak_test          ;;
        list)
            _vpn_section "📋" "Available VPN Profiles"
            printf '\n  %sWireGuard:%s\n' "$(_vbold)" "$(_vr)"
            find "$_VPN_WG_DIR" -name '*.conf' 2>/dev/null | \
                sort | while IFS= read -r f; do
                    printf '    %s%s%s\n' \
                        "$(_vsky)" "$(basename "$f" .conf)" "$(_vr)"
                done || _vpn_info "None found (requires /etc/wireguard/*.conf)"
            ;;
    esac

    printf '\n'
}
