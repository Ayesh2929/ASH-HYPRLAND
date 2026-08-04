#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG MIGRATE                                         ║
# ║  Schema version migration engine with rollback, dry-run & audit trail             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::migrate::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "🔄  ASH CONFIG MIGRATE" \
        "Upgrade configuration schema between ASH versions" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config migrate [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--from,    -f VERSION${RST}   Force source version (auto-detect default)
  ${ASH_MUTED}--to,      -t VERSION${RST}   Target version (default: latest = ${CFG_CURRENT_VERSION})
  ${ASH_MUTED}--dry-run, -n${RST}           Show changes without applying
  ${ASH_MUTED}--no-backup${RST}              Skip backup before migration
  ${ASH_MUTED}--list${RST}                  List all available migrations
  ${ASH_MUTED}--help,    -h${RST}           Show this help

${BOLD}${ASH_PRIMARY}MIGRATION VERSIONS${RST}
  ${ASH_MUTED}v1${RST} → Initial release config format
  ${ASH_MUTED}v2${RST} → Added theme section, renamed keys
  ${ASH_MUTED}v3${RST} → Added AI & privacy sections
  ${ASH_MUTED}v4${RST} → Added performance section, split bar/waybar
  ${ASH_MUTED}v5${RST} → Added snapshot section, new hyprland keys ${ASH_SUCCESS}← CURRENT${RST}

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config migrate
  ash config migrate --dry-run
  ash config migrate --from 3 --to 5
  ash config migrate --list
EOF
}

# ── Migration registry ─────────────────────────────────────────────────────────
# Each migration: from_ver to_ver description
declare -A MIGRATION_REGISTRY=(
    ["1→2"]="Added theme section; renamed wallpaper.style → theme.wallpaper_mode"
    ["2→3"]="Added ai.* and privacy.* sections"
    ["3→4"]="Added performance.* section; split bar.waybar_* → waybar.*"
    ["4→5"]="Added snapshot.* section; added hyprland.smart_gaps|borders|opacity keys"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Migration step functions — each handles exactly one version jump
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_migrate::v1_to_v2() {
    local file="$1" dry="$2"
    local changes=()

    # Rename: wallpaper.style → theme.wallpaper_mode
    local old_val; old_val=$(cfg::_read_raw "wallpaper.style" "${file}" 2>/dev/null)
    if [[ -n "${old_val}" ]]; then
        changes+=("RENAME  wallpaper.style → theme.wallpaper_mode = ${old_val}")
        if [[ "${dry}" == "false" ]]; then
            cfg::_write_raw "theme.wallpaper_mode" "${old_val}" "${file}"
            cfg::_delete_raw "wallpaper.style" "${file}"
        fi
    fi

    # Add new theme keys with defaults
    for key in "theme.color_scheme" "theme.apply_spicetify" "theme.apply_discord"; do
        local existing; existing=$(cfg::_read_raw "${key}" "${file}" 2>/dev/null)
        if [[ -z "${existing}" ]]; then
            local def; def=$(cfg::_schema_default "${key}")
            changes+=("ADD     ${key} = ${def}")
            [[ "${dry}" == "false" ]] && cfg::_write_raw "${key}" "${def}" "${file}"
        fi
    done

    printf '%s\n' "${changes[@]:-}"
}

_migrate::v2_to_v3() {
    local file="$1" dry="$2"
    local changes=()

    # Add ai.* section defaults
    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -ra parts <<< "${schema_line}"
        local key="${parts[0]}" default_val="${parts[2]}"
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)
        [[ "${section}" != "ai" ]] && [[ "${section}" != "privacy" ]] && continue

        local existing; existing=$(cfg::_read_raw "${key}" "${file}" 2>/dev/null)
        if [[ -z "${existing}" ]] && [[ -n "${default_val}" ]]; then
            changes+=("ADD     ${key} = ${default_val}")
            [[ "${dry}" == "false" ]] && cfg::_write_raw "${key}" "${default_val}" "${file}"
        fi
    done

    printf '%s\n' "${changes[@]:-}"
}

