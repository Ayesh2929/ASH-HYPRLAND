#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FONT INSTALLER                               ║
# ║           Install all required and optional fonts                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/install-fonts.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

# Required fonts
readonly -a REQUIRED_FONTS=(
    "ttf-jetbrains-mono-nerd"
    "noto-fonts"
    "noto-fonts-emoji"
    "noto-fonts-extra"
)

# Optional fonts
readonly -a OPTIONAL_FONTS=(
    "ttf-font-awesome"
    "ttf-nerd-fonts-symbols"
    "apple-fonts"
    "ttf-opensans"
    "ttf-roboto"
    "ttf-fira-code"
    "ttf-cascadia-code"
)

install_font() {
    local font="$1"
    local required="${2:-required}"

    if fc-list 2>/dev/null | grep -qi "${font//ttf-/}" 2>/dev/null; then
        ok "${font} (already installed)"
        return 0
    fi

    info "Installing: ${font}"

    # Try paru, yay, then pacman
    local installed=false
    for helper in paru yay; do
        if command -v "${helper}" &>/dev/null; then
            if "${helper}" -S --needed --noconfirm "${font}" >> "${LOG_FILE}" 2>&1; then
                installed=true
                break
            fi
        fi
    done

    if [[ "${installed}" == "false" ]]; then
        if sudo pacman -S --needed --noconfirm "${font}" >> "${LOG_FILE}" 2>&1; then
            installed=true
        fi
    fi

    if [[ "${installed}" == "true" ]]; then
        ok "${font}"
    else
        if [[ "${required}" == "required" ]]; then
            warn "FAILED to install required font: ${font}"
        else
            warn "${font} (optional — skipped)"
        fi
    fi
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo "  🔤 Installing ASH Dotfiles fonts..."
    echo ""

    echo "  Required fonts:"
    for font in "${REQUIRED_FONTS[@]}"; do
        install_font "${font}" "required"
    done

    echo ""
    echo "  Optional fonts:"
    for font in "${OPTIONAL_FONTS[@]}"; do
        install_font "${font}" "optional"
    done

    # Refresh font cache
    info "Refreshing font cache..."
    fc-cache -fv >> "${LOG_FILE}" 2>&1 \
        && ok "Font cache refreshed" \
        || warn "Font cache refresh failed"

    echo ""
    ok "Font installation complete!"

    # Verify key font
    if fc-list | grep -qi "JetBrainsMono" 2>/dev/null; then
        ok "✓ JetBrainsMono Nerd Font — VERIFIED"
    else
        warn "JetBrainsMono Nerd Font not detected — icons may not display correctly"
    fi

    echo ""
    log "INFO" "Font installation complete"
}

main "$@"