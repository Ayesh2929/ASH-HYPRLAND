#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor refresh-rate                                     ║
# ║  Change refresh rate with mode validation, VRR info, and smart suggestions       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_REFRESH_RATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_REFRESH_RATE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  AVAILABLE REFRESH RATES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rr_get_rates() {
    local monitor_name="$1"  target_res="$2"

    case "$MON_BACKEND" in
        hyprland)
            # NOTE: the JSON arrives on stdin via the pipe, so the program is fed on
            # fd 3 instead of stdin — `python3 - <<EOF` would let the heredoc
            # replace the pipe and json.load(sys.stdin) would read nothing.
            hyprctl monitors -j 2>/dev/null | python3 /dev/fd/3 3<< PYEOF
import json, sys

mons = json.load(sys.stdin)
m = next((x for x in mons if x.get('name') == '${monitor_name}'), None)
if not m:
    sys.exit(1)

# Filter modes matching target resolution
target = '${target_res}'
rates = set()
for mode in m.get('availableModes', []):
    parts = mode.split('@')
    if len(parts) == 2:
        res   = parts[0].strip()
        hz    = float(parts[1].strip().rstrip('Hz').strip())
        if not target or res == target:
            rates.add(hz)

for r in sorted(rates, reverse=True):
    print(f'{r:.3f}')
