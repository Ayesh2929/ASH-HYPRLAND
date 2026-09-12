#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ SNAPSHOT IMPORT                                    ║
# ║  Import portable .ash-snap archives with validation, decryption & dedup        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
# shellcheck disable=SC2154
set -euo pipefail
IFS=$'\n\t'

_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::import::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "${ICO_SNAPSHOT}  ASH SNAPSHOT IMPORT" \
        "Import portable .ash-snap archives from disk or URL" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash snapshot import <path|url> [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${SNAP_COLOR_NAME}path${RST}   Path to a .ash-snap.tar.gz[.gpg] archive
  ${SNAP_COLOR_NAME}url${RST}    HTTPS URL to fetch and import

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name,    -n NAME${RST}   Override snapshot name after import
  ${ASH_MUTED}--tag,     -t TAG${RST}    Assign a tag to the imported snapshot
  ${ASH_MUTED}--pin${RST}               Pin the snapshot immediately after import
  ${ASH_MUTED}--decrypt, -d${RST}        Decrypt GPG-encrypted archive (prompts for passphrase)
  ${ASH_MUTED}--gpg-key KEY${RST}        GPG key ID for decryption (skips passphrase prompt)
  ${ASH_MUTED}--force,   -f${RST}        Overwrite if a snapshot with the same name exists
  ${ASH_MUTED}--no-verify${RST}          Skip integrity verification after import
  ${ASH_MUTED}--quiet,   -q${RST}        Minimal output (prints ID on success)
  ${ASH_MUTED}--help,   -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_ACCENT}ash snapshot import${RST} ~/backups/snap-20241215.ash-snap.tar.gz
  ${ASH_ACCENT}ash snapshot import${RST} ~/encrypted.ash-snap.tar.gz.gpg --decrypt
  ${ASH_ACCENT}ash snapshot import${RST} https://example.com/snap.ash-snap.tar.gz --pin
  ${ASH_ACCENT}ash snapshot import${RST} snap.tar.gz --name "from-laptop" --tag imported

