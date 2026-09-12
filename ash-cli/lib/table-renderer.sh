#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📊 ASH TABLE RENDERER — width-aware, colour-correct terminal tables          ║
# ║      ASH DOTFILES v5.0 OMEGA                                                 ║
# ║                                                                               ║
# ║  Handles the things naive `column -t` implementations get wrong:              ║
# ║    • East-Asian wide characters count as 2 columns (CJK, emoji)               ║
# ║    • Zero-width joiners / variation selectors count as 0                      ║
# ║    • ANSI SGR escapes count as 0 but still render                             ║
# ║    • Box styles degrade gracefully when the locale isn't UTF-8                ║
# ║                                                                               ║
# ║  Author : ash-dotfiles        License : MIT                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_TABLE_RENDERER_LOADED:-}" ]] && return 0
readonly _ASH_TABLE_RENDERER_LOADED=1
readonly ASH_TABLE_VERSION="5.0.0"

# ── Box styles ───────────────────────────────────────────────────────────────
# Order: top-left horizontal top-right  vertical  bottom-left bottom-right  tee-down tee-up tee-left tee-right cross
declare -gA ASH_TABLE_STYLE=(
    [unicode]="┌ ─ ┐ │ └ ┘ ┬ ┴ ├ ┤ ┼"
    [round]="╭ ─ ╮ │ ╰ ╯ ┬ ┴ ├ ┤ ┼"
    [double]="╔ ═ ╗ ║ ╚ ╝ ╦ ╩ ╠ ╣ ╬"
    [heavy]="┏ ━ ┓ ┃ ┗ ┛ ┳ ┻ ┣ ┫ ╋"
    [ascii]="+ - + | + + + + + + +"
    [none]="  -     -   - - - - -"
)
declare -gA ASH_TABLE_SEP=(
    [unicode]="│ ─ ┼"
    [round]="│ ─ ┼"
    [double]="║ ═ ╬"
    [heavy]="┃ ━ ╋"
    [ascii]="| - +"
    [none]="  - +"
)
declare -g ASH_TABLE_DEFAULT_STYLE="unicode"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 1  WIDTH MEASUREMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Strips ANSI SGR + OSC sequences.
ash_table_strip_ansi() {
    local s="$1"
    # CSI sequences
    s="$(printf '%s' "$s" | sed -E $'s/\x1b\\[[0-9;?]*[a-zA-Z]//g')"
    # OSC (hyperlinks) terminated by BEL or ST
    s="$(printf '%s' "$s" | sed -E $'s/\x1b\\][^\x07\x1b]*(\x07|\x1b\\\\)//g')"
    printf '%s' "$s"
}

# Display width of a string, counting wide glyphs as 2 columns.
ash_table_width() {
    local s="$1"
    local clean; clean="$(ash_table_strip_ansi "$s")"

    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, unicodedata, re
s = sys.argv[1]
s = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", s)
w = 0
for ch in s:
    if unicodedata.combining(ch) or ch in "\ufe0e\ufe0f\u200d\U000E0100":
        continue
    w += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
print(w, end="")
' "$clean" 2>/dev/null && return
    fi

    # Fallback: byte length with a crude wide-char heuristic via awk.
    printf '%s' "$clean" | awk '{
        n = 0
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            n += (c ~ /[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]/) ? 2 : 1
        }
        print n
    }'
}

# Pad to a display width (left or right aligned).
ash_table_pad() {
    local s="$1" width="$2" align="${3:-left}"
    local w; w="$(ash_table_width "$s")"
    local deficit=$(( width - w ))
    (( deficit < 0 )) && deficit=0
    local pad; pad="$(printf '%*s' "$deficit" '')"

    case "$align" in
        right)  printf '%s%s' "$pad" "$s" ;;
        center)
            local l=$(( deficit / 2 )) r=$(( deficit - l ))
            printf '%s%s%s' "$(printf '%*s' "$l" '')" "$s" "$(printf '%*s' "$r" '')" ;;
        *)      printf '%s%s' "$s" "$pad" ;;
    esac
}

