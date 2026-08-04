#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — list.sh                                                     ║
# ║  Interactive, filterable snapshot browser with rich metadata display        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

snapshot::list::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot list [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--json${RST}            Output raw JSON
  ${ASH_MUTED}--pinned${RST}          Show only pinned snapshots
  ${ASH_MUTED}--tag, -t TAG${RST}     Filter by tag
  ${ASH_MUTED}--limit, -n N${RST}     Show at most N snapshots (default: 50)
  ${ASH_MUTED}--sort FIELD${RST}      Sort by: date|name|size (default: date)
  ${ASH_MUTED}--asc${RST}             Sort ascending (default: descending)
  ${ASH_MUTED}--verify${RST}          Verify checksum for each snapshot
  ${ASH_MUTED}--compact${RST}         One-line-per-snapshot compact view
  ${ASH_MUTED}--help, -h${RST}        Show this help
EOF
}

# ── Render single snapshot row (compact) ──────────────────────────────────────
snapshot::list::row_compact() {
    local entry="$1" verify="${2:-false}"
    local id name tag pinned ts bytes checksum

    id=$(printf '%s' "${entry}"       | jq -r '.id')
    name=$(printf '%s' "${entry}"     | jq -r '.name')
    tag=$(printf '%s' "${entry}"      | jq -r '.tag // ""')
    pinned=$(printf '%s' "${entry}"   | jq -r '.pinned')
    ts=$(printf '%s' "${entry}"       | jq -r '.created_at')
    bytes=$(printf '%s' "${entry}"    | jq -r '.raw_bytes // 0')
    checksum=$(printf '%s' "${entry}" | jq -r '.checksum // ""')

    local pin_ico=""
    [[ "${pinned}" == "true" ]] && pin_ico="${SNAP_COLOR_PINNED}${ICO_PIN}${RST} "

    local tag_str=""
    [[ -n "${tag}" ]] && tag_str=" ${SNAP_COLOR_TAG}[${tag}]${RST}"

    local verify_ico=""
    if [[ "${verify}" == "true" ]]; then
        local snap_dir actual_checksum
        snap_dir=$(utils::get_snapshot_dir "${id}")
        if [[ -d "${snap_dir}/content" ]]; then
            actual_checksum=$(utils::checksum_dir "${snap_dir}/content")
            if [[ "${actual_checksum}" == "${checksum}" ]]; then
                verify_ico=" ${ASH_SUCCESS}${ICO_SUCCESS}${RST}"
            else
                verify_ico=" ${ASH_ERROR}${ICO_ERROR}${RST}"
            fi
        else
            verify_ico=" ${ASH_WARNING}${ICO_WARN}${RST}"
        fi
    fi

    local rel_time size_str
    rel_time=$(utils::relative_time "${ts}")
    size_str=$(utils::human_size "${bytes}")

    printf '  %s%s%s  %s%-22s%s  %s%-30s%s  %s%8s%s  %s%-10s%s%s%s%s\n' \
        "${SNAP_COLOR_ID}"    "${id:0:26}"    "${RST}" \
        "${SNAP_COLOR_NAME}"  "$(ash_truncate "${name}" 22)"  "${RST}" \
        "${SNAP_COLOR_DATE}"  "${rel_time}"   "${RST}" \
        "${SNAP_COLOR_SIZE}"  "${size_str}"   "${RST}" \
        "${pin_ico}${tag_str}${verify_ico}"
}

# ── Render single snapshot card (detailed) ─────────────────────────────────────
snapshot::list::card() {
    local entry="$1"
    local id name tag desc pinned ts bytes checksum theme mode

    id=$(printf '%s' "${entry}"       | jq -r '.id')
    name=$(printf '%s' "${entry}"     | jq -r '.name')
    tag=$(printf '%s' "${entry}"      | jq -r '.tag // ""')
    desc=$(printf '%s' "${entry}"     | jq -r '.description // ""')
    pinned=$(printf '%s' "${entry}"   | jq -r '.pinned')
    ts=$(printf '%s' "${entry}"       | jq -r '.created_at')
    bytes=$(printf '%s' "${entry}"    | jq -r '.raw_bytes // 0')
    checksum=$(printf '%s' "${entry}" | jq -r '.checksum // ""')

    # Load extra metadata from file if available
    local snap_dir meta_file
    snap_dir=$(utils::get_snapshot_dir "${id}")
    meta_file="${snap_dir}/metadata.json"
    if [[ -f "${meta_file}" ]]; then
        theme=$(jq -r '.theme // "unknown"' "${meta_file}" 2>/dev/null)
        mode=$(jq -r  '.mode  // "default"' "${meta_file}" 2>/dev/null)
    else
        theme="unknown"; mode="default"
    fi

    local size_str rel_time date_str
    size_str=$(utils::human_size "${bytes}")
    rel_time=$(utils::relative_time "${ts}")
    date_str=$(date -d "@${ts}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || date -r "${ts}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || echo "unknown")

    # Card border
    printf '  %s%s%s\n' "${ASH_MUTED}" "$(printf '%0.s─' {1..60})" "${RST}"

    # ID + Pin
    local pin_str=""
    [[ "${pinned}" == "true" ]] && pin_str="  ${SNAP_COLOR_PINNED}${ICO_PIN} PINNED${RST}"
    printf '  %s%s%s%s\n' "${BOLD}${SNAP_COLOR_ID}" "${id}" "${RST}" "${pin_str}"

    # Name
    printf '  %s%s%s' "${BOLD}${SNAP_COLOR_NAME}" "${name}" "${RST}"
    [[ -n "${tag}" ]] && printf '  %s%s %s%s' "${SNAP_COLOR_TAG}" "${ICO_TAG}" "${tag}" "${RST}"
    printf '\n'

    # Description
    [[ -n "${desc}" ]] && printf '  %s%s%s\n' "${ASH_MUTED}" "${desc}" "${RST}"

    # Metadata grid
    printf '  %s%-10s%s %s%s%s   %s%-10s%s %s%s%s\n' \
        "${ASH_MUTED}" "Date"    "${RST}" "${SNAP_COLOR_DATE}" "${date_str}" "${RST}" \
        "${ASH_MUTED}" "Ago"     "${RST}" "${ASH_INFO}"        "${rel_time}" "${RST}"
    printf '  %s%-10s%s %s%s%s   %s%-10s%s %s%s%s\n' \
        "${ASH_MUTED}" "Size"    "${RST}" "${SNAP_COLOR_SIZE}" "${size_str}"  "${RST}" \
        "${ASH_MUTED}" "Theme"   "${RST}" "${ASH_ACCENT}"      "${theme}"     "${RST}"
    printf '  %s%-10s%s %s%s%s\n' \
        "${ASH_MUTED}" "Hash"    "${RST}" "${ASH_MUTED}"       "${checksum:0:20}…" "${RST}"
}

