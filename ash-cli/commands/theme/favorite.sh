#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — favorite.sh                                                      ║
# ║  Star the themes you use, so random and pick can work from a shortlist         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::favorite::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme favorite${RST} [list]
  ${ASH_ACCENT}ash theme favorite add${RST} <theme>…
  ${ASH_ACCENT}ash theme favorite remove${RST} <theme>…
  ${ASH_ACCENT}ash theme favorite toggle${RST} <theme>…
  ${ASH_ACCENT}ash theme favorite clear${RST}
  ${ASH_ACCENT}ash theme favorite cycle${RST}

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Favourites are a plain list of slugs in
  ${ASH_MUTED}\$XDG_DATA_HOME/ash/theme-favorites.json${RST}. They feed
  ${ASH_MUTED}theme random --favourites${RST} and ${ASH_MUTED}theme pick --favourites${RST}.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--json${RST}      Machine-readable output
  ${ASH_MUTED}--force, -f${RST} Skip the confirmation on clear

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme favorite add nord gruvbox${RST}
  ${ASH_MUTED}ash theme favorite toggle nord${RST}
  ${ASH_MUTED}ash theme favorite cycle${RST}
EOF
}

# Read the file as a newline list. Tolerates both {"themes":[…]} and a bare
# array, so a hand-edited file keeps working.
theme::favorite::load() {
    local -n out="$1"
    out=()
    [[ -f "$THEME_FAVORITES_FILE" ]] || return 0
    mapfile -t out < <(jq -r '.themes[]? // .[]?' "$THEME_FAVORITES_FILE" 2>/dev/null) || true
}

theme::favorite::write() {
    local -n list="$1"
    mkdir -p "$(dirname "$THEME_FAVORITES_FILE")" 2>/dev/null || true

    local json='[]'
    local s
    for s in "${list[@]}"; do
        [[ -n "$s" ]] || continue
        json="$(jq -c --arg s "$s" '. + [$s]' <<<"$json")"
    done

    jq -n --argjson t "$json" \
       --arg at "$(date -Is 2>/dev/null || date)" \
       '{themes: $t, updated: $at}' > "${THEME_FAVORITES_FILE}.tmp" || return 1
    mv "${THEME_FAVORITES_FILE}.tmp" "$THEME_FAVORITES_FILE"
}

