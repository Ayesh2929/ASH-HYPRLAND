#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  audio eq                                                 ║
# ║  EQ presets via EasyEffects + PipeWire filter-chain + built-in band display     ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_AUD_EQ_LOADED:-}" == "1" ]] && return 0
readonly _ASH_AUD_EQ_LOADED=1

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BUILT-IN EQ PRESETS  (band values in dB relative, 10-band)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -gA _EQ_PRESETS=(
    [flat]="0 0 0 0 0 0 0 0 0 0"
    [bass-boost]="+6 +5 +3 +1 0 0 0 0 0 0"
    [treble-boost]="0 0 0 0 0 +2 +4 +5 +6 +6"
    [vocal]="0 0 +2 +4 +5 +4 +3 +1 0 -1"
    [classical]="-2 0 0 0 0 0 +2 +4 +4 +2"
    [electronic]="+4 +3 0 -2 0 +2 +3 +4 +5 +3"
    [jazz]="+2 +2 0 +2 -2 -2 0 +2 +4 +3"
    [pop]="-1 +2 +4 +4 +2 0 +1 +2 +3 +2"
    [rock]="+4 +3 +2 0 -1 -1 +2 +4 +5 +4"
    [gaming]="+3 +2 0 +1 +2 +3 +3 +4 +5 +4"
    [podcast]="0 0 +2 +4 +5 +4 +3 +1 0 -1"
    [night]="-4 -3 -2 0 +2 +3 +4 +3 +2 0"
)

declare -gA _EQ_DESCRIPTIONS=(
    [flat]="Neutral — no EQ applied"
    [bass-boost]="Enhanced low frequencies"
    [treble-boost]="Enhanced high frequencies"
    [vocal]="Optimised for voice clarity"
    [classical]="Warm classical music profile"
    [electronic]="Electronic / EDM profile"
    [jazz]="Warm jazz profile"
    [pop]="Bright pop music profile"
    [rock]="Punchy rock profile"
    [gaming]="Directional audio for gaming"
    [podcast]="Voice-optimised for podcasts"
    [night]="Reduced bass, preserved mids for quiet listening"
)

