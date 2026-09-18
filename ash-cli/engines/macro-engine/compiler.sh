#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/macro-engine/compiler.sh                              ║
# ║  Library: sourced, never executed directly. Provides compiler helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_MACRO_ENGINE_COMPILER_LOADED:-}" ]] && return 0
readonly _ASH_MACRO_ENGINE_COMPILER_LOADED=1

# ── compiler — primary entry ───────────────────────────────────────────────
ash_macro_engine_compiler() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_macro_engine_compiler::help ;;
        *) ash_log_warn "compiler: unknown subcommand '$sub' — see help" 2>/dev/null || echo "compiler: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_macro_engine_compiler::help() {
    cat <<'EOF'
ash-cli/engines/macro-engine/compiler.sh — compiler engine helper

Usage: ash_macro_engine_compiler [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_macro_engine_compiler::run() {
    ash_log_info "compiler: run (placeholder — engine not yet wired)" 2>/dev/null || echo "compiler: run placeholder"
    return 0
}
