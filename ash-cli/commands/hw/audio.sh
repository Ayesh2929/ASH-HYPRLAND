#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║   █████╗ ██╗   ██╗██████╗ ██╗ ██████╗                                           ║
# ║  ██╔══██╗██║   ██║██╔══██╗██║██╔═══██╗                                          ║
# ║  ███████║██║   ██║██║  ██║██║██║   ██║                                          ║
# ║  ██╔══██║██║   ██║██║  ██║██║██║   ██║                                          ║
# ║  ██║  ██║╚██████╔╝██████╔╝██║╚██████╔╝                                          ║
# ║  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝                                           ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  hw audio                                                 ║
# ║  PipeWire graph • ALSA cards • sinks/sources • sample rates • latency            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_AUDIO_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_AUDIO_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PIPEWIRE INFO
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_audio_pipewire_info() {
    command -v pw-cli &>/dev/null || return 1

    local pw_info
    pw_info="$(pw-cli info 0 2>/dev/null || echo '')"
    [[ -z "$pw_info" ]] && return 1

    printf '%s' "$pw_info"
}

_audio_pipewire_version() {
    pipewire --version 2>/dev/null | grep -oP '[\d]+\.[\d.]+' | head -1 || echo '?'
}

_audio_pw_dump_nodes() {
    command -v pw-dump &>/dev/null || return 1
    pw-dump 2>/dev/null | \
    python3 -c "
import json,sys
data = json.load(sys.stdin)
for obj in data:
    t = obj.get('type','')
    if 'Node' not in t: continue
    props = obj.get('info',{}).get('props',{})
    media_class = props.get('media.class','')
    name        = props.get('node.description') or props.get('node.name','?')
    sample_rate = props.get('audio.rate','')
    channels    = props.get('audio.channels','')
    fmt         = props.get('audio.format','')
    state       = obj.get('info',{}).get('state','?')
    if media_class:
        print(f'{media_class}|{name}|{sample_rate}|{channels}|{fmt}|{state}')
" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  ALSA CARDS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_audio_alsa_cards() {
    cat /proc/asound/cards 2>/dev/null | \
    awk '/^\s+[0-9]/{
        num=$1
        getline
        desc=$0
        gsub(/^[[:space:]]+/,"",desc)
        printf "%d|%s\n",num,desc
    }'
}

