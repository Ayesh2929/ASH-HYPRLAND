#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/session-engine/deserialize.sh                              ║
# ║  Library: sourced, never executed directly. Provides deserialize helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_SESSION_ENGINE_DESERIALIZE_LOADED:-}" ]] && return 0
readonly _ASH_SESSION_ENGINE_DESERIALIZE_LOADED=1

# ── deserialize — primary entry ───────────────────────────────────────────────
ash_session_engine_deserialize() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_session_engine_deserialize::help ;;
        *) ash_log_warn "deserialize: unknown subcommand '$sub' — see help" 2>/dev/null || echo "deserialize: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_session_engine_deserialize::help() {
    cat <<'EOF'
ash-cli/engines/session-engine/deserialize.sh — deserialize engine helper

Usage: ash_session_engine_deserialize [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_session_engine_deserialize::run() {
    ash_log_info "deserialize: run (placeholder — engine not yet wired)" 2>/dev/null || echo "deserialize: run placeholder"
    return 0
}
