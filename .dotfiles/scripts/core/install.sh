#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — CORE INSTALL HELPER                          ║
# ║           Called by main install.sh for modular installation               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/core-install.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

main() {
    local phase="${1:-all}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${phase}" in
        structure)
            bash "${DOTFILES_DIR}/scripts/setup/init-structure.sh"
            ;;
        fonts)
            bash "${DOTFILES_DIR}/scripts/setup/install-fonts.sh"
            ;;
        themes)
            bash "${DOTFILES_DIR}/scripts/setup/install-themes.sh"
            ;;
        services)
            bash "${DOTFILES_DIR}/scripts/setup/setup-services.sh"
            ;;
        symlinks)
            # Create CLI symlinks
            local bin_dir="${DOTFILES_DIR}/bin"
            local local_bin="${HOME}/.local/bin"
            mkdir -p "${local_bin}"

            for bin in "${bin_dir}"/ash*; do
                if [[ -f "${bin}" ]]; then
                    local name
                    name=$(basename "${bin}")
                    chmod +x "${bin}"
                    ln -sf "${bin}" "${local_bin}/${name}" 2>/dev/null \
                        && ok "Linked: ${name}" \
                        || warn "Could not link: ${name}"
                fi
            done
            ;;
        permissions)
            # Fix all script permissions
            find "${CONFIG_DIR}" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            find "${HOME}/.local/bin" -name "ash*" -exec chmod +x {} \; 2>/dev/null || true
            ok "Permissions fixed"
            ;;
        all)
            bash "${0}" structure
            bash "${0}" symlinks
            bash "${0}" permissions
            ;;
        *)
            echo "Usage: install.sh [structure|fonts|themes|services|symlinks|permissions|all]"
            exit 1
            ;;
    esac
}

main "$@"