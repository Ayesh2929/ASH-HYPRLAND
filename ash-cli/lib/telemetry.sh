#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📈 ASH TELEMETRY — local-first, opt-in, zero-network by default              ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Privacy contract (enforced by the code, not just the docs):                  ║
# ║    1. `telemetry = false` (the default) means NOTHING is written, ever.       ║
# ║    2. Even when enabled, data stays in ~/.local/share/ash/telemetry/.         ║
# ║       There is no network code in this file. Uploading is a separate,          ║
# ║       explicitly-invoked command (`ash analytics upload`) that the user        ║
# ║       must run by hand.                                                       ║
# ║    3. No command arguments, file paths, hostnames, usernames or window        ║
# ║       titles are ever recorded — only command names, durations and counts.    ║
# ║    4. `ash telemetry purge` deletes everything immediately.                   ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_TELEMETRY_LOADED:-}" ]] && return 0
readonly _ASH_TELEMETRY_LOADED=1
readonly ASH_TELEMETRY_VERSION="5.0.0"

: "${ASH_TELEMETRY_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/ash/telemetry}"
: "${ASH_TELEMETRY_FILE:=${ASH_TELEMETRY_DIR}/events.ndjson}"
: "${ASH_TELEMETRY_MAX_BYTES:=5242880}"      # 5 MiB before rotation

_ash_telemetry_enabled() {
    # 1. Environment override wins (CI, debugging)
    case "${ASH_TELEMETRY:-}" in
        1|true|yes|on)  return 0 ;;
        0|false|no|off) return 1 ;;
    esac

    # 2. Config file
    if declare -f ash_config_get_bool >/dev/null 2>&1; then
        [[ "$(ash_config_get_bool general.telemetry false)" == "true" ]] && return 0
        return 1
    fi

    # 3. Fall back to the marker file
    [[ -f "${ASH_TELEMETRY_DIR}/enabled" ]]
}

# ── Recording ────────────────────────────────────────────────────────────────
_ash_telemetry_rotate() {
    [[ -f "$ASH_TELEMETRY_FILE" ]] || return 0
    local size
    size="$(stat -c %s "$ASH_TELEMETRY_FILE" 2>/dev/null || echo 0)"
    (( size < ASH_TELEMETRY_MAX_BYTES )) && return 0

    mv -f "$ASH_TELEMETRY_FILE" "${ASH_TELEMETRY_FILE}.1" 2>/dev/null || true
    ash_log_debug "telemetry rotated at ${size} bytes" 2>/dev/null || true
}

# Internal: appends one NDJSON record. Never fails the caller.
_ash_telemetry_write() {
    local json="$1"
    _ash_telemetry_enabled || return 0

    mkdir -p "$ASH_TELEMETRY_DIR" 2>/dev/null || return 0
    chmod 700 "$ASH_TELEMETRY_DIR" 2>/dev/null || true

    _ash_telemetry_rotate
    printf '%s\n' "$json" >> "$ASH_TELEMETRY_FILE" 2>/dev/null || true
    chmod 600 "$ASH_TELEMETRY_FILE" 2>/dev/null || true
    return 0
}

# ash_telemetry_record_command <name> [duration_ms] [exit_code]
ash_telemetry_record_command() {
    _ash_telemetry_enabled || return 0

    local name="${1:-}" duration_ms="${2:-}" exit_code="${3:-0}"
    [[ -z "$name" ]] && return 0
    # Sanitise so a crafted command name can't inject JSON.
    name="${name//[^A-Za-z0-9._-]/_}"
    [[ "$duration_ms" =~ ^[0-9]+$ ]] || duration_ms=0
    [[ "$exit_code" =~ ^-?[0-9]+$ ]] || exit_code=0

    _ash_telemetry_write \
        "$(printf '{"t":"cmd","ts":%s,"name":"%s","ms":%s,"rc":%s}' \
            "$(date +%s)" "$name" "$duration_ms" "$exit_code")"
}

