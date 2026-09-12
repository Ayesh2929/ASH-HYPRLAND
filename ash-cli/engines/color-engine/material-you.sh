#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/material-you.sh                     ║
# ║                                                                               ║
# ║  Material Design 3 tonal palettes.                                            ║
# ║                                                                               ║
# ║  Material You is not a colour scheme, it is a SET OF TONAL RAMPS: five hues    ║
# ║  (primary, secondary, tertiary, neutral, neutral-variant), each sampled at    ║
# ║  the same ten tones (0, 10, 20 … 100). Roles then pick a tone from a ramp,    ║
# ║  which is why Material apps stay consistent across light and dark.            ║
# ║                                                                               ║
# ║  The published spec defines its tones in HCT/CIELAB. This implements the same ║
# ║  *structure* in OKLCH, which this project already carries everywhere else.    ║
# ║  The two lightness scales agree closely over the mid range; where they        ║
# ║  differ, OKLCH keeps generated themes consistent with the rest of ASH.        ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_MATERIAL_LOADED:-}" ]] && return 0
ASH_MATERIAL_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]    && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]]  && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"

#: Material's ten tones, as OKLCH lightness. Tone 0 is black and 100 white in
#: the spec; here they are 0.0 and 1.0 with the rest following the same curve.
#: The published scale is not linear in perceived lightness, and neither is
#: this one — the mid tones are spaced slightly wider, matching the spec.
#: Includes Material's surface-container tones (4, 6, 12, 17, 22, 24, 87, 92,
#: 94, 96) alongside the headline ten. Without them a converted palette has
#: base and mantle on the same tone, which collapses the depth ramp that
#: Hyprland borders and Waybar layers rely on.
declare -gA ASH_M3_TONE_L=(
    [0]=0.00 [4]=0.115 [6]=0.135 [10]=0.20 [12]=0.225 [17]=0.265 [20]=0.31
    [22]=0.325 [24]=0.345 [30]=0.41 [40]=0.51 [50]=0.58 [60]=0.66
    [70]=0.74 [80]=0.82 [87]=0.875 [90]=0.91 [92]=0.925 [94]=0.94
    [95]=0.955 [96]=0.965 [98]=0.982 [99]=0.991 [100]=1.00
)

#: The tones every ramp is sampled at, in ascending order.
declare -ga ASH_M3_TONES=(0 4 6 10 12 17 20 22 24 30 40 50 60 70 80 87 90 92 94 95 96 98 99 100)

#: Chroma multipliers per tone. Material desaturates toward the extremes, and
#: a ramp with constant chroma looks synthetic at tone 10 and 95.
declare -gA ASH_M3_TONE_C=(
    [0]=0.00 [4]=0.22 [6]=0.28 [10]=0.45 [12]=0.50 [17]=0.57 [20]=0.62
    [22]=0.65 [24]=0.67 [30]=0.76 [40]=0.88 [50]=1.00 [60]=1.00 [70]=0.92
    [80]=0.82 [87]=0.755 [90]=0.70 [92]=0.66 [94]=0.62 [95]=0.58
    [96]=0.54 [98]=0.42 [99]=0.34 [100]=0.00
)

# ash_m3_ramp <dest-NAME> <hue> [chroma]
#   A tonal ramp: ten colours from tone 0 to 100 at a fixed hue.
ash_m3_ramp() {
    local -n _out="$1"
    local hue="$2" chroma="${3:-0.16}"

    local tone
    for tone in "${ASH_M3_TONES[@]}"; do
        local L C
        L="${ASH_M3_TONE_L[$tone]}"
        C="$(_ash_ok_awk "BEGIN { printf \"%.6f\", $chroma * ${ASH_M3_TONE_C[$tone]} }")"
        # Clamp chroma per tone: a saturated yellow at tone 95 is far outside
        # sRGB, and the per-channel clamp would flatten the ramp.
        local safe_c; safe_c="$(ash_ok_clamp_chroma "$L" "$C" "$hue")"
        _out["$tone"]="$(ash_ok_to_hex "$L" "$safe_c" "$hue")"
    done
}

