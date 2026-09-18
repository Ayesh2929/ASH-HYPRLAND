#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/sync-engine/delta.sh                              ║
# ║  Library: sourced, never executed directly. Provides delta helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SYNC_ENGINE_DELTA_LOADED:-}" ]] && return 0
readonly _ASH_SYNC_ENGINE_DELTA_LOADED=1

# ── delta — primary entry ───────────────────────────────────────────────
ash_sync_engine_delta() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_sync_engine_delta::help ;;
        *) ash_log_warn "delta: unknown subcommand '$sub' — see help" 2>/dev/null || echo "delta: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_sync_engine_delta::help() {
    cat <<'EOF'
ash-cli/engines/sync-engine/delta.sh — delta engine helper

Usage: ash_sync_engine_delta [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_sync_engine_delta::run() {
    ash_log_info "delta: run (placeholder — engine not yet wired)" 2>/dev/null || echo "delta: run placeholder"
    return 0
}
