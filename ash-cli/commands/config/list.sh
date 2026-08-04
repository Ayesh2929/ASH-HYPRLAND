#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG LIST                                            ║
# ║  Rich interactive config browser with section grouping, filter & search           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::list::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config list [section] [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${ASH_ACCENT}section${RST}   Filter by section (e.g. theme, hyprland, ai)

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--search,  -s QUERY${RST}  Search keys and descriptions
  ${ASH_MUTED}--modified${RST}           Show only keys that differ from defaults
  ${ASH_MUTED}--defaults${RST}           Show default values instead of current
  ${ASH_MUTED}--json${RST}              Output as JSON array
  ${ASH_MUTED}--no-defaults${RST}        Hide unset keys
  ${ASH_MUTED}--compact,   -c${RST}      One-line-per-key compact view
  ${ASH_MUTED}--help,      -h${RST}      Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config list
  ash config list theme
  ash config list --modified
  ash config list --search blur
  ash config list hyprland --json
EOF
}

# ── Section header ─────────────────────────────────────────────────────────────
_list::section_header() {
    local section="$1"
    printf '\n  %s━━━  %s%s%s  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' \
        "${ASH_PRIMARY}" "${BOLD}${ASH_PRIMARY}" "${section}" "${ASH_PRIMARY}" "${RST}"
}

# ── Single key row (compact) ───────────────────────────────────────────────────
_list::row_compact() {
    local key="$1" current="$2" default_val="$3" type="$4"
    local is_modified="$5"  # true|false

    local effective; [[ -n "${current}" ]] && effective="${current}" || effective="${default_val}"
    local val_color; val_color=$(_get::value_color "${type}" "${effective}" 2>/dev/null || printf '%s' "${ASH_INFO}")
    local mod_ico=""
    [[ "${is_modified}" == "true" ]] && mod_ico="${ASH_WARNING}●${RST} "

    printf '  %s%-45s%s  %s%s%-20s%s\n' \
        "${ASH_MUTED}" "${key}" "${RST}" \
        "${mod_ico}" \
        "${val_color}${BOLD}" "$(ash_truncate "${effective:-<empty>}" 20)" "${RST}"
}

