#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-ags.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload ags helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_AGS_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_AGS_LOADED=1

# ── reload ags — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_ags() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_ags::help ;;
        *) ash_log_warn "reload ags: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload ags: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_ags::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-ags.sh — reload ags engine helper

Usage: ash_hot_reload_engine_reload_ags [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_ags::run() {
    ash_log_info "reload ags: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload ags: run placeholder"
    return 0
}
