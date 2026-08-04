#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — MODE LIST                                        ║
# ║  /ash-cli/commands/mode/list.sh                                              ║
# ║                                                                              ║
# ║  Display all available modes with rich formatting:                           ║
# ║  • Built-in modes with descriptions and status                               ║
# ║  • Custom user modes from ~/.local/share/ash/modes/custom                    ║
# ║  • Current active mode highlighted                                           ║
# ║  • JSON output support for scripting                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__list_format="table"   # table|compact|json|minimal
__list_show_custom=true
__list_filter=""

__list_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --json)             __list_format="json"    ; ASH_JSON_OUTPUT=true ; shift ;;
            --compact)          __list_format="compact"  ; shift ;;
            --minimal)          __list_format="minimal"  ; shift ;;
            --no-custom)        __list_show_custom=false ; shift ;;
            --filter|-f)
                __list_filter="${2:?}"
                shift 2
                ;;
            --verbose)          ASH_VERBOSE=true         ; shift ;;
            *)                  shift ;;
        esac
    done
}

# Render table format
__list_render_table() {
    local current_mode
    current_mode="$(ash_mode_get_current)"

    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    local box_width=$(( term_width < 88 ? term_width - 4 : 84 ))

    printf '\n'

    # ── Header ───────────────────────────────────────────────────────────────
    printf "${COLOR_ASH_PRIMARY}${MODE_COLOR_BOLD}"
    printf "  %-6s  %-20s  %-42s  %s\n" \
        "ICON" "MODE" "DESCRIPTION" "STATUS"
    printf "  %s\n" "$(printf '─%.0s' $(seq 1 $(( box_width - 2 ))))"
    printf "${MODE_COLOR_RESET}"

    # ── Built-in Modes ────────────────────────────────────────────────────────
    for mode in "${ASH_BUILTIN_MODES[@]}"; do
        # Apply filter
        if [[ -n "${__list_filter}" ]]; then
            [[ "${mode}" =~ ${__list_filter} ]] || continue
        fi

        local icon="${MODE_ICONS[$mode]:-  }"
        local accent="${MODE_ACCENT_COLORS[$mode]:-${COLOR_ASH_TEXT}}"
        local desc="${MODE_DESCRIPTIONS[$mode]:-}"
        local status=""
        local status_color="${COLOR_ASH_MUTED}"

        # Truncate description
        local desc_short
        desc_short="${desc:0:40}"
        [[ "${#desc}" -gt 40 ]] && desc_short="${desc_short}…"

        # Mark current mode
        if [[ "${mode}" == "${current_mode}" ]]; then
            status="● active"
            status_color="${COLOR_ASH_SUCCESS}"
        fi

        printf "  ${accent}${MODE_COLOR_BOLD}%-6s${MODE_COLOR_RESET}  " "${icon}"
        printf "${accent}${MODE_COLOR_BOLD}%-20s${MODE_COLOR_RESET}  " "${mode}"
        printf "${COLOR_ASH_MUTED}%-42s${MODE_COLOR_RESET}  " "${desc_short}"
        printf "${status_color}%s${MODE_COLOR_RESET}\n" "${status}"
    done

    # ── Custom Modes ──────────────────────────────────────────────────────────
    if [[ "${__list_show_custom}" == "true" ]] && \
       [[ -d "${ASH_MODE_CUSTOM_DIR}" ]]; then
        local -a custom_modes=()
        while IFS= read -r -d '' dir; do
            local name
            name="$(basename "${dir}")"
            [[ -f "${dir}/init.sh" ]] && custom_modes+=("${name}")
        done < <(find "${ASH_MODE_CUSTOM_DIR}" -maxdepth 1 -mindepth 1 \
            -type d -print0 2>/dev/null)

        if [[ "${#custom_modes[@]}" -gt 0 ]]; then
            printf '\n'
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
                local custom_icon=" "

                if [[ -f "${config_file}" ]]; then
                    custom_desc=$(ash_json_get "${config_file}" ".description" \
                        2>/dev/null || echo "Custom mode")
                    custom_icon=$(ash_json_get "${config_file}" ".icon" \
                        2>/dev/null || echo " ")
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