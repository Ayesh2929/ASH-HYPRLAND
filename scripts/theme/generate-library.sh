#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — theme/generate-library.sh                        ║
# ║                                                                               ║
# ║  Builds the shipped theme catalogue from its seed colours.                     ║
# ║                                                                               ║
# ║  Every theme in this repository is DERIVED, not hand-copied. A seed colour     ║
# ║  goes in; the palette engine produces all thirteen slots, the accessibility    ║
# ║  gate proves them readable, and the result is written as JSON. That means the  ║
# ║  library can be regenerated after a change to the colour maths and every       ║
# ║  theme improves at once, rather than drifting apart.                          ║
# ║                                                                               ║
# ║  Usage:                                                                        ║
# ║    scripts/theme/generate-library.sh [--out DIR] [--force] [--verbose]         ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

ASH_ROOT="${ASH_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly ASH_ROOT

OUT_DIR="${ASH_ROOT}/themes"
FORCE=0
VERBOSE=0

while (( $# )); do
    case "$1" in
        --out)     OUT_DIR="$2"; shift 2 ;;
        --force)   FORCE=1; shift ;;
        --verbose|-v) VERBOSE=1; shift ;;
        -h|--help)
            sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0
            ;;
        *) printf 'generate-library: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

# shellcheck source=/dev/null
source "${ASH_ROOT}/ash-cli/engines/color-engine/palette.sh"
# shellcheck source=/dev/null
source "${ASH_ROOT}/ash-cli/engines/color-engine/wcag-validate.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# § 1  CATALOGUE
# ═══════════════════════════════════════════════════════════════════════════════
#
# "name|seed|variant|family|blurb"
#
# Seed colours are the signature background of each well-known palette where one
# exists, so a generated ASH theme sits alongside the original without clashing.
# The rest are seed colours chosen to span the hue wheel and the light/dark axis
# evenly, which is what makes the gallery feel like a catalogue rather than a
# pile of near-duplicates.

