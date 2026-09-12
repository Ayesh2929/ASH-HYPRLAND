#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — create.sh                                                       ║
# ║  Build a new theme from a seed colour, or from a description                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

theme::create::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme create${RST} <#rrggbb | "description"> [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name NAME${RST}       Display name (default: derived from the seed)
  ${ASH_MUTED}--slug SLUG${RST}       File slug (default: from the name)
  ${ASH_MUTED}--light${RST}           Build a light variant
  ${ASH_MUTED}--material${RST}        Use Material You roles instead of the house rules
  ${ASH_MUTED}--out FILE${RST}        Write here instead of the user theme directory
  ${ASH_MUTED}--force, -f${RST}       Overwrite an existing theme
  ${ASH_MUTED}--dry-run, -n${RST}     Show the palette, write nothing

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash theme create '#7aa2f7'
  ash theme create "deep forest at dusk" --light --name "Forest Dusk"
EOF
}

theme::create() {
    local want="" name="" slug="" variant="dark" out="" force=0 dry_run=0 material=0

    while (( $# )); do
        case "$1" in
            --name)     name="${2:-}"; shift 2 ;;
            --slug)     slug="${2:-}"; shift 2 ;;
            --light|-l) variant="light"; shift ;;
            --dark|-d)  variant="dark"; shift ;;
            --material) material=1; shift ;;
            --out|-o)   out="${2:-}"; shift 2 ;;
            --force|-f) force=1; shift ;;
            --dry-run|-n) dry_run=1; shift ;;
            --help|-h)  theme::create::help; return 0 ;;
            *)          want="${want:-$1}"; shift ;;
        esac
    done

    [[ -n "$want" ]] || { theme::create::help >&2; return 2; }

    # A hex seed is used directly; anything else is treated as a description and
    # resolved to a hue by the generator.
    local seed="$want"
    if [[ ! "$want" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
        seed="$(ash_generate_from_prompt "$want" 2>/dev/null)" || {
            ash_log_error "Could not derive a colour from: ${want}"
            return 1
        }
    fi
    seed="$(ash_ok_normalize_hex "$seed")"

    [[ -n "$name" ]] || name="$(ash_generate_name "$seed" 2>/dev/null || printf 'Generated')"
    [[ -n "$slug" ]] || slug="$(ash_generate_slug "$name" 2>/dev/null || \
                                printf '%s' "$name" | tr 'A-Z ' 'a-z-')"
    slug="${slug//[^a-z0-9-]/}"

    local -A pal=()
    if (( material )) && declare -f ash_m3_to_palette >/dev/null 2>&1; then
        ash_m3_to_palette pal "$seed" "$variant"
    else
        ash_palette_derive pal "$seed" "$variant"
        # Complete fills any slot the derivation did not cover, so every
        # template renders without a fallback firing.
        ash_palette_complete pal "$seed" "$variant" 2>/dev/null || true
    fi

    ash_banner "🎨 CREATE" "${name} · ${seed} · ${variant}" "80"
    printf '\n'
    local slot hex
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        hex="${pal[$slot]:-}"
        [[ -n "$hex" ]] || continue
        printf '    %-10s %s%s%s  %s\n' "$slot" "${ASH_MUTED}" "$hex" "${RST}" \
            "$(theme::swatch "$hex" 16)"
    done

    if (( dry_run )); then
        printf '\n  %s%s%s %s\n\n' "$ASH_INFO" "${ICO_INFO}" "${RST}" "Dry run — nothing written"
        return 0
    fi

    [[ -n "$out" ]] || out="${THEME_USER_DIR}/${slug}.json"

    if [[ -e "$out" ]] && (( ! force )); then
        printf '\n'
        ash_log_error "Already exists: ${out}"
        ash_log_info  "Pass --force to replace it, or --slug to pick another name"
        return 1
    fi

    theme::save "$out" pal \
        "name=${name}" "slug=${slug}" "variant=${variant}" \
        "family=custom" "seed=${seed}" "generator=ash-theme-create"

    printf '\n  %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" "Created ${out}"

    # A freshly built palette can still miss the contrast gate — report it now
    # rather than the first time it is applied.
    if declare -f ash_wcag_check_file >/dev/null 2>&1; then
        local fails
        set +e
        fails="$(ash_wcag_check_file "$out" --quiet 2>/dev/null)"
        set -e
        [[ "$fails" =~ ^[0-9]+$ ]] || fails=0
        if (( fails > 0 )); then
            printf '  %s%s%s %s\n' "$ASH_WARNING" "${ICO_WARN}" "${RST}" \
                "$(theme::plural "$fails" check) fail contrast — run 'ash theme wcag ${slug} --fix'"
        fi
    fi
    printf '\n'
}
