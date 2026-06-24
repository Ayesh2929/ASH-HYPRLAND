#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Audio Device Switcher Script                      ║
# ║                                                                              ║
# ║  Full PipeWire/PulseAudio audio device management via wpctl + pactl.       ║
# ║  List sinks/sources, set defaults, control volume per-device, manage        ║
# ║  profiles, create virtual sinks, monitor streams.                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly MAX_VOL=150            # Max volume percentage
readonly VOL_STEP=5             # Volume step per scroll/key
readonly BAR_WIDTH=10           # Volume bar character width

# ══════════════════════════════════════════════════════════════════════════════
# §02  BACKEND DETECTION
# ══════════════════════════════════════════════════════════════════════════════

detect_backend() {
    if command -v wpctl &>/dev/null && \
       systemctl --user is-active pipewire &>/dev/null 2>&1; then
        echo "pipewire"
    elif command -v pactl &>/dev/null; then
        echo "pulseaudio"
    else
        echo "none"
    fi
}

readonly BACKEND=$(detect_backend)

# ══════════════════════════════════════════════════════════════════════════════
# §03  DEVICE TYPE → ICON
# ══════════════════════════════════════════════════════════════════════════════

device_icon() {
    local name="${1,,}" desc="${2,,}"
    local combined="${name} ${desc}"

    if   [[ "$combined" =~ headphone|headphone|wh-|xm|qc ]]; then echo "󰋋"
    elif [[ "$combined" =~ earbud|airpod|pods|buds ]];        then echo "󰟗"
    elif [[ "$combined" =~ headset|jabra|plantronics ]];      then echo "󰋎"
    elif [[ "$combined" =~ bluetooth|bt-|a2dp|bthsa ]];       then echo "󰐻"
    elif [[ "$combined" =~ hdmi|display|monitor|dp- ]];       then echo "󰘚"
    elif [[ "$combined" =~ speaker|soundbar|boom|jbl ]];      then echo "󰓃"
    elif [[ "$combined" =~ usb|usb-audio|rode|blue|focusrite ]]; then echo "󰢹"
    elif [[ "$combined" =~ microphone|mic|input ]];           then echo "󰍬"
    elif [[ "$combined" =~ analog|stereo|internal|built-in ]];then echo "󰕾"
    elif [[ "$combined" =~ virtual|loop|null|pipe ]];         then echo "󰑗"
    elif [[ "$combined" =~ spdif|optical|coax ]];             then echo "󰒅"
    else                                                           echo "󰎛"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  VOLUME BAR RENDERER
# ══════════════════════════════════════════════════════════════════════════════

volume_bar() {
    local vol="$1"    # 0-100+
    local width="${2:-$BAR_WIDTH}"

    # Normalize to 0-100 for display
    local display_vol="$vol"
    [[ "$display_vol" -gt 100 ]] && display_vol=100

    local filled=$(( display_vol * width / 100 ))
    [[ $filled -gt $width ]] && filled=$width
    local empty=$(( width - filled ))

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done

    echo "$bar"
}

volume_icon() {
    local vol="$1"
    if   [[ "$vol" -eq 0 ]];   then echo "󰖁"
    elif [[ "$vol" -le 33 ]];  then echo "󰕿"
    elif [[ "$vol" -le 66 ]];  then echo "󰖀"
    else                            echo "󰕾"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  PIPEWIRE/WPCTL DEVICE LISTING
# ══════════════════════════════════════════════════════════════════════════════

get_default_sink() {
    wpctl get-volume @DEFAULT_SINK@ 2>/dev/null | awk '{print NR}' &>/dev/null
    pactl info 2>/dev/null | grep "Default Sink" | cut -d: -f2 | xargs || \
    wpctl status 2>/dev/null | grep "▶" | grep -i "sink\|output" | head -1 | \
        awk '{print $NF}' || echo ""
}

get_default_source() {
    pactl info 2>/dev/null | grep "Default Source" | cut -d: -f2 | xargs || \
    wpctl status 2>/dev/null | grep "▶" | grep -i "source\|input" | head -1 | \
        awk '{print $NF}' || echo ""
}

list_sinks_wpctl() {
    # PipeWire: use wpctl status to get output devices
    wpctl status 2>/dev/null | \
        awk '/Sinks:/,/Sources:/' | \
        grep -v "^Sinks:\|^Sources:" | \
        grep -v "^\s*$" || true
}

list_sources_wpctl() {
    wpctl status 2>/dev/null | \
        awk '/Sources:/,/Sink endpoints:/' | \
        grep -v "^Sources:\|^Sink endpoints:" | \
        grep -v "^\s*$" || true
}

get_sink_volume() {
    local id="$1"
    wpctl get-volume "$id" 2>/dev/null | \
        awk '{printf "%.0f", $2 * 100}' || echo "0"
}

get_sink_mute() {
    local id="$1"
    wpctl get-volume "$id" 2>/dev/null | grep -q "MUTED" && echo "true" || echo "false"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  PACTL DEVICE LISTING (PulseAudio fallback)
# ══════════════════════════════════════════════════════════════════════════════

list_sinks_pactl() {
    pactl list sinks 2>/dev/null | \
        awk '/^Sink #/{id=$2} /Name:/{name=$2} /Description:/{desc=substr($0, index($0,$2))} /Volume:.*%/{
            match($0, /[0-9]+%/); vol=substr($0, RSTART, RLENGTH-1)
        } /Mute:/{mute=$2} /^Sink #/{if(id && name) print id"|"name"|"desc"|"vol"|"mute; id=""; vol=0}
        END{if(id && name) print id"|"name"|"desc"|"vol"|"mute}' || true
}

list_sources_pactl() {
    pactl list sources 2>/dev/null | \
        grep -E "Name:|Description:|Volume:|Mute:|Source #" | \
        awk '/^Source #/{id=$2} /Name:/{name=$2} /Description:/{desc=substr($0,index($0,$2))} /Volume:.*%/{
            match($0,/[0-9]+%/);vol=substr($0,RSTART,RLENGTH-1)
        } /Mute:/{mute=$2} /^Source #/{if(id&&name&&name!~/monitor/)print id"|"name"|"desc"|"vol"|"mute;id=""}
        END{if(id&&name&&name!~/monitor/)print id"|"name"|"desc"|"vol"|"mute}' || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  UNIFIED DEVICE GETTER
# ══════════════════════════════════════════════════════════════════════════════

get_devices() {
    local type="${1:-sink}"     # sink | source

    if [[ "$BACKEND" == "pipewire" ]]; then
        # Use pactl even with PipeWire (it supports PulseAudio API)
        case "$type" in
            sink)    list_sinks_pactl   ;;
            source)  list_sources_pactl ;;
        esac
    else
        case "$type" in
            sink)    list_sinks_pactl   ;;
            source)  list_sources_pactl ;;
        esac
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  DEVICE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

