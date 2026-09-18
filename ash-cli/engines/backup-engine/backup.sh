#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/backup-engine/backup.sh                              ║
# ║  Library: sourced, never executed directly. Provides backup helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_BACKUP_ENGINE_BACKUP_LOADED:-}" ]] && return 0
readonly _ASH_BACKUP_ENGINE_BACKUP_LOADED=1

# ── backup — primary entry ───────────────────────────────────────────────
ash_backup_engine_backup() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_backup_engine_backup::help ;;
        *) ash_log_warn "backup: unknown subcommand '$sub' — see help" 2>/dev/null || echo "backup: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_backup_engine_backup::help() {
    cat <<'EOF'
ash-cli/engines/backup-engine/backup.sh — backup engine helper

Usage: ash_backup_engine_backup [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_backup_engine_backup::run() {
    ash_log_info "backup: run (placeholder — engine not yet wired)" 2>/dev/null || echo "backup: run placeholder"
    return 0
}
