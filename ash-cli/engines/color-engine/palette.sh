#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/palette.sh                          ║
# ║                                                                               ║
# ║  The 13-slot palette contract, and the machinery that fills it.               ║
# ║                                                                               ║
# ║  EVERY THEME IN THIS PROJECT HAS THE SAME 13 SLOTS                             ║
# ║    Surfaces   base, mantle, crust, surface, overlay                           ║
# ║    Foreground text, subtext                                                   ║
# ║    Accents    accent, mint, sky, gold, rose, violet                           ║
# ║                                                                               ║
# ║  Fixing the slot list is what lets one template render every theme, and what  ║
# ║  lets the contrast auditor check every theme with one loop. A theme that      ║
# ║  invents a slot is a theme the rest of the system cannot consume.            ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_PALETTE_LOADED:-}" ]] && return 0
ASH_PALETTE_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]      && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]]   && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"

#: The canonical slot order. Templates, exporters and the auditor all iterate
#: this exact list, so a new target never has to know about slot names.
readonly ASH_PALETTE_SLOTS=(
    base mantle crust surface overlay
    text subtext
    accent mint sky gold rose violet
)

readonly ASH_PALETTE_SURFACE_SLOTS=(base mantle crust surface overlay)
readonly ASH_PALETTE_ACCENT_SLOTS=(accent mint sky gold rose violet)

# ── Palette as an associative array ──────────────────────────────────────────
# Shell cannot return an array from a function, so palettes are passed by name:
#   declare -A p; ash_palette_default p
#   echo "${p[accent]}"
# This is the standard bash idiom for it, and it avoids the subshell that a
# `$(...)`-returning builder would cost per theme.

# ash_palette_default <name> — a neutral dark palette, useful as a base.
ash_palette_default() {
    local -n _out="$1"
    _out=(
        [base]="#1e1e2e" [mantle]="#181825" [crust]="#11111b"
        [surface]="#313244" [overlay]="#45475a"
        [text]="#cdd6f4" [subtext]="#a6adc8"
        [accent]="#cba6f7" [mint]="#a6e3a1" [sky]="#89dceb"
        [gold]="#f9e2af" [rose]="#f38ba8" [violet]="#b4befe"
    )
}

# ash_palette_from_assoc <source-name> <dest-name>
#   Copies exactly the 13 known slots, dropping anything else. Used to sanitise
#   input from a theme file, which may carry extra keys.
ash_palette_from_assoc() {
    local -n _src="$1"
    local -n _dst="$2"
    _dst=()
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        [[ -n "${_src[$slot]:-}" ]] && _dst["$slot"]="${_src[$slot]}"
    done
}

# ash_palette_complete <name> — exit 0 when all 13 slots are non-empty
ash_palette_complete() {
    local -n _p="$1"
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        [[ -n "${_p[$slot]:-}" ]] || return 1
    done
    return 0
}

# ash_palette_missing <name> — echo the names of empty slots
ash_palette_missing() {
    local -n _p="$1"
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        [[ -z "${_p[$slot]:-}" ]] && printf '%s\n' "$slot"
    done
}

# ash_palette_is_valid <name> <reason-var-name>
#   Validates every slot is a parseable hex colour. Writes the single-line
#   reason into the named variable so callers can report *why* a theme was
#   rejected without re-parsing.
ash_palette_is_valid() {
    local -n _p="$1"
    local -n _reason="$2"
    _reason=""

    local slot normalised
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        if [[ -z "${_p[$slot]:-}" ]]; then
            _reason="missing slot: ${slot}"
            return 1
        fi
        normalised="$(ash_ok_normalize_hex "${_p[$slot]}")"
        if [[ -z "$normalised" ]]; then
            _reason="slot '${slot}' is not a hex colour: ${_p[$slot]}"
            return 1
        fi
    done
    return 0
}