set_default_sink() {
    local name="$1"
    pactl set-default-sink "$name" 2>/dev/null && \
        notify_au "󰕾 Default Output" "$name" "low"
}

set_default_source() {
    local name="$1"
    pactl set-default-source "$name" 2>/dev/null && \
        notify_au "󰍬 Default Input" "$name" "low"
}

toggle_mute_sink() {
    local name="$1"
    pactl set-sink-mute "$name" toggle 2>/dev/null && {
        local muted
        muted=$(pactl list sinks 2>/dev/null | grep -A5 "Name: $name" | grep Mute | awk '{print $2}')
        local status="Unmuted"
        [[ "$muted" == "yes" ]] && status="Muted 󰖁"
        notify_au "Output: $status" "$name" "low"
    }
}

toggle_mute_source() {
    local name="$1"
    pactl set-source-mute "$name" toggle 2>/dev/null && {
        notify_au "Input: toggled mute" "$name" "low"
    }
}

set_volume() {
    local name="$1" vol="$2" type="${3:-sink}"

    # Clamp volume
    [[ "$vol" -gt "$MAX_VOL" ]] && vol="$MAX_VOL"
    [[ "$vol" -lt 0 ]] && vol=0

    if [[ "$type" == "sink" ]]; then
        pactl set-sink-volume "$name" "${vol}%" 2>/dev/null && \
            notify_au "$(volume_icon $vol) Volume: ${vol}%" "$name" "low"
    else
        pactl set-source-volume "$name" "${vol}%" 2>/dev/null && \
            notify_au "󰍬 Input: ${vol}%" "$name" "low"
    fi
}

