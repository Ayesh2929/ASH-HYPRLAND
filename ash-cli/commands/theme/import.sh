#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — import.sh                                                        ║
# ║  Bring a theme in from a file, a URL, or a seed colour                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::import::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme import${RST} <file|url|#RRGGBB> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Accepts four kinds of input and works out which it has been given:

    ${ASH_MUTED}an ASH theme${RST}    {name, slug, colors:{…}} — copied as-is
    ${ASH_MUTED}a base16 scheme${RST}  decoded into the 13 slots
    ${ASH_MUTED}a bare palette${RST}   {base: "#…", accent: "#…"} — completed
    ${ASH_MUTED}a colour${RST}         anything else is treated as a seed to derive from

  A theme with a partial palette is filled in with the generator rather than
  imported broken, and the import is validated before it is written.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name NAME${RST}        Override the display name
  ${ASH_MUTED}--slug SLUG${RST}        Override the slug
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing theme
  ${ASH_MUTED}--stdin${RST}            Read from standard input
  ${ASH_MUTED}--dry-run, -n${RST}      Validate and describe, write nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme import ~/Downloads/gruvbox.json${RST}
  ${ASH_MUTED}ash theme import https://example.com/theme.json${RST}
  ${ASH_MUTED}ash theme import '#7aa2f7' --name Tokyo Night${RST}
  ${ASH_MUTED}cat scheme.json | ash theme import --stdin${RST}
EOF
}

# Work out which of the four shapes we were handed and put a flat slot map in
# the named array. Sets _THEME_IMPORT_KIND as a side effect.
_THEME_IMPORT_KIND=""

