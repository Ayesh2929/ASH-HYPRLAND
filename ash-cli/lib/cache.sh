#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH CACHE ENGINE — TTL-aware, content-addressed, self-pruning cache       ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Design goals                                                                ║
# ║    1. Never block the UI — a miss must cost ≤ 1 stat() call                   ║
# ║    2. Never grow unbounded — LRU eviction on a size budget                    ║
# ║    3. Never serve stale by accident — monotonic TTL timestamps                ║
# ║    4. Never corrupt — atomic writes via tmp + rename                          ║
# ║                                                                               ║
# ║  Layout                                                                      ║
# ║    $ASH_CACHE_HOME/<namespace>/<key>          ← payload                       ║
# ║    $ASH_CACHE_HOME/<namespace>/<key>.meta     ← "epoch|ttl|hits|size|tags"     ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CACHE_LOADED:-}" ]] && return 0
readonly _ASH_CACHE_LOADED=1
readonly ASH_CACHE_LIB_VERSION="5.0.0"

: "${ASH_CACHE_HOME:=${XDG_CACHE_HOME:-$HOME/.cache}/ash}"
readonly ASH_CACHE_LIB_DIR="${ASH_CACHE_HOME}/store"

# Default budget: 256 MiB before LRU eviction kicks in.
: "${ASH_CACHE_MAX_BYTES:=268435456}"
# Default TTL: 1 hour.
: "${ASH_CACHE_DEFAULT_TTL:=3600}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  INTERNAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_cache_keyfile() {
    local ns="$1" key="$2"
    # Sanitise namespace so a hostile key can never escape the cache root.
    ns="${ns//[^A-Za-z0-9._-]/_}"
    key="${key//[^A-Za-z0-9._-]/_}"
    printf '%s/%s/%s' "$ASH_CACHE_LIB_DIR" "$ns" "$key"
}

_ash_cache_now() { date +%s; }

# Portable mtime (GNU stat → BSD stat → python fallback)
_ash_cache_mtime() {
    local f="$1"
    stat -c %Y "$f" 2>/dev/null \
        || stat -f %m "$f" 2>/dev/null \
        || python3 -c 'import os,sys; print(int(os.path.getmtime(sys.argv[1])))' "$f" 2>/dev/null \
        || echo 0
}

_ash_cache_size_of() {
    local f="$1"
    stat -c %s "$f" 2>/dev/null \
        || stat -f %z "$f" 2>/dev/null \
        || wc -c < "$f" 2>/dev/null \
        || echo 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  PUBLIC API
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_cache_get <namespace> <key> [ttl]
# Prints the cached payload and returns 0 on hit; returns 1 on miss/expiry.
ash_cache_get() {
    local ns="$1" key="$2" ttl="${3:-$ASH_CACHE_DEFAULT_TTL}"
    local file; file="$(_ash_cache_keyfile "$ns" "$key")"

    [[ -f "$file" ]] || return 1

    if (( ttl > 0 )); then
        local mtime now age
        mtime="$(_ash_cache_mtime "$file")"
        now="$(_ash_cache_now)"
        age=$(( now - mtime ))
        if (( age > ttl )); then
            rm -f "$file" "${file}.meta" 2>/dev/null || true
            ash_event_emit "cache.expired" "ns=${ns}" "key=${key}" "age=${age}" 2>/dev/null || true
            return 1
        fi
    fi

    # Bump hit counter in the sidecar (best-effort, never fatal).
    local meta="${file}.meta"
    if [[ -f "$meta" ]]; then
        local hits
        hits="$(awk -F'|' '{print ($3=="" ? 0 : $3)}' "$meta" 2>/dev/null || echo 0)"
        awk -F'|' -v h="$(( hits + 1 ))" 'BEGIN{OFS="|"} {sub($3, h); print}' "$meta" \
            > "${meta}.tmp" 2>/dev/null && mv -f "${meta}.tmp" "$meta" 2>/dev/null || true
    fi

    # Touch so LRU sees this as recently used.
    touch "$file" 2>/dev/null || true

    cat "$file"
    return 0
}

# ash_cache_put <namespace> <key> <value-or-"-for-stdin"> [ttl] [tags]
ash_cache_put() {
    local ns="$1" key="$2" value="$3" ttl="${4:-$ASH_CACHE_DEFAULT_TTL}" tags="${5:-}"
    local file; file="$(_ash_cache_keyfile "$ns" "$key")"

    mkdir -p "$(dirname "$file")" 2>/dev/null || return 1

    local tmp; tmp="$(mktemp "${file}.tmp.XXXXXX")" || return 1
    if [[ "$value" == "-" ]]; then
        cat > "$tmp"
    else
        printf '%s' "$value" > "$tmp"
    fi

    mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }

    local size; size="$(_ash_cache_size_of "$file")"
    printf '%s|%s|0|%s|%s\n' "$(_ash_cache_now)" "$ttl" "$size" "$tags" > "${file}.meta" 2>/dev/null || true

    ash_event_emit "cache.stored" "ns=${ns}" "key=${key}" "bytes=${size}" 2>/dev/null || true

    # Opportunistic eviction — only 1 in 32 writes to keep the hot path fast.
    if (( RANDOM % 32 == 0 )); then
        ash_cache_prune >/dev/null 2>&1 || true
    fi
    return 0
}

