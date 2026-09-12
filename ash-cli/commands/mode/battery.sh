#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — BATTERY MODE                                     ║
# ║  /ash-cli/commands/mode/battery.sh                                           ║
# ║                                                                              ║
# ║  Aggressive power conservation:                                              ║
# ║  • CPU governor → powersave                                                  ║
# ║  • GPU minimum power state                                                   ║
# ║  • Display brightness reduced                                                ║
# ║  • Bluetooth disabled                                                        ║
# ║  • WiFi power management enabled                                             ║
# ║  • Background services suspended                                             ║
# ║  • Animations disabled for GPU savings                                       ║
# ║  • Auto-activates on low battery threshold                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__battery_duration=""
__battery_no_notify=false
__battery_threshold=20       # Auto-activate below this %
__battery_brightness=30      # Target brightness %
__battery_disable_bt=true    # Disable Bluetooth
__battery_wifi_powersave=true

__battery_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __battery_duration="${2:?}"
                shift 2
                ;;
            --threshold)
                __battery_threshold="${2:?--threshold requires a value}"
                shift 2
                ;;
            --brightness)
                __battery_brightness="${2:?--brightness requires a value}"
                shift 2
                ;;
            --keep-bluetooth)   __battery_disable_bt=false     ; shift ;;
            --no-wifi-ps)       __battery_wifi_powersave=false ; shift ;;
            --no-notify)        __battery_no_notify=true       ; shift ;;
            --dry-run)          ASH_DRY_RUN=true               ; shift ;;
            --verbose)          ASH_VERBOSE=true               ; shift ;;
            *)                  shift ;;
        esac
    done
}

__battery_build_settings() {
    declare -gA __BATTERY_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="false"     # No GPU overhead
        [hypr_blur]="false"           # Major GPU power drain eliminated
        [hypr_shadow]="false"
        [hypr_rounding]="4"
        [hypr_gaps_in]="2"
        [hypr_gaps_out]="4"
        [hypr_vfr]="true"            # Crucial: reduces GPU active time
        [hypr_vrr]="0"

        # ── CPU & Power ─────────────────────────────────────────────────────
        [cpu_governor]="powersave"   # Minimum CPU frequency
        [power_profile]="power-saver" # Aggressive power saving
        [gpu_power_profile]="powersave"

        # ── Display ─────────────────────────────────────────────────────────
        [screen_brightness]="${__battery_brightness}"
        [night_light]="true"         # Warm tone reduces OLED power
        [color_temperature]="4000"
        [idle_timeout]="60"          # Quick dim: 1 minute
        [idle_lock_timeout]="120"    # Quick lock: 2 minutes
        [dpms_timeout]="60"

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="false"     # Still need battery alerts
        [notification_timeout]="4000"

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="40"
        [noise_cancel]="false"       # NC chip draws power

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"      # Show battery indicator
        [waybar_layout]="minimal-bar"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__battery_no_notify}"
        [duration]="${__battery_duration:-null}"
    )
}

__battery_apply_extras() {
    # ── Bluetooth Power Control ───────────────────────────────────────────────
    if [[ "${__battery_disable_bt}" == "true" ]]; then
        ash_log_info "  Disabling Bluetooth"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            rfkill block bluetooth 2>/dev/null || \
                bluetoothctl power off 2>/dev/null || true
            echo "bluetooth_was_on" > "${ASH_RUNTIME_DIR}/battery-bt.state" \
                2>/dev/null || true
        fi
    fi

    # ── WiFi Power Management ─────────────────────────────────────────────────
    if [[ "${__battery_wifi_powersave}" == "true" ]]; then
        ash_log_info "  Enabling WiFi power management"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            local iface
            iface=$(ip link | awk '/^[0-9]+: w/{print $2}' | tr -d ':' | head -1)
            if [[ -n "${iface}" ]]; then
                sudo iw dev "${iface}" set power_save on 2>/dev/null || true
            fi
        fi
    fi

    # ── Suspend Background Services ───────────────────────────────────────────
    ash_log_info "  Suspending non-essential services"
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        local -a suspend_services=(
            "ash-analytics"
            "ash-cloud-sync"
            "ash-github-notif"
            "ash-discord-rpc"
            "ash-spotify-sync"
        )
        for svc in "${suspend_services[@]}"; do
            systemctl --user stop "${svc}.service" 2>/dev/null || true
        done
    fi

    # ── USB Power Autosuspend ────────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        for dev in /sys/bus/usb/devices/*/power/autosuspend; do
            [[ -w "${dev}" ]] && echo "2" > "${dev}" 2>/dev/null || true
        done
    fi
}

ash_battery_mode_main() {
    __battery_parse_args "$@"
    __battery_build_settings
    ash_mode_activate "battery" "__BATTERY_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __battery_apply_extras
}

ash_battery_mode_main "$@"