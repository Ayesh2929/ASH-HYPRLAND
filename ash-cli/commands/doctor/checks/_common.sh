#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║  🩺 ASH DOCTOR — SHARED CHECK HARNESS                                        ║
# ║                                                                              ║
# ║  The twenty check modules in this directory (check-audio, check-network,      ║
# ║  check-gpu-nvidia, …) are all written the same way: each one resets a set of  ║
# ║  counters, calls _check_report once per thing it inspects, and ends with      ║
# ║  _ash_check_system_summary.                                                  ║
# ║                                                                              ║
# ║  That contract — the severity tokens, _check_report, and the system summary  ║
# ║  — was used about 1,100 times across those modules but never actually        ║
# ║  defined anywhere, and nothing ever sourced the modules either. This file is ║
# ║  the missing other half: source it, then call _ash_check_load_all.           ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
#  Severity tokens
#  ───────────────
#  These are DISTINCT small integers, not strings, because the modules also use
#  them as exit statuses:
#
#      return $CHECK_FAIL
#
#  so CHECK_PASS must be 0 for a shell `if` to read a passing check as success.
#  The values double as a severity rank, which is why the ordering below is
#  monotonic. They must stay distinct: _check_report receives nothing but the
#  value, so two tokens sharing a number would be indistinguishable and a SKIP
#  would render as a PASS.
#
#  Severity   Exit  Meaning
#  PASS         0   the thing inspected is healthy
#  INFO         1   a fact worth reporting; not a problem
#  SKIP         2   not applicable here (no such hardware, wrong platform)
#  WARN         3   degraded or suspicious; the system still works
#  FAIL         4   broken; the user should act

[[ -n "${_ASH_CHECK_COMMON_LOADED:-}" ]] && return 0
readonly _ASH_CHECK_COMMON_LOADED=1

# ── Severity tokens ───────────────────────────────────────────────────────────
readonly CHECK_PASS=0
readonly CHECK_INFO=1
readonly CHECK_SKIP=2
readonly CHECK_WARN=3
readonly CHECK_FAIL=4

# Resolve a token back to its name. `case` is used rather than an associative
# array because these constants are readonly scalars, not keys.
_ash_check_sev_name() {
    case "$1" in
        "$CHECK_PASS") printf 'PASS' ;;
        "$CHECK_INFO") printf 'INFO' ;;
        "$CHECK_SKIP") printf 'SKIP' ;;
        "$CHECK_WARN") printf 'WARN' ;;
        "$CHECK_FAIL") printf 'FAIL' ;;
        *)             printf 'INFO' ;;
    esac
}

# ── Result counters ───────────────────────────────────────────────────────────
# Each module resets PASS/WARN/FAIL/SKIP at the top of its entry function (see
# check-audio.sh:619). INFO is not in that list, so it is defaulted here rather
# than assumed — reading an unset counter under `set -u` would abort the check.
_ash_check_reset_counters() {
    _CHECK_PASS_COUNT=0
    _CHECK_INFO_COUNT=0
    _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0
    _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=()
    _CHECK_WARNINGS=()
}

