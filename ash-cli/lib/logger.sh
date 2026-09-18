#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 — LOGGER LIBRARY                                              ║
# ║  Structured, leveled, colorized logging with file output                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_LOGGER_LOADED:-}" == "1" ]] && return 0
readonly _ASH_LOGGER_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 LOG LEVELS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA ASH_LOG_LEVELS=(
    [TRACE]=0
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
    [FATAL]=5
    [SILENT]=99
)

declare -g ASH_LOG_CURRENT_LEVEL="${ASH_FLAG_LOG_LEVEL:-INFO}"
declare -g ASH_LOG_FILE_ENABLED=1
declare -g ASH_LOG_COLOR_ENABLED=1
declare -g ASH_LOG_TIMESTAMP_ENABLED=1
declare -g ASH_LOG_CALLER_ENABLED=0
declare -g ASH_LOG_JSON_ENABLED=0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 INTERNAL LOG WRITER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_log_should_print() {
    local level="$1"

    local current_int="${ASH_LOG_LEVELS[${ASH_LOG_CURRENT_LEVEL:-INFO}]:-2}"
    local level_int="${ASH_LOG_LEVELS[$level]:-2}"

    (( level_int >= current_int ))
}

_ash_log_write() {
    local level="$1"
    shift
    local message="$*"

    # Level gate
    _ash_log_should_print "$level" || return 0

    # Quiet mode: only FATAL
    if [[ "${ASH_FLAG_QUIET:-0}" -eq 1 ]] && [[ "$level" != "FATAL" ]]; then
        return 0
    fi

    local timestamp
    timestamp="$(date '+%H:%M:%S')"

    local timestamp_full
    timestamp_full="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"

    # ── Caller information (debug/trace) ─────────────────────────────────
    local caller_info=""
    if [[ "${ASH_LOG_CALLER_ENABLED:-0}" -eq 1 ]]; then
        local caller_line="${BASH_LINENO[1]:-?}"
        local caller_func="${FUNCNAME[2]:-main}"
        local caller_file
        caller_file="$(basename "${BASH_SOURCE[2]:-?}")"
        caller_info="${caller_file}:${caller_line}:${caller_func}() "
    fi

    # ── JSON output ───────────────────────────────────────────────────────
    if [[ "${ASH_LOG_JSON_ENABLED:-0}" -eq 1 ]]; then
        printf '{"ts":"%s","level":"%s","msg":"%s","caller":"%s"}\n' \
            "$timestamp_full" "$level" \
            "${message//\"/\\\"}" \
            "$caller_info"
        return 0
    fi

    # ── Color & Icon definitions per level ───────────────────────────────
    local icon color
    case "$level" in
        TRACE)  icon="◈"; color=$'\033[38;2;108;112;134m'   ;;  # Overlay0
        DEBUG)  icon="◉"; color=$'\033[38;2;116;199;236m'   ;;  # Sapphire
        INFO)   icon="●"; color=$'\033[38;2;137;180;250m'   ;;  # Blue
        WARN)   icon="▲"; color=$'\033[1;38;2;249;226;175m' ;;  # Bold Yellow
        ERROR)  icon="✗"; color=$'\033[1;38;2;243;139;168m' ;;  # Bold Red
        FATAL)  icon="☠"; color=$'\033[1;38;2;243;139;168m' ;;  # Bold Red
        *)      icon="·"; color=$'\033[0m'                  ;;
    esac

    local reset=$'\033[0m'
    local dim=$'\033[38;2;108;112;134m'

    # ── Console output ────────────────────────────────────────────────────
    local use_color=1
    [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 1 ]] && use_color=0
    [[ "${ASH_LOG_COLOR_ENABLED:-1}" -eq 0 ]] && use_color=0
    [[ ! -t 2 ]] && use_color=0

    local output_fd=1
    [[ "$level" == "ERROR" ]] || [[ "$level" == "FATAL" ]] || \
    [[ "$level" == "WARN"  ]] && output_fd=2

    if [[ $use_color -eq 1 ]]; then
        if [[ "${ASH_LOG_TIMESTAMP_ENABLED:-1}" -eq 1 ]]; then
            printf "${dim}%s${reset} ${color}%s %-5s${reset} %s%s\n" \
                "$timestamp" "$icon" "$level" "$caller_info" "$message" >&$output_fd
        else
            printf "${color}%s %-5s${reset} %s%s\n" \
                "$icon" "$level" "$caller_info" "$message" >&$output_fd
        fi
    else
        if [[ "${ASH_LOG_TIMESTAMP_ENABLED:-1}" -eq 1 ]]; then
            printf '[%s] [%-5s] %s%s\n' \
                "$timestamp" "$level" "$caller_info" "$message" >&$output_fd
        else
            printf '[%-5s] %s%s\n' \
                "$level" "$caller_info" "$message" >&$output_fd
        fi
    fi

    # ── File output ───────────────────────────────────────────────────────
    if [[ "${ASH_LOG_FILE_ENABLED:-1}" -eq 1 ]] && \
       [[ -n "${ASH_LOG_FILE:-}" ]]; then
        # Ensure log dir exists
        local log_dir
        log_dir="$(dirname "$ASH_LOG_FILE")"
        [[ -d "$log_dir" ]] || mkdir -p "$log_dir" 2>/dev/null || true

        printf '[%s] [%-5s] %s%s\n' \
            "$timestamp_full" "$level" "$caller_info" "$message" \
            >> "$ASH_LOG_FILE" 2>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 PUBLIC LOGGING INTERFACE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_log_trace() { _ash_log_write "TRACE" "$@"; }
