#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot monitor                                             ║
# ║  Capture specific monitor by name / index / all monitors                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_MONITOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_MONITOR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_mon_list_hyprctl() {
    command -v hyprctl &>/dev/null || return 1
    python3 - << 'PYEOF' 2>/dev/null
import json, subprocess
r = subprocess.run(['hyprctl', 'monitors', '-j'],
                   capture_output=True, text=True)
for m in json.loads(r.stdout):
    name  = m.get('name','?')
    x     = m.get('x',0)
    y     = m.get('y',0)
    w     = m.get('width',0)
    h     = m.get('height',0)
    hz    = m.get('refreshRate',0)
    scale = m.get('scale',1)
    act   = m.get('focused',False)
    print(f"{name}\t{x},{y} {w}x{h}\t{hz:.0f}Hz\t{scale}x\t{'★ active' if act else ''}")
PYEOF
}

_mon_list_wlr_randr() {
    command -v wlr-randr &>/dev/null || return 1
    wlr-randr 2>/dev/null | grep -E '^\w|^\s+\d' | head -20
}

ash_shot_monitor() {
    local target_monitor=""
    local all_monitors=0
    local fmt="${ASH_SHOT_FORMAT:-png}"

    for arg in "${@:-}"; do
        case "$arg" in
            --all|-a)        all_monitors=1  ;;
            --monitor=*|-m=*) target_monitor="${arg#*=}" ;;
            -m)              : ;;  # next arg consumed below
            *)               [[ -z "$target_monitor" ]] && target_monitor="$arg" ;;
        esac
    done

    shot_section "🖥️ " "Monitor Capture" "$(_sblue)"

    shot_check_wayland || return 1

    # List available monitors
    shot_kv "Listing monitors" ""
    printf '\n'

    local monitor_data
    monitor_data="$(_mon_list_hyprctl 2>/dev/null || _mon_list_wlr_randr 2>/dev/null || echo '')"

    if [[ -n "$monitor_data" ]]; then
        printf '  %s%-12s %-22s %-8s %-5s %s%s\n' \
            "$(_sdim)" "Name" "Geometry" "Rate" "Scale" "Status" "$(_sr)"
        printf '  %s%s%s\n' "$(_sdim)" "$(printf '─%.0s' $(seq 1 60))" "$(_sr)"

        while IFS=$'\t' read -r name geom rate scale status; do
            local name_color
            [[ "$status" =~ "active" ]] && name_color="$(_sgreen)" || name_color="$(_ssky)"
            printf '  %s%-12s%s %-22s %-8s %-5s %s%s%s\n' \
                "$name_color" "$name" "$(_sr)" \
                "$geom" "$rate" "$scale" \
                "$(_sgreen)" "$status" "$(_sr)"
        done <<< "$monitor_data"
        printf '\n'
    fi

    # If no target specified and not --all, prompt
    if [[ -z "$target_monitor" ]] && [[ $all_monitors -eq 0 ]]; then
        if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            # Auto-detect active monitor
            target_monitor="$(hyprctl monitors -j 2>/dev/null | \
                python3 -c "
import json,sys
mons = json.load(sys.stdin)
active = next((m for m in mons if m.get('focused')), mons[0] if mons else None)
print(active['name'] if active else '')
" 2>/dev/null || echo '')"
        fi

        if [[ -z "$target_monitor" ]]; then
            printf '  %sEnter monitor name (or leave blank for active): %s' \
                "$(_syellow)" "$(_sr)"
            read -r target_monitor
        fi
    fi

    if [[ $all_monitors -eq 1 ]]; then
        # Capture all monitors separately
        local -a monitor_names=()
        mapfile -t monitor_names < <(
            printf '%s\n' "$monitor_data" | awk -F'\t' '{print $1}' | grep -v '^$'
        )

        for mon in "${monitor_names[@]}"; do
            shot_step "Capturing monitor: ${mon}..."
            local out_file
            out_file="$(shot_filename "monitor-${mon}" "$fmt")"

            if command -v grim &>/dev/null; then
                grim -o "$mon" "$out_file" 2>/dev/null && {
                    local sz
                    sz="$(du -sh "$out_file" 2>/dev/null | cut -f1)"
                    shot_ok "${mon}: ${out_file##*/}  (${sz})"
                    shot_log "$out_file" "monitor" "$mon"
                } || shot_fail "${mon}: capture failed"
            fi
        done
    else
        local output_file
        output_file="$(shot_filename "monitor-${target_monitor:-main}" "$fmt")"

        shot_step "Capturing monitor: ${target_monitor:-active}..."

        if command -v grim &>/dev/null; then
            local grim_args=( "grim" )
            [[ -n "$target_monitor" ]] && grim_args+=( "-o" "$target_monitor" )
            grim_args+=( "$output_file" )
            "${grim_args[@]}" 2>/dev/null || {
                shot_fail "Capture failed"
                return 1
            }
        else
            shot_fail "grim required for monitor capture"
            return 1
        fi

        local size
        size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
        shot_ok "Monitor screenshot saved"
        shot_kv "File" "$output_file"
        shot_kv "Size" "$size"

        [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && shot_copy_to_clipboard "$output_file"
        [[ "${ASH_SHOT_UPLOAD:-0}" -eq 1 ]]    && ash_shot_upload "$output_file"

        shot_log "$output_file" "monitor" "${target_monitor:-active}"
        shot_notify "🖥️  Monitor Captured" "${target_monitor:-active}  •  ${size}" \
            "$output_file"
    fi

    printf '\n'
}
