#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — diff.sh                                                     ║
# ║  Rich visual diff between snapshots or snapshot vs current config           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

snapshot::diff::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot diff <id1> [id2] [options]

  If only one ID is given, diffs that snapshot against current config.
  If two IDs are given, diffs those two snapshots against each other.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--stat${RST}             Show only summary statistics
  ${ASH_MUTED}--files${RST}            Show only changed file paths (no content diff)
  ${ASH_MUTED}--path, -p PATH${RST}    Restrict diff to a specific path
  ${ASH_MUTED}--context, -c N${RST}    Lines of context in unified diff (default: 3)
  ${ASH_MUTED}--color/--no-color${RST} Force enable/disable colored diff output
  ${ASH_MUTED}--help, -h${RST}         Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash snapshot diff snap-20241215-143022-a3f1
  ash snapshot diff snap-A snap-B
  ash snapshot diff snap-A --path ~/.config/hypr/hyprland.conf
  ash snapshot diff snap-A --stat
EOF
}

# ── Resolve a snapshot's content directory or live config ─────────────────────
snapshot::diff::resolve_dir() {
    local ref="$1"

    # Special keyword: current live config
    if [[ "${ref}" == "current" ]]; then
        local tmp_dir
        tmp_dir=$(mktemp -d /tmp/ash-snap-current.XXXXXX)
        trap 'rm -rf "${tmp_dir}"' RETURN

        for target in "${SNAPSHOT_TARGETS[@]}"; do
            [[ ! -e "${target}" ]] && continue
            local rel_path="${target#"${HOME}/"}"
            local dest="${tmp_dir}/${rel_path}"
            mkdir -p "$(dirname "${dest}")"
            rsync -a --quiet "${target}" "${dest}" 2>/dev/null || true
        done
        printf '%s' "${tmp_dir}"
        return 0
    fi

    # Resolve from index
    local entry
    entry=$(index::find_by_id "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${ref}" 2>/dev/null)
    [[ -z "${entry}" ]] && {
        log::error "Snapshot not found: '${ref}'"
        return 1
    }

    local snap_id snap_dir
    snap_id=$(printf '%s' "${entry}" | jq -r '.id')
    snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    local content="${snap_dir}/content"

    # Decompress if needed
    if [[ ! -d "${content}" ]] && [[ -f "${snap_dir}/archive.tar.gz" ]]; then
        tar -xzf "${snap_dir}/archive.tar.gz" -C "${snap_dir}" 2>/dev/null
    fi

    [[ ! -d "${content}" ]] && {
        log::error "Content directory missing for snapshot: ${snap_id}"
        return 1
    }
    printf '%s' "${content}"
}

# ── Colored unified diff rendering ────────────────────────────────────────────
snapshot::diff::render_unified() {
    local diff_output="$1"

    while IFS= read -r line; do
        case "${line}" in
            '---'*|'+++'*)
                printf '%s%s%s\n' "${BOLD}${ASH_MUTED}" "${line}" "${RST}"
                ;;
            '@@'*)
                printf '%s%s%s\n' "${BOLD}${ASH_INFO}" "${line}" "${RST}"
                ;;
            '+'*)
                printf '%s%s%s\n' "${SNAP_COLOR_DIFF_ADD}" "${line}" "${RST}"
                ;;
            '-'*)
                printf '%s%s%s\n' "${SNAP_COLOR_DIFF_DEL}" "${line}" "${RST}"
                ;;
            ' '*)
                printf '%s%s%s\n' "${ASH_MUTED}" "${line}" "${RST}"
                ;;
            *)
                printf '%s\n' "${line}"
                ;;
        esac
    done <<< "${diff_output}"
}

# ── File-level summary table ──────────────────────────────────────────────────
snapshot::diff::summary_table() {
    local dir_a="$1" dir_b="$2" path_filter="${3:-}"
    local added=0 removed=0 modified=0 unchanged=0

    printf '\n  %s%-50s  %-10s%s\n' "${BOLD}${ASH_MUTED}" "File" "Status" "${RST}"
    ash_hr "─" 70 "${ASH_MUTED}"

    local find_args=(-type f)
    [[ -n "${path_filter}" ]] && find_args+=(-path "*${path_filter}*")

    # Files in A
    while IFS= read -r rel; do
        local file_a="${dir_a}/${rel}" file_b="${dir_b}/${rel}"
        if [[ ! -e "${file_b}" ]]; then
            printf '  %s%-50s  %sDELETED %s%s\n' \
                "${ASH_MUTED}" "$(ash_truncate "${rel}" 50)" \
                "${SNAP_COLOR_DIFF_DEL}" "${ICO_DELETE}" "${RST}"
            (( removed++ ))
        elif ! diff -q "${file_a}" "${file_b}" &>/dev/null; then
            printf '  %s%-50s  %sMODIFIED%s\n' \
                "${ASH_MUTED}" "$(ash_truncate "${rel}" 50)" \
                "${SNAP_COLOR_DIFF_MOD}" "${RST}"
            (( modified++ ))
        else
            (( unchanged++ ))
        fi
    done < <(find "${dir_a}" "${find_args[@]}" 2>/dev/null | sed "s|${dir_a}/||")

    # Files in B not in A (new)
    while IFS= read -r rel; do
        [[ ! -e "${dir_a}/${rel}" ]] && {
            printf '  %s%-50s  %sADDED   %s%s\n' \
                "${ASH_MUTED}" "$(ash_truncate "${rel}" 50)" \
                "${SNAP_COLOR_DIFF_ADD}" "${ICO_CREATE}" "${RST}"
            (( added++ ))
        }
    done < <(find "${dir_b}" "${find_args[@]}" 2>/dev/null | sed "s|${dir_b}/||")

    log::blank
    printf '  %s%s +%d added  -%d removed  ~%d modified  =%d unchanged%s\n' \
        "${BOLD}" \
        "${SNAP_COLOR_DIFF_ADD}" "${added}" \
        "${SNAP_COLOR_DIFF_DEL}" "${removed}" \
        "${SNAP_COLOR_DIFF_MOD}" "${modified}" \
        "${RST}" "${unchanged}" "${RST}"
}

