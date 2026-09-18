#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/ipc-engine/messages.sh                              ║
# ║  Library: sourced, never executed directly. Provides messages helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_IPC_ENGINE_MESSAGES_LOADED:-}" ]] && return 0
readonly _ASH_IPC_ENGINE_MESSAGES_LOADED=1

# ── messages — primary entry ───────────────────────────────────────────────
ash_ipc_engine_messages() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_ipc_engine_messages::help ;;
        *) ash_log_warn "messages: unknown subcommand '$sub' — see help" 2>/dev/null || echo "messages: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_ipc_engine_messages::help() {
    cat <<'EOF'
ash-cli/engines/ipc-engine/messages.sh — messages engine helper

Usage: ash_ipc_engine_messages [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_ipc_engine_messages::run() {
    ash_log_info "messages: run (placeholder — engine not yet wired)" 2>/dev/null || echo "messages: run placeholder"
    return 0
}
