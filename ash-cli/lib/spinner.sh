#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🎡 ASH SPINNER ENGINE — Spinner utilities for the ASH ecosystem                ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# A sourced library must not mutate the caller's shell options.
# `set -e` inside a sourced file silently aborts the *parent* script
# on the next non-zero test, which is a nightmare to debug.
# ── Double-source guard ────────────────────────────────────────────────────
# Every declaration below is readonly, so a second `source` of this file
# fails with "readonly variable" before any function is defined. Returning
# early makes the library safe to load from anywhere.
[[ -n "${_ASH_SPINNER_LOADED:-}" ]] && return 0
readonly _ASH_SPINNER_LOADED=1

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

readonly ASH_SPINNER_VERSION="5.0.0"

# Spinner utilities
ash_spinner() {
    local style="${1:-dots}"
    local interval="${2:-0.1}"
    local message="${3:-Loading...}"
    local max_spins="${4:-100}"
    local char_set=""

    case "${style}" in
        dots)
            char_set="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
        line)
            char_set="|/-\\"
            ;;
        circle)
            char_set="◐◑◒◓◔◕◖◗◘◙"
            ;;
        bounce)
            char_set="⚫⚪⚫⚪⚫⚪⚫⚪⚫⚪"
            ;;
        star)
            char_set="✩✫✩✫✩✫✩✫✩✫✩✫"
            ;;
        *)
            char_set="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
    esac

    local spin_count=0
    local spin_length=${#char_set}

    echo -n "${message} "
    while (( spin_count < max_spins )); do
        local char="${char_set:$(( spin_count % spin_length )):1}"
        echo -n "\r${char}"
        spin_count=$(( spin_count + 1 ))
        sleep "${interval}"
    done

    echo -n "\r✓ Done\n"
}

ash_spinner_async() {
    local style="${1:-dots}"
    local interval="${2:-0.1}"
    local message="${3:-Loading...}"
    local max_spins="${4:-100}"
    local char_set=""
    local spin_count=0
    local spin_length=0

    case "${style}" in
        dots)
            char_set="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
        line)
            char_set="|/-\\"
            ;;
        circle)
            char_set="◐◑◒◓◔◕◖◗◘◙"
            ;;
        bounce)
            char_set="⚫⚪⚫⚪⚫⚪⚫⚪⚫⚪"
            ;;
        star)
            char_set="✩✫✩✫✩✫✩✫✩✫✩✫"
            ;;
        *)
            char_set="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
    esac

    spin_length=${#char_set}

    local spinner_pid
    (
        while (( spin_count < max_spins )); do
            local char="${char_set:$(( spin_count % spin_length )):1}"
            echo -n "\r${message} ${char}"
            spin_count=$(( spin_count + 1 ))
            sleep "${interval}"
        done
        echo -n "\r${message} ✓ Done\n"
    ) &
    spinner_pid=$!

    # Wait for spinner to finish
    wait "${spinner_pid}"
}

ash_spinner_wait() {
    local duration="${1:-5}"
    local message="${2:-Waiting...}"
    local style="${3:-dots}"

    local start_time="$(date +%s)"
    local end_time=$(( start_time + duration ))
    local spin_count=0
    local style_chars=""

    case "${style}" in
        dots)
            style_chars="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
        line)
            style_chars="|/-\\"
            ;;
        circle)
            style_chars="◐◑◒◓◔◕◖◗◘◙"
            ;;
        bounce)
            style_chars="⚫⚪⚫⚪⚫⚪⚫⚪⚫⚪"
            ;;
        star)
            style_chars="✩✫✩✫✩✫✩✫✩✫✩✫"
            ;;
        *)
            style_chars="⠋⠋⠊⠊⠡⠡⠇⠇⠋⠋"
            ;;
    esac

    local style_length=${#style_chars}

    echo -n "${message} "
    while (( $(date +%s) < end_time )); do
        local char="${style_chars:$(( spin_count % style_length )):1}"
        echo -n "\r${char}"
        spin_count=$(( spin_count + 1 ))
        sleep 0.1
    done

    echo -n "\r✓ Done\n"
}

# Main entry point for spinner library
ash_spinner_main() {
    case "${1:-}" in
        init)
            echo "ASH Spinner Engine v${ASH_SPINNER_VERSION} initialized"
            ;;
        status)
            echo "ASH Spinner Engine v${ASH_SPINNER_VERSION}"
            echo "Functions: spinner, spinner_async, spinner_wait"
            ;;
        *)
            echo "Usage: ash_spinner <command>"
            echo "Commands: init, status"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_spinner_main "$@"
fi
