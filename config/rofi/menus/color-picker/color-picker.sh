#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Color Picker & Palette Manager Script             ║
# ║                                                                              ║
# ║  Full color tool: screen picking, palette browsing, format conversion,     ║
# ║  harmony generation, history and favorites.                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly HISTORY_FILE="${HOME}/.local/share/ash-dotfiles/color-history.txt"
readonly FAVORITES_FILE="${HOME}/.local/share/ash-dotfiles/color-favorites.txt"
readonly CUSTOM_PALETTE="${HOME}/.local/share/ash-dotfiles/custom-palette.txt"
readonly MAX_HISTORY=50

# ══════════════════════════════════════════════════════════════════════════════
# §02  COLOR SPACE CONVERSIONS
# ══════════════════════════════════════════════════════════════════════════════

hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d %d %d" \
        "0x${hex:0:2}" \
        "0x${hex:2:2}" \
        "0x${hex:4:2}" \
        2>/dev/null || echo "0 0 0"
}

rgb_to_hex() {
    local r="$1" g="$2" b="$3"
    printf "#%02X%02X%02X" "$r" "$g" "$b"
}

hex_to_hsl() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
print(f'hsl({h*360:.0f}, {s*100:.1f}%, {l*100:.1f}%)')
" 2>/dev/null || echo "hsl(0, 0%, 0%)"
}

hex_to_oklch() {
    python3 -c "
import sys, math

def hex_to_oklch(hex_str):
    hex_str = hex_str.lstrip('#')
    r, g, b = [int(hex_str[i:i+2], 16)/255 for i in (0,2,4)]

    # sRGB to linear
    def to_linear(c):
        return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4

    r, g, b = map(to_linear, [r, g, b])

    # Linear RGB to OKLab
    l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
    m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
    s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b

    l_, m_, s_ = [c**(1/3) for c in [l,m,s]]

    L = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
    a = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
    b2= 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_

    C = math.sqrt(a**2 + b2**2)
    h = math.degrees(math.atan2(b2, a)) % 360

    return f'oklch({L:.3f} {C:.3f} {h:.1f})'

print(hex_to_oklch('$1'))
" 2>/dev/null || echo "oklch(0 0 0)"
}

hex_to_hsv() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, s, v = colorsys.rgb_to_hsv(r, g, b)
print(f'hsv({h*360:.0f}, {s*100:.1f}%, {v*100:.1f}%)')
" 2>/dev/null || echo "hsv(0, 0%, 0%)"
}

hex_to_cmyk() {
    local hex="${1#\#}"
    python3 -c "
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
k = 1 - max(r,g,b)
if k == 1:
    c, m, y = 0, 0, 0
else:
    c = (1-r-k)/(1-k)
    m = (1-g-k)/(1-k)
    y = (1-b-k)/(1-k)
print(f'cmyk({c*100:.0f}%, {m*100:.0f}%, {y*100:.0f}%, {k*100:.0f}%)')
" 2>/dev/null || echo "cmyk(0%, 0%, 0%, 100%)"
}

# Relative luminance for contrast ratio
get_luminance() {
    local hex="${1#\#}"
    python3 -c "
def to_linear(c):
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4

r, g, b = [int('${hex}'[i:i+2], 16)/255 for i in (0,2,4)]
r, g, b = map(to_linear, [r, g, b])
L = 0.2126*r + 0.7152*g + 0.0722*b
print(f'{L:.4f}')
" 2>/dev/null || echo "0"
}

get_contrast_ratio() {
    local l1="$1" l2="$2"
    python3 -c "
l1, l2 = float('$l1'), float('$l2')
lighter = max(l1, l2)
darker  = min(l1, l2)
ratio = (lighter + 0.05) / (darker + 0.05)
print(f'{ratio:.2f}')
" 2>/dev/null || echo "1.00"
}

