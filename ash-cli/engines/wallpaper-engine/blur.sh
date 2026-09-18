#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/blur.sh                              ║
# ║  Library: sourced, never executed directly. Provides blur helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_BLUR_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_BLUR_LOADED=1

# ── blur — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_blur() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_blur::help ;;
        *) ash_log_warn "blur: unknown subcommand '$sub' — see help" 2>/dev/null || echo "blur: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_blur::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/blur.sh — blur engine helper

Usage: ash_wallpaper_engine_blur [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_blur::run() {
    ash_log_info "blur: run (placeholder — engine not yet wired)" 2>/dev/null || echo "blur: run placeholder"
    return 0
}
