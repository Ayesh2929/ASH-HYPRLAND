#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — STANDALONE DOCTOR SCRIPT                     ║
# ║           60+ health checks for the complete system                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/doctor.log"
readonly CONFIG_DIR="${HOME}/.config"
readonly DOTFILES_DIR="${HOME}/.dotfiles"

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly GREEN='\033[92m'
readonly YELLOW='\033[93m'
readonly RED='\033[91m'
readonly CYAN='\033[96m'
readonly MAGENTA='\033[95m'
readonly DIM='\033[2m'

# Counters
PASS=0; FAIL=0; WARN=0; SKIP=0

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 CHECK FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

check_cmd() {
    local name="$1"
    local cmd="$2"
    local required="${3:-required}"
    local fix="${4:-}"

    if eval "${cmd}" &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${R}  ${name}"
        ((PASS++)) || true
        log "PASS" "${name}"
    else
        if [[ "${required}" == "required" ]]; then
            echo -e "  ${RED}✗${R}  ${name}${RED} ← MISSING${R}"
            [[ -n "${fix}" ]] && echo -e "     ${DIM}Fix: ${fix}${R}"
            ((FAIL++)) || true
            log "FAIL" "${name}"
        elif [[ "${required}" == "optional" ]]; then
            echo -e "  ${YELLOW}⚠${R}  ${name} ${DIM}(optional)${R}"
            [[ -n "${fix}" ]] && echo -e "     ${DIM}Install: ${fix}${R}"
            ((WARN++)) || true
            log "WARN" "${name}"
        else
            echo -e "  ${DIM}─${R}  ${name} ${DIM}(skipped)${R}"
            ((SKIP++)) || true
        fi
    fi
}

check_file() {
    local name="$1"
    local path="$2"
    local required="${3:-required}"
    check_cmd "${name}" "test -f '${path}'" "${required}"
}

check_dir() {
    local name="$1"
    local path="$2"
    local required="${3:-required}"
    check_cmd "${name}" "test -d '${path}'" "${required}"
}

check_service() {
    local name="$1"
    local service="$2"
    local required="${3:-required}"
    check_cmd "${name}" "systemctl is-active --quiet '${service}'" "${required}"
}

check_user_service() {
    local name="$1"
    local service="$2"
    local required="${3:-required}"
    check_cmd "${name}" "systemctl --user is-active --quiet '${service}'" "${required}"
}

check_process() {
    local name="$1"
    local proc="$2"
    local required="${3:-optional}"
    check_cmd "${name}" "pgrep -x '${proc}'" "${required}"
}

check_font() {
    local name="$1"
    local pattern="$2"
    local required="${3:-required}"
    check_cmd "Font: ${name}" "fc-list | grep -qi '${pattern}'" "${required}"
}

