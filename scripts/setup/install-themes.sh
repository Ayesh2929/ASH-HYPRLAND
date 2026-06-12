#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — THEME INSTALLER                              ║
# ║           Install GTK themes, icon themes, and cursor themes               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/install-themes.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

install_pkg() {
    local pkg="$1"
    local optional="${2:-false}"

    if pacman -Q "${pkg}" &>/dev/null; then
        ok "${pkg} (already installed)"
        return 0
    fi

    info "Installing: ${pkg}"

    for helper in paru yay; do
        if command -v "${helper}" &>/dev/null; then
            if "${helper}" -S --needed --noconfirm "${pkg}" >> "${LOG_FILE}" 2>&1; then
                ok "${pkg}"
                return 0
            fi
        fi
    done

    sudo pacman -S --needed --noconfirm "${pkg}" >> "${LOG_FILE}" 2>&1 \
        && ok "${pkg}" \
        || {
            if [[ "${optional}" == "true" ]]; then
                warn "${pkg} (optional — skipped)"
            else
                warn "Failed: ${pkg}"
            fi
        }
}

apply_gtk_settings() {
    info "Applying GTK settings..."

    local settings=(
        "org.gnome.desktop.interface gtk-theme Catppuccin-Mocha-Standard-Mauve-Dark"
        "org.gnome.desktop.interface icon-theme Papirus-Dark"
        "org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice"
        "org.gnome.desktop.interface cursor-size 24"
        "org.gnome.desktop.interface font-name 'JetBrains Mono 11'"
        "org.gnome.desktop.interface document-font-name 'JetBrains Mono 11'"
        "org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'"
        "org.gnome.desktop.interface color-scheme prefer-dark"
        "org.gnome.desktop.interface enable-hot-corners false"
    )

    for setting in "${settings[@]}"; do
        local schema key value
        read -r schema key value <<< "${setting}"
        gsettings set "${schema}" "${key}" "${value}" 2>/dev/null \
            && true || warn "Could not set: ${key}"
    done

    ok "GTK settings applied"
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo "  🎨 Installing ASH Dotfiles themes..."
    echo ""

    # GTK themes
    echo "  GTK Themes:"
    install_pkg "catppuccin-gtk-theme-mocha"

    # Icon themes
    echo ""
    echo "  Icon Themes:"
    install_pkg "papirus-icon-theme"
    install_pkg "papirus-folders-catppuccin-git" "true"

    # Cursor themes
    echo ""
    echo "  Cursor Themes:"
    install_pkg "bibata-cursor-theme"
    install_pkg "catppuccin-cursors-mocha" "true"

    # Qt themes
    echo ""
    echo "  Qt Themes:"
    install_pkg "qt5ct"
    install_pkg "qt6ct"
    install_pkg "kvantum"
    install_pkg "kvantum-theme-catppuccin-git" "true"

    # Apply GTK settings
    echo ""
    apply_gtk_settings

    echo ""
    ok "Theme installation complete!"
    log "INFO" "Theme installation complete"
}

main "$@"