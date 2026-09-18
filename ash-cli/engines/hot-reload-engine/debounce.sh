#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/debounce.sh                              ║
# ║  Library: sourced, never executed directly. Provides debounce helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_DEBOUNCE_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_DEBOUNCE_LOADED=1

# ── debounce — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_debounce() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_debounce::help ;;
        *) ash_log_warn "debounce: unknown subcommand '$sub' — see help" 2>/dev/null || echo "debounce: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_debounce::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/debounce.sh — debounce engine helper

Usage: ash_hot_reload_engine_debounce [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_debounce::run() {
    ash_log_info "debounce: run (placeholder — engine not yet wired)" 2>/dev/null || echo "debounce: run placeholder"
    return 0
}
