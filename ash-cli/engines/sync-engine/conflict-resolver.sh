#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/sync-engine/conflict-resolver.sh                              ║
# ║  Library: sourced, never executed directly. Provides conflict resolver helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SYNC_ENGINE_CONFLICT_RESOLVER_LOADED:-}" ]] && return 0
readonly _ASH_SYNC_ENGINE_CONFLICT_RESOLVER_LOADED=1

# ── conflict resolver — primary entry ───────────────────────────────────────────────
ash_sync_engine_conflict_resolver() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_sync_engine_conflict_resolver::help ;;
        *) ash_log_warn "conflict resolver: unknown subcommand '$sub' — see help" 2>/dev/null || echo "conflict resolver: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_sync_engine_conflict_resolver::help() {
    cat <<'EOF'
ash-cli/engines/sync-engine/conflict-resolver.sh — conflict resolver engine helper

Usage: ash_sync_engine_conflict_resolver [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_sync_engine_conflict_resolver::run() {
    ash_log_info "conflict resolver: run (placeholder — engine not yet wired)" 2>/dev/null || echo "conflict resolver: run placeholder"
    return 0
}
