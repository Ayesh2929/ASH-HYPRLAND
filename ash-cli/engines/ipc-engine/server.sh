#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/ipc-engine/server.sh                              ║
# ║  Library: sourced, never executed directly. Provides server helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_IPC_ENGINE_SERVER_LOADED:-}" ]] && return 0
readonly _ASH_IPC_ENGINE_SERVER_LOADED=1

# ── server — primary entry ───────────────────────────────────────────────
ash_ipc_engine_server() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_ipc_engine_server::help ;;
        *) ash_log_warn "server: unknown subcommand '$sub' — see help" 2>/dev/null || echo "server: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_ipc_engine_server::help() {
    cat <<'EOF'
ash-cli/engines/ipc-engine/server.sh — server engine helper

Usage: ash_ipc_engine_server [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_ipc_engine_server::run() {
    ash_log_info "server: run (placeholder — engine not yet wired)" 2>/dev/null || echo "server: run placeholder"
    return 0
}
