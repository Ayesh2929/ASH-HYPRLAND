#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🌍  TRANSLATE.FISH  ·  ASH Dotfiles v5.0 OMEGA                                  ║
# ║  Ultra Multi-Engine Translation System                                           ║
# ║  LibreTranslate · Google · DeepL · Argos · Interactive · History · TTS           ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   translate <text>                   — Auto-detect → English
#   translate <text> -t <lang>         — Translate to language
#   translate <text> -f <lang> -t <lang> — Specify source+target
#   translate -i / --interactive       — Interactive mode
#   translate -l / --langs             — List supported languages
#   translate -h / --history           — Translation history
#   translate -c / --clipboard         — Translate clipboard content
#   translate --tts <text>             — Text-to-speech
#   translate --engine <name>          — Choose engine

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __TR_VERSION   "5.0.0"
set -g __TR_DATA_DIR  "$HOME/.local/share/ash/translate"
set -g __TR_HIST_FILE "$__TR_DATA_DIR/history.tsv"
set -g __TR_CACHE_DIR "$HOME/.cache/ash/translate"
set -g __TR_CACHE_TTL 86400   # 24h

# Default engine (argos/google/libretranslate/deepl)
set -g __TR_DEFAULT_ENGINE "argos"
set -g __TR_LIBRETRANSLATE_URL "http://localhost:5000"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  LANGUAGE MAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# code:name pairs
set -g __TR_LANGS \
    "en:English" "es:Spanish" "fr:French" "de:German" \
    "it:Italian" "pt:Portuguese" "ru:Russian" "zh:Chinese" \
    "ja:Japanese" "ko:Korean" "ar:Arabic" "hi:Hindi" \
    "nl:Dutch" "pl:Polish" "tr:Turkish" "sv:Swedish" \
    "da:Danish" "fi:Finnish" "no:Norwegian" "cs:Czech" \
    "ro:Romanian" "hu:Hungarian" "uk:Ukrainian" "el:Greek" \
    "he:Hebrew" "id:Indonesian" "ms:Malay" "th:Thai" \
    "vi:Vietnamese" "bn:Bengali" "fa:Persian" "ca:Catalan" \
    "bg:Bulgarian" "hr:Croatian" "sk:Slovak" "sl:Slovenian" \
    "lt:Lithuanian" "lv:Latvian" "et:Estonian"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  PALETTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g _R  (set_color normal)
set -g _B  (set_color --bold)
set -g _D  (set_color brblack)
set -g _W  (set_color white)
set -g _RE (set_color brred)
set -g _GR (set_color brgreen)
set -g _YE (set_color bryellow)
set -g _BL (set_color brblue)
set -g _CY (set_color brcyan)
set -g _MG (set_color brmagenta)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  INTERNAL UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_dirs
    mkdir -p $__TR_DATA_DIR $__TR_CACHE_DIR
end

function __tr_ok   -a m; echo "$_GR  ✔  $m$_R"; end
function __tr_err  -a m; echo "$_RE  ✘  $m$_R" >&2; end
function __tr_warn -a m; echo "$_YE  ⚠  $m$_R"; end
function __tr_tip  -a m; echo "$_CY  ›  $m$_R"; end
function __tr_info -a m; echo "$_BL  ℹ  $m$_R"; end

# ── language name from code ───────────────────────────────────────────────────

function __tr_lang_name -a code
    for entry in $__TR_LANGS
        set -l parts (string split ':' $entry)
        if test "$parts[1]" = "$code"
            echo $parts[2]
            return
        end
    end
    echo $code
end

# ── cache ─────────────────────────────────────────────────────────────────────

function __tr_cache_key -a text from to engine
    echo (echo "$engine:$from:$to:$text" | md5sum | cut -c1-16)
end

function __tr_cache_get -a key
    set -l f "$__TR_CACHE_DIR/$key.txt"
    test -f $f; or return 1
    set -l now  (date +%s)
    set -l mod  (stat -c %Y $f 2>/dev/null; or stat -f %m $f 2>/dev/null)
    test (math $now - $mod) -lt $__TR_CACHE_TTL; or begin rm -f $f; return 1; end
    cat $f
end

function __tr_cache_set -a key value
    __tr_dirs
    echo $value > "$__TR_CACHE_DIR/$key.txt"
end

# ── log to history ────────────────────────────────────────────────────────────

function __tr_log -a from to text result
    __tr_dirs
    printf "%s\t%s\t%s\t%s\t%s\n" \
        (date '+%Y-%m-%d %H:%M') \
        $from $to \
        (string shorten -m 60 $text) \
        (string shorten -m 60 $result) \
        >> $__TR_HIST_FILE
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  TRANSLATION ENGINES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── engine: argos-translate (offline CLI) ─────────────────────────────────────

