#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  💬 ASH PROMPT ENGINE — interactive input that degrades correctly             ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Every prompt here is TTY-aware: when stdin is a pipe (CI, `ash … | tee`),    ║
# ║  the function falls back to the default instead of hanging forever.           ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_PROMPT_LOADED:-}" ]] && return 0
readonly _ASH_PROMPT_LOADED=1
readonly ASH_PROMPT_VERSION="5.0.0"

: "${ASH_PROMPT_ASSUME_YES:=0}"
: "${ASH_PROMPT_ASSUME_NO:=0}"
: "${ASH_PROMPT_NONINTERACTIVE:=0}"

_ash_prompt_interactive() {
    [[ "${ASH_PROMPT_NONINTERACTIVE:-0}" == "1" ]] && return 1
    [[ -t 0 ]]
}

# ── Colour shortcuts that don't require lib/colors.sh ────────────────────────
_ash_p_color() {
    case "$1" in
        accent) printf '\033[38;2;203;166;247m' ;;
        ok)     printf '\033[38;2;166;227;161m' ;;
        warn)   printf '\033[38;2;249;226;175m' ;;
        err)    printf '\033[38;2;243;139;168m' ;;
        key)    printf '\033[38;2;137;180;250m' ;;
        muted)  printf '\033[38;2;108;112;134m' ;;
        *)      printf '\033[0m' ;;
    esac
}
_ash_p_reset() { printf '\033[0m'; }

_ash_p_supported() {
    [[ "${NO_COLOR:-}" != "" ]] && return 1
    [[ "${ASH_FLAG_NO_COLOR:-0}" == "1" ]] && return 1
    [[ -t 1 ]]
}

# ── 1. Confirm ───────────────────────────────────────────────────────────────
# ash_confirm <question> [default: y|n] [--timeout SEC]
ash_confirm() {
    local question="$1" default="${2:-n}"
    shift 2 || true
    local timeout=0
    while [[ $# -gt 0 ]]; do
        case "$1" in --timeout) timeout="$2"; shift 2 ;; *) shift ;; esac
    done

    [[ "${ASH_PROMPT_ASSUME_YES:-0}" == "1" ]] && return 0
    [[ "${ASH_PROMPT_ASSUME_NO:-0}"  == "1" ]] && return 1

    if ! _ash_prompt_interactive; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi

    local hint="[y/N]"
    [[ "$default" == "y" ]] && hint="[Y/n]"

    local answer=""
    if (( timeout > 0 )); then
        local c; c="$(_ash_p_color accent)"; local r; r="$(_ash_p_reset)"
        _ash_p_supported || { c=""; r=""; }
        printf '%s?%s %s %s(auto-%s in %ss)%s ' "$c" "$r" "$question" "$(_ash_p_color muted)" "$default" "$timeout" "$(_ash_p_reset)" >&2
        if read -r -t "$timeout" answer 2>/dev/null; then :; else
            printf '\n' >&2
            [[ "$default" == "y" ]]
            return $?
        fi
    else
        local c; c="$(_ash_p_color accent)"; local r; r="$(_ash_p_reset)"
        _ash_p_supported || { c=""; r=""; }
        printf '%s?%s %s %s%s%s ' "$c" "$r" "$question" "$c" "$hint" "$r" >&2
        read -r answer || answer=""
    fi

    answer="${answer:-$default}"
    case "${answer,,}" in
        y|yes|true|1|ja|oui|si|sí) return 0 ;;
        *) return 1 ;;
    esac
}

