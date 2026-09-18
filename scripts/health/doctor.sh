#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.1.0 — COMPLETE DOCTOR SCRIPT                     ║
# ║           60+ health checks covering all system components                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOCAL_DIR="${HOME}/.local"
readonly LOG_FILE="${CACHE_DIR}/logs/doctor.log"
readonly START_TIME=$(date +%s)

# Colors
readonly R=$'\033[0m' B=$'\033[1m' G=$'\033[92m' Y=$'\033[93m'
readonly RED=$'\033[91m' C=$'\033[96m' M=$'\033[95m' DIM=$'\033[2m'

declare -i PASS=0 FAIL=0 WARN=0
declare -a FAILURES=()
declare -a WARNINGS=()

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 CHECK HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

pass() {
    echo -e "  ${G}✓${R} ${1}"
    ((PASS++)) || true
    log "PASS" "${1}"
}

fail() {
    echo -e "  ${RED}✗${R} ${1}"
    [[ -n "${2:-}" ]] && echo -e "    ${DIM}→ Fix: ${2}${R}"
    ((FAIL++)) || true
    FAILURES+=("${1}")
    log "FAIL" "${1}"
}

warn() {
    echo -e "  ${Y}⚠${R} ${1} ${DIM}(optional)${R}"
    [[ -n "${2:-}" ]] && echo -e "    ${DIM}→ ${2}${R}"
    ((WARN++)) || true
    WARNINGS+=("${1}")
    log "WARN" "${1}"
}

chk() {
    local name="$1" cmd="$2" req="${3:-required}" fix="${4:-}"
    if eval "${cmd}" &>/dev/null 2>&1; then
        pass "${name}"
    else
        [[ "${req}" == "required" ]] && fail "${name}" "${fix}" || warn "${name}" "${fix}"
    fi
}

section() {
    echo ""
    echo -e "  ${B}${M}━━━ ${1} ━━━${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 HEADER
# ═══════════════════════════════════════════════════════════════════════════════

print_header() {
    clear
    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}    ${B}🏥 ASH DOTFILES v3.1.0 — HEALTH CHECK${R}            ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}    ${DIM}$(date '+%A, %B %d %Y — %H:%M:%S')${R}               ${B}${M}║${R}"
    echo -e "  ${B}${M}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 ALL CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