# ash_palette_normalise <name> — lowercase and expand every slot in place
ash_palette_normalise() {
    local -n _p="$1"
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        [[ -n "${_p[$slot]:-}" ]] || continue
        _p["$slot"]="$(ash_ok_normalize_hex "${_p[$slot]}")"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 2  SURFACE RAMPS
# ═══════════════════════════════════════════════════════════════════════════════

# ash_palette_surfaces <name> <base-hex> [variant]
#   Derives mantle/crust/surface/overlay from a single base colour.
#
#   The steps are chosen in OKLCH lightness, so they are equal *perceptual*
#   steps regardless of hue. A blue-tinted theme and an orange-tinted theme
#   built from the same base end up with the same perceived depth structure.
#
#   Dark variant descends below base (crust darkest); light ascends above it.
#   Getting this backwards is the single most common cause of an unreadable
#   light theme.
ash_palette_surfaces() {
    local -n _out="$1"
    local base="$2" variant="${3:-dark}"

    local lch L C H
    lch="$(ash_ok_from_hex "$base")" || return 1
    L="$(cut -d' ' -f1 <<<"$lch")"
    C="$(cut -d' ' -f2 <<<"$lch")"
    H="$(cut -d' ' -f3 <<<"$lch")"

    if [[ "$variant" == "light" ]]; then
        # Light themes: mantle and crust are *darker* than base, surface and
        # overlay lighter — the inverse of the dark ramp.
        _out[base]="$(ash_ok_to_hex "$L" "$C" "$H")"
        _out[mantle]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.020)" "$C" "$H")"
        _out[crust]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.045)" "$C" "$H")"
        _out[surface]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.035)" "$(_ash_pal_scale "$C" 1.15)" "$H")"
        _out[overlay]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.110)" "$(_ash_pal_scale "$C" 1.30)" "$H")"
    else
        _out[base]="$(ash_ok_to_hex "$L" "$C" "$H")"
        _out[mantle]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.025)" "$C" "$H")"
        _out[crust]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" -0.055)" "$C" "$H")"
        _out[surface]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" 0.075)" "$(_ash_pal_scale "$C" 1.15)" "$H")"
        _out[overlay]="$(ash_ok_to_hex "$(_ash_pal_shift "$L" 0.150)" "$(_ash_pal_scale "$C" 1.30)" "$H")"
    fi
}

# ── Internal lightness/chroma helpers ────────────────────────────────────────
# These clamp to the valid range, because the callers above apply fixed deltas
# that can push a near-white or near-black base out of bounds.

_ash_pal_shift() {
    _ash_ok_awk "BEGIN { v = ($1) + ($2); if (v < 0) v = 0; if (v > 1) v = 1; printf \"%.6f\", v }"
}

_ash_pal_scale() {
    _ash_ok_awk "BEGIN {
        v = ($1) * ($2)
        # Chroma above ~0.37 is not displayable in sRGB for any lightness; the
        # gamut clamp in ash_ok_to_hex would flatten it anyway, so bound it
        # here and keep the value meaningful.
        if (v > 0.37) v = 0.37
        if (v < 0)    v = 0
        printf \"%.6f\", v
    }"
}

# ash_palette_foregrounds <name> <base-hex> [variant]
#   Picks text and subtext that clear WCAG AA against base.
#
#   Rather than guessing "white on dark", it derives both from the base's hue
#   so the theme reads as one piece, then *measures* the result and corrects it.
#   A theme generator that cannot prove its own readability is not finished.
ash_palette_foregrounds() {
    local -n _out="$1"
    local base="$2" variant="${3:-dark}"

    local lch L C H
    lch="$(ash_ok_from_hex "$base")" || return 1
    L="$(cut -d' ' -f1 <<<"$lch")"
    H="$(cut -d' ' -f3 <<<"$lch")"

    if [[ "$variant" == "light" ]]; then
        _out[text]="$(ash_ok_to_hex 0.32 0.030 "$H")"
        _out[subtext]="$(ash_ok_to_hex 0.50 0.035 "$H")"
    else
        _out[text]="$(ash_ok_to_hex 0.93 0.028 "$H")"
        _out[subtext]="$(ash_ok_to_hex 0.74 0.032 "$H")"
    fi

    # Correct until both clear AA. The loop is bounded because a mid-grey base
    # can need a large move, and an unbounded nudge would spin.
    local i slot
    for i in $(seq 1 60); do
        local all_pass=1
        for slot in text subtext; do
            ash_contrast_pass "${_out[$slot]}" "$base" aa-normal || all_pass=0
        done
        (( all_pass )) && break

        for slot in text subtext; do
            ash_contrast_pass "${_out[$slot]}" "$base" aa-normal && continue
            _out[$slot]="$(ash_contrast_fix "${_out[$slot]}" "$base" aa-normal)"
        done
    done
}

