#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — BACKUP SCRIPT                                ║
# ║           Complete configuration backup with compression and rotation      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"
readonly CONFIG_DIR="${HOME}/.config"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/backup.log"
readonly BACKUP_DIR="${HOME}/.local/share/ash-dots/backups"
readonly MAX_BACKUPS=15

# Colors
readonly R='\033[0m'
readonly B='\033[1m'
readonly G='\033[92m'
readonly Y='\033[93m'
readonly C='\033[96m'
readonly M='\033[95m'
readonly DIM='\033[2m'

log()     { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info()    { echo -e "  ${C}→${R} $*"; log "INFO" "$*"; }
ok()      { echo -e "  ${G}✓${R} $*"; log "OK" "$*"; }
warn()    { echo -e "  ${Y}⚠${R} $*" >&2; log "WARN" "$*"; }
section() { echo -e "\n  ${B}${M}${1}${R}"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 BACKUP MANIFEST
# ═══════════════════════════════════════════════════════════════════════════════

# Items to backup (relative to HOME or absolute)
declare -a BACKUP_CONFIGS=(
    "${CONFIG_DIR}/hypr/UserOverrides/user.conf"
    "${CONFIG_DIR}/hypr/themes"
    "${CONFIG_DIR}/hypr/core/monitors.conf"
    "${CONFIG_DIR}/waybar/styles/colors.css"
    "${CONFIG_DIR}/kitty/themes/current.conf"
    "${CONFIG_DIR}/rofi/themes/ash-dynamic.rasi"
    "${CONFIG_DIR}/fish/themes/current.fish"
    "${CONFIG_DIR}/gtk-3.0/gtk.css"
    "${CONFIG_DIR}/gtk-4.0/gtk.css"
    "${CONFIG_DIR}/starship.toml"
    "${CACHE_DIR}/colors/current.json"
    "${CACHE_DIR}/wallpaper/last"
    "${CACHE_DIR}/wallpaper/history"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 BACKUP FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

create_backup() {
    local label="${1:-manual}"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="backup-${label}-${timestamp}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    local archive_path="${BACKUP_DIR}/${backup_name}.tar.gz"

    mkdir -p "${backup_path}"

    section "💾 Creating Backup: ${backup_name}"

    local backed_up=0
    local skipped=0

    # Backup each config item
    for item in "${BACKUP_CONFIGS[@]}"; do
        if [[ ! -e "${item}" ]]; then
            ((skipped++)) || true
            continue
        fi

        # Create relative path structure
        local rel_path="${item#${HOME}/}"
        local dest_dir="${backup_path}/$(dirname "${rel_path}")"
        mkdir -p "${dest_dir}"

        if cp -r "${item}" "${dest_dir}/" 2>/dev/null; then
            ((backed_up++)) || true
        else
            warn "Could not backup: ${item}"
        fi
    done

    # Save system info
    {
        echo "# ASH Dotfiles v3.0 Backup"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Label: ${label}"
        echo "# User: ${USER}@$(hostname)"
        echo "# Kernel: $(uname -r)"
        echo "# Hyprland: $(hyprctl version 2>/dev/null | head -1 || echo 'N/A')"
        echo ""
        echo "# Items backed up: ${backed_up}"
        echo "# Items skipped: ${skipped}"
        echo ""
        echo "# Backed up items:"
        for item in "${BACKUP_CONFIGS[@]}"; do
            [[ -e "${item}" ]] && echo "#   ${item}"
        done
    } > "${backup_path}/MANIFEST.txt"

    # Compress backup
    info "Compressing backup..."
    if tar czf "${archive_path}" \
        -C "${BACKUP_DIR}" \
        "${backup_name}" \
        2>/dev/null; then

        rm -rf "${backup_path}"
        local size
        size=$(du -sh "${archive_path}" 2>/dev/null | cut -f1)
        ok "Backup saved: ${archive_path} (${size})"
        log "INFO" "Backup created: ${archive_path} (${backed_up} items, ${size})"
    else
        warn "Compression failed — keeping uncompressed backup: ${backup_path}"
    fi

    # Rotate old backups
    rotate_backups
}

rotate_backups() {
    local backup_count
    backup_count=$(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null | wc -l)

    if (( backup_count > MAX_BACKUPS )); then
        local to_delete=$(( backup_count - MAX_BACKUPS ))
        info "Rotating: removing ${to_delete} old backup(s)..."

        find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null \
            | sort \
            | head -"${to_delete}" \
            | while IFS= read -r old_backup; do
                rm -f "${old_backup}"
                log "INFO" "Removed old backup: ${old_backup}"
            done

        ok "Rotation complete (keeping ${MAX_BACKUPS} backups)"
    fi
}

list_backups() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        echo "  No backups found"
        return 0
    fi

    local backups=()
    while IFS= read -r backup; do
        backups+=("${backup}")
    done < <(find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null | sort -r)

    if (( ${#backups[@]} == 0 )); then
        echo "  No backups found in ${BACKUP_DIR}"
        return 0
    fi

    echo ""
    echo -e "  ${B}${M}💾 Available Backups:${R}"
    echo ""

    for backup in "${backups[@]}"; do
        local name size date_str
        name=$(basename "${backup}" .tar.gz)
        size=$(du -sh "${backup}" 2>/dev/null | cut -f1)
        date_str=$(stat -c %y "${backup}" 2>/dev/null | cut -d. -f1 || echo "unknown")

        printf "  ${C}%-50s${R}  ${DIM}%6s  %s${R}\n" \
            "${name}" "${size}" "${date_str}"
    done

    echo ""
    echo -e "  ${DIM}Total: ${#backups[@]} backup(s)${R}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-create}"
    shift || true

    mkdir -p "${BACKUP_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        create | "")
            local label="${1:-manual}"
            create_backup "${label}"
            ;;

        list | ls)
            list_backups
            ;;

        rotate)
            rotate_backups
            ;;

        auto)
            # Called by ash update — silent backup
            create_backup "auto" 2>/dev/null
            ;;

        path)
            echo "${BACKUP_DIR}"
            ;;

        count)
            find "${BACKUP_DIR}" -name "backup-*.tar.gz" 2>/dev/null | wc -l
            ;;

        clean)
            info "Removing all backups..."
            read -rp "  Are you sure? [y/N]: " confirm
            if [[ "${confirm,,}" == "y" ]]; then
                rm -rf "${BACKUP_DIR}"/backup-*.tar.gz
                ok "All backups removed"
            else
                info "Cancelled"
            fi
            ;;

        *)
            echo "Usage: backup.sh [create|list|rotate|auto|path|count|clean]"
            exit 1
            ;;
    esac
}

main "$@"