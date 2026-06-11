#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MIGRATION SCRIPT                             ║
# ║           Migrate from v2.x to v3.0 configuration format                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/migrate.log"
readonly BACKUP_DIR="${HOME}/.local/share/ash-dots/backups"

readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly GREEN='\033[92m'
readonly YELLOW='\033[93m'
readonly RED='\033[91m'
readonly CYAN='\033[96m'
readonly MAGENTA='\033[95m'

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  ${CYAN}→${RESET} $*"; log "INFO" "$*"; }
ok()      { echo -e "  ${GREEN}✓${RESET} $*"; log "OK" "$*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $*" >&2; log "WARN" "$*"; }
err()     { echo -e "  ${RED}✗${RESET} $*" >&2; log "ERROR" "$*"; }
section() { echo -e "\n  ${BOLD}${MAGENTA}${1}${RESET}"; }

detect_version() {
    # Try to detect previous version
    if [[ -f "${CONFIG_DIR}/hypr/hyprland.conf" ]]; then
        local content
        content=$(cat "${CONFIG_DIR}/hypr/hyprland.conf" 2>/dev/null || echo "")

        if echo "${content}" | grep -q "ASH DOTFILES v3"; then
            echo "3.0"
        elif echo "${content}" | grep -q "ASH DOTFILES v2"; then
            echo "2.0"
        elif [[ -f "${CONFIG_DIR}/hypr/hyprland.conf" ]]; then
            echo "unknown"
        else
            echo "none"
        fi
    else
        echo "none"
    fi
}

migrate_v2_to_v3() {
    section "🔄 Migrating v2 → v3"

    # ── Backup v2 ─────────────────────────────────────────────────────────────
    info "Creating v2 backup before migration..."
    local backup_path="${BACKUP_DIR}/pre-v3-migration-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${backup_path}"

    local v2_dirs=("hypr" "waybar" "rofi" "fish" "kitty" "dunst")
    for dir in "${v2_dirs[@]}"; do
        if [[ -d "${CONFIG_DIR}/${dir}" ]]; then
            cp -r "${CONFIG_DIR}/${dir}" "${backup_path}/"
            ok "Backed up: ${dir}"
        fi
    done

    # ── Migrate UserOverrides ──────────────────────────────────────────────────
    section "📝 Migrating User Configuration"

    local old_user="${CONFIG_DIR}/hypr/hyprland.conf"
    local new_user="${CONFIG_DIR}/hypr/UserOverrides/user.conf"

    if [[ -f "${old_user}" ]]; then
        # Extract user-specific settings from old config
        info "Extracting user settings..."

        # Look for monitor configs
        local monitors
        monitors=$(grep "^monitor" "${old_user}" 2>/dev/null || echo "")

        if [[ -n "${monitors}" ]]; then
            mkdir -p "$(dirname "${new_user}")"
            {
                echo "# ASH v3.0 — Migrated User Overrides"
                echo "# Migrated from v2 on: $(date '+%Y-%m-%d %H:%M:%S')"
                echo ""
                echo "# ── Monitors (migrated from v2) ──────────────────────"
                echo "${monitors}"
                echo ""
                echo "# Add your custom keybinds and settings below:"
            } > "${new_user}"
            ok "Monitor config migrated to UserOverrides"
        fi
    fi

    # ── Migrate Theme ─────────────────────────────────────────────────────────
    section "🎨 Migrating Theme"

    # Check for old color scheme files
    local old_colors=(
        "${CONFIG_DIR}/hypr/colors.conf"
        "${CONFIG_DIR}/hypr/theme.conf"
        "${HOME}/.cache/wal/colors.sh"
    )

    for old_color in "${old_colors[@]}"; do
        if [[ -f "${old_color}" ]]; then
            info "Found old theme: ${old_color}"
            warn "Theme will be regenerated from wallpaper — run: ash theme pick"
            break
        fi
    done

    # ── Migrate Fish Config ───────────────────────────────────────────────────
    section "🐟 Migrating Fish Config"

    local old_fish="${CONFIG_DIR}/fish/config.fish"
    if [[ -f "${old_fish}" ]]; then
        info "Fish config found — preserving custom aliases"
        # Extract custom functions/aliases from old config
        local custom_content
        custom_content=$(grep -v "^#" "${old_fish}" 2>/dev/null \
            | grep -v "^$" \
            | grep -v "starship\|zoxide\|source\|set -g fish" \
            || echo "")

        if [[ -n "${custom_content}" ]]; then
            local custom_file="${DOTFILES_DIR}/config/fish/conf.d/99-migrated.fish"
            {
                echo "# Migrated from v2 fish config on $(date +%Y-%m-%d)"
                echo "${custom_content}"
            } > "${custom_file}"
            ok "Custom Fish config saved to: 99-migrated.fish"
        fi
    fi

    # ── Fix Script Permissions ────────────────────────────────────────────────
    section "🔐 Fixing Permissions"
    find "${CONFIG_DIR}" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "${HOME}/.local/bin" -name "ash*" -exec chmod +x {} \; 2>/dev/null || true
    ok "Script permissions fixed"

    # ── Summary ───────────────────────────────────────────────────────────────
    echo ""
    ok "Migration complete!"
    echo ""
    echo -e "  ${CYAN}Next steps:${RESET}"
    echo -e "    1. ${CYAN}ash theme pick${RESET}     — Set wallpaper & colors"
    echo -e "    2. ${CYAN}ash doctor${RESET}         — Verify everything works"
    echo -e "    3. Edit ${CYAN}~/.config/hypr/UserOverrides/user.conf${RESET} for custom settings"
    echo ""

    log "INFO" "Migration v2→v3 complete"
}

main() {
    mkdir -p "${CACHE_DIR}/logs" "${BACKUP_DIR}"

    echo ""
    echo -e "  ${BOLD}${MAGENTA}🔄 ASH Dotfiles — Migration Tool${RESET}"
    echo ""

    local current_version
    current_version=$(detect_version)
    info "Detected version: ${current_version}"

    case "${current_version}" in
        "3.0")
            ok "Already running ASH Dotfiles v3.0 — no migration needed"
            info "Run 'ash update' to get latest changes"
            ;;
        "2.0" | "unknown")
            warn "v2.x installation detected"
            echo ""
            echo -e "  This will migrate your v2 config to v3.0 format."
            echo -e "  A backup will be created before any changes."
            echo ""
            read -rp "  Continue migration? [y/N]: " confirm
            [[ "${confirm,,}" == "y" ]] || { info "Migration cancelled"; exit 0; }
            migrate_v2_to_v3
            ;;
        "none")
            info "No existing installation found — running fresh install"
            exec bash "${DOTFILES_DIR}/install.sh"
            ;;
    esac
}

main "$@"