# ── 2. Free-form input ───────────────────────────────────────────────────────
# ash_prompt_input <question> [default] [--validate REGEX] [--required]
ash_prompt_input() {
    local question="$1" default="${2-}"; shift 2 || true
    local validate="" required=0 secret=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --validate) validate="$2"; shift 2 ;;
            --required) required=1; shift ;;
            --secret)   secret=1; shift ;;
            *) shift ;;
        esac
    done

    if ! _ash_prompt_interactive; then
        printf '%s' "$default"
        return $(( required == 1 && -z "$default" ? 1 : 0 ))
    fi

    local c r m
    c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"; m="$(_ash_p_color muted)"
    _ash_p_supported || { c=""; r=""; m=""; }

    local attempt=0 answer=""
    while (( attempt < 3 )); do
        if [[ -n "$default" ]]; then
            printf '%s?%s %s %s[%s]%s ' "$c" "$r" "$question" "$c" "$default" "$r" >&2
        else
            printf '%s?%s %s ' "$c" "$r" "$question" >&2
        fi

        if (( secret == 1 )); then
            read -rs answer || answer=""
            printf '\n' >&2
        else
            read -r answer || answer=""
        fi

        answer="${answer:-$default}"

        if (( required == 1 )) && [[ -z "$answer" ]]; then
            printf '  %s✗ this field is required%s\n' "$(_ash_p_color err)" "$r" >&2
            (( attempt += 1 )); continue
        fi

        if [[ -n "$validate" && -n "$answer" ]]; then
            if [[ ! "$answer" =~ $validate ]]; then
                printf '  %s✗ value does not match %s%s\n' "$(_ash_p_color err)" "$validate" "$r" >&2
                (( attempt += 1 )); continue
            fi
        fi

        printf '%s' "$answer"
        return 0
    done

    printf '%s' "$answer"
    return 1
}

