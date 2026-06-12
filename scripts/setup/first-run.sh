#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.1.0 — FIRST RUN SETUP                            ║
# ║           Interactive first-boot configuration wizard                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CONFIG_DIR="${HOME}/.config"
readonly LOG_FILE="${CACHE_DIR}/logs/first-run.log"

readonly R='\033[0m' B='\033[1m' G='\033[92m' Y='\033[93m'
readonly C='\033[96m' M='\033[95m' DIM='\033[2m'

log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()   { echo -e "  ${C}→${R} $*"; }
ok()     { echo -e "  ${G}✓${R} $*"; }
warn()   { echo -e "  ${Y}⚠${R} $*" >&2; }
step()   { echo -e "\n  ${B}${M}Step ${1}/${2}: ${3}${R}"; }
prompt() { read -rp "  ${C}?${R} $* "; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 WIZARD
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    clear
    echo ""
    echo -e "  ${B}${M}╔═══════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}   ${B}🎉 Welcome to ASH Dotfiles v3.1.0!${R}        ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}   Let's get your desktop configured         ${B}${M}║${R}"
    echo -e "  ${B}${M}╚═══════════════════════════════════════════════╝${R}"
    echo ""

    # ── Step 1: Monitor Setup ─────────────────────────────────────────────────
    step 1 6 "Monitor Configuration"
    echo ""
    echo -e "  ${DIM}Your monitors need to be configured in:${R}"
    echo -e "  ${C}~/.config/hypr/UserOverrides/user.conf${R}"
    echo ""
    echo -e "  ${DIM}Detected monitors:${R}"
    hyprctl monitors 2>/dev/null | grep "Monitor" | \
        awk '{print "    " $2 " — " $3}' || echo "    (run inside Hyprland)"
    echo ""

    prompt "Open monitor config now? [Y/n]: "
    if [[ "${REPLY,,}" != "n" ]]; then
        kitty --title "Monitor Config" \
            -e nvim "${CONFIG_DIR}/hypr/UserOverrides/user.conf" \
            2>/dev/null & disown
        ok "Config opened in Kitty"
    fi

    # ── Step 2: Theme ─────────────────────────────────────────────────────────
    step 2 6 "Pick Your First Wallpaper"
    echo ""
    echo -e "  ${DIM}ASH generates your entire color theme from your wallpaper.${R}"
    echo -e "  ${DIM}Add wallpapers to: ~/Pictures/Wallpapers/${R}"
    echo ""

    prompt "Pick wallpaper now? [Y/n]: "
    if [[ "${REPLY,,}" != "n" ]]; then
        "${CONFIG_DIR}/hypr/scripts/theme/wallpaper-picker.sh" picker \
            2>/dev/null || true
        ok "Theme applied!"
    fi

    # ── Step 3: Unique Features ───────────────────────────────────────────────
    step 3 6 "Enable Unique Features"
    echo ""
    echo -e "  ASH has features no other dotfiles system has:"
    echo ""
    echo -e "  ${C}1${R}) 🎵 Music Reactive Theme (album art → colors)"
    echo -e "  ${C}2${R}) 🌤️  Smart Wallpapers (time + weather based)"
    echo -e "  ${C}3${R}) 📊 Desktop Analytics (usage tracking)"
    echo -e "  ${C}4${R}) 🎭 Context Theming (app-based colors)"
    echo -e "  ${C}5${R}) All of the above"
    echo -e "  ${C}6${R}) Skip for now"
    echo ""

    prompt "Enable features [1-6]: "
    case "${REPLY}" in
        1)
            "${CONFIG_DIR}/hypr/scripts/theme/album-art-theme.sh" enable \
                &>/dev/null & disown
            ok "Music reactive enabled"
            ;;
        2)
            "${CONFIG_DIR}/hypr/scripts/theme/smart-wallpaper.sh" enable \
                &>/dev/null & disown
            ok "Smart wallpapers enabled"
            ;;
        3)
            "${CONFIG_DIR}/hypr/scripts/analytics/desktop-analytics.sh" start \
                &>/dev/null & disown
            ok "Analytics enabled"
            ;;
        4)
            "${CONFIG_DIR}/hypr/scripts/theme/context-theme.sh" enable \
                &>/dev/null & disown
            ok "Context theming enabled"
            ;;
        5)
            bash "${HOME}/.dotfiles/scripts/setup/install-unique-features.sh" \
                2>/dev/null
            "${CONFIG_DIR}/hypr/scripts/theme/album-art-theme.sh" enable \
                &>/dev/null & disown
            "${CONFIG_DIR}/hypr/scripts/theme/smart-wallpaper.sh" enable \
                &>/dev/null & disown
            "${CONFIG_DIR}/hypr/scripts/analytics/desktop-analytics.sh" start \
                &>/dev/null & disown
            "${CONFIG_DIR}/hypr/scripts/theme/context-theme.sh" enable \
                &>/dev/null & disown
            ok "All unique features enabled!"
            ;;
        *)
            info "Skipped — enable later with: ash music enable"
            ;;
    esac

    # ── Step 4: Default Shell ─────────────────────────────────────────────────
    step 4 6 "Shell Configuration"
    echo ""

    local current_shell
    current_shell=$(getent passwd "${USER}" | cut -d: -f7)

    if [[ "${current_shell}" == *"fish"* ]]; then
        ok "Fish is already your default shell"
    else
        echo -e "  ${DIM}Current shell: ${current_shell}${R}"
        prompt "Set Fish as default shell? [Y/n]: "
        if [[ "${REPLY,,}" != "n" ]]; then
            local fish_path
            fish_path=$(command -v fish)
            grep -q "${fish_path}" /etc/shells 2>/dev/null || \
                echo "${fish_path}" | sudo tee -a /etc/shells > /dev/null
            chsh -s "${fish_path}" && ok "Fish set as default shell"
        fi
    fi

    # ── Step 5: Workspace Profiles ────────────────────────────────────────────
    step 5 6 "Workspace Profiles"
    echo ""
    echo -e "  ${DIM}Built-in profiles: coding, gaming, meeting${R}"
    echo ""

    prompt "Initialize workspace profiles? [Y/n]: "
    if [[ "${REPLY,,}" != "n" ]]; then
        "${CONFIG_DIR}/hypr/scripts/theme/workspace-profiles.sh" init \
            2>/dev/null
        ok "Profiles ready: ash workspace apply coding"
    fi

    # ── Step 6: Health Check ──────────────────────────────────────────────────
    step 6 6 "Health Check"
    echo ""

    prompt "Run health check now? [Y/n]: "
    if [[ "${REPLY,,}" != "n" ]]; then
        bash "${HOME}/.dotfiles/scripts/health/doctor.sh" 2>/dev/null || true
    fi

    # ── Done! ─────────────────────────────────────────────────────────────────
    echo ""
    echo -e "  ${B}${M}╔═══════════════════════════════════════════════╗${R}"
    echo -e "  ${B}${M}║${R}   ${G}${B}🎉 ASH Dotfiles is ready!${R}                ${B}${M}║${R}"
    echo -e "  ${B}${M}╠═══════════════════════════════════════════════╣${R}"
    echo -e "  ${B}${M}║${R}   ${C}ash help${R}        → All commands             ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}   ${C}ash score${R}       → Desktop health score    ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}   ${C}ash theme ai${R}    → AI-generated themes     ${B}${M}║${R}"
    echo -e "  ${B}${M}║${R}   ${C}ash doctor${R}      → Full health check       ${B}${M}║${R}"
    echo -e "  ${B}${M}╚═══════════════════════════════════════════════╝${R}"
    echo ""

    log "INFO" "First run complete"
}

main "$@"