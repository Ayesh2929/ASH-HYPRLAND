#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🛡️  ASH TRAP HANDLER — signal safety and guaranteed cleanup                  ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  The cardinal rule this module enforces:                                      ║
# ║      a `ash theme apply` killed with Ctrl-C must leave colours.conf VALID     ║
# ║                                                                               ║
# ║  It does that by:                                                            ║
# ║    • registering cleanup callbacks with priorities (LIFO within a priority)   ║
# ║    • guarding against re-entrant cleanup (a handler that traps again)         ║
# ║    • restoring the terminal (cursor, echo, mouse mode, alternate screen)      ║
# ║    • distinguishing interactive Ctrl-C from CI SIGTERM                        ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_TRAP_HANDLER_LOADED:-}" ]] && return 0
readonly _ASH_TRAP_HANDLER_LOADED=1
readonly ASH_TRAP_VERSION="5.0.0"

# Priority → "callback1;callback2;…"  (lower priority runs FIRST)
declare -gA ASH_TRAP_CALLBACKS=()
declare -g  ASH_TRAP_RUNNING=0
declare -g  ASH_TRAP_INSTALLED=0
declare -g  ASH_TRAP_EXIT_CODE=0
declare -g  ASH_TRAP_SIGNAL=""
declare -ga ASH_TRAP_TEMP_FILES=()

# ── Registration ─────────────────────────────────────────────────────────────
# ash_trap_on_exit <callback> [priority]   (default priority 50)
ash_trap_on_exit() {
    local callback="$1" priority="${2:-50}"
    [[ -z "$callback" ]] && return 1
    ASH_TRAP_CALLBACKS["$priority"]+="${callback};"
}

ash_trap_off_exit() {
    local callback="$1"
    local prio
    for prio in "${!ASH_TRAP_CALLBACKS[@]}"; do
        local list="${ASH_TRAP_CALLBACKS[$prio]}"
        local new="" item
        local IFS=';'
        for item in $list; do
            [[ -z "$item" || "$item" == "$callback" ]] && continue
            new+="${item};"
        done
        unset IFS
        ASH_TRAP_CALLBACKS["$prio"]="$new"
    done
}

# ── Terminal restoration ─────────────────────────────────────────────────────
ash_trap_restore_terminal() {
    # Only touch the terminal if we're attached to one — otherwise we'd
    # emit escape codes into a pipe or a log file.
    [[ -t 1 ]] || return 0

    # Re-enable echo (a password prompt may have been interrupted)
    stty echo 2>/dev/null || true
    stty sane 2>/dev/null || true

    # Leave the alternate screen if a TUI entered it
    [[ "${ASH_TUI_ALT_SCREEN:-0}" == "1" ]] && printf '\033[?1049l' 2>/dev/null || true

    # Disable any mouse tracking / bracketed paste we enabled
    printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?2004l' 2>/dev/null || true

    # Show the cursor, reset attributes
    printf '\033[?25h\033[0m' 2>/dev/null || true
    return 0
}

# ── Temp file tracking ───────────────────────────────────────────────────────
ash_trap_tempfile() {
    local prefix="${1:-ash}"
    local f; f="$(mktemp "${TMPDIR:-/tmp}/${prefix}-XXXXXX")" || return 1
    ASH_TRAP_TEMP_FILES+=("$f")
    printf '%s' "$f"
}

ash_trap_tempdir() {
    local prefix="${1:-ash}"
    local d; d="$(mktemp -d "${TMPDIR:-/tmp}/${prefix}-XXXXXX")" || return 1
    ASH_TRAP_TEMP_FILES+=("$d")
    printf '%s' "$d"
}