_theme_import_decode() {
    local src="$1"
    local -n out="$2"
    out=()
    _THEME_IMPORT_KIND="unknown"

    # ── A bare colour ─────────────────────────────────────────────────────────
    # Checked before any jq call, because a file containing `#7aa2f7` is not
    # JSON and every jq probe below fails on it — which silently turned the
    # documented `ash theme import '#7aa2f7'` into "no usable colours found".
    local rawtxt
    rawtxt="$(tr -d '[:space:]' < "$src" 2>/dev/null || true)"
    rawtxt="${rawtxt%\"}"; rawtxt="${rawtxt#\"}"
    rawtxt="${rawtxt%\'}"; rawtxt="${rawtxt#\'}"
    if [[ "$rawtxt" =~ ^#?[0-9a-fA-F]{6}$ || "$rawtxt" =~ ^#?[0-9a-fA-F]{3}$ ]]; then
        out[_c0]="#${rawtxt#\#}"
        _THEME_IMPORT_KIND="colour-list"
        return 0
    fi

    # ── ASH theme, or an object with a colours sub-object ─────────────────────
    if jq -e 'type == "object" and (has("colors") or has("colours"))' "$src" >/dev/null 2>&1; then
        _THEME_IMPORT_KIND="ash-theme"
        local k v
        while IFS=$'\t' read -r k v; do
            [[ -n "$k" ]] && out["$k"]="$v"
        done < <(jq -r '(.colors // .colours)
                        | to_entries
                        | map(select(.value | type == "string" and test("^#[0-9a-fA-F]{3,8}$")))
                        | .[] | "\(.key)\t\(.value)"' "$src" 2>/dev/null)

    # ── base16 / base24: base00…base0F ────────────────────────────────────────
    elif jq -e 'type == "object" and (has("base00") or (has("palette") and (.palette | has("base00"))))' \
            "$src" >/dev/null 2>&1; then
        _THEME_IMPORT_KIND="base16"
        local k v
        while IFS=$'\t' read -r k v; do
            [[ -n "$k" ]] && out["$k"]="$v"
        done < <(jq -r '(.palette // .)
                        | to_entries
                        | map(select(.key | test("^base[0-9A-Fa-f]{2}$")))
                        | map({k: (.key | ascii_downcase), v: (if (.value | startswith("#")) then .value else "#" + .value end)})
                        | .[] | "\(.k)\t\(.v)"' "$src" 2>/dev/null)

    # ── A bare palette: slot names at the top level ───────────────────────────
    elif jq -e 'type == "object"' "$src" >/dev/null 2>&1; then
        _THEME_IMPORT_KIND="palette"
        local k v
        while IFS=$'\t' read -r k v; do
            [[ -n "$k" ]] && out["$k"]="$v"
        done < <(jq -r 'to_entries
                        | map(select(.value | type == "string" and test("^#[0-9a-fA-F]{3,8}$")))
                        | .[] | "\(.key)\t\(.value)"' "$src" 2>/dev/null)

    # ── A list of hex codes ───────────────────────────────────────────────────
    elif jq -e 'type == "array"' "$src" >/dev/null 2>&1; then
        _THEME_IMPORT_KIND="colour-list"
        local i=0 v
        while IFS= read -r v; do
            [[ -n "$v" ]] || continue
            out["_c${i}"]="$v"
            (( i++ )) || true
        done < <(jq -r '.[] | select(type == "string")' "$src" 2>/dev/null)
    fi

    # ── A bare colour presented as JSON? Unwind it back to plain text ─────────
    if [[ "$_THEME_IMPORT_KIND" == "unknown" ]]; then
        local scalar
        scalar="$(jq -r 'if type == "string" then . else empty end' "$src" 2>/dev/null)"
        if [[ -n "$scalar" ]]; then
            out[_c0]="$scalar"
            _THEME_IMPORT_KIND="colour-list"
        fi
    fi

    ((${#out[@]})) || _THEME_IMPORT_KIND="unknown"
}

# base16 slots in base00…base0F order.
_THEME_BASE16_ORDER=(
    base        mantle      crust       surface
    overlay     text        subtext     accent
    rose        mint        gold        sky
    violet      rose
)

theme::import() {
    local input="" name="" slug="" variant="" force=0 stdin=0 dry=0
    while (( $# )); do
        case "$1" in
            --name)    name="${2:-}"; shift 2 ;;
            --slug)    slug="${2:-}"; shift 2 ;;
            --variant) variant="${2:-}"; shift 2 ;;
            --force|-f) force=1; shift ;;
            --stdin)   stdin=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)    export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help) theme::import::help; return 0 ;;
            -*)        ash_log_error "Unknown option: $1"; theme::import::help; return 2 ;;
            *)         input="$1"; shift ;;
        esac
    done

    local tmp="" cleanup=0
    if (( stdin )); then
        tmp="$(mktemp -t ash-theme-import.XXXXXX)"
        cleanup=1
        cat > "$tmp"
        input="stdin"
        [[ -s "$tmp" ]] || { ash_log_error "Nothing on standard input"; rm -f "$tmp"; return 2; }

    elif [[ "$input" =~ ^https?:// ]]; then
        if ! declare -f ash_http_download >/dev/null 2>&1; then
            ash_log_error "HTTP support is not loaded; download the file yourself and pass the path"
            return 1
        fi
        tmp="$(mktemp -t ash-theme-import.XXXXXX)"
        cleanup=1
        printf '  %sDownloading %s…%s\n' "${ASH_MUTED}" "$input" "${RST}" >&2
        if ! ash_http_download "$input" "$tmp" 2>/dev/null; then
            ash_log_error "Download failed: $input"
            rm -f "$tmp"
            return 1
        fi

    elif [[ -n "$input" && -f "$input" ]]; then
        tmp="$input"

    elif [[ -n "$input" ]]; then
        # Not a file and not a URL: treat it as a colour or a description.
        tmp="$(mktemp -t ash-theme-import.XXXXXX)"
        cleanup=1
        printf '%s' "$input" > "$tmp"

    else
        ash_log_error "Nothing to import."
        printf '  %sPass a file, a URL, a #RRGGBB colour, or --stdin.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        theme::import::help
        return 2
    fi

    local -A raw=()
    _theme_import_decode "$tmp" raw
    local kind="$_THEME_IMPORT_KIND"

    # A JSON file that decoded to nothing usable is a real error, not a colour.
    if [[ "$kind" == "unknown" && "$tmp" != "$input" || "$kind" == "unknown" && -f "$input" ]]; then
        if jq -e 'type == "object" or type == "array"' "$tmp" >/dev/null 2>&1; then
            ash_log_error "That JSON has no recognisable colours in it."
            printf '  %sLooked for: a "colors" object, base16 base00…base0F, or #rrggbb values.%s\n\n' \
                "${ASH_MUTED}" "${RST}" >&2
            (( cleanup )) && rm -f "$tmp"
            return 2
        fi
    fi

    # ── Turn whatever we got into a full palette ──────────────────────────────
    local -A pal=()

    if [[ -z "$variant" ]]; then
        variant="$(jq -r '.variant // empty' "$tmp" 2>/dev/null)"
        [[ -n "$variant" ]] || variant="dark"
    fi
    [[ "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"
        (( cleanup )) && rm -f "$tmp"
        return 2
    }

    case "$kind" in
        ash-theme|palette)
            local k
            for k in "${!raw[@]}"; do pal["$k"]="${raw[$k]}"; done
            ;;
        base16)
            local i=0
            for k in "${_THEME_BASE16_ORDER[@]}"; do
                local key
                key="$(printf 'base%02x' "$i")"
                [[ -n "${raw[$key]:-}" ]] && pal["$k"]="${raw[$key]}"
                (( i++ )) || true
            done
            ;;
        colour-list)
            # Take the most saturated entry as the seed — the first entry of a
            # palette dump is usually the background, which has no hue to build on.
            local seed="" best_c=-1 cand c
            if declare -f ash_ok_c >/dev/null 2>&1; then
                for cand in "${raw[@]}"; do
                    [[ "$cand" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
                    c="$(ash_ok_c "$cand" 2>/dev/null || printf '0')"
                    if awk -v a="$c" -v b="$best_c" 'BEGIN { exit !(a > b) }' 2>/dev/null; then
                        best_c="$c"; seed="$cand"
                    fi
                done
            fi
            [[ -n "$seed" ]] || seed="${raw[_c0]:-}"
            if [[ -n "$seed" ]] && declare -f ash_palette_derive >/dev/null 2>&1; then
                ash_palette_derive pal "$seed" "$variant" || {
                    ash_log_error "Could not derive a palette from '$seed'"
                    (( cleanup )) && rm -f "$tmp"
                    return 1
                }
            fi
            ;;
    esac

    # Partial palettes get completed rather than imported broken.
    local -a missing=()
    if declare -f ash_palette_missing >/dev/null 2>&1; then
        mapfile -t missing < <(ash_palette_missing pal 2>/dev/null) || true
    fi

    local completed=0
    if (( ${#missing[@]} )); then
        if declare -f ash_palette_complete >/dev/null 2>&1; then
            # Seed completion from whatever colour we do have, so the derived
            # slots belong to the same hue family.
            local anchor=""
            for k in accent base text; do
                [[ -n "${pal[$k]:-}" ]] && { anchor="${pal[$k]}"; break; }
            done
            if [[ -n "$anchor" ]]; then
                local -A derived=()
                ash_palette_derive derived "$anchor" "$variant" 2>/dev/null || true
                local s
                for s in "${missing[@]}"; do
                    [[ -n "${derived[$s]:-}" ]] && pal["$s"]="${derived[$s]}"
                done
            fi
            ash_palette_complete pal 2>/dev/null || true
            completed=${#missing[@]}
        fi
    fi

    local -a still_missing=()
    if declare -f ash_palette_missing >/dev/null 2>&1; then
        mapfile -t still_missing < <(ash_palette_missing pal 2>/dev/null) || true
    fi

    if (( ${#still_missing[@]} == ${#THEME_SLOT_ORDER[@]} )); then
        ash_log_error "No usable colours were found in that input."
        (( cleanup )) && rm -f "$tmp"
        return 2
    fi

    # base16/base24 schemes call it `.scheme`; ASH themes call it `.name`.
    [[ -n "$name" ]] || name="$(jq -r '.name // .scheme // .meta.name // empty' "$tmp" 2>/dev/null)"
    [[ -n "$name" ]] || name="Imported $(date +%Y-%m-%d 2>/dev/null || printf 'theme')"
    [[ -n "$slug" ]] || slug="$(jq -r '.slug // empty' "$tmp" 2>/dev/null)"
    [[ -n "$slug" ]] || slug="$name"
    slug="$(ash_generate_slug "$slug" 2>/dev/null || printf '%s' "$slug")"
    [[ -n "$slug" ]] || slug="imported-$RANDOM"

    local dest_file="${THEME_USER_DIR}/${slug}.json"

    local existed=0
    [[ -f "$dest_file" ]] && existed=1
    if (( existed && ! force && ! dry )); then
        ash_log_error "User theme '$slug' already exists."
        printf '  %sPass --force to overwrite, or --slug to import it under another name.%s\n\n' \
            "${ASH_MUTED}" "${RST}" >&2
        (( cleanup )) && rm -f "$tmp"
        return 1
    fi

    # Validate before writing — an imported theme should never land in the
    # catalogue in a state that `theme validate` would reject.
    local reason="" valid=0
    if declare -f ash_palette_is_valid >/dev/null 2>&1; then
        if ash_palette_is_valid pal reason 2>/dev/null; then valid=1; fi
    else
        valid=1
    fi

    local wcag_fails=0
    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local r
        r="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && wcag_fails="$r"
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg kind "$kind" --arg slug "$slug" --arg name "$name" \
              --arg variant "$variant" --arg file "$dest_file" \
              --argjson existed "$existed" --argjson dry "$dry" \
              --argjson filled "$completed" --argjson wcag "$wcag_fails" \
              --argjson valid "$valid" --arg reason "$reason" \
              --argjson colors "$colors_json" \
              '{kind: $kind, slug: $slug, name: $name, variant: $variant,
                file: $file, overwrote: ($existed == 1), dry_run: ($dry == 1),
                slots_filled: $filled, wcag_failures: $wcag,
                valid: ($valid == 1), invalid_reason: $reason, colors: $colors}'
        (( cleanup )) && rm -f "$tmp"
        (( dry )) && return 0
        # Fall through to write when not a dry run.
        if (( dry )); then return 0; fi
    fi

    if (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    detected   %s\n    slug       %s\n    name       %s\n    variant    %s\n' \
            "$kind" "$slug" "$name" "$variant"
        (( completed )) && printf '    filled     %s\n' "$(theme::plural "$completed" slot)"
        printf '\n'
        (( cleanup )) && rm -f "$tmp"
        return 0
    fi

    mkdir -p "$THEME_USER_DIR"
    theme::save "$dest_file" pal "slug=$slug" "name=$name" "variant=$variant" \
        "family=imported" "seed=${pal[accent]:-${pal[base]:-}}" || {
        ash_log_error "Could not write $dest_file"
        (( cleanup )) && rm -f "$tmp"
        return 1
    }
    (( cleanup )) && rm -f "$tmp"

    theme::record "$slug" import

    [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && return 0

    printf '\n  %s✅ Imported%s %s%s%s %s(%s)%s\n' \
        "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
        "${ASH_MUTED}" "$kind" "${RST}"
    printf '  %s   %s%s\n' "${ASH_MUTED}" "$dest_file" "${RST}"
    (( completed )) && printf '  %s   filled in %s the input did not supply%s\n' \
        "${ASH_MUTED}" "$(theme::plural "$completed" slot)" "${RST}"
    if (( ! valid )); then
        printf '  %s⚠  The palette is incomplete: %s%s\n' "${ASH_WARNING:-$ASH_MUTED}" "${reason:-unknown reason}" "${RST}"
    elif (( wcag_fails )); then
        printf '  %s⚠  %s fall below the 4.5:1 contrast minimum — ash theme wcag %s --fix%s\n' \
            "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "$wcag_fails" "pair")" "$slug" "${RST}"
    fi
    printf '\n  %sTry it:  ash theme preview %s --mock%s\n\n' "${ASH_MUTED}" "$slug" "${RST}"
}
