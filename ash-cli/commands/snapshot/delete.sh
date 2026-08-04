#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — delete.sh                                                   ║
# ║  Safely delete snapshots with pin-protection and batch support              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

snapshot::delete::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot delete <id|name> [id2…] [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--force,    -f${RST}    Skip confirmation prompt
  ${ASH_MUTED}--unpin${RST}           Unpin before deleting (bypass pin protection)
  ${ASH_MUTED}--all-untagged${RST}    Delete all untagged, unpinned snapshots
  ${ASH_MUTED}--older-than DAYS${RST} Delete unpinned snapshots older than N days
  ${ASH_MUTED}--dry-run${RST}         Show what would be deleted without acting
  ${ASH_MUTED}--help, -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash snapshot delete snap-20241215-143022-a3f1
  ash snapshot delete "old-config" --force
  ash snapshot delete --all-untagged --older-than 30
  ash snapshot delete snap-A snap-B snap-C --force
EOF
}

snapshot::delete::one() {
    local id="$1" force="$2" unpin="$3" dry_run="$4"

    # Resolve
    local entry
    entry=$(index::find_by_id "${id}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${id}" 2>/dev/null)
    [[ -z "${entry}" ]] && {
        log::error "Snapshot not found: '${id}'"
        return 1
    }

    local snap_id snap_name snap_pinned
    snap_id=$(printf '%s' "${entry}"     | jq -r '.id')
    snap_name=$(printf '%s' "${entry}"   | jq -r '.name')
    snap_pinned=$(printf '%s' "${entry}" | jq -r '.pinned')

    # Pin guard
    if [[ "${snap_pinned}" == "true" ]] && [[ "${unpin}" != "true" ]]; then
        log::warn "Snapshot '${snap_name}' (${snap_id}) is pinned."
        log::info "Use --unpin to override pin protection."
        return 1
    fi

    local snap_dir
    snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    local snap_size=0
    if [[ -d "${snap_dir}" ]]; then
        snap_size=$(du -sb "${snap_dir}" 2>/dev/null | awk '{print $1}' || echo 0)
    fi

    # Display what will be deleted
    printf '  %s%s%s  %s%s%s  %s%s%s  %s%s%s\n' \
        "${SNAP_COLOR_ID}"    "${snap_id:0:26}" "${RST}" \
        "${SNAP_COLOR_NAME}"  "${snap_name}"    "${RST}" \
        "${SNAP_COLOR_SIZE}"  "$(utils::human_size "${snap_size}")" "${RST}" \
        "${ASH_ERROR}"        "${ICO_DELETE}"   "${RST}"

    [[ "${dry_run}" == "true" ]] && return 0

    # Delete filesystem
    if [[ -d "${snap_dir}" ]]; then
        rm -rf "${snap_dir}"
    fi

    # Remove from index
    index::remove "${snap_id}"

    log::success "Deleted: ${snap_name} (${snap_id})"
    printf '%s' "${snap_size}"   # Return freed bytes via stdout for accumulation
}

snapshot::delete() {
    local ids=() force=false unpin=false dry_run=false
    local all_untagged=false older_than=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)        snapshot::delete::help; return 0 ;;
            --force|-f)       force=true; shift ;;
            --unpin)          unpin=true; shift ;;
            --dry-run)        dry_run=true; shift ;;
            --all-untagged)   all_untagged=true; shift ;;
            --older-than)     older_than="${2:?'--older-than requires days'}"; shift 2 ;;
            -*)               log::error "Unknown option: $1"; return 1 ;;
            *)                ids+=("$1"); shift ;;
        esac
    done

    # ── Build deletion list from flags ────────────────────────────────────────
    if [[ "${all_untagged}" == "true" ]] || (( older_than > 0 )); then
        local jq_f='.snapshots[] | select(.pinned == false)'
        [[ "${all_untagged}" == "true" ]] && \
            jq_f+=' | select(.tag == "" or .tag == null)'
        if (( older_than > 0 )); then
            local cutoff=$(( $(date +%s) - older_than * 86400 ))
            jq_f+=" | select(.created_at < ${cutoff})"
        fi

        while IFS= read -r entry; do
            ids+=("$(printf '%s' "${entry}" | jq -r '.id')")
        done < <(jq -c "${jq_f}" "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)
    fi

    [[ ${#ids[@]} -eq 0 ]] && {
        log::error "No snapshot IDs specified."
        snapshot::delete::help
        return 1
    }

    # ── Show batch summary ────────────────────────────────────────────────────
    log::section "Deleting ${#ids[@]} Snapshot(s)"
    [[ "${dry_run}" == "true" ]] && \
        printf '  %s%s DRY RUN — no files will be removed%s\n\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"

    # ── Confirm ───────────────────────────────────────────────────────────────
    if [[ "${force}" != "true" ]] && [[ "${dry_run}" != "true" ]]; then
        utils::confirm \
            "Delete ${#ids[@]} snapshot(s)? This cannot be undone." "n" || {
            log::info "Cancelled."
            return 0
        }
    fi

    lock::acquire 10 || return 1

    local freed=0 ok=0 err=0
    for id in "${ids[@]}"; do
        local freed_bytes
        freed_bytes=$(snapshot::delete::one "${id}" "${force}" "${unpin}" "${dry_run}" 2>/dev/null) || {
            (( err++ ))
            continue
        }
        (( freed += freed_bytes ))
        (( ok++ ))
    done

    lock::release

    log::blank
    (( ok > 0 )) && log::success "Deleted ${ok} snapshot(s), freed $(utils::human_size "${freed}")"
    (( err > 0 )) && log::warn   "${err} snapshot(s) could not be deleted"
    [[ "${dry_run}" == "true" ]] && \
        printf '  %sDry run complete — no changes made%s\n' "${ASH_WARNING}" "${RST}"
    log::blank
}
