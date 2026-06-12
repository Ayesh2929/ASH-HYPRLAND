#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — RESTORE SCRIPT                               ║
# ║           Restore configuration from backup with selection UI              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly BACKUP_DIR="${HOME}/.local/share/ash-dots/backups"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/restore.log"

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly G='\033[92m'
readonly Y='\033[93m'
readonly C='\033[96m'
readonly M='\033[95m'
readonly RED='\033[91m'
readonly DIM='\033[2m'

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  ${C}→${R} $*"; log "INFO" "$*"; }
ok()      { echo -e "  ${G}✓${R} $*"; log "OK" "$*"; }
warn()    { echo -e "  ${Y}⚠${R} $*" >&2; log "WARN" "$*"; }
err()     { echo -e "  ${RED}✗${R} $*" >&2; log "ERROR" "$*"; }
section() { echo -e "\n  ${B}${M}${1}${R}"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST BACKUPS
# ═══════════════════════════════════════════════════════════════════════════════

list_backups() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        echo "  No backups directory found: ${BACKUP_DIR}"
        return 1
    fi

    local backups=()
    while IFS= read -r backup; do
        backups+=("${backup}")
    done < <(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null | sort -r)

    if (( ${#backups[@]} == 0 )); then
        echo "  No backups found"
        return 1
    fi

    for backup in "${backups[@]}"; do
        local name size date_str
        name=$(basename "${backup}" .tar.gz)
        size=$(du -sh "${backup}" 2>/dev/null | cut -f1)
        date_str=$(stat -c %y "${backup}" 2>/dev/null | cut -d. -f1 || echo "?")
        printf "  %-50s  %6s  %s\n" "${name}" "${size}" "${date_str}"
    done

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RESTORE FROM BACKUP
# ═══════════════════════════════════════════════════════════════════════════════

restore_from_backup() {
    local backup_path="$1"
    local restore_mode="${2:-full}"  # full, theme-only, user-only

    if [[ ! -f "${backup_path}" ]]; then
        err "Backup not found: ${backup_path}"
        return 1
    fi

    section "🔄 Restoring: $(basename "${backup_path}")"

    # Extract to temp dir
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '${tmp_dir}'" EXIT

    info "Extracting backup..."
    if ! tar xzf "${backup_path}" -C "${tmp_dir}" 2>/dev/null; then
        err "Failed to extract backup"
        return 1
    fi

    local extracted_dir
    extracted_dir=$(find "${tmp_dir}" -maxdepth 1 -type d | tail -1)

    if [[ -z "${extracted_dir}" ]] || [[ "${extracted_dir}" == "${tmp_dir}" ]]; then
        err "Could not find extracted backup directory"
        return 1
    fi

    # Show manifest if available
    local manifest="${extracted_dir}/MANIFEST.txt"
    if [[ -f "${manifest}" ]]; then
        info "Backup manifest:"
        cat "${manifest}" | grep -v "^#" | head -10 | while IFS= read -r line; do
            echo "    ${DIM}${line}${R}"
        done
    fi

    # Confirm restore
    echo ""
    echo -e "  ${Y}⚠ This will overwrite current configuration!${R}"
    echo -e "  ${DIM}Mode: ${restore_mode}${R}"
    read -rp "  Continue? [y/N]: " confirm
    [[ "${confirm,,}" == "y" ]] || { info "Restore cancelled"; return 0; }

    # Restore based on mode
    case "${restore_mode}" in
        full)
            restore_full "${extracted_dir}"
            ;;
        theme-only)
            restore_theme "${extracted_dir}"
            ;;
        user-only)
            restore_user_overrides "${extracted_dir}"
            ;;
        *)
            restore_full "${extracted_dir}"
            ;;
    esac

    # Reload
    info "Reloading configurations..."
    ash reload 2>/dev/null || true

    ok "Restore complete!"
    log "INFO" "Restore complete from: ${backup_path}"
}

restore_full() {
    local src_dir="$1"

    # Restore all backed-up files preserving structure
    info "Restoring full configuration..."

    if [[ -d "${src_dir}/.config" ]]; then
        cp -r "${src_dir}/.config/." "${CONFIG_DIR}/" 2>/dev/null || true
        ok "Config files restored"
    fi

    if [[ -d "${src_dir}/.cache" ]]; then
        cp -r "${src_dir}/.cache/." "${CACHE_DIR}/../" 2>/dev/null || true
        ok "Cache restored"
    fi
}

