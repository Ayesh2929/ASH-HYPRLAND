#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — MODE STATUS                                      ║
# ║  /ash-cli/commands/mode/status.sh                                            ║
# ║                                                                              ║
# ║  Rich status display for the current active mode:                            ║
# ║  • Mode name, icon, and description                                          ║
# ║  • Uptime since activation                                                   ║
# ║  • Auto-revert countdown if scheduled                                        ║
# ║  • Active settings summary                                                   ║
# ║  • Hardware context (GPU vendor, power source)                               ║
# ║  • JSON output support                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__status_verbose=false
__status_format="rich"   # rich|minimal|json|oneline

__status_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --verbose|-v)   __status_verbose=true   ; shift ;;
            --json)         __status_format="json"  ; ASH_JSON_OUTPUT=true ; shift ;;
            --minimal|-m)   __status_format="minimal" ; shift ;;
            --oneline|-1)   __status_format="oneline" ; shift ;;
            *)              shift ;;
        esac
    done
}

# Calculate human-readable uptime from an ISO 8601 timestamp
__status_calculate_uptime() {
    local since="${1}"
    local now_epoch
    local then_epoch

    now_epoch=$(date -u +%s)

    # Parse ISO 8601 — GNU date and BSD date compatible
    if date --version &>/dev/null 2>&1; then
        # GNU date
        then_epoch=$(date -u -d "${since}" +%s 2>/dev/null || echo "${now_epoch}")
    else
        # BSD/macOS date
        then_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${since}" +%s 2>/dev/null \
            || echo "${now_epoch}")
    fi

    local elapsed=$(( now_epoch - then_epoch ))

    if   (( elapsed < 60 ));    then printf '%ds' "${elapsed}"
    elif (( elapsed < 3600 ));  then printf '%dm %ds' $(( elapsed/60 )) $(( elapsed%60 ))
    elif (( elapsed < 86400 )); then printf '%dh %dm' $(( elapsed/3600 )) $(( elapsed%3600/60 ))
    else                             printf '%dd %dh' $(( elapsed/86400 )) $(( elapsed%86400/3600 ))
    fi
}

# Render the rich status panel
__status_render_rich() {
    local current_mode
    local previous_mode
    local activated_at
    local duration

    current_mode="$(ash_mode_get_current)"
    previous_mode=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".previous_mode" \
        2>/dev/null || echo "unknown")
    activated_at=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".activated_at" \
        2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    duration=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".duration" \
        2>/dev/null || echo "null")

    local accent="${MODE_ACCENT_COLORS[$current_mode]:-${COLOR_ASH_PRIMARY}}"
    local icon="${MODE_ICONS[$current_mode]:-🖥️}"
    local emoji="${MODE_STATUS_EMOJI[$current_mode]:-🖥️}"
    local uptime
    uptime="$(__status_calculate_uptime "${activated_at}")"

    local gpu_vendor power_source monitor_count
    gpu_vendor="$(ash_mode_detect_gpu)"
    power_source="$(ash_mode_detect_power_source)"
    monitor_count="$(ash_mode_get_monitor_count)"

    printf '\n'

    # ── Mode Card ────────────────────────────────────────────────────────────
    printf "${accent}${MODE_COLOR_BOLD}"
    printf '  ╭─────────────────────────────────────────────╮\n'
    printf '  │  %-43s│\n' \
        "${icon} ${current_mode^^} MODE — ACTIVE"
    printf '  │  %-43s│\n' \
        "$(printf '%.43s' "${MODE_DESCRIPTIONS[$current_mode]:-}")"
    printf '  ╰─────────────────────────────────────────────╯\n'
    printf "${MODE_COLOR_RESET}\n"

    # ── Key Metrics ──────────────────────────────────────────────────────────
    local -a keys=(
        "Active for"
        "Previous mode"
        "Auto-revert"
        "Power source"
        "GPU vendor"
        "Monitors"
    )
    local -a values=(
        "${uptime}"
        "${previous_mode:-none}"
        "$([[ "${duration}" == "null" ]] && echo "disabled" || echo "${duration}")"
        "${power_source}"
        "${gpu_vendor}"
        "${monitor_count}"
    )

    for i in "${!keys[@]}"; do
        printf "  ${COLOR_ASH_MUTED}%-18s${MODE_COLOR_RESET}" "${keys[$i]}"
        printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" "${values[$i]}"
    done

    printf '\n'

    # ── Current Settings Summary (verbose only) ──────────────────────────────
    if [[ "${__status_verbose}" == "true" ]]; then
        printf "  ${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}ACTIVE SETTINGS${MODE_COLOR_RESET}\n"

        # Read live Hyprland values
        if command -v hyprctl &>/dev/null; then
            local anim_enabled blur_enabled shadow_enabled rounding
            anim_enabled=$(hyprctl getoption animations:enabled -j 2>/dev/null \
                | python3 -c "import sys,json; print(json.load(sys.stdin).get('int',1))" \
                2>/dev/null || echo "?")
            blur_enabled=$(hyprctl getoption decoration:blur:enabled -j 2>/dev/null \
                | python3 -c "import sys,json; print(json.load(sys.stdin).get('int',1))" \
                2>/dev/null || echo "?")

            printf "  ${COLOR_ASH_MUTED}%-22s${MODE_COLOR_RESET}" "Animations"
            printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" \
                "$([[ "${anim_enabled}" == "1" ]] && echo "enabled" || echo "disabled")"

            printf "  ${COLOR_ASH_MUTED}%-22s${MODE_COLOR_RESET}" "Blur"
            printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" \
                "$([[ "${blur_enabled}" == "1" ]] && echo "enabled" || echo "disabled")"
        fi

        # DND status
        local dnd_status="unknown"
        if command -v dunstctl &>/dev/null; then
            dnd_status=$(dunstctl is-paused 2>/dev/null | \
                awk '{print ($1=="true") ? "on" : "off"}')
        fi
        printf "  ${COLOR_ASH_MUTED}%-22s${MODE_COLOR_RESET}" "Do Not Disturb"
        printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" "${dnd_status}"

        # CPU governor
        local gov="unknown"
        gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
        printf "  ${COLOR_ASH_MUTED}%-22s${MODE_COLOR_RESET}" "CPU Governor"
        printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" "${gov}"

        printf '\n'
    fi

    # ── Quick Actions ────────────────────────────────────────────────────────
    printf "  ${COLOR_ASH_MUTED}Switch:  ${COLOR_ASH_INFO}ash mode <name>${MODE_COLOR_RESET}  "
    printf "  ${COLOR_ASH_MUTED}Reset:   ${COLOR_ASH_INFO}ash mode default${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_MUTED}List:    ${COLOR_ASH_INFO}ash mode list${MODE_COLOR_RESET}\n\n"
}

