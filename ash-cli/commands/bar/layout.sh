#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  bar layout                                               ║
# ║  Switch bar position • dual bars • floating • vertical • fullscreen              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BAR_LAYOUT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BAR_LAYOUT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LAYOUT DEFINITIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _LAYOUT_POSITIONS=(
    [top]="top"
    [bottom]="bottom"
    [left]="left"
    [right]="right"
    [top-bottom]="dual-horizontal"
    [floating]="floating"
    [minimal]="minimal"
    [zen]="zen"
    [gaming]="gaming"
    [island]="island"
)

declare -gA _LAYOUT_DESCRIPTIONS=(
    [top]="Standard top bar  (default Waybar position)"
    [bottom]="Bar at bottom of screen"
    [left]="Vertical left sidebar bar"
    [right]="Vertical right sidebar bar"
    [top-bottom]="Dual horizontal bars (top + bottom)"
    [floating]="Floating island bar (centered, rounded)"
    [minimal]="Minimal bar with essential modules only"
    [zen]="Hidden bar — auto-show on hover"
    [gaming]="Compact overlay bar for gaming (corner HUD)"
    [island]="macOS-style centered island"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WAYBAR LAYOUT SWITCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_layout_waybar_apply() {
    local position="$1"
    local wb_cfg_dir="${_BAR_CFG_DIR}/waybar"
    local ash_layouts_dir="${_BAR_ASH_ROOT}/config/waybar/layouts"
    local active_cfg="${wb_cfg_dir}/config.jsonc"
    local active_style="${wb_cfg_dir}/style.css"

    # Map position to layout file
    local layout_file=""
    case "$position" in
        top)       layout_file="${ash_layouts_dir}/top-bar.jsonc"       ;;
        bottom)    layout_file="${ash_layouts_dir}/bottom-bar.jsonc"    ;;
        left)      layout_file="${ash_layouts_dir}/vertical-left.jsonc" ;;
        right)     layout_file="${ash_layouts_dir}/vertical-right.jsonc" ;;
        top-bottom)layout_file="${ash_layouts_dir}/dual-bar-top.jsonc"  ;;
        floating)  layout_file="${ash_layouts_dir}/floating-bar.jsonc"  ;;
        minimal)   layout_file="${ash_layouts_dir}/minimal-bar.jsonc"   ;;
        island)    layout_file="${ash_layouts_dir}/island-bar.jsonc"    ;;
        gaming)    layout_file="${ash_layouts_dir}/gaming-bar.jsonc"    ;;
        zen)       layout_file="${ash_layouts_dir}/zen-bar.jsonc"       ;;
    esac

    if [[ -n "$layout_file" ]] && [[ -f "$layout_file" ]]; then
        # Backup current config
        local backup="${wb_cfg_dir}/config.jsonc.bak.$(date +%s)"
        [[ -f "$active_cfg" ]] && cp "$active_cfg" "$backup"

        # Apply layout
        cp "$layout_file" "$active_cfg"
        bar_ok "Layout file applied: ${layout_file##*/}"
    else
        # Modify existing config using python3 (patch position field)
        if [[ -f "$active_cfg" ]] && command -v python3 &>/dev/null; then
            python3 - "$active_cfg" "$position" << 'PYEOF'
import json, sys, re

cfg_file = sys.argv[1]
position = sys.argv[2]

with open(cfg_file, 'r') as f:
    content = f.read()

# Handle JSONC: strip comments then parse
clean = re.sub(r'//.*?$|/\*.*?\*/', '', content, flags=re.M|re.S)

try:
    config = json.loads(clean)
except Exception as e:
    # If it's an array (dual bar), modify the first entry
    try:
        configs = json.loads(clean)
        config = configs[0] if isinstance(configs, list) else {}
    except:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

position_map = {
    'top': 'top', 'bottom': 'bottom',
    'left': 'left', 'right': 'right',
    'floating': 'top',
}

