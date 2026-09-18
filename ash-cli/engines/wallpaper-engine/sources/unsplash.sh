#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/sources/unsplash.sh                              ║
# ║  Library: sourced, never executed directly. Provides unsplash helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_SOURCES_UNSPLASH_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_SOURCES_UNSPLASH_LOADED=1

# ── unsplash — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_sources_unsplash() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_sources_unsplash::help ;;
        *) ash_log_warn "unsplash: unknown subcommand '$sub' — see help" 2>/dev/null || echo "unsplash: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_sources_unsplash::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/sources/unsplash.sh — unsplash engine helper

Usage: ash_wallpaper_engine_sources_unsplash [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_sources_unsplash::run() {
    ash_log_info "unsplash: run (placeholder — engine not yet wired)" 2>/dev/null || echo "unsplash: run placeholder"
    return 0
}
