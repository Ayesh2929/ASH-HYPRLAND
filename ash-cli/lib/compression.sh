#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🗜️  ASH COMPRESSION ENGINE — archives that verify before they trust          ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Wraps tar / zstd / xz / gzip / zip / 7z behind one interface and, crucially, ║
# ║  *validates before extracting*: `tar -tzf` runs first so a truncated or       ║
# ║  hostile archive never reaches the filesystem.                               ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_COMPRESSION_LOADED:-}" ]] && return 0
readonly _ASH_COMPRESSION_LOADED=1
readonly ASH_COMPRESSION_VERSION="5.0.0"

# Best available compressor, cheapest-first trade-off:
#   zstd  — fastest with great ratio, multithreaded
#   xz    — best ratio, slow
#   gzip  — universally available
ash_compressor_available() {
    if   command -v zstd >/dev/null 2>&1; then printf 'zstd'
    elif command -v xz   >/dev/null 2>&1; then printf 'xz'
    elif command -v pigz >/dev/null 2>&1; then printf 'pigz'
    elif command -v gzip >/dev/null 2>&1; then printf 'gzip'
    else printf 'none'; fi
}

_ash_tar_flags() {
    case "${1:-$(ash_compressor_available)}" in
        zstd) printf '--zstd' ;;
        xz)   printf -- '-J' ;;
        pigz) printf -- '-I pigz' ;;
        gzip) printf -- '-z' ;;
        none) printf '' ;;
        *)    printf -- '-z' ;;
    esac
}

_ash_tar_ext() {
    case "${1:-$(ash_compressor_available)}" in
        zstd) printf 'tar.zst' ;;
        xz)   printf 'tar.xz' ;;
        pigz|gzip) printf 'tar.gz' ;;
        none) printf 'tar' ;;
        *)    printf 'tar.gz' ;;
    esac
}

# ── Compress ─────────────────────────────────────────────────────────────────
# ash_compress <output> <input…> [--compressor zstd|xz|gzip] [--level N] [--exclude PATTERN]
ash_compress() {
    local output="$1"; shift
    local -a inputs=()
    local compressor; compressor="$(ash_compressor_available)"
    local level="" exclude_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --compressor) compressor="$2"; shift 2 ;;
            --level)      level="$2"; shift 2 ;;
            --exclude)    exclude_args+=(--exclude="$2"); shift 2 ;;
            -*)           shift ;;
            *)            inputs+=("$1"); shift ;;
        esac
    done

    (( ${#inputs[@]} == 0 )) && { ash_log_error "no inputs given" 2>/dev/null || true; return 1; }

    mkdir -p "$(dirname "$output")" 2>/dev/null || true

    local -a level_args=()
    case "$compressor" in
        zstd) [[ -n "$level" ]] && level_args=("-${level}") ;;
        xz)   [[ -n "$level" ]] && level_args=("-${level}") ;;
        gzip|pigz) [[ -n "$level" ]] && level_args=("-${level}") ;;
    esac

    # -C /  with basenames so archives extract without absolute paths.
    local start_ns; start_ns="$(date +%s%N 2>/dev/null || date +%s)"
    local rc=0

    if [[ "$output" == *.zip ]]; then
        command -v zip >/dev/null 2>&1 || { ash_log_error "zip not installed" 2>/dev/null || true; return 1; }
        ( cd "$(dirname "${inputs[0]}")" && zip -qr "$output" "${inputs[@]##*/}" "${exclude_args[@]}" ) || rc=$?
    elif [[ "$output" == *.7z ]]; then
        command -v 7z >/dev/null 2>&1 || { ash_log_error "7z not installed" 2>/dev/null || true; return 1; }
        7z a -bso0 -bsp0 "$output" "${inputs[@]}" || rc=$?
    else
        local flags; flags="$(_ash_tar_flags "$compressor")"
        # shellcheck disable=SC2086
        tar -c $flags "${level_args[@]}" "${exclude_args[@]}" \
            -f "$output" -C "$(dirname "${inputs[0]}")" "${inputs[@]##*/}" || rc=$?
    fi

    local end_ns; end_ns="$(date +%s%N 2>/dev/null || date +%s)"
    local ms=$(( (end_ns - start_ns) / 1000000 ))

    if (( rc == 0 )); then
        local size; size="$(ash_file_human_size "$output")"
        ash_log_info "created ${output} (${size}, ${ms}ms)" 2>/dev/null || true
        ash_event_emit "compression.created" "file=${output}" "size=${size}" "ms=${ms}" 2>/dev/null || true
    else
        ash_log_error "compression failed for ${output}" 2>/dev/null || true
    fi
    return $rc
}

