#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — restore.sh                                                  ║
# ║  Safely restore dotfiles from a snapshot with automatic pre-restore backup  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

snapshot::restore::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot restore <id|name> [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--dry-run${RST}        Show what would be restored without applying
  ${ASH_MUTED}--force, -f${RST}      Skip confirmation prompt
  ${ASH_MUTED}--no-backup${RST}      Do not create pre-restore backup snapshot
  ${ASH_MUTED}--targets PATH…${RST}  Restore only specified paths
  ${ASH_MUTED}--no-reload${RST}      Skip hot-reload after restore
  ${ASH_MUTED}--help, -h${RST}       Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash snapshot restore snap-20241215-143022-a3f1
  ash snapshot restore "before-catppuccin" --dry-run
  ash snapshot restore snap-20241215-143022-a3f1 --force --no-backup
EOF
}

# ── Render a restore plan table ────────────────────────────────────────────────
snapshot::restore::plan() {
    local snap_dir="$1"
    local content_dir="${snap_dir}/content"
    local manifest="${snap_dir}/manifest.json"

    printf '\n  %s%s Restore Plan%s\n\n' "${BOLD}${ASH_INFO}" "${ICO_RESTORE}" "${RST}"

    local w_path=40 w_status=12
    # Header
    printf '  %s%-*s  %-*s%s\n' \
        "${BOLD}${ASH_MUTED}" \
        "${w_path}" "Path" \
        "${w_status}" "Status" \
        "${RST}"
    ash_hr "─" 60 "${ASH_MUTED}"

    local count=0
    while IFS= read -r entry; do
        local rel_path type
        rel_path=$(printf '%s' "${entry}" | jq -r '.path' 2>/dev/null)
        type=$(printf '%s' "${entry}"     | jq -r '.type' 2>/dev/null)
        local full_path="${HOME}/${rel_path}"
        local src="${content_dir}/${rel_path}"

        local status_str status_color
        if [[ ! -e "${src}" ]]; then
            status_str="MISSING SRC"
            status_color="${ASH_ERROR}"
        elif [[ ! -e "${full_path}" ]]; then
            status_str="NEW"
            status_color="${ASH_SUCCESS}"
        else
            status_str="OVERWRITE"
            status_color="${ASH_WARNING}"
        fi

        local ico
        [[ "${type}" == "dir" ]] && ico="${ICO_FOLDER}" || ico="${ICO_FILE}"

        printf '  %s%s%s %-*s  %s%-*s%s\n' \
            "${ASH_MUTED}" "${ico}" "${RST}" \
            "$(( w_path - 2 ))" "$(ash_truncate "${rel_path}" $(( w_path - 2 )))" \
            "${status_color}" "${w_status}" "${status_str}" "${RST}"

        (( count++ ))
    done < <(jq -c '.files[]' "${manifest}" 2>/dev/null)

    log::blank
    printf '  %sTotal: %d items to restore%s\n' "${ASH_MUTED}" "${count}" "${RST}"
}

