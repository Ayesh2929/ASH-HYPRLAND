#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/notification-engine/templates/theme-change.sh                              ║
# ║  Library: sourced, never executed directly. Provides theme change helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_NOTIFICATION_ENGINE_TEMPLATES_THEME_CHANGE_LOADED:-}" ]] && return 0
readonly _ASH_NOTIFICATION_ENGINE_TEMPLATES_THEME_CHANGE_LOADED=1

# ── theme change — primary entry ───────────────────────────────────────────────
ash_notification_engine_templates_theme_change() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_notification_engine_templates_theme_change::help ;;
        *) ash_log_warn "theme change: unknown subcommand '$sub' — see help" 2>/dev/null || echo "theme change: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_notification_engine_templates_theme_change::help() {
    cat <<'EOF'
ash-cli/engines/notification-engine/templates/theme-change.sh — theme change engine helper

Usage: ash_notification_engine_templates_theme_change [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_notification_engine_templates_theme_change::run() {
    ash_log_info "theme change: run (placeholder — engine not yet wired)" 2>/dev/null || echo "theme change: run placeholder"
    return 0
}
