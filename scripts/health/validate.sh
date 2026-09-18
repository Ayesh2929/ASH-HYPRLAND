#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FILE VALIDATOR                               ║
# ║           Validate all 271+ config files exist and are correct             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CONFIG_DIR="${HOME}/.config"
readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/validate.log"

# Colors
readonly R=$'\033[0m'
readonly B=$'\033[1m'
readonly G=$'\033[92m'
readonly Y=$'\033[93m'
readonly RED=$'\033[91m'
readonly C=$'\033[96m'
readonly M=$'\033[95m'
readonly DIM=$'\033[2m'

declare -i PASS=0 FAIL=0 WARN=0 SKIP=0
declare -a MISSING=()
declare -a NON_EXEC=()

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

check_file() {
    local path="$1"
    local required="${2:-required}"
    local check_exec="${3:-false}"

    local short_path="${path/$HOME/~}"

    if [[ ! -f "${path}" ]]; then
        if [[ "${required}" == "required" ]]; then
            echo -e "  ${RED}✗${R} ${short_path}"
            ((FAIL++)) || true
            MISSING+=("${short_path}")
            log "FAIL" "Missing: ${path}"
        else
            echo -e "  ${DIM}─${R} ${short_path} ${DIM}(optional)${R}"
            ((SKIP++)) || true
        fi
        return 0
    fi

    if [[ "${check_exec}" == "true" ]] && [[ ! -x "${path}" ]]; then
        echo -e "  ${Y}⚠${R} ${short_path} ${Y}(not executable)${R}"
        ((WARN++)) || true
        NON_EXEC+=("${short_path}")
        log "WARN" "Not executable: ${path}"
        return 0
    fi

    echo -e "  ${G}✓${R} ${short_path}"
    ((PASS++)) || true
    log "PASS" "${path}"
}

check_dir() {
    local path="$1"
    local required="${2:-required}"

    local short_path="${path/$HOME/~}"

    if [[ ! -d "${path}" ]]; then
        if [[ "${required}" == "required" ]]; then
            echo -e "  ${RED}✗${R} ${short_path}/ ${RED}(directory)${R}"
            ((FAIL++)) || true
            log "FAIL" "Missing dir: ${path}"
        else
            echo -e "  ${DIM}─${R} ${short_path}/ ${DIM}(optional dir)${R}"
            ((SKIP++)) || true
        fi
        return 0
    fi

    echo -e "  ${G}✓${R} ${short_path}/"
    ((PASS++)) || true
}

