#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — THEME UNDO / HISTORY                         ║
# ║           Undo last theme change, browse history, restore any past theme   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly HISTORY_DIR="${CACHE_DIR}/theme-history"
readonly LOG_FILE="${CACHE_DIR}/logs/theme-undo.log"
readonly MAX_HISTORY=20

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; log "INFO" "$*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; log "OK" "$*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; log "WARN" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 SAVE THEME SNAPSHOT (call this BEFORE applying new theme)
# ═══════════════════════════════════════════════════════════════════════════════

save_snapshot() {
    local label="${1:-auto}"

    mkdir -p "${HISTORY_DIR}"

    local snapshot_id
    snapshot_id=$(date '+%Y%m%d_%H%M%S')
    local snapshot_dir="${HISTORY_DIR}/${snapshot_id}"

    mkdir -p "${snapshot_dir}"

    # Save current state
    local saved=0

    # Save color palette
    if [[ -f "${CACHE_DIR}/colors/current.json" ]]; then
        cp "${CACHE_DIR}/colors/current.json" "${snapshot_dir}/colors.json"
        ((saved++)) || true
    fi

    # Save color shell script
    if [[ -f "${CACHE_DIR}/colors/current.sh" ]]; then
        cp "${CACHE_DIR}/colors/current.sh" "${snapshot_dir}/colors.sh"
        ((saved++)) || true
    fi

    # Save wallpaper path
    if [[ -f "${CACHE_DIR}/wallpaper/last" ]]; then
        cp "${CACHE_DIR}/wallpaper/last" "${snapshot_dir}/wallpaper.txt"
        ((saved++)) || true
    fi

    # Save Hyprland active theme
    if [[ -f "${HOME}/.config/hypr/themes/active.conf" ]]; then
        cp "${HOME}/.config/hypr/themes/active.conf" "${snapshot_dir}/active.conf"
        ((saved++)) || true
    fi

    # Save Waybar colors
    if [[ -f "${HOME}/.config/waybar/styles/colors.css" ]]; then
        cp "${HOME}/.config/waybar/styles/colors.css" "${snapshot_dir}/colors.css"
        ((saved++)) || true
    fi

    # Save thumbnail of current wallpaper
    if [[ -f "${CACHE_DIR}/wallpaper/last" ]]; then
        local current_wall
        current_wall=$(cat "${CACHE_DIR}/wallpaper/last" 2>/dev/null || echo "")
        if [[ -f "${current_wall}" ]]; then
            convert "${current_wall}" \
                -resize "200x112^" \
                -gravity center \
                -extent "200x112" \
                "${snapshot_dir}/thumbnail.jpg" \
                2>/dev/null || true
        fi
    fi

    # Save metadata
    local current_wall=""
    [[ -f "${CACHE_DIR}/wallpaper/last" ]] && \
        current_wall=$(cat "${CACHE_DIR}/wallpaper/last" 2>/dev/null || echo "")

    local primary_color="unknown"
    if [[ -f "${CACHE_DIR}/colors/current.json" ]]; then
        primary_color=$(python3 -c "
import json
try:
    d=json.load(open('${CACHE_DIR}/colors/current.json'))
    accents=d.get('accents',{})
    print(list(accents.values())[0] if accents else 'unknown')
except:
    print('unknown')
" 2>/dev/null || echo "unknown")
    fi

    cat > "${snapshot_dir}/meta.json" << EOF
{
    "id":           "${snapshot_id}",
    "label":        "${label}",
    "timestamp":    "$(date -Iseconds)",
    "wallpaper":    "${current_wall}",
    "primary_color": "${primary_color}",
    "saved_items":  ${saved}
}
EOF

    # Rotate old history (keep MAX_HISTORY entries)
    local count
    count=$(ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | wc -l)
    if (( count > MAX_HISTORY )); then
        ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | \
            sort | \
            head -$(( count - MAX_HISTORY )) | \
            xargs rm -rf 2>/dev/null || true
    fi

    log "INFO" "Snapshot saved: ${snapshot_id} (${label})"
    echo "${snapshot_id}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔄 RESTORE FROM SNAPSHOT
# ═══════════════════════════════════════════════════════════════════════════════

restore_snapshot() {
    local snapshot_id="$1"
    local snapshot_dir="${HISTORY_DIR}/${snapshot_id}"

    if [[ ! -d "${snapshot_dir}" ]]; then
        warn "Snapshot not found: ${snapshot_id}"
        return 1
    fi

    info "Restoring theme snapshot: ${snapshot_id}"

    # Save current state before restoring (for redo)
    save_snapshot "pre-restore" &>/dev/null || true

    # Restore color palette
    if [[ -f "${snapshot_dir}/colors.json" ]]; then
        cp "${snapshot_dir}/colors.json" "${CACHE_DIR}/colors/current.json"
        ok "Colors restored"
    fi

    if [[ -f "${snapshot_dir}/colors.sh" ]]; then
        cp "${snapshot_dir}/colors.sh" "${CACHE_DIR}/colors/current.sh"
    fi

    # Restore Hyprland theme
    if [[ -f "${snapshot_dir}/active.conf" ]]; then
        cp "${snapshot_dir}/active.conf" \
            "${HOME}/.config/hypr/themes/active.conf"
        ok "Hyprland theme restored"
    fi

    # Restore Waybar colors
    if [[ -f "${snapshot_dir}/colors.css" ]]; then
        cp "${snapshot_dir}/colors.css" \
            "${HOME}/.config/waybar/styles/colors.css"
        ok "Waybar colors restored"
    fi

    # Restore wallpaper
    if [[ -f "${snapshot_dir}/wallpaper.txt" ]]; then
        local old_wall
        old_wall=$(cat "${snapshot_dir}/wallpaper.txt")
        if [[ -f "${old_wall}" ]]; then
            info "Restoring wallpaper: $(basename "${old_wall}")"
            if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
                swww img "${old_wall}" \
                    --transition-type fade \
                    --transition-duration 1.5 \
                    2>/dev/null || true
            fi
            echo "${old_wall}" > "${CACHE_DIR}/wallpaper/last"
            ok "Wallpaper restored"
        fi
    fi

    # Reload all components
    info "Reloading..."
    hyprctl reload 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -USR1 kitty 2>/dev/null || true

    notify-send "↩️ Theme Restored" \
        "Restored to: ${snapshot_id}" \
        --app-name="ASH Theme" \
        --expire-time=3000 \
        2>/dev/null || true

    ok "Theme restored from snapshot: ${snapshot_id}"
    log "INFO" "Restored: ${snapshot_id}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST HISTORY
# ═══════════════════════════════════════════════════════════════════════════════

list_history() {
    if [[ ! -d "${HISTORY_DIR}" ]] || \
       [[ -z "$(ls -A "${HISTORY_DIR}" 2>/dev/null)" ]]; then
        echo "  No theme history yet"
        echo "  History is saved automatically on each theme change"
        return 0
    fi

    echo ""
    echo -e "  \033[1m\033[95m🕐 Theme History:\033[0m"
    echo ""

    local count=0
    for snapshot_dir in $(ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | sort -r); do
        local meta_file="${snapshot_dir}/meta.json"
        [[ ! -f "${meta_file}" ]] && continue

        local snap_id ts label wallpaper color
        snap_id=$(jq -r '.id // ""'           "${meta_file}" 2>/dev/null)
        ts=$(jq -r '.timestamp // ""'          "${meta_file}" 2>/dev/null | cut -dT -f1)
        label=$(jq -r '.label // ""'           "${meta_file}" 2>/dev/null)
        wallpaper=$(jq -r '.wallpaper // ""'   "${meta_file}" 2>/dev/null)
        color=$(jq -r '.primary_color // ""'   "${meta_file}" 2>/dev/null)

        local wall_name="No wallpaper"
        [[ -n "${wallpaper}" ]] && wall_name=$(basename "${wallpaper}")

        # Color swatch
        local swatch=""
        if [[ "${color}" =~ ^#[0-9a-fA-F]{6}$ ]]; then
            local r g b
            r=$(( 16#${color:1:2} ))
            g=$(( 16#${color:3:2} ))
            b=$(( 16#${color:5:2} ))
            swatch=$(printf "\033[38;2;%d;%d;%dm██\033[0m" "${r}" "${g}" "${b}")
        fi

        ((count++)) || true
        printf "  %2d. ${swatch} \033[96m%-20s\033[0m  %-10s  %s\n" \
            "${count}" "${wall_name:0:20}" "${ts}" "${label}"
    done

    echo ""
    echo -e "  \033[2mRun: ash theme undo      → Restore previous\033[0m"
    echo -e "  \033[2mRun: ash theme history   → Interactive picker\033[0m"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ROFI HISTORY PICKER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_history_picker() {
    if [[ ! -d "${HISTORY_DIR}" ]]; then
        warn "No history yet"
        return 0
    fi

    local menu=""
    local -a snapshot_ids=()

    for snapshot_dir in $(ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | sort -r | head -15); do
        local meta_file="${snapshot_dir}/meta.json"
        [[ ! -f "${meta_file}" ]] && continue

        local snap_id ts wallpaper color
        snap_id=$(jq -r '.id // ""'           "${meta_file}" 2>/dev/null)
        ts=$(jq -r '.timestamp // ""'          "${meta_file}" 2>/dev/null | cut -dT -f2 | cut -d+ -f1)
        wallpaper=$(jq -r '.wallpaper // ""'   "${meta_file}" 2>/dev/null)
        color=$(jq -r '.primary_color // ""'   "${meta_file}" 2>/dev/null)

        local wall_name="No wallpaper"
        [[ -n "${wallpaper}" ]] && wall_name=$(basename "${wallpaper}")

        snapshot_ids+=("${snap_id}")
        menu+="${snap_id}  ${ts}  ${wall_name:0:25}  ${color}\n"
    done

    if [[ -z "${menu}" ]]; then
        notify-send "↩️ Theme History" "No history found" \
            --app-name="ASH Theme" 2>/dev/null || true
        return 0
    fi

    local selected
    selected=$(echo -e "${menu}" | rofi \
        -dmenu \
        -i \
        -p "↩️ Theme History" \
        -theme-str '
            window { width: 700px; }
            listview { columns: 1; lines: 12; }
            element { padding: 8px 12px; font-family: "JetBrainsMono Nerd Font"; font-size: 12px; }
        ' \
        2>/dev/null) || {
        info "History picker cancelled"
        return 0
    }

    local snap_id
    snap_id=$(echo "${selected}" | awk '{print $1}')

    if [[ -n "${snap_id}" ]]; then
        restore_snapshot "${snap_id}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# ↩️ SIMPLE UNDO (previous theme)
# ═══════════════════════════════════════════════════════════════════════════════

undo_last() {
    # Get the second-most-recent snapshot (skip the most recent = current)
    local snapshots=()
    while IFS= read -r dir; do
        snapshots+=("$(basename "${dir}")")
    done < <(ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | sort -r)

    if (( ${#snapshots[@]} < 2 )); then
        warn "No previous theme to undo to"
        warn "Apply more themes first to build history"
        return 1
    fi

    # Restore previous snapshot (index 1, not 0)
    local previous_id="${snapshots[1]}"
    info "Undoing to: ${previous_id}"
    restore_snapshot "${previous_id}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-undo}"
    local arg="${2:-}"

    mkdir -p "${HISTORY_DIR}" "${CACHE_DIR}/logs"

    case "${action}" in
        undo | u)           undo_last ;;
        save | snapshot)    save_snapshot "${arg:-manual}" ;;
        restore | r)        restore_snapshot "${arg}" ;;
        list | history | h) list_history ;;
        picker | browse)    rofi_history_picker ;;
        clear)
            read -rp "  Delete ALL theme history? [y/N]: " confirm
            [[ "${confirm,,}" == "y" ]] && {
                rm -rf "${HISTORY_DIR:?}"/*
                ok "Theme history cleared"
            }
            ;;
        count)
            ls -1d "${HISTORY_DIR}"/[0-9]* 2>/dev/null | wc -l
            ;;
        *)
            echo "Usage: theme-undo.sh [undo|save|restore ID|list|picker|clear|count]"
            exit 1
            ;;
    esac
}

main "$@"