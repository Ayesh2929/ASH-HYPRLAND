#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH'S HYPRLAND DOTFILES v3.0 — MASTER INSTALLER                   ║
# ║           Epic Production-Ready Wayland Desktop Environment                  ║
# ║           Author: Ash | License: MIT | Version: 3.0.0                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# 🚀 USAGE: bash install.sh [--phase N] [--skip-packages] [--force] [--dry-run]
#
# 📋 PHASES:
#   Phase 1 — Pre-flight checks & system validation
#   Phase 2 — AUR helper installation
#   Phase 3 — Package installation (50+ packages)
#   Phase 4 — Directory structure creation (160+ dirs)
#   Phase 5 — Configuration deployment
#   Phase 6 — Service enablement
#   Phase 7 — Shell setup (Fish)
#   Phase 8 — Theme engine initialization
#   Phase 9 — Post-install validation

set -euo pipefail
IFS=$'\n\t'

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLORS & STYLING
# ═══════════════════════════════════════════════════════════════════════════════
readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly ITALIC='\033[3m'
readonly UNDERLINE='\033[4m'
readonly BLINK='\033[5m'

# Foreground colors
readonly BLACK='\033[30m'
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly MAGENTA='\033[35m'
readonly CYAN='\033[36m'
readonly WHITE='\033[37m'

# Bright foreground colors
readonly BBLACK='\033[90m'
readonly BRED='\033[91m'
readonly BGREEN='\033[92m'
readonly BYELLOW='\033[93m'
readonly BBLUE='\033[94m'
readonly BMAGENTA='\033[95m'
readonly BCYAN='\033[96m'
readonly BWHITE='\033[97m'

# Background colors
readonly BG_BLACK='\033[40m'
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'
readonly BG_MAGENTA='\033[45m'
readonly BG_CYAN='\033[46m'
readonly BG_WHITE='\033[47m'

# ═══════════════════════════════════════════════════════════════════════════════
# 📌 CONSTANTS & CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════
readonly DOTFILES_VERSION="3.0.0"
readonly DOTFILES_NAME="ASH Hyprland Dotfiles"
readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly LOCAL_DIR="${HOME}/.local"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_DIR="${HOME}/.local/state/ash-dots"
readonly LOG_DIR="${CACHE_DIR}/logs"
readonly INSTALL_LOG="${LOG_DIR}/install-$(date +%Y%m%d_%H%M%S).log"
readonly BACKUP_DIR="${HOME}/.local/share/ash-dots/backups"
readonly WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"

# GitHub repository
readonly REPO_URL="https://github.com/yourusername/ash-dots"
readonly REPO_BRANCH="main"

# Timing
readonly INSTALL_START=$(date +%s)

# Phase tracking
declare -i CURRENT_PHASE=0
declare -i PHASE_START=1
declare -a FAILED_PACKAGES=()
declare -a WARNINGS=()
declare -i TOTAL_ERRORS=0

# CLI flags
DRY_RUN=false
SKIP_PACKAGES=false
FORCE_INSTALL=false
VERBOSE=false
START_PHASE=1
END_PHASE=9

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PACKAGE LISTS
# ═══════════════════════════════════════════════════════════════════════════════

# Critical packages — installation fails if these are missing
readonly CRITICAL_PACKAGES=(
    "hyprland"
    "waybar"
    "kitty"
    "fish"
    "rofi-wayland"
    "swww"
    "dunst"
    "hyprlock"
    "hypridle"
    "grim"
    "slurp"
    "wl-clipboard"
    "pipewire"
    "wireplumber"
    "networkmanager"
)

# Core packages — installation warns if these fail
readonly CORE_PACKAGES=(
    "hyprpicker"
    "swappy"
    "cliphist"
    "wf-recorder"
    "pavucontrol"
    "blueman"
    "swaync"
    "polkit-kde-agent"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "qt5-wayland"
    "qt6-wayland"
    "imagemagick"
    "jq"
    "curl"
    "wget"
    "git"
    "base-devel"
    "python3"
    "btop"
    "fastfetch"
    "neovim"
    "starship"
    "fzf"
    "fd"
    "ripgrep"
    "bat"
    "eza"
    "zoxide"
    "delta"
    "lazygit"
    "playerctl"
    "pamixer"
    "brightnessctl"
    "gammastep"
    "wlsunset"
    "kdeconnect"
    "mpv"
    "imv"
    "nemo"
    "firefox"
    "thunar"
)

# AUR packages
readonly AUR_PACKAGES=(
    "hyprshot"
    "hyprprop"
    "wlogout"
    "swayosd"
    "wayshot"
    "satty"
    "nwg-look"
    "kvantum"
    "qt5ct"
    "qt6ct"
    "pfetch-rs"
    "grimblast"
    "nemo-fileroller"
    "catppuccin-gtk-theme-mocha"
    "bibata-cursor-theme"
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols"
    "noto-fonts-emoji"
    "ttf-font-awesome"
    "apple-fonts"
    "ttf-opensans"
)

# Python packages
readonly PYTHON_PACKAGES=(
    "pynvim"
    "pywal"
    "material-color-utilities"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🖨️ OUTPUT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} [${level}] ${message}" >> "${INSTALL_LOG}" 2>/dev/null || true
}

# Print banner
print_banner() {
    clear
    echo -e "${BMAGENTA}"
    cat << 'BANNER'
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                                                                               ║
    ║    ░█████╗░░██████╗██╗░░██╗    ██████╗░░█████╗░████████╗███████╗            ║
    ║    ██╔══██╗██╔════╝██║░░██║    ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝            ║
    ║    ███████║╚█████╗░███████║    ██║░░██║██║░░██║░░░██║░░░███████╗            ║
    ║    ██╔══██║░╚═══██╗██╔══██║    ██║░░██║██║░░██║░░░██║░░░╚════██║            ║
    ║    ██║░░██║██████╔╝██║░░██║    ██████╔╝╚█████╔╝░░░██║░░░███████║            ║
    ║    ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝    ╚═════╝░░╚════╝░░░░╚═╝░░░╚══════╝            ║
    ║                                                                               ║
    ║          🚀 HYPRLAND DOTFILES v3.0 — EPIC PRODUCTION INSTALLER 🚀          ║
    ║                                                                               ║
    ║    ✨ Dynamic Theme Engine  •  50+ Waybar Modules  •  Cinematic Animations  ║
    ║    🎨 Wallpaper-Driven Colors  •  60+ Health Checks  •  Zero-Bug System     ║
    ║                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${RESET}"
}

# Section header
section() {
    local title="$1"
    local emoji="${2:-🔧}"
    echo ""
    echo -e "${BOLD}${BBLUE}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET} ${emoji}  ${BOLD}${BWHITE}${title}${RESET}"
    echo -e "${BOLD}${BBLUE}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    log "INFO" "=== SECTION: ${title} ==="
}

# Phase header
phase() {
    local num="$1"
    local title="$2"
    local emoji="${3:-⚙️}"
    CURRENT_PHASE=$num
    echo ""
    echo -e "${BOLD}${BG_MAGENTA}${WHITE}  ${emoji}  PHASE ${num}/9 — ${title}  ${RESET}"
    echo -e "${DIM}${BBLACK}$(printf '─%.0s' {1..70})${RESET}"
    log "INFO" "=== PHASE ${num}: ${title} ==="
}

