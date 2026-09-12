#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG SET                                             ║
# ║  Write config values with schema validation, type coercion & hot-reload           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::set::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config set <key> <value> [options]

${BOLD}${ASH_PRIMARY}ARGUMENTS${RST}
  ${ASH_ACCENT}key${RST}     Dot-separated config key
  ${ASH_ACCENT}value${RST}   New value

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--no-validate${RST}   Skip schema validation
  ${ASH_MUTED}--no-reload${RST}     Skip hot-reload after setting
  ${ASH_MUTED}--quiet,  -q${RST}    Suppress output
  ${ASH_MUTED}--force,  -f${RST}    Set unknown keys without schema warning
  ${ASH_MUTED}--help,   -h${RST}    Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config set theme.default catppuccin-mocha
  ash config set hyprland.gaps_in 8
  ash config set hyprland.blur_enabled true
  ash config set waybar.weather_location "London,UK"
  ash config set ai.enabled true --no-reload
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::set() {
    local key="" value="" no_validate=false no_reload=false
    local quiet=false force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       config::set::help; return 0 ;;
            --no-validate)   no_validate=true; shift ;;
            --no-reload)     no_reload=true; shift ;;
            --quiet|-q)      quiet=true; shift ;;
            --force|-f)      force=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)
                if [[ -z "${key}" ]];   then key="$1";
                elif [[ -z "${value}" ]]; then value="$1";
                else log::error "Too many arguments"; return 1; fi
                shift ;;
        esac
    done

    [[ -z "${key}" || -z "${value}" ]] && {
        log::error "Both key and value are required"
        config::set::help; return 1
    }

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Schema check ──────────────────────────────────────────────────────────
    if ! cfg::_key_exists_in_schema "${key}"; then
        if [[ "${force}" == "true" ]]; then
            log::warn "Key '${key}' not in schema — setting anyway (--force)"
        else
            log::error "Unknown config key: '${key}'"
            log::info  "Run ${BOLD}ash config list${RST} to see available keys"
            log::info  "Use ${BOLD}--force${RST} to set unknown keys"
            return 1
        fi
    fi

    # ── Normalise ─────────────────────────────────────────────────────────────
    local type; type=$(cfg::_schema_type "${key}" 2>/dev/null || printf "string")
    if [[ "${type}" == "boolean" ]]; then
        value=$(cfg::_normalise_bool "${value}")
    fi

    # ── Validate ──────────────────────────────────────────────────────────────
    if [[ "${no_validate}" == "false" ]]; then
        cfg::_validate_value "${key}" "${value}" || return 1
    fi

    # ── Read current for history ───────────────────────────────────────────────
    local old_val; old_val=$(cfg::_read_raw "${key}" "${file}")

    # No-op check
    if [[ "${old_val}" == "${value}" ]]; then
        [[ "${quiet}" == "false" ]] && \
            log::info "Value unchanged: ${key} = ${value}"
        return 0
    fi

    # ── Write ─────────────────────────────────────────────────────────────────
    cfg::lock || return 1
    cfg::_write_raw "${key}" "${value}" "${file}"
    cfg::unlock

    # ── Record history ────────────────────────────────────────────────────────
    cfg::_record "set" "${key}" "${old_val}" "${value}"

    # ── Pretty output ─────────────────────────────────────────────────────────
    if [[ "${quiet}" == "false" ]]; then
        local val_color; val_color=$(_get::value_color "${type}" "${value}" 2>/dev/null || printf '%s' "${ASH_INFO}")
        printf '\n'
        printf '  %s%-40s%s\n' "${BOLD}" "${key}" "${RST}"
        printf '  %s  %s→%s  %s%s%s\n' \
            "${ASH_MUTED}" "${RST}" \
            "${val_color}${BOLD}" "${value}" "${RST}"
        [[ -n "${old_val}" ]] && \
            printf '  %s     (was: %s)%s\n' "${ASH_MUTED}" "${old_val}" "${RST}"
        log::blank
        log::success "Config updated"
    fi

    # ── Hot-reload ────────────────────────────────────────────────────────────
    if [[ "${no_reload}" == "false" ]]; then
        _set::hot_reload "${key}" "${value}"
    fi
}

# ── Targeted hot-reload based on which key changed ────────────────────────────
_set::hot_reload() {
    local key="$1" value="$2"
    local section; section=$(printf '%s' "${key}" | cut -d. -f1)

    log::debug "Hot-reload trigger for section: ${section}"

    case "${section}" in
        hyprland)
            command -v hyprctl &>/dev/null && \
                hyprctl reload 2>/dev/null && \
                log::debug "Hyprland reloaded" || true
            ;;
        waybar|bar)
            if pgrep -x waybar &>/dev/null; then
                pkill -SIGUSR2 waybar 2>/dev/null && \
                    log::debug "Waybar reloaded" || true
            fi
            ;;
        notifications)
            if pgrep -x dunst &>/dev/null; then
                pkill -SIGUSR1 dunst 2>/dev/null && log::debug "Dunst reloaded" || true
            fi
            ;;
        theme)
            # Delegate to theme engine
            local theme_apply="${_CFG_CMD_DIR}/../../scripts/theme/apply-theme.sh"
            [[ -x "${theme_apply}" ]] && \
                "${theme_apply}" --quiet 2>/dev/null && \
                log::debug "Theme re-applied" || true
            ;;
    esac
}
