#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT VERIFY                                    ║
# ║  Deep integrity audit: checksums, index sync, corruption detection & repair   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::verify::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_SUCCESS}  ASH SNAPSHOT VERIFY" \
        "Deep integrity audit — checksum, index & archive validation" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot verify [id|name…] [options]

  If no IDs are given, verifies ALL snapshots.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--quick,   -q${RST}      Check index sync only (skip checksum recompute)
  ${ASH_MUTED}--fix${RST}              Attempt to repair detected issues
  ${ASH_MUTED}--prune-ghost${RST}      Remove index entries with no matching directory
  ${ASH_MUTED}--json${RST}             Output results as JSON
  ${ASH_MUTED}--fail-fast${RST}        Stop at first failure
  ${ASH_MUTED}--help, -h${RST}         Show this help

${BOLD}${ASH_PRIMARY}CHECKS PERFORMED${RST}
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  Snapshot directory exists
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  metadata.json is valid JSON
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  content/ or archive.tar.gz present
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  SHA-256 content checksum matches stored value
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  archive.tar.gz is a valid gzip file
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  Index entry is in sync with metadata.json
  ${ASH_SUCCESS}${ICO_SUCCESS}${RST}  No ghost directories (dirs with no index entry)

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot verify${RST}
  ${ASH_ACCENT}ash snapshot verify${RST} snap-20241215-143022-a3f1 --quick
  ${ASH_ACCENT}ash snapshot verify${RST} --fix --prune-ghost
  ${ASH_ACCENT}ash snapshot verify${RST} --json > report.json
EOF
}

# ── Result constants ──────────────────────────────────────────────────────────
readonly V_PASS="PASS"
readonly V_FAIL="FAIL"
readonly V_WARN="WARN"
readonly V_SKIP="SKIP"

# ── Render result badge ────────────────────────────────────────────────────────
_verify::badge() {
    case "$1" in
        PASS) printf '%s%s PASS%s' "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" ;;
        FAIL) printf '%s%s FAIL%s' "${ASH_ERROR}"   "${ICO_ERROR}"   "${RST}" ;;
        WARN) printf '%s%s WARN%s' "${ASH_WARNING}" "${ICO_WARN}"    "${RST}" ;;
        SKIP) printf '%s─ SKIP%s'  "${ASH_MUTED}"                   "${RST}" ;;
    esac
}

