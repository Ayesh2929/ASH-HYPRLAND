#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/slideshow.sh                              ║
# ║  Library: sourced, never executed directly. Provides slideshow helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_SLIDESHOW_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_SLIDESHOW_LOADED=1

# ── slideshow — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_slideshow() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_slideshow::help ;;
        *) ash_log_warn "slideshow: unknown subcommand '$sub' — see help" 2>/dev/null || echo "slideshow: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_slideshow::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/slideshow.sh — slideshow engine helper

Usage: ash_wallpaper_engine_slideshow [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_slideshow::run() {
    ash_log_info "slideshow: run (placeholder — engine not yet wired)" 2>/dev/null || echo "slideshow: run placeholder"
    return 0
}