function __tr_engine_argos -a text from to
    if not command -q argos-translate
        return 1
    end
    set -l from_flag (test "$from" = "auto"; and echo ""; or echo "--from-lang $from")
    eval argos-translate $from_flag --to-lang $to "$text" 2>/dev/null
end

# ── engine: translate-shell (googletrans wrapper) ─────────────────────────────

function __tr_engine_trans -a text from to
    if not command -q trans
        return 1
    end
    set -l pair (test "$from" = "auto"; and echo ":$to"; or echo "$from:$to")
    trans -brief $pair "$text" 2>/dev/null
end

# ── engine: python googletrans ────────────────────────────────────────────────

function __tr_engine_google -a text from to
    command -q python3; or return 1
    python3 -c "
try:
    from googletrans import Translator
    t = Translator()
    src = None if '$from' == 'auto' else '$from'
    r = t.translate('$text', dest='$to', src=src)
    print(r.text)
except Exception as e:
    exit(1)
" 2>/dev/null
end

# ── engine: libretranslate API ────────────────────────────────────────────────

function __tr_engine_libretranslate -a text from to
    command -q curl; or return 1
    set -l src (test "$from" = "auto"; and echo "auto"; or echo $from)
    curl -sf --max-time 10 \
        -X POST "$__TR_LIBRETRANSLATE_URL/translate" \
        -H "Content-Type: application/json" \
        -d "{\"q\":\"$text\",\"source\":\"$src\",\"target\":\"$to\"}" \
        2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['translatedText'])" 2>/dev/null
end

# ── engine: mymemory (free REST API, no key needed) ──────────────────────────

function __tr_engine_mymemory -a text from to
    command -q curl; or return 1
    set -l src (test "$from" = "auto"; and echo "en"; or echo $from)
    set -l encoded (python3 -c "import urllib.parse; print(urllib.parse.quote('$text'))" 2>/dev/null)
    curl -sf --max-time 10 \
        "https://api.mymemory.translated.net/get?q=$encoded&langpair=$src|$to" \
        2>/dev/null \
        | python3 -c "