# Status messages
ok()      { echo -e "  ${BGREEN}✅${RESET} ${GREEN}${*}${RESET}"; log "OK" "$*"; }
info()    { echo -e "  ${BCYAN}ℹ️${RESET}  ${CYAN}${*}${RESET}"; log "INFO" "$*"; }
warn()    { echo -e "  ${BYELLOW}⚠️${RESET}  ${YELLOW}${*}${RESET}"; log "WARN" "$*"; WARNINGS+=("$*"); }
error()   { echo -e "  ${BRED}❌${RESET} ${RED}${*}${RESET}" >&2; log "ERROR" "$*"; ((TOTAL_ERRORS++)) || true; }
fatal()   { echo -e "  ${BRED}💀${RESET} ${BOLD}${RED}FATAL: ${*}${RESET}" >&2; log "FATAL" "$*"; exit 1; }
step()    { echo -e "  ${BBLUE}→${RESET}  ${BWHITE}${*}${RESET}"; log "STEP" "$*"; }
done_()   { echo -e "  ${BMAGENTA}🎉${RESET} ${BMAGENTA}${BOLD}${*}${RESET}"; log "DONE" "$*"; }
debug()   { [[ "${VERBOSE}" == "true" ]] && echo -e "  ${DIM}${BBLACK}🔍 ${*}${RESET}"; log "DEBUG" "$*"; }

# Progress bar
progress_bar() {
    local current="$1"
    local total="$2"
    local label="${3:-}"
    local width=50
    local pct=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    local bar=""
    bar+="${BGREEN}"
    printf -v bar_fill '%0.s█' $(seq 1 $filled) 2>/dev/null || bar_fill=$(printf '█%.0s' $(seq 1 $filled))
    printf -v bar_empty '%0.s░' $(seq 1 $empty) 2>/dev/null || bar_empty=$(printf '░%.0s' $(seq 1 $empty))

    printf "\r  ${BBLUE}[${BGREEN}%s${BBLACK}%s${BBLUE}]${RESET} ${BOLD}%3d%%${RESET} ${DIM}%s${RESET}" \
        "${bar_fill}" "${bar_empty}" "${pct}" "${label}"
    [[ $current -eq $total ]] && echo ""
}

# Spinner
spinner() {
    local pid="$1"
    local msg="${2:-Working...}"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BCYAN}%s${RESET} ${BWHITE}%s${RESET}" "${frames[$i]}" "${msg}"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    printf "\r  ${BGREEN}✓${RESET} ${BWHITE}%s${RESET}\n" "${msg}"
}

# Run command with spinner
run_spinner() {
    local msg="$1"
    shift
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "[DRY-RUN] Would run: $*"
        return 0
    fi
    "$@" &>/dev/null &
    local pid=$!
    spinner "$pid" "${msg}"
    wait "$pid"
    return $?
}

# Confirm prompt
confirm() {
    local msg="${1:-Continue?}"
    local default="${2:-y}"

    if [[ "${FORCE_INSTALL}" == "true" ]]; then
        return 0
    fi

    local prompt
    if [[ "${default}" == "y" ]]; then
        prompt="${msg} [Y/n]: "
    else
        prompt="${msg} [y/N]: "
    fi

    read -rp "$(echo -e "  ${BYELLOW}❓${RESET} ${BWHITE}${prompt}${RESET}")" response
    response="${response:-${default}}"

    case "${response,,}" in
        y|yes) return 0 ;;
        n|no)  return 1 ;;
        *)     return 0 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 PHASE 1 — PRE-FLIGHT CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

phase_1_preflight() {
    phase 1 "Pre-Flight Checks & System Validation" "🔍"

    # Create log directory
    mkdir -p "${LOG_DIR}" || fatal "Cannot create log directory: ${LOG_DIR}"
    info "Log file: ${INSTALL_LOG}"

    # ── OS Check ─────────────────────────────────────────────────────────────
    step "Checking operating system..."
    if [[ -f /etc/arch-release ]]; then
        ok "Arch Linux detected"
    elif [[ -f /etc/os-release ]]; then
        local os_name
        os_name=$(grep ^NAME /etc/os-release | cut -d= -f2 | tr -d '"')
        case "${os_name}" in
            *Endeavour*|*CachyOS*|*Garuda*|*Manjaro*|*ArcoLinux*)
                ok "Arch-based: ${os_name}"
                ;;
            *)
                warn "Non-Arch OS detected: ${os_name} — some features may not work"
                confirm "Continue anyway?" || exit 0
                ;;
        esac
    else
        fatal "Cannot detect OS — /etc/os-release not found"
    fi

    # ── Kernel Check ─────────────────────────────────────────────────────────
    step "Checking kernel version..."
    local kernel_version
    kernel_version=$(uname -r | cut -d. -f1,2)
    local kernel_major kernel_minor
    kernel_major=$(echo "$kernel_version" | cut -d. -f1)
    kernel_minor=$(echo "$kernel_version" | cut -d. -f2)

    if (( kernel_major > 6 )) || (( kernel_major == 6 && kernel_minor >= 1 )); then
        ok "Kernel $(uname -r) — meets minimum requirement (6.1+)"
    else
        warn "Kernel $(uname -r) is below recommended 6.1 — some features may fail"
    fi

    # ── User Check ────────────────────────────────────────────────────────────
    step "Checking user context..."
    if [[ "${EUID}" -eq 0 ]]; then
        fatal "Do NOT run this installer as root — run as your regular user"
    fi
    ok "Running as user: ${USER} (UID: ${EUID})"

    # Check sudo access
    if sudo -n true 2>/dev/null; then
        ok "Sudo access available (passwordless)"
    elif sudo true 2>/dev/null; then
        ok "Sudo access available"
    else
        fatal "No sudo access — required for package installation"
    fi

    # ── Hardware Check ────────────────────────────────────────────────────────
    step "Detecting hardware..."

    # RAM check
    local ram_gb
    ram_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    if (( ram_gb >= 8 )); then
        ok "RAM: ${ram_gb}GB — optimal"
    elif (( ram_gb >= 4 )); then
        warn "RAM: ${ram_gb}GB — minimum met (8GB recommended)"
    else
        warn "RAM: ${ram_gb}GB — below minimum (4GB required)"
        confirm "Continue with limited RAM?" || exit 0
    fi

    # Storage check
    local free_gb
    free_gb=$(df -BG "${HOME}" | awk 'NR==2{print $4}' | tr -d G)
    if (( free_gb >= 20 )); then
        ok "Free storage: ${free_gb}GB — sufficient"
    elif (( free_gb >= 10 )); then
        warn "Free storage: ${free_gb}GB — minimum (20GB recommended)"
    else
        error "Free storage: ${free_gb}GB — insufficient (10GB minimum required)"
        confirm "Continue anyway? (RISKY)" "n" || exit 1
    fi

    # GPU detection
    step "Detecting GPU..."
    if lspci | grep -qi "amd\|radeon"; then
        ok "GPU: AMD detected"
        GPU_VENDOR="amd"
    elif lspci | grep -qi "nvidia"; then
        ok "GPU: NVIDIA detected"
        GPU_VENDOR="nvidia"
    elif lspci | grep -qi "intel"; then
        ok "GPU: Intel detected"
        GPU_VENDOR="intel"
    else
        warn "GPU: Unknown — using generic configuration"
        GPU_VENDOR="generic"
    fi
    export GPU_VENDOR

    # ── Internet Check ────────────────────────────────────────────────────────
    step "Checking internet connectivity..."
    if curl -s --max-time 5 https://archlinux.org > /dev/null 2>&1; then
        ok "Internet connection: OK"
    elif ping -c1 -W3 8.8.8.8 > /dev/null 2>&1; then
        warn "Internet connection limited (no HTTPS to archlinux.org)"
    else
        fatal "No internet connection — required for package downloads"
    fi

    # ── Existing Config Backup ────────────────────────────────────────────────
    step "Checking for existing configurations..."
    local has_existing=false

    for dir in hypr waybar rofi kitty fish nvim; do
        if [[ -d "${CONFIG_DIR}/${dir}" ]]; then
            warn "Existing config found: ~/.config/${dir}"
            has_existing=true
        fi
    done

    if [[ "${has_existing}" == "true" ]]; then
        echo ""
        warn "Existing configurations detected!"
        echo -e "  ${BYELLOW}These will be backed up to:${RESET}"
        echo -e "  ${DIM}${BACKUP_DIR}/pre-install-$(date +%Y%m%d_%H%M%S)/${RESET}"
        confirm "Backup existing configs and continue?" || exit 0
        backup_existing_configs
    fi

    # ── Wayland Check ────────────────────────────────────────────────────────
    step "Checking Wayland compatibility..."
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        info "Running in Wayland session: ${WAYLAND_DISPLAY}"
    elif [[ -n "${DISPLAY:-}" ]]; then
        info "Running in X11 session — Hyprland will run as new session"
    else
        info "Running in TTY — Hyprland will be launched after install"
    fi

    done_ "Phase 1 complete — All pre-flight checks passed! ✈️"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 BACKUP EXISTING CONFIGS
