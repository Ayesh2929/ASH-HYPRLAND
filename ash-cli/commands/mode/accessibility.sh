#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — ACCESSIBILITY MODE                               ║
# ║  /ash-cli/commands/mode/accessibility.sh                                    ║
# ║                                                                              ║
# ║  WCAG AAA compliant accessibility environment:                               ║
# ║  • High contrast theme (4.5:1+ ratio)                                        ║
# ║  • Extra large fonts and cursor                                               ║
# ║  • Reduced motion / no animations                                            ║
# ║  • Screen reader (orca) integration                                          ║
# ║  • Keyboard-only navigation enhancements                                     ║
# ║  • Color blind-friendly palette options                                      ║
# ║  • Sticky keys support                                                       ║
# ║  • Focus indicators enlarged                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

__a11y_duration=""
__a11y_no_notify=false
__a11y_screen_reader=false
__a11y_color_blind=""           # deuteranopia|protanopia|tritanopia
__a11y_font_size="large"       # normal|large|xlarge
__a11y_sticky_keys=false
__a11y_high_contrast=true

__a11y_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                __a11y_duration="${2:?}"
                shift 2
                ;;
            --screen-reader)    __a11y_screen_reader=true       ; shift ;;
            --color-blind)
                __a11y_color_blind="${2:?}"
                shift 2
                ;;
            --font-size)
                __a11y_font_size="${2:?}"
                shift 2
                ;;
            --sticky-keys)      __a11y_sticky_keys=true         ; shift ;;
            --no-high-contrast) __a11y_high_contrast=false      ; shift ;;
            --no-notify)        __a11y_no_notify=true           ; shift ;;
            --dry-run)          ASH_DRY_RUN=true                ; shift ;;
            --verbose)          ASH_VERBOSE=true                ; shift ;;
            *)                  shift ;;
        esac
    done
}

# Map font size names to scale factors
__a11y_font_scale() {
    case "${__a11y_font_size}" in
        normal) echo "1.0"  ;;
        large)  echo "1.25" ;;
        xlarge) echo "1.5"  ;;
        *)      echo "1.25" ;;
    esac
}

__a11y_cursor_size() {
    case "${__a11y_font_size}" in
        normal) echo "24"  ;;
        large)  echo "36"  ;;
        xlarge) echo "48"  ;;
        *)      echo "36"  ;;
    esac
}

__a11y_build_settings() {
    declare -gA __A11Y_SETTINGS=(
        # ── Hyprland ────────────────────────────────────────────────────────
        [hypr_animations]="false"    # Reduce motion (WCAG 2.3.3)
        [hypr_blur]="false"          # Clear visibility over blur effects
        [hypr_shadow]="false"
        [hypr_rounding]="4"          # Subtle rounding
        [hypr_gaps_in]="8"           # More space between windows
        [hypr_gaps_out]="16"
        [hypr_border_size]="3"       # Thick, visible borders
        [hypr_vfr]="true"
        [hypr_cursor_zoom]="1.0"

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [screen_brightness]="90"     # High brightness for visibility
        [night_light]="false"        # Accurate colors for readability
        [idle_timeout]="600"         # Longer timeout (reading takes time)
        [idle_lock_timeout]="900"

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="false"     # All notifications (with sound)
        [notification_timeout]="10000" # Longer timeout to read

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="70"

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="true"
        [waybar_layout]="top-bar"

        # ── Cursor & Font ────────────────────────────────────────────────────
        [cursor_size]="$(__a11y_cursor_size)"
        [font_scale]="$(__a11y_font_scale)"

        # ── Keyboard ─────────────────────────────────────────────────────────
        [keyboard_repeat_delay]="500"  # Slower repeat for precision
        [keyboard_repeat_rate]="15"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__a11y_no_notify}"
        [duration]="${__a11y_duration:-null}"
    )
}

__a11y_apply_extras() {
    # ── Apply High Contrast Theme ────────────────────────────────────────────
    if [[ "${__a11y_high_contrast}" == "true" ]]; then
        ash_log_info "  Applying high-contrast accessibility theme"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            "${__ASH_CLI_DIR}/ash" theme apply "accessibility-high-contrast" \
                --quiet 2>/dev/null || \
                ash_log_warn "High contrast theme not found"
        fi
    fi

    # ── Color Blindness Filter ───────────────────────────────────────────────
    if [[ -n "${__a11y_color_blind}" ]]; then
        ash_log_info "  Applying color blindness filter: ${__a11y_color_blind}"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            local shader_path="${ASH_CONFIG_DIR}/hypr/shaders"

            case "${__a11y_color_blind}" in
                deuteranopia)
                    ash_hyprctl_set "decoration:screen_shader" \
                        "${shader_path}/deuteranopia.frag" || true
                    ;;
                protanopia)
                    ash_hyprctl_set "decoration:screen_shader" \
                        "${shader_path}/protanopia.frag" || true
                    ;;
                tritanopia)
                    ash_hyprctl_set "decoration:screen_shader" \
                        "${shader_path}/tritanopia.frag" || true
                    ;;
                *)
                    ash_log_warn "Unknown color blind mode: ${__a11y_color_blind}"
                    ;;
            esac
        fi
    fi

    # ── Screen Reader (Orca) ─────────────────────────────────────────────────
    if [[ "${__a11y_screen_reader}" == "true" ]]; then
        ash_log_info "  Starting Orca screen reader"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            if command -v orca &>/dev/null; then
                orca --replace &>/dev/null &
            else
                ash_log_warn "Orca not found — install: paru -S orca"
            fi
        fi
    fi

    # ── Sticky Keys ─────────────────────────────────────────────────────────
    if [[ "${__a11y_sticky_keys}" == "true" ]]; then
        ash_log_info "  Enabling sticky keys"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            gsettings set org.gnome.desktop.a11y.keyboard \
                stickykeys-enable true 2>/dev/null || true
        fi
    fi

    # ── GTK Accessibility Settings ───────────────────────────────────────────
    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        gsettings set org.gnome.desktop.interface \
            text-scaling-factor "$(__a11y_font_scale)" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface \
            cursor-size "$(__a11y_cursor_size)" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface \
            gtk-theme "HighContrast" 2>/dev/null || true
    fi
}

ash_accessibility_mode_main() {
    __a11y_parse_args "$@"
    __a11y_build_settings
    ash_mode_activate "accessibility" "__A11Y_SETTINGS"
    [[ "${ASH_DRY_RUN}" != "true" ]] && __a11y_apply_extras
}

ash_accessibility_mode_main "$@"