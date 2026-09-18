#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/backup-engine/incremental.sh                              ║
# ║  Library: sourced, never executed directly. Provides incremental helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_BACKUP_ENGINE_INCREMENTAL_LOADED:-}" ]] && return 0
readonly _ASH_BACKUP_ENGINE_INCREMENTAL_LOADED=1

# ── incremental — primary entry ───────────────────────────────────────────────
ash_backup_engine_incremental() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_backup_engine_incremental::help ;;
        *) ash_log_warn "incremental: unknown subcommand '$sub' — see help" 2>/dev/null || echo "incremental: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_backup_engine_incremental::help() {
    cat <<'EOF'
ash-cli/engines/backup-engine/incremental.sh — incremental engine helper

Usage: ash_backup_engine_incremental [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_backup_engine_incremental::run() {
    ash_log_info "incremental: run (placeholder — engine not yet wired)" 2>/dev/null || echo "incremental: run placeholder"
    return 0
}
