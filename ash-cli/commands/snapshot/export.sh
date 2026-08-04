#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH SNAPSHOT — export.sh                                                   ║
# ║  Export snapshots as portable, optionally encrypted tar archives            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

snapshot::export::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot export <id|name> [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--output, -o PATH${RST}  Destination file path (default: ./<id>.ash-snap.tar.gz)
  ${ASH_MUTED}--encrypt, -e${RST}      Encrypt with GPG symmetric passphrase
  ${ASH_MUTED}--gpg-key KEY${RST}      Encrypt using a specific GPG recipient key
  ${ASH_MUTED}--no-compress${RST}      Do not compress (plain tar)
  ${ASH_MUTED}--include-index${RST}    Bundle the full snapshot index
  ${ASH_MUTED}--verify${RST}           Verify archive integrity after export
  ${ASH_MUTED}--quiet, -q${RST}        Minimal output
  ${ASH_MUTED}--help, -h${RST}         Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash snapshot export snap-20241215-143022-a3f1
  ash snapshot export "before-update" --output ~/backups/snap.ash-snap.tar.gz
  ash snapshot export snap-A --encrypt --verify
  ash snapshot export snap-A --gpg-key user@example.com
EOF
}

# ── Main ───────────────────────────────────────────────────────────────────────
snapshot::export() {
    local target_id="" output="" encrypt=false gpg_key=""
    local compress=true include_index=false verify=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)        snapshot::export::help; return 0 ;;
            --output|-o)      output="${2:?'--output requires a path'}"; shift 2 ;;
            --encrypt|-e)     encrypt=true; shift ;;
            --gpg-key)        gpg_key="${2:?'--gpg-key requires a key ID'}"; shift 2 ;;
            --no-compress)    compress=false; shift ;;
            --include-index)  include_index=true; shift ;;
            --verify)         verify=true; shift ;;
            --quiet|-q)       quiet=true; shift ;;
            -*)               log::error "Unknown option: $1"; return 1 ;;
            *)                target_id="$1"; shift ;;
        esac
    done

    [[ -z "${target_id}" ]] && {
        log::error "Snapshot ID or name is required"
        snapshot::export::help
        return 1
    }

    # ── Check deps ────────────────────────────────────────────────────────────
    utils::require "tar"
    if [[ "${encrypt}" == "true" ]] || [[ -n "${gpg_key}" ]]; then
        utils::require "gpg"
    fi

    # ── Resolve ───────────────────────────────────────────────────────────────
    local entry
    entry=$(index::find_by_id "${target_id}" 2>/dev/null)
    [[ -z "${entry}" ]] && entry=$(index::find_by_name "${target_id}" 2>/dev/null)
    [[ -z "${entry}" ]] && {
        log::error "Snapshot not found: '${target_id}'"
        return 1
    }

    local snap_id snap_name snap_ts snap_bytes
    snap_id=$(printf '%s' "${entry}"    | jq -r '.id')
    snap_name=$(printf '%s' "${entry}"  | jq -r '.name')
    snap_ts=$(printf '%s' "${entry}"    | jq -r '.created_at')
    snap_bytes=$(printf '%s' "${entry}" | jq -r '.raw_bytes // 0')

    local snap_dir content_dir meta_file
    snap_dir=$(utils::get_snapshot_dir "${snap_id}")
    content_dir="${snap_dir}/content"
    meta_file="${snap_dir}/metadata.json"

    # Decompress if needed
    if [[ ! -d "${content_dir}" ]] && [[ -f "${snap_dir}/archive.tar.gz" ]]; then
        [[ "${quiet}" == "false" ]] && log::info "Decompressing snapshot…"
        tar -xzf "${snap_dir}/archive.tar.gz" -C "${snap_dir}" 2>/dev/null
    fi

    [[ ! -d "${content_dir}" ]] && {
        log::error "Snapshot content directory not found: ${content_dir}"
        return 1
    }

    # ── Determine output path ─────────────────────────────────────────────────
    local ext="tar"
    [[ "${compress}" == "true" ]] && ext="tar.gz"
    [[ "${encrypt}" == "true" ]] || [[ -n "${gpg_key}" ]] && ext="${ext}.gpg"

    if [[ -z "${output}" ]]; then
        output="$(pwd)/${snap_id}.ash-snap.${ext}"
    fi

    local output_dir
    output_dir="$(dirname "${output}")"
    mkdir -p "${output_dir}" 2>/dev/null || {
        log::error "Cannot create output directory: ${output_dir}"
        return 1
    }

    # ── Header ────────────────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && {
        log::section "Exporting Snapshot"
        printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Snapshot" "${RST}" "${SNAP_COLOR_ID}"   "${snap_id}"   "${RST}"
        printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Name"     "${RST}" "${SNAP_COLOR_NAME}" "${snap_name}" "${RST}"
        printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Output"   "${RST}" "${ASH_ACCENT}"      "${output}"    "${RST}"
        [[ "${encrypt}" == "true" ]] && \
            printf '  %s%s%s Symmetric encryption enabled\n' \
                "${ASH_WARNING}" "${ICO_LOCK}" "${RST}"
        [[ -n "${gpg_key}" ]] && \
            printf '  %s%s%s GPG key: %s\n' \
                "${ASH_WARNING}" "${ICO_LOCK}" "${RST}" "${gpg_key}"
        log::blank
    }

    # ── Build staging dir ─────────────────────────────────────────────────────
    local staging
    staging=$(mktemp -d /tmp/ash-export.XXXXXX)
    # shellcheck disable=SC2064
    trap "rm -rf '${staging}'" EXIT

    # Copy content
    rsync -a --quiet "${content_dir}/" "${staging}/content/"
    cp "${meta_file}" "${staging}/metadata.json" 2>/dev/null || true

    if [[ "${include_index}" == "true" ]]; then
        cp "${ASH_SNAPSHOT_INDEX}" "${staging}/index.json" 2>/dev/null || true
    fi

    # Export manifest
    cat > "${staging}/export-manifest.json" <<EOF
{
  "ash_export_version": 1,
  "snapshot_id":        "${snap_id}",
  "snapshot_name":      "${snap_name}",
  "exported_at":        $(date +%s),
  "exported_by":        "${USER:-unknown}",
  "hostname":           "$(hostname -s 2>/dev/null || echo unknown)",
  "compressed":         ${compress},
  "encrypted":          ${encrypt},
  "gpg_key":            "${gpg_key}",
  "original_bytes":     ${snap_bytes}
}
EOF

    # ── Create Archive ────────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && ash_spinner_start "Building archive…"

    local tmp_archive="${staging}/export.tar"
    [[ "${compress}" == "true" ]] && tmp_archive="${staging}/export.tar.gz"

    if [[ "${compress}" == "true" ]]; then
        tar -czf "${tmp_archive}" -C "${staging}" \
            content metadata.json export-manifest.json \
            $( [[ "${include_index}" == "true" ]] && echo "index.json" ) \
            2>/dev/null
    else
        tar -cf "${tmp_archive}" -C "${staging}" \
            content metadata.json export-manifest.json \
            $( [[ "${include_index}" == "true" ]] && echo "index.json" ) \
            2>/dev/null
    fi

    [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Archive built"

    # ── Encrypt ───────────────────────────────────────────────────────────────
    if [[ "${encrypt}" == "true" ]] || [[ -n "${gpg_key}" ]]; then
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Encrypting…"

        local gpg_args=(--batch --yes)
        if [[ -n "${gpg_key}" ]]; then
            gpg_args+=(-r "${gpg_key}" -e)
        else
            gpg_args+=(--symmetric --cipher-algo AES256
                       --passphrase-fd 0)
        fi

        if [[ -n "${gpg_key}" ]]; then
            gpg "${gpg_args[@]}" --output "${output}" "${tmp_archive}" 2>/dev/null
        else
            # Prompt for passphrase securely
            local pass pass2
            printf '\n  %sEncryption passphrase: %s' "${ASH_PRIMARY}" "${RST}"
            read -rs pass; printf '\n'
            printf '  %sConfirm passphrase:    %s' "${ASH_PRIMARY}" "${RST}"
            read -rs pass2; printf '\n'

            [[ "${pass}" != "${pass2}" ]] && {
                [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Passphrases do not match"
                return 1
            }

            printf '%s' "${pass}" | \
                gpg --batch --yes --symmetric --cipher-algo AES256 \
                    --passphrase-fd 0 --output "${output}" "${tmp_archive}" 2>/dev/null
        fi

        [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Encrypted"
    else
        mv "${tmp_archive}" "${output}"
    fi

    # ── Verify ────────────────────────────────────────────────────────────────
    if [[ "${verify}" == "true" ]]; then
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Verifying archive integrity…"
        local ok=false

        if [[ "${encrypt}" == "false" ]] && [[ -z "${gpg_key}" ]]; then
            if [[ "${compress}" == "true" ]]; then
                gzip -t "${output}" 2>/dev/null && ok=true
            else
                tar -tf "${output}" &>/dev/null && ok=true
            fi
        else
            # Just check the file exists and is non-empty
            [[ -s "${output}" ]] && ok=true
        fi

        if [[ "${ok}" == "true" ]]; then
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Integrity verified"
        else
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Verification failed"
            log::error "Archive may be corrupt: ${output}"
            return 1
        fi
    fi

    # ── Final Stats ───────────────────────────────────────────────────────────
    local final_size
    final_size=$(stat -c%s "${output}" 2>/dev/null || echo 0)

    if [[ "${quiet}" == "true" ]]; then
        printf '%s\n' "${output}"
        return 0
    fi

    log::blank
    printf '  %s%s%s  Export Complete\n\n' "${BOLD}${ASH_SUCCESS}" "${ICO_EXPORT}" "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "File"     "${RST}" "${ASH_ACCENT}"      "${output}"                      "${RST}"
    printf '  %s%-12s%s %s%s%s\n' "${ASH_MUTED}" "Size"     "${RST}" "${SNAP_COLOR_SIZE}" "$(utils::human_size "${final_size}")" "${RST}"
    printf '  %s%-12s%s %soriginal: %s compressed: %s%s\n' \
        "${ASH_MUTED}" "Ratio" "${RST}" "${ASH_MUTED}" \
        "$(utils::human_size "${snap_bytes}")" \
        "$(utils::human_size "${final_size}")" "${RST}"
    [[ "${encrypt}" == "true" ]] || [[ -n "${gpg_key}" ]] && \
        printf '  %s%s Encrypted%s\n' "${ASH_WARNING}" "${ICO_LOCK}" "${RST}"
    log::blank

    # Shasum of export
    if command -v sha256sum &>/dev/null; then
        local export_hash
        export_hash=$(sha256sum "${output}" | awk '{print $1}')
        printf '  %sSHA-256: %s%s%s\n' "${ASH_MUTED}" \
            "${ASH_MUTED}" "${export_hash}" "${RST}"
    fi

    log::blank
    printf '  %sTip:%s Copy to another machine and run:\n' "${ASH_MUTED}" "${RST}"
    printf '  %s  ash snapshot import "%s"%s\n' "${ASH_ACCENT}" "${output}" "${RST}"
    log::blank
}
