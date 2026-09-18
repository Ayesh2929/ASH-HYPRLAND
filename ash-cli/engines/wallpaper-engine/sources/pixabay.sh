#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/sources/pixabay.sh                              ║
# ║  Library: sourced, never executed directly. Provides pixabay helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_SOURCES_PIXABAY_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_SOURCES_PIXABAY_LOADED=1

# ── pixabay — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_sources_pixabay() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_sources_pixabay::help ;;
        *) ash_log_warn "pixabay: unknown subcommand '$sub' — see help" 2>/dev/null || echo "pixabay: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_sources_pixabay::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/sources/pixabay.sh — pixabay engine helper

Usage: ash_wallpaper_engine_sources_pixabay [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_sources_pixabay::run() {
    ash_log_info "pixabay: run (placeholder — engine not yet wired)" 2>/dev/null || echo "pixabay: run placeholder"
    return 0
}
