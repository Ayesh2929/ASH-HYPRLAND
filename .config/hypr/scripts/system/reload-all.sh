#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — RELOAD ALL MODULES                           ║
# ║           Hot-reload all Hyprland components without logout                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/reload.log"

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()      { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn()    { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }
section() { echo -e "\n  \033[1m\033[95m${1}\033[0m"; }

main() {
    local target="${1:-all}"

    mkdir -p "${CACHE_DIR}/logs"
    log "INFO" "Reload: ${target}"

    echo ""
    echo -e "  \033[1m\033[95m🔄 ASH Reload — ${target}\033[0m"
    echo ""

    case "${target}" in
        all | "")
            reload_hyprland
            reload_waybar
            reload_dunst
            reload_swaync
            reload_theme
            reload_gtk
            reload_cursor
            ;;
        hypr | hyprland)   reload_hyprland ;;
        waybar)             reload_waybar ;;
        dunst)              reload_dunst ;;
        swaync)             reload_swaync ;;
        theme)              reload_theme ;;
        gtk)                reload_gtk ;;
        cursor)             reload_cursor ;;
        *)
            echo "Usage: reload-all.sh [all|hypr|waybar|dunst|swaync|theme|gtk|cursor]"
            exit 1
            ;;
    esac

    echo ""
    ok "Reload complete!"
    log "INFO" "Reload complete: ${target}"

    # Send notification
    notify-send "🔄 ASH Reloaded" \
        "Configuration reloaded: ${target}" \
        --app-name="ASH" \
        --expire-time=2000 \
        2>/dev/null || true
}

reload_hyprland() {
    section "🖥️ Hyprland"
    info "Reloading Hyprland config..."
    if hyprctl reload 2>/dev/null; then
        ok "Hyprland config reloaded"
    else
        warn "Hyprland reload failed (not running?)"
    fi
}

reload_waybar() {
    section "📊 Waybar"
    info "Reloading Waybar..."

    # Try SIGUSR2 (reload CSS only — fast)
    if pkill -SIGUSR2 waybar 2>/dev/null; then
        sleep 0.3
        ok "Waybar CSS reloaded (SIGUSR2)"
        return 0
    fi

    # Full restart
    if pgrep -x waybar &>/dev/null; then
        pkill -x waybar 2>/dev/null || true
        sleep 0.5
    fi
    waybar &>/dev/null &
    disown
    sleep 0.8
    pgrep -x waybar &>/dev/null && ok "Waybar restarted" || warn "Waybar failed to start"
}

reload_dunst() {
    section "🔔 Dunst"
    info "Reloading Dunst..."

    pkill -x dunst 2>/dev/null || true
    sleep 0.3
    dunst &>/dev/null &
    disown
    sleep 0.3
    pgrep -x dunst &>/dev/null && ok "Dunst restarted" || warn "Dunst failed to start"
}

reload_swaync() {
    section "📱 SwayNC"
    info "Reloading SwayNC..."

    if command -v swaync-client &>/dev/null; then
        swaync-client --reload-config 2>/dev/null \
            && ok "SwayNC config reloaded" \
            || warn "SwayNC reload failed"
    else
        info "SwayNC not installed — skipping"
    fi
}

reload_theme() {
    section "🎨 Theme"
    info "Reapplying theme..."

    local engine="${HOME}/.config/hypr/scripts/theme/theme-engine.sh"
    if [[ -x "${engine}" ]]; then
        "${engine}" "" reapply &>/dev/null \
            && ok "Theme reapplied" \
            || warn "Theme reapply failed"
    else
        warn "Theme engine not found"
    fi
}

reload_gtk() {
    section "🎨 GTK"
    info "Applying GTK settings..."

    local theme="Catppuccin-Mocha-Standard-Mauve-Dark"
    local icons="Papirus-Dark"
    local cursor="Bibata-Modern-Ice"
    local font="JetBrains Mono 11"

    gsettings set org.gnome.desktop.interface gtk-theme       "${theme}"  2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme      "${icons}"  2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme    "${cursor}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size     24          2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name       "${font}"   2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme    "prefer-dark" 2>/dev/null || true

    ok "GTK settings applied"
}

reload_cursor() {
    section "🖱️ Cursor"
    info "Applying cursor theme..."

    hyprctl keyword cursor:theme "Bibata-Modern-Ice" 2>/dev/null || true
    hyprctl keyword cursor:size 24 2>/dev/null || true
    hyprctl setcursor "Bibata-Modern-Ice" 24 2>/dev/null \
        && ok "Cursor theme applied" \
        || warn "Cursor apply failed"
}

main "$@"