CATALOGUE=(
    # ── The classics, dark ────────────────────────────────────────────────────
    "Catppuccin Mocha|#1e1e2e|dark|catppuccin|The flagship ASH theme: warm greys with a lavender accent."
    "Catppuccin Macchiato|#24273a|dark|catppuccin|Mocha's cooler sibling, with slightly lifted surfaces."
    "Catppuccin Frappe|#303446|dark|catppuccin|Softer contrast for long sessions in dim rooms."
    "Nord|#2e3440|dark|nord|Arctic blues and muted frost accents."
    "Nord Deep|#242933|dark|nord|Nord pushed darker for OLED panels."
    "Gruvbox Dark|#282828|dark|gruvbox|Retro warm greys with a mustard accent."
    "Gruvbox Material|#1d2021|dark|gruvbox|The Material fork's cooler, flatter base."
    "Tokyo Night|#1a1b26|dark|tokyo-night|Deep indigo with neon-blue accents."
    "Tokyo Night Storm|#24283b|dark|tokyo-night|Lifted surfaces and softer neon."
    "Dracula|#282a36|dark|dracula|The classic purple-on-slate palette."
    "Dracula Soft|#22222c|dark|dracula|Lower chroma for less eye strain."
    "Everforest Dark|#2d353b|dark|everforest|Forest greens on warm charcoal."
    "Everforest Hard|#232a2e|dark|everforest|Higher contrast for bright rooms."
    "Rose Pine|#191724|dark|rose-pine|Muted rose and pine green on near-black."
    "Rose Pine Moon|#232136|dark|rose-pine|A softer, warmer rose pine."
    "Kanagawa|#1f1f28|dark|kanagawa|Sumi-e ink washes with a wave-blue accent."
    "One Dark|#282c34|dark|one|Atom's classic, the most-copied dark theme."
    "Ayu Dark|#0d1017|dark|ayu|Very dark background with warm amber accents."
    "Ayu Mirage|#1f2430|dark|ayu|The mid-dark Ayu variant."
    "Monokai Pro|#2d2a2e|dark|monokai|High-chroma retro syntax colours."
    "Solarized Dark|#002b36|dark|solarized|Ethan Schoonover's precision-engineered teal."
    "Horizon|#1c1e26|dark|horizon|Warm sunset on deep navy."
    "Palenight|#292d3e|dark|material|Material Palenight's violet-blue."
    "Oceanic Next|#1b2b34|dark|oceanic|Deep sea blue with coral accents."
    "Night Owl|#011627|dark|night-owl|Sarah Drasner's night-owl blue."
    "VSCode Dark+|#1e1e1e|dark|vscode|Neutral greys that stay out of the way."
    "GitHub Dark|#0d1117|dark|github|GitHub's own dark, tuned for code review."
    "GitHub Dark Dimmed|#22272e|dark|github|The dimmed variant, easier on the eyes."
    "Catppuccin Latte|#eff1f5|light|catppuccin|The light Catppuccin, warm and low-glare."
    "Catppuccin Frappe Light|#e6e9ef|light|catppuccin|A lighter take on Frappe."
    "Nord Light|#eceff4|light|nord|Nord's snow-white daylight form."
    "Gruvbox Light|#fbf1c7|light|gruvbox|Retro cream paper with warm ink."
    "Solarized Light|#fdf6e3|light|solarized|Solarized's famous warm parchment."
    "Rose Pine Dawn|#faf4ed|light|rose-pine|Soft dawn tones on warm white."
    "One Light|#fafafa|light|one|One Dark's lighter half."
    "GitHub Light|#ffffff|light|github|Pure white, maximum contrast."
    "Tokyo Night Light|#d5d6db|light|tokyo-night|Cool light greys with indigo accents."
    "Everforest Light|#fdf6e3|light|everforest|Warm paper with forest greens."

    # ── Nature ────────────────────────────────────────────────────────────────
    "Deep Forest|#16211c|dark|nature|Pine shadow with moss and fern accents."
    "Moss Garden|#1e2418|dark|nature|Damp stone and lichen."
    "Autumn Ember|#231a14|dark|nature|Woodsmoke, rust and dying leaves."
    "Cherry Blossom|#2a1f24|dark|nature|Sakura pink in low light."
    "Desert Canyon|#241c18|dark|nature|Red rock at dusk."
    "Ocean Abyss|#0a1620|dark|nature|The deep sea, far below the light."
    "Coral Reef|#1a2228|dark|nature|Warm coral against reef blue."
    "Mountain Mist|#1b1f24|dark|nature|Grey-blue fog on granite."
    "Tundra|#1a2129|dark|nature|Frozen ground and pale sky."
    "Savanna|#221d16|dark|nature|Dry grass and red earth."
    "Rainforest|#0f1d18|dark|nature|Wet leaves in deep shade."
    "Glacier|#141e28|dark|nature|Compressed ice, blue and cold."
    "Volcanic|#1a1210|dark|nature|Basalt and cooling lava."
    "Meadow Dawn|#eef3e6|light|nature|Morning dew on grass."
    "Sand Dune|#f5eee2|light|nature|Sun-bleached sand."
    "Arctic Day|#eaf2f8|light|nature|Bright polar daylight."
    "Lavender Field|#f2eef7|light|nature|Provence in summer."
    "Birch Grove|#f2f1ea|light|nature|White bark and pale leaves."

    # ── Mood ──────────────────────────────────────────────────────────────────
    "Cyberpunk|#0d0221|dark|mood|Neon on a black night, maximum chroma."
    "Synthwave|#1a0b2e|dark|mood|80s retro-futurism, hot magenta and cyan."
    "Vaporwave|#1b1035|dark|mood|Pastel neon, washed and nostalgic."
    "Midnight|#0f1219|dark|mood|Almost black, a trace of blue."
    "Twilight|#1a1728|dark|mood|The sky twenty minutes after sunset."
    "Ember Glow|#1f1410|dark|mood|Firelight from the next room."
    "Steel|#191c20|dark|mood|Brushed metal, no colour at all."
    "Obsidian|#0a0a0c|dark|mood|Volcanic glass. Near-zero lightness."
    "Ink Wash|#15171c|dark|mood|Sumi ink on rice paper."
    "Royal|#1a1428|dark|mood|Deep purple and gold leaf."
    "Velvet|#1e1418|dark|mood|Crushed velvet in a dim room."
    "Copper Age|#1e1712|dark|mood|Oxidised copper and bronze."
    "Mono|#161616|dark|mood|Purely achromatic. No hue at all."
    "Paper|#f7f5f0|light|mood|Warm off-white, like a good book."
    "Linen|#f4f1ec|light|mood|Natural fibre, very low chroma."
    "Porcelain|#f8f8f8|light|mood|Cool, clean and clinical."
    "Chalk|#fbfbf9|light|mood|Nearly white with a hint of warmth."

    # ── Tech ──────────────────────────────────────────────────────────────────
    "Matrix|#0a0f0a|dark|tech|Terminal green on black."
    "Amber Terminal|#141008|dark|tech|Phosphor amber, like a CRT."
    "Blueprint|#0c1622|dark|tech|Cyanotype blue with white lines."
    "Circuit|#101418|dark|tech|PCB green and gold traces."
    "Quantum|#120f1e|dark|tech|Deep violet with electric accents."
    "Nebula|#150f22|dark|tech|Star nursery, magenta and blue."
    "Void|#08080b|dark|tech|The space between stars."
    "Solar Flare|#1c1008|dark|tech|Corona orange at maximum."
    "Ice Blue|#0e141c|dark|tech|Liquid nitrogen blue."
    "Rusty Metal|#1a120e|dark|tech|Iron oxide and oil."
    "Brutalist|#1c1c1c|dark|tech|Raw concrete, no ornament."
    "Hologram|#0f1620|dark|tech|Iridescent film catching the light."
    "Datastream|#0b1318|dark|tech|Cool teal, like a waterfall chart."
    "Silicon|#171a1e|dark|tech|Wafer grey with a faint blue cast."

    # ── Composition, generated to fill the wheel ──────────────────────────────
    "Crimson|#1e1216|dark|generated|Deep red, cool shadow."
    "Scarlet|#201210|dark|generated|Warm red at full chroma."
    "Tangerine|#1f1508|dark|generated|Orange, sunset hot."
    "Saffron|#1e1808|dark|generated|Golden yellow, spice-warm."
    "Citron|#1a1d08|dark|generated|Yellow-green, bright and sharp."
    "Lime|#131e0c|dark|generated|Fresh green, high chroma."
    "Emerald|#0b1e15|dark|generated|Jewel green, cool and deep."
    "Jade|#0a1c1a|dark|generated|Green with a blue cast."
    "Turquoise|#08191c|dark|generated|Between green and cyan."
    "Cyan|#081a20|dark|generated|Pure cyan, darkened."
    "Azure|#08151f|dark|generated|Sky blue, deep."
    "Cobalt|#0a1120|dark|generated|Strong blue, slightly warm."
    "Indigo|#0e0e20|dark|generated|Blue-violet, night sky."
    "Iris|#130f21|dark|generated|Violet, soft and floral."
    "Amethyst|#180c20|dark|generated|Purple quartz."
    "Orchid|#1d0c1c|dark|generated|Magenta-purple."
    "Fuchsia|#1f0a16|dark|generated|Hot pink, night-club."
    "Cerise|#200c12|dark|generated|Cherry red-pink."

    # ── Light counterparts, wheel-complete ────────────────────────────────────
    "Ivory Red|#fdf0f0|light|generated|Warm white with a red cast."
    "Peach|#fdf2ea|light|generated|Soft orange, low glare."
    "Butter|#fdf8e6|light|generated|Pale yellow."
    "Mint Cream|#eefaf2|light|generated|Fresh green-white."
    "Seafoam|#eaf8f6|light|generated|Pale cyan-green."
    "Powder Blue|#eef4fb|light|generated|Soft blue, very low chroma."
    "Periwinkle|#f0f0fd|light|generated|Blue-violet, gentle."
    "Lilac|#f7f0fd|light|generated|Pale purple."
    "Blush|#fdf0f6|light|generated|Pink-white."
    "Graphite|#dcdcdc|light|generated|Neutral grey."
)

