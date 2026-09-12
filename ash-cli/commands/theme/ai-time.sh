#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — ai-time.sh                                                       ║
# ║  A theme that follows the clock                                                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::ai_time::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme ai-time${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Generates a palette matched to the hour: cool and dimmest overnight, warm at
  dawn, neutral and bright through the working day, warm again at dusk. The
  variant follows the sun too — light themes during daylight hours, dark after.

  Unlike ${ASH_MUTED}ash theme schedule${RST}, which applies themes you chose, this
  synthesises one from the clock and caches it, so the same hour on another day
  produces the same theme rather than a new file each time.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--apply${RST}            Apply the resulting theme
  ${ASH_MUTED}--at HH[:MM]${RST}       Use this local time instead of now (for testing)
  ${ASH_MUTED}--force-light${RST}      Force the light variant
  ${ASH_MUTED}--force-dark${RST}       Force the dark variant
  ${ASH_MUTED}--slot NAME${RST}        Use a named slot instead of the hour
  ${ASH_MUTED}--list${RST}             Show the four slots
  ${ASH_MUTED}--dry-run, -n${RST}      Show the palette, write nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme ai-time${RST}
  ${ASH_MUTED}ash theme ai-time --at 06:30 --dry-run${RST}
  ${ASH_MUTED}ash theme ai-time --apply${RST}
EOF
}

# slot → "seed variant label". The seed is the hour's colour temperature made
# concrete; the generator does the rest.
declare -gA THEME_TIME_SLOTS=(
    [dawn]="#c98a6b dark"
    [morning]="#e0b070 light"
    [day]="#7fa8d4 light"
    [afternoon]="#6f9fbf light"
    [dusk]="#a4708f dark"
    [evening]="#6a5a8f dark"
    [night]="#3a4a7a dark"
    [deep-night]="#2a3050 dark"
)

theme::ai_time::slot_for_hour() {
    local h="${1:-0}"
    h="${h#0}"; [[ -z "$h" ]] && h=0
    if   (( h >= 5  && h < 8  )); then printf 'dawn'
    elif (( h >= 8  && h < 11 )); then printf 'morning'
    elif (( h >= 11 && h < 15 )); then printf 'day'
    elif (( h >= 15 && h < 18 )); then printf 'afternoon'
    elif (( h >= 18 && h < 20 )); then printf 'dusk'
    elif (( h >= 20 && h < 22 )); then printf 'evening'
    elif (( h >= 22 && h < 24 )); then printf 'night'
    else                                printf 'deep-night'
    fi
}

