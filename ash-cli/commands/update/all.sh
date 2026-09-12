#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update all                                               ║
# ║  Master orchestrator — sequential / parallel update of all components           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_ALL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_ALL_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED BANNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_all_banner() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;166;227;161m'
        cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════╗
  ║   🚀  ASH DOTFILES — FULL SYSTEM UPDATE                       ║
  ╠══════════════════════════════════════════════════════════════╣
BANNER
        printf '  ║  %-60s║\n' "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        printf '  ╚══════════════════════════════════════════════════════════════╝\033[0m\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PRE-UPDATE SNAPSHOT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_all_pre_snapshot() {
    [[ "${ASH_UPD_NO_SNAP:-0}" -eq 1 ]] && {
        upd_info "Snapshot skipped (--no-snapshot)"
        return 0
    }

    upd_step "Creating pre-update snapshot..."

    local snap_dir="${_UPD_SNAPSHOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ash/snapshots/pre-update}"
    local snap_ts
    snap_ts="$(date +%Y%m%d-%H%M%S)"
    local snap_path="${snap_dir}/${snap_ts}"

    mkdir -p "$snap_path" 2>/dev/null || true

    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        # Save current state
        {
            printf '{\n'
            printf '  "timestamp": "%s",\n' "$snap_ts"
            printf '  "ash_version": "%s",\n' "$(cat "${ASH_ROOT_DIR:-$HOME/ash-dotfiles}/version.json" 2>/dev/null | grep -oP '"version":\s*"\K[^"]+' | head -1 || echo '?')"
            printf '  "git_commit": "%s",\n' "$(git -C "${ASH_ROOT_DIR:-$HOME/ash-dotfiles}" rev-parse HEAD 2>/dev/null | head -1 || echo '?')"
            printf '  "packages": [\n'

            case "$_UPD_PKG_MANAGER" in
                pacman) pacman -Q 2>/dev/null | awk '{printf "    \"%s=%s\",\n", $1, $2}' | head -500 ;;
                dnf)    rpm -qa 2>/dev/null | sort | awk '{printf "    \"%s\",\n", $0}' | head -500 ;;
            esac

            printf '    null\n  ]\n}\n'
        } > "${snap_path}/state.json" 2>/dev/null

        upd_ok "Snapshot created: ${snap_path##*/}"
        upd_log_info "Snapshot: ${snap_path}"
    else
        upd_info "[dry-run] Would create snapshot at ${snap_path}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  COMPONENT RUNNER WITH TIMING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_all_run_component() {
    local name="$1"  icon="$2"  sub_script="$3"  fn_name="$4"
    local step_num="$5"  total_steps="$6"

    local start_ts
    start_ts="$(date +%s)"

    # Status line
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n  \033[38;2;108;112;134m[%d/%d]\033[0m  %s\033[1;38;2;137;220;235m%s  %s\033[0m\n' \
            "$step_num" "$total_steps" "$icon" "$name" ""
    else
        printf '\n  [%d/%d]  %s  %s\n' "$step_num" "$total_steps" "$icon" "$name"
    fi

    # Load and run
    _upd_load_sub "$sub_script" 2>/dev/null || {
        upd_warn "Could not load ${sub_script}.sh"
        upd_result_skip "$name"
        return 0
    }

    local exit_code=0
    "$fn_name" 2>&1 || exit_code=$?

    local elapsed=$(( $(date +%s) - start_ts ))

    if [[ $exit_code -eq 0 ]]; then
        printf '  %s  %-20s  %s✓  %ds%s\n' \
            "$icon" "$name" "$(_ugreen)" "$elapsed" "$(_ur)"
    else
        printf '  %s  %-20s  %s✗  failed  %ds%s\n' \
            "$icon" "$name" "$(_ured)" "$elapsed" "$(_ur)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_update_all() {
    local global_start
    global_start="$(date +%s)"

    _all_banner
    upd_lock_acquire || return 1

    # Define component pipeline
    # Format: "name|icon|sub_script|fn_name"
    local -a components=(
        "System Packages|💻|system|ash_update_system"
        "ASH Dotfiles|📁|dotfiles|ash_update_dotfiles"
        "ASH Plugins|🔌|plugins|ash_update_plugins"
        "Theme Library|🎨|themes|ash_update_themes"
        "Neovim|📝|nvim|ash_update_nvim"
        "Fish Shell|🐟|fish|ash_update_fish"
        "Flatpak|📦|flatpak|ash_update_flatpak"
    )

    local total="${#components[@]}"

    upd_progress_start "$total"
    _UPD_PASS_COUNT=0; _UPD_FAIL_COUNT=0; _UPD_SKIP_COUNT=0
    _UPD_FAILED_LIST=()

    # Pre-update snapshot
    _all_pre_snapshot

    upd_divider
    printf '\n  %sRunning %d update component(s)...%s\n' \
        "$(_udim)" "$total" "$(_ur)"

    local step=0
    for component in "${components[@]}"; do
        (( step++ )) || true
        IFS='|' read -r name icon sub_script fn_name <<< "$component"

        upd_progress_step "$name"
        _all_run_component "$name" "$icon" "$sub_script" "$fn_name" "$step" "$total"
    done

    # ── Global summary ────────────────────────────────────────────────────────────
    local elapsed=$(( $(date +%s) - global_start ))
    upd_summary_report "$elapsed"
    upd_lock_release

    # Final notification
    local notif_msg="${_UPD_PASS_COUNT} components updated"
    [[ $_UPD_FAIL_COUNT -gt 0 ]] && \
        notif_msg+="  •  ${_UPD_FAIL_COUNT} failed"

    command -v notify-send &>/dev/null && [[ "${ASH_UPD_NO_NOTIFY:-0}" -ne 1 ]] && \
        notify-send "🚀 ASH Update Complete" "$notif_msg" \
            --icon=system-software-update 2>/dev/null || true

    printf '\n  %sLog: %s%s\n\n' "$(_udim)" "$_UPD_LOG_FILE" "$(_ur)"

    [[ $_UPD_FAIL_COUNT -eq 0 ]]
}