# Volume adjustment via rofi dialog
adjust_volume() {
    local name="$1" type="${2:-sink}"

    # Get current volume
    local current_vol=50
    if [[ "$type" == "sink" ]]; then
        current_vol=$(pactl list sinks 2>/dev/null | \
            grep -A10 "Name: $name" | \
            grep "Volume:" | head -1 | \
            grep -oP '\d+(?=%)' | head -1 || echo 50)
    fi

    local new_vol
    new_vol=$(echo -e "$(seq 0 5 150 | tac | while read v; do echo "${v}%$(volume_bar $v 12)"; done)" | \
        rofi -dmenu \
            -p "$(volume_icon $current_vol) Volume: ${current_vol}%" \
            -mesg "Device: <b>$(echo "$name" | sed 's/\./ /g; s/_/ /g')</b>" \
            -filter "${current_vol}%" \
            -theme-str "
                window { width: 280px; height: 0px; }
                listview { lines: 8; }
                entry { font: JetBrainsMono Nerd Font Bold 13; }
            " \
            2>/dev/null | grep -oP '^\d+' || echo "")

    [[ -n "$new_vol" ]] && set_volume "$name" "$new_vol" "$type"
}

# Switch profile for device
switch_profile() {
    local name="$1"

    local profiles
    profiles=$(pactl list cards 2>/dev/null | \
        grep -A50 "Name: $name" | \
        grep "^    [a-z]" | \
        grep -v "^    \s" | \
        awk '{print $1}' | head -20 || true)

    if [[ -z "$profiles" ]]; then
        notify_au "No profiles" "No profiles available for $name" "low"
        return
    fi

    local chosen_profile
    chosen_profile=$(echo "$profiles" | \
        rofi -dmenu \
            -p "󰒓 Profile" \
            -mesg "Select profile for: <b>$name</b>" \
            -theme-str "window { width: 400px; } listview { lines: 8; }" \
            2>/dev/null || echo "")

    if [[ -n "$chosen_profile" ]]; then
        pactl set-card-profile "$name" "$chosen_profile" &>/dev/null && \
            notify_au "Profile set" "$chosen_profile" "low"
    fi
}

# Create virtual null sink
create_virtual_sink() {
    local name
    name=$(rofi -dmenu \
        -p "Virtual sink name" \
        -filter "ASH-Virtual" \
        -theme-str "window { width: 350px; } listview { lines: 0; }" \
        2>/dev/null || echo "")

    [[ -z "$name" ]] && return

    pactl load-module module-null-sink sink_name="$name" \
        sink_properties="device.description=$name" &>/dev/null && \
        notify_au "󰑗 Virtual sink created" "$name" "low"
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ACTIVE STREAMS DISPLAY
# ══════════════════════════════════════════════════════════════════════════════

build_streams_entries() {
    printf '─── ACTIVE PLAYBACK STREAMS ──────────────\0nonselectable\x1ftrue\n'

    local streams
    streams=$(pactl list sink-inputs 2>/dev/null | \
        grep -E "Sink Input #|application.name|Volume:" | \
        awk '/Sink Input #/{id=$NF} /application.name/{
            gsub(/"/, "", $NF); app=$NF
        } /Volume:/{
            match($0,/[0-9]+%/); vol=substr($0,RSTART,RLENGTH-1)
            print id"|"app"|"vol
        }' | head -15 || true)

    if [[ -z "$streams" ]]; then
        printf '󰝚  No active playback streams\0nonselectable\x1ftrue\n'
    else
        while IFS='|' read -r id app vol; do
            local bar
            bar=$(volume_bar "${vol:-0}" 8)
            local display
            display=$(printf '󰝚  %-25s  %s  %s%%' \
                "${app:0:23}" "$bar" "${vol:-0}")
            printf '%s\0info\x1fnone\n' "$display"
        done <<< "$streams"
    fi

    printf '─── ACTIVE RECORDING STREAMS ─────────────\0nonselectable\x1ftrue\n'

    local rec_streams
    rec_streams=$(pactl list source-outputs 2>/dev/null | \
        grep -E "Source Output #|application.name|Volume:" | \
        awk '/Source Output #/{id=$NF} /application.name/{
            gsub(/"/, "", $NF); app=$NF
        } /Volume:/{
            match($0,/[0-9]+%/); vol=substr($0,RSTART,RLENGTH-1)
            print id"|"app"|"vol
        }' | head -10 || true)

    if [[ -z "$rec_streams" ]]; then
        printf '󰍬  No active recording streams\0nonselectable\x1ftrue\n'
    else
        while IFS='|' read -r id app vol; do
            local display
            display=$(printf '󰍬  %-25s  %s%%' "${app:0:23}" "${vol:-0}")
            printf '%s\0info\x1fnone\n' "$display"
        done <<< "$rec_streams"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_au() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Audio" \
        --icon=audio-headphones \
        --urgency="$urgency" \
        --expire-time=2500 \
        --hint=string:x-dunst-stack-tag:audio-switcher \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_device_entries() {
    local show_type="${1:-both}"   # output | input | both
    local default_sink default_source

    default_sink=$(pactl info 2>/dev/null | grep "Default Sink" | cut -d: -f2 | xargs || echo "")
    default_source=$(pactl info 2>/dev/null | grep "Default Source" | cut -d: -f2 | xargs || echo "")

    # ── OUTPUT DEVICES ─────────────────────────────────────────────────────────
    if [[ "$show_type" == "output" || "$show_type" == "both" ]]; then
        printf '─── OUTPUT DEVICES ───────────────────────\0nonselectable\x1ftrue\n'

        local sinks
        sinks=$(pactl list sinks 2>/dev/null | \
            awk '/^Sink #/{id=$2} /Name:/{name=$2} /Description:/{
                desc=substr($0,index($0,$2))
            } /^\s+Volume:.*front/{
                match($0,/[0-9]+%/); vol=substr($0,RSTART,RLENGTH-1)
            } /Mute:/{mute=$2} /^$/{
                if(id && name) print id"|"name"|"desc"|"vol"|"mute; id=""
            }' | head -20 || true)

        if [[ -z "$sinks" ]]; then
            printf '  No output devices found\0nonselectable\x1ftrue\n'
        else
            while IFS='|' read -r id name desc vol mute; do
                [[ -z "$name" ]] && continue

                local icon
                icon=$(device_icon "$name" "$desc")
                local bar
                bar=$(volume_bar "${vol:-0}" 8)
                local vol_icon
                vol_icon=$(volume_icon "${vol:-0}")
                local is_default=false
                [[ "$name" == "$default_sink" ]] && is_default=true

                local default_mark="" mute_mark=""
                $is_default && default_mark="● Default  "
                [[ "$mute" == "yes" ]] && mute_mark="󰖁 Muted"

                local desc_short
                desc_short=$(echo "$desc" | head -c 32)

                local display
                display=$(printf '%s  %-28s  %s%s  %s%%  %s%s' \
                    "$icon" \
                    "${desc_short:0:26}" \
                    "$bar" \
                    "$vol_icon" \
                    "${vol:-0}" \
                    "$default_mark" \
                    "$mute_mark")

                local entry_class=""
                $is_default && entry_class="default"
                [[ "$mute" == "yes" ]] && entry_class="muted"

                printf '%s\0info\x1fset-default-sink\x1fmeta\x1f%s|%s|sink\n' \
                    "$display" "$name" "$desc"

            done <<< "$sinks"
        fi

        # Actions for outputs
        printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
        printf '󰑗  Create Virtual Output Sink\0info\x1fcreate-virtual\n'
        printf '󰎛  Open Pavucontrol\0info\x1fpavucontrol\n'
    fi

    # ── INPUT DEVICES ──────────────────────────────────────────────────────────
    if [[ "$show_type" == "input" || "$show_type" == "both" ]]; then
        printf '─── INPUT DEVICES ────────────────────────\0nonselectable\x1ftrue\n'

        local sources
        sources=$(pactl list sources 2>/dev/null | \
            awk '/^Source #/{id=$2} /Name:/{name=$2} /Description:/{
                desc=substr($0,index($0,$2))
            } /^\s+Volume:.*front/{
                match($0,/[0-9]+%/); vol=substr($0,RSTART,RLENGTH-1)
            } /Mute:/{mute=$2} /^$/{
                if(id && name && name !~ /monitor/) print id"|"name"|"desc"|"vol"|"mute; id=""
            }' | head -15 || true)

        if [[ -z "$sources" ]]; then
            printf '  No input devices found\0nonselectable\x1ftrue\n'
        else
            while IFS='|' read -r id name desc vol mute; do
                [[ -z "$name" ]] && continue
                [[ "$name" =~ monitor ]] && continue   # Skip monitor sources

                local icon
                icon=$(device_icon "$name" "$desc")
                local bar
                bar=$(volume_bar "${vol:-0}" 8)
                local is_default=false
                [[ "$name" == "$default_source" ]] && is_default=true

                local default_mark="" mute_mark=""
                $is_default && default_mark="● Default  "
                [[ "$mute" == "yes" ]] && mute_mark="󰍭 Muted"

                local desc_short
                desc_short=$(echo "$desc" | head -c 32)

                local display
                display=$(printf '%s  %-28s  %s  %s%%  %s%s' \
                    "$icon" \
                    "${desc_short:0:26}" \
                    "$bar" \
                    "${vol:-0}" \
                    "$default_mark" \
                    "$mute_mark")

                printf '%s\0info\x1fset-default-source\x1fmeta\x1f%s|%s|source\n' \
                    "$display" "$name" "$desc"

            done <<< "$sources"
        fi

        # Actions for inputs
        printf '─────────────────────────────────────────\0nonselectable\x1ftrue\n'
        printf '󰍭  Mute All Inputs\0info\x1fmute-all-inputs\n'
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        set-default-sink)
            IFS='|' read -r name desc type <<< "$meta"
            [[ -n "$name" ]] && {
                show_sink_menu "$name" "$desc"
            }
            ;;
        set-default-source)
            IFS='|' read -r name desc type <<< "$meta"
            [[ -n "$name" ]] && {
                show_source_menu "$name" "$desc"
            }
            ;;
        mute-all-inputs)
            pactl list sources short 2>/dev/null | \
                awk '!/monitor/{print $2}' | \
                while read -r src; do
                    pactl set-source-mute "$src" 1 2>/dev/null || true
                done
            notify_au "󰍭 All inputs muted" "" "normal"
            ;;
        create-virtual)
            create_virtual_sink
            ;;
        pavucontrol)
            command -v pavucontrol &>/dev/null && \
                pavucontrol &>/dev/null & disown || \
                notify_au "Error" "pavucontrol not installed" "critical"
            ;;
        none|"")
            return 0
            ;;
    esac
}