${BOLD}${ASH_PRIMARY}FORMAT${RST}
  ${ASH_MUTED}Supported extensions:${RST}
    .ash-snap.tar.gz        Compressed archive
    .ash-snap.tar           Uncompressed archive
    .ash-snap.tar.gz.gpg    GPG-encrypted compressed archive
    .ash-snap.tar.gpg       GPG-encrypted uncompressed archive
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § VALIDATORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_import::is_url()       { [[ "$1" =~ ^https?:// ]]; }
_import::is_encrypted() { [[ "$1" == *.gpg ]]; }
_import::is_compressed(){ [[ "$1" == *.tar.gz* ]] || [[ "$1" == *.tgz* ]]; }

_import::validate_manifest() {
    local manifest_file="$1"
    [[ ! -f "${manifest_file}" ]] && {
        log::error "Archive missing export-manifest.json — may not be an ASH snapshot"
        return 1
    }
    local ver
    ver=$(jq -r '.ash_export_version // 0' "${manifest_file}" 2>/dev/null || echo 0)
    (( ver < 1 )) && {
        log::error "Unrecognised export manifest version: ${ver}"
        return 1
    }
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § RENDER — import summary card
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_import::render_card() {
    local snap_id="$1" snap_name="$2" snap_date="$3"
    local snap_size="$4" encrypted="$5" tag="$6" pinned="$7"

    printf '\n'
    printf '  %s╭──────────────────────────────────────────────────────────╮%s\n' \
        "${ASH_SUCCESS}" "${RST}"
    printf '  %s│%s  %s%s  Snapshot Imported Successfully%s%s%*s%s%s│%s\n' \
        "${ASH_SUCCESS}" "${RST}" \
        "${BOLD}${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" \
        "${BOLD}${ASH_SUCCESS}" \
        5 '' \
        "${RST}" "${ASH_SUCCESS}" "${RST}"
    printf '  %s╰──────────────────────────────────────────────────────────╯%s\n' \
        "${ASH_SUCCESS}" "${RST}"
    printf '\n'
    printf '  %s%-14s%s %s%s%s\n'  "${ASH_MUTED}" "ID"        "${RST}" "${SNAP_COLOR_ID}"   "${snap_id}"   "${RST}"
    printf '  %s%-14s%s %s%s%s\n'  "${ASH_MUTED}" "Name"      "${RST}" "${SNAP_COLOR_NAME}" "${snap_name}" "${RST}"
    printf '  %s%-14s%s %s%s%s\n'  "${ASH_MUTED}" "Exported"  "${RST}" "${SNAP_COLOR_DATE}" "${snap_date}" "${RST}"
    printf '  %s%-14s%s %s%s%s\n'  "${ASH_MUTED}" "Size"      "${RST}" "${SNAP_COLOR_SIZE}" "${snap_size}" "${RST}"
    [[ -n "${tag}" ]] && \
        printf '  %s%-14s%s %s%s%s\n' "${ASH_MUTED}" "Tag" "${RST}" "${SNAP_COLOR_TAG}" "${tag}" "${RST}"
    [[ "${encrypted}" == "true" ]] && \
        printf '  %s%s%-14s%s Decrypted & imported\n' "${ASH_WARNING}" "${ICO_LOCK}" "${RST}" ""
    [[ "${pinned}" == "true" ]] && \
        printf '  %s%s Pinned%s\n' "${SNAP_COLOR_PINNED}" "${ICO_PIN}" "${RST}"
    printf '\n'
    printf '  %sTip:%s ash snapshot restore %s%s%s\n' \
        "${ASH_MUTED}" "${RST}" "${ASH_ACCENT}" "${snap_id}" "${RST}"
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
snapshot::import() {
    local src_path="" override_name="" tag="" pinned=false
    local decrypt=false gpg_key="" force=false no_verify=false quiet=false

    # ── Parse ──────────────────────────────────────────────────────────────────
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       snapshot::import::help; return 0 ;;
            --name|-n)       override_name="${2:?'--name requires a value'}"; shift 2 ;;
            --tag|-t)        tag="${2:?'--tag requires a value'}"; shift 2 ;;
            --pin)           pinned=true; shift ;;
            --decrypt|-d)    decrypt=true; shift ;;
            --gpg-key)       gpg_key="${2:?'--gpg-key requires a key ID'}"; shift 2 ;;
            --force|-f)      force=true; shift ;;
            --no-verify)     no_verify=true; shift ;;
            --quiet|-q)      quiet=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               src_path="$1"; shift ;;
        esac
    done

    [[ -z "${src_path}" ]] && {
        log::error "No archive path or URL specified."
        snapshot::import::help; return 1
    }

    utils::require "tar" "jq"

    # ── Download if URL ────────────────────────────────────────────────────────
    local local_path="${src_path}"
    if _import::is_url "${src_path}"; then
        utils::require "curl"
        local tmp_dl
        tmp_dl=$(mktemp /tmp/ash-import-dl.XXXXXX)
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Downloading archive…"
        if ! curl -fsSL --progress-bar -o "${tmp_dl}" "${src_path}" 2>/dev/null; then
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Download failed"
            log::error "Failed to download: ${src_path}"
            rm -f "${tmp_dl}"
            return 1
        fi
        [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Downloaded"
        # Infer filename for extension checks
        local_path="${tmp_dl}"
        # Rename with correct extension so detection works
        local inferred_name
        inferred_name=$(basename "${src_path}")
        local renamed="/tmp/${inferred_name}"
        mv "${tmp_dl}" "${renamed}"
        local_path="${renamed}"
    fi

    [[ ! -f "${local_path}" ]] && {
        log::error "File not found: ${local_path}"
        return 1
    }

    # ── Create staging area ────────────────────────────────────────────────────
    local staging
    staging=$(mktemp -d /tmp/ash-import.XXXXXX)
    # shellcheck disable=SC2064
    trap "rm -rf '${staging}'" EXIT

    local work_archive="${local_path}"

    # ── Decrypt if needed ──────────────────────────────────────────────────────
    if _import::is_encrypted "${local_path}" || [[ "${decrypt}" == "true" ]]; then
        utils::require "gpg"
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Decrypting archive…"

        local decrypted_path="${staging}/decrypted.tar"
        [[ "${local_path}" == *.tar.gz.gpg ]] && decrypted_path="${staging}/decrypted.tar.gz"

        local gpg_args=(--batch --yes --output "${decrypted_path}")
        if [[ -n "${gpg_key}" ]]; then
            gpg_args+=(-u "${gpg_key}" --decrypt "${local_path}")
            gpg "${gpg_args[@]}" 2>/dev/null || {
                [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Decryption failed"
                log::error "GPG decryption failed. Wrong key or corrupted archive."
                return 1
            }
        else
            # Interactive passphrase via pinentry / TTY
            gpg --batch --yes --output "${decrypted_path}" \
                --decrypt "${local_path}" 2>/dev/null || {
                [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Decryption failed"
                log::error "GPG decryption failed."
                return 1
            }
        fi

        [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Decrypted"
        work_archive="${decrypted_path}"
    fi

    # ── Extract ────────────────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && ash_spinner_start "Extracting archive…"

    if _import::is_compressed "${work_archive}"; then
        tar -xzf "${work_archive}" -C "${staging}" 2>/dev/null || {
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Extraction failed"
            log::error "Failed to extract archive. File may be corrupted."
            return 1
        }
    else
        tar -xf "${work_archive}" -C "${staging}" 2>/dev/null || {
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Extraction failed"
            log::error "Failed to extract archive."
            return 1
        }
    fi

    [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Extracted"

    # ── Validate manifest ──────────────────────────────────────────────────────
    local manifest_file="${staging}/export-manifest.json"
    _import::validate_manifest "${manifest_file}" || return 1

    local orig_id orig_name exported_at orig_bytes encrypted_flag
    orig_id=$(jq -r         '.snapshot_id   // "unknown"' "${manifest_file}")
    orig_name=$(jq -r       '.snapshot_name // "imported"' "${manifest_file}")
    exported_at=$(jq -r     '.exported_at   // 0'          "${manifest_file}")
    orig_bytes=$(jq -r      '.original_bytes // 0'          "${manifest_file}")
    encrypted_flag=$(jq -r  '.encrypted     // false'       "${manifest_file}")

    [[ -d "${staging}/content" ]] || {
        log::error "Archive content directory missing. Archive may be malformed."
        return 1
    }

    # ── Resolve name & check dups ─────────────────────────────────────────────
    local final_name="${override_name:-${orig_name}}"
    final_name="${final_name//[^a-zA-Z0-9._-]/-}"
    final_name="${final_name:0:64}"

    if index::find_by_name "${final_name}" 2>/dev/null | grep -q '"id"'; then
        if [[ "${force}" == "true" ]]; then
            log::warn "Snapshot '${final_name}' exists — overwriting (--force)"
            local old_id
            old_id=$(index::find_by_name "${final_name}" | jq -r '.id')
            local old_dir; old_dir=$(utils::get_snapshot_dir "${old_id}")
            rm -rf "${old_dir}"
            index::remove "${old_id}"
        else
            log::error "A snapshot named '${final_name}' already exists."
            log::info  "Use --name to pick a different name, or --force to overwrite."
            return 1
        fi
    fi

    # ── Verify integrity ───────────────────────────────────────────────────────
    if [[ "${no_verify}" == "false" ]]; then
        [[ "${quiet}" == "false" ]] && ash_spinner_start "Verifying content integrity…"
        local content_checksum
        content_checksum=$(utils::checksum_dir "${staging}/content")

        # Cross-check with embedded metadata if present
        local meta_checksum=""
        [[ -f "${staging}/metadata.json" ]] && \
            meta_checksum=$(jq -r '.checksum // ""' "${staging}/metadata.json" 2>/dev/null)

        if [[ -n "${meta_checksum}" ]] && \
           [[ "${content_checksum}" != "${meta_checksum}" ]]; then
            [[ "${quiet}" == "false" ]] && ash_spinner_stop 1 "Integrity check FAILED"
            log::error "Checksum mismatch — archive content may be tampered."
            log::info  "Use --no-verify to import anyway (not recommended)."
            return 1
        fi
        [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Integrity verified"
    fi

    # ── Acquire lock & install ────────────────────────────────────────────────
    lock::acquire 15 || return 1

    local new_id
    new_id=$(utils::generate_id)
    local new_snap_dir
    new_snap_dir=$(utils::get_snapshot_dir "${new_id}")
    mkdir -p "${new_snap_dir}"

    [[ "${quiet}" == "false" ]] && ash_spinner_start "Installing snapshot…"

    rsync -a --quiet "${staging}/content/" "${new_snap_dir}/content/"

    # Write metadata
    local epoch; epoch=$(date +%s)
    local final_checksum
    final_checksum=$(utils::checksum_dir "${new_snap_dir}/content")

    cat > "${new_snap_dir}/metadata.json" <<EOF
{
  "id":            "${new_id}",
  "name":          "${final_name}",
  "tag":           "${tag}",
  "description":   "Imported from: $(basename "${src_path}")",
  "pinned":        ${pinned},
  "created_at":    ${epoch},
  "imported_at":   ${epoch},
  "original_id":   "${orig_id}",
  "original_name": "${orig_name}",
  "exported_at":   ${exported_at},
  "encrypted":     ${encrypted_flag},
  "created_by":    "${USER:-unknown}",
  "hostname":      "$(hostname -s 2>/dev/null || echo unknown)",
  "checksum":      "${final_checksum}",
  "raw_bytes":     ${orig_bytes}
}
EOF

    # Copy export manifest for provenance
    cp "${manifest_file}" "${new_snap_dir}/import-provenance.json" 2>/dev/null || true

    # Compress content into archive
    [[ "${quiet}" == "false" ]] && ash_spinner_start "Compressing…"
    tar -czf "${new_snap_dir}/archive.tar.gz" \
        -C "${new_snap_dir}" content 2>/dev/null || true
    [[ "${quiet}" == "false" ]] && ash_spinner_stop 0 "Compressed"

    # Register in index
    local index_entry
    index_entry=$(jq -n \
        --arg  id       "${new_id}" \
        --arg  name     "${final_name}" \
        --arg  tag      "${tag}" \
        --arg  desc     "Imported from $(basename "${src_path}")" \
        --argjson pin   "${pinned}" \
        --argjson ts    "${epoch}" \
        --argjson bytes "${orig_bytes}" \
        --arg  chk      "${final_checksum}" \
        '{id:$id,name:$name,tag:$tag,description:$desc,
          pinned:$pin,created_at:$ts,raw_bytes:$bytes,checksum:$chk}')
    index::add "${index_entry}"

    lock::release

    # ── Output ────────────────────────────────────────────────────────────────
    if [[ "${quiet}" == "true" ]]; then
        printf '%s\n' "${new_id}"
        return 0
    fi

    local date_str
    date_str=$(date -d "@${exported_at}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || date -r "${exported_at}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || echo "unknown")

    _import::render_card \
        "${new_id}" "${final_name}" "${date_str}" \
        "$(utils::human_size "${orig_bytes}")" \
        "${encrypted_flag}" "${tag}" "${pinned}"
}
