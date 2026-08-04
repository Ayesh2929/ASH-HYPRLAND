#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT HISTORY                                   ║
# ║  Rich timeline browser, action audit log & interactive navigation             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

readonly HISTORY_FILE="${ASH_STATE_DIR}/snapshot-history.jsonl"
readonly HISTORY_MAX_ENTRIES=500

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::history::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_CLOCK}  ASH SNAPSHOT HISTORY" \
        "Audit log, timeline browser & usage analytics" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot history [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--limit,   -n N${RST}     Show last N events (default: 25)
  ${ASH_MUTED}--action   ACT${RST}      Filter: create|restore|delete|export|import|tag|pin
  ${ASH_MUTED}--snap-id  ID${RST}       Show history for a specific snapshot
  ${ASH_MUTED}--since    DATE${RST}     Events since date (YYYY-MM-DD)
  ${ASH_MUTED}--json${RST}              Raw JSONL output
  ${ASH_MUTED}--stats${RST}             Show usage statistics & analytics
  ${ASH_MUTED}--timeline${RST}          Render a visual timeline
  ${ASH_MUTED}--clear${RST}             Clear entire history (with confirmation)
  ${ASH_MUTED}--help, -h${RST}          Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot history${RST}
  ${ASH_ACCENT}ash snapshot history${RST} --action restore --limit 10
  ${ASH_ACCENT}ash snapshot history${RST} --stats
  ${ASH_ACCENT}ash snapshot history${RST} --timeline --limit 50
  ${ASH_ACCENT}ash snapshot history${RST} --snap-id snap-20241215-143022-a3f1
EOF
}

# ── Append to history log ──────────────────────────────────────────────────────
history::record() {
    # history::record <action> <snap_id> <snap_name> [extra_json_kv]
    local action="$1" snap_id="$2" snap_name="${3:-}" extra="${4:-}"
    mkdir -p "$(dirname "${HISTORY_FILE}")"

    local entry
    entry=$(jq -cn \
        --arg action    "${action}" \
        --arg snap_id   "${snap_id}" \
        --arg snap_name "${snap_name}" \
        --argjson ts    "$(date +%s)" \
        --arg user      "${USER:-unknown}" \
        --arg host      "$(hostname -s 2>/dev/null || echo unknown)" \
        '{action:$action,snap_id:$snap_id,snap_name:$snap_name,
          timestamp:$ts,user:$user,host:$host}')

    # Merge extra keys
    if [[ -n "${extra}" ]]; then
        entry=$(printf '%s\n%s' "${entry}" "${extra}" | jq -sc '.[0] * .[1]')
    fi

    printf '%s\n' "${entry}" >> "${HISTORY_FILE}"

    # Rotate if too large (keep last HISTORY_MAX_ENTRIES lines)
    local line_count
    line_count=$(wc -l < "${HISTORY_FILE}" 2>/dev/null || echo 0)
    if (( line_count > HISTORY_MAX_ENTRIES )); then
        local tmp; tmp=$(mktemp)
        tail -n "${HISTORY_MAX_ENTRIES}" "${HISTORY_FILE}" > "${tmp}"
        mv "${tmp}" "${HISTORY_FILE}"
    fi
}

# ── Action icon ───────────────────────────────────────────────────────────────
_hist::action_style() {
    case "$1" in
        create)  printf '%s%s%s' "${ASH_SUCCESS}"  "${ICO_CREATE}"  "${RST}" ;;
        restore) printf '%s%s%s' "${ASH_INFO}"     "${ICO_RESTORE}" "${RST}" ;;
        delete)  printf '%s%s%s' "${ASH_ERROR}"    "${ICO_DELETE}"  "${RST}" ;;
        export)  printf '%s%s%s' "${ASH_WARNING}"  "${ICO_EXPORT}"  "${RST}" ;;
        import)  printf '%s%s%s' "${ASH_PRIMARY}"  "${ICO_SNAPSHOT}""${RST}" ;;
        pin)     printf '%s%s%s' "${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}" ;;
        unpin)   printf '%s%s%s' "${ASH_MUTED}"    "${ICO_PIN}"     "${RST}" ;;
        tag)     printf '%s%s%s' "${SNAP_COLOR_TAG}" "${ICO_TAG}"   "${RST}" ;;
        verify)  printf '%s%s%s' "${ASH_SUCCESS}"  "${ICO_SUCCESS}" "${RST}" ;;
        *)       printf '%s%s%s' "${ASH_MUTED}"    "${ICO_INFO}"    "${RST}" ;;
    esac
}

