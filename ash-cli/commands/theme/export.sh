#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — export.sh                                                        ║
# ║  Convert a theme into other tools' formats                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::export::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme export${RST} <theme> [--format FMT] [--out FILE]

${BOLD}${ASH_PRIMARY}FORMATS${RST}
  ${ASH_MUTED}json${RST}        ASH theme document (default)
  ${ASH_MUTED}base16${RST}      base16 YAML scheme, for other theme tools
  ${ASH_MUTED}css${RST}         Custom properties (--prefix to namespace)
  ${ASH_MUTED}scss${RST}        SCSS variables
  ${ASH_MUTED}kitty${RST}       kitty.conf fragment
  ${ASH_MUTED}alacritty${RST}   alacritty TOML fragment
  ${ASH_MUTED}env${RST}         ASH_THEME_* shell variables
  ${ASH_MUTED}gpl${RST}         GIMP palette
  ${ASH_MUTED}hex${RST}         One hex per line
  ${ASH_MUTED}list${RST}        The available formats

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--format, -F FMT${RST}   Output format (default json)
  ${ASH_MUTED}--out, -o FILE${RST}     Write to a file instead of stdout
  ${ASH_MUTED}--prefix STR${RST}        Prefix for css/scss variable names
  ${ASH_MUTED}--force${RST}             Overwrite an existing --out file

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme export nord --format base16 --out nord.yaml${RST}
  ${ASH_MUTED}ash theme export nord -F css --prefix "ash-“${RST}
  ${ASH_MUTED}ash theme export nord -F hex | head -3${RST}
EOF
}

_THEME_EXPORT_FORMATS="json base16 css scss kitty alacritty env gpl hex"

# base16 wants the 16 slots in its own order and without the leading '#'.
theme::export::base16() {
    local -n p="$1"
    local slug="$2" name="$3" variant="$4"
    cat <<EOF
scheme: "${name:-$slug}"
author: "ASH DOTFILES"
base00: "${p[base]#\#}"
base01: "${p[mantle]#\#}"
base02: "${p[surface]#\#}"
base03: "${p[overlay]#\#}"
base04: "${p[subtext]#\#}"
base05: "${p[text]#\#}"
base06: "${p[text]#\#}"
base07: "${p[base]#\#}"
base08: "${p[rose]#\#}"
base09: "${p[gold]#\#}"
base0A: "${p[gold]#\#}"
base0B: "${p[mint]#\#}"
base0C: "${p[sky]#\#}"
base0D: "${p[accent]#\#}"
base0E: "${p[violet]#\#}"
base0F: "${p[crust]#\#}"
EOF
}

theme::export::css() {
    local -n p="$1"
    local prefix="$2"
    printf ':root {\n'
    local slot
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        [[ -n "${p[$slot]:-}" ]] || continue
        printf '  --%s%s: %s;\n' "$prefix" "$slot" "${p[$slot]}"
    done
    printf '}\n'
}

theme::export::scss() {
    local -n p="$1"
    local prefix="$2"
    local slot
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        [[ -n "${p[$slot]:-}" ]] || continue
        printf '$%s%s: %s;\n' "$prefix" "$slot" "${p[$slot]}"
    done
}

theme::export::kitty() {
    local -n p="$1"
    cat <<EOF
# ash theme — kitty fragment
foreground            ${p[text]}
background            ${p[base]}
selection_foreground  ${p[base]}
selection_background  ${p[accent]}
cursor                ${p[accent]}
cursor_text_color     ${p[base]}
url_color             ${p[sky]}
active_border_color   ${p[accent]}
inactive_border_color ${p[overlay]}
active_tab_foreground   ${p[base]}
active_tab_background   ${p[accent]}
inactive_tab_foreground ${p[subtext]}
inactive_tab_background ${p[mantle]}
color0  ${p[crust]}
color8  ${p[overlay]}
color1  ${p[rose]}
color9  ${p[rose]}
color2  ${p[mint]}
color10 ${p[mint]}
color3  ${p[gold]}
color11 ${p[gold]}
color4  ${p[accent]}
color12 ${p[accent]}
color5  ${p[violet]}
color13 ${p[violet]}
color6  ${p[sky]}
color14 ${p[sky]}
color7  ${p[text]}
color15 ${p[text]}
EOF
}

theme::export::alacritty() {
    local -n p="$1"
    cat <<EOF
# ash theme — alacritty fragment
[colors.primary]
background = "${p[base]}"
foreground = "${p[text]}"

[colors.cursor]
text = "${p[base]}"
cursor = "${p[accent]}"

[colors.selection]
text = "${p[base]}"
background = "${p[accent]}"

[colors.normal]
black   = "${p[crust]}"
red     = "${p[rose]}"
green   = "${p[mint]}"
yellow  = "${p[gold]}"
blue    = "${p[accent]}"
magenta = "${p[violet]}"
cyan    = "${p[sky]}"
white   = "${p[text]}"

[colors.bright]
black   = "${p[overlay]}"
red     = "${p[rose]}"
green   = "${p[mint]}"
yellow  = "${p[gold]}"
blue    = "${p[accent]}"
magenta = "${p[violet]}"
cyan    = "${p[sky]}"
white   = "${p[text]}"
EOF
}

