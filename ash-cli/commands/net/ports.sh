#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗  ██████╗ ██████╗ ████████╗███████╗                                     ║
# ║  ██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝                                     ║
# ║  ██████╔╝██║   ██║██████╔╝   ██║   ███████╗                                     ║
# ║  ██╔═══╝ ██║   ██║██╔══██╗   ██║   ╚════██║                                     ║
# ║  ██║     ╚██████╔╝██║  ██║   ██║   ███████║                                     ║
# ║  ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝                                     ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net ports                                                ║
# ║  Listening ports • process ownership • risk flags • scan target               ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_PORTS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_PORTS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_p()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_pr()     { _p '\033[0m';                        }
_pbold()  { _p '\033[1m';                        }
_pdim()   { _p '\033[38;2;108;112;134m';         }
_pgreen() { _p '\033[38;2;166;227;161m';         }
_pred()   { _p '\033[1;38;2;243;139;168m';       }
_pyellow(){ _p '\033[1;38;2;249;226;175m';       }
_pteal()  { _p '\033[38;2;148;226;213m';         }
_pblue()  { _p '\033[38;2;137;180;250m';         }
_psky()   { _p '\033[38;2;137;220;235m';         }
_pmauve() { _p '\033[1;38;2;203;166;247m';       }
_pppeach() { _p '\033[38;2;250;179;135m';         }
_ppink()  { _p '\033[38;2;245;194;231m';         }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WELL-KNOWN PORT DATABASE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _PORT_NAMES=(
    [20]="FTP-data"       [21]="FTP"          [22]="SSH"
    [23]="Telnet"         [25]="SMTP"         [53]="DNS"
    [67]="DHCP-server"   [68]="DHCP-client"  [69]="TFTP"
    [80]="HTTP"           [110]="POP3"        [119]="NNTP"
    [123]="NTP"           [143]="IMAP"        [161]="SNMP"
    [194]="IRC"           [389]="LDAP"        [443]="HTTPS"
    [445]="SMB"           [465]="SMTPS"       [514]="Syslog"
    [587]="SMTP-sub"      [631]="CUPS"        [636]="LDAPS"
    [873]="rsync"         [993]="IMAPS"       [995]="POP3S"
    [1080]="SOCKS5"       [1194]="OpenVPN"    [1433]="MSSQL"
    [1723]="PPTP"         [2049]="NFS"        [3000]="dev-server"
    [3306]="MySQL"        [3389]="RDP"        [4444]="Metasploit"
    [4789]="VXLAN"        [5000]="dev-server" [5432]="PostgreSQL"
    [5900]="VNC"          [6379]="Redis"      [6443]="Kubernetes"
    [8080]="HTTP-alt"     [8443]="HTTPS-alt"  [8888]="Jupyter"
    [9000]="PHP-FPM"      [9090]="Prometheus" [9200]="Elasticsearch"
    [11211]="Memcached"   [27017]="MongoDB"   [51820]="WireGuard"
)

declare -gA _PORT_RISK=(
    [21]="HIGH:FTP sends credentials in plaintext"
    [23]="CRITICAL:Telnet is completely unencrypted"
    [1080]="MEDIUM:SOCKS proxy exposed"
    [4444]="HIGH:Common Metasploit listener port"
    [5900]="MEDIUM:VNC without auth is vulnerable"
    [6379]="HIGH:Redis often misconfigured with no auth"
    [11211]="HIGH:Memcached amplification attack vector"
    [27017]="HIGH:MongoDB default: no authentication"
)

_port_label() {
    local port="$1"
    printf '%s' "${_PORT_NAMES[$port]:-unknown}"
}

