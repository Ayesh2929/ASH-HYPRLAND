#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — PRESENT MODE                                     ║
# ║  /ash-cli/commands/mode/present.sh                                           ║
# ║                                                                              ║
# ║  Professional presentation environment:                                      ║
# ║  • Mirror or extend display automatically                                    ║
# ║  • All notifications silenced                                                ║
# ║  • Clean desktop, no private content visible                                 ║
# ║  • High contrast theme for projector readability                             ║
# ║  • Cursor highlighting enabled                                               ║
# ║  • Screen sharing indicators visible                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__present_duration=""
__present_no_notify=false
__present_mirror=false
__present_cursor_highlight=true
__present_high_contrast=false

__present_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __present_duration="${2:?}"
                shift 2
                ;;
            --mirror)           __present_mirror=true          ; shift ;;
            --no-cursor-hl)     __present_cursor_highlight=false ; shift ;;
            --high-contrast)    __present_high_contrast=true   ; shift ;;
            --no-notify)        __present_no_notify=true       ; shift ;;
            --dry-run)          ASH_DRY_RUN=true               ; shift ;;
            --verbose)          ASH_VERBOSE=true               ; shift ;;
            *)                  shift ;;
        esac
    done
}

__present_build_settings() {
    declare -gA __PRESENT_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="false"     # No distracting animations
        [hypr_blur]="false"           # Clean for projector
        [hypr_shadow]="false"
        [hypr_rounding]="6"
        [hypr_gaps_in]="6"
        [hypr_gaps_out]="12"
        [hypr_border_size]="2"
        [hypr_vfr]="false"            # Consistent frame delivery
        [hypr_opacity]="1.0"          # Full opacity (readability)

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"
        [idle_timeout]="0"            # Never sleep during presentation
        [idle_lock_timeout]="0"

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="false"         # Accurate colors for projector
        [screen_brightness]="100"     # Max for projector readability

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"       # No embarrassing notifications

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_microphone]="mute"     # Mute mic (use dedicated mic)
        [noise_cancel]="false"

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="false"      # Hidden for clean look
        [waybar_layout]="minimal-bar"

        # ── Cursor ──────────────────────────────────────────────────────────
        [cursor_size]="28"            # Larger cursor for visibility

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__present_no_notify}"
        [duration]="${__present_duration:-null}"
    )
}

__present_apply_extras() {
    # ── Monitor Mirroring ────────────────────────────────────────────────────
    if [[ "${__present_mirror}" == "true" ]]; then
        ash_log_info "  Configuring display mirroring"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Get all connected monitors
            local monitors
            monitors=$(hyprctl monitors -j 2>/dev/null \
                | python3 -c "
import sys, json
monitors = json.load(sys.stdin)
for m in monitors[1:]:
    name = m['name']
    x = monitors[0]['x']
    y = monitors[0]['y']
    w = monitors[0]['width']
    h = monitors[0]['height']
    print(f'{name},auto,0x0,1')
" 2>/dev/null || echo "")

            if [[ -n "${monitors}" ]]; then
                while IFS= read -r monitor_conf; do
                    hyprctl keyword monitor "${monitor_conf}" 2>/dev/null || true
                done <<< "${monitors}"
            fi
        fi
    fi

    # ── Cursor Spotlight ─────────────────────────────────────────────────────
    if [[ "${__present_cursor_highlight}" == "true" ]]; then
        ash_log_info "  Enabling cursor spotlight"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            # Hyprland zoom on cursor
            ash_hyprctl_set "cursor:zoom_factor" "1.0"
            # Apply spotlight shader if available
            local spotlight_shader="${ASH_CONFIG_DIR}/hypr/shaders/vignette.frag"
            if [[ -f "${spotlight_shader}" ]]; then
                ash_hyprctl_set "decoration:screen_shader" "${spotlight_shader}"
            fi
        fi
    fi

    # ── Hide Sensitive Windows ───────────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        # Move private/sensitive app classes to special workspace
        local -a sensitive_classes=("bitwarden" "keepassxc" "signal" "element")
        for cls in "${sensitive_classes[@]}"; do
            hyprctl dispatch movetoworkspacesilent \
                "special:private,class:${cls}" 2>/dev/null || true
        done
    fi
}

ash_present_mode_main() {
    __present_parse_args "$@"
    __present_build_settings
    ash_mode_activate "present" "__PRESENT_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __present_apply_extras
}

ash_present_mode_main "$@"