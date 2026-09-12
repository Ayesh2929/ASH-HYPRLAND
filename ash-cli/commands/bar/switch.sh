#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ███████╗██╗    ██╗██╗████████╗ ██████╗██╗  ██╗                                 ║
# ║  ██╔════╝██║    ██║██║╚══██╔══╝██╔════╝██║  ██║                                 ║
# ║  ███████╗██║ █╗ ██║██║   ██║   ██║     ███████║                                 ║
# ║  ╚════██║██║███╗██║██║   ██║   ██║     ██╔══██║                                 ║
# ║  ███████║╚███╔███╔╝██║   ██║   ╚██████╗██║  ██║                                 ║
# ║  ╚══════╝ ╚══╝╚══╝ ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝                                 ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  bar switch                                               ║
# ║  Switch between bar backends with graceful transition and config migration       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BAR_SWITCH_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BAR_SWITCH_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _SWITCH_BACKEND_INFO=(
    [waybar]="🖥️   Waybar     |Most popular GTK bar|waybar|Wayland"
    [ags]="⚡  AGS         |TypeScript/GJS bar|ags|Wayland"
    [eww]="🔧  EWW         |Elkowar's Wacky Widgets|eww|Wayland/X11"
    [polybar]="📊  Polybar     |Highly configurable X11 bar|polybar|X11"
    [ironbar]="🦀  Ironbar     |Rust-based Wayland bar|ironbar|Wayland"
    [lemonbar]="🍋  Lemonbar    |Lightweight X11 bar|lemonbar|X11"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TRANSITION ANIMATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_transition() {
    local from="$1"  to="$2"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n  '

        # Slide-out animation for old bar
        local old_name="${from:0:8}"
        printf '%s%s%s' "$(_bred)" "$old_name" "$(_br)"
        sleep 0.1

        for arrow in '→' '→→' '→→→' '→→→→' '→→→→→'; do
            printf '\r  %s%s  %s%s%s     ' \
                "$(_bred)" "${old_name}" \
                "$(_bdim)" "$arrow" "$(_br)"
            sleep 0.06
        done

        # Slide-in animation for new bar
        local new_name="${to:0:8}"
        for arrow in '←←←←←' '←←←←' '←←←' '←←' '←'; do
            printf '\r  %s%s  %s%s%s' \
                "$(_bdim)" "$arrow" \
                "$(_bgreen)" "${new_name}" "$(_br)"
            sleep 0.06
        done

        printf '\r  %-50s\n' ""
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND COMPARISON TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_comparison_table() {
    printf '\n  %s%-12s %-12s %-12s %-12s %-10s %-8s%s\n' \
        "$(_bdim)" "Backend" "Language" "Protocol" "Themes" "CPU" "Status" "$(_br)"
    printf '  %s%s%s\n' "$(_bdim)" "$(printf '─%.0s' $(seq 1 70))" "$(_br)"

    declare -A lang_map=(
        [waybar]="GTK/CSS"    [ags]="TypeScript"
        [eww]="Yuck/SCSS"     [polybar]="IniConfig"
        [ironbar]="TOML"      [lemonbar]="Shell"
    )
    declare -A proto_map=(
        [waybar]="Wayland"  [ags]="Wayland"
        [eww]="Both"        [polybar]="X11"
        [ironbar]="Wayland" [lemonbar]="X11"
    )
    declare -A theme_map=(
        [waybar]="CSS+SCSS"  [ags]="CSS+SCSS"
        [eww]="SCSS"         [polybar]="IniFile"
        [ironbar]="CSS"      [lemonbar]="Colors"
    )

    for backend in waybar ags eww ironbar polybar lemonbar; do
        local installed_badge running_badge
        local proc="${_BAR_BACKEND_PROCS[$backend]:-$backend}"

        if command -v "$backend" &>/dev/null; then
            installed_badge="${_bgreen}✓ installed${_br}"
        else
            installed_badge="${_bdim}✗ missing${_br}"
        fi

        local cur_marker=""
        [[ "$backend" == "$BAR_BACKEND" ]] && \
            cur_marker="${_bmauve} ← active${_br}"

        printf '  %s%-12s%s %-12s %-12s %-12s %-10s %s%s\n' \
            "$(_bsky)" "$backend" "$(_br)" \
            "${lang_map[$backend]:-?}" \
            "${proto_map[$backend]:-?}" \
            "${theme_map[$backend]:-?}" \
            "" \
            "$installed_badge" \
            "$cur_marker"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  STOP ALL BARS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_stop_all() {
    bar_step "Stopping all running bars..."

    local stopped=0
    for backend in "${!_BAR_BACKEND_PROCS[@]}"; do
        local proc="${_BAR_BACKEND_PROCS[$backend]}"
        if pgrep -x "$proc" &>/dev/null 2>&1; then
            pkill -x "$proc" 2>/dev/null || pkill "$proc" 2>/dev/null || true
            sleep 0.1
            if ! pgrep -x "$proc" &>/dev/null 2>&1; then
                bar_ok "Stopped: ${backend}"
                (( stopped++ )) || true
            else
                bar_warn "Still running: ${backend}  — trying SIGKILL..."
                pkill -9 -x "$proc" 2>/dev/null || true
            fi
        fi
    done

    (( stopped == 0 )) && bar_info "No bars were running"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  START NEW BACKEND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_switch_start_backend() {
    local backend="$1"

    if ! command -v "$backend" &>/dev/null; then
        bar_fail "${backend} not installed"
        bar_info "Install: paru -S ${backend}"
        return 1
    fi

    bar_step "Starting ${backend}..."

    local exit_code=0
    case "$backend" in
        waybar)
            waybar &>/dev/null &
            sleep 0.5
            pgrep -x waybar &>/dev/null || exit_code=1
            ;;
        ags)
            ags &>/dev/null &
            sleep 0.5
            pgrep -x ags &>/dev/null || exit_code=1
            ;;
        eww)
            eww daemon &>/dev/null
            sleep 0.3
            eww open bar &>/dev/null 2>&1 || exit_code=1
            ;;
        polybar)
            # polybar needs a bar name
            local poly_bar
            poly_bar="$(grep '^\[bar/' "${_BAR_CFG_DIR}/polybar/config.ini" \
                       2>/dev/null | head -1 | sed 's/\[bar\///;s/\]//')"
            polybar "${poly_bar:-main}" &>/dev/null &
            sleep 0.4
            pgrep -x polybar &>/dev/null || exit_code=1
            ;;
        ironbar)
            ironbar &>/dev/null &
            sleep 0.4
            pgrep -x ironbar &>/dev/null || exit_code=1
            ;;
        *)
            "$backend" &>/dev/null &
            sleep 0.5
            pgrep -x "$backend" &>/dev/null || exit_code=1
            ;;
    esac

    if [[ $exit_code -eq 0 ]]; then
        local pid
        pid="$(pgrep -x "${_BAR_BACKEND_PROCS[$backend]:-$backend}" | head -1)"
        bar_ok "${backend} started  (PID: ${pid})"
    else
        bar_fail "${backend} failed to start"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bar_switch() {
    local target_backend=""
    local list_mode=0
    local compare_mode=0
    local no_transition=0
    local force=0

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)        list_mode=1        ;;
            --compare|-c)     compare_mode=1     ;;
            --no-transition)  no_transition=1    ;;
            --force|-f)       force=1            ;;
            waybar|ags|eww|polybar|ironbar|lemonbar)
                target_backend="$arg"
                ;;
        esac
    done

    bar_section "🔀" "Switch Bar Backend" "$(_bsapph)"

    if [[ $list_mode -eq 1 ]]; then
        bar_kv "Current" "$BAR_BACKEND"
        printf '\n  %sAvailable backends:%s\n\n' "$(_bbold)" "$(_br)"

        for backend in "${!_SWITCH_BACKEND_INFO[@]}"; do
            IFS='|' read -r icon desc _ _ <<< "${_SWITCH_BACKEND_INFO[$backend]}"
            local installed_mark
            command -v "$backend" &>/dev/null && \
                installed_mark="${_bgreen}✓${_br}" || \
                installed_mark="${_bdim}✗${_br}"
            local active_mark
            [[ "$backend" == "$BAR_BACKEND" ]] && \
                active_mark="${_bmauve} ← running${_br}" || active_mark=""

            printf '   %s  %s%-10s%s  %s%s%s%s\n' \
                "$installed_mark" \
                "$(_bsky)" "$backend" "$(_br)" \
                "$(_bdim)" "$desc" "$(_br)" \
                "$active_mark"
        done | sort

        printf '\n  %sUsage: ash bar switch <backend>%s\n\n' "$(_bdim)" "$(_br)"
        return 0
    fi

    if [[ $compare_mode -eq 1 ]]; then
        _switch_comparison_table
        printf '\n'
        return 0
    fi

    # Interactive picker if no target
    if [[ -z "$target_backend" ]]; then
        if command -v fzf &>/dev/null; then
            local fzf_list
            fzf_list="$(for backend in "${!_SWITCH_BACKEND_INFO[@]}"; do
                IFS='|' read -r icon desc pkg _ <<< "${_SWITCH_BACKEND_INFO[$backend]}"
                local installed="$(command -v "$backend" &>/dev/null && echo '✓' || echo '✗')"
                local active="$([ "$backend" == "$BAR_BACKEND" ] && echo ' ← active' || echo '')"
                printf '%s  %-10s  %s%s  [%s]\n' \
                    "$installed" "$backend" "$desc" "$active" "$pkg"
            done | sort)"

            target_backend="$(printf '%s\n' "$fzf_list" | \
                fzf \
                    --prompt "  🔀  Select bar backend: " \
                    --height=15 \
                    --border=rounded \
                    --color="hl:$(_bmauve | sed 's/\033\[//;s/m//')" \
                    --header="↵=switch  ESC=cancel" \
                    2>/dev/null | awk '{print $2}' || echo '')"
        fi

        if [[ -z "$target_backend" ]]; then
            bar_info "No backend selected"
            bar_info "Run: ash bar switch --list"
            printf '\n'; return 0
        fi
    fi

    # Validate target
    if [[ -z "${_SWITCH_BACKEND_INFO[$target_backend]:-}" ]]; then
        bar_fail "Unknown backend: ${target_backend}"
        bar_info "Valid: ${!_SWITCH_BACKEND_INFO[*]}"
        printf '\n'; return 1
    fi

    bar_kv "From"   "$BAR_BACKEND"
    bar_kv "To"     "$target_backend"

    if [[ "$target_backend" == "$BAR_BACKEND" ]] && [[ $force -eq 0 ]]; then
        bar_info "${target_backend} is already the active bar"
        bar_info "Use --force to restart it anyway"
        printf '\n'; return 0
    fi

    # Check if target is installed
    if ! command -v "$target_backend" &>/dev/null; then
        bar_fail "${target_backend} is not installed"

        IFS='|' read -r _ _ pkg _ <<< "${_SWITCH_BACKEND_INFO[$target_backend]:-|||}"
        [[ -n "$pkg" ]] && bar_info "Install: paru -S ${pkg}"

        printf '\n'; return 1
    fi

    # Confirm
    if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
        printf '  %sSwitch from %s%s%s to %s%s%s? [Y/n] %s' \
            "$(_bdim)" "$(_bred)" "$BAR_BACKEND" "$(_bdim)" \
            "$(_bgreen)" "$target_backend" "$(_bdim)" "$(_br)"
        local ans
        read -r ans
        [[ "${ans,,}" == "n" ]] && { bar_info "Cancelled"; printf '\n'; return 0; }
    fi

    # Transition animation
    [[ $no_transition -eq 0 ]] && _switch_transition "$BAR_BACKEND" "$target_backend"

    # Stop all running bars
    _switch_stop_all
    sleep 0.3

    # Start new backend
    local start_exit=0
    _switch_start_backend "$target_backend" || start_exit=$?

    if [[ $start_exit -eq 0 ]]; then
        # Save preference
        printf '%s\n' "$target_backend" > "${_BAR_STATE_DIR}/preferred-backend"
        BAR_BACKEND="$target_backend"

        bar_ok "Switched to: ${target_backend}"
        bar_notify "🔀 Bar Switched" "${BAR_BACKEND} → ${target_backend}"
    else
        bar_fail "Failed to start ${target_backend}"
        bar_info "Check: ash bar logs"

        # Try to restart previous bar
        bar_warn "Attempting to restart previous bar: ${BAR_BACKEND}..."
        _switch_start_backend "$BAR_BACKEND" &>/dev/null || \
            bar_fail "Could not restore ${BAR_BACKEND}"
    fi

    printf '\n'
}
