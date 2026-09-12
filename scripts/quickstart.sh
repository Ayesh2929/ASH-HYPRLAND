#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH'S HYPRLAND DOTFILES v5.0 OMEGA — QUICKSTART                   ║
# ║           One-Command Setup Script                                           ║
# ║           Usage: bash <(curl -sSL https://raw.githubusercontent.com/...)    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly REPO_URL="https://github.com/Ayesh2929/ASH-HYPRLAND"
readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly BOLD='\033[1m'
readonly RESET='\033[0m'
readonly GREEN='\033[92m'
readonly CYAN='\033[96m'
readonly MAGENTA='\033[95m'
readonly YELLOW='\033[93m'
readonly RED='\033[91m'

print_quick_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << 'BANNER'
     █████╗ ███████╗██╗  ██╗    ██████╗  ██████╗ ████████╗███████╗
    ██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
    ███████║███████╗███████║    ██║  ██║██║   ██║   ██║   ███████╗
    ██╔══██║╚════██║██╔══██║    ██║  ██║██║   ██║   ██║   ╚════██║
    ██║  ██║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║   ███████║
    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝

              🚀 QUICKSTART — ASH HYPRLAND DOTFILES v5.0 OMEGA 🚀
BANNER
    echo -e "${RESET}"
}

log() { echo -e "  ${GREEN}✓${RESET} $*"; }
info() { echo -e "  ${CYAN}→${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
die() { echo -e "  ${RED}✗ FATAL:${RESET} $*" >&2; exit 1; }

check_requirements() {
    info "Checking requirements..."

    # Check OS
    [[ -f /etc/arch-release ]] || {
        warn "Not detected as Arch Linux"
        read -rp "  Continue anyway? [y/N]: " r
        [[ "${r,,}" == "y" ]] || exit 0
    }

    # Check not root
    [[ "${EUID}" -ne 0 ]] || die "Don't run as root!"

    # Check internet
    curl -s --max-time 5 https://github.com > /dev/null 2>&1 || die "No internet connection"

    log "Requirements met"
}

install_git() {
    if ! command -v git &>/dev/null; then
        info "Installing git..."
        sudo pacman -S --needed --noconfirm git base-devel \
            || die "Failed to install git"
        log "git installed"
    else
        log "git already installed"
    fi
}

clone_repo() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        info "Dotfiles already cloned — updating..."
        cd "${DOTFILES_DIR}" && git pull origin main
        log "Repository updated"
    else
        info "Cloning ASH dotfiles repository..."
        git clone --depth=1 "${REPO_URL}" "${DOTFILES_DIR}" \
            || die "Failed to clone repository"
        log "Repository cloned to ${DOTFILES_DIR}"
    fi
}

run_installer() {
    info "Running main installer..."
    chmod +x "${DOTFILES_DIR}/install.sh"
    exec bash "${DOTFILES_DIR}/install.sh" "$@"
}

main() {
    print_quick_banner

    echo -e "  ${CYAN}This will install ASH Hyprland Dotfiles v5.0 OMEGA${RESET}"
    echo -e "  ${CYAN}Repository: ${REPO_URL}${RESET}"
    echo -e "  ${CYAN}Target: ${DOTFILES_DIR}${RESET}"
    echo ""
    read -rp "  Continue? [Y/n]: " response
    [[ "${response,,}" != "n" ]] || exit 0

    check_requirements
    install_git
    clone_repo
    run_installer "$@"
}

main "$@"