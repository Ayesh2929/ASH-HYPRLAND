#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT TAG                                       ║
# ║  Add, remove, rename & filter tags across the snapshot collection             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::tag::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_TAG}  ASH SNAPSHOT TAG" \
        "Organise snapshots with flexible tagging" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot tag <subcommand> [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${SNAP_COLOR_NAME}set${RST}    <id|name> <tag>    Set or overwrite a snapshot's tag
  ${SNAP_COLOR_NAME}clear${RST}  <id|name> [id2…]   Remove tag from snapshot(s)
  ${SNAP_COLOR_NAME}rename${RST} <old> <new>         Rename a tag across all snapshots
  ${SNAP_COLOR_NAME}list${RST}   [--counts]          List all distinct tags with counts

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--quiet, -q${RST}   Suppress decorative output
  ${ASH_MUTED}--help,  -h${RST}   Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot tag set${RST}   snap-20241215-143022-a3f1 stable
  ${ASH_ACCENT}ash snapshot tag clear${RST} snap-20241215-143022-a3f1
  ${ASH_ACCENT}ash snapshot tag rename${RST} before-update pre-update
  ${ASH_ACCENT}ash snapshot tag list${RST}  --counts
EOF
}

# ── Validate tag string ───────────────────────────────────────────────────────
_tag::validate() {
    local t="$1"
    [[ -z "${t}" ]]              && { log::error "Tag cannot be empty"; return 1; }
    [[ "${#t}" -gt 32 ]]         && { log::error "Tag too long (max 32 chars)"; return 1; }
    [[ "${t}" =~ [^a-zA-Z0-9._-] ]] && {
        log::error "Tag '${t}' contains invalid characters (allowed: a-z A-Z 0-9 . _ -)"
        return 1
    }
    return 0
}

# ── Update tag in index + metadata ───────────────────────────────────────────
_tag::write() {
    local snap_id="$1" new_tag="$2"

    index::update_field "${snap_id}" "tag" "\"${new_tag}\""

    local meta="${ASH_SNAPSHOT_DIR}/${snap_id}/metadata.json"
    if [[ -f "${meta}" ]]; then
        local tmp; tmp=$(mktemp)
        jq --arg t "${new_tag}" '.tag = $t' "${meta}" > "${tmp}" && mv "${tmp}" "${meta}"
    fi
}

