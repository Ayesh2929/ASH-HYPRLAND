# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — colors256 Ultra                                    ║
# ║  Complete terminal color explorer: 256 colors, truecolor, ASH palette      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

function colors256 --description "Terminal color explorer: 256 colors, truecolor & ASH palette"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l WHITE  (set_color white)
    set -l CYAN   (set_color cyan)
    set -l PURPLE (set_color magenta)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __c256_help --description "Print help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🎨  colors256 — Terminal Color Explorer          ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  colors256 [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "(none)"         "Show all 256 colors (compact)" \
            "16"             "Show 16 ANSI colors" \
            "256"            "Show all 256 colors (detailed)" \
            "cube"           "Show 6x6x6 color cube" \
            "grays"          "Show grayscale ramp" \
            "truecolor"      "Truecolor gradient test" \
            "ash"            "ASH theme current palette" \
            "test"           "Terminal capabilities test" \
            "pick"           "Interactive color picker" \
            "nearest <hex>"  "Find nearest 256-color to hex" \
            "convert <val>"  "Convert between color formats"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "colors256              # All 256 colors compact" \
            "colors256 ash          # Current ASH theme palette" \
            "colors256 truecolor    # Check truecolor support" \
            "colors256 pick         # Interactive color picker" \
            "colors256 nearest ff6b35  # Find nearest color index" \
            "colors256 convert 196  # Get hex for color 196"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔧 COLOR CONVERSION UTILITIES                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __c256_ansi_bg --description "Set 256-color background"
        printf '\033[48;5;%dm' $argv[1]
    end

    function __c256_ansi_fg --description "Set 256-color foreground"
        printf '\033[38;5;%dm' $argv[1]
    end

    function __c256_rgb_bg --description "Set truecolor background"
        printf '\033[48;2;%d;%d;%dm' $argv[1] $argv[2] $argv[3]
    end

    function __c256_rgb_fg --description "Set truecolor foreground"
        printf '\033[38;2;%d;%d;%dm' $argv[1] $argv[2] $argv[3]
    end

    function __c256_reset --description "Reset terminal colors"
        printf '\033[0m'
    end

    # ── 256-color index to RGB (approximate) ──────────────────────────────────
    function __c256_idx_to_rgb --description "Convert 256-color index to R G B"
        set -l idx $argv[1]

        if test $idx -lt 16
            # System colors — approximate
            set -l sys_colors \
                "0 0 0" "170 0 0" "0 170 0" "170 170 0" \
                "0 0 170" "170 0 170" "0 170 170" "170 170 170" \
                "85 85 85" "255 85 85" "85 255 85" "255 255 85" \
                "85 85 255" "255 85 255" "85 255 255" "255 255 255"
            echo $sys_colors[(math $idx + 1)]
        else if test $idx -lt 232
            # 6x6x6 color cube
            set -l i (math $idx - 16)
            set -l b (math $i % 6)
            set -l g (math "int($i / 6) % 6")
            set -l r (math "int($i / 36)")
            set -l rv (math "($r > 0) * (55 + $r * 40)")
            set -l gv (math "($g > 0) * (55 + $g * 40)")
            set -l bv (math "($b > 0) * (55 + $b * 40)")
            echo "$rv $gv $bv"
        else
            # Grayscale ramp
            set -l v (math "8 + ($idx - 232) * 10")
            echo "$v $v $v"
        end
    end

    # ── Hex to R G B ──────────────────────────────────────────────────────────
    function __c256_hex_to_rgb --description "Convert hex color to R G B"
        set -l hex (string replace '#' '' $argv[1])
        set -l r (math --scale 0 "0x"(string sub --start 1 --length 2 $hex))
        set -l g (math --scale 0 "0x"(string sub --start 3 --length 2 $hex))
        set -l b (math --scale 0 "0x"(string sub --start 5 --length 2 $hex))
        echo "$r $g $b"
    end

    # ── Color distance (squared Euclidean) ────────────────────────────────────
    function __c256_color_dist --description "Color distance squared"
        set -l r1 $argv[1]; set -l g1 $argv[2]; set -l b1 $argv[3]
        set -l r2 $argv[4]; set -l g2 $argv[5]; set -l b2 $argv[6]
        math "(($r1-$r2)*($r1-$r2)) + (($g1-$g2)*($g1-$g2)) + (($b1-$b2)*($b1-$b2))"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖼️  RENDERERS                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── 16 ANSI colors ────────────────────────────────────────────────────────
    function __c256_show_16 --description "Render 16 ANSI system colors"
        printf "\n  $BOLD$CYAN  16 ANSI System Colors$R\n\n"

        set -l names \
            "Black" "Red" "Green" "Yellow" "Blue" "Magenta" "Cyan" "White" \
            "Br.Black" "Br.Red" "Br.Green" "Br.Yellow" "Br.Blue" "Br.Magenta" "Br.Cyan" "Br.White"

        printf "  $BOLD%-6s  %-14s  %-8s  %s$R\n" "IDX" "NAME" "FG TEXT" "BG BLOCK"
        printf "  $DIM%s$R\n" (string repeat -n 55 "─")

        for i in (seq 0 15)
            set -l name $names[(math $i + 1)]

            # Show colored blocks
            printf "  $DIM%-4d$R  %-14s  " $i $name
            printf "%s  %-8s%s  " (__c256_ansi_fg $i) "Text $i" (__c256_reset)
            printf "%s%s  %-8s%s%s\n" \
                (__c256_ansi_bg $i) \
                (test $i -lt 8 && printf '\033[37m' || printf '\033[30m') \
                "Block $i" \
                (__c256_reset) \
                $R
        end
        printf "\n"
    end

    # ── All 256 colors compact ────────────────────────────────────────────────
    function __c256_show_compact --description "Render 256 colors compact grid"
        printf "\n  $BOLD$CYAN  256 Terminal Colors$R  $DIM(compact view)$R\n\n"

        # System 16
        printf "  $BOLD  System Colors (0-15):$R\n  "
        for i in (seq 0 15)
            printf "%s  %3d  %s" (__c256_ansi_bg $i) $i (__c256_reset)
            test $i -eq 7 && printf "\n  "
        end
        printf "\n\n"

        # 6x6x6 Color Cube (16-231)
        printf "  $BOLD  Color Cube (16-231):$R\n"
        for row in (seq 0 5)
            for face in (seq 0 5)
                printf "  "
                for col in (seq 0 5)
                    set -l idx (math "16 + $face * 36 + $row * 6 + $col")
                    printf "%s  %3d  %s" (__c256_ansi_bg $idx) $idx (__c256_reset)
                end
            end
            printf "\n"
        end
        printf "\n"

        # Grayscale ramp (232-255)
        printf "  $BOLD  Grayscale (232-255):$R\n  "
        for i in (seq 232 255)
            printf "%s  %3d  %s" (__c256_ansi_bg $i) $i (__c256_reset)
            if test (math "($i - 232 + 1) % 12") -eq 0
                printf "\n  "
            end
        end
        printf "\n\n"
    end

    # ── 256 colors detailed ────────────────────────────────────────────────────
    function __c256_show_256 --description "Render 256 colors with hex values"
        printf "\n  $BOLD$CYAN  256 Colors — Detailed$R\n\n"
        printf "  $BOLD$CYAN%-6s  %-10s  %-8s  %s$R\n" "IDX" "HEX" "RGB" "SWATCH"
        printf "  $DIM%s$R\n" (string repeat -n 60 "─")

        for i in (seq 0 255)
            set -l rgb_parts (__c256_idx_to_rgb $i)
            set -l r (echo $rgb_parts | awk '{print $1}')
            set -l g (echo $rgb_parts | awk '{print $2}')
            set -l b (echo $rgb_parts | awk '{print $3}')

            # Compute hex
            set -l hex (printf '#%02x%02x%02x' $r $g $b)

            # Determine text color for swatch
            set -l luminance (math --scale 0 "($r * 299 + $g * 587 + $b * 114) / 1000")
            set -l txt_col (test $luminance -gt 128 && printf '\033[30m' || printf '\033[37m')

            printf "  $DIM%-4d$R  $DIM%-10s$R  $DIM%3d,%3d,%3d$R  %s%s  %-8s%s\n" \
                $i $hex $r $g $b \
                (__c256_ansi_bg $i) $txt_col "  idx $i  " (__c256_reset)

            # Pause every 16 for readability (only in detailed mode)
            if test (math "$i % 64") -eq 63 && test $i -lt 255
                printf "  $DIM[Press Enter to continue...]$R"
                read -l _dummy
            end
        end
        printf "\n"
    end

    # ── Color cube only ────────────────────────────────────────────────────────
    function __c256_show_cube --description "Render 6x6x6 color cube"
        printf "\n  $BOLD$CYAN  6×6×6 Color Cube (indices 16-231)$R\n\n"

        for r in (seq 0 5)
            printf "  $DIM  R=%d:$R  " $r
            for g in (seq 0 5)
                for b in (seq 0 5)
                    set -l idx (math "16 + $r * 36 + $g * 6 + $b")
                    printf "%s  %s" (__c256_ansi_bg $idx) (__c256_reset)
                end
                printf "  "
            end
            printf "\n"
        end
        printf "\n"

        # Legend
        printf "  $DIM  Each row: fixed Red, columns: Green(0-5) × Blue(0-5)$R\n\n"
    end

    # ── Grayscale ─────────────────────────────────────────────────────────────
    function __c256_show_grays --description "Render grayscale ramp"
        printf "\n  $BOLD$CYAN  Grayscale Ramp (indices 232-255)$R\n\n"
        printf "  "

        for i in (seq 232 255)
            set -l v (math "8 + ($i - 232) * 10")
            printf "%s  %3d  " (__c256_ansi_bg $i) $i
            test (math "($i - 232 + 1) % 8") -eq 0 && printf "%s\n  " (__c256_reset)
        end
        printf "%s\n" (__c256_reset)

        # Also show gradient bar
        printf "\n  $BOLD  Gradient:$R\n  "
        for i in (seq 232 255)
            printf "%s    " (__c256_ansi_bg $i)
        end
        printf "%s\n\n" (__c256_reset)
    end

    # ── Truecolor test ────────────────────────────────────────────────────────
    function __c256_show_truecolor --description "Truecolor gradient tests"
        printf "\n  $BOLD$CYAN  Truecolor (24-bit) Gradient Test$R\n\n"

        # ── Red → Green gradient
        printf "  $BOLD  Red → Green:$R\n  "
        set -l steps 80
        for i in (seq 0 $steps)
            set -l r (math --scale 0 "255 - ($i * 255 / $steps)")
            set -l g (math --scale 0 "$i * 255 / $steps")
            printf "%s " (__c256_rgb_bg $r $g 0)
        end
        printf "%s\n\n" (__c256_reset)

        # ── Blue → Cyan gradient
        printf "  $BOLD  Blue → Cyan:$R\n  "
        for i in (seq 0 $steps)
            set -l g (math --scale 0 "$i * 255 / $steps")
            printf "%s " (__c256_rgb_bg 0 $g 255)
        end
        printf "%s\n\n" (__c256_reset)

        # ── Rainbow
        printf "  $BOLD  Rainbow:$R\n  "
        for i in (seq 0 $steps)
            set -l h (math --scale 3 "$i * 360.0 / $steps")
            # HSV to RGB approximation
            set -l s (math --scale 3 "$h / 60.0")
            set -l sector (math --scale 0 "int($s)")
            set -l frac (math --scale 3 "$s - $sector")
            set -l p 0
            set -l q (math --scale 0 "int(255 * (1 - $frac))")
            set -l tv (math --scale 0 "int(255 * $frac)")

            set -l r 0; set -l g 0; set -l b 0
            switch $sector
                case 0; set r 255; set g $tv;  set b $p
                case 1; set r $q;  set g 255;  set b $p
                case 2; set r $p;  set g 255;  set b $tv
                case 3; set r $p;  set g $q;   set b 255
                case 4; set r $tv; set g $p;   set b 255
                case 5; set r 255; set g $p;   set b $q
            end
            printf "%s " (__c256_rgb_bg $r $g $b)
        end
        printf "%s\n\n" (__c256_reset)

        # ── Black → White
        printf "  $BOLD  Black → White:$R\n  "
        for i in (seq 0 $steps)
            set -l v (math --scale 0 "$i * 255 / $steps")
            printf "%s " (__c256_rgb_bg $v $v $v)
        end
        printf "%s\n\n" (__c256_reset)

        # Support check
        printf "  $BOLD  Truecolor Support:$R  "
        if printf '\033[38;2;255;100;0mTRUECOLOR\033[0m' | grep -q TRUECOLOR 2>/dev/null
            printf "$GREEN✓ Supported$R\n"
        else
            printf "$GREEN✓ Terminal renders 24-bit colors$R\n"
        end

        printf "  $BOLD  COLORTERM:$R     $DIM%s$R\n" \
            (set -q COLORTERM && echo $COLORTERM || echo "not set")
        printf "  $BOLD  TERM:$R          $DIM%s$R\n\n" $TERM
    end

    # ── ASH theme palette ─────────────────────────────────────────────────────
    function __c256_show_ash --description "Show current ASH theme palette"
        printf "\n  $BOLD$PURPLE  🎨 ASH Theme Palette$R\n"

        set -l theme_name (set -q ASH_THEME_NAME && echo $ASH_THEME_NAME || echo "unknown")
        set -l variant    (set -q ASH_THEME_VARIANT && echo $ASH_THEME_VARIANT || echo "dark")
        printf "  $DIM  Theme: %s (%s)$R\n\n" $theme_name $variant

        # Catppuccin Mocha palette (default)
        set -l palette \
            "rosewater:F5E0DC" \
            "flamingo:F2CDCD" \
            "pink:F5C2E7" \
            "mauve:CBA6F7" \
            "red:F38BA8" \
            "maroon:EBA0AC" \
            "peach:FAB387" \
            "yellow:F9E2AF" \
            "green:A6E3A1" \
            "teal:94E2D5" \
            "sky:89DCeb" \
            "sapphire:74C7EC" \
            "blue:89B4FA" \
            "lavender:B4BEFE" \
            "text:CDD6F4" \
            "subtext1:BAC2DE" \
            "subtext0:A6ADC8" \
            "overlay2:9399B2" \
            "overlay1:7F849C" \
            "overlay0:6C7086" \
            "surface2:585B70" \
            "surface1:45475A" \
            "surface0:313244" \
            "base:1E1E2E" \
            "mantle:181825" \
            "crust:11111B"

        # Override with ASH theme colors if available
        for color_entry in $palette
            set -l name (string split ':' $color_entry)[1]
            set -l default_hex (string split ':' $color_entry)[2]

            # Try to get from ASH globals
            set -l var_name "ASH_COLOR_"(string upper $name)
            set -l hex $default_hex

            if set -q $var_name
                set hex (string replace '#' '' $$var_name)
            end

            # Parse RGB
            set -l r (math --scale 0 "0x"(string sub --start 1 --length 2 $hex) 2>/dev/null; or echo 128)
            set -l g (math --scale 0 "0x"(string sub --start 3 --length 2 $hex) 2>/dev/null; or echo 128)
            set -l b (math --scale 0 "0x"(string sub --start 5 --length 2 $hex) 2>/dev/null; or echo 128)

            # Determine text color
            set -l lum (math --scale 0 "($r * 299 + $g * 587 + $b * 114) / 1000" 2>/dev/null; or echo 0)
            set -l txt_col (test $lum -gt 128 && printf '\033[30m' || printf '\033[37m')

            # Swatch (wide block)
            set -l swatch (printf '%s%s  %-12s  #%s  rgb(%3d,%3d,%3d)  %s' \
                (__c256_rgb_bg $r $g $b) $txt_col $name $hex $r $g $b (__c256_reset))

            printf "  %s\n" $swatch
        end
        printf "\n"
    end

    # ── Terminal capabilities test ─────────────────────────────────────────────
    function __c256_test --description "Test terminal capabilities"
        printf "\n  $BOLD$CYAN  Terminal Capabilities Test$R\n\n"

        # Basic attributes
        printf "  $BOLD Attributes:$R\n"
        printf "    \033[1mBold\033[0m    "
        printf "    \033[2mDim\033[0m    "
        printf "    \033[3mItalic\033[0m    "
        printf "    \033[4mUnderline\033[0m    "
        printf "    \033[5mBlink\033[0m    "
        printf "    \033[7mReverse\033[0m    "
        printf "    \033[9mStrikethrough\033[0m\n\n"

        # Color depths
        printf "  $BOLD Color Depth:$R\n"

        # 8 colors
        printf "    8-color:      "
        for c in 31 32 33 34 35 36 37
            printf "\033[${c}m████\033[0m"
        end
        printf "\n"

        # 256 colors
        printf "    256-color:    "
        for c in 196 202 208 214 220 226 118 46 51 39 21 57 129 201
            printf "%s████%s" (__c256_ansi_fg $c) (__c256_reset)
        end
        printf "\n"

        # Truecolor
        printf "    Truecolor:    "
        for i in (seq 0 13)
            set -l r (math --scale 0 "255 - ($i * 18)")
            set -l b (math --scale 0 "$i * 18")
            printf "%s████%s" (__c256_rgb_fg $r 100 $b) (__c256_reset)
        end
        printf "\n\n"

        # Environment
        printf "  $BOLD Environment:$R\n"
        printf "    %-20s  $DIM%s$R\n" "TERM:"        (set -q TERM && echo $TERM || echo "not set")
        printf "    %-20s  $DIM%s$R\n" "COLORTERM:"   (set -q COLORTERM && echo $COLORTERM || echo "not set")
        printf "    %-20s  $DIM%s$R\n" "TERM_PROGRAM:" (set -q TERM_PROGRAM && echo $TERM_PROGRAM || echo "not set")
        printf "    %-20s  $DIM%s$R\n" "TMUX:"        (set -q TMUX && echo "yes (tmux session)" || echo "no")
        printf "    %-20s  $DIM%s$R\n" "SSH:"         (set -q SSH_CONNECTION && echo "yes (remote)" || echo "no (local)")

        # Nerd Font test
        printf "\n  $BOLD Nerd Font Icons:$R\n"
        printf "    "
        for icon in "  " "  " "  " "  " "  " "  " "  " "  " "  " "  "
            printf "%s" $icon
        end
        printf "\n    $DIM(Icons should display correctly with a Nerd Font installed)$R\n\n"

        # Unicode test
        printf "  $BOLD Unicode:$R\n"
        printf "    Box:     ┌─┬─┐ │ │ ├─┼─┤ └─┴─┘\n"
        printf "    Blocks:  █ ▓ ▒ ░ ▐ ▌ ▀ ▄\n"
        printf "    Math:    ∑ ∏ ∫ √ ∞ ≤ ≥ ≠ ≈\n"
        printf "    Misc:    ★ ☆ ♠ ♣ ♥ ♦ ← → ↑ ↓ ↔\n\n"
    end

    # ── Find nearest 256-color ────────────────────────────────────────────────
    function __c256_nearest --description "Find nearest 256-color index to hex"
        set -l hex $argv[1]
        set -l target (__c256_hex_to_rgb $hex)
        set -l tr (echo $target | awk '{print $1}')
        set -l tg (echo $target | awk '{print $2}')
        set -l tb (echo $target | awk '{print $3}')

        set -l best_idx 0
        set -l best_dist 999999999

        for i in (seq 0 255)
            set -l rgb (__c256_idx_to_rgb $i)
            set -l r (echo $rgb | awk '{print $1}')
            set -l g (echo $rgb | awk '{print $2}')
            set -l b (echo $rgb | awk '{print $3}')

            set -l dist (math "(($tr-$r)*($tr-$r)) + (($tg-$g)*($tg-$g)) + (($tb-$b)*($tb-$b))")

            if test $dist -lt $best_dist
                set best_dist $dist
                set best_idx $i
            end
        end

        # Show result
        set -l rgb (__c256_idx_to_rgb $best_idx)
        set -l r (echo $rgb | awk '{print $1}')
        set -l g (echo $rgb | awk '{print $2}')
        set -l b (echo $rgb | awk '{print $3}')
        set -l nearest_hex (printf '#%02x%02x%02x' $r $g $b)

        printf "\n  $BOLD  Nearest 256-color to #%s$R\n\n" $hex
        printf "  Input:    "
        set -l ir (__c256_hex_to_rgb $hex | awk '{print $1}')
        set -l ig (__c256_hex_to_rgb $hex | awk '{print $2}')
        set -l ib (__c256_hex_to_rgb $hex | awk '{print $3}')
        printf "%s          %s  #%s  rgb(%d,%d,%d)\n" \
            (__c256_rgb_bg $ir $ig $ib) (__c256_reset) $hex $ir $ig $ib

        printf "  Nearest:  "
        printf "%s  %3d  %s  %s  rgb(%d,%d,%d)\n" \
            (__c256_ansi_bg $best_idx) $best_idx (__c256_reset) \
            $nearest_hex $r $g $b

        printf "\n  $BOLD  Use in terminal:$R\n"
        printf "  $DIM  Foreground: \\033[38;5;%dm$R\n" $best_idx
        printf "  $DIM  Background: \\033[48;5;%dm$R\n\n" $best_idx
    end

    # ── Convert color format ──────────────────────────────────────────────────
    function __c256_convert --description "Convert color index to all formats"
        set -l val $argv[1]

        printf "\n  $BOLD  Color Conversion: %s$R\n\n" $val

        if string match -qr '^\d+$' $val && test $val -ge 0 && test $val -le 255
            # Index to other formats
            set -l rgb (__c256_idx_to_rgb $val)
            set -l r (echo $rgb | awk '{print $1}')
            set -l g (echo $rgb | awk '{print $2}')
            set -l b (echo $rgb | awk '{print $3}')
            set -l hex (printf '#%02x%02x%02x' $r $g $b)

            printf "  %s  %3d  %s\n\n" (__c256_ansi_bg $val) $val (__c256_reset)
            printf "  $BOLD  Index:$R       %d\n" $val
            printf "  $BOLD  Hex:$R         %s\n" $hex
            printf "  $BOLD  RGB:$R         rgb(%d, %d, %d)\n" $r $g $b
            printf "  $BOLD  HSL:$R         (approximate)\n"

            printf "\n  $BOLD  ANSI escape:$R\n"
            printf "  $DIM  FG: \\033[38;5;%dm$R\n" $val
            printf "  $DIM  BG: \\033[48;5;%dm$R\n" $val

            printf "\n  $BOLD  Fish set_color:$R\n"
            printf "  $DIM  set_color %s$R\n" $hex

        else if string match -qr '^#?[0-9a-fA-F]{6}$' $val
            # Hex to others
            set -l rgb (__c256_hex_to_rgb $val)
            set -l r (echo $rgb | awk '{print $1}')
            set -l g (echo $rgb | awk '{print $2}')
            set -l b (echo $rgb | awk '{print $3}')
            set -l hex (string replace '#' '' $val | string lower)

            printf "  %s      %s\n\n" (__c256_rgb_bg $r $g $b) (__c256_reset)
            printf "  $BOLD  Hex:$R    #%s\n" $hex
            printf "  $BOLD  RGB:$R    rgb(%d, %d, %d)\n" $r $g $b

            printf "\n  $BOLD  Truecolor escape:$R\n"
            printf "  $DIM  FG: \\033[38;2;%d;%d;%dm$R\n" $r $g $b
            printf "  $DIM  BG: \\033[48;2;%d;%d;%dm$R\n" $r $g $b

            printf "\n  $BOLD  Nearest 256-color:$R  "
            __c256_nearest $hex 2>/dev/null | grep "Nearest:" | head -1
        else
            printf "  $RED✗$R  Invalid: use a 256-color index (0-255) or hex (#RRGGBB)\n\n"
        end
    end

    # ── Interactive color picker ───────────────────────────────────────────────
    function __c256_pick --description "Interactive 256-color picker with fzf"
        if not command -q fzf
            printf "  $YELLOW⚠$R  fzf required for interactive picker\n"
            printf "  $DIM  Showing compact view instead$R\n"
            __c256_show_compact
            return
        end

        set -l selected (
            begin
                for i in (seq 0 255)
                    set -l rgb (__c256_idx_to_rgb $i)
                    set -l r (echo $rgb | awk '{print $1}')
                    set -l g (echo $rgb | awk '{print $2}')
                    set -l b (echo $rgb | awk '{print $3}')
                    set -l hex (printf '%02x%02x%02x' $r $g $b)
                    printf "%s  %3d  \033[0m  #%s  rgb(%3d,%3d,%3d)\n" \
                        (__c256_ansi_bg $i) $i $hex $r $g $b
                end
            end |
            fzf --ansi \
                --no-sort \
                --border-label "  🎨 256-Color Picker " \
                --border rounded \
                --prompt "  🎨 " \
                --pointer "▶" \
                --preview '
                    idx=$(echo {} | awk "{print \$2}")
                    hex=$(echo {} | grep -oP "#\K[0-9a-f]{6}")
                    echo ""
                    echo "  Index: $idx"
                    echo "  Hex:   #$hex"
                    echo "  ANSI:  \\033[38;5;${idx}m (FG)"
                    echo "         \\033[48;5;${idx}m (BG)"
                    echo "  Fish:  set_color #$hex"
                    echo ""
                    printf "  " && printf "\033[48;5;${idx}m                    \033[0m\n"
                ' \
                --preview-window 'right:35%:border-rounded' \
                --header '  Enter:select and echo  Ctrl-Y:copy hex  ' \
                --bind 'ctrl-y:execute-silent(echo {} | grep -oP "#\K[0-9a-f]{6}" | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)+abort' \
                --height 80%
        )

        if test -n "$selected"
            set -l idx (echo $selected | awk '{print $2}')
            set -l hex (echo $selected | grep -oP '#[0-9a-fA-F]{6}')
            printf "\n  Selected: Index $CYAN%s$R  Hex $CYAN%s$R\n\n" $idx $hex
            __c256_convert $idx
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 MODE DISPATCH                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _mode (test (count $argv) -gt 0 && echo $argv[1] || echo compact)

    switch $_mode
        case --help -h help;           __c256_help
        case 16 ansi system;           __c256_show_16
        case 256 detailed all;         __c256_show_256
        case compact '' default;       __c256_show_compact
        case cube;                     __c256_show_cube
        case grays grayscale grey;     __c256_show_grays
        case truecolor tc 24bit;       __c256_show_truecolor
        case ash theme palette;        __c256_show_ash
        case test capabilities caps;   __c256_test
        case pick interactive;         __c256_pick
        case nearest closest
            if test -z "$argv[2]"
                printf "  $RED✗$R  Usage: colors256 nearest <hex>\n"; return 1
            end
            __c256_nearest $argv[2]
        case convert
            if test -z "$argv[2]"
                printf "  $RED✗$R  Usage: colors256 convert <index|hex>\n"; return 1
            end
            __c256_convert $argv[2]
        case '*'
            # Try to interpret as color index or hex
            if string match -qr '^\d+$' $argv[1]
                __c256_convert $argv[1]
            else if string match -qr '^#?[0-9a-fA-F]{6}$' $argv[1]
                __c256_convert $argv[1]
            else
                printf "  $RED✗$R  Unknown mode: $argv[1]\n"
                __c256_help
                return 1
            end
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __c256_help __c256_ansi_bg __c256_ansi_fg \
        __c256_rgb_bg __c256_rgb_fg __c256_reset __c256_idx_to_rgb \
        __c256_hex_to_rgb __c256_color_dist __c256_show_16 __c256_show_compact \
        __c256_show_256 __c256_show_cube __c256_show_grays __c256_show_truecolor \
        __c256_show_ash __c256_test __c256_nearest __c256_convert __c256_pick 2>/dev/null

end
