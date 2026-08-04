#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update nvim                                              ║
# ║  Neovim binary + Lazy.nvim plugins + Mason LSP servers + TreeSitter parsers     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_NVIM_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_NVIM_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_nvim() {
    upd_section "📝" "Neovim Update" "$(_ugreen)"

    # ── Neovim binary ─────────────────────────────────────────────────────────────
    if ! command -v nvim &>/dev/null; then
        upd_fail "Neovim not installed"
        upd_info "Install: paru -S neovim"
        upd_result_fail "nvim (not installed)"
        return 1
    fi

    local nvim_ver
    nvim_ver="$(nvim --version 2>/dev/null | head -1 | grep -oP 'v[\d.]+')"
    upd_kv "Neovim version" "$nvim_ver"

    # Update neovim via package manager
    if [[ "$_UPD_PKG_MANAGER" == "pacman" ]] && [[ -n "$_UPD_AUR_HELPER" ]]; then
        upd_step "Updating neovim via ${_UPD_AUR_HELPER}..."
        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            "$_UPD_AUR_HELPER" -S --needed --noconfirm neovim 2>/dev/null || true
        fi
    fi

    # ── Lazy.nvim plugins ─────────────────────────────────────────────────────────
    upd_section "📦" "Lazy.nvim Plugins" "$(_uteal)"

    local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
    if [[ -d "$lazy_dir" ]]; then
        local plugin_count
        plugin_count="$(find "$lazy_dir" -maxdepth 1 -mindepth 1 -type d | wc -l)"
        upd_kv "Installed plugins" "$plugin_count"
    fi

    upd_step "Running Lazy.nvim sync..."

    if [[ "${ASH_UPD_DRY:-0}" -eq 1 ]]; then
        upd_info "[dry-run] Would run: nvim --headless '+Lazy! sync' +qa"
    else
        local lazy_output
        if timeout 120 nvim --headless \
            --cmd 'set noswapfile' \
            "+Lazy! sync" \
            "+qa" 2>&1 | head -30; then
            upd_ok "Lazy.nvim sync complete"
        else
            upd_warn "Lazy.nvim sync timed out or failed"
            upd_info "Run manually: nvim → :Lazy sync"
        fi
    fi

    # ── Mason packages ────────────────────────────────────────────────────────────
    upd_section "🔧" "Mason LSP/Formatters" "$(_usapph)"

    local mason_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason"
    if [[ -d "$mason_dir" ]]; then
        local mason_count
        mason_count="$(find "${mason_dir}/packages" -maxdepth 1 \
                       -mindepth 1 -type d 2>/dev/null | wc -l)"
        upd_kv "Mason packages" "$mason_count"

        if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
            upd_step "Updating Mason packages..."
            timeout 180 nvim --headless \
                --cmd 'set noswapfile' \
                "+MasonUpdate" \
                "+qa" 2>/dev/null && \
                upd_ok "Mason packages updated" || \
                upd_warn "Mason update incomplete — run :MasonUpdate in Neovim"
        fi
    else
        upd_info "Mason not initialized"
    fi

    # ── TreeSitter parsers ─────────────────────────────────────────────────────────
    upd_step "Updating TreeSitter parsers..."
    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        timeout 120 nvim --headless \
            --cmd 'set noswapfile' \
            "+TSUpdateSync" \
            "+qa" 2>/dev/null && \
            upd_ok "TreeSitter parsers updated" || \
            upd_warn "TSUpdate failed — run :TSUpdateSync in Neovim"
    fi

    upd_result_pass "nvim"
}
