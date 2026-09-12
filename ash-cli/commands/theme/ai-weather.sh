#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — ai-weather.sh                                                    ║
# ║  Let the sky pick the palette                                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::ai_weather::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme ai-weather${RST} [location] [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Reads the current conditions from wttr.in and maps them to a palette: rain
  greys and deepens, clear skies take the sun's warmth, snow goes pale and cool.
  Temperature nudges the warm/cool balance on top of the condition.

  Needs network access. When it is unavailable this fails and says so rather
  than falling back to an unrelated theme, and ${ASH_MUTED}--condition${RST} lets you use
  the mapping without a network at all.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--condition NAME${RST}     Use a condition directly (skips the network)
  ${ASH_MUTED}--temp C${RST}             Temperature in Celsius (default 15)
  ${ASH_MUTED}--list${RST}               Show the condition → palette mapping
  ${ASH_MUTED}--apply${RST}              Apply after generating
  ${ASH_MUTED}--dry-run, -n${RST}        Show the palette, write nothing
  ${ASH_MUTED}--json${RST}               Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme ai-weather London${RST}
  ${ASH_MUTED}ash theme ai-weather --condition rain --temp 4 --apply${RST}
EOF
}

# condition → "seed variant". Conditions are matched case-insensitively and by
# substring, because wttr.in describes them in prose.
declare -gA THEME_WEATHER_SEEDS=(
    [clear]="#e2b25c dark"      [sunny]="#e8a63f light"
    [partly-cloudy]="#9fb3c8 dark"  [cloudy]="#8b98a8 dark"
    [overcast]="#6f7885 dark"   [mist]="#9aa5ad dark"
    [fog]="#a8b0b6 dark"        [rain]="#5f7d95 dark"
    [drizzle]="#7d97aa dark"    [shower]="#4f7288 dark"
    [heavy-rain]="#3f5f75 dark" [thunder]="#4a4a6a dark"
    [snow]="#c8d8e8 light"      [sleet]="#a8bccc light"
    [blizzard]="#dce8f0 light"  [hail]="#8fa8bc light"
    [wind]="#7f9fa8 dark"       [hot]="#e0713f dark"
    [cold]="#5f7fa8 dark"
)

# wttr.in's condition text → one of the keys above.
theme::ai_weather::classify() {
    local desc="${1,,}"
    case "$desc" in
        *thunder*|*storm*)            printf 'thunder' ;;
        *blizzard*|*heavy*snow*)      printf 'blizzard' ;;
        *snow*|*sleet*|*ice*pellet*)  printf 'snow' ;;
        *hail*)                       printf 'hail' ;;
        *heavy*rain*|*torrential*)    printf 'heavy-rain' ;;
        *drizzle*|*light*rain*)       printf 'drizzle' ;;
        *shower*)                     printf 'shower' ;;
        *rain*|*wet*)                 printf 'rain' ;;
        *fog*)                        printf 'fog' ;;
        *mist*)                       printf 'mist' ;;
        *overcast*)                   printf 'overcast' ;;
        *cloudy*|*cloud*|*over*)      printf 'cloudy' ;;
        *sunny*|*clear*sun*)          printf 'sunny' ;;
        *clear*)                      printf 'clear' ;;
        *wind*|*gale*)                printf 'wind' ;;
        *)                            printf 'partly-cloudy' ;;
    esac
}