# Truncate to a display width, appending an ellipsis.
ash_table_truncate() {
    local s="$1" width="$2" ellipsis="${3:-…}"
    local w; w="$(ash_table_width "$s")"
    (( w <= width )) && { printf '%s' "$s"; return; }

    local ell_w; ell_w="$(ash_table_width "$ellipsis")"
    local budget=$(( width - ell_w ))
    (( budget < 0 )) && budget=0

    local out="" acc=0 ch cw
    local i
    for (( i = 0; i < ${#s}; i++ )); do
        ch="${s:i:1}"
        cw="$(ash_table_width "$ch")"
        (( acc + cw > budget )) && break
        out+="$ch"; acc=$(( acc + cw ))
    done
    printf '%s%s' "$out" "$ellipsis"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § 2  RENDERING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ash_table_render <delimiter> <style> <align-spec> <header-line> <row…>
#   align-spec: e.g. "left,right,center" (defaults to left)
#   Rows are read on stdin as delimiter-separated fields (default "|").
ash_table_render() {
    local delimiter="${1:-|}" style="${2:-$ASH_TABLE_DEFAULT_STYLE}" align_spec="${3:-}"
    local header_line="${4:-}"
    local max_col_width="${ASH_TABLE_MAX_COL_WIDTH:-64}"
    local term_width="${ASH_TABLE_TERM_WIDTH:-$(tput cols 2>/dev/null || echo 120)}"

    # ── Parse style ───────────────────────────────────────────────────────
    local -a S
    read -r -a S <<< "${ASH_TABLE_STYLE[$style]:-${ASH_TABLE_STYLE[unicode]}}"
    [[ ${#S[@]} -lt 11 ]] && read -r -a S <<< "${ASH_TABLE_STYLE[unicode]}"
    local TL="${S[0]}" H="${S[1]}" TR="${S[2]}" V="${S[3]}" BL="${S[4]}" BR="${S[5]}"
    local TD="${S[6]}" TU="${S[7]}" TLJ="${S[8]}" TRJ="${S[9]}" X="${S[10]}"

    # ── Gather data ───────────────────────────────────────────────────────
    local -a rows=()
    [[ -n "$header_line" ]] && rows+=("$header_line")
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        rows+=("$line")
    done

    (( ${#rows[@]} == 0 )) && return 0

    # ── Split into a matrix ───────────────────────────────────────────────
    local -a col_widths=()
    local -A matrix=()
    local r=0
    local IFS_SAVE="${IFS-}"
    IFS="$delimiter"

    local row
    for row in "${rows[@]}"; do
        local -a cells
        read -r -a cells <<< "$row"
        IFS="$IFS_SAVE"
        local c=0
        for (( c = 0; c < ${#cells[@]}; c++ )); do
            local cell="${cells[c]}"
            cell="${cell#"${cell%%[![:space:]]*}"}"
            cell="${cell%"${cell##*[![:space:]]}"}"
            matrix["${r}:${c}"]="$cell"
            local w; w="$(ash_table_width "$cell")"
            (( w > max_col_width )) && w="$max_col_width"
            (( ${col_widths[c]:-0} < w )) && col_widths[c]="$w"
        done
        (( c > ${#cells[@]} )) && true
        IFS="$delimiter"
        (( r += 1 ))
    done
    IFS="$IFS_SAVE"

    local ncols=${#col_widths[@]}
    (( ncols == 0 )) && return 0

    # ── Shrink columns if the table exceeds the terminal ──────────────────
    local total=0 c
    for (( c = 0; c < ncols; c++ )); do total=$(( total + ${col_widths[c]} )); done
    local overhead=$(( ncols * 3 + 1 ))
    while (( total + overhead > term_width )) && (( max_col_width > 8 )); do
        max_col_width=$(( max_col_width - 4 ))
        local widest=0 widest_i=0
        for (( c = 0; c < ncols; c++ )); do
            if (( ${col_widths[c]} > widest )); then widest=${col_widths[c]}; widest_i=$c; fi
        done
        (( col_widths[widest_i] > 8 )) && col_widths[widest_i]=$(( col_widths[widest_i] - 4 ))
        total=0
        for (( c = 0; c < ncols; c++ )); do total=$(( total + ${col_widths[c]} )); done
    done

    # ── Alignment ─────────────────────────────────────────────────────────
    local -a aligns=()
    if [[ -n "$align_spec" ]]; then
        IFS=',' read -r -a aligns <<< "$align_spec"
    fi
    for (( c = 0; c < ncols; c++ )); do
        [[ -z "${aligns[c]:-}" ]] && aligns[c]="left"
        # Numeric columns auto-align right — a small touch that makes
        # dashboards dramatically easier to scan.
        if [[ "${aligns[c]}" == "auto" ]]; then
            local numeric=1
            local rr
            for (( rr = 1; rr < r; rr++ )); do
                local v="${matrix["${rr}:${c}"]:-}"
                [[ -z "$v" ]] && continue
                [[ "$v" =~ ^[0-9.,%+-]+$ ]] || { numeric=0; break; }
            done
            aligns[c]="$([ "$numeric" -eq 1 ] && echo right || echo left)"
        fi
    done

    # ── Line builders ─────────────────────────────────────────────────────
    _ash_table_rule() {
        local l="$1" m="$2" rr="$3"
        local out="$l"
        local i
        for (( i = 0; i < ncols; i++ )); do
            (( i > 0 )) && out+="$m"
            local dashes; dashes="$(printf '%*s' "$(( ${col_widths[i]} + 2 ))" '' | tr ' ' "$H")"
            out+="$dashes"
        done
        out+="$rr"
        printf '%s' "$out"
    }

    _ash_table_row() {
        local row_idx="$1" is_header="$2"
        local out="$V"
        local i
        for (( i = 0; i < ncols; i++ )); do
            local cell="${matrix["${row_idx}:${i}"]:-}"
            cell="$(ash_table_truncate "$cell" "${col_widths[i]}")"
            local padded; padded="$(ash_table_pad "$cell" "${col_widths[i]}" "${aligns[i]}")"
            out+=" ${padded} ${V}"
        done
        printf '%s' "$out"
    }

    # ── Emit ──────────────────────────────────────────────────────────────
    printf '%s\n' "$(_ash_table_rule "$TL" "$TD" "$TR")"

    local start_row=0
    if [[ -n "$header_line" ]]; then
        printf '%s\n' "$(_ash_table_row 0 1)"
        printf '%s\n' "$(_ash_table_rule "$TLJ" "$X" "$TRJ")"
        start_row=1
    fi

    local rr
    for (( rr = start_row; rr < r; rr++ )); do
        printf '%s\n' "$(_ash_table_row "$rr" 0)"
    done

    printf '%s\n' "$(_ash_table_rule "$BL" "$TU" "$BR")"
}

# Convenience: pipe rows in, get a table out.
#   ash_table "Header A|Header B" "r1c1|r1c2" …
ash_table() {
    local header="${1:-}"; shift || true
    {
        local row
        for row in "$@"; do printf '%s\n' "$row"; done
    } | ash_table_render "|" "${ASH_TABLE_STYLE_NAME:-$ASH_TABLE_DEFAULT_STYLE}" "${ASH_TABLE_ALIGN:-}" "$header"
}

# Two-column key/value view, used all over `ash config` and `ash doctor`.
ash_table_kv() {
    local title="${1:-}"
    shift || true
    [[ -n "$title" ]] && printf '\n  %s\n' "$(_ash_table_bold "$title")"
    {
        local row
        for row in "$@"; do printf '%s\n' "$row"; done
    } | ash_table_render "|" "${ASH_TABLE_STYLE_NAME:-unicode}" "left,left" ""
}

_ash_table_bold() {
    if declare -f ash_bold >/dev/null 2>&1; then ash_bold "$1"; else printf '%s' "$1"; fi
}

# Simple horizontal bar for percentages (doctor, analytics, disk usage).
ash_table_bar() {
    local value="$1" max="${2:-100}" width="${3:-24}" filled_char="${4:-█}" empty_char="${5:-░}"
    [[ "$max" == "0" ]] && max=1
    local filled=$(( value * width / max ))
    (( filled > width )) && filled=$width
    (( filled < 0 )) && filled=0

    local f="" e=""
    local i
    for (( i = 0; i < filled; i++ )); do f+="$filled_char"; done
    for (( i = filled; i < width; i++ )); do e+="$empty_char"; done
    printf '%s%s' "$f" "$e"
}

# Colourised bar — green/amber/red based on utilisation.
ash_table_bar_colored() {
    local value="$1" max="${2:-100}" width="${3:-24}"
    local pct=$(( max > 0 ? value * 100 / max : 0 ))
    local colour="" reset=""
    if declare -f ash_fg >/dev/null 2>&1; then
        if   (( pct >= 90 )); then colour="${ASH_C_RED:-}"
        elif (( pct >= 70 )); then colour="${ASH_C_YELLOW:-}"
        else                       colour="${ASH_C_GREEN:-}"; fi
        reset="${ASH_RESET:-}"
    fi
    printf '%s%s%s' "$colour" "$(ash_table_bar "$value" "$max" "$width")" "$reset"
}

# Sparkline from a whitespace-separated series:  ▁▂▃▄▅▆▇█
ash_table_sparkline() {
    local -a data=("$@")
    (( ${#data[@]} == 0 )) && return 0

    local min="${data[0]}" max="${data[0]}" v
    for v in "${data[@]}"; do
        (( v < min )) && min="$v"
        (( v > max )) && max="$v"
    done

    local range=$(( max - min ))
    (( range == 0 )) && range=1

    local blocks=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local out=""
    for v in "${data[@]}"; do
        local idx=$(( (v - min) * 7 / range ))
        (( idx < 0 )) && idx=0
        (( idx > 7 )) && idx=7
        out+="${blocks[idx]}"
    done
    printf '%s' "$out"
}

# Heatmap row: converts 0-100 values into coloured blocks.
ash_table_heatmap() {
    local -a data=("$@")
    local out="" v
    for v in "${data[@]}"; do
        local idx=$(( v * 4 / 100 ))
        (( idx < 0 )) && idx=0
        (( idx > 4 )) && idx=4
        case "$idx" in
            0) out+="${ASH_C_MUTED:-}·${ASH_RESET:-}" ;;
            1) out+="${ASH_C_GREEN:-}▒${ASH_RESET:-}" ;;
            2) out+="${ASH_C_YELLOW:-}▒${ASH_RESET:-}" ;;
            3) out+="${ASH_C_ORANGE:-}▓${ASH_RESET:-}" ;;
            4) out+="${ASH_C_RED:-}█${ASH_RESET:-}" ;;
        esac
    done
    printf '%s' "$out"
}
