#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗                                    ║
# ║  ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝                                    ║
# ║  ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝                                     ║
# ║  ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝                                      ║
# ║  ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║                                       ║
# ║  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝                                       ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  net proxy                                                ║
# ║  HTTP/SOCKS proxy • set/unset/test • pac files • environment management         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_PROXY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_PROXY_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COLOUR HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_px()      { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && printf '%s' "$1" || true; }
_pxr()     { _px '\033[0m';                       }
_pxbold()  { _px '\033[1m';                       }
_pxdim()   { _px '\033[38;2;108;112;134m';        }
_pxgreen() { _px '\033[38;2;166;227;161m';        }
_pxred()   { _px '\033[1;38;2;243;139;168m';      }
_pxyellow(){ _px '\033[1;38;2;249;226;175m';      }
_pxteal()  { _px '\033[38;2;148;226;213m';        }
_pxblue()  { _px '\033[38;2;137;180;250m';        }
_pxsky()   { _px '\033[38;2;137;220;235m';        }
_pxmauve() { _px '\033[1;38;2;203;166;247m';      }
_pxpeach() { _px '\033[38;2;250;179;135m';        }

_px_section() {
    printf '\n%s%s  %s%s\n' "$(_pxmauve)" "$1" "$2" "$(_pxr)"
    printf '%s  %s%s\n' "$(_pxdim)" "$(printf '─%.0s' $(seq 1 54))" "$(_pxr)"
}

_px_kv() {
    printf '  %s%-24s%s %s%s%s\n' \
        "$(_pxdim)" "${1}:" "$(_pxr)" "${3:-$(_pxgreen)}" "$2" "$(_pxr)"
}