theme::export() {
    local want="" format="json" out="" prefix="" force=0
    while (( $# )); do
        case "$1" in
            --format|-F) format="${2:-json}"; shift 2 ;;
            --out|-o)    out="${2:-}"; shift 2 ;;
            --prefix)    prefix="${2:-}"; shift 2 ;;
            # `export` already emits machine-readable output; --json is
            # accepted as the same request so every subcommand takes it.
            --json)      format="json"; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            --force|-f)  force=1; shift ;;
            -h|--help)   theme::export::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::export::help; return 2 ;;
            *)           want="$1"; shift ;;
        esac
    done

    if [[ "$want" == "list" || "$format" == "list" ]]; then
        printf '\n  %sFormats:${RST} %s\n\n' "${BOLD}${ASH_PRIMARY}" "$_THEME_EXPORT_FORMATS"
        return 0
    fi

    [[ -n "$want" ]] || { ash_log_error "Which theme should I export?"; theme::export::help; return 2; }

    case " $_THEME_EXPORT_FORMATS " in
        *" $format "*) : ;;
        *) ash_log_error "Unknown format: $format"
           printf '  %sAvailable: %s%s\n\n' "${ASH_MUTED}" "$_THEME_EXPORT_FORMATS" "${RST}" >&2
           return 2 ;;
    esac

    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    local slug name variant
    slug="$(jq -r '.slug // empty' "$file" 2>/dev/null)"
    name="$(jq -r '.name // empty' "$file" 2>/dev/null)"
    variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
    [[ -n "$slug" ]] || slug="$(basename "$file" .json)"

    # Refuse before generating anything, so a failed run cannot leave a
    # half-written file behind.
    if [[ -n "$out" && -e "$out" && "$force" -eq 0 ]]; then
        ash_log_error "$out already exists."
        printf '  %sPass --force to overwrite it.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    local -A pal=()
    theme::load "$file" pal

    # Drop anything the exporter cannot use, rather than emitting `#` in the
    # middle of a generated config.
    local _k _v
    for _k in "${!pal[@]}"; do
        _v="${pal[$_k]}"
        [[ "$_v" =~ ^#[0-9a-fA-F]{6}$ ]] || unset "pal[$_k]"
    done

    local body=""
    case "$format" in
        json)      body="$(jq -S . "$file" 2>/dev/null)" ;;
        base16)    body="$(theme::export::base16 pal "$slug" "$name" "$variant")" ;;
        css)       body="$(theme::export::css pal "$prefix")" ;;
        scss)      body="$(theme::export::scss pal "$prefix")" ;;
        kitty)     body="$(theme::export::kitty pal)" ;;
        alacritty) body="$(theme::export::alacritty pal)" ;;
        env)
            local slot
            for slot in "${THEME_SLOT_ORDER[@]}"; do
                [[ -n "${pal[$slot]:-}" ]] || continue
                body+="ASH_THEME_$(tr '[:lower:]' '[:upper:]' <<<"$slot")='${pal[$slot]}'"$'\n'
            done
            body+="ASH_THEME_SLUG='$slug'"$'\n'
            body+="ASH_THEME_VARIANT='$variant'"$'\n'
            ;;
        gpl)
            body="GIMP Palette"$'\n'"Name: ${name:-$slug}"$'\n'"Columns: 4"$'\n'$'#'
            local s v
            for s in "${THEME_SLOT_ORDER[@]}"; do
                v="${pal[$s]:-}"; [[ -n "$v" ]] || continue
                body+="$(printf '%3d %3d %3d\t%s' \
                    "$(( 16#${v:1:2} ))" "$(( 16#${v:3:2} ))" "$(( 16#${v:5:2} ))" "$s")"$'\n'
            done
            ;;
        hex)
            local s
            for s in "${THEME_SLOT_ORDER[@]}"; do
                [[ -n "${pal[$s]:-}" ]] && body+="${pal[$s]}"$'\n'
            done
            ;;
    esac

    if [[ -z "$body" ]]; then
        ash_log_error "Nothing to write — '$slug' has no colours for format '$format'"
        return 1
    fi

    if [[ -n "$out" ]]; then
        mkdir -p "$(dirname "$out")"
        printf '%s\n' "$body" > "${out}.tmp" || { ash_log_error "Could not write $out"; return 1; }
        mv "${out}.tmp" "$out"
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            jq -n --arg slug "$slug" --arg format "$format" --arg out "$out" \
                  --argjson bytes "$(printf '%s' "$body" | wc -c)" \
                  '{slug: $slug, format: $format, out: $out, bytes: $bytes}'
        else
            printf '\n  %s✅ Exported%s %s%s%s as %s%s%s\n' \
                "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
                "${ASH_MUTED}" "$format" "${RST}"
            printf '  %s   %s%s\n\n' "${ASH_MUTED}" "$out" "${RST}"
        fi
    else
        printf '%s\n' "$body"
    fi
}