# Cached computation: run <command…> once and memoise its stdout.
#   ash_cache_compute <ns> <key> <ttl> <command…>
ash_cache_compute() {
    local ns="$1" key="$2" ttl="$3"; shift 3

    if ash_cache_get "$ns" "$key" "$ttl"; then
        ah_cache_hit=1
        return 0
    fi

    local out rc=0
    out="$("$@" 2>/dev/null)" || rc=$?
    if (( rc == 0 )) && [[ -n "$out" ]]; then
        ash_cache_put "$ns" "$key" "$out" "$ttl"
    fi
    printf '%s' "$out"
    return $rc
}

# Stale-while-revalidate: return possibly-old data immediately, refresh in bg.
ash_cache_get_swr() {
    local ns="$1" key="$2" ttl="$3"; shift 3
    local file; file="$(_ash_cache_keyfile "$ns" "$key")"

    if [[ -f "$file" ]]; then
        local age=$(( $(_ash_cache_now) - $(_ash_cache_mtime "$file") ))
        if (( age <= ttl )); then
            cat "$file"; return 0
        fi
        # Serve stale, refresh in background
        cat "$file"
        ( ash_cache_compute "$ns" "$key" "$ttl" "$@" >/dev/null 2>&1 & ) 2>/dev/null || true
        return 0
    fi

    ash_cache_compute "$ns" "$key" "$ttl" "$@"
    return $?
}

ash_cache_has() {
    local ns="$1" key="$2" ttl="${3:-$ASH_CACHE_DEFAULT_TTL}"
    ash_cache_get "$ns" "$key" "$ttl" >/dev/null 2>&1
}

ash_cache_delete() {
    local ns="$1" key="$2"
    local file; file="$(_ash_cache_keyfile "$ns" "$key")"
    local existed=1
    [[ -f "$file" ]] || existed=0
    rm -f "$file" "${file}.meta" 2>/dev/null || true
    ash_event_emit "cache.invalidated" "ns=${ns}" "key=${key}" 2>/dev/null || true
    return $(( existed == 1 ? 0 : 1 ))
}