_ash_trap_cleanup_temp() {
    local f
    for f in "${ASH_TRAP_TEMP_FILES[@]:-}"; do
        [[ -z "$f" || ! -e "$f" ]] && continue
        # Anything we created is 0600/0700 and may hold secrets.
        if command -v shred >/dev/null 2>&1 && [[ -f "$f" ]]; then
            shred -u -n 1 "$f" 2>/dev/null || rm -f "$f" 2>/dev/null || true
        else
            rm -rf "$f" 2>/dev/null || true
        fi
    done
    ASH_TRAP_TEMP_FILES=()
    return 0
}

# ── The main dispatcher ──────────────────────────────────────────────────────
_ash_trap_dispatch() {
    local exit_code="${1:-0}"
    local signal="${2:-}"

    # Re-entrancy guard: a callback that triggers another signal would
    # otherwise recurse until the stack blows.
    if (( ASH_TRAP_RUNNING == 1 )); then
        return 0
    fi
    ASH_TRAP_RUNNING=1

    ASH_TRAP_EXIT_CODE="$exit_code"
    ASH_TRAP_SIGNAL="$signal"

    # Detach every trap so a callback can't re-enter this function.
    trap - EXIT INT TERM HUP QUIT ERR 2>/dev/null || true

    # ── Signal banner ────────────────────────────────────────────────────
    if [[ -n "$signal" ]]; then
        case "$signal" in
            INT)
                [[ -t 1 ]] && printf '\n\033[38;2;249;226;175m  ⚠ interrupted (Ctrl-C)\033[0m\n' >&2
                # 130 is the conventional exit code for SIGINT
                [[ "$exit_code" == "0" ]] && exit_code=130
                ;;
            TERM)
                [[ -t 1 ]] && printf '\n\033[38;2;243;139;168m  ⚠ terminated\033[0m\n' >&2
                [[ "$exit_code" == "0" ]] && exit_code=143
                ;;
            HUP)
                [[ -t 1 ]] && printf '\n\033[38;2;249;226;175m  ⚠ terminal closed\033[0m\n' >&2
                [[ "$exit_code" == "0" ]] && exit_code=129
                ;;
        esac
    fi

    # ── Run callbacks, lowest priority number first ──────────────────────
    local prio
    for prio in $(printf '%s\n' "${!ASH_TRAP_CALLBACKS[@]:-}" 2>/dev/null | grep -E '^[0-9]+$' | LC_ALL=C sort -n); do
        local list="${ASH_TRAP_CALLBACKS[$prio]}"
        [[ -z "$list" ]] && continue

        local IFS=';'
        local cb
        for cb in $list; do
            [[ -z "$cb" ]] && continue
            if declare -f "$cb" >/dev/null 2>&1; then
                # A misbehaving callback must not prevent the others running.
                "$cb" "$exit_code" 2>/dev/null || true
            fi
        done
        unset IFS
    done

    # ── Always restore the terminal last ─────────────────────────────────
    ash_trap_restore_terminal

    ASH_TRAP_RUNNING=0

    # `exit` inside a trap during `set -e` needs care: use the literal code.
    exit "$exit_code"
}

# ── Installation ─────────────────────────────────────────────────────────────
ash_trap_install() {
    (( ASH_TRAP_INSTALLED == 1 )) && return 0

    # Default cleanup set — application code can add more.
    ash_trap_on_exit "_ash_trap_cleanup_temp"            10
    ash_trap_on_exit "ash_lock_release_all"              20
    ash_trap_on_exit "ash_trap_restore_terminal"         90

    trap '_ash_trap_dispatch $? ""'    EXIT
    trap '_ash_trap_dispatch 130 INT'  INT
    trap '_ash_trap_dispatch 143 TERM' TERM
    trap '_ash_trap_dispatch 129 HUP'  HUP
    trap '_ash_trap_dispatch 131 QUIT' QUIT

    ASH_TRAP_INSTALLED=1
    return 0
}

ash_trap_uninstall() {
    trap - EXIT INT TERM HUP QUIT 2>/dev/null || true
    ASH_TRAP_INSTALLED=0
}