# ── Validate ─────────────────────────────────────────────────────────────────
ash_archive_valid() {
    local archive="$1"
    [[ -f "$archive" ]] || return 1

    case "$archive" in
        *.zip) command -v unzip >/dev/null 2>&1 && unzip -tqq "$archive" >/dev/null 2>&1 ;;
        *.7z)  command -v 7z    >/dev/null 2>&1 && 7z t -bso0 -bsp0 "$archive" >/dev/null 2>&1 ;;
        *.tar)
            if command -v zstd >/dev/null 2>&1 && tar --zstd -tf "$archive" >/dev/null 2>&1; then return 0; fi
            tar -tf  "$archive" >/dev/null 2>&1 || \
            tar -tzf "$archive" >/dev/null 2>&1 || \
            tar -tJf "$archive" >/dev/null 2>&1 ;;
        *.zst) command -v zstd >/dev/null 2>&1 && zstd -t "$archive" >/dev/null 2>&1 ;;
        *.gz)  gzip -t "$archive" >/dev/null 2>&1 ;;
        *.xz)  command -v xz >/dev/null 2>&1 && xz -t "$archive" >/dev/null 2>&1 ;;
        *)     return 1 ;;
    esac
}

ash_archive_list() {
    local archive="$1"
    case "$archive" in
        *.zip) command -v unzip >/dev/null 2>&1 && unzip -Z1 "$archive" 2>/dev/null ;;
        *.7z)  command -v 7z >/dev/null 2>&1 && 7z l -ba -bso0 "$archive" 2>/dev/null | awk '{print $NF}' ;;
        *)
            if tar -tf "$archive" >/dev/null 2>&1; then tar -tf "$archive"
            elif tar -tzf "$archive" >/dev/null 2>&1; then tar -tzf "$archive"
            elif tar -tJf "$archive" >/dev/null 2>&1; then tar -tJf "$archive"
            fi ;;
    esac
}

