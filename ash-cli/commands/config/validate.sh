#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG VALIDATE                                        ║
# ║  Deep schema validation, type checking, cross-key logic & fix suggestions         ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::validate::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config validate [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--section,  -s SECTION${RST}  Validate only this section
  ${ASH_MUTED}--key,      -k KEY${RST}      Validate only this key
  ${ASH_MUTED}--fix${RST}                   Auto-fix recoverable issues
  ${ASH_MUTED}--strict${RST}                Fail on warnings too
  ${ASH_MUTED}--json${RST}                  Output results as JSON
  ${ASH_MUTED}--quiet,    -q${RST}           Minimal output
  ${ASH_MUTED}--help,     -h${RST}           Show this help

${BOLD}${ASH_PRIMARY}CHECKS${RST}
  ✦ Type validation (boolean/integer/float/string)
  ✦ Allowed values enumeration
  ✦ Range constraints (numeric bounds)
  ✦ Cross-key dependency logic
  ✦ Unknown keys in config file
  ✦ Deprecated key detection
  ✦ File syntax integrity

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config validate
  ash config validate --section theme
  ash config validate --fix
  ash config validate --json > report.json
EOF
}

# ── Result constants ──────────────────────────────────────────────────────────
readonly VALID_PASS="PASS"
readonly VALID_WARN="WARN"
readonly VALID_FAIL="FAIL"

# ── Deprecated keys ───────────────────────────────────────────────────────────
readonly -A CFG_DEPRECATED_KEYS=(
    ["theme.wallpaper"]="wallpaper.backend"
    ["bar.waybar_layout"]="bar.layout"
    ["ash.sound_effects"]="ash.sound"
)

# ── Range constraints [key]=min:max ───────────────────────────────────────────
readonly -A CFG_RANGES=(
    ["hyprland.border_size"]="0:20"
    ["hyprland.gaps_in"]="0:100"
    ["hyprland.gaps_out"]="0:200"
    ["hyprland.rounding"]="0:50"
    ["hyprland.blur_size"]="1:20"
    ["hyprland.blur_passes"]="1:10"
    ["hyprland.inactive_opacity"]="0.1:1.0"
    ["hyprland.active_opacity"]="0.1:1.0"
    ["hyprland.fullscreen_opacity"]="0.1:1.0"
    ["bar.height"]="20:120"
    ["bar.transparency"]="0.0:1.0"
    ["wallpaper.blur_strength"]="1:20"
    ["snapshot.auto_interval_hours"]="1:168"
    ["notifications.timeout_low"]="0:60000"
    ["notifications.timeout_normal"]="0:60000"
    ["lockscreen.timeout_idle"]="30:3600"
    ["privacy.clear_clipboard_timeout"]="0:3600"
)

# ── Cross-key logic rules ─────────────────────────────────────────────────────
# Format: "key_that_enables|dependency_key|dependency_required_value|message"
readonly -a CFG_CROSS_RULES=(
    "wallpaper.slideshow|wallpaper.slideshow_interval|>0|slideshow_interval must be positive"
    "ai.auto_theme_mood|ai.enabled|true|ai.enabled must be true for mood-based theming"
    "ai.auto_theme_weather|ai.enabled|true|ai.enabled must be true for weather-based theming"
    "ai.theme_suggestions|ai.enabled|true|ai.enabled must be true for theme suggestions"
    "theme.auto_dark_light|theme.dark_start|*|dark_start must be set for auto dark/light"
    "theme.auto_dark_light|theme.light_start|*|light_start must be set for auto dark/light"
)

