#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG RESET                                           ║
# ║  Reset keys or sections to schema defaults with backup & audit trail              ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::reset::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config reset [key|section] [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${ASH_ACCENT}key${RST}      Reset a specific key to its default
  ${ASH_ACCENT}section${RST}  Reset all keys in a section (e.g. theme, hyprland)
  ${ASH_MUTED}(none)${RST}    Reset the entire configuration

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--no-backup${RST}    Do not create a backup before resetting
  ${ASH_MUTED}--force,  -f${RST}  Skip confirmation prompt
  ${ASH_MUTED}--quiet,  -q${RST}  Suppress output
  ${ASH_MUTED}--help,   -h${RST}  Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config reset
  ash config reset theme
  ash config reset hyprland.gaps_in
  ash config reset ai --force
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::reset() {
    local target="" no_backup=false force=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)   config::reset::help; return 0 ;;
            --no-backup) no_backup=true; shift ;;
            --force|-f)  force=true; shift ;;
            --quiet|-q)  quiet=true; shift ;;
            -*)          log::error "Unknown option: $1"; return 1 ;;
            *)           target="$1"; shift ;;
        esac
    done

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Determine scope ────────────────────────────────────────────────────────
    local scope_label=""
    local -a target_keys=()

    if [[ -z "${target}" ]]; then
        scope_label="entire configuration"
        for line in "${CFG_SCHEMA[@]}"; do
            IFS='|' read -r key _ <<< "${line}"
            target_keys+=("${key}")
        done
    elif cfg::_key_exists_in_schema "${target}"; then
        # Single key
        scope_label="key '${target}'"
        target_keys=("${target}")
    else
        # Section
        scope_label="section '${target}'"
        for line in "${CFG_SCHEMA[@]}"; do
            IFS='|' read -r key _ <<< "${line}"
            local sec; sec=$(printf '%s' "${key}" | cut -d. -f1)
            [[ "${sec}" == "${target}" ]] && target_keys+=("${key}")
        done
        (( ${#target_keys[@]} == 0 )) && {
            log::error "No keys found for section '${target}'"
            return 1
        }
    fi

    # ── Show preview ──────────────────────────────────────────────────────────
    if [[ "${quiet}" == "false" ]]; then
        log::blank
        printf '  %s⚙  Reset: %s%s%s\n\n' \
            "${BOLD}" "${ASH_WARNING}${BOLD}" "${scope_label}" "${RST}"

        local prev_count=0
        for key in "${target_keys[@]}"; do
            local current; current=$(cfg::_read_raw "${key}" "${file}")
            local default_val; default_val=$(cfg::_schema_default "${key}")
            [[ -z "${current}" ]] && continue  # Already at default
            [[ "${current}" == "${default_val}" ]] && continue

            printf '  %s%-45s%s  %s%s%s  %s→%s  %s%s%s\n' \
                "${ASH_MUTED}" "${key}" "${RST}" \
                "${ASH_ERROR}" "${current}" "${RST}" \
                "${ASH_MUTED}" "${RST}" \
                "${ASH_SUCCESS}" "${default_val}" "${RST}"
            (( prev_count++ ))
        done

        if (( prev_count == 0 )); then
            log::success "All keys in ${scope_label} are already at defaults"
            return 0
        fi
        log::blank
    fi

    # ── Confirm ────────────────────────────────────────────────────────────────
    if [[ "${force}" != "true" ]]; then
        utils::confirm "Reset ${scope_label} to defaults?" "n" || {
            log::info "Reset cancelled."; return 0
        }
    fi

    # ── Backup ────────────────────────────────────────────────────────────────
    if [[ "${no_backup}" == "false" ]]; then
        local backup_file="${CFG_BACKUP_DIR}/ash.conf.$(date '+%Y%m%d-%H%M%S').bak"
        mkdir -p "${CFG_BACKUP_DIR}"
        cp "${file}" "${backup_file}"
        [[ "${quiet}" == "false" ]] && \
            log::info "Backup saved: ${backup_file}"
    fi

    # ── Apply reset ────────────────────────────────────────────────────────────
    cfg::lock || return 1
    local count=0
    for key in "${target_keys[@]}"; do
        local default_val; default_val=$(cfg::_schema_default "${key}")
        local current; current=$(cfg::_read_raw "${key}" "${file}")

        if [[ -n "${current}" ]] && [[ "${current}" != "${default_val}" ]]; then
            if [[ -n "${default_val}" ]]; then
                cfg::_write_raw "${key}" "${default_val}" "${file}"
            else
                cfg::_delete_raw "${key}" "${file}"
            fi
            cfg::_record "reset" "${key}" "${current}" "${default_val}"
            (( count++ ))
        fi
    done
    cfg::unlock

    [[ "${quiet}" == "false" ]] && {
        log::blank
        log::success "Reset ${count} key(s) in ${scope_label}"
        log::blank
    }
}
