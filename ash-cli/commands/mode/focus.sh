#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — FOCUS MODE                                        ║
# ║  /ash-cli/commands/mode/focus.sh                                              ║
# ║                                                                              ║
# ║  Distraction-free deep work environment:                                     ║
# ║  • All notifications silenced                                                 ║
# ║  • Pomodoro timer integration                                                 ║
# ║  • Warm color temperature for long sessions                                   ║
# ║  • Waybar hidden for clean desktop                                            ║
# ║  • Strict mode blocks distraction websites                                    ║
# ║  • Ambient sound support                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   ash mode focus [options]
#
# OPTIONS:
#   --duration <time>     Auto-revert after time (e.g. 90m)
#   --pomodoro            Start a pomodoro work session
#   --ambient <name>      Play ambient sound (rain, ...)
#   --strict              Block distraction websites via /etc/hosts
#   --no-notify           Skip desktop notification
#   --no-animation        Skip transition animation
#   --dry-run             Preview without applying
#   --verbose             Show detailed output
#
# EXAMPLES:
#   ash mode focus
#   ash mode focus --duration 90m
#   ash mode focus --pomodoro --ambient rain

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────

__focus_duration=""
__focus_no_notify=false
__focus_pomodoro=false
__focus_pomodoro_duration="25"
__focus_ambient=""
__focus_strict=false

__focus_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --duration)
                [[ -n "${2:-}" ]] || ash_die "--duration requires a value (e.g. 90m)"
                __focus_duration="${2}"
                shift 2
                ;;
            --pomodoro)         __focus_pomodoro=true            ; shift ;;
            --ambient)
                [[ -n "${2:-}" ]] || ash_die "--ambient requires a value"
                __focus_ambient="${2}"
                shift 2
                ;;
            --strict)           __focus_strict=true              ; shift ;;
            --no-notify)        __focus_no_notify=true           ; shift ;;
            --dry-run)          ASH_DRY_RUN=true                 ; shift ;;
            --verbose)          ASH_VERBOSE=true                 ; shift ;;
            --no-animation)     ASH_NO_ANIMATION=true            ; shift ;;
            --help|-h)
                printf '\n'
                printf "${MODE_ACCENT_COLORS[focus]}${MODE_COLOR_BOLD}"
                printf "  %s FOCUS MODE — Distraction-Free Deep Work\n" "${MODE_ICONS[focus]}"
                printf "${MODE_COLOR_RESET}\n"
                printf "  ${COLOR_ASH_TEXT}%s${MODE_COLOR_RESET}\n\n" \
                    "${MODE_DESCRIPTIONS[focus]}"
                return 0
                ;;
            *)
                ash_log_warn "Unknown option for focus mode: '${1}'"
                shift
                ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — MODE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