# ── Main ───────────────────────────────────────────────────────────────────────
snapshot::restore() {
    local target_id="" dry_run=false force=false
    local no_backup=false no_reload=false
    local filter_targets=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)    snapshot::restore::help; return 0 ;;
            --dry-run)    dry_run=true; shift ;;
            --force|-f)   force=true; shift ;;
            --no-backup)  no_backup=true; shift ;;
            --no-reload)  no_reload=true; shift ;;
            --targets)    shift
                          while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                              filter_targets+=("$1"); shift
                          done ;;
            -*)           log::error "Unknown option: $1"; return 1 ;;
            *)            target_id="$1"; shift ;;
        esac
    done

    [[ -z "${target_id}" ]] && {
        log::error "Snapshot ID or name is required"
        snapshot::restore::help
        return 1
    }

    # ── Resolve ID ────────────────────────────────────────────────────────────
    local meta_raw
    meta_raw=$(index::find_by_id "${target_id}" 2>/dev/null)
    if [[ -z "${meta_raw}" ]]; then
        meta_raw=$(index::find_by_name "${target_id}" 2>/dev/null)
    fi
    [[ -z "${meta_raw}" ]] && {
        log::error "No snapshot found matching: '${target_id}'"
        log::info  "Run 'ash snapshot list' to see available snapshots"
        return 1
    }

    local snap_id snap_name snap_date snap_checksum
    snap_id=$(printf '%s' "${meta_raw}"       | jq -r '.id')
    snap_name=$(printf '%s' "${meta_raw}"     | jq -r '.name')
    snap_date=$(printf '%s' "${meta_raw}"     | jq -r '.created_at')
    snap_checksum=$(printf '%s' "${meta_raw}" | jq -r '.checksum')

    local snap_dir
    snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    local content_dir="${snap_dir}/content"
    local meta_file="${snap_dir}/metadata.json"
    local archive="${snap_dir}/archive.tar.gz"

    [[ ! -d "${snap_dir}" ]] && {
        log::error "Snapshot directory missing: ${snap_dir}"
        log::warn  "Index may be corrupt. Run 'ash snapshot list --verify'"
        return 1
    }

    # ── Decompress if needed ──────────────────────────────────────────────────
    if [[ ! -d "${content_dir}" ]] && [[ -f "${archive}" ]]; then
        log::info "Decompressing snapshot archive…"
        tar -xzf "${archive}" -C "${snap_dir}"
    fi

    [[ ! -d "${content_dir}" ]] && {
        log::error "Snapshot content missing. Archive may be corrupted."
        return 1
    }

    # ── Verify Integrity ──────────────────────────────────────────────────────
    log::info "Verifying snapshot integrity…"
    local current_checksum
    current_checksum=$(utils::checksum_dir "${content_dir}")
    if [[ "${current_checksum}" != "${snap_checksum}" ]]; then
        log::warn "Checksum mismatch! Snapshot may be corrupted or tampered."
        if [[ "${force}" != "true" ]]; then
            utils::confirm "Continue anyway?" "n" || {
                log::info "Restore cancelled."
                return 1
            }
        fi
    else
        log::success "Integrity check passed"
    fi

    # ── Show Info ─────────────────────────────────────────────────────────────
    log::section "Restoring Snapshot"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Snapshot"  "${RST}" "${SNAP_COLOR_ID}"   "${snap_id}"   "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Name"      "${RST}" "${SNAP_COLOR_NAME}" "${snap_name}" "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Created"   "${RST}" "${SNAP_COLOR_DATE}" \
        "$(date -d "@${snap_date}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${snap_date}" '+%Y-%m-%d %H:%M:%S')" "${RST}"

    # ── Dry Run ───────────────────────────────────────────────────────────────
    if [[ "${dry_run}" == "true" ]]; then
        printf '\n  %s%s DRY RUN MODE — no changes will be made%s\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"
        snapshot::restore::plan "${snap_dir}"
        return 0
    fi

    # ── Show Plan ─────────────────────────────────────────────────────────────
    snapshot::restore::plan "${snap_dir}"

    # ── Confirm ───────────────────────────────────────────────────────────────
    if [[ "${force}" != "true" ]]; then
        utils::confirm "Apply this restore?" "n" || {
            log::info "Restore cancelled."
            return 0
        }
    fi

    # ── Pre-restore Backup ────────────────────────────────────────────────────
    if [[ "${no_backup}" != "true" ]]; then
        log::info "Creating pre-restore safety snapshot…"
        local backup_name="pre-restore-${snap_id:0:20}"
        # Source create module inline
        source "${_SNAP_DIR}/create.sh"
        if snapshot::create "${backup_name}" \
            --tag "auto-backup" \
            --desc "Auto backup before restoring ${snap_id}" \
            --quiet 2>/dev/null; then
            log::success "Safety snapshot created: ${backup_name}"
        else
            log::warn "Could not create safety snapshot (proceeding anyway)"
        fi
    fi

    # ── Acquire Lock ──────────────────────────────────────────────────────────
    lock::acquire 15 || return 1

    # ── Perform Restore ───────────────────────────────────────────────────────
    log::blank
    ash_spinner_start "Restoring configuration files…"

    local restored=0 failed=0 total=0
    local manifest="${snap_dir}/manifest.json"

    while IFS= read -r entry; do
        local rel_path
        rel_path=$(printf '%s' "${entry}" | jq -r '.path' 2>/dev/null)
        local src="${content_dir}/${rel_path}"
        local dest="${HOME}/${rel_path}"

        # Apply target filter if specified
        if (( ${#filter_targets[@]} > 0 )); then
            local match=false
            for f in "${filter_targets[@]}"; do
                [[ "${dest}" == "${f}"* ]] && { match=true; break; }
            done
            [[ "${match}" == "false" ]] && continue
        fi

        (( total++ ))

        if [[ ! -e "${src}" ]]; then
            log::debug "Skipping missing source: ${src}"
            (( failed++ ))
            continue
        fi

        mkdir -p "$(dirname "${dest}")"
        if rsync -a --delete --quiet "${src}" "${dest}" 2>/dev/null; then
            (( restored++ ))
            log::debug "Restored: ${dest}"
        else
            (( failed++ ))
            log::warn "Failed to restore: ${dest}"
        fi
    done < <(jq -c '.files[]' "${manifest}" 2>/dev/null)

    ash_spinner_stop 0 "Restore complete"
    lock::release

    # ── Hot Reload ────────────────────────────────────────────────────────────
    if [[ "${no_reload}" != "true" ]]; then
        log::info "Triggering hot-reload…"
        local reload_script
        reload_script="${_SNAP_DIR}/../../engines/hot-reload-engine/reload-all.sh"
        if [[ -x "${reload_script}" ]]; then
            "${reload_script}" --quiet 2>/dev/null || true
            log::success "Hot-reload triggered"
        else
            log::warn "Hot-reload engine not found; restart apps manually"
        fi
    fi

    # ── Summary ───────────────────────────────────────────────────────────────
    log::blank
    printf '  %s%s Restore Complete%s\n' "${BOLD}${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}"
    printf '  %s%-12s%s %s%d%s files restored\n' \
        "${ASH_MUTED}" "Result" "${RST}" "${ASH_SUCCESS}" "${restored}" "${RST}"
    (( failed > 0 )) && printf '  %s%d files failed%s\n' "${ASH_WARNING}" "${failed}" "${RST}"
    log::blank
}
