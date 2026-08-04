#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update plugins                                           ║
# ║  ASH plugin registry update • version checks • git-based plugin refresh         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_PLUGINS_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_PLUGINS_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_plugins() {
    upd_section "🔌" "ASH Plugins Update" "$(_ulav)"

    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
    local plugins_dir="${ash_root}/plugins"
    local ash_data="${XDG_DATA_HOME:-$HOME/.local/share}/ash/plugins"

    if [[ ! -d "$plugins_dir" ]]; then
        upd_fail "Plugins directory not found: ${plugins_dir}"
        return 1
    fi

    local total=0  updated=0  failed=0  skipped=0

    # ── Core plugins (bundled with dotfiles, updated via dotfiles update) ─────────
    upd_step "Checking bundled core plugins..."
    local core_count
    core_count="$(find "${plugins_dir}/core" -name 'plugin.json' 2>/dev/null | wc -l)"
    upd_kv "Core plugins" "${core_count} bundled"
    (( total += core_count )) || true

    # ── Community plugins (git repos in ASH data dir) ────────────────────────────
    upd_section "🌐" "Community Plugins" "$(_uteal)"

    if [[ -d "$ash_data" ]]; then
        local -a plugin_dirs=()
        mapfile -t plugin_dirs < <(
            find "$ash_data" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort
        )

        if [[ ${#plugin_dirs[@]} -eq 0 ]]; then
            upd_info "No community plugins installed"
        fi

        for pdir in "${plugin_dirs[@]}"; do
            local pname
            pname="$(basename "$pdir")"
            (( total++ )) || true

            # Git-based plugin
            if [[ -d "${pdir}/.git" ]]; then
                upd_step "Updating plugin: ${pname}..."

                if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
                    upd_info "[dry-run] Would update: ${pname}"
                    (( skipped++ )) || true
                    continue
                fi

                local before_commit
                before_commit="$(git -C "$pdir" rev-parse --short HEAD 2>/dev/null || echo '?')"

                if git -C "$pdir" pull --rebase origin HEAD 2>/dev/null; then
                    local after_commit
                    after_commit="$(git -C "$pdir" rev-parse --short HEAD 2>/dev/null)"

                    if [[ "$before_commit" != "$after_commit" ]]; then
                        upd_ok "${pname}: ${before_commit} → ${after_commit}"
                        (( updated++ )) || true
                    else
                        upd_skip "${pname}  (no changes)"
                        (( skipped++ )) || true
                    fi
                else
                    upd_fail "${pname}: pull failed"
                    (( failed++ )) || true
                fi
            else
                # Static plugin
                upd_kv "$pname" "static  (no update needed)"
                (( skipped++ )) || true
            fi
        done
    else
        upd_info "No user plugin data directory found"
    fi

    # ── Summary ───────────────────────────────────────────────────────────────────
    printf '\n'
    upd_kv "Total plugins" "$total"
    upd_kv "Updated"       "$updated"
    upd_kv "Skipped"       "$skipped"
    [[ $failed -gt 0 ]] && upd_kv "Failed" "$failed" "$(_ured)"

    if (( failed == 0 )); then
        upd_result_pass "plugins"
        upd_ok "Plugin update complete"
    else
        upd_result_fail "plugins (${failed} failed)"
    fi
}
