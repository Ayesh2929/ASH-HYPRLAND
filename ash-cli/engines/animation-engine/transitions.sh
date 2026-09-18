#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/animation-engine/transitions.sh                              ║
# ║  Library: sourced, never executed directly. Provides transitions helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_ANIMATION_ENGINE_TRANSITIONS_LOADED:-}" ]] && return 0
readonly _ASH_ANIMATION_ENGINE_TRANSITIONS_LOADED=1

# ── transitions — primary entry ───────────────────────────────────────────────
ash_animation_engine_transitions() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_animation_engine_transitions::help ;;
        *) ash_log_warn "transitions: unknown subcommand '$sub' — see help" 2>/dev/null || echo "transitions: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_animation_engine_transitions::help() {
    cat <<'EOF'
ash-cli/engines/animation-engine/transitions.sh — transitions engine helper

Usage: ash_animation_engine_transitions [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_animation_engine_transitions::run() {
    ash_log_info "transitions: run (placeholder — engine not yet wired)" 2>/dev/null || echo "transitions: run placeholder"
    return 0
}
