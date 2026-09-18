#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — apply.sh                                                        ║
# ║  Render the config fragments for a theme into the XDG config tree            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

theme::apply::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme apply${RST} <name> [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--out, -o DIR${RST}     Config home to write into (default: \$XDG_CONFIG_HOME)
  ${ASH_MUTED}--only APP${RST}       Render just one target, repeatable
  ${ASH_MUTED}--dry-run, -n${RST}    Show what would be written, write nothing
  ${ASH_MUTED}--no-backup${RST}      Do not keep a .bak of files being replaced
  ${ASH_MUTED}--list-targets${RST}   Show the template → destination mapping

${BOLD}${ASH_PRIMARY}NOTES${RST}
  Each template is a FRAGMENT — colour definitions your application includes —
  so applying never overwrites an application's real configuration. Destinations
  are listed in ${ASH_MUTED}engines/color-engine/templates/targets.tsv${RST}.
EOF
}

# Read the target manifest. Skips blank and comment lines.
theme::apply::targets() {
    local manifest="${THEME_TEMPLATE_DIR}/targets.tsv"
    [[ -r "$manifest" ]] || return 1
    grep -vE '^\s*(#|$)' "$manifest"
}

theme::apply() {
    local want="" out_dir="" dry_run=0 backup=1 list_targets=0
    local -a only=()

    while (( $# )); do
        case "$1" in
            --out|-o)        out_dir="${2:-}"; shift 2 ;;
            --only)          only+=("${2:-}"); shift 2 ;;
            --dry-run|-n)    dry_run=1; shift ;;
            --no-backup)     backup=0; shift ;;
            --list-targets)  list_targets=1; shift ;;
            --help|-h)       theme::apply::help; return 0 ;;
            *)               want="${want:-$1}"; shift ;;
        esac
    done

    if (( list_targets )); then
        printf '\n  %s%-22s %s%s\n\n' "${BOLD}${ASH_PRIMARY}" "TEMPLATE" "DESTINATION" "${RST}"
        local name dest desc
        while IFS=$'\t' read -r name dest desc; do
            printf '  %s%-22s%s %s%s%s  %s%s%s\n' \
                "$ASH_ACCENT" "$name" "$RST" "${ASH_MUTED}" "$dest" "$RST" \
                "${ASH_MUTED}" "${desc:-}" "${RST}"
        done < <(theme::apply::targets)
        printf '\n'
        return 0
    fi

    [[ -n "$want" ]] || { theme::apply::help >&2; return 2; }

    local file
    file="$(theme::resolve "$want")" || {
        ash_log_error "No such theme: ${want}"
        return 1
    }

    if ! declare -f ash_tpl_render_file >/dev/null 2>&1; then
        ash_log_error "Template engine unavailable (lib/template-engine.sh)"
        return 1
    fi

    # Default destination is the XDG config home, so the fragments land beside
    # the configs that include them.
    [[ -n "$out_dir" ]] || out_dir="${ASH_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"

    local -A pal=()
    theme::load "$file" pal

    local slug name variant
    slug="$(jq -r '.slug // "theme"' "$file" 2>/dev/null)"
    name="$(jq -r '.name // .slug // "theme"' "$file" 2>/dev/null)"
    variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"

    # Metadata slots the templates interpolate on top of the colour slots.
    pal[theme_name]="$name"
    pal[theme_slug]="$slug"
    pal[variant]="$variant"
    if [[ "$variant" == "light" ]]; then pal[variant_is_dark]="false"; else pal[variant_is_dark]="true"; fi
    pal[wallpaper]="${ASH_WALLPAPER_CURRENT:-}"

    # Publish the palette to the template engine.
    #
    # The engine reads its variables from the global ASH_TPL_VARS array;
    # ash_tpl_render_file's second argument is the partial-recursion depth, not a
    # context. Nothing had populated the array, so every placeholder resolved to
    # the empty string and the fragments were written as `rgb()` and
    # `@define-color base    ;`.
    ash_tpl_reset
    local key
    for key in "${!pal[@]}"; do
        [[ -n "${pal[$key]}" ]] && ash_tpl_set "$key" "${pal[$key]}"
    done

    local targets
    targets="$(theme::apply::targets)" || {
        ash_log_error "Missing target manifest: ${THEME_TEMPLATE_DIR}/targets.tsv"
        return 1
    }

    ash_banner "🎨 APPLY ${name}" "${slug} · ${variant} → ${out_dir}" "80"
    printf '\n'

    local tpl dest desc rendered=0 skipped=0 failed=0
    local -a rendered_names=()

    while IFS=$'\t' read -r tpl dest desc; do
        [[ -n "$tpl" ]] || continue

        # --only filters by template name.
        if (( ${#only[@]} )); then
            local m=0 o
            for o in "${only[@]}"; do [[ "$o" == "$tpl" ]] && m=1; done
            (( m )) || continue
        fi

        local source="${THEME_TEMPLATE_DIR}/${tpl}.template"
        local target="${out_dir}/${dest}"

        if [[ ! -r "$source" ]]; then
            printf '  %s✗%s %-20s %s\n' "$ASH_ERROR" "$RST" "$tpl" "no template"
            (( failed++ )) || true
            continue
        fi

        if (( dry_run )); then
            printf '  %s·%s %-20s %s%s%s\n' "$ASH_MUTED" "$RST" "$tpl" \
                "${ASH_MUTED}" "$target" "${RST}"
            (( skipped++ )) || true
            continue
        fi

        local content
        if ! content="$(ash_tpl_render_file "$source")"; then
            printf '  %s✗%s %-20s %s\n' "$ASH_ERROR" "$RST" "$tpl" "render failed"
            (( failed++ )) || true
            continue
        fi

        mkdir -p "$(dirname "$target")" 2>/dev/null || {
            printf '  %s✗%s %-20s %s\n' "$ASH_ERROR" "$RST" "$tpl" "cannot create $(dirname "$target")"
            (( failed++ )) || true
            continue
        }

        # Keep one generation of the previous fragment. These files are
        # generated, so a .bak is cheap insurance against a bad render.
        if (( backup )) && [[ -f "$target" ]]; then
            cp -f "$target" "${target}.bak" 2>/dev/null || true
        fi

        printf '%s\n' "$content" > "$target" 2>/dev/null || {
            printf '  %s✗%s %-20s %s\n' "$ASH_ERROR" "$RST" "$tpl" "cannot write"
            (( failed++ )) || true
            continue
        }

        printf '  %s✓%s %-20s %s%s%s\n' "$ASH_SUCCESS" "$RST" "$tpl" \
            "${ASH_MUTED}" "$target" "${RST}"
        rendered_names+=("$tpl")
        (( rendered++ )) || true
    done <<<"$targets"

    printf '\n'
    if (( dry_run )); then
        printf '  %s%s%s %s\n\n' "$ASH_INFO" "${ICO_INFO}" "${RST}" \
            "Dry run — $(theme::plural "$skipped" fragment) would be written"
        return 0
    fi

    if (( rendered > 0 )); then
        printf '  %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" \
            "$(theme::plural "$rendered" fragment) written"
        (( failed )) && printf '  %s%s%s %s\n' "$ASH_ERROR" "${ICO_ERROR}" "${RST}" \
            "$(theme::plural "$failed" fragment) failed"

        # Only record the change if something was actually written.
        theme::set_current "$file" "$slug"
        theme::record "$slug" "apply"

        # Reload anything that watches its config, and tell the running session.
        if declare -f ash_ipc_broadcast >/dev/null 2>&1; then
            ash_ipc_broadcast "theme_changed" "{\"slug\":\"${slug}\"}" 2>/dev/null || true
        fi
        if declare -f ash_hook_run >/dev/null 2>&1; then
            ash_hook_run "post-theme-change" "THEME=${slug}" 2>/dev/null || true
        fi
    else
        printf '  %s%s%s %s\n' "$ASH_WARNING" "${ICO_WARN}" "${RST}" "Nothing was written"
    fi
    printf '\n'

    (( failed == 0 ))
}
