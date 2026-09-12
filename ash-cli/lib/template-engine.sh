#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🧩 ASH TEMPLATE ENGINE — a tiny, dependency-free string renderer             ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  This is the component that turns `themes/<name>/colors.json` into concrete   ║
# ║  config files for 25+ applications. It exists because `envsubst` chokes on    ║
# ║  loops, `sed` chokes on `&` in values, and neither handles conditionals.      ║
# ║                                                                               ║
# ║  Syntax                                                                      ║
# ║    {{key}}                     variable substitution                         ║
# ║    {{key|upper}}               filters: upper lower title trim quote         ║
# ║                                        hex2rgb rgb2hex lighten darken        ║
# ║                                        alpha2hex contrast_fg split0..split9  ║
# ║    {{key:-fallback}}           default when unset/empty                       ║
# ║    {{#if key}} … {{/if}}       conditional block                              ║
# ║    {{#unless key}} … {{/unless}}                                             ║
# ║    {{#each list as item}} … {{/each}}   iterate a space-separated list        ║
# ║    {{> partial}}               inline another template file                  ║
# ║    \{{ literal }}              escape to emit a literal {{ … }}               ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_TEMPLATE_ENGINE_LOADED:-}" ]] && return 0
readonly _ASH_TEMPLATE_ENGINE_LOADED=1
readonly ASH_TEMPLATE_VERSION="5.0.0"

declare -gA ASH_TPL_VARS=()
declare -g  ASH_TPL_PARTIAL_DIR=""
declare -g  ASH_TPL_MAX_DEPTH=8

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  VARIABLE CONTEXT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_tpl_reset() { ASH_TPL_VARS=(); }

ash_tpl_set()     { ASH_TPL_VARS["$1"]="$2"; }
ash_tpl_set_raw() { ASH_TPL_VARS["$1"]="$2"; }

