#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🎨 ASH ANIMATION ENGINE — Animation utilities for the ASH ecosystem             ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# A sourced library must not mutate the caller's shell options.
# `set -e` inside a sourced file silently aborts the *parent* script
# on the next non-zero test, which is a nightmare to debug.
# ── Double-source guard ────────────────────────────────────────────────────
# Every declaration below is readonly, so a second `source` of this file
# fails with "readonly variable" before any function is defined. Returning
# early makes the library safe to load from anywhere.
[[ -n "${_ASH_ANIMATION_LOADED:-}" ]] && return 0
readonly _ASH_ANIMATION_LOADED=1

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

readonly ASH_ANIMATION_VERSION="5.0.0"

# Animation utilities
ash_animation_fade_in() {
    local duration="${1:-0.5}"
    local delay="${2:-0}"
    local element="${3:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.opacity = '0';"
        echo "setTimeout(() => {"
        echo "  element.style.opacity = '1';"
        echo "  element.style.transition = 'opacity ${duration}s';"
        echo "}, ${delay});"
    else
        echo "document.body.style.opacity = '0';"
        echo "setTimeout(() => {"
        echo "  document.body.style.opacity = '1';"
        echo "  document.body.style.transition = 'opacity ${duration}s';"
        echo "}, ${delay});"
    fi
}

ash_animation_fade_out() {
    local duration="${1:-0.5}"
    local delay="${2:-0}"
    local element="${3:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.transition = 'opacity ${duration}s';"
        echo "setTimeout(() => {"
        echo "  element.style.opacity = '0';"
        echo "}, ${delay});"
    else
        echo "document.body.style.transition = 'opacity ${duration}s';"
        echo "setTimeout(() => {"
        echo "  document.body.style.opacity = '0';"
        echo "}, ${delay});"
    fi
}

ash_animation_slide_in() {
    local direction="${1:-right}"
    local duration="${2:-0.5}"
    local delay="${3:-0}"
    local element="${4:-}"

    local transform=""
    case "${direction}" in
        left) transform="translateX(-100%)" ;;
        right) transform="translateX(100%)" ;;
        up) transform="translateY(100%)" ;;
        down) transform="translateY(-100%)" ;;
        *) transform="translateX(100%)" ;;
    esac

    if [[ -n "${element}" ]]; then
        echo "element.style.opacity = '0';"
        echo "element.style.transform = '${transform}';"
        echo "setTimeout(() => {"
        echo "  element.style.transition = 'all ${duration}s ease';"
        echo "  element.style.opacity = '1';"
        echo "  element.style.transform = 'translateX(0)';"
        echo "}, ${delay});"
    else
        echo "document.body.style.transition = 'all ${duration}s ease';"
        echo "setTimeout(() => {"
        echo "  document.body.style.opacity = '1';"
        echo "  document.body.style.transform = 'translateX(0)';"
        echo "}, ${delay});"
    fi
}

ash_animation_bounce() {
    local duration="${1:-1}"
    local times="${2:-2}"
    local distance="${3:-20}"
    local element="${4:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'bounce ${duration}s ${times} ease infinite';"
        echo "@keyframes bounce {"
        echo "  0%, 100% { transform: translateY(0); }"
        echo "  50% { transform: translateY(-${distance}px); }"
        echo "};"
    else
        echo "document.body.style.animation = 'bounce ${duration}s ${times} ease infinite';"
        echo "@keyframes bounce {"
        echo "  0%, 100% { transform: translateY(0); }"
        echo "  50% { transform: translateY(-${distance}px); }"
        echo "};"
    fi
}

ash_animation_pulse() {
    local duration="${1:-1}"
    local times="${2:-infinite}"
    local scale="${3:-1.1}"
    local element="${4:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'pulse ${duration}s ${times} ease infinite';"
        echo "@keyframes pulse {"
        echo "  0%, 100% { transform: scale(1); }"
        echo "  50% { transform: scale(${scale}); }"
        echo "};"
    else
        echo "document.body.style.animation = 'pulse ${duration}s ${times} ease infinite';"
        echo "@keyframes pulse {"
        echo "  0%, 100% { transform: scale(1); }"
        echo "  50% { transform: scale(${scale}); }"
        echo "};"
    fi
}

ash_animation_shake() {
    local duration="${1:-0.5}"
    local distance="${2:-10}"
    local element="${3:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'shake ${duration}s ease infinite';"
        echo "@keyframes shake {"
        echo "  0%, 100% { transform: translateX(0); }"
        echo "  25% { transform: translateX(-${distance}px); }"
        echo "  50% { transform: translateX(${distance}px); }"
        echo "  75% { transform: translateX(-${distance}px); }"
        echo "};"
    else
        echo "document.body.style.animation = 'shake ${duration}s ease infinite';"
        echo "@keyframes shake {"
        echo "  0%, 100% { transform: translateX(0); }"
        echo "  25% { transform: translateX(-${distance}px); }"
        echo "  50% { transform: translateX(${distance}px); }"
        echo "  75% { transform: translateX(-${distance}px); }"
        echo "};"
    fi
}

ash_animation_flip() {
    local duration="${1:-0.5}"
    local element="${2:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'flip ${duration}s ease';"
        echo "@keyframes flip {"
        echo "  0% { transform: rotateY(0); }"
        echo "  100% { transform: rotateY(180deg); }"
        echo "};"
    else
        echo "document.body.style.animation = 'flip ${duration}s ease';"
        echo "@keyframes flip {"
        echo "  0% { transform: rotateY(0); }"
        echo "  100% { transform: rotateY(180deg); }"
        echo "};"
    fi
}