# Frequency labels for 10-band
declare -ga _EQ_BANDS=( "32Hz" "64Hz" "125Hz" "250Hz" "500Hz" "1kHz" "2kHz" "4kHz" "8kHz" "16kHz" )

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  VISUAL EQ BAND DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_eq_visual() {
    local preset_name="$1"
    local bands_str="${_EQ_PRESETS[$preset_name]:-0 0 0 0 0 0 0 0 0 0}"
    local -a bands=()
    read -ra bands <<< "$bands_str"

    local max_h=8   # bar height in rows

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n  %s10-Band EQ — %s%s%s:\n\n' \
            "$(_adim)" "$(_apeach)$(_abold)" "$preset_name" "$(_ar)"

        # Draw bars from top to bottom
        for (( row=max_h; row>=-max_h; row-- )); do
            printf '  '
            if (( row == 0 )); then
                # Centre line (0dB)
                printf '%s' "$(_adim)"
                printf '%s' "$(printf '─%.0s' $(seq 1 70))"
                printf '%s 0dB\n' "$(_ar)"
                continue
            fi

            for (( bi=0; bi<${#bands[@]}; bi++ )); do
                local band_val="${bands[$bi]}"
                band_val="${band_val//+/}"   # strip + prefix

                # Determine if this row should show a block for this band
                local show_block=0
                if (( row > 0 )) && (( band_val > 0 )); then
                    # Positive band, positive row
                    (( row <= band_val )) && show_block=1
                elif (( row < 0 )) && (( band_val < 0 )); then
                    local abs_val=$(( -band_val ))
                    local abs_row=$(( -row ))
                    (( abs_row <= abs_val )) && show_block=1
                fi

                if [[ $show_block -eq 1 ]]; then
                    local bc
                    if   (( band_val >= 5  )); then bc="$(_agreen)"
                    elif (( band_val >= 2  )); then bc="$(_ateal)"
                    elif (( band_val >= 0  )); then bc="$(_ablue)"
                    elif (( band_val >= -2 )); then bc="$(_ayellow)"
                    else                            bc="$(_ared)"
                    fi
                    printf '%s██%s ' "$bc" "$(_ar)"
                else
                    printf '%s  %s ' "$(_adim)" "$(_ar)"
                fi
            done

            # Row label (dB)
            if (( row > 0 )); then
                printf '%s+%d%s' "$(_adim)" "$row" "$(_ar)"
            else
                printf '%s%d%s' "$(_adim)" "$row" "$(_ar)"
            fi
            printf '\n'
        done

        # Frequency labels
        printf '  '
        for band in "${_EQ_BANDS[@]}"; do
            printf '%s%-3s%s ' "$(_adim)" "${band}" "$(_ar)"
        done
        printf '\n\n'

        # Numeric values row
        printf '  %sValues: %s' "$(_adim)" "$(_ar)"
        for (( bi=0; bi<${#bands[@]}; bi++ )); do
            local v="${bands[$bi]}"
            local vc
            v="${v//+/}"
            if   [[ "$v" =~ ^-   ]]; then vc="$(_ared)"
            elif [[ "${bands[$bi]}" =~ ^\+ ]]; then vc="$(_agreen)"
            else vc="$(_adim)"
            fi
            printf '%s%+d%s ' "$vc" "$v" "$(_ar)"
        done
        printf 'dB\n'
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  EASYEFFECTS INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_eq_easyeffects_apply() {
    local preset="$1"

    command -v easyeffects &>/dev/null || return 1

    # Check for preset file
    local preset_file="${_AUD_EQ_DIR}/${preset}.json"
    if [[ ! -f "$preset_file" ]]; then
        # Search in standard locations
        for search_dir in \
            "$_AUD_EQ_DIR" \
            "/usr/share/easyeffects/output" \
            "${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/output"; do
            [[ -f "${search_dir}/${preset}.json" ]] && \
                preset_file="${search_dir}/${preset}.json" && break
        done
    fi

    if [[ -f "$preset_file" ]]; then
        aud_step "Applying EasyEffects preset: ${preset}..."
        easyeffects --load-preset "$preset" 2>/dev/null && \
            aud_ok "EasyEffects preset applied: ${preset}" || \
            aud_warn "EasyEffects could not load preset"
        return 0
    fi

    return 1
}

_eq_list_easyeffects() {
    local -a ee_presets=()
    for dir in \
        "$_AUD_EQ_DIR" \
        "${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/output" \
        "/usr/share/easyeffects/output"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            ee_presets+=("$(basename "$f" .json)")
        done < <(find "$dir" -name '*.json' 2>/dev/null | sort)
    done

    if [[ ${#ee_presets[@]} -gt 0 ]]; then
        printf '\n  %sEasyEffects presets:%s\n' "$(_adim)" "$(_ar)"
        for p in "${ee_presets[@]}"; do
            printf '    %s•%s  %s%s%s\n' \
                "$(_adim)" "$(_ar)" "$(_agreen)" "$p" "$(_ar)"
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_audio_eq() {
    local preset=""  list_mode=0  show_visual=1

    for arg in "${@:-}"; do
        case "$arg" in
            --list|-l)        list_mode=1    ;;
            --no-visual)      show_visual=0  ;;
            *)  [[ -z "$preset" ]] && preset="$arg" ;;
        esac
    done

    aud_section "🎛️ " "Equalizer" "$(_ateal)"
    aud_kv "Backend" "$AUD_BACKEND"

    if [[ $list_mode -eq 1 ]]; then
        printf '\n  %sBuilt-in presets:%s\n\n' "$(_abold)" "$(_ar)"
        printf '  %s%-16s  %s%s\n' "$(_adim)" "Preset" "Description" "$(_ar)"
        printf '  %s%s%s\n' "$(_adim)" "$(printf '─%.0s' $(seq 1 55))" "$(_ar)"

        for preset_name in $(printf '%s\n' "${!_EQ_PRESETS[@]}" | sort); do
            local desc="${_EQ_DESCRIPTIONS[$preset_name]:-}"
            local ee_mark=""
            [[ -f "${_AUD_EQ_DIR}/${preset_name}.json" ]] && \
                ee_mark=" ${_ateal}[EE]${_ar}"
            printf '  %s%-16s%s  %s%s%s%s\n' \
                "$(_agreen)" "$preset_name" "$(_ar)" \
                "$(_adim)" "$desc" "$(_ar)" "$ee_mark"
        done

        _eq_list_easyeffects
        printf '\n'
        return 0
    fi

    # Interactive picker if no preset given
    if [[ -z "$preset" ]]; then
        if command -v fzf &>/dev/null; then
            preset="$(for p in $(printf '%s\n' "${!_EQ_PRESETS[@]}" | sort); do
                printf '%-16s  %s\n' "$p" "${_EQ_DESCRIPTIONS[$p]:-}"
            done | \
                fzf --prompt "  🎛️   EQ Preset: " \
                    --height=15 \
                    --border=rounded \
                    --color="hl:$(_ateal | sed 's/\033\[//;s/m//')" \
                    --header="ESC to cancel" \
                    2>/dev/null | awk '{print $1}' || echo '')"
        fi

        [[ -z "$preset" ]] && {
            aud_info "No preset selected. Run: ash audio eq --list"
            printf '\n'; return 0
        }
    fi

    # Check if preset exists
    if [[ -z "${_EQ_PRESETS[$preset]:-}" ]]; then
        # Try EasyEffects preset
        if ! _eq_easyeffects_apply "$preset"; then
            aud_fail "Unknown EQ preset: ${preset}"
            aud_info "Run: ash audio eq --list  to see available presets"
            return 1
        fi
    else
        aud_kv "Preset"   "$preset"
        aud_kv "Desc"     "${_EQ_DESCRIPTIONS[$preset]:-}"

        # Show visual EQ
        [[ $show_visual -eq 1 ]] && _eq_visual "$preset"

        # Try EasyEffects first
        if ! _eq_easyeffects_apply "$preset" 2>/dev/null; then
            # PipeWire filter-chain (eqfa10p) fallback
            if command -v pw-cli &>/dev/null; then
                aud_info "EasyEffects not running — PipeWire EQ not yet applied"
                aud_info "Start EasyEffects for persistent EQ: easyeffects &"
            else
                aud_info "Install EasyEffects for EQ: paru -S easyeffects"
            fi
        fi
    fi

    aud_notify "🎛️  EQ" "Preset: ${preset}"

    printf '\n'
}
