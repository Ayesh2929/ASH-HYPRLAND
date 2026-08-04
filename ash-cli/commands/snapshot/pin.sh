#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT PIN                                       ║
# ║  Pin / unpin snapshots to protect them from auto-cleanup & bulk deletes        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::pin::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_PIN}  ASH SNAPSHOT PIN" \
        "Protect snapshots from automated cleanup" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot pin   <id|name> [id2…]   ${ASH_MUTED}Pin one or more snapshots${RST}
  ash snapshot unpin <id|name> [id2…]   ${ASH_MUTED}Unpin one or more snapshots${RST}

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--all-tagged TAG${RST}   Pin/unpin all snapshots with a given tag
  ${ASH_MUTED}--list${RST}             List all currently pinned snapshots
  ${ASH_MUTED}--quiet, -q${RST}        Suppress decorative output
  ${ASH_MUTED}--help,  -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot pin${RST}   snap-20241215-143022-a3f1
  ${ASH_ACCENT}ash snapshot pin${RST}   "before-upgrade" "stable-config"
  ${ASH_ACCENT}ash snapshot unpin${RST} snap-20241215-143022-a3f1
  ${ASH_ACCENT}ash snapshot pin${RST}   --all-tagged stable
  ${ASH_ACCENT}ash snapshot pin${RST}   --list
EOF
}

# ── Render pin status badge ───────────────────────────────────────────────────
_pin::badge() {
    local pinned="$1"
    if [[ "${pinned}" == "true" ]]; then
        printf '%s%s PINNED%s' "${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}"
    else
        printf '%s○ UNPINNED%s' "${ASH_MUTED}" "${RST}"
    fi
}

# ── Set pin state on one snapshot ────────────────────────────────────────────
_pin::set_one() {
    local ref="$1" state="$2" quiet="$3"

    local entry
    entry=$(index::find_by_id "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && {
        log::error "Snapshot not found: '${ref}'"
        return 1
    }

    local snap_id snap_name current_pin
    snap_id=$(printf '%s' "${entry}"      | jq -r '.id')
    snap_name=$(printf '%s' "${entry}"    | jq -r '.name')
    current_pin=$(printf '%s' "${entry}"  | jq -r '.pinned')

    if [[ "${current_pin}" == "${state}" ]]; then
        [[ "${quiet}" == "false" ]] && \
            log::info "'${snap_name}' is already $( [[ "${state}" == "true" ]] && echo "pinned" || echo "unpinned" )"
        return 0
    fi

    # Update index
    index::update_field "${snap_id}" "pinned" "${state}"

    # Update metadata file
    local meta="${ASH_SNAPSHOT_DIR}/${snap_id}/metadata.json"
    if [[ -f "${meta}" ]]; then
        local tmp; tmp=$(mktemp)
        jq --argjson p "${state}" '.pinned = $p' "${meta}" > "${tmp}" && mv "${tmp}" "${meta}"
    fi

    [[ "${quiet}" == "false" ]] && \
        printf '  %s%s%s  %s%s%s  %s\n' \
            "${SNAP_COLOR_ID}"   "${snap_id:0:26}" "${RST}" \
            "${SNAP_COLOR_NAME}" "${snap_name}"    "${RST}" \
            "$(_pin::badge "${state}")"
}

# ── List pinned snapshots ─────────────────────────────────────────────────────
_pin::list_pinned() {
    index::init
    local pinned_entries
    pinned_entries=$(jq -c '.snapshots[] | select(.pinned == true)' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    if [[ -z "${pinned_entries}" ]]; then
        log::blank
        ash_center "${ASH_MUTED}No pinned snapshots${RST}" 60
        log::blank
        return 0
    fi

    printf '\n  %s%s Pinned Snapshots%s\n\n' \
        "${BOLD}${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}"
    printf '  %s%-26s  %-28s  %-12s  %s%s\n' \
        "${BOLD}${ASH_MUTED}" "ID" "Name" "Created" "Tag" "${RST}"
    ash_hr "─" 80 "${ASH_MUTED}"

    while IFS= read -r entry; do
        local sid sname sts stag
        sid=$(printf '%s' "${entry}"   | jq -r '.id')
        sname=$(printf '%s' "${entry}" | jq -r '.name')
        sts=$(printf '%s' "${entry}"   | jq -r '.created_at')
        stag=$(printf '%s' "${entry}"  | jq -r '.tag // ""')

        local ago; ago=$(utils::relative_time "${sts}")

        printf '  %s%-26s%s  %s%-28s%s  %s%-12s%s  %s%s%s\n' \
            "${SNAP_COLOR_ID}"   "${sid:0:26}"                     "${RST}" \
            "${SNAP_COLOR_NAME}" "$(ash_truncate "${sname}" 28)"   "${RST}" \
            "${SNAP_COLOR_DATE}" "${ago}"                           "${RST}" \
            "${SNAP_COLOR_TAG}"  "${stag}"                         "${RST}"
    done <<< "${pinned_entries}"

    local count; count=$(printf '%s\n' "${pinned_entries}" | grep -c '"id"' || echo 0)
    log::blank
    printf '  %s%d snapshot(s) pinned%s\n' "${ASH_MUTED}" "${count}" "${RST}"
    log::blank
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::pin() {
    local action="${1:-pin}"; shift || true
    # Normalise: 'unpin' maps to state=false, everything else to state=true
    local pin_state="true"
    [[ "${action}" == "unpin" ]] && pin_state="false"

    local ids=() all_tagged="" list_mode=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)        snapshot::pin::help; return 0 ;;
            --list)           list_mode=true; shift ;;
            --all-tagged)     all_tagged="${2:?'--all-tagged requires a TAG'}"; shift 2 ;;
            --quiet|-q)       quiet=true; shift ;;
            -*)               log::error "Unknown option: $1"; return 1 ;;
            *)                ids+=("$1"); shift ;;
        esac
    done

    [[ "${list_mode}" == "true" ]] && { _pin::list_pinned; return 0; }

    # Resolve --all-tagged
    if [[ -n "${all_tagged}" ]]; then
        while IFS= read -r sid; do
            ids+=("${sid}")
        done < <(jq -r --arg t "${all_tagged}" \
            '.snapshots[] | select(.tag == $t) | .id' \
            "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)
        (( ${#ids[@]} == 0 )) && {
            log::warn "No snapshots found with tag '${all_tagged}'"
            return 0
        }
    fi

    [[ ${#ids[@]} -eq 0 ]] && {
        log::error "No snapshot ID or name specified."
        snapshot::pin::help; return 1
    }

    local verb; [[ "${pin_state}" == "true" ]] && verb="Pinning" || verb="Unpinning"
    [[ "${quiet}" == "false" ]] && log::section "${verb} ${#ids[@]} Snapshot(s)"

    lock::acquire 10 || return 1
    local ok=0 err=0
    for ref in "${ids[@]}"; do
        _pin::set_one "${ref}" "${pin_state}" "${quiet}" && (( ok++ )) || (( err++ ))
    done
    lock::release

    [[ "${quiet}" == "false" ]] && {
        log::blank
        (( ok > 0 ))  && log::success "${verb} complete: ${ok} snapshot(s)"
        (( err > 0 )) && log::warn    "${err} snapshot(s) could not be updated"
        log::blank
    }
}

snapshot::pin "$@"