show_sink_menu() {
    local name="$1" desc="${2:-}"

    local current_vol=50
    current_vol=$(pactl list sinks 2>/dev/null | \
        grep -A10 "Name: $name" | \
        grep "Volume:" | head -1 | \
        grep -oP '\d+(?=%)' | head -1 || echo 50)

    local choice
    choice=$(printf '%s\n' \
        "󰕾  Set as Default Output" \
        "󰖁  Mute / Unmute" \
        "󰎚  Adjust Volume (${current_vol}%)" \
        "󰒓  Switch Profile" \
        "󰋼  Device Info" \
        "Cancel" | \
        rofi -dmenu \
            -p "$(device_icon "$name" "$desc") ${desc:-$name}" \
            -theme-str "
                window { width: 320px; }
                listview { lines: 6; }
                element { padding: 9px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #89dceb;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "Cancel")

    case "$choice" in
        "󰕾  Set as Default"*)  set_default_sink    "$name" ;;
        "󰖁  Mute"*)            toggle_mute_sink    "$name" ;;
        "󰎚  Adjust Volume"*)   adjust_volume       "$name" "sink" ;;
        "󰒓  Switch Profile"*)  switch_profile      "$name" ;;
        "󰋼  Device Info")
            local info
            info=$(pactl list sinks 2>/dev/null | \
                awk "/^Sink #/{found=0} /Name: $name/{found=1} found{print}" | \
                head -20)
            notify_au "Device Info" "$info" "low"
            ;;
        *) ;;
    esac
}

