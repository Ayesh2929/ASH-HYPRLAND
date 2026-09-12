#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  🎁 ASH BOX RENDERER — panels, banners, progress boxes, gradients             ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_BOX_RENDERER_LOADED:-}" ]] && return 0
readonly _ASH_BOX_RENDERER_LOADED=1
readonly ASH_BOX_VERSION="5.0.0"

declare -gA ASH_BOX_STYLE=(
    [single]="┌ ┐ └ ┘ ─ │"
    [double]="╔ ╗ ╚ ╝ ═ ║"
    [round]="╭ ╮ ╰ ╯ ─ │"
    [heavy]="┏ ┓ ┗ ┛ ━ ┃"
    [dashed]="┌ ┐ └ ┘ ┄ ┆"
    [ascii]="+ + + + - |"
    [blank]="  "        # spaces only — a floating panel
)
declare -g ASH_BOX_DEFAULT_STYLE="round"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  COLOUR HELPERS (independent of lib/colors.sh so this lib stands alone)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_box_fg() {
    local hex="${1#\#}"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    printf '\033[38;2;%d;%d;%dm' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
_ash_box_bg() {
    local hex="${1#\#}"
    (( ${#hex} == 3 )) && hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    printf '\033[48;2;%d;%d;%dm' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
_ash_box_reset() { printf '\033[0m'; }

_ash_box_supports_colour() {
    [[ "${NO_COLOR:-}" != "" ]] && return 1
    [[ "${ASH_FLAG_NO_COLOR:-0}" == "1" ]] && return 1
    [[ -t 1 ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  CORE BOX
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ash_box_w() { ash_table_width "$1"; }
_ash_box_pad() { ash_table_pad "$1" "$2" "${3:-left}"; }
_ash_box_trim() { ash_table_truncate "$1" "$2" "${3:-…}"; }

# ash_box_render <title> <style> [content-lines on stdin]
# Env knobs: ASH_BOX_WIDTH, ASH_BOX_PAD, ASH_BOX_ACCENT (hex)
ash_box_render() {
    local title="${1:-}" style="${2:-$ASH_BOX_DEFAULT_STYLE}"
    local pad="${ASH_BOX_PAD:-2}"
    local width="${ASH_BOX_WIDTH:-0}"
    local accent="${ASH_BOX_ACCENT:-}"

    local -a S
    # Explicit IFS: this is a space-separated string, and a caller that set
    # IFS=$'\n\t' (as mode.sh does) would otherwise get one giant element.
    IFS=' ' read -r -a S <<< "${ASH_BOX_STYLE[$style]:-${ASH_BOX_STYLE[single]}}"
    local TL="${S[0]:-┌}" TR="${S[1]:-┐}" BL="${S[2]:-└}" BR="${S[3]:-┘}" H="${S[4]:-─}" V="${S[5]:-│}"

    # ── Read the body ─────────────────────────────────────────────────────
    local -a lines=()
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do lines+=("$line"); done
    (( ${#lines[@]} == 0 )) && lines=("")

    # ── Determine the inner width ─────────────────────────────────────────
    local content_w=0 w
    for line in "${lines[@]}"; do
        w="$(_ash_box_w "$line")"
        (( w > content_w )) && content_w="$w"
    done
    if [[ -n "$title" ]]; then
        w="$(( $(_ash_box_w "$title") + 4 ))"
        (( w > content_w )) && content_w="$w"
    fi

    local inner=$(( content_w + pad * 2 ))
    if (( width > 0 )); then
        local target=$(( width - 2 ))
        (( target > inner )) && inner=$target
    else
        # Never exceed the terminal
        local term_w; term_w="$(tput cols 2>/dev/null || echo 120)"
        (( inner + 2 > term_w )) && inner=$(( term_w - 2 ))
    fi
    (( inner < 4 )) && inner=4

    local body_w=$(( inner - pad * 2 ))
    (( body_w < 1 )) && body_w=1

    # ── Colour ────────────────────────────────────────────────────────────
    local c="" r=""
    if _ash_box_supports_colour; then
        r="$(_ash_box_reset)"
        [[ -n "$accent" ]] && c="$(_ash_box_fg "$accent")"
    fi

    # ── Top border, with the title embedded ───────────────────────────────
    local hbar; hbar="$(printf '%*s' "$inner" '' | tr ' ' "$H")"
    if [[ -n "$title" ]]; then
        local t; t="$(ash_table_truncate " $title " "$inner")"
        local tw; tw="$(_ash_box_w "$t")"
        local remain=$(( inner - tw ))
        (( remain < 0 )) && remain=0
        local l=$(( remain / 2 )) rr=$(( remain - l ))
        printf '%s%s%s%s%s%s%s%s\n' \
            "$c" "$TL" "$(printf '%*s' "$l" '' | tr ' ' "$H")" "$t" \
            "$(printf '%*s' "$rr" '' | tr ' ' "$H")" "$TR" "$r" ""
    else
        printf '%s%s%s%s%s\n' "$c" "$TL" "$hbar" "$TR" "$r"
    fi

    # ── Body ──────────────────────────────────────────────────────────────
    local padding; padding="$(printf '%*s' "$pad" '')"
    for line in "${lines[@]}"; do
        local cell; cell="$(ash_table_truncate "$line" "$body_w")"
        local padded; padded="$(_ash_box_pad "$cell" "$body_w")"
        printf '%s%s%s%s%s%s\n' "$c" "$V" "$r$padding" "$padded$padding" "$c$V" "$r"
    done

    # ── Bottom border ─────────────────────────────────────────────────────
    printf '%s%s%s%s%s\n' "$c" "$BL" "$hbar" "$BR" "$r"
}

# Convenience wrappers -------------------------------------------------------
# ── Manual box primitives ─────────────────────────────────────────────────────
#
# ash_box_render takes a title and reads its body from stdin. Sometimes the
# caller needs to interleave its own content between the border rows instead —
# mode.sh draws a banner whose middle rows come from ModeIcon tables and
# coloured segments — so it needs the pieces rather than the assembled box:
#
#     ash_box_top    86
#     ash_box_row    86 "  🎮🎯🎬 ASH DOTFILES v5.0 OMEGA — MODE ENGINE"
#     ash_box_row    86 "  Desktop Environment Mode Switching System"
#     ash_box_bottom 86
#
# Width is the TOTAL width including both border columns. Content is padded (or
# trimmed with an ellipsis) to the inner width so the right border stays flush —
# the same guarantee ash_box_render gives, applied row by row.
_ash_box_chars() {
    local style="${1:-$ASH_BOX_DEFAULT_STYLE}"
    printf '%s' "${ASH_BOX_STYLE[$style]:-${ASH_BOX_STYLE[single]}}"
}

# ash_box_top [width] [style]
ash_box_top() {
    local width="${1:-${ASH_BOX_WIDTH:-80}}" style="${2:-$ASH_BOX_DEFAULT_STYLE}"
    # IFS is set explicitly: the caller may have redefined it (mode.sh uses
    # IFS=$'\n\t'), and without this the whole style string lands in C[0] and
    # every later index is unbound.
    local -a C
    IFS=' ' read -r -a C <<< "$(_ash_box_chars "$style")"

    local inner=$(( width - 2 ))
    (( inner < 1 )) && inner=1

    local rule="" i
    for (( i = 0; i < inner; i++ )); do rule+="${C[4]}"; done

    printf '%s%s%s' "${C[0]}" "$rule" "${C[1]}"
}

# ash_box_bottom [width] [style]
ash_box_bottom() {
    local width="${1:-${ASH_BOX_WIDTH:-80}}" style="${2:-$ASH_BOX_DEFAULT_STYLE}"
    # IFS is set explicitly: the caller may have redefined it (mode.sh uses
    # IFS=$'\n\t'), and without this the whole style string lands in C[0] and
    # every later index is unbound.
    local -a C
    IFS=' ' read -r -a C <<< "$(_ash_box_chars "$style")"

    local inner=$(( width - 2 ))
    (( inner < 1 )) && inner=1

    local rule="" i
    for (( i = 0; i < inner; i++ )); do rule+="${C[4]}"; done

    printf '%s%s%s' "${C[2]}" "$rule" "${C[3]}"
}

# ash_box_row <width> <content> [style]
ash_box_row() {
    local width="${1:-${ASH_BOX_WIDTH:-80}}" content="${2:-}" style="${3:-$ASH_BOX_DEFAULT_STYLE}"
    # IFS is set explicitly: the caller may have redefined it (mode.sh uses
    # IFS=$'\n\t'), and without this the whole style string lands in C[0] and
    # every later index is unbound.
    local -a C
    IFS=' ' read -r -a C <<< "$(_ash_box_chars "$style")"

    local inner=$(( width - 2 ))
    (( inner < 1 )) && inner=1

    # Measure in display columns, not bytes: the banner carries Nerd Font icons
    # and an emoji, and %-*s would misjudge both, pushing the right border out.
    local padded
    padded="$(ash_table_pad "$content" "$inner" left)"
    padded="$(ash_table_truncate "$padded" "$inner" "…")"

    printf '%s%s%s' "${C[5]}" "$padded" "${C[5]}"
}

ash_box()      { shift 0; ash_box_render "${1:-}" "${2:-$ASH_BOX_DEFAULT_STYLE}"; }

ash_box_title() {
    local title="$1"; shift || true
    printf '%s\n' "$@" | ash_box_render "$title" "$ASH_BOX_DEFAULT_STYLE"
}

ash_box_success() {
    local title="$1"; shift || true
    ASH_BOX_ACCENT="${ASH_COLOR_SUCCESS:-#a6e3a1}" bash -c '
        source /dev/stdin
    ' </dev/null 2>/dev/null || true
    printf '%s\n' "$@" | ASH_BOX_ACCENT="#a6e3a1" ash_box_render "✓ ${title}" "$ASH_BOX_DEFAULT_STYLE"
}

ash_box_error() {
    local title="$1"; shift || true
    printf '%s\n' "$@" | ASH_BOX_ACCENT="#f38ba8" ash_box_render "✗ ${title}" "$ASH_BOX_DEFAULT_STYLE"
}

ash_box_warn() {
    local title="$1"; shift || true
    printf '%s\n' "$@" | ASH_BOX_ACCENT="#f9e2af" ash_box_render "⚠ ${title}" "$ASH_BOX_DEFAULT_STYLE"
}

ash_box_info() {
    local title="$1"; shift || true
    printf '%s\n' "$@" | ASH_BOX_ACCENT="#89b4fa" ash_box_render "ℹ ${title}" "$ASH_BOX_DEFAULT_STYLE"
}

# ── Panels: a side-by-side strip used by the dashboard ───────────────────────
# ash_box_panel <width> <title> <accent-hex> <line…>
ash_box_panel() {
    local width="$1" title="$2" accent="${3:-}"; shift 3 || true
    ASH_BOX_WIDTH="$width" ASH_BOX_ACCENT="$accent" \
        printf '%s\n' "$@" | ASH_BOX_WIDTH="$width" ASH_BOX_ACCENT="$accent" \
        ash_box_render "$title" "round"
}

# ── Banner: the big ASCII wordmark with a gradient sweep ─────────────────────
ash_banner() {
    local text="${1:-ASH}"
    local use_colour=0
    _ash_box_supports_colour && use_colour=1

    local -a rows=(
        " █████╗ ███████╗██╗  ██╗"
        "██╔══██╗██╔════╝██║  ██║"
        "███████║███████╗███████║"
        "██╔══██║╚════██║██╔══██║"
        "██║  ██║███████║██║  ██║"
        "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
    )

    # Catppuccin Mocha gradient: mauve → blue → teal
    local -a grad=("#cba6f7" "#b4befe" "#89b4fa" "#74c7ec" "#89dceb" "#94e2d5")

    local i
    for (( i = 0; i < ${#rows[@]}; i++ )); do
        if [[ $use_colour -eq 1 ]]; then
            printf '%s%s%s\n' "$(_ash_box_fg "${grad[i]}")" "${rows[i]}" "$(_ash_box_reset)"
        else
            printf '%s\n' "${rows[i]}"
        fi
    done

    if [[ $use_colour -eq 1 ]]; then
        printf '%s  %s v%s — THE HYPRLAND ECOSYSTEM%s\n' \
            "$(_ash_box_fg '#6c7086')" "$text" "${ASH_VERSION:-5.0.0-omega}" "$(_ash_box_reset)"
    else
        printf '  %s v%s — THE HYPRLAND ECOSYSTEM\n' "$text" "${ASH_VERSION:-5.0.0-omega}"
    fi
}

# ── Gradient text (used for section headings) ────────────────────────────────
ash_gradient_text() {
    local text="$1"
    local from="${2:-#cba6f7}" to="${3:-#94e2d5}"
    local -a grad=("#cba6f7" "#b4befe" "#89b4fa" "#74c7ec" "#89dceb" "#94e2d5")

    _ash_box_supports_colour || { printf '%s' "$text"; return 0; }

    # If explicit endpoints were supplied, interpolate our own ramp.
    if [[ "$from" != "#cba6f7" || "$to" != "#94e2d5" ]]; then
        local f="${from#\#}" t="${to#\#}"
        local fr=$((16#${f:0:2})) fg=$((16#${f:2:2})) fb=$((16#${f:4:2}))
        local tr=$((16#${t:0:2})) tg=$((16#${t:2:2})) tb=$((16#${t:4:2}))
        local len=${#text} i ch
        for (( i = 0; i < len; i++ )); do
            local pct=$(( i * 100 / (len > 1 ? len - 1 : 1) ))
            local rr=$(( fr + (tr - fr) * pct / 100 ))
            local gg=$(( fg + (tg - fg) * pct / 100 ))
            local bb=$(( fb + (tb - fb) * pct / 100 ))
            ch="${text:i:1}"
            printf '%s%s' "$(_ash_box_fg "$(printf '#%02x%02x%02x' "$rr" "$gg" "$bb")")" "$ch"
        done
        printf '%s' "$(_ash_box_reset)"
        return 0
    fi

    local len=${#text} i
    for (( i = 0; i < len; i++ )); do
        printf '%s%s' "$(_ash_box_fg "${grad[$(( i * ${#grad[@]} / (len > 0 ? len : 1) ))]}")" "${text:i:1}"
    done
    printf '%s' "$(_ash_box_reset)"
}

# ── Section heading ──────────────────────────────────────────────────────────
ash_section() {
    local title="$1"
    if _ash_box_supports_colour; then
        printf '\n  %s%s%s\n' "$(_ash_box_fg '#89b4fa')" "$title" "$(_ash_box_reset)"
        printf '  %s%s%s\n' "$(_ash_box_fg '#45475a')" "$(printf '─%.0s' $(seq 1 56))" "$(_ash_box_reset)"
    else
        printf '\n  %s\n  %s\n' "$title" "$(printf '%.0s-' $(seq 1 56))"
    fi
}

# ── Splash / boot screen ────────────────────────────────────────────────────
ash_splash() {
    local lines=("$@")
    clear 2>/dev/null || true
    printf '\n'
    ash_banner "ASH DOTFILES"
    printf '\n'
    if _ash_box_supports_colour; then
        local i=0 colours=("#cba6f7" "#b4befe" "#89b4fa" "#74c7ec" "#89dceb" "#94e2d5" "#a6e3a1" "#f9e2af")
        local l
        for l in "${lines[@]}"; do
            printf '    %s%s%s\n' "$(_ash_box_fg "${colours[$(( i % ${#colours[@]} ))]}")" "$l" "$(_ash_box_reset)"
            (( i += 1 ))
        done
    else
        local l
        for l in "${lines[@]}"; do printf '    %s\n' "$l"; done
    fi
    printf '\n'
}

# ── Notification toast (transient, non-blocking) ─────────────────────────────
ash_box_toast() {
    local message="$1" kind="${2:-info}" duration="${3:-2}"
    case "$kind" in
        success) ASH_BOX_ACCENT="#a6e3a1" ;;
        error)   ASH_BOX_ACCENT="#f38ba8" ;;
        warn)    ASH_BOX_ACCENT="#f9e2af" ;;
        *)       ASH_BOX_ACCENT="#89b4fa" ;;
    esac

    local term_w; term_w="$(tput cols 2>/dev/null || echo 80)"
    local msg_w=$(( $(_ash_box_w "$message") + 6 ))
    local _unused=$(( term_w - msg_w ))

    printf '%s\n' "$message" | ash_box_render "" "round"

    if [[ "$duration" =~ ^[0-9]+$ ]] && (( duration > 0 )); then
        sleep "$duration"
    fi
}

# ── Divider ──────────────────────────────────────────────────────────────────
ash_divider() {
    local char="${1:-─}" width="${2:-0}"
    (( width == 0 )) && width="$(tput cols 2>/dev/null || echo 80)"
    local line; line="$(printf '%*s' "$width" '' | tr ' ' "$char")"
    if _ash_box_supports_colour; then
        printf '%s%s%s\n' "$(_ash_box_fg '#45475a')" "$line" "$(_ash_box_reset)"
    else
        printf '%s\n' "$line"
    fi
}

# ── Big numeric stat card ───────────────────────────────────────────────────
ash_stat_card() {
    local label="$1" value="$2" unit="${3:-}" delta="${4:-}"
    local accent="${5:-#89b4fa}"

    local top="┌$(printf '─%.0s' $(seq 1 28))┐"
    local bot="└$(printf '─%.0s' $(seq 1 28))┘"

    if _ash_box_supports_colour; then
        local c; c="$(_ash_box_fg "$accent")"; local r; r="$(_ash_box_reset)"
        local dim; dim="$(_ash_box_fg '#6c7086')"
        printf '%s%s%s\n' "$c" "$top" "$r"
        printf '%s│%s %-26s %s│%s\n' "$c" "$r" "$label" "$c" "$r"
        printf '%s│%s %s%-20s%s %-5s %s│%s\n' "$c" "$r" "$c" "$value" "$r" "$unit" "$c" "$r"
        [[ -n "$delta" ]] && printf '%s│%s %s%-26s%s %s│%s\n' "$c" "$r" "$dim" "$delta" "$r" "$c" "$r"
        printf '%s%s%s\n' "$c" "$bot" "$r"
    else
        printf '%s\n│ %-26s │\n│ %-20s %-5s │\n%s\n' "$top" "$label" "$value" "$unit" "$bot"
    fi
}
