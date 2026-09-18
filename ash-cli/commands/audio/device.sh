#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  audio device                                             ║
# ║  List and switch audio sinks/sources with fzf picker and profile management     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_AUD_DEVICE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_AUD_DEVICE_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE LISTER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dev_list_sinks() {
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl status 2>/dev/null | \
            awk '/Sinks:/{p=1; next} /Sources:|Filters:|Streams:|Clients:/{p=0} p && NF'
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl list sinks short 2>/dev/null
    fi
}

_dev_list_sources() {
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl status 2>/dev/null | \
            awk '/Sources:/{p=1; next} /Filters:|Streams:|Clients:|Sinks:/{p=0} p && NF'
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl list sources short 2>/dev/null | grep -v 'monitor'
    fi
}

_dev_get_default_sink_id() {
    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl status 2>/dev/null | \
            awk '/Sinks:/{p=1} p && /\*/{match($0,/[0-9]+/); print substr($0,RSTART,RLENGTH); exit}'
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        pactl get-default-sink 2>/dev/null
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE TABLE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dev_render_table() {
    local title="$1"  raw_data="$2"

    printf '\n  %s%s%s\n' "$(_abold)" "$title" "$(_ar)"
    printf '  %s%s%s\n' "$(_adim)" "$(printf '─%.0s' $(seq 1 60))" "$(_ar)"

    local count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local is_default=0
        [[ "$line" =~ ^\* ]] || [[ "$line" =~ "│ *" ]] && is_default=1

        local id name state vol
        if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
            id="$(printf '%s' "$line" | grep -oP '^\s*\*?\s*\K\d+' | head -1)"
            name="$(printf '%s' "$line" | sed 's/^[^.]*\. //' | sed 's/ \[.*\]//' | cut -c1-45)"
            vol="$(printf '%s' "$line" | grep -oP '\d+\.\d+' | head -1)"
        else
            id="$(printf '%s' "$line" | awk '{print $1}')"
            name="$(printf '%s' "$line" | awk '{print $2}' | cut -c1-45)"
            state="$(printf '%s' "$line" | awk '{print $5}')"
        fi

        (( count++ )) || true

        local star_col line_col
        if [[ $is_default -eq 1 ]] || printf '%s' "$line" | grep -q '^\s*\*'; then
            star_col="$(_agreen)"
            line_col="$(_agreen)"
        else
            star_col="$(_adim)"
            line_col="$(_ablue)"
        fi

        # Device type icon
        local dev_icon
        if printf '%s' "${name,,}" | grep -qE 'headphone|headset|earphone'; then
            dev_icon="🎧"
        elif printf '%s' "${name,,}" | grep -qE 'speaker|output|loopback'; then
            dev_icon="🔊"
        elif printf '%s' "${name,,}" | grep -qE 'micro|input|capture'; then
            dev_icon="🎤"
        elif printf '%s' "${name,,}" | grep -qE 'hdmi|display|monitor'; then
            dev_icon="🖥️ "
        elif printf '%s' "${name,,}" | grep -qE 'bluetooth|bt'; then
            dev_icon="📡"
        else
            dev_icon="🔌"
        fi

        printf '  %s%s%s  %s%3s%s  %s%s%s\n' \
            "$star_col" "$(printf '%s' "$line" | grep -q '^\s*\*' && echo '★' || echo '○')" "$(_ar)" \
            "$(_adim)" "$id" "$(_ar)" \
            "$line_col" "${dev_icon} ${name}" "$(_ar)"

    done <<< "$raw_data"

    printf '\n  %s%d device(s)%s\n' "$(_adim)" "$count" "$(_ar)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  DEVICE SWITCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dev_switch() {
    local device_id="$1"  mode="${2:-sink}"

    aud_step "Switching ${mode} to device ID: ${device_id}..."

    if [[ $AUD_HAS_WPCTL -eq 1 ]]; then
        wpctl set-default "$device_id" 2>/dev/null && \
            aud_ok "Default ${mode} set to: ${device_id}" || {
            aud_fail "Failed to switch device"
            return 1
        }
    elif [[ $AUD_HAS_PACTL -eq 1 ]]; then
        local cmd
        [[ "$mode" == "sink" ]] && cmd="set-default-sink" || cmd="set-default-source"
        pactl "$cmd" "$device_id" 2>/dev/null && \
            aud_ok "Default ${mode} set to: ${device_id}"
    else
        aud_fail "No audio control tool available"
        return 1
    fi

    aud_notify "🎧 Audio Device" "Switched ${mode} to device ${device_id}"
}

_dev_fzf_pick() {
    local mode="$1"  raw_data="$2"

    command -v fzf &>/dev/null || return 1

    local selected
    selected="$(printf '%s\n' "$raw_data" | \
        fzf \
            --prompt "  🎧  Select ${mode}: " \
            --height=15 \
            --border=rounded \
            --color="hl:$(_amauve | sed 's/\033\[//;s/m//')" \
            --header="↵=switch  ESC=cancel" \
            2>/dev/null | grep -oP '^\s*\*?\s*\K\d+' | head -1 || echo '')"

    printf '%s' "$selected"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PIPEWIRE NODE INFO
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dev_pw_nodes() {
    command -v pw-dump &>/dev/null || return 0

    printf '\n  %sPipeWire Nodes:%s\n' "$(_adim)" "$(_ar)"
    pw-dump 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for obj in data:
    t = obj.get('type','')
    if 'Node' not in t:
        continue
    props = obj.get('info',{}).get('props',{})
    mc    = props.get('media.class','')
    name  = props.get('node.description') or props.get('node.name','?')
    rate  = props.get('audio.rate','')
    state = obj.get('info',{}).get('state','?')
    if mc:
        col = $'\033[38;2;137;180;250m' if 'Sink' in mc else $'\033[38;2;166;227;161m'
        r = $'\033[0m'
        d = $'\033[38;2;108;112;134m'
        print(f'  {col}{mc:<30}{r}  {name[:35]:<35}  {d}{rate}Hz  {state}{r}')
" 2>/dev/null | head -20 || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_audio_device() {
    local action="list"  mode="sink"  device_id=""

    for arg in "${@:-}"; do
        case "$arg" in
            list|-l)         action="list"    ;;
            switch|set|-s)   action="switch"  ;;
            source)          mode="source"    ;;
            sink)            mode="sink"      ;;
            nodes|pw)        action="nodes"   ;;
            [0-9]*)          device_id="$arg" ;;
        esac
    done

    aud_section "🎧" "Audio Devices" "$(_asapph)"
    aud_kv "Backend" "$AUD_BACKEND"

    if [[ "$action" == "nodes" ]]; then
        _dev_pw_nodes
        printf '\n'; return 0
    fi

    # Fetch device lists
    local sinks_data sources_data
    sinks_data="$(_dev_list_sinks)"
    sources_data="$(_dev_list_sources)"

    if [[ "$action" == "list" ]]; then
        _dev_render_table "🔊 Sinks (Outputs)" "$sinks_data"
        _dev_render_table "🎤 Sources (Inputs)" "$sources_data"

        # PipeWire extra info
        if pgrep -x pipewire &>/dev/null && [[ $AUD_HAS_WPCTL -eq 1 ]]; then
            aud_section "🌊" "PipeWire Status" "$(_adim)"
            wpctl status 2>/dev/null | head -30 | while IFS= read -r line; do
                printf '  %s%s%s\n' "$(_adim)" "$line" "$(_ar)"
            done
        fi

        printf '\n'
        return 0
    fi

    # Switch device
    if [[ "$action" == "switch" ]]; then
        local raw_data
        [[ "$mode" == "sink" ]] && raw_data="$sinks_data" || raw_data="$sources_data"

        if [[ -z "$device_id" ]]; then
            # Interactive picker
            device_id="$(_dev_fzf_pick "$mode" "$raw_data")"
        fi

        if [[ -z "$device_id" ]]; then
            # Numbered fallback
            _dev_render_table "🎧 Select ${mode}" "$raw_data"
            printf '  %sEnter device ID: %s' "$(_ayellow)" "$(_ar)"
            read -r device_id
        fi

        [[ -z "$device_id" ]] && { aud_info "No device selected"; return 0; }
        _dev_switch "$device_id" "$mode"
    fi

    printf '\n'
}
