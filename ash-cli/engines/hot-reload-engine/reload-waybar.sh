#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-waybar.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload waybar helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_WAYBAR_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_WAYBAR_LOADED=1

# ── reload waybar — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_waybar() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_waybar::help ;;
        *) ash_log_warn "reload waybar: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload waybar: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_waybar::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-waybar.sh — reload waybar engine helper

Usage: ash_hot_reload_engine_reload_waybar [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_waybar::run() {
    ash_log_info "reload waybar: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload waybar: run placeholder"
    return 0
}
