#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG GET                                             ║
# ║  Read configuration values with type display, default fallback & JSON output      ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::get::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config get <key> [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${ASH_ACCENT}key${RST}   Dot-separated config key (e.g. theme.default)

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--raw,       -r${RST}     Print raw value only (no decorations)
  ${ASH_MUTED}--json,      -j${RST}     Output as JSON object
  ${ASH_MUTED}--default,   -d${RST}     Show default value (not current)
  ${ASH_MUTED}--info,      -i${RST}     Show full key metadata (type, default, desc)
  ${ASH_MUTED}--no-default    ${RST}    Return error if key not set (no fallback)
  ${ASH_MUTED}--help,      -h${RST}     Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config get theme.default
  ash config get theme.default --raw
  ash config get theme.default --info
  ash config get hyprland.blur_enabled --json
EOF
}

# ── Value colour by type ──────────────────────────────────────────────────────
_get::value_color() {
    local type="$1" value="$2"
    case "${type}" in
        boolean)
            [[ "${value}" == "true" ]]  && printf '%s' "${ASH_SUCCESS}" || printf '%s' "${ASH_ERROR}"
            ;;
        integer|float)
            printf '%s' "${SNAP_COLOR_SIZE}"
            ;;
        string)
            printf '%s' "${SNAP_COLOR_NAME}"
            ;;
        *)
            printf '%s' "${ASH_INFO}"
            ;;
    esac
}

# ── Type badge ────────────────────────────────────────────────────────────────
_get::type_badge() {
    case "$1" in
        boolean) printf '%s bool%s'    "${ASH_SUCCESS}" "${RST}" ;;
        integer) printf '%s int%s'     "${ASH_INFO}"    "${RST}" ;;
        float)   printf '%s float%s'   "${ASH_WARNING}" "${RST}" ;;
        string)  printf '%s string%s'  "${ASH_ACCENT}"  "${RST}" ;;
        *)       printf '%s ?%s'       "${ASH_MUTED}"   "${RST}" ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::get() {
    local raw=false json_out=false show_default=false
    local info_mode=false no_default=false key=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)      config::get::help; return 0 ;;
            --raw|-r)       raw=true; shift ;;
            --json|-j)      json_out=true; shift ;;
            --default|-d)   show_default=true; shift ;;
            --info|-i)      info_mode=true; shift ;;
            --no-default)   no_default=true; shift ;;
            -*)             log::error "Unknown option: $1"; return 1 ;;
            *)              key="$1"; shift ;;
        esac
    done

    [[ -z "${key}" ]] && {
        log::error "Key is required"
        config::get::help; return 1
    }

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Resolve value ──────────────────────────────────────────────────────────
    local current_val; current_val=$(cfg::_read_raw "${key}" "${file}")
    local default_val; default_val=$(cfg::_schema_default "${key}" 2>/dev/null || true)
    local type;        type=$(cfg::_schema_type    "${key}" 2>/dev/null || printf "string")
    local desc;        desc=$(cfg::_schema_desc    "${key}" 2>/dev/null || true)

    local effective_val="${current_val}"
    local source_label="file"

    if [[ -z "${effective_val}" ]]; then
        if [[ "${no_default}" == "true" ]]; then
            log::error "Key '${key}' is not set in config"
            return 1
        fi
        effective_val="${default_val}"
        source_label="default"
    fi

    [[ "${show_default}" == "true" ]] && {
        effective_val="${default_val}"
        source_label="default"
    }

    # ── Output modes ──────────────────────────────────────────────────────────

    # Raw
    if [[ "${raw}" == "true" ]]; then
        printf '%s\n' "${effective_val}"
        return 0
    fi

    # JSON
    if [[ "${json_out}" == "true" ]]; then
        jq -n \
            --arg key     "${key}" \
            --arg value   "${effective_val}" \
            --arg type    "${type}" \
            --arg default "${default_val}" \
            --arg source  "${source_label}" \
            --arg desc    "${desc}" \
            '{key:$key,value:$value,type:$type,default:$default,source:$source,description:$desc}'
        return 0
    fi

    # Info mode — full metadata card
    if [[ "${info_mode}" == "true" ]]; then
        local allowed_vals=()
        mapfile -t allowed_vals < <(cfg::_schema_allowed "${key}" 2>/dev/null || true)

        log::blank
        printf '  %s╭─────────────────────────────────────────────────╮%s\n' \
            "${ASH_PRIMARY}" "${RST}"
        printf '  %s│%s  %s%s%s%s%*s%s│%s\n' \
            "${ASH_PRIMARY}" "${RST}" \
            "${BOLD}${ASH_INFO}" "⚙ " "${key}" "${RST}" \
            "$(( 47 - ${#key} - 2 ))" '' \
            "${ASH_PRIMARY}" "${RST}"
        printf '  %s╰─────────────────────────────────────────────────╯%s\n\n' \
            "${ASH_PRIMARY}" "${RST}"

        local val_color; val_color=$(_get::value_color "${type}" "${effective_val}")
        printf '  %s%-16s%s %s%s%s\n' \
            "${ASH_MUTED}" "Value"       "${RST}" "${val_color}${BOLD}" "${effective_val:-<empty>}" "${RST}"
        printf '  %s%-16s%s %s\n' \
            "${ASH_MUTED}" "Type"        "${RST}" "$(_get::type_badge "${type}")"
        printf '  %s%-16s%s %s%s%s\n' \
            "${ASH_MUTED}" "Default"     "${RST}" "${ASH_MUTED}" "${default_val:-<none>}" "${RST}"
        printf '  %s%-16s%s %s%s%s\n' \
            "${ASH_MUTED}" "Source"      "${RST}" \
            "$( [[ "${source_label}" == "file" ]] && printf '%s' "${ASH_SUCCESS}" || printf '%s' "${ASH_MUTED}" )" \
            "${source_label}" "${RST}"
        printf '  %s%-16s%s %s%s%s\n' \
            "${ASH_MUTED}" "Description" "${RST}" "${ASH_INFO}" "${desc}" "${RST}"

        if (( ${#allowed_vals[@]} > 0 )); then
            printf '  %s%-16s%s' "${ASH_MUTED}" "Allowed" "${RST}"
            for av in "${allowed_vals[@]}"; do
                local av_color="${ASH_MUTED}"
                [[ "${av}" == "${effective_val}" ]] && av_color="${ASH_SUCCESS}${BOLD}"
                printf ' %s%s%s' "${av_color}" "${av}" "${RST}"
            done
            printf '\n'
        fi
        log::blank
        return 0
    fi

    # ── Default pretty output ─────────────────────────────────────────────────
    local val_color; val_color=$(_get::value_color "${type}" "${effective_val}")
    local src_str=""
    [[ "${source_label}" == "default" ]] && \
        src_str=" ${ASH_MUTED}(default)${RST}"

    printf '  %s%s%s  %s%s%s%s\n' \
        "${ASH_MUTED}" "${key}" "${RST}" \
        "${val_color}${BOLD}" "${effective_val:-<empty>}" "${RST}" \
        "${src_str}"
}
