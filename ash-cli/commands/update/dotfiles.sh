#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update dotfiles                                          ║
# ║  Git pull • conflict resolution • config migration • rebuild hooks              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_DOTFILES_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_DOTFILES_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_dotfiles() {
    local start_time
    start_time="$(date +%s)"

    upd_section "📁" "ASH Dotfiles Update" "$(_upeach)"

    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"

    if [[ ! -d "$ash_root" ]]; then
        upd_fail "ASH root not found: ${ash_root}"
        upd_info "Clone: git clone https://github.com/ash-dotfiles/ash-dotfiles ${ash_root}"
        return 1
    fi

    if [[ ! -d "${ash_root}/.git" ]]; then
        upd_fail "Not a git repository: ${ash_root}"
        return 1
    fi

    upd_kv "Repository" "$ash_root"

    # ── Current state ─────────────────────────────────────────────────────────────
    local current_branch current_commit remote_url
    current_branch="$(git -C "$ash_root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    current_commit="$( git -C "$ash_root" rev-parse --short HEAD 2>/dev/null || echo '?')"
    remote_url="$(     git -C "$ash_root" remote get-url origin 2>/dev/null || echo '?')"

    upd_kv "Branch"     "$current_branch"
    upd_kv "Current"    "$current_commit"
    upd_kv "Remote"     "$remote_url"

    # ── Check for local changes ───────────────────────────────────────────────────
    local uncommitted
    uncommitted="$(git -C "$ash_root" status --porcelain 2>/dev/null | wc -l)"

    if (( uncommitted > 0 )); then
        upd_warn "${uncommitted} uncommitted change(s) detected"
        git -C "$ash_root" status --short 2>/dev/null | head -10 | \
            while IFS= read -r line; do
                printf '    %s%s%s\n' "$(_udim)" "$line" "$(_ur)"
            done

        if [[ "${ASH_UPD_YES:-0}" -ne 1 ]]; then
            printf '  %sContinue? (local changes will be stashed) [Y/n] %s' \
                "$(_uyellow)" "$(_ur)"
            local ans
            read -r ans
            [[ "${ans,,}" == "n" ]] && { upd_skip "dotfiles (uncommitted changes)"; return 0; }
        fi

        # Stash local changes
        upd_step "Stashing local changes..."
        [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && \
            git -C "$ash_root" stash push -m "ash-update-$(date +%s)" 2>/dev/null && \
            upd_ok "Changes stashed"
    fi

    # ── Fetch ────────────────────────────────────────────────────────────────────
    upd_step "Fetching from origin..."
    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        git -C "$ash_root" fetch origin 2>/dev/null || {
            upd_fail "Fetch failed — check network connection"
            return 1
        }
    fi

    # ── Check if updates available ────────────────────────────────────────────────
    local commits_behind
    commits_behind="$(git -C "$ash_root" rev-list HEAD..origin/${current_branch} \
                      --count 2>/dev/null || echo 0)"

    if (( commits_behind == 0 )); then
        upd_ok "Already up to date"
        upd_result_pass "dotfiles (up to date)"
        return 0
    fi

    upd_kv "Behind by" "${commits_behind} commit(s)"

    # Show incoming commits
    printf '\n  %sIncoming changes:%s\n' "$(_udim)" "$(_ur)"
    git -C "$ash_root" log "HEAD..origin/${current_branch}" \
        --oneline 2>/dev/null | head -10 | \
    while IFS= read -r cline; do
        local chash="${cline%% *}"
        local cmsg="${cline#* }"
        printf '    %s%s%s  %s%s%s\n' \
            "$(_udim)" "$chash" "$(_ur)" \
            "$(_usky)" "$cmsg" "$(_ur)"
    done

    # ── Pull ─────────────────────────────────────────────────────────────────────
    printf '\n'
    if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
        upd_info "[dry-run] Would pull ${commits_behind} commit(s)"
    else
        upd_step "Pulling updates..."
        if git -C "$ash_root" pull --rebase origin "$current_branch" 2>/dev/null; then
            local new_commit
            new_commit="$(git -C "$ash_root" rev-parse --short HEAD 2>/dev/null)"
            upd_ok "Updated: ${current_commit} → ${new_commit}"
            upd_log_ok "dotfiles: ${current_commit} → ${new_commit}"
        else
            upd_fail "Pull failed — merge conflict?"
            upd_info "Fix: cd ${ash_root} && git rebase --abort"
            return 1
        fi
    fi

    # ── Post-update hooks ─────────────────────────────────────────────────────────
    local hooks_dir="${ash_root}/scripts/hooks"
    local post_update_hook="${hooks_dir}/post-update.sh"

    if [[ -f "$post_update_hook" ]] && [[ -x "$post_update_hook" ]]; then
        upd_step "Running post-update hook..."
        [[ "${ASH_UPD_DRY:-0}" -ne 1 ]] && \
            bash "$post_update_hook" 2>&1 | head -20 | \
            while IFS= read -r line; do
                printf '  %s%s%s\n' "$(_udim)" "$line" "$(_ur)"
            done
    fi

    # ── Pop stash ────────────────────────────────────────────────────────────────
    if (( uncommitted > 0 )) && [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        upd_step "Restoring stashed changes..."
        git -C "$ash_root" stash pop 2>/dev/null && \
            upd_ok "Local changes restored" || \
            upd_warn "Could not restore stash — check: git stash list"
    fi

    upd_result_pass "dotfiles"
    local elapsed=$(( $(date +%s) - start_time ))
    upd_ok "Dotfiles updated in ${elapsed}s"

    command -v notify-send &>/dev/null && [[ "${ASH_UPD_NO_NOTIFY:-0}" -ne 1 ]] && \
        notify-send "📁 Dotfiles Updated" "${commits_behind} commits applied" \
            --icon=folder-git 2>/dev/null || true
}
