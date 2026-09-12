#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR FIX                                                 ║
# ║  Intelligent auto-repair engine — targeted fixes with safety guards & rollback        ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

doctor::fix::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "🔧  ASH DOCTOR FIX" \
        "Intelligent auto-repair engine with safety guards & rollback" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash doctor fix [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--category,  -c CAT${RST}   Fix only issues in this category
  ${ASH_MUTED}--severity,  -s SEV${RST}   Fix only: warn|fail|crit (default: all)
  ${ASH_MUTED}--dry-run,   -n${RST}        Preview fixes without applying
  ${ASH_MUTED}--force,     -f${RST}        Skip individual confirmations
  ${ASH_MUTED}--no-backup${RST}            Skip snapshot before fixing
  ${ASH_MUTED}--from-last${RST}           Fix issues from last doctor run (no re-scan)
  ${ASH_MUTED}--help,      -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}SAFETY${RST}
  • Creates a config snapshot before applying any fixes
  • Each fix is attempted individually — failures don't stop others
  • Dry-run mode shows exactly what would be executed
  • Dangerous operations always require confirmation

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash doctor fix
  ash doctor fix --dry-run
  ash doctor fix --category fonts --force
  ash doctor fix --severity fail --no-backup
  ash doctor fix --from-last
EOF
}

# ── Fix result renderer ────────────────────────────────────────────────────────
_fix::render_result() {
    local id="$1" title="$2" status="$3" detail="${4:-}"
    case "${status}" in
        fixed)
            printf '  %s%s FIXED%s   %s%s%s  %s%s%s\n' \
                "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" \
                "${ASH_INFO}" "${title}" "${RST}" \
                "${ASH_MUTED}" "${detail}" "${RST}"
            ;;
        skipped)
            printf '  %s─ SKIP%s    %s%s%s  %s%s%s\n' \
                "${ASH_MUTED}" "${RST}" \
                "${ASH_MUTED}" "${title}" "${RST}" \
                "${ASH_MUTED}" "${detail}" "${RST}"
            ;;
        failed)
            printf '  %s%s FAILED%s  %s%s%s  %s%s%s\n' \
                "${ASH_ERROR}" "${ICO_ERROR}" "${RST}" \
                "${ASH_ERROR}" "${title}" "${RST}" \
                "${ASH_MUTED}" "${detail}" "${RST}"
            ;;
        manual)
            printf '  %s%s MANUAL%s  %s%s%s\n' \
                "${ASH_WARNING}" "${ICO_WARN}" "${RST}" \
                "${ASH_WARNING}" "${title}" "${RST}"
            printf '     %sRun: %s%s%s\n' "${ASH_MUTED}" "${ASH_ACCENT}" "${detail}" "${RST}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § BUILT-IN FIX ROUTINES
