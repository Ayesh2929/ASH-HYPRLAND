#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/macro-engine/recorder.sh                              ║
# ║  Library: sourced, never executed directly. Provides recorder helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_MACRO_ENGINE_RECORDER_LOADED:-}" ]] && return 0
readonly _ASH_MACRO_ENGINE_RECORDER_LOADED=1

# ── recorder — primary entry ───────────────────────────────────────────────
ash_macro_engine_recorder() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_macro_engine_recorder::help ;;
        *) ash_log_warn "recorder: unknown subcommand '$sub' — see help" 2>/dev/null || echo "recorder: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_macro_engine_recorder::help() {
    cat <<'EOF'
ash-cli/engines/macro-engine/recorder.sh — recorder engine helper

Usage: ash_macro_engine_recorder [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_macro_engine_recorder::run() {
    ash_log_info "recorder: run (placeholder — engine not yet wired)" 2>/dev/null || echo "recorder: run placeholder"
    return 0
}
