#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power lock                                               ║
# ║  Screen lock: hyprlock → swaylock → i3lock → xscreensaver fallback chain        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_LOCK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_LOCK_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_lock_hyprlock() {
    # hyprlock looks in ~/.config/hypr by default, but ASH ships its config in
    # ~/.config/hyprlock — use whichever exists and pass it explicitly.
    local cfg_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local hyprlock_cfg="" candidate
    for candidate in "${cfg_dir}/hypr/hyprlock.conf" "${cfg_dir}/hyprlock/hyprlock.conf"; do
        [[ -f "$candidate" ]] && { hyprlock_cfg="$candidate"; break; }
    done

    if [[ -n "$hyprlock_cfg" ]]; then
        hyprlock --config "$hyprlock_cfg" 2>/dev/null || hyprlock 2>/dev/null
    else
        # Basic invocation without config
        hyprlock 2>/dev/null
    fi
}

_lock_swaylock() {
    local swaylock_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/swaylock/config"
    local -a args=( "swaylock" )

    if [[ -f "$swaylock_cfg" ]]; then
        args+=( "--config" "$swaylock_cfg" )
    else
        # Sensible defaults
        args+=(
            "--clock"
            "--indicator"
            "--color" "1e1e2e"
            "--ring-color" "cba6f7"
            "--key-hl-color" "a6e3a1"
            "--text-color" "cdd6f4"
            "--inside-color" "1e1e2e"
            "--separator-color" "313244"
            "--fade-in" "0.2"
        )
    fi

    "${args[@]}" 2>/dev/null
}

_lock_i3lock() {
    local -a args=( "i3lock" )

    # Generate a blurred screenshot for lock background
    local lock_img="/tmp/ash-lock-bg.png"

    if command -v grim &>/dev/null && command -v magick &>/dev/null; then
        grim "$lock_img" 2>/dev/null && \
            magick "$lock_img" -blur 0x10 "$lock_img" 2>/dev/null
        args+=( "-i" "$lock_img" )
    else
        args+=( "-c" "1e1e2e" )
    fi

    args+=( "--nofork" )
    "${args[@]}" 2>/dev/null
    rm -f "$lock_img" 2>/dev/null || true
}

ash_power_lock() {
    local locker="auto"
    local immediate=0

    for arg in "${@:-}"; do
        case "$arg" in
            --hyprlock)   locker="hyprlock"   ;;
            --swaylock)   locker="swaylock"   ;;
            --i3lock)     locker="i3lock"     ;;
            --now)        immediate=1         ;;
        esac
    done

    pwr_section "🔒" "Lock Screen" "$(_pwblue)"

    # Auto-detect locker
    if [[ "$locker" == "auto" ]]; then
        if command -v hyprlock &>/dev/null && \
           [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            locker="hyprlock"
        elif command -v swaylock &>/dev/null; then
            locker="swaylock"
        elif command -v i3lock &>/dev/null; then
            locker="i3lock"
        elif command -v xscreensaver-command &>/dev/null; then
            locker="xscreensaver"
        else
            pwr_fail "No screen locker found"
            pwr_info "Install: paru -S hyprlock"
            return 1
        fi
    fi

    pwr_kv "Locker" "$locker"
    pwr_log "lock" "initiated"
    pwr_run_hook "on-lock"

    pwr_step "Locking screen with ${locker}..."

    local exit_code=0
    case "$locker" in
        hyprlock)    _lock_hyprlock    || exit_code=$? ;;
        swaylock)    _lock_swaylock    || exit_code=$? ;;
        i3lock)      _lock_i3lock      || exit_code=$? ;;
        xscreensaver) xscreensaver-command -lock 2>/dev/null || exit_code=$? ;;
    esac

    if [[ $exit_code -eq 0 ]]; then
        pwr_log "lock" "ok"
        pwr_run_hook "on-unlock"
    else
        pwr_log "lock" "failed"
        pwr_fail "Lock failed (exit: ${exit_code})"
        return 1
    fi

    printf '\n'
}
