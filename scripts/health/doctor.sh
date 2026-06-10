#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — STANDALONE DOCTOR SCRIPT                     ║
# ║           60+ health checks for the complete system                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/doctor.log"

# Colors
readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly RED='\033[91m'
readonly GREEN='\033[92m'
readonly YELLOW='\033[93m'
readonly CYAN='\033[96m'
readonly MAGENTA='\033[95m'
readonly DIM='\033[2m'
readonly BWHITE='\033[97m'

declare -i TOTAL_PASS=0
declare -i TOTAL_FAIL=0
declare -i TOTAL_WARN=0
declare -a FAILURES=()
declare -a WARNINGS=()

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ─── Output helpers ───────────────────────────────────────────────────────────

section() {
    echo ""
    echo -e "  ${BOLD}${MAGENTA}━━━ ${1} ━━━${RESET}"
}

check_pass() {
    local name="$1"
    echo -e "  ${GREEN}✓${RESET} ${name}"
    ((TOTAL_PASS++)) || true
    log "PASS" "${name}"
}

check_fail() {
    local name="$1"
    local hint="${2:-}"
    echo -e "  ${RED}✗${RESET} ${name}"
    [[ -n "${hint}" ]] && echo -e "    ${DIM}→ ${hint}${RESET}"
    ((TOTAL_FAIL++)) || true
    FAILURES+=("${name}")
    log "FAIL" "${name}"
}

check_warn() {
    local name="$1"
    local hint="${2:-}"
    echo -e "  ${YELLOW}⚠${RESET} ${name}"
    [[ -n "${hint}" ]] && echo -e "    ${DIM}→ ${hint}${RESET}"
    ((TOTAL_WARN++)) || true
    WARNINGS+=("${name}")
    log "WARN" "${name}"
}

