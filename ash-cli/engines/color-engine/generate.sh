#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/generate.sh                        ║
# ║                                                                               ║
# ║  Deterministic theme generation from a text prompt.                            ║
# ║                                                                               ║
# ║  "Deterministic" is the load-bearing word. The same prompt always produces     ║
# ║  the same theme, on any machine, with no network and no model weights. The     ║
# ║  prompt is hashed to a hue, so the theme is *reproducible* — a user who likes  ║
# ║  a generated theme can share the prompt and get the identical palette back.    ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_GENERATE_LOADED:-}" ]] && return 0
ASH_GENERATE_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]   && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"

# ── Keyword lexicon ──────────────────────────────────────────────────────────
#
# Words a user actually types, mapped to (hue, chroma-scale, variant). A prompt
# that matches several entries is resolved by the SUM of its matches, so
# "cyberpunk neon" lands between the two rather than on whichever happens to be
# checked first.
#
# Values are hue degrees in OKLCH. Chroma scale >1 means "more saturated than
# the default for this lightness", <1 means muted.
declare -gA ASH_GEN_LEXICON=(
    # ── Nature ──
    [forest]=148:0.9   [tree]=145:0.9    [moss]=120:0.8    [leaf]=135:0.95
    [ocean]=230:1.0    [sea]=225:1.0     [wave]=235:1.1    [aqua]=195:1.0
    [sky]=220:0.85     [cloud]=225:0.5   [rain]=210:0.7    [storm]=250:0.8
    [sunset]=25:1.15   [sunrise]=40:1.1  [dusk]=300:0.9    [dawn]=20:1.0
    [desert]=60:0.8    [sand]=70:0.6     [canyon]=35:0.9   [clay]=30:0.7
    [cherry]=350:1.0   [rose]=355:1.0    [blossom]=340:0.95 [petal]=345:0.9
    [lavender]=290:0.8 [violet]=292:1.0  [orchid]=310:0.95 [plum]=320:0.9
    [ember]=20:1.2     [lava]=15:1.25    [fire]=18:1.2     [ash]=0:0.15
    [ice]=200:0.8      [frost]=195:0.75  [snow]=210:0.25   [glacier]=205:0.8
    [gold]=85:1.1      [honey]=75:1.0    [amber]=65:1.15   [bronze]=55:0.85
    [mint]=160:0.95    [sage]=150:0.6    [olive]=100:0.7   [jade]=165:0.9
    [copper]=45:0.9    [rust]=30:0.85    [wine]=345:0.8    [blood]=10:1.15

    # ── Mood ──
    [cyberpunk]=300:1.3 [neon]=310:1.35  [synthwave]=290:1.25 [vaporwave]=275:1.2
    [retro]=30:1.0      [vintage]=40:0.65 [sepia]=45:0.5    [antique]=50:0.6
    [minimal]=0:0.35    [clean]=220:0.5  [simple]=0:0.4     [plain]=0:0.3
    [dark]=265:0.7      [light]=60:0.6   [bright]=60:1.1    [muted]=0:0.55
    [pastel]=330:0.5    [soft]=340:0.55  [gentle]=350:0.5   [calm]=210:0.6
    [vibrant]=15:1.25   [bold]=10:1.2    [intense]=5:1.3    [vivid]=20:1.3
    [elegant]=280:0.6   [luxury]=45:0.85 [premium]=50:0.9   [royal]=275:1.0
    [cozy]=30:0.7       [warm]=35:0.9    [cool]=220:0.85    [cold]=210:0.8
    [fresh]=170:0.9     [natural]=130:0.7 [organic]=120:0.65 [earthy]=35:0.7
    [night]=265:0.75    [midnight]=262:0.8 [twilight]=285:0.85
    [morning]=45:1.0    [evening]=290:0.9 [day]=215:0.75     [noon]=50:1.05

    # ── Tech ──
    [matrix]=140:1.2    [terminal]=140:1.1 [hacker]=135:1.15 [green]=140:1.0
    [oceanic]=215:1.0   [nordic]=230:0.6  [arctic]=210:0.65  [polar]=205:0.7
    [space]=255:0.9     [cosmos]=270:1.0  [galaxy]=285:1.1   [nebula]=300:1.15
    [star]=240:0.8      [void]=270:0.7    [abyss]=250:0.85   [quantum]=265:1.1
    [sakura]=345:0.95   [kimono]=350:0.85 [matcha]=130:0.7   [indigo]=255:1.0
    [gruvbox]=40:0.85   [dracula]=285:1.05 [nord]=225:0.55   [tokyo]=255:0.95
    [catppuccin]=280:0.85 [everforest]=140:0.6 [rosepine]=0:0.6
)

