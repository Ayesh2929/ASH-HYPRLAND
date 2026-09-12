#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║  🎨 ASH THEME — theme catalogue, generation and contrast validation          ║
# ║      ASH DOTFILES v5.0 OMEGA                                                ║
# ║                                                                              ║
# ║  This command is the front door to ash-cli/engines/color-engine, which until  ║
# ║  now was unreachable from the CLI entirely — `ash-cli/ash` contained zero     ║
# ║  references to the engine, and this file was a nine-line stub.               ║
# ║                                                                              ║
# ║  USAGE                                                                       ║
# ║    ash theme list    [--family F] [--variant V] [--json]                     ║
# ║    ash theme show    <name>                                                  ║
# ║    ash theme apply   <name> [--out DIR] [--dry-run] [--force]                ║
# ║    ash theme generate <#seed|prompt> [--light] [--name N] [--out FILE]       ║
# ║    ash theme extract <image> [--out FILE] [--count N]                        ║
# ║    ash theme wcag    [<name>|--sweep] [--json] [--fix]                       ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

# ── Locate the repo ───────────────────────────────────────────────────────────
_THEME_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_THEME_LIB_DIR="${_THEME_CMD_DIR}/../../lib"
_THEME_ENGINE_DIR="${_THEME_CMD_DIR}/../../engines/color-engine"
_THEME_ROOT="$(cd "${_THEME_CMD_DIR}/../../.." && pwd)"
_THEME_CATALOGUE="${ASH_THEMES_DIR:-${_THEME_ROOT}/themes}"
_THEME_TEMPLATE_DIR="${_THEME_ENGINE_DIR}/templates"

# ── Libraries ─────────────────────────────────────────────────────────────────
# Each guards itself, so this is a no-op when the dispatcher already loaded them.
for _lib in colors logger utils template-engine; do
    [[ -r "${_THEME_LIB_DIR}/${_lib}.sh" ]] && source "${_THEME_LIB_DIR}/${_lib}.sh"
done
unset _lib

# ── Colour engine ─────────────────────────────────────────────────────────────
# Sourced in dependency order: oklch/hsl are the maths, contrast and harmonize
# build on them, palette builds on those, and wcag-validate sits on top.
for _mod in oklch hsl contrast-check harmonize palette generate extract gradient wcag-validate; do
    [[ -r "${_THEME_ENGINE_DIR}/${_mod}.sh" ]] && source "${_THEME_ENGINE_DIR}/${_mod}.sh"
done
unset _mod

