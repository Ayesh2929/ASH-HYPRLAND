#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗ ███╗   ██╗███████╗                                                     ║
# ║  ██╔══██╗████╗  ██║██╔════╝                                                     ║
# ║  ██║  ██║██╔██╗ ██║███████╗                                                     ║
# ║  ██║  ██║██║╚██╗██║╚════██║                                                     ║
# ║  ██████╔╝██║ ╚████║███████║                                                     ║
# ║  ╚═════╝ ╚═╝  ╚═══╝╚══════╝                                                     ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net dns                                                  ║
# ║  DNS resolver • latency benchmark • DNSSEC • DoT/DoH • flush • rebind test     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_DNS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_DNS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_d()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_dr()     { _d '\033[0m';                        }
_dbold()  { _d '\033[1m';                        }
_ddim()   { _d '\033[38;2;108;112;134m';         }
_dgreen() { _d '\033[38;2;166;227;161m';         }
_dred()   { _d '\033[1;38;2;243;139;168m';       }
_dyellow(){ _d '\033[1;38;2;249;226;175m';       }
_dteal()  { _d '\033[38;2;148;226;213m';         }
_dblue()  { _d '\033[38;2;137;180;250m';         }
_dsky()   { _d '\033[38;2;137;220;235m';         }
_dmauve() { _d '\033[1;38;2;203;166;247m';       }
_dpeach() { _d '\033[38;2;250;179;135m';         }

_dns_section() {
    printf '\n%s%s  %s%s\n' "$(_dmauve)" "$1" "$2" "$(_dr)"
    printf '%s  %s%s\n' "$(_ddim)" "$(printf '─%.0s' $(seq 1 54))" "$(_dr)"
}

_dns_kv() {
    printf '  %s%-24s%s %s%s%s\n' \
        "$(_ddim)" "${1}:" "$(_dr)" "${3:-$(_dgreen)}" "$2" "$(_dr)"
}

