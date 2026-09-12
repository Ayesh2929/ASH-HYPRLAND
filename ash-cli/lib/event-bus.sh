#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📡 ASH EVENT BUS — in-process pub/sub + cross-process journal               ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Two delivery planes, one API:                                                ║
# ║    • In-process  — handlers are bash functions; zero fork overhead            ║
# ║    • Cross-process — events are appended to a journal file that any `ash`     ║
# ║      invocation tails, enabling `ash theme apply` in one terminal to notify   ║
# ║      a waybar listener in another.                                            ║
# ║                                                                               ║
# ║  Patterns are glob-style with hierarchical matching:                          ║
# ║      theme.*        theme.applied, theme.created, theme.removed               ║
# ║      *.changed      config.changed, json.changed, wallpaper.changed           ║
# ║      **             every event                                               ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_EVENT_BUS_LOADED:-}" ]] && return 0
readonly _ASH_EVENT_BUS_LOADED=1
readonly ASH_EVENT_BUS_VERSION="5.0.0"

: "${ASH_EVENT_JOURNAL:=${ASH_RUNTIME_DIR:-/tmp/ash}/events.journal}"
: "${ASH_EVENT_HISTORY_SIZE:=500}"

# Pattern -> "handler1;handler2;…"   (functions or external commands)
declare -gA ASH_EVENT_HANDLERS=()
# Ring buffer of the most recent events for `ash events --history`
declare -ga ASH_EVENT_HISTORY=()
# Timestamp of the last emitted event, for rate limiting / debounce
declare -g ASH_EVENT_LAST_TS=0
declare -g ASH_EVENT_COUNT=0
# When set, ash_event_emit only logs to the journal (no handler dispatch).
: "${ASH_EVENT_SILENT:=0}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  PATTERN MATCHING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Glob match on dotted namespaces where `*` never crosses a `.` boundary
# and `**` matches everything.
_ash_event_matches() {
    local event="$1" pattern="$2"

    [[ "$pattern" == "**" || "$pattern" == "*" ]] && return 0
    [[ "$event" == "$pattern" ]] && return 0

    case "$pattern" in
        *'**'*) return 0 ;;
    esac

    # Translate `*` to a segment-local wildcard: [^.]*
    local regex="^${pattern//./\\.}$"
    regex="${regex//\*/[^.]*}"
    [[ "$event" =~ $regex ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  SUBSCRIPTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_event_on <pattern> <handler> [priority] [id]
# `handler` may be a bash function name or a shell command string.
ash_event_on() {
    local pattern="$1" handler="$2" priority="${3:-50}" id="${4:-}"

    if [[ -z "$id" ]]; then
        id="$(printf '%s' "${pattern}:${handler}" | cksum | awk '{print $1}')"
    fi

    # Stored as "priority|id|handler" so we can sort deterministically.
    ASH_EVENT_HANDLERS["$pattern"]+="${priority}|${id}|${handler}"$'\n'
    return 0
}

# ash_event_off <pattern> <handler-or-id>
ash_event_off() {
    local pattern="$1" target="$2"
    [[ -n "${ASH_EVENT_HANDLERS[$pattern]:-}" ]] || return 1

    local kept="" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        local _prio _id _handler
        IFS='|' read -r _prio _id _handler <<< "$line"
        if [[ "$_id" == "$target" || "$_handler" == "$target" ]]; then
            continue
        fi
        kept+="${line}"$'\n'
    done <<< "${ASH_EVENT_HANDLERS[$pattern]}"

    ASH_EVENT_HANDLERS["$pattern"]="$kept"
    return 0
}

ash_event_off_all() {
    local pattern="${1:-}"
    if [[ -n "$pattern" ]]; then
        unset 'ASH_EVENT_HANDLERS[$pattern]'
    else
        ASH_EVENT_HANDLERS=()
    fi
    return 0
}

ash_event_listeners() {
    local pattern
    for pattern in "${!ASH_EVENT_HANDLERS[@]}"; do
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            local prio id handler
            IFS='|' read -r prio id handler <<< "$line"
            printf '%s|%s|%s|%s\n' "$pattern" "$prio" "$id" "$handler"
        done <<< "${ASH_EVENT_HANDLERS[$pattern]}"
    done | LC_ALL=C sort
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 3  EMISSION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_event_emit <name> [key=value …]
ash_event_emit() {
    local event="${1:-}"; shift || true
    [[ -z "$event" ]] && return 1

    local ts; ts="$(date +%s.%N 2>/dev/null || date +%s)"
    ASH_EVENT_LAST_TS="$ts"
    (( ASH_EVENT_COUNT += 1 ))

    # ── Journal (cross-process plane) ────────────────────────────────────
    if [[ -n "${ASH_EVENT_JOURNAL:-}" ]]; then
        mkdir -p "$(dirname "$ASH_EVENT_JOURNAL")" 2>/dev/null || true
        {
            printf '%s\t%s\t%s\t%s\n' "$ts" "$$" "${ASH_TASK_NAME:-${0##*/}}" "$event"
            local kv
            for kv in "$@"; do printf '  %s\n' "$kv"; done
        } >> "$ASH_EVENT_JOURNAL" 2>/dev/null || true

        # Trim the journal when it grows past ~1 MiB to keep tails cheap.
        local jsize
        jsize="$(stat -c %s "$ASH_EVENT_JOURNAL" 2>/dev/null || echo 0)"
        if (( jsize > 1048576 )); then
            tail -c 524288 "$ASH_EVENT_JOURNAL" > "${ASH_EVENT_JOURNAL}.tmp" 2>/dev/null \
                && mv -f "${ASH_EVENT_JOURNAL}.tmp" "$ASH_EVENT_JOURNAL" 2>/dev/null || true
        fi
    fi

    # ── History ring buffer (in-process plane) ───────────────────────────
    ASH_EVENT_HISTORY+=("${ts}|${event}|${*:-}")
    while (( ${#ASH_EVENT_HISTORY[@]} > ASH_EVENT_HISTORY_SIZE )); do
        ASH_EVENT_HISTORY=("${ASH_EVENT_HISTORY[@]:1}")
    done

    # ── Dispatch to handlers ─────────────────────────────────────────────
    [[ "${ASH_EVENT_SILENT:-0}" == "1" ]] && return 0

    local pattern
    for pattern in "${!ASH_EVENT_HANDLERS[@]}"; do
        _ash_event_matches "$event" "$pattern" || continue

        # Highest priority first (lower number = earlier)
        local -a ordered
        mapfile -t ordered < <(
            while IFS= read -r line || [[ -n "$line" ]]; do
                [[ -z "$line" ]] && continue
                printf '%s\n' "$line"
            done <<< "${ASH_EVENT_HANDLERS[$pattern]}" | LC_ALL=C sort -t'|' -k1,1n
        )

        local entry
        for entry in "${ordered[@]}"; do
            [[ -z "$entry" ]] && continue
            local prio id handler
            IFS='|' read -r prio id handler <<< "$entry"
            [[ -z "$handler" ]] && continue

            if declare -f "$handler" >/dev/null 2>&1; then
                # Handler failures must never take down the emitter.
                "$handler" "$event" "$@" 2>/dev/null || \
                    ash_log_debug "event handler '${handler}' failed for ${event}" 2>/dev/null || true
            else
                # Treat as an external command template.
                #   "notify-send 'Theme' \"\$ASH_EVENT_NAME\"" — vars are exported below.
                ASH_EVENT_NAME="$event" ASH_EVENT_TS="$ts" \
                    bash -c "$handler" 2>/dev/null || true
            fi
        done
    done

    return 0
}

# Emit synchronously and wait for every handler to finish.
ash_event_emit_sync() { ash_event_emit "$@"; }

# Coalesce bursts: only emit if the last event of this name was > window ago.
ash_event_emit_debounced() {
    local event="$1" window="${2:-1}"; shift 2 || true
    local now; now="$(date +%s)"
    local last_key="ASH_EVENT_DEBOUNCE_${event//[^A-Za-z0-9]/_}"
    local last="${!last_key:-0}"

    if (( now - last < window )); then
        return 1
    fi
    printf -v "$last_key" '%s' "$now"
    ash_event_emit "$event" "$@"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 4  CROSS-PROCESS: JOURNAL READING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_event_wait <pattern> [timeout] — blocks until a matching event appears.
# Exits 124 on timeout (same convention as `timeout(1)`).
ash_event_wait() {
    local pattern="$1" timeout="${2:-30}"
    local start; start="$(date +%s)"

    [[ -f "$ASH_EVENT_JOURNAL" ]] || touch "$ASH_EVENT_JOURNAL" 2>/dev/null || return 1

    # Start from the current end of file; we only care about the future.
    local pos
    pos="$(stat -c %s "$ASH_EVENT_JOURNAL" 2>/dev/null || echo 0)"

    while :; do
        local size
        size="$(stat -c %s "$ASH_EVENT_JOURNAL" 2>/dev/null || echo 0)"
        if (( size > pos )); then
            local chunk
            chunk="$(tail -c "+$(( pos + 1 ))" "$ASH_EVENT_JOURNAL" 2>/dev/null)"
            pos="$size"

            local line ev
            while IFS= read -r line || [[ -n "$line" ]]; do
                [[ "$line" == $'\t'* || -z "$line" ]] && continue
                ev="$(printf '%s' "$line" | awk -F'\t' 'NF>=4 {print $4}')"
                [[ -z "$ev" ]] && continue
                if _ash_event_matches "$ev" "$pattern"; then
                    printf '%s\n' "$line"
                    return 0
                fi
            done <<< "$chunk"
        fi

        local elapsed=$(( $(date +%s) - start ))
        (( elapsed >= timeout )) && return 124
        sleep 0.1
    done
}

# ash_event_tail <pattern> — follows the journal forever, printing matches.
ash_event_tail() {
    local pattern="${1:-**}"
    ash_log_info "tailing events matching '${pattern}' (Ctrl-C to stop)" 2>/dev/null || true
    touch "$ASH_EVENT_JOURNAL" 2>/dev/null || true
    tail -F "$ASH_EVENT_JOURNAL" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == $'\t'* ]]; then
            printf '%s\n' "$line"; continue
        fi
        local ev; ev="$(printf '%s' "$line" | awk -F'\t' 'NF>=4 {print $4}')"
        [[ -z "$ev" ]] && continue
        _ash_event_matches "$ev" "$pattern" && printf '%s\n' "$line"
    done
}

# ── History intro­spection ───────────────────────────────────────────────────
ash_event_history() {
    local pattern="${1:-**}" limit="${2:-50}"
    local entry count=0
    for (( idx = ${#ASH_EVENT_HISTORY[@]} - 1; idx >= 0; idx-- )); do
        entry="${ASH_EVENT_HISTORY[idx]}"
        local _ts ev
        IFS='|' read -r _ts ev _ <<< "$entry"
        _ash_event_matches "$ev" "$pattern" || continue
        printf '%s\n' "$entry"
        (( count += 1 ))
        (( count >= limit )) && break
    done
}

ash_event_journal_read() {
    local pattern="${1:-**}" limit="${2:-100}"
    [[ -f "$ASH_EVENT_JOURNAL" ]] || return 0
    tail -n "$(( limit * 8 ))" "$ASH_EVENT_JOURNAL" 2>/dev/null | awk -F'\t' -v n="$limit" '
        NF>=4 { printf "%s|%s|%s|%s\n", $1, $2, $3, $4 }
    ' | { local printed=0 l
        while IFS= read -r l || [[ -n "$l" ]]; do
            local ev="${l##*|}"
            if [[ "$ev" == "$pattern" || "$pattern" == "**" ]]; then
                printf '%s\n' "$l"; (( printed += 1 ))
                (( printed >= limit )) && break
            fi
        done; }
}

ash_event_stats() {
    printf 'listeners   : %d patterns\n' "${#ASH_EVENT_HANDLERS[@]}"
    printf 'emitted     : %d events this process\n' "$ASH_EVENT_COUNT"
    printf 'history     : %d buffered\n' "${#ASH_EVENT_HISTORY[@]}"
    if [[ -f "$ASH_EVENT_JOURNAL" ]]; then
        printf 'journal     : %s (%s events)\n' \
            "$ASH_EVENT_JOURNAL" "$(grep -c $'\t' "$ASH_EVENT_JOURNAL" 2>/dev/null || echo 0)"
    else
        printf 'journal     : (not yet created)\n'
    fi
}

# ── Standard event name registry (documentation-as-code) ─────────────────────
# Keeping names centralised prevents typos like "theme.aplied" silently
# producing an event nobody listens to.
readonly -a ASH_EVENT_NAMES=(
    # lifecycle
    "ash.start" "ash.exit" "ash.signal"
    # config
    "config.loaded" "config.changed" "config.reloaded" "config.unset"
    # theme
    "theme.apply.start" "theme.applied" "theme.failed"
    "theme.created" "theme.removed" "theme.imported" "theme.exported"
    "theme.changed" "theme.preview"
    # wallpaper
    "wallpaper.changed" "wallpaper.downloaded" "wallpaper.generated"
    # color
    "color.extracted" "color.generated" "color.harmonized" "color.contrast.warn"
    # mode
    "mode.changed" "mode.reset"
    # plugin
    "plugin.installed" "plugin.removed" "plugin.enabled" "plugin.disabled"
    "plugin.updated" "plugin.failed"
    # snapshot / backup
    "snapshot.created" "snapshot.restored" "snapshot.deleted" "snapshot.pruned"
    "backup.created" "backup.failed"
    # system
    "system.battery.low" "system.battery.critical" "system.ac.connected"
    "system.network.up" "system.network.down" "system.bluetooth.connected"
    "system.monitor.connected" "system.monitor.disconnected"
    "system.suspend" "system.resume" "system.lock" "system.unlock"
    "system.idle" "system.thermal.warn"
    # ui
    "cache.stored" "cache.expired" "cache.pruned" "cache.cleared" "cache.invalidated"
    "json.changed" "lock.acquired" "lock.released" "lock.stale_broken"
    "hook.pre" "hook.post" "hook.failed"
    "widget.update" "bar.reload" "osd.show" "notification.sent"
)

ash_event_is_known() {
    local e
    for e in "${ASH_EVENT_NAMES[@]}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}