__focus_build_settings() {
    declare -gA __FOCUS_SETTINGS=(
        # ── Hyprland Compositor ─────────────────────────────────────────────
        [hypr_animations]="false"     # No distractions from motion
        [hypr_blur]="false"           # Clean, uncluttered visuals
        [hypr_shadow]="false"
        [hypr_rounding]="8"           # Subtle rounding
        [hypr_gaps_in]="4"
        [hypr_gaps_out]="20"          # Big outer gap for breathing room
        [hypr_border_size]="1"
        [hypr_vfr]="true"
        [hypr_opacity]="1.0"          # Full opacity — no distractions

        # ── Power ───────────────────────────────────────────────────────────
        [cpu_governor]="schedutil"
        [power_profile]="balanced"

        # ── Display ─────────────────────────────────────────────────────────
        [night_light]="true"          # Warm colors for long sessions
        [color_temperature]="4200"    # Warm amber tone
        [screen_brightness]="65"      # Easy on eyes
        [idle_timeout]="600"          # Longer idle (deep work = rare idle)
        [idle_lock_timeout]="900"

        # ── Notifications ───────────────────────────────────────────────────
        [do_not_disturb]="true"       # Complete silence
        [notification_timeout]="1500" # Brief if any slip through

        # ── Audio ───────────────────────────────────────────────────────────
        [audio_volume]="30"           # Low, ambient-friendly
        [noise_cancel]="true"

        # ── Bar ─────────────────────────────────────────────────────────────
        [waybar_visible]="false"      # Hidden for clean desktop
        [waybar_layout]="zen-bar"

        # ── Productivity Tools ───────────────────────────────────────────────
        [pomodoro]="${__focus_pomodoro}"
        [clipboard_history]="true"

        # ── Control Keys ────────────────────────────────────────────────────
        [no_notify]="${__focus_no_notify}"
        [duration]="${__focus_duration:-null}"
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# FOCUS-SPECIFIC EXTRAS
# ─────────────────────────────────────────────────────────────────────────────

__focus_apply_extras() {
    # ── Ambient Sounds ───────────────────────────────────────────────────────
    if [[ -n "${__focus_ambient}" ]]; then
        ash_log_info "  Starting ambient sound: ${__focus_ambient}"

        local sound_file="${ASH_DATA_HOME}/sounds/ambient/${__focus_ambient}.ogg"
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            if [[ -f "${sound_file}" ]]; then
                pkill -f "mpv.*ambient" 2>/dev/null || true
                mpv --loop=inf --volume=40 --no-video \
                    "${sound_file}" &>/dev/null &
                echo "$!" > "${ASH_RUNTIME_DIR}/ambient-sound.pid"
            else
                ash_log_warn "Ambient sound not found: ${sound_file}"
                # Try online sources
                case "${__focus_ambient}" in
                    rain)
                        mpv --loop=inf --volume=40 --no-video \
                            "https://myinstants.com/media/sounds/rain.mp3" \
                            &>/dev/null || true &
                        ;;
                    *)
                        ash_log_warn "Unknown ambient sound: ${__focus_ambient}"
                        ;;
                esac
            fi
        fi
    fi

    # ── Strict Mode: Block Distractions ─────────────────────────────────────
    if [[ "${__focus_strict}" == "true" ]]; then
        ash_log_info "  Enabling strict mode (website blocking)"

        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            local distraction_domains=(
                "reddit.com"
                "twitter.com"
                "x.com"
                "facebook.com"
                "instagram.com"
                "tiktok.com"
                "youtube.com"
                "twitch.tv"
                "news.ycombinator.com"
            )

            local hosts_marker="# ASH-FOCUS-MODE-START"
            local hosts_end="# ASH-FOCUS-MODE-END"

            # Only add if not already blocked
            if ! grep -q "${hosts_marker}" /etc/hosts 2>/dev/null; then
                {
                    echo ""
                    echo "${hosts_marker}"
                    for domain in "${distraction_domains[@]}"; do
                        echo "127.0.0.1 ${domain} www.${domain}"
                    done
                    echo "${hosts_end}"
                } | sudo tee -a /etc/hosts > /dev/null 2>/dev/null || \
                    ash_log_warn "Could not modify /etc/hosts (needs sudo)"
            fi

            # Save state for cleanup on mode exit
            echo "true" > "${ASH_RUNTIME_DIR}/focus-strict.state"
        fi
    fi

    # ── Send Pomodoro Start Notification ────────────────────────────────────
    if [[ "${__focus_pomodoro}" == "true" ]] && \
       [[ "${ASH_QUIET}" != "true" ]] && \
       [[ "${__focus_no_notify}" != "true" ]]; then
        if [[ "${ASH_DRY_RUN}" != "true" ]]; then
            notify-send \
                --app-name="ASH Focus Mode" \
                --urgency=normal \
                --expire-time=5000 \
                "🍅 Pomodoro Started" \
                "${__focus_pomodoro_duration} min work session. You've got this!" \
                2>/dev/null || true
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# POST-HOOK: CLEANUP FOCUS MODE EXTRAS
# ─────────────────────────────────────────────────────────────────────────────

# Register a post-mode-change cleanup hook that fires when mode changes away
__focus_register_cleanup_hook() {
    cat > "${ASH_RUNTIME_DIR}/focus-cleanup.sh" <<-'CLEANUP'
	#!/usr/bin/env bash
	# ASH Focus Mode cleanup hook
	# Remove /etc/hosts entries
	if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/ash/focus-strict.state" ]]; then
	    sudo sed -i '/# ASH-FOCUS-MODE-START/,/# ASH-FOCUS-MODE-END/d' \
	        /etc/hosts 2>/dev/null || true
	    rm -f "${XDG_RUNTIME_DIR:-/tmp}/ash/focus-strict.state"
	fi
	# Stop ambient sounds
	if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/ash/ambient-sound.pid" ]]; then
	    kill "$(cat "${XDG_RUNTIME_DIR:-/tmp}/ash/ambient-sound.pid")" 2>/dev/null || true
	    rm -f "${XDG_RUNTIME_DIR:-/tmp}/ash/ambient-sound.pid"
	fi
	CLEANUP
    chmod +x "${ASH_RUNTIME_DIR}/focus-cleanup.sh"
}

ash_focus_mode_main() {
    __focus_parse_args "$@"
    __focus_build_settings

    # Register cleanup before activation
    __focus_register_cleanup_hook

    ash_mode_activate "focus" "__FOCUS_SETTINGS"

    if [[ "${ASH_DRY_RUN}" != "true" ]]; then
        __focus_apply_extras
    fi
}

ash_focus_mode_main "$@"