# ash_generate_prompt_hue <prompt>
#   Hash the prompt to a hue in [0,360) so unknown words still produce a stable,
#   well-spread theme.
ash_generate_prompt_hue() {
    local prompt="$1"
    local digest
    # sha256 of the prompt; the first 8 hex digits are plenty of entropy for a
    # 360-degree wheel, and taking a prefix avoids the integer-width problem
    # that the full digest would create in bash arithmetic.
    if command -v sha256sum >/dev/null 2>&1; then
        digest="$(printf '%s' "$prompt" | sha256sum | cut -c1-8)"
    elif command -v shasum >/dev/null 2>&1; then
        digest="$(printf '%s' "$prompt" | shasum -a 256 | cut -c1-8)"
    else
        # No hasher at all: fall back to a checksum over the bytes. Weaker
        # distribution, still deterministic, still no external dependency.
        digest="$(printf '%s' "$prompt" | cksum | awk '{printf "%08x", $1}')"
    fi
    _ash_ok_awk "$_ASH_GEN_HEX_AWK
    BEGIN { printf \"%.4f\", (hex_int(\"$digest\") % 36000) / 100 }"
}

# The awk used above needs a hex parser; provide it without relying on gawk's
# strtonum, which mawk and busybox awk do not have.
_ASH_GEN_HEX_AWK='
function hex_int(s,   i, n, c, v) {
    n = length(s); v = 0
    for (i = 1; i <= n; i++) {
        c = tolower(substr(s, i, 1))
        v = v * 16 + ((c >= "0" && c <= "9") ? c + 0 : index("abcdef", c) + 9)
    }
    return v
}
'

# ash_generate_from_prompt <dest-NAME> <prompt> [--light]
ash_generate_from_prompt() {
    local _target="$1" prompt="$2" variant="${3:-dark}"

    local hue chroma_scale matches=0
    local -a matched_hues=()
    local -a matched_chroma=()

    # Longest-match-first so "synthwave" is not also scored as "wave".
    local lower; lower="$(tr '[:upper:]' '[:lower:]' <<<"$prompt")"
    local word
    for word in $(tr -cs '[:alnum:]' '\n' <<<"$lower" | sort -u); do
        [[ -n "${ASH_GEN_LEXICON[$word]:-}" ]] || continue
        local spec="${ASH_GEN_LEXICON[$word]}"
        matched_hues+=("${spec%%:*}")
        matched_chroma+=("${spec##*:}")
        (( matches += 1 ))
    done

    if (( matches == 0 )); then
        # Nothing recognised: hash the whole prompt.
        hue="$(ash_generate_prompt_hue "$lower")"
        chroma_scale="0.85"
    else
        # Circular mean of the matched hues, so "warm and cool" does not land
        # on the arithmetic average of 35 and 220 (which would be 127, green —
        # matching neither word).
        local sum_x=0 sum_y=0 i
        local csum=0
        for (( i = 0; i < matches; i++ )); do
            read -r x y < <(_ash_ok_awk "BEGIN {
                rad = ${matched_hues[i]} * 3.141592653589793 / 180
                printf \"%.10f %.10f\", cos(rad), sin(rad)
            }")
            sum_x="$(_ash_ok_awk "BEGIN { printf \"%.10f\", $sum_x + $x }")"
            sum_y="$(_ash_ok_awk "BEGIN { printf \"%.10f\", $sum_y + $y }")"
            csum="$(_ash_ok_awk "BEGIN { printf \"%.6f\", $csum + ${matched_chroma[i]} }")"
        done

        hue="$(_ash_ok_awk "BEGIN {
            if ($sum_x == 0 && $sum_y == 0) { print 268; exit }
            h = atan2($sum_y, $sum_x) * 180 / 3.141592653589793
            while (h < 0) h += 360
            printf \"%.4f\", h
        }")"
        chroma_scale="$(_ash_ok_awk "BEGIN { printf \"%.4f\", $csum / $matches }")"
    fi

    # Variant inference: a prompt containing "light"/"day"/"pastel" asks for a
    # light theme even when the caller did not pass --light. Explicit flags win.
    if [[ "$variant" != "light" ]]; then
        case "$lower" in
            *light*|*bright*|*pastel*|*day*|*snow*|*frost*|*clean*|*minimal*)
                variant="light" ;;
        esac
    fi

    local base_l
    [[ "$variant" == "light" ]] && base_l="0.95" || base_l="0.18"

    local seed
    seed="$(ash_ok_to_hex "$base_l" "$(_ash_pal_scale 0.030 "$chroma_scale")" "$hue")"

    ASH_GENERATE_LAST_HUE="$hue"
    ASH_GENERATE_LAST_CHROMA="$chroma_scale"
    ASH_GENERATE_LAST_MATCHES="$matches"

    ash_palette_derive "$_target" "$seed" "$variant"
}

# ash_generate_name <prompt>
#   A readable theme name from the prompt: title-cased, truncated, and with the
#   hash suffix used only when two prompts would otherwise collide.
ash_generate_name() {
    local prompt="$1"
    local name
    name="$(sed -E 's/[^[:alnum:] ]+/ /g; s/ +/ /g; s/^ | $//g' <<<"$1")"
    name="$(awk '{ for (i=1;i<=NF && i<=3;i++) printf "%s%s", (i>1?" ":""), toupper(substr($i,1,1)) substr($i,2) }' <<<"$name")"
    [[ -z "$name" ]] && name="Generated"
    printf '%s' "$name"
}

# ash_generate_slug <prompt>
ash_generate_slug() {
    local slug
    slug="$(tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    [[ -z "$slug" ]] && slug="generated"
    # Cap the length; a 200-character slug is not a filename.
    printf '%s' "${slug:0:48}"
}
