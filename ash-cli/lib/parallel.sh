#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH PARALLEL ENGINE — bounded worker pool with result collection          ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Why not `xargs -P`? Because we need:                                         ║
# ║    • per-task stdout/stderr captured separately, not interleaved              ║
# ║    • per-task exit codes so a partial failure is reportable                   ║
# ║    • progress callbacks (this drives the animated apply pipeline)             ║
# ║    • cancellation on first failure (`--fail-fast`)                            ║
# ║                                                                               ║
# ║  Uses bash job control — no GNU parallel dependency.                          ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_PARALLEL_LOADED:-}" ]] && return 0
readonly _ASH_PARALLEL_LOADED=1
readonly ASH_PARALLEL_VERSION="5.0.0"

: "${ASH_PARALLEL_JOBS:=$(nproc 2>/dev/null || echo 4)}"
: "${ASH_PARALLEL_TMP:=${TMPDIR:-/tmp}}"

declare -gA ASH_PARALLEL_RESULTS=()

_ash_parallel_results_dir() {
    local d="${ASH_PARALLEL_TMP}/ash-parallel-$$"
    mkdir -p "${d}/out" "${d}/err" 2>/dev/null || true
    printf '%s' "$d"
}

# ── 1. Run a command against every line of stdin ─────────────────────────────
# ash_parallel_run [-j JOBS] [-k] [-q] <command-template>
#   The literal token `{}` is replaced by each input line.
#   Without `{}`, the line is appended as the last argument.
ash_parallel_run() {
    local jobs="$ASH_PARALLEL_JOBS" fail_fast=0 quiet=0 keep_order=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--jobs)      jobs="$2"; shift 2 ;;
            -k|--fail-fast) fail_fast=1; shift ;;
            -q|--quiet)     quiet=1; shift ;;
            --ordered)      keep_order=1; shift ;;
            -*)             shift ;;
            *)              break ;;
        esac
    done

    local -a template=("$@")
    (( ${#template[@]} == 0 )) && { ash_log_error "no command given" 2>/dev/null || true; return 1; }
    [[ "$jobs" =~ ^[0-9]+$ ]] || jobs=4
    (( jobs < 1 )) && jobs=1

    local dir; dir="$(_ash_parallel_results_dir)"

    local -a pids=() items=() idx_map=()
    local line index=0 running=0 fail_count=0

    _ash_parallel_launch() {
        local item="$1" index="$2"
        (
            local -a cmd=()
            local arg had_placeholder=0
            for arg in "${template[@]}"; do
                if [[ "$arg" == *'{}'* ]]; then
                    cmd+=("${arg//\{\}/$item}")
                    had_placeholder=1
                else
                    cmd+=("$arg")
                fi
            done
            (( had_placeholder == 0 )) && cmd+=("$item")

            "${cmd[@]}" > "${dir}/out/${index}" 2> "${dir}/err/${index}"
            printf '%d' $? > "${dir}/out/${index}.rc"
        ) &
        pids+=("$!")
        idx_map+=("$index")
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue

        # Keep the pool bounded: wait for one slot before launching more.
        if (( running >= jobs )); then
            local done_pid="${pids[0]}"
            wait "$done_pid" 2>/dev/null || true
            pids=("${pids[@]:1}")
            (( running -= 1 ))

            if (( fail_fast == 1 )); then
                local rc_f
                rc_f="$(cat "${dir}/out/${idx_map[0]}.rc" 2>/dev/null || echo 1)"
                (( rc_f != 0 )) && { (( quiet == 0 )) && ash_log_error "fail-fast: aborting after ${index} tasks" 2>/dev/null || true; break; }
            fi
            idx_map=("${idx_map[@]:1}")
        fi

        _ash_parallel_launch "$line" "$index"
        (( running += 1 ))
        (( index += 1 ))
    done

    # Drain the remaining workers.
    local p
    for p in "${pids[@]:-}"; do
        [[ -z "$p" ]] && continue
        wait "$p" 2>/dev/null || true
    done

    # ── Collect ──────────────────────────────────────────────────────────
    local i=0
    for (( i = 0; i < index; i++ )); do
        local rc
        rc="$(cat "${dir}/out/${i}.rc" 2>/dev/null || echo 1)"
        ASH_PARALLEL_RESULTS["$i.rc"]="$rc"
        ASH_PARALLEL_RESULTS["$i.out"]="$(cat "${dir}/out/${i}" 2>/dev/null)"
        ASH_PARALLEL_RESULTS["$i.err"]="$(cat "${dir}/err/${i}" 2>/dev/null)"

        if (( rc != 0 )); then (( fail_count += 1 )); fi

        if (( quiet == 0 )); then
            if (( rc == 0 )); then
                [[ -s "${dir}/out/${i}" ]] && cat "${dir}/out/${i}"
            else
                printf '  ✗ task %d failed (exit %s)\n' "$i" "$rc" >&2
                [[ -s "${dir}/err/${i}" ]] && sed 's/^/      /' "${dir}/err/${i}" >&2
            fi
        fi
    done

    # Clean up unless the caller wants to inspect the raw files.
    [[ "${ASH_PARALLEL_KEEP_TMP:-0}" == "1" ]] || rm -rf "$dir" 2>/dev/null || true

    (( fail_count == 0 )) && return 0 || return 1
}

# ── 2. Run a set of bash functions in parallel ───────────────────────────────
# ash_parallel_functions <job-count> <fn> [fn…]
# Each function is listed in ASH_PARALLEL_FN_ARGS as its argument vector.
ash_parallel_functions() {
    local jobs="${1:-$ASH_PARALLEL_JOBS}"; shift
    local -a fns=("$@")
    (( ${#fns[@]} == 0 )) && return 0

    local dir; dir="$(_ash_parallel_results_dir)"
    local -a pids=() names=()

    local n
    for n in "${fns[@]}"; do
        (
            local rc=0
            if declare -f "$n" >/dev/null 2>&1; then
                # shellcheck disable=SC2086
                "$n" ${ASH_PARALLEL_FN_ARGS:-} > "${dir}/out/${n}" 2> "${dir}/err/${n}" || rc=$?
            else
                printf 'function not found: %s\n' "$n" >&2
                rc=127
            fi
            printf '%d' "$rc" > "${dir}/out/${n}.rc"
        ) &
        pids+=("$!")
        names+=("$n")

        # Simple throttling: wait when we exceed the pool.
        while (( $(jobs -rp 2>/dev/null | wc -l) >= jobs )); do sleep 0.02; done
    done

    local p rc fail=0
    for p in "${pids[@]}"; do wait "$p" 2>/dev/null || true; done

    for n in "${names[@]}"; do
        rc="$(cat "${dir}/out/${n}.rc" 2>/dev/null || echo 1)"
        ASH_PARALLEL_RESULTS["${n}.rc"]="$rc"
        ASH_PARALLEL_RESULTS["${n}.out"]="$(cat "${dir}/out/${n}" 2>/dev/null)"
        (( rc != 0 )) && { fail=1; printf '  ✗ %s failed\n' "$n" >&2; }
    done

    rm -rf "$dir" 2>/dev/null || true
    return $fail
}

# ── 3. Map over an array with a progress bar ─────────────────────────────────
# ash_parallel_map <callback-fn> <item…>
# The callback receives the item as $1 and runs in a subshell.
ash_parallel_map() {
    local callback="$1"; shift
    local -a items=("$@")
    (( ${#items[@]} == 0 )) && return 0

    local total="${#items[@]}"
    local jobs="$ASH_PARALLEL_JOBS"
    local completed=0

    local -a pids=()
    local item
    for item in "${items[@]}"; do
        (
            "$callback" "$item" >/dev/null 2>&1
        ) &
        pids+=("$!")

        while (( $(jobs -rp 2>/dev/null | wc -l) >= jobs )); do
            wait -n 2>/dev/null || true
            (( completed += 1 ))
            if declare -f ash_progress_bar >/dev/null 2>&1; then
                ash_progress_bar "$completed" "$total" "applying"
            fi
        done
    done

    local p
    for p in "${pids[@]}"; do
        wait "$p" 2>/dev/null || true
        (( completed += 1 ))
        if declare -f ash_progress_bar >/dev/null 2>&1; then
            ash_progress_bar "$completed" "$total" "applying"
        fi
    done
    printf '\n'
    return 0
}

# ── 4. Race: first successful result wins ────────────────────────────────────
# Useful for "try these 3 wallpaper mirrors, take whichever answers first".
ash_parallel_race() {
    local -a commands=("$@")
    (( ${#commands[@]} == 0 )) && return 1

    local dir; dir="$(_ash_parallel_results_dir)"
    local -a pids=()

    local i=0
    for i in "${!commands[@]}"; do
        (
            local rc=0
            eval "${commands[i]}" > "${dir}/out/${i}" 2>/dev/null || rc=$?
            printf '%d' "$rc" > "${dir}/out/${i}.rc"
        ) &
        pids+=("$!")
    done

    local winner=-1
    while (( winner < 0 )); do
        for i in "${!commands[@]}"; do
            local rcfile="${dir}/out/${i}.rc"
            if [[ -f "$rcfile" ]] && [[ "$(cat "$rcfile")" == "0" ]]; then
                winner="$i"
                break
            fi
        done
        # All finished with no winner?
        local alive=0
        for p in "${pids[@]}"; do kill -0 "$p" 2>/dev/null && (( alive += 1 )); done
        (( alive == 0 )) && (( winner < 0 )) && break
        sleep 0.05
    done

    for p in "${pids[@]}"; do
        kill "$p" 2>/dev/null || true
        wait "$p" 2>/dev/null || true
    done

    if (( winner >= 0 )); then
        cat "${dir}/out/${winner}" 2>/dev/null
        rm -rf "$dir" 2>/dev/null || true
        return 0
    fi
    rm -rf "$dir" 2>/dev/null || true
    return 1
}

# ── 5. Timeout-bounded batch (prevents one slow plugin hanging a pipeline) ───
ash_parallel_batch_timeout() {
    local timeout_s="$1"; shift
    local dir; dir="$(_ash_parallel_results_dir)"

    local -a pids=() names=()
    local cmd
    for cmd in "$@"; do
        local safe; safe="$(printf '%s' "$cmd" | cksum | awk '{print $1}')"
        (
            local rc=0
            if command -v timeout >/dev/null 2>&1; then
                timeout --kill-after=2 "$timeout_s" bash -c "$cmd" > "${dir}/out/${safe}" 2>&1 || rc=$?
            else
                bash -c "$cmd" > "${dir}/out/${safe}" 2>&1 || rc=$?
            fi
            printf '%d' "$rc" > "${dir}/out/${safe}.rc"
        ) &
        pids+=("$!")
        names+=("$safe")
    done

    local p
    for p in "${pids[@]}"; do wait "$p" 2>/dev/null || true; done

    local fail=0 n rc
    for n in "${names[@]}"; do
        rc="$(cat "${dir}/out/${n}.rc" 2>/dev/null || echo 1)"
        if (( rc == 0 )); then
            cat "${dir}/out/${n}" 2>/dev/null
        elif (( rc == 124 )); then
            printf '  ⚠ task timed out after %ss\n' "$timeout_s" >&2
            fail=1
        else
            sed 's/^/      /' "${dir}/out/${n}" 2>/dev/null >&2
            fail=1
        fi
    done

    rm -rf "$dir" 2>/dev/null || true
    return $fail
}

# ── 6. Informational: how many workers should we actually use? ───────────────
ash_parallel_recommended_jobs() {
    local cores load
    cores="$(nproc 2>/dev/null || echo 2)"

    # If the box is already loaded, backing off avoids making things worse.
    if [[ -r /proc/loadavg ]]; then
        load="$(awk '{print int($1)}' /proc/loadavg)"
        if (( load >= cores )); then
            printf '%d' "$(( cores / 2 > 0 ? cores / 2 : 1 ))"
            return
        fi
    fi

    # I/O-heavy work (rendering 25 config files) benefits from oversubscription.
    printf '%d' "$(( cores + 2 ))"
}
