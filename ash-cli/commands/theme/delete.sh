#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — delete.sh                                                        ║
# ║  Remove a user theme, reversibly                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::delete::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme delete${RST} <theme> [options]
  ${ASH_ACCENT}ash theme delete${RST} --list
  ${ASH_ACCENT}ash theme delete${RST} --empty-trash

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Only themes you own are removable. The catalogue is generated from the repo, so
  "deleting" a built-in would come back at the next regeneration — this command
  refuses instead of pretending. Deleted themes are moved to a trash directory
  rather than unlinked, so a mistaken delete costs one command to undo.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--list${RST}          Show the trash
  ${ASH_MUTED}--empty-trash${RST}   Permanently remove everything in the trash
  ${ASH_MUTED}--force, -f${RST}     Skip the confirmation prompt
  ${ASH_MUTED}--yes${RST}           Alias for --force
  ${ASH_MUTED}--json${RST}          Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme delete nord-mine${RST}
  ${ASH_MUTED}ash theme delete nord-mine --force${RST}
EOF
}

# Trash entries are stored as <slug>.<epoch>.json so two deletes of the same
# slug never collide and the newest is easy to find.
theme::delete::list() {
    local f found=0

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        local rows='[]' name slug at
        if [[ -d "$THEME_TRASH_DIR" ]]; then
            for f in "$THEME_TRASH_DIR"/*.json; do
                [[ -f "$f" ]] || continue
                slug="$(basename "$f" .json)"
                slug="${slug%.*}"
                name="$(jq -r '.name // empty' "$f" 2>/dev/null)"
                rows="$(jq -c --arg s "$slug" --arg n "$name" --arg p "$f" \
                        '. + [{slug: $s, name: $n, file: $p}]' <<<"$rows")"
            done
        fi
        jq -n --argjson t "$rows" '{trash: $t, count: ($t | length)}'
        return 0
    fi

    ash_banner "🗑  THEME TRASH" "deleted themes are kept here" 80

    if [[ -d "$THEME_TRASH_DIR" ]]; then
        for f in "$THEME_TRASH_DIR"/*.json; do
            [[ -f "$f" ]] || continue
            local slug name
            slug="$(basename "$f" .json)"; slug="${slug%.*}"
            name="$(jq -r '.name // empty' "$f" 2>/dev/null)"
            printf '    %s%-24s%s %s%s%s\n' "$BOLD" "$slug" "$RST" "${ASH_MUTED}" "$name" "${RST}"
            (( found++ )) || true
        done
    fi

    if (( found )); then
        printf '\n  %s%s%s\n\n' "${ASH_MUTED}" "$(theme::plural "$found" theme) in the trash" "${RST}"
    else
        printf '\n  %sTrash is empty — nothing has been deleted.%s\n\n' "${ASH_MUTED}" "${RST}"
    fi
}

theme::delete() {
    local want="" force=0 list=0 empty=0
    while (( $# )); do
        case "$1" in
            --list|-l)     list=1; shift ;;
            --empty-trash) empty=1; shift ;;
            --force|-f|--yes|-y) force=1; shift ;;
            --json)        export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)     theme::delete::help; return 0 ;;
            -*)            ash_log_error "Unknown option: $1"; theme::delete::help; return 2 ;;
            *)             want="$1"; shift ;;
        esac
    done

    (( list )) && { theme::delete::list; return 0; }

    if (( empty )); then
        if [[ ! -d "$THEME_TRASH_DIR" ]]; then
            printf '\n  %sTrash is already empty.%s\n\n' "${ASH_MUTED}" "${RST}"
            return 0
        fi
        local n=0 f
        for f in "$THEME_TRASH_DIR"/*.json; do [[ -f "$f" ]] && (( n++ )) || true; done
        if (( n == 0 )); then
            printf '\n  %sTrash is already empty.%s\n\n' "${ASH_MUTED}" "${RST}"
            return 0
        fi
        if (( ! force )); then
            if declare -f ash_confirm >/dev/null 2>&1; then
                ash_confirm "Permanently delete $(theme::plural "$n" theme)?" || {
                    printf '  %sCancelled.%s\n' "${ASH_MUTED}" "${RST}"; return 0; }
            fi
        fi
        rm -f "$THEME_TRASH_DIR"/*.json
        printf '\n  %s✅ Removed %s from the trash.%s\n\n' \
            "${ASH_SUCCESS}" "$(theme::plural "$n" theme)" "${RST}"
        return 0
    fi

    [[ -n "$want" ]] || { ash_log_error "Which theme should I delete?"; theme::delete::help; return 2; }

    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    # Refuse to delete the catalogue. Checked by realpath, not by string prefix:
    # the user directory may legitimately live inside the checkout.
    local real_user real_file real_cat
    real_user="$(cd "$THEME_USER_DIR" 2>/dev/null && pwd || printf '%s' "$THEME_USER_DIR")"
    real_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
    real_cat="$(cd "$THEME_CATALOGUE_DIR" 2>/dev/null && pwd || printf '%s' "$THEME_CATALOGUE_DIR")"

    case "$real_file" in
        "${real_user}"/*) : ;;
        "${real_cat}"/*)
            ash_log_error "'$want' is a catalogue theme — it cannot be deleted."
            printf '\n  %sThe catalogue is regenerated from the repo, so the file would\n' "${ASH_MUTED}" >&2
            printf '  come back. To get a theme you can change, clone it first:%s\n\n' "${RST}" >&2
            printf '    ash theme clone %s my-%s\n\n' "$want" "$want" >&2
            return 2
            ;;
        *)
            ash_log_error "'$want' is outside the theme directories; refusing to delete it."
            printf '  %s%s%s\n\n' "${ASH_MUTED}" "$real_file" "${RST}" >&2
            return 2
            ;;
    esac

    local slug
    slug="$(jq -r '.slug // empty' "$file" 2>/dev/null)"
    [[ -n "$slug" ]] || slug="$(basename "$file" .json)"

    local current=""
    current="$(theme::current 2>/dev/null || true)"
    if [[ "$current" == "$slug" ]]; then
        ash_log_error "'$slug' is the theme currently applied."
        printf '  %sApply a different theme first, or pass --force.%s\n' "${ASH_MUTED}" "${RST}" >&2
        (( force )) || return 2
    fi

    if (( ! force )) && declare -f ash_confirm >/dev/null 2>&1; then
        ash_confirm "Delete '$slug'?" || { printf '  %sCancelled.%s\n' "${ASH_MUTED}" "${RST}"; return 0; }
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        jq -n --arg slug "$slug" --arg file "$file" \
              '{deleted: $slug, file: $file, reversible: true}'
        # Deliberately still move it: --json asks for a different encoding of
        # the result, not for a dry run.
    fi

    mkdir -p "$THEME_TRASH_DIR"
    local stamp trash_file
    stamp="$(date +%s 2>/dev/null || printf '0')"
    trash_file="${THEME_TRASH_DIR}/${slug}.${stamp}.json"

    if mv "$file" "$trash_file" 2>/dev/null; then
        theme::record "$slug" delete
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then return 0; fi
        printf '\n  %s✅ Deleted%s %s%s%s\n' \
            "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}"
        printf '  %s   Recover with: mv %s %s%s\n\n' \
            "${ASH_MUTED}" "$trash_file" "$file" "${RST}"
    else
        ash_log_error "Could not move '$slug' to the trash"
        return 1
    fi
}
