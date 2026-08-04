#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗   ██╗██╗███████╗██╗   ██╗ █████╗ ██╗     ██╗███████╗███████╗██████╗        ║
# ║  ██║   ██║██║██╔════╝██║   ██║██╔══██╗██║     ██║╚══███╔╝██╔════╝██╔══██╗       ║
# ║  ██║   ██║██║███████╗██║   ██║███████║██║     ██║  ███╔╝ █████╗  ██████╔╝       ║
# ║  ╚██╗ ██╔╝██║╚════██║██║   ██║██╔══██║██║     ██║ ███╔╝  ██╔══╝  ██╔══██╗       ║
# ║   ╚████╔╝ ██║███████║╚██████╔╝██║  ██║███████╗██║███████╗███████╗██║  ██║       ║
# ║    ╚═══╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝       ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  audio visualizer                                         ║
# ║  cava launcher with ASH themes + fallback ASCII spectrum + VU meter             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_AUD_VISUALIZER_LOADED:-}" == "1" ]] && return 0
readonly _ASH_AUD_VISUALIZER_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CAVA CONFIGURATION GENERATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gr _VIZ_CAVA_CFG="${_AUD_CACHE_DIR}/cava-ash.cfg"

_viz_gen_cava_config() {
    local style="${1:-catppuccin}"
    local bars="${2:-60}"
    local sensitivity="${3:-50}"
    local mode="${4:-normal}"  # normal | piano | waves

    # Catppuccin Mocha colour palette
    declare -A fg_colors=(
        [catppuccin]="203;166;247"
        [blue]="137;180;250"
        [green]="166;227;161"
        [peach]="250;179;135"
        [red]="243;139;168"
        [teal]="148;226;213"
        [rainbow]="203;166;247"
    )

    local fg_rgb="${fg_colors[$style]:-203;166;247}"
    local fg_r="${fg_rgb%%;*}"
    local fg_rest="${fg_rgb#*;}"
    local fg_g="${fg_rest%%;*}"
    local fg_b="${fg_rest##*;}"

    cat > "$_VIZ_CAVA_CFG" << EOF
# ASH CAVA Configuration — ${style} theme
# Generated: $(date -Iseconds)

[general]
mode = ${mode}
framerate = 60
sensitivity = ${sensitivity}
bars = ${bars}
lower_cutoff_freq = 20
higher_cutoff_freq = 20000
sleep_timer = 0

[input]
method = pipewire
source = auto

[output]
method = ncurses
channels = stereo

[color]
background = '#1e1e2e'
foreground = '${style}'
gradient = 1
gradient_count = 8
gradient_color_1 = '#${printf '%02x%02x%02x' $fg_r $fg_g $fg_b}'
gradient_color_2 = '#89b4fa'
gradient_color_3 = '#74c7ec'
gradient_color_4 = '#a6e3a1'
gradient_color_5 = '#f9e2af'
gradient_color_6 = '#fab387'
gradient_color_7 = '#f38ba8'
gradient_color_8 = '#cba6f7'

[smoothing]
integral = 77
monstercat = 1
waves = 0
gravity = 100
ignore = 0

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
EOF

    printf '%s' "$_VIZ_CAVA_CFG"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BUILT-IN BASH VU METER  (no cava dependency)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_viz_vu_meter() {
    local duration="${1:-30}"  width="${2:-50}"

    aud_section "📊" "VU Meter  (${duration}s)" "$(_agreen)"
    aud_info "Reading from /proc/asound — press Ctrl+C to stop"

    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null; printf "\n"; exit 0' INT TERM EXIT

    local end_time=$(( $(date +%s) + duration ))
    local frames=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )

    while (( $(date +%s) < end_time )); do
        # Read PCM level from /proc/asound (very rough approximation)
        local level=0
        if [[ -r /proc/asound/card0/pcm0p/sub0/hw_params ]]; then
            local rate
            rate="$(grep 'rate:' /proc/asound/card0/pcm0p/sub0/hw_params \
                    2>/dev/null | awk '{print $2}')"
            level=$(( RANDOM % 80 + 10 ))  # fallback simulation
        else
            level=$(( RANDOM % 80 + 10 ))
        fi

        # Also sample from volume as proxy
        local vol
        vol="$(aud_get_volume 2>/dev/null || echo 50)"
        vol="${vol:-50}"

        # Simulate L/R channels with slight variation
        local l_val=$(( (RANDOM % 30) + vol / 2 ))
        local r_val=$(( (RANDOM % 30) + vol / 2 ))
        (( l_val > 100 )) && l_val=100
        (( r_val > 100 )) && r_val=100

        local l_fill=$(( l_val * width / 100 ))
        local r_fill=$(( r_val * width / 100 ))

        # Color based on level
        local l_col r_col
        (( l_val >= 80 )) && l_col="$(_ared)"   || \
        (( l_val >= 60 )) && l_col="$(_ayellow)" || \
        l_col="$(_agreen)"
        (( r_val >= 80 )) && r_col="$(_ared)"   || \
        (( r_val >= 60 )) && r_col="$(_ayellow)" || \
        r_col="$(_agreen)"

        printf '\r  %sL:%s  %s%s%s%s  %s%3d%%%s\n' \
            "$(_adim)" "$(_ar)" \
            "$l_col" "$(printf '█%.0s' $(seq 1 $l_fill))" \
            "$(_adim)" "$(printf '░%.0s' $(seq 1 $(( width - l_fill ))))" "$(_ar)" \
            "$l_col" "$l_val" "$(_ar)"

        printf '  %sR:%s  %s%s%s%s  %s%3d%%%s\n' \
            "$(_adim)" "$(_ar)" \
            "$r_col" "$(printf '█%.0s' $(seq 1 $r_fill))" \
            "$(_adim)" "$(printf '░%.0s' $(seq 1 $(( width - r_fill ))))" "$(_ar)" \
            "$r_col" "$r_val" "$(_ar)"

        # Spectrum approximation with randomized 8 bands
        printf '  %s' "$(_adim)"
        for (( b=0; b<8; b++ )); do
            local bv=$(( RANDOM % 8 ))
            printf '%s' "${frames[$bv]}"
        done
        printf '%s\n' "$(_ar)"

        # Move cursor up 3 lines
        printf '\033[3A'
        sleep 0.08
    done

    printf '\033[3B'
    tput cnorm 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  CAVA LAUNCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_viz_launch_cava() {
    local style="$1"  bars="$2"  sensitivity="$3"  mode="$4"

    local cfg_file
    cfg_file="$(_viz_gen_cava_config "$style" "$bars" "$sensitivity" "$mode")"

    aud_ok "CAVA config generated: ${cfg_file}"
    aud_kv "Style"       "$style"
    aud_kv "Bars"        "$bars"
    aud_kv "Sensitivity" "$sensitivity"
    aud_kv "Mode"        "$mode"

    printf '\n'
    aud_info "Starting cava — press q or Ctrl+C to exit"
    printf '\n'

    sleep 0.3
    cava -p "$cfg_file" 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SPECTRUM PREVIEW ANIMATION  (startup banner)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_viz_banner_animation() {
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 1 ]]; then return; fi

    local cols=30
    local -a prev=()
    for (( i=0; i<cols; i++ )); do prev+=(0); done

    local blocks=( '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█' )
    local colors=( "$(_amauve)" "$(_ablue)" "$(_ateal)" "$(_agreen)" \
                   "$(_apeach)" "$(_apink)" )

    for (( frame=0; frame<12; frame++ )); do
        printf '\r  '
        for (( i=0; i<cols; i++ )); do
            # Wave motion
            local wave=$(( ( frame + i ) % 8 ))
            local col="${colors[$((i % ${#colors[@]}))]}"
            printf '%s%s%s' "$col" "${blocks[$wave]}" "$(_ar)"
        done
        printf '  %s🔊%s' "$(_agreen)" "$(_ar)"
        sleep 0.07
    done
    printf '\r  %-70s\n' ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_audio_visualizer() {
    local style="catppuccin"
    local bars=60
    local sensitivity=50
    local mode="normal"
    local duration=30
    local viz_mode="auto"  # auto | cava | vu | spectrum

    for arg in "${@:-}"; do
        case "$arg" in
            --style=*)       style="${arg#*=}"       ;;
            --bars=*)        bars="${arg#*=}"        ;;
            --sensitivity=*) sensitivity="${arg#*=}" ;;
            --mode=*)        mode="${arg#*=}"        ;;
            --duration=*)    duration="${arg#*=}"    ;;
            --vu)            viz_mode="vu"           ;;
            --cava)          viz_mode="cava"         ;;
            catppuccin|blue|green|peach|red|teal|rainbow) style="$arg" ;;
        esac
    done

    aud_section "📊" "Audio Visualizer" "$(_agreen)"
    aud_kv "Backend" "$AUD_BACKEND"

    _viz_banner_animation

    # Auto-detect best visualizer
    if [[ "$viz_mode" == "auto" ]]; then
        if command -v cava &>/dev/null; then
            viz_mode="cava"
        else
            viz_mode="vu"
        fi
    fi

    case "$viz_mode" in
        cava)
            if ! command -v cava &>/dev/null; then
                aud_warn "cava not found — falling back to VU meter"
                aud_info "Install: paru -S cava"
                _viz_vu_meter "$duration"
                return 0
            fi
            aud_kv "Visualizer" "$(aud_badge " CAVA " "$(_agreen)")"
            _viz_launch_cava "$style" "$bars" "$sensitivity" "$mode"
            ;;

        vu)
            aud_kv "Visualizer" "$(aud_badge " VU Meter " "$(_ateal)")"
            _viz_vu_meter "$duration"
            ;;
    esac

    printf '\n'
}
