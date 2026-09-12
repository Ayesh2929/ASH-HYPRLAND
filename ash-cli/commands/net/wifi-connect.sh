#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  net wifi-connect                                         ║
# ║  Interactive WiFi connection manager with credential handling & retry logic      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_NET_WIFI_CONNECT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_NET_WIFI_CONNECT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wc_require_tool() {
    command -v nmcli &>/dev/null && return 0
    command -v iwctl  &>/dev/null && return 0

    printf '\n  %s✗  No WiFi manager found%s\n' "$(_nred)" "$(_nr)"
    printf '  %sInstall one of: NetworkManager (nmcli) / iwd (iwctl)%s\n' \
        "$(_ndim)" "$(_nr)"
    return 1
}

_wc_list_saved() {
    command -v nmcli &>/dev/null || return 1
    nmcli -t -f NAME,TYPE,ACTIVE con show 2>/dev/null | \
        grep '802-11-wireless' | \
        awk -F: '{printf "%s  [%s]\n", $1, ($3=="yes"?"★ ACTIVE":"  saved")}'
}

_wc_is_known() {
    local ssid="$1"
    command -v nmcli &>/dev/null || return 1
    nmcli -t -f NAME con show 2>/dev/null | grep -qx "$ssid"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CONNECTION ATTEMPT WITH RETRY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wc_connect_nmcli() {
    local ssid="$1"  password="${2:-}"  iface="${3:-}"

    local cmd_args=( "nmcli" "dev" "wifi" "connect" "$ssid" )
    [[ -n "$password" ]] && cmd_args+=( "password" "$password" )
    [[ -n "$iface"    ]] && cmd_args+=( "ifname"   "$iface"   )

    local output exit_code=0
    output="$("${cmd_args[@]}" 2>&1)" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        printf '  %s✓  Connected to %s%s\n' "$(_ngreen)" "$ssid" "$(_nr)"
        return 0
    else
        local reason
        reason="$(printf '%s' "$output" | tail -1)"
        printf '  %s✗  Connection failed: %s%s\n' "$(_nred)" "$reason" "$(_nr)"
        return 1
    fi
}

_wc_connect_iwctl() {
    local ssid="$1"  password="${2:-}"  iface="${3:-sta0}"

    printf '  %s→  Connecting via iwctl...%s\n' "$(_nteal)" "$(_nr)"

    if [[ -n "$password" ]]; then
        iwctl --passphrase "$password" station "$iface" connect "$ssid" 2>/dev/null
    else
        iwctl station "$iface" connect "$ssid" 2>/dev/null
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERACTIVE SSID PICKER (fzf / select)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wc_pick_ssid() {
    local scan_data
    scan_data="$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null || echo '')"
    [[ -z "$scan_data" ]] && return 1

    if command -v fzf &>/dev/null; then
        printf '%s' "$scan_data" | \
        awk -F: 'NF>=1 && $1!="" {printf "%-35s  Signal:%-4s  %s\n", $1, $2, $3}' | \
        fzf --prompt "  🔍  Select WiFi: " \
            --height=20 \
            --border=rounded \
            --color="hl:$(_ngreen),hl+:$(_nblue)" \
            --header="ESC to cancel" \
            --preview="echo {1}" \
            --preview-window=hidden | \
        awk '{print $1}'
    else
        # Fallback: bash select
        printf '\n  %sAvailable networks:%s\n' "$(_nbold)" "$(_nr)"
        local -a ssids=()
        while IFS=':' read -r ssid signal security; do
            [[ -z "$ssid" ]] && continue
            ssids+=("$ssid")
            printf '    %s%-35s%s Signal:%s  %s\n' \
                "$(_nsky)" "$ssid" "$(_nr)" "$signal" "$security"
        done <<< "$scan_data"

        printf '\n  %sEnter SSID (or number): %s' "$(_ndim)" "$(_nr)"
        local choice
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 )) && \
           (( choice <= ${#ssids[@]} )); then
            printf '%s' "${ssids[$((choice-1))]}"
        else
            printf '%s' "$choice"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_net_wifi_connect() {
    local ssid=""  password=""  iface=""  forget=0  disconnect=0

    for arg in "${@:-}"; do
        case "$arg" in
            --password=*|-p=*)  password="${arg#*=}"  ;;
            --iface=*)          iface="${arg#*=}"     ;;
            --forget)           forget=1              ;;
            --disconnect|-d)    disconnect=1          ;;
            -*)                 : ;;
            *)                  [[ -z "$ssid" ]] && ssid="$arg" ;;
        esac
    done

    net_section "🔌" "WiFi Connect" "$(_ngreen)"

    _wc_require_tool || return 1

    # ── Disconnect ────────────────────────────────────────────────────────────────
    if [[ $disconnect -eq 1 ]]; then
        local active_iface
        active_iface="${iface:-$( _scan_find_iface 2>/dev/null )}"
        printf '  %s→  Disconnecting %s...%s\n' "$(_nteal)" "$active_iface" "$(_nr)"
        nmcli dev disconnect "$active_iface" 2>/dev/null && \
            printf '  %s✓  Disconnected%s\n' "$(_ngreen)" "$(_nr)" || \
            printf '  %s✗  Disconnect failed%s\n' "$(_nred)" "$(_nr)"
        net_divider; return
    fi

    # ── Forget network ────────────────────────────────────────────────────────────
    if [[ $forget -eq 1 ]] && [[ -n "$ssid" ]]; then
        printf '  %s→  Forgetting %s...%s\n' "$(_nteal)" "$ssid" "$(_nr)"
        nmcli con delete "$ssid" 2>/dev/null && \
            printf '  %s✓  Network forgotten%s\n' "$(_ngreen)" "$(_nr)" || \
            printf '  %s✗  Failed%s\n' "$(_nred)" "$(_nr)"
        net_divider; return
    fi

    # ── Interactive SSID selection ────────────────────────────────────────────────
    if [[ -z "$ssid" ]]; then
        printf '\n  %s⠋  Scanning for networks...%s\n' "$(_nteal)" "$(_nr)"
        nmcli dev wifi rescan 2>/dev/null || true
        sleep 1
        ssid="$(_wc_pick_ssid)"
        [[ -z "$ssid" ]] && {
            printf '  %sNo SSID selected%s\n' "$(_nyellow)" "$(_nr)"
            net_divider; return 0
        }
    fi

    net_kv "SSID"      "$ssid"
    net_kv "Interface" "${iface:-auto}"

    # ── Check if already known ────────────────────────────────────────────────────
    if _wc_is_known "$ssid"; then
        printf '  %s★  Known network — reconnecting...%s\n' "$(_ndim)" "$(_nr)"
        if nmcli con up "$ssid" ${iface:+ifname "$iface"} 2>/dev/null; then
            printf '  %s✓  Reconnected to %s%s\n' "$(_ngreen)" "$ssid" "$(_nr)"
            net_divider; return 0
        fi
    fi

    # ── Get password ──────────────────────────────────────────────────────────────
    if [[ -z "$password" ]]; then
        # Check if network is open
        local security
        security="$(nmcli -t -f SSID,SECURITY dev wifi list 2>/dev/null | \
                    awk -F: -v s="$ssid" '$1==s{print $2}' | head -1)"

        if [[ -z "$security" ]]; then
            printf '  %s(Open network — no password needed)%s\n' "$(_ndim)" "$(_nr)"
        else
            printf '  %sPassword for %s%s%s: ' \
                "$(_ndim)" "$(_nsky)" "$ssid" "$(_nr)"
            read -rs password
            printf '\n'
        fi
    fi

    # ── Attempt connection ────────────────────────────────────────────────────────
    printf '\n  %s→  Connecting...%s\n' "$(_nteal)" "$(_nr)"

    local max_retries=3  retry=0  connected=0

    while (( retry < max_retries )); do
        (( retry++ )) || true

        if command -v nmcli &>/dev/null; then
            _wc_connect_nmcli "$ssid" "$password" "$iface" && \
                connected=1 && break
        elif command -v iwctl &>/dev/null; then
            _wc_connect_iwctl "$ssid" "$password" "$iface" && \
                connected=1 && break
        fi

        if (( retry < max_retries )); then
            printf '  %s  Retry %d/%d in 2s...%s\n' \
                "$(_nyellow)" "$retry" "$max_retries" "$(_nr)"
            sleep 2
        fi
    done

    if [[ $connected -eq 1 ]]; then
        # Show new IP
        sleep 1
        local new_ip
        new_ip="$(net_iface_ipv4 "${iface:-$(nmcli -t -f DEVICE,STATE dev | grep ':connected' | cut -d: -f1 | head -1)}")"
        [[ -n "$new_ip" ]] && net_kv "New IPv4" "$new_ip"

        # Show notification
        command -v notify-send &>/dev/null && \
            notify-send "🌐 WiFi Connected" "Connected to: $ssid" \
                --icon=network-wireless 2>/dev/null || true
    else
        printf '\n  %s✗  Could not connect after %d attempts%s\n' \
            "$(_nred)" "$max_retries" "$(_nr)"
        printf '  %sTry: ash net wifi-scan  to verify the network is visible%s\n' \
            "$(_ndim)" "$(_nr)"
    fi

    net_divider
}
