#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — MODE LIST                                         ║
# ║  /ash-cli/commands/mode/list.sh                                               ║
# ║                                                                              ║
# ║  List all available modes:                                                    ║
# ║  • Built-in modes with icons and descriptions                                 ║
# ║  • Custom modes from ~/.local/share/ash/modes/custom                          ║
# ║  • Active mode highlighted                                                   ║
# ║  • Formats: table (default), compact, minimal, json                           ║
# ║  • Regex filter support                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode list [options]
#
# OPTIONS:
#   --format <table|compact|minimal|json>   Output format
#   --filter <regex>                        Filter modes by name
#   --no-custom                             Hide custom modes
#
# EXAMPLES:
#   ash mode list
#   ash mode list --format json
#   ash mode list --filter ^b

set -euo pipefail

__list_format="table"
__list_filter=""
__list_show_custom=true

__list_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --format)
                __list_format="${2:?--format requires a value}"
                shift 2
                ;;
            --filter)
                __list_filter="${2:?--filter requires a value}"
                shift 2
                ;;
            --no-custom)    __list_show_custom=false  ; shift ;;
            --json)         __list_format="json"      ; shift ;;
            --compact)      __list_format="compact"   ; shift ;;
            --minimal)      __list_format="minimal"   ; shift ;;
            --verbose)      ASH_VERBOSE=true          ; shift ;;
            --help|-h)
                printf "  ${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}%s MODE LIST${MODE_COLOR_RESET}\n" \
                    "${MODE_ICONS[default]}"
                printf "  ${COLOR_ASH_MUTED}List available modes (built-in + custom)${MODE_COLOR_RESET}\n"
                return 0
                ;;
            *)              shift ;;
        esac
    done
}

