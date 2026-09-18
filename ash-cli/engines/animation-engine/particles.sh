#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ash-cli/engines/animation-engine/particles.sh                              ║
# ║  Library: sourced, never executed directly. Provides particles helpers.      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_ANIMATION_ENGINE_PARTICLES_LOADED:-}" ]] && return 0
readonly _ASH_ANIMATION_ENGINE_PARTICLES_LOADED=1

# ── particles — primary entry ───────────────────────────────────────────────
ash_animation_engine_particles() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ash_animation_engine_particles::help ;;
        *) ash_log_warn "particles: unknown subcommand '$sub' — see help" 2>/dev/null || echo "particles: unknown subcommand '$sub'" >&2; return 2 ;;
    esac
}

ash_animation_engine_particles::help() {
    cat <<'EOF'
ash-cli/engines/animation-engine/particles.sh — particles engine helper

Usage: ash_animation_engine_particles [help]

This engine is part of ASH's modular system. It is sourced as a library;
its functions are called by the ash CLI dispatchers.

EOF
}

# Placeholder implementations — preserve API surface so callers do not break.
ash_animation_engine_particles::run() {
    ash_log_info "particles: run (placeholder — engine not yet wired)" 2>/dev/null || echo "particles: run placeholder"
    return 0
}