wcag_rating() {
    local ratio="$1"
    python3 -c "
r = float('$ratio')
if r >= 7: print('AAA')
elif r >= 4.5: print('AA')
elif r >= 3: print('AA Large')
else: print('Fail')
" 2>/dev/null || echo "?"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  COLOR SWATCH BLOCK RENDERER
# ══════════════════════════════════════════════════════════════════════════════

# Generate colored block character using ANSI in Pango
color_swatch_pango() {
    local hex="${1#\#}"
    printf '<span background="#%s" foreground="#%s">████</span>' "$hex" "$hex"
}

# Approximate text color (black or white) for readability on this background
get_text_on_bg() {
    local hex="${1#\#}"
    local lum
    lum=$(get_luminance "$hex")
    python3 -c "
l = float('$lum')
print('000000' if l > 0.179 else 'ffffff')
" 2>/dev/null || echo "ffffff"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  HARMONY GENERATORS
# ══════════════════════════════════════════════════════════════════════════════

generate_complementary() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
h2 = (h + 0.5) % 1.0
r2, g2, b2 = colorsys.hls_to_rgb(h2, l, s)
print('#%02X%02X%02X' % (int(r2*255), int(g2*255), int(b2*255)))
" 2>/dev/null || echo "#000000"
}

generate_analogous() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
for offset in [-30/360, 30/360]:
    h2 = (h + offset) % 1.0
    r2, g2, b2 = colorsys.hls_to_rgb(h2, l, s)
    print('#%02X%02X%02X' % (int(r2*255), int(g2*255), int(b2*255)))
" 2>/dev/null
}

generate_triadic() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
for offset in [1/3, 2/3]:
    h2 = (h + offset) % 1.0
    r2, g2, b2 = colorsys.hls_to_rgb(h2, l, s)
    print('#%02X%02X%02X' % (int(r2*255), int(g2*255), int(b2*255)))
" 2>/dev/null
}

generate_shades() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
for lightness in [0.20, 0.35, 0.50, 0.65, 0.80]:
    r2, g2, b2 = colorsys.hls_to_rgb(h, lightness, s)
    print('#%02X%02X%02X' % (int(r2*255), int(g2*255), int(b2*255)))
" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  PALETTE DEFINITIONS
# ══════════════════════════════════════════════════════════════════════════════

build_catppuccin_mocha() {
    cat << 'COLORS'
rosewater|#f5e0dc|Catppuccin Mocha
flamingo|#f2cdcd|Catppuccin Mocha
pink|#f5c2e7|Catppuccin Mocha
mauve|#cba4f7|Catppuccin Mocha
red|#f38ba8|Catppuccin Mocha
maroon|#eba0ac|Catppuccin Mocha
peach|#fab387|Catppuccin Mocha
yellow|#f9e2af|Catppuccin Mocha
green|#a6e3a1|Catppuccin Mocha
teal|#94e2d5|Catppuccin Mocha
sky|#89dceb|Catppuccin Mocha
sapphire|#74c7ec|Catppuccin Mocha
blue|#89b4fa|Catppuccin Mocha
lavender|#b4befe|Catppuccin Mocha
text|#cdd6f4|Catppuccin Mocha
subtext1|#bac2de|Catppuccin Mocha
subtext0|#a6adc8|Catppuccin Mocha
overlay2|#9399b2|Catppuccin Mocha
overlay1|#7f849c|Catppuccin Mocha
overlay0|#6c7086|Catppuccin Mocha
surface2|#585b70|Catppuccin Mocha
surface1|#45475a|Catppuccin Mocha
surface0|#313244|Catppuccin Mocha
base|#1e1e2e|Catppuccin Mocha
mantle|#181825|Catppuccin Mocha
crust|#11111b|Catppuccin Mocha
COLORS
}

build_catppuccin_latte() {
    cat << 'COLORS'
rosewater|#dc8a78|Catppuccin Latte
flamingo|#dd7878|Catppuccin Latte
pink|#ea76cb|Catppuccin Latte
mauve|#8839ef|Catppuccin Latte
red|#d20f39|Catppuccin Latte
maroon|#e64553|Catppuccin Latte
peach|#fe640b|Catppuccin Latte
yellow|#df8e1d|Catppuccin Latte
green|#40a02b|Catppuccin Latte
teal|#179299|Catppuccin Latte
sky|#04a5e5|Catppuccin Latte
sapphire|#209fb5|Catppuccin Latte
blue|#1e66f5|Catppuccin Latte
lavender|#7287fd|Catppuccin Latte
text|#4c4f69|Catppuccin Latte
base|#eff1f5|Catppuccin Latte
mantle|#e6e9ef|Catppuccin Latte
crust|#dce0e8|Catppuccin Latte
COLORS
}