restore_theme() {
    local src_dir="$1"

    info "Restoring theme files only..."

    local theme_files=(
        ".cache/ash-dots/colors/current.json"
        ".cache/ash-dots/colors/current.sh"
        ".cache/ash-dots/wallpaper/last"
        ".config/hypr/themes/active.conf"
        ".config/waybar/styles/colors.css"
        ".config/kitty/themes/current.conf"
        ".config/rofi/themes/ash-dynamic.rasi"
        ".config/fish/themes/current.fish"
    )

    for rel_path in "${theme_files[@]}"; do
        local src="${src_dir}/${rel_path}"
        local dst="${HOME}/${rel_path}"

        if [[ -f "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp "${src}" "${dst}" 2>/dev/null \
                && ok "Restored: ${rel_path}" \
                || warn "Could not restore: ${rel_path}"
        fi
    done
}

restore_user_overrides() {
    local src_dir="$1"

    info "Restoring user overrides only..."

    local user_conf="${src_dir}/.config/hypr/UserOverrides/user.conf"
    if [[ -f "${user_conf}" ]]; then
        local dst="${CONFIG_DIR}/hypr/UserOverrides/user.conf"
        mkdir -p "$(dirname "${dst}")"
        cp "${user_conf}" "${dst}" 2>/dev/null \
            && ok "User overrides restored" \
            || warn "Could not restore user overrides"
    else
        warn "No user overrides found in backup"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 INTERACTIVE RESTORE PICKER
# ═══════════════════════════════════════════════════════════════════════════════

interactive_restore() {
    if [[ ! -d "${BACKUP_DIR}" ]] || \
       [[ -z "$(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null)" ]]; then
        err "No backups found in ${BACKUP_DIR}"
        info "Create a backup first: ash backup"
        return 1
    fi

    # Rofi picker if available
    if command -v rofi &>/dev/null; then
        local selected
        selected=$(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null \
            | sort -r \
            | while IFS= read -r b; do
                local name size date_str
                name=$(basename "${b}" .tar.gz)
                size=$(du -sh "${b}" 2>/dev/null | cut -f1)
                date_str=$(stat -c %y "${b}" 2>/dev/null | cut -d. -f1 | cut -dT -f1 || echo "?")
                echo "${name}   ${size}   ${date_str}"
              done \
            | rofi \
                -dmenu \
                -i \
                -p "🔄 Select Backup to Restore" \
                -theme-str 'window { width: 700px; } listview { lines: 12; }' \
                2>/dev/null) || {
            info "Restore cancelled"
            return 0
        }

        local backup_name
        backup_name=$(echo "${selected}" | awk '{print $1}')
        local backup_path="${BACKUP_DIR}/${backup_name}.tar.gz"

        if [[ ! -f "${backup_path}" ]]; then
            err "Backup not found: ${backup_path}"
            return 1
        fi

        # Choose restore mode
        local mode
        mode=$(echo -e "🔄 Full Restore\n🎨 Theme Only\n👤 User Overrides Only" \
            | rofi \
                -dmenu \
                -i \
                -p "Restore Mode" \
                -theme-str 'window { width: 400px; } listview { lines: 3; }' \
                2>/dev/null) || { info "Cancelled"; return 0; }

        case "${mode}" in
            "🔄 Full"*)   restore_from_backup "${backup_path}" "full" ;;
            "🎨 Theme"*)  restore_from_backup "${backup_path}" "theme-only" ;;
            "👤 User"*)   restore_from_backup "${backup_path}" "user-only" ;;
        esac

    else
        # Text-based picker
        echo ""
        echo -e "  ${B}${M}Available Backups:${R}"
        echo ""
        list_backups

        echo ""
        read -rp "  Enter backup name (or 'list' to show): " selection

        if [[ "${selection}" == "list" ]]; then
            list_backups
            return 0
        fi

        local backup_path="${BACKUP_DIR}/${selection}"
        [[ "${selection}" != *.tar.gz ]] && backup_path="${backup_path}.tar.gz"

        restore_from_backup "${backup_path}" "full"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-interactive}"
    shift || true

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        interactive | "")
            interactive_restore
            ;;
        list | ls)
            echo ""
            echo -e "  ${B}${M}💾 Available Backups:${R}"
            echo ""
            list_backups
            ;;
        restore)
            local backup="${1:-}"
            local mode="${2:-full}"
            if [[ -z "${backup}" ]]; then
                interactive_restore
            else
                local path="${BACKUP_DIR}/${backup}"
                [[ "${backup}" != *.tar.gz ]] && path="${path}.tar.gz"
                restore_from_backup "${path}" "${mode}"
            fi
            ;;
        theme)
            # Restore just the theme from latest backup
            local latest
            latest=$(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null \
                | sort -r | head -1)
            if [[ -n "${latest}" ]]; then
                restore_from_backup "${latest}" "theme-only"
            else
                err "No backups found"
                exit 1
            fi
            ;;
        latest)
            local latest
            latest=$(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null \
                | sort -r | head -1)
            if [[ -n "${latest}" ]]; then
                restore_from_backup "${latest}" "full"
            else
                err "No backups found"
                exit 1
            fi
            ;;
        *)
            echo "Usage: restore.sh [interactive|list|restore NAME|theme|latest]"
            exit 1
            ;;
    esac
}

main "$@"