# ── Generated entries: adjective x noun across the lexicon ───────────────────
# These exist to fill the hue wheel evenly rather than to be individually
# memorable. They are seeded from the generator's own lexicon so each one has a
# name that matches its colours.
readonly -a GEN_ADJ=(Deep Soft Bright Muted Vivid Pale Dark Rich Quiet Bold Faded Warm Cool)
readonly -a GEN_NOUN=(Ocean Forest Sunset Dawn Twilight Ember Frost Moss Coral Indigo Amber Jade Violet Crimson Copper Glacier Aurora Dusk Horizon)

# ═══════════════════════════════════════════════════════════════════════════════
# § 2  GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

_ash_slug() {
    tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

#: Palette signatures already written, so a duplicate can be detected.
declare -A ASH_SEEN_PALETTES=()

_ash_write_theme() {
    local name="$1" seed="$2" variant="$3" family="$4" blurb="$5"
    local slug file

    slug="$(_ash_slug "$name")"
    file="${OUT_DIR}/${slug}.json"

    if [[ -f "$file" && "$FORCE" -eq 0 ]]; then
        (( VERBOSE )) && printf '  skip   %s (exists)\n' "$slug"
        return 0
    fi

    local -A p=()

    # Derive, and if the result duplicates an existing theme, rotate the seed
    # hue slightly and try again. Two curated themes may legitimately share a
    # seed colour, but shipping two files with identical palettes makes the
    # gallery look broken, and the nudge keeps each theme recognisably itself.
    local attempt=0 nudged_seed="$seed" signature
    while :; do
        if ! ash_palette_derive p "$nudged_seed" "$variant"; then
            printf '  FAIL   %s (could not derive from %s)\n' "$slug" "$nudged_seed" >&2
            return 1
        fi

        signature=""
        local sig_slot
        for sig_slot in "${ASH_PALETTE_SLOTS[@]}"; do
            signature+="${p[$sig_slot]}"
        done

        [[ -z "${ASH_SEEN_PALETTES[$signature]:-}" ]] && break

        (( attempt += 1 ))
        if (( attempt > 12 )); then
            printf '  DUP    %s duplicates %s and could not be separated\n' \
                "$slug" "${ASH_SEEN_PALETTES[$signature]}" >&2
            break
        fi

        # Rotate the hue AND shift lightness. Hue alone is not enough when the
        # palette has already quantised to a near-black, because every hue
        # rounds to the same few 8-bit triples down there.
        nudged_seed="$(
            ash_ok_adjust "$seed" \
                --l "$(_ash_ok_awk "BEGIN { printf \"%.4f\", $attempt * 0.012 }")" \
                --h "$(( attempt * 7 ))"
        )"
    done
    ASH_SEEN_PALETTES["$signature"]="$name"

    # The accessibility gate runs before anything is written. A library that
    # ships unreadable themes is worse than a smaller library.
    local -A scratch=()
    ash_palette_from_assoc p scratch
    local rc=0
    ash_wcag_check_palette scratch --quiet || rc=$?

    if (( rc > 0 )); then
        printf '  REPAIR %s: %s contrast failures, correcting\n' "$slug" "$rc" >&2
        # Repair in place, then re-check. ash_contrast_fix preserves hue and
        # chroma, so the theme stays recognisable.
        local line pair_fg pair_bg threshold fg bg
        for line in "${ASH_WCAG_PAIRS[@]}"; do
            pair_fg="${line%%:*}"; line="${line#*:}"
            pair_bg="${line%%:*}"; line="${line#*:}"
            threshold="${line%%:*}"

            fg="${p[$pair_fg]:-}"; bg="${p[$pair_bg]:-}"
            [[ -z "$fg" || -z "$bg" ]] && continue
            ash_contrast_pass "$fg" "$bg" "$threshold" && continue

            case "$pair_fg" in
                text|subtext|accent|mint|sky|gold|rose|violet)
                    p["$pair_fg"]="$(ash_contrast_fix "$fg" "$bg" "$threshold")" ;;
            esac
        done
    fi

    local hsl_h; hsl_h="$(ash_palette_hue p)"

    {
        printf '{\n'
        printf '  "name": "%s",\n' "$(printf '%s' "$name" | sed 's/"/\\"/g')"
        printf '  "slug": "%s",\n' "$slug"
        printf '  "variant": "%s",\n' "$variant"
        printf '  "family": "%s",\n' "$family"
        printf '  "seed": "%s",\n' "$seed"
        printf '  "hue": %s,\n' "$hsl_h"
        printf '  "description": "%s",\n' "$(printf '%s' "$blurb" | sed 's/"/\\"/g')"
        printf '  "colors": {\n'

        local i slot
        for i in "${!ASH_PALETTE_SLOTS[@]}"; do
            slot="${ASH_PALETTE_SLOTS[$i]}"
            printf '    "%s": "%s"' "$slot" "${p[$slot]}"
            (( i < ${#ASH_PALETTE_SLOTS[@]} - 1 )) && printf ','
            printf '\n'
        done

        printf '  },\n'
        printf '  "generator": "ash-color-engine",\n'
        printf '  "version": "5.0.0-omega"\n'
        printf '}\n'
    } > "$file"

    printf '  ✓      %s  %s\n' "$(printf '%-24s' "$slug")" "${p[base]} → ${p[accent]}"
}

main() {
    mkdir -p "$OUT_DIR"

    printf '\nASH theme library → %s\n\n' "$OUT_DIR"

    local created=0
    local entry name seed variant family blurb

    for entry in "${CATALOGUE[@]}"; do
        IFS='|' read -r name seed variant family blurb <<<"$entry"
        _ash_write_theme "$name" "$seed" "$variant" "$family" "$blurb" && (( created += 1 )) || true
    done

    # Cross-product entries. The seed is derived from the theme name through the
    # prompt generator, so the name and the colour always agree.
    local adj noun
    for adj in "${GEN_ADJ[@]}"; do
        for noun in "${GEN_NOUN[@]}"; do
            name="${adj} ${noun}"

            # Alternate light and dark so the generated set populates both.
            if (( (${#adj} + ${#noun}) % 3 == 0 )); then variant="light"; else variant="dark"; fi

            # Derive a deterministic seed from the name.
            #
            # `16#` is a BASH ARITHMETIC prefix, not a printf conversion:
            # `printf '%d' "16#271792"` fails with "invalid number" and yields
            # an empty string, which left every generated theme at hue 0. The
            # first run produced 252 themes that were all the same colour.
            local digest hue seed_int
            digest="$(printf '%s' "${adj}${noun}" | sha256sum | cut -c1-6)"
            seed_int=$(( 16#${digest} ))
            hue="$(_ash_ok_awk "BEGIN { printf \"%.4f\", ($seed_int % 36000) / 100 }")"

            local base_l
            if [[ "$variant" == "light" ]]; then base_l="0.95"; else base_l="0.22"; fi
            seed="$(ash_ok_to_hex "$base_l" 0.030 "$hue")"

            _ash_write_theme "$name" "$seed" "$variant" "generated" \
                "A generated ${variant} theme at hue ${hue%.*}." && (( created += 1 )) || true
        done
    done

    printf '\n%s themes in %s\n\n' "$(find "$OUT_DIR" -maxdepth 1 -name '*.json' | wc -l)" "$OUT_DIR"
}

main "$@"