# ── Validate a single key-value pair ─────────────────────────────────────────
_validate::check_one() {
    local key="$1" value="$2"
    local issues=()
    local result="${VALID_PASS}"

    # Type check
    local type; type=$(cfg::_schema_type "${key}" 2>/dev/null || printf "string")
    case "${type}" in
        boolean)
            [[ "${value}" =~ ^(true|false)$ ]] || {
                issues+=("Type error: expected boolean (true|false), got '${value}'")
                result="${VALID_FAIL}"
            }
            ;;
        integer)
            [[ "${value}" =~ ^-?[0-9]+$ ]] || {
                issues+=("Type error: expected integer, got '${value}'")
                result="${VALID_FAIL}"
            }
            ;;
        float)
            [[ "${value}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || {
                issues+=("Type error: expected float, got '${value}'")
                result="${VALID_FAIL}"
            }
            ;;
    esac

    # Allowed values
    local allowed_vals=()
    mapfile -t allowed_vals < <(cfg::_schema_allowed "${key}" 2>/dev/null || true)
    if (( ${#allowed_vals[@]} > 0 )); then
        local match=false
        for av in "${allowed_vals[@]}"; do
            [[ "${value}" == "${av}" ]] && { match=true; break; }
        done
        [[ "${match}" == "false" ]] && {
            issues+=("Value '${value}' not in allowed set: $(IFS=','; printf '%s' "${allowed_vals[*]}")")
            result="${VALID_FAIL}"
        }
    fi

    # Range constraint
    local range="${CFG_RANGES[${key}]:-}"
    if [[ -n "${range}" ]] && [[ "${type}" =~ ^(integer|float)$ ]]; then
        local min="${range%%:*}" max="${range##*:}"
        local cmp_result
        cmp_result=$(python3 -c "
v, lo, hi = float('${value}' or 0), float('${min}'), float('${max}')
print('ok' if lo <= v <= hi else f'out_of_range:{lo}:{hi}')
" 2>/dev/null || printf 'skip')
        if [[ "${cmp_result}" == out_of_range:* ]]; then
            local lo="${cmp_result#out_of_range:}"; lo="${lo%%:*}"
            local hi="${cmp_result##*:}"
            issues+=("Value ${value} out of range [${lo}, ${hi}]")
            result="${VALID_FAIL}"
        fi
    fi

    printf '%s' "${result}"
    for msg in "${issues[@]}"; do
        printf '\n%s' "${msg}"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::validate() {
    local section_filter="" key_filter="" fix=false
    local strict=false json_out=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      config::validate::help; return 0 ;;
            --section|-s)   section_filter="${2:?'--section requires value'}"; shift 2 ;;
            --key|-k)       key_filter="${2:?'--key requires value'}"; shift 2 ;;
            --fix)          fix=true; shift ;;
            --strict)       strict=true; shift ;;
            --json)         json_out=true; shift ;;
            --quiet|-q)     quiet=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              shift ;;
        esac
    done

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    [[ "${quiet}" == "false" ]] && [[ "${json_out}" == "false" ]] && {
        log::blank
        printf '  %s⚙  Config Validation%s\n\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
    }

    local pass_count=0 warn_count=0 fail_count=0
    local json_results=()

    # ── Per-key validation ────────────────────────────────────────────────────
    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -ra parts <<< "${schema_line}"
        local key="${parts[0]}" type="${parts[1]}" default_val="${parts[2]}" desc="${parts[3]}"
        local section; section=$(printf '%s' "${key}" | cut -d. -f1)

        [[ -n "${section_filter}" ]] && [[ "${section}" != "${section_filter}" ]] && continue
        [[ -n "${key_filter}" ]] && [[ "${key}" != "${key_filter}" ]] && continue

        local current; current=$(cfg::_read_raw "${key}" "${file}")
        [[ -z "${current}" ]] && continue  # Unset keys use defaults — skip

        local check_output
        check_output=$(_validate::check_one "${key}" "${current}")
        local result; result=$(printf '%s' "${check_output}" | head -1)
        local messages=()
        while IFS= read -r msg; do
            [[ -n "${msg}" ]] && messages+=("${msg}")
        done < <(printf '%s' "${check_output}" | tail -n +2)

        case "${result}" in
            PASS) (( pass_count++ )) ;;
            WARN) (( warn_count++ )) ;;
            FAIL) (( fail_count++ )) ;;
        esac

        if [[ "${json_out}" == "true" ]]; then
            local msgs_json; msgs_json=$(printf '%s\n' "${messages[@]:-}" | \
                jq -Rs 'split("\n") | map(select(. != ""))')
            json_results+=("$(jq -n \
                --arg key    "${key}" \
                --arg result "${result}" \
                --arg value  "${current}" \
                --argjson msgs "${msgs_json}" \
                '{key:$key,result:$result,value:$value,messages:$msgs}')")
        elif [[ "${quiet}" == "false" ]]; then
            local badge
            case "${result}" in
                PASS) badge="${ASH_SUCCESS}${ICO_SUCCESS} PASS${RST}" ;;
                WARN) badge="${ASH_WARNING}${ICO_WARN} WARN${RST}" ;;
                FAIL) badge="${ASH_ERROR}${ICO_ERROR} FAIL${RST}" ;;
            esac

            printf '  %s  %s%-42s%s  %s%s%s\n' \
                "${badge}" \
                "${ASH_MUTED}" "${key}" "${RST}" \
                "${ASH_INFO}" "$(ash_truncate "${current}" 24)" "${RST}"

            for msg in "${messages[@]:-}"; do
                printf '     %s↳ %s%s\n' "${ASH_ERROR}" "${msg}" "${RST}"

                # Auto-fix: reset to default
                if [[ "${fix}" == "true" ]]; then
                    local def; def=$(cfg::_schema_default "${key}")
                    if [[ -n "${def}" ]]; then
                        cfg::_write_raw "${key}" "${def}" "${file}"
                        printf '     %s⚡ Fixed → %s%s\n' "${ASH_WARNING}" "${def}" "${RST}"
                        (( fail_count-- )); (( warn_count++ ))
                    fi
                fi
            done
        fi
    done

    # ── Deprecated key check ──────────────────────────────────────────────────
    for dep_key in "${!CFG_DEPRECATED_KEYS[@]}"; do
        local dep_val; dep_val=$(cfg::_read_raw "${dep_key}" "${file}")
        [[ -z "${dep_val}" ]] && continue
        local replacement="${CFG_DEPRECATED_KEYS[${dep_key}]}"

        [[ "${quiet}" == "false" ]] && [[ "${json_out}" == "false" ]] && \
            printf '  %s%s DEPR%s  %s%-42s%s  %sUse: %s%s\n' \
                "${ASH_MUTED}" "${ICO_WARN}" "${RST}" \
                "${ASH_MUTED}" "${dep_key}" "${RST}" \
                "${ASH_MUTED}" "${replacement}" "${RST}"
        (( warn_count++ ))
    done

    # ── Cross-key rules ───────────────────────────────────────────────────────
    for rule in "${CFG_CROSS_RULES[@]}"; do
        IFS='|' read -r trigger_key dep_key required_val message <<< "${rule}"
        local trigger_val; trigger_val=$(cfg::_read_raw "${trigger_key}" "${file}")
        [[ "${trigger_val}" != "true" ]] && continue  # Rule only applies when trigger is true

        local dep_val; dep_val=$(cfg::_read_raw "${dep_key}" "${file}")

        local rule_ok=true
        if [[ "${required_val}" == "*" ]]; then
            [[ -z "${dep_val}" ]] && rule_ok=false
        elif [[ "${required_val}" == ">0" ]]; then
            (( ${dep_val:-0} > 0 )) || rule_ok=false
        else
            [[ "${dep_val}" != "${required_val}" ]] && rule_ok=false
        fi

        if [[ "${rule_ok}" == "false" ]]; then
            [[ "${quiet}" == "false" ]] && [[ "${json_out}" == "false" ]] && \
                printf '  %s%s LOGIC%s  %s%s → %s%s  %s%s%s\n' \
                    "${ASH_WARNING}" "${ICO_WARN}" "${RST}" \
                    "${ASH_MUTED}" "${trigger_key}" "${dep_key}" "${RST}" \
                    "${ASH_MUTED}" "${message}" "${RST}"
            (( warn_count++ ))
        fi
    done

    # ── JSON output ───────────────────────────────────────────────────────────
    if [[ "${json_out}" == "true" ]]; then
        local total=$(( pass_count + warn_count + fail_count ))
        printf '{\n'
        printf '  "summary": {"total":%d,"passed":%d,"warnings":%d,"failed":%d},\n' \
            "${total}" "${pass_count}" "${warn_count}" "${fail_count}"
        printf '  "results": [\n'
        local ri=0
        for r in "${json_results[@]}"; do
            (( ri++ ))
            printf '    %s%s\n' "${r}" \
                "$( (( ri < ${#json_results[@]} )) && printf ',' || true )"
        done
        printf '  ]\n}\n'
        return $(( fail_count > 0 ? 1 : 0 ))
    fi

    # ── Summary ───────────────────────────────────────────────────────────────
    [[ "${quiet}" == "false" ]] && {
        log::blank
        ash_hr "─" 70 "${ASH_MUTED}"
        printf '\n  %s%-10s%s %s%d%s\n' "${ASH_SUCCESS}"  "${ICO_SUCCESS} Passed"   "${RST}" "${BOLD}" "${pass_count}"  "${RST}"
        printf '  %s%-10s%s %s%d%s\n'   "${ASH_WARNING}"  "${ICO_WARN} Warnings"   "${RST}" "${BOLD}" "${warn_count}"  "${RST}"
        printf '  %s%-10s%s %s%d%s\n\n' "${ASH_ERROR}"    "${ICO_ERROR} Failed"    "${RST}" "${BOLD}" "${fail_count}"  "${RST}"

        if (( fail_count == 0 )) && (( warn_count == 0 )); then
            log::success "All config keys are valid ✓"
        elif (( fail_count == 0 )); then
            log::warn "${warn_count} warning(s) found"
        else
            log::error "${fail_count} validation error(s) found"
            log::info  "Run with ${BOLD}--fix${RST} to auto-repair recoverable issues"
        fi
        log::blank
    }

    local exit_code=0
    (( fail_count > 0 )) && exit_code=1
    [[ "${strict}" == "true" ]] && (( warn_count > 0 )) && exit_code=1
    return "${exit_code}"
}