# Universal checker
check() {
    local name="$1"
    local cmd="$2"
    local severity="${3:-required}"  # required | optional
    local hint="${4:-}"

    if eval "${cmd}" &>/dev/null 2>&1; then
        check_pass "${name}"
    else
        if [[ "${severity}" == "required" ]]; then
            check_fail "${name}" "${hint}"
        else
            check_warn "${name}" "${hint}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 CHECK GROUPS
# ═══════════════════════════════════════════════════════════════════════════════

check_system() {
    section "🖥️ System"
    check "Arch Linux / arch-based"    "test -f /etc/arch-release"                  "optional"
    check "Kernel ≥ 6.1"               "awk -F. 'NR==1{exit !(\$1>6 || (\$1==6 && \$2>=1))}' <<< \$(uname -r | tr '.' '\n' | head -2 | tr '\n' '.')" "optional"
    check "Wayland session"            "test -n '${WAYLAND_DISPLAY:-}'"              "optional" "Start Hyprland first"
    check "XDG_RUNTIME_DIR set"        "test -n '${XDG_RUNTIME_DIR:-}'"
    check "Systemd user session"       "systemctl --user status &>/dev/null"
    check "D-Bus session"              "test -n '${DBUS_SESSION_BUS_ADDRESS:-}'"     "optional"
    check "User bin in PATH"           "echo \$PATH | grep -q '${HOME}/.local/bin'"
}

check_critical_tools() {
    section "🔴 Critical Tools"
    local tools=(
        "hyprland:hyprland"
        "waybar:waybar"
        "rofi:rofi"
        "kitty:kitty"
        "fish:fish"
        "dunst:dunst"
        "swww:swww"
        "hyprlock:hyprlock"
        "hypridle:hypridle"
        "grim:grim"
        "slurp:slurp"
        "wl-copy:wl-clipboard"
        "ImageMagick:convert"
        "jq:jq"
        "curl:curl"
        "git:git"
        "Neovim:nvim"
        "Python3:python3"
        "Pipewire:pipewire"
        "NetworkManager:nmcli"
    )

    for entry in "${tools[@]}"; do
        local name="${entry%%:*}"
        local bin="${entry##*:}"
        check "${name}" "command -v ${bin}" "required" "Install: paru -S ${bin}"
    done
}

check_optional_tools() {
    section "🟡 Optional Tools"
    local tools=(
        "swappy:swappy"
        "hyprpicker:hyprpicker"
        "wf-recorder:wf-recorder"
        "playerctl:playerctl"
        "pamixer:pamixer"
        "brightnessctl:brightnessctl"
        "cliphist:cliphist"
        "tesseract (OCR):tesseract"
        "SwayNC:swaync"
        "btop:btop"
        "fastfetch:fastfetch"
        "starship:starship"
        "fzf:fzf"
        "fd:fd"
        "ripgrep:rg"
        "bat:bat"
        "eza:eza"
        "zoxide:zoxide"
        "lazygit:lazygit"
        "blueman:blueman-manager"
        "nemo:nemo"
        "pavucontrol:pavucontrol"
    )

    for entry in "${tools[@]}"; do
        local name="${entry%%:*}"
        local bin="${entry##*:}"
        check "${name}" "command -v ${bin}" "optional" "paru -S ${bin}"
    done
}

check_services() {
    section "⚙️ System Services"
    check "NetworkManager active"    "systemctl is-active NetworkManager"
    check "Bluetooth active"         "systemctl is-active bluetooth"          "optional"
    check "Pipewire (user)"          "systemctl --user is-active pipewire"
    check "Wireplumber (user)"       "systemctl --user is-active wireplumber"

    section "⚙️ Running Processes"
    check "Hyprland running"         "pgrep -x Hyprland"                     "optional"
    check "Waybar running"           "pgrep -x waybar"                       "optional"
    check "Dunst running"            "pgrep -x dunst"                        "optional"
    check "swww-daemon running"      "pgrep -x swww-daemon"                  "optional"
    check "hypridle running"         "pgrep -x hypridle"                     "optional"
    check "Pipewire running"         "pgrep -x pipewire"
    check "Wireplumber running"      "pgrep -x wireplumber"
}

check_fonts() {
    section "🔤 Fonts"
    check "JetBrainsMono Nerd Font"  "fc-list | grep -qi 'JetBrainsMonoNerd\|JetBrainsMono Nerd'" "required" \
          "paru -S ttf-jetbrains-mono-nerd"
    check "Noto Color Emoji"         "fc-list | grep -qi 'Noto.*Emoji\|NotoColorEmoji'"            "required" \
          "sudo pacman -S noto-fonts-emoji"
    check "Font Awesome"             "fc-list | grep -qi 'Font Awesome\|FontAwesome'"              "optional"
    check "Symbols Nerd Font"        "fc-list | grep -qi 'Symbols Nerd\|NerdFontsSymbols'"         "optional"
    check "Papirus icon theme"       "test -d /usr/share/icons/Papirus-Dark"                       "optional"
    check "Bibata cursor theme"      "test -d /usr/share/icons/Bibata-Modern-Ice"                  "optional"
}

check_configs() {
    section "📋 Configuration Files"
    local configs=(
        "hyprland.conf:${CONFIG_DIR}/hypr/hyprland.conf"
        "env.conf:${CONFIG_DIR}/hypr/core/env.conf"
        "monitors.conf:${CONFIG_DIR}/hypr/core/monitors.conf"
        "keybinds.conf:${CONFIG_DIR}/hypr/modules/keybinds.conf"
        "autostart.conf:${CONFIG_DIR}/hypr/modules/autostart.conf"
        "user.conf (overrides):${CONFIG_DIR}/hypr/UserOverrides/user.conf"
        "waybar top.jsonc:${CONFIG_DIR}/waybar/configs/top.jsonc"
        "waybar style.css:${CONFIG_DIR}/waybar/styles/main.css"
        "rofi config:${CONFIG_DIR}/rofi/config.rasi"
        "fish config:${CONFIG_DIR}/fish/config.fish"
        "kitty config:${CONFIG_DIR}/kitty/kitty.conf"
        "dunstrc:${CONFIG_DIR}/dunst/dunstrc"
        "hypridle config:${CONFIG_DIR}/hypridle/hypridle.conf"
        "hyprlock config:${CONFIG_DIR}/hyprlock/hyprlock.conf"
        "nvim init.lua:${CONFIG_DIR}/nvim/init.lua"
        "starship.toml:${CONFIG_DIR}/starship.toml"
        "btop config:${CONFIG_DIR}/btop/btop.conf"
        "mpv config:${CONFIG_DIR}/mpv/mpv.conf"
    )

    for entry in "${configs[@]}"; do
        local name="${entry%%:*}"
        local path="${entry##*:}"
        check "${name}" "test -f '${path}'" "optional" "Run: ash reload"
    done
}

check_scripts() {
    section "📜 Script Permissions"
    local script_dirs=(
        "${CONFIG_DIR}/hypr/scripts"
        "${CONFIG_DIR}/waybar/scripts"
        "${CONFIG_DIR}/rofi/scripts"
        "${CONFIG_DIR}/hyprlock/scripts"
    )

    local total_scripts=0
    local executable_scripts=0

    for dir in "${script_dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            while IFS= read -r script; do
                ((total_scripts++)) || true
                if [[ -x "${script}" ]]; then
                    ((executable_scripts++)) || true
                fi
            done < <(find "${dir}" -name "*.sh" 2>/dev/null)
        fi
    done

    if (( total_scripts == 0 )); then
        check_warn "Script directories" "No scripts found — check config deployment"
    elif (( executable_scripts == total_scripts )); then
        check_pass "All ${total_scripts} scripts are executable"
    else
        local non_exec=$(( total_scripts - executable_scripts ))
        check_warn "${non_exec}/${total_scripts} scripts not executable" \
                   "Run: find ~/.config -name '*.sh' -exec chmod +x {} \\;"
    fi
}

check_theme() {
    section "🎨 Theme Engine"
    check "Color cache exists"       "test -f '${CACHE_DIR}/colors/current.json'"    "optional" \
          "Run: ash theme pick"
    check "Wallpaper history"        "test -f '${CACHE_DIR}/wallpaper/last'"         "optional" \
          "Run: ash theme pick"
    check "Hyprland active theme"    "test -f '${CONFIG_DIR}/hypr/themes/active.conf'" "optional"
    check "Waybar colors CSS"        "test -f '${CONFIG_DIR}/waybar/styles/colors.css'" "optional"
    check "Kitty theme"              "test -f '${CONFIG_DIR}/kitty/themes/current.conf'" "optional"
    check "Rofi dynamic theme"       "test -f '${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi'" "optional"
    check "Fish theme"               "test -f '${CONFIG_DIR}/fish/themes/current.fish'" "optional"
    check "Wallpaper directory"      "test -d '${HOME}/Pictures/Wallpapers'"
    check "Screenshots directory"    "test -d '${HOME}/Pictures/Screenshots'"

    # Check theme engine script
    local engine="${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh"
    check "Theme engine script"      "test -x '${engine}'"                           "required" \
          "chmod +x ${engine}"
}

check_audio() {
    section "🔊 Audio System"
    check "Pipewire installed"       "command -v pipewire"
    check "Wireplumber installed"    "command -v wireplumber"
    check "wpctl available"          "command -v wpctl"
    check "pactl available"          "command -v pactl"
    check "pamixer available"        "command -v pamixer"                             "optional"
    check "Audio sink available"     "wpctl get-volume @DEFAULT_AUDIO_SINK@ &>/dev/null" "optional"
}

check_gpu() {
    section "🎮 GPU & Display"
    if lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        check "AMD GPU detected"     "true"
        check "AMD Vulkan support"   "test -f /usr/share/vulkan/icd.d/radeon_icd.x86_64.json" "optional"
        check "Mesa installed"       "command -v glxinfo || test -f /usr/lib/libGL.so" "optional"
    elif lspci 2>/dev/null | grep -qi nvidia; then
        check "NVIDIA GPU detected"  "true"
        check "nvidia-smi available" "command -v nvidia-smi"                         "optional"
    elif lspci 2>/dev/null | grep -qi intel; then
        check "Intel GPU detected"   "true"
    fi

    check "Vulkan support"           "command -v vulkaninfo"                         "optional"
    check "DRM/KMS available"        "test -d /sys/class/drm"
    check "wayland socket"           "test -n '${WAYLAND_DISPLAY:-}' && test -S '${XDG_RUNTIME_DIR:-/tmp}/${WAYLAND_DISPLAY:-wayland-0}'" "optional"
}

check_network() {
    section "🌐 Network"
    check "NetworkManager available" "command -v nmcli"
    check "nmcli working"            "nmcli general status &>/dev/null"              "optional"
    check "Internet connectivity"    "curl -s --max-time 3 https://archlinux.org &>/dev/null" "optional"
    check "WiFi available"           "nmcli radio wifi &>/dev/null"                  "optional"
}

check_shell() {
    section "🐟 Shell"
    check "Fish shell installed"     "command -v fish"
    check "Fish is default shell"    "[[ \"\$(getent passwd \${USER} | cut -d: -f7)\" == *fish* ]]" "optional" \
          "chsh -s $(command -v fish)"
    check "Starship installed"       "command -v starship"                           "optional"
    check "FZF installed"            "command -v fzf"                                "optional"
    check "Zoxide installed"         "command -v zoxide"                             "optional"
    check "Fisher (plugin mgr)"      "fish -c 'functions -q fisher' 2>/dev/null"     "optional"
}

check_editor() {
    section "📝 Editor"
    check "Neovim installed"         "command -v nvim"
    check "Neovim ≥ 0.9"            "nvim --version 2>/dev/null | head -1 | grep -qE 'NVIM v(0\.9|0\.1[0-9]|[1-9])'" "optional"
    check "lazy.nvim installed"      "test -d '${HOME}/.local/share/nvim/lazy/lazy.nvim'"  "optional"
    check "Neovim config exists"     "test -f '${CONFIG_DIR}/nvim/init.lua'"
}

check_dotfiles() {
    section "📦 Dotfiles Repo"
    check "Dotfiles directory"       "test -d '${DOTFILES_DIR}'"
    check "Git repository"           "test -d '${DOTFILES_DIR}/.git'"               "optional"
    check "ASH CLI installed"        "command -v ash"
    check "ASH CLI executable"       "test -x '${HOME}/.local/bin/ash'"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

print_summary() {
    local elapsed=$(( $(date +%s) - START_TIME ))
    echo ""
    echo -e "  ${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${BOLD}${BWHITE}📊 HEALTH CHECK SUMMARY${RESET}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "  ${GREEN}✓ Passed:${RESET}   ${BOLD}${TOTAL_PASS}${RESET}"
    echo -e "  ${YELLOW}⚠ Warnings:${RESET} ${BOLD}${TOTAL_WARN}${RESET}"
    echo -e "  ${RED}✗ Failed:${RESET}   ${BOLD}${TOTAL_FAIL}${RESET}"
    echo -e "  ${DIM}⏱ Duration: ${elapsed}s${RESET}"
    echo ""

    if (( ${#FAILURES[@]} > 0 )); then
        echo -e "  ${RED}${BOLD}Critical Issues:${RESET}"
        for f in "${FAILURES[@]}"; do
            echo -e "    ${RED}•${RESET} ${f}"
        done
        echo ""
    fi

    if (( ${#WARNINGS[@]} > 0 )); then
        echo -e "  ${YELLOW}${BOLD}Warnings:${RESET}"
        for w in "${WARNINGS[@]}"; do
            echo -e "    ${YELLOW}•${RESET} ${w}"
        done
        echo ""
    fi

    if (( TOTAL_FAIL == 0 && TOTAL_WARN == 0 )); then
        echo -e "  ${GREEN}${BOLD}🎉 Perfect health — all checks passed!${RESET}"
    elif (( TOTAL_FAIL == 0 )); then
        echo -e "  ${YELLOW}${BOLD}✓ Healthy with ${TOTAL_WARN} warning(s)${RESET}"
    elif (( TOTAL_FAIL <= 3 )); then
        echo -e "  ${YELLOW}${BOLD}⚠ ${TOTAL_FAIL} critical issue(s) require attention${RESET}"
    else
        echo -e "  ${RED}${BOLD}❌ ${TOTAL_FAIL} critical failures — system may not work correctly${RESET}"
    fi

    echo ""
    echo -e "  ${DIM}Log: ${LOG_FILE}${RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    readonly START_TIME=$(date +%s)

    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo -e "  ${BOLD}${MAGENTA}🏥 ASH DOTFILES v3.0 — Health Check${RESET}"
    echo -e "  ${DIM}$(date '+%A, %B %d %Y — %H:%M:%S')${RESET}"

    check_system
    check_critical_tools
    check_optional_tools
    check_services
    check_fonts
    check_configs
    check_scripts
    check_theme
    check_audio
    check_gpu
    check_network
    check_shell
    check_editor
    check_dotfiles

    print_summary

    log "INFO" "doctor complete: pass=${TOTAL_PASS} warn=${TOTAL_WARN} fail=${TOTAL_FAIL}"

    # Exit code based on failures
    (( TOTAL_FAIL == 0 ))
}

main "$@"