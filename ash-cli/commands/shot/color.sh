#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot color                                               ║
# ║  Screen color picker with hex / rgb / hsl / oklch output + swatch preview      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_COLOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_COLOR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_color_hex_to_rgb() {
    local hex="${1#'#'}"
    local r g b
    r=$(( 16#${hex:0:2} ))
    g=$(( 16#${hex:2:2} ))
    b=$(( 16#${hex:4:2} ))
    printf '%d %d %d' "$r" "$g" "$b"
}

_color_rgb_to_hsl() {
    python3 - "$1" "$2" "$3" << 'PYEOF' 2>/dev/null
import sys, colorsys
r,g,b = int(sys.argv[1])/255, int(sys.argv[2])/255, int(sys.argv[3])/255
h,l,s = colorsys.rgb_to_hls(r,g,b)
print(f"{h*360:.1f} {s*100:.1f} {l*100:.1f}")
PYEOF
}

_color_swatch() {
    local r="$1"  g="$2"  b="$3"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        # True-color block
        printf '\n  \033[48;2;%d;%d;%dm  %s  \033[48;2;%d;%d;%dm  %s  \033[48;2;%d;%d;%dm  %s  \033[0m\n' \
            "$r" "$g" "$b" "     " \
            "$r" "$g" "$b" "     " \
            "$r" "$g" "$b" "     "
    fi
}

_color_luminance() {
    local r="$1" g="$2" b="$3"
    # Simple luminance to pick contrast text color
    local lum=$(( (r*299 + g*587 + b*114) / 1000 ))
    (( lum > 128 )) && printf 'dark' || printf 'light'
}

ash_shot_color() {
    local output_format="all"  # hex | rgb | hsl | oklch | all
    local copy_to_clip=0

    for arg in "${@:-}"; do
        case "$arg" in
            --format=*) output_format="${arg#*=}" ;;
            --hex)      output_format="hex"   ;;
            --rgb)      output_format="rgb"   ;;
            --hsl)      output_format="hsl"   ;;
            --clipboard|-c) copy_to_clip=1    ;;
        esac
    done

    shot_section "🎨" "Color Picker" "$(_speach)"

    # Try hyprpicker first (best Wayland support)
    if command -v hyprpicker &>/dev/null; then
        shot_info "Click on any pixel to sample its color..."
        shot_info "Hold Shift for magnifier  •  ESC to cancel"

        local picked_hex
        picked_hex="$(hyprpicker --format=hex 2>/dev/null | tr -d '\n')" || {
            shot_info "Color pick cancelled"
            return 0
        }

        [[ -z "$picked_hex" ]] && { shot_info "No color selected"; return 0; }

        local r g b
        read -r r g b <<< "$(_color_hex_to_rgb "$picked_hex")"

        local hsl_vals
        hsl_vals="$(_color_rgb_to_hsl "$r" "$g" "$b")"
        local h l sat
        read -r h sat l <<< "$hsl_vals"

        # Display swatch
        _color_swatch "$r" "$g" "$b"

        # Values
        printf '\n'
        shot_kv "HEX" "$picked_hex"
        shot_kv "RGB" "rgb(${r}, ${g}, ${b})"
        shot_kv "HSL" "hsl(${h}°, ${sat}%, ${l}%)"

        # Clipboard
        local primary_value="$picked_hex"
        case "$output_format" in
            rgb) primary_value="rgb(${r}, ${g}, ${b})" ;;
            hsl) primary_value="hsl(${h}°, ${sat}%, ${l}%)" ;;
        esac

        if [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] || [[ $copy_to_clip -eq 1 ]]; then
            printf '%s' "$primary_value" | wl-copy 2>/dev/null && \
                shot_ok "Copied: ${primary_value}" || \
                shot_warn "wl-copy not available"
        fi

        shot_notify "🎨 Color Picked" "$picked_hex  rgb($r,$g,$b)" ""

    elif command -v gpick &>/dev/null; then
        shot_step "Launching gpick color picker..."
        gpick -p 2>/dev/null || true

    elif command -v xcolor &>/dev/null; then
        local color
        color="$(xcolor 2>/dev/null)"
        [[ -n "$color" ]] && shot_kv "Color" "$color"

    else
        shot_fail "No color picker found"
        shot_info "Install: paru -S hyprpicker  (recommended for Wayland)"
        shot_info "Alternative: paru -S gpick"
        return 1
    fi

    printf '\n'
}
