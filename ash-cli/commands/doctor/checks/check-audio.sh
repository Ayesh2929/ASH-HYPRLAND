#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   █████╗ ██╗   ██╗██████╗ ██╗ ██████╗                                          ║
# ║  ██╔══██╗██║   ██║██╔══██╗██║██╔═══██╗                                         ║
# ║  ███████║██║   ██║██║  ██║██║██║   ██║                                         ║
# ║  ██╔══██║██║   ██║██║  ██║██║██║   ██║                                         ║
# ║  ██║  ██║╚██████╔╝██████╔╝██║╚██████╔╝                                         ║
# ║  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝                                          ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: AUDIO                                     ║
# ║  PipeWire • WirePlumber • ALSA • PulseAudio • Bluetooth audio • EasyEffects     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_AUDIO_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_AUDIO_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — PIPEWIRE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_pipewire() {
    _check_header "🎵 PipeWire Audio Server"

    # ── Binary ──────────────────────────────────────────────────────────────────
    if ! command -v pipewire &>/dev/null; then
        _check_report $CHECK_FAIL \
            "pipewire binary" \
            "Not found" \
            "Install: paru -S pipewire pipewire-audio"
        return $CHECK_FAIL
    fi

    local pw_ver
    pw_ver="$(pipewire --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo 'unknown')"
    _check_report $CHECK_PASS \
        "pipewire binary" \
        "v${pw_ver}"

    # ── Process running ──────────────────────────────────────────────────────────
    if pgrep -x pipewire &>/dev/null; then
        local pw_pid
        pw_pid="$(pgrep -x pipewire | head -1)"
        _check_report $CHECK_PASS \
            "pipewire process" \
            "Running  (PID: ${pw_pid})"
    else
        _check_report $CHECK_FAIL \
            "pipewire process" \
            "Not running" \
            "Start: systemctl --user enable --now pipewire"
        return $CHECK_FAIL
    fi

    # ── systemd service status ───────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local svc_state
        svc_state="$(systemctl --user is-active pipewire 2>/dev/null || echo 'inactive')"
        local svc_enabled
        svc_enabled="$(systemctl --user is-enabled pipewire 2>/dev/null || echo 'disabled')"

        if [[ "$svc_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "pipewire.service" \
                "active  •  enabled: ${svc_enabled}"
        else
            _check_report $CHECK_WARN \
                "pipewire.service" \
                "state=${svc_state}  •  enabled: ${svc_enabled}" \
                "Enable: systemctl --user enable --now pipewire"
        fi

        # pipewire-pulse companion service
        local pulse_state
        pulse_state="$(systemctl --user is-active pipewire-pulse 2>/dev/null || echo 'inactive')"
        if [[ "$pulse_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "pipewire-pulse.service" \
                "active  (PulseAudio API compatibility)"
        else
            _check_report $CHECK_WARN \
                "pipewire-pulse.service" \
                "state=${pulse_state}" \
                "Enable: systemctl --user enable --now pipewire-pulse"
        fi
    fi

    # ── pw-cli info ─────────────────────────────────────────────────────────────
    if command -v pw-cli &>/dev/null; then
        local pw_server_info
        pw_server_info="$(pw-cli info 0 2>/dev/null | \
                          grep -E 'version:|default\.clock' | head -4 || echo '')"
        if [[ -n "$pw_server_info" ]]; then
            local pw_runtime_ver
            pw_runtime_ver="$(printf '%s' "$pw_server_info" | \
                              grep 'version:' | awk '{print $2}' | head -1)"
            _check_report $CHECK_PASS \
                "PipeWire runtime version" \
                "${pw_runtime_ver:-${pw_ver}}"

            local pw_clock_rate
            pw_clock_rate="$(printf '%s' "$pw_server_info" | \
                             grep 'default.clock.rate' | awk -F'=' '{print $2}' | \
                             tr -d ' "' | head -1)"
            [[ -n "$pw_clock_rate" ]] && \
                _check_report $CHECK_INFO \
                    "Default sample rate" \
                    "${pw_clock_rate} Hz"
        fi
    fi

    # ── PIPEWIRE_RUNTIME_DIR socket ─────────────────────────────────────────────
    local pw_socket="${XDG_RUNTIME_DIR:-/run/user/${UID:-1000}}/pipewire-0"
    if [[ -S "$pw_socket" ]]; then
        _check_report $CHECK_PASS \
            "PipeWire socket" \
            "${pw_socket}"
    else
        _check_report $CHECK_WARN \
            "PipeWire socket" \
            "Missing: ${pw_socket}" \
            "Socket should exist when PipeWire is running"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — WIREPLUMBER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_wireplumber() {
    _check_header "🔀 WirePlumber  (Session Manager)"

    # ── Binary ──────────────────────────────────────────────────────────────────
    if ! command -v wireplumber &>/dev/null; then
        _check_report $CHECK_FAIL \
            "wireplumber binary" \
            "Not found" \
            "Install: paru -S wireplumber"
        return $CHECK_FAIL
    fi

    local wp_ver
    wp_ver="$(wireplumber --version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo '?')"
    _check_report $CHECK_PASS \
        "wireplumber binary" \
        "v${wp_ver}"

    # ── Process running ──────────────────────────────────────────────────────────
    if pgrep -x wireplumber &>/dev/null; then
        _check_report $CHECK_PASS \
            "wireplumber process" \
            "Running"
    else
        _check_report $CHECK_FAIL \
            "wireplumber process" \
            "Not running" \
            "Start: systemctl --user enable --now wireplumber"
        return $CHECK_FAIL
    fi

    # ── systemd service ──────────────────────────────────────────────────────────
    if command -v systemctl &>/dev/null; then
        local wp_state
        wp_state="$(systemctl --user is-active wireplumber 2>/dev/null || echo 'inactive')"
        if [[ "$wp_state" == "active" ]]; then
            _check_report $CHECK_PASS \
                "wireplumber.service" \
                "active"
        else
            _check_report $CHECK_WARN \
                "wireplumber.service" \
                "state=${wp_state}" \
                "Enable: systemctl --user enable --now wireplumber"
        fi
    fi

    # ── wpctl status — count objects ────────────────────────────────────────────
    if command -v wpctl &>/dev/null; then
        local wpctl_out
        wpctl_out="$(wpctl status 2>/dev/null || echo '')"

        if [[ -n "$wpctl_out" ]]; then
            # Count sinks and sources
            local sink_count source_count device_count
            sink_count="$(  printf '%s' "$wpctl_out" | grep -c 'Sinks\|sink'    || echo 0)"
            source_count="$(printf '%s' "$wpctl_out" | grep -c 'Sources\|source' || echo 0)"
            device_count="$(printf '%s' "$wpctl_out" | grep -c '\[vol:'          || echo 0)"

            _check_report $CHECK_PASS \
                "wpctl status" \
                "${device_count} audio device(s) registered"

            # Default sink
            local default_sink
            default_sink="$(wpctl status 2>/dev/null | \
                            awk '/Sinks:/{found=1} found && /\*/{print; exit}' | \
                            sed 's/.*\. //' | cut -c1-60)"
            [[ -n "$default_sink" ]] && \
                _check_report $CHECK_INFO \
                    "Default sink (output)" \
                    "$default_sink"

            # Default source
            local default_source
            default_source="$(wpctl status 2>/dev/null | \
                              awk '/Sources:/{found=1} found && /\*/{print; exit}' | \
                              sed 's/.*\. //' | cut -c1-60)"
            [[ -n "$default_source" ]] && \
                _check_report $CHECK_INFO \
                    "Default source (input)" \
                    "$default_source"
        else
            _check_report $CHECK_WARN \
                "wpctl status" \
                "Empty response — WirePlumber not fully initialized"
        fi

        # ── Volume sanity ────────────────────────────────────────────────────────
        local vol_out
        vol_out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo '')"
        if [[ -n "$vol_out" ]]; then
            local vol_val
            vol_val="$(printf '%s' "$vol_out" | grep -oP '[\d.]+')"
            local vol_pct
            vol_pct="$(printf '%.0f' "$(echo "$vol_val * 100" | bc -l 2>/dev/null || echo 0)")"

            if printf '%s' "$vol_out" | grep -q '\[MUTED\]'; then
                _check_report $CHECK_INFO \
                    "Default output volume" \
                    "MUTED  (${vol_pct}%)"
            else
                _check_report $CHECK_PASS \
                    "Default output volume" \
                    "${vol_pct}%"
            fi
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — ALSA LAYER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_alsa() {
    _check_header "🔊 ALSA  (Kernel Audio Layer)"

    # ── Kernel modules ───────────────────────────────────────────────────────────
    if lsmod 2>/dev/null | grep -q '^snd\b'; then
        local snd_modules
        snd_modules="$(lsmod | awk '/^snd/{print $1}' | sort | tr '\n' '  ')"
        _check_report $CHECK_PASS \
            "ALSA kernel modules" \
            "$snd_modules"
    else
        _check_report $CHECK_FAIL \
            "ALSA kernel modules" \
            "No snd_* modules loaded" \
            "Load: sudo modprobe snd_hda_intel  (or relevant driver)"
    fi

    # ── snd_hda_intel (HDA audio — most common) ─────────────────────────────────
    if lsmod 2>/dev/null | grep -q 'snd_hda_intel'; then
        _check_report $CHECK_PASS \
            "snd_hda_intel" \
            "Loaded  (HD Audio — standard for Intel/AMD audio)"
    fi

    # ── Sound cards via /proc ────────────────────────────────────────────────────
    local cards_file="/proc/asound/cards"
    if [[ -r "$cards_file" ]]; then
        local card_count
        card_count="$(grep -c '^[[:space:]]*[0-9]' "$cards_file" 2>/dev/null || echo 0)"

        if (( card_count == 0 )); then
            _check_report $CHECK_FAIL \
                "ALSA sound cards" \
                "No cards detected" \
                "Check: dmesg | grep -i 'snd\|audio\|hda'"
        else
            _check_report $CHECK_PASS \
                "ALSA sound cards" \
                "${card_count} card(s) detected"

            while IFS= read -r line; do
                [[ "$line" =~ ^[[:space:]]*[0-9] ]] || continue
                local card_num card_name
                card_num="$(printf '%s' "$line" | awk '{print $1}')"
                card_name="$(printf '%s' "$line" | sed 's/^[[:space:]]*[0-9]* \[//' | sed 's/\].*//')"
                _check_report $CHECK_INFO \
                    "  Card ${card_num}" \
                    "${card_name}"
            done < "$cards_file"
        fi
    else
        _check_report $CHECK_INFO \
            "ALSA sound cards" \
            "/proc/asound/cards not readable"
    fi

    # ── aplay -l quick test ──────────────────────────────────────────────────────
    if command -v aplay &>/dev/null; then
        local aplay_out
        aplay_out="$(aplay -l 2>/dev/null | grep -c '^card' || echo 0)"
        _check_report $CHECK_INFO \
            "aplay -l devices" \
            "${aplay_out} playback device(s)"
    else
        _check_report $CHECK_INFO \
            "aplay" \
            "Not installed" \
            "Install: paru -S alsa-utils"
    fi

    # ── sof-firmware (Sound Open Firmware — modern Intel/AMD laptops) ───────────
    local sof_fw_dir="/lib/firmware/intel/sof"
    local sof_alt_dir="/lib/firmware/amd/sof"

    if [[ -d "$sof_fw_dir" ]] || [[ -d "$sof_alt_dir" ]]; then
        local sof_count
        sof_count="$(find "${sof_fw_dir}" "${sof_alt_dir}" \
                     -name '*.ri' -o -name '*.ldc' 2>/dev/null | wc -l)"
        _check_report $CHECK_PASS \
            "SOF firmware" \
            "${sof_count} firmware files  (Sound Open Firmware — modern laptops)"
    else
        _check_report $CHECK_INFO \
            "SOF firmware" \
            "Not found — may not be needed on your hardware" \
            "Install if audio broken on laptop: paru -S sof-firmware"
    fi

    # ── UCM profiles ────────────────────────────────────────────────────────────
    local ucm_count
    ucm_count="$(find /usr/share/alsa/ucm2 -name '*.conf' 2>/dev/null | wc -l)"
    if (( ucm_count > 0 )); then
        _check_report $CHECK_PASS \
            "ALSA UCM profiles" \
            "${ucm_count} UCM config files  (Use Case Manager)"
    else
        _check_report $CHECK_INFO \
            "ALSA UCM profiles" \
            "None found — may cause issues on some laptops"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — AUDIO DEVICES & ROUTING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_devices() {
    _check_header "🎧 Audio Devices & Routing"

    # ── pactl list sinks ─────────────────────────────────────────────────────────
    if command -v pactl &>/dev/null; then
        local sinks_out
        sinks_out="$(pactl list sinks short 2>/dev/null || echo '')"

        if [[ -z "$sinks_out" ]]; then
            _check_report $CHECK_FAIL \
                "pactl sinks" \
                "No sinks listed — PipeWire/PulseAudio not responding" \
                "Restart: systemctl --user restart pipewire pipewire-pulse"
        else
            local sink_count
            sink_count="$(printf '%s\n' "$sinks_out" | wc -l)"
            _check_report $CHECK_PASS \
                "Audio sinks (outputs)" \
                "${sink_count} sink(s) available"

            while IFS= read -r sink_line; do
                [[ -z "$sink_line" ]] && continue
                local sink_id sink_name sink_state
                sink_id="$(  printf '%s' "$sink_line" | awk '{print $1}')"
                sink_name="$(printf '%s' "$sink_line" | awk '{print $2}')"
                sink_state="$(printf '%s' "$sink_line" | awk '{print $5}')"
                _check_report $CHECK_INFO \
                    "  Sink [${sink_id}]" \
                    "${sink_name}  •  ${sink_state}"
            done <<< "$sinks_out"
        fi

        # ── Sources (inputs) ────────────────────────────────────────────────────
        local sources_out
        sources_out="$(pactl list sources short 2>/dev/null | grep -v 'monitor' || echo '')"
        local src_count
        src_count="$(printf '%s\n' "$sources_out" | grep -c '.' || echo 0)"
        _check_report $CHECK_INFO \
            "Audio sources (inputs)" \
            "${src_count} non-monitor source(s)"

    else
        _check_report $CHECK_INFO \
            "pactl" \
            "Not installed" \
            "Install: paru -S libpulse"
    fi

    # ── pamixer ──────────────────────────────────────────────────────────────────
    if command -v pamixer &>/dev/null; then
        local mute_state
        mute_state="$(pamixer --get-mute 2>/dev/null || echo 'unknown')"
        local vol
        vol="$(pamixer --get-volume 2>/dev/null || echo '?')"

        if [[ "$mute_state" == "true" ]]; then
            _check_report $CHECK_INFO \
                "pamixer  (default sink)" \
                "MUTED at ${vol}%"
        else
            _check_report $CHECK_PASS \
                "pamixer  (default sink)" \
                "Volume: ${vol}%  •  not muted"
        fi
    else
        _check_report $CHECK_WARN \
            "pamixer" \
            "Not installed" \
            "Install: paru -S pamixer  (used by waybar volume module)"
    fi

    # ── playerctl (media control) ────────────────────────────────────────────────
    if command -v playerctl &>/dev/null; then
        local player_status
        player_status="$(playerctl status 2>/dev/null || echo 'No player')"
        local player_name
        player_name="$(playerctl --list-all 2>/dev/null | tr '\n' '  ' || echo 'none')"
        _check_report $CHECK_INFO \
            "playerctl" \
            "${player_status}  •  players: ${player_name:-none}"
    else
        _check_report $CHECK_WARN \
            "playerctl" \
            "Not installed" \
            "Install: paru -S playerctl  (required for media keys)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — BLUETOOTH AUDIO
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_bluetooth() {
    _check_header "📡 Bluetooth Audio Integration"

    # ── pipewire-bluetooth ───────────────────────────────────────────────────────
    local pw_bt_lib
    pw_bt_lib="$(find /usr/lib /usr/lib64 -name 'libspa-bluez5.so' \
                 -o -name 'bluez5.so' 2>/dev/null | head -1 || echo '')"

    if [[ -n "$pw_bt_lib" ]]; then
        _check_report $CHECK_PASS \
            "pipewire-bluetooth" \
            "$(basename "$pw_bt_lib")  (Bluetooth audio backend)"
    else
        _check_report $CHECK_WARN \
            "pipewire-bluetooth" \
            "libspa-bluez5.so not found" \
            "Install: paru -S pipewire-bluetooth"
    fi

    # ── Codecs available ─────────────────────────────────────────────────────────
    local -a bt_codec_libs=(
        "libldacBT_enc.so:LDAC (Sony hi-res codec)"
        "libaptx.so:aptX (Qualcomm)"
        "libaac.so:AAC"
        "libfreeaptx.so:aptX (open-source)"
    )

    for codec_entry in "${bt_codec_libs[@]}"; do
        IFS=':' read -r lib_name codec_desc <<< "$codec_entry"
        local lib_path
        lib_path="$(find /usr/lib /usr/lib64 -name "$lib_name" 2>/dev/null | head -1 || echo '')"
        if [[ -n "$lib_path" ]]; then
            _check_report $CHECK_PASS \
                "BT Codec: ${codec_desc}" \
                "Available"
        else
            _check_report $CHECK_INFO \
                "BT Codec: ${codec_desc}" \
                "Not installed" \
                "Install: paru -S $(printf '%s' "$lib_name" | sed 's/lib/lib/;s/\.so//')"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — AUDIO TOOLS & EXTRAS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_tools() {
    _check_header "🛠️  Audio Tools & Extras"

    # Format: "binary:package:critical:description"
    local -a tools=(
        "pw-play:pipewire:1:pw-play  (PipeWire audio player)"
        "pw-record:pipewire:1:pw-record  (PipeWire audio recorder)"
        "pw-dump:pipewire:0:pw-dump  (PipeWire graph dump)"
        "helvum:helvum:0:Helvum  (PipeWire GTK patchbay)"
        "qpwgraph:qpwgraph:0:qpwgraph  (PipeWire Qt patchbay)"
        "easyeffects:easyeffects:0:EasyEffects  (audio DSP / EQ)"
        "carla:carla:0:Carla  (plugin host)"
        "jack_simple_client:jack2:0:JACK  (pro audio)"
        "sox:sox:0:SoX  (audio processing CLI)"
        "ffmpeg:ffmpeg:0:FFmpeg  (audio conversion)"
        "mpv:mpv:0:mpv  (media player)"
        "cava:cava:0:CAVA  (audio visualizer)"
        "ncmpcpp:ncmpcpp:0:ncmpcpp  (MPD client)"
        "mpc:mpc:0:mpc  (MPD CLI client)"
        "mpd:mpd:0:MPD  (music player daemon)"
    )

    for tool_def in "${tools[@]}"; do
        IFS=':' read -r cmd pkg critical desc <<< "$tool_def"

        if command -v "$cmd" &>/dev/null; then
            local ver
            ver="$("$cmd" --version 2>/dev/null | head -1 | \
                   grep -oP '[\d.]+' | head -1 || echo 'installed')"
            _check_report $CHECK_PASS "$desc" "$ver"
        else
            if [[ "$critical" == "1" ]]; then
                _check_report $CHECK_FAIL "$desc" \
                    "Not installed" \
                    "Install: paru -S $pkg"
            else
                _check_report $CHECK_INFO "$desc" \
                    "Not installed  (optional)" \
                    "Install: paru -S $pkg"
            fi
        fi
    done

    # ── EasyEffects presets ──────────────────────────────────────────────────────
    local ee_presets_dir="${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/output"
    if [[ -d "$ee_presets_dir" ]]; then
        local preset_count
        preset_count="$(find "$ee_presets_dir" -name '*.json' | wc -l)"
        _check_report $CHECK_INFO \
            "EasyEffects presets" \
            "${preset_count} preset(s) in ${ee_presets_dir}"
    fi

    # ── ASH audio config ────────────────────────────────────────────────────────
    local ash_pw_conf="${XDG_CONFIG_HOME:-$HOME/.config}/pipewire"
    if [[ -d "$ash_pw_conf" ]]; then
        local conf_count
        conf_count="$(find "$ash_pw_conf" -name '*.conf' | wc -l)"
        _check_report $CHECK_INFO \
            "PipeWire config overrides" \
            "${conf_count} file(s) in ${ash_pw_conf}"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — DMESG AUDIO ERRORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_audio_dmesg() {
    _check_header "📋 Audio Kernel Messages"

    # ── Errors / warnings ───────────────────────────────────────────────────────
    local audio_errors
    audio_errors="$(dmesg 2>/dev/null | \
                    grep -iE 'snd|alsa|hda|audio.*error|audio.*fail|sof.*fail' | \
                    grep -iE 'error|fail|warn' | tail -5 || echo '')"

    if [[ -n "$audio_errors" ]]; then
        local err_count
        err_count="$(printf '%s\n' "$audio_errors" | wc -l)"
        _check_report $CHECK_WARN \
            "Audio dmesg errors" \
            "${err_count} error/warning line(s)"

        while IFS= read -r err_line; do
            _check_report $CHECK_WARN \
                "  dmesg" \
                "$(printf '%s' "$err_line" | sed 's/.*\] //' | cut -c1-80)"
        done <<< "$audio_errors"
    else
        _check_report $CHECK_PASS \
            "Audio dmesg errors" \
            "None detected"
    fi

    # ── PipeWire journal errors ──────────────────────────────────────────────────
    if command -v journalctl &>/dev/null; then
        local pw_journal_errors
        pw_journal_errors="$(journalctl --user -u pipewire -u wireplumber \
                             --since '10 minutes ago' --no-pager -q \
                             2>/dev/null | grep -iE 'error|fail|warn' | \
                             tail -3 || echo '')"

        if [[ -n "$pw_journal_errors" ]]; then
            local je_count
            je_count="$(printf '%s\n' "$pw_journal_errors" | wc -l)"
            _check_report $CHECK_WARN \
                "PipeWire journal errors" \
                "${je_count} recent error(s)" \
                "See full log: journalctl --user -u pipewire --since '10 min ago'"
        else
            _check_report $CHECK_PASS \
                "PipeWire journal errors" \
                "None in last 10 minutes"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_audio() {
    local mode="${1:-full}"   # quick | full

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;148;226;213m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🎵  ASH DOCTOR — AUDIO CHECK                            ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  Checks: PipeWire • WirePlumber • ALSA • devices • BT   ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — AUDIO CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_audio_pipewire
            _chk_audio_wireplumber
            ;;
        full|*)
            _chk_audio_pipewire
            _chk_audio_wireplumber
            _chk_audio_alsa
            _chk_audio_devices
            _chk_audio_bluetooth
            _chk_audio_tools
            _chk_audio_dmesg
            ;;
    esac

    _ash_check_system_summary
}

ash_check_audio_quick() {
    local issues=0
    pgrep -x pipewire   &>/dev/null || (( issues++ )) || true
    pgrep -x wireplumber &>/dev/null || (( issues++ )) || true
    if (( issues == 0 )); then
        ash_log_success "Audio: OK  (PipeWire + WirePlumber running)"
    else
        ash_log_warn "Audio: ${issues} issue(s) — run 'ash doctor full --audio'"
        return 1
    fi
}
