#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ████████╗ ██████╗ ██████╗                                                       ║
# ║  ╚══██╔══╝██╔═══██╗██╔══██╗                                                      ║
# ║     ██║   ██║   ██║██████╔╝                                                      ║
# ║     ██║   ██║   ██║██╔══██╗                                                      ║
# ║     ██║   ╚██████╔╝██║  ██║                                                      ║
# ║     ╚═╝    ╚═════╝ ╚═╝  ╚═╝                                                      ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net tor                                                   ║
# ║  Tor daemon control • circuit info • identity refresh • torification             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_TOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_TOR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _TOR_SOCKS_HOST="127.0.0.1"
declare -gr _TOR_SOCKS_PORT="9050"
declare -gr _TOR_CONTROL_PORT="9051"
declare -gr _TOR_DNS_PORT="5353"
declare -gr _TOR_CONTROL_COOKIE="/var/lib/tor/control_auth_cookie"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_t()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_tr()     { _t '\033[0m';                        }
_tbold()  { _t '\033[1m';                        }
_tdim()   { _t '\033[38;2;108;112;134m';         }
_tgreen() { _t '\033[38;2;166;227;161m';         }
_tred()   { _t '\033[1;38;2;243;139;168m';       }
_tyellow(){ _t '\033[1;38;2;249;226;175m';       }
_tteal()  { _t '\033[38;2;148;226;213m';         }
_tblue()  { _t '\033[38;2;137;180;250m';         }
_tsky()   { _t '\033[38;2;137;220;235m';         }
_tmauve() { _t '\033[1;38;2;203;166;247m';       }
_tpeach() { _t '\033[38;2;250;179;135m';         }

_tor_section() {
    printf '\n%s%s  %s%s\n' "$(_tmauve)" "$1" "$2" "$(_tr)"
    printf '%s  %s%s\n' "$(_tdim)" "$(printf '─%.0s' $(seq 1 54))" "$(_tr)"
}

_tor_kv() {
    printf '  %s%-24s%s %s%s%s\n' \
        "$(_tdim)" "${1}:" "$(_tr)" "${3:-$(_tgreen)}" "$2" "$(_tr)"
}

