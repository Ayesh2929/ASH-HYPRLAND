#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Compatibility Layer                              ║
# ║                                                                              ║
# ║  Aliases for the helper names that command files call.                      ║
# ║                                                                              ║
# ║  These functions are referenced across many commands but were never         ║
# ║  defined anywhere, so every call site failed at runtime with               ║
# ║  "command not found". Rather than rewrite ~490 call sites, each name is     ║
# ║  implemented here in terms of the real implementation that already exists.  ║
# ║                                                                              ║
# ║  Naming: this file defines the *short* names (ash_hr, ash_truncate, …)      ║
# ║  that call sites use, delegating to the namespaced implementations          ║
# ║  (ash_table_*, ash_box_*, ash_log_*, …) in the other libraries.             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_COMPAT_LOADED:-}" ]] && return 0
readonly _ASH_COMPAT_LOADED=1

# ── Guard: every delegate is optional ─────────────────────────────────────────
# Command files can be sourced standalone (tests, plugins), so never assume a
# delegate exists. `_ash_compat_has <fn>` is true when it does.
_ash_compat_has() { declare -F "$1" >/dev/null 2>&1; }

# ── Colour support ────────────────────────────────────────────────────────────
# Mirrors ash_log_* / box-renderer's convention: honour ASH_FLAG_NO_COLOR and
# non-TTY output so piping into a file or a pager stays clean.
_ash_compat_colour() { [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; }

# ══════════════════════════════════════════════════════════════════════════════
# § 1  TEXT HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# ash_truncate <text> [width] [ellipsis]
#   Shorten <text> to <width> display columns, appending an ellipsis when cut.
#   Width defaults to 40. Delegates to ash_table_truncate, which is
#   UTF-8 aware (it measures via ash_table_width).
ash_truncate() {
    local text="${1:-}" width="${2:-40}" ellipsis="${3:-…}"

    if _ash_compat_has ash_table_truncate; then
        ash_table_truncate "$text" "$width" "$ellipsis"
        return 0
    fi

    # Fallback: character-count approximation
    if (( ${#text} <= width )); then
        printf '%s' "$text"
    else
        printf '%s%s' "${text:0:width-1}" "$ellipsis"
    fi
}

# ash_center <text> [width] [stream]
#   Print <text> horizontally centred within <width> columns.
ash_center() {
    local text="${1:-}" width="${2:-80}" stream="${3:-1}"
    local w=0

    if _ash_compat_has ash_table_width; then
        w="$(ash_table_width "$text" 2>/dev/null || printf '%s' "${#text}")"
    else
        w="${#text}"
    fi

    local pad=$(( (width - w) / 2 ))
    (( pad < 0 )) && pad=0

    printf '%*s%s\n' "$pad" '' "$text" >&"$stream"
}

# ash_hr [char] [width] [colour]
#   Print a horizontal rule. Width defaults to the terminal width, or 80 when
#   there is no TTY.
ash_hr() {
    local char="${1:-─}" width="${2:-0}" colour="${3:-}"

    if (( width <= 0 )); then
        if [[ -t 1 ]]; then
            width="$(tput cols 2>/dev/null || printf '80')"
        else
            width=80
        fi
    fi

    # Build with a loop rather than `printf '%*s' | tr` — tr is byte-oriented
    # on some coreutils builds and would split multibyte rule characters.
    local line='' i
    for (( i = 0; i < width; i++ )); do line+="$char"; done

    if [[ -n "$colour" ]] && _ash_compat_colour; then
        printf '%s%s\033[0m\n' "$colour" "$line"
    else
        printf '%s\n' "$line"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 2  STATUS MESSAGES
# ══════════════════════════════════════════════════════════════════════════════

# ash_print_info / ash_print_warn / ash_print_error / ash_print_success
#   Thin wrappers so command files can report status without depending on the
#   logger being configured.
ash_print_info() {
    if _ash_compat_has ash_log_info; then
        ash_log_info "$*"
    else
        printf '%s\n' "$*" >&2
    fi
}

ash_print_warn() {
    if _ash_compat_has ash_log_warn; then
        ash_log_warn "$*"
    else
        printf 'warning: %s\n' "$*" >&2
    fi
}

ash_print_error() {
    if _ash_compat_has ash_log_error; then
        ash_log_error "$*"
    else
        printf 'error: %s\n' "$*" >&2
    fi
}

ash_print_success() {
    if _ash_compat_has ash_log_success; then
        ash_log_success "$*"
    else
        printf '%s\n' "$*" >&2
    fi
}

# ash_die <message> [exit-code]
#   Report a fatal error and exit. Used for unrecoverable command failures.
ash_die() {
    local message="$*" code=1
    [[ -n "${2:-}" ]] && code="$2"

    if _ash_compat_has ash_log_fatal; then
        ash_log_fatal "$message"      # ash_log_fatal exits by itself
    fi

    printf 'error: %s\n' "$message" >&2
    exit "$code"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 3  SPINNER  (start/stop pair)
# ══════════════════════════════════════════════════════════════════════════════
#
# Call sites use a start/stop pair:
#     ash_spinner_start "Copying configuration files…"
#     …work…
#     ash_spinner_stop 0 "Files copied"
# ash_spinner_async() in spinner.sh is synchronous (it waits), so it cannot be
# used for this; spin in the background and track the PID instead.

_ASH_SPINNER_PID=''

ash_spinner_start() {
    local message="${1:-Working…}"

    # Never spin when output is not a terminal or colour is disabled — a
    # background writer would interleave with the caller's own output.
    if ! _ash_compat_colour; then
        return 0
    fi

    # Stop any previous spinner so two cannot fight over the cursor.
    ash_spinner_stop 0 '' >/dev/null 2>&1 || true

    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local n=${#chars}

    (
        local i=0
        trap 'printf "\r\033[K" >&2; exit 0' TERM INT
        while :; do
            printf '\r\033[K%s %s' "$message" "${chars:i:1}" >&2
            i=$(( (i + 1) % n ))
            sleep 0.08
        done
    ) &
    _ASH_SPINNER_PID=$!

    return 0
}

# ash_spinner_stop [exit-code] [message]
#   Stop the spinner and optionally report the outcome. The exit code drives
#   which of ✓ / ✗ is shown; it is also returned so callers can chain.
ash_spinner_stop() {
    local rc="${1:-0}" message="${2:-}"

    if [[ -n "$_ASH_SPINNER_PID" ]]; then
        kill "$_ASH_SPINNER_PID" 2>/dev/null || true
        wait "$_ASH_SPINNER_PID" 2>/dev/null || true
        _ASH_SPINNER_PID=''
        _ash_compat_colour && printf '\r\033[K' >&2
    fi

    if [[ -n "$message" ]]; then
        if [[ "$rc" -eq 0 ]]; then
            ash_print_success "$message"
        else
            ash_print_error "$message"
        fi
    fi

    return "$rc"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 4  PROGRESS
# ══════════════════════════════════════════════════════════════════════════════

# ash_progress <current> <total> <label> [width]
#   Render a "label [██░░] n/total" line. Written to stderr so that commands
#   producing machine-readable output on stdout are not corrupted.
ash_progress() {
    local current="${1:-0}" total="${2:-1}" label="${3:-}" width="${4:-30}"

    (( total > 0 )) || total=1
    (( current > total )) && current="$total"
    (( width < 1 )) && width=1

    local filled=$(( width * current / total ))
    local empty=$(( width - filled ))

    local bar='' pad=''
    (( filled > 0 )) && bar="$(printf '█%.0s' $(seq 1 "$filled"))"
    (( empty > 0 ))  && pad="$(printf '░%.0s' $(seq 1 "$empty"))"

    if [[ -n "$label" ]]; then
        printf '%s [%s%s] %d/%d\n' "$label" "$bar" "$pad" "$current" "$total" >&2
    else
        printf '[%s%s] %d/%d\n' "$bar" "$pad" "$current" "$total" >&2
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  MODE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# ash_mode_status_brief
#   One-line summary of the active desktop mode, shown when a mode is already
#   active and no change is needed. Reads the globals set by mode.sh; every
#   lookup is guarded so it is safe when mode.sh is not loaded.
ash_mode_status_brief() {
    local mode='default'
    if _ash_compat_has ash_mode_get_current; then
        mode="$(ash_mode_get_current 2>/dev/null || printf 'default')"
    fi

    local icon='' colour=''
    if declare -p MODE_ICONS >/dev/null 2>&1; then
        icon="${MODE_ICONS[$mode]:-}"
    fi
    if declare -p MODE_ACCENT_COLORS >/dev/null 2>&1; then
        colour="${MODE_ACCENT_COLORS[$mode]:-}"
    fi

    if _ash_compat_colour && [[ -n "$colour" ]]; then
        printf '  %s%s %s\033[0m is the active mode\n' "$colour" "$icon" "$mode"
    else
        printf '  %s%s is the active mode\n' "$icon" "$mode"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  log:: NAMESPACE
# ══════════════════════════════════════════════════════════════════════════════
#
# 368 call sites across 35 files use a `log::` API that only ever existed in
# config/nvim/templates/bash.sh (a Neovim snippet that is never sourced).
# The CLI's real logger is the ash_log_* family, so map one onto the other.

log::info()    { ash_print_info "$@"; }
log::warn()    { ash_print_warn "$@"; }
log::error()   { ash_print_error "$@"; }
log::debug()   {
    if _ash_compat_has ash_log_debug; then ash_log_debug "$@"; fi
    return 0
}
log::success() { ash_print_success "$@"; }
log::ok()      { ash_print_success "$@"; }

log::section() {
    if _ash_compat_has ash_log_section; then
        ash_log_section "$@"
    else
        local rule='──────────────────────────────────────────────────────────'
        printf '\n%s\n  %s\n%s\n' "$rule" "$*" "$rule"
    fi
}

log::step() {
    if _ash_compat_has ash_log_step; then
        ash_log_step "$@"
    else
        printf '→ %s\n' "$*"
    fi
}

log::die() {
    if _ash_compat_has ash_log_fatal; then
        ash_log_fatal "$@"        # exits
    fi
    printf 'error: %s\n' "$*" >&2
    exit 1
}

# log::blank
#   Just a blank line — used to space out sections of report output. 95 call
#   sites rely on it existing.
log::blank() {
    printf '\n'
}
