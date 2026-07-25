#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  📖  DEFINE.FISH  ·  ASH Dotfiles v5.0 OMEGA                                    ║
# ║  Ultra Dictionary & Word Intelligence System                                     ║
# ║  Definitions · Synonyms · Antonyms · Etymology · Examples · Pronunciation        ║
# ║  Offline (wn/dict) · Online (Free Dictionary API) · Thesaurus · Rhymes · FZF    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   define <word>               — Full definition
#   define <word> -s            — Synonyms only
#   define <word> -a            — Antonyms only
#   define <word> -e            — Etymology
#   define <word> -r            — Rhymes
#   define <word> -p            — Pronunciation (IPA)
#   define <word> --examples    — Usage examples
#   define -i / --interactive   — FZF word explorer
#   define -h / --history       — Word history
#   define --wotd               — Word of the day
#   define --random             — Random word

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __DF_VERSION   "5.0.0"
set -g __DF_DATA_DIR  "$HOME/.local/share/ash/define"
set -g __DF_HIST_FILE "$__DF_DATA_DIR/word-history.log"
set -g __DF_FAV_FILE  "$__DF_DATA_DIR/favorites.txt"
set -g __DF_CACHE_DIR "$HOME/.cache/ash/define"
set -g __DF_CACHE_TTL 604800  # 7 days

set -g __DF_API_URL   "https://api.dictionaryapi.dev/api/v2/entries/en"
set -g __DF_RHYME_URL "https://api.datamuse.com/words"

# Part-of-speech icons
set -g __DF_POS_ICONS \
    "noun:📌" "verb:⚡" "adjective:🎨" "adverb:💨" \
    "pronoun:👤" "preposition:📍" "conjunction:🔗" \
    "interjection:❗" "article:📰" "determiner:🔍"

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

function __df_dirs;  mkdir -p $__DF_DATA_DIR $__DF_CACHE_DIR; end
function __df_ok   -a m; echo "$_GR  ✔  $m$_R"; end
function __df_err  -a m; echo "$_RE  ✘  $m$_R" >&2; end
function __df_warn -a m; echo "$_YE  ⚠  $m$_R"; end
function __df_tip  -a m; echo "$_CY  ›  $m$_R"; end
function __df_info -a m; echo "$_BL  ℹ  $m$_R"; end

function __df_section -a title
    echo ""
    echo "$_BL  ┌─ $_YE$title $_BL$(string repeat -n (math 48 - (string length $title)) '─')$_R"
end

# ── POS icon ─────────────────────────────────────────────────────────────────

function __df_pos_icon -a pos
    for entry in $__DF_POS_ICONS
        set -l parts (string split ':' $entry)
        if test "$parts[1]" = "$pos"
            echo $parts[2]
            return
        end
    end
    echo "🔤"
end

# ── cache ─────────────────────────────────────────────────────────────────────

function __df_cache_get -a word
    set -l f "$__DF_CACHE_DIR/$word.json"
    test -f $f; or return 1
    set -l now  (date +%s)
    set -l mod  (stat -c %Y $f 2>/dev/null; or stat -f %m $f 2>/dev/null)
    test (math $now - $mod) -lt $__DF_CACHE_TTL; or begin rm -f $f; return 1; end
    cat $f
end

function __df_cache_set -a word json
    __df_dirs
    echo $json > "$__DF_CACHE_DIR/$word.json"
end

# ── log word ──────────────────────────────────────────────────────────────────

function __df_log -a word
    __df_dirs
    echo "$word  "(date '+%Y-%m-%d %H:%M') >> $__DF_HIST_FILE
end

# ── fetch word data ────────────────────────────────━━━━━━━━━━━━━━━━───────────