_migrate::v3_to_v4() {
    local file="$1" dry="$2"
    local changes=()

    # Split bar.waybar_* → waybar.*
    # (legacy key pattern)
    local old_clock; old_clock=$(cfg::_read_raw "bar.waybar_clock_format" "${file}" 2>/dev/null)
    if [[ -n "${old_clock}" ]]; then
        changes+=("MOVE    bar.waybar_clock_format → waybar.clock_format = ${old_clock}")
        if [[ "${dry}" == "false" ]]; then
            cfg::_write_raw "waybar.clock_format" "${old_clock}" "${file}"
            cfg::_delete_raw "bar.waybar_clock_format" "${file}"
        fi
    fi

    # Add performance.* section
    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -ra parts <<< "${schema_line}"
        local key="${parts[0]}" default_val="${parts[2]}"
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)
        [[ "${section}" != "performance" ]] && continue

        local existing; existing=$(cfg::_read_raw "${key}" "${file}" 2>/dev/null)
        if [[ -z "${existing}" ]] && [[ -n "${default_val}" ]]; then
            changes+=("ADD     ${key} = ${default_val}")
            [[ "${dry}" == "false" ]] && cfg::_write_raw "${key}" "${default_val}" "${file}"
        fi
    done

    printf '%s\n' "${changes[@]:-}"
}