# ── Main ───────────────────────────────────────────────────────────────────────
snapshot::list() {
    local json_out=false pinned_only=false tag_filter=""
    local limit=50 sort_field="date" sort_asc=false
    local verify=false compact=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       snapshot::list::help; return 0 ;;
            --json)          json_out=true; shift ;;
            --pinned)        pinned_only=true; shift ;;
            --tag|-t)        tag_filter="${2:?'--tag requires a value'}"; shift 2 ;;
            --limit|-n)      limit="${2:?'--limit requires a number'}"; shift 2 ;;
            --sort)          sort_field="${2:-date}"; shift 2 ;;
            --asc)           sort_asc=true; shift ;;
            --verify)        verify=true; shift ;;
            --compact)       compact=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               shift ;;
        esac
    done

    index::init

    # ── Build JQ Filter ───────────────────────────────────────────────────────
    local jq_filter='.snapshots'

    [[ "${pinned_only}" == "true" ]] && \
        jq_filter+=' | map(select(.pinned == true))'

    [[ -n "${tag_filter}" ]] && \
        jq_filter+=" | map(select(.tag == \"${tag_filter}\"))"

    # Sort
    case "${sort_field}" in
        name) jq_filter+=' | sort_by(.name)' ;;
        size) jq_filter+=' | sort_by(.raw_bytes)' ;;
        *)    jq_filter+=' | sort_by(.created_at)' ;;
    esac

    [[ "${sort_asc}" == "false" ]] && jq_filter+=' | reverse'

    # Limit
    jq_filter+=" | .[:${limit}]"

    # ── Fetch Data ────────────────────────────────────────────────────────────
    local data
    data=$(jq -c "${jq_filter}" "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo '[]')

    local count
    count=$(printf '%s' "${data}" | jq 'length' 2>/dev/null || echo 0)

    # ── JSON mode ─────────────────────────────────────────────────────────────
    if [[ "${json_out}" == "true" ]]; then
        printf '%s\n' "${data}" | jq '.'
        return 0
    fi

    # ── Empty state ───────────────────────────────────────────────────────────
    if (( count == 0 )); then
        log::blank
        ash_center "${BOLD}${ASH_MUTED}No snapshots found${RST}" 60
        log::blank
        printf '  %sTip:%s ash snapshot create "my-first-snapshot"\n' \
            "${ASH_MUTED}" "${RST}"
        log::blank
        return 0
    fi

    # ── Header ────────────────────────────────────────────────────────────────
    log::blank
    ash_banner \
        "${ICO_LIST}  Snapshots  (${count})" \
        "$(
            [[ -n "${tag_filter}" ]]  && printf ' tag:%s' "${tag_filter}"
            [[ "${pinned_only}" == "true" ]] && printf ' pinned-only'
            [[ "${verify}" == "true" ]] && printf ' +verify'
            :
        )" 70

    # ── Compact mode column headers ────────────────────────────────────────────
    if [[ "${compact}" == "true" ]]; then
        printf '  %s%-26s  %-22s  %-10s  %8s  %s%s\n' \
            "${BOLD}${ASH_MUTED}" "ID" "Name" "When" "Size" "Tags" "${RST}"
        ash_hr "─" 70 "${ASH_MUTED}"
    fi

    # ── Render Each Entry ─────────────────────────────────────────────────────
    local idx=0
    while IFS= read -r entry; do
        (( idx++ ))

        if [[ "${compact}" == "true" ]]; then
            snapshot::list::row_compact "${entry}" "${verify}"
        else
            snapshot::list::card "${entry}"
        fi

    done < <(printf '%s\n' "${data}" | jq -c '.[]' 2>/dev/null)

    # ── Footer ────────────────────────────────────────────────────────────────
    log::blank
    ash_hr "─" 70 "${ASH_MUTED}"
    local total_all
    total_all=$(jq '.snapshots | length' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo 0)
    printf '  %sShowing %d of %d snapshots%s' "${ASH_MUTED}" "${count}" "${total_all}" "${RST}"
    [[ "${limit}" -lt "${total_all}" ]] && \
        printf '  %s(use --limit %d for more)%s' "${ASH_MUTED}" "${total_all}" "${RST}"
    printf '\n'

    printf '  %sStorage: %s%s\n' \
        "${ASH_MUTED}" \
        "$(utils::human_size "$(du -sb "${ASH_SNAPSHOT_DIR}" 2>/dev/null | awk '{print $1}' || echo 0)")" \
        "${RST}"
    log::blank
}
