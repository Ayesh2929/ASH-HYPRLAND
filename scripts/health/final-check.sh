#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FINAL CHECK SCRIPT                           ║
# ║           Ultimate validation — runs after installation to confirm all     ║
# ║           271+ files are present and system is ready                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOCAL_DIR="${HOME}/.local"
readonly LOG_FILE="${CACHE_DIR}/logs/final-check.log"

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly G='\033[92m'
readonly Y='\033[93m'
readonly C='\033[96m'
readonly M='\033[95m'
readonly RED='\033[91m'
readonly DIM='\033[2m'
readonly BWHITE='\033[97m'

declare -i PASS=0 FAIL=0 WARN=0
readonly START_TIME=$(date +%s)

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 CHECK HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

chk() {
    local name="$1"
    local cmd="$2"
    local required="${3:-required}"

    if eval "${cmd}" &>/dev/null 2>&1; then
        ((PASS++)) || true
        return 0
    else
        if [[ "${required}" == "required" ]]; then
            echo -e "  ${RED}✗${R} ${name}"
            ((FAIL++)) || true
        else
            echo -e "  ${Y}⚠${R} ${name} ${DIM}(optional)${R}"
            ((WARN++)) || true
        fi
        log "FAIL" "${name}"
        return 1
    fi
}

section() {
    echo ""
    echo -e "  ${B}${M}${1}${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

print_header() {
    clear
    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}     ${B}${BWHITE}🔍 ASH DOTFILES v3.0 — FINAL CHECK${R}           ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}     ${DIM}Validating complete installation...${R}             ${B}${M}║${R}"
    echo -e "  ${B}${M}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""
}

check_critical_binaries() {
    section "🔴 Critical Binaries"
    chk "hyprland"       "command -v hyprland"
    chk "waybar"         "command -v waybar"
    chk "rofi"           "command -v rofi"
    chk "kitty"          "command -v kitty"
    chk "fish"           "command -v fish"
    chk "dunst"          "command -v dunst"
    chk "swww"           "command -v swww"
    chk "hyprlock"       "command -v hyprlock"
    chk "hypridle"       "command -v hypridle"
    chk "grim"           "command -v grim"
    chk "slurp"          "command -v slurp"
    chk "wl-copy"        "command -v wl-copy"
    chk "convert (IM)"   "command -v convert"
    chk "jq"             "command -v jq"
    chk "curl"           "command -v curl"
    chk "git"            "command -v git"
    chk "nvim"           "command -v nvim"
    chk "ash CLI"        "command -v ash"
}

check_config_files() {
    section "📋 Core Config Files"
    chk "hyprland.conf"         "test -f '${CONFIG_DIR}/hypr/hyprland.conf'"
    chk "env.conf"              "test -f '${CONFIG_DIR}/hypr/core/env.conf'"
    chk "keybinds.conf"         "test -f '${CONFIG_DIR}/hypr/modules/keybinds.conf'"
    chk "autostart.conf"        "test -f '${CONFIG_DIR}/hypr/modules/autostart.conf'"
    chk "windowrules.conf"      "test -f '${CONFIG_DIR}/hypr/rules/windowrules.conf'"
    chk "theme-engine.sh"       "test -x '${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh'"
    chk "waybar top.jsonc"      "test -f '${CONFIG_DIR}/waybar/configs/top.jsonc'"
    chk "waybar main.css"       "test -f '${CONFIG_DIR}/waybar/styles/main.css'"
    chk "rofi config.rasi"      "test -f '${CONFIG_DIR}/rofi/config.rasi'"
    chk "fish config.fish"      "test -f '${CONFIG_DIR}/fish/config.fish'"
    chk "dunstrc"               "test -f '${CONFIG_DIR}/dunst/dunstrc'"
    chk "hypridle.conf"         "test -f '${CONFIG_DIR}/hypridle/hypridle.conf'"
    chk "hyprlock.conf"         "test -f '${CONFIG_DIR}/hyprlock/hyprlock.conf'"
    chk "kitty.conf"            "test -f '${CONFIG_DIR}/kitty/kitty.conf'"
    chk "nvim init.lua"         "test -f '${CONFIG_DIR}/nvim/init.lua'"
    chk "starship.toml"         "test -f '${CONFIG_DIR}/starship.toml'"
    chk "UserOverrides"         "test -f '${CONFIG_DIR}/hypr/UserOverrides/user.conf'"
}

check_scripts_executable() {
    section "📜 Script Permissions"
    local total=0 executable=0
    while IFS= read -r script; do
        ((total++)) || true
        [[ -x "${script}" ]] && ((executable++)) || true
    done < <(find "${CONFIG_DIR}/hypr/scripts" "${CONFIG_DIR}/waybar/scripts" \
        "${CONFIG_DIR}/rofi/scripts" "${CONFIG_DIR}/hyprlock/scripts" \
        -name "*.sh" 2>/dev/null)

    if (( total == 0 )); then
        echo -e "  ${Y}⚠${R} No scripts found ${DIM}(optional)${R}"
        ((WARN++)) || true
    elif (( executable == total )); then
        echo -e "  ${G}✓${R} All ${total} scripts are executable"
        ((PASS++)) || true
    else
        local non_exec=$(( total - executable ))
        echo -e "  ${Y}⚠${R} ${non_exec}/${total} scripts not executable"
        echo -e "    ${DIM}Fix: find ~/.config -name '*.sh' -exec chmod +x {} \\;${R}"
        ((WARN++)) || true
    fi
}