if isinstance(config, dict):
    config['position'] = position_map.get(position, 'top')
    config['layer'] = 'top' if position != 'floating' else 'overlay'

with open(cfg_file, 'w') as f:
    json.dump(config, f, indent=2)

PYEOF
            bar_ok "Config patched: position=${position}"
        else
            bar_warn "No layout file found for '${position}'"
            bar_info "Expected: ${ash_layouts_dir}/${position}-bar.jsonc"
            return 1
        fi
    fi

    # Corresponding CSS if available
    local style_file="${ash_layouts_dir}/../themes/${position}.css"
    if [[ -f "$style_file" ]]; then
        [[ -f "$active_style" ]] && cp "$active_style" "${active_style}.bak"
        cp "$style_file" "$active_style"
        bar_ok "Style applied: ${style_file##*/}"
    fi

    # Persist layout preference
    printf '%s\n' "$position" > "${_BAR_STATE_DIR}/current-layout"
}

_layout_ags_apply() {
    local position="$1"
    local ags_cfg="${_BAR_CFG_DIR}/ags"

    bar_step "Applying AGS layout: ${position}..."

    # AGS uses env vars or config JS
    local config_js="${ags_cfg}/config.js"
    if [[ -f "$config_js" ]]; then
        # Patch position variable
        sed -i "s/position: ['\"].*['\"]/position: '${position}'/" \
            "$config_js" 2>/dev/null || true
        bar_ok "AGS config patched"
    fi
}