# ── Row renderer ─────────────────────────────────────────────────────────────
_hist::render_row() {
    local entry="$1"
    local action ts snap_id snap_name
    action=$(printf '%s' "${entry}"    | jq -r '.action    // "unknown"')
    ts=$(printf '%s' "${entry}"        | jq -r '.timestamp // 0')
    snap_id=$(printf '%s' "${entry}"   | jq -r '.snap_id   // ""')
    snap_name=$(printf '%s' "${entry}" | jq -r '.snap_name // ""')

    local date_str rel_time
    date_str=$(date -d "@${ts}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || date -r "${ts}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || echo "unknown")
    rel_time=$(utils::relative_time "${ts}")

    local act_icon; act_icon=$(_hist::action_style "${action}")
    local action_pad; printf -v action_pad '%-8s' "${action}"

    printf '  %s  %s%s%s  %s%-26s%s  %s%-24s%s  %s%s%s\n' \
        "${act_icon}" \
        "${ASH_MUTED}" "${action_pad}" "${RST}" \
        "${SNAP_COLOR_ID}"   "${snap_id:0:26}"                    "${RST}" \
        "${SNAP_COLOR_NAME}" "$(ash_truncate "${snap_name}" 24)"  "${RST}" \
        "${SNAP_COLOR_DATE}" "${rel_time}"                        "${RST}"
}

# ── Timeline renderer ─────────────────────────────────────────────────────────
_hist::render_timeline() {
    local limit="$1"
    local -a events=()

    [[ ! -f "${HISTORY_FILE}" ]] && {
        log::warn "No history recorded yet"
        return 0
    }

    while IFS= read -r line; do
        events+=("${line}")
    done < <(tail -n "${limit}" "${HISTORY_FILE}" | sort -t'"' -k4 2>/dev/null || tail -n "${limit}" "${HISTORY_FILE}")

    printf '\n  %s%s Timeline%s  (last %d events)\n\n' \
        "${BOLD}${ASH_PRIMARY}" "${ICO_CLOCK}" "${RST}" "${#events[@]}"

    local prev_date=""
    for entry in "${events[@]}"; do
        local ts; ts=$(printf '%s' "${entry}" | jq -r '.timestamp // 0')
        local cur_date
        cur_date=$(date -d "@${ts}" '+%Y-%m-%d' 2>/dev/null \
                   || date -r "${ts}" '+%Y-%m-%d' 2>/dev/null || echo "")

        # Day separator
        if [[ "${cur_date}" != "${prev_date}" ]] && [[ -n "${cur_date}" ]]; then
            prev_date="${cur_date}"
            printf '\n  %s─── %s ───────────────────────────────────────%s\n' \
                "${ASH_MUTED}" "${cur_date}" "${RST}"
        fi

        local action ts_fmt snap_name snap_id
        action=$(printf '%s' "${entry}"    | jq -r '.action    // "unknown"')
        ts_fmt=$(date -d "@${ts}" '+%H:%M:%S' 2>/dev/null \
                 || date -r "${ts}" '+%H:%M:%S' 2>/dev/null || echo "?")
        snap_name=$(printf '%s' "${entry}" | jq -r '.snap_name // ""')
        snap_id=$(printf '%s' "${entry}"   | jq -r '.snap_id   // ""')

        local act_ico; act_ico=$(_hist::action_style "${action}")

        printf '  %s%s%s  %s  %s%s%s  %s%s%s\n' \
            "${ASH_MUTED}" "${ts_fmt}" "${RST}" \
            "${act_ico}" \
            "${SNAP_COLOR_NAME}" "$(ash_truncate "${snap_name}" 28)" "${RST}" \
            "${SNAP_COLOR_ID}"   "${snap_id:0:20}" "${RST}"
    done
    log::blank
}

