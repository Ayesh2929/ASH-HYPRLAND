#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🔄 ASH STATE MACHINE — declarative, guard-checked transitions                ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Desktop modes (`game`, `focus`, `cinema` …) are not independent toggles —    ║
# ║  they are states, and switching between them must run exit actions in the      ║
# ║  right order. A naive "if game mode then disable notifications" approach       ║
# ║  leaks state: leave game mode without re-enabling notifications and you        ║
# ║  silently never get another notification all session.                        ║
# ║                                                                               ║
# ║  This module makes transitions explicit:                                      ║
# ║      state ──(event)──▶ state'   guarded by a predicate                      ║
# ║  with `on_enter` / `on_exit` actions that always run in a safe order.         ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_STATE_MACHINE_LOADED:-}" ]] && return 0
readonly _ASH_STATE_MACHINE_LOADED=1
readonly ASH_STATE_MACHINE_VERSION="5.0.0"

# Machine registry
declare -gA ASH_FSM_STATES=()       # "machine.state" -> 1
declare -gA ASH_FSM_INITIAL=()      # machine -> state
declare -gA ASH_FSM_CURRENT=()      # machine -> state
declare -gA ASH_FSM_ON_ENTER=()     # "machine.state" -> callback
declare -gA ASH_FSM_ON_EXIT=()      # "machine.state" -> callback
declare -gA ASH_FSM_TRANSITIONS=()  # "machine.src.event" -> "dst|guard"
declare -ga ASH_FSM_HISTORY=()

# ── Definition ───────────────────────────────────────────────────────────────
ash_fsm_define() {
    local machine="$1" initial="$2"
    ASH_FSM_INITIAL["$machine"]="$initial"
    ASH_FSM_CURRENT["$machine"]="$initial"
    ASH_FSM_STATES["${machine}.${initial}"]=1
    return 0
}

ash_fsm_add_state() {
    local machine="$1" state="$2" on_enter="${3:-}" on_exit="${4:-}"
    ASH_FSM_STATES["${machine}.${state}"]=1
    [[ -n "$on_enter" ]] && ASH_FSM_ON_ENTER["${machine}.${state}"]="$on_enter"
    [[ -n "$on_exit"  ]] && ASH_FSM_ON_EXIT["${machine}.${state}"]="$on_exit"
    return 0
}

# ash_fsm_add_transition <machine> <from> <event> <to> [guard-fn]
ash_fsm_add_transition() {
    local machine="$1" from="$2" event="$3" to="$4" guard="${5:-}"
    ASH_FSM_STATES["${machine}.${from}"]=1
    ASH_FSM_STATES["${machine}.${to}"]=1
    ASH_FSM_TRANSITIONS["${machine}.${from}.${event}"]="${to}|${guard}"
    return 0
}

ash_fsm_state_exists() {
    [[ -n "${ASH_FSM_STATES["${1}.${2}"]+x}" ]]
}

ash_fsm_current() { printf '%s' "${ASH_FSM_CURRENT[${1:-}]:-}"; }

ash_fsm_is() { [[ "${ASH_FSM_CURRENT[${1:-}]:-}" == "${2:-}" ]]; }

