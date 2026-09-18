#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/hot-reload-engine/reload-rofi.sh                              ║
# ║  Library: sourced, never executed directly. Provides reload rofi helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_HOT_RELOAD_ENGINE_RELOAD_ROFI_LOADED:-}" ]] && return 0
readonly _ASH_HOT_RELOAD_ENGINE_RELOAD_ROFI_LOADED=1

# ── reload rofi — primary entry ───────────────────────────────────────────────
ash_hot_reload_engine_reload_rofi() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_hot_reload_engine_reload_rofi::help ;;
        *) ash_log_warn "reload rofi: unknown subcommand '$sub' — see help" 2>/dev/null || echo "reload rofi: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_hot_reload_engine_reload_rofi::help() {
    cat <<'EOF'
ash-cli/engines/hot-reload-engine/reload-rofi.sh — reload rofi engine helper

Usage: ash_hot_reload_engine_reload_rofi [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_hot_reload_engine_reload_rofi::run() {
    ash_log_info "reload rofi: run (placeholder — engine not yet wired)" 2>/dev/null || echo "reload rofi: run placeholder"
    return 0
}