theme::ai_weather() {
    local location="" condition="" temp="15" apply=0 dry=0 json=0 list=0

    while (( $# )); do
        case "$1" in
            --condition)  condition="${2,,}"; shift 2 ;;
            --temp)       temp="${2:-15}"; shift 2 ;;
            --list)       list=1; shift ;;
            --apply)      apply=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::ai_weather::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::ai_weather::help; return 2 ;;
            *)            location="$1"; shift ;;
        esac
    done

    [[ "$temp" =~ ^-?[0-9]+$ ]] || { ash_log_error "--temp takes a number (got: $temp)"; return 2; }

    if (( list )); then
        if (( json )); then
            local obj='{}'
            local k
            for k in "${!THEME_WEATHER_SEEDS[@]}"; do
                obj="$(jq -c --arg k "$k" --arg v "${THEME_WEATHER_SEEDS[$k]}" \
                        '. + {($k): ($v | split(" "))}' <<<"$obj")"
            done
            jq -n --argjson s "$obj" '{conditions: $s}'
        else
            printf '\n  %sWeather → palette%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
            local k seed variant
            for k in clear sunny partly-cloudy cloudy overcast mist fog rain drizzle \
                     shower heavy-rain thunder snow sleet blizzard hail wind hot cold; do
                seed="${THEME_WEATHER_SEEDS[$k]%% *}"
                variant="${THEME_WEATHER_SEEDS[$k]##* }"
                printf '    %-14s %s  %s%-5s%s  %s%s%s\n' \
                    "$k" "$seed" "${ASH_MUTED}" "$variant" "${RST}" \
                    "${ASH_MUTED}" "$(theme::swatch "$seed" 8)" "${RST}"
            done
            printf '\n'
        fi
        return 0
    fi

    # ── Fetch, unless a condition was given outright ──────────────────────────
    local source="given"
    if [[ -z "$condition" ]]; then
        source="network"
        if ! declare -f ash_http_get >/dev/null 2>&1; then
            ash_log_error "HTTP support is not loaded; use --condition instead."
            return 1
        fi

        local where="${location:-}"
        local url="https://wttr.in/${where// /+}?format=%C|%t"
        local raw
        raw="$(ash_http_get "$url" 2>/dev/null || printf '')"

        if [[ -z "$raw" || "$raw" == *"Unknown location"* || "$raw" == *"Sorry"* ]]; then
            ash_log_error "Could not reach wttr.in${where:+ for '$where'}."
            printf '  %sCheck your connection, or pick a condition by hand:%s\n' \
                "${ASH_MUTED}" "${RST}" >&2
            printf '    ash theme ai-weather --condition rain --temp 8\n\n' >&2
            return 1
        fi

        local desc temp_raw
        desc="${raw%%|*}"
        temp_raw="${raw##*|}"
        condition="$(theme::ai_weather::classify "$desc")"

        # "+12°C" / "-3°C" / "12°C"
        if [[ "$temp_raw" =~ (-?[0-9]+) ]]; then
            temp="${BASH_REMATCH[1]}"
        fi
        [[ "$json" != "1" ]] && printf '  %s%s — %s%s\n' \
            "${ASH_MUTED}" "$(awk '{print toupper(substr($0,1,1)) substr($0,2)}' <<<"$desc")" "$temp°C" "${RST}"
    fi

    local spec="${THEME_WEATHER_SEEDS[$condition]:-}"
    if [[ -z "$spec" ]]; then
        ash_log_error "Unknown condition: $condition"
        printf '  %sRun %sash theme ai-weather --list%s for the vocabulary.%s\n\n' \
            "${ASH_MUTED}" "${ASH_ACCENT}" "${ASH_MUTED}" "${RST}" >&2
        return 2
    fi

    local seed variant
    read -r seed variant <<<"$spec"

    # Temperature shifts the palette, not just the label: below freezing cools
    # it, above 28°C warms it, and the variant flips for extremes.
    if (( temp <= 0 )); then
        variant="dark"
        if declare -f ash_ok_set_l >/dev/null 2>&1; then
            seed="$(ash_ok_set_l "$seed" "$(awk -v l="$(ash_ok_l "$seed" 2>/dev/null || echo 0.5)" 'BEGIN{l-=0.06; if(l<0.1)l=0.1; printf "%.4f", l}')" 2>/dev/null || printf '%s' "$seed")"
        fi
    elif (( temp >= 28 )); then
        if declare -f ash_ok_set_l >/dev/null 2>&1; then
            seed="$(ash_ok_set_l "$seed" "$(awk -v l="$(ash_ok_l "$seed" 2>/dev/null || echo 0.5)" 'BEGIN{l+=0.05; if(l>0.9)l=0.9; printf "%.4f", l}')" 2>/dev/null || printf '%s' "$seed")"
        fi
    fi

    local slug="ash-weather-${condition}"
    local dest="${THEME_USER_DIR}/${slug}.json"
    local name="Weather — $condition"

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
        jq -n --arg slug "$slug" --arg condition "$condition" --arg variant "$variant" \
              --arg seed "$seed" --arg temp "$temp" --arg location "$location" \
              --arg source "$source" --arg file "$dest" \
              --argjson dry "$dry" --argjson wcag "$wcag" --argjson colors "$colors_json" \
              '{slug: $slug, condition: $condition, variant: $variant, seed: $seed,
                temperature_c: ($temp|tonumber), location: $location, source: $source,
                file: $file, dry_run: ($dry == 1), wcag_failures: $wcag, colors: $colors}'
        (( dry )) && return 0
    elif (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    condition %s%s%s  temp %s°C  variant %s\n    seed      %s%s%s\n\n' \
            "${ASH_ACCENT}" "$condition" "${RST}" "$temp" "$variant" \
            "${ASH_ACCENT}" "$seed" "${RST}"
        local s
        for s in "${THEME_SLOT_ORDER[@]}"; do
            [[ -n "${pal[$s]:-}" ]] && printf '    %-9s %s  %s\n' \
                "$s" "${pal[$s]}" "$(theme::swatch "${pal[$s]}" 10)"
        done
        printf '\n'
        return 0
    fi

    theme::save "$dest" pal "slug=$slug" "name=$name" "variant=$variant" \
        "family=weather" "seed=$seed" "condition=$condition" "temperature=$temp" || {
        ash_log_error "Could not write $dest"; return 1; }
    theme::record "$slug" ai-weather

    if (( apply )); then
        theme::source_sub apply || return 1
        theme::apply "$slug" || return $?
        if (( json )); then
            jq -n --arg slug "$slug" --arg condition "$condition" \
                  '{slug: $slug, condition: $condition, applied: true}'
        fi
    elif [[ "$json" != "1" ]]; then
        printf '\n  %s🌤  %s%s%s — %s%s at %s°C%s\n' \
            "" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
            "${ASH_MUTED}" "$condition" "$temp" "${RST}"
        (( wcag )) && printf '  %s⚠  %s below 4.5:1 — ash theme wcag %s --fix%s\n' \
            "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "$wcag" "pair")" "$slug" "${RST}"
        printf '\n'
    fi
}
