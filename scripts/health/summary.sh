#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SYSTEM SUMMARY SCRIPT                        ║
# ║           8-section status dashboard with complete system overview         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CONFIG_DIR="${HOME}/.config"
readonly LOG_FILE="${CACHE_DIR}/logs/summary.log"

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly G='\033[92m'
readonly Y='\033[93m'
readonly C='\033[96m'
readonly M='\033[95m'
readonly DIM='\033[2m'
readonly RED='\033[91m'

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 DATA COLLECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_wallpaper() {
    local last="${CACHE_DIR}/wallpaper/last"
    [[ -f "${last}" ]] && basename "$(cat "${last}")" || "None"
}

get_theme_colors() {
    local colors_json="${CACHE_DIR}/colors/current.json"
    if [[ -f "${colors_json}" ]]; then
        python3 -c "
import json, sys
try:
    with open('${colors_json}') as f:
        data = json.load(f)
    for section, colors in data.items():
        if isinstance(colors, dict):
            for k, v in colors.items():
                print(f'{k}: {v}')
except:
    pass
" 2>/dev/null | head -8 || echo "Not generated"
    else
        echo "Not generated (run: ash theme pick)"
    fi
}

get_system_info() {
    echo "OS:       $(cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo "Kernel:   $(uname -r)"
    echo "Hostname: $(hostname)"
    echo "User:     ${USER}"
    echo "Shell:    $(fish --version 2>&1 | head -1 || echo 'unknown')"
    echo "Uptime:   $(uptime -p 2>/dev/null | sed 's/up //' || echo 'unknown')"
}

get_hardware_info() {
    local cpu ram gpu
    cpu=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs | cut -c1-50)
    ram=$(awk '/MemTotal/{printf "%.0fGB", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    gpu=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | xargs | cut -c1-50 || echo "Unknown")

    echo "CPU: ${cpu}"
    echo "RAM: ${ram}"
    echo "GPU: ${gpu}"
}

get_running_services() {
    local services=("Hyprland" "waybar" "dunst" "swww-daemon" "hypridle" "pipewire" "wireplumber")
    for svc in "${services[@]}"; do
        if pgrep -x "${svc}" &>/dev/null; then
            echo -e "  ${G}●${R} ${svc}"
        else
            echo -e "  ${DIM}○${R} ${svc}"
        fi
    done
}

get_waybar_modules() {
    local top_jsonc="${CONFIG_DIR}/waybar/configs/top.jsonc"
    if [[ -f "${top_jsonc}" ]]; then
        local count
        count=$(grep -c '"custom/' "${top_jsonc}" 2>/dev/null || echo "0")
        echo "Custom modules: ${count}"
        echo "Config: top.jsonc"
    else
        echo "Config: not found"
    fi
}

get_stats() {
    # Count scripts
    local scripts_count
    scripts_count=$(find "${CONFIG_DIR}/hypr/scripts" "${CONFIG_DIR}/waybar/scripts" \
        "${CONFIG_DIR}/rofi/scripts" "${CONFIG_DIR}/hyprlock/scripts" \
        -name "*.sh" 2>/dev/null | wc -l || echo "0")

    # Count config files
    local configs_count
    configs_count=$(find "${CONFIG_DIR}" -name "*.conf" -o -name "*.jsonc" \
        -o -name "*.json" -o -name "*.css" -o -name "*.toml" \
        -o -name "*.lua" -o -name "*.js" -o -name "*.fish" \
        2>/dev/null | wc -l || echo "0")

    echo "Shell scripts:   ${scripts_count}"
    echo "Config files:    ${configs_count}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 DISPLAY
# ═══════════════════════════════════════════════════════════════════════════════

print_header() {
    clear
    echo ""
    echo -e "  ${B}${M}╔════════════════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}      ${B}🚀 ASH DOTFILES v3.0 — SYSTEM SUMMARY${R}            ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}      ${DIM}$(date '+%A, %B %d %Y — %H:%M:%S')${R}               ${B}${M}║${R}"
    echo -e "  ${B}${M}╚════════════════════════════════════════════════════════════╝${R}"
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo -e "  ${B}${C}▐ ${title}${R}"
    echo -e "  ${DIM}$(printf '─%.0s' {1..55})${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    print_header

    # ── Section 1: System ────────────────────────────────────────────────────
    print_section "🖥️  SYSTEM INFORMATION"
    get_system_info | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${R}"
    done

    # ── Section 2: Hardware ──────────────────────────────────────────────────
    print_section "💻 HARDWARE"
    get_hardware_info | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${R}"
    done

    # ── Section 3: Theme Engine ──────────────────────────────────────────────
    print_section "🎨 THEME ENGINE"
    echo -e "  ${DIM}Wallpaper: $(get_wallpaper)${R}"
    echo ""
    get_theme_colors | head -6 | while IFS= read -r line; do
        local key="${line%%:*}"
        local val="${line##*: }"
        # Show color swatch
        if [[ "${val}" =~ ^#[0-9a-fA-F]{6}$ ]]; then
            local r g b
            r=$(( 16#${val:1:2} ))
            g=$(( 16#${val:3:2} ))
            b=$(( 16#${val:5:2} ))
            printf "  \033[38;2;%d;%d;%dm██\033[0m  %-12s %s\n" "${r}" "${g}" "${b}" "${key}" "${val}"
        fi
    done

    # ── Section 4: Running Services ───────────────────────────────────────────
    print_section "⚙️  RUNNING SERVICES"
    get_running_services

    # ── Section 5: Waybar ────────────────────────────────────────────────────
    print_section "📊 WAYBAR STATUS"
    get_waybar_modules | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${R}"
    done

    # ── Section 6: File Statistics ────────────────────────────────────────────
    print_section "📁 FILE STATISTICS"
    get_stats | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${R}"
    done

    # ── Section 7: Quick Status ───────────────────────────────────────────────
    print_section "✅ QUICK HEALTH CHECK"
    local checks=(
        "hyprland:command -v hyprland"
        "waybar:command -v waybar"
        "fish:command -v fish"
        "nvim:command -v nvim"
        "ash CLI:command -v ash"
        "theme colors:test -f ${CACHE_DIR}/colors/current.json"
        "JetBrains font:fc-list | grep -qi JetBrains"
    )

    for check in "${checks[@]}"; do
        local name="${check%%:*}"
        local cmd="${check##*:}"
        if eval "${cmd}" &>/dev/null; then
            echo -e "  ${G}✓${R} ${name}"
        else
            echo -e "  ${RED}✗${R} ${name}"
        fi
    done

    # ── Section 8: Quick Commands ─────────────────────────────────────────────
    print_section "🚀 QUICK COMMANDS"
    echo -e "  ${C}ash theme pick${R}     ${DIM}→ Pick wallpaper${R}"
    echo -e "  ${C}ash doctor${R}         ${DIM}→ Health check${R}"
    echo -e "  ${C}ash update${R}         ${DIM}→ Update everything${R}"
    echo -e "  ${C}ash reload${R}         ${DIM}→ Reload all configs${R}"
    echo -e "  ${C}ash backup${R}         ${DIM}→ Backup configuration${R}"
    echo -e "  ${C}ash help${R}           ${DIM}→ Full command reference${R}"

    echo ""
    log "INFO" "Summary complete"
}

main "$@"