# ── Extract ──────────────────────────────────────────────────────────────────
# ash_extract <archive> [dest] [--strip-components N] [--force]
# Safety: refuses paths containing ".." or absolute components.
ash_extract() {
    local archive="$1" dest="${2:-.}"
    shift 2 || true
    local strip="" force=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --strip-components) strip="$2"; shift 2 ;;
            --force) force=1; shift ;;
            *) shift ;;
        esac
    done

    [[ -f "$archive" ]] || { ash_log_error "archive not found: $archive" 2>/dev/null || true; return 1; }

    # ── Validate before touching the filesystem ──────────────────────────
    if ! ash_archive_valid "$archive"; then
        ash_log_error "archive is corrupt or unsupported: ${archive}" 2>/dev/null || true
        return 1
    fi

    # ── Path-traversal guard (Zip-Slip / tar-slip) ───────────────────────
    local hostile=0 entry
    while IFS= read -r entry || [[ -n "$entry" ]]; do
        [[ -z "$entry" ]] && continue
        if [[ "$entry" == /* || "$entry" == *'../'* || "$entry" == '..' ]]; then
            ash_log_error "refusing to extract unsafe path: ${entry}" 2>/dev/null || true
            hostile=1
        fi
    done < <(ash_archive_list "$archive")

    (( hostile == 1 )) && return 1

    # ── Symlink escape guard ─────────────────────────────────────────────
    if [[ "$archive" == *.tar* || "$archive" == *.tar ]]; then
        local symlink_target
        symlink_target="$(tar -tvf "$archive" 2>/dev/null | awk '$1 ~ /^l/ {print $NF}' | grep -E '^/|\.\.' | head -1 || true)"
        [[ -n "$symlink_target" ]] && {
            ash_log_error "archive contains an escaping symlink: ${symlink_target}" 2>/dev/null || true
            return 1
        }
    fi

    mkdir -p "$dest" 2>/dev/null || return 1

    local -a strip_args=()
    [[ -n "$strip" ]] && strip_args=(--strip-components="$strip")

    local rc=0
    case "$archive" in
        *.zip)
            command -v unzip >/dev/null 2>&1 || return 1
            unzip -q ${force:+-o} ${force:-} -d "$dest" "$archive" 2>/dev/null || rc=$?
            ;;
        *.7z)
            command -v 7z >/dev/null 2>&1 || return 1
            7z x -bso0 -bsp0 -o"$dest" ${force:+-y} "$archive" >/dev/null 2>&1 || rc=$?
            ;;
        *)
            if tar --zstd -tf "$archive" >/dev/null 2>&1; then
                tar --zstd -xf "$archive" "${strip_args[@]}" -C "$dest" || rc=$?
            elif tar -tzf "$archive" >/dev/null 2>&1; then
                tar -xzf "$archive" "${strip_args[@]}" -C "$dest" || rc=$?
            elif tar -tJf "$archive" >/dev/null 2>&1; then
                tar -xJf "$archive" "${strip_args[@]}" -C "$dest" || rc=$?
            else
                tar -xf "$archive" "${strip_args[@]}" -C "$dest" || rc=$?
            fi
            ;;
    esac

    (( rc == 0 )) && ash_log_info "extracted ${archive} → ${dest}" 2>/dev/null || \
        ash_log_error "extraction failed: ${archive}" 2>/dev/null || true
    return $rc
}

# ── Auto-detect and extract by content, not extension ────────────────────────
ash_extract_auto() {
    local file="$1" dest="${2:-.}"
    local detected=""

    if head -c 4 "$file" 2>/dev/null | grep -q $'PK\x03\x04'; then detected="zip"
    elif head -c 6 "$file" 2>/dev/null | grep -q $'\x28\xb5\x2f\xfd'; then detected="zst"
    elif head -c 2 "$file" 2>/dev/null | grep -q $'\x1f\x8b'; then detected="gz"
    elif head -c 6 "$file" 2>/dev/null | grep -q $'\xfd7zXZ'; then detected="xz"
    elif head -c 4 "$file" 2>/dev/null | grep -q $'7z\xbc\xaf'; then detected="7z"
    elif head -c 3 "$file" 2>/dev/null | grep -q $'BZh'; then detected="bz2"
    fi

    case "$detected" in
        zip) ash_extract "$file" "$dest" ;;
        gz|bz2|xz|zst)
            # Single-file stream: decompress directly.
            mkdir -p "$dest"
            local base; base="$(basename "$file")"
            base="${base%.gz}"; base="${base%.bz2}"; base="${base%.xz}"; base="${base%.zst}"
            case "$detected" in
                gz)  gzip -dc "$file" > "${dest}/${base}" ;;
                bz2) bzip2 -dc "$file" > "${dest}/${base}" ;;
                xz)  xz -dc "$file" > "${dest}/${base}" ;;
                zst) zstd -dc "$file" > "${dest}/${base}" ;;
            esac
            ;;
        *)
            if [[ "$(basename "$file")" == *.tar* || "$(basename "$file")" == *.tar ]]; then
                ash_extract "$file" "$dest"
            else
                cp -p "$file" "$dest/" 2>/dev/null
            fi
            ;;
    esac
}

# ── Helpers ──────────────────────────────────────────────────────────────────
ash_file_human_size() {
    local f="$1"
    local b
    b="$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f" 2>/dev/null || echo 0)"
    if   (( b >= 1073741824 )); then awk -v b="$b" 'BEGIN{printf "%.2f GiB", b/1073741824}'
    elif (( b >= 1048576 ));    then awk -v b="$b" 'BEGIN{printf "%.2f MiB", b/1048576}'
    elif (( b >= 1024 ));       then awk -v b="$b" 'BEGIN{printf "%.1f KiB", b/1024}'
    else printf '%d B' "$b"; fi
}

ash_archive_ratio() {
    local archive="$1" original_size="$2"
    local packed; packed="$(stat -c %s "$archive" 2>/dev/null || echo 1)"
    (( packed == 0 )) && packed=1
    awk -v o="$original_size" -v p="$packed" 'BEGIN{ printf "%.1f%%", (1 - p/o) * 100 }'
}

ash_archive_info() {
    local archive="$1"
    [[ -f "$archive" ]] || return 1
    local entries compressed
    entries="$(ash_archive_list "$archive" | wc -l)"
    compressed="$(ash_file_human_size "$archive")"
    printf 'file      : %s\n' "$archive"
    printf 'size      : %s\n' "$compressed"
    printf 'entries   : %d\n' "$entries"
    printf 'format    : %s\n' "${archive##*.}"
    printf 'valid     : %s\n' "$(ash_archive_valid "$archive" && echo yes || echo NO)"
}

# ── Incremental backup helper (used by backup-engine) ────────────────────────
# Creates a snapshot, hard-linking unchanged files from the previous one.
ash_compress_incremental() {
    local source="$1" dest_dir="$2" label="${3:-backup}"
    local prev_link="${dest_dir}/latest"

    mkdir -p "$dest_dir" 2>/dev/null || return 1
    local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
    local snapshot="${dest_dir}/${label}-${stamp}"
    local tmp="${dest_dir}/.${label}-${stamp}.partial"

    mkdir -p "$tmp" || return 1

    if [[ -L "$prev_link" && -d "$prev_link" ]]; then
        # rsync with --link-dest gives us an incremental hardlink farm
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --delete --link-dest="$prev_link" "$source"/ "$tmp"/ 2>/dev/null \
                || { rm -rf "$tmp"; return 1; }
        else
            cp -al "$prev_link"/. "$tmp"/ 2>/dev/null || true
            cp -ru "$source"/. "$tmp"/ 2>/dev/null || true
        fi
    else
        if command -v rsync >/dev/null 2>&1; then
            rsync -a "$source"/ "$tmp"/ 2>/dev/null || { rm -rf "$tmp"; return 1; }
        else
            cp -a "$source"/. "$tmp"/ 2>/dev/null || { rm -rf "$tmp"; return 1; }
        fi
    fi

    mv -T "$tmp" "$snapshot" 2>/dev/null || mv "$tmp" "$snapshot"
    ln -sfn "$snapshot" "${dest_dir}/latest"

    printf '%s\n' "$snapshot"
    ash_event_emit "compression.incremental" "snapshot=${snapshot}" 2>/dev/null || true
}

# Keeps only the N most recent snapshots (link farm stays bounded).
ash_compress_retention() {
    local dest_dir="$1" keep="${2:-7}"
    local -a snaps=()
    mapfile -t snaps < <(find "$dest_dir" -maxdepth 1 -type d -name 'backup-*' -print 2>/dev/null | LC_ALL=C sort)
    (( ${#snaps[@]} <= keep )) && return 0

    local to_remove=$(( ${#snaps[@]} - keep )) i
    for (( i = 0; i < to_remove; i++ )); do
        rm -rf "${snaps[i]}" 2>/dev/null || true
    done
    ash_log_info "retention: removed ${to_remove} old snapshot(s)" 2>/dev/null || true
}