# Render the human-readable table
__list_render_table() {
    local current_mode
    current_mode="$(ash_mode_get_current)"

    printf '\n'
    printf "  ${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}Built-in Modes${MODE_COLOR_RESET}\n"
    printf "  %s\n" "$(printf '─%.0s' $(seq 1 40))"

    for mode in "${ASH_BUILTIN_MODES[@]}"; do
        # Apply filter
        if [[ -n "${__list_filter}" ]]; then
            [[ "${mode}" =~ ${__list_filter} ]] || continue
        fi

        local desc="${MODE_DESCRIPTIONS[$mode]:-}"

        local desc_short="${desc:0:40}"
        [[ "${#desc}" -gt 40 ]] && desc_short="${desc_short}…"

        local status=""
        local status_color="${COLOR_ASH_MUTED}"
        [[ "${mode}" == "${current_mode}" ]] && {
            status="● active"
            status_color="${COLOR_ASH_SUCCESS}"
        }

        printf "  ${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_PRIMARY}}${MODE_COLOR_BOLD}%-6s${MODE_COLOR_RESET}  " \
            "${MODE_ICONS[$mode]:-󰋙 }"
        printf "${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_PRIMARY}}%-20s${MODE_COLOR_RESET}  " "${mode}"
        printf "${COLOR_ASH_MUTED}%-42s${MODE_COLOR_RESET}  " "${desc_short}"
        printf "${status_color}%s${MODE_COLOR_RESET}\n" "${status}"
    done

    # ── Custom Modes ─────────────────────────────────────────────────────────
    if [[ "${__list_show_custom}" == "true" ]]; then
        local -a custom_modes=()
        if [[ -d "${ASH_MODE_CUSTOM_DIR}" ]]; then
            while IFS= read -r -d '' dir; do
                [[ -f "${dir}/init.sh" ]] && custom_modes+=("$(basename "${dir}")")
            done < <(find "${ASH_MODE_CUSTOM_DIR}" -maxdepth 1 -mindepth 1 \
                -type d -print0 2>/dev/null)
        fi

        if [[ ${#custom_modes[@]} -gt 0 ]]; then
            printf "  ${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}Custom Modes${MODE_COLOR_RESET}\n"
            printf "  %s\n" "$(printf '─%.0s' $(seq 1 40))"

            for name in "${custom_modes[@]}"; do
                # Apply filter
                if [[ -n "${__list_filter}" ]]; then
                    [[ "${name}" =~ ${__list_filter} ]] || continue
                fi

                # Read config.json for metadata
                local config_file="${ASH_MODE_CUSTOM_DIR}/${name}/config.json"
                local custom_desc="Custom mode"
                local custom_icon="󰋙 "

                if [[ -f "${config_file}" ]]; then
                    custom_desc=$(ash_json_get "${config_file}" ".description" \
                        2>/dev/null || echo "Custom mode")
                    custom_icon=$(ash_json_get "${config_file}" ".icon" \
                        2>/dev/null || echo "󰋙 ")
                fi

                local desc_short="${custom_desc:0:40}"
                [[ "${#custom_desc}" -gt 40 ]] && desc_short="${desc_short}…"

                local status=""
                local status_color="${COLOR_ASH_MUTED}"
                [[ "${name}" == "${current_mode}" ]] && {
                    status="● active"
                    status_color="${COLOR_ASH_SUCCESS}"
                }

                printf "  ${COLOR_ASH_WARNING}${MODE_COLOR_BOLD}%-6s${MODE_COLOR_RESET}  " \
                    "${custom_icon}"
                printf "${COLOR_ASH_WARNING}%-20s${MODE_COLOR_RESET}  " "${name}"
                printf "${COLOR_ASH_MUTED}%-42s${MODE_COLOR_RESET}  " "${desc_short}"
                printf "${status_color}%s${MODE_COLOR_RESET}\n" "${status}"
            done
        fi
    fi

    printf '\n'
    printf "  ${COLOR_ASH_MUTED}Total: %d built-in" "${#ASH_BUILTIN_MODES[@]}"
    if [[ "${__list_show_custom}" == "true" ]]; then
        local custom_count=0
        [[ -d "${ASH_MODE_CUSTOM_DIR}" ]] && \
            custom_count=$(find "${ASH_MODE_CUSTOM_DIR}" -maxdepth 1 -mindepth 1 \
                -type d 2>/dev/null | wc -l)
        printf " + %d custom" "${custom_count}"
    fi
    printf "${MODE_COLOR_RESET}\n\n"
}

# Render JSON format
__list_render_json() {
    local current_mode
    current_mode="$(ash_mode_get_current)"

    printf '{\n'
    printf '  "current": "%s",\n' "${current_mode}"
    printf '  "built_in": [\n'

    local -i i=0
    local -i total=${#ASH_BUILTIN_MODES[@]}

    for mode in "${ASH_BUILTIN_MODES[@]}"; do
        (( i++ ))
        local comma=","
        [[ "${i}" -eq "${total}" ]] && comma=""
        printf '    {\n'
        printf '      "name": "%s",\n' "${mode}"
        printf '      "icon": "%s",\n' "${MODE_ICONS[$mode]:-}"
        printf '      "description": "%s",\n' "${MODE_DESCRIPTIONS[$mode]:-}"
        printf '      "active": %s\n' "$([[ "${mode}" == "${current_mode}" ]] && echo true || echo false)"
        printf '    }%s\n' "${comma}"
    done

    printf '  ],\n'
    printf '  "custom": [\n'

    # Custom modes
    local -a custom_found=()
    if [[ -d "${ASH_MODE_CUSTOM_DIR}" ]]; then
        while IFS= read -r -d '' dir; do
            [[ -f "${dir}/init.sh" ]] && custom_found+=("$(basename "${dir}")")
        done < <(find "${ASH_MODE_CUSTOM_DIR}" -maxdepth 1 -mindepth 1 \
            -type d -print0 2>/dev/null)
    fi

    local -i j=0
    local -i ctotal=${#custom_found[@]}

    for name in "${custom_found[@]}"; do
        (( j++ ))
        local comma=","
        [[ "${j}" -eq "${ctotal}" ]] && comma=""
        printf '    {"name":"%s","active":%s}%s\n' \
            "${name}" \
            "$([[ "${name}" == "${current_mode}" ]] && echo true || echo false)" \
            "${comma}"
    done

    printf '  ]\n}\n'
}

# Compact one-line-per-mode format
__list_render_compact() {
    local current_mode
    current_mode="$(ash_mode_get_current)"

    for mode in "${ASH_BUILTIN_MODES[@]}"; do
        [[ -n "${__list_filter}" ]] && \
            [[ ! "${mode}" =~ ${__list_filter} ]] && continue

        local prefix="  "
        [[ "${mode}" == "${current_mode}" ]] && \
            prefix="${COLOR_ASH_SUCCESS}● ${MODE_COLOR_RESET}"

        printf "%s${MODE_ACCENT_COLORS[$mode]:-}%s ${MODE_ICONS[$mode]:-}${MODE_COLOR_RESET}\n" \
            "${prefix}" "${mode}"
    done
}

ash_list_mode_main() {
    __list_parse_args "$@"

    case "${__list_format}" in
        json)    __list_render_json    ;;
        compact) __list_render_compact ;;
        minimal)
            for mode in "${ASH_BUILTIN_MODES[@]}"; do
                printf '%s\n' "${mode}"
            done
            ;;
        *)       __list_render_table   ;;
    esac
}

ash_list_mode_main "$@"