# ── The reporter ──────────────────────────────────────────────────────────────
#
#   _check_report <SEVERITY> <TITLE> [DETAIL] [FIX]
#
# One aligned line per finding, plus an indented remedy when there is one:
#
#   ✅  pipewire binary                     v1.0.5
#   ⚠️  /boot space                         82% (1.2 GiB free)
#       ↳ Clean: paru -Sc
#
# TITLE is the subject, DETAIL is what was observed, FIX is the command or step
# that resolves it. Output is a single printf so a check's findings cannot
# interleave with another check's under a spinner.
_check_report() {
    local code="${1:-}"
    local title="${2:-}"
    local detail="${3:-}"
    local fix="${4:-}"

    local sev colour icon
    sev="$(_ash_check_sev_name "$code")"

    case "$sev" in
        PASS) colour="${ASH_SUCCESS:-}"; icon="${ICO_SUCCESS:-}" ;;
        INFO) colour="${ASH_INFO:-}";    icon="${ICO_INFO:-}"    ;;
        SKIP) colour="${ASH_MUTED:-}";   icon="${ICO_SKIP:-}"   ;;
        WARN) colour="${ASH_WARNING:-}"; icon="${ICO_WARN:-}"   ;;
        FAIL) colour="${ASH_ERROR:-}";   icon="${ICO_ERROR:-}"  ;;
    esac

    # Count first, so a formatting problem can never lose a finding.
    #
    # `|| true` is load-bearing on every increment: `(( x++ ))` evaluates to the
    # PRE-increment value, so counting from 0 yields status 1, and these modules
    # run under `set -e` — the first result of a run would abort the whole check.
    case "$sev" in
        PASS) (( _CHECK_PASS_COUNT++ )) || true ;;
        INFO) (( _CHECK_INFO_COUNT++ )) || true ;;
        SKIP) (( _CHECK_SKIP_COUNT++ )) || true ;;
        WARN) (( _CHECK_WARN_COUNT++ )) || true
              _CHECK_WARNINGS+=("${title}") ;;
        FAIL) (( _CHECK_FAIL_COUNT++ )) || true
              _CHECK_FAILURES+=("${title}") ;;
    esac

    # Row: two-space gutter, icon, severity, subject, detail.
    #
    # The subject is padded by DISPLAY COLUMNS, not with %-38s. printf measures
    # bytes, so "✅ Bluetooth adapter" and "Bluetooth adapter" would be padded to
    # the same byte count but occupy different numbers of columns, and the detail
    # column would stagger. _ash_pad measures with wc -L instead.
    local title_padded
    title_padded="$(_ash_pad "$title" 38)"

    # The icon is padded to 2 columns for the same reason: an emoji is 2 wide
    # while the ASCII fallback is 3, so a fixed-width %s would shift the severity
    # label only when unicode is disabled.
    local icon_padded
    icon_padded="$(_ash_pad "$icon" 2)"

    printf '  %s%s%s %s%-4s%s %s %s%s%s\n' \
        "$colour" "$icon_padded" "${RST:-}" \
        "$colour" "$sev" "${RST:-}" \
        "$title_padded" \
        "${ASH_MUTED:-}" "$detail" "${RST:-}"

    if [[ -n "$fix" ]]; then
        printf '       %s↳ %s%s\n' "${ASH_MUTED:-}" "$fix" "${RST:-}"
    fi

    # Feed the aggregate report the doctor command builds, when it is loaded.
    if declare -F doc::result >/dev/null 2>&1; then
        doc::result "$sev" "${_CHECK_CATEGORY:-general}" "${_CHECK_ID:-check}" \
            "$title" "$detail" "$fix"
    fi
}

# ── Section header ────────────────────────────────────────────────────────────
#
#   _check_header "🎵 PipeWire Audio Server"
#
# Every group of findings inside a check module opens with one of these (136
# call sites across the twenty modules). It is a visual break plus a rule, sized
# to the terminal so the line does not wrap on a narrow window.
_check_header() {
    local text="${1:-}"

    # Size the rule to the available width, clamped to a readable range: a
    # 200-column terminal would otherwise draw a rule wider than the eye can
    # follow, and a 20-column one would draw a stub.
    local width
    width="$(tput cols 2>/dev/null || printf '80')"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width > 100 )) && width=100
    (( width < 40 ))  && width=40

    # Account for the two-space gutter and the leading space before the label.
    local label_w left right fill
    label_w="$(_ash_display_width "$text")"
    fill=$(( width - label_w - 5 ))
    (( fill < 4 )) && fill=4
    left=$(( fill / 2 ))
    right=$(( fill - left ))

    local pad_l="" pad_r="" i
    for (( i = 0; i < left;  i++ )); do pad_l+="─"; done
    for (( i = 0; i < right; i++ )); do pad_r+="─"; done

    printf '\n  %s%s %s%s%s %s%s%s\n' \
        "${ASH_MUTED:-}" "$pad_l" \
        "${BOLD:-}${ASH_PRIMARY:-}" "$text" \
        "${RST:-}" \
        "${ASH_MUTED:-}" "$pad_r" "${RST:-}"
}

# ── Loader ────────────────────────────────────────────────────────────────────
#
# Sourcing is deliberately lazy and failure-tolerant: one malformed check module
# must not take down the other nineteen. A module that fails to load is reported
# as a SKIP, so it is visible in the output rather than silently absent.
_ash_check_load_all() {
    local dir="${_ASH_CHECK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    local file name

    # _common.sh itself has already been sourced by the caller.
    for file in "${dir}"/check-*.sh; do
        [[ -f "$file" ]] || continue
        name="$(basename "$file" .sh)"

        # Derive the category from the filename so doc::result can group by area.
        _CHECK_CATEGORY="${name#check-}"
        _CHECK_ID="$name"

        if ! source "$file" 2>/dev/null; then
            printf '  %s%s SKIP%s %-38s %s\n' \
                "${ASH_MUTED:-}" "${ICO_WARN:-}" "${RST:-}" \
                "${name}" "module failed to load"
        fi
    done
    unset _CHECK_CATEGORY _CHECK_ID
}