# ── tag set ───────────────────────────────────────────────────────────────────
_tag::set() {
    local ref="$1" new_tag="$2" quiet="${3:-false}"
    _tag::validate "${new_tag}" || return 1

    local entry
    entry=$(index::find_by_id "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && { log::error "Snapshot not found: '${ref}'"; return 1; }

    local snap_id snap_name old_tag
    snap_id=$(printf '%s' "${entry}"   | jq -r '.id')
    snap_name=$(printf '%s' "${entry}" | jq -r '.name')
    old_tag=$(printf '%s' "${entry}"   | jq -r '.tag // ""')

    _tag::write "${snap_id}" "${new_tag}"

    [[ "${quiet}" == "false" ]] && \
        printf '  %s%s%s  %s%s%s  %s→%s  %s%s%s\n' \
            "${SNAP_COLOR_ID}"   "${snap_id:0:26}"                  "${RST}" \
            "${SNAP_COLOR_NAME}" "$(ash_truncate "${snap_name}" 24)" "${RST}" \
            "${ASH_MUTED}" "${RST}" \
            "${SNAP_COLOR_TAG}"  "${new_tag}"                       "${RST}"
}

# ── tag clear ─────────────────────────────────────────────────────────────────
_tag::clear() {
    local ref="$1" quiet="${2:-false}"

    local entry
    entry=$(index::find_by_id "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && { log::error "Snapshot not found: '${ref}'"; return 1; }

    local snap_id snap_name
    snap_id=$(printf '%s' "${entry}"   | jq -r '.id')
    snap_name=$(printf '%s' "${entry}" | jq -r '.name')

    _tag::write "${snap_id}" ""

    [[ "${quiet}" == "false" ]] && \
        printf '  %s%s%s  %s%s%s  %stag cleared%s\n' \
            "${SNAP_COLOR_ID}"   "${snap_id:0:26}"                  "${RST}" \
            "${SNAP_COLOR_NAME}" "$(ash_truncate "${snap_name}" 24)" "${RST}" \
            "${ASH_MUTED}" "${RST}"
}

# ── tag rename ────────────────────────────────────────────────────────────────
_tag::rename() {
    local old_tag="$1" new_tag="$2" quiet="${3:-false}"
    _tag::validate "${new_tag}" || return 1

    local affected=0
    while IFS= read -r snap_id; do
        _tag::write "${snap_id}" "${new_tag}"
        (( affected++ ))
        [[ "${quiet}" == "false" ]] && \
            printf '  %s%s%s  renamed tag: %s%s%s → %s%s%s\n' \
                "${SNAP_COLOR_ID}" "${snap_id:0:26}" "${RST}" \
                "${SNAP_COLOR_TAG}" "${old_tag}" "${RST}" \
                "${SNAP_COLOR_TAG}" "${new_tag}" "${RST}"
    done < <(jq -r --arg t "${old_tag}" \
        '.snapshots[] | select(.tag == $t) | .id' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    if (( affected == 0 )); then
        log::warn "No snapshots found with tag '${old_tag}'"
    else
        log::success "Renamed tag '${old_tag}' → '${new_tag}' on ${affected} snapshot(s)"
    fi
}

# ── tag list ──────────────────────────────────────────────────────────────────
_tag::list() {
    local counts="${1:-false}"

    # Gather all distinct tags with counts
    local tag_data
    tag_data=$(jq -r '
        .snapshots
        | map(.tag // "")
        | map(select(. != ""))
        | group_by(.)
        | map({tag: .[0], count: length})
        | sort_by(.tag)
        | .[]
        | "\(.count)\t\(.tag)"
    ' "${ASH_SNAPSHOT_INDEX}" 2>/dev/null)

    if [[ -z "${tag_data}" ]]; then
        log::blank
        ash_center "${ASH_MUTED}No tags assigned to any snapshot${RST}" 60
        log::blank
        return 0
    fi

    printf '\n  %s%s All Tags%s\n\n' "${BOLD}${ASH_PRIMARY}" "${ICO_TAG}" "${RST}"

    if [[ "${counts}" == "true" ]]; then
        printf '  %s%-32s  %s%s\n' "${BOLD}${ASH_MUTED}" "Tag" "Count" "${RST}"
        ash_hr "─" 50 "${ASH_MUTED}"
        while IFS=$'\t' read -r count tag; do
            # Draw a mini bar
            local bar_len=$(( count > 20 ? 20 : count ))
            local bar; bar=$(printf '%*s' "${bar_len}" '' | tr ' ' '▪')
            printf '  %s%-32s%s  %s%3d%s  %s%s%s\n' \
                "${SNAP_COLOR_TAG}"  "${tag}"   "${RST}" \
                "${SNAP_COLOR_SIZE}" "${count}" "${RST}" \
                "${ASH_MUTED}"       "${bar}"   "${RST}"
        done <<< "${tag_data}"
    else
        while IFS=$'\t' read -r _ tag; do
            printf '  %s%s %s%s%s\n' \
                "${SNAP_COLOR_TAG}" "${ICO_TAG}" \
                "${BOLD}" "${tag}" "${RST}"
        done <<< "${tag_data}"
    fi

    # Untagged count
    local untagged_count
    untagged_count=$(jq \
        '.snapshots | map(select(.tag == "" or .tag == null)) | length' \
        "${ASH_SNAPSHOT_INDEX}" 2>/dev/null || echo 0)
    (( untagged_count > 0 )) && \
        printf '\n  %s%d snapshot(s) untagged%s\n' "${ASH_MUTED}" "${untagged_count}" "${RST}"
    log::blank
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::tag() {
    local subcmd="${1:-list}"; shift || true
    local quiet=false

    # Peek for global flags
    local _args=()
    for arg in "$@"; do
        case "${arg}" in
            --quiet|-q) quiet=true ;;
            --help|-h)  snapshot::tag::help; return 0 ;;
            *)          _args+=("${arg}") ;;
        esac
    done
    set -- "${_args[@]:-}"

    index::init

    case "${subcmd}" in
        set)
            local ref="${1:?'tag set requires <id> <tag>'}"; shift
            local new_tag="${1:?'tag set requires a tag value'}"; shift
            [[ "${quiet}" == "false" ]] && log::section "Setting Tag"
            lock::acquire 10 || return 1
            _tag::set "${ref}" "${new_tag}" "${quiet}"
            lock::release
            [[ "${quiet}" == "false" ]] && { log::blank; log::success "Tag set"; log::blank; }
            ;;

        clear)
            (( $# < 1 )) && { log::error "clear requires at least one ID"; return 1; }
            [[ "${quiet}" == "false" ]] && log::section "Clearing Tags"
            lock::acquire 10 || return 1
            for ref in "$@"; do
                _tag::clear "${ref}" "${quiet}"
            done
            lock::release
            [[ "${quiet}" == "false" ]] && { log::blank; log::success "Tags cleared"; log::blank; }
            ;;

        rename)
            local old="${1:?'rename requires <old-tag> <new-tag>'}"; shift
            local new="${1:?'rename requires a new tag value'}"; shift
            [[ "${quiet}" == "false" ]] && log::section "Renaming Tag: ${old} → ${new}"
            lock::acquire 10 || return 1
            _tag::rename "${old}" "${new}" "${quiet}"
            lock::release
            ;;

        list|ls)
            local show_counts=false
            [[ "${1:-}" == "--counts" ]] && show_counts=true
            _tag::list "${show_counts}"
            ;;

        help|--help|-h)
            snapshot::tag::help ;;
        *)
            log::error "Unknown subcommand: '${subcmd}'"
            log::info  "Run 'ash snapshot tag --help' for usage"
            return 1 ;;
    esac
}

snapshot::tag "$@"