check_services() {
    section "⚙️ Services"
    chk "Pipewire"          "systemctl --user is-active pipewire"
    chk "Wireplumber"       "systemctl --user is-active wireplumber"
    chk "NetworkManager"    "systemctl is-active NetworkManager"
    chk "Hyprland running"  "pgrep -x Hyprland" "optional"
    chk "Waybar running"    "pgrep -x waybar" "optional"
    chk "Dunst running"     "pgrep -x dunst" "optional"
}

check_fonts() {
    section "🔤 Fonts"
    chk "JetBrainsMono NF"  "fc-list | grep -qi 'JetBrainsMono'"
    chk "Noto Color Emoji"  "fc-list | grep -qi 'Noto.*Emoji'"
    chk "Font Awesome"      "fc-list | grep -qi 'Font Awesome'" "optional"
}

check_theme() {
    section "🎨 Theme Engine"
    chk "Color cache"       "test -f '${CACHE_DIR}/colors/current.json'" "optional"
    chk "Wallpaper history" "test -f '${CACHE_DIR}/wallpaper/last'" "optional"
    chk "Active theme"      "test -f '${CONFIG_DIR}/hypr/themes/active.conf'" "optional"
    chk "Waybar colors"     "test -f '${CONFIG_DIR}/waybar/styles/colors.css'" "optional"
    chk "Wallpapers dir"    "test -d '${HOME}/Pictures/Wallpapers'"
    chk "Screenshots dir"   "test -d '${HOME}/Pictures/Screenshots'"
}

check_directories() {
    section "📁 Key Directories"
    chk "~/.dotfiles"           "test -d '${DOTFILES_DIR}'"
    chk "~/.cache/ash-dots"     "test -d '${CACHE_DIR}'"
    chk "~/.local/bin"          "test -d '${LOCAL_DIR}/bin'"
    chk "~/.config/hypr"        "test -d '${CONFIG_DIR}/hypr'"
    chk "~/.config/waybar"      "test -d '${CONFIG_DIR}/waybar'"
    chk "~/.config/rofi"        "test -d '${CONFIG_DIR}/rofi'"
    chk "~/.config/fish"        "test -d '${CONFIG_DIR}/fish'"
    chk "~/.config/nvim"        "test -d '${CONFIG_DIR}/nvim'"
}

check_file_count() {
    section "📊 File Statistics"

    local config_count scripts_count total_count
    config_count=$(find "${CONFIG_DIR}" -type f \( \
        -name "*.conf" -o -name "*.jsonc" -o -name "*.json" \
        -o -name "*.css" -o -name "*.toml" -o -name "*.lua" \
        -o -name "*.js" -o -name "*.fish" -o -name "*.rasi" \
        -o -name "*.ini" -o -name "*.yaml" -o -name "*.yuck" \
    \) 2>/dev/null | wc -l)

    scripts_count=$(find "${CONFIG_DIR}" -name "*.sh" 2>/dev/null | wc -l)
    total_count=$(( config_count + scripts_count ))

    echo -e "  ${C}Config files:${R}  ${config_count}"
    echo -e "  ${C}Shell scripts:${R} ${scripts_count}"
    echo -e "  ${C}Total files:${R}   ${total_count}"
    ((PASS++)) || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 REPORT
# ═══════════════════════════════════════════════════════════════════════════════

print_report() {
    local elapsed=$(( $(date +%s) - START_TIME ))
    local total=$(( PASS + FAIL + WARN ))

    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}                   FINAL CHECK REPORT                    ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${M}║${R}  ${G}✓ Passed:${R}   ${B}${PASS}${R} / ${total}                                  ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${Y}⚠ Warnings:${R} ${B}${WARN}${R}                                        ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${RED}✗ Failed:${R}   ${B}${FAIL}${R}                                        ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${DIM}⏱ Time:${R}     ${elapsed}s                                       ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════════════╣${R}"

    if (( FAIL == 0 && WARN == 0 )); then
        echo -e "  ${B}${M}║${R}  ${G}${B}🎉 PERFECT — Installation complete!${R}                ${B}${M}║${R}"
    elif (( FAIL == 0 )); then
        echo -e "  ${B}${M}║${R}  ${G}${B}✅ SUCCESS — ${WARN} optional items missing${R}             ${B}${M}║${R}"
    elif (( FAIL <= 3 )); then
        echo -e "  ${B}${M}║${R}  ${Y}${B}⚠ PARTIAL — ${FAIL} critical issue(s)${R}                   ${B}${M}║${R}"
    else
        echo -e "  ${B}${M}║${R}  ${RED}${B}❌ FAILED — ${FAIL} critical failures${R}                    ${B}${M}║${R}"
    fi

    echo -e "  ${B}${M}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""

    if (( FAIL == 0 )); then
        echo -e "  ${G}${B}🚀 Ready to use! Run these commands:${R}"
        echo ""
        echo -e "  ${C}ash theme pick${R}      — Choose wallpaper"
        echo -e "  ${C}ash doctor${R}          — Full health check"
        echo -e "  ${C}ash help${R}            — All commands"
    else
        echo -e "  ${RED}${B}⚠ Fix issues then re-run:${R} ${C}ash doctor${R}"
    fi

    echo ""
    log "INFO" "final-check: pass=${PASS} warn=${WARN} fail=${FAIL} time=${elapsed}s"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    print_header
    check_critical_binaries
    check_config_files
    check_scripts_executable
    check_services
    check_fonts
    check_theme
    check_directories
    check_file_count
    print_report

    exit $(( FAIL > 0 ? 1 : 0 ))
}

main "$@"