build_tokyo_night() {
    cat << 'COLORS'
bg|#1a1b26|Tokyo Night
bg_dark|#16161e|Tokyo Night
bg_highlight|#292e42|Tokyo Night
terminal_black|#414868|Tokyo Night
fg|#c0caf5|Tokyo Night
fg_dark|#a9b1d6|Tokyo Night
blue|#7aa2f7|Tokyo Night
cyan|#7dcfff|Tokyo Night
blue1|#2ac3de|Tokyo Night
blue5|#89ddff|Tokyo Night
blue6|#b4f9f8|Tokyo Night
magenta|#bb9af7|Tokyo Night
magenta2|#ff007c|Tokyo Night
purple|#9d7cd8|Tokyo Night
orange|#ff9e64|Tokyo Night
yellow|#e0af68|Tokyo Night
green|#9ece6a|Tokyo Night
green1|#73daca|Tokyo Night
teal|#1abc9c|Tokyo Night
red|#f7768e|Tokyo Night
red1|#db4b4b|Tokyo Night
COLORS
}

build_gruvbox() {
    cat << 'COLORS'
dark0_hard|#1d2021|Gruvbox Dark
dark0|#282828|Gruvbox Dark
dark0_soft|#32302f|Gruvbox Dark
dark1|#3c3836|Gruvbox Dark
dark2|#504945|Gruvbox Dark
dark3|#665c54|Gruvbox Dark
dark4|#7c6f64|Gruvbox Dark
gray|#928374|Gruvbox Dark
light0_hard|#f9f5d7|Gruvbox Dark
light0|#fbf1c7|Gruvbox Dark
fg|#ebdbb2|Gruvbox Dark
light1|#ebdbb2|Gruvbox Dark
bright_red|#fb4934|Gruvbox Dark
bright_green|#b8bb26|Gruvbox Dark
bright_yellow|#fabd2f|Gruvbox Dark
bright_blue|#83a598|Gruvbox Dark
bright_purple|#d3869b|Gruvbox Dark
bright_aqua|#8ec07c|Gruvbox Dark
bright_orange|#fe8019|Gruvbox Dark
neutral_red|#cc241d|Gruvbox Dark
neutral_green|#98971a|Gruvbox Dark
neutral_yellow|#d79921|Gruvbox Dark
neutral_blue|#458588|Gruvbox Dark
neutral_purple|#b16286|Gruvbox Dark
neutral_aqua|#689d6a|Gruvbox Dark
neutral_orange|#d65d0e|Gruvbox Dark
COLORS
}

build_nord() {
    cat << 'COLORS'
nord0|#2e3440|Nord
nord1|#3b4252|Nord
nord2|#434c5e|Nord
nord3|#4c566a|Nord
nord4|#d8dee9|Nord
nord5|#e5e9f0|Nord
nord6|#eceff4|Nord
nord7|#8fbcbb|Nord
nord8|#88c0d0|Nord
nord9|#81a1c1|Nord
nord10|#5e81ac|Nord
nord11|#bf616a|Nord
nord12|#d08770|Nord
nord13|#ebcb8b|Nord
nord14|#a3be8c|Nord
nord15|#b48ead|Nord
COLORS
}

build_web_colors() {
    cat << 'COLORS'
black|#000000|CSS Colors
white|#ffffff|CSS Colors
red|#ff0000|CSS Colors
lime|#00ff00|CSS Colors
blue|#0000ff|CSS Colors
yellow|#ffff00|CSS Colors
cyan|#00ffff|CSS Colors
magenta|#ff00ff|CSS Colors
silver|#c0c0c0|CSS Colors
gray|#808080|CSS Colors
maroon|#800000|CSS Colors
olive|#808000|CSS Colors
green|#008000|CSS Colors
purple|#800080|CSS Colors
teal|#008080|CSS Colors
navy|#000080|CSS Colors
orange|#ffa500|CSS Colors
coral|#ff7f50|CSS Colors
hotpink|#ff69b4|CSS Colors
deepskyblue|#00bfff|CSS Colors
gold|#ffd700|CSS Colors
limegreen|#32cd32|CSS Colors
turquoise|#40e0d0|CSS Colors
indigo|#4b0082|CSS Colors
violet|#ee82ee|CSS Colors
chocolate|#d2691e|CSS Colors
tomato|#ff6347|CSS Colors
orchid|#da70d6|CSS Colors
slateblue|#6a5acd|CSS Colors
forestgreen|#228b22|CSS Colors
COLORS
}

