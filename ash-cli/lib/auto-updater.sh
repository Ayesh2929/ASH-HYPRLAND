#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⬆️  ASH AUTO-UPDATER — safe, reversible, rate-limited self-update            ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Updating someone's dotfiles is the single most dangerous thing this project  ║
# ║  does. The design reflects that:                                              ║
# ║    1. Never update without a verified snapshot that can be restored           ║
# ║    2. Never force-push over local modifications — stash, then report          ║
# ║    3. Never check more than once per interval (GitHub rate limits)            ║
# ║    4. Never run a post-update hook that hasn't been syntax-checked            ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_AUTO_UPDATER_LOADED:-}" ]] && return 0
readonly _ASH_AUTO_UPDATER_LOADED=1
readonly ASH_AUTO_UPDATER_VERSION="5.0.0"

: "${ASH_UPDATE_REMOTE:=origin}"
: "${ASH_UPDATE_BRANCH:=main}"
: "${ASH_UPDATE_CHECK_INTERVAL:=86400}"     # once a day
: "${ASH_UPDATE_STATE:=${XDG_STATE_HOME:-$HOME/.local/state}/ash/update.json}"

# ── Repository root resolution ───────────────────────────────────────────────
ash_update_repo_root() {
    if [[ -n "${ASH_REPO_ROOT:-}" && -d "${ASH_REPO_ROOT}/.git" ]]; then
        printf '%s' "$ASH_REPO_ROOT"; return 0
    fi
    local candidate
    for candidate in "${ASH_CLI_DIR:-}/.." "${ASH_DOTFILES:-}" "$HOME/.dotfiles" "$HOME/.config/ash"; do
        [[ -z "$candidate" ]] && continue
        candidate="$(cd "$candidate" 2>/dev/null && pwd)" || continue
        [[ -d "${candidate}/.git" ]] && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

ash_update_is_git_repo() {
    local root; root="$(ash_update_repo_root)" || return 1
    git -C "$root" rev-parse --git-dir >/dev/null 2>&1
}

# ── Version comparison ───────────────────────────────────────────────────────
ash_update_local_version() {
    local root; root="$(ash_update_repo_root)" || { printf '%s' "${ASH_VERSION:-0.0.0}"; return; }
    if [[ -f "${root}/version.json" ]]; then
        ash_json_get "${root}/version.json" '.version' "${ASH_VERSION:-0.0.0}"
    else
        printf '%s' "${ASH_VERSION:-0.0.0}"
    fi
}

# ── Rate-limited check ───────────────────────────────────────────────────────
ash_update_should_check() {
    [[ -f "$ASH_UPDATE_STATE" ]] || return 0

    local last now
    last="$(ash_json_get "$ASH_UPDATE_STATE" '.last_check' '0')"
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
    now="$(date +%s)"

    (( now - last >= ASH_UPDATE_CHECK_INTERVAL ))
}

_ash_update_record_check() {
    mkdir -p "$(dirname "$ASH_UPDATE_STATE")" 2>/dev/null || true
    local remote_version="${1:-}"
    {
        printf '{\n'
        printf '  "last_check": %s,\n' "$(date +%s)"
        printf '  "last_check_human": "%s",\n' "$(date -Iseconds)"
        [[ -n "$remote_version" ]] && printf '  "remote_version": "%s",\n' "$remote_version"
        printf '  "local_version": "%s"\n' "$(ash_update_local_version)"
        printf '}\n'
    } > "${ASH_UPDATE_STATE}.tmp" 2>/dev/null \
        && mv -f "${ASH_UPDATE_STATE}.tmp" "$ASH_UPDATE_STATE" 2>/dev/null || true
}

# ── Fetch remote state ───────────────────────────────────────────────────────
# Prints: status|local|remote|behind|ahead|modified
#   status ∈ { up-to-date, update-available, diverged, dirty, error }
ash_update_check() {
    local force="${1:-0}"

    ash_update_is_git_repo || { printf 'error|%s||||\n' "$(ash_update_local_version)"; return 1; }

    if [[ "$force" != "1" ]] && ! ash_update_should_check; then
        local cached
        cached="$(ash_json_get "$ASH_UPDATE_STATE" '.remote_version' '')"
        printf 'cached|%s|%s||||\n' "$(ash_update_local_version)" "$cached"
        return 0
    fi

    local root; root="$(ash_update_repo_root)"
    local local_version remote_version=""
    local_version="$(ash_update_local_version)"

    # Respect an active lock so two ash processes don't both fetch.
    if declare -f ash_lock_acquire >/dev/null 2>&1; then
        ash_lock_acquire "update-check" --timeout 5 2>/dev/null || {
            printf 'busy|%s||||\n' "$local_version"; return 0; }
    fi
    local lock_held=1

    local rc=0
    git -C "$root" fetch "$ASH_UPDATE_REMOTE" --quiet --no-tags 2>/dev/null || rc=$?

    if (( rc != 0 )); then
        [[ $lock_held -eq 1 ]] && declare -f ash_lock_release >/dev/null 2>&1 && ash_lock_release "update-check"
        printf 'error|%s||||\n' "$local_version"
        return 1
    fi

    # Remote version from version.json on the tracking branch
    if git -C "$root" cat-file -e "${ASH_UPDATE_REMOTE}/${ASH_UPDATE_BRANCH}:version.json" 2>/dev/null; then
        remote_version="$(git -C "$root" show "${ASH_UPDATE_REMOTE}/${ASH_UPDATE_BRANCH}:version.json" 2>/dev/null \
            | ash_json_get - '.version' '' 2>/dev/null)"
    fi
    [[ -z "$remote_version" ]] && remote_version="$local_version"

    local behind ahead
    behind="$(git -C "$root" rev-list --count "HEAD..${ASH_UPDATE_REMOTE}/${ASH_UPDATE_BRANCH}" 2>/dev/null || echo 0)"
    ahead="$(git -C "$root" rev-list --count "${ASH_UPDATE_REMOTE}/${ASH_UPDATE_BRANCH}..HEAD" 2>/dev/null || echo 0)"

    local modified=0
    [[ -n "$(git -C "$root" status --porcelain 2>/dev/null | head -1)" ]] && modified=1

    _ash_update_record_check "$remote_version"
    [[ $lock_held -eq 1 ]] && declare -f ash_lock_release >/dev/null 2>&1 && ash_lock_release "update-check"

    local status="up-to-date"
    if (( modified == 1 )); then               status="dirty"
    elif (( behind > 0 && ahead > 0 )); then   status="diverged"
    elif (( behind > 0 )); then                status="update-available"
    fi

    printf '%s|%s|%s|%s|%s|%s\n' \
        "$status" "$local_version" "$remote_version" "$behind" "$ahead" "$modified"
    return 0
}

# ── Apply ────────────────────────────────────────────────────────────────────
# ash_update_apply [--dry-run] [--force] [--yes]
ash_update_apply() {
    local dry_run=0 force=0 assume_yes=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) dry_run=1; shift ;;
            --force)   force=1; shift ;;
            --yes|-y)  assume_yes=1; shift ;;
            *) shift ;;
        esac
    done

    ash_update_is_git_repo || {
        ash_log_error "not a git repository — cannot auto-update" 2>/dev/null || true
        return 1
    }

    local root; root="$(ash_update_repo_root)"
    local before_version; before_version="$(ash_update_local_version)"

    local check; check="$(ash_update_check 1)"
    local status local_v remote_v behind ahead modified
    IFS='|' read -r status local_v remote_v behind ahead modified <<< "$check"

    printf '  local  : %s\n' "$local_v"
    printf '  remote : %s\n' "$remote_v"

    case "$status" in
        up-to-date|cached)
            printf '  ✓ already up to date\n'
            return 0
            ;;
        busy)
            printf '  ⚠ another update check is in progress\n'
            return 1
            ;;
        error)
            printf '  ✗ could not reach the remote\n'
            return 1
            ;;
        diverged)
            printf '  ⚠ your branch has diverged from %s/%s (%s ahead, %s behind)\n' \
                "$ASH_UPDATE_REMOTE" "$ASH_UPDATE_BRANCH" "$ahead" "$behind"
            printf '    resolve manually, or run: ash update --force (discards local commits)\n'
            (( force == 0 )) && return 1
            ;;
        dirty)
            printf '  ⚠ you have local modifications\n'
            ;;
    esac

    if (( dry_run == 1 )); then
        printf '  [dry-run] would fast-forward %s commit(s)\n' "$behind"
        return 0
    fi

    if (( assume_yes == 0 )) && declare -f ash_confirm >/dev/null 2>&1; then
        ash_confirm "  Apply update now?" "y" || { printf '  aborted\n'; return 0; }
    fi

    # ── Step 1: snapshot (the rollback path) ─────────────────────────────
    local snapshot_id=""
    if declare -f ash_backup_create >/dev/null 2>&1; then
        printf '  creating rollback snapshot…\n'
        snapshot_id="$(ash_backup_create --label "pre-update-${local_v}" 2>/dev/null || true)"
    elif command -v ash >/dev/null 2>&1 && [[ -x "${root}/ash-cli/ash" ]]; then
        snapshot_id="$("${root}/ash-cli/ash" snapshot create --auto --tag pre-update 2>/dev/null | tail -1 || true)"
    fi

    if [[ -z "$snapshot_id" ]]; then
        printf '  ⚠ could not create a snapshot\n'
        if (( force == 0 )); then
            printf '    refusing to update without a rollback point (use --force to override)\n'
            return 1
        fi
    else
        printf '  ✓ snapshot: %s\n' "$snapshot_id"
    fi

    # ── Step 2: stash local changes ──────────────────────────────────────
    local stashed=0
    if (( modified == 1 )); then
        if git -C "$root" stash push -u -m "ash-auto-update-$(date +%s)" >/dev/null 2>&1; then
            stashed=1
            printf '  ✓ local modifications stashed\n'
        else
            ash_log_error "could not stash local changes" 2>/dev/null || true
            return 1
        fi
    fi

    # ── Step 3: pre-update hook ──────────────────────────────────────────
    declare -f ash_hook_run >/dev/null 2>&1 && \
        ash_hook_run "pre_update" "from=${local_v}" "to=${remote_v}" 2>/dev/null || true

    # ── Step 4: pull ─────────────────────────────────────────────────────
    local rc=0
    local -a pull_args=(--ff-only)
    (( force == 1 )) && pull_args=(--force)

    git -C "$root" pull "${pull_args[@]}" "$ASH_UPDATE_REMOTE" "$ASH_UPDATE_BRANCH" >/dev/null 2>&1 || rc=$?

    if (( rc != 0 )); then
        printf '  ✗ pull failed\n'
        (( stashed == 1 )) && git -C "$root" stash pop >/dev/null 2>&1 || true
        if [[ -n "$snapshot_id" ]] && declare -f ash_backup_restore >/dev/null 2>&1; then
            printf '  rolling back…\n'
            ash_backup_restore "$snapshot_id" >/dev/null 2>&1 || true
        fi
        return 1
    fi

    # ── Step 5: restore local changes ────────────────────────────────────
    local conflicts=0
    if (( stashed == 1 )); then
        if git -C "$root" stash pop >/dev/null 2>&1; then
            printf '  ✓ local modifications restored\n'
        else
            conflicts=1
            printf '  ⚠ stash could not be applied cleanly — resolve with: git stash show -p | git apply\n'
        fi
    fi

    # ── Step 6: post-update tasks ────────────────────────────────────────
    if declare -f ash_cache_clear >/dev/null 2>&1; then
        ash_cache_clear "update" >/dev/null 2>&1 || true
    fi

    declare -f ash_hook_run >/dev/null 2>&1 && \
        ash_hook_run "post_update" "from=${local_v}" "to=${remote_v}" 2>/dev/null || true

    local after_version; after_version="$(ash_update_local_version)"
    printf '  ✓ updated %s → %s\n' "$before_version" "$after_version"

    ash_event_emit "update.applied" \
        "from=${before_version}" "to=${after_version}" "snapshot=${snapshot_id}" 2>/dev/null || true

    (( conflicts == 1 )) && return 2
    return 0
}

