#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ███████╗██╗██████╗ ███████╗██╗    ██╗ █████╗ ██╗     ██╗                       ║
# ║  ██╔════╝██║██╔══██╗██╔════╝██║    ██║██╔══██╗██║     ██║                       ║
# ║  █████╗  ██║██████╔╝█████╗  ██║ █╗ ██║███████║██║     ██║                       ║
# ║  ██╔══╝  ██║██╔══██╗██╔══╝  ██║███╗██║██╔══██║██║     ██║                       ║
# ║  ██║     ██║██║  ██║███████╗╚███╔███╔╝██║  ██║███████╗███████╗                  ║
# ║  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net firewall                                             ║
# ║  nftables • ufw • iptables • rule browser • quick allow/deny                   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_FIREWALL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_FIREWALL_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fw()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_fwr()     { _fw '\033[0m';                        }
_fwbold()  { _fw '\033[1m';                        }
_fwdim()   { _fw '\033[38;2;108;112;134m';         }
_fwgreen() { _fw '\033[38;2;166;227;161m';         }
_fwred()   { _fw '\033[1;38;2;243;139;168m';       }
_fwyellow(){ _fw '\033[1;38;2;249;226;175m';       }
_fwteal()  { _fw '\033[38;2;148;226;213m';         }
_fwblue()  { _fw '\033[38;2;137;180;250m';         }
_fwsky()   { _fw '\033[38;2;137;220;235m';         }
_fwmauve() { _fw '\033[1;38;2;203;166;247m';       }
_fwpeach() { _fw '\033[38;2;250;179;135m';         }

_fw_section() {
    printf '\n%s%s  %s%s\n' "$(_fwmauve)" "$1" "$2" "$(_fwr)"
    printf '%s  %s%s\n' "$(_fwdim)" "$(printf '─%.0s' $(seq 1 54))" "$(_fwr)"
}

_fw_kv() {
    printf '  %s%-22s%s %s%s%s\n' \
        "$(_fwdim)" "${1}:" "$(_fwr)" "${3:-$(_fwgreen)}" "$2" "$(_fwr)"
}