get_all_colors() {
    local palette="${1:-catppuccin-mocha}"

    case "$palette" in
        catppuccin-mocha)   build_catppuccin_mocha ;;
        catppuccin-latte)   build_catppuccin_latte ;;
        tokyo-night)        build_tokyo_night ;;
        gruvbox)            build_gruvbox ;;
        nord)               build_nord ;;
        web)                build_web_colors ;;
        all)
            build_catppuccin_mocha
            build_tokyo_night
            build_gruvbox
            build_nord
            build_web_colors
            ;;
        *)
            build_catppuccin_mocha
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  HISTORY & FAVORITES
# ══════════════════════════════════════════════════════════════════════════════

ensure_files() {
    mkdir -p "$(dirname "$HISTORY_FILE")" \
             "$(dirname "$FAVORITES_FILE")"
    touch "$HISTORY_FILE" "$FAVORITES_FILE" 2>/dev/null || true
}

add_to_history() {
    local hex="$1" name="${2:-picked}"
    ensure_files

    local tmp
    tmp=$(mktemp)
    echo "${hex}|${name}|$(date +%s)" | cat - "$HISTORY_FILE" > "$tmp" 2>/dev/null || true
    head -"$MAX_HISTORY" "$tmp" > "$HISTORY_FILE" 2>/dev/null || true
    rm -f "$tmp"
}

is_favorite() {
    grep -qF "$1" "$FAVORITES_FILE" 2>/dev/null
}

toggle_favorite() {
    local hex="$1" name="${2:-color}"
    ensure_files

    if is_favorite "$hex"; then
        local tmp
        tmp=$(mktemp)
        grep -vF "$hex" "$FAVORITES_FILE" > "$tmp" 2>/dev/null || true
        mv "$tmp" "$FAVORITES_FILE"
        notify_cp "Unfavorited" "$hex" "low"
    else
        echo "${hex}|${name}" >> "$FAVORITES_FILE"
        notify_cp "★ Favorited" "$hex" "low"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  COPY ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

copy_color() {
    local hex="$1" format="${2:-hex}" name="${3:-color}"

    local output
    case "$format" in
        hex)    output="$hex" ;;
        rgb)
            IFS=' ' read -r r g b <<< "$(hex_to_rgb "$hex")"
            output="rgb($r, $g, $b)"
            ;;
        hsl)    output=$(hex_to_hsl "$hex") ;;
        oklch)  output=$(hex_to_oklch "$hex") ;;
        hsv)    output=$(hex_to_hsv "$hex") ;;
        cmyk)   output=$(hex_to_cmyk "$hex") ;;
        css-hsl) output=$(hex_to_hsl "$hex") ;;
        css-var) output="--color-${name,,}: ${hex};" ;;
        *)      output="$hex" ;;
    esac

    echo -n "$output" | wl-copy 2>/dev/null && \
        notify_cp "Copied $format" "$output" "low"

    add_to_history "$hex" "$name"
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  SCREEN PICKER
# ══════════════════════════════════════════════════════════════════════════════

