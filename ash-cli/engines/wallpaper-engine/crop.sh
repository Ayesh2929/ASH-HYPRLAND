#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/wallpaper-engine/crop.sh                              ║
# ║  Library: sourced, never executed directly. Provides crop helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_WALLPAPER_ENGINE_CROP_LOADED:-}" ]] && return 0
readonly _ASH_WALLPAPER_ENGINE_CROP_LOADED=1

# ── crop — primary entry ───────────────────────────────────────────────
ash_wallpaper_engine_crop() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_wallpaper_engine_crop::help ;;
        *) ash_log_warn "crop: unknown subcommand '$sub' — see help" 2>/dev/null || echo "crop: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_wallpaper_engine_crop::help() {
    cat <<'EOF'
ash-cli/engines/wallpaper-engine/crop.sh — crop engine helper

Usage: ash_wallpaper_engine_crop [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_wallpaper_engine_crop::run() {
    ash_log_info "crop: run (placeholder — engine not yet wired)" 2>/dev/null || echo "crop: run placeholder"
    return 0
}