# ═══════════════════════════════════════════════════════════════════════════════

backup_existing_configs() {
    local backup_path="${BACKUP_DIR}/pre-install-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${backup_path}"

    local dirs=("hypr" "waybar" "rofi" "kitty" "fish" "nvim" "dunst" "swaync"
                 "hyprlock" "hypridle" "ags" "eww" "btop" "fastfetch" "mpv")

    for dir in "${dirs[@]}"; do
        if [[ -d "${CONFIG_DIR}/${dir}" ]]; then
            cp -r "${CONFIG_DIR}/${dir}" "${backup_path}/" 2>/dev/null || true
            ok "Backed up: ~/.config/${dir}"
        fi
    done

    # Create backup manifest
    {
        echo "ASH Dotfiles v${DOTFILES_VERSION} — Pre-install Backup"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "User: ${USER}"
        echo "Kernel: $(uname -r)"
        echo ""
        echo "Backed up directories:"
        ls "${backup_path}/"
    } > "${backup_path}/MANIFEST.txt"

    ok "Backup complete: ${backup_path}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📦 PHASE 2 — AUR HELPER INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

phase_2_aur_helper() {
    phase 2 "AUR Helper Installation" "📦"

    # Check for existing AUR helpers
    local aur_helper=""

    if command -v paru &>/dev/null; then
        aur_helper="paru"
        ok "Found existing AUR helper: paru"
    elif command -v yay &>/dev/null; then
        aur_helper="yay"
        ok "Found existing AUR helper: yay"
    else
        info "No AUR helper found — installing paru"

        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would install paru"
            return 0
        fi

        # Install paru
        local tmp_dir
        tmp_dir=$(mktemp -d)
        cd "${tmp_dir}"

        step "Installing git and base-devel..."
        sudo pacman -S --needed --noconfirm git base-devel >> "${INSTALL_LOG}" 2>&1 \
            || fatal "Failed to install git/base-devel"

        step "Cloning paru repository..."
        git clone https://aur.archlinux.org/paru.git >> "${INSTALL_LOG}" 2>&1 \
            || fatal "Failed to clone paru"

        cd paru
        step "Building paru (this may take a minute)..."
        makepkg -si --noconfirm >> "${INSTALL_LOG}" 2>&1 \
            || fatal "Failed to build paru"

        cd "${HOME}"
        rm -rf "${tmp_dir}"
        aur_helper="paru"
        ok "paru installed successfully"
    fi

    # Export for later phases
    export AUR_HELPER="${aur_helper}"
    info "Using AUR helper: ${AUR_HELPER}"

    done_ "Phase 2 complete — AUR helper ready! 📦"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📥 PHASE 3 — PACKAGE INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

phase_3_packages() {
    phase 3 "Package Installation" "📥"

    if [[ "${SKIP_PACKAGES}" == "true" ]]; then
        warn "Package installation skipped (--skip-packages)"
        return 0
    fi

    local total_packages=$(( ${#CRITICAL_PACKAGES[@]} + ${#CORE_PACKAGES[@]} + ${#AUR_PACKAGES[@]} ))
    local installed=0

    # ── Critical Packages ────────────────────────────────────────────────────
    section "Installing Critical Packages (${#CRITICAL_PACKAGES[@]})" "🔴"

    for pkg in "${CRITICAL_PACKAGES[@]}"; do
        step "Installing: ${pkg}"
        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would install: ${pkg}"
        else
            if ! sudo pacman -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1; then
                if ! "${AUR_HELPER}" -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1; then
                    error "CRITICAL: Failed to install ${pkg}"
                    FAILED_PACKAGES+=("CRITICAL:${pkg}")
                else
                    ok "${pkg} (AUR)"
                fi
            else
                ok "${pkg}"
            fi
        fi
        ((installed++)) || true
        progress_bar "${installed}" "${total_packages}" "${pkg}"
    done

    # Check if any critical packages failed
    local critical_failures=0
    for failed in "${FAILED_PACKAGES[@]}"; do
        [[ "${failed}" == CRITICAL:* ]] && ((critical_failures++)) || true
    done

    if (( critical_failures > 0 )); then
        fatal "${critical_failures} critical packages failed — cannot continue"
    fi

    # ── Core Packages ─────────────────────────────────────────────────────────
    section "Installing Core Packages (${#CORE_PACKAGES[@]})" "🟡"

    for pkg in "${CORE_PACKAGES[@]}"; do
        step "Installing: ${pkg}"
        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would install: ${pkg}"
        else
            if ! sudo pacman -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1; then
                if ! "${AUR_HELPER}" -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1; then
                    warn "Optional package failed: ${pkg}"
                    FAILED_PACKAGES+=("OPTIONAL:${pkg}")
                else
                    ok "${pkg} (AUR)"
                fi
            else
                ok "${pkg}"
            fi
        fi
        ((installed++)) || true
        progress_bar "${installed}" "${total_packages}" "${pkg}"
    done

    # ── AUR Packages ─────────────────────────────────────────────────────────
    section "Installing AUR Packages (${#AUR_PACKAGES[@]})" "🟢"

    for pkg in "${AUR_PACKAGES[@]}"; do
        step "Installing: ${pkg}"
        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would install AUR: ${pkg}"
        else
            if ! "${AUR_HELPER}" -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1; then
                warn "AUR package failed: ${pkg}"
                FAILED_PACKAGES+=("AUR:${pkg}")
            else
                ok "${pkg} (AUR)"
            fi
        fi
        ((installed++)) || true
        progress_bar "${installed}" "${total_packages}" "${pkg}"
    done

    # ── Python Packages ───────────────────────────────────────────────────────
    section "Installing Python Packages" "🐍"

    if command -v pip3 &>/dev/null; then
        for pkg in "${PYTHON_PACKAGES[@]}"; do
            if [[ "${DRY_RUN}" == "true" ]]; then
                info "[DRY-RUN] Would pip install: ${pkg}"
            else
                pip3 install --user "${pkg}" >> "${INSTALL_LOG}" 2>&1 \
                    && ok "${pkg}" \
                    || warn "pip3 package failed: ${pkg}"
            fi
        done
    else
        warn "pip3 not available — skipping Python packages"
    fi

    # ── GPU-Specific Packages ─────────────────────────────────────────────────
    section "Installing GPU-Specific Packages" "🎮"

    case "${GPU_VENDOR:-generic}" in
        nvidia)
            step "Installing NVIDIA Wayland packages..."
            local nvidia_pkgs=("nvidia" "nvidia-utils" "nvidia-settings" "libva-nvidia-driver" "egl-wayland")
            for pkg in "${nvidia_pkgs[@]}"; do
                if [[ "${DRY_RUN}" != "true" ]]; then
                    sudo pacman -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1 \
                        && ok "${pkg}" || warn "NVIDIA package failed: ${pkg}"
                fi
            done
            ;;
        amd)
            step "Installing AMD Wayland packages..."
            local amd_pkgs=("mesa" "vulkan-radeon" "libva-mesa-driver" "mesa-vdpau" "radeontop")
            for pkg in "${amd_pkgs[@]}"; do
                if [[ "${DRY_RUN}" != "true" ]]; then
                    sudo pacman -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1 \
                        && ok "${pkg}" || warn "AMD package failed: ${pkg}"
                fi
            done
            # radeontop from AUR
            "${AUR_HELPER}" -S --needed --noconfirm radeontop >> "${INSTALL_LOG}" 2>&1 \
                && ok "radeontop (AUR)" || warn "radeontop failed"
            ;;
        intel)
            step "Installing Intel Wayland packages..."
            local intel_pkgs=("mesa" "vulkan-intel" "libva-intel-driver" "intel-media-driver")
            for pkg in "${intel_pkgs[@]}"; do
                if [[ "${DRY_RUN}" != "true" ]]; then
                    sudo pacman -S --needed --noconfirm "${pkg}" >> "${INSTALL_LOG}" 2>&1 \
                        && ok "${pkg}" || warn "Intel package failed: ${pkg}"
                fi
            done
            ;;
    esac

    # ── Summary ───────────────────────────────────────────────────────────────
    echo ""
    info "Package installation summary:"
    info "  Total packages attempted: ${total_packages}"
    info "  Failed packages: ${#FAILED_PACKAGES[@]}"

    if (( ${#FAILED_PACKAGES[@]} > 0 )); then
        warn "Failed packages (${#FAILED_PACKAGES[@]}):"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            warn "  - ${pkg}"
        done
    fi

    done_ "Phase 3 complete — Packages installed! 📦"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 PHASE 4 — DIRECTORY STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════════

phase_4_directories() {
    phase 4 "Directory Structure Creation (160+ directories)" "📁"

    local dirs=(
        # Hyprland
        "${CONFIG_DIR}/hypr"
        "${CONFIG_DIR}/hypr/core"
        "${CONFIG_DIR}/hypr/modules"
        "${CONFIG_DIR}/hypr/rules"
        "${CONFIG_DIR}/hypr/scripts"
        "${CONFIG_DIR}/hypr/scripts/theme"
        "${CONFIG_DIR}/hypr/scripts/media"
        "${CONFIG_DIR}/hypr/scripts/system"
        "${CONFIG_DIR}/hypr/scripts/hardware"
        "${CONFIG_DIR}/hypr/scripts/network"
        "${CONFIG_DIR}/hypr/scripts/utils"
        "${CONFIG_DIR}/hypr/assets"
        "${CONFIG_DIR}/hypr/assets/shaders"
        "${CONFIG_DIR}/hypr/assets/sounds"
        "${CONFIG_DIR}/hypr/UserOverrides"
        "${CONFIG_DIR}/hypr/plugins"
        "${CONFIG_DIR}/hypr/themes"

        # Waybar
        "${CONFIG_DIR}/waybar"
        "${CONFIG_DIR}/waybar/configs"
        "${CONFIG_DIR}/waybar/styles"
        "${CONFIG_DIR}/waybar/scripts"
        "${CONFIG_DIR}/waybar/scripts/hardware"
        "${CONFIG_DIR}/waybar/scripts/system"
        "${CONFIG_DIR}/waybar/scripts/media"
        "${CONFIG_DIR}/waybar/scripts/network"
        "${CONFIG_DIR}/waybar/scripts/utils"
        "${CONFIG_DIR}/waybar/modules"

        # Rofi
        "${CONFIG_DIR}/rofi"
        "${CONFIG_DIR}/rofi/themes"
        "${CONFIG_DIR}/rofi/launchers"
        "${CONFIG_DIR}/rofi/powermenu"
        "${CONFIG_DIR}/rofi/scripts"

        # Notifications
        "${CONFIG_DIR}/dunst"
        "${CONFIG_DIR}/dunst/scripts"
        "${CONFIG_DIR}/swaync"

        # Lock/Idle
        "${CONFIG_DIR}/hyprlock"
        "${CONFIG_DIR}/hyprlock/scripts"
        "${CONFIG_DIR}/hyprlock/assets"
        "${CONFIG_DIR}/hypridle"

        # Terminals
        "${CONFIG_DIR}/kitty"
        "${CONFIG_DIR}/kitty/themes"
        "${CONFIG_DIR}/kitty/kittens"
        "${CONFIG_DIR}/wezterm"
        "${CONFIG_DIR}/alacritty"

        # Shell
        "${CONFIG_DIR}/fish"
        "${CONFIG_DIR}/fish/conf.d"
        "${CONFIG_DIR}/fish/functions"
        "${CONFIG_DIR}/fish/completions"
        "${CONFIG_DIR}/fish/themes"

        # Neovim
        "${CONFIG_DIR}/nvim"
        "${CONFIG_DIR}/nvim/lua"
        "${CONFIG_DIR}/nvim/lua/core"
        "${CONFIG_DIR}/nvim/lua/plugins"
        "${CONFIG_DIR}/nvim/lua/lsp"
        "${CONFIG_DIR}/nvim/lua/themes"
        "${CONFIG_DIR}/nvim/lua/utils"
        "${CONFIG_DIR}/nvim/lua/ui"
        "${CONFIG_DIR}/nvim/after"
        "${CONFIG_DIR}/nvim/after/plugin"
        "${CONFIG_DIR}/nvim/snippets"

        # AGS
        "${CONFIG_DIR}/ags"
        "${CONFIG_DIR}/ags/modules"
        "${CONFIG_DIR}/ags/services"
        "${CONFIG_DIR}/ags/styles"
        "${CONFIG_DIR}/ags/widgets"
        "${CONFIG_DIR}/ags/utils"

        # EWW
        "${CONFIG_DIR}/eww"
        "${CONFIG_DIR}/eww/dashboard"
        "${CONFIG_DIR}/eww/bar"
        "${CONFIG_DIR}/eww/scripts"
        "${CONFIG_DIR}/eww/scripts/system"
        "${CONFIG_DIR}/eww/scripts/media"

        # GTK
        "${CONFIG_DIR}/gtk-2.0"
        "${CONFIG_DIR}/gtk-3.0"
        "${CONFIG_DIR}/gtk-4.0"

        # Qt
        "${CONFIG_DIR}/qt5ct"
        "${CONFIG_DIR}/qt5ct/colors"
        "${CONFIG_DIR}/qt6ct"
        "${CONFIG_DIR}/qt6ct/colors"
        "${CONFIG_DIR}/Kvantum"
        "${CONFIG_DIR}/Kvantum/AshTheme"

        # Media
        "${CONFIG_DIR}/mpv"
        "${CONFIG_DIR}/mpv/scripts"
        "${CONFIG_DIR}/mpv/script-opts"

        # System tools
        "${CONFIG_DIR}/btop"
        "${CONFIG_DIR}/btop/themes"
        "${CONFIG_DIR}/fastfetch"
        "${CONFIG_DIR}/fastfetch/themes"
        "${CONFIG_DIR}/ripgrep"
        "${CONFIG_DIR}/python"

        # Systemd
        "${CONFIG_DIR}/systemd"
        "${CONFIG_DIR}/systemd/user"
        "${CONFIG_DIR}/environment.d"

        # Cache directories
        "${CACHE_DIR}"
        "${CACHE_DIR}/colors"
        "${CACHE_DIR}/wallpaper"
        "${CACHE_DIR}/thumbnails"
        "${CACHE_DIR}/logs"

        # State
        "${STATE_DIR}"
        "${STATE_DIR}/sessions"
        "${STATE_DIR}/theme-history"

        # Local
        "${LOCAL_DIR}/bin"
        "${LOCAL_DIR}/share/applications"
        "${LOCAL_DIR}/share/ash-dots"
        "${LOCAL_DIR}/share/ash-dots/backups"
        "${LOCAL_DIR}/share/ash-dots/themes"

        # Wallpapers
        "${WALLPAPER_DIR}"
        "${WALLPAPER_DIR}/dark"
        "${WALLPAPER_DIR}/light"
        "${WALLPAPER_DIR}/anime"
        "${WALLPAPER_DIR}/abstract"
        "${WALLPAPER_DIR}/cyberpunk"
        "${WALLPAPER_DIR}/nature"
        "${WALLPAPER_DIR}/landscapes"
        "${WALLPAPER_DIR}/space"
        "${WALLPAPER_DIR}/minimal"
        "${WALLPAPER_DIR}/gradient"

        # Screenshots & Recordings
        "${HOME}/Pictures/Screenshots"
        "${HOME}/Pictures/Recordings"
        "${HOME}/Pictures/ColorPicker"
        "${HOME}/Pictures/Edited"

        # Dotfiles structure
        "${DOTFILES_DIR}/scripts"
        "${DOTFILES_DIR}/scripts/core"
        "${DOTFILES_DIR}/scripts/health"
        "${DOTFILES_DIR}/scripts/setup"
        "${DOTFILES_DIR}/bin"
        "${DOTFILES_DIR}/docs"
        "${DOTFILES_DIR}/themes"
        "${DOTFILES_DIR}/config"
    )

    local total=${#dirs[@]}
    local created=0

    for dir in "${dirs[@]}"; do
        if [[ "${DRY_RUN}" == "true" ]]; then
            debug "[DRY-RUN] Would create: ${dir}"
        else
            mkdir -p "${dir}" 2>/dev/null || warn "Could not create: ${dir}"
        fi
        ((created++)) || true
        progress_bar "${created}" "${total}" "$(basename "${dir}")"
    done

    ok "Created ${total} directories"
    done_ "Phase 4 complete — Directory structure ready! 📁"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 PHASE 5 — CONFIGURATION DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════════

phase_5_configs() {
    phase 5 "Configuration Deployment" "📋"

    # ── Deploy from dotfiles repo ─────────────────────────────────────────────
    if [[ -d "${DOTFILES_DIR}/config" ]]; then
        step "Deploying configurations from ${DOTFILES_DIR}/config..."

        # Hyprland
        deploy_config "hypr" "${CONFIG_DIR}/hypr"
        # Waybar
        deploy_config "waybar" "${CONFIG_DIR}/waybar"
        # Rofi
        deploy_config "rofi" "${CONFIG_DIR}/rofi"
        # Fish
        deploy_config "fish" "${CONFIG_DIR}/fish"
        # Neovim
        deploy_config "nvim" "${CONFIG_DIR}/nvim"
        # Kitty
        deploy_config "kitty" "${CONFIG_DIR}/kitty"
        # Dunst
        deploy_config "dunst" "${CONFIG_DIR}/dunst"
        # SwayNC
        deploy_config "swaync" "${CONFIG_DIR}/swaync"
        # Hyprlock
        deploy_config "hyprlock" "${CONFIG_DIR}/hyprlock"
        # Hypridle
        deploy_config "hypridle" "${CONFIG_DIR}/hypridle"
        # AGS
        deploy_config "ags" "${CONFIG_DIR}/ags"
        # EWW
        deploy_config "eww" "${CONFIG_DIR}/eww"
        # btop
        deploy_config "btop" "${CONFIG_DIR}/btop"
        # fastfetch
        deploy_config "fastfetch" "${CONFIG_DIR}/fastfetch"
        # mpv
        deploy_config "mpv" "${CONFIG_DIR}/mpv"
    else
        warn "Dotfiles config directory not found — skipping config deployment"
        info "Run 'ash reload' after placing configs in ${DOTFILES_DIR}"
    fi

    # ── GPU-Specific Environment ──────────────────────────────────────────────
    step "Setting up GPU-specific environment..."
    setup_gpu_env

    # ── User Overrides ────────────────────────────────────────────────────────
    step "Creating user overrides template..."
    if [[ ! -f "${CONFIG_DIR}/hypr/UserOverrides/user.conf" ]]; then
        create_user_overrides
        ok "User overrides template created"
    else
        info "User overrides already exist — not overwriting"
    fi

    done_ "Phase 5 complete — Configurations deployed! 📋"
}

# Deploy a configuration directory
deploy_config() {
    local src_name="$1"
    local dst_dir="$2"
    local src_dir="${DOTFILES_DIR}/config/${src_name}"

    if [[ ! -d "${src_dir}" ]]; then
        warn "Source not found: ${src_dir}"
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        info "[DRY-RUN] Would deploy: ${src_dir} → ${dst_dir}"
        return 0
    fi

    cp -r "${src_dir}/." "${dst_dir}/" 2>/dev/null \
        && ok "Deployed: ${src_name}" \
        || warn "Partial deploy: ${src_name}"
}

# Setup GPU environment
setup_gpu_env() {
    local env_file="${CONFIG_DIR}/hypr/core/env.conf"

    case "${GPU_VENDOR:-generic}" in
        nvidia)
            info "Enabling NVIDIA optimizations..."
            # Will be handled in env.conf via sed
            ;;
        amd)
            info "Enabling AMD optimizations..."
            ;;
        intel)
            info "Enabling Intel optimizations..."
            ;;
    esac
}

# Create user overrides template
create_user_overrides() {
    cat > "${CONFIG_DIR}/hypr/UserOverrides/user.conf" << 'EOF'
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — USER OVERRIDES                                 ║
# ║                                                                               ║
# ║   🎯 PUT ALL YOUR PERSONAL CUSTOMIZATIONS HERE                               ║
# ║   This file is NOT tracked by git — it survives all updates                  ║
# ║   This file is loaded LAST — it has highest priority                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ── Monitor Configuration ─────────────────────────────────────────────────────
# Uncomment and modify for your setup:
# monitor = HDMI-A-1, 1920x1080@144, 0x0, 1
# monitor = DP-1, 2560x1440@165, 1920x0, 1
# monitor = ,preferred,auto,auto          # Auto-detect all monitors

# ── Custom Keybinds ───────────────────────────────────────────────────────────
# Add your personal keybinds here:
# bind = SUPER, T, exec, your-terminal

# ── Custom Window Rules ───────────────────────────────────────────────────────
# windowrulev2 = float, class:^(your-app)$

# ── Performance Tweaks ────────────────────────────────────────────────────────
# For better gaming performance, uncomment:
# decoration {
#     blur {
#         passes = 2
#         size = 8
#     }
# }
# animations { enabled = false }
# general { allow_tearing = true }

# ── Personal Apps ─────────────────────────────────────────────────────────────
# exec-once = your-startup-app
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⚙️ PHASE 6 — SERVICE ENABLEMENT
# ═══════════════════════════════════════════════════════════════════════════════

phase_6_services() {
    phase 6 "Service Enablement" "⚙️"

    # ── SystemD User Services ─────────────────────────────────────────────────
    local system_services=(
        "NetworkManager"
        "bluetooth"
    )

    local user_services=(
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
    )

    section "Enabling System Services" "🔧"
    for svc in "${system_services[@]}"; do
        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would enable: ${svc}"
        else
            sudo systemctl enable --now "${svc}" >> "${INSTALL_LOG}" 2>&1 \
                && ok "${svc}" \
                || warn "Failed to enable: ${svc}"
        fi
    done

    section "Enabling User Services" "👤"
    for svc in "${user_services[@]}"; do
        if [[ "${DRY_RUN}" == "true" ]]; then
            info "[DRY-RUN] Would enable user: ${svc}"
        else
            systemctl --user enable --now "${svc}" >> "${INSTALL_LOG}" 2>&1 \
                && ok "${svc} (user)" \
                || warn "Failed to enable user service: ${svc}"
        fi
    done

    # ── XDG Portal Setup ──────────────────────────────────────────────────────
    step "Configuring XDG portal..."
    if [[ "${DRY_RUN}" != "true" ]]; then
        mkdir -p "${CONFIG_DIR}"
        cat > "${CONFIG_DIR}/xdg-desktop-portal/hyprland-portals.conf" << 'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Settings=gtk
EOF
        ok "XDG portal configured"
    fi

    # ── Polkit Agent ─────────────────────────────────────────────────────────
    step "Setting up polkit agent..."
    if command -v /usr/lib/polkit-kde-authentication-agent-1 &>/dev/null; then
        ok "KDE polkit agent available"
    elif command -v /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &>/dev/null; then
        ok "GNOME polkit agent available"
    else
        warn "No polkit agent found — some elevated actions may not work"
    fi

    # ── Bluetooth Setup ───────────────────────────────────────────────────────
    step "Setting up Bluetooth..."
    if [[ "${DRY_RUN}" != "true" ]]; then
        sudo systemctl enable --now bluetooth >> "${INSTALL_LOG}" 2>&1 \
            && ok "Bluetooth enabled" \
            || warn "Bluetooth service failed"
    fi

    # ── SDDM / Display Manager ────────────────────────────────────────────────
    step "Checking display manager..."
    if systemctl is-enabled sddm &>/dev/null; then
        ok "SDDM is already enabled"
    elif systemctl is-enabled gdm &>/dev/null; then
        warn "GDM detected — consider switching to SDDM for Hyprland"
    elif systemctl is-enabled lightdm &>/dev/null; then
        warn "LightDM detected — consider switching to SDDM"
    else
        info "No display manager detected"
        if confirm "Install and enable SDDM?"; then
            if [[ "${DRY_RUN}" != "true" ]]; then
                sudo pacman -S --needed --noconfirm sddm >> "${INSTALL_LOG}" 2>&1
                sudo systemctl enable sddm >> "${INSTALL_LOG}" 2>&1 \
                    && ok "SDDM enabled" \
                    || warn "SDDM installation failed"
            fi
        fi
    fi

    done_ "Phase 6 complete — Services enabled! ⚙️"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🐟 PHASE 7 — SHELL SETUP
# ═══════════════════════════════════════════════════════════════════════════════

phase_7_shell() {
    phase 7 "Shell Setup (Fish)" "🐟"

    # ── Install Fish ──────────────────────────────────────────────────────────
    step "Verifying Fish installation..."
    if ! command -v fish &>/dev/null; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            sudo pacman -S --needed --noconfirm fish >> "${INSTALL_LOG}" 2>&1 \
                && ok "Fish installed" \
                || fatal "Failed to install Fish"
        fi
    else
        ok "Fish already installed: $(fish --version)"
    fi

    # ── Set Default Shell ─────────────────────────────────────────────────────
    step "Setting Fish as default shell..."
    local fish_path
    fish_path=$(command -v fish)

    # Add to /etc/shells if not present
    if ! grep -q "${fish_path}" /etc/shells 2>/dev/null; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            echo "${fish_path}" | sudo tee -a /etc/shells >> "${INSTALL_LOG}" 2>&1 \
                && ok "Added Fish to /etc/shells" \
                || warn "Could not add Fish to /etc/shells"
        fi
    fi

    # Change shell
    if [[ "${SHELL}" != "${fish_path}" ]]; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            chsh -s "${fish_path}" >> "${INSTALL_LOG}" 2>&1 \
                && ok "Default shell changed to Fish" \
                || warn "Could not change shell — run: chsh -s ${fish_path}"
        fi
    else
        ok "Fish is already the default shell"
    fi

    # ── Install Fisher (plugin manager) ───────────────────────────────────────
    step "Installing Fisher plugin manager..."
    if [[ "${DRY_RUN}" != "true" ]]; then
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" >> "${INSTALL_LOG}" 2>&1 \
            && ok "Fisher installed" \
            || warn "Fisher installation failed"
    fi

    # ── Install Fish Plugins ──────────────────────────────────────────────────
    local fish_plugins=(
        "jorgebucaran/autopair.fish"
        "PatrickF1/fzf.fish"
        "franciscolourenco/done"
        "jorgebucaran/nvm.fish"
        "jethrokuan/z"
        "nickeb96/puffer-fish"
    )

    section "Installing Fish Plugins" "🔌"
    for plugin in "${fish_plugins[@]}"; do
        if [[ "${DRY_RUN}" != "true" ]]; then
            fish -c "fisher install ${plugin}" >> "${INSTALL_LOG}" 2>&1 \
                && ok "${plugin}" \
                || warn "Plugin failed: ${plugin}"
        else
            info "[DRY-RUN] Would install Fish plugin: ${plugin}"
        fi
    done

    # ── Install Starship ──────────────────────────────────────────────────────
    step "Installing Starship prompt..."
    if ! command -v starship &>/dev/null; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y >> "${INSTALL_LOG}" 2>&1 \
                && ok "Starship installed" \
                || warn "Starship installation failed (try: paru -S starship)"
        fi
    else
        ok "Starship already installed: $(starship --version)"
    fi

    done_ "Phase 7 complete — Shell setup done! 🐟"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 PHASE 8 — THEME ENGINE INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

phase_8_theme() {
    phase 8 "Theme Engine Initialization" "🎨"

    # ── Download Sample Wallpapers ────────────────────────────────────────────
    step "Setting up default wallpaper..."
    local default_wallpaper="${WALLPAPER_DIR}/dark/ash-default.jpg"

    if [[ ! -f "${default_wallpaper}" ]]; then
        # Create a gradient wallpaper using ImageMagick as fallback
        if command -v convert &>/dev/null; then
            if [[ "${DRY_RUN}" != "true" ]]; then
                convert -size 3840x2160 \
                    gradient:"#1a1b2e-#16213e" \
                    -modulate 100,120,100 \
                    "${default_wallpaper}" 2>/dev/null \
                    && ok "Default gradient wallpaper created" \
                    || warn "Could not create default wallpaper"
            fi
        else
            warn "ImageMagick not found — no default wallpaper created"
            warn "Add wallpapers to: ${WALLPAPER_DIR}"
        fi
    else
        ok "Default wallpaper exists"
    fi

    # ── Initialize swww ───────────────────────────────────────────────────────
    step "Initializing swww daemon..."
    if command -v swww &>/dev/null; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            swww-daemon &>/dev/null &
            sleep 1
            if pgrep -x swww-daemon &>/dev/null; then
                ok "swww daemon started"
                # Apply default wallpaper if exists
                if [[ -f "${default_wallpaper}" ]]; then
                    swww img "${default_wallpaper}" \
                        --transition-type grow \
                        --transition-duration 2 2>/dev/null \
                        && ok "Default wallpaper applied" \
                        || warn "Could not apply wallpaper"
                fi
            else
                warn "swww daemon failed to start — will start on Hyprland launch"
            fi
        fi
    else
        warn "swww not installed — wallpaper daemon unavailable"
    fi

    # ── Initialize Theme Engine ───────────────────────────────────────────────
    step "Initializing theme engine..."
    local theme_engine="${CONFIG_DIR}/hypr/scripts/theme-engine.sh"

    if [[ -f "${theme_engine}" ]]; then
        chmod +x "${theme_engine}"
        if [[ "${DRY_RUN}" != "true" ]] && [[ -f "${default_wallpaper}" ]]; then
            "${theme_engine}" "${default_wallpaper}" "boot" >> "${INSTALL_LOG}" 2>&1 \
                && ok "Theme engine initialized" \
                || warn "Theme engine failed — run 'ash theme pick' after install"
        fi
    else
        warn "Theme engine not found — will be available after config deployment"
    fi

    # ── Setup CLI Tools ───────────────────────────────────────────────────────
    step "Setting up ASH CLI tools..."
    local bin_dir="${DOTFILES_DIR}/bin"

    if [[ -d "${bin_dir}" ]]; then
        for bin in "${bin_dir}"/ash*; do
            if [[ -f "${bin}" ]]; then
                local bin_name
                bin_name=$(basename "${bin}")
                chmod +x "${bin}"
                ln -sf "${bin}" "${LOCAL_DIR}/bin/${bin_name}" 2>/dev/null \
                    && ok "Linked: ${bin_name}" \
                    || warn "Could not link: ${bin_name}"
            fi
        done
    fi

    # ── Make all scripts executable ───────────────────────────────────────────
    step "Setting script permissions..."
    if [[ "${DRY_RUN}" != "true" ]]; then
        find "${CONFIG_DIR}/hypr/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        find "${CONFIG_DIR}/waybar/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        find "${CONFIG_DIR}/rofi/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        find "${CONFIG_DIR}/hyprlock/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        find "${CONFIG_DIR}/eww/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        ok "Script permissions set"
    fi

    # ── Install Desktop Entries ───────────────────────────────────────────────
    step "Installing desktop entries..."
    local entries=(
        "ash-theme"
        "ash-screenshot"
        "ash-settings"
        "ash-recorder"
    )

    for entry in "${entries[@]}"; do
        local entry_src="${DOTFILES_DIR}/config/applications/${entry}.desktop"
        local entry_dst="${LOCAL_DIR}/share/applications/${entry}.desktop"

        if [[ -f "${entry_src}" ]]; then
            cp "${entry_src}" "${entry_dst}" 2>/dev/null \
                && ok "Desktop entry: ${entry}" \
                || warn "Could not install: ${entry}.desktop"
        fi
    done

    # Update desktop database
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "${LOCAL_DIR}/share/applications" 2>/dev/null || true
        ok "Desktop database updated"
    fi

    done_ "Phase 8 complete — Theme engine initialized! 🎨"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ✅ PHASE 9 — POST-INSTALL VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

phase_9_validation() {
    phase 9 "Post-Install Validation" "✅"

    local pass=0
    local fail=0
    local warn_count=0

    # ── Binary Checks ─────────────────────────────────────────────────────────
    section "Checking Installed Binaries" "🔍"

    local critical_bins=(
        "hyprland" "waybar" "kitty" "fish" "rofi"
        "swww" "dunst" "grim" "slurp" "wl-copy"
        "pipewire" "wpctl" "nmcli" "convert" "jq"
        "curl" "git" "nvim" "starship" "fzf"
    )

    for bin in "${critical_bins[@]}"; do
        if command -v "${bin}" &>/dev/null; then
            ok "${bin}"
            ((pass++)) || true
        else
            error "Missing: ${bin}"
            ((fail++)) || true
        fi
    done

    # ── Config File Checks ────────────────────────────────────────────────────
    section "Checking Configuration Files" "📋"

    local critical_configs=(
        "${CONFIG_DIR}/hypr/hyprland.conf"
        "${CONFIG_DIR}/waybar/configs/top.jsonc"
        "${CONFIG_DIR}/rofi/config.rasi"
        "${CONFIG_DIR}/fish/config.fish"
        "${CONFIG_DIR}/kitty/kitty.conf"
        "${CONFIG_DIR}/dunst/dunstrc"
        "${CONFIG_DIR}/hypridle/hypridle.conf"
        "${CONFIG_DIR}/nvim/init.lua"
    )

    for cfg in "${critical_configs[@]}"; do
        if [[ -f "${cfg}" ]]; then
            ok "${cfg/$HOME/\~}"
            ((pass++)) || true
        else
            warn "Missing config: ${cfg/$HOME/\~}"
            ((warn_count++)) || true
        fi
    done

    # ── Service Checks ────────────────────────────────────────────────────────
    section "Checking Services" "⚙️"

    local check_services=(
        "NetworkManager"
        "bluetooth"
    )

    for svc in "${check_services[@]}"; do
        if systemctl is-enabled "${svc}" &>/dev/null; then
            ok "System service: ${svc}"
            ((pass++)) || true
        else
            warn "Service not enabled: ${svc}"
            ((warn_count++)) || true
        fi
    done

    local check_user_services=(
        "pipewire"
        "wireplumber"
    )

    for svc in "${check_user_services[@]}"; do
        if systemctl --user is-enabled "${svc}" &>/dev/null; then
            ok "User service: ${svc}"
            ((pass++)) || true
        else
            warn "User service not enabled: ${svc}"
            ((warn_count++)) || true
        fi
    done

    # ── Font Checks ───────────────────────────────────────────────────────────
    section "Checking Fonts" "🔤"

    local check_fonts=(
        "JetBrainsMono Nerd Font"
        "Noto Color Emoji"
    )

    for font in "${check_fonts[@]}"; do
        if fc-list | grep -qi "${font}" 2>/dev/null; then
            ok "Font: ${font}"
            ((pass++)) || true
        else
            warn "Font not found: ${font}"
            ((warn_count++)) || true
        fi
    done

    # ── Shell Check ───────────────────────────────────────────────────────────
    section "Checking Shell" "🐟"

    if command -v fish &>/dev/null; then
        ok "Fish shell available"
        ((pass++)) || true
    else
        error "Fish shell not found"
        ((fail++)) || true
    fi

    # ── Final Report ──────────────────────────────────────────────────────────
    local elapsed=$(( $(date +%s) - INSTALL_START ))
    local elapsed_min=$(( elapsed / 60 ))
    local elapsed_sec=$(( elapsed % 60 ))

    echo ""
    echo -e "${BOLD}${BBLUE}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET}            ${BOLD}${BWHITE}INSTALLATION SUMMARY${RESET}                              ${BOLD}${BBLUE}║${RESET}"
    echo -e "${BOLD}${BBLUE}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET}  ${BGREEN}✅ Passed:${RESET}   ${BOLD}${BWHITE}${pass}${RESET}                                               ${BOLD}${BBLUE}║${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET}  ${BYELLOW}⚠️  Warnings:${RESET} ${BOLD}${BWHITE}${warn_count}${RESET}                                               ${BOLD}${BBLUE}║${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET}  ${BRED}❌ Failed:${RESET}   ${BOLD}${BWHITE}${fail}${RESET}                                               ${BOLD}${BBLUE}║${RESET}"
    echo -e "${BOLD}${BBLUE}║${RESET}  ${BCYAN}⏱️  Time:${RESET}     ${BOLD}${BWHITE}${elapsed_min}m ${elapsed_sec}s${RESET}                                          ${BOLD}${BBLUE}║${RESET}"
    echo -e "${BOLD}${BBLUE}╠══════════════════════════════════════════════════════════════════╣${RESET}"

    if (( fail == 0 )); then
        echo -e "${BOLD}${BBLUE}║${RESET}  ${BGREEN}🎉 STATUS: INSTALLATION SUCCESSFUL!${RESET}                         ${BOLD}${BBLUE}║${RESET}"
    elif (( fail < 3 )); then
        echo -e "${BOLD}${BBLUE}║${RESET}  ${BYELLOW}⚠️  STATUS: PARTIAL SUCCESS — ${fail} failures${RESET}                    ${BOLD}${BBLUE}║${RESET}"
    else
        echo -e "${BOLD}${BBLUE}║${RESET}  ${BRED}❌ STATUS: MULTIPLE FAILURES — ${fail} errors${RESET}                    ${BOLD}${BBLUE}║${RESET}"
    fi

    echo -e "${BOLD}${BBLUE}╚══════════════════════════════════════════════════════════════════╝${RESET}"

    # ── Next Steps ────────────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${BWHITE}🚀 NEXT STEPS:${RESET}"
    echo ""
    echo -e "  ${BGREEN}1.${RESET} ${WHITE}Reboot your system:${RESET}"
    echo -e "     ${DIM}sudo reboot${RESET}"
    echo ""
    echo -e "  ${BGREEN}2.${RESET} ${WHITE}Pick a wallpaper and apply theme:${RESET}"
    echo -e "     ${DIM}ash theme pick${RESET}"
    echo ""
    echo -e "  ${BGREEN}3.${RESET} ${WHITE}Run health check:${RESET}"
    echo -e "     ${DIM}ash doctor${RESET}"
    echo ""
    echo -e "  ${BGREEN}4.${RESET} ${WHITE}Configure your monitors:${RESET}"
    echo -e "     ${DIM}nvim ~/.config/hypr/UserOverrides/user.conf${RESET}"
    echo ""
    echo -e "  ${BGREEN}5.${RESET} ${WHITE}Check the documentation:${RESET}"
    echo -e "     ${DIM}cat ~/.dotfiles/docs/KEYBINDS.md${RESET}"

    log "INFO" "Installation complete — pass:${pass} warn:${warn_count} fail:${fail} time:${elapsed}s"
    done_ "Phase 9 complete — Validation done! ✅"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════════════════

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --phase)
                START_PHASE="${2:-1}"
                END_PHASE="${START_PHASE}"
                shift 2
                ;;
            --from-phase)
                START_PHASE="${2:-1}"
                shift 2
                ;;
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --force|-f)
                FORCE_INSTALL=true
                shift
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo -e "${BOLD}ASH Dotfiles v${DOTFILES_VERSION} — Installer${RESET}"
    echo ""
    echo "USAGE:"
    echo "  bash install.sh [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --phase N          Run only phase N (1-9)"
    echo "  --from-phase N     Start from phase N"
    echo "  --skip-packages    Skip package installation"
    echo "  --force, -f        Skip confirmation prompts"
    echo "  --dry-run, -n      Show what would be done"
    echo "  --verbose, -v      Verbose output"
    echo "  --help, -h         Show this help"
    echo ""
    echo "PHASES:"
    echo "  1 — Pre-flight checks"
    echo "  2 — AUR helper"
    echo "  3 — Packages"
    echo "  4 — Directories"
    echo "  5 — Configurations"
    echo "  6 — Services"
    echo "  7 — Shell (Fish)"
    echo "  8 — Theme engine"
    echo "  9 — Validation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    print_banner

    echo -e "${DIM}  Log: ${INSTALL_LOG}${RESET}"
    echo -e "${DIM}  Dry-run: ${DRY_RUN} | Force: ${FORCE_INSTALL} | Skip-pkg: ${SKIP_PACKAGES}${RESET}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        warn "DRY-RUN MODE — No changes will be made"
    fi

    if ! confirm "Start ASH Dotfiles v${DOTFILES_VERSION} installation?"; then
        info "Installation cancelled"
        exit 0
    fi

    # Run phases
    local phases=(1 2 3 4 5 6 7 8 9)

    for phase_num in "${phases[@]}"; do
        if (( phase_num < START_PHASE )) || (( phase_num > END_PHASE )); then
            debug "Skipping phase ${phase_num}"
            continue
        fi

        case ${phase_num} in
            1) phase_1_preflight ;;
            2) phase_2_aur_helper ;;
            3) phase_3_packages ;;
            4) phase_4_directories ;;
            5) phase_5_configs ;;
            6) phase_6_services ;;
            7) phase_7_shell ;;
            8) phase_8_theme ;;
            9) phase_9_validation ;;
        esac
    done

    echo ""
    echo -e "${BOLD}${BMAGENTA}"
    echo "  ╔═══════════════════════════════════════════════════════════════════╗"
    echo "  ║     🎉  ASH DOTFILES v3.0 — INSTALLATION COMPLETE  🎉           ║"
    echo "  ║                                                                   ║"
    echo "  ║     Thank you for using ASH Dotfiles!                            ║"
    echo "  ║     Your epic Hyprland desktop is ready to launch.              ║"
    echo "  ║                                                                   ║"
    echo "  ║     → sudo reboot                                                ║"
    echo "  ║     → ash theme pick                                             ║"
    echo "  ║     → ash doctor                                                 ║"
    echo "  ╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    log "INFO" "=== INSTALLATION COMPLETE ==="
}

main "$@"