# ── Main ───────────────────────────────────────────────────────────────────────
snapshot::diff() {
    local ref_a="" ref_b="current"
    local stat_only=false files_only=false path_filter="" context=3

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)     snapshot::diff::help; return 0 ;;
            --stat)        stat_only=true; shift ;;
            --files)       files_only=true; shift ;;
            --path|-p)     path_filter="${2:?'--path requires a value'}"; shift 2 ;;
            --context|-c)  context="${2:-3}"; shift 2 ;;
            -*)            log::error "Unknown option: $1"; return 1 ;;
            *)
                if [[ -z "${ref_a}" ]]; then ref_a="$1"
                else                          ref_b="$1"
                fi
                shift ;;
        esac
    done

    [[ -z "${ref_a}" ]] && {
        log::error "At least one snapshot ID is required"
        snapshot::diff::help
        return 1
    }

    # ── Header ────────────────────────────────────────────────────────────────
    log::section "Snapshot Diff"
    printf '  %sA%s  %s%s%s\n' "${BOLD}${ASH_WARNING}" "${RST}" "${SNAP_COLOR_ID}" "${ref_a}" "${RST}"
    printf '  %sB%s  %s%s%s\n' "${BOLD}${ASH_INFO}"    "${RST}" "${SNAP_COLOR_ID}" "${ref_b}" "${RST}"
    [[ -n "${path_filter}" ]] && \
        printf '  %sFilter: %s%s%s\n' "${ASH_MUTED}" "${ASH_ACCENT}" "${path_filter}" "${RST}"
    log::blank

    # ── Resolve Dirs ──────────────────────────────────────────────────────────
    local dir_a dir_b
    dir_a=$(snapshot::diff::resolve_dir "${ref_a}") || return 1
    dir_b=$(snapshot::diff::resolve_dir "${ref_b}") || return 1

    # ── Stat / Files / Full ───────────────────────────────────────────────────
    if [[ "${stat_only}" == "true" ]] || [[ "${files_only}" == "true" ]]; then
        snapshot::diff::summary_table "${dir_a}" "${dir_b}" "${path_filter}"
        return 0
    fi

    # Full diff
    local find_args=(-type f)
    [[ -n "${path_filter}" ]] && find_args+=(-path "*${path_filter}*")

    local diff_found=false

    while IFS= read -r rel; do
        local file_a="${dir_a}/${rel}" file_b="${dir_b}/${rel}"

        [[ ! -e "${file_b}" ]] && file_b="/dev/null"

        local raw_diff
        raw_diff=$(diff -u --label "A/${rel}" --label "B/${rel}" \
            -U "${context}" "${file_a}" "${file_b}" 2>/dev/null || true)

        [[ -z "${raw_diff}" ]] && continue
        diff_found=true

        # File separator
        printf '\n  %s%s%s  %s%s%s\n' \
            "${BOLD}${ASH_PRIMARY}" "${ICO_DIFF}" "${RST}" \
            "${BOLD}" "${rel}" "${RST}"
        ash_hr "─" 70 "${ASH_MUTED}"

        snapshot::diff::render_unified "${raw_diff}"

    done < <(find "${dir_a}" "${find_args[@]}" 2>/dev/null | sed "s|${dir_a}/||")

    # Files only in B (new)
    while IFS= read -r rel; do
        [[ -e "${dir_a}/${rel}" ]] && continue
        diff_found=true
        printf '\n  %s%s%s  %s%s%s  %s(new file)%s\n' \
            "${BOLD}${ASH_SUCCESS}" "${ICO_CREATE}" "${RST}" \
            "${BOLD}" "${rel}" "${RST}" \
            "${ASH_MUTED}" "${RST}"
        ash_hr "─" 70 "${ASH_MUTED}"
        local raw_diff
        raw_diff=$(diff -u --label "/dev/null" --label "B/${rel}" \
            -U "${context}" /dev/null "${dir_b}/${rel}" 2>/dev/null || true)
        snapshot::diff::render_unified "${raw_diff}"
    done < <(find "${dir_b}" "${find_args[@]}" 2>/dev/null | sed "s|${dir_b}/||")

    if [[ "${diff_found}" == "false" ]]; then
        printf '\n  %s%s Snapshots are identical%s\n\n' \
            "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}"
    else
        log::blank
        snapshot::diff::summary_table "${dir_a}" "${dir_b}" "${path_filter}"
    fi
}