pick_from_screen() {
    if ! command -v hyprpicker &>/dev/null; then
        notify_cp "hyprpicker not found" "paru -S hyprpicker" "normal"
        return 1
    fi

    local picked
    picked=$(hyprpicker --autocopy --format=hex 2>/dev/null | tr -d '\n' || echo "")

    if [[ -n "$picked" && "$picked" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        add_to_history "$picked" "screen-pick"
        notify_cp "🎨 Picked" "$picked" "low"
        echo "$picked"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  HARMONY GENERATOR UI
# ══════════════════════════════════════════════════════════════════════════════

show_harmony_for() {
    local hex="$1" name="${2:-color}"

    local comp
    comp=$(generate_complementary "$hex")
    local analogous1 analogous2
    IFS=$'\n' read -r analogous1 analogous2 <<< "$(generate_analogous "$hex")"
    local triadic1 triadic2
    IFS=$'\n' read -r triadic1 triadic2 <<< "$(generate_triadic "$hex")"

    # Show harmony as notification with swatches
    local msg=""
    msg+="Base: $hex\n"
    msg+="Complementary: ${comp}\n"
    msg+="Analogous: ${analogous1} ${analogous2}\n"
    msg+="Triadic: ${triadic1} ${triadic2}"

    notify_cp "🎨 Harmonies for $name" "$msg" "low"
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_cp() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Color Picker" \
        --icon=color-picker \
        --urgency="$urgency" \
        --expire-time=2500 \
        --hint=string:x-dunst-stack-tag:color-picker \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_color_entries() {
    local palette="${1:-catppuccin-mocha}"

    local current_section=""

    while IFS='|' read -r name hex palette_name; do
        [[ -z "$hex" ]] && continue

        # Section header per palette
        if [[ "$palette_name" != "$current_section" ]]; then
            current_section="$palette_name"
            printf '─── %s ─────────────────────────\0nonselectable\x1ftrue\n' \
                "$(echo "$palette_name" | tr '[:lower:]' '[:upper:]')"
        fi

        # Get formats
        local hex_upper="${hex^^}"
        local hsl_str
        hsl_str=$(hex_to_hsl "$hex" 2>/dev/null || echo "")
        local rgb_str
        IFS=' ' read -r r g b <<< "$(hex_to_rgb "$hex" 2>/dev/null || echo "0 0 0")"
        local rgb_short="rgb($r,$g,$b)"

        # Contrast ratios
        local lum
        lum=$(get_luminance "$hex" 2>/dev/null || echo "0.5")
        local white_lum="1.0"
        local black_lum="0.0"
        local vs_white
        vs_white=$(get_contrast_ratio "$lum" "$white_lum" 2>/dev/null || echo "1")
        local vs_black
        vs_black=$(get_contrast_ratio "$lum" "$black_lum" 2>/dev/null || echo "1")

        # Favorite indicator
        local fav_mark=""
        is_favorite "$hex" && fav_mark=" ★"

        # Swatch (colored block using the hex)
        local swatch="████"

        # Format display line
        local display
        display=$(printf '%s  %-14s  %s  %-16s  %-20s  %s:%s%s' \
            "$swatch" \
            "${name:0:12}" \
            "${hex_upper}" \
            "${rgb_short:0:14}" \
            "${hsl_str:0:18}" \
            "${vs_white}:1" \
            "${vs_black}:1" \
            "$fav_mark")

        printf '%s\0info\x1fcopy\x1fmeta\x1f%s|%s|%s\n' \
            "$display" "$hex" "$name" "$palette_name"

    done < <(get_all_colors "$palette")
}

build_history_entries() {
    ensure_files
    printf '─── RECENTLY PICKED ─────────────────────\0nonselectable\x1ftrue\n'

    local count=0
    while IFS='|' read -r hex name ts; do
        [[ -z "$hex" ]] && continue

        local IFS2=' '
        read -r r g b <<< "$(hex_to_rgb "$hex" 2>/dev/null || echo "0 0 0")"

        local display
        display=$(printf '████  %-12s  %s  rgb(%d,%d,%d)' \
            "${name:0:10}" \
            "$hex" \
            "$r" "$g" "$b")

        printf '%s\0info\x1fcopy\x1fmeta\x1f%s|%s|history\n' \
            "$display" "$hex" "$name"

        (( count++ )) || true
        [[ $count -ge 15 ]] && break
    done < "$HISTORY_FILE"

    [[ $count -eq 0 ]] && \
        printf '  No color history yet — pick a color!\0nonselectable\x1ftrue\n'
}

build_favorites_entries() {
    ensure_files
    printf '─── FAVORITES ────────────────────────────\0nonselectable\x1ftrue\n'

    local count=0
    while IFS='|' read -r hex name; do
        [[ -z "$hex" ]] && continue

        local hsl_str
        hsl_str=$(hex_to_hsl "$hex" 2>/dev/null || echo "")

        local display
        display=$(printf '████  ★ %-12s  %s  %s' \
            "${name:0:10}" \
            "$hex" \
            "${hsl_str:0:18}")

        printf '%s\0info\x1fcopy\x1fmeta\x1f%s|%s|favorite\n' \
            "$display" "$hex" "$name"

        (( count++ )) || true
    done < "$FAVORITES_FILE"

    [[ $count -eq 0 ]] && \
        printf '  No favorites yet — press Ctrl+F to add!\0nonselectable\x1ftrue\n'
}

build_harmony_entries() {
    # Show harmony for last picked/selected color
    local last_hex
    last_hex=$(head -1 "$HISTORY_FILE" 2>/dev/null | cut -d'|' -f1 || echo "#cba4f7")

    printf '─── HARMONY FOR %s ────────────────────\0nonselectable\x1ftrue\n' \
        "${last_hex^^}"

    # Complementary
    local comp
    comp=$(generate_complementary "$last_hex" 2>/dev/null || echo "#000000")
    printf '████  Complementary  %s\0info\x1fcopy\x1fmeta\x1f%s|complementary|harmony\n' \
        "$comp" "$comp"

    # Analogous
    printf '─── Analogous ───\0nonselectable\x1ftrue\n'
    while IFS= read -r analog_hex; do
        [[ -z "$analog_hex" ]] && continue
        printf '████  Analogous  %s\0info\x1fcopy\x1fmeta\x1f%s|analogous|harmony\n' \
            "$analog_hex" "$analog_hex"
    done < <(generate_analogous "$last_hex" 2>/dev/null || true)

    # Triadic
    printf '─── Triadic ─────\0nonselectable\x1ftrue\n'
    while IFS= read -r tri_hex; do
        [[ -z "$tri_hex" ]] && continue
        printf '████  Triadic  %s\0info\x1fcopy\x1fmeta\x1f%s|triadic|harmony\n' \
            "$tri_hex" "$tri_hex"
    done < <(generate_triadic "$last_hex" 2>/dev/null || true)

    # Monochromatic shades
    printf '─── Shades ──────\0nonselectable\x1ftrue\n'
    while IFS= read -r shade_hex; do
        [[ -z "$shade_hex" ]] && continue
        printf '████  Shade  %s\0info\x1fcopy\x1fmeta\x1f%s|shade|harmony\n' \
            "$shade_hex" "$shade_hex"
    done < <(generate_shades "$last_hex" 2>/dev/null || true)
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        copy)
            IFS='|' read -r hex name palette <<< "$meta"
            [[ -n "$hex" ]] && {
                copy_color "$hex" "hex" "$name"
            }
            ;;
        toggle-fav)
            IFS='|' read -r hex name rest <<< "$meta"
            [[ -n "$hex" ]] && toggle_favorite "$hex" "$name"
            ;;
        pick-screen)
            local picked
            picked=$(pick_from_screen 2>/dev/null || echo "")
            [[ -n "$picked" ]] && copy_color "$picked" "hex" "picked"
            ;;
        harmony)
            IFS='|' read -r hex name rest <<< "$meta"
            [[ -n "$hex" ]] && show_harmony_for "$hex" "$name"
            ;;
        none|"")    return 0 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §13  CURRENT VIEW STATE