# ── Stats dashboard ───────────────────────────────────────────────────────────
_hist::render_stats() {
    [[ ! -f "${HISTORY_FILE}" ]] && {
        log::warn "No history data available"
        return 0
    }

    printf '\n  %s%s Usage Statistics%s\n\n' \
        "${BOLD}${ASH_PRIMARY}" "${ICO_INFO}" "${RST}"

    # Action frequency
    declare -A action_counts
    local total=0
    while IFS= read -r entry; do
        local a; a=$(printf '%s' "${entry}" | jq -r '.action // "unknown"')
        action_counts["${a}"]=$(( ${action_counts["${a}"]:-0} + 1 ))
        (( total++ ))
    done < "${HISTORY_FILE}"

    printf '  %sAction Breakdown%s\n' "${BOLD}${ASH_MUTED}" "${RST}"
    ash_hr "─" 50 "${ASH_MUTED}"

    local max_count=1
    for v in "${action_counts[@]}"; do
        (( v > max_count )) && max_count="${v}"
    done

    for action in create restore delete export import pin unpin tag verify; do
        local cnt="${action_counts[${action}]:-0}"
        (( cnt == 0 )) && continue
        local bar_w=$(( cnt * 30 / max_count ))
        local bar; bar=$(printf '%*s' "${bar_w}" '' | tr ' ' '▪')
        local pct=$(( cnt * 100 / total ))
        local act_ico; act_ico=$(_hist::action_style "${action}")

        printf '  %s  %-8s%s  %s%-30s%s  %s%3d%s  %s%3d%%%s\n' \
            "${act_ico}" "${action}" "${RST}" \
            "${ASH_PRIMARY}" "${bar}" "${RST}" \
            "${BOLD}" "${cnt}" "${RST}" \
            "${ASH_MUTED}" "${pct}" "${RST}"
    done

    # Most active snapshots
    printf '\n  %sMost Referenced Snapshots%s\n' "${BOLD}${ASH_MUTED}" "${RST}"
    ash_hr "─" 50 "${ASH_MUTED}"

    jq -r '.snap_name' "${HISTORY_FILE}" 2>/dev/null \
        | sort | uniq -c | sort -rn | head -5 \
        | while read -r cnt sname; do
            printf '  %s%3d%s  %s%s%s\n' \
                "${BOLD}" "${cnt}" "${RST}" \
                "${SNAP_COLOR_NAME}" "${sname}" "${RST}"
        done

    # Total events & date range
    local first_ts last_ts
    first_ts=$(head -1 "${HISTORY_FILE}" | jq -r '.timestamp // 0')
    last_ts=$(tail  -1 "${HISTORY_FILE}" | jq -r '.timestamp // 0')
    local first_date; first_date=$(date -d "@${first_ts}" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
    local last_date;  last_date=$(date  -d "@${last_ts}"  '+%Y-%m-%d' 2>/dev/null || echo "unknown")

    printf '\n  %sTotal Events%s  %s%d%s  (%s to %s)\n' \
        "${ASH_MUTED}" "${RST}" \
        "${BOLD}" "${total}" "${RST}" \
        "${first_date}" "${last_date}"
    log::blank
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::history() {
    local limit=25 action_filter="" snap_id_filter="" since=""
    local json_out=false stats=false timeline=false clear_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      snapshot::history::help; return 0 ;;
            --limit|-n)     limit="${2:?'--limit requires N'}"; shift 2 ;;
            --action)       action_filter="${2:?'--action requires a value'}"; shift 2 ;;
            --snap-id)      snap_id_filter="${2:?'--snap-id requires an ID'}"; shift 2 ;;
            --since)        since="${2:?'--since requires YYYY-MM-DD'}"; shift 2 ;;
            --json)         json_out=true; shift ;;
            --stats)        stats=true; shift ;;
            --timeline)     timeline=true; shift ;;
            --clear)        clear_mode=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              shift ;;
        esac
    done

    # ── Clear mode ────────────────────────────────────────────────────────────
    if [[ "${clear_mode}" == "true" ]]; then
        utils::confirm "Clear entire snapshot history?" "n" || { log::info "Cancelled."; return 0; }
        rm -f "${HISTORY_FILE}"
        log::success "History cleared"
        return 0
    fi

    # ── Stats ─────────────────────────────────────────────────────────────────
    [[ "${stats}" == "true" ]] && { _hist::render_stats; return 0; }

    # ── Timeline ──────────────────────────────────────────────────────────────
    [[ "${timeline}" == "true" ]] && { _hist::render_timeline "${limit}"; return 0; }

    # ── Empty guard ───────────────────────────────────────────────────────────
    if [[ ! -f "${HISTORY_FILE}" ]] || [[ ! -s "${HISTORY_FILE}" ]]; then
        log::blank
        ash_center "${ASH_MUTED}No history recorded yet${RST}" 60
        log::blank
        printf '  %sTip:%s Snapshots you create, restore & export will appear here.\n' \
            "${ASH_MUTED}" "${RST}"
        log::blank
        return 0
    fi

    # ── Filter & collect ──────────────────────────────────────────────────────
    local since_ts=0
    [[ -n "${since}" ]] && since_ts=$(date -d "${since}" +%s 2>/dev/null || echo 0)

    local -a rows=()
    while IFS= read -r entry; do
        [[ -z "${entry}" ]] && continue

        local a_action a_snap_id a_ts
        a_action=$(printf '%s' "${entry}"   | jq -r '.action    // ""')
        a_snap_id=$(printf '%s' "${entry}"  | jq -r '.snap_id   // ""')
        a_ts=$(printf '%s' "${entry}"       | jq -r '.timestamp // 0')

        [[ -n "${action_filter}" ]] && [[ "${a_action}" != "${action_filter}" ]] && continue
        [[ -n "${snap_id_filter}" ]] && [[ "${a_snap_id}" != "${snap_id_filter}"* ]] && continue
        (( since_ts > 0 )) && (( a_ts < since_ts )) && continue

        rows+=("${entry}")
    done < <(tail -n "$((limit * 3))" "${HISTORY_FILE}" | tac)  # newest first

    local total_rows="${#rows[@]}"
    (( total_rows > limit )) && rows=("${rows[@]:0:${limit}}")
    local show_count="${#rows[@]}"

    # ── JSON mode ─────────────────────────────────────────────────────────────
    if [[ "${json_out}" == "true" ]]; then
        printf '[\n'
        local idx=0
        for entry in "${rows[@]}"; do
            (( idx++ ))
            printf '  %s%s\n' \
                "${entry}" "$( (( idx < show_count )) && echo ',' || echo '' )"
        done
        printf ']\n'
        return 0
    fi

    # ── Table header ──────────────────────────────────────────────────────────
    log::blank
    printf '  %s%s Snapshot History%s' \
        "${BOLD}${ASH_PRIMARY}" "${ICO_CLOCK}" "${RST}"
    [[ -n "${action_filter}" ]] && \
        printf '  %sfilter: %s%s%s' "${ASH_MUTED}" "${SNAP_COLOR_TAG}" "${action_filter}" "${RST}"
    printf '\n\n'
    printf '  %s%-10s  %-26s  %-24s  %s%s\n' \
        "${BOLD}${ASH_MUTED}" "Action" "Snapshot ID" "Name" "When" "${RST}"
    ash_hr "─" 80 "${ASH_MUTED}"

    for entry in "${rows[@]}"; do
        _hist::render_row "${entry}"
    done

    # ── Footer ────────────────────────────────────────────────────────────────
    ash_hr "─" 80 "${ASH_MUTED}"
    printf '  %sShowing %d of %d events%s\n' \
        "${ASH_MUTED}" "${show_count}" "${total_rows}" "${RST}"
    local total_all
    total_all=$(wc -l < "${HISTORY_FILE}" 2>/dev/null || echo 0)
    printf '  %s%d total events in log%s\n\n' "${ASH_MUTED}" "${total_all}" "${RST}"
}

snapshot::history "$@"
