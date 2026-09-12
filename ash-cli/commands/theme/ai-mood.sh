#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — ai-mood.sh                                                       ║
# ║  Name a mood, get the palette that matches it                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::ai_mood::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme ai-mood${RST} <mood> [options]
  ${ASH_ACCENT}ash theme ai-mood${RST} --list

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Maps a mood to a colour temperature, saturation and lightness, then derives a
  palette from that. Unlike ${ASH_MUTED}ai-generate${RST}, which reads the words in a free
  description, this works from a fixed vocabulary so the same word always
  produces the same theme.

${BOLD}${ASH_PRIMARY}MOODS${RST}
EOF
    printf '  %s\n' "${THEME_MOODS[*]:-}"
    cat <<EOF

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--list${RST}             Show the vocabulary
  ${ASH_MUTED}--name NAME${RST}        Theme name (default: the mood)
  ${ASH_MUTED}--slug SLUG${RST}        Theme slug
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--apply${RST}            Apply after generating
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing theme
  ${ASH_MUTED}--dry-run, -n${RST}      Show the palette, write nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme ai-mood calm${RST}
  ${ASH_MUTED}ash theme ai-mood focused --variant dark --apply${RST}
EOF
}

# mood → "seed-hex variant". Chosen so the mood word alone is enough: the
# palette generator handles the rest, and the seed fixes the hue family.
declare -gA THEME_MOOD_SEEDS=(
    [calm]="#7fb3c8"        [serene]="#8fbfb4"
    [focused]="#4a6fa5"     [productive]="#3f7f7f"
    [energetic]="#e8734a"   [vibrant]="#e2492f"
    [warm]="#d98b4a"        [cozy]="#b8804f"
    [cool]="#4f8fc4"        [cold]="#6f9fd8"
    [dark]="#2b2f3a"        [moody]="#3a2f4a"
    [bright]="#ffc857"      [cheerful]="#f7b733"
    [romantic]="#e0729a"    [soft]="#e8b4c8"
    [forest]="#4f8f5f"      [nature]="#6da34d"
    [ocean]="#2f7fa8"       [sunset]="#e07a5f"
    [night]="#2a2d43"       [midnight]="#1b1f2e"
    [dawn]="#f2a39a"        [dusk]="#8f6f9f"
    [minimal]="#9aa0a6"     [clean]="#c3c9d1"
    [retro]="#c9a227"       [neon]="#39ff88"
    [pastel]="#b8c8e8"      [monochrome]="#888a8f"
)

declare -ga THEME_MOODS=(
    calm serene focused productive energetic vibrant warm cozy cool cold
    dark moody bright cheerful romantic soft forest nature ocean sunset
    night midnight dawn dusk minimal clean retro neon pastel monochrome
)

