#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — pick.sh                                                          ║
# ║  Choose a theme from a list instead of remembering its name                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::pick::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme pick${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Shows the catalogue and applies whatever you choose. With a fuzzy finder
  installed (fzf, sk) you can type to filter; otherwise a numbered prompt is
  used, which works over a plain terminal and a serial console.

  Entering a number previews the theme before applying it, so a wrong keystroke
  costs a redraw rather than a re-themed desktop.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--family NAME${RST}       Only this family
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--favourites${RST}        Only starred themes
  ${ASH_MUTED}--no-preview${RST}        Skip the preview step
  ${ASH_MUTED}--no-apply${RST}          Print the choice, change nothing
  ${ASH_MUTED}--json${RST}              Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme pick${RST}
  ${ASH_MUTED}ash theme pick --family catppuccin${RST}
EOF
}

theme::pick() {
    local family="" variant="" favs=0 preview=1 apply=1

    while (( $# )); do
        case "$1" in
            --family|-f)  family="${2:-}"; shift 2 ;;
            --variant|-v) variant="${2:-}"; shift 2 ;;
            --favourites|--favorites) favs=1; shift ;;
            --no-preview) preview=0; shift ;;
            --no-apply)   apply=0; shift ;;
            --json)       export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::pick::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::pick::help; return 2 ;;
            *)            ash_log_error "Unexpected argument: $1"; theme::pick::help; return 2 ;;
        esac
    done

    [[ -z "$variant" || "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"; return 2; }

    local -a fav_slugs=()
    if (( favs )) && [[ -f "$THEME_FAVORITES_FILE" ]]; then
        mapfile -t fav_slugs < <(jq -r '.themes[]? // .[]?' "$THEME_FAVORITES_FILE" 2>/dev/null) || true
    fi

    local -a slugs=() labels=()
    local slug name var family_c _seed _path

    while IFS=$'\t' read -r slug name var family_c _seed _path; do
        [[ -n "$slug" ]] || continue
        [[ -n "$family" && "$family_c" != "$family" ]] && continue
        [[ -n "$variant" && "$var" != "$variant" ]] && continue
        if (( favs )); then
            local hit=0 f
            for f in "${fav_slugs[@]}"; do [[ "$f" == "$slug" ]] && { hit=1; break; }; done
            (( hit )) || continue
        fi
        slugs+=("$slug")
        labels+=("$(printf '%-28s %s' "$slug" "${name:-$slug}")")
    done < <(theme::index)

    if (( ${#slugs[@]} == 0 )); then
        ash_log_error "No theme matches those filters."
        return 1
    fi

    local chosen=""

    # ── Fuzzy finder, when one is available ───────────────────────────────────
    if declare -f ash_dep_has_command >/dev/null 2>&1 && ash_dep_has_command fzf 2>/dev/null; then
        chosen="$(printf '%s\n' "${labels[@]}" | fzf --prompt="theme ❯ " --height=60% \
                    --preview-window=down:60% 2>/dev/tty)" || true
        chosen="${chosen%% *}"

    elif declare -f ash_prompt_select >/dev/null 2>&1; then
        # The house prompt, which degrades on its own when there is no tty.
        chosen="$(ash_prompt_select "Choose a theme" "${labels[@]}" 2>/dev/tty)" || true
        [[ -n "$chosen" ]] && chosen="${chosen%% *}"
    fi

    # ── Numbered fallback ─────────────────────────────────────────────────────
    if [[ -z "$chosen" ]]; then
        if [[ ! -t 0 && ! -e /dev/tty ]]; then
            ash_log_error "No terminal to prompt on."
            printf '  %sUse --json for the list, or pass a theme name directly.%s\n\n' \
                "${ASH_MUTED}" "${RST}" >&2
            return 1
        fi

        printf '\n  %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "🎯 PICK A THEME" "${RST}"
        local i=0
        for i in "${!labels[@]}"; do
            printf '    %s%3d%s  %s\n' "${ASH_MUTED}" "$(( i + 1 ))" "${RST}" "${labels[$i]}"
        done
        printf '\n  %s0 = cancel%s\n\n' "${ASH_MUTED}" "${RST}"

        local reply=""
        read -r -p "  Number: " reply </dev/tty || true
        [[ "$reply" =~ ^[0-9]+$ ]] || { ash_log_error "Not a number: $reply"; return 2; }
        (( reply == 0 )) && { printf '  %sCancelled.%s\n' "${ASH_MUTED}" "${RST}"; return 0; }
        (( reply >= 1 && reply <= ${#slugs[@]} )) || {
            ash_log_error "Out of range: $reply (1-${#slugs[@]})"; return 2; }
        chosen="${slugs[$(( reply - 1 ))]}"
    fi

    [[ -n "$chosen" ]] || return 0

    # ── Preview, then confirm ─────────────────────────────────────────────────
    if (( preview )) && theme::resolve "$chosen" >/dev/null 2>&1; then
        theme::source_sub preview || true
        declare -F theme::preview >/dev/null 2>&1 && theme::preview "$chosen" >/dev/tty 2>&1 || true

        if declare -f ash_confirm >/dev/null 2>&1; then
            ash_confirm "Apply $chosen?" </dev/tty || {
                printf '  %sNot applied.%s\n\n' "${ASH_MUTED}" "${RST}"
                return 0
            }
        fi
    fi

    if (( ! apply )); then
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            jq -n --arg slug "$chosen" --argjson n "${#slugs[@]}" \
                  '{slug: $slug, candidates: $n, applied: false}'
        else
            printf '\n  %s→ %s%s%s\n\n' "" "${BOLD}${ASH_ACCENT}" "$chosen" "${RST}"
        fi
        return 0
    fi

    theme::source_sub apply || return 1
    theme::apply "$chosen" || return $?

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        jq -n --arg slug "$chosen" --argjson n "${#slugs[@]}" \
              '{slug: $slug, candidates: $n, applied: true}'
    fi
}
