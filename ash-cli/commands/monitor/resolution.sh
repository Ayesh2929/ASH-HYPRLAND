#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor resolution                                       ║
# ║  Change resolution with mode listing, custom input, and validation              ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_RESOLUTION_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_RESOLUTION_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  AVAILABLE MODES FETCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_res_get_modes() {
    local monitor_name="$1"

    case "$MON_BACKEND" in
        hyprland)
            hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
mons = json.load(sys.stdin)
m = next((x for x in mons if x.get('name') == '${monitor_name}'), None)
if m:
    for mode in m.get('availableModes', []):
        print(mode)
" 2>/dev/null
            ;;
        xrandr)
            xrandr 2>/dev/null | awk -v out="$monitor_name" \
                'p && /^[[:space:]]+[0-9]+x[0-9]+/{print $1} \
                 /^'$monitor_name' /{p=1} /^[A-Z]/{p=0}'
            ;;
        wlr-randr)
            wlr-randr 2>/dev/null | awk \
                -v out="$monitor_name" \
                '/^'$monitor_name'/{p=1} p && /[0-9]+x[0-9]+@/{
                    gsub(/@.*/,""); print $1
                    gsub(/[^0-9x]/,"")
                } /^[A-Z]/{p=0}'
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL MODE PICKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_res_mode_badge() {
    local mode="$1"
    python3 -c "
mode = '${mode}'.replace('@','@').split('@')[0]
try:
    w,h = map(int, mode.split('x'))
    if w >= 3840:  quality = '4K'
    elif w >= 2560: quality = 'QHD'
    elif w >= 1920: quality = 'FHD'
    elif w >= 1280: quality = 'HD'
    elif w >= 1024: quality = 'XGA'
    else:           quality = 'Low'
    print(quality)
except:
    print('')
" 2>/dev/null
}

_res_display_modes() {
    local monitor_name="$1"
    local current_w current_h

    # Get current resolution
    local current_res
    current_res="$(mon_get_monitors_json | python3 -c "
import json, sys
mons = json.load(sys.stdin)
m = next((x for x in mons if x.get('name') == '${monitor_name}'), {})
w = m.get('width', 0)
h = m.get('height', 0)
print(f'{w}x{h}')
" 2>/dev/null)"

    printf '\n  %sAvailable resolutions for %s%s%s:\n\n' \
        "$(_mdim)" "$(_msky)" "$monitor_name" "$(_mr)"
    printf '  %s%-12s %-8s %-6s %-6s%s\n' \
        "$(_mdim)" "Resolution" "Quality" "Ratio" "Status" "$(_mr)"
    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 45))" "$(_mr)"

    local i=0
    local -a modes_list=()

    while IFS= read -r mode; do
        [[ -z "$mode" ]] && continue
        local res="${mode%%@*}"
        [[ "$res" =~ ^[0-9]+x[0-9]+$ ]] || continue

        # Deduplicate
        local dup=0
        for existing in "${modes_list[@]:-}"; do
            [[ "$existing" == "$res" ]] && dup=1 && break
        done
        [[ $dup -eq 1 ]] && continue
        modes_list+=("$res")

        (( i++ )) || true
        local quality
        quality="$(_res_mode_badge "$res")"

        # Aspect ratio
        local w="${res%%x*}"  h="${res##*x}"
        local ratio_str=""
        if command -v python3 &>/dev/null; then
            ratio_str="$(python3 -c "
import math
w,h = $w,$h
g = math.gcd(w,h)
print(f'{w//g}:{h//g}')
" 2>/dev/null)"
        fi

        local current_mark=""
        [[ "$res" == "$current_res" ]] && \
            current_mark="${_mgreen} ← current${_mr}"

        local quality_color
        case "$quality" in
            4K)  quality_color="$(_mmauve)" ;;
            QHD) quality_color="$(_mblue)"  ;;
            FHD) quality_color="$(_mteal)"  ;;
            HD)  quality_color="$(_mgreen)" ;;
            *)   quality_color="$(_mdim)"   ;;
        esac

        printf '  %s%3d%s  %s%-12s%s %-8s %-6s%s%s\n' \
            "$(_mpeach)" "$i" "$(_mr)" \
            "$(_msky)" "$res" "$(_mr)" \
            "${quality_color}${quality}${_mr}" \
            "${ratio_str}" \
            "$current_mark"
    done < <(_res_get_modes "$monitor_name" | sort -t'x' -k1 -rn | uniq)

    printf '%s' "${modes_list[@]:-}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_monitor_resolution() {
    local monitor_name=""  target_res=""  list_only=0

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)     list_only=1  ;;
            --monitor=*)   monitor_name="${arg#*=}" ;;
            [0-9]*x[0-9]*) target_res="$arg" ;;
            *)
                if [[ -z "$monitor_name" ]] && \
                   [[ "$arg" =~ ^[A-Za-z] ]]; then
                    monitor_name="$arg"
                fi
                ;;
        esac
    done

    mon_section "📐" "Monitor Resolution" "$(_mmauve)"
    mon_kv "Backend" "$MON_BACKEND"

    # Auto-select active monitor
    if [[ -z "$monitor_name" ]]; then
        monitor_name="$(mon_get_monitors_json | python3 -c "