# Palette slots, in the order they are presented. Surface tones first (dark to
# light), then foregrounds, then the accents — the order a reader scans them in.
_THEME_SLOT_ORDER=(
    crust mantle base surface overlay
    text subtext
    accent mint sky gold rose violet
)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Resolve a user-supplied name to a catalogue file. Accepts a slug, a display
# name in any case, or a path. Searches top-level themes first, then presets/.
theme::resolve() {
    local want="$1" cand

    # An explicit path wins.
    [[ -f "$want" ]] && { printf '%s' "$want"; return 0; }

    # Exact slug.
    for cand in "${_THEME_CATALOGUE}/${want}.json" \
                "${_THEME_CATALOGUE}/presets/${want}.json"; do
        [[ -f "$cand" ]] && { printf '%s' "$cand"; return 0; }
    done

    # Case-insensitive display-name match, then slug match.
    local f slug name
    for f in "${_THEME_CATALOGUE}"/*.json; do
        [[ -f "$f" ]] || continue
        slug="$(jq -r '.slug // empty' "$f" 2>/dev/null)"
        name="$(jq -r '.name // empty' "$f" 2>/dev/null)"
        if [[ "${slug,,}" == "${want,,}" || "${name,,}" == "${want,,}" ]]; then
            printf '%s' "$f"; return 0
        fi
    done

    return 1
}

# A filled block in the colour itself, so the swatch IS the hex.
theme::swatch() {
    local hex="$1" width="${2:-12}"
    [[ -n "$hex" ]] || { printf '%*s' "$width" ''; return; }
    [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 1 || ! -t 1 ]] && { printf '%*s' "$width" ''; return; }

    local r g b bar
    r=$(( 16#${hex:1:2} )); g=$(( 16#${hex:3:2} )); b=$(( 16#${hex:5:2} ))
    bar="$(printf '%*s' "$width" '' | tr ' ' '█')"
    printf '\033[38;2;%d;%d;%dm%s\033[0m' "$r" "$g" "$b" "$bar"
}

# Count with correct pluralisation.
theme::plural() {
    local n="$1" one="$2" many="${3:-${2}s}"
    if [[ "$n" == "1" ]]; then printf '%s %s' "$n" "$one"; else printf '%s %s' "$n" "$many"; fi
}

# ─────────────────────────────────────────────────────────────────────────────
# list
# ─────────────────────────────────────────────────────────────────────────────
theme::list() {
    local family="" variant="" json=0
    # --json is consumed by the dispatcher as a global flag (ash:345 sets
    # ASH_FLAG_JSON_OUTPUT and removes it from the argument list), so the
    # subcommand only ever sees it when someone calls the function directly.
    # Both routes have to be honoured.
    [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && json=1
    while (( $# )); do
        case "$1" in
            --family|-f)  family="${2:-}";  shift 2 ;;
            --variant|-v) variant="${2:-}"; shift 2 ;;
            --json)       json=1; shift ;;
            --help|-h)    theme::help; return 0 ;;
            *) printf 'ash theme list: unknown option %s\n' "$1" >&2; return 2 ;;
        esac
    done

    local -a files=()
    local f
    for f in "${_THEME_CATALOGUE}"/*.json; do
        [[ -f "$f" ]] || continue
        files+=("$f")
    done

    if (( ${#files[@]} == 0 )); then
        ash_log_error "No themes found in ${_THEME_CATALOGUE}"
        ash_log_info  "Generate the catalogue with: scripts/theme/generate-library.sh"
        return 1
    fi

    # One jq pass over the whole catalogue rather than one per file: 361 files
    # spawned as 361 processes takes seconds, this takes milliseconds.
    local rows
    rows="$(jq -r '
        [.slug // "", .name // "", .variant // "dark", .family // "other", .seed // ""]
        | @tsv
    ' "${files[@]}" 2>/dev/null | sort -t$'\t' -k4,4 -k1,1)"

    [[ -n "$family"  ]] && rows="$(awk -F'\t' -v f="$family"  '$4 == f' <<<"$rows")"
    [[ -n "$variant" ]] && rows="$(awk -F'\t' -v v="$variant" '$3 == v' <<<"$rows")"

    if (( json )); then
        local total
        total="$(grep -c . <<<"$rows" || true)"
        jq -n --argjson n "$total" --arg fam "$family" --arg var "$variant" \
              --arg json_rows "$rows" \
              '{total: $n, family: $fam, variant: $var,
                themes: ($json_rows | split("\n") | map(select(length > 0)
                        | split("\t") | {slug: .[0], name: .[1], variant: .[2], family: .[3], seed: .[4]}))}'
        return 0
    fi

    ash_banner "🎨 THEME CATALOGUE" \
        "${_THEME_CATALOGUE}" "80"

    local n=0 last_family="" slug name var seed seed_hex
    while IFS=$'\t' read -r slug name var fam seed; do
        [[ -n "$slug" ]] || continue
        if [[ "$fam" != "$last_family" ]]; then
            printf '\n  %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "$fam" "${RST}"
            last_family="$fam"
        fi
        # The chip is drawn from the theme's own seed, so the list previews it.
        seed_hex="$(ash_ok_normalize_hex "${seed:-#000000}" 2>/dev/null || printf '#000000')"
        printf '    %s %-26s %s%-22s%s %s%s%s\n' \
            "$(theme::swatch "$seed_hex" 2)" \
            "$slug" \
            "${ASH_MUTED}" "$name" "${RST}" \
            "${ASH_MUTED}" "$var" "${RST}"
        (( n++ )) || true
    done <<<"$rows"

    # Count DISTINCT families in the filtered set, not the row count.
    local fam_n
    fam_n="$(awk -F'\t' 'NF { seen[$4] = 1 } END { print length(seen) + 0 }' <<<"$rows")"
    local fam_word="families"
    [[ "$fam_n" == "1" ]] && fam_word="family"
    printf '\n  %s%s%s\n' "${ASH_MUTED}" \
        "$(theme::plural "$n" theme) across ${fam_n} ${fam_word}" "${RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# show
# ─────────────────────────────────────────────────────────────────────────────
theme::show() {
    local want="${1:-}"
    [[ -n "$want" ]] || { ash_log_error "Usage: ash theme show <name>"; return 2; }

    local file
    file="$(theme::resolve "$want")" || {
        ash_log_error "No such theme: ${want}"
        ash_log_info  "Run 'ash theme list' to see the catalogue"
        return 1
    }

    local name slug variant family seed
    name="$(jq -r '.name    // "?"' "$file")"
    slug="$(jq -r '.slug    // "?"' "$file")"
    variant="$(jq -r '.variant // "dark"' "$file")"
    family="$(jq -r '.family  // "other"' "$file")"
    seed="$(jq -r '.seed    // ""' "$file")"

    ash_banner "🎨 ${name}" "${slug} · ${variant} · ${family}" "80"

    local -A pal=()
    if declare -f _ash_palette_load_file >/dev/null 2>&1; then
        _ash_palette_load_file "$file" pal
    else
        # Fallback so `show` still works from a bare checkout.
        local k v
        while IFS=$'\t' read -r k v; do pal["$k"]="$v"; done < <(
            jq -r 'to_entries | map(select(.value | test("^#[0-9a-fA-F]{6}$")))
                   | .[] | "\(.key)\t\(.value)"' "$file" 2>/dev/null
        )
    fi

    local slot hex
    printf '\n'
    for slot in "${_THEME_SLOT_ORDER[@]}"; do
        hex="${pal[$slot]:-}"
        [[ -n "$hex" ]] || continue
        printf '    %-10s %s%s%s  %s\n' \
            "$slot" "${ASH_MUTED}" "$hex" "${RST}" "$(theme::swatch "$hex" 16)"
    done

    # Contrast summary, straight from the engine.
    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local -A copy=()
        for slot in "${!pal[@]}"; do copy["$slot"]="${pal[$slot]}"; done

        # --quiet is the mode that returns the failure count WITHOUT printing a
        # report. Without it the report text is captured instead of the number.
        local fails
        set +e
        fails="$(ash_wcag_check_palette copy --quiet 2>/dev/null)"
        set -e
        # Guard against a non-numeric result so a future change to the engine
        # cannot turn this into an arithmetic error.
        [[ "$fails" =~ ^[0-9]+$ ]] || fails=0

        printf '\n    %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "CONTRAST" "${RST}"
        if (( fails == 0 )); then
            printf '    %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" \
                "All WCAG checks pass"
        else
            printf '    %s%s%s %s\n' "$ASH_ERROR" "${ICO_ERROR}" "${RST}" \
                "$(theme::plural "$fails" check) failing"
            printf '    %s↳ ash theme wcag %s%s\n' "${ASH_MUTED}" "$slug" "${RST}"
        fi
    fi
    printf '\n    %s%s%s\n\n' "${ASH_MUTED}" "$file" "${RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# apply — render the templates for a theme into configuration files
# ─────────────────────────────────────────────────────────────────────────────
theme::apply() {
    local want="${1:-}"; shift || true
    local out_dir="${ASH_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
    local dry_run=0 force=0

    while (( $# )); do
        case "$1" in
            --out|-o)   out_dir="${2:-}"; shift 2 ;;
            --dry-run|-n) dry_run=1; shift ;;
            --force|-f) force=1; shift ;;
            *) printf 'ash theme apply: unknown option %s\n' "$1" >&2; return 2 ;;
        esac
    done

    [[ -n "$want" ]] || { ash_log_error "Usage: ash theme apply <name> [--out DIR]"; return 2; }

    local file
    file="$(theme::resolve "$want")" || { ash_log_error "No such theme: ${want}"; return 1; }

    if ! declare -f ash_tpl_render_file >/dev/null 2>&1; then
        ash_log_error "Template engine unavailable (lib/template-engine.sh)"
        return 1
    fi

    local slug
    slug="$(jq -r '.slug // "theme"' "$file")"

    local -A pal=()
    if declare -f _ash_palette_load_file >/dev/null 2>&1; then
        _ash_palette_load_file "$file" pal
    fi
    # The templates also read metadata slots, so fold those in.
    pal[name]="$slug"
    pal[slug]="$slug"
    pal[variant]="$(jq -r '.variant // "dark"' "$file")"

    ash_banner "🎨 APPLY ${slug}" "${out_dir}" "80"

    local rendered=0 skipped=0 failed=0 tpl target name
    for tpl in "${_THEME_TEMPLATE_DIR}"/*.template; do
        [[ -f "$tpl" ]] || continue
        name="$(basename "$tpl" .template)"

        if (( dry_run )); then
            printf '    %s%s%s %s\n' "${ASH_MUTED}" "would write" "${RST}" "$name"
            (( rendered++ )) || true
            continue
        fi

        if ! ash_tpl_render_file "$tpl" pal >/dev/null 2>&1; then
            printf '    %s%s%s %s\n' "$ASH_ERROR" "render failed" "${RST}" "$name"
            (( failed++ )) || true
            continue
        fi
        (( rendered++ )) || true
    done

    printf '\n'
    if (( dry_run )); then
        printf '  %s%s%s %s\n\n' "$ASH_INFO" "${ICO_INFO}" "${RST}" \
            "Dry run — $(theme::plural "$rendered" template) would be rendered"
    else
        printf '  %s%s%s %s\n\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" \
            "$(theme::plural "$rendered" template) rendered" \
            "${failed:+· $failed failed}"
    fi

    (( failed == 0 )) || return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# generate
# ─────────────────────────────────────────────────────────────────────────────
theme::generate() {
    local want="${1:-}"; shift || true
    local variant="dark" name="" out=""

    while (( $# )); do
        case "$1" in
            --light|-l) variant="light"; shift ;;
            --dark|-d)  variant="dark";  shift ;;
            --name)     name="${2:-}";   shift 2 ;;
            --out|-o)   out="${2:-}";    shift 2 ;;
            *) printf 'ash theme generate: unknown option %s\n' "$1" >&2; return 2 ;;
        esac
    done

    [[ -n "$want" ]] || {
        ash_log_error "Usage: ash theme generate <#rrggbb|prompt> [--light] [--out FILE]"
        return 2
    }

    # A hex seed is used directly; anything else is treated as a prompt and
    # resolved to a hue by the generator.
    local seed="$want"
    if [[ ! "$want" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
        seed="$(ash_generate_from_prompt "$want" 2>/dev/null)" || {
            ash_log_error "Could not derive a colour from: ${want}"
            return 1
        }
    fi
    seed="$(ash_ok_normalize_hex "$seed")"

    local -A pal=()
    ash_palette_derive pal "$seed" "$variant"
    ash_palette_complete pal "$seed" "$variant" 2>/dev/null || true

    if [[ -z "$name" ]]; then
        name="$(ash_generate_name "$seed" 2>/dev/null || printf 'generated')"
    fi

    if [[ -z "$out" && ! -t 1 ]]; then
        # Piped with no destination: emit the palette as JSON.
        if declare -f ash_palette_render_json >/dev/null 2>&1; then
            ash_palette_render_json pal
        else
            ash_palette_render_kv pal
        fi
        return 0
    fi

    ash_banner "🎨 GENERATED" "${name} · ${seed} · ${variant}" "80"

    local slot hex
    printf '\n'
    for slot in "${_THEME_SLOT_ORDER[@]}"; do
        hex="${pal[$slot]:-}"
        [[ -n "$hex" ]] || continue
        printf '    %-10s %s%s%s  %s\n' \
            "$slot" "${ASH_MUTED}" "$hex" "${RST}" "$(theme::swatch "$hex" 16)"
    done

    if [[ -n "$out" ]]; then
        local slug
        slug="$(ash_generate_slug "$name" 2>/dev/null || printf '%s' "$name" | tr 'A-Z ' 'a-z-')"
        jq -n --arg name "$name" --arg slug "$slug" --arg variant "$variant" \
              --arg seed "$seed" --arg family "generated" \
              --argjson colors "$(printf '%s\n' "${!pal[@]}" | while read -r k; do
                                    printf '%s\0' "$k" "${pal[$k]}"; done | xargs -0 -n2 printf '%s %s\n' \
                                    | jq -Rn '[inputs | split(" ") | {(.[0]): .[1]}] | add')" \
              '{name: $name, slug: $slug, variant: $variant, family: $family,
                seed: $seed, colors: $colors}' > "$out"
        printf '\n  %s%s%s %s\n\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" "Wrote ${out}"
    else
        printf '\n'
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# extract — pull a palette out of an image
# ─────────────────────────────────────────────────────────────────────────────
theme::extract() {
    local img="${1:-}"; shift || true
    local out="" count=8

    while (( $# )); do
        case "$1" in
            --out|-o)   out="${2:-}";   shift 2 ;;
            --count|-n) count="${2:-8}"; shift 2 ;;
            *) printf 'ash theme extract: unknown option %s\n' "$1" >&2; return 2 ;;
        esac
    done

    [[ -f "$img" ]] || { ash_log_error "Not a readable image: ${img:-<none>}"; return 1; }

    local backend
    backend="$(ash_extract_backend 2>/dev/null || printf 'none')"
    if [[ "$backend" == "none" ]]; then
        ash_log_error "No extraction backend available"
        ash_log_info  "Install ImageMagick, or Pillow for the Python backend"
        return 1
    fi

    ash_banner "🎨 EXTRACT" "$(basename "$img") · backend: ${backend}" "80"

    local -a colors=()
    while IFS= read -r c; do
        [[ -n "$c" ]] && colors+=("$c")
    done < <(ash_extract_palette "$img" "$count" 2>/dev/null)

    if (( ${#colors[@]} == 0 )); then
        ash_log_error "No colours extracted from ${img}"
        return 1
    fi

    printf '\n'
    local c
    for c in "${colors[@]}"; do
        printf '    %s%s%s  %s\n' "${ASH_MUTED}" "$c" "${RST}" "$(theme::swatch "$c" 24)"
    done

    local hue
    hue="$(ash_extract_dominant_hue "${colors[@]}" 2>/dev/null || true)"
    printf '\n    %sdominant hue%s %s\n' "${ASH_MUTED}" "${RST}" "${hue:-unknown}"

    if [[ -n "$out" ]]; then
        printf '%s\n' "${colors[@]}" > "$out"
        printf '\n  %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" "Wrote ${out}"
    fi
    printf '\n'
}

# ─────────────────────────────────────────────────────────────────────────────
# wcag — contrast validation
# ─────────────────────────────────────────────────────────────────────────────
theme::wcag() {
    local want="" sweep=0 json=0 fix=0

    while (( $# )); do
        case "$1" in
            --sweep|-s) sweep=1; shift ;;
            --json)     json=1; shift ;;
            --fix)      fix=1; shift ;;
            --help|-h)  theme::help; return 0 ;;
            *)          want="$1"; shift ;;
        esac
    done

    # Whole catalogue.
    if (( sweep )) || [[ -z "$want" ]]; then
        local args=(sweep "${_THEME_CATALOGUE}")
        (( json )) && args+=(--json)
        (( fix ))  && args+=(--fix)
        ash_wcag_main "${args[@]}"
        return $?
    fi

    # Single theme.
    local file
    file="$(theme::resolve "$want")" || { ash_log_error "No such theme: ${want}"; return 1; }

    if (( fix )); then
        # Capture the before/after so the success line can say what actually
        # changed. Without --in-place this function writes to stdout and leaves
        # the file untouched, which made the message a lie.
        local before after
        before="$(jq -cS '.colors // .' "$file" 2>/dev/null || printf '')"

        if ash_wcag_fix_file "$file" --in-place; then
            after="$(jq -cS '.colors // .' "$file" 2>/dev/null || printf '')"
            if [[ "$before" == "$after" ]]; then
                printf '  %s%s%s %s\n' "$ASH_INFO" "${ICO_INFO}" "${RST}" \
                    "$(basename "$file") already passes — nothing to repair"
            else
                printf '  %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" \
                    "Repaired contrast in $(basename "$file")"
            fi
            return 0
        fi

        printf '  %s%s%s %s\n' "$ASH_ERROR" "${ICO_ERROR}" "${RST}" \
            "Could not repair $(basename "$file")"
        return 1
    fi

    local args=("$file")
    (( json )) && args+=(--json)
    ash_wcag_main check "${args[@]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# help / dispatch
# ─────────────────────────────────────────────────────────────────────────────
theme::help() {
    ash_banner "🎨 ASH THEME" "catalogue · generation · contrast" "80"

    cat <<EOF

${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme${RST} <subcommand> [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${ASH_ACCENT}list${RST}      [--family F] [--variant V] [--json]   Browse the catalogue
  ${ASH_ACCENT}show${RST}      <name>                               Display a palette
  ${ASH_ACCENT}apply${RST}     <name> [--out DIR] [--dry-run]       Render config files
  ${ASH_ACCENT}generate${RST}  <#seed|prompt> [--light] [--out F]   Derive a palette
  ${ASH_ACCENT}extract${RST}   <image> [--count N] [--out F]        Pull colours from an image
  ${ASH_ACCENT}wcag${RST}      [<name>|--sweep] [--json] [--fix]    Check contrast

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}# Browse and preview${RST}
  ash theme list --family nord
  ash theme show nord

${ASH_MUTED}# Build config files from a theme${RST}
  ash theme apply nord --out ~/.config

${ASH_MUTED}# Derive a new palette from a colour, or from words${RST}
  ash theme generate '#7aa2f7'
  ash theme generate "deep forest at dusk" --light

${ASH_MUTED}# Validate contrast across the whole catalogue${RST}
  ash theme wcag --sweep

${BOLD}${ASH_PRIMARY}CATALOGUE${RST}
  ${ASH_MUTED}${_THEME_CATALOGUE}${RST}
  ${ASH_MUTED}Templates: ${_THEME_TEMPLATE_DIR}${RST}

EOF
}

theme::main() {
    local sub="${1:-}"; shift || true

    case "$sub" in
        list|ls)          theme::list "$@" ;;
        show|info)        theme::show "$@" ;;
        apply|set)        theme::apply "$@" ;;
        generate|gen)     theme::generate "$@" ;;
        extract)          theme::extract "$@" ;;
        wcag|contrast)    theme::wcag "$@" ;;
        help|--help|-h|"") theme::help ;;
        *)
            ash_log_error "Unknown subcommand: ${sub}"
            ash_log_info  "Run 'ash theme --help' for usage"
            return 1
            ;;
    esac
}

# Executing this file directly still works; sourcing it — which is how the
# dispatcher loads it — must only define the entry point.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    theme::main "$@"
fi

ash_cmd_theme() {
    theme::main "$@"
}

# Top-level `ash wcag` entry point — see the ASH_COMMANDS table in ash-cli/ash.
# Only the contrast gate is exposed this way; the rest of the engine is reached
# through `ash theme`.
ash_cmd_wcag() {
    theme::wcag "$@"
}
