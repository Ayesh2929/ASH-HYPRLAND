#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/harmonize.sh                        ║
# ║                                                                               ║
# ║  Classical colour-harmony schemes, plus palette repair.                        ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_HARMONIZE_LOADED:-}" ]] && return 0
ASH_HARMONIZE_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]   && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"

# ash_harmony_scheme <scheme> <base-hex> [variant]
#   Echoes the hues (one per line, degrees) for a named scheme.
#
#   Offsets are standard colour-theory relationships. They are applied as hue
#   ROTATIONS of the base, then each result is clamped back into gamut — a
#   rotation can push chroma past what sRGB holds at that lightness.
ash_harmony_scheme() {
    local scheme="$1" base="$2" variant="${3:-dark}"

    local lch hue chroma
    lch="$(ash_ok_from_hex "$base")" || return 1
    hue="$(cut -d' ' -f3 <<<"$lch")"
    chroma="$(cut -d' ' -f2 <<<"$lch")"

    local -a offsets
    case "$scheme" in
        complementary)    offsets=(0 180) ;;
        analogous)        offsets=(-30 -15 0 15 30) ;;
        triadic)          offsets=(0 120 240) ;;
        tetradic|square)  offsets=(0 90 180 270) ;;
        split-complementary) offsets=(0 150 210) ;;
        monochromatic)    offsets=(0 0 0 0 0) ;;
        # Rectangular is the term used in most paint and design references;
        # "square" is the same thing rotated 45 degrees, so both names map here.
        *)
            printf 'ash harmonize: unknown scheme: %s\n' "$scheme" >&2
            printf '  try: complementary, analogous, triadic, tetradic, split-complementary, monochromatic\n' >&2
            return 2
            ;;
    esac

    local off
    for off in "${offsets[@]}"; do
        _ash_ok_awk "BEGIN {
            h = ($hue) + ($off)
            while (h < 0)    h += 360
            while (h >= 360) h -= 360
            printf \"%.4f\n\", h
        }"
    done
}

