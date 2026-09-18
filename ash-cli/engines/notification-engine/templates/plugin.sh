#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/notification-engine/templates/plugin.sh                              ║
# ║  Library: sourced, never executed directly. Provides plugin helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_NOTIFICATION_ENGINE_TEMPLATES_PLUGIN_LOADED:-}" ]] && return 0
readonly _ASH_NOTIFICATION_ENGINE_TEMPLATES_PLUGIN_LOADED=1

# ── plugin — primary entry ───────────────────────────────────────────────
ash_notification_engine_templates_plugin() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_notification_engine_templates_plugin::help ;;
        *) ash_log_warn "plugin: unknown subcommand '$sub' — see help" 2>/dev/null || echo "plugin: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_notification_engine_templates_plugin::help() {
    cat <<'EOF'
ash-cli/engines/notification-engine/templates/plugin.sh — plugin engine helper

Usage: ash_notification_engine_templates_plugin [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_notification_engine_templates_plugin::run() {
    ash_log_info "plugin: run (placeholder — engine not yet wired)" 2>/dev/null || echo "plugin: run placeholder"
    return 0
}