theme::ai_mood() {
    local mood="" name="" slug="" variant="" apply=0 force=0 dry=0 json=0 list=0

    while (( $# )); do
        case "$1" in
            --list)       list=1; shift ;;
            --name)       name="${2:-}"; shift 2 ;;
            --slug)       slug="${2:-}"; shift 2 ;;
            --variant)    variant="${2:-}"; shift 2 ;;
            --apply)      apply=1; shift ;;
            --force|-f)   force=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::ai_mood::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::ai_mood::help; return 2 ;;
            *)            mood="${1,,}"; shift ;;
        esac
    done

    if (( list )); then
        if (( json )); then
            jq -n --argjson m "$(printf '%s\n' "${THEME_MOODS[@]}" | jq -Rn '[inputs|select(length>0)]')" \
                  '{moods: $m, count: ($m|length)}'
        else
            printf '\n  %sMoods%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
            local m
            for m in "${THEME_MOODS[@]}"; do
                printf '    %s%s%s  ' "${ASH_ACCENT}" "$m" "${RST}"
                printf '%s%s%s\n' "${ASH_MUTED}" "${THEME_MOOD_SEEDS[$m]}" "${RST}"
            done
            printf '\n'
        fi
        return 0
    fi

    [[ -n "$mood" ]] || { ash_log_error "Which mood?"; theme::ai_mood::help; return 2; }

    local seed="${THEME_MOOD_SEEDS[$mood]:-}"
    if [[ -z "$seed" ]]; then
        # Unknown word: do not just fail. Offer the nearest known mood, since a
        # typo should not be a dead end.
        local near="" n d best=99
        for n in "${THEME_MOODS[@]}"; do
            if [[ "$n" == *"$mood"* || "$mood" == *"$n"* ]]; then near="$n"; break; fi
            # Cheap edit-ish distance: length difference after trimming the
            # common prefix, which is enough to catch transposed letters.
            local common=0 i
            for (( i = 0; i < ${#n} && i < ${#mood}; i++ )); do
                [[ "${n:i:1}" == "${mood:i:1}" ]] && (( common++ )) || break
            done
            d=$(( ${#n} + ${#mood} - 2 * common ))
            if (( d < best )); then best="$d"; near="$n"; fi
        done
        if (( best <= 3 )) && [[ -n "$near" ]]; then
            ash_log_error "Unknown mood: $mood"
            printf '  %sDid you mean %s%s%s?%s\n\n' "${ASH_MUTED}" "${ASH_ACCENT}" "$near" "${ASH_MUTED}" "${RST}" >&2
            return 2
        fi
        # Nothing close: derive from the word itself rather than refusing.
        [[ -n "$name" ]] || name="$mood"
        local -A tmp=()
        if declare -f ash_generate_from_prompt >/dev/null 2>&1 && \
           ash_generate_from_prompt tmp "$mood" "${variant:-dark}" 2>/dev/null; then
            seed="${tmp[accent]:-${tmp[base]:-#808080}}"
        else
            seed="#808080"
        fi
    fi

    [[ -n "$variant" ]] || variant="dark"
    [[ "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"; return 2; }
    [[ -n "$name" ]] || name="$(awk '{ printf "%s%s", toupper(substr($0,1,1)), substr($0,2) }' <<<"$mood")"
    [[ -n "$slug" ]] || slug="$(ash_generate_slug "$name" 2>/dev/null || printf '%s' "$mood")"
    [[ -n "$slug" ]] || slug="mood-$mood"

    local dest="${THEME_USER_DIR}/${slug}.json"
    if [[ -f "$dest" && "$force" -eq 0 && "$dry" -eq 0 ]]; then
        ash_log_error "User theme '$slug' already exists."
        printf '  %sPass --force to overwrite.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    if ! declare -f ash_palette_derive >/dev/null 2>&1; then
        ash_log_error "The colour engine is not loaded."; return 1
    fi

    local -A pal=()
    if ! ash_palette_derive pal "$seed" "$variant"; then
        ash_log_error "Could not derive a palette from $seed"; return 1
    fi

    local wcag=0
    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local r; r="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && wcag="$r"
    fi

    if (( json )); then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg slug "$slug" --arg name "$name" --arg mood "$mood" \
              --arg variant "$variant" --arg seed "$seed" --arg file "$dest" \
              --argjson dry "$dry" --argjson wcag "$wcag" --argjson colors "$colors_json" \
              '{slug: $slug, name: $name, mood: $mood, variant: $variant, seed: $seed,
                file: $file, dry_run: ($dry == 1), wcag_failures: $wcag, colors: $colors}'
        (( dry )) && return 0
    elif (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    mood   %s\n    seed   %s%s%s\n\n' "$mood" "${ASH_ACCENT}" "$seed" "${RST}"
        local slot
        for slot in "${THEME_SLOT_ORDER[@]}"; do
            [[ -n "${pal[$slot]:-}" ]] && printf '    %-9s %s  %s\n' \
                "$slot" "${pal[$slot]}" "$(theme::swatch "${pal[$slot]}" 10)"
        done
        printf '\n'
        return 0
    fi

    theme::save "$dest" pal "slug=$slug" "name=$name" "variant=$variant" \
        "family=mood" "seed=$seed" "mood=$mood" || {
        ash_log_error "Could not write $dest"; return 1; }

    theme::record "$slug" ai-mood

    if [[ "$json" != "1" ]]; then
        printf '\n  %s💭 %s%s%s — %s%s%s\n' \
            "" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" "${ASH_MUTED}" "$mood ($seed)" "${RST}"
        (( wcag )) && printf '  %s⚠  %s below 4.5:1 — ash theme wcag %s --fix%s\n' \
            "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "$wcag" "pair")" "$slug" "${RST}"
        printf '\n'
    fi

    if (( apply )); then
        theme::source_sub apply || return 1
        theme::apply "$slug" || return $?
    elif [[ "$json" != "1" ]]; then
        printf '  %sApply it:  ash theme apply %s%s\n\n' "${ASH_MUTED}" "$slug" "${RST}"
    fi
}
