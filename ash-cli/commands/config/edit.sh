#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ CONFIG EDIT                                            ║
# ║  Open config in preferred editor with post-edit validation & hot-reload           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

config::edit::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash config edit [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--editor,   -e EDITOR${RST}   Override editor (default: \$EDITOR or config ash.editor)
  ${ASH_MUTED}--section,  -s SECTION${RST}  Jump to section (if editor supports it)
  ${ASH_MUTED}--key,      -k KEY${RST}      Jump to specific key line
  ${ASH_MUTED}--no-validate${RST}            Skip post-edit validation
  ${ASH_MUTED}--no-reload${RST}             Skip hot-reload after edit
  ${ASH_MUTED}--backup${RST}                Create backup before opening editor
  ${ASH_MUTED}--help,     -h${RST}           Show this help

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash config edit
  ash config edit --editor nvim
  ash config edit --key theme.default
  ash config edit --section hyprland --backup
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config::edit() {
    local editor_override="" section="" key=""
    local no_validate=false no_reload=false backup=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       config::edit::help; return 0 ;;
            --editor|-e)     editor_override="${2:?'--editor requires EDITOR'}"; shift 2 ;;
            --section|-s)    section="${2:?'--section requires SECTION'}"; shift 2 ;;
            --key|-k)        key="${2:?'--key requires KEY'}"; shift 2 ;;
            --no-validate)   no_validate=true; shift ;;
            --no-reload)     no_reload=true; shift ;;
            --backup)        backup=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               shift ;;
        esac
    done

    local file="${CFG_ACTIVE_FILE:-${CFG_MAIN_FILE}}"

    # ── Resolve editor ────────────────────────────────────────────────────────
    local chosen_editor=""
    if [[ -n "${editor_override}" ]]; then
        chosen_editor="${editor_override}"
    else
        # 1. Config value
        local cfg_editor; cfg_editor=$(cfg::_read_raw "ash.editor" "${file}")
        # 2. $EDITOR env
        # 3. Fallbacks
        chosen_editor="${cfg_editor:-${EDITOR:-${VISUAL:-nano}}}"
    fi

    command -v "${chosen_editor%% *}" &>/dev/null || {
        log::error "Editor not found: ${chosen_editor}"
        log::info  "Set your editor with: ash config set ash.editor nvim"
        return 1
    }

    # ── Backup ────────────────────────────────────────────────────────────────
    if [[ "${backup}" == "true" ]]; then
        local bkp="${CFG_BACKUP_DIR}/ash.conf.pre-edit-$(date '+%Y%m%d-%H%M%S').bak"
        mkdir -p "${CFG_BACKUP_DIR}"
        cp "${file}" "${bkp}"
        log::info "Backup saved: ${bkp}"
    fi

    # ── Record pre-edit checksum ──────────────────────────────────────────────
    local pre_chk
    pre_chk=$(sha256sum "${file}" 2>/dev/null | awk '{print $1}' || date +%s)

    # ── Compute line number for --key or --section ────────────────────────────
    local line_num=0
    if [[ -n "${key}" ]]; then
        local escaped_key; escaped_key=$(printf '%s' "${key}" | sed 's/\./\\./g')
        line_num=$(grep -nE "^[[:space:]]*${escaped_key}[[:space:]]*=" \
            "${file}" 2>/dev/null | head -1 | cut -d: -f1 || echo 0)
    elif [[ -n "${section}" ]]; then
        line_num=$(grep -n "^# ── ${section}" "${file}" 2>/dev/null | head -1 | cut -d: -f1 || echo 0)
        (( line_num == 0 )) && \
            line_num=$(grep -nE "^${section}\." "${file}" 2>/dev/null | head -1 | cut -d: -f1 || echo 0)
    fi

    # ── Open editor ───────────────────────────────────────────────────────────
    printf '  %s%s  Opening %s%s%s\n' \
        "${ASH_INFO}" "⚙" \
        "${BOLD}" "${file}" "${RST}"

    local editor_cmd="${chosen_editor}"
    if (( line_num > 0 )); then
        case "${chosen_editor}" in
            nvim|vim|vi|nano|micro)
                editor_cmd="${chosen_editor} +${line_num}" ;;
            hx|helix)
                editor_cmd="${chosen_editor} ${file}:${line_num}"; file="" ;;
            code|codium)
                editor_cmd="${chosen_editor} --goto ${file}:${line_num}"; file="" ;;
        esac
    fi

    # shellcheck disable=SC2086
    ${editor_cmd} "${file}"
    local edit_status=$?

    (( edit_status != 0 )) && {
        log::error "Editor exited with error (${edit_status})"
        return "${edit_status}"
    }

    # ── Check if file changed ─────────────────────────────────────────────────
    local post_chk
    post_chk=$(sha256sum "${file}" 2>/dev/null | awk '{print $1}' || date +%s)

    if [[ "${pre_chk}" == "${post_chk}" ]]; then
        log::info "No changes detected."
        return 0
    fi

    cfg::_record "edit" "" "" ""

    # ── Post-edit validation ──────────────────────────────────────────────────
    if [[ "${no_validate}" == "false" ]]; then
        log::info "Running post-edit validation…"
        # Source validate and run quietly
        source "${_CFG_CMD_DIR}/validate.sh"
        if config::validate --quiet 2>/dev/null; then
            log::success "Config is valid"
        else
            log::warn "Validation found issues — run 'ash config validate' for details"
        fi
    fi

    # ── Hot-reload ────────────────────────────────────────────────────────────
    [[ "${no_reload}" == "false" ]] && \
        _set::hot_reload "all" "" 2>/dev/null || true

    log::success "Config saved and reloaded"
}