_px_ok()   { printf '  %s✓%s  %s\n' "$(_pxgreen)"  "$(_pxr)" "$1"; }
_px_fail() { printf '  %s✗%s  %s\n' "$(_pxred)"    "$(_pxr)" "$1"; }
_px_info() { printf '  %sℹ%s  %s\n' "$(_pxdim)"    "$(_pxr)" "$1"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROXY ENV VARS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -ga _PROXY_VARS=(
    http_proxy HTTP_PROXY
    https_proxy HTTPS_PROXY
    ftp_proxy FTP_PROXY
    all_proxy ALL_PROXY
    no_proxy NO_PROXY
    SOCKS_PROXY socks_proxy
)

_proxy_status() {
    _px_section "📡" "Current Proxy Configuration"

    local found=0
    for var in "${_PROXY_VARS[@]}"; do
        local val="${!var:-}"
        if [[ -n "$val" ]]; then
            _px_kv "$var" "$val"
            (( found++ )) || true
        fi
    done

    if (( found == 0 )); then
        _px_info "No proxy environment variables set"
    fi

    # Check gsettings / GNOME proxy
    if command -v gsettings &>/dev/null; then
        local gnome_mode
        gnome_mode="$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'")"
        if [[ "$gnome_mode" != "none" ]] && [[ -n "$gnome_mode" ]]; then
            printf '\n'
            _px_kv "GNOME proxy mode" "$gnome_mode"
        fi
    fi

    # /etc/environment
    if grep -qE '^(http|https|all)_proxy' /etc/environment 2>/dev/null; then
        printf '\n'
        _px_info "Proxy also set in /etc/environment:"
        grep -E '(http|https|all|no)_proxy' /etc/environment 2>/dev/null | \
        while IFS= read -r line; do
            printf '    %s%s%s\n' "$(_pxblue)" "$line" "$(_pxr)"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SET PROXY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proxy_set() {
    local proxy_url="$1"   # e.g. http://user:pass@proxy:8080
    local persist="${2:-0}"

    # Validate URL format
    if ! printf '%s' "$proxy_url" | \
         grep -qP '^(http|https|socks[45]?)://'; then
        _px_fail "Invalid proxy URL: $proxy_url"
        printf '  %sFormat: http[s]://[user:pass@]host:port%s\n' \
            "$(_pxdim)" "$(_pxr)"
        return 1
    fi

    _px_section "✅" "Set Proxy"
    printf '  %s→  Setting proxy to: %s%s%s\n' \
        "$(_pxteal)" "$(_pxsky)" "$proxy_url" "$(_pxr)"

    local -a vars_to_set=(
        "http_proxy=${proxy_url}"
        "https_proxy=${proxy_url}"
        "ftp_proxy=${proxy_url}"
        "all_proxy=${proxy_url}"
        "HTTP_PROXY=${proxy_url}"
        "HTTPS_PROXY=${proxy_url}"
        "ALL_PROXY=${proxy_url}"
    )

    if [[ $persist -eq 1 ]]; then
        # Write to environment.d
        local env_file="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/proxy.conf"
        mkdir -p "$(dirname "$env_file")" 2>/dev/null

        {
            printf '# ASH proxy configuration — generated %s\n' "$(date -Iseconds)"
            for v in "${vars_to_set[@]}"; do
                printf '%s\n' "$v"
            done
            printf 'no_proxy=localhost,127.0.0.1,::1\n'
        } > "$env_file"

        _px_ok "Proxy saved to ${env_file}"
        _px_info "Log out and back in to apply to all applications"
    else
        # Export to current shell via eval hint
        printf '\n  %sTo activate in current shell, run:%s\n' "$(_pxdim)" "$(_pxr)"
        for v in "${vars_to_set[@]}"; do
            printf '  %sexport %s%s\n' "$(_pxblue)" "$v" "$(_pxr)"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  UNSET PROXY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proxy_unset() {
    _px_section "🚫" "Unset Proxy"

    # Remove persistent file
    local env_file="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/proxy.conf"
    if [[ -f "$env_file" ]]; then
        rm -f "$env_file" && _px_ok "Removed ${env_file}"
    fi

    # Unset from current session
    printf '\n  %sTo clear in current shell, run:%s\n' "$(_pxdim)" "$(_pxr)"
    for var in "${_PROXY_VARS[@]}"; do
        printf '  %sunset %s%s\n' "$(_pxblue)" "$var" "$(_pxr)"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROXY TEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_proxy_test() {
    local proxy_url="${1:-${http_proxy:-${HTTP_PROXY:-}}}"

    _px_section "🔬" "Proxy Test"

    if [[ -z "$proxy_url" ]]; then
        _px_fail "No proxy configured (set http_proxy or pass URL)"
        return 1
    fi

    _px_kv "Testing proxy" "$proxy_url"

    local test_url="https://api4.my-ip.io/ip"
    local start_ns end_ns ms result exit_code=0

    start_ns="$(date +%s%N)"
    result="$(curl -fsSL --max-time 10 \
              --proxy "$proxy_url" \
              "$test_url" 2>/dev/null)" || exit_code=$?
    end_ns="$(date +%s%N)"
    ms=$(( (end_ns - start_ns) / 1000000 ))

    if [[ $exit_code -eq 0 ]] && [[ -n "$result" ]]; then
        _px_ok "Proxy working!  Response IP: $result  (${ms}ms)"
    else
        _px_fail "Proxy test failed  (exit: $exit_code  time: ${ms}ms)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_proxy() {
    local action="status"  proxy_url=""  persist=0

    for arg in "${@:-}"; do
        case "$arg" in
            status|show)          action="status"  ;;
            set)                  action="set"     ;;
            unset|clear|off)      action="unset"   ;;
            test|check)           action="test"    ;;
            --persist|-p)         persist=1        ;;
            http://*|https://*|socks*://*) proxy_url="$arg" ;;
        esac
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;180;190;254m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🌉  ASH  ─  Proxy Manager                                ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        status) _proxy_status ;;
        set)    _proxy_set "$proxy_url" "$persist" ;;
        unset)  _proxy_unset ;;
        test)   _proxy_test "$proxy_url" ;;
    esac

    printf '\n'
}