PYEOF
            ;;
        xrandr)
            xrandr 2>/dev/null | awk -v out="$monitor_name" -v res="$target_res" \
                '
                /^'$monitor_name'/{p=1; next}
                p && /^\s+[0-9]+x[0-9]+/{
                    split($1, a, "x")
                    r = a[1]"x"a[2]
                    if (r == res || res == "") {
                        for (i=2; i<=NF; i++) {
                            hz = $i
                            gsub(/[*+]/, "", hz)
                            print hz
                        }
                    }
                }
                p && /^[A-Z]/{p=0}
                ' | sort -rn | uniq
            ;;
        wlr-randr)
            wlr-randr 2>/dev/null | awk \
                -v out="$monitor_name" -v res="$target_res" \
                'BEGIN{p=0}
                /^'$monitor_name'/{p=1; next}
                p && /[0-9]+x[0-9]+@/{
                    match($0, /([0-9]+x[0-9]+)@([0-9.]+)/, arr)
                    if (arr[1] == res || res == "") print arr[2]
                }
                p && /^[A-Z]/{p=0}' | sort -rn | uniq
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  REFRESH RATE BADGE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rr_badge() {
    local hz="$1"
    local hz_int="${hz%.*}"

    local badge_color badge_label
    if   (( hz_int >= 360 )); then badge_label="360Hz+  🚀"; badge_color="$(_mmauve)"
    elif (( hz_int >= 240 )); then badge_label="240Hz   ⚡"; badge_color="$(_mpink)"
    elif (( hz_int >= 165 )); then badge_label="165Hz   🔥"; badge_color="$(_mpeach)"
    elif (( hz_int >= 144 )); then badge_label="144Hz   🎮"; badge_color="$(_mgreen)"
    elif (( hz_int >= 120 )); then badge_label="120Hz   📺"; badge_color="$(_mteal)"
    elif (( hz_int >=  60 )); then badge_label="60Hz    ✓";  badge_color="$(_mblue)"
    else                           badge_label="${hz}Hz  ⚠"; badge_color="$(_mdim)"
    fi

    printf '%s%s%s' "$badge_color" "$badge_label" "$(_mr)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VRR STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rr_vrr_info() {
    local monitor_name="$1"

    if [[ "$MON_BACKEND" == "hyprland" ]]; then
        local vrr_state
        vrr_state="$(mon_get_monitors_json | python3 -c "
import json,sys
mons=json.load(sys.stdin)
m=next((x for x in mons if x.get('name')=='${monitor_name}'),{})
vrr = m.get('vrr', False)
vrr_cap = m.get('vrrCapable', vrr)
print('yes' if vrr else 'no', 'yes' if vrr_cap else 'no')
" 2>/dev/null)"
        local vrr_on vrr_cap
        read -r vrr_on vrr_cap <<< "$vrr_state"

        if [[ "$vrr_cap" == "yes" ]]; then
            mon_kv "VRR capable" "$(mon_badge " ✓ Yes " "$(_mgreen)")"
            if [[ "$vrr_on" == "yes" ]]; then
                mon_kv "VRR active" "$(mon_badge " ✓ Enabled " "$(_mgreen)")"
            else
                mon_kv "VRR active" "$(mon_badge " Disabled " "$(_mdim)")"
                mon_info "Enable VRR: hyprctl keyword monitor ${monitor_name},vrr,1"
            fi
        else
            mon_kv "VRR capable" "$(mon_badge " ✗ No " "$(_mdim)")"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RATE PICKER (fzf / list)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_rr_display_rates() {
    local monitor_name="$1"  cur_hz="$2"  target_res="$3"
    local -a rates=()
    mapfile -t rates < <(_rr_get_rates "$monitor_name" "$target_res")

    if [[ ${#rates[@]} -eq 0 ]]; then
        mon_info "No modes found  (listing all rates)"
        mapfile -t rates < <(_rr_get_rates "$monitor_name" "")
    fi

    printf '\n  %sAvailable refresh rates for %s%s%s @ %s:\n\n' \
        "$(_mdim)" "$(_msky)" "$monitor_name" "$(_mr)" "$target_res"
    printf '  %s%-6s  %-20s  %s%s\n' \
        "$(_mdim)" "Rate" "Quality" "Status" "$(_mr)"
    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 42))" "$(_mr)"

    local i=0
    for rate in "${rates[@]}"; do
        [[ -z "$rate" ]] && continue
        (( i++ )) || true
        local badge
        badge="$(_rr_badge "$rate")"
        local cur_mark=""
        local rate_int="${rate%.*}"
        local cur_int="${cur_hz%.*}"
        [[ "$rate_int" == "$cur_int" ]] && \
            cur_mark="${_mgreen}  ← current${_mr}"

        printf '  %s%3d%s  %s%-8s%s  %s%s\n' \
            "$(_mpeach)" "$i" "$(_mr)" \
            "$(_msky)" "$rate" "$(_mr)" \
            "$badge" "$cur_mark"
    done

    printf '%s\n' "${rates[@]:-}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_monitor_refresh_rate() {
    local monitor_name=""  target_hz=""  list_only=0

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)     list_only=1  ;;
            --monitor=*)   monitor_name="${arg#*=}" ;;
            [0-9]*)        target_hz="$arg" ;;
            *)
                if [[ -z "$monitor_name" ]] && \
                   [[ "$arg" =~ ^[A-Za-z] ]]; then
                    monitor_name="$arg"
                fi
                ;;
        esac
    done

    mon_section "⚡" "Monitor Refresh Rate" "$(_mpeach)"
    mon_kv "Backend" "$MON_BACKEND"

    # Auto-detect active monitor
    if [[ -z "$monitor_name" ]]; then
        monitor_name="$(mon_get_monitors_json | python3 -c "
import json,sys
mons=json.load(sys.stdin)
f=next((m['name'] for m in mons if m.get('focused')),None)
if not f and mons: f=mons[0]['name']
print(f or '')
" 2>/dev/null)"
    fi

    [[ -z "$monitor_name" ]] && { mon_fail "No monitor found"; return 1; }

    mon_kv "Monitor" "$monitor_name"

    # Get current state
    local cur_data
    cur_data="$(mon_get_monitors_json | python3 -c "
import json,sys
mons=json.load(sys.stdin)
m=next((x for x in mons if x.get('name')=='${monitor_name}'),{})
print(m.get('width',1920), m.get('height',1080), m.get('refreshRate',60),
      m.get('scale',1), m.get('x',0), m.get('y',0))
