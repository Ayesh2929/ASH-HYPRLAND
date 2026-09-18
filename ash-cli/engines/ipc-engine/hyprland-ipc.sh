#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/ipc-engine/hyprland-ipc.sh                              ║
# ║  Library: sourced, never executed directly. Provides hyprland ipc helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_IPC_ENGINE_HYPRLAND_IPC_LOADED:-}" ]] && return 0
readonly _ASH_IPC_ENGINE_HYPRLAND_IPC_LOADED=1

# ── hyprland ipc — primary entry ───────────────────────────────────────────────
ash_ipc_engine_hyprland_ipc() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_ipc_engine_hyprland_ipc::help ;;
        *) ash_log_warn "hyprland ipc: unknown subcommand '$sub' — see help" 2>/dev/null || echo "hyprland ipc: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_ipc_engine_hyprland_ipc::help() {
    cat <<'EOF'
ash-cli/engines/ipc-engine/hyprland-ipc.sh — hyprland ipc engine helper

Usage: ash_ipc_engine_hyprland_ipc [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_ipc_engine_hyprland_ipc::run() {
    ash_log_info "hyprland ipc: run (placeholder — engine not yet wired)" 2>/dev/null || echo "hyprland ipc: run placeholder"
    return 0
}