_migrate::v4_to_v5() {
    local file="$1" dry="$2"
    local changes=()

    # Add snapshot.* section
    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -ra parts <<< "${schema_line}"
        local key="${parts[0]}" default_val="${parts[2]}"
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)
        [[ "${section}" != "snapshot" ]] && continue

        local existing; existing=$(cfg::_read_raw "${key}" "${file}" 2>/dev/null)
        if [[ -z "${existing}" ]] && [[ -n "${default_val}" ]]; then
            changes+=("ADD     ${key} = ${default_val}")
            [[ "${dry}" == "false" ]] && cfg::_write_raw "${key}" "${default_val}" "${file}"
        fi
    done

    # Add new hyprland keys
    local new_hypr_keys=(
        "hyprland.smart_gaps"
        "hyprland.smart_borders"
        "hyprland.inactive_opacity"
        "hyprland.active_opacity"
        "hyprland.fullscreen_opacity"
    )
    for key in "${new_hypr_keys[@]}"; do
        local existing; existing=$(cfg::_read_raw "${key}" "${file}" 2>/dev/null)
        if [[ -z "${existing}" ]]; then
            local def; def=$(cfg::_schema_default "${key}")
            [[ -z "${def}" ]] && continue
            changes+=("ADD     ${key} = ${def}")
            [[ "${dry}" == "false" ]] && cfg::_write_raw "${key}" "${def}" "${file}"
        fi
    done

    printf '%s\n' "${changes[@]:-}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::migrate() {
    local from_ver="" to_ver="${CFG_CURRENT_VERSION}"
    local dry_run=false no_backup=false list_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)   config::migrate::help; return 0 ;;
            --from|-f)   from_ver="${2:?'--from requires VERSION'}"; shift 2 ;;
            --to|-t)     to_ver="${2:?'--to requires VERSION'}"; shift 2 ;;
            --dry-run|-n) dry_run=true; shift ;;
            --no-backup) no_backup=true; shift ;;
            --list)      list_mode=true; shift ;;
            -*)          log::error "Unknown option: $1"; return 1 ;;
            *)           shift ;;
        esac
    done

    # ── List mode ─────────────────────────────────────────────────────────────
    if [[ "${list_mode}" == "true" ]]; then
        log::blank
        printf '  %s📋  Available Migrations%s\n\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
        printf '  %s%-12s  %s%s\n' "${BOLD}${ASH_MUTED}" "Version" "Description" "${RST}"
        ash_hr "─" 70 "${ASH_MUTED}"
        for key in $(printf '%s\n' "${!MIGRATION_REGISTRY[@]}" | sort); do
            local from_v="${key%%→*}" to_v="${key##*→}"
            printf '  %sv%s%s → %sv%s%s  %s%s%s\n' \
                "${ASH_INFO}" "${from_v}" "${RST}" \
                "${ASH_SUCCESS}" "${to_v}" "${RST}" \
                "${ASH_MUTED}" "${MIGRATION_REGISTRY[${key}]}" "${RST}"
        done
        log::blank
        return 0
    fi

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Detect current version ────────────────────────────────────────────────
    if [[ -z "${from_ver}" ]]; then
        from_ver=$(cfg::_read_raw "${CFG_VERSION_KEY}" "${file}" 2>/dev/null || echo "1")
        from_ver="${from_ver:-1}"
    fi

    log::blank
    printf '  %s🔄  Config Migration%s\n\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
    printf '  %s%-14s%s %s%s → %s%s\n\n' \
        "${ASH_MUTED}" "Version path" "${RST}" \
        "${BOLD}" "v${from_ver}" "v${to_ver}" "${RST}"

    # ── Already up-to-date ────────────────────────────────────────────────────
    if (( from_ver >= to_ver )); then
        log::success "Config is already at version ${to_ver} — no migration needed"
        log::blank
        return 0
    fi

    # ── Dry run banner ────────────────────────────────────────────────────────
    [[ "${dry_run}" == "true" ]] && \
        printf '  %s%s DRY RUN — no changes will be written%s\n\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"

    # ── Backup ────────────────────────────────────────────────────────────────
    if [[ "${no_backup}" == "false" ]] && [[ "${dry_run}" == "false" ]]; then
        local bkp="${CFG_BACKUP_DIR}/ash.conf.pre-migrate-v${from_ver}-$(date '+%Y%m%d-%H%M%S').bak"
        mkdir -p "${CFG_BACKUP_DIR}"
        cp "${file}" "${bkp}"
        log::info "Backup saved: ${bkp}"
    fi

    # ── Run migration steps ───────────────────────────────────────────────────
    local current_ver="${from_ver}"
    local total_changes=0
    cfg::lock || return 1

    while (( current_ver < to_ver )); do
        local next_ver=$(( current_ver + 1 ))
        local step_fn="_migrate::v${current_ver}_to_v${next_ver}"
        local step_desc="${MIGRATION_REGISTRY["${current_ver}→${next_ver}"]:-Custom migration}"

        printf '  %s[v%d → v%d]%s  %s\n' \
            "${BOLD}${ASH_INFO}" "${current_ver}" "${next_ver}" "${RST}" "${step_desc}"

        if declare -f "${step_fn}" &>/dev/null; then
            local step_out
            step_out=$("${step_fn}" "${file}" "${dry_run}" 2>/dev/null || true)

            if [[ -n "${step_out}" ]]; then
                while IFS= read -r change; do
                    [[ -z "${change}" ]] && continue
                    local kind; kind=$(printf '%s' "${change}" | awk '{print $1}')
                    local detail; detail=$(printf '%s' "${change}" | cut -c9-)
                    local color="${ASH_SUCCESS}"
                    [[ "${kind}" == "RENAME" ]] && color="${ASH_WARNING}"
                    [[ "${kind}" == "REMOVE" ]] && color="${ASH_ERROR}"

                    printf '     %s%-8s%s  %s%s%s\n' \
                        "${color}" "${kind}" "${RST}" \
                        "${ASH_MUTED}" "${detail}" "${RST}"
                    (( total_changes++ ))
                done <<< "${step_out}"
            else
                printf '     %s(no changes required)%s\n' "${ASH_MUTED}" "${RST}"
            fi
        else
            log::warn "No migration function for v${current_ver}→v${next_ver}"
        fi

        # Update version in config
        if [[ "${dry_run}" == "false" ]]; then
            cfg::_write_raw "${CFG_VERSION_KEY}" "${next_ver}" "${file}"
        fi

        current_ver="${next_ver}"
        printf '\n'
    done

    cfg::unlock

    # ── Record migration ──────────────────────────────────────────────────────
    [[ "${dry_run}" == "false" ]] && \
        cfg::_record "migrate" "${CFG_VERSION_KEY}" "${from_ver}" "${to_ver}"

    # ── Summary ───────────────────────────────────────────────────────────────
    ash_hr "─" 70 "${ASH_MUTED}"
    log::blank

    if [[ "${dry_run}" == "true" ]]; then
        printf '  %sDry run complete — %d change(s) would be applied%s\n' \
            "${ASH_WARNING}" "${total_changes}" "${RST}"
    else
        log::success "Migration complete: v${from_ver} → v${to_ver}"
        printf '  %s%d change(s) applied%s\n' "${ASH_MUTED}" "${total_changes}" "${RST}"
    fi
    log::blank
}
