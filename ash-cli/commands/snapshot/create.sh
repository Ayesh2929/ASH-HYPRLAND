#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — create.sh                                                   ║
# ║  Create atomic, compressed, checksummed configuration snapshots             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Help ───────────────────────────────────────────────────────────────────────
snapshot::create::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot create [name] [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${SNAP_COLOR_NAME}name${RST}              Optional human-readable snapshot name

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--tag,  -t  TAG${RST}    Assign a tag label (e.g. stable, before-update)
  ${ASH_MUTED}--desc, -d  DESC${RST}   Short description stored in metadata
  ${ASH_MUTED}--pin${RST}              Pin snapshot (protects from auto-cleanup)
  ${ASH_MUTED}--no-compress${RST}      Skip gzip compression (faster, larger)
  ${ASH_MUTED}--targets PATH…${RST}    Override default target paths
  ${ASH_MUTED}--quiet, -q${RST}        Minimal output
  ${ASH_MUTED}--help,  -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash snapshot create
  ash snapshot create "before-theme-change" --tag stable --pin
  ash snapshot create "daily" --desc "Automated daily backup"
EOF
}

# ── Main ───────────────────────────────────────────────────────────────────────
snapshot::create() {
    # ── Parse Arguments ────────────────────────────────────────────────────────
    local name="" tag="" desc="" pinned=false compress=true quiet=false
    local custom_targets=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       snapshot::create::help; return 0 ;;
            --tag|-t)        tag="${2:?'--tag requires a value'}"; shift 2 ;;
            --desc|-d)       desc="${2:?'--desc requires a value'}"; shift 2 ;;
            --pin)           pinned=true; shift ;;
            --no-compress)   compress=false; shift ;;
            --quiet|-q)      quiet=true; shift ;;
            --targets)       shift
                             while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                                 custom_targets+=("$1"); shift
                             done ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               name="$1"; shift ;;
        esac
    done

    # ── Auto-name ──────────────────────────────────────────────────────────────
    if [[ -z "${name}" ]]; then
        name="snapshot-$(date '+%Y%m%d-%H%M%S')"
    fi

    # ── Sanitise name ──────────────────────────────────────────────────────────
    name="${name//[^a-zA-Z0-9._-]/-}"
    name="${name:0:64}"

    # ── Check for duplicate name ───────────────────────────────────────────────
    if index::find_by_name "${name}" | grep -q '"id"' 2>/dev/null; then
        log::error "A snapshot named '${name}' already exists."
        log::info  "Use a different name or delete the existing one first."
        return 1
    fi

    # ── Header ────────────────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && {
        log::section "Creating Snapshot"
        printf '  %sName%s    %s%s%s\n' \
            "${ASH_MUTED}" "${RST}" "${SNAP_COLOR_NAME}${BOLD}" "${name}" "${RST}"
        [[ -n "${tag}"  ]] && printf '  %sTag%s     %s%s%s\n' \
            "${ASH_MUTED}" "${RST}" "${SNAP_COLOR_TAG}" "${tag}" "${RST}"
        [[ -n "${desc}" ]] && printf '  %sDesc%s    %s%s%s\n' \
            "${ASH_MUTED}" "${RST}" "${ASH_INFO}" "${desc}" "${RST}"
        [[ "${pinned}" == "true" ]] && printf '  %s%s Pinned%s\n' \
            "${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}"
        log::blank
    }

    # ── Acquire Lock ───────────────────────────────────────────────────────────
    lock::acquire 10 || return 1

    # ── Generate ID & Dirs ────────────────────────────────────────────────────
    local snap_id snap_dir
    snap_id=$(utils::generate_id)
    snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    local snap_content_dir="${snap_dir}/content"
    local snap_meta_file="${snap_dir}/metadata.json"
    local snap_manifest="${snap_dir}/manifest.json"

    mkdir -p "${snap_content_dir}"

    # ── Resolve Targets ────────────────────────────────────────────────────────
    local targets=()
    if (( ${#custom_targets[@]} > 0 )); then
        targets=("${custom_targets[@]}")
    else
        targets=("${SNAPSHOT_TARGETS[@]}")
    fi

    # ── Copy Files ─────────────────────────────────────────────────────────────
    local copied=0 skipped=0 failed=0
    local manifest_entries=()
    local epoch
    epoch=$(date +%s)

    [[ "${quiet}" == "false" ]] && ash_spinner_start "Copying configuration files…"

    for target in "${targets[@]}"; do
        if [[ ! -e "${target}" ]]; then
            (( skipped++ ))
            log::debug "Skipping missing target: ${target}"
            continue
        fi

        local rel_path
        rel_path="${target#"${HOME}/"}"
        local dest="${snap_content_dir}/${rel_path}"
        mkdir -p "$(dirname "${dest}")"

        if rsync -a --quiet "${target}" "${dest}" 2>/dev/null; then
            (( copied++ ))
            manifest_entries+=("{\"path\":\"${rel_path}\",\"type\":\"$(
                [[ -d "${target}" ]] && echo dir || echo file
            )\"}")
            log::debug "Copied: ${target}"
        else
            (( failed++ ))
            log::warn "Failed to copy: ${target}"
        fi
    done

    [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Files copied"

    # ── Compute Checksum ───────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && ash_spinner_start "Computing integrity checksum…"
    local checksum
    checksum=$(utils::checksum_dir "${snap_content_dir}")
    [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Checksum computed"

    # ── Compute Size ──────────────────────────────────────────────────────────
    local raw_bytes
    raw_bytes=$(du -sb "${snap_content_dir}" 2>/dev/null | awk '{print $1}' || echo 0)

    # ── Optional Compression ──────────────────────────────────────────────────
    local archive_path="" archive_size=0
    if [[ "${compress}" == "true" ]]; then
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Compressing snapshot…"
        archive_path="${snap_dir}/archive.tar.gz"
        tar -czf "${archive_path}" -C "${snap_dir}" content 2>/dev/null
        archive_size=$(stat -c%s "${archive_path}" 2>/dev/null || echo 0)
        [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Compressed to $(utils::human_size "${archive_size}")"
    fi

    # ── Write Manifest ────────────────────────────────────────────────────────
    local manifest_json
    manifest_json=$(printf '[%s]' "$(IFS=','; echo "${manifest_entries[*]:-}")")
    cat > "${snap_manifest}" <<EOF
{
  "version": 1,
  "files": ${manifest_json},
  "copied": ${copied},
  "skipped": ${skipped},
  "failed": ${failed}
}
EOF

    # ── Write Metadata ────────────────────────────────────────────────────────
    local hostname kernel ash_ver theme_current mode_current
    hostname=$(hostname -s 2>/dev/null || echo "unknown")
    kernel=$(uname -r 2>/dev/null || echo "unknown")
    ash_ver=$(cat "${ASH_CONFIG_DIR}/../../../version.json" 2>/dev/null \
              | jq -r '.version // "unknown"' 2>/dev/null || echo "unknown")
    theme_current=$(cat "${ASH_DATA_DIR}/state/current-theme.json" 2>/dev/null \
                    | jq -r '.name // "unknown"' 2>/dev/null || echo "unknown")
    mode_current=$(cat "${ASH_DATA_DIR}/state/current-mode.json" 2>/dev/null \
                   | jq -r '.name // "default"' 2>/dev/null || echo "default")

    cat > "${snap_meta_file}" <<EOF
{
  "id":          "${snap_id}",
  "name":        "${name}",
  "tag":         "${tag}",
  "description": "${desc}",
  "pinned":      ${pinned},
  "created_at":  ${epoch},
  "created_by":  "${USER:-unknown}",
  "hostname":    "${hostname}",
  "kernel":      "${kernel}",
  "ash_version": "${ash_ver}",
  "theme":       "${theme_current}",
  "mode":        "${mode_current}",
  "checksum":    "${checksum}",
  "raw_bytes":   ${raw_bytes},
  "archive_bytes": ${archive_size},
  "compressed":  ${compress},
  "targets_count": ${#targets[@]},
  "files_copied": ${copied},
  "files_skipped": ${skipped},
  "files_failed": ${failed}
}
EOF

    # ── Update Index ──────────────────────────────────────────────────────────
    local index_entry
    index_entry=$(jq -n \
        --arg id      "${snap_id}" \
        --arg name    "${name}" \
        --arg tag     "${tag}" \
        --arg desc    "${desc}" \
        --argjson pin "${pinned}" \
        --argjson ts  "${epoch}" \
        --argjson bytes "${raw_bytes}" \
        --arg checksum "${checksum}" \
        '{id:$id,name:$name,tag:$tag,description:$desc,
          pinned:$pin,created_at:$ts,raw_bytes:$bytes,checksum:$checksum}')
    index::add "${index_entry}"

    lock::release

    # ── Success Output ────────────────────────────────────────────────────────
    if [[ "${quiet}" == "true" ]]; then
        printf '%s\n' "${snap_id}"
        return 0
    fi

    log::blank
    printf '%s╭─────────────────────────────────────────────────────╮%s\n' \
        "${ASH_SUCCESS}" "${RST}"
    printf '%s│%s  %s%s Snapshot Created Successfully%s%s%s%s%s │%s\n' \
        "${ASH_SUCCESS}" "${RST}" \
        "${BOLD}${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" \
        "${BOLD}${ASH_SUCCESS}" \
        "$(printf '%*s' "$(( 21 - ${#snap_id} ))" '')" \
        "${RST}" "${ASH_SUCCESS}" "${RST}"
    printf '%s╰─────────────────────────────────────────────────────╯%s\n' \
        "${ASH_SUCCESS}" "${RST}"

    log::blank

    local size_str
    size_str=$(utils::human_size "${archive_size:-${raw_bytes}}")

    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "ID"       "${RST}" "${SNAP_COLOR_ID}"   "${snap_id}"  "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Name"     "${RST}" "${SNAP_COLOR_NAME}" "${name}"     "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Created"  "${RST}" "${SNAP_COLOR_DATE}" "$(date -d "@${epoch}" '+%Y-%m-%d %H:%M:%S')" "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Size"     "${RST}" "${SNAP_COLOR_SIZE}" "${size_str}" "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Checksum" "${RST}" "${ASH_MUTED}"       "${checksum:0:16}…" "${RST}"
    printf '  %s%-12s%s %d copied, %d skipped, %d failed\n' \
        "${ASH_MUTED}" "Files" "${RST}" "${copied}" "${skipped}" "${failed}"
    [[ -n "${tag}"  ]] && printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Tag" "${RST}" "${SNAP_COLOR_TAG}" "${tag}" "${RST}"
    [[ "${pinned}" == "true" ]] && printf '  %s%s Pinned%s\n' "${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}"

    log::blank
    printf '  %sTip:%s ash snapshot restore %s%s%s\n' \
        "${ASH_MUTED}" "${RST}" "${ASH_ACCENT}" "${snap_id}" "${RST}"
    log::blank
}