theme::ai_time() {
    local apply=0 at="" force_light=0 force_dark=0 slot="" list=0 dry=0 json=0

    while (( $# )); do
        case "$1" in
            --apply)        apply=1; shift ;;
            --at)           at="${2:-}"; shift 2 ;;
            --force-light)  force_light=1; shift ;;
            --force-dark)   force_dark=1; shift ;;
            --slot)         slot="${2:-}"; shift 2 ;;
            --list)         list=1; shift ;;
            --dry-run|-n)   dry=1; shift ;;
            --json)         json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)      theme::ai_time::help; return 0 ;;
            -*)             ash_log_error "Unknown option: $1"; theme::ai_time::help; return 2 ;;
            *)              ash_log_error "Unexpected argument: $1"; theme::ai_time::help; return 2 ;;
        esac
    done

    if (( force_light && force_dark )); then
        ash_log_error "--force-light and --force-dark are mutually exclusive"; return 2
    fi

    if (( list )); then
        if (( json )); then
            local obj='{}'
            local k
            for k in dawn morning day afternoon dusk evening night deep-night; do
                obj="$(jq -c --arg k "$k" --arg v "${THEME_TIME_SLOTS[$k]}" \
                        '. + {($k): ($v | split(" "))}' <<<"$obj")"
            done
            jq -n --argjson s "$obj" '{slots: $s}'
        else
            printf '\n  %sTime-of-day slots%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
            local k seed variant
            for k in dawn morning day afternoon dusk evening night deep-night; do
                read -r seed variant <<<"${THEME_TIME_SLOTS[$k]}"
                printf '    %-11s %s  %s%s%s  %s%s%s\n' \
                    "$k" "$seed" "${ASH_MUTED}" "$variant" "${RST}" \
                    "${ASH_MUTED}" "$(theme::swatch "$seed" 8)" "${RST}"
            done
            printf '\n'
        fi
        return 0
    fi

    # ── Which slot? ───────────────────────────────────────────────────────────
    local hour
    if [[ -n "$at" ]]; then
        if [[ "$at" =~ ^([0-9]{1,2})(:([0-9]{2}))?$ ]]; then
            hour="${BASH_REMATCH[1]}"
        else
            ash_log_error "--at wants HH or HH:MM (got: $at)"; return 2
        fi
        (( hour >= 0 && hour <= 23 )) || { ash_log_error "--at hour out of range: $hour"; return 2; }
    else
        hour="$(date +%H 2>/dev/null || printf '12')"
    fi

    [[ -n "$slot" ]] || slot="$(theme::ai_time::slot_for_hour "$hour")"

    local spec="${THEME_TIME_SLOTS[$slot]:-}"
    if [[ -z "$spec" ]]; then
        ash_log_error "Unknown slot: $slot"
        printf '  %sValid slots: %s%s\n\n' "${ASH_MUTED}" "$(printf '%s ' dawn morning day afternoon dusk evening night deep-night)" "${RST}" >&2
        return 2
    fi

    local seed variant
    read -r seed variant <<<"$spec"
    (( force_light )) && variant="light"
    (( force_dark ))  && variant="dark"

    local slug="ash-time-${slot}"
    local dest="${THEME_USER_DIR}/${slug}.json"
    local name="Time of Day — $slot"

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
        jq -n --arg slug "$slug" --arg slot "$slot" --arg variant "$variant" \
              --arg seed "$seed" --arg at "${at:-now}" --arg hour "$hour" \
              --arg file "$dest" --argjson dry "$dry" --argjson wcag "$wcag" \
              --argjson colors "$colors_json" \
              '{slug: $slug, slot: $slot, variant: $variant, seed: $seed,
                requested_at: $at, hour: $hour, file: $file,
                dry_run: ($dry == 1), wcag_failures: $wcag, colors: $colors}'
        (( dry )) && return 0
    elif (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    slot   %s%s%s  (hour %s)\n    seed   %s%s%s\n    variant %s\n\n' \
            "${ASH_ACCENT}" "$slot" "${RST}" "$hour" "${ASH_ACCENT}" "$seed" "${RST}" "$variant"
        local s
        for s in "${THEME_SLOT_ORDER[@]}"; do
            [[ -n "${pal[$s]:-}" ]] && printf '    %-9s %s  %s\n' \
                "$s" "${pal[$s]}" "$(theme::swatch "${pal[$s]}" 10)"
        done
        printf '\n'
        return 0
    fi

    # Cached: the same slot regenerates to the same file rather than
    # accumulating one theme per hour per day.
    local existing_color=""
    [[ -f "$dest" ]] && existing_color="$(jq -r '.colors.base // empty' "$dest" 2>/dev/null)"

    if [[ "$existing_color" == "${pal[base]}" ]]; then
        [[ "$json" != "1" ]] && printf '\n  %s%s is already up to date (%s, %s).%s\n' \
            "${ASH_MUTED}" "$slug" "$slot" "$variant" "${RST}"
        if (( ! apply )); then
            [[ "$json" != "1" ]] && printf '\n'
            return 0
        fi
    else
        theme::save "$dest" pal "slug=$slug" "name=$name" "variant=$variant" \
            "family=time" "seed=$seed" "slot=$slot" || {
            ash_log_error "Could not write $dest"; return 1; }
        theme::record "$slug" ai-time
    fi

    if (( apply )); then
        theme::source_sub apply || return 1
        theme::apply "$slug" || return $?
        if (( json )); then
            jq -n --arg slug "$slug" --arg slot "$slot" \
                  '{slug: $slug, slot: $slot, applied: true}'
        fi
    elif [[ "$json" != "1" ]]; then
        printf '  %s🕐 %s%s%s — %s%s%s  %s(ash theme ai-time --apply)%s\n\n' \
            "" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
            "${ASH_MUTED}" "$slot/$variant" "${RST}" "${ASH_MUTED}" "${RST}"
    fi
}
