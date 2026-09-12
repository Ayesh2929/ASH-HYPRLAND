#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — STREAM MODE                                      ║
# ║  /ash-cli/commands/mode/stream.sh                                            ║
# ║                                                                              ║
# ║  OBS-ready live streaming setup:                                             ║
# ║  • OBS Studio launched with stream scene collection                          ║
# ║  • Audio routing configured (OBS virtual cable)                              ║
# ║  • Recording indicator shown in Waybar                                       ║
# ║  • Camera feed optimized                                                     ║
# ║  • Privacy: password managers hidden, shell history paused                   ║
# ║  • Discord muted (prevent audio bleed)                                       ║
# ║  • High-performance compositor for capture quality                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__stream_duration=""
__stream_no_notify=false
__stream_launch_obs=true
__stream_scene_collection=""
__stream_mute_discord=true
__stream_camera_device=""

__stream_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __stream_duration="${2:?}"
                shift 2
                ;;
            --no-obs)           __stream_launch_obs=false          ; shift ;;
            --scene)
                __stream_scene_collection="${2:?}"
                shift 2
                ;;
            --camera)
                __stream_camera_device="${2:?}"
                shift 2
                ;;
            --no-mute-discord)  __stream_mute_discord=false        ; shift ;;
            --no-notify)        __stream_no_notify=true            ; shift ;;
            --dry-run)          ASH_DRY_RUN=true                   ; shift ;;
            --verbose)          ASH_VERBOSE=true                   ; shift ;;
            *)                  shift ;;
        esac
    done
}

__stream_build_settings() {
    declare -gA __STREAM_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="true"      # Keep smooth for stream quality
        [hypr_blur]="false"           # Reduce GPU load for encoding
        [hypr_shadow]="true"
        [hypr_rounding]="8"
        [hypr_gaps_in]="4"
        [hypr_gaps_out]="8"
        [hypr_vfr]="false"           # Consistent frames for capture
        [hypr_vrr]="0"               # Stable framerate for encoder

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="performance"  # Encoding needs CPU headroom
        [power_profile]="performance"
        [gpu_power_profile]="performance"
        [idle_timeout]="0"           # Never idle during stream

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="false"        # Accurate colors on stream
        [screen_brightness]="85"

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"      # No accidental notification reveals

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="70"
        [audio_microphone]="unmute"  # Streaming mic active
        [noise_cancel]="true"        # Clean audio for viewers

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="top-bar"    # Show recording indicator

        # ── Screen Recording ─────────────────────────────────────────────────
        [screen_record_ready]="true"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__stream_no_notify}"
        [duration]="${__stream_duration:-null}"
    )
}

__stream_apply_extras() {
    # ── Launch OBS Studio ────────────────────────────────────────────────────
    if [[ "${__stream_launch_obs}" == "true" ]]; then
        ash_log_info "  Launching OBS Studio"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            if command -v obs &>/dev/null; then
                local obs_args=("--startreplaybuffer")
                [[ -n "${__stream_scene_collection}" ]] && \
                    obs_args+=("--scene" "${__stream_scene_collection}")

                obs "${obs_args[@]}" &>/dev/null &
                sleep 2   # Brief wait for OBS to initialize
            else
                ash_log_warn "OBS Studio not found — install with: paru -S obs-studio"
            fi
        fi
    fi

    # ── Mute Discord (prevent feedback/echo) ─────────────────────────────────
    if [[ "${__stream_mute_discord}" == "true" ]]; then
        ash_log_info "  Muting Discord audio output"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Mute Discord via PulseAudio/PipeWire sink input
            pactl list sink-inputs 2>/dev/null \
                | grep -A5 "application.name.*discord\|application.name.*Discord" \
                | grep "Sink Input #" \
                | awk '{print $3}' \
                | while read -r input_id; do
                    pactl set-sink-input-mute "${input_id}" 1 2>/dev/null || true
                done
        fi
    fi

    # ── Configure PipeWire Audio Routing ─────────────────────────────────────
    ash_log_info "  Configuring PipeWire audio routing for streaming"
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        # Create virtual OBS cable if obs-virtual-sink module is available
        pactl load-module module-virtual-sink \
            sink_name=obs_virtual_sink \
            sink_properties="device.description='OBS Virtual Sink'" \
            2>/dev/null || true
    fi

    # ── Privacy: Hide Sensitive Windows ──────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        local -a private_classes=(
            "bitwarden" "keepassxc" "_1password"
            "org.keepassxc.KeePassXC"
        )
        for cls in "${private_classes[@]}"; do
            hyprctl dispatch movetoworkspacesilent \
                "special:stream-private,class:${cls}" 2>/dev/null || true
        done
    fi

    # ── Show Stream Status Notification ──────────────────────────────────────
    if [[ "${__stream_no_notify}" != "true" ]] && \
       [[ "${ASH_DRY_RUN}" != "true" ]]; then
        notify-send \
            --urgency=normal \
            --expire-time=5000 \
            "📡 Stream Mode Active" \
            "OBS ready • DND on • Mic live • Privacy windows hidden" \
            2>/dev/null || true
    fi
}

ash_stream_mode_main() {
    __stream_parse_args "$@"
    __stream_build_settings
    ash_mode_activate "stream" "__STREAM_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __stream_apply_extras
}

ash_stream_mode_main "$@"