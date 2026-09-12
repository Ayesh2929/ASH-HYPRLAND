#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — search.sh                                                        ║
# ║  Find a theme by name, colour, hue or family                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::search::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme search${RST} <query…> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Matches the query against slug, display name and family. Beyond text, a query
  may be a colour, which finds themes whose accent looks like it:

    ${ASH_MUTED}#7aa2f7${RST}        accents within --tolerance ΔE of this colour
    ${ASH_MUTED}blue${RST}           hue words (red, orange, yellow, green, teal,
                     cyan, blue, indigo, violet, magenta, pink, brown)
    ${ASH_MUTED}dark${RST} / ${ASH_MUTED}light${RST}    variant

  All conditions must hold, so 'search nord light' means both.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--family NAME${RST}       Restrict to a family
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--tolerance N${RST}       Colour-match distance in OKLab ΔE (default 0.08)
  ${ASH_MUTED}--limit N${RST}           Cap the number of results
  ${ASH_MUTED}--json${RST}              Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme search gruvbox${RST}
  ${ASH_MUTED}ash theme search '#7aa2f7' --tolerance 0.05${RST}
  ${ASH_MUTED}ash theme search teal light${RST}
EOF
}

# Hue words to a centre angle in OKLab degrees.
theme::search::hue_of_word() {
    case "${1,,}" in
        red)              printf '29'  ;;
        orange)           printf '55'  ;;
        brown)            printf '55'  ;;
        yellow)           printf '95'  ;;
        lime)             printf '115' ;;
        green)            printf '142' ;;
        teal)             printf '165' ;;
        cyan)             printf '195' ;;
        blue)             printf '245' ;;
        indigo)           printf '270' ;;
        violet|purple)    printf '292' ;;
        magenta)          printf '325' ;;
        pink|rose)        printf '340' ;;
        *)                return 1 ;;
    esac
}

theme::search() {
    local family="" variant="" tolerance="0.08" limit=""
    local -a terms=()

    while (( $# )); do
        case "$1" in
            --family|-f)    family="${2:-}"; shift 2 ;;
            --variant|-v)   variant="${2:-}"; shift 2 ;;
            --tolerance|-t) tolerance="${2:-0.08}"; shift 2 ;;
            --limit|-n)     limit="${2:-}"; shift 2 ;;
            --json)         export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)      theme::search::help; return 0 ;;
            -*)             ash_log_error "Unknown option: $1"; theme::search::help; return 2 ;;
            *)              terms+=("$1"); shift ;;
        esac
    done

    if (( ${#terms[@]} == 0 )); then
        ash_log_error "Nothing to search for."
        theme::search::help
        return 2
    fi

    [[ "$tolerance" =~ ^[0-9]*\.?[0-9]+$ ]] || {
        ash_log_error "--tolerance takes a number (got: $tolerance)"; return 2; }
    [[ -z "$limit" || "$limit" =~ ^[0-9]+$ ]] || {
        ash_log_error "--limit takes a number (got: $limit)"; return 2; }

    # Split the query into the conditions it implies.
    local -a text_terms=() colour_terms=() hue_terms=()
    local t
    for t in "${terms[@]}"; do
        case "${t,,}" in
            dark|light)
                variant="${t,,}" ;;
            *)
                if [[ "$t" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
                    colour_terms+=("#${t#\#}")
                elif theme::search::hue_of_word "$t" >/dev/null 2>&1; then
                    hue_terms+=("$t")
                else
                    text_terms+=("$t")
                fi
                ;;
        esac
    done

    local -A haystack=()
    local slug name var family_c seed path
    while IFS=$'\t' read -r slug name var family_c seed path; do
        [[ -n "$slug" ]] || continue
        haystack["$slug"]="$(tr '[:upper:]' '[:lower:]' <<<"$slug $name $family_c")"
    done < <(theme::index)

    # Which files need a colour test? Only those that pass the cheap text and
    # metadata filters — a ΔE per file is far more expensive than a substring.
    local -a results=()
    local -A meta=()

    while IFS=$'\t' read -r slug name var family_c seed path; do
        [[ -n "$slug" ]] || continue
        [[ -n "$family"  && "$family_c" != "$family" ]] && continue
        [[ -n "$variant" && "$var" != "$variant" ]] && continue

        local text="${haystack[$slug]}"
        local tt ok=1
        for tt in "${text_terms[@]}"; do
            [[ "$text" == *"${tt,,}"* ]] || { ok=0; break; }
        done
        (( ok )) || continue

        # Text and metadata have already passed; the colour test is the only
        # reason to open the file.
        if (( ${#colour_terms[@]} || ${#hue_terms[@]} )); then
            if ! declare -f ash_ok_from_hex >/dev/null 2>&1; then
                ash_log_error "The colour engine is needed for colour searches."
                return 1
            fi

            local accent
            accent="$(jq -r '(.colors // .) | .accent // empty' "$path" 2>/dev/null)"
            [[ -n "$accent" ]] || continue

            local hue
            hue="$(ash_ok_from_hex "$accent" 2>/dev/null | cut -d' ' -f3)" || continue
            [[ -n "$hue" ]] || continue

            # ash_ok_distance takes two hexes and returns an OKLab delta-E.
            local ct d
            for ct in "${colour_terms[@]}"; do
                d="$(ash_ok_distance "$accent" "$ct" 2>/dev/null || printf '99')"
                awk -v d="$d" -v tol="$tolerance" 'BEGIN { exit !(d <= tol) }' || { ok=0; break; }
            done
            (( ok )) || continue

            local ht word centre diff
            for word in "${hue_terms[@]}"; do
                centre="$(theme::search::hue_of_word "$word")"
                # Circular difference: 350° and 10° are 20° apart, not 340°.
                diff="$(awk -v a="$hue" -v b="$centre" 'BEGIN {
                    d = a - b; if (d < 0) d = -d; if (d > 180) d = 360 - d; print d }')"
                awk -v d="$diff" 'BEGIN { exit !(d <= 30) }' || { ok=0; break; }
            done
            (( ok )) || continue
        fi

        results+=("$slug")
        meta["$slug"]="$(printf '%s\t%s\t%s\t%s' "$slug" "${name:-$slug}" "$var" "$family_c")"
        (( limit )) && (( ${#results[@]} >= limit )) && break
    done < <(theme::index)

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        local rows='[]'
        local r
        for r in "${results[@]}"; do
            rows="$(jq -c --argjson row "$(jq -Rn --arg s "${meta[$r]}" '$s | split("\t") | {slug: .[0], name: .[1], variant: .[2], family: .[3]}')" \
                    '. + [$row]' <<<"$rows")"
        done
        jq -n --argjson n "${#results[@]}" --arg q "${terms[*]}" --argjson r "$rows" \
              '{query: $q, total: $n, themes: $r}'
        return 0
    fi

    ash_banner "🔍 THEME SEARCH" "${terms[*]}" 80

    if (( ${#results[@]} == 0 )); then
        printf '\n  %sNo theme matches "%s".%s\n' "${ASH_MUTED}" "${terms[*]}" "${RST}"
        printf '  %sTry a shorter query, or drop --family/--variant.%s\n\n' "${ASH_MUTED}" "${RST}"
        return 1
    fi

    local r
    for r in "${results[@]}"; do
        printf '    %-30s %s\n' "$r" "$(awk -F'\t' '{ print $2 "  " $3 "  " $4 }' <<<"${meta[$r]}")"
    done
    printf '\n  %s%s%s\n\n' "${ASH_MUTED}" "$(theme::plural "${#results[@]}" result)" "${RST}"
}
