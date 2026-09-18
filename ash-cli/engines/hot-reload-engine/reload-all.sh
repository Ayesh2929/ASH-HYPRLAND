#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-all.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload all helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_ALL_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_ALL_LOADED=1

# ── reload all — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_all() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_all::help ;;
        *) ash_log_warn "reload all: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload all: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_all::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-all.sh — reload all engine helper

Usage: ash_hot_reload_engine_reload_all [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_all::run() {
    ash_log_info "reload all: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload all: run placeholder"
    return 0
}