# ══════════════════════════════════════════════════════════════════════════════

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-colorpicker"
mkdir -p "$STATE_DIR"
readonly VIEW_FILE="${STATE_DIR}/view"
readonly PALETTE_FILE="${STATE_DIR}/palette"

get_view()    { cat "$VIEW_FILE"    2>/dev/null || echo "palette"; }
get_palette() { cat "$PALETTE_FILE" 2>/dev/null || echo "catppuccin-mocha"; }

# ══════════════════════════════════════════════════════════════════════════════
# §14  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --pick)
            pick_from_screen
            ;;
        --hex-to-rgb)  [[ -n "${2:-}" ]] && hex_to_rgb "$2" ;;
        --hex-to-hsl)  [[ -n "${2:-}" ]] && hex_to_hsl "$2" ;;
        --hex-to-oklch)[[ -n "${2:-}" ]] && hex_to_oklch "$2" ;;
        --contrast)    [[ -n "${3:-}" ]] && {
            l1=$(get_luminance "$2")
            l2=$(get_luminance "$3")
            ratio=$(get_contrast_ratio "$l1" "$l2")
            rating=$(wcag_rating "$ratio")
            echo "$ratio:1 ($rating)"
            };;
        --harmony)     [[ -n "${2:-}" ]] && show_harmony_for "$2" ;;
        --help|-h)
            echo "ASH Color Picker v5.0"
            echo ""
            echo "Usage: color-picker.sh [OPTION] [COLOR]"
            echo "  --pick              Pick from screen"
            echo "  --hex-to-rgb HEX    Convert to RGB"
            echo "  --hex-to-hsl HEX    Convert to HSL"
            echo "  --hex-to-oklch HEX  Convert to OKLCH"
            echo "  --contrast A B      Contrast ratio"
            echo "  --harmony HEX       Show color harmonies"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §15  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show cp \
        -modi "cp:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/color-picker/color-picker.rasi" \
        2>/dev/null
    exit 0
