#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor mirror                                           ║
# ║  Clone/mirror display to another output with resolution matching                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_MIRROR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_MIRROR_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_mirror_hyprland() {
    local source="$1"  target="$2"

    # Get source dimensions
    local src_w src_h src_hz
    local src_json
    src_json="$(hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
mons = json.load(sys.stdin)
src = next((m for m in mons if m['name'] == '${source}'), None)
if src:
    print(src.get('width',1920), src.get('height',1080), src.get('refreshRate',60))
" 2>/dev/null)"

    read -r src_w src_h src_hz <<< "$src_json"
    src_w="${src_w:-1920}"
    src_h="${src_h:-1080}"
    src_hz="${src_hz:-60}"

    mon_kv "Source"     "${source}  (${src_w}x${src_h}@${src_hz}Hz)"
    mon_kv "Target"     "$target"
    mon_kv "Mirror mode" "Same position as source"

    mon_step "Setting mirror mode via Hyprland..."

    # In Hyprland, mirroring = same resolution, same position
    hyprctl keyword monitor \
        "${target},${src_w}x${src_h}@${src_hz},0x0,1,mirror,${source}" \
        2>/dev/null && \
        mon_ok "Mirror active: ${source} → ${target}"
}

_mirror_wlr() {
    local source="$1"  target="$2"

    # Get source resolution
    local src_mode
    src_mode="$(wlr-randr 2>/dev/null | \
        awk -v s="$source" 'p && /current/{print $1; p=0} $0~s{p=1}' | head -1)"

    mon_step "Mirroring via wlr-randr..."
    wlr-randr --output "$target" --same-as "$source" 2>/dev/null && \
        mon_ok "Mirror active: ${source} → ${target}"
}

_mirror_xrandr() {
    local source="$1"  target="$2"
    mon_step "Mirroring via xrandr..."
    xrandr --output "$target" --same-as "$source" 2>/dev/null && \
        mon_ok "Mirror active: ${source} → ${target}"
}

_mirror_disable() {
    local target="$1"
    mon_step "Disabling mirror on: ${target}..."

    case "$MON_BACKEND" in
        hyprland)
            # Restore to its own position
            hyprctl keyword monitor "${target},preferred,auto,1" 2>/dev/null
            ;;
        wlr-randr)
            wlr-randr --output "$target" --auto 2>/dev/null
            ;;
        xrandr)
            xrandr --output "$target" --auto 2>/dev/null
            ;;
    esac

    mon_ok "Mirror disabled on: ${target}"
}

ash_monitor_mirror() {
    local source=""  target=""  disable=0

    for arg in "${@:-}"; do
        case "$arg" in
            --disable|-d) disable=1   ;;
            --source=*)   source="${arg#*=}" ;;
            --target=*)   target="${arg#*=}" ;;
            *)
                if [[ -z "$source" ]]; then source="$arg"
                elif [[ -z "$target" ]]; then target="$arg"
                fi
                ;;
        esac
    done

    mon_section "🪞" "Mirror / Clone Display" "$(_mlav)"
    mon_kv "Backend" "$MON_BACKEND"

    # Interactive picker if not specified
    if [[ -z "$source" ]] || [[ -z "$target" ]]; then
        local -a names=()
        mapfile -t names < <(mon_get_names)

        if [[ ${#names[@]} -lt 2 ]]; then
            mon_fail "Need at least 2 monitors for mirroring"
            printf '\n'; return 1
        fi

        if [[ -z "$source" ]]; then
            printf '\n  %sAvailable monitors:%s\n' "$(_mdim)" "$(_mr)"
            local i=0
            for name in "${names[@]}"; do
                (( i++ )) || true
                printf '    %s%d%s  %s%s%s\n' \
                    "$(_mpeach)" "$i" "$(_mr)" "$(_msky)" "$name" "$(_mr)"
            done

            printf '  %sSource monitor [1-%d]: %s' \
                "$(_myellow)" "${#names[@]}" "$(_mr)"
            local choice
            read -r choice
            [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 )) && \
                (( choice <= ${#names[@]} )) && \
                source="${names[$((choice-1))]}" || {
                mon_fail "Invalid selection"; return 1
            }
        fi

        if [[ -z "$target" ]]; then
            printf '  %sTarget monitor [1-%d]: %s' \
                "$(_myellow)" "${#names[@]}" "$(_mr)"
            local choice2
            read -r choice2
            [[ "$choice2" =~ ^[0-9]+$ ]] && (( choice2 >= 1 )) && \
                (( choice2 <= ${#names[@]} )) && \
                target="${names[$((choice2-1))]}" || {
                mon_fail "Invalid selection"; return 1
            }
        fi
    fi

    [[ "$source" == "$target" ]] && {
        mon_fail "Source and target cannot be the same monitor"
        return 1
    }

    if [[ $disable -eq 1 ]]; then
        _mirror_disable "$target"
        printf '\n'; return 0
    fi

    case "$MON_BACKEND" in
        hyprland) _mirror_hyprland "$source" "$target" ;;
        wlr-randr|sway) _mirror_wlr "$source" "$target"   ;;
        xrandr)   _mirror_xrandr   "$source" "$target" ;;
        *)
            mon_fail "Mirror not supported for backend: ${MON_BACKEND}"
            return 1
            ;;
    esac

    [[ "${ASH_MON_SAVE:-0}" -eq 1 ]] && mon_save_config
    mon_notify "🪞 Mirror Active" "${source} → ${target}"

    printf '\n'
}
