#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/dispatcher.sh                              ║
# ║  Library: sourced, never executed directly. Provides dispatcher helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_DISPATCHER_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_DISPATCHER_LOADED=1

# ── dispatcher — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_dispatcher() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_dispatcher::help ;;
        *) ash_log_warn "dispatcher: unknown subcommand '$sub' — see help" 2>/dev/null || echo "dispatcher: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_dispatcher::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/dispatcher.sh — dispatcher engine helper

Usage: ash_hot_reload_engine_dispatcher [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_dispatcher::run() {
    ash_log_info "dispatcher: run (placeholder — engine not yet wired)" 2>/dev/null || echo "dispatcher: run placeholder"
    return 0
}