theme::favorite() {
    local action="list" json=0 force=0
    local -a targets=()

    while (( $# )); do
        case "$1" in
            --json)      json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            --force|-f)  force=1; shift ;;
            -h|--help)   theme::favorite::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::favorite::help; return 2 ;;
            *)
                case "${1,,}" in
                    add|remove|rm|delete|toggle|clear|list|ls|cycle)
                        action="${1,,}" ;;
                    *) targets+=("$1") ;;
                esac
                shift ;;
        esac
    done

    case "$action" in
        rm|delete) action="remove" ;;
        ls)        action="list" ;;
    esac

    local -a favs=()
    theme::favorite::load favs

    case "$action" in
        list)
            if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
                local rows='[]' s
                for s in "${favs[@]}"; do
                    [[ -n "$s" ]] || continue
                    local name variant family
                    local f
                    f="$(theme::resolve "$s" 2>/dev/null || printf '')"
                    if [[ -n "$f" ]]; then
                        name="$(jq -r '.name // empty' "$f" 2>/dev/null)"
                        variant="$(jq -r '.variant // "dark"' "$f" 2>/dev/null)"
                        family="$(jq -r '.family // "other"' "$f" 2>/dev/null)"
                    else
                        # A favourite whose theme was deleted: say so rather
                        # than hiding it, or the list silently shrinks.
                        name="(missing)"; variant=""; family=""
                    fi
                    rows="$(jq -c --arg s "$s" --arg n "$name" --arg v "$variant" --arg f "$family" \
                            '. + [{slug: $s, name: $n, variant: $v, family: $f,
                                   present: ($n != "(missing)")}]' <<<"$rows")"
                done
                jq -n --argjson t "$rows" '{count: ($t|length), themes: $t}'
                return 0
            fi

            ash_banner "⭐ FAVOURITE THEMES" "$(theme::plural "${#favs[@]}" theme)" 80

            if (( ${#favs[@]} == 0 )); then
                printf '\n  %sNothing starred yet.%s\n' "${ASH_MUTED}" "${RST}"
                printf '  %sStar a theme:  ash theme favorite add nord%s\n\n' "${ASH_MUTED}" "${RST}"
                return 0
            fi

            local s n=0
            for s in "${favs[@]}"; do
                [[ -n "$s" ]] || continue
                local f
                f="$(theme::resolve "$s" 2>/dev/null || printf '')"
                if [[ -n "$f" ]]; then
                    local name variant
                    name="$(jq -r '.name // empty' "$f" 2>/dev/null)"
                    variant="$(jq -r '.variant // "dark"' "$f" 2>/dev/null)"
                    printf '    %s⭐%s %-28s %s%s%s\n' \
                        "${ASH_ACCENT}" "${RST}" "$s" "${ASH_MUTED}" "${name:-$s}  $variant" "${RST}"
                    (( n++ )) || true
                else
                    printf '    %s⚠%s  %-28s %smissing — the theme was deleted%s\n' \
                        "${ASH_WARNING:-$ASH_MUTED}" "${RST}" "$s" "${ASH_MUTED}" "${RST}"
                fi
            done
            printf '\n  %s%s%s\n\n' "${ASH_MUTED}" "$(theme::plural "$n" favourite)" "${RST}"
            ;;

        clear)
            if (( ${#favs[@]} == 0 )); then
                printf '\n  %sNo favourites to clear.%s\n\n' "${ASH_MUTED}" "${RST}"
                return 0
            fi
            if (( ! force )) && declare -f ash_confirm >/dev/null 2>&1; then
                ash_confirm "Clear $(theme::plural "${#favs[@]}" favourite)?" || {
                    printf '  %sCancelled.%s\n' "${ASH_MUTED}" "${RST}"; return 0; }
            fi
            local empty=()
            theme::favorite::write empty
            printf '\n  %s✅ Cleared %s.%s\n\n' \
                "${ASH_SUCCESS}" "$(theme::plural "${#favs[@]}" favourite)" "${RST}"
            ;;

        cycle)
            # Walk the favourites in order, so repeated invocations rotate
            # through the shortlist rather than picking at random.
            if (( ${#favs[@]} == 0 )); then
                ash_log_error "No favourites to cycle through."
                return 1
            fi
            local current idx=-1 i=0
            current="$(theme::current 2>/dev/null || true)"
            for i in "${!favs[@]}"; do
                [[ "${favs[$i]}" == "$current" ]] && { idx="$i"; break; }
            done
            local next=$(( (idx + 1) % ${#favs[@]} ))
            theme::source_sub apply || return 1
            theme::apply "${favs[$next]}" || return $?
            ;;

        add|remove|toggle)
            if (( ${#targets[@]} == 0 )); then
                ash_log_error "$action wants at least one theme."
                return 2
            fi

            local -a next=("${favs[@]}")
            local -a added=() removed=()
            local t

            for t in "${targets[@]}"; do
                local slug
                if slug="$(theme::resolve "$t" 2>/dev/null)"; then
                    slug="$(jq -r '.slug // empty' "$slug" 2>/dev/null)"
                fi
                [[ -n "$slug" ]] || slug="$(ash_generate_slug "$t" 2>/dev/null || printf '%s' "$t")"

                if ! theme::resolve "$t" >/dev/null 2>&1; then
                    ash_log_error "No such theme: $t"
                    continue
                fi

                local present=0 j
                for j in "${!next[@]}"; do [[ "${next[$j]}" == "$slug" ]] && { present=1; break; }; done

                case "$action" in
                    add)
                        if (( present )); then
                            printf '  %s·%s %s is already a favourite\n' "${ASH_MUTED}" "${RST}" "$slug"
                        else
                            next+=("$slug"); added+=("$slug")
                        fi
                        ;;
                    remove)
                        if (( present )); then
                            local -a trimmed=() k
                            for k in "${next[@]}"; do [[ "$k" == "$slug" ]] || trimmed+=("$k"); done
                            next=("${trimmed[@]:-}"); removed+=("$slug")
                        else
                            printf '  %s·%s %s is not a favourite\n' "${ASH_MUTED}" "${RST}" "$slug"
                        fi
                        ;;
                    toggle)
                        if (( present )); then
                            local -a trimmed=() k
                            for k in "${next[@]}"; do [[ "$k" == "$slug" ]] || trimmed+=("$k"); done
                            next=("${trimmed[@]:-}"); removed+=("$slug")
                        else
                            next+=("$slug"); added+=("$slug")
                        fi
                        ;;
                esac
            done

            # Nothing changed: do not rewrite the file, which would only churn
            # the "updated" timestamp.
            if (( ${#added[@]} == 0 && ${#removed[@]} == 0 )); then
                [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && \
                    jq -n --argjson n "${#favs[@]}" '{changed: 0, count: $n}'
                return 0
            fi

            theme::favorite::write next || { ash_log_error "Could not write $THEME_FAVORITES_FILE"; return 1; }

            if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
                jq -n --argjson added "$(printf '%s\n' "${added[@]:-}" | jq -Rn '[inputs | select(length>0)]')" \
                      --argjson removed "$(printf '%s\n' "${removed[@]:-}" | jq -Rn '[inputs | select(length>0)]')" \
                      --argjson count "${#next[@]}" \
                      '{added: $added, removed: $removed, count: $count}'
                return 0
            fi

            local s
            for s in "${added[@]:-}";   do [[ -n "$s" ]] && printf '  %s⭐ Added%s %s\n' "${ASH_ACCENT}" "${RST}" "$s"; done
            for s in "${removed[@]:-}"; do [[ -n "$s" ]] && printf '  %s·  Removed%s %s\n' "${ASH_MUTED}" "${RST}" "$s"; done
            printf '\n  %s%s now starred.%s\n\n' "${ASH_MUTED}" "$(theme::plural "${#next[@]}" theme)" "${RST}"
            ;;
    esac
}