_audio_alsa_pcm() {
    cat /proc/asound/pcm 2>/dev/null | head -20 || echo ''
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  WPCTL STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_audio_wpctl_sinks() {
    command -v wpctl &>/dev/null || return 1

    local wpctl_out
    wpctl_out="$(wpctl status 2>/dev/null || echo '')"
    [[ -z "$wpctl_out" ]] && return 1

    printf '\n  \033[38;2;108;112;134mSinks (outputs):\033[0m\n'
    local in_sinks=0
    while IFS= read -r line; do
        if [[ "$line" =~ "Sinks:" ]]; then
            in_sinks=1; continue
        fi
        if [[ "$line" =~ "Sources:" ]]; then
            in_sinks=0
            printf '\n  \033[38;2;108;112;134mSources (inputs):\033[0m\n'
            continue
        fi
        if [[ "$line" =~ "Filters:" ]] || [[ "$line" =~ "Streams:" ]]; then
            in_sinks=0; continue
        fi

        if (( in_sinks )); then
            local star=""
            [[ "$line" == *'*'* ]] && star=$'\033[1;38;2;166;227;161m★ DEFAULT  \033[0m'
            local clean
            clean="$(printf '%s' "$line" | sed 's/\*//' | sed 's/^[[:space:]]*//')"
            [[ -n "$clean" ]] && \
                printf '  %s\033[38;2;205;214;244m%s\033[0m\n' "$star" "$clean"
        fi
    done <<< "$wpctl_out"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL VOLUME METER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_audio_volume_display() {
    command -v wpctl &>/dev/null || return 0

    local vol_out
    vol_out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo '')"
    [[ -z "$vol_out" ]] && return 0

    local vol_num
    vol_num="$(printf '%s' "$vol_out" | grep -oP '[\d.]+')"
    local vol_pct
    vol_pct="$(hw_div "$vol_num" 1 0)"
    local muted=0
    printf '%s' "$vol_out" | grep -q '\[MUTED\]' && muted=1

    local bar_width=30
    local filled=$(( vol_pct * bar_width / 100 ))
    (( filled > bar_width )) && filled=$bar_width
    local empty=$(( bar_width - filled ))

    local vol_color
    if   [[ $muted -eq 1 ]]; then vol_color=$'\033[38;2;108;112;134m'
    elif (( vol_pct >= 100 )); then vol_color=$'\033[38;2;243;139;168m'
    elif (( vol_pct >= 80 ));  then vol_color=$'\033[38;2;249;226;175m'
    else                            vol_color=$'\033[38;2;166;227;161m'
    fi

    local mute_icon
    [[ $muted -eq 1 ]] && mute_icon="🔇" || mute_icon="🔊"

    printf '\n  %s  ' "$mute_icon"
    printf '%s' "$vol_color"
    printf '%.0s█' $(seq 1 "$filled")
    printf '\033[38;2;88;91;112m'
    printf '%.0s░' $(seq 1 "$empty")
    printf '\033[0m'
    printf '  \033[1m%d%%\033[0m' "$vol_pct"
    [[ $muted -eq 1 ]] && printf '  \033[38;2;243;139;168mMUTED\033[0m'
    printf '\n'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PIPEWIRE NODE TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_audio_node_table() {
    local nodes
    nodes="$(_audio_pw_dump_nodes 2>/dev/null || echo '')"
    [[ -z "$nodes" ]] && {
        printf '  \033[38;2;108;112;134m(pw-dump unavailable)\033[0m\n'
        return 0
    }

    printf '\n  \033[38;2;108;112;134m%-30s %-25s %-8s %s\033[0m\n' \
        "Class" "Name" "Rate" "State"
    printf '  \033[38;2;88;91;112m%s\033[0m\n' \
        "$(printf '─%.0s' $(seq 1 75))"

    while IFS='|' read -r class name rate channels fmt state; do
        [[ -z "$class" ]] && continue

        local class_color
        case "$class" in
            *Sink*)   class_color=$'\033[38;2;137;180;250m' ;;
            *Source*) class_color=$'\033[38;2;166;227;161m' ;;
            *)        class_color=$'\033[38;2;148;226;213m' ;;
        esac

        local state_color
        case "$state" in
            running) state_color=$'\033[38;2;166;227;161m' ;;
            idle)    state_color=$'\033[38;2;108;112;134m' ;;
            error)   state_color=$'\033[38;2;243;139;168m' ;;
            *)       state_color=$'\033[38;2;205;214;244m' ;;
        esac

        printf '  %s%-30s\033[0m \033[38;2;205;214;244m%-25s\033[0m %-8s %s%-8s\033[0m\n' \
            "$class_color" "${class:0:29}" \
            "${name:0:24}" \
            "${rate:+${rate}Hz}" \
            "$state_color" "$state"

    done <<< "$nodes"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_audio() {
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--short" ]] && short=1
    done

    hw_section "🔊" "Audio Subsystem" $'\033[38;2;250;179;135m'

    # ── PipeWire ──────────────────────────────────────────────────────────────────
    if pgrep -x pipewire &>/dev/null; then
        local pw_ver
        pw_ver="$(_audio_pipewire_version)"

        hw_kv "PipeWire" "v${pw_ver}  \033[38;2;166;227;161m●  running\033[0m"

        # Runtime info
        local pw_info
        pw_info="$(_audio_pipewire_info 2>/dev/null || echo '')"
        if [[ -n "$pw_info" ]]; then
            local pw_clock pw_latency pw_quantum
            pw_clock="$(   printf '%s' "$pw_info" | grep 'default.clock.rate'    | head -1 | grep -oP '\d+')"
            pw_quantum="$( printf '%s' "$pw_info" | grep 'default.clock.quantum' | head -1 | grep -oP '\d+')"
            [[ -n "$pw_clock"   ]] && hw_kv "Sample rate"  "${pw_clock} Hz"
            [[ -n "$pw_quantum" ]] && hw_kv "Quantum"      "$pw_quantum  (buffer size)"
            if [[ -n "$pw_clock" ]] && [[ -n "$pw_quantum" ]]; then
                local latency_ms
                latency_ms="$(hw_div "$(( pw_quantum * 1000 ))" "${pw_clock:-48000}" 2)"
                hw_kv "Latency"  "${latency_ms} ms"
            fi
        fi
    else
        hw_kv "PipeWire" $'\033[38;2;243;139;168m✗  not running\033[0m'
    fi

    pgrep -x wireplumber &>/dev/null && \
        hw_kv "WirePlumber" $'\033[38;2;166;227;161m●  running\033[0m' || \
        hw_kv "WirePlumber" $'\033[38;2;243;139;168m✗  not running\033[0m'

    # ── Volume ────────────────────────────────────────────────────────────────────
    hw_section "🔉" "Volume" $'\033[38;2;249;226;175m'
    _audio_volume_display

    # ── ALSA Cards ────────────────────────────────────────────────────────────────
    hw_section "🎛" "ALSA Sound Cards" $'\033[38;2;148;226;213m'

    local card_found=0
    while IFS='|' read -r num desc; do
        [[ -z "$num" ]] && continue
        printf '  \033[38;2;108;112;134m%2d:\033[0m  \033[38;2;205;214;244m%s\033[0m\n' \
            "$num" "$desc"
        (( card_found++ )) || true
    done < <(_audio_alsa_cards 2>/dev/null)

    (( card_found == 0 )) && \
        printf '  \033[38;2;108;112;134mNo ALSA cards detected\033[0m\n'

    # ── WirePlumber device list ────────────────────────────────────────────────────
    hw_section "📋" "Sinks & Sources" $'\033[38;2;137;220;235m'
    _audio_wpctl_sinks

    if [[ $short -eq 0 ]]; then
        hw_section "🔬" "PipeWire Node Graph" $'\033[38;2;203;166;247m'
        _audio_node_table
    fi

    hw_divider
}
