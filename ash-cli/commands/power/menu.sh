#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  power menu                                               ║
# ║  Interactive power menu: rofi / wlogout / fzf TUI / wofi / dmenu               ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_POWER_MENU_LOADED:-}" == "1" ]] && return 0
readonly _ASH_POWER_MENU_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MENU ENTRIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Format: "label|icon|command|description|color"
declare -gA _MENU_ACTIONS=(
    ["🔒 Lock"]="lock|🔒|ash_power_lock|Lock screen|$(_pwblue)"
    ["💤 Suspend"]="suspend|💤|ash_power_suspend|Suspend to RAM|$(_pwblue)"
    ["❄️  Hibernate"]="hibernate|❄️ |ash_power_hibernate|Hibernate to disk|$(_pwblue)"
    ["🚪 Logout"]="logout|🚪|ash_power_logout|Log out session|$(_pwyellow)"
    ["🔁 Reboot"]="reboot|🔁|ash_power_reboot|Restart system|$(_pwpeach)"
    ["🔴 Shutdown"]="shutdown|🔴|ash_power_shutdown|Power off|$(_pwred)"
)

# Ordered list for display
declare -ga _MENU_ORDER=(
    "🔒 Lock"
    "💤 Suspend"
    "❄️  Hibernate"
    "🚪 Logout"
    "🔁 Reboot"
    "🔴 Shutdown"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WLOGOUT LAUNCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_menu_wlogout() {
    local wlogout_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout"

    if [[ -f "${wlogout_cfg}/layout" ]]; then
        wlogout \
            --layout "${wlogout_cfg}/layout" \
            --css "${wlogout_cfg}/style.css" \
            --column-spacing 20 \
            --row-spacing 20 \
            --margin-top 100 \
            --margin-bottom 100 \
            2>/dev/null &
    else
        wlogout 2>/dev/null &
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ROFI POWER MENU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_menu_rofi() {
    local rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"

    # Build menu list
    local rofi_list
    rofi_list="$(printf '%s\n' "${_MENU_ORDER[@]}")"

    local chosen
    chosen="$(printf '%s\n' "${_MENU_ORDER[@]}" | \
        rofi -dmenu \
            -p "⚡ Power" \
            -theme-str "
                window { width: 300px; }
                element { padding: 12px; }
                element-text { font: 'JetBrainsMono Nerd Font 13'; }
            " \
            -no-fixed-num-lines \
            -scroll-method 0 \
            2>/dev/null || echo '')"

    [[ -z "$chosen" ]] && return 0
    _menu_execute_choice "$chosen"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FZF TUI POWER MENU  (terminal-native)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_menu_fzf() {
    local -a display_entries=()
    for label in "${_MENU_ORDER[@]}"; do
        IFS='|' read -r action icon fn desc color <<< "${_MENU_ACTIONS[$label]:-}"
        display_entries+=("${label}  —  ${desc}")
    done

    local chosen
    chosen="$(printf '%s\n' "${display_entries[@]}" | \
        fzf \
            --prompt "  ⚡  Power: " \
            --height=14 \
            --border=rounded \
            --border-label=" 🔋 Power Manager " \
            --border-label-pos=3 \
            --info=hidden \
            --no-sort \
            --color="bg:#1e1e2e,fg:#cdd6f4,hl:#cba6f7,hl+:#f38ba8" \
            --color="border:#313244,prompt:#cba6f7,pointer:#f38ba8" \
            --color="marker:#a6e3a1,spinner:#f5c2e7,info:#cdd6f4" \
            --pointer="→" \
            --marker="✓" \
            --header="  Tab=select  Enter=execute  ESC=cancel" \
            --header-first \
            2>/dev/null | awk -F'  —' '{print $1}' | sed 's/ *$//' || echo '')"

    [[ -z "$chosen" ]] && { pwr_info "Cancelled"; return 0; }

    # Strip trailing spaces to match _MENU_ORDER keys
    chosen="${chosen%"${chosen##*[![:space:]]}"}"
    _menu_execute_choice "$chosen"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  TERMINAL TUI MENU  (no fzf/rofi dependency)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_menu_tui() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n\033[1;38;2;243;139;168m'
        printf '  ╔══════════════════════════════════════╗\n'
        printf '  ║  ⚡  ASH Power Menu                   ║\n'
        printf '  ╠══════════════════════════════════════╣\n'
        printf '\033[0m'
    fi

    local i=0
    for label in "${_MENU_ORDER[@]}"; do
        (( i++ )) || true
        IFS='|' read -r action icon fn desc color <<< "${_MENU_ACTIONS[$label]:-}"

        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
            printf '  \033[1;38;2;203;166;247m║\033[0m  '
            printf '\033[38;2;249;226;175m%d\033[0m  ' "$i"
            printf '%s%-20s\033[0m  \033[38;2;108;112;134m%s\033[0m' \
                "${color:-}" "$label" "$desc"
            printf '\n'
        else
            printf '  [%d]  %-22s  %s\n' "$i" "$label" "$desc"
        fi
    done

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '  \033[1;38;2;203;166;247m╠══════════════════════════════════════╣\033[0m\n'
        printf '  \033[1;38;2;203;166;247m║\033[0m  \033[38;2;108;112;134m[0] Cancel\033[0m\n'
        printf '  \033[1;38;2;203;166;247m╚══════════════════════════════════════╝\033[0m\n'
    fi

    printf '\n  %sChoice [0-%d]: %s' "$(_pwdim)" "${#_MENU_ORDER[@]}" "$(_pwr)"

    local choice
    read -r choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        pwr_info "Cancelled"
        return 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && \
       (( choice >= 1 )) && (( choice <= ${#_MENU_ORDER[@]} )); then
        local selected_label="${_MENU_ORDER[$((choice-1))]}"
        _menu_execute_choice "$selected_label"
    else
        pwr_fail "Invalid selection: ${choice}"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ACTION EXECUTOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_menu_execute_choice() {
    local chosen="$1"
    local action_data="${_MENU_ACTIONS[$chosen]:-}"

    if [[ -z "$action_data" ]]; then
        # Try fuzzy match
        for label in "${_MENU_ORDER[@]}"; do
            if [[ "${label,,}" == *"${chosen,,}"* ]]; then
                action_data="${_MENU_ACTIONS[$label]:-}"
                break
            fi
        done
    fi

    [[ -z "$action_data" ]] && {
        pwr_fail "Unknown selection: ${chosen}"
        return 1
    }

    local action icon fn desc color
    IFS='|' read -r action icon fn desc color <<< "$action_data"

    pwr_log "menu→${action}" "initiated"

    # Load and execute the sub-command
    _pwr_load_sub "$action" || return 1

    if declare -f "$fn" &>/dev/null; then
        "$fn"
    else
        pwr_fail "Action function not found: ${fn}"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_power_menu() {
    local mode="auto"

    for arg in "${@:-}"; do
        case "$arg" in
            --rofi)     mode="rofi"    ;;
            --fzf)      mode="fzf"     ;;
            --tui)      mode="tui"     ;;
            --wlogout)  mode="wlogout" ;;
            --wofi)     mode="wofi"    ;;
        esac
    done

    # Auto-detect best available frontend
    if [[ "$mode" == "auto" ]]; then
        if command -v wlogout &>/dev/null && \
           [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            mode="wlogout"
        elif command -v rofi &>/dev/null; then
            mode="rofi"
        elif command -v fzf &>/dev/null; then
            mode="fzf"
        else
            mode="tui"
        fi
    fi

    case "$mode" in
        wlogout) _menu_wlogout ;;
        rofi)    _menu_rofi    ;;
        fzf)     _menu_fzf     ;;
        tui|*)   _menu_tui     ;;
    esac
}
