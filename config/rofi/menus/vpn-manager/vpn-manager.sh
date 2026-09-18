#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — VPN Manager (rofi)                               ║
# ║                                                                              ║
# ║  Lists every NetworkManager VPN/WireGuard profile, shows the active tunnel, ║
# ║  and connects, disconnects or imports a profile without leaving the panel.  ║
# ║                                                                              ║
# ║  Opened from config/waybar/custom-modules/vpn-status.jsonc (falls back to   ║
# ║  nmtui when rofi is unavailable).                                           ║
# ║                                                                              ║
# ║  ROFI_RETV protocol:                                                         ║
# ║    0  = init (print the menu)                                                ║
# ║    1  = entry selected                                                       ║
# ║   10  = Ctrl+I  import an .ovpn/.conf file                                   ║
# ║   11  = Ctrl+R  refresh the list                                             ║
# ║   12  = Ctrl+D  disconnect the active tunnel                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THEME_FILE="${SCRIPT_DIR}/vpn-manager.rasi"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly LOG_FILE="${STATE_DIR}/vpn-manager.log"

command -v nmcli >/dev/null 2>&1 || {
    notify-send --app-name="ash-vpn" --urgency=critical \
        "VPN manager" "nmcli not found — install NetworkManager" 2>/dev/null || true
    exit 1
}

mkdir -p "$STATE_DIR" 2>/dev/null || true
log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name="ash-vpn" --urgency="${2:-low}" "$1" "${3:-}" 2>/dev/null || true
}

vpn_profiles() {
    nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | awk -F: '$2 ~ /^(vpn|wireguard)$/ { print $1 }'
}

active_vpn() {
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | awk -F: '$2 ~ /^(vpn|wireguard)$/ { print $1; exit }'
}

rofi_theme=()
[[ -f "$THEME_FILE" ]] && rofi_theme=(-theme "$THEME_FILE")

show_menu() {
    local active; active="$(active_vpn || true)"
    if [[ -n "$active" ]]; then
        printf '\0prompt\x1fVPN (connected: %s)\n' "$active"
        printf '󰦝  Disconnect %s\n' "$active"
    else
        printf '\0prompt\x1fVPN\n'
        printf '󰦞  No active tunnel\n'
    fi
    printf '󰒓  Import .ovpn / .conf…\n'
    printf '󰑓  Refresh list\n'
    while IFS= read -r profile; do
        [[ -n "$profile" ]] || continue
        if [[ "$profile" == "${active:-}" ]]; then
            printf '󰄬  %s (connected)\n' "$profile"
        else
            printf '󰖂  %s\n' "$profile"
        fi
    done < <(vpn_profiles)
}

connect_profile() {
    local profile="$1"
    if nmcli connection up "$profile" >/dev/null 2>&1; then
        notify "🔒 VPN connected" low "$profile"
        log "connected $profile"
    else
        notify "⚠ VPN connection failed" critical "$profile — check credentials or see journalctl -u NetworkManager"
        log "failed $profile"
    fi
}

disconnect_profile() {
    local profile="$1"
    nmcli connection down "$profile" >/dev/null 2>&1 || true
    notify "🔓 VPN disconnected" low "$profile"
    log "disconnected $profile"
}

import_profile() {
    local file
    file="$(rofi -dmenu -p 'Path to .ovpn/.conf' "${rofi_theme[@]}" </dev/null)" || exit 0
    [[ -f "$file" ]] || { notify "⚠ File not found" normal "$file"; exit 0; }

    local name
    name="$(basename "$file")"
    name="${name%.ovpn}"; name="${name%.conf}"
    if nmcli connection import type openvpn file "$file" >/dev/null 2>&1 \
       || nmcli connection import type wireguard file "$file" >/dev/null 2>&1; then
        notify "➕ VPN imported" low "$name"
        log "imported $file as $name"
    else
        notify "⚠ Import failed" critical "$file"
    fi
}

# ── rofi callback loop ───────────────────────────────────────────────────────
retv="${ROFI_RETV:-0}"
case "$retv" in
    10) import_profile; exit 0 ;;
    11) show_menu; exit 0 ;;
    12)
        active="$(active_vpn || true)"
        [[ -n "$active" ]] && disconnect_profile "$active"
        exit 0
        ;;
    1)
        selection="${1:-}"
        case "$selection" in
            *"No active tunnel"*) exit 0 ;;
            *"Import .ovpn"*)     import_profile; exit 0 ;;
            *"Refresh list"*)     show_menu; exit 0 ;;
            *"Disconnect "*)
                disconnect_profile "${selection#*Disconnect }"
                exit 0
                ;;
            *)
                profile="$(printf '%s' "$selection" | sed 's/^[^ ]*  //; s/ (connected)$//')"
                if [[ "$profile" == "$(active_vpn || true)" ]]; then
                    disconnect_profile "$profile"
                else
                    connect_profile "$profile"
                fi
                exit 0
                ;;
        esac
        ;;
esac

show_menu
