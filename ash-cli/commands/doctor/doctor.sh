#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                          ║
# ║   ██████╗  ██████╗  ██████╗████████╗ ██████╗ ██████╗                                   ║
# ║   ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗                                  ║
# ║   ██║  ██║██║   ██║██║        ██║   ██║   ██║██████╔╝                                  ║
# ║   ██║  ██║██║   ██║██║        ██║   ██║   ██║██╔══██╗                                  ║
# ║   ██████╔╝╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║                                  ║
# ║   ╚═════╝  ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝                                  ║
# ║                                                                                          ║
# ║   ASH DOTFILES v5.0 OMEGA ◆ DOCTOR COMMAND DISPATCHER                                  ║
# ║   System health diagnostics • auto-fix • deep audit • report generation               ║
# ║                                                                                          ║
# ║   Architecture:                                                                          ║
# ║     doctor.sh   — dispatcher + check registry + shared primitives                      ║
# ║     quick.sh    — fast 30-second essential checks                                       ║
# ║     full.sh     — comprehensive deep system audit (200+ checks)                        ║
# ║     fix.sh      — intelligent auto-repair engine                                        ║
# ║     report.sh   — rich report generation (JSON/HTML/Markdown/PDF)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
# shellcheck disable=SC2034,SC2154,SC1090,SC1091
set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § BOOTSTRAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_DOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_DOC_DIR}/../../lib"

source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § CONSTANTS & PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
readonly DOC_STATE_DIR="${ASH_STATE_DIR:-${HOME}/.local/state/ash}/doctor"
readonly DOC_REPORT_DIR="${ASH_DATA_DIR:-${HOME}/.local/share/ash}/reports"
readonly DOC_LAST_RUN_FILE="${DOC_STATE_DIR}/last-run.json"
readonly DOC_CHECKS_DIR="${_DOC_DIR}/checks"
readonly DOC_FIXERS_DIR="${_DOC_DIR}/fixers"
readonly DOC_VERSION="5.0.0"

# ── Result severity constants ─────────────────────────────────────────────────
readonly SEV_PASS="PASS"        # ✓ Everything OK
readonly SEV_INFO="INFO"        # ℹ Informational, no action needed
readonly SEV_WARN="WARN"        # ⚠ Should fix, non-critical
readonly SEV_FAIL="FAIL"        # ✗ Must fix, system impacted
readonly SEV_CRIT="CRIT"        # ✦ Critical failure, functionality broken
readonly SEV_SKIP="SKIP"        # ─ Check not applicable

# ── Check category definitions ─────────────────────────────────────────────────
readonly -a DOC_CATEGORIES=(
    "system:🖥 System Environment"
    "wayland:🌊 Wayland & Display"
    "hyprland:🪟 Hyprland Compositor"
    "gpu:🎮 GPU & Graphics"
    "audio:🔊 Audio System"
    "network:🌐 Network"
    "fonts:🔤 Fonts & Icons"
    "tools:🔧 Required Tools"
    "optional:📦 Optional Tools"
    "config:⚙ Configuration Files"
    "theme:🎨 Theme Engine"
    "plugins:🔌 Plugin System"
    "performance:⚡ Performance"
    "security:🔒 Security"
    "permissions:🛡 Permissions"
    "services:⏱ Systemd Services"
    "portals:🚪 XDG Portals"
    "disk:💾 Disk Space"
    "dependencies:📋 Dependencies"
)

# ── Global check result accumulator ───────────────────────────────────────────
declare -ga DOC_RESULTS=()      # "SEVERITY|CATEGORY|ID|TITLE|MESSAGE|FIX_CMD"
declare -gi DOC_PASS_COUNT=0
declare -gi DOC_INFO_COUNT=0
declare -gi DOC_WARN_COUNT=0
declare -gi DOC_FAIL_COUNT=0
declare -gi DOC_CRIT_COUNT=0
declare -gi DOC_SKIP_COUNT=0
declare -g  DOC_START_TIME=0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § SHARED CHECK PRIMITIVES
# These functions are sourced by quick.sh, full.sh, and fix.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Record a check result ─────────────────────────────────────────────────────
doc::result() {
    # Usage: doc::result <SEV> <CATEGORY> <ID> <TITLE> <MESSAGE> [FIX_CMD]
    local sev="$1" category="$2" id="$3" title="$4" msg="$5" fix="${6:-}"

    DOC_RESULTS+=("${sev}|${category}|${id}|${title}|${msg}|${fix}")

    # `|| true` on every increment is load-bearing. `(( x++ ))` evaluates to the
    # PRE-increment value, so the first result of a run counts from 0 and yields
    # status 1 — and this file runs under `set -e`, so the very first call would
    # abort the command before printing anything.
    case "${sev}" in
        PASS) (( DOC_PASS_COUNT++ )) || true ;;
        INFO) (( DOC_INFO_COUNT++ )) || true ;;
        WARN) (( DOC_WARN_COUNT++ )) || true ;;
        FAIL) (( DOC_FAIL_COUNT++ )) || true ;;
        CRIT) (( DOC_CRIT_COUNT++ )) || true ;;
        SKIP) (( DOC_SKIP_COUNT++ )) || true ;;
    esac
}