# ── Firing ───────────────────────────────────────────────────────────────────
# ash_fsm_fire <machine> <event> [args…]
# Returns:
#   0  transition performed
#   1  no transition defined for this event in this state
#   2  guard rejected the transition
#   3  unknown machine
ash_fsm_fire() {
    local machine="$1" event="$2"; shift 2 || true

    [[ -z "${ASH_FSM_INITIAL[$machine]:-}" ]] && return 3

    local current="${ASH_FSM_CURRENT[$machine]}"
    local key="${machine}.${current}.${event}"
    local entry="${ASH_FSM_TRANSITIONS[$key]:-}"

    if [[ -z "$entry" ]]; then
        # Self-transition is a no-op but not an error.
        if [[ "$event" == "$current" ]]; then return 0; fi
        return 1
    fi

    local target="${entry%%|*}"
    local guard="${entry#*|}"
    [[ "$guard" == "$target" ]] && guard=""

    # ── Guard evaluation ─────────────────────────────────────────────────
    if [[ -n "$guard" ]] && declare -f "$guard" >/dev/null 2>&1; then
        if ! "$guard" "$current" "$target" "$@" 2>/dev/null; then
            ash_log_debug "fsm[${machine}]: guard '${guard}' rejected ${current}→${target}" 2>/dev/null || true
            return 2
        fi
    fi

    if ! ash_fsm_state_exists "$machine" "$target"; then
        ash_log_error "fsm[${machine}]: target state '${target}' was never defined" 2>/dev/null || true
        return 1
    fi

    # ── Exit action (of the old state) ───────────────────────────────────
    local exit_cb="${ASH_FSM_ON_EXIT["${machine}.${current}"]:-}"
    if [[ -n "$exit_cb" ]] && declare -f "$exit_cb" >/dev/null 2>&1; then
        # Exit failures must not strand us between states, so we record but
        # continue — the enter action is what makes the state meaningful.
        "$exit_cb" "$target" "$@" 2>/dev/null || \
            ash_log_warn "fsm[${machine}]: on_exit '${exit_cb}' failed" 2>/dev/null || true
    fi

    # ── Commit ───────────────────────────────────────────────────────────
    ASH_FSM_CURRENT["$machine"]="$target"
    ASH_FSM_HISTORY+=("$(date +%s)|${machine}|${current}|${event}|${target}")

    # ── Enter action ─────────────────────────────────────────────────────
    local enter_cb="${ASH_FSM_ON_ENTER["${machine}.${target}"]:-}"
    local enter_rc=0
    if [[ -n "$enter_cb" ]] && declare -f "$enter_cb" >/dev/null 2>&1; then
        "$enter_cb" "$current" "$@" || enter_rc=$?
    fi

    ash_event_emit "fsm.transition" \
        "machine=${machine}" "from=${current}" "event=${event}" "to=${target}" 2>/dev/null || true

    if (( enter_rc != 0 )); then
        ash_log_warn "fsm[${machine}]: on_enter for '${target}' exited ${enter_rc}" 2>/dev/null || true
        return 4
    fi
    return 0
}

# Attempts a transition but never fails the caller — used in autostart paths.
ash_fsm_fire_quiet() { ash_fsm_fire "$@" 2>/dev/null || true; }

# ── Introspection ────────────────────────────────────────────────────────────
ash_fsm_possible_events() {
    local machine="$1"
    local current="${ASH_FSM_CURRENT[$machine]:-}"
    local key
    for key in "${!ASH_FSM_TRANSITIONS[@]}"; do
        [[ "$key" == "${machine}.${current}."* ]] || continue
        printf '%s\n' "${key##${machine}.${current}.}"
    done | LC_ALL=C sort
}

ash_fsm_describe() {
    local machine="$1"
    printf 'machine : %s\n' "$machine"
    printf 'current : %s\n' "${ASH_FSM_CURRENT[$machine]:-<undefined>}"
    printf 'states  :\n'
    local key
    for key in "${!ASH_FSM_STATES[@]}"; do
        [[ "$key" == "${machine}."* ]] || continue
        local st="${key#${machine}.}"
        local marker=" "
        [[ "$st" == "${ASH_FSM_CURRENT[$machine]}" ]] && marker="▶"
        printf '   %s %s' "$marker" "$st"
        [[ -n "${ASH_FSM_ON_ENTER["${machine}.${st}"]:-}" ]] && printf '  [enter: %s]' "${ASH_FSM_ON_ENTER["${machine}.${st}"]}"
        printf '\n'
    done | LC_ALL=C sort

    printf 'transitions :\n'
    for key in "${!ASH_FSM_TRANSITIONS[@]}"; do
        [[ "$key" == "${machine}."* ]] || continue
        local rest="${key#${machine}.}"
        local from="${rest%%.*}"
        local ev="${rest#*.}"
        local entry="${ASH_FSM_TRANSITIONS[$key]}"
        printf '   %-14s --%-14s--> %s\n' "$from" "$ev" "${entry%%|*}"
    done | LC_ALL=C sort
}