ash_animation_zoom() {
    local duration="${1:-0.5}"
    local scale="${2:-2}"
    local element="${3:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'zoom ${duration}s ease';"
        echo "@keyframes zoom {"
        echo "  0% { transform: scale(0); }"
        echo "  100% { transform: scale(${scale}); }"
        echo "};"
    else
        echo "document.body.style.animation = 'zoom ${duration}s ease';"
        echo "@keyframes zoom {"
        echo "  0% { transform: scale(0); }"
        echo "  100% { transform: scale(${scale}); }"
        echo "};"
    fi
}

ash_animation_custom() {
    local name="${1:-custom}"
    local keyframes="${2}"
    local duration="${3:-1}"
    local iteration_count="${4:-1}"
    local element="${5:-}"

    if [[ -n "${element}" ]]; then
        echo "element.style.animation = \"${name} ${duration}s ${iteration_count} ease;\""
        echo "@keyframes ${name} {"
        echo "${keyframes}"
        echo "};"
    else
        echo "document.body.style.animation = \"${name} ${duration}s ${iteration_count} ease;\""
        echo "@keyframes ${name} {"
        echo "${keyframes}"
        echo "};"
    fi
}

ash_animation_remove() {
    local element="${1:-}"
    if [[ -n "${element}" ]]; then
        echo "element.style.animation = 'none';"
    else
        echo "document.body.style.animation = 'none';"
    fi
}

ash_animation_pause() {
    local element="${1:-}"
    if [[ -n "${element}" ]]; then
        echo "element.style.animationPlayState = 'paused';"
    else
        echo "document.body.style.animationPlayState = 'paused';"
    fi
}

ash_animation_resume() {
    local element="${1:-}"
    if [[ -n "${element}" ]]; then
        echo "element.style.animationPlayState = 'running';"
    else
        echo "document.body.style.animationPlayState = 'running';"
    fi
}

# Animation presets
ash_animation_preset() {
    local preset="${1}"
    case "${preset}" in
        typewriter)
            echo "document.body.style.animation = 'typewriter 2s steps(40) forwards';"
            echo "@keyframes typewriter {"
            echo "  to { width: 100%; }"
            echo "};"
            ;;
        glitch)
            echo "document.body.style.animation = 'glitch 0.5s linear forwards';"
            echo "@keyframes glitch {"
            echo "  0% { transform: translate(0); }"
            echo "  25% { transform: translate(-10px, 10px); }"
            echo "  50% { transform: translate(10px, -10px); }"
            echo "  75% { transform: translate(-10px, 5px); }"
            echo "  100% { transform: translate(0); }"
            echo "};"
            ;;
        float)
            echo "document.body.style.animation = 'float 3s ease-in-out infinite';"
            echo "@keyframes float {"
            echo "  0%, 100% { transform: translateY(0); }"
            echo "  50% { transform: translateY(-20px); }"
            echo "};"
            ;;
        glow)
            echo "document.body.style.animation = 'glow 2s ease-in-out infinite alternate';"
            echo "@keyframes glow {"
            echo "  0%, 100% { box-shadow: 0 0 10px ${COLOR_ASH_PRIMARY}, 0 0 20px ${COLOR_ASH_PRIMARY}, 0 0 30px ${COLOR_ASH_PRIMARY}; }"
            echo "  50% { box-shadow: 0 0 5px ${COLOR_ASH_SECONDARY}, 0 0 10px ${COLOR_ASH_SECONDARY}, 0 0 15px ${COLOR_ASH_SECONDARY}; }"
            echo "};"
            ;;
        *)
            echo "Unknown animation preset: ${preset}"
            ;;
    esac
}

# Animation timeline utilities
ash_animation_sequence() {
    local animations="${1}"
    echo "async function playAnimationSequence() {"
    echo "  const animations = [${animations}];"
    echo "  for (const animation of animations) {"
    echo "    await new Promise(resolve => setTimeout(resolve, animation.delay));"
    echo "    animation.execute();"
    echo "  }"
    echo "}"
}

# Animation controller utilities
ash_animation_controller() {
    echo "class AnimationController {"
    echo "  constructor() {"
    echo "    this.animations = new Map();"
    echo "  }"
    echo "  addAnimation(id, animation) {"
    echo "    this.animations.set(id, animation);"
    echo "  }"
    echo "  playAnimation(id) {"
    echo "    const animation = this.animations.get(id);"
    echo "    if (animation) {"
    echo "      animation.execute();"
    echo "    }"
    echo "  }"
    echo "  pauseAnimation(id) {"
    echo "    const animation = this.animations.get(id);"
    echo "    if (animation) {"
    echo "      animation.pause();"
    echo "    }"
    echo "  }"
    echo "  resumeAnimation(id) {"
    echo "    const animation = this.animations.get(id);"
    echo "    if (animation) {"
    echo "      animation.resume();"
    echo "    }"
    echo "  }"
    echo "  stopAnimation(id) {"
    echo "    const animation = this.animations.get(id);"
    echo "    if (animation) {"
    echo "      animation.stop();"
    echo "    }"
    echo "  }"
    echo "}"
}

# Main entry point for animation library
ash_animation_main() {
    case "${1:-}" in
        init)
            echo "ASH Animation Engine v${ASH_ANIMATION_VERSION} initialized"
            ;;
        status)
            echo "ASH Animation Engine v${ASH_ANIMATION_VERSION}"
            echo "Animation functions: fade_in, fade_out, slide_in, bounce, pulse, shake, flip, zoom, custom, remove, pause, resume"
            echo "Presets: typewriter, glitch, float, glow"
            ;;
        *)
            echo "Usage: ash_animation <command>"
            echo "Commands: init, status"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_animation_main "$@"
fi
