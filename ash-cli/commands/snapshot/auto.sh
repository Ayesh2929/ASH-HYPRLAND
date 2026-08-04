#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT AUTO                                      ║
# ║  Intelligent automatic snapshot scheduling, triggers & retention policy        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ── Defaults ──────────────────────────────────────────────────────────────────
readonly AUTO_STATE_FILE="${ASH_STATE_DIR}/auto-snapshot.json"
readonly AUTO_LOCK_FILE="${ASH_STATE_DIR}/.auto-snapshot.lock"

_auto::state_init() {
    [[ -f "${AUTO_STATE_FILE}" ]] && return 0
    cat > "${AUTO_STATE_FILE}" <<'EOF'
{
  "enabled":           false,
  "interval_hours":    24,
  "trigger_on_theme":  true,
  "trigger_on_update": true,
  "trigger_on_mode":   false,
  "max_auto_keep":     10,
  "max_age_days":      30,
  "prefix":            "auto",
  "tag":               "auto",
  "last_run_at":       0,
  "last_snap_id":      ""
}
EOF
}

_auto::state_get() { local k="$1"; jq -r ".${k} // empty" "${AUTO_STATE_FILE}" 2>/dev/null; }
_auto::state_set() {
    local key="$1" val="$2"
    local tmp; tmp=$(mktemp)
    # Determine type: quote strings, pass numbers/bools raw
    if [[ "${val}" =~ ^(true|false|[0-9]+)$ ]]; then
        jq --argjson v "${val}" ".${key} = \$v" "${AUTO_STATE_FILE}" > "${tmp}"
    else
        jq --arg v "${val}" ".${key} = \$v" "${AUTO_STATE_FILE}" > "${tmp}"
    fi
    mv "${tmp}" "${AUTO_STATE_FILE}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::auto::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_CLOCK}  ASH SNAPSHOT AUTO" \
        "Intelligent automatic snapshot scheduling & retention" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot auto <subcommand> [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${SNAP_COLOR_NAME}enable${RST}                   Enable automatic snapshots
  ${SNAP_COLOR_NAME}disable${RST}                  Disable automatic snapshots
  ${SNAP_COLOR_NAME}status${RST}                   Show current auto-snapshot configuration
  ${SNAP_COLOR_NAME}run${RST}                      Trigger a manual auto-snapshot now
  ${SNAP_COLOR_NAME}configure${RST} [options]      Adjust auto-snapshot settings

${BOLD}${ASH_PRIMARY}CONFIGURE OPTIONS${RST}
  ${ASH_MUTED}--interval,    -i HOURS${RST}  Hours between auto-snapshots   (default: 24)
  ${ASH_MUTED}--max-keep,    -k N${RST}      Maximum auto snapshots to keep (default: 10)
  ${ASH_MUTED}--max-age,     -a DAYS${RST}   Delete auto snaps older than N days (default: 30)
  ${ASH_MUTED}--prefix,      -p STR${RST}    Filename prefix for auto snapshots
  ${ASH_MUTED}--tag,         -t TAG${RST}    Tag applied to all auto snapshots
  ${ASH_MUTED}--on-theme${RST}               Snapshot before every theme change
  ${ASH_MUTED}--no-on-theme${RST}            Disable pre-theme-change snapshots
  ${ASH_MUTED}--on-update${RST}              Snapshot before every system update
  ${ASH_MUTED}--no-on-update${RST}           Disable pre-update snapshots
  ${ASH_MUTED}--on-mode${RST}                Snapshot on mode switch
  ${ASH_MUTED}--help, -h${RST}              Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot auto enable${RST}
  ${ASH_ACCENT}ash snapshot auto configure${RST} --interval 12 --max-keep 20
  ${ASH_ACCENT}ash snapshot auto run${RST}
  ${ASH_ACCENT}ash snapshot auto status${RST}
EOF
}

# ── Retention: prune old auto snapshots ───────────────────────────────────────
_auto::prune() {
    local max_keep; max_keep=$(_auto::state_get max_auto_keep)
    local max_age;  max_age=$(_auto::state_get max_age_days)
    local prefix;   prefix=$(_auto::state_get prefix)

    log::debug "Auto-prune: max_keep=${max_keep} max_age=${max_age}d"

    # Collect auto snapshots sorted by date ascending (oldest first)
    local auto_ids=()
    while IFS= read -r snap_id; do
        auto_ids+=("${snap_id}")
    done < <(jq -r \
        --arg pfx "${prefix}-" \
        '.snapshots
         | map(select((.name | startswith($pfx)) and .pinned == false))
         | sort_by(.created_at)
         | .[].id' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    local now; now=$(date +%s)
    local cutoff=$(( now - max_age * 86400 ))
    local deleted=0

    for sid in "${auto_ids[@]}"; do
        local ts
        ts=$(jq -r --arg id "${sid}" \
            '.snapshots[] | select(.id == $id) | .created_at' \
            "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo 0)

        if (( ts < cutoff )); then
            local sdir; sdir=$(utils::get_snapshot_dir "${sid}")
            rm -rf "${sdir}" 2>/dev/null
            index::remove "${sid}"
            (( deleted++ ))
            log::debug "Pruned (age): ${sid}"
        fi
    done

    # Re-collect after age pruning
    local remaining=()
    while IFS= read -r sid; do
        remaining+=("${sid}")
    done < <(jq -r \
        --arg pfx "${prefix}-" \
        '.snapshots
         | map(select((.name | startswith($pfx)) and .pinned == false))
         | sort_by(.created_at)
         | .[].id' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    # Prune by count
    local excess=$(( ${#remaining[@]} - max_keep ))
    if (( excess > 0 )); then
        for (( i=0; i<excess; i++ )); do
            local sid="${remaining[$i]}"
            local sdir; sdir=$(utils::get_snapshot_dir "${sid}")
            rm -rf "${sdir}" 2>/dev/null
            index::remove "${sid}"
            (( deleted++ ))
            log::debug "Pruned (count): ${sid}"
        done
    fi

    (( deleted > 0 )) && log::info "Auto-prune: removed ${deleted} old snapshot(s)"
}

# ── Check if a snapshot is due ────────────────────────────────────────────────
_auto::is_due() {
    local interval_h; interval_h=$(_auto::state_get interval_hours)
    local last_run;   last_run=$(_auto::state_get last_run_at)
    local now;        now=$(date +%s)
    local threshold=$(( interval_h * 3600 ))
    (( now - last_run >= threshold ))
}

# ── Status renderer ───────────────────────────────────────────────────────────
_auto::render_status() {
    _auto::state_init
    local enabled;        enabled=$(_auto::state_get enabled)
    local interval;       interval=$(_auto::state_get interval_hours)
    local max_keep;       max_keep=$(_auto::state_get max_auto_keep)
    local max_age;        max_age=$(_auto::state_get max_age_days)
    local prefix;         prefix=$(_auto::state_get prefix)
    local tag;            tag=$(_auto::state_get tag)
    local on_theme;       on_theme=$(_auto::state_get trigger_on_theme)
    local on_update;      on_update=$(_auto::state_get trigger_on_update)
    local on_mode;        on_mode=$(_auto::state_get trigger_on_mode)
    local last_run;       last_run=$(_auto::state_get last_run_at)
    local last_snap_id;   last_snap_id=$(_auto::state_get last_snap_id)

    local enabled_color="${ASH_ERROR}"
    local enabled_str="DISABLED"
    [[ "${enabled}" == "true" ]] && { enabled_color="${ASH_SUCCESS}"; enabled_str="ENABLED"; }

    local due_str="—"
    _auto::is_due && due_str="${ASH_WARNING}NOW${RST}"

    local last_str="never"
    (( last_run > 0 )) && last_str=$(utils::relative_time "${last_run}")

    log::blank
    printf '  %s%s Auto Snapshot Status%s\n\n' \
        "${BOLD}${ASH_PRIMARY}" "${ICO_CLOCK}" "${RST}"

    printf '  %s%-20s%s %s%s%s\n' "${ASH_MUTED}" "Status"       "${RST}" \
        "${BOLD}${enabled_color}" "${enabled_str}" "${RST}"
    printf '  %s%-20s%s %s%dh%s\n' "${ASH_MUTED}" "Interval"    "${RST}" \
        "${ASH_INFO}" "${interval}" "${RST}"
    printf '  %s%-20s%s %s%d snapshots%s\n' "${ASH_MUTED}" "Max keep"    "${RST}" \
        "${SNAP_COLOR_SIZE}" "${max_keep}" "${RST}"
    printf '  %s%-20s%s %s%d days%s\n' "${ASH_MUTED}" "Max age"     "${RST}" \
        "${SNAP_COLOR_SIZE}" "${max_age}" "${RST}"
    printf '  %s%-20s%s %s%s%s\n' "${ASH_MUTED}" "Prefix"       "${RST}" \
        "${SNAP_COLOR_NAME}" "${prefix}" "${RST}"
    printf '  %s%-20s%s %s%s%s\n' "${ASH_MUTED}" "Tag"          "${RST}" \
        "${SNAP_COLOR_TAG}" "${tag}" "${RST}"
    printf '  %s%-20s%s %s%s%s\n' "${ASH_MUTED}" "Last run"     "${RST}" \
        "${SNAP_COLOR_DATE}" "${last_str}" "${RST}"
    [[ -n "${last_snap_id}" ]] && \
        printf '  %s%-20s%s %s%s%s\n' "${ASH_MUTED}" "Last snapshot" "${RST}" \
            "${SNAP_COLOR_ID}" "${last_snap_id}" "${RST}"
    printf '\n'

    local _bool_on="${ASH_SUCCESS}${ICO_SUCCESS}${RST}"
    local _bool_off="${ASH_MUTED}○${RST}"
    printf '  %sTriggers%s\n' "${BOLD}${ASH_MUTED}" "${RST}"
    printf '  %s  %-18s%s %s\n' "${ASH_MUTED}" "Before theme"  "${RST}" \
        "$( [[ "${on_theme}"  == "true" ]] && printf '%s' "${_bool_on}" || printf '%s' "${_bool_off}" )"
    printf '  %s  %-18s%s %s\n' "${ASH_MUTED}" "Before update" "${RST}" \
        "$( [[ "${on_update}" == "true" ]] && printf '%s' "${_bool_on}" || printf '%s' "${_bool_off}" )"
    printf '  %s  %-18s%s %s\n' "${ASH_MUTED}" "On mode switch"  "${RST}" \
        "$( [[ "${on_mode}"   == "true" ]] && printf '%s' "${_bool_on}" || printf '%s' "${_bool_off}" )"

    # Next due countdown
    local last_run_ts; last_run_ts=$(_auto::state_get last_run_at)
    if (( last_run_ts > 0 )); then
        local next_ts=$(( last_run_ts + interval * 3600 ))
        local now; now=$(date +%s)
        if (( next_ts > now )); then
            local secs_left=$(( next_ts - now ))
            printf '\n  %sNext auto-snapshot in %dh %dm%s\n' \
                "${ASH_MUTED}" \
                "$(( secs_left / 3600 ))" \
                "$(( (secs_left % 3600) / 60 ))" \
                "${RST}"
        else
            printf '\n  %s%s Auto-snapshot is overdue%s\n' \
                "${ASH_WARNING}" "${ICO_WARN}" "${RST}"
        fi
    fi
    log::blank
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::auto() {
    _auto::state_init

    local subcmd="${1:-status}"; shift || true

    case "${subcmd}" in
        enable)
            _auto::state_set enabled true
            log::success "Auto-snapshot ENABLED"
            _auto::render_status
            ;;

        disable)
            _auto::state_set enabled false
            log::info "Auto-snapshot disabled"
            ;;

        status)
            _auto::render_status
            ;;

        run)
            # ── Trigger an immediate auto-snapshot ─────────────────────────
            local prefix; prefix=$(_auto::state_get prefix)
            local auto_tag; auto_tag=$(_auto::state_get tag)
            local snap_name="${prefix}-$(date '+%Y%m%d-%H%M%S')"

            log::section "Auto-Snapshot — On Demand"

            source "${_SNAP_DIR}/create.sh"
            local new_id
            new_id=$(snapshot::create "${snap_name}" \
                --tag "${auto_tag}" \
                --desc "Auto-snapshot triggered manually" \
                --quiet) || {
                log::error "Auto-snapshot creation failed"
                return 1
            }

            _auto::state_set last_run_at "$(date +%s)"
            _auto::state_set last_snap_id "${new_id}"

            _auto::prune

            log::success "Auto-snapshot created: ${new_id}"
            printf '  %sName:%s %s%s%s\n' \
                "${ASH_MUTED}" "${RST}" "${SNAP_COLOR_NAME}" "${snap_name}" "${RST}"
            ;;

        configure)
            # ── Apply configuration changes ────────────────────────────────
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --interval|-i)   _auto::state_set interval_hours "${2:?}"; shift 2 ;;
                    --max-keep|-k)   _auto::state_set max_auto_keep  "${2:?}"; shift 2 ;;
                    --max-age|-a)    _auto::state_set max_age_days   "${2:?}"; shift 2 ;;
                    --prefix|-p)     _auto::state_set prefix         "${2:?}"; shift 2 ;;
                    --tag|-t)        _auto::state_set tag            "${2:?}"; shift 2 ;;
                    --on-theme)      _auto::state_set trigger_on_theme  true;  shift ;;
                    --no-on-theme)   _auto::state_set trigger_on_theme  false; shift ;;
                    --on-update)     _auto::state_set trigger_on_update true;  shift ;;
                    --no-on-update)  _auto::state_set trigger_on_update false; shift ;;
                    --on-mode)       _auto::state_set trigger_on_mode   true;  shift ;;
                    --no-on-mode)    _auto::state_set trigger_on_mode   false; shift ;;
                    --help|-h)       snapshot::auto::help; return 0 ;;
                    *)               log::error "Unknown option: $1"; return 1 ;;
                esac
            done
            log::success "Auto-snapshot configuration updated"
            _auto::render_status
            ;;

        # ── Internal hook called by theme/update engines ───────────────────
        _hook_theme|_hook_update|_hook_mode)
            local trigger="${subcmd#_hook_}"
            local key="trigger_on_${trigger}"
            local enabled_flag; enabled_flag=$(_auto::state_get enabled)
            local trigger_flag; trigger_flag=$(_auto::state_get "${key}")

            [[ "${enabled_flag}" != "true" ]]  && return 0
            [[ "${trigger_flag}" != "true" ]]  && return 0

            local prefix; prefix=$(_auto::state_get prefix)
            local auto_tag; auto_tag=$(_auto::state_get tag)
            local snap_name="${prefix}-${trigger}-$(date '+%Y%m%d-%H%M%S')"

            source "${_SNAP_DIR}/create.sh"
            local new_id
            new_id=$(snapshot::create "${snap_name}" \
                --tag "${auto_tag}" \
                --desc "Auto-snapshot: ${trigger} trigger" \
                --quiet) && {
                _auto::state_set last_run_at "$(date +%s)"
                _auto::state_set last_snap_id "${new_id}"
                _auto::prune
                log::debug "Auto-snapshot created on ${trigger}: ${new_id}"
            }
            ;;

        help|--help|-h)
            snapshot::auto::help ;;
        *)
            log::error "Unknown subcommand: '${subcmd}'"
            log::info  "Run 'ash snapshot auto --help' for usage"
            return 1 ;;
    esac
}

snapshot::auto "$@"