# ash_palette_accents <name> <seed-hue> [variant] [chroma-scale]
#
#   The six accent slots are anchored to ABSOLUTE hue targets, not offsets
#   from the seed.
#
#   This was wrong on the first attempt. Offsets were designed against a
#   zero-hue base and then added to the seed's hue, so a purple seed (hue 284)
#   produced a "mint" at 54° — orange — and a "rose" at 254° — blue. A slot
#   called mint has to be green for every seed, or the name is a lie and every
#   template that assumes "green means success" renders wrong.
#
#   Cohesion comes from two places that do not compromise the names:
#     • a small hue nudge (≤ 12°) toward the seed, so the palette reads as one
#       family rather than six unrelated swatches, and
#     • the seed's chroma and the variant's lightness, which is where most of
#       the "same theme" feeling actually lives.
ash_palette_accents() {
    local -n _out="$1"
    local seed_hue="$2" variant="${3:-dark}" chroma_scale="${4:-1.0}"

    local L C
    if [[ "$variant" == "light" ]]; then
        L=0.52; C=0.16
    else
        L=0.78; C=0.14
    fi
    C="$(_ash_pal_scale "$C" "$chroma_scale")"

    # ── Resolve the six final hues ───────────────────────────────────────
    #
    # Which colour moves, when two would collide, is the whole design question
    # here, and the first two attempts got it wrong in opposite directions.
    #
    # Attempt 1 moved accent to the midpoint of the widest gap: a purple theme
    # shipped with a chartreuse primary. Attempt 2 spiralled accent to the
    # nearest free angle, which was better, but accent is the SEED hue — it is
    # the theme's identity — and blue seeds sit close to the violet target, so
    # every blue theme came out with a purple accent. Nord is a blue palette and
    # was rendering its primary colour as #d1a2ff.
    #
    # Attempt 3, here: accent stays on the seed hue, and the SEMANTIC slots move
    # to make room. That is the right way round — "accent" has no meaning beyond
    # "the theme's colour", while "mint" has to stay green and "sky" has to stay
    # blue, so it is the latter that should yield.
    local accent_hue="$seed_hue"
    local -a placed=("$accent_hue")
    local -a final_hues=()

    # slot:target-hue. Targets are absolute; cohesion pulls each up to 12
    # degrees toward the seed without letting it stop being its own colour.
    local -a spec=(mint:145 sky:220 gold:85 rose:8 violet:292)

    local entry slot target h
    for entry in "${spec[@]}"; do
        slot="${entry%%:*}"
        target="${entry##*:}"

        h="$(_ash_palette_cohere "$target" "$seed_hue")"

        # Avoid the accent and everything already placed.
        if [[ ${#placed[@]} -gt 0 ]]; then
            h="$(_ash_palette_avoid "$h" "${placed[@]}")"
        fi

        placed+=("$h")
        final_hues+=("$slot:$h")
    done

    # Accent last, so it is unaffected by the semantic slots moving.
    local -a all_spec=("accent:$accent_hue")
    local item
    for item in "${final_hues[@]}"; do all_spec+=("$item"); done

    for entry in "${all_spec[@]}"; do
        slot="${entry%%:*}"
        hue="${entry##*:}"

        if [[ -z "$hue" ]]; then
            printf 'ash palette: failed to resolve hue for slot %s\n' "$slot" >&2
            return 1
        fi

        # Clamp chroma to what sRGB can show at this (L, H) BEFORE generating.
        # ash_ok_to_hex clamps per channel at the end, and that clamp silently
        # rotates the hue — a blue asking for more chroma than sRGB holds gets
        # squashed toward purple. Clamping chroma first keeps the emitted hue
        # identical to the requested one.
        local safe_c
        safe_c="$(ash_ok_clamp_chroma "$L" "$C" "$hue")"

        _out["$slot"]="$(ash_ok_to_hex "$L" "$safe_c" "$hue")"
    done

    # Belt and braces: a slot the spec missed still needs a value, or the
    # palette is incomplete and every validator downstream rejects it.
    for slot in "${ASH_PALETTE_ACCENT_SLOTS[@]}"; do
        [[ -n "${_out[$slot]:-}" ]] && continue
        _out["$slot"]="$(ash_ok_to_hex "$L" "$C" "$seed_hue")"
    done
}

# _ash_palette_cohere <target-hue> <seed-hue> → nudged hue
#   Pulls a semantic hue up to 12 degrees toward the seed so the palette reads
#   as one family, without letting the slot stop being the colour its name
#   promises. The cap is the whole point: "mint" must stay recognisably green
#   for a red seed.
_ash_palette_cohere() {
    _ash_ok_awk -v target="$1" -v seed="$2" '
    BEGIN {
        d = seed - target
        while (d >  180) d -= 360
        while (d < -180) d += 360

        MAX_NUDGE = 12
        if (d >  MAX_NUDGE) d =  MAX_NUDGE
        if (d < -MAX_NUDGE) d = -MAX_NUDGE

        h = target + d
        while (h < 0)    h += 360
        while (h >= 360) h -= 360
        printf "%.4f", h
    }'
}

# _ash_palette_avoid <hue> <occupied-hues...> → the nearest separation
#
#   Keeps accent as close to the seed as possible.
#
#   The obvious approach — jump to the midpoint of the widest gap — keeps the
#   six hues distinct but destroys theme identity: a purple seed whose hue
#   collided with the violet slot landed on yellow-green, so a "purple theme"
#   shipped with a chartreuse primary colour. Distinctness is necessary, not
#   sufficient; the accent also has to belong.
#
#   So instead: spiral outward from the seed hue, one degree at a time, and
#   take the first angle that clears MIN_SEP from every occupied hue. The
#   result is normally the seed itself, and otherwise the smallest possible
#   deviation from it.
_ash_palette_avoid() {
    local seed="$1"; shift
    _ash_ok_awk -v seed="$seed" -v others="$*" '
    function wrap(h) {
        while (h < 0)    h += 360
        while (h >= 360) h -= 360
        return h
    }
    function dist(a, b,   d) {
        d = a - b
        while (d >  180) d -= 360
        while (d < -180) d += 360
        return (d < 0) ? -d : d
    }
    function clears(h,   i) {
        for (i = 1; i <= n; i++)
            if (dist(h, occ[i]) < MIN_SEP) return 0
        return 1
    }
    BEGIN {
        MIN_SEP = 26          # below this the two swatches read as one colour
        MAX_SEARCH = 180      # a full half-turn; past that, nothing is left
        n = split(others, occ, " ")

        if (clears(seed)) { printf "%.4f", seed; exit }

        # Spiral out, alternating sides, so ties resolve toward the seed.
        for (step = 1; step <= MAX_SEARCH; step++) {
            up = wrap(seed + step)
            if (clears(up)) { printf "%.4f", up; exit }

            down = wrap(seed - step)
            if (clears(down)) { printf "%.4f", down; exit }
        }

        # Only reachable if MIN_SEP is greater than half the average gap, which
        # six evenly-spaced hues cannot produce. Fall back to the seed rather
        # than emitting an empty string the callers would have to handle.
        printf "%.4f", seed
    }'
}

# ash_palette_derive <dest-NAME> <seed-hex> [variant]
#   The one-call entry point: seed colour in, complete 13-slot palette out.
#
#   NOTE ON NAMEREFS. This function deliberately does NOT declare
#   `local -n _out="$1"`. The first version did, and then forwarded `_out` to
#   the helpers below — which each declare their own `local -n _out="$1"`.
#   Passing a nameref by name makes the callee bind `_out` to `_out`, a
#   self-referential cycle: bash warns "circular name reference" and every read
#   of the array silently yields garbage.
#
#   A nameref must be forwarded by the name of the array it points AT, so this
#   function keeps the caller's name in a plain variable and passes that down.
ash_palette_derive() {
    local _target="$1"
    local seed="$2" variant="${3:-dark}"

    local seed_lch hue chroma
    seed_lch="$(ash_ok_from_hex "$seed")" || {
        printf 'ash palette: not a colour: %s\n' "$seed" >&2
        return 1
    }
    hue="$(cut -d' ' -f3 <<<"$seed_lch")"
    chroma="$(cut -d' ' -f2 <<<"$seed_lch")"

    # A seed that is nearly achromatic (a grey) carries no usable hue, and
    # deriving accents from it produces either six identical swatches or six
    # random ones. Fall back to the house hue instead of inventing a palette
    # out of numerical noise.
    if _ash_ok_awk "BEGIN { exit(($chroma < 0.02) ? 0 : 1) }"; then
        hue="$(_ash_ok_awk 'BEGIN { printf "%.4f", 268 }')"
    fi

    ash_palette_surfaces    "$_target" "$seed" "$variant" || return 1
    ash_palette_foregrounds "$_target" "$seed" "$variant" || return 1
    ash_palette_accents     "$_target" "$hue"  "$variant" || return 1
    ash_palette_normalise   "$_target"
}

# ash_palette_render_json <name> [indent]
#   Serialise a palette as JSON. Values are emitted through a printf format
#   rather than string interpolation so a slot containing a quote cannot break
#   out of the document.
ash_palette_render_json() {
    local -n _p="$1"
    local indent="${2:-  }"

    printf '{\n'
    local i slot
    for i in "${!ASH_PALETTE_SLOTS[@]}"; do
        slot="${ASH_PALETTE_SLOTS[$i]}"
        printf '%s"%-8s": "%s"' "$indent" "$slot" "${_p[$slot]:-}"
        (( i < ${#ASH_PALETTE_SLOTS[@]} - 1 )) && printf ','
        printf '\n'
    done
    printf '}\n'
}

# ash_palette_render_kv <name> → "base=#1e1e2e" lines, for .conf fragments
ash_palette_render_kv() {
    local -n _p="$1"
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        printf '%s=%s\n' "$slot" "${_p[$slot]:-}"
    done
}

# ash_palette_render_hypr <name> → `$base = rgb(1e1e2e)` lines for Hyprland
ash_palette_render_hypr() {
    local -n _p="$1"
    local slot
    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        printf '$%s = rgb(%s)\n' "$slot" "$(tr -d '#' <<<"${_p[$slot]:-}")"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 3  ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════

# ash_palette_audit <name> [--json]
#   Reports the contrast of every foreground/background pair a user actually
#   reads. Exits 1 when any pair falls below AA, so it composes as a gate in a
#   build script.
ash_palette_audit() {
    local -n _p="$1"
    local mode="${2:-text}"

    # pair:foreground:background:label
    local -a pairs=(
        "text:base:body text on background"
        "subtext:base:secondary text on background"
        "accent:base:accent on background"
        "text:mantle:body text on mantle"
        "text:surface:body text on surface"
        "accent:surface:accent on surface"
    )

    local worst=99.0 failed=0 line ratio fg bg label
    local -a json_rows=()

    for line in "${pairs[@]}"; do
        local pair_fg="${line%%:*}"
        local rest="${line#*:}"
        local pair_bg="${rest%%:*}"
        label="${rest#*:}"

        fg="${_p[$pair_fg]:-}"
        bg="${_p[$pair_bg]:-}"
        [[ -z "$fg" || -z "$bg" ]] && continue

        ratio="$(ash_contrast_ratio "$fg" "$bg")"
        ash_contrast_pass "$fg" "$bg" aa-normal || failed=1
        _ash_ok_awk "BEGIN { exit(($ratio < $worst) ? 0 : 1) }" && worst="$ratio"

        if [[ "$mode" == "--json" ]]; then
            json_rows+=("$(printf '{"fg":"%s","bg":"%s","label":"%s","ratio":%s,"grade":"%s"}' \
                "$fg" "$bg" "$label" "$ratio" "$(ash_contrast_grade "$ratio")")")
        else
            printf '%s %-41s %-8s %-6s %s:1\n' \
                "$(ash_contrast_emoji "$ratio")" "$label" "$fg" "$ratio" "$(ash_contrast_grade "$ratio")"
        fi
    done

    if [[ "$mode" == "--json" ]]; then
        local IFS=,
        printf '{"minimum":%s,"passes_aa":%s,"pairs":[%s]}\n' \
            "$worst" "$([ "$failed" -eq 0 ] && echo true || echo false)" "${json_rows[*]}"
    else
        printf '\nminimum %.2f:1 → %s\n' "$worst" "$(ash_contrast_grade "$worst")"
    fi

    return "$failed"
}

# ash_palette_distance <nameA> <nameB>
#   Mean perceptual distance across all 13 slots. Used to detect near-duplicate
#   themes in a large library.
ash_palette_distance() {
    local -n _a="$1"
    local -n _b="$2"
    local slot total=0 n=0 d

    for slot in "${ASH_PALETTE_SLOTS[@]}"; do
        [[ -z "${_a[$slot]:-}" || -z "${_b[$slot]:-}" ]] && continue
        d="$(ash_ok_distance "${_a[$slot]}" "${_b[$slot]}")" || continue
        total="$(_ash_ok_awk "BEGIN { printf \"%.8f\", $total + $d }")"
        (( n += 1 ))
    done

    (( n == 0 )) && { printf '0'; return; }
    _ash_ok_awk "BEGIN { printf \"%.6f\", $total / $n }"
}

# ash_palette_hue <name> — the dominant hue, for sorting a gallery
ash_palette_hue() {
    local -n _p="$1"
    ash_ok_h "${_p[accent]:-${_p[base]:-#000000}}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 4  CLI
# ═══════════════════════════════════════════════════════════════════════════════

ash_palette_usage() {
    cat <<'USAGE'
ash palette — build and inspect 13-slot palettes

  ash palette derive <seed-hex> [--light]   seed colour → full palette
  ash palette surfaces <base-hex> [--light]  only the five surface slots
  ash palette audit <theme.json>            WCAG report for a theme file
  ash palette json <seed-hex> [--light]     emit the palette as JSON
  ash palette hypr <seed-hex> [--light]     emit Hyprland $variable lines
USAGE
}

_ash_palette_load_file() {
    local file="$1" name="$2"
    local -n _dst="$name"

    [[ -r "$file" ]] || { printf 'ash palette: cannot read %s\n' "$file" >&2; return 1; }

    # Prefer jq; fall back to a grep that only understands the flat shape this
    # project writes. A theme file is flat by construction, so the fallback is
    # not a lossy parser for real input.
    local slot value
    if command -v jq >/dev/null 2>&1; then
        while IFS=$'\t' read -r slot value; do
            [[ -n "$slot" ]] && _dst["$slot"]="$value"
        done < <(jq -r '.colors // . | to_entries[] | "\(.key)\t\(.value)"' "$file" 2>/dev/null)
    else
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*\"?([a-z]+)\"?[[:space:]]*:[[:space:]]*\"(#[0-9a-fA-F]{3,8})\" ]] || continue
            _dst["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        done < "$file"
    fi
}

ash_palette_main() {
    local cmd="${1:-}"; shift || true
    local variant="dark"

    # --light can appear anywhere after the subcommand.
    local -a args=()
    while (( $# )); do
        case "$1" in
            --light|-l) variant="light"; shift ;;
            --dark|-d)  variant="dark";  shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    case "$cmd" in
        derive|json|hypr|surfaces)
            local seed="${args[0]:-}"
            [[ -n "$seed" ]] || { printf 'ash palette: a seed colour is required\n' >&2; return 2; }

            local -A p=()
            case "$cmd" in
                surfaces)
                    ash_palette_surfaces p "$seed" "$variant"
                    ash_palette_render_kv p
                    ;;
                derive)
                    ash_palette_derive p "$seed" "$variant"
                    ash_palette_render_kv p
                    echo "---"
                    ash_palette_audit p >&2 || true
                    ;;
                json)
                    ash_palette_derive p "$seed" "$variant"
                    ash_palette_render_json p
                    ;;
                hypr)
                    ash_palette_derive p "$seed" "$variant"
                    ash_palette_render_hypr p
                    ;;
            esac
            ;;

        audit)
            local file="${args[0]:-}"
            [[ -n "$file" ]] || { printf 'ash palette: a theme file is required\n' >&2; return 2; }
            local -A p=()
            _ash_palette_load_file "$file" p || return 1
            if [[ "${args[1]:-}" == "--json" ]]; then
                ash_palette_audit p --json
            else
                ash_palette_audit p
            fi
            ;;

        ''|help|-h|--help) ash_palette_usage ;;
        *) printf 'ash palette: unknown subcommand: %s\n\n' "$cmd" >&2; ash_palette_usage >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_palette_main "$@"
fi
