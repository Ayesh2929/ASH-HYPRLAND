#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — ai-generate.sh                                                   ║
# ║  Describe a theme in words and get one back                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::ai_generate::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme ai-generate${RST} "<description>" [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Turns a description into a palette. Two paths, and it is honest about which
  one it used:

    ${ASH_MUTED}local${RST}   the colour engine maps the words to hues and derives a
            palette from them. Always available, instant, no network.
    ${ASH_MUTED}model${RST}   a language model is asked for a seed colour, which is then
            derived locally. Used when Ollama is reachable.

  The model never supplies the palette itself — only a seed colour — so a bad
  generation can still produce a coherent, contrast-checked theme. Every result
  is WCAG-checked before it is saved.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name NAME${RST}        Theme name (default: derived from the words)
  ${ASH_MUTED}--slug SLUG${RST}        Theme slug
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--local${RST}            Skip the model even if one is available
  ${ASH_MUTED}--apply${RST}            Apply the theme after generating it
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing theme
  ${ASH_MUTED}--dry-run, -n${RST}      Show the palette, write nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme ai-generate "deep forest at dusk"${RST}
  ${ASH_MUTED}ash theme ai-generate "pastel sunrise" --variant light --apply${RST}
EOF
}

# Is a model reachable? Ollama answers /api/tags with a list.
theme::ai_generate::model_available() {
    [[ "${ASH_AI_ENABLED:-1}" == "1" ]] || return 1
    [[ -n "${ASH_AI_ENDPOINT:-}" ]] || return 1
    declare -f ash_http_get_json >/dev/null 2>&1 || return 1
    ash_http_get_json "${ASH_AI_ENDPOINT%/}/api/tags" >/dev/null 2>&1
}

# Ask the model for a single seed colour.
theme::ai_generate::ask_model() {
    local prompt="$1"
    local payload
    payload="$(jq -cn --arg m "${ASH_AI_MODEL:-llama3.2}" \
        --arg p "Reply with ONE hex colour code and nothing else, for a theme described as: ${prompt}" \
        '{model: $m, prompt: $p, stream: false}')"

    local reply
    reply="$(ash_http_post_json "${ASH_AI_ENDPOINT%/}/api/generate" "$payload" 2>/dev/null)" || return 1
    [[ -n "$reply" ]] || return 1

    # Take the first hex in the response; a model that adds prose is fine as
    # long as it names a colour somewhere.
    local hex
    hex="$(jq -r '.response // empty' <<<"$reply" 2>/dev/null | grep -oiE '#?[0-9a-f]{6}' | head -1)"
    [[ -n "$hex" ]] || return 1
    printf '#%s' "$(tr 'A-F' 'a-f' <<<"${hex#\#}")"
}

theme::ai_generate() {
    local prompt="" name="" slug="" variant="dark" local_only=0 apply=0 force=0 dry=0 json=0

    while (( $# )); do
        case "$1" in
            --name)      name="${2:-}"; shift 2 ;;
            --slug)      slug="${2:-}"; shift 2 ;;
            --variant)   variant="${2:-}"; shift 2 ;;
            --local)     local_only=1; shift ;;
            --apply)     apply=1; shift ;;
            --force|-f)  force=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)      json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)   theme::ai_generate::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::ai_generate::help; return 2 ;;
            *)           prompt="${prompt:+$prompt }$1"; shift ;;
        esac
    done

    [[ -n "$prompt" ]] || { ash_log_error "Describe the theme you want."; theme::ai_generate::help; return 2; }
    [[ "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"; return 2; }

    [[ -n "$name" ]] || name="$(ash_generate_name "$prompt" 2>/dev/null || printf '%s' "$prompt")"
    [[ -n "$slug" ]] || slug="$(ash_generate_slug "$name" 2>/dev/null || printf 'generated')"
    [[ -n "$slug" ]] || slug="generated-$RANDOM"

    local dest="${THEME_USER_DIR}/${slug}.json"
    if [[ -f "$dest" && "$force" -eq 0 && "$dry" -eq 0 ]]; then
        ash_log_error "User theme '$slug' already exists."
        printf '  %sPass --force to overwrite, or --slug for another name.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    # ── Pick a seed ───────────────────────────────────────────────────────────
    local source="local" seed="" wcag=0

    if (( ! local_only )) && theme::ai_generate::model_available; then
        local model_hex
        if model_hex="$(theme::ai_generate::ask_model "$prompt")"; then
            seed="$model_hex"; source="model"
        fi
    fi

    local -A pal=()
    if [[ -n "$seed" ]]; then
        # A seed from the model still goes through the engine, so the derived
        # palette keeps the accent relationships and contrast guarantees.
        if ! ash_palette_derive pal "$seed" "$variant" 2>/dev/null; then
            seed=""; source="local"
        fi
    fi

    if [[ -z "$seed" ]]; then
        if declare -f ash_generate_from_prompt >/dev/null 2>&1; then
            if ! ash_generate_from_prompt pal "$prompt" "$variant"; then
                ash_log_error "Could not generate a palette from that description."
                return 1
            fi
        else
            ash_log_error "The colour engine is not loaded."
            return 1
        fi
        seed="${pal[accent]:-${pal[base]:-}}"
        [[ "$source" == "model" ]] && source="local (model output unusable)"
    fi

    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local r
        r="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && wcag="$r"
    fi

    if (( json )); then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg slug "$slug" --arg name "$name" --arg variant "$variant" \
              --arg prompt "$prompt" --arg seed "$seed" --arg source "$source" \
              --arg file "$dest" --argjson dry "$dry" --argjson wcag "$wcag" \
              --argjson colors "$colors_json" \
              '{slug: $slug, name: $name, variant: $variant, prompt: $prompt,
                seed: $seed, source: $source, file: $file,
                dry_run: ($dry == 1), wcag_failures: $wcag, colors: $colors}'
        (( dry )) && return 0
    elif (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    source  %s\n    seed    %s%s%s\n\n' "$source" "${ASH_ACCENT}" "$seed" "${RST}"
        local slot
        for slot in "${THEME_SLOT_ORDER[@]}"; do
            [[ -n "${pal[$slot]:-}" ]] && printf '    %-9s %s  %s\n' \
                "$slot" "${pal[$slot]}" "$(theme::swatch "${pal[$slot]}" 10)"
        done
        printf '\n'
        return 0
    fi

    theme::save "$dest" pal "slug=$slug" "name=$name" "variant=$variant" \
        "family=generated" "seed=$seed" "prompt=$prompt" || {
        ash_log_error "Could not write $dest"; return 1; }

    theme::record "$slug" ai-generate

    if [[ "$json" != "1" ]]; then
        printf '\n  %s🤖 Generated%s %s%s%s %s(%s)%s\n' \
            "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
            "${ASH_MUTED}" "$source" "${RST}"
        printf '  %s   "%s"%s\n' "${ASH_MUTED}" "$prompt" "${RST}"
        (( wcag )) && printf '  %s⚠  %s below 4.5:1 — ash theme wcag %s --fix%s\n' \
            "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "$wcag" "pair")" "$slug" "${RST}"
        printf '\n'
    fi

    if (( apply )); then
        theme::source_sub apply || return 1
        theme::apply "$slug" || return $?
    elif [[ "$json" != "1" ]]; then
        printf '  %sTry it:  ash theme preview %s --mock%s\n\n' "${ASH_MUTED}" "$slug" "${RST}"
    fi
}
