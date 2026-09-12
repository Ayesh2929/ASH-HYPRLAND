#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — random.sh                                                        ║
# ║  Pick a theme you did not choose                                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::random::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme random${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Chooses a theme at random and applies it. Filters apply first and the pick is
  made from what is left, so "a random light theme" is a bounded choice rather
  than a rejection loop.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--family NAME${RST}       Only this family
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--dark${RST}              Short for --variant dark
  ${ASH_MUTED}--light${RST}             Short for --variant light
  ${ASH_MUTED}--favourites${RST}        Only starred themes
  ${ASH_MUTED}--user${RST}              Only themes you made or imported
  ${ASH_MUTED}--no-apply${RST}          Print the choice, change nothing
  ${ASH_MUTED}--avoid-current${RST}     Never pick what is applied now
  ${ASH_MUTED}--seed N${RST}            Deterministic pick (same N, same theme)
  ${ASH_MUTED}--json${RST}              Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme random${RST}
  ${ASH_MUTED}ash theme random --light --avoid-current${RST}
  ${ASH_MUTED}ash theme random --no-apply --seed 42${RST}
EOF
}

theme::random() {
    local family="" variant="" favs=0 user=0 apply=1 avoid=0 seed="" dry=0

    while (( $# )); do
        case "$1" in
            --family|-f)   family="${2:-}"; shift 2 ;;
            --variant|-v)  variant="${2:-}"; shift 2 ;;
            --dark)        variant="dark"; shift ;;
            --light)       variant="light"; shift ;;
            --favourites|--favorites) favs=1; shift ;;
            --user|-u)     user=1; shift ;;
            --no-apply)    apply=0; shift ;;
            --avoid-current) avoid=1; shift ;;
            --seed)        seed="${2:-}"; shift 2 ;;
            --json)        export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)     theme::random::help; return 0 ;;
            -*)            ash_log_error "Unknown option: $1"; theme::random::help; return 2 ;;
            *)             ash_log_error "Unexpected argument: $1"; theme::random::help; return 2 ;;
        esac
    done

    [[ -z "$variant" || "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"; return 2; }
    [[ -z "$seed" || "$seed" =~ ^[0-9]+$ ]] || {
        ash_log_error "--seed takes a number (got: $seed)"; return 2; }

    local real_user
    real_user="$(cd "$THEME_USER_DIR" 2>/dev/null && pwd || printf '%s' "$THEME_USER_DIR")"

    # Favourites are a small set, so load them once rather than per row.
    local -a fav_slugs=()
    if (( favs )) && [[ -f "$THEME_FAVORITES_FILE" ]]; then
        mapfile -t fav_slugs < <(jq -r '.themes[]? // .[]?' "$THEME_FAVORITES_FILE" 2>/dev/null) || true
        if (( ${#fav_slugs[@]} == 0 )); then
            ash_log_error "No favourites yet."
            printf '  %sStar one first:  ash theme favorite add <theme>%s\n\n' "${ASH_MUTED}" "${RST}" >&2
            return 1
        fi
    fi

    local current=""
    current="$(theme::current 2>/dev/null || true)"

    local -a pool=()
    local slug name var family_c path
    while IFS=$'\t' read -r slug name var family_c _seed path; do
        [[ -n "$slug" ]] || continue
        [[ -n "$family" && "$family_c" != "$family" ]] && continue
        [[ -n "$variant" && "$var" != "$variant" ]] && continue
        if (( user )); then
            local rp
            rp="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
            [[ "$rp" == "${real_user}"/* ]] || continue
        fi
        if (( favs )); then
            local hit=0 f
            for f in "${fav_slugs[@]}"; do [[ "$f" == "$slug" ]] && { hit=1; break; }; done
            (( hit )) || continue
        fi
        if (( avoid )) && [[ "$slug" == "$current" ]]; then continue; fi
        pool+=("$slug")
    done < <(theme::index)

    if (( ${#pool[@]} == 0 )); then
        ash_log_error "No theme matches those filters."
        (( avoid )) && (( ${#pool[@]} == 0 )) && \
            printf '  %s--avoid-current removed the only candidate; try again without it.%s\n' \
                "${ASH_MUTED}" "${RST}" >&2
        printf '\n'
        return 1
    fi

    local idx
    if [[ -n "$seed" ]]; then
        # Modulo rather than $RANDOM so the same seed gives the same theme on
        # any machine and in any shell.
        idx=$(( seed % ${#pool[@]} ))
    elif [[ -r /dev/urandom ]]; then
        idx="$(od -An -N2 -tu2 < /dev/urandom | tr -d ' ')"
        idx=$(( idx % ${#pool[@]} ))
    else
        idx=$(( RANDOM % ${#pool[@]} ))
    fi

    local chosen="${pool[$idx]}"
    local chosen_file
    if ! chosen_file="$(theme::resolve "$chosen")"; then
        ash_log_error "Could not resolve the chosen theme: $chosen"
        return 1
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && (( ! apply )); then
        jq -n --arg slug "$chosen" --arg file "$chosen_file" --argjson pool "${#pool[@]}" \
              --arg family "$family" --arg variant "$variant" --arg seed "$seed" \
              '{slug: $slug, file: $file, candidates: $pool,
                filters: {family: $family, variant: $variant, seed: $seed}, applied: false}'
        return 0
    fi

    if (( ! apply )); then
        printf '\n  %s🎲 %s%s%s  %s(%s to choose from)%s\n\n' \
            "" "${BOLD}${ASH_ACCENT}" "$chosen" "${RST}" \
            "${ASH_MUTED}" "${#pool[@]}" "${RST}"
        printf '  %sApply it:  ash theme apply %s%s\n\n' "${ASH_MUTED}" "$chosen" "${RST}"
        return 0
    fi

    # Apply through the same code path as the command, so hooks, the current
    # marker and the history all stay consistent.
    theme::source_sub apply || return 1
    theme::apply "$chosen" || return $?

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        jq -n --arg slug "$chosen" --arg file "$chosen_file" --argjson pool "${#pool[@]}" \
              '{slug: $slug, file: $file, candidates: $pool, applied: true}'
        return 0
    fi

    printf '  🎲 Chose %s%s%s at random from %s%s%s\n\n' \
        "${BOLD}${ASH_ACCENT}" "$chosen" "${RST}" \
        "${ASH_MUTED}" "$(theme::plural "${#pool[@]}" candidate)" "${RST}"
}