function __df_fetch -a word
    # Check cache
    set -l cached (__df_cache_get $word)
    test $status -eq 0 -a -n "$cached"; and echo $cached; and return 0

    if not command -q curl
        __df_err "curl required for online lookup"
        return 1
    end

    set -l json (curl -sf --max-time 10 "$__DF_API_URL/$word" 2>/dev/null)

    if test -z "$json"; or string match -q '*title*"No Definitions Found"*' $json
        return 1
    end

    __df_cache_set $word $json
    echo $json
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  OFFLINE ENGINES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_wordnet -a word
    command -q wn; or return 1
    wn $word -over 2>/dev/null | head -50
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  MAIN DEFINITION DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_full -a word json
    echo ""
    echo "$_BL  ╔═══════════════════════════════════════════════════════════════╗$_R"
    printf "$_BL  ║$_R  📖  $_CY$_B%s$_R%s  ($_D Dictionary$_R)%s  $_BL║$_R\n" \
        $word \
        (string repeat -n (math 20 - (string length $word)) ' ') \
        (string repeat -n 8 ' ')
    echo "$_BL  ╚═══════════════════════════════════════════════════════════════╝$_R"

    echo $json | python3 -c "
import sys, json

data = json.load(sys.stdin)
if not isinstance(data, list) or len(data) == 0:
    print('  No data found')
    sys.exit(1)

entry = data[0]

R  = '\033[0m'
B  = '\033[1m'
D  = '\033[90m'
W  = '\033[97m'
GR = '\033[92m'
YE = '\033[93m'
BL = '\033[94m'
CY = '\033[96m'
MG = '\033[95m'
RE = '\033[91m'

# Pronunciation
phonetics = entry.get('phonetics', [])
for ph in phonetics:
    text = ph.get('text', '')
    if text:
        print(f'\n  {D}Pronunciation:{R}  {CY}{text}{R}')
        break

# Meanings
for meaning in entry.get('meanings', []):
    pos  = meaning.get('partOfSpeech', '')
    defs = meaning.get('definitions', [])
    syns = meaning.get('synonyms', [])
    ants = meaning.get('antonyms', [])

    pos_icons = {
        'noun':'📌','verb':'⚡','adjective':'🎨','adverb':'💨',
        'pronoun':'👤','preposition':'📍','conjunction':'🔗',
        'interjection':'❗','article':'📰','determiner':'🔍'
    }
    icon = pos_icons.get(pos, '🔤')

    print(f'\n  {BL}┌─ {YE}{icon}  {B}{pos.upper()}{R}  {BL}' + '─'*40 + R)

    for i, d in enumerate(defs[:5], 1):
        definition = d.get('definition', '')
        example    = d.get('example', '')
        d_syns     = d.get('synonyms', [])[:3]
        d_ants     = d.get('antonyms', [])[:3]

        print(f'  {D}{i:>2}.{R}  {W}{definition}{R}')
        if example:
            print(f'       {D}e.g. \"{example}\"{R}')
        if d_syns:
            print(f'       {GR}syn: {\", \".join(d_syns)}{R}')
        if d_ants:
            print(f'       {RE}ant: {\", \".join(d_ants)}{R}')

    if syns:
        print(f'  {D}  Synonyms:   {GR}{\", \".join(syns[:8])}{R}')
    if ants:
        print(f'  {D}  Antonyms:   {RE}{\", \".join(ants[:8])}{R}')
" 2>/dev/null

    # Offline fallback info
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  SYNONYMS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_synonyms -a word json
    echo ""
    echo "$_GR  🔗 Synonyms for: $_CY$word$_R"
    echo ""

    echo $json | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not isinstance(data, list): sys.exit(1)

seen = set()
GR='\033[92m'; D='\033[90m'; W='\033[97m'; R='\033[0m'; YE='\033[93m'

for entry in data:
    for meaning in entry.get('meanings', []):
        pos  = meaning.get('partOfSpeech','')
        syns = meaning.get('synonyms',[])
        for d in meaning.get('definitions',[]):
            syns += d.get('synonyms',[])
        syns = [s for s in syns if s not in seen]
        if syns:
            seen.update(syns)
            print(f'  {D}{pos:<16}{R} {GR}{chr(10).join(\"  \"+s for s in syns[:8])}{R}')