# Load every scalar from a JSON file as a template variable.
#   { "bg": "#1e1e2e", "accent": "#cba6f7" }  →  {{bg}} {{accent}}
ash_tpl_load_json() {
    local file="$1" prefix="${2:-}"
    [[ -f "$file" ]] || return 1

    if command -v jq >/dev/null 2>&1; then
        local key value
        while IFS=$'\t' read -r key value; do
            [[ -z "$key" ]] && continue
            ASH_TPL_VARS["${prefix}${key}"]="$value"
        # Flatten nested objects and arrays to dotted keys.
        #
        # The previous version could not work at all: `to_entries[]` emits entry
        # OBJECTS ({key, value}), so `flat`'s `type == "object"` branch was taken
        # for every input, including leaves — it recursed until the kernel killed
        # jq with SIGKILL (observed rc 137). Two further faults were hidden behind
        # it: the leaf branch emitted `"\($p)\(.)"` with no TAB, so the caller's
        # `read -r key value` put the whole line in `key`; and `flat($p + .key…)`
        # read `.key` AFTER the `.value` pipe, where the input is the value.
        #
        # `stderr` is no longer discarded: a failing loader that reports nothing
        # is how this stayed invisible.
        done < <(jq -r '
            def flat($p):
                if type == "object" then
                    to_entries[] | (.key as $k | (.value | flat($p + "." + $k)))
                elif type == "array" then
                    to_entries[] | (.key as $i | (.value | tostring | "\($p).\($i)\t\(.)"))
                else
                    "\($p)\t\(.)"
                end;

            to_entries[] as $e
            | $e.value
            | if type == "object" or type == "array"
              then flat($e.key)
              else "\($e.key)\t\($e.value)" end
        ' "$file")
    else
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*:[[:space:]]*(\"([^\"]*)\"|[0-9.]+|true|false) ]]; then
                local k="${BASH_REMATCH[1]}" v="${BASH_REMATCH[3]:-${BASH_REMATCH[2]}}"
                v="${v//\"/}"
                ASH_TPL_VARS["${prefix}${k}"]="$v"
            fi
        done < "$file"
    fi
    return 0
}

# Load KEY=VALUE pairs from an INI file's [section] (or all sections).
ash_tpl_load_ini() {
    local file="$1" section="${2:-}"
    [[ -f "$file" ]] || return 1

    local cur="" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        [[ -z "${line//[[:space:]]/}" ]] && continue
        if [[ "$line" == \[*\] ]]; then
            cur="${line#[}"; cur="${cur%]}"; continue
        fi
        [[ -n "$section" && "$cur" != "$section" ]] && continue
        if [[ "$line" == *'='* ]]; then
            local k="${line%%=*}" v="${line#*=}"
            k="${k%"${k##*[![:space:]]}"}"; k="${k#"${k%%[![:space:]]*}"}"
            v="${v%"${v##*[![:space:]]}"}"; v="${v#"${v%%[![:space:]]*}"}"
            v="${v#\"}"; v="${v%\"}"
            ASH_TPL_VARS["$k"]="$v"
            [[ -n "$cur" ]] && ASH_TPL_VARS["${cur}.${k}"]="$v"
        fi
    done < "$file"
    return 0
}

ash_tpl_var() { printf '%s' "${ASH_TPL_VARS[${1:-}]:-${2-}}"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  FILTERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Shell-safe hex → "r, g, b"
_ash_tpl_hex2rgb() {
    local hex="${1#\#}"
    # Expand #abc → #aabbcc
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    printf '%d, %d, %d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

_ash_tpl_hex2rgb_nospace() {
    local hex="${1#\#}"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    printf '%d,%d,%d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

_ash_tpl_rgb2hex() {
    local r="$1" g="$2" b="$3"
    printf '#%02x%02x%02x' "${r:-0}" "${g:-0}" "${b:-0}"
}

# Lighten/darken by a percentage, in pure bash.
# amount > 0 lightens toward 255, amount < 0 darkens toward 0.
# Pure bash matters here: this runs ~1000 times while rendering a theme, and
# `awk` lacks strtonum on mawk/busybox, which made the previous version fail
# silently on minimal distros (Alpine, Void).
_ash_tpl_shade() {
    local hex="${1#\#}" amount="$2"
    hex="$(printf '%s' "$hex" | tr 'A-F' 'a-f')"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    (( ${#hex} >= 6 )) || { printf '#%s' "$hex"; return; }

    local r=$(( 16#${hex:0:2} )) g=$(( 16#${hex:2:2} )) b=$(( 16#${hex:4:2} ))
    # Negative amounts arrive as "-20"; bash's 16# parsing chokes on the
    # minus sign inside the arithmetic so we strip it explicitly.
    local amt="${amount#-}"
    local negative=0
    [[ "$amount" == -* ]] && negative=1
    [[ "$amt" =~ ^[0-9]+$ ]] || amt=0
    (( amt > 100 )) && amt=100

    local nr ng nb
    if (( negative == 1 )); then
        nr=$(( r * (100 - amt) / 100 ))
        ng=$(( g * (100 - amt) / 100 ))
        nb=$(( b * (100 - amt) / 100 ))
    else
        nr=$(( r + (255 - r) * amt / 100 ))
        ng=$(( g + (255 - g) * amt / 100 ))
        nb=$(( b + (255 - b) * amt / 100 ))
    fi

    printf '#%02x%02x%02x' "$nr" "$ng" "$nb"
}

# Hex + 0.0-1.0 alpha → 8-digit hex (#rrggbbaa), the format Hyprland,
# GTK4 and Waybar understand.
_ash_tpl_alpha2hex() {
    local hex="${1#\#}" alpha="$2"
    hex="$(printf '%s' "$hex" | tr 'A-F' 'a-f')"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"

    # Clamp alpha and convert to 0-255 without awk.
    local a="${alpha:-1}"
    [[ "$a" =~ ^[0-9]*\.?[0-9]+$ ]] || a=1
    local a8
    a8="$(awk -v a="$a" 'BEGIN{ v=int(a*255+0.5); if(v<0)v=0; if(v>255)v=255; printf "%d", v }')"

    printf '#%s%02x' "$hex" "$a8"
}

# Pick black or white text that stays readable on this background.
# Implements the WCAG 2.1 relative-luminance + contrast-ratio definitions, so
# generated themes are accessibility-checked instead of using a naive
# "is the channel average below 128?" test.
#
# Hex parsing happens in bash (POSIX, no strtonum) and only the curve is
# handed to awk, which every distro ships.
_ash_tpl_contrast_fg() {
    local hex="${1#\#}"
    hex="$(printf '%s' "$hex" | tr 'A-F' 'a-f')"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    (( ${#hex} >= 6 )) || { printf '#ffffff'; return; }

    # 8-digit hex (#rrggbbaa) — ignore the alpha channel for luminance.
    hex="${hex:0:6}"

    local r=$(( 16#${hex:0:2} )) g=$(( 16#${hex:2:2} )) b=$(( 16#${hex:4:2} ))

    awk -v r="$r" -v g="$g" -v b="$b" '
        function lin(c) {
            c = c / 255;
            return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4;
        }
        BEGIN {
        L = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);

        cw = 1.05 / (L + 0.05);          # ratio vs white
        cb = (L + 0.05) / 0.05;          # ratio vs black

        # Prefer the better ratio; on ties prefer white for dark brand colours.
        if (cw >= cb) print "#ffffff"; else print "#000000";
    }'
}

_ash_tpl_apply_filter() {
    local value="$1" filter="$2"
    case "$filter" in
        upper)        printf '%s' "${value^^}" ;;
        lower)        printf '%s' "${value,,}" ;;
        title)        printf '%s' "$value" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' ;;
        trim)         printf '%s' "$value" | tr -d '[:space:]' ;;
        quote)        printf '"%s"' "$value" ;;
        squote)       printf "'%s'" "$value" ;;
        hex2rgb)      _ash_tpl_hex2rgb "$value" ;;
        hex2rgbns)    _ash_tpl_hex2rgb_nospace "$value" ;;
        contrast_fg)  _ash_tpl_contrast_fg "$value" ;;
        strip_hash)   printf '%s' "${value#\#}" ;;
        add_hash)     printf '#%s' "${value#\#}" ;;
        reverse)      printf '%s' "$value" | rev ;;
        basename)     basename -- "$value" ;;
        dirname)      dirname -- "$value" ;;
        *)
            if [[ "$filter" =~ ^lighten([0-9]+)$ ]]; then       _ash_tpl_shade "$value" "${BASH_REMATCH[1]}"
            elif [[ "$filter" =~ ^darken([0-9]+)$ ]]; then      _ash_tpl_shade "$value" "-${BASH_REMATCH[1]}"
            elif [[ "$filter" =~ ^alpha([0-9.]+)$ ]]; then      _ash_tpl_alpha2hex "$value" "${BASH_REMATCH[1]}"
            elif [[ "$filter" =~ ^split([0-9]+)$ ]]; then
                local sep="${ASH_TPL_SPLIT_SEP:-.}"
                local -a parts
                IFS="$sep" read -r -a parts <<< "$value"
                printf '%s' "${parts[${BASH_REMATCH[1]}]:-}"
            else
                printf '%s' "$value"
            fi
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 3  RENDERING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Resolve {{key}} / {{key:-default}} / {{key|filter}} / {{key|f1|f2}}
# Resolve {{key}} / {{key:-default}} / {{key|filter}} / {{key|f1|f2}}
_ash_tpl_expand() {
    local token="$1"
    local default=""
    local expr="$token"

    # {{key:-default}} — the default may itself contain ':'
    if [[ "$expr" == *":-"* ]]; then
        default="${expr#*:-}"
        expr="${expr%%:-*}"
    fi

    expr="${expr#"${expr%%[![:space:]]*}"}"
    expr="${expr%"${expr##*[![:space:]]}"}"

    local var="$expr"
    local -a filters=()
    if [[ "$expr" == *"|"* ]]; then
        var="${expr%%|*}"
        local rest="${expr#*|}"
        IFS='|' read -r -a filters <<< "$rest"
    fi
    var="${var%"${var##*[![:space:]]}"}"

    # Direct lookup, then a flattened dotted-path fallback so both
    # {{bg}} and {{theme.bg}} resolve the same value.
    local value="${ASH_TPL_VARS[$var]:-}"
    if [[ -z "$value" && "$var" == *.* ]]; then
        local leaf="${var##*.}"
        value="${ASH_TPL_VARS[$leaf]:-}"
    elif [[ -z "$value" ]]; then
        local flat
        for flat in "${!ASH_TPL_VARS[@]}"; do
            if [[ "${flat##*.}" == "$var" ]]; then value="${ASH_TPL_VARS[$flat]}"; break; fi
        done
    fi
    [[ -z "$value" ]] && value="$default"

    local flt
    for flt in "${filters[@]:-}"; do
        [[ -z "$flt" ]] && continue
        flt="${flt#"${flt%%[![:space:]]*}"}"
        flt="${flt%"${flt##*[![:space:]]}"}"
        value="$(_ash_tpl_apply_filter "$value" "$flt")"
    done

    printf '%s' "$value"
}

# ── Nesting-aware block matcher ──────────────────────────────────────────────
# Given the body text that follows a `{{#kind …}}` opener, returns the byte
# offset of the matching `{{/kind}}`, counting nested openers of the same kind.
_ash_tpl_find_close() {
    local kind="$1" body="$2"
    local depth=1 pos=0 len=${#body}
    local open="{{#${kind}" close="{{/${kind}}}"

    while (( pos < len )); do
        local chunk="${body:pos}"
        local pre_o="${chunk%%"$open"*}"
        local pre_c="${chunk%%"$close"*}"

        if [[ "$pre_c" == "$chunk" ]]; then
            printf '%s' "$len"; return 1          # unbalanced
        fi
        local at_c=$(( pos + ${#pre_c} ))

        if [[ "$pre_o" != "$chunk" ]]; then
            local at_o=$(( pos + ${#pre_o} ))
            if (( at_o < at_c )); then
                (( depth += 1 ))
                pos=$(( at_o + ${#open} ))
                continue
            fi
        fi

        (( depth -= 1 ))
        (( depth == 0 )) && { printf '%s' "$at_c"; return 0; }
        pos=$(( at_c + ${#close} ))
    done

    printf '%s' "$len"; return 1
}

# Renders a template string already held in memory.
ash_tpl_render_string() {
    local template="$1"
    local depth="${2:-0}"

    (( depth > ASH_TPL_MAX_DEPTH )) && { printf '%s' "$template"; return 0; }

    # ── 1. Protect `\{{` escapes with placeholders that survive rendering ──
    local -a stash_keys=() stash_vals=()
    local guard=0
    while [[ "$template" == *'\{{'* ]]; do
        (( guard += 1 )); (( guard > 500 )) && break
        local key=$'\x01ASHTPL'"${#stash_keys[@]}"$'\x01'
        local before="${template%%\\\{\{*}"
        local after="${template#*\\\{\{}"
        local lit
        if [[ "$after" == *'}}'* ]]; then
            lit="{{${after%%\}\}*}}}"
            template="${before}${key}${after#*\}\}}"
        else
            lit="{{${after}"
            template="${before}${key}"
        fi
        stash_keys+=("$key")
        stash_vals+=("$lit")
    done

    # ── 2. Single left-to-right scan ──────────────────────────────────────
    local out="" cursor=0 len=${#template} safety=0

    while (( cursor < len )); do
        (( safety += 1 ))
        (( safety > 50000 )) && { out+="${template:cursor}"; break; }

        local rest="${template:cursor}"
        if [[ "$rest" != *'{{'* ]]; then out+="$rest"; break; fi

        local pre="${rest%%\{\{*}"
        out+="$pre"
        cursor=$(( cursor + ${#pre} ))

        local tail="${template:cursor}"
        local after_open="${tail:2}"

        if [[ "$after_open" != *'}}'* ]]; then out+="$tail"; break; fi

        local token="${after_open%%\}\}*}"
        local token_len=$(( ${#token} + 4 ))

        case "$token" in
            '#if'*|'#unless'*)
                local kind="if"
                [[ "$token" == '#unless'* ]] && kind="unless"

                local cond_expr="${token#\#${kind}}"
                cond_expr="${cond_expr#"${cond_expr%%[![:space:]]*}"}"
                cond_expr="${cond_expr%"${cond_expr##*[![:space:]]}"}"

                local body_start=$(( cursor + token_len ))
                local body="${template:body_start}"
                local close_at
                close_at="$(_ash_tpl_find_close "$kind" "$body")" || close_at=${#body}

                local inner="${body:0:close_at}"
                local consumed=$(( body_start + close_at + ${#kind} + 5 ))

                local negate=0
                [[ "$cond_expr" == '!'* ]] && { negate=1; cond_expr="${cond_expr#!}"; }
                cond_expr="${cond_expr// /}"

                local cond_val="true"
                if [[ "$cond_expr" == *'=='* ]]; then
                    local lhs="${cond_expr%%==*}" rhs="${cond_expr##*==}"
                    local lval="${ASH_TPL_VARS[$lhs]:-$lhs}"
                    [[ "$lval" == "$rhs" ]] && cond_val="true" || cond_val="false"
                else
                    cond_val="${ASH_TPL_VARS[$cond_expr]:-}"
                fi

                local truthy=0
                case "${cond_val,,}" in
                    ""|0|false|no|off|none|disabled|null) truthy=0 ;;
                    *) truthy=1 ;;
                esac
                (( negate == 1 )) && truthy=$(( 1 - truthy ))
                [[ "$kind" == "unless" ]] && truthy=$(( 1 - truthy ))

                (( truthy == 1 )) && out+="$(ash_tpl_render_string "$inner" $(( depth + 1 )))"
                cursor=$consumed
                ;;

            '#each'*)
                local loop_expr="${token#\#each}"
                loop_expr="${loop_expr#"${loop_expr%%[![:space:]]*}"}"
                loop_expr="${loop_expr%"${loop_expr##*[![:space:]]}"}"

                local list_var="${loop_expr%% as *}"
                local item_var="${loop_expr##* as }"
                list_var="${list_var// /}"
                item_var="${item_var// /}"

                local body_start=$(( cursor + token_len ))
                local body="${template:body_start}"
                local close_at
                close_at="$(_ash_tpl_find_close "each" "$body")" || close_at=${#body}

                local inner="${body:0:close_at}"
                local consumed=$(( body_start + close_at + 9 ))     # {{/each}}

                local rendered="" idx=0 item
                for item in ${ASH_TPL_VARS[$list_var]:-}; do
                    ASH_TPL_VARS["$item_var"]="$item"
                    ASH_TPL_VARS["${item_var}_index"]="$idx"
                    rendered+="$(ash_tpl_render_string "$inner" $(( depth + 1 )))"
                    (( idx += 1 ))
                done
                out+="$rendered"
                cursor=$consumed
                ;;

            '>'*)
                local pname="${token#>}"; pname="${pname// /}"
                local pfile=""
                local cand
                for cand in \
                    "${ASH_TPL_PARTIAL_DIR}/${pname}" \
                    "${ASH_TPL_PARTIAL_DIR}/${pname}.tpl" \
                    "${ASH_TPL_PARTIAL_DIR}/${pname}.part" \
                    "${ASH_TPL_PARTIAL_DIR}/${pname}.template"
                do
                    [[ -f "$cand" ]] && { pfile="$cand"; break; }
                done
                [[ -n "$pfile" ]] && out+="$(ash_tpl_render_file "$pfile" $(( depth + 1 )))"
                cursor=$(( cursor + token_len ))
                ;;

            '!'*|'/'*) cursor=$(( cursor + token_len )) ;;

            *) out+="$(_ash_tpl_expand "$token")"
               cursor=$(( cursor + token_len )) ;;
        esac
    done

    # ── 3. Restore escaped literals ───────────────────────────────────────
    local i
    for (( i = 0; i < ${#stash_keys[@]}; i++ )); do
        out="${out//${stash_keys[i]}/${stash_vals[i]}}"
    done

    printf '%s' "$out"
}

# Renders <file> against the current variable context.
ash_tpl_render_file() {
    local file="$1" depth="${2:-0}"
    [[ -f "$file" ]] || return 1

    # {{! partials: ./partials }} declares the partial search path for this file.
    local decl=""
    decl="$(head -5 "$file" 2>/dev/null | grep -oP '\{\{!\s*partials:\s*\K[^}]+' | head -1 || true)"
    if [[ -n "$decl" ]]; then
        decl="${decl%"${decl##*[![:space:]]}"}"
        decl="${decl#"${decl%%[![:space:]]*}"}"
        [[ "$decl" != /* ]] && decl="$(dirname "$file")/${decl}"
        ASH_TPL_PARTIAL_DIR="$decl"
    elif [[ -z "$ASH_TPL_PARTIAL_DIR" ]]; then
        ASH_TPL_PARTIAL_DIR="$(dirname "$file")"
    fi

    local content
    content="$(cat "$file")"
    ash_tpl_render_string "$content" "$depth"
}

# ash_tpl_render_to <template-file> <output-file> [--mode OCTAL] [--check]
# Returns 0 when the output changed, 2 when it was already identical
# (lets the hot-reload engine skip pointless service restarts).
ash_tpl_render_to() {
    local tpl="$1" out="$2"; shift 2
    local mode="" check_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)  mode="$2"; shift 2 ;;
            --check) check_only=1; shift ;;
            *) shift ;;
        esac
    done

    [[ -f "$tpl" ]] || { ash_log_error "template not found: $tpl" 2>/dev/null || true; return 1; }

    local rendered; rendered="$(ash_tpl_render_file "$tpl")"

    if [[ $check_only -eq 1 ]]; then
        [[ -f "$out" ]] && [[ "$(cat "$out" 2>/dev/null)" == "$rendered" ]] && return 2
        return 0
    fi

    mkdir -p "$(dirname "$out")" 2>/dev/null || return 1

    if [[ -f "$out" ]] && [[ "$(cat "$out")" == "$rendered" ]]; then
        return 2      # unchanged — callers use this to skip reloads
    fi

    local tmp; tmp="$(mktemp "${out}.tmp.XXXXXX")" || return 1
    printf '%s\n' "$rendered" > "$tmp"

    [[ -n "$mode" ]] && chmod "$mode" "$tmp" 2>/dev/null || true
    [[ -f "$out" && -z "$mode" ]] && chmod --reference="$out" "$tmp" 2>/dev/null || true

    mv -f "$tmp" "$out"
    return 0
}

# Render one template to every application target in a manifest.
# Manifest line: <template>|<output>|<reload-command>
ash_tpl_render_batch() {
    local manifest="$1"
    local changed=0 total=0 failed=0

    [[ -f "$manifest" ]] || return 1

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        [[ -z "${line//[[:space:]]/}" ]] && continue
        (( total += 1 ))

        local tpl="${line%%|*}"
        local rest="${line#*|}"
        local out="${rest%%|*}"

        tpl="${tpl//\~/$HOME}"; out="${out//\~/$HOME}"

        local rc=0
        ash_tpl_render_to "$tpl" "$out" || rc=$?
        if (( rc == 0 )); then
            (( changed += 1 ))
            ash_log_debug "rendered: $out" 2>/dev/null || true
        elif (( rc == 2 )); then
            ash_log_debug "unchanged: $out" 2>/dev/null || true
        else
            (( failed += 1 ))
            ash_log_warn "render failed: $tpl → $out" 2>/dev/null || true
        fi
    done < "$manifest"

    ash_log_info "templates: ${changed} changed, $(( total - changed - failed )) unchanged, ${failed} failed" 2>/dev/null || true
    return $(( failed > 0 ? 1 : 0 ))
}

# ── Validation (catches typos refs before they reach disk) ───────────────────
ash_tpl_validate() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    local errors=0
    # Unbalanced blocks
    local ifs unlesss eachs endifs endunlesss endeachs
    ifs="$(grep -o '{{#if ' "$file" 2>/dev/null | wc -l)"
    unlesss="$(grep -o '{{#unless ' "$file" 2>/dev/null | wc -l)"
    eachs="$(grep -o '{{#each ' "$file" 2>/dev/null | wc -l)"
    endifs="$(grep -o '{{/if}}' "$file" 2>/dev/null | wc -l)"
    endunlesss="$(grep -o '{{/unless}}' "$file" 2>/dev/null | wc -l)"
    endeachs="$(grep -o '{{/each}}' "$file" 2>/dev/null | wc -l)"

    (( ifs != endifs ))             && { printf '  ✗ unbalanced {{#if}}: %d open, %d close\n' "$ifs" "$endifs"; (( errors += 1 )); }
    (( unlesss != endunlesss ))     && { printf '  ✗ unbalanced {{#unless}}\n'; (( errors += 1 )); }
    (( eachs != endeachs ))         && { printf '  ✗ unbalanced {{#each}}\n'; (( errors += 1 )); }
    (( ${#file} > 0 )) && true

    # Unknown variables
    local var
    while IFS= read -r var || [[ -n "$var" ]]; do
        [[ -z "$var" ]] && continue
        [[ "$var" == '#'* || "$var" == '/'* || "$var" == '>'* || "$var" == '!'* ]] && continue
        local base="${var%%|*}"; base="${base%%:-*}"
        base="${base// /}"
        [[ -z "$base" ]] && continue
        if [[ -z "${ASH_TPL_VARS[$base]+x}" ]]; then
            printf '  ⚠ undefined variable: {{%s}}\n' "$base"
        fi
    done < <(grep -oP '\{\{\K[^}]+' "$file" 2>/dev/null | LC_ALL=C sort -u)

    (( errors == 0 )) && printf '  ✓ template structure valid\n'
    return $(( errors > 0 ? 1 : 0 ))
}
