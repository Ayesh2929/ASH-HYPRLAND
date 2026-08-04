#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update system                                            ║
# ║  System package manager update with AUR support, mirrors, and kernel alerts     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_SYSTEM_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_SYSTEM_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PRE-FLIGHT CHECKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_preflight() {
    # Check internet
    if ! ping -c 1 -W 2 -q 8.8.8.8 &>/dev/null 2>&1; then
        upd_fail "No internet connection"
        return 1
    fi

    # Check lock files
    if [[ -f /var/lib/pacman/db.lck ]] && [[ "$_UPD_PKG_MANAGER" == "pacman" ]]; then
        upd_fail "/var/lib/pacman/db.lck exists — another pacman process running?"
        upd_info "Remove if stale: sudo rm /var/lib/pacman/db.lck"
        return 1
    fi

    # Check disk space (need at least 1GB)
    local avail_kb
    avail_kb="$(df / 2>/dev/null | awk 'NR==2{print $4}')"
    if [[ "$avail_kb" =~ ^[0-9]+$ ]] && (( avail_kb < 1048576 )); then
        upd_warn "Low disk space: $(( avail_kb / 1024 ))MB free"
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MIRROR REFRESH  (Arch only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_refresh_mirrors() {
    command -v reflector &>/dev/null || return 0

    upd_step "Refreshing pacman mirrors via reflector..."
    local reflector_args=(
        "--latest" "20"
        "--sort" "rate"
        "--protocol" "https"
        "--save" "/etc/pacman.d/mirrorlist"
        "--country" "$(curl -fsSL --max-time 3 https://ipapi.co/country_code 2>/dev/null || echo 'US')"
    )

    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        sudo reflector "${reflector_args[@]}" 2>/dev/null && \
            upd_ok "Mirrors refreshed" || \
            upd_warn "Mirror refresh failed — continuing with current mirrors"
    else
        upd_info "[dry-run] Would refresh mirrors via reflector"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  KERNEL VERSION MONITOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_kernel_check() {
    local running_kernel
    running_kernel="$(uname -r)"

    local installed_kernel=""
    if command -v pacman &>/dev/null; then
        installed_kernel="$(pacman -Q linux 2>/dev/null | awk '{print $2}' | head -1)"
    fi

    upd_kv "Running kernel"   "$running_kernel"
    [[ -n "$installed_kernel" ]] && upd_kv "Installed kernel" "$installed_kernel"

    # Detect if kernel was updated and reboot needed
    if [[ -n "$installed_kernel" ]]; then
        local running_ver="${running_kernel%-*}"
        local installed_ver="${installed_kernel}-arch"
        if [[ "$running_ver" != "${installed_ver%%-*}" ]]; then
            upd_warn "Kernel updated — reboot required to apply new kernel"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PACKAGE COUNT DELTA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_count_updates() {
    case "$_UPD_PKG_MANAGER" in
        pacman)
            local aur_count=0
            local official_count
            official_count="$(sudo -n checkupdates 2>/dev/null | wc -l || echo '?')"

            if [[ -n "$_UPD_AUR_HELPER" ]]; then
                aur_count="$("$_UPD_AUR_HELPER" -Qua 2>/dev/null | wc -l || echo 0)"
            fi

            printf '%s official  •  %s AUR' "$official_count" "$aur_count"
            ;;
        dnf)
            dnf check-update --quiet 2>/dev/null | grep -c '^[^ ]' || echo '?'
            ;;
        apt)
            apt-get -s upgrade 2>/dev/null | \
                grep '^[0-9]' | awk '{print $1 " packages"}'
            ;;
        *)
            echo '?'
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN UPDATE RUNNERS PER PKG MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_run_arch() {
    local yes_flag=""
    [[ "${ASH_UPD_YES:-0}" -eq 1 ]] && yes_flag="--noconfirm"

    if [[ -n "$_UPD_AUR_HELPER" ]]; then
        upd_step "Running ${_UPD_AUR_HELPER} -Syu  (official + AUR)..."

        if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
            "$_UPD_AUR_HELPER" -Syu --print 2>/dev/null | head -20
            return 0
        fi

        local update_output
        if [[ "${ASH_UPD_VERBOSE:-0}" -eq 1 ]]; then
            "$_UPD_AUR_HELPER" -Syu $yes_flag 2>&1 | tee -a "$_UPD_LOG_FILE"
        else
            update_output="$("$_UPD_AUR_HELPER" -Syu $yes_flag 2>&1)"
            printf '%s' "$update_output" >> "$_UPD_LOG_FILE"
        fi
    else
        upd_step "Running sudo pacman -Syu  (official only)..."

        if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
            sudo pacman -Syu --print 2>/dev/null | head -20
            return 0
        fi

        if [[ "${ASH_UPD_VERBOSE:-0}" -eq 1 ]]; then
            sudo pacman -Syu $yes_flag 2>&1 | tee -a "$_UPD_LOG_FILE"
        else
            sudo pacman -Syu $yes_flag 2>&1 >> "$_UPD_LOG_FILE"
        fi
    fi
}

