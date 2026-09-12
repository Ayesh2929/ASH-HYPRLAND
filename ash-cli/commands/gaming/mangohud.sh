#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  gaming mangohud                                          ║
# ║  MangoHUD overlay: toggle • presets • custom config • benchmark mode             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_GAMING_MANGOHUD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_GAMING_MANGOHUD_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PRESET CONFIGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _MANGO_PRESETS=(
    [minimal]="fps,frametime,cpu_load,gpu_load"
    [performance]="fps,frametime,cpu_load,gpu_load,cpu_temp,gpu_temp,ram,vram"
    [full]="fps,frametime,cpu_load,gpu_load,cpu_temp,gpu_temp,ram,vram,battery,network,io_read,io_write,engine_version,vulkan_driver,gpu_name,cpu_power,gpu_power"
    [benchmark]="fps,frametime,frame_timing,benchmark"
    [overlay]="fps,cpu_load,gpu_load,ram,gpu_temp"
    [streaming]="fps,frametime,cpu_load,gpu_load,cpu_temp"
)

_mango_write_preset() {
    local preset="$1"
    local cfg_file="$2"

    local metrics="${_MANGO_PRESETS[$preset]:-}"
    if [[ -z "$metrics" ]]; then
        gm_fail "Unknown preset: ${preset}"
        gm_info "Available: ${!_MANGO_PRESETS[*]}"
        return 1
    fi

    mkdir -p "$(dirname "$cfg_file")" 2>/dev/null || true

    cat > "$cfg_file" << CONF
# ASH MangoHUD Config — ${preset} preset
# Generated: $(date -Iseconds)

${metrics//,/$'\n'}

background_alpha=0.5
font_size=20
position=top-left
text_color=cdd6f4
background_color=1e1e2e
cpu_color=89b4fa
gpu_color=a6e3a1
fps_color=cba6f7
frametime_color=fab387
engine_color=f38ba8
CONF

    gm_ok "Config written: ${cfg_file}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL CONFIG EDITOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mango_show_config() {
    local cfg="${1:-$_GM_MANGOHUD_CFG}"

    if [[ ! -f "$cfg" ]]; then
        gm_info "No MangoHUD config found at: ${cfg}"
        gm_info "Create with: ash gaming mangohud preset minimal"
        return 0
    fi

    gm_section "📄" "MangoHUD Config" "$(_gdim)"
    gm_kv "File" "$cfg"

    printf '\n'
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^# ]]; then
            printf '  %s%s%s\n' "$(_gdim)" "$line" "$(_gr)"
        elif [[ "$line" =~ ^[a-z] ]]; then
            local key="${line%%=*}"
            local val="${line#*=}"
            printf '  %s%-28s%s %s%s%s\n' \
                "$(_gteal)" "$key" "$(_gr)" \
                "$(_ggreen)" "$val" "$(_gr)"
        else
            printf '  %s\n' "$line"
        fi
    done < "$cfg"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BENCHMARK MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mango_benchmark_summary() {
    # Parse MangoHUD benchmark CSV files
    local bench_dir="${XDG_DATA_HOME:-$HOME/.local/share}/MangoHud"
    [[ -d "$bench_dir" ]] || { gm_info "No benchmark data found"; return 0; }

    gm_section "📈" "Benchmark Results" "$(_ggreen)"

    find "$bench_dir" -name '*.csv' -newer "$bench_dir" 2>/dev/null | \
    sort -r | head -5 | \
    while IFS= read -r csv_file; do
        local game_name
        game_name="$(basename "$csv_file" .csv)"
        gm_kv "Game" "$game_name"

        if command -v python3 &>/dev/null; then
            python3 - "$csv_file" << 'PYEOF'
import csv, sys, os, statistics

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R = '' if no_color else '\033[0m'
GRN = '' if no_color else '\033[38;2;166;227;161m'
YELL = '' if no_color else '\033[38;2;249;226;175m'
RED  = '' if no_color else '\033[38;2;243;139;168m'
DIM  = '' if no_color else '\033[38;2;108;112;134m'

try:
    with open(sys.argv[1]) as f:
        reader = csv.DictReader(f)
        fps_vals = []
        for row in reader:
            try:
                fps_vals.append(float(row.get('fps',0) or 0))
            except:
                pass

    if fps_vals:
        avg = statistics.mean(fps_vals)
        p1  = statistics.quantiles(fps_vals, n=100)[0]
        p01 = min(fps_vals)
        mx  = max(fps_vals)

        def fps_color(fps):
            if fps >= 120: return GRN
            if fps >= 60:  return YELL
            return RED

        print(f'  {DIM}  Average  :{R} {fps_color(avg)}{avg:.1f}{R} {DIM}fps{R}')
        print(f'  {DIM}  1% Low   :{R} {fps_color(p1)}{p1:.1f}{R} {DIM}fps{R}')
        print(f'  {DIM}  0.1% Low :{R} {fps_color(p01)}{p01:.1f}{R} {DIM}fps{R}')
        print(f'  {DIM}  Max      :{R} {fps_color(mx)}{mx:.1f}{R} {DIM}fps{R}')
except Exception as e:
    print(f'  Could not parse: {e}')
PYEOF
        fi
        printf '\n'
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_gaming_mangohud() {
    local action="status"
    local preset=""
    local target_app=""

    for arg in "${@:-}"; do
        case "$arg" in
            status|info)                   action="status"    ;;
            toggle|on|off|enable|disable)  action="toggle"   ;;
            preset|-p)                     action="preset"   ;;
            config|edit)                   action="config"   ;;
            benchmark|bench)               action="bench"    ;;
            run|-r)                        action="run"      ;;
            minimal|performance|full|overlay|streaming|benchmark)
                preset="$arg"
                [[ "$action" != "run" ]] && action="preset"
                ;;
            *)
                [[ "$action" == "run" ]] && target_app="$arg" || preset="$arg"
                ;;
        esac
    done

    gm_section "📊" "MangoHUD" "$(_gteal)"

    # Check installation
    if ! command -v mangohud &>/dev/null; then
        gm_fail "MangoHUD not installed"
        gm_info "Install: paru -S mangohud"
        printf '\n'; return 1
    fi

    local mango_ver
    mango_ver="$(mangohud --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
    gm_kv "Version"    "v${mango_ver}"
    gm_kv "Config"     "${_GM_MANGOHUD_CFG/#$HOME/~}"
    gm_kv "Preset"     "${preset:-default}"

    case "$action" in
        status)
            gm_section "📋" "Config Preview" "$(_gdim)"
            _mango_show_config
            ;;

        preset)
            if [[ -z "$preset" ]]; then
                printf '\n  %sAvailable presets:%s\n' "$(_gdim)" "$(_gr)"
                for p in "${!_MANGO_PRESETS[@]}"; do
                    local metrics="${_MANGO_PRESETS[$p]}"
                    printf '    %s%-12s%s  %s%s%s\n' \
                        "$(_gsky)" "$p" "$(_gr)" \
                        "$(_gdim)" "${metrics:0:50}" "$(_gr)"
                done | sort

                printf '\n  %sSelect preset: %s' "$(_gyellow)" "$(_gr)"
                read -r preset
            fi

            _mango_write_preset "$preset" "$_GM_MANGOHUD_CFG"
            gm_notify "📊 MangoHUD" "Preset applied: ${preset}"
            ;;

        toggle)
            # Toggle via env var hint
            local env_file="${_GM_CONFIG_DIR}/mangohud.env"
            if [[ -f "$env_file" ]] && grep -q 'MANGOHUD=1' "$env_file" 2>/dev/null; then
                echo "MANGOHUD=0" > "$env_file"
                gm_ok "MangoHUD: DISABLED"
                gm_notify "📊 MangoHUD" "Overlay disabled"
            else
                echo "MANGOHUD=1" > "$env_file"
                gm_ok "MangoHUD: ENABLED"
                gm_info "Launch games with: MANGOHUD=1 <game>"
                gm_info "Or use Steam launch options: MANGOHUD=1 %command%"
                gm_notify "📊 MangoHUD" "Overlay enabled"
            fi
            ;;

        config)
            local editor="${EDITOR:-nvim}"
            mkdir -p "$(dirname "$_GM_MANGOHUD_CFG")" 2>/dev/null || true
            [[ ! -f "$_GM_MANGOHUD_CFG" ]] && \
                _mango_write_preset "performance" "$_GM_MANGOHUD_CFG"
            gm_step "Opening: ${_GM_MANGOHUD_CFG}"
            "$editor" "$_GM_MANGOHUD_CFG"
            ;;

        bench)
            _mango_benchmark_summary
            ;;

        run)
            if [[ -z "$target_app" ]]; then
                gm_fail "No application specified"
                gm_info "Usage: ash gaming mangohud run <application>"
                printf '\n'; return 1
            fi
            gm_step "Launching with MangoHUD: ${target_app}..."
            [[ -n "$preset" ]] && _mango_write_preset "$preset" "$_GM_MANGOHUD_CFG"
            MANGOHUD=1 MANGOHUD_CONFIG="$_GM_MANGOHUD_CFG" \
                mangohud "$target_app" 2>/dev/null &
            gm_ok "Launched: ${target_app}  (PID: $!)"
            ;;
    esac

    printf '\n'
}
