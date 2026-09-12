#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — GAME MODE                                        ║
# ║  /ash-cli/commands/mode/game.sh                                              ║
# ║                                                                              ║
# ║  Maximum performance gaming mode:                                            ║
# ║  • CPU governor → performance                                                ║
# ║  • GPU profile → high performance                                            ║
# ║  • All compositor effects disabled                                           ║
# ║  • Notifications paused                                                      ║
# ║  • GameMode daemon activated                                                 ║
# ║  • MangoHud overlay ready                                                    ║
# ║  • Network QoS prioritized for gaming                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode game [options]
#
# OPTIONS:
#   --duration <time>     Auto-revert after time (e.g. 3h)
#   --no-notify           Skip desktop notification
#   --mangohud            Enable MangoHud overlay
#   --no-animation        Skip transition animation
#   --gpu-overclock       Apply GPU overclock profile (requires root)
#   --low-latency         Apply additional kernel latency tweaks
#   --dry-run             Preview without applying
#   --verbose             Show detailed output
#
# EXAMPLES:
#   ash mode game
#   ash mode game --duration 3h
#   ash mode game --mangohud --low-latency

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────

__game_duration=""
__game_no_notify=false
__game_mangohud=false
__game_gpu_overclock=false
__game_low_latency=false

__game_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                [[ -n "${2:-}" ]] || ash_die "--duration requires a value (e.g. 3h)"
                __game_duration="${2}"
                shift 2
                ;;
            --no-notify)        __game_no_notify=true   ; shift ;;
            --mangohud)         __game_mangohud=true    ; shift ;;
            --gpu-overclock)    __game_gpu_overclock=true ; shift ;;
            --low-latency)      __game_low_latency=true ; shift ;;
            --dry-run)          ASH_DRY_RUN=true        ; shift ;;
            --verbose)          ASH_VERBOSE=true        ; shift ;;
            --no-animation)     ASH_NO_ANIMATION=true   ; shift ;;
            --help|-h)
                ash_game_help
                return 0
                ;;
            *)
                ash_log_warn "Unknown option for game mode: '${1}'"
                shift
                ;;
        esac
    done
}