_sys_run_fedora() {
    local yes_flag="-y"
    [[ "${ASH_UPD_YES:-0}" -ne 1 ]] && yes_flag=""
    upd_step "Running sudo dnf upgrade..."
    [[ "${ASH_UPD_DRY:-0}" -eq 1 ]] && \
        { sudo dnf upgrade --assumeno 2>/dev/null; return; }
    sudo dnf upgrade $yes_flag 2>&1 | tee -a "$_UPD_LOG_FILE"
}

_sys_run_debian() {
    upd_step "Running apt update && apt upgrade..."
    if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
        sudo apt-get update -q 2>/dev/null
        sudo apt-get upgrade --simulate 2>/dev/null
        return
    fi
    sudo apt-get update -q 2>&1 | tee -a "$_UPD_LOG_FILE"
    local yes_flag
    [[ "${ASH_UPD_YES:-0}" -eq 1 ]] && yes_flag="-y" || yes_flag=""
    sudo apt-get upgrade $yes_flag 2>&1 | tee -a "$_UPD_LOG_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  POST-UPDATE CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sys_post_cleanup() {
    case "$_UPD_PKG_MANAGER" in
        pacman)
            # Remove orphans if none selected
            local orphans
            orphans="$(pacman -Qdtq 2>/dev/null | wc -l)"
            if (( orphans > 0 )); then
                upd_info "${orphans} orphaned package(s) found — run: paru -Rns \$(pacman -Qdtq)"
            fi

            # Clean old cache (keep 2)
            if command -v paccache &>/dev/null; then
                upd_step "Cleaning package cache (keep 2 versions)..."
                [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && \
                    sudo paccache -rq --keep 2 2>/dev/null || true
            fi
            ;;
        apt)
            [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && \
                sudo apt-get autoremove -q 2>/dev/null || true
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_update_system() {
    local start_time
    start_time="$(date +%s)"

    upd_section "💻" "System Update" "$(_ugreen)"

    _sys_preflight || return 1

    # Info display
    upd_kv "Package manager" "${_UPD_PKG_MANAGER:-unknown}  ${_UPD_AUR_HELPER:+(+${_UPD_AUR_HELPER})}"
    upd_kv "Mode" "$( [[ "${ASH_UPD_DRY:-0}" -eq 1 ]] && echo 'dry-run' || echo 'live')"

    local avail_updates
    avail_updates="$(_sys_count_updates)"
    upd_kv "Available" "$avail_updates"

    # Kernel info
    _sys_kernel_check

    printf '\n'

    # Confirm if not --yes
    if [[ "${ASH_UPD_YES:-0}" -ne 1 ]] && [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        printf '  %sProceed with system update? [Y/n] %s' "$(_uyellow)" "$(_ur)"
        local ans
        read -r ans
        [[ "${ans,,}" == "n" ]] && { upd_skip "System update"; return 0; }
    fi

    # Refresh mirrors (Arch)
    [[ "$_UPD_PKG_MANAGER" == "pacman" ]] && _sys_refresh_mirrors

    # Run update
    local exit_code=0

    case "$_UPD_PKG_MANAGER" in
        pacman) _sys_run_arch    || exit_code=$? ;;
        dnf)    _sys_run_fedora  || exit_code=$? ;;
        apt)    _sys_run_debian  || exit_code=$? ;;
        nix)
            upd_step "Running nix-env -u..."
            [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && nix-env -u 2>&1 | tee -a "$_UPD_LOG_FILE"
            ;;
        xbps)
            upd_step "Running sudo xbps-install -Su..."
            [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && \
                sudo xbps-install -Su 2>&1 | tee -a "$_UPD_LOG_FILE"
            ;;
        *)
            upd_fail "Unknown package manager: ${_UPD_PKG_MANAGER}"
            return 1
            ;;
    esac

    if [[ $exit_code -eq 0 ]]; then
        _sys_post_cleanup
        upd_result_pass "system"
        upd_ok "System update complete"

        local elapsed=$(( $(date +%s) - start_time ))
        upd_log_ok "System update completed in ${elapsed}s"

        command -v notify-send &>/dev/null && [[ "${ASH_UPD_NO_NOTIFY:-0}" -ne 1 ]] && \
            notify-send "🔄 System Updated" "Packages updated successfully" \
                --icon=system-software-update 2>/dev/null || true
    else
        upd_result_fail "system"
        upd_fail "System update failed (exit: ${exit_code})"
        upd_info "Check log: ${_UPD_LOG_FILE}"
    fi
}
