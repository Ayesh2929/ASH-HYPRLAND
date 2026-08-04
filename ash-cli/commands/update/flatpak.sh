#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update flatpak                                           ║
# ║  Flatpak remotes refresh • app updates • runtime updates • unused removal       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_FLATPAK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_FLATPAK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_flatpak() {
    upd_section "📦" "Flatpak Update" "$(_upeach)"

    if ! command -v flatpak &>/dev/null; then
        upd_skip "Flatpak not installed"
        upd_result_skip "flatpak"
        return 0
    fi

    local fp_ver
    fp_ver="$(flatpak --version 2>/dev/null | grep -oP '[\d.]+')"
    upd_kv "Flatpak version" "$fp_ver"

    # ── Remotes ───────────────────────────────────────────────────────────────────
    upd_step "Refreshing Flatpak remotes..."
    local -a remotes=()
    mapfile -t remotes < <(flatpak remotes --columns=name 2>/dev/null | tail -n +1)

    for remote in "${remotes[@]}"; do
        [[ -z "$remote" ]] && continue
        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            flatpak remote-ls --updates "$remote" &>/dev/null || true
        fi
        printf '    %s•%s  %s%s%s\n' "$(_udim)" "$(_ur)" "$(_uteal)" "$remote" "$(_ur)"
    done

    # ── Count available updates ───────────────────────────────────────────────────
    local update_count
    update_count="$(flatpak update --noninteractive --no-deploy \
                   2>/dev/null | grep -c 'ID\|Update' || echo '?')"

    local installed_count
    installed_count="$(flatpak list --app 2>/dev/null | wc -l)"

    upd_kv "Installed apps" "$installed_count"

    # ── Show what will be updated ─────────────────────────────────────────────────
    local updates_list
    updates_list="$(flatpak update --noninteractive --no-deploy 2>/dev/null | \
                   grep -v '^$\|^Info' | head -20 || echo '')"

    if [[ -n "$updates_list" ]]; then
        printf '\n  %sAvailable updates:%s\n' "$(_udim)" "$(_ur)"
        while IFS= read -r uline; do
            [[ -z "$uline" ]] && continue
            printf '    %s%s%s\n' "$(_usky)" "$uline" "$(_ur)"
        done <<< "$updates_list"
    fi

    printf '\n'

    # ── Apply updates ─────────────────────────────────────────────────────────────
    upd_step "Updating Flatpak applications..."
    if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
        upd_info "[dry-run] Would run: flatpak update -y"
    else
        local fp_args=( "flatpak" "update" )
        [[ "${ASH_UPD_YES:-0}" -eq 1 ]] && fp_args+=( "-y" )

        if "${fp_args[@]}" 2>&1 | tee -a "$_UPD_LOG_FILE" | \
           grep -q 'Nothing to do\|Up to date\|app/'; then
            upd_ok "Flatpak apps updated"
        else
            upd_warn "Flatpak update output was empty"
        fi
    fi

    # ── Remove unused runtimes ─────────────────────────────────────────────────────
    upd_step "Removing unused Flatpak runtimes..."
    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        flatpak uninstall --unused -y 2>/dev/null && \
            upd_ok "Unused runtimes removed" || \
            upd_info "No unused runtimes found"
    fi

    # ── Runtime list ───────────────────────────────────────────────────────────────
    local runtime_count
    runtime_count="$(flatpak list --runtime 2>/dev/null | wc -l)"
    upd_kv "Installed runtimes" "$runtime_count"

    upd_result_pass "flatpak"
    upd_ok "Flatpak update complete"
}
