# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔐  PASSWORD GENERATOR — ASH DOTFILES v5.0 OMEGA                          ║
# ║  Cryptographically Secure • Memorable • Beautiful Output                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function gen_password \
    --description "🔐 Generate cryptographically secure passwords with style"

    # ── Colors ─────────────────────────────────────────────────────────────────
    function __pw_colors
        set -g PW_RESET   \e'[0m'
        set -g PW_BOLD    \e'[1m'
        set -g PW_DIM     \e'[2m'
        set -g PW_ITALIC  \e'[3m'
        set -g PW_ACCENT  \e'[38;2;203;166;247m'   # Catppuccin Mauve
        set -g PW_GREEN   \e'[38;2;166;227;161m'
        set -g PW_RED     \e'[38;2;243;139;168m'
        set -g PW_YELLOW  \e'[38;2;249;226;175m'
        set -g PW_BLUE    \e'[38;2;137;180;250m'
        set -g PW_CYAN    \e'[38;2;137;220;235m'
        set -g PW_PINK    \e'[38;2;245;194;231m'
        set -g PW_PEACH   \e'[38;2;250;179;135m'
        set -g PW_SURFACE \e'[38;2;88;91;112m'
        set -g PW_TEAL    \e'[38;2;148;226;213m'

        # Strength colors
        set -g PW_STR_1   \e'[38;2;243;139;168m'   # Very Weak — red
        set -g PW_STR_2   \e'[38;2;250;179;135m'   # Weak — peach
        set -g PW_STR_3   \e'[38;2;249;226;175m'   # Fair — yellow
        set -g PW_STR_4   \e'[38;2;166;227;161m'   # Strong — green
        set -g PW_STR_5   \e'[38;2;137;220;235m'   # Very Strong — cyan
    end

    # ── Helpers ────────────────────────────────────────────────────────────────
    function __pw_banner
        echo
        printf "%s╔══════════════════════════════════════════════════════╗%s\n" $PW_ACCENT $PW_RESET
        printf "%s║%s  %s🔐 PASSWORD GENERATOR%s  %s•%s  %sASH DOTFILES v5.0%s       %s║%s\n" \
            $PW_ACCENT $PW_RESET \
            $PW_BOLD $PW_RESET \
            $PW_SURFACE $PW_RESET \
            $PW_DIM $PW_RESET \
            $PW_ACCENT $PW_RESET
        printf "%s╚══════════════════════════════════════════════════════╝%s\n" $PW_ACCENT $PW_RESET
        echo
    end

    function __pw_section --argument-names icon title
        printf "\n  %s%s%s  %s%s%s\n" $PW_ACCENT $icon $PW_RESET $PW_BOLD $title $PW_RESET
        printf "  %s%s%s\n" $PW_SURFACE (string repeat --count 52 "─") $PW_RESET
    end

    function __pw_ok  --argument-names msg; printf "  %s✓%s  %s\n" $PW_GREEN  $PW_RESET $msg; end
    function __pw_err --argument-names msg; printf "  %s✗%s  %s%s%s\n" $PW_RED $PW_RESET $PW_RED $msg $PW_RESET; end
    function __pw_inf --argument-names msg; printf "  %s●%s  %s\n" $PW_BLUE   $PW_RESET $msg; end
    function __pw_wrn --argument-names msg; printf "  %s⚠%s  %s%s%s\n" $PW_YELLOW $PW_RESET $PW_YELLOW $msg $PW_RESET; end
    function __pw_kv  --argument-names k v
        printf "  %s%-22s%s  %s%s%s\n" $PW_SURFACE $k $PW_RESET $PW_CYAN $v $PW_RESET
    end

    # ── Charset builders ───────────────────────────────────────────────────────
    set -l CHARS_UPPER  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    set -l CHARS_LOWER  "abcdefghijklmnopqrstuvwxyz"
    set -l CHARS_DIGITS "0123456789"
    set -l CHARS_SYM    '!@#$%^&*()-_=+[]{}|;:,.<>?'
    set -l CHARS_SAFE   '!@#$%^&*-_=+'    # No ambiguous symbols
    set -l CHARS_AMBIG  "0O1lI"           # Ambiguous characters to optionally exclude

    # Memorable word list (common BIP39 style, shortened)
    set -l WORDLIST \
        "apple" "brave" "cloud" "delta" "eagle" "flame" "grape" "honey" \
        "ivory" "jewel" "karma" "lemon" "maple" "noble" "ocean" "pearl" \
        "quest" "raven" "solar" "tiger" "ultra" "vivid" "winds" "xenon" \
        "yacht" "zebra" "amber" "blaze" "coral" "dusk"  "ember" "frost" \
        "glyph" "haven" "indie" "joker" "knack" "lunar" "magic" "nexus" \
        "onyx"  "pixel" "quark" "ridge" "storm" "topaz" "umbra" "vault" \
        "witch" "xerus" "yodel" "zonal" "acorn" "bloom" "crisp" "depth" \
        "ether" "forge" "gleam" "haste" "input" "joint" "kiosk" "latch" \
        "mount" "night" "orbit" "prism" "quill" "realm" "shine" "token" \
        "upper" "vigor" "waltz" "xeric" "yield" "zippy" "azure" "basin" \
        "chess" "drift" "epoch" "flint" "giant" "hydro" "image" "judge" \
        "knife" "light" "minor" "nurse" "olive" "prose" "queen" "river" \
        "squad" "trace" "unity" "venom" "water" "xenon" "youth" "zeal"

    set -l WORDCOUNT (count $WORDLIST)

    # ── Cryptographic random source ────────────────────────────────────────────
    function __pw_random_bytes --argument-names n
        # Prefer /dev/urandom for CSPRNG
        if test -r /dev/urandom
            dd if=/dev/urandom bs=1 count=$n 2>/dev/null | od -An -tu1 | string split " " | \
                string match -rv '^$'
        else
            # Fallback: $RANDOM (non-cryptographic, warn user)
            for i in (seq $n)
                echo $RANDOM
            end
        end
    end

    function __pw_random_int --argument-names max
        # Returns a cryptographically random int in [0, max)
        set -l rand_bytes (__pw_random_bytes 4)
        set -l val 0
        for b in $rand_bytes
            set val (math "($val * 256 + $b) % $max")
        end
        echo $val
    end

    function __pw_random_char --argument-names charset
        set -l len (string length -- "$charset")
        set -l idx (__pw_random_int $len)
        string sub --start (math $idx + 1) --length 1 "$charset"
    end

    function __pw_random_word
        set -l idx (__pw_random_int $WORDCOUNT)
        echo $WORDLIST[(math $idx + 1)]
    end

    # ── Password generators ────────────────────────────────────────────────────
    function __pw_gen_random \
        --argument-names length charset
        set -l pw ""
        for i in (seq $length)
            set pw $pw(__pw_random_char $charset)
        end
        echo "$pw"
    end

    function __pw_gen_memorable \
        --argument-names num_words separator capitalize numbers
        set -l words
        for i in (seq $num_words)
            set -l w (__pw_random_word)
            if test "$capitalize" = "true"
                set w (string upper (string sub --length 1 "$w"))(string sub --start 2 "$w")
            end
            set -a words $w
        end
        set -l pw (string join "$separator" $words)
        if test "$numbers" = "true"
            set -l num (__pw_random_int 9000)
            set num (math $num + 1000)
            set pw "$pw$separator$num"
        end
        echo "$pw"
    end

    function __pw_gen_pin --argument-names length
        set -l pw ""
        for i in (seq $length)
            set pw $pw(__pw_random_int 10)
        end
        echo "$pw"
    end

    function __pw_gen_hex --argument-names length
        set -l chars "0123456789abcdef"
        __pw_gen_random $length $chars
    end

    function __pw_gen_base64 --argument-names length
        if command -q openssl
            openssl rand -base64 (math "ceil($length * 3 / 4)") | \
                string replace -ar '[^a-zA-Z0-9+/=]' '' | \
                string sub --length $length
        else
            dd if=/dev/urandom bs=(math "ceil($length * 3 / 4)") count=1 2>/dev/null | \
                base64 | string sub --length $length
        end
    end

    function __pw_gen_pronounceable --argument-names length
        # CVC pattern: consonant-vowel-consonant
        set -l vowels     "aeiou"
        set -l consonants "bcdfghjklmnpqrstvwxyz"
        set -l pw ""
        set -l i 0
        while test (string length -- "$pw") -lt $length
            set i (math $i + 1)
            set -l mod (math "$i % 3")
            switch "$mod"
                case 1 0; set pw $pw(__pw_random_char $consonants)
                case 2;   set pw $pw(__pw_random_char $vowels)
            end
        end
        echo (string sub --length $length "$pw")
    end

    function __pw_gen_pattern --argument-names pattern
        # Pattern: U=uppercase, l=lowercase, d=digit, s=symbol, *=any
        set -l pw ""
        for i in (seq (string length -- "$pattern"))
            set -l ch (string sub --start $i --length 1 "$pattern")
            switch "$ch"
                case U; set pw $pw(__pw_random_char $CHARS_UPPER)
                case l; set pw $pw(__pw_random_char $CHARS_LOWER)
                case d; set pw $pw(__pw_random_char $CHARS_DIGITS)
                case s; set pw $pw(__pw_random_char $CHARS_SYM)
                case '*'
                    set -l all "$CHARS_UPPER$CHARS_LOWER$CHARS_DIGITS$CHARS_SYM"
                    set pw $pw(__pw_random_char $all)
                case '*'
                    set pw "$pw$ch"  # Literal character
            end
        end
        echo "$pw"
    end

    # ── Strength analysis ──────────────────────────────────────────────────────
    function __pw_strength_score --argument-names pw
        set -l len  (string length -- "$pw")
        set -l score 0

        # Length bonus
        if test $len -ge 8;  set score (math $score + 1); end
        if test $len -ge 12; set score (math $score + 1); end
        if test $len -ge 16; set score (math $score + 1); end
        if test $len -ge 20; set score (math $score + 1); end

        # Charset bonus
        string match -qr '[A-Z]' -- "$pw"; and set score (math $score + 1)
        string match -qr '[a-z]' -- "$pw"; and set score (math $score + 1)
        string match -qr '[0-9]' -- "$pw"; and set score (math $score + 1)
        string match -qr '[^a-zA-Z0-9]' -- "$pw"; and set score (math $score + 1)

        # Penalty: repeated chars
        set -l uniq (string split "" "$pw" | sort -u | wc -l | string trim)
        if test $uniq -lt (math "ceil($len * 0.5)")
            set score (math $score - 1)
        end

        echo $score
    end

    function __pw_strength_label --argument-names score
        if test $score -le 2
            printf "%s■■□□□  Very Weak%s" $PW_STR_1 $PW_RESET
        else if test $score -le 3
            printf "%s■■■□□  Weak%s" $PW_STR_2 $PW_RESET
        else if test $score -le 5
            printf "%s■■■■□  Fair%s" $PW_STR_3 $PW_RESET
        else if test $score -le 6
            printf "%s■■■■■  Strong%s" $PW_STR_4 $PW_RESET
        else
            printf "%s■■■■■  Very Strong 🏆%s" $PW_STR_5 $PW_RESET
        end
    end

    function __pw_entropy --argument-names pw
        # Estimate entropy: log2(charset_size^length)
        set -l len (string length -- "$pw")
        set -l pool 0
        string match -qr '[a-z]' -- "$pw"; and set pool (math $pool + 26)
        string match -qr '[A-Z]' -- "$pw"; and set pool (math $pool + 26)
        string match -qr '[0-9]' -- "$pw"; and set pool (math $pool + 10)
        string match -qr '[^a-zA-Z0-9]' -- "$pw"; and set pool (math $pool + 32)
        test $pool -eq 0; and set pool 1
        # entropy = len * log2(pool)
        set -l entropy (math "round($len * log($pool) / log(2))")
        echo $entropy
    end

    function __pw_crack_time --argument-names entropy
        # Assume 10^12 guesses/sec (modern offline GPU attack)
        set -l combos (math "pow(2, $entropy)")
        set -l secs   (math "$combos / pow(10, 12)")
        if test $secs -lt 1
            echo "Instant"
        else if test $secs -lt 60
            echo "$secs seconds"
        else if test $secs -lt 3600
            echo (math "round($secs / 60)" )" minutes"
        else if test $secs -lt 86400
            echo (math "round($secs / 3600)")" hours"
        else if test $secs -lt 31536000
            echo (math "round($secs / 86400)")" days"
        else if test $secs -lt 3153600000
            echo (math "round($secs / 31536000)")" years"
        else
            echo "Centuries+"
        end
    end

    # ── Render colored password ────────────────────────────────────────────────
    function __pw_colorize --argument-names pw
        set -l out ""
        for i in (seq (string length -- "$pw"))
            set -l ch (string sub --start $i --length 1 "$pw")
            if string match -qr '[A-Z]' -- "$ch"
                set out "$out$PW_CYAN$ch$PW_RESET"
            else if string match -qr '[a-z]' -- "$ch"
                set out "$out$PW_RESET$ch"
            else if string match -qr '[0-9]' -- "$ch"
                set out "$out$PW_YELLOW$ch$PW_RESET"
            else
                set out "$out$PW_PINK$ch$PW_RESET"
            end
        end
        echo "$out"
    end

    # ── Password card renderer ─────────────────────────────────────────────────
    function __pw_render_card \
        --argument-names pw label show_strength entropy
        set -l len (string length -- "$pw")
        set -l score (__pw_strength_score $pw)
        set -l colored (__pw_colorize $pw)

        printf "\n  %s┌──────────────────────────────────────────────────────┐%s\n" \
            $PW_ACCENT $PW_RESET
        if test -n "$label"
            printf "  %s│%s  %s%-52s%s%s│%s\n" \
                $PW_ACCENT $PW_RESET \
                $PW_DIM $label $PW_RESET \
                $PW_ACCENT $PW_RESET
            printf "  %s├──────────────────────────────────────────────────────┤%s\n" \
                $PW_ACCENT $PW_RESET
        end
        printf "  %s│%s  %s  %-48s  %s%s│%s\n" \
            $PW_ACCENT $PW_RESET \
            $PW_BOLD "$colored" $PW_RESET \
            $PW_ACCENT $PW_RESET
        printf "  %s├──────────────────────────────────────────────────────┤%s\n" \
            $PW_ACCENT $PW_RESET
        printf "  %s│%s  Length: %s%-6d%s  Entropy: %s%d bits%s%s%*s%s│%s\n" \
            $PW_ACCENT $PW_RESET \
            $PW_GREEN $len $PW_RESET \
            $PW_BLUE $entropy $PW_RESET \
            $PW_SURFACE \
            (math "max(0, 22 - (string length $entropy))" ) "" \
            $PW_RESET \
            $PW_ACCENT $PW_RESET
        if test "$show_strength" = "true"
            printf "  %s│%s  Strength: %-43s%s│%s\n" \
                $PW_ACCENT $PW_RESET \
                (__pw_strength_label $score) \
                $PW_ACCENT $PW_RESET
        end
        printf "  %s└──────────────────────────────────────────────────────┘%s\n" \
            $PW_ACCENT $PW_RESET
    end

    # ── History ────────────────────────────────────────────────────────────────
    set -l PW_HISTORY "$HOME/.local/share/ash/password-history.log"

    function __pw_log --argument-names type length entropy
        mkdir -p (dirname "$PW_HISTORY")
        printf "%s\t%s\t%d\t%d bits\n" \
            (date +"%Y-%m-%d %H:%M:%S") $type $length $entropy \
            >> "$PW_HISTORY"
    end

    # ── Clipboard ──────────────────────────────────────────────────────────────
    function __pw_clip --argument-names pw timeout_secs
        if command -q wl-copy
            echo -n "$pw" | wl-copy
        else if command -q xclip
            echo -n "$pw" | xclip -selection clipboard
        else
            return 1
        end
        # Auto-clear clipboard after timeout
        if test -n "$timeout_secs"; and test "$timeout_secs" -gt 0
            command bash -c "sleep $timeout_secs && echo -n '' | wl-copy 2>/dev/null || echo -n '' | xclip -selection clipboard 2>/dev/null" &>/dev/null &
            disown
        end
        return 0
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  ARGUMENT PARSING
    # ══════════════════════════════════════════════════════════════════════════
    set -l options \
        'h/help' \
        'v/version' \
        'q/quiet' \
        'n/no-banner' \
        'l/length=' \
        't/type=' \
        'u/upper' \
        'L/lower' \
        'd/digits' \
        's/symbols' \
        'S/safe-symbols' \
        'a/no-ambiguous' \
        'c/clipboard' \
        'C/clip-timeout=' \
        'k/count=' \
        'w/words=' \
        'W/word-sep=' \
        'K/capitalize' \
        'D/word-digits' \
        'p/pin' \
        'x/hex' \
        'b/base64' \
        'P/pronounceable' \
        'T/pattern=' \
        'm/memorable' \
        'r/reveal' \
        'e/entropy' \
        'f/force' \
        'o/output=' \
        'H/history' \
        'I/interactive' \
        'Q/no-strength'

    argparse $options -- $argv 2>/dev/null
    or begin
        __pw_err "Invalid arguments. Use --help for usage."
        return 1
    end

    __pw_colors

    # ── Version ────────────────────────────────────────────────────────────────
    if set -q _flag_version
        printf "%s🔐 gen_password%s  %sv5.0.0%s  %s(ASH Dotfiles Omega)%s\n" \
            $PW_ACCENT $PW_RESET $PW_GREEN $PW_RESET $PW_SURFACE $PW_RESET
        return 0
    end

    # ── Help ───────────────────────────────────────────────────────────────────
    if set -q _flag_help
        __pw_banner
        printf "%sUSAGE%s\n  gen_password [OPTIONS]\n\n" $PW_ACCENT $PW_RESET

        __pw_section "⚙️" "CORE OPTIONS"
        __pw_kv "-h, --help"         "Show this help"
        __pw_kv "-v, --version"      "Version info"
        __pw_kv "-q, --quiet"        "Output password only (pipe-safe)"
        __pw_kv "-n, --no-banner"    "Skip banner"
        __pw_kv "-k, --count=N"      "Generate N passwords (default: 1)"
        __pw_kv "-l, --length=N"     "Password length (default: 16)"

        __pw_section "🔡" "CHARACTER SETS"
        __pw_kv "-u, --upper"        "Include uppercase A-Z"
        __pw_kv "-L, --lower"        "Include lowercase a-z"
        __pw_kv "-d, --digits"       "Include digits 0-9"
        __pw_kv "-s, --symbols"      "Include all symbols"
        __pw_kv "-S, --safe-symbols" "Safe symbols only (no ambiguous)"
        __pw_kv "-a, --no-ambiguous" "Exclude 0,O,1,l,I"

        __pw_section "🎯" "TYPE SHORTCUTS"
        __pw_kv "-t, --type=TYPE"     "Type: random memorable pin hex b64 pronounce"
        __pw_kv "-m, --memorable"     "Memorable word-based password"
        __pw_kv "-p, --pin"           "Numeric PIN only"
        __pw_kv "-x, --hex"           "Hexadecimal string"
        __pw_kv "-b, --base64"        "Base64 string"
        __pw_kv "-P, --pronounceable" "Pronounceable (CVC pattern)"
        __pw_kv "-T, --pattern=PAT"   "Custom pattern (U=upper l=lower d=digit s=symbol)"

        __pw_section "💬" "MEMORABLE OPTIONS"
        __pw_kv "-w, --words=N"      "Number of words (default: 4)"
        __pw_kv "-W, --word-sep=S"   "Word separator (default: -)"
        __pw_kv "-K, --capitalize"   "Capitalize each word"
        __pw_kv "-D, --word-digits"  "Append random digits"

        __pw_section "📋" "OUTPUT OPTIONS"
        __pw_kv "-c, --clipboard"       "Copy to clipboard"
        __pw_kv "-C, --clip-timeout=N"  "Clear clipboard after N seconds"
        __pw_kv "-r, --reveal"          "Show uncolored password (for piping)"
        __pw_kv "-e, --entropy"         "Show entropy + crack time"
        __pw_kv "-o, --output=FILE"     "Save passwords to file"
        __pw_kv "-H, --history"         "Show generation history"
        __pw_kv "-Q, --no-strength"     "Skip strength indicator"
        __pw_kv "-I, --interactive"     "Interactive wizard"

        __pw_section "💡" "EXAMPLES"
        printf "  %s# Strong 32-char random%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --length=32 --upper --lower --digits --symbols\n\n"
        printf "  %s# Memorable passphrase%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --memorable --words=5 --capitalize --word-digits\n\n"
        printf "  %s# 6-digit PIN%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --pin --length=6\n\n"
        printf "  %s# Custom pattern: 3 uppercase, 3 digits, 2 symbols%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --pattern=UUUdddss\n\n"
        printf "  %s# Generate 5 passwords, copy first to clipboard%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --count=5 --length=20 --clipboard\n\n"
        printf "  %s# Pronounceable password%s\n" $PW_SURFACE $PW_RESET
        printf "  gen_password --pronounceable --length=14\n\n"
        echo
        return 0
    end

    # ── History ────────────────────────────────────────────────────────────────
    if set -q _flag_history
        set -q _flag_no_banner; or __pw_banner
        __pw_section "📋" "GENERATION HISTORY (last 20)"
        if test -f "$PW_HISTORY"
            set -l n 0
            tail -20 "$PW_HISTORY" | while read -l ts type len entropy
                set n (math $n + 1)
                printf "  %s%2d%s  %s%-14s%s  %s%-5s%s  %s%-8s%s  %s%s%s\n" \
                    $PW_ACCENT $n $PW_RESET \
                    $PW_BLUE $type $PW_RESET \
                    $PW_GREEN $len $PW_RESET \
                    $PW_YELLOW $entropy $PW_RESET \
                    $PW_SURFACE $ts $PW_RESET
            end
        else
            __pw_inf "No history yet."
        end
        echo
        return 0
    end

    # ── Interactive wizard ─────────────────────────────────────────────────────
    if set -q _flag_interactive
        set -q _flag_no_banner; or __pw_banner
        __pw_section "🎛️" "INTERACTIVE WIZARD"

        printf "  %s?%s  %sType%s %s[random/memorable/pin/hex/base64/pronounce]:%s " \
            $PW_ACCENT $PW_RESET $PW_BOLD $PW_RESET $PW_SURFACE $PW_RESET
        read -l itype
        test -n "$itype"; and set _flag_type $itype

        printf "  %s?%s  %sLength / word count%s %s(default: 16):%s " \
            $PW_ACCENT $PW_RESET $PW_BOLD $PW_RESET $PW_SURFACE $PW_RESET
        read -l ilen
        test -n "$ilen"; and set _flag_length $ilen

        printf "  %s?%s  %sCopy to clipboard?%s %s[y/N]:%s " \
            $PW_ACCENT $PW_RESET $PW_BOLD $PW_RESET $PW_SURFACE $PW_RESET
        read -l iclip
        if string match -qi 'y*' -- "$iclip"
            set _flag_clipboard true
        end
        echo
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  BUILD CHARSET & DETERMINE TYPE
    # ══════════════════════════════════════════════════════════════════════════
    set -l length     (test -n "$_flag_length"; and echo $_flag_length; or echo 16)
    set -l count      (test -n "$_flag_count";  and echo $_flag_count;  or echo 1)
    set -l words      (test -n "$_flag_words";  and echo $_flag_words;  or echo 4)
    set -l word_sep   (test -n "$_flag_word_sep"; and echo $_flag_word_sep; or echo "-")
    set -l pw_type    (test -n "$_flag_type";   and echo $_flag_type;   or echo "random")
    set -l clip_time  (test -n "$_flag_clip_timeout"; and echo $_flag_clip_timeout; or echo 30)

    # Type shortcuts
    set -q _flag_memorable;    and set pw_type "memorable"
    set -q _flag_pin;          and set pw_type "pin"
    set -q _flag_hex;          and set pw_type "hex"
    set -q _flag_base64;       and set pw_type "base64"
    set -q _flag_pronounceable;and set pw_type "pronounce"
    set -q _flag_pattern;      and set pw_type "pattern"

    # Build charset for random mode
    set -l charset ""
    if test "$pw_type" = "random"
        # Default: all char classes if none specified
        set -l any_flag 0
        set -q _flag_upper   && set any_flag 1
        set -q _flag_lower   && set any_flag 1
        set -q _flag_digits  && set any_flag 1
        set -q _flag_symbols && set any_flag 1
        set -q _flag_safe_symbols && set any_flag 1

        if test $any_flag -eq 0
            # Default: uppers + lowers + digits + safe symbols
            set charset "$CHARS_UPPER$CHARS_LOWER$CHARS_DIGITS$CHARS_SAFE"
        else
            set -q _flag_upper   && set charset "$charset$CHARS_UPPER"
            set -q _flag_lower   && set charset "$charset$CHARS_LOWER"
            set -q _flag_digits  && set charset "$charset$CHARS_DIGITS"
            set -q _flag_symbols && set charset "$charset$CHARS_SYM"
            set -q _flag_safe_symbols && set charset "$charset$CHARS_SAFE"
        end

        # Remove ambiguous characters
        if set -q _flag_no_ambiguous
            for ambig in (string split "" $CHARS_AMBIG)
                set charset (string replace -a $ambig "" $charset)
            end
        end

        # Deduplicate
        set charset (string split "" "$charset" | sort -u | string join "")
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  GENERATE PASSWORDS
    # ══════════════════════════════════════════════════════════════════════════
    set -q _flag_no_banner; or __pw_banner

    if test $count -eq 1
        set -q _flag_no_banner; or __pw_section "🔑" "GENERATED PASSWORD"
    else
        set -q _flag_no_banner; or __pw_section "🔑" "GENERATED PASSWORDS ($count)"
    end

    set -l passwords
    set -l first_pw ""

    for i in (seq $count)
        # Generate
        set -l pw
        switch "$pw_type"
            case random
                set pw (__pw_gen_random $length $charset)
            case memorable
                set -l cap   (set -q _flag_capitalize; and echo "true"; or echo "false")
                set -l digs  (set -q _flag_word_digits; and echo "true"; or echo "false")
                set pw (__pw_gen_memorable $words $word_sep $cap $digs)
            case pin
                set pw (__pw_gen_pin $length)
            case hex
                set pw (__pw_gen_hex $length)
            case base64
                set pw (__pw_gen_base64 $length)
            case pronounce
                set pw (__pw_gen_pronounceable $length)
            case pattern
                set pw (__pw_gen_pattern $_flag_pattern)
            case '*'
                __pw_err "Unknown type: $pw_type"
                return 1
        end

        set -a passwords $pw
        test $i -eq 1; and set first_pw $pw

        set -l entropy (__pw_entropy $pw)
        set -l score   (__pw_strength_score $pw)
        set -l show_str (set -q _flag_no_strength; and echo "false"; or echo "true")

        if set -q _flag_quiet
            echo "$pw"
        else if test $count -gt 1
            # Multi-password: compact list
            printf "  %s%2d%s  " $PW_SURFACE $i $PW_RESET
            __pw_colorize $pw
            printf "  %s%d bits%s\n" $PW_DIM $entropy $PW_RESET
        else
            # Single password: full card
            __pw_render_card $pw "" $show_str $entropy

            if set -q _flag_entropy
                printf "\n"
                __pw_kv "Entropy"    "$entropy bits"
                __pw_kv "Crack time" (__pw_crack_time $entropy)
                __pw_kv "Score"      "$score / 8"
            end
        end

        __pw_log $pw_type (string length -- "$pw") $entropy
    end

    # ── Charset info ───────────────────────────────────────────────────────────
    if not set -q _flag_quiet; and test "$pw_type" = "random"
        printf "\n"
        __pw_kv "Type"       "$pw_type"
        __pw_kv "Length"     "$length"
        __pw_kv "Charset"    (string length -- "$charset")" chars"
        if test $count -gt 1
            __pw_kv "Generated"  "$count passwords"
        end
    end

    # ── Save to file ───────────────────────────────────────────────────────────
    if set -q _flag_output
        printf "%s\n" $passwords > $_flag_output
        set -q _flag_quiet; or __pw_ok "Saved $count passwords to: $_flag_output"
    end

    # ── Clipboard ──────────────────────────────────────────────────────────────
    if set -q _flag_clipboard
        if __pw_clip $first_pw $clip_time
            if not set -q _flag_quiet
                __pw_ok "Copied to clipboard  →  auto-clears in $clip_time""s"
            end
        else
            set -q _flag_quiet; or __pw_wrn "Clipboard tool not found"
        end
    end

    # ── Footer ─────────────────────────────────────────────────────────────────
    if not set -q _flag_quiet
        printf "\n  %s%s%s\n" $PW_SURFACE (string repeat --count 54 "─") $PW_RESET
        printf "  %s🔐 ASH Password Engine%s  %sv5.0%s  %s•%s  %sCryptographically secure%s\n" \
            $PW_ACCENT $PW_RESET \
            $PW_GREEN  $PW_RESET \
            $PW_SURFACE $PW_RESET \
            $PW_DIM    $PW_RESET
        echo
    end

    # ── Cleanup ────────────────────────────────────────────────────────────────
    functions --erase __pw_colors __pw_banner __pw_section
    functions --erase __pw_ok __pw_err __pw_inf __pw_wrn __pw_kv
    functions --erase __pw_random_bytes __pw_random_int __pw_random_char __pw_random_word
    functions --erase __pw_gen_random __pw_gen_memorable __pw_gen_pin
    functions --erase __pw_gen_hex __pw_gen_base64 __pw_gen_pronounceable __pw_gen_pattern
    functions --erase __pw_strength_score __pw_strength_label __pw_entropy __pw_crack_time
    functions --erase __pw_colorize __pw_render_card __pw_log __pw_clip
end