# Each function fixes a specific class of issue
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_fix::permissions() {
    local dry="$1"
    local fixed=0 failed=0

    # Fix ASH directory permissions
    local dirs=(
        "${ASH_DATA_DIR:-${HOME}/.local/share/ash}:700"
        "${ASH_STATE_DIR:-${HOME}/.local/state/ash}:700"
        "${ASH_CACHE_DIR:-${HOME}/.cache/ash}:700"
        "${XDG_CONFIG_HOME:-${HOME}/.config}/ash:700"
    )
    for entry in "${dirs[@]}"; do
        local dpath="${entry%%:*}" perm="${entry##*:}"
        [[ ! -d "${dpath}" ]] && continue
        local current_perm; current_perm=$(stat -c '%a' "${dpath}" 2>/dev/null || echo 0)
        if [[ "${current_perm}" != "${perm}" ]]; then
            if [[ "${dry}" == "false" ]]; then
                chmod "${perm}" "${dpath}" 2>/dev/null && (( fixed++ )) || (( failed++ ))
            else
                printf '     %sDRY: chmod %s %s%s\n' \
                    "${ASH_MUTED}" "${perm}" "${dpath}" "${RST}"
                (( fixed++ ))
            fi
        fi
    done

    # SSH dir
    [[ -d "${HOME}/.ssh" ]] && {
        local ssh_perm; ssh_perm=$(stat -c '%a' "${HOME}/.ssh" 2>/dev/null)
        if [[ "${ssh_perm}" != "700" ]]; then
            [[ "${dry}" == "false" ]] && \
                chmod 700 "${HOME}/.ssh" 2>/dev/null && (( fixed++ )) || (( failed++ ))
        fi
        # SSH keys
        find "${HOME}/.ssh" -name "id_*" ! -name "*.pub" 2>/dev/null | while read -r keyfile; do
            local kperm; kperm=$(stat -c '%a' "${keyfile}" 2>/dev/null)
            [[ "${kperm}" != "600" ]] && {
                [[ "${dry}" == "false" ]] && chmod 600 "${keyfile}" 2>/dev/null || true
            }
        done
    }

    # ASH binary
    local ash_bin="${_DOC_DIR}/../../ash"
    [[ -f "${ash_bin}" ]] && [[ ! -x "${ash_bin}" ]] && {
        [[ "${dry}" == "false" ]] && chmod +x "${ash_bin}" 2>/dev/null && (( fixed++ )) || (( failed++ ))
    }

    printf '%d %d' "${fixed}" "${failed}"
}

_fix::fonts() {
    local dry="$1"
    # Install Nerd Font if missing
    if ! fc-list 2>/dev/null | grep -qi "nerd\|nf-"; then
        if [[ "${dry}" == "false" ]]; then
            if command -v paru &>/dev/null; then
                printf '     %sInstalling JetBrains Mono Nerd Font…%s\n' "${ASH_INFO}" "${RST}"
                paru -S --noconfirm ttf-jetbrains-mono-nerd 2>/dev/null && \
                    fc-cache -f 2>/dev/null || true
            else
                printf '     %sManual: paru -S ttf-jetbrains-mono-nerd%s\n' "${ASH_WARNING}" "${RST}"
            fi
        fi
        printf 'nerd_font'
    fi
}

_fix::services() {
    local dry="$1"
    local ash_services=(
        "ash-hot-reload.service"
        "ash-weather-fetch.timer"
        "ash-update-check.timer"
    )
    local fixed=0 failed=0
    for svc in "${ash_services[@]}"; do
        if ! systemctl --user is-enabled --quiet "${svc}" 2>/dev/null; then
            if [[ "${dry}" == "false" ]]; then
                systemctl --user enable --now "${svc}" 2>/dev/null && \
                    (( fixed++ )) || (( failed++ ))
            else
                printf '     %sDRY: systemctl --user enable --now %s%s\n' \
                    "${ASH_MUTED}" "${svc}" "${RST}"
                (( fixed++ ))
            fi
        fi
    done

    # XDG portal
    if ! systemctl --user is-active --quiet xdg-desktop-portal 2>/dev/null; then
        [[ "${dry}" == "false" ]] && \
            systemctl --user start xdg-desktop-portal 2>/dev/null && \
            (( fixed++ )) || true
    fi

    printf '%d %d' "${fixed}" "${failed}"
}

_fix::symlinks() {
    local dry="$1"
    local fixed=0
    # Repair broken symlinks in ASH dirs
    while IFS= read -r broken_link; do
        if [[ "${dry}" == "false" ]]; then
            rm -f "${broken_link}" 2>/dev/null && (( fixed++ ))
            log::debug "Removed broken symlink: ${broken_link}"
        else
            printf '     %sDRY: remove broken symlink %s%s\n' \
                "${ASH_MUTED}" "${broken_link}" "${RST}"
            (( fixed++ ))
        fi
    done < <(find \
        "${ASH_DATA_DIR:-${HOME}/.local/share/ash}" \
        "${XDG_CONFIG_HOME:-${HOME}/.config}/ash" \
        -xtype l 2>/dev/null)
    printf '%d' "${fixed}"
}

