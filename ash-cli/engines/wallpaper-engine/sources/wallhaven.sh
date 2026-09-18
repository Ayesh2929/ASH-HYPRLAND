#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/sources/wallhaven.sh                              ║
# ║  Library: sourced, never executed directly. Provides wallhaven helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_SOURCES_WALLHAVEN_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_SOURCES_WALLHAVEN_LOADED=1

# ── wallhaven — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_sources_wallhaven() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_sources_wallhaven::help ;;
        *) ash_log_warn "wallhaven: unknown subcommand '$sub' — see help" 2>/dev/null || echo "wallhaven: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_sources_wallhaven::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/sources/wallhaven.sh — wallhaven engine helper

Usage: ash_wallpaper_engine_sources_wallhaven [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_sources_wallhaven::run() {
    ash_log_info "wallhaven: run (placeholder — engine not yet wired)" 2>/dev/null || echo "wallhaven: run placeholder"
    return 0
}