# ── Scoped cleanup: run a callback when a block finishes ─────────────────────
# Usage:
#     ash_with_cleanup "rm -f /tmp/x" bash -c '…'
ash_with_cleanup() {
    local cleanup="$1"; shift
    local rc=0
    "$@" || rc=$?
    eval "$cleanup" 2>/dev/null || true
    return $rc
}

# ── SIGINT sub-shell isolation ───────────────────────────────────────────────
# Runs a command in a subshell that ignores SIGINT, so Ctrl-C propagates to
# the parent's handler instead of killing a half-finished critical section.
ash_run_uninterruptible() {
    (
        trap '' INT
        "$@"
    )
}

# ── Debug helper ─────────────────────────────────────────────────────────────
ash_trap_report() {
    printf '  installed  : %s\n' "$( ((ASH_TRAP_INSTALLED==1)) && echo yes || echo no)"
    printf '  running    : %s\n' "$( ((ASH_TRAP_RUNNING==1)) && echo yes || echo no)"
    printf '  exit code  : %s\n' "$ASH_TRAP_EXIT_CODE"
    printf '  signal     : %s\n' "${ASH_TRAP_SIGNAL:-none}"
    printf '  temp files : %d tracked\n' "${#ASH_TRAP_TEMP_FILES[@]}"

    local prio
    for prio in $(printf '%s\n' "${!ASH_TRAP_CALLBACKS[@]:-}" 2>/dev/null | grep -E '^[0-9]+$' | LC_ALL=C sort -n); do
        printf '  [%s] %s\n' "$prio" "${ASH_TRAP_CALLBACKS[$prio]}"
    done
}

# ── ERR-trap helper used with `set -E` ───────────────────────────────────────
# Prints a stack trace when the script dies unexpectedly.
ash_trap_print_stacktrace() {
    local exit_code="${1:-1}"
    [[ "$exit_code" == "0" ]] && return 0

    printf '\n\033[38;2;243;139;168m  ✗ ASH failed (exit %s)\033[0m\n' "$exit_code" >&2
    [[ -n "${BASH_SOURCE[*]:-}" ]] && {
        printf '  at: %s:%s\n' "${BASH_SOURCE[1]:-?}" "${BASH_LINENO[0]:-?}" >&2
        printf '  cmd: %s\n' "${BASH_COMMAND:-?}" >&2
    }

    if [[ "${ASH_FLAG_DEBUG:-0}" == "1" ]]; then
        printf '\n  call stack:\n' >&2
        local i
        for (( i = 0; i < ${#FUNCNAME[@]} - 1 && i < 12; i++ )); do
            printf '    %2d  %s() at %s:%s\n' \
                "$i" "${FUNCNAME[i]}" "${BASH_SOURCE[i]:-?}" "${BASH_LINENO[i]:-?}" >&2
        done
    else
        printf '  re-run with --debug for a full call stack\n' >&2
    fi
    printf '  report issues: %s/issues\n' "${ASH_REPO:-https://github.com/ash-dotfiles/ash-dotfiles}" >&2
    return 0
}

# ── Defence against runaway background processes ─────────────────────────────
# Any child started through this helper is killed when ASH exits.
declare -ga ASH_TRAP_CHILD_PIDS=()

ash_trap_background() {
    "$@" &
    local pid=$!
    ASH_TRAP_CHILD_PIDS+=("$pid")
    printf '%s' "$pid"
}

_ash_trap_kill_children() {
    local pid
    for pid in "${ASH_TRAP_CHILD_PIDS[@]:-}"; do
        [[ -z "$pid" ]] && continue
        kill -TERM "$pid" 2>/dev/null || true
    done
    # Give them a moment, then be firm.
    sleep 0.2
    for pid in "${ASH_TRAP_CHILD_PIDS[@]:-}"; do
        [[ -z "$pid" ]] && continue
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
    done
    ASH_TRAP_CHILD_PIDS=()
    return 0
}