_tor_ok()   { printf '  %s✓%s  %s\n' "$(_tgreen)"  "$(_tr)" "$1"; }
_tor_fail() { printf '  %s✗%s  %s\n' "$(_tred)"    "$(_tr)" "$1"; }
_tor_info() { printf '  %sℹ%s  %s\n' "$(_tdim)"    "$(_tr)" "$1"; }
_tor_warn() { printf '  %s⚠%s  %s\n' "$(_tyellow)" "$(_tr)" "$1"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TOR AVAILABILITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_tor_installed() { command -v tor &>/dev/null; }

_tor_running() {
    pgrep -x tor &>/dev/null || \
    ss -tlnp 2>/dev/null | grep -q ":${_TOR_SOCKS_PORT} "
}

_tor_socks_available() {
    (echo >/dev/tcp/"$_TOR_SOCKS_HOST"/"$_TOR_SOCKS_PORT") 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TOR CONTROL PROTOCOL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_tor_control_cmd() {
    local cmd="$1"
    local password="${TOR_CONTROL_PASSWORD:-}"

    if command -v torify &>/dev/null && command -v nc &>/dev/null; then
        if [[ -n "$password" ]]; then
            printf 'AUTHENTICATE "%s"\r\n%s\r\nQUIT\r\n' \
                "$password" "$cmd" | \
            nc -q 1 "$_TOR_SOCKS_HOST" "$_TOR_CONTROL_PORT" 2>/dev/null
        else
            # Cookie auth
            printf 'AUTHENTICATE\r\n%s\r\nQUIT\r\n' "$cmd" | \
            nc -q 1 "$_TOR_SOCKS_HOST" "$_TOR_CONTROL_PORT" 2>/dev/null
        fi
    fi
}

_tor_new_identity() {
    _tor_section "🔄" "Request New Identity"

    if ! _tor_socks_available; then
        _tor_fail "Tor SOCKS not available on port ${_TOR_SOCKS_PORT}"
        return 1
    fi

    # Try via control port
    local result
    if result="$(_tor_control_cmd "SIGNAL NEWNYM" 2>/dev/null)"; then
        if printf '%s' "$result" | grep -q '250 OK'; then
            _tor_ok "New Tor identity requested successfully"
            _tor_info "Wait ~10 seconds for circuit to change"
            return 0
        fi
    fi

    # Fallback: restart tor
    _tor_warn "Control port method failed — consider setting TOR_CONTROL_PASSWORD"
    _tor_info "Alternatively: sudo systemctl restart tor"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VERIFY TOR ROUTING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_tor_verify() {
    _tor_section "🔍" "Tor Routing Verification"

    # Check 1: via check.torproject.org
    printf '  %s→  Testing via check.torproject.org...%s\n' "$(_tteal)" "$(_tr)"

    local tor_check_result
    tor_check_result="$(curl -fsSL \
        --socks5 "${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
        --max-time 15 \
        "https://check.torproject.org/api/ip" \
        2>/dev/null || echo '{}')"

    if command -v python3 &>/dev/null; then
        local is_tor exit_ip
        is_tor="$(printf '%s' "$tor_check_result" | \
                  python3 -c "import sys,json; d=json.load(sys.stdin); \
                  print(d.get('IsTor', False))" 2>/dev/null || echo 'false')"
        exit_ip="$(printf '%s' "$tor_check_result" | \
                   python3 -c "import sys,json; d=json.load(sys.stdin); \
                   print(d.get('IP', '?'))" 2>/dev/null || echo '?')"

        if [[ "$is_tor" == "True" ]]; then
            _tor_ok "Traffic IS going through Tor!"
            _tor_kv "Exit IP" "$exit_ip"
        else
            _tor_fail "Traffic NOT going through Tor  (IP: ${exit_ip})"
        fi
    else
        # Simple check
        if curl -fsSL \
            --socks5 "${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
            --max-time 15 \
            "https://check.torproject.org/" 2>/dev/null | \
            grep -q "Congratulations"; then
            _tor_ok "Congratulations! Traffic is going through Tor"
        else
            _tor_fail "Not routing through Tor"
        fi
    fi

    # Tor exit node location
    local geo_ip
    geo_ip="$(curl -fsSL \
        --socks5 "${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
        --max-time 15 \
        "https://ipapi.co/country_name" 2>/dev/null || echo '?')"
    [[ -n "$geo_ip" ]] && _tor_kv "Exit location" "$geo_ip"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TORIFY A COMMAND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_tor_run_cmd() {
    local -a cmd=("$@")

    _tor_section "⚡" "Run Command via Tor"
    printf '  %s→  %s%s\n' "$(_tteal)" "${cmd[*]}" "$(_tr)"

    if ! _tor_socks_available; then
        _tor_fail "Tor SOCKS not available — start tor first"
        return 1
    fi

    if command -v torsocks &>/dev/null; then
        torsocks "${cmd[@]}"
    elif command -v proxychains &>/dev/null; then
        proxychains "${cmd[@]}" 2>/dev/null
    else
        # Set env vars and use curl/wget style proxy
        env \
            http_proxy="socks5://${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
            https_proxy="socks5://${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
            ALL_PROXY="socks5://${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
            "${cmd[@]}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED ONION BOOT SEQUENCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_tor_boot_animation() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        local frames=(
            "🧅  Connecting to Tor network..."
            "🧅  Finding relays..."
            "🧅  Building circuits..."
            "🧅  Establishing anonymity..."
        )
        for frame in "${frames[@]}"; do
            printf '\r  %s%s%s' "$(_tmauve)" "$frame" "$(_tr)"
            sleep 0.4
        done
        printf '\r  %-50s\r' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_tor() {
    local action="status"
    local -a run_cmd=()

    for arg in "${@:-}"; do
        case "$arg" in
            status|info)      action="status"   ;;
            start)            action="start"    ;;
            stop)             action="stop"     ;;
            restart)          action="restart"  ;;
            newid|newnym)     action="newid"    ;;
            verify|check)     action="verify"   ;;
            run|exec)         action="run"      ;;
            *)
                [[ "$action" == "run" ]] && run_cmd+=("$arg")
                ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🧅  ASH  ─  Tor Privacy Manager                          ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        status)
            _tor_section "🧅" "Tor Status"

            if ! _tor_installed; then
                _tor_fail "Tor not installed"
                printf '  %sInstall: paru -S tor%s\n' "$(_tdim)" "$(_tr)"
                printf '\n'; return 1
            fi

            local tor_ver
            tor_ver="$(tor --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
            _tor_kv "Tor version" "$tor_ver"

            if _tor_running; then
                _tor_ok "Tor daemon is RUNNING"
            else
                _tor_fail "Tor daemon is NOT running"
                printf '  %sStart: ash net tor start%s\n' "$(_tdim)" "$(_tr)"
            fi

            _tor_kv "SOCKS proxy" "${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}"

            if _tor_socks_available; then
                _tor_ok "SOCKS port ${_TOR_SOCKS_PORT} is open"
            else
                _tor_fail "SOCKS port ${_TOR_SOCKS_PORT} not accessible"
            fi

            # Circuit status via control port
            _tor_info "Check circuits: ash net tor verify"
            ;;

        start)
            _tor_section "▶" "Start Tor"

            if _tor_running; then
                _tor_ok "Tor is already running"
                printf '\n'; return 0
            fi

            _tor_boot_animation

            if command -v systemctl &>/dev/null; then
                sudo systemctl start tor && \
                    _tor_ok "Tor started via systemd" || \
                    _tor_fail "Failed to start tor"
            else
                sudo tor --RunAsDaemon 1 && \
                    _tor_ok "Tor started as daemon" || \
                    _tor_fail "Failed to start tor"
            fi

            # Wait for SOCKS
            for (( i=0; i<10; i++ )); do
                sleep 0.5
                _tor_socks_available && {
                    _tor_ok "Tor SOCKS ready on port ${_TOR_SOCKS_PORT}"
                    break
                }
            done

            command -v notify-send &>/dev/null && \
                notify-send "🧅 Tor Started" \
                    "SOCKS proxy: ${_TOR_SOCKS_HOST}:${_TOR_SOCKS_PORT}" \
                    --icon=tor 2>/dev/null || true
            ;;

        stop)
            _tor_section "⏹" "Stop Tor"
            if command -v systemctl &>/dev/null; then
                sudo systemctl stop tor && \
                    _tor_ok "Tor stopped" || \
                    _tor_fail "Failed to stop tor"
            else
                sudo pkill tor && _tor_ok "Tor stopped" || \
                    _tor_fail "Failed"
            fi
            ;;

        restart)
            _tor_section "🔄" "Restart Tor"
            if command -v systemctl &>/dev/null; then
                sudo systemctl restart tor && \
                    _tor_ok "Tor restarted" || \
                    _tor_fail "Failed"
            else
                sudo pkill tor 2>/dev/null || true
                sleep 1
                sudo tor --RunAsDaemon 1 && _tor_ok "Tor restarted"
            fi
            ;;

        newid)
            _tor_new_identity
            ;;

        verify)
            _tor_verify
            ;;

        run)
            if [[ ${#run_cmd[@]} -eq 0 ]]; then
                printf '  Usage: ash net tor run <command> [args]\n'
                return 1
            fi
            _tor_run_cmd "${run_cmd[@]}"
            ;;
    esac

    printf '\n'
}
