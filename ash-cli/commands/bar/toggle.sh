#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bar toggle                                               ║
# ║  Toggle bar visibility • per-monitor • per-output • fade animation support      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BAR_TOGGLE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BAR_TOGGLE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

declare -gr _TOGGLE_STATE_FILE="${_BAR_STATE_DIR}/visibility"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISIBILITY STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_toggle_get_state() {
    cat "$_TOGGLE_STATE_FILE" 2>/dev/null || printf 'visible'
}

_toggle_set_state() {
    printf '%s\n' "$1" > "$_TOGGLE_STATE_FILE"
}

_toggle_is_visible() {
    [[ "$(_toggle_get_state)" == "visible" ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BACKEND-SPECIFIC SHOW/HIDE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_toggle_waybar_show() {
    pkill -SIGUSR1 waybar 2>/dev/null && bar_ok "Waybar shown (SIGUSR1)"
}

_toggle_waybar_hide() {
    pkill -SIGUSR1 waybar 2>/dev/null && bar_ok "Waybar hidden (SIGUSR1)"
}

_toggle_waybar_toggle() {
    # Waybar: SIGUSR1 toggles visibility
    if pkill -SIGUSR1 waybar 2>/dev/null; then
        bar_ok "Waybar visibility toggled  (SIGUSR1)"
        return 0
    fi
    bar_fail "Could not signal Waybar"
    return 1
}

_toggle_ags_toggle() {
    if command -v ags &>/dev/null; then
        ags -r "App.toggleWindow('bar')" 2>/dev/null && \
            bar_ok "AGS bar toggled" || \
            bar_warn "AGS toggle failed"
    fi
}

_toggle_eww_toggle() {
    if command -v eww &>/dev/null; then
        local state
        state="$(eww get EWW_BAR_VISIBLE 2>/dev/null || echo 'true')"
        if [[ "$state" == "true" ]]; then
            eww close bar 2>/dev/null && bar_ok "EWW bar hidden"
        else
            eww open bar 2>/dev/null && bar_ok "EWW bar shown"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  HYPRLAND LAYER RULES (alternative approach)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_toggle_hyprland_opacity() {
    local opacity="${1:-0}"  # 0 = hide, 1 = show

    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || \
       ! command -v hyprctl &>/dev/null; then
        return 1
    fi

    # Get bar window address
    local bar_addr
    bar_addr="$(hyprctl clients -j 2>/dev/null | \
        python3 -c "
import json,sys
clients = json.load(sys.stdin)
bar = next((c for c in clients if '${BAR_BACKEND}' in c.get('class','').lower() or
            '${BAR_BACKEND}' in c.get('initialTitle','').lower()), None)
print(bar['address'] if bar else '')
" 2>/dev/null || echo '')"

    [[ -z "$bar_addr" ]] && return 1

    hyprctl dispatch setfloating address:"$bar_addr" &>/dev/null || true

    if [[ "$opacity" -eq 0 ]]; then
        hyprctl setprop address:"$bar_addr" alpha 0 2>/dev/null && \
            bar_ok "Bar hidden via Hyprland alpha"
    else
        hyprctl setprop address:"$bar_addr" alpha 1 2>/dev/null && \
            bar_ok "Bar shown via Hyprland alpha"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ANIMATED TOGGLE (CSS opacity transition workaround)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_toggle_animation() {
    local direction="$1"  # show | hide
    local frames=( '▏' '▎' '▍' '▌' '▋' '▊' '▉' '█' )
    [[ "$direction" == "hide" ]] && \
        frames=( '█' '▉' '▊' '▋' '▌' '▍' '▎' '▏' ' ' )

    printf '\n  '
    for frame in "${frames[@]}"; do
        printf '\r  %s%s%s  Bar %sing...' \
            "$(_bblue)" "$frame" "$(_br)" "$direction"
        sleep 0.04
    done
    printf '\r  %-40s\n' ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bar_toggle() {
    local force_action=""    # show | hide | ""=toggle
    local use_animation=1
    local quiet=0

    for arg in "${@:-}"; do
        case "$arg" in
            show|unhide|on)   force_action="show"       ;;
            hide|off)         force_action="hide"        ;;
            --no-animation)   use_animation=0            ;;
            --quiet|-q)       quiet=1                    ;;
        esac
    done

    [[ $quiet -eq 0 ]] && bar_section "👁️ " "Toggle Bar" "$(_bpeach)"
    [[ $quiet -eq 0 ]] && bar_kv "Backend" "$BAR_BACKEND"

    if ! bar_is_running "$BAR_BACKEND"; then
        [[ $quiet -eq 0 ]] && bar_warn "${BAR_BACKEND} is not running"
        [[ $quiet -eq 0 ]] && bar_info "Start it first: ash bar start"
        printf '\n'; return 0
    fi

    # Determine action
    local action="toggle"
    if [[ -n "$force_action" ]]; then
        action="$force_action"
    else
        # Smart toggle based on state
        if _toggle_is_visible; then
            action="hide"
        else
            action="show"
        fi
    fi

    [[ $quiet -eq 0 ]] && bar_kv "Action" "$action"

    local exit_code=0

    # Animate
    if [[ $use_animation -eq 1 ]] && [[ $quiet -eq 0 ]]; then
        _toggle_animation "$action" &
        local anim_pid=$!
    fi

    # Apply toggle per backend
    case "$BAR_BACKEND" in
        waybar)
            _toggle_waybar_toggle || exit_code=$?
            ;;
        ags)
            _toggle_ags_toggle || exit_code=$?
            ;;
        eww)
            _toggle_eww_toggle || exit_code=$?
            ;;
        *)
            # Generic: kill / restart
            if [[ "$action" == "hide" ]]; then
                pkill -x "$BAR_BACKEND" 2>/dev/null && \
                    { [[ $quiet -eq 0 ]] && bar_ok "${BAR_BACKEND} hidden"; } || \
                    exit_code=$?
            else
                "$BAR_BACKEND" &>/dev/null &
                sleep 0.3
                bar_is_running "$BAR_BACKEND" && \
                    { [[ $quiet -eq 0 ]] && bar_ok "${BAR_BACKEND} shown"; } || \
                    exit_code=$?
            fi
            ;;
    esac

    # Stop animation
    if [[ $use_animation -eq 1 ]] && [[ $quiet -eq 0 ]] && \
       [[ -n "${anim_pid:-}" ]]; then
        kill "$anim_pid" 2>/dev/null || true
        wait "$anim_pid" 2>/dev/null || true
    fi

    if [[ $exit_code -eq 0 ]]; then
        # Update state
        if [[ "$action" == "hide" ]]; then
            _toggle_set_state "hidden"
        else
            _toggle_set_state "visible"
        fi

        bar_notify "👁️  Bar Toggle" "${BAR_BACKEND}: ${action}"
    fi

    printf '\n'
    return $exit_code
}