_port_risk() {
    local port="$1"
    printf '%s' "${_PORT_RISK[$port]:-}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PORT TABLE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ports_render_table() {
    local proto_filter="${1:-}"   # tcp | udp | ""=both
    local show_all="${2:-0}"      # 1 = include established

    # Header
    printf '\n  %s%-7s %-25s %-10s %-20s %s%s\n' \
        "$(_pdim)" "Proto" "Local Address" "Port" "Process" "Service" "$(_pr)"
    printf '  %s%s%s\n' "$(_pdim)" "$(printf '─%.0s' $(seq 1 80))" "$(_pr)"

    local -a risk_findings=()
    local count=0

    # ss -tlnup for TCP + UDP
    local ss_flags="-tlnup"
    [[ $show_all -eq 1 ]] && ss_flags="-tlnupa"

    ss $ss_flags 2>/dev/null | tail -n +2 | \
    while IFS= read -r line; do
        local netid local_addr process
        netid="$(     printf '%s' "$line" | awk '{print $1}')"
        local_addr="$(printf '%s' "$line" | awk '{print $5}')"
        process="$(   printf '%s' "$line" | awk '{print $7}')"

        # Filter protocol
        [[ -n "$proto_filter" ]] && \
            [[ "${netid,,}" != "${proto_filter,,}" ]] && continue

        # Extract port from address
        local port
        port="$(printf '%s' "$local_addr" | grep -oP '(?<=:)\d+$')"
        [[ -z "$port" ]] && continue

        # Extract address (IPv4/IPv6/any)
        local addr
        addr="${local_addr%:$port}"

        # Process name from users:(...) field
        local proc_name
        proc_name="$(printf '%s' "$process" | \
                     grep -oP '(?<=\(\(")[^"]+' | head -1 || echo '?')"

        # Service name
        local svc
        svc="$(_port_label "$port")"

        # Protocol color
        local proto_color
        case "${netid,,}" in
            tcp*) proto_color="$(_pblue)"   ;;
            udp*)  proto_color="$(_pyellow)" ;;
            *)    proto_color="$(_pdim)"    ;;
        esac

        # Address exposure
        local addr_color addr_icon
        if [[ "$addr" =~ ^(0\.0\.0\.0|\*|\:\:)$ ]]; then
            addr_color="$(_ppink)"
            addr_icon="⚠ "
        else
            addr_color="$(_pdim)"
            addr_icon=""
        fi

        # Port risk
        local risk
        risk="$(_port_risk "$port")"
        local risk_badge=""
        if [[ -n "$risk" ]]; then
            local risk_level="${risk%%:*}"
            case "$risk_level" in
                CRITICAL) risk_badge="${_pred}[CRITICAL]${_pr}" ;;
                HIGH)     risk_badge="${_pred}[HIGH]${_pr}"     ;;
                MEDIUM)   risk_badge="${_pyellow}[MED]${_pr}"   ;;
            esac
            risk_findings+=("${port}: ${risk##*:}")
        fi

        printf '  %s%-7s%s %s%-16s%s %s%-12s%s %-18s %s%-14s%s %s\n' \
            "$proto_color" "${netid^^}" "$(_pr)" \
            "$addr_color" "${addr_icon}${addr:0:15}" "$(_pr)" \
            "$(_pppeach)$(_pbold)" "$port" "$(_pr)" \
            "${proc_name:0:17}" \
            "$(_pteal)" "${svc:0:14}" "$(_pr)" \
            "$risk_badge"

        (( count++ )) || true

    done

    printf '\n  %s%d listening port(s)%s\n' "$(_pdim)" "$count" "$(_pr)"

    # Risk summary
    if [[ ${#risk_findings[@]} -gt 0 ]]; then
        printf '\n  %s⚠  Security Findings:%s\n' "$(_pred)" "$(_pr)"
        for finding in "${risk_findings[@]}"; do
            printf '    %s•%s  %s\n' "$(_pred)" "$(_pr)" "$finding"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SCAN A SPECIFIC PORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ports_check_port() {
    local target="$1"  port="$2"

    printf '\n  %s→  Checking %s:%s...%s\n' \
        "$(_pteal)" "$target" "$port" "$(_pr)"

    if command -v nc &>/dev/null; then
        local start_ns end_ns ms
        start_ns="$(date +%s%N)"
        if nc -z -w 3 "$target" "$port" 2>/dev/null; then
            end_ns="$(date +%s%N)"
            ms=$(( (end_ns - start_ns) / 1000000 ))
            local svc
            svc="$(_port_label "$port")"
            printf '  %s✓%s  Port %s%s%s (%s) is %sOPEN%s  %s%dms%s\n' \
                "$(_pgreen)" "$(_pr)" \
                "$(_pppeach)$(_pbold)" "$port" "$(_pr)" "$svc" \
                "$(_pgreen)" "$(_pr)" \
                "$(_pdim)" "$ms" "$(_pr)"
        else
            printf '  %s✗%s  Port %s%s%s is %sCLOSED/FILTERED%s\n' \
                "$(_pred)" "$(_pr)" \
                "$(_pppeach)" "$port" "$(_pr)" \
                "$(_pred)" "$(_pr)"
        fi
    elif command -v bash &>/dev/null; then
        if (echo >/dev/tcp/"$target"/"$port") 2>/dev/null; then
            printf '  %s✓  Port %s: OPEN%s\n' "$(_pgreen)" "$port" "$(_pr)"
        else
            printf '  %s✗  Port %s: CLOSED%s\n' "$(_pred)" "$port" "$(_pr)"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_ports() {
    local action="list"  proto=""  target=""  port=""  show_all=0

    for arg in "${@:-}"; do
        case "$arg" in
            --tcp|-t)       proto="tcp"    ;;
            --udp|-u)       proto="udp"    ;;
            --all|-a)       show_all=1     ;;
            check|scan)     action="check" ;;
            --port=*)       port="${arg#*=}" ;;
            --target=*)     target="${arg#*=}" ;;
            *)
                if [[ $action == "check" ]]; then
                    [[ -z "$target" ]] && target="$arg" || port="$arg"
                fi
                ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;250;179;135m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🚪  ASH  ─  Port Scanner / Listener View                 ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        list)
            printf '\n  %sListening ports%s%s\n' \
                "$(_pbold)" "${proto:+  (${proto^^} only)}" "$(_pr)"
            _ports_render_table "$proto" "$show_all"
            ;;
        check)
            [[ -z "$target" ]] && target="127.0.0.1"
            [[ -z "$port"   ]] && {
                printf '  Usage: ash net ports check [target] <port>\n'
                return 1
            }
            _ports_check_port "$target" "$port"
            ;;
    esac

    printf '\n'
}