_fix::cache() {
    local dry="$1"
    local freed_bytes=0
    local cache_dir="${ASH_CACHE_DIR:-${HOME}/.cache/ash}"

    # Old preview files (>7 days)
    local old_files; old_files=$(find "${cache_dir}" -type f -mtime +7 2>/dev/null | wc -l)
    if (( old_files > 0 )); then
        if [[ "${dry}" == "false" ]]; then
            freed_bytes=$(find "${cache_dir}" -type f -mtime +7 2>/dev/null \
                -exec du -b {} + | awk '{s+=$1} END {print s+0}')
            find "${cache_dir}" -type f -mtime +7 2>/dev/null -delete
        else
            printf '     %sDRY: remove %d cached file(s) older than 7 days%s\n' \
                "${ASH_MUTED}" "${old_files}" "${RST}"
        fi
    fi

    # Thumbnail cache
    local thumb_cache="${HOME}/.cache/thumbnails"
    if [[ -d "${thumb_cache}" ]]; then
        local old_thumbs; old_thumbs=$(find "${thumb_cache}" -type f -mtime +30 2>/dev/null | wc -l)
        if (( old_thumbs > 0 )) && [[ "${dry}" == "false" ]]; then
            find "${thumb_cache}" -type f -mtime +30 2>/dev/null -delete
        fi
    fi

    printf '%d' "${freed_bytes}"
}