# ── Single key card (detailed) ────────────────────────────────────────────────
_list::row_card() {
    local key="$1" current="$2" default_val="$3" type="$4" desc="$5"

    local effective source_label
    if [[ -n "${current}" ]]; then
        effective="${current}"; source_label="set"
    else
        effective="${default_val}"; source_label="default"
    fi

    local val_color; val_color=$(_get::value_color "${type}" "${effective}" 2>/dev/null || printf '%s' "${ASH_INFO}")
    local is_modified=false
    [[ -n "${current}" ]] && [[ "${current}" != "${default_val}" ]] && is_modified=true

    local mod_badge=""
    [[ "${is_modified}" == "true" ]] && mod_badge=" ${ASH_WARNING}●modified${RST}"
    [[ "${source_label}" == "default" ]] && mod_badge=" ${ASH_MUTED}(default)${RST}"

    printf '  %s%-45s%s  %s%s%s%s\n' \
        "${ASH_INFO}" "${key}" "${RST}" \
        "${val_color}${BOLD}" "$(ash_truncate "${effective:-<empty>}" 24)" "${RST}" \
        "${mod_badge}"

    printf '  %s  %-43s%s  %s%s%s\n' \
        "${ASH_MUTED}" "${desc:0:43}" "${RST}" \
        "${ASH_MUTED}" "$(_get::type_badge "${type}" 2>/dev/null)" "${RST}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::list() {
    local section_filter="" search="" modified_only=false
    local show_defaults=false json_out=false no_defaults=false compact=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)     config::list::help; return 0 ;;
            --search|-s)   search="${2:?'--search requires QUERY'}"; shift 2 ;;
            --modified)    modified_only=true; shift ;;
            --defaults)    show_defaults=true; shift ;;
            --json)        json_out=true; shift ;;
            --no-defaults) no_defaults=true; shift ;;
            --compact|-c)  compact=true; shift ;;
            -*)            log::error "Unknown option: $1"; return 1 ;;
            *)             section_filter="$1"; shift ;;
        esac
    done

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Build entry list ──────────────────────────────────────────────────────
    local prev_section="" total=0 modified_count=0
    local json_entries=()

    # Compact header
    if [[ "${compact}" == "false" ]] && [[ "${json_out}" == "false" ]]; then
        log::blank
        local total_keys="${#CFG_SCHEMA[@]}"
        local file_size; file_size=$(du -sh "${file}" 2>/dev/null | awk '{print $1}' || echo "?")
        ash_banner "⚙  ASH CONFIGURATION" \
            "${total_keys} keys • ${file_size} • ${file}" 72
    fi

    if [[ "${compact}" == "true" ]] && [[ "${json_out}" == "false" ]]; then
        printf '  %s%-45s  %-20s%s\n' \
            "${BOLD}${ASH_MUTED}" "Key" "Value" "${RST}"
        ash_hr "─" 70 "${ASH_MUTED}"
    fi

    for schema_line in "${CFG_SCHEMA[@]}"; do
        IFS='|' read -ra parts <<< "${schema_line}"
        local key="${parts[0]}" type="${parts[1]}" default_val="${parts[2]}"
        local desc="${parts[3]}"

        local section; section=$(printf '%s' "${key}" | cut -d. -f1)

        # Section filter
        [[ -n "${section_filter}" ]] && [[ "${section}" != "${section_filter}" ]] && continue

        # Search filter
        if [[ -n "${search}" ]]; then
            local search_lower="${search,,}"
            local key_lower="${key,,}" desc_lower="${desc,,}"
            [[ "${key_lower}" != *"${search_lower}"* ]] && \
            [[ "${desc_lower}" != *"${search_lower}"* ]] && continue
        fi

        local current; current=$(cfg::_read_raw "${key}" "${file}")

        # Modified filter
        if [[ "${modified_only}" == "true" ]]; then
            [[ -z "${current}" ]] && continue
            [[ "${current}" == "${default_val}" ]] && continue
        fi

        # No-defaults filter
        if [[ "${no_defaults}" == "true" ]] && [[ -z "${current}" ]]; then
            continue
        fi

        local is_modified=false
        [[ -n "${current}" ]] && [[ "${current}" != "${default_val}" ]] && is_modified=true

        local effective="${current:-${default_val}}"
        [[ "${show_defaults}" == "true" ]] && effective="${default_val}"

        (( total++ ))
        [[ "${is_modified}" == "true" ]] && (( modified_count++ ))

        # JSON accumulate
        if [[ "${json_out}" == "true" ]]; then
            json_entries+=("$(jq -n \
                --arg key     "${key}" \
                --arg value   "${effective}" \
                --arg current "${current}" \
                --arg default "${default_val}" \
                --arg type    "${type}" \
                --arg desc    "${desc}" \
                --arg section "${section}" \
                --argjson mod "${is_modified}" \
                '{key:$key,value:$value,current:$current,default:$default,
                  type:$type,description:$desc,section:$section,modified:$mod}')")
            continue
        fi

        # Section header (grouped, not compact)
        if [[ "${compact}" == "false" ]]; then
            if [[ "${section}" != "${prev_section}" ]]; then
                _list::section_header "${section}"
                prev_section="${section}"
            fi
            _list::row_card "${key}" "${current}" "${default_val}" "${type}" "${desc}"
        else
            _list::row_compact "${key}" "${current}" "${default_val}" "${type}" "${is_modified}"
        fi
    done

    # ── JSON output ───────────────────────────────────────────────────────────
    if [[ "${json_out}" == "true" ]]; then
        printf '[\n'
        local idx=0
        for e in "${json_entries[@]}"; do
            (( idx++ ))
            printf '  %s%s\n' "${e}" \
                "$( (( idx < ${#json_entries[@]} )) && printf ',' || true )"
        done
        printf ']\n'
        return 0
    fi

    # ── Footer ────────────────────────────────────────────────────────────────
    log::blank
    ash_hr "─" 70 "${ASH_MUTED}"
    printf '  %s%d keys shown' "${ASH_MUTED}" "${total}"
    (( modified_count > 0 )) && \
        printf '  •  %s%d modified%s' "${ASH_WARNING}" "${modified_count}" "${RST}"
    printf '%s\n' "${RST}"
    [[ -n "${search}" ]] && \
        printf '  %sSearch: "%s"%s\n' "${ASH_INFO}" "${search}" "${RST}"
    log::blank
}