" 2>/dev/null

    # Also try datamuse
    if command -q curl
        set -l more (curl -sf --max-time 8 \
            "$__DF_RHYME_URL?rel_syn=$word&max=15" 2>/dev/null \
            | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(', '.join(x['word'] for x in d[:12]))
" 2>/dev/null)
        test -n "$more"; and echo "  $_D(datamuse)$_R $_CY$more$_R"
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  ANTONYMS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_antonyms -a word json
    echo ""
    echo "$_RE  ↔️  Antonyms for: $_CY$word$_R"
    echo ""

    echo $json | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not isinstance(data, list): sys.exit(1)

seen = set()
RE='\033[91m'; D='\033[90m'; R='\033[0m'

for entry in data:
    for meaning in entry.get('meanings', []):
        pos  = meaning.get('partOfSpeech','')
        ants = meaning.get('antonyms',[])
        for d in meaning.get('definitions',[]):
            ants += d.get('antonyms',[])
        ants = [a for a in ants if a not in seen]
        if ants:
            seen.update(ants)
            print(f'  {D}{pos:<16}{R} {RE}{chr(10).join(\"  \"+a for a in ants[:8])}{R}')
" 2>/dev/null

    # datamuse antonyms
    if command -q curl
        set -l more (curl -sf --max-time 8 \
            "$__DF_RHYME_URL?rel_ant=$word&max=12" 2>/dev/null \
            | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(', '.join(x['word'] for x in d[:10]))
" 2>/dev/null)
        test -n "$more"; and echo "  $_D(datamuse)$_R $_RE$more$_R"
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  ETYMOLOGY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_etymology -a word
    echo ""
    echo "$_MG  🏛️  Etymology: $_CY$word$_R"
    echo ""

    # Try etymonline via curl
    if command -q curl
        set -l page (curl -sf --max-time 10 \
            "https://www.etymonline.com/word/$word" \
            -A "Mozilla/5.0" 2>/dev/null)
        if test -n "$page"
            echo $page | python3 -c "
import sys, re
html = sys.stdin.read()
# Extract etymology text from section tags
matches = re.findall(r'<section[^>]*>.*?</section>', html, re.DOTALL)
for m in matches[:2]:
    text = re.sub(r'<[^>]+>', '', m)
    text = re.sub(r'\s+', ' ', text).strip()
    if len(text) > 50:
        print('  ' + text[:500])
        print()
" 2>/dev/null
            test $status -eq 0; and return 0
        end
    end

    # Fallback: wn
    if command -q wn
        wn $word -over 2>/dev/null | grep -i 'origin\|etym\|from ' | head -5 \
            | while read -l line; echo "  $_D$line$_R"; end
        and return 0
    end

    __df_warn "Etymology not available offline — try: wn (wordnet) or visit etymonline.com"
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  PRONUNCIATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_pronunciation -a word json
    echo ""
    echo "$_CY  🔊 Pronunciation: $_W$word$_R"
    echo ""

    echo $json | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not isinstance(data, list): sys.exit(1)

CY='\033[96m'; D='\033[90m'; W='\033[97m'; R='\033[0m'; GR='\033[92m'

for entry in data:
    for ph in entry.get('phonetics', []):
        text  = ph.get('text', '')
        audio = ph.get('audio', '')
        if text:
            print(f'  {D}IPA:{R}    {CY}{text}{R}')
        if audio:
            print(f'  {D}Audio:{R}  {GR}{audio}{R}')
" 2>/dev/null

    # Try espeak for pronunciation
    if command -q espeak-ng
        echo ""
        echo "  $_D  Phonemes (espeak-ng):$_R"
        espeak-ng --ipa -q "$word" 2>/dev/null | while read -l line
            echo "  $_MG  $line$_R"
        end

        set -l speak (read -P "  🔊 Speak it? [y/N] ")
        test "$speak" = "y" -o "$speak" = "Y"
            and espeak-ng "$word" 2>/dev/null
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  RHYMES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_rhymes -a word
    echo ""
    echo "$_MG  🎵 Rhymes with: $_CY$word$_R"
    echo ""

    if command -q curl
        set -l rhymes (curl -sf --max-time 10 \
            "$__DF_RHYME_URL?rel_rhy=$word&max=30" 2>/dev/null \
            | python3 -c "
import sys,json
d=json.load(sys.stdin)
words = [x['word'] for x in d]
# Group by syllable count roughly
short  = [w for w in words if len(w) <= 5][:10]
medium = [w for w in words if 5 < len(w) <= 8][:10]
long_  = [w for w in words if len(w) > 8][:5]
if short:  print('Short: '  + ', '.join(short))
if medium: print('Medium: ' + ', '.join(medium))
if long_:  print('Long: '   + ', '.join(long_))
" 2>/dev/null)

        if test -n "$rhymes"
            echo $rhymes | while read -l line
                echo "  $_CY$line$_R"
            end
        else
            __df_warn "No rhymes found for '$word'"
        end
    else
        __df_err "curl required for rhyme lookup"
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  EXAMPLES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_examples -a word json
    echo ""
    echo "$_YE  💬 Examples: $_CY$word$_R"
    echo ""

    echo $json | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not isinstance(data, list): sys.exit(1)

YE='\033[93m'; D='\033[90m'; W='\033[97m'; R='\033[0m'; CY='\033[96m'

count = 0
for entry in data:
    for meaning in entry.get('meanings', []):
        pos = meaning.get('partOfSpeech','')
        for d in meaning.get('definitions',[]):
            ex = d.get('example','')
            if ex and count < 10:
                print(f'  {D}({pos}){R}')
                print(f'  {W}\"{ex}\"{R}')
                print()
                count += 1
" 2>/dev/null
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  WORD OF THE DAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_wotd
    if not command -q curl
        __df_err "curl required"
        return 1
    end

    set -l data (curl -sf --max-time 10 \
        "https://api.wordnik.com/v4/words.json/wordOfTheDay?api_key=a2a73e7b947cad4cbcdc9ad2922f2a55c23d5a1d" \
        2>/dev/null)

    if test -n "$data"
        set -l word (echo $data | python3 -c "import sys,json; print(json.load(sys.stdin).get('word',''))" 2>/dev/null)
        if test -n "$word"
            echo ""
            echo "$_YE  🌟 Word of the Day: $_CY$_B$word$_R"
            echo ""
            define $word
            return 0
        end
    end

    # Fallback: random from a curated list
    set -l words serendipity ephemeral luminous mellifluous \
        solitude wanderlust ineffable labyrinthine \
        petrichor halcyon sonder vellichor hiraeth \
        sonder eunoia clinomania novaturient

    set -l wotd $words[(math (date +%j) % (count $words) + 1)]
    echo ""
    echo "$_YE  🌟 Word of the Day: $_CY$_B$wotd$_R  $_D(curated)$_R"
    echo ""
    define $wotd
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  INTERACTIVE MODE (FZF)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_interactive
    command -q fzf; or begin __df_err "fzf required"; return 1; end
    __df_dirs

    __df_info "Interactive mode — type to explore words"
    echo ""

    while true
        set -l word (read -P "  📖 Word (empty=exit): " | string trim | string lower)
        test -z "$word"; and break

        set -l actions \
            "📖  Full definition" \
            "🔗  Synonyms" \
            "↔️   Antonyms" \
            "🏛️   Etymology" \
            "🔊  Pronunciation" \
            "🎵  Rhymes" \
            "💬  Examples only" \
            "⭐  Add to favorites" \
            "🔊  Speak word" \
            "↩️   Next word"

        set -l action (printf '%s\n' $actions | fzf \
            --prompt "  📖 $word ❯ " \
            --height=45% \
            --layout=reverse \
            --border=rounded \
            --no-preview \
            --color="header:italic:cyan" \
            --header "  What would you like to know about '$word'?")

        test -z "$action"; and continue

        set -l json (__df_fetch $word 2>/dev/null)
        set -l fetch_ok $status

        switch $action
            case "*Full definition*"
                if test $fetch_ok -eq 0 -a -n "$json"
                    __df_full $word $json
                else
                    # Offline fallback
                    __df_wordnet $word; or __df_dict $word; or __df_sdcv $word
                end
                __df_log $word

            case "*Synonyms*"
                test $fetch_ok -eq 0 -a -n "$json"
                    and __df_synonyms $word $json
                    or __df_warn "Could not fetch data for '$word'"

            case "*Antonyms*"
                test $fetch_ok -eq 0 -a -n "$json"
                    and __df_antonyms $word $json
                    or __df_warn "Could not fetch antonyms"

            case "*Etymology*"
                __df_etymology $word

            case "*Pronunciation*"
                test $fetch_ok -eq 0 -a -n "$json"
                    and __df_pronunciation $word $json
                    or __df_pronunciation $word "[]"

            case "*Rhymes*"
                __df_rhymes $word

            case "*Examples*"
                test $fetch_ok -eq 0 -a -n "$json"
                    and __df_examples $word $json
                    or __df_warn "No examples available"

            case "*favorites*"
                echo "$word  "(date '+%Y-%m-%d') >> $__DF_FAV_FILE
                __df_ok "Added to favorites: $word"

            case "*Speak*"
                command -q espeak-ng; and espeak-ng "$word" 2>/dev/null
                command -q espeak;    and espeak "$word" 2>/dev/null
                command -q say;       and say "$word" 2>/dev/null

            case "*Next*"
                continue
        end
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_history
    __df_dirs
    if not test -s $__DF_HIST_FILE
        __df_warn "No word history yet"
        return 1
    end

    set -l count (wc -l < $__DF_HIST_FILE | string trim)

    echo ""
    echo "$_BL  ┌─ $_YE📜 Word History ($count lookups)$_R"
    echo ""

    if command -q fzf
        set -l word (tac $__DF_HIST_FILE | awk '{print $1}' | sort | uniq -c | sort -rn \
            | awk '{printf "%5s × %s\n", $1, $2}' \
            | fzf \
                --prompt "  📜 History ❯ " \
                --height=60% \
                --layout=reverse \
                --border=rounded \
                --no-preview \
                --header "  Enter=define again  Esc=exit" \
            | awk '{print $NF}')

        test -n "$word"; and define $word
    else
        tac $__DF_HIST_FILE | head -30 | while read -l line
            echo "  $_D$line$_R"
        end
    end
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  FAVORITES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_favorites
    __df_dirs
    if not test -s $__DF_FAV_FILE
        __df_warn "No favorites yet"
        __df_tip  "Add with: define --fav <word>"
        return 1
    end

    if command -q fzf
        set -l word (cat $__DF_FAV_FILE | sort -u | fzf \
            --prompt "  ⭐ Favorites ❯ " \
            --height=60% \
            --layout=reverse \
            --border=rounded \
            --no-preview \
            --header "  Enter=define  Esc=exit" \
            | awk '{print $1}')
        test -n "$word"; and define $word
    else
        cat $__DF_FAV_FILE | sort -u | while read -l line
            echo "  $_YE⭐$_R  $_CY$line$_R"
        end
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __df_help
    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  📖  $_CY$_B define$_R  ·  $_D v$__DF_VERSION · ASH Dotfiles OMEGA$_R          $_BL║$_R"
    echo "$_BL  ╚══════════════════════════════════════════════════════════════╝$_R"
    echo ""
    printf "  $_YE%-38s$_R %s\n" "USAGE"                      "DESCRIPTION"
    printf "  $_D%s$_R\n" (string repeat -n 66 '─')
    printf "  $_GR%-38s$_R %s\n" "define <word>"               "Full definition"
    printf "  $_GR%-38s$_R %s\n" "define <word> -s"            "Synonyms only"
    printf "  $_GR%-38s$_R %s\n" "define <word> -a"            "Antonyms only"
    printf "  $_GR%-38s$_R %s\n" "define <word> -e"            "Etymology"
    printf "  $_GR%-38s$_R %s\n" "define <word> -p"            "Pronunciation (IPA)"
    printf "  $_GR%-38s$_R %s\n" "define <word> -r"            "Rhymes"
    printf "  $_GR%-38s$_R %s\n" "define <word> --examples"    "Usage examples"
    printf "  $_GR%-38s$_R %s\n" "define -i / --interactive"   "FZF word explorer"
    printf "  $_GR%-38s$_R %s\n" "define --history"            "Word lookup history"
    printf "  $_GR%-38s$_R %s\n" "define --favorites"          "Favorited words"
    printf "  $_GR%-38s$_R %s\n" "define --fav <word>"         "Add to favorites"
    printf "  $_GR%-38s$_R %s\n" "define --wotd"               "Word of the day"
    printf "  $_GR%-38s$_R %s\n" "define --random"             "Random interesting word"
    printf "  $_GR%-38s$_R %s\n" "define --flush-cache"        "Clear cache"
    echo ""
    echo "  $_D  API: dictionaryapi.dev (free, no key) · datamuse.com (rhymes)$_R"
    echo "  $_D  Offline: wordnet (wn) · dict · sdcv$_R"
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function define --description "📖 Ultra dictionary & word intelligence"
    test (count $argv) -eq 0; and begin __df_help; return 0; end

    switch $argv[1]
        case -h --help;        __df_help;          return 0
        case -i --interactive; __df_interactive;   return $status
        case --history;        __df_history;       return $status
        case --favorites;      __df_favorites;     return $status
        case --wotd;           __df_wotd;          return $status
        case --flush-cache
            rm -f $__DF_CACHE_DIR/*.json
            __df_ok "Cache cleared"
            return 0
        case --version
            echo "$_CY  📖  define v$__DF_VERSION$_R"
            return 0
        case --random
            set -l rare_words serendipity ephemeral sonder petrichor \
                @vellichor halcyon hiraeth eunoia clinomania \
                novaturient ineffable mellifluous luminous solitude
            set -l r $rare_words[(random 1 (count $rare_words))]
            define $r
            return $status
    end

    # Parse flags
    set -l word     ""
    set -l mode     "full"
    set -l fav_add  0

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -s --synonyms;   set mode "synonyms"
            case -a --antonyms;   set mode "antonyms"
            case -e --etymology;  set mode "etymology"
            case -p --pronunciation; set mode "pronunciation"
            case -r --rhymes;     set mode "rhymes"
            case --examples;      set mode "examples"
            case --fav
                set fav_add 1
            case '*'
                test -z "$word"
                    and set word $argv[$i]
                    or  set word "$word $argv[$i]"
        end
        set i (math $i + 1)
    end

    set word (string trim $word | string lower)
    test -z "$word"; and begin __df_err "No word provided"; return 1; end

    # Add to favorites
    if test $fav_add -eq 1
        __df_dirs
        echo "$word  "(date '+%Y-%m-%d') >> $__DF_FAV_FILE
        __df_ok "Added to favorites: $word"
    end

    # Etymology and rhymes don't need JSON
    if test "$mode" = "etymology"
        __df_etymology $word
        __df_log $word
        return $status
    end

    if test "$mode" = "rhymes"
        __df_rhymes $word
        __df_log $word
        return $status
    end

    # Fetch JSON
    set -l json (__df_fetch $word)
    if test $status -ne 0 -o -z "$json"
        # Offline fallback
        __df_warn "Online lookup failed for '$word' — trying offline..."
        echo ""
        __df_wordnet $word
            or begin __df_err "Word not found: '$word'"; return 1; end
        __df_log $word
        return 0
    end

    __df_log $word

    switch $mode
        case full
            __df_full $word $json
        case synonyms
            __df_synonyms $word $json
        case antonyms
            __df_antonyms $word $json
        case pronunciation
            __df_pronunciation $word $json
        case examples
            __df_examples $word $json
    end
end
