#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/sources/local.sh                              ║
# ║  Library: sourced, never executed directly. Provides local helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_SOURCES_LOCAL_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_SOURCES_LOCAL_LOADED=1

# ── local — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_sources_local() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_sources_local::help ;;
        *) ash_log_warn "local: unknown subcommand '$sub' — see help" 2>/dev/null || echo "local: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_sources_local::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/sources/local.sh — local engine helper

Usage: ash_wallpaper_engine_sources_local [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_sources_local::run() {
    ash_log_info "local: run (placeholder — engine not yet wired)" 2>/dev/null || echo "local: run placeholder"
    return 0
}