# ── Verify one snapshot ───────────────────────────────────────────────────────
_verify::one() {
    local snap_id="$1" quick="$2" fix="$3"
    local snap_dir; snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    local meta_file="${snap_dir}/metadata.json"
    local archive="${snap_dir}/archive.tar.gz"
    local content_dir="${snap_dir}/content"

    # Collect per-check results
    local -A results=(
        [dir]=SKIP [meta]=SKIP [content]=SKIP
        [checksum]=SKIP [archive]=SKIP [index_sync]=SKIP
    )
    local -A messages

    local overall="${V_PASS}"
    local fail_count=0

    # ── Check 1: Directory exists ─────────────────────────────────────────────
    if [[ -d "${snap_dir}" ]]; then
        results[dir]="${V_PASS}"
    else
        results[dir]="${V_FAIL}"
        messages[dir]="Directory missing: ${snap_dir}"
        (( fail_count++ ))
        overall="${V_FAIL}"
        # Can't continue without dir
        return 1
    fi

    # ── Check 2: metadata.json valid ─────────────────────────────────────────
    if [[ -f "${meta_file}" ]] && jq '.' "${meta_file}" &>/dev/null; then
        results[meta]="${V_PASS}"
    elif [[ ! -f "${meta_file}" ]]; then
        results[meta]="${V_WARN}"
        messages[meta]="metadata.json missing"
        [[ "${overall}" == "${V_PASS}" ]] && overall="${V_WARN}"
    else
        results[meta]="${V_FAIL}"
        messages[meta]="metadata.json is malformed JSON"
        (( fail_count++ ))
        overall="${V_FAIL}"
    fi

    # ── Check 3: Content present ──────────────────────────────────────────────
    if [[ -d "${content_dir}" ]]; then
        results[content]="${V_PASS}"
    elif [[ -f "${archive}" ]]; then
        results[content]="${V_WARN}"
        messages[content]="Only archive present (content not decompressed)"
    else
        results[content]="${V_FAIL}"
        messages[content]="Neither content/ nor archive.tar.gz found"
        (( fail_count++ ))
        overall="${V_FAIL}"
    fi

    # ── Check 4: Archive integrity ────────────────────────────────────────────
    if [[ -f "${archive}" ]]; then
        if gzip -t "${archive}" 2>/dev/null; then
            results[archive]="${V_PASS}"
        else
            results[archive]="${V_FAIL}"
            messages[archive]="archive.tar.gz failed gzip integrity check"
            (( fail_count++ ))
            overall="${V_FAIL}"
        fi
    else
        results[archive]="${V_SKIP}"
    fi

    # ── Check 5: Checksum ─────────────────────────────────────────────────────
    if [[ "${quick}" == "true" ]]; then
        results[checksum]="${V_SKIP}"
        messages[checksum]="Skipped in --quick mode"
    elif [[ -d "${content_dir}" ]]; then
        local stored_chk=""
        [[ -f "${meta_file}" ]] && \
            stored_chk=$(jq -r '.checksum // ""' "${meta_file}" 2>/dev/null)

        if [[ -z "${stored_chk}" ]]; then
            results[checksum]="${V_WARN}"
            messages[checksum]="No stored checksum in metadata"
            [[ "${overall}" == "${V_PASS}" ]] && overall="${V_WARN}"
        else
            local actual_chk
            actual_chk=$(utils::checksum_dir "${content_dir}")
            if [[ "${actual_chk}" == "${stored_chk}" ]]; then
                results[checksum]="${V_PASS}"
            else
                results[checksum]="${V_FAIL}"
                messages[checksum]="Checksum mismatch (stored: ${stored_chk:0:12}… actual: ${actual_chk:0:12}…)"
                (( fail_count++ ))
                overall="${V_FAIL}"

                # Auto-fix: update checksum
                if [[ "${fix}" == "true" ]] && [[ -f "${meta_file}" ]]; then
                    local tmp; tmp=$(mktemp)
                    jq --arg c "${actual_chk}" '.checksum = $c' "${meta_file}" > "${tmp}" \
                        && mv "${tmp}" "${meta_file}"
                    index::update_field "${snap_id}" "checksum" "\"${actual_chk}\""
                    messages[checksum]+=" [FIXED: checksum updated]"
                    results[checksum]="${V_WARN}"
                    overall="${V_WARN}"
                    (( fail_count-- ))
                fi
            fi
        fi
    fi

    # ── Check 6: Index sync ────────────────────────────────────────────────────
    local idx_entry
    idx_entry=$(index::find_by_id "${snap_id}" 2>/dev/null)
    if [[ -z "${idx_entry}" ]]; then
        results[index_sync]="${V_FAIL}"
        messages[index_sync]="Snapshot not registered in index"
        (( fail_count++ ))
        overall="${V_FAIL}"

        # Auto-fix: re-register
        if [[ "${fix}" == "true" ]] && [[ -f "${meta_file}" ]]; then
            local name ts bytes chk pin tag desc
            name=$(jq -r '.name      // "unknown"' "${meta_file}" 2>/dev/null)
            ts=$(jq -r   '.created_at // 0'        "${meta_file}" 2>/dev/null)
            bytes=$(jq -r '.raw_bytes // 0'         "${meta_file}" 2>/dev/null)
            chk=$(jq -r  '.checksum  // ""'         "${meta_file}" 2>/dev/null)
            pin=$(jq -r  '.pinned    // false'       "${meta_file}" 2>/dev/null)
            tag=$(jq -r  '.tag       // ""'          "${meta_file}" 2>/dev/null)
            desc=$(jq -r '.description // ""'        "${meta_file}" 2>/dev/null)

            local new_entry
            new_entry=$(jq -n \
                --arg  id    "${snap_id}" \
                --arg  name  "${name}" \
                --arg  tag   "${tag}" \
                --arg  desc  "${desc}" \
                --argjson p  "${pin}" \
                --argjson ts "${ts}" \
                --argjson b  "${bytes}" \
                --arg  chk   "${chk}" \
                '{id:$id,name:$name,tag:$tag,description:$desc,
                  pinned:$p,created_at:$ts,raw_bytes:$b,checksum:$chk}')
            index::add "${new_entry}"
            messages[index_sync]="Not in index [FIXED: re-registered]"
            results[index_sync]="${V_WARN}"
            overall="${V_WARN}"
            (( fail_count-- ))
        fi
    else
        results[index_sync]="${V_PASS}"
    fi

    # ── Return structured result ───────────────────────────────────────────────
    # Print as JSON for aggregation
    jq -n \
        --arg id       "${snap_id}" \
        --arg overall  "${overall}" \
        --argjson fc   "${fail_count}" \
        --arg  dir     "${results[dir]}" \
        --arg  meta    "${results[meta]}" \
        --arg  content "${results[content]}" \
        --arg  chk     "${results[checksum]}" \
        --arg  archive "${results[archive]}" \
        --arg  idx     "${results[index_sync]}" \
        --arg  msg_dir     "${messages[dir]:-}" \
        --arg  msg_meta    "${messages[meta]:-}" \
        --arg  msg_content "${messages[content]:-}" \
        --arg  msg_chk     "${messages[checksum]:-}" \
        --arg  msg_archive "${messages[archive]:-}" \
        --arg  msg_idx     "${messages[index_sync]:-}" \
        '{id:$id,overall:$overall,fail_count:$fc,
          checks:{
            dir:{result:$dir,message:$msg_dir},
            meta:{result:$meta,message:$msg_meta},
            content:{result:$content,message:$msg_content},
            checksum:{result:$chk,message:$msg_chk},
            archive:{result:$archive,message:$msg_archive},
            index_sync:{result:$idx,message:$msg_idx}
          }}'
}