show_source_menu() {
    local name="$1" desc="${2:-}"

    local choice
    choice=$(printf '%s\n' \
        "󰍬  Set as Default Input" \
        "󰍭  Mute / Unmute" \
        "󰎚  Adjust Volume" \
        "Cancel" | \
        rofi -dmenu \
            -p "$(device_icon "$name" "$desc") ${desc:-$name}" \
            -theme-str "
                window { width: 300px; }
                listview { lines: 4; }
                element { padding: 9px 16px; border-radius: 8px; }
            " \
            2>/dev/null || echo "Cancel")

    case "$choice" in
        "󰍬  Set as Default"*)  set_default_source  "$name" ;;
        "󰍭  Mute"*)            toggle_mute_source  "$name" ;;
        "󰎚  Adjust Volume")    adjust_volume       "$name" "source" ;;
        *) ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §13  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --list-sinks)   get_devices sink ;;
        --list-sources) get_devices source ;;
        --default-sink) get_default_sink ;;
        --default-source) get_default_source ;;
        --set-sink)     [[ -n "${2:-}" ]] && set_default_sink "$2" ;;
        --set-source)   [[ -n "${2:-}" ]] && set_default_source "$2" ;;
        --mute-out)     [[ -n "${2:-}" ]] && toggle_mute_sink "$2" ;;
        --mute-in)      [[ -n "${2:-}" ]] && toggle_mute_source "$2" ;;
        --vol-out)      [[ -n "${2:-}" && -n "${3:-}" ]] && set_volume "$2" "$3" "sink" ;;
        --vol-in)       [[ -n "${2:-}" && -n "${3:-}" ]] && set_volume "$2" "$3" "source" ;;
        --streams)      build_streams_entries ;;
        --backend)      echo "$BACKEND" ;;
        --help|-h)
            echo "ASH Audio Switcher v5.0"
            echo "Backend: $BACKEND"
            echo ""
            echo "Usage: audio-switcher.sh [OPTION]"
            echo "  --list-sinks       List output devices"
            echo "  --list-sources     List input devices"
            echo "  --default-sink     Show default output"
            echo "  --default-source   Show default input"
            echo "  --set-sink NAME    Set default output"
            echo "  --set-source NAME  Set default input"
            echo "  --mute-out NAME    Toggle output mute"
            echo "  --mute-in NAME     Toggle input mute"
            echo "  --vol-out N PCT    Set output volume"
            echo "  --vol-in N PCT     Set input volume"
            echo "  --streams          Show active streams"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §14  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" "${3:-}" 2>/dev/null || true

    rofi \
        -show au \
        -modi "au:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/audio-switcher/audio-switcher.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_device_entries "both"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# Ctrl+M: Mute focused device
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    if [[ -n "$meta_value" ]]; then
        IFS='|' read -r name desc type <<< "$meta_value"
        case "${type:-sink}" in
            sink)   toggle_mute_sink   "${name:-}" ;;
            source) toggle_mute_source "${name:-}" ;;
        esac
    fi
    build_device_entries "both"
    exit 0
fi

# Ctrl+P: Profile switcher
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    if [[ -n "$meta_value" ]]; then
        IFS='|' read -r name desc type <<< "$meta_value"
        [[ -n "$name" ]] && switch_profile "$name"
    fi
    build_device_entries "both"
    exit 0
fi

# Ctrl+R: Refresh
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    build_device_entries "both"
    exit 0
fi

# Ctrl+S: Streams view
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    build_streams_entries
    exit 0
fi

# Ctrl+V: Virtual sink
if [[ "${ROFI_RETV}" -eq 15 ]]; then
    create_virtual_sink
    build_device_entries "both"
    exit 0
fi

# Alt+Enter: Volume adjust
if [[ "${ROFI_RETV}" -eq 16 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    if [[ -n "$meta_value" ]]; then
        IFS='|' read -r name desc type <<< "$meta_value"
        [[ -n "$name" ]] && adjust_volume "$name" "${type:-sink}"
    fi
    build_device_entries "both"
    exit 0
fi

# Re-filter
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_device_entries "both"
    exit 0
fi