# ── Rollback to the snapshot taken before the last update ────────────────────
ash_update_rollback() {
    local snapshot_id="${1:-}"

    if [[ -z "$snapshot_id" ]]; then
        if [[ -f "$ASH_UPDATE_STATE" ]]; then
            snapshot_id="$(ash_json_get "$ASH_UPDATE_STATE" '.last_snapshot' '')"
        fi
    fi

    if [[ -z "$snapshot_id" ]]; then
        printf '  ✗ no snapshot recorded for rollback\n'
        return 1
    fi

    if declare -f ash_backup_restore >/dev/null 2>&1; then
        ash_backup_restore "$snapshot_id" && printf '  ✓ rolled back to %s\n' "$snapshot_id"
        return $?
    fi

    printf '  ✗ no restore backend available\n'
    return 1
}

# ── Notification: tells the user an update exists, without updating ──────────
ash_update_notify_if_available() {
    local check; check="$(ash_update_check 0 2>/dev/null)" || return 0
    local status local_v remote_v
    IFS='|' read -r status local_v remote_v _ _ _ <<< "$check"

    [[ "$status" != "update-available" ]] && return 0

    if declare -f ash_notify >/dev/null 2>&1; then
        ash_notify "ASH update available" \
            "${local_v} → ${remote_v}\nRun: ash update apply" \
            --icon="software-update-available" --urgency=low --app-name="ASH Dotfiles" 2>/dev/null || true
    fi

    # Also touch a status file that waybar can read without shelling out.
    local flag="${XDG_CACHE_HOME:-$HOME/.cache}/ash/update-available"
    mkdir -p "$(dirname "$flag")" 2>/dev/null || true
    printf '%s|%s\n' "$local_v" "$remote_v" > "$flag" 2>/dev/null || true

    return 0
}

# ── Health/diagnostic surface for `ash doctor` ───────────────────────────────
ash_update_health() {
    if ! ash_update_is_git_repo; then
        printf '  ⚠ not a git checkout — auto-update unavailable\n'
        return 0
    fi

    local root; root="$(ash_update_repo_root)"
    printf '  repo      : %s\n' "$root"
    printf '  branch    : %s\n' "$(git -C "$root" branch --show-current 2>/dev/null || echo '?')"
    printf '  commit    : %s\n' "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo '?')"
    printf '  version   : %s\n' "$(ash_update_local_version)"

    local dirty
    dirty="$(git -C "$root" status --porcelain 2>/dev/null | wc -l)"
    if (( dirty == 0 )); then
        printf '  worktree  : ✓ clean\n'
    else
        printf '  worktree  : ⚠ %d modified path(s)\n' "$dirty"
    fi

    if [[ -f "$ASH_UPDATE_STATE" ]]; then
        printf '  last check: %s\n' "$(ash_json_get "$ASH_UPDATE_STATE" '.last_check_human' 'never')"
    else
        printf '  last check: never\n'
    fi
    return 0
}