# ash_m3_scheme <dest-NAME> <seed-hex> [--dark]
#   The five Material ramps, derived from one seed colour.
#
#   Secondary and tertiary are the standard rotations of the source hue, with
#   reduced chroma — this is what makes a Material palette feel related without
#   being monotonous.
ash_m3_scheme() {
    local -n _out="$1"
    local seed="$2" variant="${3:-light}"

    local lch hue chroma
    lch="$(ash_ok_from_hex "$seed")" || return 1
    hue="$(cut -d' ' -f3 <<<"$lch")"
    chroma="$(cut -d' ' -f2 <<<"$lch")"

    # A near-grey seed has no usable hue; fall back to the Material default
    # purple rather than producing five identical grey ramps.
    if _ash_ok_awk "BEGIN { exit(($chroma < 0.02) ? 0 : 1) }"; then
        hue="$(_ash_ok_awk 'BEGIN { printf "%.4f", 294 }')"
        chroma="0.14"
    fi

    # The spec's chroma floor keeps a muted seed from producing a fully grey
    # scheme, which reads as a bug rather than a choice.
    local c_primary; c_primary="$(_ash_ok_awk "BEGIN { v = $chroma; if (v < 0.10) v = 0.10; if (v > 0.20) v = 0.20; printf \"%.6f\", v }")"
    local c_secondary; c_secondary="$(_ash_ok_awk "BEGIN { printf \"%.6f\", $c_primary * 0.42 }")"
    local c_tertiary;  c_tertiary="$(_ash_ok_awk  "BEGIN { printf \"%.6f\", $c_primary * 0.68 }")"
    local c_variant;   c_variant="$(_ash_ok_awk   "BEGIN { printf \"%.6f\", $c_primary * 0.22 }")"

    local h_secondary h_tertiary
    h_secondary="$(_ash_ok_awk "BEGIN { h = $hue - 12; if (h < 0) h += 360; printf \"%.4f\", h }")"
    h_tertiary="$(_ash_ok_awk  "BEGIN { h = $hue + 60; if (h >= 360) h -= 360; printf \"%.4f\", h }")"

    local -A ramp=()
    local tone

    ash_m3_ramp ramp "$hue"          "$c_primary"
    for tone in "${!ramp[@]}"; do _out["primary_$tone"]="${ramp[$tone]}"; done

    ash_m3_ramp ramp "$h_secondary"  "$c_secondary"
    for tone in "${!ramp[@]}"; do _out["secondary_$tone"]="${ramp[$tone]}"; done

    ash_m3_ramp ramp "$h_tertiary"   "$c_tertiary"
    for tone in "${!ramp[@]}"; do _out["tertiary_$tone"]="${ramp[$tone]}"; done

    ash_m3_ramp ramp "$hue"          "$c_variant"
    for tone in "${!ramp[@]}"; do _out["variant_$tone"]="${ramp[$tone]}"; done

    # The neutral ramp is what makes Material look like Material: it is very
    # slightly tinted toward the primary hue, not pure grey. Material uses a
    # chroma of about 4 in HCT; ~0.008 in OKLCH is the equivalent tint.
    ash_m3_ramp ramp "$hue" 0.008
    for tone in "${!ramp[@]}"; do _out["neutral_$tone"]="${ramp[$tone]}"; done

    # The error ramp is FIXED in the Material spec — it does not derive from the
    # seed, because "danger" must look the same in every app. Omitting it left
    # the rose slot empty in every converted palette: ash_m3_role returned
    # nothing for error_80, and an empty slot fails every downstream validator.
    ash_m3_ramp ramp 30 0.18
    for tone in "${!ramp[@]}"; do _out["error_$tone"]="${ramp[$tone]}"; done

    ASH_M3_SEED_HUE="$hue"
    ASH_M3_DARK="$([[ "$variant" == "dark" ]] && echo 1 || echo 0)"
}

