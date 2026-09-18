#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/ipc-engine/client.sh                              ║
# ║  Library: sourced, never executed directly. Provides client helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_IPC_ENGINE_CLIENT_LOADED:-}" ]] && return 0
readonly _ASH_IPC_ENGINE_CLIENT_LOADED=1

# ── client — primary entry ───────────────────────────────────────────────
ash_ipc_engine_client() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_ipc_engine_client::help ;;
        *) ash_log_warn "client: unknown subcommand '$sub' — see help" 2>/dev/null || echo "client: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_ipc_engine_client::help() {
    cat <<'EOF'
ash-cli/engines/ipc-engine/client.sh — client engine helper

Usage: ash_ipc_engine_client [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_ipc_engine_client::run() {
    ash_log_info "client: run (placeholder — engine not yet wired)" 2>/dev/null || echo "client: run placeholder"
    return 0
}