# Every module's entry/quick function name, given its filename. Modules follow
# check-<name>.sh → ash_check_<name>, with dashes promoted to underscores.
_ash_check_fn_name() {
    local base="${1##*/}"
    base="${base%.sh}"
    base="${base#check-}"
    base="${base//-/_}"
    printf 'ash_check_%s' "$base"
}

# Run every loaded check, full or quick. Returns the number of FAILs, so the
# caller can gate on it, and keeps going after a module aborts — a crash in one
# area is not a reason to skip diagnosing the rest.
_ash_check_run_all() {
    local mode="${1:-full}"
    local dir="${_ASH_CHECK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    local file fn rc fails=0

    for file in "${dir}"/check-*.sh; do
        [[ -f "$file" ]] || continue

        fn="$(_ash_check_fn_name "$file")"
        [[ "$mode" == "quick" ]] && fn="${fn}_quick"

        declare -F "$fn" >/dev/null 2>&1 || continue

        set +e
        "$fn"
        rc=$?
        set -e

        # Quick variants return a plain count of issues rather than a token.
        if [[ "$mode" == "quick" ]]; then
            (( rc > fails )) && fails=$rc
        elif [[ "$rc" == "$CHECK_FAIL" ]]; then
            (( fails++ )) || true
        fi
    done

    printf '%d' "$fails"
}

# ── System summary ────────────────────────────────────────────────────────────
#
# Called at the end of each module's entry function (check-audio.sh:650 and the
# nineteen others). Printed once per process: twenty modules in a row each
# announcing the same hostname and kernel is noise, not diagnostics.
_ash_check_system_summary() {
    [[ -n "${_ASH_CHECK_SUMMARY_PRINTED:-}" ]] && return 0
    _ASH_CHECK_SUMMARY_PRINTED=1

    local host kernel distro uptime_str cpu mem_pct disk_pct

    host="$(uname -n 2>/dev/null || printf 'unknown')"
    kernel="$(uname -r 2>/dev/null || printf 'unknown')"

    distro="unknown"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        distro="$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-${NAME:-unknown}}")"
    fi

    uptime_str="unknown"
    if [[ -r /proc/uptime ]]; then
        local secs
        secs="$(cut -d. -f1 /proc/uptime 2>/dev/null || printf 0)"
        printf -v uptime_str '%dd %dh %dm' \
            $(( secs / 86400 )) $(( (secs % 86400) / 3600 )) $(( (secs % 3600) / 60 ))
    fi

    cpu="$(awk -F': ' '/^model name/ { print $2; exit }' /proc/cpuinfo 2>/dev/null || printf 'unknown')"

    mem_pct="unknown"
    if command -v free >/dev/null 2>&1; then
        mem_pct="$(free | awk '/^Mem:/ { printf "%.0f%%", ($3 / $2) * 100 }' 2>/dev/null || printf 'unknown')"
    fi

    disk_pct="unknown"
    if command -v df >/dev/null 2>&1; then
        disk_pct="$(df -h / 2>/dev/null | awk 'NR==2 { print $5 }' || printf 'unknown')"
    fi

    printf '\n  %s%s%s\n' "${BOLD:-}${ASH_PRIMARY:-}" "SYSTEM" "${RST:-}"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Host"     "${RST:-}" "$host"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Distro"   "${RST:-}" "$distro"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Kernel"   "${RST:-}" "$kernel"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Uptime"   "${RST:-}" "$uptime_str"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "CPU"      "${RST:-}" "$cpu"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Memory"   "${RST:-}" "$mem_pct in use"
    printf '  %s%-14s%s %s\n' "${ASH_MUTED:-}" "Disk (/)" "${RST:-}" "$disk_pct in use"
}

# ── Per-module summary line ───────────────────────────────────────────────────
# Modules print their own banner; this gives them a consistent footer with the
# tally, so the reader can see how the area scored without scrolling back.
_ash_check_summary_line() {
    local area="${1:-check}"
    printf '  %s%s%s %s%s pass%s · %s%s info%s · %s%s warn%s · %s%s fail%s · %s%s skip%s\n' \
        "${ASH_MUTED:-}" "└─" "${RST:-}" \
        "${ASH_SUCCESS:-}" "${_CHECK_PASS_COUNT:-0}" "${RST:-}" \
        "${ASH_INFO:-}"    "${_CHECK_INFO_COUNT:-0}" "${RST:-}" \
        "${ASH_WARNING:-}" "${_CHECK_WARN_COUNT:-0}" "${RST:-}" \
        "${ASH_ERROR:-}"   "${_CHECK_FAIL_COUNT:-0}" "${RST:-}" \
        "${ASH_MUTED:-}"   "${_CHECK_SKIP_COUNT:-0}" "${RST:-}"
}