# ash_harmony_apply <dest-slot-array-NAME> <scheme> <base-hex> [variant]
#   Writes a scheme's colours into the accent slots, cycling if the scheme has
#   fewer colours than there are slots.
ash_harmony_apply() {
    local -n _out="$1"
    local scheme="$2" base="$3" variant="${4:-dark}"

    local -a hues=()
    while IFS= read -r h; do hues+=("$h"); done < <(ash_harmony_scheme "$scheme" "$base" "$variant")
    (( ${#hues[@]} == 0 )) && return 1

    local L C
    if [[ "$variant" == "light" ]]; then L=0.52; C=0.16; else L=0.78; C=0.14; fi

    local i slot hue
    for i in "${!ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        slot="${ASH_PALETTE_ACCENT_SLOTS[$i]}"
        hue="${hues[$(( i % ${#hues[@]} ))]}"

        # Monochromatic schemes have one hue; vary lightness across the slots
        # instead, or every accent would be the identical swatch.
        local slot_L="$L"
        if [[ ${#hues[@]} -eq 1 ]]; then
            slot_L="$(_ash_ok_awk "BEGIN {
                v = $L + ($i - 2) * 0.055
                if (v < 0.35) v = 0.35
                if (v > 0.92) v = 0.92
                printf \"%.4f\", v
            }")"
        fi

        local safe_c; safe_c="$(ash_ok_clamp_chroma "$slot_L" "$C" "$hue")"
        _out["$slot"]="$(ash_ok_to_hex "$slot_L" "$safe_c" "$hue")"
    done
}

# ash_harmony_repair <dest-NAME> <source-NAME> [threshold]
#   Fixes a palette whose accents have drifted too close together.
#
#   This is the repair path for hand-authored themes. People pick six accents by
#   eye, and two of them end up 8 degrees apart — fine in a swatch sheet,
#   indistinguishable as a status dot. Repair rotates the offending accents away
#   from their nearest neighbour, keeping lightness and chroma untouched.
ash_harmony_repair() {
    local -n _out="$1"
    local -n _src="$2"
    local threshold="${3:-25}"

    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        _out["$slot"]="${_src[$slot]:-}"
    done

    # Collect the accents that actually need separating.
    local -a kept_hues=()
    local moved=0

    for slot in "${ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        local hex="${_out[$slot]:-}"
        [[ -n "$hex" ]] || continue

        local lch L C H
        lch="$(ash_ok_from_hex "$hex")"
        L="$(cut -d' ' -f1 <<<"$lch")"
        C="$(cut -d' ' -f2 <<<"$lch")"
        H="$(cut -d' ' -f3 <<<"$lch")"

        # Too close to something already placed?
        local conflict=0
        local prev
        for prev in "${kept_hues[@]:-}"; do
            [[ -n "$prev" ]] || continue
            local d
            d="$(_ash_ok_awk "BEGIN {
                d = $H - $prev
                while (d >  180) d -= 360
                while (d < -180) d += 360
                if (d < 0) d = -d
                printf \"%.4f\", d
            }")"
            if _ash_ok_awk "BEGIN { exit(($d < $threshold) ? 0 : 1) }"; then
                conflict=1
                break
            fi
        done

        if (( conflict )); then
            # Rotate away until clear. Bounded at a half-turn, since past that
            # the search wraps and we would revisit angles already rejected.
            local step new_h="" candidate
            for (( step = 1; step <= 180; step++ )); do
                for candidate in "$(( ${H%.*} + step ))" "$(( ${H%.*} - step ))"; do
                    local wrapped
                    wrapped="$(_ash_ok_awk "BEGIN {
                        h = $candidate
                        while (h < 0)    h += 360
                        while (h >= 360) h -= 360
                        printf \"%.4f\", h
                    }")"

                    local ok=1
                    for prev in "${kept_hues[@]:-}"; do
                        [[ -n "$prev" ]] || continue
                        local dd
                        dd="$(_ash_ok_awk "BEGIN {
                            d = $wrapped - $prev
                            while (d >  180) d -= 360
                            while (d < -180) d += 360
                            if (d < 0) d = -d
                            printf \"%.4f\", d
                        }")"
                        _ash_ok_awk "BEGIN { exit(($dd >= $threshold) ? 0 : 1) }" || { ok=0; break; }
                    done

                    if (( ok )); then new_h="$wrapped"; break 2; fi
                done
            done

            if [[ -n "$new_h" ]]; then
                local safe_c; safe_c="$(ash_ok_clamp_chroma "$L" "$C" "$new_h")"
                _out["$slot"]="$(ash_ok_to_hex "$L" "$safe_c" "$new_h")"
                H="$new_h"
                (( moved += 1 ))
            fi
        fi

        kept_hues+=("$H")
    done

    ASH_HARMONY_MOVED="$moved"
    return 0
}

# ash_harmony_rotate <dest-NAME> <source-NAME> <degrees>
#   Rotates every accent hue by a fixed amount. This is the "shift the whole
#   palette" control in the theme editor.
ash_harmony_rotate() {
    local -n _out="$1"
    local -n _src="$2"
    local degrees="$3"

    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        _out["$slot"]="${_src[$slot]:-}"
    done

    for slot in "${ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        [[ -n "${_out[$slot]:-}" ]] || continue
        _out["$slot"]="$(ash_ok_rotate "${_out[$slot]}" "$degrees")"
    done
}

# ash_harmony_temperature <hex> → warm | cool | neutral
ash_harmony_temperature() {
    local h c
    h="$(ash_ok_h "$1")" || return 1
    c="$(ash_ok_c "$1")" || return 1

    # With almost no chroma the hue is numerical noise: #888888 reports 89.8
    # degrees and would be called "warm". Below this chroma the eye cannot see
    # a tint at all, so the honest answer is neutral.
    if _ash_ok_awk "BEGIN { exit(($c < 0.01) ? 0 : 1) }"; then
        printf 'neutral'
        return 0
    fi
    # Thresholds are in OKLCH degrees, which are NOT the HSL degrees most
    # people have in mind. On the OKLCH wheel: red 29, orange 60, yellow 110,
    # green 142, cyan 195, blue 264, magenta 328, pink 350. Classifying with
    # the HSL boundaries put yellow (110) in "neutral", which is plainly wrong.
    _ash_ok_awk "BEGIN {
        h = $h
        if (h <= 115 || h >= 325)       print \"warm\"     # red - yellow, plus magenta/pink
        else if (h >= 160 && h <= 290)  print \"cool\"     # teal - blue
        else                            print \"neutral\"  # the green/yellow and violet gaps
    }"
}

# ash_harmony_score <name>
#   Heuristic 0-1 score for how well a palette hangs together. Combines accent
#   separation, contrast compliance and chroma consistency. Used to sort a
#   theme gallery by "polish".
ash_harmony_score() {
    local -n _p="$1"

    # 1. Accent separation, normalised: 30 degrees or more is full marks.
    local hues=() slot
    for slot in "${ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        [[ -n "${_p[$slot]:-}" ]] && hues+=("$(ash_ok_h "${_p[$slot]}")")
    done

    # Scored on the CLOSEST pair, not the average.
    #
    # Averaging over 30 pairs hid the problem it exists to detect: a palette
    # with one 4-degree collision and five well-spaced accents scored 0.93,
    # identical to the repaired palette, because four degrees is invisible in a
    # mean of thirty. The minimum separation is what a user actually notices.
    local sep_min=999 a b i j
    for (( i = 0; i < ${#hues[@]}; i++ )); do
        for (( j = i + 1; j < ${#hues[@]}; j++ )); do
            a="${hues[i]}"; b="${hues[j]}"
            local d
            d="$(_ash_ok_awk "BEGIN {
                d = $a - $b
                while (d >  180) d -= 360
                while (d < -180) d += 360
                if (d < 0) d = -d
                printf \"%.4f\", d
            }")"
            _ash_ok_awk "BEGIN { exit(($d < $sep_min) ? 0 : 1) }" && sep_min="$d"
        done
    done

    local sep_score=0
    (( ${#hues[@]} >= 2 )) && sep_score="$(_ash_ok_awk "BEGIN {
        v = $sep_min / 30
        if (v > 1) v = 1
        printf \"%.6f\", v
    }")"

    # 2. Contrast, capped at AAA.
    local ratio; ratio="$(ash_contrast_ratio "${_p[text]:-${_p[base]}}" "${_p[base]:-}")"
    local contrast_score; contrast_score="$(_ash_ok_awk "BEGIN {
        v = ($ratio - 3) / (7 - 3)
        if (v < 0) v = 0
        if (v > 1) v = 1
        printf \"%.6f\", v
    }")"

    # 3. Chroma consistency, scored by the spread of accent chroma.
    local cmin=99 cmax=0 c
    for slot in "${ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        [[ -n "${_p[$slot]:-}" ]] || continue
        c="$(ash_ok_c "${_p[$slot]}")"
        _ash_ok_awk "BEGIN { exit(($c < $cmin) ? 0 : 1) }" && cmin="$c"
        _ash_ok_awk "BEGIN { exit(($c > $cmax) ? 0 : 1) }" && cmax="$c"
    done
    local chroma_score; chroma_score="$(_ash_ok_awk "BEGIN {
        if ($cmax <= 0) { print 0; exit }
        printf \"%.6f\", 1 - ($cmax - $cmin) / $cmax
    }")"

    # Weighted: separation matters most (it is what users notice), contrast is
    # a correctness floor, chroma consistency is polish.
    _ash_ok_awk "BEGIN {
        printf \"%.4f\", 0.45*$sep_score + 0.40*$contrast_score + 0.15*$chroma_score
    }"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        scheme)      ash_harmony_scheme "${2:?}" "${3:?}" "${4:-dark}" ;;
        temperature) ash_harmony_temperature "${2:?}" ;;
        *)
            cat <<'USAGE'
usage: harmonize.sh scheme <scheme> <base-hex> [dark|light]
       harmonize.sh temperature <hex>
schemes: complementary, analogous, triadic, tetradic, split-complementary, monochromatic
USAGE
            exit 2 ;;
    esac
fi
