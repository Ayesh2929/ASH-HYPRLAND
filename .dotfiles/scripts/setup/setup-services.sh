#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SERVICE SETUP SCRIPT                         ║
# ║           Enable and configure all required systemd services               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/setup-services.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

main() {
    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo "  ⚙️  Setting up ASH Dotfiles services..."
    echo ""

    # ── System Services ───────────────────────────────────────────────────────
    echo "  System services:"

    local system_services=("NetworkManager" "bluetooth" "systemd-timesyncd")
    for svc in "${system_services[@]}"; do
        if systemctl is-available "${svc}" &>/dev/null; then
            sudo systemctl enable --now "${svc}" 2>/dev/null \
                && ok "${svc}" \
                || warn "${svc} failed"
        else
            warn "${svc} not available"
        fi
    done

    # ── User Services ─────────────────────────────────────────────────────────
    echo ""
    echo "  User services:"

    local user_services=("pipewire" "pipewire-pulse" "wireplumber")
    for svc in "${user_services[@]}"; do
        if systemctl --user is-available "${svc}" &>/dev/null; then
            systemctl --user enable --now "${svc}" 2>/dev/null \
                && ok "${svc} (user)" \
                || warn "${svc} (user) failed"
        else
            warn "${svc} not available"
        fi
    done

    # ── ASH User Services ─────────────────────────────────────────────────────
    echo ""
    echo "  ASH services:"

    local ash_services=("ash-clipboard" "ash-battery")
    local config_dir="${HOME}/.config/systemd/user"

    for svc in "${ash_services[@]}"; do
        if [[ -f "${config_dir}/${svc}.service" ]]; then
            systemctl --user enable "${svc}" 2>/dev/null \
                && ok "${svc}" \
                || warn "${svc} failed"
        else
            info "${svc} service not installed — skipping"
        fi
    done

    # ── XDG Portal ────────────────────────────────────────────────────────────
    echo ""
    info "Configuring XDG portal..."
    mkdir -p "${HOME}/.config/xdg-desktop-portal"
    cat > "${HOME}/.config/xdg-desktop-portal/hyprland-portals.conf" << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Settings=gtk
EOF
    ok "XDG portal configured"

    # ── DBus Update ───────────────────────────────────────────────────────────
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        info "Updating DBus environment..."
        dbus-update-activation-environment --systemd \
            WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE \
            2>/dev/null && ok "DBus environment updated"
    fi

    echo ""
    ok "Service setup complete!"
    log "INFO" "setup-services complete"
}

main "$@"