# ash_m3_role <scheme-NAME> <role> <light|dark>
#   Maps a Material role onto a tone from the appropriate ramp. This is the
#   table from the spec; it is the whole reason roles and ramps are separate.
ash_m3_role() {
    local -n _s="$1"
    local role="$2" mode="${3:-light}"

    local key
    if [[ "$mode" == "dark" ]]; then
        case "$role" in
            primary)             key="primary_80" ;;
            on-primary)          key="primary_20" ;;
            primary-container)   key="primary_30" ;;
            on-primary-container) key="primary_90" ;;
            secondary)           key="secondary_80" ;;
            on-secondary)        key="secondary_20" ;;
            secondary-container) key="secondary_30" ;;
            on-secondary-container) key="secondary_90" ;;
            tertiary)            key="tertiary_80" ;;
            on-tertiary)         key="tertiary_20" ;;
            tertiary-container)  key="tertiary_30" ;;
            on-tertiary-container) key="tertiary_90" ;;
            surface)             key="neutral_10" ;;
            on-surface)          key="neutral_90" ;;
            surface-container-lowest) key="neutral_4" ;;
            surface-container-low)    key="neutral_6" ;;
            surface-container)        key="neutral_12" ;;
            surface-container-high)   key="neutral_17" ;;
            surface-container-highest) key="neutral_22" ;;
            surface-variant)     key="variant_30" ;;
            on-surface-variant)  key="variant_80" ;;
            outline)             key="variant_60" ;;
            background)          key="neutral_10" ;;
            on-background)       key="neutral_90" ;;
            error)               key="error_80" ;;
            error-container)     key="error_30" ;;
            on-error-container)  key="error_90" ;;
            shadow)              key="neutral_0" ;;
            *) return 2 ;;
        esac
    else
        case "$role" in
            primary)             key="primary_40" ;;
            on-primary)          key="primary_100" ;;
            primary-container)   key="primary_90" ;;
            on-primary-container) key="primary_10" ;;
            secondary)           key="secondary_40" ;;
            on-secondary)        key="secondary_100" ;;
            secondary-container) key="secondary_90" ;;
            on-secondary-container) key="secondary_10" ;;
            tertiary)            key="tertiary_40" ;;
            on-tertiary)         key="tertiary_100" ;;
            tertiary-container)  key="tertiary_90" ;;
            on-tertiary-container) key="tertiary_10" ;;
            surface)             key="neutral_98" ;;
            on-surface)          key="neutral_10" ;;
            surface-container-lowest) key="neutral_100" ;;
            surface-container-low)    key="neutral_99" ;;
            surface-container)        key="neutral_96" ;;
            surface-container-high)   key="neutral_94" ;;
            surface-container-highest) key="neutral_92" ;;
            surface-variant)     key="variant_90" ;;
            on-surface-variant)  key="variant_30" ;;
            outline)             key="variant_50" ;;
            background)          key="neutral_99" ;;
            on-background)       key="neutral_10" ;;
            error)               key="error_40" ;;
            error-container)     key="error_90" ;;
            on-error-container)  key="error_10" ;;
            shadow)              key="neutral_0" ;;
            *) return 2 ;;
        esac
    fi

    printf '%s' "${_s[$key]:-}"
}

# ash_m3_to_palette <dest-NAME> <scheme-NAME> <light|dark>
#   Collapse a Material scheme into ASH's 13 slots so a Material theme can be
#   used everywhere else in this project.
ash_m3_to_palette() {
    local _out_name="$1"        # the NAME, not a nameref — see the note below
    local _scheme_name="$2"
    local mode="${3:-light}"

    local -n _out="$_out_name"

    # Why `_scheme_name` is a plain variable rather than `local -n _s="$2"`:
    # ash_m3_role declares its own `local -n _s="$1"`. Forwarding a nameref by
    # name makes the callee bind _s to _s — a self-referential cycle that bash
    # reports as "circular name reference" and that yields empty strings for
    # every read. A nameref must be passed along as the name of the array it
    # points at, never as the reference itself.
    #
    # This is the second time this exact bug appeared in this engine, so it is
    # now checked automatically (see scripts/lint/nameref-cycle.sh).
    if [[ "$mode" == "dark" ]]; then
        # Each surface slot takes a distinct container tone. Material gives
        # `surface` and `background` the same tone, which would leave base and
        # mantle identical here and flatten the depth ramp that Hyprland
        # borders, Waybar layers and the dashboard panels rely on.
        _out[base]="$(ash_m3_role "$_scheme_name" surface dark)"
        _out[mantle]="$(ash_m3_role "$_scheme_name" surface-container-low dark)"
        _out[crust]="$(ash_m3_role "$_scheme_name" surface-container-lowest dark)"
        _out[surface]="$(ash_m3_role "$_scheme_name" surface-variant dark)"
        _out[overlay]="$(ash_m3_role "$_scheme_name" outline dark)"
        _out[text]="$(ash_m3_role "$_scheme_name" on-surface dark)"
        _out[subtext]="$(ash_m3_role "$_scheme_name" on-surface-variant dark)"
    else
        # In a light theme the container tones ascend to white, so mapping
        # "lowest" to crust would make crust the BRIGHTEST surface. ASH uses
        # one convention everywhere else — crust is always the deepest surface,
        # in both variants (see ash_palette_surfaces) — so crust takes a
        # container tone that is darker than base rather than lighter.
        _out[base]="$(ash_m3_role "$_scheme_name" surface light)"
        _out[mantle]="$(ash_m3_role "$_scheme_name" surface-container light)"
        _out[crust]="$(ash_m3_role "$_scheme_name" surface-container-high light)"
        _out[surface]="$(ash_m3_role "$_scheme_name" surface-variant light)"
        _out[overlay]="$(ash_m3_role "$_scheme_name" outline light)"
        _out[text]="$(ash_m3_role "$_scheme_name" on-surface light)"
        _out[subtext]="$(ash_m3_role "$_scheme_name" on-surface-variant light)"
    fi

    _out[accent]="$(ash_m3_role "$_scheme_name" primary "$mode")"
    _out[mint]="$(ash_m3_role "$_scheme_name" tertiary "$mode")"
    _out[sky]="$(ash_m3_role "$_scheme_name" secondary "$mode")"
    _out[gold]="$(ash_m3_role "$_scheme_name" tertiary-container "$mode" 2>/dev/null || ash_m3_role "$_scheme_name" tertiary "$mode")"
    _out[rose]="$(ash_m3_role "$_scheme_name" error "$mode")"
    _out[violet]="$(ash_m3_role "$_scheme_name" primary-container "$mode")"

    # Container tones are too low-contrast for a text-adjacent accent, so the
    # two derived slots are corrected against the surface before use.
    local slot
    for slot in mint sky gold rose violet; do
        ash_contrast_pass "${_out[$slot]}" "${_out[base]}" aa-normal && continue
        _out["$slot"]="$(ash_contrast_fix "${_out[$slot]}" "${_out[base]}" aa-normal)"
    done
}

