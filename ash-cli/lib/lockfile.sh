#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔒 ASH LOCKFILE ENGINE — advisory locking with stale-lock recovery           ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Problem: two `ash theme apply` invocations at once corrupt colors.conf.       ║
# ║                                                                               ║
# ║  Solution: layered locking                                                   ║
# ║    Tier 1 — flock(1) when available (kernel-level, auto-released on exit)     ║
# ║    Tier 2 — atomic mkdir(2) when flock is absent (still race-free)            ║
# ║    Tier 3 — PID liveness probe to reclaim locks left by crashed processes     ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_LOCKFILE_LOADED:-}" ]] && return 0
readonly _ASH_LOCKFILE_LOADED=1
readonly ASH_LOCKFILE_VERSION="5.0.0"

: "${ASH_RUNTIME_DIR:=${XDG_RUNTIME_DIR:-/tmp}/ash}"
readonly ASH_LOCK_DIR="${ASH_RUNTIME_DIR}/locks"

# How long a lock may sit before it is considered abandoned (seconds).
: "${ASH_LOCK_STALE_AGE:=300}"

declare -gA ASH_HELD_LOCKS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_lock_path() {
    local name="${1//[^A-Za-z0-9._-]/_}"
    printf '%s/%s.lock' "$ASH_LOCK_DIR" "$name"
}

# True when the PID is alive AND is not a zombie.
_ash_lock_pid_alive() {
    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1

    # Reject zombies on Linux (they answer kill -0 but hold nothing)
    if [[ -r "/proc/${pid}/stat" ]]; then
        local state
        state="$(awk '{print $3}' "/proc/${pid}/stat" 2>/dev/null)"
        [[ "$state" == "Z" ]] && return 1
    fi
    return 0
}

# Is this pid the same process that wrote the lock? (guards against PID reuse)
_ash_lock_pid_matches() {
    local pid="$1" recorded_start="$2"
    [[ -z "$recorded_start" ]] && return 0
    [[ -r "/proc/${pid}/stat" ]] || return 0

    # Field 22 of /proc/<pid>/stat is starttime (in clock ticks since boot)
    local current_start
    current_start="$(awk '{print $22}' "/proc/${pid}/stat" 2>/dev/null)"
    [[ "$current_start" == "$recorded_start" ]]
}

_ash_lock_process_start_time() {
    local pid="$1"
    [[ -r "/proc/${pid}/stat" ]] && awk '{print $22}' "/proc/${pid}/stat" 2>/dev/null || printf ''
}

