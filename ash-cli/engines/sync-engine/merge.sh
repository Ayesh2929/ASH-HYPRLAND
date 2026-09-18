#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/sync-engine/merge.sh                              ║
# ║  Library: sourced, never executed directly. Provides merge helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SYNC_ENGINE_MERGE_LOADED:-}" ]] && return 0
readonly _ASH_SYNC_ENGINE_MERGE_LOADED=1

# ── merge — primary entry ───────────────────────────────────────────────
ash_sync_engine_merge() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_sync_engine_merge::help ;;
        *) ash_log_warn "merge: unknown subcommand '$sub' — see help" 2>/dev/null || echo "merge: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_sync_engine_merge::help() {
    cat <<'EOF'
ash-cli/engines/sync-engine/merge.sh — merge engine helper

Usage: ash_sync_engine_merge [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_sync_engine_merge::run() {
    ash_log_info "merge: run (placeholder — engine not yet wired)" 2>/dev/null || echo "merge: run placeholder"
    return 0
}