# One-line compact status
__status_render_oneline() {
    local current_mode
    current_mode="$(ash_mode_get_current)"
    local icon="${MODE_ICONS[$current_mode]:-}"
    local activated_at
    activated_at=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".activated_at" \
        2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    local uptime
    uptime="$(__status_calculate_uptime "${activated_at}")"

    printf "%s%s (%s)\n" "${icon}" "${current_mode}" "${uptime}"
}

# JSON status output
__status_render_json() {
    local current_mode activated_at duration previous_mode
    current_mode="$(ash_mode_get_current)"
    activated_at=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".activated_at" \
        2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    duration=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".duration" \
        2>/dev/null || echo "null")
    previous_mode=$(ash_json_get "${ASH_MODE_STATE_FILE}" ".previous_mode" \
        2>/dev/null || echo "null")

    local uptime
    uptime="$(__status_calculate_uptime "${activated_at}")"

    printf '{\n'
    printf '  "mode": "%s",\n' "${current_mode}"
    printf '  "icon": "%s",\n' "${MODE_ICONS[$current_mode]:-}"
    printf '  "description": "%s",\n' "${MODE_DESCRIPTIONS[$current_mode]:-}"
    printf '  "previous": "%s",\n' "${previous_mode}"
    printf '  "activated_at": "%s",\n' "${activated_at}"
    printf '  "uptime": "%s",\n' "${uptime}"
    printf '  "duration": %s,\n' "${duration}"
    printf '  "hardware": {\n'
    printf '    "gpu": "%s",\n' "$(ash_mode_detect_gpu)"
    printf '    "power_source": "%s",\n' "$(ash_mode_detect_power_source)"
    printf '    "monitors": %s\n' "$(ash_mode_get_monitor_count)"
    printf '  }\n'
    printf '}\n'
}

ash_status_mode_main() {
    __status_parse_args "$@"

    # Ensure state file exists
    if [[ ! -f "${ASH_MODE_STATE_FILE}" ]]; then
        ash_mode_init_state
    fi

    case "${__status_format}" in
        json)    __status_render_json    ;;
        minimal) __status_render_oneline ;;
        oneline) __status_render_oneline ;;
        *)       __status_render_rich    ;;
    esac
}

ash_status_mode_main "$@"