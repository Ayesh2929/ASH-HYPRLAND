#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT CLEAN                                     ║
# ║  Intelligent garbage collection with rich preview & safety guards             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::clean::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_DELETE}  ASH SNAPSHOT CLEAN" \
        "Smart garbage collection with dry-run preview" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot clean [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--older-than,  -o DAYS${RST}   Remove unpinned snapshots older than N days
  ${ASH_MUTED}--keep,        -k N${RST}       Keep only N most recent unpinned snapshots
  ${ASH_MUTED}--untagged${RST}               Remove only untagged unpinned snapshots
  ${ASH_MUTED}--tag,         -t TAG${RST}     Remove only snapshots with this tag
  ${ASH_MUTED}--orphaned${RST}               Remove snapshots with missing content dirs
  ${ASH_MUTED}--cache${RST}                  Clear decompressed content caches only
  ${ASH_MUTED}--dry-run,     -n${RST}         Preview deletions without acting
  ${ASH_MUTED}--force,       -f${RST}          Skip confirmation prompt
  ${ASH_MUTED}--help,        -h${RST}          Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot clean${RST} --older-than 30 --dry-run
  ${ASH_ACCENT}ash snapshot clean${RST} --keep 5 --force
  ${ASH_ACCENT}ash snapshot clean${RST} --untagged --older-than 7
  ${ASH_ACCENT}ash snapshot clean${RST} --orphaned
  ${ASH_ACCENT}ash snapshot clean${RST} --cache
EOF
}