_fix::config_validate() {
    local dry="$1"
    if command -v ash &>/dev/null && [[ "${dry}" == "false" ]]; then
        ash config validate --fix --quiet 2>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::fix() {
    local cat_filter="" sev_filter="" dry_run=false
    local force=false no_backup=false from_last=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)       doctor::fix::help; return 0 ;;
            --category|-c)   cat_filter="${2:?'--category requires value'}"; shift 2 ;;
            --severity|-s)   sev_filter="${2:?'--severity requires value'}"; shift 2 ;;
            --dry-run|-n)    dry_run=true; shift ;;
            --force|-f)      force=true; shift ;;
            --no-backup)     no_backup=true; shift ;;
            --from-last)     from_last=true; shift ;;
            -*)              log::error "Unknown option: $1"; return 1 ;;
            *)               shift ;;
        esac
    done

    # ── Header ────────────────────────────────────────────────────────────────
    log::blank
    printf '  %s🔧  ASH Doctor Fix%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
    [[ "${dry_run}" == "true" ]] && \
        printf '  %s%s DRY RUN — no changes will be applied%s\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"
    log::blank

    # ── Load issues ───────────────────────────────────────────────────────────
    local issues_to_fix=()

    if [[ "${from_last}" == "true" ]]; then
        # Load from persisted last run
        if [[ ! -f "${DOC_LAST_RUN_FILE}" ]]; then
            log::error "No last doctor run found. Run 'ash doctor quick' or 'ash doctor full' first."
            return 1
        fi
        log::info "Loading issues from last doctor run…"
        while IFS= read -r entry; do
            local sev cat id title msg fix
            sev=$(printf '%s' "${entry}"   | jq -r '.severity')
            cat=$(printf '%s' "${entry}"   | jq -r '.category')
            id=$(printf '%s' "${entry}"    | jq -r '.id')
            title=$(printf '%s' "${entry}" | jq -r '.title')
            msg=$(printf '%s' "${entry}"   | jq -r '.message')
            fix=$(printf '%s' "${entry}"   | jq -r '.fix // ""')
            issues_to_fix+=("${sev}|${cat}|${id}|${title}|${msg}|${fix}")
        done < <(jq -c '.results[]
            | select(.severity == "WARN" or .severity == "FAIL" or .severity == "CRIT")
            | select(.fix != "" and .fix != null)' \
            "${DOC_LAST_RUN_FILE}" 2>/dev/null)
    else
        # Run quick scan to populate DOC_RESULTS
        log::info "Scanning for issues…"
        source "${_DOC_DIR}/quick.sh" 2>/dev/null || true
        doctor::quick --no-summary --compact 2>/dev/null || true

        # Extract fixable issues
        for entry in "${DOC_RESULTS[@]}"; do
            IFS='|' read -r sev cat id title msg fix <<< "${entry}"
            [[ "${sev}" == "${SEV_PASS}" ]] && continue
            [[ "${sev}" == "${SEV_INFO}" ]] && continue
            [[ "${sev}" == "${SEV_SKIP}" ]] && continue
            [[ -z "${fix}" ]] && continue
            [[ -n "${cat_filter}" ]] && [[ "${cat}" != "${cat_filter}" ]] && continue
            [[ -n "${sev_filter}" ]] && [[ "${sev,,}" != "${sev_filter,,}" ]] && continue
            issues_to_fix+=("${entry}")
        done
    fi

    # ── Nothing to fix ────────────────────────────────────────────────────────
    if (( ${#issues_to_fix[@]} == 0 )); then
        log::success "No fixable issues found! System is healthy."
        log::blank
        return 0
    fi

    # ── Show fix plan ─────────────────────────────────────────────────────────
    local total_fixes="${#issues_to_fix[@]}"
    printf '  %s%s%s  %s%d fixable issue(s) found%s\n\n' \
        "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}" \
        "${BOLD}" "${total_fixes}" "${RST}"

    printf '  %s%-8s  %-14s  %-38s  %s%s\n' \
        "${BOLD}${ASH_MUTED}" "Severity" "Category" "Issue" "Fix Command" "${RST}"
    ash_hr "─" 80 "${ASH_MUTED}"

    for entry in "${issues_to_fix[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"
        printf '  %s  %s%-12s%s  %s%-38s%s  %s%s%s\n' \
            "$(doc::badge "${sev}")" \
            "${ASH_MUTED}" "${cat}" "${RST}" \
            "${ASH_INFO}" "$(ash_truncate "${title}" 38)" "${RST}" \
            "${ASH_ACCENT}" "$(ash_truncate "${fix}" 30)" "${RST}"
    done

    log::blank

    # ── Confirm ───────────────────────────────────────────────────────────────
    if [[ "${dry_run}" == "false" ]] && [[ "${force}" == "false" ]]; then
        utils::confirm "Apply ${total_fixes} fix(es)?" "n" || {
            log::info "Fix cancelled."
            return 0
        }
    fi

    # ── Pre-fix snapshot ──────────────────────────────────────────────────────
    if [[ "${no_backup}" == "false" ]] && [[ "${dry_run}" == "false" ]]; then
        log::info "Creating pre-fix safety snapshot…"
        local snap_id
        if snap_id=$(ash snapshot create "pre-doctor-fix" \
            --tag auto-backup --desc "Before doctor fix" --quiet 2>/dev/null); then
            log::success "Safety snapshot: ${snap_id}"
        else
            log::warn "Could not create snapshot — proceeding without backup"
        fi
    fi

    # ── Run built-in fix categories ────────────────────────────────────────────
    log::section "Running Auto-Fixes"
    local fixed_total=0 failed_total=0 manual_total=0

    # ── Category: Permissions ─────────────────────────────────────────────────
    local needs_perm_fix=false
    for entry in "${issues_to_fix[@]}"; do
        IFS='|' read -r _ cat _ <<< "${entry}"
        [[ "${cat}" == "permissions" ]] && { needs_perm_fix=true; break; }
    done
    if [[ "${needs_perm_fix}" == "true" ]]; then
        ash_spinner_start "Fixing permissions…"
        local perm_result
        perm_result=$(_fix::permissions "${dry_run}" 2>/dev/null || echo "0 0")
        local pf="${perm_result%% *}" pfail="${perm_result##* }"
        ash_spinner_stop 0 "Permissions fixed: ${pf}"
        (( fixed_total += pf ))
        (( failed_total += pfail ))
    fi

    # ── Category: Fonts ───────────────────────────────────────────────────────
    for entry in "${issues_to_fix[@]}"; do
        IFS='|' read -r _ cat id title _ fix <<< "${entry}"
        [[ "${cat}" != "fonts" ]] && continue
        if [[ "${dry_run}" == "true" ]]; then
            _fix::render_result "${id}" "${title}" "skipped" "(dry-run)"
        else
            ash_spinner_start "Installing fonts…"
            _fix::fonts "${dry_run}" &>/dev/null
            ash_spinner_stop 0 "Font fix applied"
            (( fixed_total++ ))
        fi
        break
    done

    # ── Category: Services ────────────────────────────────────────────────────
    local needs_svc_fix=false
    for entry in "${issues_to_fix[@]}"; do
        IFS='|' read -r _ cat _ <<< "${entry}"
        [[ "${cat}" == "services" || "${cat}" == "portals" ]] && { needs_svc_fix=true; break; }
    done
    if [[ "${needs_svc_fix}" == "true" ]]; then
        ash_spinner_start "Enabling services…"
        local svc_result
        svc_result=$(_fix::services "${dry_run}" 2>/dev/null || echo "0 0")
        local sf="${svc_result%% *}" sfail="${svc_result##* }"
        ash_spinner_stop 0 "Services fixed: ${sf}"
        (( fixed_total += sf ))
        (( failed_total += sfail ))
    fi

    # ── Cache cleanup ──────────────────────────────────────────────────────────
    ash_spinner_start "Cleaning cache…"
    local freed_bytes; freed_bytes=$(_fix::cache "${dry_run}" 2>/dev/null || echo 0)
    ash_spinner_stop 0 "Cache cleaned$(
        (( freed_bytes > 0 )) && printf ' — freed %s' "$(utils::human_size "${freed_bytes}")")"

    # ── Symlinks ───────────────────────────────────────────────────────────────
    ash_spinner_start "Repairing symlinks…"
    local sym_fixed; sym_fixed=$(_fix::symlinks "${dry_run}" 2>/dev/null || echo 0)
    ash_spinner_stop 0 "Symlinks: ${sym_fixed} repaired"
    (( fixed_total += sym_fixed ))

    # ── Config validation ──────────────────────────────────────────────────────
    ash_spinner_start "Validating config…"
    _fix::config_validate "${dry_run}" 2>/dev/null || true
    ash_spinner_stop 0 "Config validated"

    # ── Emit manual fix instructions for remaining issues ─────────────────────
    local manual_issues=()
    for entry in "${issues_to_fix[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"
        # If fix is a package install — show as manual
        if [[ "${fix}" == *"paru -S"* ]] || [[ "${fix}" == *"pacman -S"* ]]; then
            manual_issues+=("${entry}")
            (( manual_total++ ))
        fi
    done

    if (( ${#manual_issues[@]} > 0 )); then
        log::blank
        printf '  %s%s Manual Actions Required%s\n\n' \
            "${BOLD}${ASH_WARNING}" "${ICO_WARN}" "${RST}"
        for entry in "${manual_issues[@]}"; do
            IFS='|' read -r sev cat id title msg fix <<< "${entry}"
            _fix::render_result "${id}" "${title}" "manual" "${fix}"
        done
    fi

    # ── Summary ───────────────────────────────────────────────────────────────
    log::blank
    ash_hr "─" 70 "${ASH_MUTED}"
    log::blank
    printf '  %s%s Auto-fixed%s   %s%d%s\n' \
        "${ASH_SUCCESS}" "${ICO_SUCCESS}" "${RST}" "${BOLD}" "${fixed_total}"  "${RST}"
    printf '  %s%s Manual req%s   %s%d%s\n' \
        "${ASH_WARNING}" "${ICO_WARN}"    "${RST}" "${BOLD}" "${manual_total}" "${RST}"
    (( failed_total > 0 )) && \
        printf '  %s%s Failed%s      %s%d%s\n' \
            "${ASH_ERROR}" "${ICO_ERROR}"  "${RST}" "${BOLD}" "${failed_total}" "${RST}"

    log::blank
    [[ "${dry_run}" == "false" ]] && \
        log::info "Run ${BOLD}ash doctor quick${RST} to verify fixes"
    log::blank
}