" 2>/dev/null)"

    local cur_w cur_h cur_hz cur_scale cur_x cur_y
    read -r cur_w cur_h cur_hz cur_scale cur_x cur_y <<< "$cur_data"

    mon_kv "Current" "${cur_w}x${cur_h}@${cur_hz}Hz"

    # VRR info
    _rr_vrr_info "$monitor_name"

    # List available rates for current resolution
    local cur_res="${cur_w}x${cur_h}"
    local -a rates_arr=()
    mapfile -t rates_arr < <(_rr_get_rates "$monitor_name" "$cur_res")

    if [[ $list_only -eq 1 ]]; then
        _rr_display_rates "$monitor_name" "$cur_hz" "$cur_res" &>/dev/null
        return 0
    fi

    if [[ -z "$target_hz" ]]; then
        # Interactive picker
        if command -v fzf &>/dev/null && [[ ${#rates_arr[@]} -gt 0 ]]; then
            target_hz="$(for r in "${rates_arr[@]}"; do
                badge="$(_rr_badge "$r" | sed 's/\033\[[^m]*m//g')"
                printf '%-10s  %s\n' "$r" "$badge"
            done | \
                fzf --prompt "  ⚡  Refresh rate: " \
                    --height=15 \
                    --border=rounded \
                    --color="hl:$(_mpeach | sed 's/\033\[//;s/m//')" \
                    --header="Current: ${cur_hz}Hz at ${cur_res}  ESC=cancel" \
                    2>/dev/null | awk '{print $1}' || echo '')"
        else
            _rr_display_rates "$monitor_name" "$cur_hz" "$cur_res" &>/dev/null
            printf '\n  %sEnter refresh rate (e.g. 144): %s' \
                "$(_myellow)" "$(_mr)"
            read -r target_hz
        fi
    fi

    [[ -z "$target_hz" ]] && { mon_info "No rate selected"; return 0; }

    # Strip .000 suffix if user entered plain number
    target_hz="${target_hz%.000}"

    local new_hz="${target_hz}"

    # Validate
    if ! [[ "$new_hz" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        mon_fail "Invalid refresh rate: ${new_hz}"
        return 1
    fi

    mon_kv "Applying" "${cur_w}x${cur_h}@${new_hz}Hz"

    local badge
    badge="$(_rr_badge "$new_hz")"
    mon_kv "Quality" "$badge"

    # Check if rate is available for this resolution
    local rate_valid=0
    for r in "${rates_arr[@]:-}"; do
        local r_int="${r%.*}"
        local t_int="${new_hz%.*}"
        [[ "$r_int" == "$t_int" ]] && rate_valid=1 && break
    done

    if [[ $rate_valid -eq 0 ]] && [[ ${#rates_arr[@]} -gt 0 ]]; then
        mon_warn "Rate ${new_hz}Hz may not be supported at ${cur_res}"
        mon_info "Supported rates: ${rates_arr[*]:-}"
        if [[ "${ASH_FLAG_YES:-0}" -ne 1 ]]; then
            printf '  %sContinue anyway? [y/N] %s' "$(_myellow)" "$(_mr)"
            local ans; read -r ans
            [[ "${ans,,}" != "y" ]] && { mon_info "Cancelled"; return 0; }
        fi
    fi

    mon_apply "$monitor_name" "$cur_w" "$cur_h" "$new_hz" \
        "$cur_x" "$cur_y" "$cur_scale" && \
        mon_ok "Refresh rate set: ${new_hz}Hz" || {
        mon_fail "Failed to set refresh rate"
        return 1
    }

    [[ "${ASH_MON_SAVE:-0}" -eq 1 ]] && mon_save_config
    mon_notify "⚡ Refresh Rate" "${monitor_name}: ${new_hz}Hz"

    printf '\n'
}