_fw_ok()   { printf '  %s●%s  %s\n' "$(_fwgreen)"  "$(_fwr)" "$1"; }
_fw_fail() { printf '  %s●%s  %s\n' "$(_fwred)"    "$(_fwr)" "$1"; }
_fw_info() { printf '  %sℹ%s  %s\n' "$(_fwdim)"    "$(_fwr)" "$1"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DETECT ACTIVE FIREWALL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fw_detect() {
    local active=""

    # nftables
    if systemctl is-active nftables &>/dev/null 2>&1 || \
       sudo -n nft list ruleset &>/dev/null 2>&1; then
        active="${active:+$active, }nftables"
    fi

    # ufw
    if command -v ufw &>/dev/null; then
        local ufw_status
        ufw_status="$(sudo -n ufw status 2>/dev/null | head -1 | awk '{print $2}')"
        [[ "$ufw_status" == "active" ]] && active="${active:+$active, }ufw"
    fi

    # firewalld
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --state &>/dev/null 2>&1 && \
            active="${active:+$active, }firewalld"
    fi

    # iptables (legacy)
    if command -v iptables &>/dev/null; then
        local ipt_rules
        ipt_rules="$(sudo -n iptables -S 2>/dev/null | \
                     grep -vc '^-P' 2>/dev/null || echo 0)"
        (( ipt_rules > 0 )) && \
            active="${active:+$active, }iptables(${ipt_rules} rules)"
    fi

    printf '%s' "${active:-none}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  NFTABLES RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fw_nftables_display() {
    _fw_section "🔧" "nftables Ruleset"

    local nft_out
    nft_out="$(sudo -n nft list ruleset 2>/dev/null || \
               nft list ruleset 2>/dev/null || echo '')"

    if [[ -z "$nft_out" ]]; then
        _fw_info "No nftables rules loaded (or requires root)"
        return 0
    fi

    local rule_count
    rule_count="$(printf '%s' "$nft_out" | grep -c '^\s*\w' || echo 0)"
    _fw_kv "Rule lines" "$rule_count"

    # Render with syntax highlighting
    printf '\n'
    while IFS= read -r line; do
        if [[ "$line" =~ ^table ]]; then
            printf '  %s%s%s\n' "$(_fwmauve)" "$line" "$(_fwr)"
        elif [[ "$line" =~ ^[[:space:]]*chain ]]; then
            printf '  %s%s%s\n' "$(_fwteal)" "$line" "$(_fwr)"
        elif [[ "$line" =~ accept ]]; then
            printf '  %s%s%s\n' "$(_fwgreen)" "$line" "$(_fwr)"
        elif [[ "$line" =~ drop|reject ]]; then
            printf '  %s%s%s\n' "$(_fwred)" "$line" "$(_fwr)"
        elif [[ "$line" =~ ^[[:space:]]*} ]]; then
            printf '  %s%s%s\n' "$(_fwdim)" "$line" "$(_fwr)"
        else
            printf '  %s%s%s\n' "$(_fwblue)" "$line" "$(_fwr)"
        fi
    done <<< "$nft_out"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  UFW STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fw_ufw_display() {
    command -v ufw &>/dev/null || return 0
    _fw_section "🛡" "UFW Status"

    local ufw_out
    ufw_out="$(sudo -n ufw status verbose 2>/dev/null || \
               sudo ufw status verbose 2>/dev/null || echo '')"

    [[ -z "$ufw_out" ]] && { _fw_info "Cannot read UFW status"; return 0; }

    printf '\n'
    while IFS= read -r line; do
        if [[ "$line" =~ Status:.*active ]]; then
            printf '  %s%s%s\n' "$(_fwgreen)$(_fwbold)" "$line" "$(_fwr)"
        elif [[ "$line" =~ Status:.*inactive ]]; then
            printf '  %s%s%s\n' "$(_fwdim)" "$line" "$(_fwr)"
        elif [[ "$line" =~ ALLOW ]]; then
            printf '  %s%s%s\n' "$(_fwgreen)" "$line" "$(_fwr)"
        elif [[ "$line" =~ DENY|REJECT ]]; then
            printf '  %s%s%s\n' "$(_fwred)" "$line" "$(_fwr)"
        elif [[ "$line" =~ ^-- ]]; then
            printf '  %s%s%s\n' "$(_fwdim)" "$line" "$(_fwr)"
        else
            printf '  %s\n' "$line"
        fi
    done <<< "$ufw_out"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  QUICK ALLOW / DENY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fw_quick_allow() {
    local port_proto="$1"  # e.g. 22 or 22/tcp or 80,443

    _fw_section "✅" "Allow Port"

    # Try UFW first
    if command -v ufw &>/dev/null; then
        local ufw_status
        ufw_status="$(sudo -n ufw status 2>/dev/null | head -1 | awk '{print $2}')"
        if [[ "$ufw_status" == "active" ]]; then
            if sudo ufw allow "$port_proto" 2>/dev/null; then
                _fw_ok "ufw allow $port_proto"
                return 0
            fi
        fi
    fi

    # nftables
    if command -v nft &>/dev/null; then
        local port="${port_proto%%/*}"
        local proto="${port_proto##*/}"
        [[ "$proto" == "$port" ]] && proto="tcp"

        sudo nft add rule inet filter input \
            "$proto" dport "$port" accept 2>/dev/null && \
            _fw_ok "nft: allow ${proto} port ${port}" || \
            _fw_fail "Failed to add rule"
    fi
}

_fw_quick_deny() {
    local port_proto="$1"

    _fw_section "🚫" "Deny Port"

    if command -v ufw &>/dev/null; then
        sudo ufw deny "$port_proto" 2>/dev/null && \
            _fw_ok "ufw deny $port_proto" || \
            _fw_fail "Failed"
    else
        local port="${port_proto%%/*}"
        local proto="${port_proto##*/}"
        [[ "$proto" == "$port" ]] && proto="tcp"
        sudo nft add rule inet filter input \
            "$proto" dport "$port" drop 2>/dev/null && \
            _fw_ok "nft: drop ${proto} port ${port}" || \
            _fw_fail "Failed"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_firewall() {
    local action="status"  target=""

    for arg in "${@:-}"; do
        case "$arg" in
            status|show)              action="status"  ;;
            allow|permit)             action="allow"   ;;
            deny|block|reject|drop)   action="deny"    ;;
            nft|nftables)             action="nft"     ;;
            ufw)                      action="ufw"     ;;
            enable)                   action="enable"  ;;
            disable)                  action="disable" ;;
            *)                        target="$arg"    ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🛡️   ASH  ─  Firewall Manager                            ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        status)
            _fw_section "📊" "Firewall Overview"
            local active
            active="$(_fw_detect)"

            if [[ "$active" == "none" ]]; then
                _fw_fail "No active firewall detected"
            else
                _fw_ok "Active: $active"
            fi

            _fw_ufw_display
            _fw_nftables_display
            ;;
        allow)
            [[ -z "$target" ]] && {
                printf '  Usage: ash net firewall allow <port>[/proto]\n'
                return 1
            }
            _fw_quick_allow "$target"
            ;;
        deny)
            [[ -z "$target" ]] && {
                printf '  Usage: ash net firewall deny <port>[/proto]\n'
                return 1
            }
            _fw_quick_deny "$target"
            ;;
        nft)    _fw_nftables_display ;;
        ufw)    _fw_ufw_display      ;;
        enable)
            command -v ufw &>/dev/null && \
                sudo ufw enable && _fw_ok "UFW enabled"
            ;;
        disable)
            command -v ufw &>/dev/null && \
                sudo ufw disable && _fw_ok "UFW disabled"
            ;;
    esac

    printf '\n'
}