_layout_eww_apply() {
    local position="$1"
    bar_step "Applying EWW layout: ${position}..."

    local eww_cfg="${_BAR_CFG_DIR}/eww/eww.yuck"
    if [[ -f "$eww_cfg" ]]; then
        bar_info "EWW layout change requires manual config edit: ${eww_cfg}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  LAYOUT VISUALIZER  (ASCII art preview)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_layout_ascii_preview() {
    local position="$1"

    printf '\n  %sLayout preview:%s\n' "$(_bdim)" "$(_br)"

    local bar_line="$(_bblue)$(_bbold)████████████████████████████████$(_br)"
    local emp_line="$(_bdim)░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░$(_br)"
    local border="$(_bdim)┌────────────────────────────────────┐$(_br)"
    local border_b="$(_bdim)└────────────────────────────────────┘$(_br)"

    printf '  %s\n' "$border"

    case "$position" in
        top)
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$bar_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            ;;
        bottom)
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$bar_line" "$(_bdim)" "$(_br)"
            ;;
        top-bottom)
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$bar_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$bar_line" "$(_bdim)" "$(_br)"
            ;;
        left)
            local lbar="$(_bblue)$(_bbold)████$(_br)"
            local lemp="$(_bdim)░░░░░░░░░░░░░░░░░░░░░░░░░░░░$(_br)"
            printf '  %s│%s%s %s%s│%s\n' "$(_bdim)" "$(_br)" "$lbar" "$lemp" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s %s%s│%s\n' "$(_bdim)" "$(_br)" "$lbar" "$lemp" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s %s%s│%s\n' "$(_bdim)" "$(_br)" "$lbar" "$lemp" "$(_bdim)" "$(_br)"
            ;;
        floating|island)
            local fbar="$(_bdim)    $(_bblue)$(_bbold)████████████████████$(_bdim)    $(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$bar_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s                                    %s│%s\n' "$(_bdim)" "$(_br)" "$(_bdim)" "$(_br)"
            printf '  %s│%s    %s%s    %s│%s\n' "$(_bdim)" "$(_br)" "$(_bblue)$(_bbold)████████████████████$(_br)" "$(_bdim)" "$(_bdim)" "$(_br)"
            ;;
        zen|minimal)
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            printf '  %s│%s%s%s│%s\n' "$(_bdim)" "$(_br)" "$emp_line" "$(_bdim)" "$(_br)"
            ;;
    esac

    printf '  %s\n\n' "$border_b"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_bar_layout() {
    local position=""
    local list_layouts=0
    local preview=1
    local no_reload=0

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)    list_layouts=1  ;;
            --no-preview) preview=0       ;;
            --no-reload)  no_reload=1     ;;
            top|bottom|left|right|top-bottom|floating|minimal|zen|gaming|island)
                position="$arg"
                ;;
        esac
    done

    bar_section "🗂️ " "Bar Layout" "$(_blav)"

    if [[ $list_layouts -eq 1 ]]; then
        printf '\n  %sAvailable layouts:%s\n\n' "$(_bbold)" "$(_br)"
        printf '  %s%-14s  %s%s\n' "$(_bdim)" "Name" "Description" "$(_br)"
        printf '  %s%s%s\n' "$(_bdim)" "$(printf '─%.0s' $(seq 1 55))" "$(_br)"

        local current_layout="?"
        [[ -f "${_BAR_STATE_DIR}/current-layout" ]] && \
            current_layout="$(cat "${_BAR_STATE_DIR}/current-layout")"

        for layout in "${!_LAYOUT_POSITIONS[@]}"; do
            local cur_marker=""
            [[ "$layout" == "$current_layout" ]] && \
                cur_marker="${_bgreen}  ← current${_br}"

            printf '  %s%-14s%s  %s%s%s%s\n' \
                "$(_bsky)" "$layout" "$(_br)" \
                "$(_bdim)" "${_LAYOUT_DESCRIPTIONS[$layout]}" "$(_br)" \
                "$cur_marker"
        done | sort

        printf '\n  %sUsage: ash bar layout <name>%s\n' "$(_bdim)" "$(_br)"
        printf '\n'
        return 0
    fi

    # Interactive picker if no position given
    if [[ -z "$position" ]]; then
        if command -v fzf &>/dev/null; then
            local layout_input
            layout_input="$(
                for layout in "${!_LAYOUT_POSITIONS[@]}"; do
                    printf '%-14s  %s\n' "$layout" "${_LAYOUT_DESCRIPTIONS[$layout]}"
                done | sort | \
                fzf \
                    --prompt "  🗂️   Select layout: " \
                    --height=15 \
                    --border=rounded \
                    --color="hl:$(_bmauve | sed 's/\033\[//;s/m//')" \
                    --header="ESC to cancel" \
                    2>/dev/null | awk '{print $1}'
            )"
            position="${layout_input:-}"
        fi

        if [[ -z "$position" ]]; then
            bar_info "No layout specified"
            bar_info "Run: ash bar layout --list"
            printf '\n'; return 0
        fi
    fi

    # Validate
    if [[ -z "${_LAYOUT_POSITIONS[$position]:-}" ]]; then
        bar_fail "Unknown layout: ${position}"
        bar_info "Valid layouts: ${!_LAYOUT_POSITIONS[*]}"
        printf '\n'; return 1
    fi

    bar_kv "Backend"   "$BAR_BACKEND"
    bar_kv "Layout"    "$position"
    bar_kv "Desc"      "${_LAYOUT_DESCRIPTIONS[$position]}"

    # ASCII preview
    [[ $preview -eq 1 ]] && _layout_ascii_preview "$position"

    # Apply layout
    bar_step "Applying layout: ${position}..."

    case "$BAR_BACKEND" in
        waybar)  _layout_waybar_apply "$position" ;;
        ags)     _layout_ags_apply    "$position" ;;
        eww)     _layout_eww_apply    "$position" ;;
        *)       bar_warn "Layout switching not supported for ${BAR_BACKEND}" ;;
    esac

    # Reload to apply
    if [[ $no_reload -eq 0 ]] && bar_is_running "$BAR_BACKEND"; then
        bar_step "Reloading bar to apply layout..."
        _bar_load_sub reload &>/dev/null || true
        ash_bar_reload --quiet 2>/dev/null || true
    fi

    bar_notify "🗂️  Bar Layout" "${BAR_BACKEND}: ${position}"

    printf '\n'
}