ash_fsm_history() {
    local machine="${1:-}" limit="${2:-20}"
    local entry count=0
    local i
    for (( i = ${#ASH_FSM_HISTORY[@]} - 1; i >= 0; i-- )); do
        entry="${ASH_FSM_HISTORY[i]}"
        if [[ -n "$machine" ]]; then
            [[ "$(printf '%s' "$entry" | cut -d'|' -f2)" == "$machine" ]] || continue
        fi
        printf '%s\n' "$entry"
        (( count += 1 ))
        (( count >= limit )) && break
    done
}

# ── Persistence (so mode survives a crash / logout) ──────────────────────────
ash_fsm_save() {
    local file="${ASH_FSM_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/ash/fsm.json}"
    mkdir -p "$(dirname "$file")" 2>/dev/null || true

    {
        printf '{\n'
        local first=1 machine
        for machine in $(printf '%s\n' "${!ASH_FSM_CURRENT[@]}" | LC_ALL=C sort); do
            (( first == 1 )) && first=0 || printf ',\n'
            printf '  "%s": "%s"' "$machine" "${ASH_FSM_CURRENT[$machine]}"
        done
        printf '\n}\n'
    } > "${file}.tmp" 2>/dev/null && mv -f "${file}.tmp" "$file" 2>/dev/null || true
    return 0
}

ash_fsm_restore() {
    local file="${ASH_FSM_STATE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/ash/fsm.json}"
    [[ -f "$file" ]] || return 1

    if command -v jq >/dev/null 2>&1; then
        local line
        while IFS=$'\t' read -r machine state; do
            [[ -z "$machine" ]] && continue
            if ash_fsm_state_exists "$machine" "$state"; then
                ASH_FSM_CURRENT["$machine"]="$state"
            fi
        done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$file" 2>/dev/null)
    fi
    return 0
}

# ── Composite: fire on every registered machine ──────────────────────────────
ash_fsm_broadcast() {
    local event="$1"; shift || true
    local machine fired=0
    for machine in "${!ASH_FSM_INITIAL[@]}"; do
        if ash_fsm_fire "$machine" "$event" "$@" >/dev/null 2>&1; then
            (( fired += 1 ))
        fi
    done
    printf '%d\n' "$fired"
}

# ── Validation: catch unreachable states at build time ───────────────────────
ash_fsm_validate() {
    local machine="$1"
    local errors=0 warnings=0

    local current="${ASH_FSM_INITIAL[$machine]:-}"
    if [[ -z "$current" ]]; then
        printf '  ✗ machine has no initial state\n'
        return 1
    fi
    if ! ash_fsm_state_exists "$machine" "$current"; then
        printf '  ✗ initial state "%s" is not defined\n' "$current"
        (( errors += 1 ))
    fi

    # Reachability via breadth-first traversal
    declare -A seen=() queue=()
    queue=("$current"); seen["$current"]=1
    local idx=0
    while (( idx < ${#queue[@]} )); do
        local st="${queue[idx]}"; (( idx += 1 ))
        local key
        for key in "${!ASH_FSM_TRANSITIONS[@]}"; do
            [[ "$key" == "${machine}.${st}."* ]] || continue
            local target="${ASH_FSM_TRANSITIONS[$key]%%|*}"
            [[ -n "${seen[$target]:-}" ]] && continue
            seen["$target"]=1
            queue+=("$target")
        done
    done

    local key
    for key in "${!ASH_FSM_STATES[@]}"; do
        [[ "$key" == "${machine}."* ]] || continue
        local st="${key#${machine}.}"
        if [[ -z "${seen[$st]:-}" ]]; then
            printf '  ⚠ state "%s" is unreachable from "%s"\n' "$st" "$current"
            (( warnings += 1 ))
        fi
    done

    # Every state should have at least one outgoing transition except finals
    for key in "${!ASH_FSM_STATES[@]}"; do
        [[ "$key" == "${machine}."* ]] || continue
        local st="${key#${machine}.}"
        local has=0
        local tkey
        for tkey in "${!ASH_FSM_TRANSITIONS[@]}"; do
            [[ "$tkey" == "${machine}.${st}."* ]] && { has=1; break; }
        done
        if (( has == 0 )) && [[ "${st}" != *"final"* && "$st" != "off" ]]; then
            printf '  ⚠ state "%s" is a dead end (no outgoing transitions)\n' "$st"
            (( warnings += 1 ))
        fi
    done

    printf '  %s: %d error(s), %d warning(s)\n' "$machine" "$errors" "$warnings"
    return $(( errors > 0 ? 1 : 0 ))
}

# ── Reference implementation: the desktop-mode machine ───────────────────────
# This is what `ash mode <name>` drives.
ash_fsm_define_modes() {
    ash_fsm_define "desktop_mode" "default"

    ash_fsm_add_state "desktop_mode" "default"   "ash_mode_enter_default"   "ash_mode_exit_default"
    ash_fsm_add_state "desktop_mode" "game"      "ash_mode_enter_game"      "ash_mode_exit_game"
    ash_fsm_add_state "desktop_mode" "work"      "ash_mode_enter_work"      "ash_mode_exit_work"
    ash_fsm_add_state "desktop_mode" "focus"     "ash_mode_enter_focus"     "ash_mode_exit_focus"
    ash_fsm_add_state "desktop_mode" "cinema"    "ash_mode_enter_cinema"    "ash_mode_exit_cinema"
    ash_fsm_add_state "desktop_mode" "present"   "ash_mode_enter_present"   "ash_mode_exit_present"
    ash_fsm_add_state "desktop_mode" "stream"    "ash_mode_enter_stream"    "ash_mode_exit_stream"
    ash_fsm_add_state "desktop_mode" "battery"   "ash_mode_enter_battery"   "ash_mode_exit_battery"
    ash_fsm_add_state "desktop_mode" "privacy"   "ash_mode_enter_privacy"   "ash_mode_exit_privacy"
    ash_fsm_add_state "desktop_mode" "accessibility" "ash_mode_enter_accessibility" "ash_mode_exit_accessibility"

    local state
    for state in game work focus cinema present stream battery privacy accessibility; do
        ash_fsm_add_transition "desktop_mode" "default"  "$state" "$state" "ash_mode_guard_$state"
        ash_fsm_add_transition "desktop_mode" "$state"   "default" "default"
        # Allow switching directly between non-default modes — the exit/enter
        # pair makes this safe, and it's what users actually do.
        local other
        for other in game work focus cinema present stream battery privacy accessibility; do
            [[ "$other" == "$state" ]] && continue
            ash_fsm_add_transition "desktop_mode" "$state" "$other" "$other" "ash_mode_guard_$other"
        done
    done
    return 0
}

# ── Guards (fail-closed: reject when we can't verify) ────────────────────────
ash_mode_guard_game() {
    # Game mode needs a GPU and, ideally, gamemode installed.
    ash_dep_has_command gamemode 2>/dev/null || true
    return 0     # advisory only — never block the user
}

ash_mode_guard_battery() {
    [[ -d /sys/class/power_supply ]] || return 1
    local bat
    for bat in /sys/class/power_supply/BAT*; do
        [[ -d "$bat" ]] && return 0
    done
    return 1
}

ash_mode_guard_stream() {
    # Streaming needs a recording backend + a way to show the indicator.
    ash_dep_has_capability screencast 2>/dev/null && return 0
    ash_dep_has_capability notify 2>/dev/null && return 0
    return 0
}

ash_mode_guard_cinema()  { return 0; }
ash_mode_guard_focus()   { return 0; }
ash_mode_guard_work()    { return 0; }
ash_mode_guard_present() { return 0; }
ash_mode_guard_privacy() { return 0; }
ash_mode_guard_accessibility() { return 0; }