section() {
    echo ""
    echo -e "  ${B}${MAGENTA}${1}${R}"
    echo -e "  ${DIM}$(printf '─%.0s' {1..50})${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖨️ HEADER
# ═══════════════════════════════════════════════════════════════════════════════

print_header() {
    clear
    echo ""
    echo -e "  ${B}${MAGENTA}╔════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${MAGENTA}║${R}  ${B}🏥 ASH Doctor — System Health Check v3.0${R}  ${B}${MAGENTA}║${R}"
    echo -e "  ${B}${MAGENTA}╚════════════════════════════════════════════════╝${R}"
    echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S') — $(hostname)${R}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 ALL CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

run_checks() {

    # ── Environment ──────────────────────────────────────────────────────────
    section "🌐 Environment"
    check_cmd "Wayland session active"     "test -n '${WAYLAND_DISPLAY:-}'"   "required"
    check_cmd "XDG_RUNTIME_DIR set"        "test -n '${XDG_RUNTIME_DIR:-}'"   "required"
    check_cmd "XDG_SESSION_TYPE=wayland"   "[[ '${XDG_SESSION_TYPE:-}' == 'wayland' ]]" "required"
    check_cmd "Running as regular user"    "test '${EUID:-0}' -ne 0"          "required"
    check_cmd "HOME directory exists"      "test -d '${HOME}'"                "required"

    # ── Critical Binaries ────────────────────────────────────────────────────
    section "🔴 Critical Binaries"
    check_cmd "hyprland"          "command -v hyprland"   "required" "pacman -S hyprland"
    check_cmd "waybar"            "command -v waybar"     "required" "pacman -S waybar"
    check_cmd "rofi-wayland"      "command -v rofi"       "required" "paru -S rofi-wayland"
    check_cmd "kitty"             "command -v kitty"      "required" "pacman -S kitty"
    check_cmd "fish"              "command -v fish"       "required" "pacman -S fish"
    check_cmd "dunst"             "command -v dunst"      "required" "pacman -S dunst"
    check_cmd "swww"              "command -v swww"       "required" "paru -S swww"
    check_cmd "hyprlock"          "command -v hyprlock"   "required" "paru -S hyprlock"
    check_cmd "hypridle"          "command -v hypridle"   "required" "paru -S hypridle"
    check_cmd "grim"              "command -v grim"       "required" "pacman -S grim"
    check_cmd "slurp"             "command -v slurp"      "required" "pacman -S slurp"
    check_cmd "wl-copy"           "command -v wl-copy"    "required" "pacman -S wl-clipboard"
    check_cmd "convert (IM)"      "command -v convert"    "required" "pacman -S imagemagick"
    check_cmd "jq"                "command -v jq"         "required" "pacman -S jq"
    check_cmd "curl"              "command -v curl"       "required" "pacman -S curl"
    check_cmd "git"               "command -v git"        "required" "pacman -S git"
    check_cmd "nvim"              "command -v nvim"       "required" "pacman -S neovim"

    # ── Optional Binaries ────────────────────────────────────────────────────
    section "🟡 Optional Binaries"
    check_cmd "swappy"            "command -v swappy"       "optional" "paru -S swappy"
    check_cmd "hyprpicker"        "command -v hyprpicker"   "optional" "paru -S hyprpicker"
    check_cmd "wf-recorder"       "command -v wf-recorder"  "optional" "paru -S wf-recorder"
    check_cmd "playerctl"         "command -v playerctl"    "optional" "pacman -S playerctl"
    check_cmd "pamixer"           "command -v pamixer"      "optional" "pacman -S pamixer"
    check_cmd "brightnessctl"     "command -v brightnessctl""optional" "pacman -S brightnessctl"
    check_cmd "cliphist"          "command -v cliphist"     "optional" "paru -S cliphist"
    check_cmd "tesseract (OCR)"   "command -v tesseract"    "optional" "pacman -S tesseract"
    check_cmd "swaync-client"     "command -v swaync-client""optional" "paru -S swaync"
    check_cmd "lazygit"           "command -v lazygit"      "optional" "pacman -S lazygit"
    check_cmd "btop"              "command -v btop"         "optional" "pacman -S btop"
    check_cmd "fastfetch"         "command -v fastfetch"    "optional" "paru -S fastfetch"
    check_cmd "starship"          "command -v starship"     "optional" "pacman -S starship"
    check_cmd "fzf"               "command -v fzf"          "optional" "pacman -S fzf"
    check_cmd "fd"                "command -v fd"           "optional" "pacman -S fd"
    check_cmd "ripgrep (rg)"      "command -v rg"           "optional" "pacman -S ripgrep"
    check_cmd "bat"               "command -v bat"          "optional" "pacman -S bat"
    check_cmd "eza"               "command -v eza"          "optional" "paru -S eza"
    check_cmd "zoxide"            "command -v zoxide"       "optional" "pacman -S zoxide"
    check_cmd "delta"             "command -v delta"        "optional" "pacman -S git-delta"
    check_cmd "ffmpeg"            "command -v ffmpeg"       "optional" "pacman -S ffmpeg"
    check_cmd "socat"             "command -v socat"        "optional" "pacman -S socat"

    # ── Running Processes ────────────────────────────────────────────────────
    section "⚙️ Running Processes"
    check_process "Hyprland"          "Hyprland"      "required"
    check_process "Waybar"            "waybar"        "required"
    check_process "Dunst"             "dunst"         "required"
    check_process "swww-daemon"       "swww-daemon"   "optional"
    check_process "hypridle"          "hypridle"      "optional"
    check_process "pipewire"          "pipewire"      "required"
    check_process "wireplumber"       "wireplumber"   "required"

    # ── System Services ──────────────────────────────────────────────────────
    section "🔧 System Services"
    check_service "NetworkManager"    "NetworkManager"   "required"
    check_service "bluetooth"         "bluetooth"        "optional"
    check_user_service "pipewire"     "pipewire"         "required"
    check_user_service "wireplumber"  "wireplumber"      "required"

    # ── Fonts ────────────────────────────────────────────────────────────────
    section "🔤 Fonts"
    check_font "JetBrainsMono Nerd Font"    "JetBrainsMono"     "required"
    check_font "Noto Color Emoji"           "Noto.*Emoji"       "required"
    check_font "Symbols Nerd Font"          "Symbols Nerd"      "optional"
    check_font "Font Awesome"               "Font Awesome"      "optional"

    # ── Config Files ─────────────────────────────────────────────────────────
    section "📋 Configuration Files"
    check_file "hyprland.conf"         "${CONFIG_DIR}/hypr/hyprland.conf"
    check_file "waybar top.jsonc"      "${CONFIG_DIR}/waybar/configs/top.jsonc"
    check_file "rofi config.rasi"      "${CONFIG_DIR}/rofi/config.rasi"
    check_file "fish config.fish"      "${CONFIG_DIR}/fish/config.fish"
    check_file "kitty.conf"            "${CONFIG_DIR}/kitty/kitty.conf"
    check_file "dunstrc"               "${CONFIG_DIR}/dunst/dunstrc"
    check_file "hypridle.conf"         "${CONFIG_DIR}/hypridle/hypridle.conf"
    check_file "hyprlock.conf"         "${CONFIG_DIR}/hyprlock/hyprlock.conf"
    check_file "nvim init.lua"         "${CONFIG_DIR}/nvim/init.lua"
    check_file "user.conf (overrides)" "${CONFIG_DIR}/hypr/UserOverrides/user.conf"
    check_file "starship.toml"         "${CONFIG_DIR}/starship.toml"
    check_file "btop.conf"             "${CONFIG_DIR}/btop/btop.conf" "optional"
    check_file "fastfetch config"      "${CONFIG_DIR}/fastfetch/config.jsonc" "optional"

    # ── Theme Engine ─────────────────────────────────────────────────────────
    section "🎨 Theme Engine"
    check_file "theme-engine.sh"       "${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh"
    check_file "wallpaper-picker.sh"   "${CONFIG_DIR}/hypr/scripts/theme/wallpaper-picker.sh"
    check_file "color palette (JSON)"  "${CACHE_DIR}/colors/current.json" "optional"
    check_file "color palette (shell)" "${CACHE_DIR}/colors/current.sh"   "optional"
    check_file "hyprland theme"        "${CONFIG_DIR}/hypr/themes/active.conf" "optional"
    check_file "waybar colors.css"     "${CONFIG_DIR}/waybar/styles/colors.css" "optional"
    check_file "kitty theme"           "${CONFIG_DIR}/kitty/themes/current.conf" "optional"
    check_file "rofi dynamic theme"    "${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi" "optional"
    check_file "wallpaper history"     "${CACHE_DIR}/wallpaper/last" "optional"
    check_dir  "wallpaper directory"   "${HOME}/Pictures/Wallpapers"

    # ── Scripts Executable ───────────────────────────────────────────────────
    section "📜 Script Permissions"
    local scripts=(
        "${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh"
        "${CONFIG_DIR}/hypr/scripts/theme/wallpaper-picker.sh"
        "${CONFIG_DIR}/hypr/scripts/utils/screenshot.sh"
        "${CONFIG_DIR}/hypr/scripts/media/volume.sh"
        "${CONFIG_DIR}/hypr/scripts/media/brightness.sh"
        "${CONFIG_DIR}/hypr/scripts/system/lock.sh"
        "${HOME}/.local/bin/ash"
    )
    for script in "${scripts[@]}"; do
        local name
        name=$(basename "${script}")
        check_cmd "${name} is executable" "test -x '${script}'" "required" \
            "chmod +x '${script}'"
    done

    # ── Audio ────────────────────────────────────────────────────────────────
    section "🔊 Audio System"
    check_cmd "PipeWire available"     "command -v pw-cli"      "required"
    check_cmd "wpctl available"        "command -v wpctl"       "required"
    check_cmd "pactl available"        "command -v pactl"       "optional"
    check_cmd "Audio sink exists"      "wpctl status 2>/dev/null | grep -q 'Audio'" "required"

    # ── GPU Detection ────────────────────────────────────────────────────────
    section "🎮 GPU & Display"
    check_cmd "GPU detected (lspci)"   "lspci | grep -qi 'vga\|3d\|display'" "required"
    check_cmd "DRM/KMS available"      "test -d /sys/class/drm" "required"
    check_cmd "Vulkan available"       "command -v vulkaninfo"  "optional"
    check_cmd "Mesa installed"         "command -v glxinfo || command -v eglinfo" "optional"

    # ── Network ──────────────────────────────────────────────────────────────
    section "🌐 Network"
    check_cmd "nmcli available"        "command -v nmcli"       "required"
    check_cmd "Network connected"      "nmcli -t -f STATE general | grep -q 'connected'" "optional"
    check_cmd "Internet access"        "curl -s --max-time 3 https://archlinux.org > /dev/null" "optional"

    # ── Dotfiles Structure ───────────────────────────────────────────────────
    section "📁 Dotfiles"
    check_dir  "~/.dotfiles exists"    "${DOTFILES_DIR}"
    check_dir  "ASH cache dir"         "${CACHE_DIR}"
    check_dir  "ASH logs dir"          "${CACHE_DIR}/logs"
    check_file "ASH CLI (ash)"         "${HOME}/.local/bin/ash"
    check_cmd  "ash in PATH"           "command -v ash" "required" \
        "ln -sf ~/.dotfiles/bin/ash ~/.local/bin/ash"

}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 REPORT
# ═══════════════════════════════════════════════════════════════════════════════

print_report() {
    local total=$(( PASS + FAIL + WARN + SKIP ))

    echo ""
    echo -e "  ${B}${MAGENTA}╔════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${MAGENTA}║${R}                  HEALTH REPORT                  ${B}${MAGENTA}║${R}"
    echo -e "  ${B}${MAGENTA}╠════════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${MAGENTA}║${R}  ${GREEN}✓ Passed:${R}   ${B}${PASS}${R} / ${total}                            ${B}${MAGENTA}║${R}"
    echo -e "  ${B}${MAGENTA}║${R}  ${YELLOW}⚠ Warnings:${R} ${B}${WARN}${R}                                  ${B}${MAGENTA}║${R}"
    echo -e "  ${B}${MAGENTA}║${R}  ${RED}✗ Failed:${R}   ${B}${FAIL}${R}                                  ${B}${MAGENTA}║${R}"
    echo -e "  ${B}${MAGENTA}╠════════════════════════════════════════════════╣${R}"

    if (( FAIL == 0 && WARN <= 5 )); then
        echo -e "  ${B}${MAGENTA}║${R}  ${GREEN}${B}🎉 EXCELLENT — System is healthy!${R}             ${B}${MAGENTA}║${R}"
    elif (( FAIL == 0 )); then
        echo -e "  ${B}${MAGENTA}║${R}  ${YELLOW}${B}✓ GOOD — Minor warnings only${R}                  ${B}${MAGENTA}║${R}"
    elif (( FAIL <= 3 )); then
        echo -e "  ${B}${MAGENTA}║${R}  ${YELLOW}${B}⚠ FAIR — ${FAIL} critical issue(s)${R}                ${B}${MAGENTA}║${R}"
    else
        echo -e "  ${B}${MAGENTA}║${R}  ${RED}${B}❌ POOR — ${FAIL} critical failures${R}                ${B}${MAGENTA}║${R}"
    fi

    echo -e "  ${B}${MAGENTA}╚════════════════════════════════════════════════╝${R}"
    echo ""

    if (( FAIL > 0 )); then
        echo -e "  ${CYAN}💡 To fix issues:${R}"
        echo -e "  ${DIM}  ash update     → Update dotfiles${R}"
        echo -e "  ${DIM}  ash reload     → Reload all config${R}"
        echo ""
    fi

    log "INFO" "doctor complete: pass=${PASS} warn=${WARN} fail=${FAIL}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"
    print_header
    run_checks
    print_report
    exit $(( FAIL > 0 ? 1 : 0 ))
}

main "$@"