ash_cache_clear() {
    local ns="${1:-}"
    if [[ -n "$ns" ]]; then
        ns="${ns//[^A-Za-z0-9._-]/_}"
        rm -rf "${ASH_CACHE_LIB_DIR:?}/${ns:?}" 2>/dev/null || true
    else
        rm -rf "${ASH_CACHE_LIB_DIR:?}"/* 2>/dev/null || true
    fi
    ash_event_emit "cache.cleared" "ns=${ns:-all}" 2>/dev/null || true
    return 0
}

ash_cache_keys() {
    local ns="${1:-}"
    local root="${ASH_CACHE_LIB_DIR}${ns:+/${ns//[^A-Za-z0-9._-]/_}}"
    [[ -d "$root" ]] || return 0
    find "$root" -type f ! -name '*.meta' -printf '%P\n' 2>/dev/null | LC_ALL=C sort
}

ash_cache_namespaces() {
    [[ -d "$ASH_CACHE_LIB_DIR" ]] || return 0
    find "$ASH_CACHE_LIB_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | LC_ALL=C sort
}

# ── Statistics ───────────────────────────────────────────────────────────────
# Emits: namespace|entries|bytes|hits|oldest_age
ash_cache_stats() {
    [[ -d "$ASH_CACHE_LIB_DIR" ]] || { printf '%-20s %8s %12s %8s %10s\n' "NAMESPACE" "ENTRIES" "SIZE" "HITS" "OLDEST"; return 0; }

    printf '%-20s %8s %12s %8s %10s\n' "NAMESPACE" "ENTRIES" "SIZE" "HITS" "OLDEST"

    local ns dir count bytes hits meta oldest now mt age
    now="$(_ash_cache_now)"

    for dir in "$ASH_CACHE_LIB_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        ns="$(basename "$dir")"
        count=0; bytes=0; hits=0; oldest=0

        local f
        while IFS= read -r f || [[ -n "$f" ]]; do
            [[ -z "$f" ]] && continue
            (( count += 1 ))
            bytes=$(( bytes + $(_ash_cache_size_of "$f") ))
            mt="$(_ash_cache_mtime "$f")"
            (( oldest == 0 || mt < oldest )) && oldest="$mt"
            if [[ -f "${f}.meta" ]]; then
                local h; h="$(awk -F'|' '{print $3}' "${f}.meta" 2>/dev/null)"
                [[ "$h" =~ ^[0-9]+$ ]] && hits=$(( hits + h ))
            fi
        done < <(find "$dir" -type f ! -name '*.meta' 2>/dev/null)

        age=$(( oldest > 0 ? now - oldest : 0 ))
        printf '%-20s %8d %12s %8d %9ds\n' \
            "$ns" "$count" "$(ash_cache_human_bytes "$bytes")" "$hits" "$age"
    done

    printf '%-20s %8s %12s\n' "─── TOTAL ───" "────────" "────────────"
    local total_bytes=0 total_files=0
    total_bytes="$(du -sb "$ASH_CACHE_LIB_DIR" 2>/dev/null | awk '{print $1}' || echo 0)"
    total_files="$(find "$ASH_CACHE_LIB_DIR" -type f ! -name '*.meta' 2>/dev/null | wc -l)"
    printf '%-20s %8d %12s\n' "all" "$total_files" "$(ash_cache_human_bytes "${total_bytes:-0}")"
}

ash_cache_human_bytes() {
    local b="${1:-0}"
    if   (( b >= 1073741824 )); then awk -v b="$b" 'BEGIN{printf "%.2f GiB", b/1073741824}'
    elif (( b >= 1048576 ));    then awk -v b="$b" 'BEGIN{printf "%.2f MiB", b/1048576}'
    elif (( b >= 1024 ));       then awk -v b="$b" 'BEGIN{printf "%.2f KiB", b/1024}'
    else printf '%d B' "$b"; fi
}

# ── Garbage collection ───────────────────────────────────────────────────────
# 1. Drop entries older than their TTL
# 2. If still over budget, evict by (hits asc, mtime asc) — pure LRU+LFU hybrid
ash_cache_prune() {
    local dry_run=0
    [[ "${1:-}" == "--dry-run" ]] && dry_run=1

    [[ -d "$ASH_CACHE_LIB_DIR" ]] || return 0

    local now removed=0 freed=0
    now="$(_ash_cache_now)"

    # ── Phase 1: TTL expiry ──────────────────────────────────────────────
    local f meta ttl stored age
    while IFS= read -r f || [[ -n "$f" ]]; do
        [[ -z "$f" ]] && continue
        meta="${f}.meta"
        [[ -f "$meta" ]] || continue
        IFS='|' read -r stored ttl _ _ < "$meta" 2>/dev/null || continue
        [[ "$ttl" =~ ^[0-9]+$ ]] || ttl=0
        (( ttl == 0 )) && continue                    # ttl=0 means "never expires"

        age=$(( now - $(_ash_cache_mtime "$f") ))
        if (( age > ttl )); then
            if (( dry_run == 0 )); then
                freed=$(( freed + $(_ash_cache_size_of "$f") ))
                rm -f "$f" "$meta" 2>/dev/null || true
            fi
            (( removed += 1 ))
        fi
    done < <(find "$ASH_CACHE_LIB_DIR" -type f 2>/dev/null)

    # ── Phase 2: budget enforcement (LRU + LFU) ──────────────────────────
    local total_bytes
    total_bytes="$(du -sb "$ASH_CACHE_LIB_DIR" 2>/dev/null | awk '{print $1}')"
    total_bytes="${total_bytes:-0}"

    if (( total_bytes > ASH_CACHE_MAX_BYTES )); then
        local target=$(( ASH_CACHE_MAX_BYTES * 80 / 100 ))   # shrink to 80 %
        local over=$(( total_bytes - target ))

        # score = hits * 1000000 - mtime  (lowest score evicted first)
        local candidate_list
        candidate_list="$(
            while IFS= read -r f || [[ -n "$f" ]]; do
                [[ -z "$f" ]] && continue
                local h=0
                [[ -f "${f}.meta" ]] && h="$(awk -F'|' '{print $3}' "${f}.meta" 2>/dev/null)"
                [[ "$h" =~ ^[0-9]+$ ]] || h=0
                printf '%s\t%s\t%s\n' "$(( h * 1000000 - $(_ash_cache_mtime "$f") ))" "$(_ash_cache_size_of "$f")" "$f"
            done < <(find "$ASH_CACHE_LIB_DIR" -type f ! -name '*.meta' 2>/dev/null) \
            | LC_ALL=C sort -n -k1,1
        )"

        local score size path
        while IFS=$'\t' read -r score size path; do
            [[ -z "$path" ]] && continue
            (( over <= 0 )) && break
            if (( dry_run == 0 )); then
                freed=$(( freed + size ))
                rm -f "$path" "${path}.meta" 2>/dev/null || true
            fi
            over=$(( over - size ))
            (( removed += 1 ))
        done <<< "$candidate_list"
    fi

    if (( dry_run == 1 )); then
        ash_log_info "cache prune (dry-run): would evict ${removed} entries"
    else
        ash_log_info "cache prune: evicted ${removed} entries, freed $(ash_cache_human_bytes "$freed")" 2>/dev/null || true
        ash_event_emit "cache.pruned" "removed=${removed}" "freed=${freed}" 2>/dev/null || true
    fi

    printf '%d\n' "$removed"
}

# Warm a set of keys concurrently (used at login to pre-populate weather etc.)
ash_cache_warm() {
    local -a specs=("$@")   # each: "ns key ttl command…"
    local spec
    for spec in "${specs[@]}"; do
        ( ash_cache_compute $spec >/dev/null 2>&1 & ) 2>/dev/null || true
    done
    return 0
}

ash_cache_integrity_check() {
    [[ -d "$ASH_CACHE_LIB_DIR" ]] || { printf '  ✓ cache directory absent (clean state)\n'; return 0; }

    local orphans=0 broken=0
    local f
    while IFS= read -r f || [[ -n "$f" ]]; do
        [[ -z "$f" ]] && continue
        [[ -f "${f}.meta" ]] || { (( orphans += 1 )); }
    done < <(find "$ASH_CACHE_LIB_DIR" -type f ! -name '*.meta' 2>/dev/null)

    while IFS= read -r f || [[ -n "$f" ]]; do
        [[ "$f" == *.meta ]] || continue
        [[ -f "${f%.meta}" ]] || (( broken += 1 ))
    done < <(find "$ASH_CACHE_LIB_DIR" -type f -name '*.meta' 2>/dev/null)

    printf '  entries without metadata : %d\n' "$orphans"
    printf '  metadata without entries : %d\n' "$broken"
    (( orphans == 0 && broken == 0 )) && printf '  ✓ cache integrity OK\n' || printf '  ⚠ run: ash clean --cache\n'
}