# ── Render deletion plan table ────────────────────────────────────────────────
_clean::render_plan() {
    local -n _ids="$1"   # nameref: array of IDs to delete
    local total_bytes=0

    printf '\n  %s%s Deletion Plan%s\n\n' "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"
    printf '  %s%-26s  %-28s  %-10s  %s%s\n' \
        "${BOLD}${ASH_MUTED}" "ID" "Name" "Age" "Size" "${RST}"
    ash_hr "─" 76 "${ASH_MUTED}"

    local count=0
    for sid in "${_ids[@]}"; do
        local entry
        entry=$(jq -r --arg id "${sid}" \
            '.snapshots[] | select(.id == $id)' \
            "${ASH_SNAPSHOT_INDEX}" 2>/dev/null) || continue

        local sname sts sbytes
        sname=$(printf '%s' "${entry}"  | jq -r '.name')
        sts=$(printf '%s' "${entry}"    | jq -r '.created_at')
        sbytes=$(printf '%s' "${entry}" | jq -r '.raw_bytes // 0')

        local age_str; age_str=$(utils::relative_time "${sts}")
        local size_str; size_str=$(utils::human_size "${sbytes}")

        printf '  %s%-26s%s  %s%-28s%s  %s%-10s%s  %s%s%s\n' \
            "${SNAP_COLOR_ID}"   "${sid:0:26}"                    "${RST}" \
            "${SNAP_COLOR_NAME}" "$(ash_truncate "${sname}" 28)"  "${RST}" \
            "${SNAP_COLOR_DATE}" "${age_str}"                     "${RST}" \
            "${SNAP_COLOR_SIZE}" "${size_str}"                    "${RST}"

        (( total_bytes += sbytes ))
        (( count++ ))
    done

    ash_hr "─" 76 "${ASH_MUTED}"
    printf '  %s%d snapshot(s) — %s will be freed%s\n\n' \
        "${BOLD}" "${count}" \
        "$(utils::human_size "${total_bytes}")" "${RST}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::clean() {
    local older_than=0 keep=0 untagged=false tag_filter=""
    local orphaned=false cache_only=false dry_run=false force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)        snapshot::clean::help; return 0 ;;
            --older-than|-o)  older_than="${2:?'--older-than requires days'}"; shift 2 ;;
            --keep|-k)        keep="${2:?'--keep requires a number'}"; shift 2 ;;
            --untagged)       untagged=true; shift ;;
            --tag|-t)         tag_filter="${2:?'--tag requires a value'}"; shift 2 ;;
            --orphaned)       orphaned=true; shift ;;
            --cache)          cache_only=true; shift ;;
            --dry-run|-n)     dry_run=true; shift ;;
            --force|-f)       force=true; shift ;;
            -*)               log::error "Unknown option: $1"; return 1 ;;
            *)                shift ;;
        esac
    done

    index::init

    log::section "Snapshot Clean"
    [[ "${dry_run}" == "true" ]] && \
        printf '  %s%s DRY RUN — no files will be deleted%s\n\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"

    # ── Cache-only mode ───────────────────────────────────────────────────────
    if [[ "${cache_only}" == "true" ]]; then
        log::info "Scanning for decompressed content caches…"
        local freed=0
        while IFS= read -r snap_id; do
            local sdir; sdir=$(utils::get_snapshot_dir "${snap_id}")
            local content_dir="${sdir}/content"
            local archive="${sdir}/archive.tar.gz"
            if [[ -d "${content_dir}" ]] && [[ -f "${archive}" ]]; then
                local sz; sz=$(du -sb "${content_dir}" 2>/dev/null | awk '{print $1}' || echo 0)
                if [[ "${dry_run}" == "false" ]]; then
                    rm -rf "${content_dir}"
                    log::debug "Cleared cache: ${snap_id}"
                fi
                (( freed += sz ))
            fi
        done < <(jq -r '.snapshots[].id' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

        if [[ "${dry_run}" == "true" ]]; then
            log::info "Would free $(utils::human_size "${freed}") in cache directories"
        else
            log::success "Cleared $(utils::human_size "${freed}") of cached content"
        fi
        return 0
    fi

    # ── Orphaned mode ─────────────────────────────────────────────────────────
    local to_delete=()

    if [[ "${orphaned}" == "true" ]]; then
        log::info "Scanning for orphaned snapshots…"
        while IFS= read -r snap_id; do
            local sdir; sdir=$(utils::get_snapshot_dir "${snap_id}")
            if [[ ! -d "${sdir}/content" ]] && [[ ! -f "${sdir}/archive.tar.gz" ]]; then
                to_delete+=("${snap_id}")
                log::debug "Orphaned: ${snap_id}"
            fi
        done < <(jq -r '.snapshots[].id' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)
    fi

    # ── Build JQ filter for policy-based selection ────────────────────────────
    local jq_f='.snapshots | map(select(.pinned == false))'

    [[ "${untagged}" == "true" ]] && \
        jq_f+=' | map(select(.tag == "" or .tag == null))'

    [[ -n "${tag_filter}" ]] && \
        jq_f+=" | map(select(.tag == \"${tag_filter}\"))"

    if (( older_than > 0 )); then
        local cutoff=$(( $(date +%s) - older_than * 86400 ))
        jq_f+=" | map(select(.created_at < ${cutoff}))"
    fi

    jq_f+=' | sort_by(.created_at) | .[].id'

    while IFS= read -r snap_id; do
        # Avoid duplicates
        local dup=false
        for existing in "${to_delete[@]:-}"; do
            [[ "${existing}" == "${snap_id}" ]] && { dup=true; break; }
        done
        [[ "${dup}" == "false" ]] && to_delete+=("${snap_id}")
    done < <(jq -r "${jq_f}" "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    # ── Apply --keep (trim from oldest, keep newest N) ────────────────────────
    if (( keep > 0 )); then
        local total_unpinned
        total_unpinned=$(jq '.snapshots | map(select(.pinned == false)) | length' \
            "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo 0)
        local excess=$(( total_unpinned - keep ))
        if (( excess > 0 )); then
            local keep_ids=()
            while IFS= read -r sid; do
                keep_ids+=("${sid}")
            done < <(jq -r \
                '.snapshots | map(select(.pinned == false))
                 | sort_by(.created_at) | .[:'"${excess}"'] | .[].id' \
                "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

            for sid in "${keep_ids[@]}"; do
                local dup=false
                for existing in "${to_delete[@]:-}"; do
                    [[ "${existing}" == "${sid}" ]] && { dup=true; break; }
                done
                [[ "${dup}" == "false" ]] && to_delete+=("${sid}")
            done
        fi
    fi

    # ── Nothing to do ─────────────────────────────────────────────────────────
    if (( ${#to_delete[@]} == 0 )); then
        log::success "Nothing to clean — all snapshots match retention policy"
        local total; total=$(jq '.snapshots | length' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)
        local sz; sz=$(du -sh "${ASH_SNAPSHOT_DIR}" 2>/dev/null | awk '{print $1}' || echo "?")
        printf '  %s%d snapshots, %s on disk%s\n' "${ASH_MUTED}" "${total}" "${sz}" "${RST}"
        return 0
    fi

    # ── Show plan ─────────────────────────────────────────────────────────────
    _clean::render_plan to_delete

    [[ "${dry_run}" == "true" ]] && return 0

    # ── Confirm ───────────────────────────────────────────────────────────────
    if [[ "${force}" != "true" ]]; then
        utils::confirm \
            "Permanently delete ${#to_delete[@]} snapshot(s)?" "n" || {
            log::info "Clean cancelled."
            return 0
        }
    fi

    # ── Execute ───────────────────────────────────────────────────────────────
    lock::acquire 15 || return 1

    local freed=0 ok=0 err=0
    local total="${#to_delete[@]}"
    local idx=0

    for sid in "${to_delete[@]}"; do
        (( idx++ ))
        ash_progress "${idx}" "${total}" "Deleting ${sid:0:20}…" 36

        local sdir; sdir=$(utils::get_snapshot_dir "${sid}")
        local sz=0
        [[ -d "${sdir}" ]] && sz=$(du -sb "${sdir}" 2>/dev/null | awk '{print $1}' || echo 0)

        if rm -rf "${sdir}" 2>/dev/null; then
            index::remove "${sid}"
            (( freed += sz ))
            (( ok++ ))
        else
            log::warn "Could not delete: ${sid}"
            (( err++ ))
        fi
    done

    lock::release

    log::blank
    (( ok > 0 ))  && log::success "Removed ${ok} snapshot(s), freed $(utils::human_size "${freed}")"
    (( err > 0 )) && log::warn    "${err} snapshot(s) could not be deleted"

    # Post-clean stats
    local remaining; remaining=$(jq '.snapshots | length' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo 0)
    local remaining_sz; remaining_sz=$(du -sh "${ASH_SNAPSHOT_DIR}" 2>/dev/null | awk '{print $1}' || echo "?")
    printf '  %s%d snapshots remaining, %s on disk%s\n' \
        "${ASH_MUTED}" "${remaining}" "${remaining_sz}" "${RST}"
    log::blank
}

snapshot::clean "$@"