ash_log_debug() { _ash_log_write "DEBUG" "$@"; }
ash_log_info()  { _ash_log_write "INFO"  "$@"; }
ash_log_warn()  { _ash_log_write "WARN"  "$@"; }
ash_log_error() { _ash_log_write "ERROR" "$@"; }

ash_log_fatal() {
    _ash_log_write "FATAL" "$@"
    exit 1
}

# Convenience: log with context
ash_log_success() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;166;227;161m✓\033[0m %s\n' "$*"
    else
        printf '✓ %s\n' "$*"
    fi
    _ash_log_write "INFO" "SUCCESS: $*"
}

ash_log_step() {
    local step_num="${1}"
    local step_total="${2}"
    local message="${3}"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[38;2;108;112;134m[%d/%d]\033[0m \033[38;2;137;180;250m→\033[0m %s\n' \
            "$step_num" "$step_total" "$message"
    else
        printf '[%d/%d] → %s\n' "$step_num" "$step_total" "$message"
    fi
}

# Section header
ash_log_section() {
    local title="$1"
    local width="${ASH_TERM_WIDTH:-80}"
    local inner_width=$(( width - 4 ))

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;203;166;247m'
        printf '┌'
        printf '─%.0s' $(seq 1 $inner_width)
        printf '┐\n'
        printf '│ %-*s│\n' "$(( inner_width - 1 ))" "$title"
        printf '└'
        printf '─%.0s' $(seq 1 $inner_width)
        printf '┘\033[0m\n'
    else
        printf '\n═══ %s ═══\n' "$title"
    fi
}

# Structured key=value log
ash_log_kv() {
    local key="$1"
    local value="$2"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '  \033[38;2;148;226;213m%-20s\033[0m \033[38;2;166;227;161m%s\033[0m\n' \
            "${key}:" "$value"
    else
        printf '  %-20s %s\n' "${key}:" "$value"
    fi
}

# Multi-line log with indentation
ash_log_detail() {
    local prefix="${1:-  }"
    shift

    for line in "$@"; do
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[38;2;108;112;134m%s%s\033[0m\n' "$prefix" "$line"
        else
            printf '%s%s\n' "$prefix" "$line"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 LOG CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_log_set_level() {
    local level="${1^^}"
    if [[ -z "${ASH_LOG_LEVELS[$level]:-}" ]]; then
        ash_log_error "Unknown log level: ${1}"
        ash_log_info  "Valid levels: TRACE DEBUG INFO WARN ERROR FATAL"
        return 1
    fi
    ASH_LOG_CURRENT_LEVEL="$level"
    ash_log_debug "Log level set to: ${level}"
}

ash_log_enable_caller() {
    ASH_LOG_CALLER_ENABLED=1
}

ash_log_enable_json() {
    ASH_LOG_JSON_ENABLED=1
}

ash_log_set_file() {
    ASH_LOG_FILE="$1"
    ASH_LOG_FILE_ENABLED=1
}

ash_log_disable_file() {
    ASH_LOG_FILE_ENABLED=0
}

# Rotate logs
ash_log_rotate() {
    local max_size_kb="${1:-5120}"  # 5MB default

    [[ -z "${ASH_LOG_FILE:-}" ]] && return 0
    [[ ! -f "$ASH_LOG_FILE"   ]] && return 0

    local size_kb
    size_kb=$(du -k "$ASH_LOG_FILE" 2>/dev/null | cut -f1)

    if (( size_kb > max_size_kb )); then
        local rotated="${ASH_LOG_FILE}.$(date '+%Y%m%d-%H%M%S')"
        mv "$ASH_LOG_FILE" "$rotated"
        gzip "$rotated" 2>/dev/null || true

        # Keep only last 5 rotated logs
        find "$(dirname "$ASH_LOG_FILE")" \
            -name "$(basename "$ASH_LOG_FILE").*.gz" \
            -printf '%T@ %p\n' 2>/dev/null | \
            sort -n | head -n -5 | cut -d' ' -f2- | \
            xargs rm -f 2>/dev/null || true

        ash_log_info "Log rotated: ${rotated}.gz"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷 INITIALIZE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Sync level from global flag if already set
if [[ -n "${ASH_FLAG_LOG_LEVEL:-}" ]]; then
    ASH_LOG_CURRENT_LEVEL="${ASH_FLAG_LOG_LEVEL}"
fi

# Rotate on load
ash_log_rotate 2>/dev/null || true