# Records a feature being used (theme id, mode id …) — no paths or titles.
ash_telemetry_record_feature() {
    _ash_telemetry_enabled || return 0

    local feature="${1:-}" value="${2:-}"
    [[ -z "$feature" ]] && return 0
    feature="${feature//[^A-Za-z0-9._-]/_}"
    value="${value//[^A-Za-z0-9._-]/_}"

    _ash_telemetry_write \
        "$(printf '{"t":"feature","ts":%s,"feature":"%s","value":"%s"}' \
            "$(date +%s)" "$feature" "$value")"
}

ash_telemetry_record_error() {
    _ash_telemetry_enabled || return 0
    local context="${1:-unknown}"
    context="${context//[^A-Za-z0-9._-]/_}"

    _ash_telemetry_write \
        "$(printf '{"t":"error","ts":%s,"context":"%s","bash":"%s"}' \
            "$(date +%s)" "$context" "${BASH_VERSION%%(*}")"
}

ash_telemetry_record_performance() {
    _ash_telemetry_enabled || return 0
    local operation="${1:-}" ms="${2:-0}"
    [[ -z "$operation" ]] && return 0
    operation="${operation//[^A-Za-z0-9._-]/_}"
    [[ "$ms" =~ ^[0-9]+$ ]] || ms=0

    _ash_telemetry_write \
        "$(printf '{"t":"perf","ts":%s,"op":"%s","ms":%s}' \
            "$(date +%s)" "$operation" "$ms")"
}

# ── Analysis (all local) ─────────────────────────────────────────────────────
# Prints: command|count|total_ms|avg_ms|failures
ash_telemetry_command_stats() {
    local limit="${1:-20}"
    [[ -f "$ASH_TELEMETRY_FILE" ]] || return 0

    if command -v jq >/dev/null 2>&1; then
        jq -rs '
            [ .[] | select(.t == "cmd") ]
            | group_by(.name)
            | map({
                name:   .[0].name,
                count:  length,
                total:  (map(.ms) | add),
                avg:    ((map(.ms) | add) / length | floor),
                fails:  (map(select(.rc != 0)) | length)
              })
            | sort_by(-.count)
            | .[]
            | "\(.name)|\(.count)|\(.total)|\(.avg)|\(.fails)"
        ' "$ASH_TELEMETRY_FILE" 2>/dev/null | head -"$limit"
    else
        # No jq: crude but functional parser for our own known-shape records.
        grep '"t":"cmd"' "$ASH_TELEMETRY_FILE" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
            local name ms rc
            name="$(printf '%s' "$line" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')"
            ms="$(printf '%s' "$line"   | sed -n 's/.*"ms":\([0-9]*\).*/\1/p')"
            rc="$(printf '%s' "$line"   | sed -n 's/.*"rc":\(-\?[0-9]*\).*/\1/p')"
            printf '%s %s %s\n' "$name" "${ms:-0}" "${rc:-0}"
        done | awk '
            { n[$1]++; t[$1]+=$2; if ($3 != 0) f[$1]++ }
            END { for (k in n) printf "%s|%d|%d|%d|%d\n", k, n[k], t[k], t[k]/n[k], f[k]+0 }
        ' | sort -t'|' -k2,2nr | head -"$limit"
    fi
}

ash_telemetry_theme_stats() {
    [[ -f "$ASH_TELEMETRY_FILE" ]] || return 0
    grep '"t":"feature"' "$ASH_TELEMETRY_FILE" 2>/dev/null \
        | sed -n 's/.*"feature":"theme","value":"\([^"]*\)".*/\1/p' \
        | sort | uniq -c | sort -rn
}

ash_telemetry_summary() {
    if [[ ! -f "$ASH_TELEMETRY_FILE" ]]; then
        printf '  no telemetry recorded yet\n'
        return 0
    fi

    local total size days_active
    total="$(wc -l < "$ASH_TELEMETRY_FILE" 2>/dev/null || echo 0)"
    size="$(stat -c %s "$ASH_TELEMETRY_FILE" 2>/dev/null || echo 0)"
    days_active="$(grep -o '"ts":[0-9]*' "$ASH_TELEMETRY_FILE" 2>/dev/null \
        | cut -d: -f2 | while read -r ts; do date -d "@$ts" +%F 2>/dev/null || true; done | sort -u | wc -l)"

    printf '  status      : %s\n' "$(_ash_telemetry_enabled && echo enabled || echo disabled)"
    printf '  records     : %d\n' "$total"
    printf '  on disk     : %s\n' "$(ash_file_human_size "$ASH_TELEMETRY_FILE" 2>/dev/null || echo "${size} B")"
    printf '  active days : %d\n' "$days_active"
    printf '  location    : %s\n' "$ASH_TELEMETRY_FILE"
    printf '  network     : none (upload is manual)\n'
}

# ── Consent management ───────────────────────────────────────────────────────
ash_telemetry_enable() {
    mkdir -p "$ASH_TELEMETRY_DIR" 2>/dev/null || true
    chmod 700 "$ASH_TELEMETRY_DIR" 2>/dev/null || true
    : > "${ASH_TELEMETRY_DIR}/enabled"
    printf 'Telemetry: ENABLED (local only — nothing leaves this machine)\n'
    printf 'Disable any time with: ash telemetry disable\n'
}

ash_telemetry_disable() {
    rm -f "${ASH_TELEMETRY_DIR}/enabled" 2>/dev/null || true
    printf 'Telemetry: DISABLED\n'
}

ash_telemetry_purge() {
    if [[ -d "$ASH_TELEMETRY_DIR" ]]; then
        local count; count="$(find "$ASH_TELEMETRY_DIR" -type f 2>/dev/null | wc -l)"
        rm -rf "${ASH_TELEMETRY_DIR:?}" 2>/dev/null || true
        printf 'Purged %d telemetry file(s).\n' "$count"
    else
        printf 'Nothing to purge.\n'
    fi
}

ash_telemetry_export() {
    local out="${1:-${ASH_TELEMETRY_DIR}/export-$(date +%Y%m%d).json}"
    [[ -f "$ASH_TELEMETRY_FILE" ]] || { printf 'no telemetry data\n'; return 1; }

    if command -v jq >/dev/null 2>&1; then
        jq -s '.' "$ASH_TELEMETRY_FILE" > "$out" 2>/dev/null || return 1
    else
        { printf '['; local first=1 l
          while IFS= read -r l || [[ -n "$l" ]]; do
              [[ -z "$l" ]] && continue
              (( first == 1 )) && first=0 || printf ','
              printf '%s' "$l"
          done < "$ASH_TELEMETRY_FILE"
          printf ']'; } > "$out"
    fi
    printf '%s\n' "$out"
}

# ── Opt-in prompt shown once on first run ────────────────────────────────────
ash_telemetry_first_run_prompt() {
    local marker="${ASH_CONFIG_HOME:-$HOME/.config/ash}/.telemetry-asked"
    [[ -f "$marker" ]] && return 0
    [[ "${ASH_PROMPT_NONINTERACTIVE:-0}" == "1" ]] && return 0
    [[ ! -t 0 ]] && return 0

    printf '\n'
    printf '  ┌────────────────────────────────────────────────────────┐\n'
    printf '  │  Anonymous, LOCAL usage statistics                     │\n'
    printf '  ├────────────────────────────────────────────────────────┤\n'
    printf '  │  ASH can keep local stats: which commands you use, how │\n'
    printf '  │  long they take. This helps you spot slow workflows.   │\n'
    printf '  │                                                        │\n'
    printf '  │  • Stored only in ~/.local/share/ash/telemetry/        │\n'
    printf '  │  • Nothing is ever sent over the network               │\n'
    printf '  │  • No paths, no hostnames, no window titles            │\n'
    printf '  └────────────────────────────────────────────────────────┘\n'

    if declare -f ash_confirm >/dev/null 2>&1; then
        if ash_confirm "  Enable local statistics?" "n"; then
            ash_telemetry_enable
        else
            printf '  Kept disabled. Changing your mind: ash telemetry enable\n'
        fi
    fi

    mkdir -p "$(dirname "$marker")" 2>/dev/null || true
    : > "$marker"
    printf '\n'
}