# ── Render verification result card ──────────────────────────────────────────
_verify::render_result() {
    local result_json="$1"
    local snap_id overall fail_count
    snap_id=$(printf '%s' "${result_json}"    | jq -r '.id')
    overall=$(printf '%s' "${result_json}"    | jq -r '.overall')
    fail_count=$(printf '%s' "${result_json}" | jq -r '.fail_count')

    # Header row
    local snap_name
    snap_name=$(jq -r --arg id "${snap_id}" \
        '.snapshots[] | select(.id == $id) | .name' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo "unknown")

    local overall_badge; overall_badge=$(_verify::badge "${overall}")
    printf '\n  %s%s%s  %s%s%s  %s\n' \
        "${SNAP_COLOR_ID}"   "${snap_id:0:26}"                   "${RST}" \
        "${SNAP_COLOR_NAME}" "$(ash_truncate "${snap_name}" 24)" "${RST}" \
        "${overall_badge}"

    # Per-check rows
    local check_names=(dir meta content checksum archive index_sync)
    local check_labels=("Directory" "Metadata" "Content" "Checksum" "Archive" "Index Sync")

    for i in "${!check_names[@]}"; do
        local cname="${check_names[$i]}" clabel="${check_labels[$i]}"
        local cresult cmsg
        cresult=$(printf '%s' "${result_json}" | jq -r ".checks.${cname}.result")
        cmsg=$(printf '%s'    "${result_json}" | jq -r ".checks.${cname}.message // \"\"")

        local badge; badge=$(_verify::badge "${cresult}")
        printf '     %s  %-14s%s' "${badge}" "${clabel}" "${RST}"
        [[ -n "${cmsg}" ]] && \
            printf '  %s%s%s' "${ASH_MUTED}" "${cmsg}" "${RST}"
        printf '\n'
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::verify() {
    local ids=() quick=false fix=false prune_ghost=false
    local json_out=false fail_fast=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       snapshot::verify::help; return 0 ;;
            --quick|-q)      quick=true; shift ;;
            --fix)           fix=true; shift ;;
            --prune-ghost)   prune_ghost=true; shift ;;
            --json)          json_out=true; shift ;;
            --fail-fast)     fail_fast=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               ids+=("$1"); shift ;;
        esac
    done

    index::init

    # ── Resolve target IDs ────────────────────────────────────────────────────
    local target_ids=()
    if (( ${#ids[@]} > 0 )); then
        for ref in "${ids[@]}"; do
            local entry
            entry=$(index::find_by_id "${ref}" 2>/dev/null)
            [[ -z "${entry}" ]] && entry=$(index::find_by_name "${ref}" 2>/dev/null)
            [[ -z "${entry}" ]] && { log::error "Snapshot not found: '${ref}'"; continue; }
            target_ids+=("$(printf '%s' "${entry}" | jq -r '.id')")
        done
    else
        while IFS= read -r sid; do
            target_ids+=("${sid}")
        done < <(jq -r '.snapshots[].id' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)
    fi

    local total="${#target_ids[@]}"
    if (( total == 0 )); then
        log::warn "No snapshots to verify"
        return 0
    fi

    # ── Ghost directory scan ───────────────────────────────────────────────────
    local ghost_count=0
    if [[ "${prune_ghost}" == "true" ]]; then
        log::info "Scanning for ghost directories…"
        while IFS= read -r snap_dir; do
            local dir_id
            dir_id=$(basename "${snap_dir}")
            if ! jq -e --arg id "${dir_id}" \
                '.snapshots[] | select(.id == $id)' \
                "${ASH_SNAPSHOT_INDEX}" &>/dev/null; then
                log::warn "Ghost directory: ${dir_id}"
                rm -rf "${snap_dir}" 2>/dev/null && (( ghost_count++ ))
                log::debug "Removed ghost: ${snap_dir}"
            fi
        done < <(find "${ASH_SNAPSHOT_DIR}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
        (( ghost_count > 0 )) && log::success "Removed ${ghost_count} ghost directory/directories"
    fi

    # ── Header ────────────────────────────────────────────────────────────────
    if [[ "${json_out}" == "false" ]]; then
        log::blank
        printf '  %s%s Verifying %d Snapshot(s)%s\n' \
            "${BOLD}${ASH_PRIMARY}" "${ICO_SUCCESS}" "${total}" "${RST}"
        [[ "${quick}" == "true" ]]  && \
            printf '  %sQuick mode (checksum skipped)%s\n' "${ASH_MUTED}" "${RST}"
        [[ "${fix}" == "true" ]]    && \
            printf '  %sAuto-fix enabled%s\n' "${ASH_WARNING}" "${RST}"
        log::blank
    fi

    # ── Verify each ───────────────────────────────────────────────────────────
    local pass_count=0 fail_count=0 warn_count=0
    local all_results=()
    local idx=0

    for snap_id in "${target_ids[@]}"; do
        (( idx++ ))
        [[ "${json_out}" == "false" ]] && \
            ash_progress "${idx}" "${total}" "Verifying ${snap_id:0:20}…" 32

        local result
        result=$(_verify::one "${snap_id}" "${quick}" "${fix}" 2>/dev/null || echo '{"overall":"FAIL","fail_count":1}')
        all_results+=("${result}")

        local ov; ov=$(printf '%s' "${result}" | jq -r '.overall')
        case "${ov}" in
            PASS) (( pass_count++ )) ;;
            FAIL) (( fail_count++ ));
                  [[ "${fail_fast}" == "true" ]] && break ;;
            WARN) (( warn_count++ )) ;;
        esac

        # Record in history
        source "${_SNAP_DIR}/history.sh" 2>/dev/null || true
        declare -f history::record &>/dev/null && \
            history::record "verify" "${snap_id}" "" \
            "{\"result\":\"${ov}\"}" 2>/dev/null || true
    done

    # ── JSON output ───────────────────────────────────────────────────────────
    if [[ "${json_out}" == "true" ]]; then
        printf '[\n'
        local ri=0
        for r in "${all_results[@]}"; do
            (( ri++ ))
            printf '  %s%s\n' "${r}" \
                "$( (( ri < ${#all_results[@]} )) && echo ',' || echo '' )"
        done
        printf ']\n'
        return $(( fail_count > 0 ? 1 : 0 ))
    fi

    # ── Render results ────────────────────────────────────────────────────────
    for result in "${all_results[@]}"; do
        _verify::render_result "${result}"
    done

    # ── Summary ───────────────────────────────────────────────────────────────
    log::blank
    ash_hr "═" 70 "${ASH_PRIMARY}"
    printf '\n  %sVerification Summary%s\n\n' "${BOLD}" "${RST}"

    printf '  %s%s PASSED%s   %s%d%s\n' \
        "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" "${BOLD}" "${pass_count}" "${RST}"
    printf '  %s%s WARNINGS%s %s%d%s\n' \
        "${ASH_WARNING}" "${ICO_WARN}"    "${RST}" "${BOLD}" "${warn_count}" "${RST}"
    printf '  %s%s FAILED%s   %s%d%s\n' \
        "${ASH_ERROR}"   "${ICO_ERROR}"   "${RST}" "${BOLD}" "${fail_count}" "${RST}"
    (( ghost_count > 0 )) && \
        printf '  %s%s GHOSTS%s   %s%d removed%s\n' \
            "${ASH_MUTED}" "${ICO_DELETE}" "${RST}" "${BOLD}" "${ghost_count}" "${RST}"

    log::blank

    if (( fail_count > 0 )); then
        printf '  %s%s %d issue(s) require attention%s\n' \
            "${BOLD}${ASH_ERROR}" "${ICO_ERROR}" "${fail_count}" "${RST}"
        printf '  %sTip:%s Re-run with %s--fix%s to attempt auto-repair\n' \
            "${ASH_MUTED}" "${RST}" "${ASH_ACCENT}" "${RST}"
    elif (( warn_count > 0 )); then
        printf '  %s%s All snapshots verified with warnings%s\n' \
            "${ASH_WARNING}" "${ICO_WARN}" "${RST}"
    else
        printf '  %s%s All %d snapshot(s) verified successfully%s\n' \
            "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${total}" "${RST}"
    fi
    log::blank

    return $(( fail_count > 0 ? 1 : 0 ))
}

snapshot::verify "$@"
