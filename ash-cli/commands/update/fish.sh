#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update fish                                              ║
# ║  Fish shell + Fisher plugin manager + all fish plugins + completions rebuild    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_FISH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_FISH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_fish() {
    upd_section "🐟" "Fish Shell Update" "$(_usky)"

    # ── Fish binary ───────────────────────────────────────────────────────────────
    if ! command -v fish &>/dev/null; then
        upd_fail "Fish shell not installed"
        upd_info "Install: paru -S fish"
        upd_result_fail "fish (not installed)"
        return 1
    fi

    local fish_ver
    fish_ver="$(fish --version 2>/dev/null | grep -oP '[\d.]+')"
    upd_kv "Fish version" "$fish_ver"

    # Update fish via package manager
    upd_step "Updating fish via package manager..."
    if [[ "$_UPD_PKG_MANAGER" == "pacman" ]] && [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        "${_UPD_AUR_HELPER:-pacman}" -S --needed \
            "$([[ -n "$_UPD_AUR_HELPER" ]] && echo '--noconfirm' || echo '')" \
            fish 2>/dev/null || true
    fi

    # ── Fisher plugin manager ─────────────────────────────────────────────────────
    upd_section "🎣" "Fisher Plugins" "$(_uteal)"

    local fisher_path="${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions/fisher.fish"

    if [[ ! -f "$fisher_path" ]]; then
        upd_info "Fisher not installed"
        upd_step "Installing Fisher..."
        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" \
                2>/dev/null && upd_ok "Fisher installed" || upd_warn "Fisher install failed"
        fi
    else
        # Self-update Fisher
        upd_step "Updating Fisher plugin manager..."
        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            fish -c "fisher update jorgebucaran/fisher" 2>/dev/null && \
                upd_ok "Fisher updated" || upd_warn "Fisher self-update failed"
        fi
    fi

    # ── List installed Fisher plugins ─────────────────────────────────────────────
    local fisher_list_file="${XDG_CONFIG_HOME:-$HOME/.config}/fish/fish_plugins"
    if [[ -f "$fisher_list_file" ]]; then
        local plugin_count
        plugin_count="$(wc -l < "$fisher_list_file")"
        upd_kv "Fish plugins" "$plugin_count"

        cat "$fisher_list_file" | \
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            printf '    %s•%s  %s%s%s\n' \
                "$(_udim)" "$(_ur)" "$(_usky)" "$plugin" "$(_ur)"
        done

        # Update all Fisher plugins
        upd_step "Updating all Fish plugins..."
        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            if fish -c "fisher update" 2>/dev/null; then
                upd_ok "All Fish plugins updated"
            else
                upd_warn "Fisher update had issues"
            fi
        else
            upd_info "[dry-run] Would run: fisher update"
        fi
    fi

    # ── Rebuild completions cache ─────────────────────────────────────────────────
    upd_step "Rebuilding completions cache..."
    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        fish -c "fish_update_completions" 2>/dev/null && \
            upd_ok "Completions cache rebuilt" || \
            upd_warn "Completion rebuild had issues"
    fi

    # ── ASH fish conf.d ───────────────────────────────────────────────────────────
    local fish_confd="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
    if [[ -d "$fish_confd" ]]; then
        local confd_count
        confd_count="$(find "$fish_confd" -name '*.fish' | wc -l)"
        upd_kv "conf.d files" "$confd_count"

        # Syntax check
        local broken=0
        while IFS= read -r ff; do
            fish --no-execute "$ff" 2>/dev/null || (( broken++ )) || true
        done < <(find "$fish_confd" -name '*.fish' 2>/dev/null)

        if (( broken == 0 )); then
            upd_ok "All conf.d files syntax-valid"
        else
            upd_warn "${broken} conf.d file(s) have syntax errors"
        fi
    fi

    upd_result_pass "fish"
    upd_ok "Fish shell environment updated"
}