# ── Severity badge renderer ───────────────────────────────────────────────────
doc::badge() {
    local sev="$1" compact="${2:-false}"
    if [[ "${compact}" == "true" ]]; then
        case "${sev}" in
            PASS) printf '%s●%s' "${ASH_SUCCESS}"                   "${RST}" ;;
            INFO) printf '%s●%s' "${ASH_INFO}"                      "${RST}" ;;
            WARN) printf '%s●%s' "${ASH_WARNING}"                   "${RST}" ;;
            FAIL) printf '%s●%s' "${ASH_ERROR}"                     "${RST}" ;;
            CRIT) printf '%s●%s' "${BOLD}${ASH_ERROR}"              "${RST}" ;;
            SKIP) printf '%s─%s' "${ASH_MUTED}"                     "${RST}" ;;
        esac
        return
    fi
    case "${sev}" in
        PASS) printf '%s%s PASS%s' "${ASH_SUCCESS}"        "${ICO_SUCCESS}" "${RST}" ;;
        INFO) printf '%s%s INFO%s' "${ASH_INFO}"           "${ICO_INFO}"    "${RST}" ;;
        WARN) printf '%s%s WARN%s' "${ASH_WARNING}"        "${ICO_WARN}"    "${RST}" ;;
        FAIL) printf '%s%s FAIL%s' "${ASH_ERROR}"          "${ICO_ERROR}"   "${RST}" ;;
        CRIT) printf '%s%s CRIT%s' "${BOLD}${ASH_ERROR}"   "☠"             "${RST}" ;;
        SKIP) printf '%s─ SKIP%s'  "${ASH_MUTED}"                          "${RST}" ;;
    esac
}

# ── Health score calculator ────────────────────────────────────────────────────
doc::health_score() {
    local total=$(( DOC_PASS_COUNT + DOC_WARN_COUNT + DOC_FAIL_COUNT + DOC_CRIT_COUNT ))
    (( total == 0 )) && { printf '0'; return; }
    # Weights: PASS=100 WARN=60 FAIL=20 CRIT=0
    local weighted=$(( DOC_PASS_COUNT * 100 + DOC_WARN_COUNT * 60 + DOC_FAIL_COUNT * 20 ))
    printf '%d' $(( weighted / total ))
}

# ── Score to letter grade ─────────────────────────────────────────────────────
doc::health_grade() {
    local score="$1"
    if   (( score >= 95 )); then printf 'A+'
    elif (( score >= 90 )); then printf 'A'
    elif (( score >= 80 )); then printf 'B'
    elif (( score >= 70 )); then printf 'C'
    elif (( score >= 50 )); then printf 'D'
    else                         printf 'F'
    fi
}

# ── Score colour ──────────────────────────────────────────────────────────────
doc::score_color() {
    local score="$1"
    if   (( score >= 90 )); then printf '%s' "${ASH_SUCCESS}"
    elif (( score >= 70 )); then printf '%s' "${ASH_WARNING}"
    elif (( score >= 50 )); then printf '%s' "${SNAP_COLOR_DIFF_MOD}"
    else                         printf '%s' "${ASH_ERROR}"
    fi
}