import sys,json
d=json.load(sys.stdin)
t=d['responseData']['translatedText']
print(t)
" 2>/dev/null
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  MAIN TRANSLATE ENGINE DISPATCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_translate -a text from to engine
    test -z "$engine"; and set engine $__TR_DEFAULT_ENGINE

    # Check cache
    set -l key (__tr_cache_key $text $from $to $engine)
    set -l cached (__tr_cache_get $key)
    if test $status -eq 0 -a -n "$cached"
        echo $cached
        return 0
    end

    set -l result ""

    # Try chosen engine, then fallback chain
    set -l engines $engine trans argos mymemory google libretranslate

    for eng in $engines
        switch $eng
            case argos
                set result (__tr_engine_argos $text $from $to)
            case trans
                set result (__tr_engine_trans $text $from $to)
            case google
                set result (__tr_engine_google $text $from $to)
            case mymemory
                set result (__tr_engine_mymemory $text $from $to)
            case libretranslate
                set result (__tr_engine_libretranslate $text $from $to)
        end
        test -n "$result"; and break
    end

    if test -z "$result"
        __tr_err "All translation engines failed"
        return 1
    end

    __tr_cache_set $key $result
    __tr_log $from $to $text $result
    echo $result
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  DISPLAY RESULT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_display -a text result from to engine
    set -l from_name (__tr_lang_name $from)
    set -l to_name   (__tr_lang_name $to)

    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════╗$_R"
    printf "$_BL  ║$_R  🌍  $_CY$_B Translation$_R  $_D%s → %s$_R  ($_D%s$_R)%s  $_BL║$_R\n" \
        $from_name $to_name $engine \
        (string repeat -n (math 14 - (string length $engine)) ' ')
    echo "$_BL  ╠══════════════════════════════════════════════════════════╣$_R"
    echo "$_BL  ║$_R  $_D Source:$_R"
    echo "$_BL  ║$_R    $_W$text$_R"
    echo "$_BL  ║$_R"
    echo "$_BL  ║$_R  $_D Translation:$_R"
    echo "$_BL  ║$_R    $_GR$result$_R"
    echo "$_BL  ╚══════════════════════════════════════════════════════════╝$_R"
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  LANGUAGE PICKER (fzf)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_pick_lang -a prompt_text
    printf '%s\n' $__TR_LANGS \
        | awk -F: '{printf "%-6s %s\n", $1, $2}' \
        | fzf \
            --prompt "  $prompt_text ❯ " \
            --height=55% \
            --layout=reverse \
            --border=rounded \
            --no-preview \
            --color="header:italic:cyan" \
        | awk '{print $1}'
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  TTS (text-to-speech)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_tts -a text lang
    test -z "$lang"; and set lang "en"
    if command -q espeak-ng
        espeak-ng -v $lang "$text" 2>/dev/null; and return 0
    else if command -q espeak
        espeak -v $lang "$text" 2>/dev/null; and return 0
    else if command -q festival
        echo "$text" | festival --tts 2>/dev/null; and return 0
    else if command -q say  # macOS
        say -v Auto "$text" 2>/dev/null; and return 0
    else
        # Google TTS via curl (requires mpv/ffplay)
        if command -q curl; and command -q mpv
            set -l encoded (python3 -c "import urllib.parse; print(urllib.parse.quote('$text'))" 2>/dev/null)
            set -l url "https://translate.google.com/translate_tts?ie=UTF-8&q=$encoded&tl=$lang&client=gtx"
            curl -sA "Mozilla/5.0" "$url" 2>/dev/null | mpv - 2>/dev/null
            return 0
        end
        __tr_err "No TTS engine found (install espeak-ng or espeak)"
        return 1
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  INTERACTIVE MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_interactive
    command -q fzf; or begin
        __tr_err "fzf required for interactive mode"
        return 1
    end

    # Pick target language
    set -l to (__tr_pick_lang "🌍 Target language")
    test -z "$to"; and return 0

    set -l from "auto"
    set -l to_name (__tr_lang_name $to)

    echo ""
    __tr_info "Interactive mode: auto → $_CY$to_name$_R  (Ctrl+C to exit)"
    echo ""

    while true
        set -l text (read -P "  📝 Text to translate (empty=exit): ")
        test -z "$text"; and break

        set -l result (__tr_translate $text $from $to $__TR_DEFAULT_ENGINE)
        if test $status -eq 0 -a -n "$result"
            __tr_display $text $result $from $to $__TR_DEFAULT_ENGINE

            # Copy to clipboard?
            set -l clip (read -P "  📋 Copy translation? [y/N] ")
            if test "$clip" = "y" -o "$clip" = "Y"
                command -q wl-copy; and echo $result | wl-copy; and __tr_ok "Copied"
                command -q xclip;  and echo $result | xclip -selection clipboard
            end

            # TTS?
            set -l tts_ask (read -P "  🔊 Speak translation? [y/N] ")
            test "$tts_ask" = "y" -o "$tts_ask" = "Y"
                and __tr_tts $result $to &
        end
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HISTORY VIEWER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_history
    __tr_dirs
    if not test -s $__TR_HIST_FILE
        __tr_warn "No translation history yet"
        return 1
    end

    set -l count (wc -l < $__TR_HIST_FILE | string trim)

    echo ""
    echo "$_BL  ┌─ $_YE📜 Translation History ($count entries)$_R"
    echo ""

    if command -q fzf
        set -l result (tac $__TR_HIST_FILE | fzf \
            --prompt "  📜 History ❯ " \
            --height=70% \
            --layout=reverse \
            --border=rounded \
            --ansi \
            --delimiter='\t' \
            --with-nth=1,2,3,4 \
            --preview '
                echo {} | awk -F"\t" "{
                    print \"Time:   \" \$1
                    print \"From:   \" \$2
                    print \"To:     \" \$3
                    print \"Source: \" \$4
                    print \"Result: \" \$5
                }"
            ' \
            --preview-window "bottom:6:wrap" \
            --header "  Enter=copy result  Ctrl+D=delete  Esc=exit")

        if test -n "$result"
            set -l translation (echo $result | awk -F'\t' '{print $5}')
            command -q wl-copy; and echo $translation | wl-copy; and __tr_ok "Copied"
            command -q xclip;  and echo $translation | xclip -selection clipboard
        end
    else
        cat $__TR_HIST_FILE | while read -l line
            set -l parts (string split '\t' $line)
            printf "  $_D%-18s$_R $_MG%s→%s$_R  $_W%s$_R  $_GR%s$_R\n" \
                $parts[1] $parts[2] $parts[3] \
                (string shorten -m 30 $parts[4]) \
                (string shorten -m 30 $parts[5])
        end | tail -30
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __tr_help
    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  🌍  $_CY$_B translate$_R  ·  $_D v$__TR_VERSION · ASH Dotfiles OMEGA$_R       $_BL║$_R"
    echo "$_BL  ╚══════════════════════════════════════════════════════════════╝$_R"
    echo ""
    printf "  $_YE%-40s$_R %s\n" "USAGE" "DESCRIPTION"
    printf "  $_D%s$_R\n" (string repeat -n 68 '─')
    printf "  $_GR%-40s$_R %s\n" "translate <text>"                "Auto → English"
    printf "  $_GR%-40s$_R %s\n" "translate <text> -t <lang>"      "Translate to lang"
    printf "  $_GR%-40s$_R %s\n" "translate <text> -f <l> -t <l>"  "Specify source+target"
    printf "  $_GR%-40s$_R %s\n" "translate -i / --interactive"    "Interactive session"
    printf "  $_GR%-40s$_R %s\n" "translate -l / --langs"          "List languages"
    printf "  $_GR%-40s$_R %s\n" "translate -h / --history"        "Translation history"
    printf "  $_GR%-40s$_R %s\n" "translate -c / --clipboard"      "Translate clipboard"
    printf "  $_GR%-40s$_R %s\n" "translate --tts <text>"          "Text-to-speech"
    printf "  $_GR%-40s$_R %s\n" "translate --engine <name>"       "Choose engine"
    printf "  $_GR%-40s$_R %s\n" "translate --flush-cache"         "Clear translation cache"
    echo ""
    echo "  $_YE  ENGINES$_R"
    printf "  $_D%-38s$_R %s\n" (string repeat -n 38 '─') (string repeat -n 28 '─')
    printf "  $_CY%-20s$_R %s\n" "argos"          "Offline (argos-translate CLI)"
    printf "  $_CY%-20s$_R %s\n" "trans"          "translate-shell (googletrans)"
    printf "  $_CY%-20s$_R %s\n" "mymemory"       "Free REST API (no key)"
    printf "  $_CY%-20s$_R %s\n" "google"         "googletrans Python lib"
    printf "  $_CY%-20s$_R %s\n" "libretranslate" "Self-hosted LibreTranslate"
    echo ""
    echo "  $_YE  EXAMPLES$_R"
    printf "  $_D%s$_R\n" (string repeat -n 50 '─')
    echo '  $_D  translate "Hello world" -t es$_R'
    echo '  $_D  translate "Bonjour" -f fr -t de$_R'
    echo '  $_D  translate -i   (interactive session)$_R'
    echo '  $_D  translate --tts "こんにちは" $_R'
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function translate --description "🌍 Ultra multi-engine translation system"
    test (count $argv) -eq 0; and begin __tr_help; return 0; end

    set -l text     ""
    set -l from     "auto"
    set -l to       "en"
    set -l engine   $__TR_DEFAULT_ENGINE
    set -l tts_mode 0
    set -l copy_out 0

    # ── parse args ────────────────────────────────────────────────────────────
    set -l i 1
    while test $i -le (count $argv)
        set -l a $argv[$i]
        switch $a
            case -h --help;       __tr_help; return 0
            case -i --interactive; __tr_interactive; return $status
            case -l --langs
                printf '%s\n' $__TR_LANGS | awk -F: '{printf "  %-6s %s\n", $1, $2}'
                return 0
            case --history;       __tr_history; return $status
            case -c --clipboard
                if command -q wl-paste
                    set text (wl-paste 2>/dev/null)
                else if command -q xclip
                    set text (xclip -selection clipboard -o 2>/dev/null)
                else
                    __tr_err "No clipboard tool"
                    return 1
                end
            case --tts
                set tts_mode 1
            case -f --from
                set i (math $i + 1)
                set from $argv[$i]
            case -t --to
                set i (math $i + 1)
                set to $argv[$i]
            case --engine
                set i (math $i + 1)
                set engine $argv[$i]
            case -C --copy
                set copy_out 1
            case --flush-cache
                rm -f $__TR_CACHE_DIR/*.txt
                __tr_ok "Cache cleared"
                return 0
            case --version
                echo "$_CY  🌍  translate v$__TR_VERSION$_R"
                return 0
            case '*'
                test -z "$text"
                    and set text $a
                    or  set text "$text $a"
        end
        set i (math $i + 1)
    end

    test -z "$text"; and begin __tr_err "No text provided"; return 1; end

    # TTS only mode
    if test $tts_mode -eq 1
        __tr_tts $text $to
        return $status
    end

    # Translate
    set -l result (__tr_translate $text $from $to $engine)
    if test $status -ne 0; return 1; end

    __tr_display $text $result $from $to $engine

    # Auto-copy if requested
    if test $copy_out -eq 1
        command -q wl-copy; and echo $result | wl-copy; and __tr_ok "Copied to clipboard"
        command -q xclip;  and echo $result | xclip -selection clipboard
    end
end