_dns_latency_color() {
    local ms="$1"
    if   (( ms < 20  )); then printf '%s' "$(_dgreen)"
    elif (( ms < 60  )); then printf '%s' "$(_dyellow)"
    elif (( ms < 150 )); then printf '%s' "$(_dpeach)"
    else                      printf '%s' "$(_dred)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  KNOWN PUBLIC RESOLVERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _DNS_RESOLVERS=(
    ["Cloudflare"]="1.1.1.1"
    ["Cloudflare Alt"]="1.0.0.1"
    ["Google"]="8.8.8.8"
    ["Google Alt"]="8.8.4.4"
    ["Quad9"]="9.9.9.9"
    ["Quad9 Alt"]="149.112.112.112"
    ["OpenDNS"]="208.67.222.222"
    ["Comodo"]="8.26.56.26"
    ["AdGuard"]="94.140.14.14"
    ["NextDNS"]="45.90.28.0"
    ["Mullvad"]="194.242.2.2"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DNS RESOLVER BENCHMARK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dns_bench_resolver() {
    local label="$1"  resolver="$2"  host="${3:-archlinux.org}"
    local samples=3  total=0  ok=0

    for (( i=0; i<samples; i++ )); do
        local start_ns end_ns elapsed

        start_ns="$(date +%s%N)"
        if dig +short +timeout=3 +tries=1 "$host" @"$resolver" \
           &>/dev/null 2>&1; then
            end_ns="$(date +%s%N)"
            elapsed=$(( (end_ns - start_ns) / 1000000 ))
            (( total += elapsed )) || true
            (( ok++ )) || true
        fi
    done

    if (( ok == 0 )); then
        printf '  %-20s %-16s  %s%s%s\n' \
            "$label" "$resolver" "$(_dred)" "TIMEOUT" "$(_dr)"
        return 1
    fi

    local avg=$(( total / ok ))
    local ms_color
    ms_color="$(_dns_latency_color "$avg")"

    # Latency bar (max 200ms)
    local bar_w=20
    local filled=$(( avg * bar_w / 200 ))
    (( filled > bar_w )) && filled=$bar_w
    local empty=$(( bar_w - filled ))

    printf '  %s%-20s%s %-16s  %s%s%s%s%s%s  %s%4d ms%s\n' \
        "$(_dsky)" "$label" "$(_dr)" \
        "$(_ddim)$resolver$(_dr)" \
        "$ms_color" \
        "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(_ddim)" \
        "$(printf '░%.0s' $(seq 1 $empty))" \
        "$(_dr)" \
        "$ms_color$(_dbold)" "$avg" "$(_dr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CURRENT RESOLVER INFO
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dns_current_info() {
    _dns_section "🔍" "Current DNS Configuration"

    # systemd-resolved
    if command -v resolvectl &>/dev/null && \
       systemctl is-active systemd-resolved &>/dev/null 2>&1; then
        _dns_kv "Manager" "systemd-resolved"

        local resolved_status
        resolved_status="$(resolvectl status 2>/dev/null | head -30)"

        local dns_servers dnssec dot
        dns_servers="$(printf '%s' "$resolved_status" | \
                       grep -E 'DNS Servers?:' | \
                       awk '{$1="";$2="";print}' | tr '\n' ' ')"
        dnssec="$(     printf '%s' "$resolved_status" | \
                       grep 'DNSSEC' | awk '{print $NF}' | head -1)"
        dot="$(        printf '%s' "$resolved_status" | \
                       grep 'DNS over TLS' | awk '{print $NF}' | head -1)"

        _dns_kv "Servers"      "${dns_servers:-?}"
        _dns_kv "DNSSEC"       "${dnssec:-?}"
        _dns_kv "DNS-over-TLS" "${dot:-?}"

        # Label known resolvers
        for ns in $dns_servers; do
            for known in "${!_DNS_RESOLVERS[@]}"; do
                if [[ "${_DNS_RESOLVERS[$known]}" == "$ns" ]]; then
                    printf '    %s%s → %s%s\n' \
                        "$(_ddim)" "$ns" "$known" "$(_dr)"
                fi
            done
        done
    else
        # /etc/resolv.conf fallback
        _dns_kv "Manager" "resolv.conf  (static)"
        while IFS=' ' read -r directive value; do
            [[ "$directive" == "nameserver" ]] && \
                _dns_kv "Nameserver" "$value"
            [[ "$directive" == "search" ]] && \
                _dns_kv "Search" "$value"
        done < /etc/resolv.conf 2>/dev/null
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DNS FLUSH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dns_flush() {
    _dns_section "🔄" "DNS Cache Flush"

    local flushed=0

    # systemd-resolved
    if command -v resolvectl &>/dev/null; then
        resolvectl flush-caches 2>/dev/null && {
            printf '  %s✓%s  systemd-resolved cache flushed\n' \
                "$(_dgreen)" "$(_dr)"
            (( flushed++ )) || true
        }
    fi

    # nscd
    if command -v nscd &>/dev/null; then
        sudo -n nscd -i hosts 2>/dev/null && {
            printf '  %s✓%s  nscd cache flushed\n' "$(_dgreen)" "$(_dr)"
            (( flushed++ )) || true
        }
    fi

    # dnsmasq
    if pgrep dnsmasq &>/dev/null; then
        sudo -n pkill -HUP dnsmasq 2>/dev/null && {
            printf '  %s✓%s  dnsmasq reloaded\n' "$(_dgreen)" "$(_dr)"
            (( flushed++ )) || true
        }
    fi

    (( flushed == 0 )) && \
        printf '  %sNo DNS cache manager detected%s\n' "$(_dyellow)" "$(_dr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_dns() {
    local action="info"  query_host=""  resolver=""

    for arg in "${@:-}"; do
        case "$arg" in
            info|status)          action="info"      ;;
            bench|benchmark)      action="bench"     ;;
            flush)                action="flush"     ;;
            lookup|query|resolve) action="lookup"    ;;
            --host=*)             query_host="${arg#*=}" ;;
            --resolver=*|@*)      resolver="${arg#*=}"; resolver="${resolver#@}" ;;
            *)  [[ -z "$query_host" ]] && query_host="$arg" ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;148;226;213m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🔍  ASH  ─  DNS Manager                                  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        info)
            _dns_current_info

            # Quick resolution test
            _dns_section "📡" "Resolution Test"
            local -a test_domains=( "archlinux.org" "github.com" "cloudflare.com" )
            for dom in "${test_domains[@]}"; do
                local start_ns end_ns ms result
                start_ns="$(date +%s%N)"
                result="$(dig +short +timeout=3 "$dom" 2>/dev/null | head -1)"
                end_ns="$(date +%s%N)"
                ms=$(( (end_ns - start_ns) / 1000000 ))

                if [[ -n "$result" ]]; then
                    printf '  %s✓%s  %-30s  %s%s%s  %s%dms%s\n' \
                        "$(_dgreen)" "$(_dr)" "$dom" \
                        "$(_ddim)" "$result" "$(_dr)" \
                        "$(_dns_latency_color "$ms")$(_dbold)" "$ms" "$(_dr)"
                else
                    printf '  %s✗%s  %-30s  %sFAILED%s\n' \
                        "$(_dred)" "$(_dr)" "$dom" "$(_dred)" "$(_dr)"
                fi
            done
            ;;

        lookup)
            _dns_section "🔎" "DNS Lookup"
            local target="${query_host:-archlinux.org}"
            local dns_server="${resolver:-}"

            printf '\n  %sQuerying: %s%s%s via %s%s%s\n' \
                "$(_ddim)" "$(_dsky)" "$target" "$(_dr)" \
                "$(_ddim)" "${dns_server:-system resolver}" "$(_dr)"

            local dig_cmd=( dig "+all" "$target" )
            [[ -n "$dns_server" ]] && dig_cmd+=( "@${dns_server}" )

            if command -v dig &>/dev/null; then
                "${dig_cmd[@]}" 2>/dev/null | \
                while IFS= read -r line; do
                    if [[ "$line" =~ ^";;" ]]; then
                        printf '  %s%s%s\n' "$(_ddim)" "$line" "$(_dr)"
                    elif [[ -n "$line" ]]; then
                        printf '  %s%s%s\n' "$(_dblue)" "$line" "$(_dr)"
                    fi
                done
            else
                host "$target" ${dns_server:+$dns_server} 2>/dev/null | \
                while IFS= read -r line; do
                    printf '  %s%s%s\n' "$(_dblue)" "$line" "$(_dr)"
                done
            fi
            ;;

        bench)
            _dns_section "⚡" "DNS Resolver Benchmark"
            printf '\n  %s%-20s %-16s  %-22s  %s%s\n' \
                "$(_ddim)" "Provider" "IP" "Response Time" "Avg" "$(_dr)"
            printf '  %s%s%s\n' \
                "$(_ddim)" "$(printf '─%.0s' $(seq 1 68))" "$(_dr)"

            local bench_host="archlinux.org"
            for label in "${!_DNS_RESOLVERS[@]}"; do
                _dns_bench_resolver "$label" "${_DNS_RESOLVERS[$label]}" "$bench_host"
            done
            ;;

        flush)
            _dns_flush
            ;;
    esac

    printf '\n'
}
