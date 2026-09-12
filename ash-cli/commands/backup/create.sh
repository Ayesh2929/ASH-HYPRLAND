#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  backup create                                            ║
# ║  Full/incremental/differential backups with zstd compression + manifest         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_CREATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_CREATE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKUP ID GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cr_gen_id() {
    local type="${1:-full}"
    local ts
    ts="$(date '+%Y%m%d-%H%M%S')"
    local short_hash
    short_hash="$(cat /dev/urandom 2>/dev/null | \
                  head -c 4 | xxd -p 2>/dev/null | \
                  head -c 6 || printf '%06x' "$(( RANDOM * RANDOM ))")"
    printf 'ash-%s-%s-%s' "$type" "$ts" "$short_hash"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COMPRESSION SELECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cr_get_compress_ext() {
    local compress="${1:-zstd}"
    case "${compress,,}" in
        zstd|zst)  printf '.zst'  ;;
        gzip|gz)   printf '.gz'   ;;
        bzip2|bz2) printf '.bz2'  ;;
        xz)        printf '.xz'   ;;
        lz4)       printf '.lz4'  ;;
        none|"")   printf ''      ;;
        *)         printf '.zst'  ;;
    esac
}

_cr_get_tar_compress_flag() {
    local compress="${1:-zstd}"
    case "${compress,,}" in
        zstd|zst)  printf '--use-compress-program=zstd' ;;
        gzip|gz)   printf '-z'  ;;
        bzip2|bz2) printf '-j'  ;;
        xz)        printf '-J'  ;;
        lz4)       printf '--use-compress-program=lz4' ;;
        none|"")   printf ''    ;;
        *)         printf '--use-compress-program=zstd' ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MANIFEST GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cr_generate_manifest() {
    local bk_id="$1"   bk_path="$2"
    local targets="$3"  bk_type="$4"
    local compress="$5"  encrypted="${6:-false}"
    local size="${7:-0}"

    local manifest_file="${_BK_MANIFEST_DIR}/${bk_id}.json"

    python3 - << PYEOF > "$manifest_file" 2>/dev/null
import json, hashlib, os, sys

bk_id       = '${bk_id}'
bk_path     = '${bk_path}'
targets_str = '${targets}'
bk_type     = '${bk_type}'
compress    = '${compress}'
encrypted   = ${encrypted} == 'true' or '${encrypted}' == 'true'
size        = ${size} if '${size}'.isdigit() else 0

# Compute SHA256 of the archive
sha256 = 'unavailable'
try:
    h = hashlib.sha256()
    with open(bk_path, 'rb') as f:
        while chunk := f.read(65536):
            h.update(chunk)
    sha256 = h.hexdigest()
except Exception as e:
    sha256 = f'error: {e}'

manifest = {
    'schema':    '1.0',
    'id':         bk_id,
    'path':       bk_path,
    'type':       bk_type,
    'targets':    [t.strip() for t in targets_str.split(',') if t.strip()],
    'compression': compress,
    'encrypted':  encrypted,
    'size_bytes': os.path.getsize(bk_path) if os.path.exists(bk_path) else size,
    'sha256':     sha256,
    'created_at': '$(date -Iseconds)',
    'hostname':   '$(hostname 2>/dev/null || echo unknown)',
    'user':       '${USER:-unknown}',
    'ash_version': '${ASH_VERSION:-5.0.0-omega}',
}

print(json.dumps(manifest, indent=2))
PYEOF

    printf '%s' "$manifest_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CREATE ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cr_banner() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;137;180;250m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  💾  Creating Backup                                      ║\n'
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INCREMENTAL SUPPORT (using timestamp file)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cr_get_last_full_ts() {
    # Returns timestamp of last full backup for incremental reference
    [[ -f "$_BK_INDEX_FILE" ]] || return 0
    python3 -c "
import json
data = json.load(open('${_BK_INDEX_FILE}'))
fulls = [(v.get('created_at',''), v.get('path',''))
         for v in data.values() if v.get('type') == 'full']
if fulls:
    fulls.sort(reverse=True)
    print(fulls[0][0])
" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_backup_create() {
    local bk_type="full"
    local dest="${ASH_BK_DEST:-$_BK_DEFAULT_DIR}"
    local compress="${ASH_BK_COMPRESS:-zstd}"
    local encrypt="${ASH_BK_ENCRYPT:-0}"
    local tag="${ASH_BK_TAG:-}"
    local -a extra_targets=()
    local dry_run=0

    for arg in "${@:-}"; do
        case "$arg" in
            full|incremental|incr|diff|differential)
                bk_type="${arg}"
                [[ "$bk_type" == "incr" ]] && bk_type="incremental"
                [[ "$bk_type" == "diff" ]] && bk_type="differential"
                ;;
            --type=*)         bk_type="${arg#*=}"     ;;
            --dest=*)         dest="${arg#*=}"         ;;
            --compress=*)     compress="${arg#*=}"     ;;
            --encrypt|-e)     encrypt=1               ;;
            --tag=*)          tag="${arg#*=}"          ;;
            --dry-run|-n)     dry_run=1               ;;
            /*)               extra_targets+=("$arg") ;;
        esac
    done

    _cr_banner
    bk_section "✨" "Create Backup" "$(_bkblue)"

    # Generate backup ID
    local bk_id
    bk_id="$(_cr_gen_id "$bk_type")"

    # File extension
    local ext
    ext=".tar$(_cr_get_compress_ext "$compress")"
    [[ $encrypt -eq 1 ]] && ext="${ext}.gpg"

    local bk_filename="${bk_id}${ext}"
    local bk_path="${dest}/${bk_filename}"

    # Build target list
    local -a targets=("${_BK_DEFAULT_TARGETS[@]}")
    for t in "${extra_targets[@]}"; do
        targets+=("$t")
    done

    # Filter to existing paths
    local -a valid_targets=()
    for t in "${targets[@]}"; do
        [[ -e "$t" ]] && valid_targets+=("$t") || \
            bk_warn "Skipping non-existent: ${t}"
    done

    if [[ ${#valid_targets[@]} -eq 0 ]]; then
        bk_fail "No valid backup targets found"
        return 1
    fi

    # Display plan
    bk_kv "Backup ID"    "$bk_id"
    bk_kv "Type"         "$bk_type"
    bk_kv "Destination"  "${bk_path/#$HOME/~}"
    bk_kv "Compression"  "$compress"
    bk_kv "Encrypted"    "$([[ $encrypt -eq 1 ]] && echo 'yes (GPG)' || echo 'no')"
    [[ -n "$tag" ]] && bk_kv "Tag"    "$tag"

    printf '\n  %sTargets:%s\n' "$(_bkdim)" "$(_bkr)"
    for t in "${valid_targets[@]}"; do
        local t_size
        t_size="$(du -sh "$t" 2>/dev/null | cut -f1 || echo '?')"
        printf '    %s•%s  %s%-45s%s  %s%s%s\n' \
            "$(_bkdim)" "$(_bkr)" \
            "$(_bksky)" "${t/#$HOME/~}" "$(_bkr)" \
            "$(_bkdim)" "$t_size" "$(_bkr)"
    done

    printf '\n'

    if [[ $dry_run -eq 1 ]]; then
        bk_info "DRY RUN — no files written"
        return 0
    fi

    # Confirm
    if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
        printf '  %sProceed with backup? [Y/n] %s' "$(_bkyellow)" "$(_bkr)"
        local ans; read -r ans
        [[ "${ans,,}" == "n" ]] && { bk_info "Cancelled"; printf '\n'; return 0; }
    fi

    mkdir -p "$dest" 2>/dev/null || true

    # Get tar compression flag
    local compress_flag
    compress_flag="$(_cr_get_tar_compress_flag "$compress")"

    # Incremental: use snapshot file
    local snapshot_arg=""
    if [[ "$bk_type" == "incremental" ]]; then
        local snapshot_file="${_BK_STATE_DIR}/incremental.snar"
        snapshot_arg="--listed-incremental=${snapshot_file}"
    fi

    # Progress tracking via parallel process
    local start_time
    start_time="$(date +%s)"
    local tmp_archive="${dest}/.tmp-${bk_id}${ext%.gpg}"

    bk_spin_start "Archiving files..."

    local tar_exit=0
    {
        tar \
            --create \
            --preserve-permissions \
            --numeric-owner \
            --ignore-failed-read \
            ${compress_flag:+$compress_flag} \
            ${snapshot_arg:+$snapshot_arg} \
            --exclude-vcs-ignores \
            --exclude='.cache' \
            --exclude='*.pyc' \
            --exclude='__pycache__' \
            --exclude='node_modules' \
            --exclude='.git/objects/pack' \
            --file="$tmp_archive" \
            -- "${valid_targets[@]}" 2>/dev/null
    } || tar_exit=$?

    if [[ $tar_exit -ne 0 ]] && [[ ! -f "$tmp_archive" ]]; then
        bk_spin_stop 0 "Archive creation failed (exit: ${tar_exit})"
        return 1
    fi

    bk_spin_stop 1 "Archive created"

    # Encrypt if requested
    local final_path="$tmp_archive"
    if [[ $encrypt -eq 1 ]]; then
        bk_spin_start "Encrypting with GPG..."

        local gpg_key=""
        [[ -f "$_BK_GPGKEY_FILE" ]] && gpg_key="$(cat "$_BK_GPGKEY_FILE" 2>/dev/null)"

        local gpg_exit=0
        if [[ -n "$gpg_key" ]]; then
            gpg --batch --yes \
                --recipient "$gpg_key" \
                --encrypt \
                --output "${bk_path}" \
                "$tmp_archive" 2>/dev/null || gpg_exit=$?
        else
            gpg --batch --yes \
                --symmetric \
                --cipher-algo AES256 \
                --output "${bk_path}" \
                "$tmp_archive" 2>/dev/null || gpg_exit=$?
        fi

        rm -f "$tmp_archive" 2>/dev/null || true

        if [[ $gpg_exit -ne 0 ]]; then
            bk_spin_stop 0 "Encryption failed"
            return 1
        fi
        bk_spin_stop 1 "Encryption complete"
        final_path="$bk_path"
    else
        mv "$tmp_archive" "$bk_path" 2>/dev/null
        final_path="$bk_path"
    fi

    # Compute final size
    local final_size
    final_size="$(stat -c '%s' "$final_path" 2>/dev/null || echo 0)"
    local elapsed=$(( $(date +%s) - start_time ))

    # Generate manifest
    bk_step "Generating manifest..."
    local targets_csv
    targets_csv="$(printf '%s,' "${valid_targets[@]}")"
    targets_csv="${targets_csv%,}"

    _cr_generate_manifest \
        "$bk_id" "$final_path" \
        "$targets_csv" "$bk_type" \
        "$compress" "$([[ $encrypt -eq 1 ]] && echo true || echo false)" \
        "$final_size" &>/dev/null

    # Register in index
    bk_index_add "$bk_id" "$final_path" "$bk_type" "$final_size" \
        "$([[ $encrypt -eq 1 ]] && echo true || echo false)" "$tag"

    bk_log_ok "create: ${bk_id}  size=$(bk_human_size "$final_size")  time=${elapsed}s"

    # ── Result display ────────────────────────────────────────────────────────────
    printf '\n'
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\033[1;38;2;166;227;161m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  ✓  BACKUP CREATED SUCCESSFULLY                           ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '\033[0m'
    fi

    bk_kv "Backup ID"    "$bk_id"
    bk_kv "File"         "${final_path/#$HOME/~}"
    bk_kv "Size"         "$(bk_human_size "$final_size")"
    bk_kv "Time"         "${elapsed}s"
    bk_kv "Type"         "$bk_type"
    [[ $encrypt -eq 1 ]] && bk_kv "Encrypted" "$(bk_badge " ✓ GPG " "$(_bkteal)")"

    bk_notify "💾 Backup Created" \
        "${bk_id}  •  $(bk_human_size "$final_size")  •  ${elapsed}s" "normal"

    printf '\n'
}