import json,sys
mons=json.load(sys.stdin)
focused=next((m['name'] for m in mons if m.get('focused')), None)
if not focused and mons: focused=mons[0]['name']
print(focused or '')
" 2>/dev/null)"
    fi

    [[ -z "$monitor_name" ]] && {
        mon_fail "No monitor found"
        return 1
    }

    mon_kv "Monitor" "$monitor_name"

    # Get current resolution
    local cur_w cur_h cur_hz cur_scale cur_x cur_y
    local cur_data
    cur_data="$(mon_get_monitors_json | python3 -c "
import json,sys
mons=json.load(sys.stdin)
m=next((x for x in mons if x.get('name')=='${monitor_name}'),{})
print(m.get('width',1920), m.get('height',1080),
      m.get('refreshRate',60), m.get('scale',1),
      m.get('x',0), m.get('y',0))
" 2>/dev/null)"
    read -r cur_w cur_h cur_hz cur_scale cur_x cur_y <<< "$cur_data"

    mon_kv "Current"  "${cur_w}x${cur_h}@${cur_hz}Hz"

    # Show available modes
    local -a modes_arr=()
    mapfile -t modes_arr < <(_res_get_modes "$monitor_name" | \
        grep -oP '\d+x\d+' | sort -t'x' -k1 -rn | uniq)

    if [[ $list_only -eq 1 ]]; then
        _res_display_modes "$monitor_name" &>/dev/null
        return 0
    fi

    if [[ -z "$target_res" ]]; then
        # Interactive picker
        if command -v fzf &>/dev/null; then
            local fzf_list
            fzf_list="$(for m in "${modes_arr[@]:-}"; do
                local qual w h
                qual="$(_res_mode_badge "$m")"
                printf '%-14s  %-6s\n' "$m" "$qual"
            done)"

            target_res="$(printf '%s\n' "$fzf_list" | \
                fzf --prompt "  📐  Resolution: " \
                    --height=15 \
                    --border=rounded \
                    --color="hl:$(_mmauve | sed 's/\033\[//;s/m//')" \
                    --header="Current: ${cur_w}x${cur_h}  ESC=cancel" \
                    2>/dev/null | awk '{print $1}' || echo '')"
        else
            _res_display_modes "$monitor_name" &>/dev/null
            printf '\n  %sEnter resolution (e.g. 1920x1080): %s' \
                "$(_myellow)" "$(_mr)"
            read -r target_res
        fi
    fi

    [[ -z "$target_res" ]] && { mon_info "No resolution selected"; return 0; }

    # Validate format
    if ! [[ "$target_res" =~ ^[0-9]+x[0-9]+$ ]]; then
        mon_fail "Invalid format: ${target_res}  (expected: WxH)"
        return 1
    fi

    local new_w="${target_res%%x*}"  new_h="${target_res##*x}"

    mon_kv "Applying" "${new_w}x${new_h}@${cur_hz}Hz"

    mon_apply "$monitor_name" "$new_w" "$new_h" "$cur_hz" \
        "$cur_x" "$cur_y" "$cur_scale" && \
        mon_ok "Resolution set: ${new_w}x${new_h}" || {
        mon_fail "Failed to set resolution"
        return 1
    }

    [[ "${ASH_MON_SAVE:-0}" -eq 1 ]] && mon_save_config
    mon_notify "📐 Resolution" "${monitor_name}: ${new_w}x${new_h}"

    printf '\n'
}
