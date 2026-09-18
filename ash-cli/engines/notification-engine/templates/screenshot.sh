#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/notification-engine/templates/screenshot.sh                              ║
# ║  Library: sourced, never executed directly. Provides screenshot helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_NOTIFICATION_ENGINE_TEMPLATES_SCREENSHOT_LOADED:-}" ]] && return 0
readonly _ASH_NOTIFICATION_ENGINE_TEMPLATES_SCREENSHOT_LOADED=1

# ── screenshot — primary entry ───────────────────────────────────────────────
ash_notification_engine_templates_screenshot() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_notification_engine_templates_screenshot::help ;;
        *) ash_log_warn "screenshot: unknown subcommand '$sub' — see help" 2>/dev/null || echo "screenshot: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_notification_engine_templates_screenshot::help() {
    cat <<'EOF'
ash-cli/engines/notification-engine/templates/screenshot.sh — screenshot engine helper

Usage: ash_notification_engine_templates_screenshot [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_notification_engine_templates_screenshot::run() {
    ash_log_info "screenshot: run (placeholder — engine not yet wired)" 2>/dev/null || echo "screenshot: run placeholder"
    return 0
}