# ── 3. Single-select menu ────────────────────────────────────────────────────
# ash_prompt_select <question> <option…>
# Options may be "value|label|description". Prints the chosen *value*.
ash_prompt_select() {
    local question="$1"; shift
    local -a options=("$@")

    if (( ${#options[@]} == 0 )); then return 1; fi

    # Non-interactive: first option wins.
    if ! _ash_prompt_interactive; then
        printf '%s' "${options[0]%%|*}"
        return 0
    fi

    local c r m k
    c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"
    m="$(_ash_p_color muted)";  k="$(_ash_p_color key)"
    _ash_p_supported || { c=""; r=""; m=""; k=""; }

    printf '\n%s?%s %s\n' "$c" "$r" "$question" >&2

    local i=1 opt value label desc
    for opt in "${options[@]}"; do
        value="${opt%%|*}"
        local rest="${opt#*|}"
        if [[ "$rest" == "$opt" ]]; then label="$value"; desc=""
        else label="${rest%%|*}"; desc="${rest#*|}"; [[ "$desc" == "$label" ]] && desc=""; fi
        printf '  %s%2d)%s %s' "$k" "$i" "$r" "$label" >&2
        [[ -n "$desc" ]] && printf '  %s%s%s' "$m" "$desc" "$r" >&2
        printf '\n' >&2
        (( i += 1 ))
    done

    local answer=""
    while :; do
        printf '%s  choice [1-%d]%s (or "q" to cancel): ' "$k" "${#options[@]}" "$r" >&2
        read -r answer || answer="q"

        [[ "${answer,,}" == "q" ]] && return 1

        if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#options[@]} )); then
            local chosen="${options[$(( answer - 1 ))]}"
            printf '%s' "${chosen%%|*}"
            return 0
        fi

        printf '  %s✗ enter a number between 1 and %d%s\n' "$(_ash_p_color err)" "${#options[@]}" "$r" >&2
    done
}

# ── 4. Multi-select ──────────────────────────────────────────────────────────
# ash_prompt_multi_select <question> <option…>
# Accepts "1,3-5,8". Prints one chosen value per line.
ash_prompt_multi_select() {
    local question="$1"; shift
    local -a options=("$@")

    if ! _ash_prompt_interactive; then
        local opt
        for opt in "${options[@]}"; do printf '%s\n' "${opt%%|*}"; done
        return 0
    fi

    local c r m k
    c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"
    m="$(_ash_p_color muted)";  k="$(_ash_p_color key)"
    _ash_p_supported || { c=""; r=""; m=""; k=""; }

    printf '\n%s?%s %s %s(comma-separated, ranges ok: 1,3-5)%s\n' "$c" "$r" "$question" "$m" "$r" >&2

    local i=1 opt
    for opt in "${options[@]}"; do
        local value="${opt%%|*}"; local rest="${opt#*|}"
        local label="$value"; [[ "$rest" != "$opt" ]] && label="${rest%%|*}"
        printf '  %s%2d)%s %s\n' "$k" "$i" "$r" "$label" >&2
        (( i += 1 ))
    done

    printf '%s  selection%s ("all" or "none"): ' "$k" "$r" >&2
    local answer=""
    read -r answer || answer="none"

    if [[ "${answer,,}" == "all" ]]; then
        for opt in "${options[@]}"; do printf '%s\n' "${opt%%|*}"; done
        return 0
    fi
    [[ "${answer,,}" == "none" || -z "$answer" ]] && return 1

    local -a picked=()
    local IFS_SAVE="${IFS-}"
    IFS=',' read -r -a tokens <<< "$answer"
    IFS="$IFS_SAVE"

    local token
    for token in "${tokens[@]}"; do
        token="${token// /}"
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local lo="${BASH_REMATCH[1]}" hi="${BASH_REMATCH[2]}"
            (( lo > hi )) && { local tmp="$lo"; lo="$hi"; hi="$tmp"; }
            local n
            for (( n = lo; n <= hi; n++ )); do
                (( n >= 1 && n <= ${#options[@]} )) && picked+=("$n")
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            (( token >= 1 && token <= ${#options[@]} )) && picked+=("$token")
        fi
    done

    (( ${#picked[@]} == 0 )) && return 1

    local idx
    for idx in $(printf '%s\n' "${picked[@]}" | LC_ALL=C sort -n -u); do
        printf '%s\n' "${options[$(( idx - 1 ))]%%|*}"
    done
    return 0
}

# ── 5. Fuzzy picker (fzf with a select(1) fallback) ──────────────────────────
# Reads candidate lines on stdin, prints the chosen one.
ash_prompt_fuzzy() {
    local prompt="${1:-Select}"
    local preview="${2:-}"

    if command -v fzf >/dev/null 2>&1 && _ash_prompt_interactive; then
        local -a args=(
            --height=60% --layout=reverse --border=rounded
            --prompt="${prompt} ❯ " --pointer="▶" --marker="✓"
            --color="bg+:-1,fg+:#cdd6f4,hl:#f5c2e7,fg:#6c7086,header:#f9e2af,prompt:#cba6f7,pointer:#f5c2e7,marker:#a6e3a1,spinner:#f5c2e7,info:#cba6f7,border:#313244"
        )
        [[ -n "$preview" ]] && args+=(--preview "$preview" --preview-window=right:55%:rounded)
        fzf "${args[@]}"
        return $?
    fi

    # Fallback: numbered select built on pure bash.
    local -a items=()
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do items+=("$line"); done
    (( ${#items[@]} == 0 )) && return 1

    # Non-interactive or huge list → grep-based filter
    if ! _ash_prompt_interactive || (( ${#items[@]} > 200 )); then
        printf '%s\n' "${items[0]}"
        return 0
    fi

    local c r k m
    c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"; k="$(_ash_p_color key)"; m="$(_ash_p_color muted)"
    _ash_p_supported || { c=""; r=""; k=""; m=""; }

    printf '%s?%s %s\n' "$c" "$r" "$prompt" >&2
    local i
    for (( i = 0; i < ${#items[@]}; i++ )); do
        printf '  %s%2d)%s %s\n' "$k" "$(( i + 1 ))" "$r" "${items[i]}" >&2
    done
    printf '%s  filter (substring, empty = all):%s ' "$k" "$r" >&2
    local filter=""; read -r filter || filter=""

    local -a matched=()
    for (( i = 0; i < ${#items[@]}; i++ )); do
        if [[ -z "$filter" || "${items[i],,}" == *"${filter,,}"* ]]; then
            matched+=("$i")
        fi
    done
    (( ${#matched[@]} == 0 )) && { printf '  no matches\n' >&2; return 1; }

    if (( ${#matched[@]} == 1 )); then
        printf '%s' "${items[${matched[0]}]}"
        return 0
    fi

    printf '%s  index [1-%d]:%s ' "$k" "${#matched[@]}" "$r" >&2
    local sel=""; read -r sel || sel="1"
    [[ "$sel" =~ ^[0-9]+$ ]] || sel=1
    (( sel < 1 || sel > ${#matched[@]} )) && sel=1

    printf '%s' "${items[${matched[$(( sel - 1 ))]}]}"
}

# ── 6. Progress-aware prompt ─────────────────────────────────────────────────
# Runs <command> while showing a spinner, then asks a follow-up.
ash_prompt_with_spinner() {
    local message="$1"; shift
    if declare -f ash_spinner >/dev/null 2>&1; then
        ash_spinner "$message" -- "$@"
    else
        printf '  %s …\n' "$message" >&2
        "$@"
    fi
}

# ── 7. Menu loop (returns to the menu until Quit) ────────────────────────────
# ash_prompt_menu <title> <handler-function> <entry…>
# Each entry is "key|label|description"; the handler receives the key.
ash_prompt_menu() {
    local title="$1" handler="$2"; shift 2
    local -a entries=("$@")

    while :; do
        local c r m
        c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"; m="$(_ash_p_color muted)"
        _ash_p_supported || { c=""; r=""; m=""; }

        printf '\n%s── %s %s%s\n\n' "$c" "$title" "$(printf '─%.0s' $(seq 1 40))" "$r"

        local -a options=()
        local entry
        for entry in "${entries[@]}"; do
            local key="${entry%%|*}" rest="${entry#*|}"
            local label="${rest%%|*}" desc="${rest#*|}"
            [[ "$desc" == "$label" ]] && desc=""
            printf '  %s%-4s%s %s' "$(_ash_p_color key)" "$key" "$r" "$label"
            [[ -n "$desc" ]] && printf '  %s%s%s' "$m" "$desc" "$r"
            printf '\n'
            options+=("$key")
        done
        printf '  %s%-4s%s %s\n' "$(_ash_p_color key)" "q" "$r" "Quit"

        printf '\n%s  ❯ %s' "$c" "$r"
        local choice=""; read -r choice || choice="q"

        [[ "${choice,,}" == "q" || -z "$choice" ]] && return 0

        if declare -f "$handler" >/dev/null 2>&1; then
            "$handler" "$choice" || true
        else
            printf '  %s✗ unknown action: %s%s\n' "$(_ash_p_color err)" "$choice" "$r"
        fi
    done
}

# ── 8. Password ──────────────────────────────────────────────────────────────
ash_prompt_password() {
    local prompt="${1:-Password: }"
    local confirm="${2:-0}"
    local c r; c="$(_ash_p_color accent)"; r="$(_ash_p_reset)"
    _ash_p_supported || { c=""; r=""; }

    ! _ash_prompt_interactive && return 1

    local pw1="" pw2=""
    printf '%s%s%s' "$c" "$prompt" "$r" >&2
    read -rs pw1; printf '\n' >&2

    if [[ "$confirm" == "1" ]]; then
        printf '%sConfirm:%s ' "$c" "$r" >&2
        read -rs pw2; printf '\n' >&2
        [[ "$pw1" != "$pw2" ]] && { printf '  %s✗ passwords do not match%s\n' "$(_ash_p_color err)" "$r" >&2; return 1; }
    fi

    printf '%s' "$pw1"
}

# ── 9. Path picker with tab-completion-ish validation ────────────────────────
ash_prompt_path() {
    local question="$1" default="${2:-$PWD}" must_exist="${3:-0}"

    local answer
    answer="$(ash_prompt_input "$question" "$default" --validate '^.+$')" || return 1
    answer="${answer/#\~/$HOME}"

    if [[ "$must_exist" == "1" && ! -e "$answer" ]]; then
        printf '  %s✗ path does not exist: %s%s\n' "$(_ash_p_color err)" "$answer" "$(_ash_p_reset)" >&2
        return 1
    fi
    printf '%s' "$answer"
}