fi

VIEW=$(get_view)
PALETTE=$(get_palette)

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_files
    case "$VIEW" in
        history)  build_history_entries ;;
        favorites) build_favorites_entries ;;
        harmony)  build_harmony_entries ;;
        *)        build_color_entries "$PALETTE" ;;
    esac
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"

    case "$VIEW" in
        history)   build_history_entries ;;
        favorites) build_favorites_entries ;;
        harmony)   build_harmony_entries ;;
        *)         build_color_entries "$PALETTE" ;;
    esac
    exit 0
fi

# Ctrl+P: Screen picker
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    dispatch_action "pick-screen"
    build_color_entries "$PALETTE"
    exit 0
fi

# Ctrl+H: Copy as HSL
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && copy_color "$hex" "hsl" "$name"
    build_color_entries "$PALETTE"
    exit 0
fi

# Ctrl+O: Copy as OKLCH
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && copy_color "$hex" "oklch" "$name"
    build_color_entries "$PALETTE"
    exit 0
fi

# Ctrl+R: Copy as RGB
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && copy_color "$hex" "rgb" "$name"
    build_color_entries "$PALETTE"
    exit 0
fi

# Ctrl+F: Toggle favorite
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && toggle_favorite "$hex" "$name"
    build_color_entries "$PALETTE"
    exit 0
fi

# Ctrl+G: Generate harmony
if [[ "${ROFI_RETV}" -eq 15 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && {
        add_to_history "$hex" "$name"
        echo "harmony" > "$VIEW_FILE"
    }
    build_harmony_entries
    exit 0
fi

# Ctrl+B: Browse palettes
if [[ "${ROFI_RETV}" -eq 22 ]]; then
    local new_palette
    new_palette=$(printf '%s\n' \
        "catppuccin-mocha" \
        "catppuccin-latte" \
        "tokyo-night" \
        "gruvbox" \
        "nord" \
        "web" | \
        rofi -dmenu \
            -p "Select palette" \
            -theme-str "window { width: 280px; } listview { lines: 6; }" \
            2>/dev/null || echo "catppuccin-mocha")
    echo "$new_palette" > "$PALETTE_FILE"
    echo "palette" > "$VIEW_FILE"
    build_color_entries "$new_palette"
    exit 0
fi

# Alt+Enter: Copy as RGB css
if [[ "${ROFI_RETV}" -eq 23 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    IFS='|' read -r hex name rest <<< "$meta_value"
    [[ -n "$hex" ]] && copy_color "$hex" "rgb" "$name"
    build_color_entries "$PALETTE"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    case "$VIEW" in
        history)   build_history_entries ;;
        favorites) build_favorites_entries ;;
        harmony)   build_harmony_entries ;;
        *)         build_color_entries "$PALETTE" ;;
    esac
    exit 0
fi