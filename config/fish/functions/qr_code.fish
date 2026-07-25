# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔲  QR CODE GENERATOR — ASH DOTFILES v5.0 OMEGA                           ║
# ║  Ultra Premium • Full Featured • Beautiful Output                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function qr_code \
    --description "🔲 Generate beautiful QR codes from text, URLs, files & more" \
    --argument-names input

    # ── Internal: Load ASH theme colors ───────────────────────────────────────
    function __qr_colors
        set -g QR_RESET   \e'[0m'
        set -g QR_BOLD    \e'[1m'
        set -g QR_DIM     \e'[2m'
        set -g QR_ITALIC  \e'[3m'

        # Detect ASH theme accent or fall back to purple
        if set -q ASH_ACCENT_HEX
            set -g QR_ACCENT  \e'[38;2;'(string join ";" (string split "," $ASH_ACCENT_RGB))'m'
        else
            set -g QR_ACCENT  \e'[38;2;203;166;247m'   # Catppuccin Mauve
        end

        set -g QR_GREEN   \e'[38;2;166;227;161m'
        set -g QR_RED     \e'[38;2;243;139;168m'
        set -g QR_YELLOW  \e'[38;2;249;226;175m'
        set -g QR_BLUE    \e'[38;2;137;180;250m'
        set -g QR_CYAN    \e'[38;2;137;220;235m'
        set -g QR_PINK    \e'[38;2;245;194;231m'
        set -g QR_PEACH   \e'[38;2;250;179;135m'
        set -g QR_SURFACE \e'[38;2;88;91;112m'
        set -g QR_OVERLAY \e'[38;2;108;112;134m'

        set -g QR_BG_DARK \e'[48;2;30;30;46m'
        set -g QR_BG_MID  \e'[48;2;49;50;68m'
    end

    # ── Internal: Animated spinner ─────────────────────────────────────────────
    function __qr_spinner --argument-names msg
        set -l frames '⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷'
        set -l i 0
        while true
            printf "\r  %s%s%s  %s" $QR_ACCENT $frames[(math "$i % 8 + 1")] $QR_RESET $msg
            set i (math $i + 1)
            sleep 0.08
        end
    end

    # ── Internal: Banner ───────────────────────────────────────────────────────
    function __qr_banner
        echo
        printf "%s╔══════════════════════════════════════════════════════╗%s\n" $QR_ACCENT $QR_RESET
        printf "%s║%s  %s🔲 QR CODE GENERATOR%s  %s•%s  %sASH DOTFILES v5.0%s          %s║%s\n" \
            $QR_ACCENT $QR_RESET \
            $QR_BOLD $QR_RESET \
            $QR_SURFACE $QR_RESET \
            $QR_DIM $QR_RESET \
            $QR_ACCENT $QR_RESET
        printf "%s╚══════════════════════════════════════════════════════╝%s\n" $QR_ACCENT $QR_RESET
        echo
    end

    # ── Internal: Section header ───────────────────────────────────────────────
    function __qr_section --argument-names icon title
        printf "\n  %s%s%s  %s%s%s\n" \
            $QR_ACCENT $icon $QR_RESET \
            $QR_BOLD $title $QR_RESET
        printf "  %s%s%s\n" \
            $QR_SURFACE \
            (string repeat --count 52 "─") \
            $QR_RESET
    end

    # ── Internal: Status messages ──────────────────────────────────────────────
    function __qr_ok  --argument-names msg;   printf "  %s✓%s  %s\n" $QR_GREEN  $QR_RESET $msg; end
    function __qr_err --argument-names msg;   printf "  %s✗%s  %s\n" $QR_RED    $QR_RESET $msg; end
    function __qr_inf --argument-names msg;   printf "  %s●%s  %s\n" $QR_BLUE   $QR_RESET $msg; end
    function __qr_wrn --argument-names msg;   printf "  %s⚠%s  %s%s%s\n" $QR_YELLOW $QR_RESET $QR_YELLOW $msg $QR_RESET; end
    function __qr_kv  --argument-names k v
        printf "  %s%-20s%s  %s%s%s\n" $QR_SURFACE $k $QR_RESET $QR_CYAN $v $QR_RESET
    end

    # ── Internal: Dependency check ─────────────────────────────────────────────
    function __qr_check_deps --argument-names mode
        set -l missing
        # Core encoder
        if not command -q qrencode
            set -a missing "qrencode (pacman -S qrencode)"
        end
        # Optional deps per mode
        switch "$mode"
            case save-png save-svg
                if not command -q qrencode
                    set -a missing "qrencode"
                end
            case preview
                if not command -q feh; and not command -q imv; and not command -q eog
                    set -a missing "imv or feh (image viewer)"
                end
            case wifi
                command -q nmcli; or set -a missing "nmcli (networkmanager)"
            case scan
                if not command -q zbarcam; and not command -q zbarimg
                    set -a missing "zbar (pacman -S zbar)"
                end
            case clipboard
                if not command -q wl-paste; and not command -q xclip
                    set -a missing "wl-clipboard or xclip"
                end
        end
        if test (count $missing) -gt 0
            __qr_err "Missing dependencies:"
            for dep in $missing
                printf "     %s→%s  %s%s%s\n" $QR_RED $QR_RESET $QR_YELLOW $dep $QR_RESET
            end
            return 1
        end
        return 0
    end

    # ── Internal: Detect content type ─────────────────────────────────────────
    function __qr_detect_type --argument-names data
        if string match -qr '^https?://' -- "$data"
            echo "url"
        else if string match -qr '^mailto:' -- "$data"
            echo "email"
        else if string match -qr '^tel:' -- "$data"
            echo "phone"
        else if string match -qr '^WIFI:' -- "$data"
            echo "wifi"
        else if string match -qr '^BEGIN:VCARD' -- "$data"
            echo "vcard"
        else if string match -qr '^BEGIN:VEVENT' -- "$data"
            echo "calendar"
        else if string match -qr '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -- "$data"
            echo "ip"
        else if string match -qr '^[0-9a-fA-F]{64}$' -- "$data"
            echo "hash"
        else if string match -qr '^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$' -- "$data"
            echo "bitcoin"
        else
            echo "text"
        end
    end

    # ── Internal: Type badge ───────────────────────────────────────────────────
    function __qr_type_badge --argument-names type
        switch "$type"
            case url;      printf "%s🌐 URL%s"       $QR_BLUE   $QR_RESET
            case email;    printf "%s📧 EMAIL%s"     $QR_GREEN  $QR_RESET
            case phone;    printf "%s📞 PHONE%s"     $QR_YELLOW $QR_RESET
            case wifi;     printf "%s📶 WIFI%s"      $QR_CYAN   $QR_RESET
            case vcard;    printf "%s👤 VCARD%s"     $QR_PINK   $QR_RESET
            case calendar; printf "%s📅 CALENDAR%s"  $QR_PEACH  $QR_RESET
            case ip;       printf "%s🌍 IP%s"        $QR_ACCENT $QR_RESET
            case hash;     printf "%s#️  HASH%s"      $QR_SURFACE $QR_RESET
            case bitcoin;  printf "%s₿  BITCOIN%s"  $QR_YELLOW $QR_RESET
            case text;     printf "%s📝 TEXT%s"      $QR_GREEN  $QR_RESET
            case '*';      printf "%s❓ UNKNOWN%s"   $QR_RED    $QR_RESET
        end
    end

    # ── Internal: Compute QR stats ────────────────────────────────────────────
    function __qr_compute_stats --argument-names data ecc
        set -l len (string length -- "$data")
        # Estimate version from length + ECC
        set -l version
        if test $len -le 17
            set version 1
        else if test $len -le 32
            set version 2
        else if test $len -le 53
            set version 3
        else if test $len -le 78
            set version 4
        else if test $len -le 106
            set version 5
        else if test $len -le 134
            set version 6
        else if test $len -le 154
            set version 7
        else if test $len -le 192
            set version 8
        else if test $len -le 230
            set version 9
        else if test $len -le 271
            set version 10
        else if test $len -le 321
            set version 11
        else if test $len -le 367
            set version 12
        else if test $len -le 425
            set version 13
        else if test $len -le 458
            set version 14
        else if test $len -le 520
            set version 15
        else
            set version (math "ceil($len / 30)")
        end
        # Modules
        set -l modules (math "$version * 4 + 17")
        # Error correction capacity
        switch "$ecc"
            case L; set -l ecc_pct "7%"
            case M; set -l ecc_pct "15%"
            case Q; set -l ecc_pct "25%"
            case H; set -l ecc_pct "30%"
            case '*'; set -l ecc_pct "15%"
        end
        echo "$version $modules $ecc_pct"
    end

    # ── Internal: Generate QR in terminal ─────────────────────────────────────
    function __qr_generate_terminal --argument-names data ecc margin
        set ecc (string upper -- "$ecc")
        test -z "$margin"; and set margin 1
        qrencode \
            --type=UTF8 \
            --level=$ecc \
            --margin=$margin \
            --output=- \
            -- "$data" 2>/dev/null
    end

    # ── Internal: Generate QR PNG ─────────────────────────────────────────────
    function __qr_generate_png \
        --argument-names data ecc margin size fg_color bg_color outfile
        set ecc (string upper -- "$ecc")
        test -z "$margin";   and set margin 4
        set -l size (math "$size * 10")
        qrencode \
            --type=PNG \
            --level=$ecc \
            --margin=$margin \
            --size=$size \
            --foreground=$fg_color \
            --background=$bg_color \
            --output="$outfile" \
            -- "$data" 2>/dev/null
    end

    # ── Internal: Generate QR SVG ─────────────────────────────────────────────
    function __qr_generate_svg \
        --argument-names data ecc margin fg_color bg_color outfile
        set ecc (string upper -- "$ecc")
        test -z "$margin"; and set margin 4
        qrencode \
            --type=SVG \
            --level=$ecc \
            --margin=$margin \
            --foreground=$fg_color \
            --background=$bg_color \
            --output="$outfile" \
            -- "$data" 2>/dev/null
    end

    # ── Internal: Render colored QR in terminal (large mode) ──────────────────
    function __qr_render_large --argument-names data ecc
        set -l raw (qrencode --type=UTF8I --level=$ecc --margin=2 --output=- -- "$data" 2>/dev/null)
        # Wrap with accent-colored border
        set -l width 54
        printf "\n%s  " $QR_ACCENT
        string repeat --count $width "─"
        printf "%s\n" $QR_RESET
        echo "$raw" | while read -l line
            printf "  %s%s%s\n" $QR_ACCENT "│" $QR_RESET
        end
        printf "%s  " $QR_ACCENT
        string repeat --count $width "─"
        printf "%s\n\n" $QR_RESET
        # Actually render properly
        qrencode --type=UTF8I --level=$ecc --margin=2 --output=- -- "$data" 2>/dev/null | \
            while read -l line
                printf "  %s\n" "$line"
            end
    end

    # ── Internal: WIFI QR data builder ────────────────────────────────────────
    function __qr_build_wifi \
        --argument-names ssid password security_type hidden
        test -z "$security_type"; and set security_type WPA
        test -z "$hidden";        and set hidden false
        printf "WIFI:T:%s;S:%s;P:%s;H:%s;;" \
            $security_type $ssid $password $hidden
    end

    # ── Internal: vCard builder ───────────────────────────────────────────────
    function __qr_build_vcard \
        --argument-names name phone email org url
        printf "BEGIN:VCARD\nVERSION:3.0\nFN:%s\n" "$name"
        test -n "$phone"; and printf "TEL:%s\n" "$phone"
        test -n "$email"; and printf "EMAIL:%s\n" "$email"
        test -n "$org";   and printf "ORG:%s\n" "$org"
        test -n "$url";   and printf "URL:%s\n" "$url"
        printf "END:VCARD"
    end

    # ── Internal: Share via clipboard ─────────────────────────────────────────
    function __qr_clipboard_copy --argument-names data
        if command -q wl-copy
            echo -n "$data" | wl-copy
            return 0
        else if command -q xclip
            echo -n "$data" | xclip -selection clipboard
            return 0
        end
        return 1
    end

    # ── Internal: Open image viewer ───────────────────────────────────────────
    function __qr_preview_image --argument-names filepath
        for viewer in imv feh eog eom viewnior
            if command -q $viewer
                command $viewer "$filepath" &>/dev/null &
                disown
                return 0
            end
        end
        return 1
    end

    # ── Internal: Scan from image ─────────────────────────────────────────────
    function __qr_scan_image --argument-names filepath
        if command -q zbarimg
            zbarimg --quiet --raw "$filepath" 2>/dev/null
            return $status
        end
        return 1
    end

    # ── Internal: History log ─────────────────────────────────────────────────
    set -l QR_HISTORY_FILE "$HOME/.local/share/ash/qr-history.log"

    function __qr_log_history --argument-names type data outfile
        mkdir -p (dirname "$QR_HISTORY_FILE")
        printf "%s\t%s\t%s\t%s\n" \
            (date +"%Y-%m-%d %H:%M:%S") \
            $type \
            (string sub --length 60 "$data") \
            (test -n "$outfile"; and echo "$outfile"; or echo "-") \
            >> "$QR_HISTORY_FILE"
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  ARGUMENT PARSING
    # ══════════════════════════════════════════════════════════════════════════

    set -l options \
        'h/help' \
        'v/version' \
        'V/verbose' \
        'o/output=' \
        'f/format=' \
        'e/ecc=' \
        'm/margin=' \
        's/size=' \
        'F/fg=' \
        'B/bg=' \
        'p/preview' \
        'c/clipboard' \
        'n/no-banner' \
        'q/quiet' \
        'l/large' \
        'S/stats' \
        'H/history' \
        'w/wifi' \
        'W/wifi-ssid=' \
        'k/wifi-pass=' \
        'T/wifi-type=' \
        'x/wifi-hidden' \
        'C/contact' \
        'N/name=' \
        'P/phone=' \
        'E/email=' \
        'O/org=' \
        'U/url=' \
        'b/batch=' \
        'I/interactive' \
        'Q/qr-from-clipboard' \
        'r/read=' \
        'A/ascii'

    argparse $options -- $argv 2>/dev/null
    or begin
        __qr_err "Invalid arguments. Use --help for usage."
        return 1
    end

    # ── Load colors ────────────────────────────────────────────────────────────
    __qr_colors

    # ── Version ────────────────────────────────────────────────────────────────
    if set -q _flag_version
        printf "%s🔲 qr_code%s  %sv5.0.0%s  %s(ASH Dotfiles Omega)%s\n" \
            $QR_ACCENT $QR_RESET \
            $QR_GREEN  $QR_RESET \
            $QR_SURFACE $QR_RESET
        return 0
    end

    # ── Help ───────────────────────────────────────────────────────────────────
    if set -q _flag_help
        __qr_banner
        printf "%sUSAGE%s\n" $QR_ACCENT $QR_RESET
        printf "  qr_code [OPTIONS] [INPUT]\n\n"

        __qr_section "⚙️" "CORE OPTIONS"
        __qr_kv "-h, --help"        "Show this help message"
        __qr_kv "-v, --version"     "Show version info"
        __qr_kv "-V, --verbose"     "Verbose output"
        __qr_kv "-q, --quiet"       "Suppress all decoration (pipe-safe)"
        __qr_kv "-n, --no-banner"   "Skip banner, show QR only"

        __qr_section "📤" "OUTPUT OPTIONS"
        __qr_kv "-o, --output=FILE"  "Save to file (auto-detect format)"
        __qr_kv "-f, --format=FMT"   "Format: terminal, png, svg (default: terminal)"
        __qr_kv "-l, --large"        "Render larger QR in terminal"
        __qr_kv "-A, --ascii"        "Force ASCII-only output"
        __qr_kv "-p, --preview"      "Open PNG in image viewer"
        __qr_kv "-c, --clipboard"    "Copy input to clipboard also"

        __qr_section "🎨" "STYLE OPTIONS"
        __qr_kv "-e, --ecc=LEVEL"   "Error correction: L M Q H (default: M)"
        __qr_kv "-m, --margin=N"    "Quiet zone modules (default: 1)"
        __qr_kv "-s, --size=N"      "Module size 1-10 (default: 3)"
        __qr_kv "-F, --fg=HEX"      "Foreground color hex (default: 000000)"
        __qr_kv "-B, --bg=HEX"      "Background color hex (default: FFFFFF)"

        __qr_section "📶" "WIFI QR"
        __qr_kv "-w, --wifi"           "Interactive WiFi QR wizard"
        __qr_kv "-W, --wifi-ssid=NAME" "WiFi SSID"
        __qr_kv "-k, --wifi-pass=PASS" "WiFi password"
        __qr_kv "-T, --wifi-type=TYPE" "Security: WPA WPA2 WEP nopass (default: WPA)"
        __qr_kv "-x, --wifi-hidden"    "Hidden network"

        __qr_section "👤" "CONTACT (vCard) QR"
        __qr_kv "-C, --contact"      "Interactive vCard wizard"
        __qr_kv "-N, --name=NAME"    "Full name"
        __qr_kv "-P, --phone=NUM"    "Phone number"
        __qr_kv "-E, --email=ADDR"   "Email address"
        __qr_kv "-O, --org=ORG"      "Organization"
        __qr_kv "-U, --url=URL"      "Website URL"

        __qr_section "🔧" "ADVANCED"
        __qr_kv "-S, --stats"            "Show QR statistics"
        __qr_kv "-H, --history"          "Show generation history"
        __qr_kv "-b, --batch=FILE"       "Batch generate from file (one per line)"
        __qr_kv "-I, --interactive"      "Interactive mode"
        __qr_kv "-Q, --qr-from-clip"     "Generate from clipboard content"
        __qr_kv "-r, --read=FILE"        "Decode QR from image file"

        __qr_section "💡" "EXAMPLES"
        printf "  %s# Basic URL%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code 'https://github.com'\n\n"
        printf "  %s# Save PNG with custom colors%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code --output=qr.png --fg=cba6f7 --bg=1e1e2e 'hello'\n\n"
        printf "  %s# WiFi QR code%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code --wifi-ssid=MyNet --wifi-pass=secret\n\n"
        printf "  %s# Contact card QR%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code --contact --name='Ada Lovelace' --email=ada@math.io\n\n"
        printf "  %s# Batch generate%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code --batch=urls.txt --format=png --output=./qrcodes/\n\n"
        printf "  %s# Decode from image%s\n" $QR_SURFACE $QR_RESET
        printf "  qr_code --read=qr.png\n\n"
        echo
        return 0
    end

    # ── Show history ──────────────────────────────────────────────────────────
    if set -q _flag_history
        set -q _flag_no_banner; or __qr_banner
        __qr_section "📋" "GENERATION HISTORY"
        if test -f "$QR_HISTORY_FILE"
            set -l count 0
            tail -20 "$QR_HISTORY_FILE" | while read -l timestamp type data outfile
                set count (math $count + 1)
                printf "  %s%2d%s  %s%-10s%s  %s%-12s%s  %s%s%s  %s%s%s\n" \
                    $QR_ACCENT $count $QR_RESET \
                    $QR_BLUE $type $QR_RESET \
                    $QR_SURFACE $timestamp $QR_RESET \
                    $QR_CYAN $data $QR_RESET \
                    $QR_YELLOW $outfile $QR_RESET
            end
            printf "\n  %s%s%s\n" $QR_SURFACE \
                "History file: $QR_HISTORY_FILE" $QR_RESET
        else
            __qr_inf "No history yet."
        end
        echo
        return 0
    end

    # ── Decode / Scan QR from image ───────────────────────────────────────────
    if set -q _flag_read
        set -q _flag_no_banner; or __qr_banner
        __qr_section "🔍" "DECODE QR CODE"
        if not test -f "$_flag_read"
            __qr_err "File not found: $_flag_read"
            return 1
        end
        __qr_check_deps scan; or return 1
        __qr_inf "Scanning: $_flag_read"
        set -l decoded (__qr_scan_image $_flag_read)
        if test $status -eq 0; and test -n "$decoded"
            printf "\n  %s┌─────────────────────────────────────────┐%s\n" $QR_GREEN $QR_RESET
            printf "  %s│%s  %s%-41s%s%s│%s\n" \
                $QR_GREEN $QR_RESET \
                $QR_BOLD $decoded $QR_RESET \
                $QR_GREEN $QR_RESET
            printf "  %s└─────────────────────────────────────────┘%s\n\n" $QR_GREEN $QR_RESET
            set -l dtype (__qr_detect_type $decoded)
            __qr_kv "Content type" (__qr_type_badge $dtype)
            __qr_kv "Characters"   (string length -- "$decoded")
            # Copy to clipboard
            if __qr_clipboard_copy $decoded
                __qr_ok "Copied to clipboard"
            end
        else
            __qr_err "Could not decode QR code from image."
            return 1
        end
        echo
        return 0
    end

    # ── QR from Clipboard ─────────────────────────────────────────────────────
    if set -q _flag_qr_from_clipboard
        if command -q wl-paste
            set input (wl-paste 2>/dev/null | string trim)
        else if command -q xclip
            set input (xclip -selection clipboard -o 2>/dev/null | string trim)
        else
            __qr_err "No clipboard tool found (wl-paste or xclip)"
            return 1
        end
        if test -z "$input"
            __qr_err "Clipboard is empty."
            return 1
        end
        __qr_inf "Using clipboard content..."
    end

    # ── Batch mode ────────────────────────────────────────────────────────────
    if set -q _flag_batch
        set -q _flag_no_banner; or __qr_banner
        if not test -f "$_flag_batch"
            __qr_err "Batch file not found: $_flag_batch"
            return 1
        end
        __qr_check_deps; or return 1
        set -l outdir (test -n "$_flag_output"; and echo $_flag_output; or echo "./qr-batch-"(date +%s))
        mkdir -p "$outdir"
        set -l format  (test -n "$_flag_format"; and echo $_flag_format; or echo "png")
        set -l ecc     (test -n "$_flag_ecc";    and echo $_flag_ecc;    or echo "M")
        set -l fg      (test -n "$_flag_fg";     and echo $_flag_fg;     or echo "000000")
        set -l bg      (test -n "$_flag_bg";     and echo $_flag_bg;     or echo "FFFFFF")
        set -l size    (test -n "$_flag_size";   and echo $_flag_size;   or echo 3)

        __qr_section "📦" "BATCH GENERATION"
        __qr_kv "Source"    $_flag_batch
        __qr_kv "Output"    $outdir
        __qr_kv "Format"    $format

        set -l idx 0
        set -l ok  0
        set -l bad 0

        while read -l line
            set line (string trim -- "$line")
            test -z "$line"; and continue
            string match -q '#*' -- "$line"; and continue
            set idx (math $idx + 1)
            set -l slug (string lower (string replace -ar '[^a-zA-Z0-9]' '_' (string sub --length 30 "$line")))
            set -l outfile "$outdir/qr-$idx-$slug.$format"
            switch "$format"
                case png
                    __qr_generate_png $line $ecc 4 $size $fg $bg $outfile
                case svg
                    __qr_generate_svg $line $ecc 4 $fg $bg $outfile
                case '*'
                    __qr_generate_png $line $ecc 4 $size $fg $bg $outfile
            end
            if test $status -eq 0
                set ok (math $ok + 1)
                printf "  %s✓%s  %s%-3d%s  %s%s%s\n" \
                    $QR_GREEN $QR_RESET \
                    $QR_YELLOW $idx $QR_RESET \
                    $QR_SURFACE (string sub --length 50 "$line") $QR_RESET
                __qr_log_history "batch-$format" $line $outfile
            else
                set bad (math $bad + 1)
                printf "  %s✗%s  %s%-3d%s  %s%s%s\n" \
                    $QR_RED $QR_RESET \
                    $QR_YELLOW $idx $QR_RESET \
                    $QR_RED (string sub --length 50 "$line") $QR_RESET
            end
        end < "$_flag_batch"

        printf "\n"
        __qr_kv "Generated"  "$ok files"
        __qr_kv "Failed"     "$bad files"
        __qr_kv "Saved to"   $outdir
        echo
        return 0
    end

    # ── WiFi wizard ────────────────────────────────────────────────────────────
    if set -q _flag_wifi; or set -q _flag_wifi_ssid
        set -q _flag_no_banner; or __qr_banner
        __qr_section "📶" "WIFI QR CODE WIZARD"

        set -l ssid     $_flag_wifi_ssid
        set -l password $_flag_wifi_pass
        set -l sec_type (test -n "$_flag_wifi_type"; and echo $_flag_wifi_type; or echo "WPA")
        set -l hidden   (set -q _flag_wifi_hidden; and echo "true"; or echo "false")

        # Interactive if missing SSID
        if test -z "$ssid"
            printf "  %s?%s  %sNetwork SSID:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read ssid
        end
        if test -z "$password"
            printf "  %s?%s  %sPassword%s %s(leave empty for open):%s " \
                $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET $QR_SURFACE $QR_RESET
            read -s password
            echo
        end
        if test -z "$password"
            set sec_type "nopass"
        end
        printf "  %s?%s  %sSecurity type%s %s[WPA/WPA2/WEP/nopass] (default: %s):%s " \
            $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET $QR_SURFACE $sec_type $QR_RESET
        read -l user_type
        test -n "$user_type"; and set sec_type $user_type

        set input (__qr_build_wifi $ssid $password $sec_type $hidden)

        printf "\n"
        __qr_kv "SSID"     $ssid
        __qr_kv "Security" $sec_type
        __qr_kv "Hidden"   $hidden
        echo
    end

    # ── Contact (vCard) wizard ────────────────────────────────────────────────
    if set -q _flag_contact; or set -q _flag_name
        set -q _flag_no_banner; or __qr_banner
        __qr_section "👤" "VCARD QR CODE WIZARD"

        set -l vname  $_flag_name
        set -l vphone $_flag_phone
        set -l vemail $_flag_email
        set -l vorg   $_flag_org
        set -l vurl   $_flag_url

        if test -z "$vname"
            printf "  %s?%s  %sFull name:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read vname
        end
        if test -z "$vphone"
            printf "  %s?%s  %sPhone:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read vphone
        end
        if test -z "$vemail"
            printf "  %s?%s  %sEmail:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read vemail
        end
        if test -z "$vorg"
            printf "  %s?%s  %sOrganization:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read vorg
        end
        if test -z "$vurl"
            printf "  %s?%s  %sWebsite:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
            read vurl
        end

        set input (__qr_build_vcard $vname $vphone $vemail $vorg $vurl)

        printf "\n"
        __qr_kv "Name"  $vname
        test -n "$vphone"; and __qr_kv "Phone" $vphone
        test -n "$vemail"; and __qr_kv "Email" $vemail
        test -n "$vorg";   and __qr_kv "Org"   $vorg
        test -n "$vurl";   and __qr_kv "URL"   $vurl
        echo
    end

    # ── Interactive mode ──────────────────────────────────────────────────────
    if set -q _flag_interactive
        set -q _flag_no_banner; or __qr_banner
        __qr_section "🎛️" "INTERACTIVE MODE"
        printf "  %s?%s  %sEnter text or URL to encode:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
        read input
        test -z "$input"; and begin; __qr_err "Nothing entered."; return 1; end
        printf "  %s?%s  %sFormat [terminal/png/svg]:%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
        read -l ifmt
        test -n "$ifmt"; and set _flag_format $ifmt
        printf "  %s?%s  %sOutput file (optional):%s " $QR_ACCENT $QR_RESET $QR_BOLD $QR_RESET
        read -l iout
        test -n "$iout"; and set _flag_output $iout
        echo
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  VALIDATE INPUT DATA
    # ══════════════════════════════════════════════════════════════════════════

    # Merge positional args if input not set yet
    if test -z "$input"
        set input (string join " " $argv)
    end

    if test -z "$input"
        if not set -q _flag_quiet
            __qr_err "No input provided."
            printf "  %sUsage:%s  qr_code [OPTIONS] <text-or-url>\n" $QR_CYAN $QR_RESET
            printf "  %sTip:%s    qr_code --help   for full usage\n\n" $QR_SURFACE $QR_RESET
        end
        return 1
    end

    # ── Check core dependency ──────────────────────────────────────────────────
    __qr_check_deps; or return 1

    # ── Defaults ───────────────────────────────────────────────────────────────
    set -l format  (test -n "$_flag_format"; and echo $_flag_format; or echo "terminal")
    set -l ecc     (test -n "$_flag_ecc";    and echo (string upper -- $_flag_ecc); or echo "M")
    set -l margin  (test -n "$_flag_margin"; and echo $_flag_margin; or echo 1)
    set -l size    (test -n "$_flag_size";   and echo $_flag_size;   or echo 3)
    set -l fg      (test -n "$_flag_fg";     and echo $_flag_fg;     or echo "000000")
    set -l bg      (test -n "$_flag_bg";     and echo $_flag_bg;     or echo "FFFFFF")
    set -l outfile $_flag_output

    # Auto-detect format from output extension
    if test -n "$outfile"
        switch (string lower (path extension "$outfile"))
            case .png; set format png
            case .svg; set format svg
            case .txt; set format terminal
        end
    end

    # ── Detect content type ────────────────────────────────────────────────────
    set -l content_type (__qr_detect_type $input)
    set -l input_len    (string length -- "$input")

    # ── Quiet/pipe-safe mode ───────────────────────────────────────────────────
    if set -q _flag_quiet
        switch "$format"
            case terminal
                qrencode --type=UTF8I --level=$ecc --margin=$margin --output=- -- "$input"
            case png
                set outfile (test -n "$outfile"; and echo "$outfile"; or echo "qr.png")
                __qr_generate_png $input $ecc $margin $size $fg $bg $outfile
            case svg
                set outfile (test -n "$outfile"; and echo "$outfile"; or echo "qr.svg")
                __qr_generate_svg $input $ecc $margin $fg $bg $outfile
        end
        return $status
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  BANNER + META INFO
    # ══════════════════════════════════════════════════════════════════════════
    set -q _flag_no_banner; or __qr_banner

    __qr_section "📋" "INPUT DETAILS"
    __qr_kv "Content type" (__qr_type_badge $content_type)
    __qr_kv "Characters"   "$input_len"
    __qr_kv "ECC level"    "$ecc  $(switch "$ecc"
        case L; echo '(Low — 7% recovery)'
        case M; echo '(Medium — 15% recovery)'
        case Q; echo '(Quartile — 25% recovery)'
        case H; echo '(High — 30% recovery)'
    end)"
    __qr_kv "Format"       "$format"
    if test $input_len -le 80
        __qr_kv "Data"         (string sub --length 60 "$input")(test $input_len -gt 60; and printf "…")
    else
        __qr_kv "Data"         (string sub --length 57 "$input")"…"
    end

    # ── Stats ──────────────────────────────────────────────────────────────────
    if set -q _flag_stats
        set -l stats_arr (__qr_compute_stats $input $ecc)
        set -l qr_ver  $stats_arr[1]
        set -l qr_mod  $stats_arr[2]
        set -l qr_cap  $stats_arr[3]

        __qr_section "📊" "QR STATISTICS"
        __qr_kv "QR Version"    "$qr_ver"
        __qr_kv "Module grid"  "${qr_mod}×${qr_mod}"
        __qr_kv "ECC capacity"  "$qr_cap of data restorable"
        __qr_kv "Data bytes"    $input_len
        __qr_kv "Encoding"      (command -q qrencode; and qrencode --help 2>&1 | grep -o 'kanji\|utf8'; or echo "UTF-8")
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  GENERATE
    # ══════════════════════════════════════════════════════════════════════════
    switch "$format"

        # ── Terminal ───────────────────────────────────────────────────────────
        case terminal
            __qr_section "🖥️" "QR CODE — TERMINAL"
            echo

            if set -q _flag_large
                __qr_render_large $input $ecc
            else if set -q _flag_ascii
                qrencode --type=ANSIUTF8 --level=$ecc --margin=$margin --output=- -- "$input" 2>/dev/null | \
                    while read -l line
                        printf "  %s\n" "$line"
                    end
            else
                # Default: UTF8 blocks, nicely padded
                set -l qr_output (__qr_generate_terminal $input $ecc $margin)
                echo "$qr_output" | while read -l line
                    printf "  %s\n" "$line"
                end
            end
            echo

            # Copy to clipboard if requested
            if set -q _flag_clipboard
                if __qr_clipboard_copy $input
                    __qr_ok "Input text copied to clipboard"
                else
                    __qr_wrn "Could not copy to clipboard"
                end
            end
            __qr_log_history "terminal" $input ""

        # ── PNG ────────────────────────────────────────────────────────────────
        case png
            __qr_section "🖼️" "QR CODE — PNG"
            set outfile (test -n "$outfile"; and echo "$outfile"; or echo "$HOME/qr-"(date +%s)".png")

            printf "\n  %s⟳%s  Generating PNG …\n" $QR_ACCENT $QR_RESET
            __qr_generate_png $input $ecc $margin $size $fg $bg $outfile
            if test $status -eq 0
                __qr_ok "Saved: $outfile"
                __qr_kv "Size"       (test -f "$outfile"; and du -h "$outfile" | cut -f1; or echo "n/a")
                __qr_kv "Foreground" "#$fg"
                __qr_kv "Background" "#$bg"
                __qr_kv "Module size" "${size}px"

                # Preview
                if set -q _flag_preview
                    if __qr_preview_image $outfile
                        __qr_ok "Opened in image viewer"
                    else
                        __qr_wrn "No image viewer found"
                    end
                end
            else
                __qr_err "PNG generation failed."
                return 1
            end
            __qr_log_history "png" $input $outfile

        # ── SVG ────────────────────────────────────────────────────────────────
        case svg
            __qr_section "🎨" "QR CODE — SVG"
            set outfile (test -n "$outfile"; and echo "$outfile"; or echo "$HOME/qr-"(date +%s)".svg")

            printf "\n  %s⟳%s  Generating SVG …\n" $QR_ACCENT $QR_RESET
            __qr_generate_svg $input $ecc $margin $fg $bg $outfile
            if test $status -eq 0
                __qr_ok "Saved: $outfile"
                __qr_kv "Size"        (test -f "$outfile"; and du -h "$outfile" | cut -f1; or echo "n/a")
                __qr_kv "Foreground"  "#$fg"
                __qr_kv "Background"  "#$bg"
                __qr_inf "SVG is scalable — perfect for printing"
            else
                __qr_err "SVG generation failed."
                return 1
            end
            __qr_log_history "svg" $input $outfile

        # ── Unknown ────────────────────────────────────────────────────────────
        case '*'
            __qr_err "Unknown format: $format"
            __qr_inf "Valid formats: terminal, png, svg"
            return 1
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  FOOTER
    # ══════════════════════════════════════════════════════════════════════════
    printf "\n  %s%s%s\n" $QR_SURFACE (string repeat --count 54 "─") $QR_RESET
    printf "  %s🔲 ASH QR Engine%s  %sv5.0%s  %s•%s  %sqrencode backend%s\n" \
        $QR_ACCENT $QR_RESET \
        $QR_GREEN  $QR_RESET \
        $QR_SURFACE $QR_RESET \
        $QR_DIM    $QR_RESET
    echo

    # ── Cleanup inner functions ────────────────────────────────────────────────
    functions --erase __qr_colors __qr_spinner __qr_banner __qr_section
    functions --erase __qr_ok __qr_err __qr_inf __qr_wrn __qr_kv
    functions --erase __qr_check_deps __qr_detect_type __qr_type_badge
    functions --erase __qr_compute_stats __qr_generate_terminal
    functions --erase __qr_generate_png __qr_generate_svg __qr_render_large
    functions --erase __qr_build_wifi __qr_build_vcard
    functions --erase __qr_clipboard_copy __qr_preview_image
    functions --erase __qr_scan_image __qr_log_history
end