ash_game_help() {
    printf '\n'
    printf "${MODE_ACCENT_COLORS[game]}${MODE_COLOR_BOLD}"
    printf "  %s GAME MODE — Maximum Performance Gaming\n" "${MODE_ICONS[game]}"
    printf "${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n\n" \
        "${MODE_DESCRIPTIONS[game]}"
    printf "  ${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}WHAT IT DOES${MODE_COLOR_RESET}\n"
    local -a actions=(
        "CPU governor       → performance (max clock speed)"
        "GPU power profile  → high (maximum throughput)"
        "Compositor effects → disabled (0ms render overhead)"
        "Blur + shadows     → disabled (GPU free for game)"
        "Animations         → disabled (no frame budget waste)"
        "Do Not Disturb     → enabled (no interruptions)"
        "Waybar             → minimal gaming layout"
        "GameMode daemon    → activated (process priority)"
        "VRR/FreeSync       → enabled (smooth frame pacing)"
        "CPU idle           → disabled (no latency spikes)"
        "Network QoS        → gaming priority"
    )
    for action in "${actions[@]}"; do
        printf "  ${MODE_ACCENT_COLORS[game]}  ●${MODE_COLOR_RESET} "
        printf "${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n" "${action}"
    done
    printf "\n"
    printf "  ${COLOR_ASH_SECONDARY}${MODE_COLOR_BOLD}OPTIONS${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_INFO}--duration <time>${MODE_COLOR_RESET}    "
    printf "${COLOR_ASH_MUTED}Auto-revert (30m, 2h, 1d)${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_INFO}--mangohud${MODE_COLOR_RESET}           "
    printf "${COLOR_ASH_MUTED}Enable MangoHud overlay${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_INFO}--low-latency${MODE_COLOR_RESET}        "
    printf "${COLOR_ASH_MUTED}Kernel-level latency tweaks${MODE_COLOR_RESET}\n"
    printf "  ${COLOR_ASH_INFO}--gpu-overclock${MODE_COLOR_RESET}      "
    printf "${COLOR_ASH_MUTED}GPU overclock profile (needs root)${MODE_COLOR_RESET}\n"
    printf "\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — MODE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Build the settings array for this mode.
# Keys map directly to ash_mode_execute_action() cases in mode.sh
__game_build_settings() {
    declare -gA __GAME_SETTINGS=(
        # ── Hyprland Compositor ─────────────────────────────────────────────
        [hypr_animations]="false"       # Kill all animations
        [hypr_blur]="false"             # No blur (GPU free for game)
        [hypr_shadow]="false"           # No shadows
        [hypr_rounding]="0"             # No rounded corners (minor perf gain)
        [hypr_gaps_in]="0"             # Maximize usable screen space
        [hypr_gaps_out]="0"            # Maximize usable screen space
        [hypr_border_size]="1"         # Minimal border
        [hypr_vfr]="false"             # Disable VFR (consistent frame delivery)
        [hypr_vrr]="1"                 # Enable VRR/FreeSync/G-Sync

        # ── CPU & Power ─────────────────────────────────────────────────────
        [cpu_governor]="performance"    # Max clock speed, no throttling
        [power_profile]="performance"   # power-profiles-daemon
        [gpu_power_profile]="performance" # GPU maximum power state

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="false"          # Full color temperature
        [idle_timeout]="0"             # Never dim/sleep during gaming

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"        # No interruptions
        [notification_timeout]="2000"  # Very short timeout if any sneak through

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="80"            # Comfortable gaming volume
        [noise_cancel]="false"         # Disable to reduce CPU overhead

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_layout]="gaming-bar"   # Minimal gaming-specific layout

        # ── System Processes ─────────────────────────────────────────────────
        [gamemode_daemon]="true"       # GameMode: SCHED_BATCH → SCHED_FIFO

        # ── Clipboard ────────────────────────────────────────────────────────
        [clipboard_history]="true"     # Keep enabled for game captures

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__game_no_notify}"
        [duration]="${__game_duration:-null}"
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — ADDITIONAL GAME-SPECIFIC ACTIONS
# ─────────────────────────────────────────────────────────────────────────────

# Apply extra game-mode-specific tweaks beyond the standard action framework
__game_apply_extras() {
    # ── MangoHud Overlay ────────────────────────────────────────────────────
    if [[ "${__game_mangohud}" == "true" ]]; then
        ash_log_info "  Enabling MangoHud overlay configuration"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Set MangoHud environment variable for launched games
            local mangohud_config="${XDG_CONFIG_HOME:-${HOME}/.config}/MangoHud/MangoHud.conf"
            if [[ -f "${mangohud_config}" ]]; then
                export MANGOHUD=1
                export MANGOHUD_CONFIG="${mangohud_config}"
            fi
        fi
    fi

    # ── Low Latency Kernel Tweaks ────────────────────────────────────────────
    if [[ "${__game_low_latency}" == "true" ]]; then
        ash_log_info "  Applying low-latency kernel tweaks"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Disable CPU idle states for minimum interrupt latency
            if [[ -w /dev/cpu_dma_latency ]]; then
                # Write 0 = no idle states (requires root or CAP_SYS_NICE)
                echo 0 > /dev/cpu_dma_latency 2>/dev/null || \
                    ash_log_debug "cpu_dma_latency requires elevated privileges"
            fi

            # Increase scheduler slice for real-time responsiveness
            sudo sysctl -w kernel.sched_min_granularity_ns=500000 \
                2>/dev/null || ash_log_debug "sysctl requires sudo"
            sudo sysctl -w kernel.sched_wakeup_granularity_ns=250000 \
                2>/dev/null || true
        fi
    fi

    # ── GPU Overclock Profile ────────────────────────────────────────────────
    if [[ "${__game_gpu_overclock}" == "true" ]]; then
        local gpu_vendor
        gpu_vendor="$(ash_mode_detect_gpu)"
        ash_log_info "  Applying GPU overclock profile (${gpu_vendor})"

        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            case "${gpu_vendor}" in
                nvidia)
                    # NVIDIA overclock via nvidia-settings
                    if command -v nvidia-settings &>/dev/null; then
                        nvidia-settings --assign \
                            "[gpu:0]/GPUPowerMizerMode=1" \
                            2>/dev/null || true
                    fi
                    ;;
                amd)
                    # AMD overclock via CoreCtrl/MangoHud profiles
                    ash_log_debug "AMD overclock requires CoreCtrl"
                    ;;
                *)
                    ash_log_warn "GPU overclock not supported for: ${gpu_vendor}"
                    ;;
            esac
        fi
    fi

    # ── Window Rule: Force Float for Game Launchers ──────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        hyprctl keyword windowrulev2 "float,class:steam" 2>/dev/null || true
        hyprctl keyword windowrulev2 \
            "fullscreen,class:(steam_app_.*)" 2>/dev/null || true
    fi

    # ── Disable Compositor for Native Games ─────────────────────────────────
    # Note: Hyprland always uses composition but we minimize its impact above
    ash_log_debug "Compositor overhead minimized for gaming"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

ash_game_mode_main() {
    # Parse this mode's specific arguments
    __game_parse_args "$@"

    # Build the settings table
    __game_build_settings

    # Activate via the central framework in mode.sh
    ash_mode_activate "game" "__GAME_SETTINGS"

    # Apply game-specific extras not covered by the generic framework
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        __game_apply_extras
    fi
}

ash_game_mode_main "$@"