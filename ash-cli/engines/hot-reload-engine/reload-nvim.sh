#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-nvim.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload nvim helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_NVIM_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_NVIM_LOADED=1

# ── reload nvim — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_nvim() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_nvim::help ;;
        *) ash_log_warn "reload nvim: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload nvim: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_nvim::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-nvim.sh — reload nvim engine helper

Usage: ash_hot_reload_engine_reload_nvim [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_nvim::run() {
    ash_log_info "reload nvim: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload nvim: run placeholder"
    return 0
}
