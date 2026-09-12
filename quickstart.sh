#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v5.0 OMEGA — QUICKSTART                             ║
# ║           One-command setup: bash <(curl -sSL URL/quickstart.sh)           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly ASH_VERSION="5.0.0-omega"
readonly REPO_URL="https://github.com/Ayesh2929/ASH-HYPRLAND"
readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly INSTALL_LOG="/tmp/ash-quickstart.log"

# Colors
readonly R='\033[0m' B='\033[1m' G='\033[92m' Y='\033[93m'
readonly RED='\033[91m' C='\033[96m' M='\033[95m' DIM='\033[2m'

log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${INSTALL_LOG}" 2>/dev/null || true; }
info()   { echo -e "  ${C}→${R} $*"; log "INFO" "$*"; }
ok()     { echo -e "  ${G}✓${R} $*"; log "OK" "$*"; }
warn()   { echo -e "  ${Y}⚠${R} $*" >&2; log "WARN" "$*"; }
err()    { echo -e "  ${RED}✗${R} $*" >&2; log "ERROR" "$*"; }
die()    { err "$*"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 BANNER
# ═══════════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo -e "${M}${B}"
    cat << 'BANNER'
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║    █████╗ ███████╗██╗  ██╗    ██████╗  ██████╗ ████████╗███████╗ ║
    ║   ██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝ ║
    ║   ███████║███████╗███████║    ██║  ██║██║   ██║   ██║   ███████╗ ║
    ║   ██╔══██║╚════██║██╔══██║    ██║  ██║██║   ██║   ██║   ╚════██║ ║
    ║   ██║  ██║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║   ███████║ ║
    ║   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝ ║
    ║                                                                   ║
    ║        🚀 QUICKSTART — ASH HYPRLAND DOTFILES v5.0 OMEGA 🚀       ║
    ║                                                                   ║
    ║   ✨ Dynamic Themes  •  AI Color Gen  •  Music Reactive          ║
    ║   🎵 Health Score    •  Analytics     •  Smart Wallpapers        ║
    ║   🤖 2600+ Files      •  0 Known Bugs  •  Production Ready       ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ✅ REQUIREMENTS CHECK
# ═══════════════════════════════════════════════════════════════════════════════

check_requirements() {
    info "Checking requirements..."

    # Not root
    [[ "${EUID}" -ne 0 ]] || die "Don't run as root! Run as your regular user."

    # Arch-based OS
    if ! [[ -f /etc/arch-release ]]; then
        warn "Not detected as Arch Linux"
        read -rp "  Continue anyway? [y/N]: " r
        [[ "${r,,}" == "y" ]] || { info "Cancelled"; exit 0; }
    fi

    # Internet
    curl -s --max-time 5 https://github.com > /dev/null 2>&1 || \
        die "No internet connection"

    # Sudo
    sudo -n true 2>/dev/null || sudo true 2>/dev/null || \
        die "No sudo access"

    ok "Requirements met"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 SECURITY: Verify download
# ═══════════════════════════════════════════════════════════════════════════════

verify_download() {
    local file="$1"
    local expected_sha="${2:-}"

    if [[ -z "${expected_sha}" ]]; then
        return 0  # No checksum provided — skip
    fi

    local actual_sha
    actual_sha=$(sha256sum "${file}" | awk '{print $1}')

    if [[ "${actual_sha}" == "${expected_sha}" ]]; then
        ok "Checksum verified: ${actual_sha:0:16}..."
    else
        die "Checksum mismatch! Expected: ${expected_sha:0:16} Got: ${actual_sha:0:16}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 INSTALL GIT
# ═══════════════════════════════════════════════════════════════════════════════

install_git() {
    if command -v git &>/dev/null; then
        ok "git already installed: $(git --version)"
        return 0
    fi

    info "Installing git..."
    sudo pacman -S --needed --noconfirm git base-devel \
        >> "${INSTALL_LOG}" 2>&1 || die "Failed to install git"
    ok "git installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 CLONE REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════════

clone_repo() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        info "Repository already exists — updating..."
        cd "${DOTFILES_DIR}"

        # Stash local changes
        if ! git diff --quiet 2>/dev/null; then
            git stash push -m "quickstart-update" 2>/dev/null || true
        fi

        git pull origin main >> "${INSTALL_LOG}" 2>&1 \
            && ok "Repository updated" \
            || warn "Pull failed — using existing files"
        return 0
    fi

    info "Cloning ASH Dotfiles..."
    git clone \
        --depth=1 \
        --progress \
        "${REPO_URL}" \
        "${DOTFILES_DIR}" \
        >> "${INSTALL_LOG}" 2>&1 || die "Clone failed"

    ok "Repository cloned to: ${DOTFILES_DIR}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 RUN INSTALLER
# ═══════════════════════════════════════════════════════════════════════════════

run_installer() {
    local installer="${DOTFILES_DIR}/install.sh"

    if [[ ! -f "${installer}" ]]; then
        die "install.sh not found in ${DOTFILES_DIR}"
    fi

    chmod +x "${installer}"
    exec bash "${installer}" "$@"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    print_banner

    echo -e "  ${C}Repository:${R} ${REPO_URL}"
    echo -e "  ${C}Install to:${R} ${DOTFILES_DIR}"
    echo -e "  ${C}Log file:${R}   ${INSTALL_LOG}"
    echo ""
    echo -e "  ${Y}This will install ASH Dotfiles v${ASH_VERSION} on your system.${R}"
    echo ""

    read -rp "  Continue? [Y/n]: " response
    [[ "${response,,}" != "n" ]] || { info "Cancelled"; exit 0; }

    echo ""

    check_requirements
    install_git
    clone_repo

    echo ""
    info "Starting main installer..."
    echo ""

    run_installer "$@"
}

main "$@"