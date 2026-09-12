#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG UNSET                                           ║
# ║  Remove keys & restore defaults with safety guards                                ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::unset::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config unset <key> [key2…] [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--force,   -f${RST}   Skip confirmation for protected keys
  ${ASH_MUTED}--no-reload${RST}     Skip hot-reload after unsetting
  ${ASH_MUTED}--quiet,   -q${RST}   Suppress output
  ${ASH_MUTED}--help,    -h${RST}   Show this help

${BOLD}${ASH_PRIMARY}NOTES${RST}
  Unsetting a key causes the default value to be used.
  The key line is commented out (prefixed with #) for traceability.

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config unset theme.default
  ash config unset hyprland.gaps_in hyprland.gaps_out
  ash config unset ai.enabled --quiet
EOF
}

# Protected keys — warn before removing
readonly -a CFG_PROTECTED_KEYS=(
    "ash.config.version"
    "ash.shell"
)

config::unset() {
    local keys=() force=false no_reload=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)   config::unset::help; return 0 ;;
            --force|-f)  force=true; shift ;;
            --no-reload) no_reload=true; shift ;;
            --quiet|-q)  quiet=true; shift ;;
            -*)          log::error "Unknown option: $1"; return 1 ;;
            *)           keys+=("$1"); shift ;;
        esac
    done

    (( ${#keys[@]} == 0 )) && {
        log::error "At least one key required"
        config::unset::help; return 1
    }

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"
    local ok=0 err=0

    for key in "${keys[@]}"; do
        # Check current value
        local current; current=$(cfg::_read_raw "${key}" "${file}")
        local default_val; default_val=$(cfg::_schema_default "${key}" 2>/dev/null || true)

        if [[ -z "${current}" ]]; then
            [[ "${quiet}" == "false" ]] && \
                log::info "'${key}' is already unset (using default: ${default_val:-<none>})"
            continue
        fi

        # Protected key guard
        for pk in "${CFG_PROTECTED_KEYS[@]}"; do
            if [[ "${key}" == "${pk}" ]] && [[ "${force}" != "true" ]]; then
                log::warn "'${key}' is a protected key."
                utils::confirm "Unset anyway?" "n" || { (( err++ )); continue 2; }
            fi
        done

        cfg::lock || return 1
        # Comment out the line rather than delete — preserves history in file
        local escaped_key
        escaped_key=$(printf '%s' "${key}" | sed 's/\./\\./g')
        sed -i -E \
            "s|^([[:space:]]*)${escaped_key}([[:space:]]*)=(.*)$|# UNSET: \1${key}\2=\3|" \
            "${file}"
        cfg::unlock

        cfg::_record "unset" "${key}" "${current}" ""

        [[ "${quiet}" == "false" ]] && \
            printf '  %s%s%s  %s→%s  %s%s%s  %s(default: %s)%s\n' \
                "${ASH_MUTED}" "${key}" "${RST}" \
                "${ASH_ERROR}" "${RST}" \
                "${ASH_MUTED}" "${current}" "${RST}" \
                "${ASH_MUTED}" "${default_val:-<none>}" "${RST}"
        (( ok++ ))
    done

    [[ "${quiet}" == "false" ]] && (( ok > 0 )) && {
        log::blank; log::success "${ok} key(s) unset"; log::blank
    }

    # Hot-reload
    [[ "${no_reload}" == "false" ]] && (( ok > 0 )) && \
        _set::hot_reload "$(printf '%s' "${keys[0]}" | cut -d. -f1)" "" 2>/dev/null || true
}