run_all_checks() {

    # ── Environment ──────────────────────────────────────────────────────────
    section "🌐 Environment"
    chk "Wayland session"          "test -n '${WAYLAND_DISPLAY:-}'"         required "Start Hyprland"
    chk "XDG_RUNTIME_DIR"          "test -n '${XDG_RUNTIME_DIR:-}'"         required
    chk "XDG_SESSION_TYPE=wayland" "[[ '${XDG_SESSION_TYPE:-}' == 'wayland' ]]" required
    chk "Not running as root"      "test '${EUID:-0}' -ne 0"                required
    chk "HOME directory exists"    "test -d '${HOME}'"                       required
    chk "~/.local/bin in PATH"     "echo \$PATH | grep -q '${HOME}/.local/bin'" required \
        "Add to profile: export PATH=\$HOME/.local/bin:\$PATH"

    # ── Critical Binaries ────────────────────────────────────────────────────
    section "🔴 Critical Binaries"
    local critical_bins=(
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
        "nvim:nvim"
        "python3:python3"
        "ash CLI:ash"
    )

    for entry in "${critical_bins[@]}"; do
        local name="${entry%%:*}" bin="${entry##*:}"
        chk "${name}" "command -v ${bin}" required "paru -S ${bin}"
    done

    # ── Optional Tools ───────────────────────────────────────────────────────
    section "🟡 Optional Tools"
    local optional_bins=(
        "swappy:swappy"
        "hyprpicker:hyprpicker"
        "wf-recorder:wf-recorder"
        "playerctl:playerctl"
        "pamixer:pamixer"
        "brightnessctl:brightnessctl"
        "cliphist:cliphist"
        "tesseract (OCR):tesseract"
        "swaync:swaync"
        "btop:btop"
        "fastfetch:fastfetch"
        "starship:starship"
        "fzf:fzf"
        "fd:fd"
        "ripgrep:rg"
        "bat:bat"
        "eza:eza"
        "zoxide:zoxide"
        "delta:delta"
        "lazygit:lazygit"
        "sqlite3 (analytics):sqlite3"
        "socat (analytics):socat"
        "ollama (AI themes):ollama"
    )

    for entry in "${optional_bins[@]}"; do
        local name="${entry%%:*}" bin="${entry##*:}"
        chk "${name}" "command -v ${bin}" optional "paru -S ${bin}"
    done

    # ── Running Processes ────────────────────────────────────────────────────
    section "⚙️ Running Processes"
    chk "Hyprland"          "pgrep -x Hyprland"      required
    chk "Waybar"            "pgrep -x waybar"         required
    chk "Dunst"             "pgrep -x dunst"           required
    chk "Pipewire"          "pgrep -x pipewire"        required
    chk "Wireplumber"       "pgrep -x wireplumber"     required
    chk "swww-daemon"       "pgrep -x swww-daemon"     optional "Run: swww-daemon &"
    chk "hypridle"          "pgrep -x hypridle"        optional "Run: hypridle &"
    chk "NetworkManager"    "systemctl is-active NetworkManager" required

    # ── Fonts ────────────────────────────────────────────────────────────────
    section "🔤 Fonts"
    chk "JetBrainsMono NF"  "fc-list | grep -qi 'JetBrainsMono'"   required "paru -S ttf-jetbrains-mono-nerd"
    chk "Noto Color Emoji"  "fc-list | grep -qi 'Noto.*Emoji'"     required "sudo pacman -S noto-fonts-emoji"
    chk "Font Awesome"      "fc-list | grep -qi 'Font Awesome'"    optional "paru -S ttf-font-awesome"
    chk "Symbols Nerd Font" "fc-list | grep -qi 'Symbols Nerd'"   optional "paru -S ttf-nerd-fonts-symbols"

    # ── Config Files ─────────────────────────────────────────────────────────
    section "📋 Core Config Files"
    local configs=(
        "${CONFIG_DIR}/hypr/hyprland.conf"
        "${CONFIG_DIR}/hypr/core/env.conf"
        "${CONFIG_DIR}/hypr/core/monitors.conf"
        "${CONFIG_DIR}/hypr/modules/keybinds.conf"
        "${CONFIG_DIR}/hypr/modules/autostart.conf"
        "${CONFIG_DIR}/hypr/UserOverrides/user.conf"
        "${CONFIG_DIR}/hypr/scripts/theme/theme-engine.sh"
        "${CONFIG_DIR}/waybar/configs/top.jsonc"
        "${CONFIG_DIR}/waybar/styles/main.css"
        "${CONFIG_DIR}/rofi/config.rasi"
        "${CONFIG_DIR}/fish/config.fish"
        "${CONFIG_DIR}/kitty/kitty.conf"
        "${CONFIG_DIR}/dunst/dunstrc"
        "${CONFIG_DIR}/hypridle/hypridle.conf"
        "${CONFIG_DIR}/hyprlock/hyprlock.conf"
        "${CONFIG_DIR}/nvim/init.lua"
        "${CONFIG_DIR}/starship.toml"
    )

    for cfg in "${configs[@]}"; do
        local short="${cfg/$HOME/~}"
        chk "${short}" "test -f '${cfg}'" required
    done

    # ── Unique Feature Scripts ────────────────────────────────────────────────
    section "🌟 Unique Feature Scripts"
    local unique_scripts=(
        "${CONFIG_DIR}/hypr/scripts/theme/album-art-theme.sh:ash music"
        "${CONFIG_DIR}/hypr/scripts/theme/health-score.sh:ash score"
        "${CONFIG_DIR}/hypr/scripts/theme/workspace-profiles.sh:ash workspace"
        "${CONFIG_DIR}/hypr/scripts/theme/smart-wallpaper.sh:ash smart"
        "${CONFIG_DIR}/hypr/scripts/analytics/desktop-analytics.sh:ash analytics"
        "${CONFIG_DIR}/hypr/scripts/theme/ai-theme.sh:ash theme ai"
        "${CONFIG_DIR}/hypr/scripts/theme/theme-undo.sh:ash theme undo"
        "${CONFIG_DIR}/hypr/scripts/theme/light-theme.sh:ash theme mode"
        "${CONFIG_DIR}/hypr/scripts/theme/context-theme.sh:ash context"
    )

    for entry in "${unique_scripts[@]}"; do
        local path="${entry%%:*}" cmd="${entry##*:}"
        local short="${path/$HOME/~}"
        chk "${cmd} (${short##*/})" "test -x '${path}'" required \
            "chmod +x '${path}'"
    done

    # ── Script Permissions ───────────────────────────────────────────────────
    section "📜 Script Permissions"
    local total=0 exec_count=0
    while IFS= read -r script; do
        ((total++)) || true
        [[ -x "${script}" ]] && ((exec_count++)) || true
    done < <(find "${CONFIG_DIR}" -name "*.sh" 2>/dev/null)

    if (( total == 0 )); then
        warn "No scripts found"
    elif (( exec_count == total )); then
        pass "All ${total} scripts are executable"
    else
        local non_exec=$(( total - exec_count ))
        fail "${non_exec}/${total} scripts not executable" \
            "find ~/.config -name '*.sh' -exec chmod +x {} \\;"
    fi

    # ── Theme Engine ─────────────────────────────────────────────────────────
    section "🎨 Theme Engine"
    chk "Color cache (JSON)"   "test -f '${CACHE_DIR}/colors/current.json'"  optional "ash theme pick"
    chk "Color cache (shell)"  "test -f '${CACHE_DIR}/colors/current.sh'"    optional "ash theme pick"
    chk "Hyprland active theme" "test -f '${CONFIG_DIR}/hypr/themes/active.conf'" optional
    chk "Waybar colors.css"    "test -f '${CONFIG_DIR}/waybar/styles/colors.css'" optional
    chk "Kitty current.conf"   "test -f '${CONFIG_DIR}/kitty/themes/current.conf'" optional
    chk "Rofi dynamic theme"   "test -f '${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi'" optional
    chk "Fish current.fish"    "test -f '${CONFIG_DIR}/fish/themes/current.fish'" optional
    chk "Wallpaper history"    "test -f '${CACHE_DIR}/wallpaper/last'"         optional
    chk "Wallpapers directory" "test -d '${HOME}/Pictures/Wallpapers'"         required

    # ── Audio System ──────────────────────────────────────────────────────────
    section "🔊 Audio"
    chk "Pipewire active"      "systemctl --user is-active pipewire"       required
    chk "Wireplumber active"   "systemctl --user is-active wireplumber"    required
    chk "wpctl available"      "command -v wpctl"                           required
    chk "Audio sink exists"    "wpctl get-volume @DEFAULT_AUDIO_SINK@ &>/dev/null" optional

    # ── GPU & Display ────────────────────────────────────────────────────────
    section "🎮 GPU & Display"
    chk "GPU detected"         "lspci 2>/dev/null | grep -qiE 'vga|3d|display'" required
    chk "DRM subsystem"        "test -d /sys/class/drm"                    required
    chk "Wayland socket"       "test -S '${XDG_RUNTIME_DIR:-/tmp}/${WAYLAND_DISPLAY:-wayland-0}'" optional
    chk "Vulkan support"       "command -v vulkaninfo"                      optional

    # GPU type specific
    if lspci 2>/dev/null | grep -qi nvidia; then
        chk "NVIDIA driver"    "command -v nvidia-smi"                     optional "Install NVIDIA drivers"
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        chk "Mesa (AMD)"       "command -v glxinfo || test -f /usr/lib/libGL.so" optional
    fi

    # ── Network ──────────────────────────────────────────────────────────────
    section "🌐 Network"
    chk "NetworkManager"       "command -v nmcli"                           required
    chk "nmcli working"        "nmcli general status &>/dev/null"           optional
    chk "Internet access"      "curl -s --max-time 3 https://archlinux.org &>/dev/null" optional

    # ── Shell ────────────────────────────────────────────────────────────────
    section "🐟 Shell"
    chk "Fish installed"       "command -v fish"                            required
    chk "Fish default shell"   "[[ \"\$(getent passwd \${USER} | cut -d: -f7)\" == *fish* ]]" optional \
        "chsh -s \$(which fish)"
    chk "Starship installed"   "command -v starship"                        optional
    chk "Zoxide installed"     "command -v zoxide"                          optional
    chk "FZF installed"        "command -v fzf"                             optional

    # ── Neovim ───────────────────────────────────────────────────────────────
    section "📝 Neovim"
    chk "Neovim installed"     "command -v nvim"                            required
    chk "Neovim ≥ 0.9"        "nvim --version | head -1 | grep -qE 'v(0\\.9|0\\.1[0-9]|[1-9])'" optional
    chk "lazy.nvim installed"  "test -d '${HOME}/.local/share/nvim/lazy/lazy.nvim'" optional
    chk "Neovim config"        "test -f '${CONFIG_DIR}/nvim/init.lua'"     required

    # ── Dotfiles ─────────────────────────────────────────────────────────────
    section "📦 Dotfiles"
    chk "~/.dotfiles exists"   "test -d '${DOTFILES_DIR}'"                 required
    chk "Git repository"       "test -d '${DOTFILES_DIR}/.git'"            optional
    chk "ASH CLI installed"    "command -v ash"                              required
    chk "ASH CLI executable"   "test -x '${LOCAL_DIR}/bin/ash'"            required \
        "chmod +x ~/.local/bin/ash"
    chk "Backups directory"    "test -d '${LOCAL_DIR}/share/ash-dots/backups'" optional
    chk "Cache directory"      "test -d '${CACHE_DIR}'"                    required
    chk "Logs directory"       "test -d '${CACHE_DIR}/logs'"               required

    # ── Directories ──────────────────────────────────────────────────────────
    section "📁 Key Directories"
    local dirs=(
        "${HOME}/Pictures/Wallpapers"
        "${HOME}/Pictures/Screenshots"
        "${HOME}/Pictures/Recordings"
        "${CACHE_DIR}/colors"
        "${CACHE_DIR}/wallpaper"
        "${HOME}/.local/state/ash-dots"
    )
    for dir in "${dirs[@]}"; do
        chk "${dir/$HOME/~}" "test -d '${dir}'" optional
    done

    # ── Unique Features Status ────────────────────────────────────────────────
    section "🌟 Unique Features"
    chk "Music reactive daemon"   "pgrep -f album-art-theme"    optional "ash music enable"
    chk "Smart wallpaper daemon"  "pgrep -f smart-wallpaper"    optional "ash smart enable"
    chk "Analytics daemon"        "pgrep -f desktop-analytics"  optional "ash analytics start"
    chk "Context theme daemon"    "pgrep -f context-theme"      optional "ash context enable"
    chk "Theme history exists"    "test -d '${CACHE_DIR}/theme-history'" optional
    chk "Workspace profiles"      "test -d '${HOME}/.local/share/ash-dots/workspace-profiles'" optional
    chk "AI palette cache"        "test -d '${CACHE_DIR}/ai-palettes'" optional
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 FINAL REPORT
# ═══════════════════════════════════════════════════════════════════════════════

print_report() {
    local elapsed=$(( $(date +%s) - START_TIME ))
    local total=$(( PASS + FAIL + WARN ))

    echo ""
    echo -e "  ${B}${M}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}                   HEALTH REPORT                          ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${M}║${R}  ${G}✓ Passed:${R}    ${B}${PASS}${R} / ${total}                                  ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${Y}⚠ Warnings:${R}  ${B}${WARN}${R} (optional features)                   ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${RED}✗ Failed:${R}    ${B}${FAIL}${R}                                        ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}  ${DIM}⏱ Duration:${R}  ${elapsed}s                                     ${B}${M}║${R}"
    echo -e "  ${B}${M}╠══════════════════════════════════════════════════════════╣${R}"

    if (( FAIL == 0 && WARN == 0 )); then
        echo -e "  ${B}${M}║${R}  ${G}${B}🎉 PERFECT HEALTH — All checks passed!${R}           ${B}${M}║${R}"
    elif (( FAIL == 0 )); then
        echo -e "  ${B}${M}║${R}  ${G}${B}✅ Healthy — ${WARN} optional item(s) missing${R}       ${B}${M}║${R}"
    elif (( FAIL <= 3 )); then
        echo -e "  ${B}${M}║${R}  ${Y}${B}⚠ ${FAIL} critical issue(s) found${R}                    ${B}${M}║${R}"
    else
        echo -e "  ${B}${M}║${R}  ${RED}${B}❌ ${FAIL} critical failures — action needed${R}          ${B}${M}║${R}"
    fi

    echo -e "  ${B}${M}╚══════════════════════════════════════════════════════════╝${R}"

    # Show failures
    if (( ${#FAILURES[@]} > 0 )); then
        echo ""
        echo -e "  ${RED}${B}Critical Issues:${R}"
        for f in "${FAILURES[@]}"; do
            echo -e "    ${RED}•${R} ${f}"
        done
    fi

    # Quick fixes
    if (( FAIL > 0 )); then
        echo ""
        echo -e "  ${C}Quick Fix Commands:${R}"
        echo -e "    ${DIM}find ~/.config -name '*.sh' -exec chmod +x {} \\;${R}"
        echo -e "    ${DIM}ash theme pick    → generate missing theme files${R}"
        echo -e "    ${DIM}ash update        → update everything${R}"
        echo -e "    ${DIM}ash reload all    → restart all components${R}"
    fi

    echo ""
    echo -e "  ${DIM}Full log: ${LOG_FILE}${R}"
    echo ""

    log "INFO" "Doctor: pass=${PASS} warn=${WARN} fail=${FAIL} time=${elapsed}s"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"
    print_header
    run_all_checks
    print_report
    exit $(( FAIL > 0 ? 1 : 0 ))
}

main "$@"