# ash_m3_render_json <scheme-NAME>
ash_m3_render_json() {
    local -n _s="$1"
    local first=1 key
    printf '{\n'
    for key in $(printf '%s\n' "${!_s[@]}" | sort -t_ -k1,1 -k2,2n); do
        (( first )) || printf ',\n'
        printf '  "%s": "%s"' "$key" "${_s[$key]}"
        first=0
    done
    printf '\n}\n'
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 4  CLI
# ═══════════════════════════════════════════════════════════════════════════════
#
# Dispatched through a function called directly, NOT through `bash -c '...' $@`.
#
# The first version wrapped the work in `bash -c` and passed the user arguments
# as the child's positionals. That silently shifts every index by one (the first
# argument after the script text becomes $0, not $1), so `ramp 264 0.16` passed
# hue=0.16 and chroma=264 — producing a pink ramp for a request for blue — and
# `scheme` tried to parse the word "light" as a seed colour.

ash_m3_usage() {
    cat <<'USAGE'
ash material -- Material Design 3 tonal palettes

  ash material ramp <hue 0-360> [chroma]        twelve tones at one hue
  ash material scheme <seed-hex> [light|dark]   all five Material ramps
  ash material roles <seed-hex> [light|dark]    the named Material roles
USAGE
}

ash_m3_main() {
    local cmd="${1:-}"; shift || true

    case "$cmd" in
        ramp)
            local hue="${1:?hue required (0-360)}"
            local chroma="${2:-0.16}"

            local -A r=()
            ash_m3_ramp r "$hue" "$chroma" || return 1

            local tone
            for tone in "${ASH_M3_TONES[@]}"; do
                printf '%3s  %s\n' "$tone" "${r[$tone]}"
            done
            ;;

        scheme)
            local seed="${1:?seed colour required}"
            local mode="${2:-light}"

            local -A sc=()
            ash_m3_scheme sc "$seed" "$mode" || return 1
            ash_m3_render_json sc
            ;;

        roles)
            local seed="${1:?seed colour required}"
            local mode="${2:-light}"

            local -A sc=(); ash_m3_scheme sc "$seed" "$mode" || return 1
            local -A out=(); ash_m3_to_palette out sc "$mode"

            local slot
            for slot in "${ASH_PALETTE_SLOTS[@]}"; do
                printf '%-9s %s\n' "$slot" "${out[$slot]}"
            done
            echo '---'
            ash_palette_audit out || true
            ;;

        ''|help|-h|--help) ash_m3_usage ;;

        *)
            printf 'ash material: unknown subcommand: %s\n\n' "$cmd" >&2
            ash_m3_usage >&2
            return 2
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_m3_main "$@"
fi