_ash_lock_hostname() { hostname 2>/dev/null || printf 'unknown'; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  ACQUIRE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_lock_acquire <name> [--timeout SEC] [--wait] [--readonly] [--force]
ash_lock_acquire() {
    local name="$1"; shift || true
    local timeout=0 wait_mode=0 force=0 readonly_mode=0
    local name_arg="$name"
    local -a name_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout)  timeout="$2"; shift 2 ;;
            --wait)     wait_mode=1; timeout="${timeout:-30}"; shift ;;
            --readonly) readonly_mode=1; shift ;;
            --force)    force=1; shift ;;
            *)          name_args+=("$1"); shift ;;
        esac
    done
    # Allow "ash_lock_acquire name part2 part3" → "name-part2-part3"
    if (( ${#name_args[@]} > 0 )); then
        name="${name_arg}-$(IFS=-; printf '%s' "${name_args[*]}")"
    fi

    mkdir -p "$ASH_LOCK_DIR" 2>/dev/null || return 1
    local lockfile; lockfile="$(_ash_lock_path "$name")"

    # ── Fast path: already reentrant in this process ─────────────────────
    if [[ -n "${ASH_HELD_LOCKS[$name]:-}" ]]; then
        # Increment a re-entrancy depth counter
        ASH_HELD_LOCKS["$name"]=$(( ${ASH_HELD_LOCKS[$name]} + 1 ))
        return 0
    fi

    local start_ts; start_ts="$(date +%s)"
    local acquired=0

    while :; do
        # ── Tier 1: flock ────────────────────────────────────────────────
        if command -v flock >/dev/null 2>&1 && [[ $readonly_mode -eq 0 ]]; then
            # FD 200 is high enough to avoid clashing with script FDs.
            if [[ $wait_mode -eq 1 ]]; then
                if exec 200>"$lockfile" && flock -w "$timeout" 200; then
                    acquired=1
                fi
            else
                if exec 200>"$lockfile" && flock -n 200; then
                    acquired=1
                fi
            fi
            if [[ $acquired -eq 1 ]]; then
                printf '%s|%s|%s|%s|%s\n' \
                    "$$" "$(_ash_lock_process_start_time $$)" \
                    "$(_ash_lock_hostname)" "$(date +%s)" "${ASH_TASK_NAME:-${0##*/}}" \
                    > "${lockfile}.info" 2>/dev/null || true
                ASH_HELD_LOCKS["$name"]=1
                ash_event_emit "lock.acquired" "name=${name}" "pid=$$" 2>/dev/null || true
                return 0
            fi
        fi

        # ── Tier 2: atomic mkdir ─────────────────────────────────────────
        if mkdir "${lockfile}.d" 2>/dev/null; then
            printf '%s|%s|%s|%s|%s\n' \
                "$$" "$(_ash_lock_process_start_time $$)" \
                "$(_ash_lock_hostname)" "$(date +%s)" "${ASH_TASK_NAME:-${0##*/}}" \
                > "${lockfile}.d/owner" 2>/dev/null || true
            ASH_HELD_LOCKS["$name"]=1
            ash_event_emit "lock.acquired" "name=${name}" "pid=$$" 2>/dev/null || true
            return 0
        fi

        # ── Tier 3: stale detection ──────────────────────────────────────
        local owner_pid="" owner_start="" owner_age=0 owner_file=""
        if [[ -f "${lockfile}.info" ]]; then owner_file="${lockfile}.info"
        elif [[ -f "${lockfile}.d/owner" ]]; then owner_file="${lockfile}.d/owner"; fi

        if [[ -n "$owner_file" ]]; then
            IFS='|' read -r owner_pid owner_start _ owner_age _ < "$owner_file" 2>/dev/null || true
        fi

        local now; now="$(date +%s)"
        local lock_mtime; lock_mtime="$(_ash_cache_mtime "$lockfile" 2>/dev/null || echo "$now")"
        local lock_age=$(( now - lock_mtime ))

        local stale=0 reason=""
        if [[ -z "$owner_pid" ]]; then
            (( lock_age > ASH_LOCK_STALE_AGE )) && { stale=1; reason="no owner and age ${lock_age}s"; }
        elif ! _ash_lock_pid_alive "$owner_pid"; then
            stale=1; reason="owner pid ${owner_pid} is dead"
        elif ! _ash_lock_pid_matches "$owner_pid" "$owner_start"; then
            stale=1; reason="pid ${owner_pid} was reused by another process"
        elif (( lock_age > ASH_LOCK_STALE_AGE * 4 )); then
            stale=1; reason="lock held for ${lock_age}s (suspiciously long)"
        fi

        if [[ $stale -eq 1 || $force -eq 1 ]]; then
            ash_log_warn "breaking stale lock '${name}': ${reason:-forced}" 2>/dev/null || true
            rm -rf "${lockfile}" "${lockfile}.info" "${lockfile}.d" 2>/dev/null || true
            ash_event_emit "lock.stale_broken" "name=${name}" "reason=${reason}" 2>/dev/null || true
            continue   # retry immediately
        fi

        # ── Not stale: honour timeout / report contention ────────────────
        if [[ $wait_mode -eq 0 ]]; then
            ash_log_warn "lock '${name}' is held by pid ${owner_pid}" 2>/dev/null \
                || printf 'ash: lock held by pid %s\n' "${owner_pid:-unknown}" >&2
            return 1
        fi

        local elapsed=$(( now - start_ts ))
        if (( elapsed >= timeout )); then
            ash_log_error "timed out after ${timeout}s waiting for lock '${name}'" 2>/dev/null \
                || printf "ash: timeout waiting for lock '%s'\n" "$name" >&2
            return 1
        fi

        sleep 0.15
    done
}

# ── Non-blocking probe ───────────────────────────────────────────────────────
ash_lock_is_held() {
    local name="$1"
    local lockfile; lockfile="$(_ash_lock_path "$name")"

    [[ -f "${lockfile}.info" || -d "${lockfile}.d" ]] || return 1

    local owner_pid=""
    if [[ -f "${lockfile}.info" ]]; then
        IFS='|' read -r owner_pid _ < "${lockfile}.info" 2>/dev/null || true
    elif [[ -f "${lockfile}.d/owner" ]]; then
        IFS='|' read -r owner_pid _ < "${lockfile}.d/owner" 2>/dev/null || true
    fi

    [[ -z "$owner_pid" ]] && return 1
    _ash_lock_pid_alive "$owner_pid"
}

# ── Run a command under a lock, always releasing it ─────────────────────────
#   ash_lock_run <name> [--timeout N] -- <command…>
ash_lock_run() {
    local name="$1"; shift
    local -a lock_opts=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do
        lock_opts+=("$1"); shift
    done
    [[ "${1:-}" == "--" ]] && shift

    if ! ash_lock_acquire "$name" "${lock_opts[@]}"; then
        return 1
    fi

    local rc=0
    "$@" || rc=$?

    ash_lock_release "$name"
    return $rc
}

# ── Release ──────────────────────────────────────────────────────────────────
ash_lock_release() {
    local name="$1"
    local lockfile; lockfile="$(_ash_lock_path "$name")"

    # Re-entrancy: only the outermost release actually unlocks.
    if [[ -n "${ASH_HELD_LOCKS[$name]:-}" ]] && (( ASH_HELD_LOCKS[$name] > 1 )); then
        ASH_HELD_LOCKS["$name"]=$(( ASH_HELD_LOCKS[$name] - 1 ))
        return 0
    fi

    # Only remove the lock if we still own it (avoids deleting a successor's lock)
    local owner_pid=""
    [[ -f "${lockfile}.info" ]] && IFS='|' read -r owner_pid _ < "${lockfile}.info" 2>/dev/null || true
    [[ -z "$owner_pid" && -f "${lockfile}.d/owner" ]] && IFS='|' read -r owner_pid _ < "${lockfile}.d/owner" 2>/dev/null || true

    if [[ -z "$owner_pid" || "$owner_pid" == "$$" ]]; then
        exec 200>&- 2>/dev/null || true     # close the flock FD
        rm -f "${lockfile}" "${lockfile}.info" 2>/dev/null || true
        rm -rf "${lockfile}.d" 2>/dev/null || true
        unset 'ASH_HELD_LOCKS[$name]'
        ash_event_emit "lock.released" "name=${name}" "pid=$$" 2>/dev/null || true
    fi
    return 0
}

# ── Introspection ────────────────────────────────────────────────────────────
# Emits: name|pid|host|acquired|task|age|state
ash_lock_list() {
    [[ -d "$ASH_LOCK_DIR" ]] || return 0

    local lockfile name owner_file pid start host acquired task age now state
    now="$(date +%s)"

    for lockfile in "$ASH_LOCK_DIR"/*.lock "$ASH_LOCK_DIR"/*.lock.d; do
        [[ -e "$lockfile" ]] || continue
        name="$(basename "$lockfile")"
        name="${name%.lock}"; name="${name%.lock.d}"

        owner_file="${lockfile}.info"
        [[ -f "$owner_file" ]] || owner_file="${lockfile}/owner"
        [[ -f "$owner_file" ]] || owner_file="$lockfile"

        pid=""; start=""; host=""; acquired=""; task=""
        IFS='|' read -r pid start host acquired task < "$owner_file" 2>/dev/null || true

        if [[ -n "$pid" ]] && _ash_lock_pid_alive "$pid"; then state="HELD"
        elif [[ -n "$pid" ]]; then state="STALE"
        else state="ORPHAN"; fi

        age=""; [[ "$acquired" =~ ^[0-9]+$ ]] && age=$(( now - acquired ))

        printf '%s|%s|%s|%s|%s|%s|%s\n' \
            "$name" "${pid:-?}" "${host:-?}" "${acquired:-0}" "${task:-?}" "${age:-0}" "$state"
    done
}

ash_lock_force_release() {
    local name="$1"
    local lockfile; lockfile="$(_ash_lock_path "$name")"
    rm -f "${lockfile}" "${lockfile}.info" 2>/dev/null || true
    rm -rf "${lockfile}.d" 2>/dev/null || true
    unset 'ASH_HELD_LOCKS[$name]' 2>/dev/null || true
    return 0
}

ash_lock_clear_stale() {
    local cleared=0 name pid state
    while IFS='|' read -r name pid _ _ _ _ state; do
        [[ -z "$name" ]] && continue
        if [[ "$state" == "STALE" || "$state" == "ORPHAN" ]]; then
            ash_lock_force_release "$name"
            (( cleared += 1 ))
        fi
    done < <(ash_lock_list)
    printf '%d\n' "$cleared"
}

# Release everything this process holds — wired into the EXIT trap.
ash_lock_release_all() {
    local name
    for name in "${!ASH_HELD_LOCKS[@]}"; do
        [[ -z "$name" ]] && continue
        ASH_HELD_LOCKS["$name"]=1        # defeat the re-entrancy guard
        ash_lock_release "$name"
    done
    ASH_HELD_LOCKS=()
    return 0
}

# ── Convenience: named global locks used across the codebase ─────────────────
ash_lock_theme()   { ash_lock_acquire "theme-apply" "$@"; }
ash_lock_config()  { ash_lock_acquire "config-write" "$@"; }
ash_lock_plugin()  { ash_lock_acquire "plugin-op" "$@"; }
ash_lock_update()  { ash_lock_acquire "update" "$@"; }
ash_lock_snapshot(){ ash_lock_acquire "snapshot" "$@"; }

# ── Composite lock (all-or-nothing, ordered to prevent deadlock) ─────────────
ash_lock_acquire_many() {
    local -a names=("$@")
    local -a sorted
    # Sort so every caller acquires in the same order → no deadlock cycle.
    mapfile -t sorted < <(printf '%s\n' "${names[@]}" | LC_ALL=C sort -u)

    local -a held=()
    local n
    for n in "${sorted[@]}"; do
        if ash_lock_acquire "$n" --timeout 10; then
            held+=("$n")
        else
            local h
            for h in "${held[@]}"; do ash_lock_release "$h"; done
            return 1
        fi
    done
    return 0
}

ash_lock_release_many() {
    local n
    for n in "$@"; do ash_lock_release "$n"; done
    return 0
}
