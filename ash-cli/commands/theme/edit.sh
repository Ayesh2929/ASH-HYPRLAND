#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — edit.sh                                                          ║
# ║  Change a theme's metadata or individual palette slots                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::edit::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme edit${RST} <theme> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Edits a theme in place. Metadata changes are free; changing a colour re-derives
  the theme from its new seed so the rest of the palette stays coherent, unless
  you name a slot explicitly.

  Built-in themes are read-only. Point this at a clone instead — it will offer to
  make one.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name NAME${RST}            Display name
  ${ASH_MUTED}--slug SLUG${RST}            New slug (also renames the file)
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--family NAME${RST}          Family, for grouping
  ${ASH_MUTED}--seed #RRGGBB${RST}         New seed; re-derives the whole palette
  ${ASH_MUTED}--slot SLOT=#RRGGBB${RST}    Set one slot (repeatable)
  ${ASH_MUTED}--rotate DEG${RST}           Rotate every accent hue by DEG degrees
  ${ASH_MUTED}--dry-run, -n${RST}          Show the diff without writing
  ${ASH_MUTED}--json${RST}                 Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme edit nord-mine --name "Nord Mine"${RST}
  ${ASH_MUTED}ash theme edit nord-mine --slot accent=#88c0d0 --slot rose=#bf616a${RST}
  ${ASH_MUTED}ash theme edit nord-mine --seed '#81a1c1' --dry-run${RST}
EOF
}

# Normalise and verify a colour argument. Accepts #rgb, #rrggbb, rgb and rrggbb.
_theme_edit_hex() {
    local v="$1"
    if declare -f ash_ok_normalize_hex >/dev/null 2>&1; then
        ash_ok_normalize_hex "$v" 2>/dev/null && return 0
    fi
    v="${v#\#}"
    [[ "$v" =~ ^[0-9a-fA-F]{6}$ ]] && { printf '#%s' "$(tr 'A-F' 'a-f' <<<"$v")"; return 0; }
    [[ "$v" =~ ^[0-9a-fA-F]{3}$ ]] && {
        printf '#%s%s%s%s%s%s' "${v:0:1}" "${v:0:1}" "${v:1:1}" "${v:1:1}" "${v:2:1}" "${v:2:1}" | tr 'A-F' 'a-f'
        return 0
    }
    return 1
}