# ── Health score bar ──────────────────────────────────────────────────────────
doc::score_bar() {
    local score="$1" width="${2:-30}"
    local filled=$(( score * width / 100 ))
    local empty=$(( width - filled ))
    local color; color=$(doc::score_color "${score}")

    printf '%s' "${color}"
    printf '%*s' "${filled}" '' | tr ' ' '█'
    printf '%s' "${ASH_MUTED}"
    printf '%*s' "${empty}"  '' | tr ' ' '░'
    printf '%s' "${RST}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § CHECK MACROS — used by full.sh / quick.sh checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check that a binary exists on PATH
doc::check_cmd() {
    # doc::check_cmd <category> <id> <cmd> [required=true] [fix_cmd]
    local cat="$1" id="$2" cmd="$3" required="${4:-true}" fix="${5:-}"
    local title="Command: ${cmd}"

    if command -v "${cmd}" &>/dev/null; then
        local ver
        ver=$(${cmd} --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+[\.0-9]*' | head -1 || echo "")
        local msg="Found$([ -n "${ver}" ] && printf ' v%s' "${ver}")"
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" "${msg}" ""
    else
        local sev; [[ "${required}" == "true" ]] && sev="${SEV_FAIL}" || sev="${SEV_WARN}"
        local msg="Not found on PATH"
        [[ "${required}" == "false" ]] && msg="Not installed (optional)"
        doc::result "${sev}" "${cat}" "${id}" "${title}" "${msg}" "${fix}"
    fi
}

# Check that a file/dir exists
doc::check_path() {
    local cat="$1" id="$2" path="$3" label="${4:-}" sev_fail="${5:-${SEV_FAIL}}" fix="${6:-}"
    local title="${label:-Path: ${path}}"

    if [[ -e "${path}" ]]; then
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" "Exists: ${path}" ""
    else
        doc::result "${sev_fail}" "${cat}" "${id}" "${title}" "Missing: ${path}" "${fix}"
    fi
}

# Check a systemd user service is active
doc::check_service() {
    local cat="$1" id="$2" svc="$3" required="${4:-false}"
    local title="Service: ${svc}"
    local sev_fail; [[ "${required}" == "true" ]] && sev_fail="${SEV_FAIL}" || sev_fail="${SEV_WARN}"

    if systemctl --user is-active --quiet "${svc}" 2>/dev/null; then
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" "Active" ""
    elif systemctl --user is-enabled --quiet "${svc}" 2>/dev/null; then
        doc::result "${SEV_WARN}" "${cat}" "${id}" "${title}" \
            "Enabled but not running" "systemctl --user start ${svc}"
    else
        doc::result "${sev_fail}" "${cat}" "${id}" "${title}" \
            "Not enabled" "systemctl --user enable --now ${svc}"
    fi
}

# Check that a file has correct permissions
doc::check_perm() {
    local cat="$1" id="$2" path="$3" expected_perm="$4" fix="${5:-}"
    local title="Permissions: $(basename "${path}")"
    [[ ! -e "${path}" ]] && {
        doc::result "${SEV_SKIP}" "${cat}" "${id}" "${title}" "Path does not exist" ""
        return
    }
    local actual_perm
    actual_perm=$(stat -c '%a' "${path}" 2>/dev/null || echo "???")
    if [[ "${actual_perm}" == "${expected_perm}" ]]; then
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" "${actual_perm} ✓" ""
    else
        doc::result "${SEV_WARN}" "${cat}" "${id}" "${title}" \
            "Got ${actual_perm}, expected ${expected_perm}" \
            "${fix:-chmod ${expected_perm} ${path}}"
    fi
}

# Check minimum disk space
doc::check_disk_space() {
    local cat="$1" id="$2" path="$3" min_mb="$4"
    local title="Disk space: ${path}"
    local avail_kb
    avail_kb=$(df -k "${path}" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
    local avail_mb=$(( avail_kb / 1024 ))

    if (( avail_mb >= min_mb )); then
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" \
            "$(utils::human_size "$(( avail_kb * 1024 ))") available" ""
    elif (( avail_mb >= (min_mb / 2) )); then
        doc::result "${SEV_WARN}" "${cat}" "${id}" "${title}" \
            "Low: only $(utils::human_size "$(( avail_kb * 1024 ))") available (min: ${min_mb}MiB)" ""
    else
        doc::result "${SEV_FAIL}" "${cat}" "${id}" "${title}" \
            "Critical: $(utils::human_size "$(( avail_kb * 1024 ))") — system may malfunction" ""
    fi
}

# Check env variable is set
doc::check_env() {
    local cat="$1" id="$2" var="$3" expected="${4:-}" sev_fail="${5:-${SEV_WARN}}"
    local title="Env: \$${var}"
    local val="${!var:-}"

    if [[ -z "${val}" ]]; then
        doc::result "${sev_fail}" "${cat}" "${id}" "${title}" "Not set" ""
    elif [[ -n "${expected}" ]] && [[ "${val}" != "${expected}"* ]]; then
        doc::result "${SEV_WARN}" "${cat}" "${id}" "${title}" \
            "Value '${val}' (expected '${expected}…')" ""
    else
        doc::result "${SEV_PASS}" "${cat}" "${id}" "${title}" "${val}" ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § RENDER ENGINE — formats and prints check results
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

doc::render_results() {
    local mode="${1:-full}"       # full | compact | issues-only
    local category_filter="${2:-}"

    local prev_category=""

    for entry in "${DOC_RESULTS[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"

        [[ -n "${category_filter}" ]] && [[ "${cat}" != "${category_filter}" ]] && continue

        # Issues-only mode: skip PASS and INFO
        if [[ "${mode}" == "issues-only" ]]; then
            [[ "${sev}" == "${SEV_PASS}" ]] && continue
            [[ "${sev}" == "${SEV_INFO}" ]] && continue
            [[ "${sev}" == "${SEV_SKIP}" ]] && continue
        fi

        # Category header
        if [[ "${cat}" != "${prev_category}" ]]; then
            prev_category="${cat}"
            local cat_label=""
            for cdef in "${DOC_CATEGORIES[@]}"; do
                local ckey="${cdef%%:*}" clabel="${cdef#*:}"
                [[ "${ckey}" == "${cat}" ]] && { cat_label="${clabel}"; break; }
            done
            printf '\n  %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "${cat_label:-${cat}}" "${RST}"
            ash_hr "─" 72 "${ASH_MUTED}"
        fi

        local badge; badge=$(doc::badge "${sev}")

        if [[ "${mode}" == "compact" ]]; then
            printf '  %s  %s%s%s\n' \
                "${badge}" \
                "${ASH_MUTED}" "$(ash_truncate "${title}" 50)" "${RST}"
        else
            # Full row
            printf '  %s  %s%-38s%s  %s%s%s\n' \
                "${badge}" \
                "${ASH_INFO}" "$(ash_truncate "${title}" 38)" "${RST}" \
                "${ASH_MUTED}" "$(ash_truncate "${msg}" 32)" "${RST}"

            # Fix hint
            if [[ -n "${fix}" ]] && [[ "${sev}" != "${SEV_PASS}" ]] && \
               [[ "${sev}" != "${SEV_SKIP}" ]] && [[ "${sev}" != "${SEV_INFO}" ]]; then
                printf '     %s⚡ Fix: %s%s%s\n' \
                    "${ASH_MUTED}" "${ASH_ACCENT}" "${fix}" "${RST}"
            fi
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § SUMMARY DASHBOARD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

doc::render_summary() {
    local elapsed="${1:-0}"
    local score; score=$(doc::health_score)
    local grade; grade=$(doc::health_grade "${score}")
    local score_color; score_color=$(doc::score_color "${score}")
    local total=$(( DOC_PASS_COUNT + DOC_INFO_COUNT + DOC_WARN_COUNT + \
                    DOC_FAIL_COUNT + DOC_CRIT_COUNT + DOC_SKIP_COUNT ))
    local actionable=$(( DOC_WARN_COUNT + DOC_FAIL_COUNT + DOC_CRIT_COUNT ))

    printf '\n'
    printf '  %s╔══════════════════════════════════════════════════════════╗%s\n' \
        "${ASH_PRIMARY}" "${RST}"
    printf '  %s║%s  %s%s Health Report%s%s%30s%s%s║%s\n' \
        "${ASH_PRIMARY}" "${RST}" \
        "${BOLD}${ASH_PRIMARY}" "🩺" "${RST}" \
        "${BOLD}" "" "${RST}" \
        "${ASH_PRIMARY}" "${RST}"
    printf '  %s╚══════════════════════════════════════════════════════════╝%s\n\n' \
        "${ASH_PRIMARY}" "${RST}"

    # Score gauge
    printf '  %sHealth Score%s  %s%s%s  %s%d/100%s  %s%s%s\n' \
        "${ASH_MUTED}" "${RST}" \
        "${score_color}${BOLD}" "${grade}" "${RST}" \
        "${score_color}${BOLD}" "${score}" "${RST}" \
        "${score_color}" "$(doc::score_bar "${score}" 28)" "${RST}"
    printf '\n'

    # Stats grid
    local w=14
    printf '  %s%-*s%s  %s%-*s%s  %s%-*s%s  %s%-*s%s  %s%-*s%s  %s%-*s%s\n' \
        "${BOLD}${ASH_SUCCESS}"  "${w}" "✓ PASSED"   "${RST}" \
        "${BOLD}${ASH_INFO}"     "${w}" "ℹ INFO"     "${RST}" \
        "${BOLD}${ASH_WARNING}"  "${w}" "⚠ WARNINGS" "${RST}" \
        "${BOLD}${ASH_ERROR}"    "${w}" "✗ FAILED"   "${RST}" \
        "${BOLD}${ASH_ERROR}"    "${w}" "☠ CRITICAL" "${RST}" \
        "${BOLD}${ASH_MUTED}"    "${w}" "─ SKIPPED"  "${RST}"

    printf '  %s%-*d%s  %s%-*d%s  %s%-*d%s  %s%-*d%s  %s%-*d%s  %s%-*d%s\n\n' \
        "${ASH_SUCCESS}"  "${w}" "${DOC_PASS_COUNT}"  "${RST}" \
        "${ASH_INFO}"     "${w}" "${DOC_INFO_COUNT}"  "${RST}" \
        "${ASH_WARNING}"  "${w}" "${DOC_WARN_COUNT}"  "${RST}" \
        "${ASH_ERROR}"    "${w}" "${DOC_FAIL_COUNT}"  "${RST}" \
        "${ASH_ERROR}"    "${w}" "${DOC_CRIT_COUNT}"  "${RST}" \
        "${ASH_MUTED}"    "${w}" "${DOC_SKIP_COUNT}"  "${RST}"

    # Timing
    printf '  %sChecks: %d total • Elapsed: %.1fs%s\n' \
        "${ASH_MUTED}" "${total}" "${elapsed}" "${RST}"

    # Action required?
    if (( actionable > 0 )); then
        printf '\n  %s%s %d issue(s) require attention%s\n' \
            "${BOLD}${ASH_ERROR}" "${ICO_WARN}" "${actionable}" "${RST}"
        printf '  %sTip:%s Run %sash doctor fix%s to auto-repair issues\n' \
            "${ASH_MUTED}" "${RST}" "${ASH_ACCENT}" "${RST}"
    else
        printf '\n  %s%s All systems nominal%s\n' \
            "${BOLD}${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}"
    fi
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § PERSISTENCE — save/load last run results
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

doc::save_results() {
    mkdir -p "${DOC_STATE_DIR}"
    local ts; ts=$(date +%s)
    local score; score=$(doc::health_score)
    local grade; grade=$(doc::health_grade "${score}")

    # Build JSON results array
    local results_json='['
    local first=true
    for entry in "${DOC_RESULTS[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"
        [[ "${first}" == "true" ]] && first=false || results_json+=','
        results_json+=$(jq -n \
            --arg sev   "${sev}" \
            --arg cat   "${cat}" \
            --arg id    "${id}" \
            --arg title "${title}" \
            --arg msg   "${msg}" \
            --arg fix   "${fix}" \
            '{severity:$sev,category:$cat,id:$id,title:$title,message:$msg,fix:$fix}')
    done
    results_json+=']'

    jq -n \
        --argjson ts        "${ts}" \
        --argjson score     "${score}" \
        --arg     grade     "${grade}" \
        --argjson pass      "${DOC_PASS_COUNT}" \
        --argjson info      "${DOC_INFO_COUNT}" \
        --argjson warn      "${DOC_WARN_COUNT}" \
        --argjson fail      "${DOC_FAIL_COUNT}" \
        --argjson crit      "${DOC_CRIT_COUNT}" \
        --argjson skip      "${DOC_SKIP_COUNT}" \
        --argjson results   "${results_json}" \
        --arg     host      "$(hostname -s 2>/dev/null || echo unknown)" \
        --arg     ash_ver   "${DOC_VERSION}" \
        '{timestamp:$ts,score:$score,grade:$grade,
          hostname:$host,ash_version:$ash_ver,
          summary:{pass:$pass,info:$info,warn:$warn,fail:$fail,crit:$crit,skip:$skip},
          results:$results}' \
        > "${DOC_LAST_RUN_FILE}"
}

doc::load_last_results() {
    [[ ! -f "${DOC_LAST_RUN_FILE}" ]] && {
        log::warn "No previous doctor run found"
        return 1
    }
    cat "${DOC_LAST_RUN_FILE}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "🩺  ASH DOCTOR" \
        "System health diagnostics • auto-fix • report generation" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash doctor <subcommand> [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${ASH_ACCENT}quick${RST}     [opts]   Fast 30-second essential health check
  ${ASH_ACCENT}full${RST}      [opts]   Comprehensive deep audit (200+ checks)
  ${ASH_ACCENT}fix${RST}       [opts]   Intelligent auto-repair engine
  ${ASH_ACCENT}report${RST}    [opts]   Generate rich diagnostic report

${BOLD}${ASH_PRIMARY}GLOBAL OPTIONS${RST}
  ${ASH_MUTED}--category, -c CAT${RST}   Limit to one category
  ${ASH_MUTED}--json${RST}               Output raw JSON results
  ${ASH_MUTED}--quiet,    -q${RST}       Minimal output
  ${ASH_MUTED}--debug${RST}              Enable debug logging
  ${ASH_MUTED}--help,     -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}CATEGORIES${RST}
$(for cdef in "${DOC_CATEGORIES[@]}"; do
    local ck="${cdef%%:*}" cl="${cdef#*:}"
    printf '  %s%-14s%s %s\n' "${ASH_ACCENT}" "${ck}" "${RST}" "${cl}"
done)

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${FG_BBLACK}# Quick check — good for daily use${RST}
  ${ASH_ACCENT}ash doctor quick${RST}

  ${FG_BBLACK}# Full audit with JSON output${RST}
  ${ASH_ACCENT}ash doctor full${RST} --json > report.json

  ${FG_BBLACK}# Only check GPU category${RST}
  ${ASH_ACCENT}ash doctor full${RST} --category gpu

  ${FG_BBLACK}# Auto-fix all detected issues${RST}
  ${ASH_ACCENT}ash doctor fix${RST}

  ${FG_BBLACK}# Generate HTML report${RST}
  ${ASH_ACCENT}ash doctor report${RST} --format html --output ~/ash-report.html

${BOLD}${ASH_PRIMARY}LAST RUN${RST}
$(if [[ -f "${DOC_LAST_RUN_FILE}" ]]; then
    local ts; ts=$(jq -r '.timestamp // 0' "${DOC_LAST_RUN_FILE}" 2>/dev/null || echo 0)
    local score; score=$(jq -r '.score // "?"' "${DOC_LAST_RUN_FILE}" 2>/dev/null || echo "?")
    local grade; grade=$(jq -r '.grade // "?"' "${DOC_LAST_RUN_FILE}" 2>/dev/null || echo "?")
    local rel; rel=$(utils::relative_time "${ts}")
    printf '  %sRan %s — Score: %d/100 (%s)%s\n' "${ASH_MUTED}" "${rel}" "${score}" "${grade}" "${RST}"
else
    printf '  %sNo previous run found%s\n' "${ASH_MUTED}" "${RST}"
fi)

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::main() {
    # ── Global flags ──────────────────────────────────────────────────────────
    export DOC_CATEGORY_FILTER=""
    export DOC_JSON_OUTPUT=false
    export DOC_QUIET=false

    while [[ "${1:-}" == --* ]]; do
        case "$1" in
            --category|-c)  DOC_CATEGORY_FILTER="${2:?'--category requires value'}"; shift 2 ;;
            --json)         DOC_JSON_OUTPUT=true; shift ;;
            --quiet|-q)     DOC_QUIET=true; shift ;;
            --debug)        ASH_LOG_LEVEL="DEBUG"; shift ;;
            --help|-h)      doctor::help; return 0 ;;
            *)              break ;;
        esac
    done

    mkdir -p "${DOC_STATE_DIR}" "${DOC_REPORT_DIR}"

    local subcmd="${1:-quick}"
    shift || true

    case "${subcmd}" in
        quick)   source "${_DOC_DIR}/quick.sh";  doctor::quick  "$@" ;;
        full)    source "${_DOC_DIR}/full.sh";   doctor::full   "$@" ;;
        fix)     source "${_DOC_DIR}/fix.sh";    doctor::fix    "$@" ;;
        report)  source "${_DOC_DIR}/report.sh"; doctor::report "$@" ;;
        help|--help|-h) doctor::help ;;
        *)
            log::error "Unknown subcommand: '${subcmd}'"
            log::info  "Run ${BOLD}ash doctor --help${RST} for usage"
            return 1
            ;;
    esac
}

# Executing this file directly still works; sourcing it — which is how the
# dispatcher loads it — must only define the entry point. The unconditional
# `doctor::main "$@"` that used to sit here ran the entire command at source time.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    doctor::main "$@"
fi

# ── Dispatcher entry point ────────────────────────────────────────────────────
# The ash dispatcher sources this file and calls ash_cmd_<category>. Without
# this function the command reported "Command function not found" after already
# having run itself once at source time.
ash_cmd_doctor() {
    doctor::main "$@"
}
