#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/notification-engine/progress.sh                              ║
# ║  Library: sourced, never executed directly. Provides progress helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_NOTIFICATION_ENGINE_PROGRESS_LOADED:-}" ]] && return 0
readonly _ASH_NOTIFICATION_ENGINE_PROGRESS_LOADED=1

# ── progress — primary entry ───────────────────────────────────────────────
ash_notification_engine_progress() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_notification_engine_progress::help ;;
        *) ash_log_warn "progress: unknown subcommand '$sub' — see help" 2>/dev/null || echo "progress: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_notification_engine_progress::help() {
    cat <<'EOF'
ash-cli/engines/notification-engine/progress.sh — progress engine helper

Usage: ash_notification_engine_progress [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_notification_engine_progress::run() {
    ash_log_info "progress: run (placeholder — engine not yet wired)" 2>/dev/null || echo "progress: run placeholder"
    return 0
}