theme::edit() {
    local want="" new_name="" new_slug="" new_variant="" new_family="" new_seed=""
    local rotate="" dry=0
    local -a slot_pairs=()

    while (( $# )); do
        case "$1" in
            --name)    new_name="${2:-}"; shift 2 ;;
            --slug)    new_slug="${2:-}"; shift 2 ;;
            --variant) new_variant="${2:-}"; shift 2 ;;
            --family)  new_family="${2:-}"; shift 2 ;;
            --seed)    new_seed="${2:-}"; shift 2 ;;
            --slot)    slot_pairs+=("${2:-}"); shift 2 ;;
            --rotate)  rotate="${2:-}"; shift 2 ;;
            --dry-run|-n) dry=1; shift ;;
            --json)    export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help) theme::edit::help; return 0 ;;
            -*)        ash_log_error "Unknown option: $1"; theme::edit::help; return 2 ;;
            *)         want="$1"; shift ;;
        esac
    done

    [[ -n "$want" ]] || { ash_log_error "Which theme should I edit?"; theme::edit::help; return 2; }

    if [[ -z "$new_name$new_slug$new_variant$new_family$new_seed$rotate" && ${#slot_pairs[@]} -eq 0 ]]; then
        ash_log_error "Nothing to change."
        printf '  %sTry --name, --slug, --variant, --family, --seed, --slot or --rotate.%s\n\n' \
            "${ASH_MUTED}" "${RST}" >&2
        theme::edit::help
        return 2
    fi

    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    # Built-ins are regenerated from the repo, so an edit there is thrown away at
    # the next catalogue build. Offer the clone rather than doing it silently.
    local real_user real_file
    real_user="$(cd "$THEME_USER_DIR" 2>/dev/null && pwd || printf '%s' "$THEME_USER_DIR")"
    real_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
    if [[ "$real_file" != "${real_user}"/* ]]; then
        ash_log_error "'$want' is a catalogue theme; edits there are lost at the next rebuild."
        printf '\n  %sClone it first, then edit the clone:%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        printf '    ash theme clone %s %s-mine\n' "$want" "$want" >&2
        printf '    ash theme edit %s-mine --slot accent=#88c0d0\n\n' "$want" >&2
        return 2
    fi

    # ── Validate every argument before touching the file ──────────────────────
    if [[ -n "$new_variant" && "$new_variant" != "dark" && "$new_variant" != "light" ]]; then
        ash_log_error "--variant must be dark or light (got: $new_variant)"; return 2
    fi
    if [[ -n "$new_seed" ]]; then
        if ! new_seed="$(_theme_edit_hex "$new_seed")"; then
            ash_log_error "--seed is not a colour: $new_seed"; return 2
        fi
    fi
    if [[ -n "$rotate" && ! "$rotate" =~ ^-?[0-9]+$ ]]; then
        ash_log_error "--rotate takes whole degrees (got: $rotate)"; return 2
    fi

    local -a normalised_slots=()
    local pair slot hex
    for pair in "${slot_pairs[@]}"; do
        if [[ "$pair" != *=* ]]; then
            ash_log_error "--slot wants SLOT=#RRGGBB (got: $pair)"; return 2
        fi
        slot="${pair%%=*}"
        hex="${pair#*=}"
        if ! theme::is_slot "$slot"; then
            ash_log_error "Unknown slot: $slot"
            printf '  %sValid slots: %s%s\n\n' "${ASH_MUTED}" \
                "$(printf '%s ' "${THEME_SLOT_ORDER[@]}")" "${RST}" >&2
            return 2
        fi
        if ! hex="$(_theme_edit_hex "$hex")"; then
            ash_log_error "Slot '$slot' has an invalid colour: ${pair#*=}"; return 2
        fi
        normalised_slots+=("$slot=$hex")
    done

    # ── Build the new palette in memory ───────────────────────────────────────
    local -A before=() after=()
    theme::load "$file" before

    local old_slug old_variant
    old_slug="$(jq -r '.slug // empty' "$file" 2>/dev/null)"
    old_variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
    [[ -n "$new_variant" ]] || new_variant="$old_variant"

    local -A pal=()
    if [[ -n "$new_seed" ]] && declare -f ash_palette_derive >/dev/null 2>&1; then
        # A new seed means a new palette: re-derive so every slot keeps its
        # relationship to the accent rather than leaving 12 stale colours.
        ash_palette_derive pal "$new_seed" "$new_variant" || {
            ash_log_error "Could not derive a palette from $new_seed"; return 1; }
    else
        local k
        for k in "${!before[@]}"; do pal["$k"]="${before[$k]}"; done
        # Keep the seed metadata honest when the variant changes without a seed.
        [[ -n "$new_seed" ]] && pal[seed]="$new_seed"
    fi

    # An explicit --slot always wins over a derived value.
    for pair in "${normalised_slots[@]}"; do
        pal["${pair%%=*}"]="${pair#*=}"
    done

    if [[ -n "$rotate" ]] && declare -f ash_ok_rotate >/dev/null 2>&1; then
        for slot in accent mint sky gold rose violet; do
            [[ -n "${pal[$slot]:-}" ]] || continue
            pal["$slot"]="$(ash_ok_rotate "${pal[$slot]}" "$rotate" 2>/dev/null || printf '%s' "${pal[$slot]}")"
        done
    fi

    [[ -n "$new_name" ]]    || new_name="$(jq -r '.name // empty' "$file" 2>/dev/null)"
    [[ -n "$new_slug" ]]    || new_slug="$old_slug"
    [[ -n "$new_family" ]]  || new_family="$(jq -r '.family // "other"' "$file" 2>/dev/null)"
    new_slug="$(ash_generate_slug "$new_slug" 2>/dev/null || printf '%s' "$new_slug")"

    local dest_file="${THEME_USER_DIR}/${new_slug}.json"

    # ── Report, then write ────────────────────────────────────────────────────
    if (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n\n' "${ASH_MUTED}" "${RST}"
    fi

    local changed=0
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        local b="${before[$slot]:-}" a="${pal[$slot]:-}"
        [[ "$b" != "$a" ]] && (( changed++ )) || true
    done

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg slug "$new_slug" --arg name "$new_name" --arg variant "$new_variant" \
              --arg family "$new_family" --arg file "$dest_file" \
              --arg old_slug "$old_slug" --argjson slots "$changed" \
              --argjson dry "$dry" --argjson colors "$colors_json" \
              '{slug: $slug, name: $name, variant: $variant, family: $family,
                file: $file, previous_slug: $old_slug, slots_changed: $slots,
                dry_run: ($dry == 1), colors: $colors}'
        (( dry )) && return 0
    elif (( dry )); then
        printf '    %-9s %-10s → %s\n' "slot" "before" "after"
        for slot in "${THEME_SLOT_ORDER[@]}"; do
            local b="${before[$slot]:-}" a="${pal[$slot]:-}"
            [[ "$b" != "$a" ]] && printf '    %-9s %-10s → %s%s%s\n' \
                "$slot" "${b:-—}" "${ASH_ACCENT}" "${a:-—}" "${RST}"
        done
        printf '\n    %sslug %s → %s%s\n\n' "${ASH_MUTED}" "$old_slug" "$new_slug" "${RST}"
        return 0
    fi

    theme::save "$dest_file" pal "slug=$new_slug" "name=$new_name" \
        "variant=$new_variant" "family=$new_family" \
        "seed=${new_seed:-${pal[seed]:-${before[accent]:-}}}" || {
        ash_log_error "Could not write $dest_file"; return 1; }

    # A slug change means a rename; leaving the old file would give the
    # catalogue two copies of one theme.
    if [[ "$new_slug" != "$old_slug" && "$file" != "$dest_file" && "$file" == "${real_user}"/* ]]; then
        rm -f "$file"
    fi

    theme::record "$new_slug" edit

    [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && return 0

    printf '\n  %s✅ Updated%s %s%s%s %s(%s changed)%s\n' \
        "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$new_slug" "${RST}" \
        "${ASH_MUTED}" "$(theme::plural "$changed" slot)" "${RST}"
    printf '  %s   %s%s\n\n' "${ASH_MUTED}" "$dest_file" "${RST}"

    if (( changed )); then
        printf '  %sRe-apply to see it:  ash theme apply %s%s\n\n' \
            "${ASH_MUTED}" "$new_slug" "${RST}"
    fi
}