section() {
    echo ""
    echo -e "  ${B}${M}${1}${R}"
    echo -e "  ${DIM}$(printf '─%.0s' {1..50})${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 FILE MANIFEST
# ═══════════════════════════════════════════════════════════════════════════════

validate_all() {

    section "📁 Dotfiles Repository"
    check_dir  "${DOTFILES_DIR}"
    check_file "${DOTFILES_DIR}/install.sh"                          required  true
    check_file "${DOTFILES_DIR}/quickstart.sh"                       required  true
    check_file "${DOTFILES_DIR}/README.md"
    check_file "${DOTFILES_DIR}/.gitignore"                          optional
    check_file "${DOTFILES_DIR}/LICENSE"                             optional

    section "📁 Dotfiles Scripts"
    check_file "${DOTFILES_DIR}/scripts/core/update.sh"              required  true
    check_file "${DOTFILES_DIR}/scripts/core/backup.sh"              required  true
    check_file "${DOTFILES_DIR}/scripts/core/restore.sh"             required  true
    check_file "${DOTFILES_DIR}/scripts/health/doctor.sh"            required  true
    check_file "${DOTFILES_DIR}/scripts/health/validate.sh"          required  true
    check_file "${DOTFILES_DIR}/scripts/health/summary.sh"           optional

    section "🖥️ Hyprland Core"
    check_file "${CONFIG_DIR}/hypr/hyprland.conf"                    required
    check_file "${CONFIG_DIR}/hypr/core/env.conf"                    required
    check_file "${CONFIG_DIR}/hypr/core/monitors.conf"               required
    check_file "${CONFIG_DIR}/hypr/core/input.conf"                  required
    check_file "${CONFIG_DIR}/hypr/core/general.conf"                required
    check_file "${CONFIG_DIR}/hypr/core/cursor.conf"                 required
    check_file "${CONFIG_DIR}/hypr/core/binds.conf"                  required

    section "🖥️ Hyprland Modules"
    check_file "${CONFIG_DIR}/hypr/modules/decorations.conf"         required
    check_file "${CONFIG_DIR}/hypr/modules/animations.conf"          required
    check_file "${CONFIG_DIR}/hypr/modules/blur.conf"                required
    check_file "${CONFIG_DIR}/hypr/modules/lighting.conf"            required
    check_file "${CONFIG_DIR}/hypr/modules/layouts.conf"             required
    check_file "${CONFIG_DIR}/hypr/modules/gestures.conf"            required
    check_file "${CONFIG_DIR}/hypr/modules/misc.conf"                required
    check_file "${CONFIG_DIR}/hypr/modules/submaps.conf"             required
    check_file "${CONFIG_DIR}/hypr/modules/media-keys.conf"          required
    check_file "${CONFIG_DIR}/hypr/modules/keybinds.conf"            required
    check_file "${CONFIG_DIR}/hypr/modules/autostart.conf"           required

    section "🖥️ Hyprland Rules"
    check_file "${CONFIG_DIR}/hypr/rules/windowrules.conf"           required
    check_file "${CONFIG_DIR}/hypr/rules/workspacerules.conf"        required
    check_file "${CONFIG_DIR}/hypr/rules/layerrules.conf"            required

    section "🖥️ Hyprland Scripts"
    check_file "${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh"    required  true
    check_file "${CONFIG_DIR}/hypr/scripts/theme/wallpaper-picker.sh" required true
    check_file "${CONFIG_DIR}/hypr/scripts/utils/screenshot.sh"      required  true
    check_file "${CONFIG_DIR}/hypr/scripts/media/volume.sh"          required  true
    check_file "${CONFIG_DIR}/hypr/scripts/media/brightness.sh"      required  true
    check_file "${CONFIG_DIR}/hypr/scripts/media/recorder.sh"        required  true
    check_file "${CONFIG_DIR}/hypr/scripts/media/player-picker.sh"   optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/system/lock.sh"           required  true
    check_file "${CONFIG_DIR}/hypr/scripts/system/power-profile.sh"  required  true
    check_file "${CONFIG_DIR}/hypr/scripts/system/session-restore.sh" optional true
    check_file "${CONFIG_DIR}/hypr/scripts/system/reload-all.sh"     optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/system/idle-inhibit.sh"   optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/hardware/touchpad.sh"     optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/hardware/monitor-layout.sh" optional true
    check_file "${CONFIG_DIR}/hypr/scripts/hardware/magnifier.sh"    optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/hardware/dpms.sh"         optional  true
    check_file "${CONFIG_DIR}/hypr/scripts/network/wifi-toggle.sh"   required  true
    check_file "${CONFIG_DIR}/hypr/scripts/network/bluetooth-toggle.sh" optional true

    section "📊 Waybar"
    check_file "${CONFIG_DIR}/waybar/configs/top.jsonc"              required
    check_file "${CONFIG_DIR}/waybar/styles/main.css"                required
    check_file "${CONFIG_DIR}/waybar/styles/animations.css"          required
    check_file "${CONFIG_DIR}/waybar/scripts/utils/weather.sh"       optional  true
    check_file "${CONFIG_DIR}/waybar/scripts/media/player.sh"        optional  true
    check_file "${CONFIG_DIR}/waybar/scripts/system/updates.sh"      optional  true
    check_file "${CONFIG_DIR}/waybar/scripts/hardware/gpu.sh"        optional  true
    check_file "${CONFIG_DIR}/waybar/scripts/hardware/disk.sh"       optional  true

    section "🚀 Rofi"
    check_file "${CONFIG_DIR}/rofi/config.rasi"                      required
    check_file "${CONFIG_DIR}/rofi/scripts/launcher.sh"              required  true
    check_file "${CONFIG_DIR}/rofi/scripts/powermenu.sh"             required  true
    check_file "${CONFIG_DIR}/rofi/scripts/window-switcher.sh"       optional  true
    check_file "${CONFIG_DIR}/rofi/scripts/emoji.sh"                 optional  true

    section "🐟 Fish Shell"
    check_file "${CONFIG_DIR}/fish/config.fish"                      required
    check_file "${CONFIG_DIR}/fish/conf.d/30-abbr.fish"              required
    check_file "${CONFIG_DIR}/fish/conf.d/00-env.fish"               required
    check_file "${CONFIG_DIR}/fish/conf.d/50-wayland.fish"           optional
    check_file "${CONFIG_DIR}/fish/conf.d/40-keybinds.fish"          optional
    check_file "${CONFIG_DIR}/fish/functions/fish_prompt.fish"        required
    check_file "${CONFIG_DIR}/fish/functions/fish_greeting.fish"      required
    check_file "${CONFIG_DIR}/fish/functions/extract.fish"            optional
    check_file "${CONFIG_DIR}/fish/functions/sysinfo.fish"            optional
    check_file "${CONFIG_DIR}/fish/completions/ash.fish"              optional

    section "📝 Neovim"
    check_file "${CONFIG_DIR}/nvim/init.lua"                         required
    check_file "${CONFIG_DIR}/nvim/lua/core/options.lua"             required
    check_file "${CONFIG_DIR}/nvim/lua/core/keymaps.lua"             required
    check_file "${CONFIG_DIR}/nvim/lua/core/autocmds.lua"            required
    check_file "${CONFIG_DIR}/nvim/lua/core/lazy.lua"                required
    check_file "${CONFIG_DIR}/nvim/lua/plugins/ui.lua"               required
    check_file "${CONFIG_DIR}/nvim/lua/plugins/lsp.lua"              required
    check_file "${CONFIG_DIR}/nvim/lua/plugins/editor.lua"           optional
    check_file "${CONFIG_DIR}/nvim/lua/plugins/tools.lua"            optional
    check_file "${CONFIG_DIR}/nvim/lua/plugins/debug.lua"            optional
    check_file "${CONFIG_DIR}/nvim/lua/plugins/lang.lua"             optional
    check_file "${CONFIG_DIR}/nvim/lua/plugins/ai.lua"               optional
    check_file "${CONFIG_DIR}/nvim/lua/lsp/init.lua"                 required
    check_file "${CONFIG_DIR}/nvim/lua/lsp/servers.lua"              required
    check_file "${CONFIG_DIR}/nvim/lua/themes/ash.lua"               required
    check_file "${CONFIG_DIR}/nvim/lua/ui/statusline.lua"            optional
    check_file "${CONFIG_DIR}/nvim/after/plugin/lsp-attach.lua"      optional
    check_file "${CONFIG_DIR}/nvim/after/plugin/highlights.lua"      optional
    check_file "${CONFIG_DIR}/nvim/after/plugin/format.lua"          optional

    section "🔒 Hyprlock + Hypridle"
    check_file "${CONFIG_DIR}/hyprlock/hyprlock.conf"                required
    check_file "${CONFIG_DIR}/hyprlock/scripts/battery.sh"           required  true
    check_file "${CONFIG_DIR}/hyprlock/scripts/network.sh"           required  true
    check_file "${CONFIG_DIR}/hyprlock/scripts/player.sh"            required  true
    check_file "${CONFIG_DIR}/hyprlock/scripts/sysinfo.sh"           required  true
    check_file "${CONFIG_DIR}/hypridle/hypridle.conf"                required

    section "💻 Terminals"
    check_file "${CONFIG_DIR}/kitty/kitty.conf"                      required
    check_file "${CONFIG_DIR}/wezterm/wezterm.lua"                   optional
    check_file "${CONFIG_DIR}/alacritty/alacritty.toml"              optional

    section "🔔 Notifications"
    check_file "${CONFIG_DIR}/dunst/dunstrc"                         required
    check_file "${CONFIG_DIR}/swaync/config.json"                    optional
    check_file "${CONFIG_DIR}/swaync/style.css"                      optional

    section "🎨 Theming"
    check_file "${CONFIG_DIR}/gtk-3.0/settings.ini"                  required
    check_file "${CONFIG_DIR}/gtk-4.0/settings.ini"                  optional
    check_file "${CONFIG_DIR}/qt5ct/qt5ct.conf"                      optional
    check_file "${CONFIG_DIR}/starship.toml"                         required

    section "🎵 Media"
    check_file "${CONFIG_DIR}/mpv/mpv.conf"                          optional
    check_file "${CONFIG_DIR}/mpv/input.conf"                        optional
    check_file "${CONFIG_DIR}/mpv/scripts/autoload.lua"              optional

    section "📊 System Tools"
    check_file "${CONFIG_DIR}/btop/btop.conf"                        optional
    check_file "${CONFIG_DIR}/fastfetch/config.jsonc"                optional

    section "⚙️ System Integration"
    check_file "${CONFIG_DIR}/environment.d/ash.conf"                optional
    check_file "${CONFIG_DIR}/mimeapps.list"                        optional
    check_file "${CONFIG_DIR}/electron-flags.conf"                   optional
    check_file "${CONFIG_DIR}/ripgrep/config"                        optional

    section "🔌 Systemd Services"
    check_file "${CONFIG_DIR}/systemd/user/ash-theme.service"        optional
    check_file "${CONFIG_DIR}/systemd/user/ash-idle.service"         optional
    check_file "${CONFIG_DIR}/systemd/user/ash-clipboard.service"    optional
    check_file "${CONFIG_DIR}/systemd/user/ash-battery.service"      optional

    section "🖥️ CLI Tools"
    check_file "${HOME}/.local/bin/ash"                              required  true
    check_file "${HOME}/.local/bin/ash-theme"                        optional  true
    check_file "${HOME}/.local/bin/ash-doctor"                       optional  true
    check_file "${HOME}/.local/bin/ash-update"                       optional  true

    section "📋 Desktop Entries"
    check_file "${HOME}/.local/share/applications/ash-theme.desktop"     optional
    check_file "${HOME}/.local/share/applications/ash-screenshot.desktop" optional

    section "🎨 AGS / EWW"
    check_file "${CONFIG_DIR}/ags/config.js"                         optional
    check_file "${CONFIG_DIR}/ags/modules/bar.js"                    optional
    check_file "${CONFIG_DIR}/eww/dashboard/eww.yuck"                optional

    section "📚 Documentation"
    check_file "${DOTFILES_DIR}/README.md"                           required
    check_file "${DOTFILES_DIR}/docs/KEYBINDS.md"                    optional
    check_file "${DOTFILES_DIR}/docs/THEMING.md"                     optional
    check_file "${DOTFILES_DIR}/docs/TROUBLESHOOTING.md"             optional

}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 REPORT
# ═══════════════════════════════════════════════════════════════════════════════

print_report() {
    local total=$(( PASS + FAIL + WARN + SKIP ))

    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}         VALIDATION REPORT                      ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${M}║${R}  ${G}✓ Present:${R}   ${B}${PASS}${R} / ${total}                          ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${Y}⚠ Warnings:${R} ${B}${WARN}${R}                                ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${RED}✗ Missing:${R}  ${B}${FAIL}${R}                                ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${DIM}─ Optional:${R} ${SKIP}                                ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════╣${R}"

    if (( FAIL == 0 )); then
        echo -e "  ${B}${M}║${R}  ${G}${B}✅ ALL REQUIRED FILES PRESENT${R}               ${B}${M}║${R}"
    else
        echo -e "  ${B}${M}║${R}  ${RED}${B}❌ ${FAIL} REQUIRED FILES MISSING${R}                ${B}${M}║${R}"
    fi

    echo -e "  ${B}${M}╚══════════════════════════════════════════════════╝${R}"

    if (( ${#MISSING[@]} > 0 )); then
        echo ""
        echo -e "  ${RED}${B}Missing Files:${R}"
        for f in "${MISSING[@]}"; do
            echo -e "    ${RED}•${R} ${f}"
        done
    fi

    if (( ${#NON_EXEC[@]} > 0 )); then
        echo ""
        echo -e "  ${Y}${B}Non-executable Scripts:${R}"
        echo -e "  ${DIM}Fix: find ~/.config -name '*.sh' -exec chmod +x {} \\;${R}"
        for f in "${NON_EXEC[@]}"; do
            echo -e "    ${Y}•${R} ${f}"
        done
    fi

    echo ""
    log "INFO" "Validate: pass=${PASS} warn=${WARN} fail=${FAIL} skip=${SKIP}"
}

verify_file_count() {
    echo ""
    echo -e "  \033[1m\033[95m📊 FILE COUNT VERIFICATION\033[0m"
    echo -e "  \033[2m$(printf '─%.0s' {1..50})\033[0m"

    local config_files scripts_configs total
    config_files=$(find "${HOME}/.config" -type f \( \
        -name "*.conf" -o -name "*.rasi" -o -name "*.css" -o -name "*.jsonc" \
        -o -name "*.json" -o -name "*.toml" -o -name "*.lua" -o -name "*.js" \
        -o -name "*.fish" -o -name "*.yaml" -o -name "*.ini" -o -name "*.yuck" \
        -o -name "*.scss" -o -name "*.glsl" \
    \) 2>/dev/null | wc -l)

    scripts_configs=$(find "${HOME}/.config" -name "*.sh" 2>/dev/null | wc -l)
    total=$(( config_files + scripts_configs ))

    echo -e "  Config files:   \033[97m${config_files}\033[0m"
    echo -e "  Shell scripts:  \033[97m${scripts_configs}\033[0m"
    echo -e "  Total:          \033[97m${total}\033[0m"

    local dotfiles_scripts
    dotfiles_scripts=$(find "${HOME}/.dotfiles/scripts" -name "*.sh" 2>/dev/null | wc -l)
    echo -e "  Dotfiles scripts: \033[97m${dotfiles_scripts}\033[0m"

    if (( total >= 200 )); then
        echo -e "\n  \033[92m✓ File count verified — 200+ files present\033[0m"
    else
        echo -e "\n  \033[93m⚠ Low file count (${total}) — some files may be missing\033[0m"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    echo ""
    echo -e "  ${B}${M}🔍 ASH Dotfiles v3.0 — File Validator${R}"
    echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${R}"

    validate_all
    print_report
    verify_file_count

    exit $(( FAIL > 0 ? 1 : 0 ))
}

main "$@"

