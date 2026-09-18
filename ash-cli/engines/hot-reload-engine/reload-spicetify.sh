#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-spicetify.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload spicetify helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_SPICETIFY_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_SPICETIFY_LOADED=1

# ── reload spicetify — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_spicetify() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_spicetify::help ;;
        *) ash_log_warn "reload spicetify: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload spicetify: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_spicetify::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-spicetify.sh — reload spicetify engine helper

Usage: ash_hot_reload_engine_reload_spicetify [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_spicetify::run() {
    ash_log_info "reload spicetify: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload spicetify: run placeholder"
    return 0
}
