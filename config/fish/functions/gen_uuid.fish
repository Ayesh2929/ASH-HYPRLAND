# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🆔  UUID / ULID / NANOID GENERATOR — ASH DOTFILES v5.0 OMEGA              ║
# ║  All UUID versions • ULID • NanoID • KSUID • Beautiful Output              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function gen_uuid \
    --description "🆔 Generate UUIDs, ULIDs, NanoIDs, KSUIDs and more"

    # ── Colors ─────────────────────────────────────────────────────────────────
    function __uid_colors
        set -g UID_RESET   \e'[0m'
        set -g UID_BOLD    \e'[1m'
        set -g UID_DIM     \e'[2m'
        set -g UID_ACCENT  \e'[38;2;137;220;235m'   # Catppuccin Teal
        set -g UID_GREEN   \e'[38;2;166;227;161m'
        set -g UID_RED     \e'[38;2;243;139;168m'
        set -g UID_YELLOW  \e'[38;2;249;226;175m'
        set -g UID_BLUE    \e'[38;2;137;180;250m'
        set -g UID_CYAN    \e'[38;2;137;220;235m'
        set -g UID_PINK    \e'[38;2;245;194;231m'
        set -g UID_PEACH   \e'[38;2;250;179;135m'
        set -g UID_MAUVE   \e'[38;2;203;166;247m'
        set -g UID_SURFACE \e'[38;2;88;91;112m'

        # UUID segment colors
        set -g UID_SEG1  \e'[38;2;203;166;247m'   # time_low         — mauve
        set -g UID_SEG2  \e'[38;2;137;220;235m'   # time_mid         — teal
        set -g UID_SEG3  \e'[38;2;249;226;175m'   # time_hi+version  — yellow
        set -g UID_SEG4  \e'[38;2;250;179;135m'   # clock_seq        — peach
        set -g UID_SEG5  \e'[38;2;166;227;161m'   # node             — green
        set -g UID_DASH  \e'[38;2;88;91;112m'
    end

    # ── Helpers ────────────────────────────────────────────────────────────────
    function __uid_banner
        echo
        printf "%s╔══════════════════════════════════════════════════════╗%s\n" $UID_ACCENT $UID_RESET
        printf "%s║%s  %s🆔 UUID / ID GENERATOR%s  %s•%s  %sASH DOTFILES v5.0%s      %s║%s\n" \
            $UID_ACCENT $UID_RESET \
            $UID_BOLD $UID_RESET \
            $UID_SURFACE $UID_RESET \
            $UID_DIM $UID_RESET \
            $UID_ACCENT $UID_RESET
        printf "%s╚══════════════════════════════════════════════════════╝%s\n" $UID_ACCENT $UID_RESET
        echo
    end

    function __uid_section --argument-names icon title
        printf "\n  %s%s%s  %s%s%s\n" $UID_ACCENT $icon $UID_RESET $UID_BOLD $title $UID_RESET
        printf "  %s%s%s\n" $UID_SURFACE (string repeat --count 52 "─") $UID_RESET
    end

    function __uid_ok  --argument-names msg; printf "  %s✓%s  %s\n" $UID_GREEN  $UID_RESET $msg; end
    function __uid_err --argument-names msg; printf "  %s✗%s  %s%s%s\n" $UID_RED $UID_RESET $UID_RED $msg $UID_RESET; end
    function __uid_inf --argument-names msg; printf "  %s●%s  %s\n" $UID_BLUE   $UID_RESET $msg; end
    function __uid_wrn --argument-names msg; printf "  %s⚠%s  %s%s%s\n" $UID_YELLOW $UID_RESET $UID_YELLOW $msg $UID_RESET; end
    function __uid_kv  --argument-names k v
        printf "  %s%-22s%s  %s%s%s\n" $UID_SURFACE $k $UID_RESET $UID_CYAN $v $UID_RESET
    end

    # ── Random primitives ──────────────────────────────────────────────────────
    function __uid_randbytes --argument-names n
        dd if=/dev/urandom bs=1 count=$n 2>/dev/null | od -An -tx1 | \
            string replace -ar '\s+' '' | string sub --length (math "$n * 2")
    end

    function __uid_randint --argument-names max
        set -l b (__uid_randbytes 4)
        math "(0x$b) % $max"
    end

    function __uid_timestamp_ms
        # Milliseconds since epoch
        if command -q python3
            python3 -c "import time; print(int(time.time() * 1000))"
        else
            math (date +%s) \* 1000
        end
    end

    function __uid_timestamp_ns
        date +%s%N 2>/dev/null; or math (date +%s) \* 1000000000
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  UUID GENERATORS
    # ══════════════════════════════════════════════════════════════════════════

    # ── UUID v4 (random) ───────────────────────────────────────────────────────
    function __uid_v4
        if command -q uuidgen
            uuidgen | string lower
        else if command -q python3
            python3 -c "import uuid; print(uuid.uuid4())"
        else
            # Manual /dev/urandom implementation
            set -l b (__uid_randbytes 16)
            # Set version (4) and variant bits
            set -l b7  (printf '%02x' (math "0x"(string sub --start 13 --length 2 "$b")" & 0x0f | 0x40"))
            set -l b9  (printf '%02x' (math "0x"(string sub --start 17 --length 2 "$b")" & 0x3f | 0x80"))
            set -l p1  (string sub --start 1  --length 8  "$b")
            set -l p2  (string sub --start 9  --length 4  "$b")
            set -l p3  "$b7"(string sub --start 15 --length 2 "$b")
            set -l p4  "$b9"(string sub --start 19 --length 2 "$b")
            set -l p5  (string sub --start 21 --length 12 "$b")
            printf "%s-%s-%s-%s-%s" $p1 $p2 $p3 $p4 $p5
        end
    end

    # ── UUID v1 (time-based) ───────────────────────────────────────────────────
    function __uid_v1
        if command -q python3
            python3 -c "import uuid; print(uuid.uuid1())"
        else
            # Fallback: encode current time into UUID-v1 format
            set -l ts_ns (__uid_timestamp_ns)
            # UUID epoch offset: 12219292800000000000 (100ns intervals from 15-Oct-1582)
            set -l uuid_ts (math "$ts_ns / 100 + 122192928000000000")
            set -l ts_hex  (printf '%016x' $uuid_ts)
            set -l t_low   (string sub --start 9  --length 8 "$ts_hex")
            set -l t_mid   (string sub --start 5  --length 4 "$ts_hex")
            set -l t_hi    "1"(string sub --start 2 --length 3 "$ts_hex")
            set -l clk_seq (printf '%04x' (math (math (date +%N)) % 16384 + 32768))
            set -l node    (__uid_randbytes 6)
            printf "%s-%s-%s-%s-%s" $t_low $t_mid $t_hi $clk_seq $node
        end
    end

    # ── UUID v3 (MD5 namespace) ────────────────────────────────────────────────
    function __uid_v3 --argument-names namespace name
        if command -q python3
            python3 -c "
import uuid
ns_map = {
    'dns':  uuid.NAMESPACE_DNS,
    'url':  uuid.NAMESPACE_URL,
    'oid':  uuid.NAMESPACE_OID,
    'x500': uuid.NAMESPACE_X500,
}
ns = ns_map.get('$namespace', uuid.NAMESPACE_URL)
print(uuid.uuid3(ns, '$name'))
"
        else
            __uid_err "UUID v3 requires python3"; return 1
        end
    end

    # ── UUID v5 (SHA-1 namespace) ──────────────────────────────────────────────
    function __uid_v5 --argument-names namespace name
        if command -q python3
            python3 -c "
import uuid
ns_map = {
    'dns':  uuid.NAMESPACE_DNS,
    'url':  uuid.NAMESPACE_URL,
    'oid':  uuid.NAMESPACE_OID,
    'x500': uuid.NAMESPACE_X500,
}
ns = ns_map.get('$namespace', uuid.NAMESPACE_URL)
print(uuid.uuid5(ns, '$name'))
"
        else
            __uid_err "UUID v5 requires python3"; return 1
        end
    end

    # ── UUID v7 (Unix epoch time-ordered) ─────────────────────────────────────
    function __uid_v7
        if command -q python3
            python3 -c "
import time, os, struct
# UUID v7: 48-bit Unix ms timestamp + version(7) + 12-bit random + variant + 62-bit random
ms = int(time.time() * 1000)
rand_a = int.from_bytes(os.urandom(2), 'big') & 0x0FFF
rand_b = int.from_bytes(os.urandom(8), 'big') & 0x3FFFFFFFFFFFFFFF
ts_hi  = (ms >> 28) & 0xFFFFFFFF
ts_mid = (ms >> 12) & 0xFFFF
ver_ts = 0x7000 | rand_a
var_rb = 0x8000000000000000 | rand_b
parts  = [
    f'{ts_hi:08x}',
    f'{ts_mid:04x}',
    f'{ver_ts:04x}',
    f'{(var_rb >> 48) & 0xFFFF:04x}',
    f'{var_rb & 0xFFFFFFFFFFFF:012x}',
]
print('-'.join(parts))
" 2>/dev/null
        else
            # Fallback: timestamp-prefixed v4
            set -l ts (printf '%012x' (__uid_timestamp_ms))
            set -l rand (__uid_randbytes 10)
            set -l ver (printf '%04x' (math "0x"(string sub --length 4 "$rand")" & 0x0fff | 0x7000"))
            set -l var (printf '%04x' (math "0x"(string sub --start 5 --length 4 "$rand")" & 0x3fff | 0x8000"))
            printf "%s-%s-%s-%s-%s" \
                (string sub --length 8 "$ts") \
                (string sub --start 9 --length 4 "$ts") \
                $ver $var \
                (string sub --start 9 "$rand")
        end
    end

    # ── UUID Nil ───────────────────────────────────────────────────────────────
    function __uid_nil
        echo "00000000-0000-0000-0000-000000000000"
    end

    # ── UUID Max ───────────────────────────────────────────────────────────────
    function __uid_max
        echo "ffffffff-ffff-ffff-ffff-ffffffffffff"
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  ULID (Universally Unique Lexicographically Sortable Identifier)
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_ulid
        if command -q ulid
            ulid
        else if command -q python3
            python3 -c "
import time, os
# Crockford Base32
CROCKFORD = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
ts   = int(time.time() * 1000)
rand = int.from_bytes(os.urandom(10), 'big')
# Encode timestamp (10 chars)
ts_str = ''
t = ts
for _ in range(10):
    ts_str = CROCKFORD[t & 0x1F] + ts_str
    t >>= 5
# Encode random (16 chars)
r_str = ''
r = rand
for _ in range(16):
    r_str = CROCKFORD[r & 0x1F] + r_str
    r >>= 5
print(ts_str + r_str)
" 2>/dev/null
        else
            __uid_err "ULID generation requires python3 or ulid command"
            return 1
        end
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  NANOID
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_nanoid --argument-names size alphabet
        test -z "$size";     and set size 21
        test -z "$alphabet"; and set alphabet "A-Za-z0-9_-"
        if command -q python3
            python3 -c "
import os, math
ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-'
size  = int('$size')
mask  = (1 << math.ceil(math.log2(len(ALPHA)))) - 1
step  = math.ceil(1.6 * mask * size / len(ALPHA))
result = ''
while len(result) < size:
    for byte in os.urandom(step):
        idx = byte & mask
        if idx < len(ALPHA):
            result += ALPHA[idx]
            if len(result) == size:
                break
print(result)
"
        else
            # Shell fallback
            set -l chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
            set -l clen  (string length -- "$chars")
            set -l out ""
            while test (string length -- "$out") -lt $size
                set -l idx (__uid_randint $clen)
                set out $out(string sub --start (math $idx + 1) --length 1 "$chars")
            end
            echo "$out"
        end
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  KSUID (K-Sortable Unique Identifier)
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_ksuid
        if command -q python3
            python3 -c "
import time, os
# KSUID: 4-byte timestamp + 16-byte random, base62 encoded
BASE62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
EPOCH  = 1400000000  # KSUID custom epoch
ts     = int(time.time()) - EPOCH
rand   = os.urandom(16)
data   = ts.to_bytes(4, 'big') + rand
n      = int.from_bytes(data, 'big')
result = ''
while n:
    result = BASE62[n % 62] + result
    n //= 62
result = result.zfill(27)
print(result)
" 2>/dev/null
        else
            __uid_err "KSUID requires python3"; return 1
        end
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  SNOWFLAKE (Twitter-style distributed ID)
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_snowflake --argument-names machine_id datacenter_id
        test -z "$machine_id";    and set machine_id    1
        test -z "$datacenter_id"; and set datacenter_id 1
        if command -q python3
            python3 -c "
import time
# Snowflake: 41-bit timestamp | 5-bit datacenter | 5-bit machine | 12-bit sequence
EPOCH    = 1288834974657
ts       = int(time.time() * 1000) - EPOCH
dc       = $datacenter_id & 0x1F
mid      = $machine_id    & 0x1F
seq      = 0  # In production, atomic increment
snowflake = (ts << 22) | (dc << 17) | (mid << 12) | seq
print(snowflake)
" 2>/dev/null
        else
            __uid_err "Snowflake ID requires python3"; return 1
        end
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  SHORTUUID
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_short --argument-names length
        test -z "$length"; and set length 8
        set -l chars "0123456789abcdefghijklmnopqrstuvwxyz"
        set -l clen  (string length -- "$chars")
        set -l out ""
        for i in (seq $length)
            set -l idx (__uid_randint $clen)
            set out $out(string sub --start (math $idx + 1) --length 1 "$chars")
        end
        echo "$out"
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  UUID COLORIZER
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_colorize_uuid --argument-names uid
        # Color each segment differently
        set -l parts (string split "-" "$uid")
        if test (count $parts) -eq 5
            printf "%s%s%s-%s%s%s-%s%s%s-%s%s%s-%s%s%s" \
                $UID_SEG1 $parts[1] $UID_RESET \
                $UID_DASH "-" $UID_RESET \
                $UID_SEG2 $parts[2] $UID_RESET \
                $UID_DASH "-" $UID_RESET \
                $UID_SEG3 $parts[3] $UID_RESET \
                $UID_DASH "-" $UID_RESET \
                $UID_SEG4 $parts[4] $UID_RESET \
                $UID_DASH "-" $UID_RESET \
                $UID_SEG5 $parts[5] $UID_RESET
        else
            printf "%s%s%s" $UID_ACCENT $uid $UID_RESET
        end
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  UUID INSPECTOR / PARSER
    # ══════════════════════════════════════════════════════════════════════════
    function __uid_inspect --argument-names uid
        set uid (string lower -- "$uid")
        # Validate UUID format
        if not string match -qr '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -- "$uid"
            __uid_err "Not a valid UUID: $uid"
            return 1
        end
        set -l parts (string split "-" "$uid")
        # Version
        set -l ver_char (string sub --start 1 --length 1 "$parts[3]")
        set -l version $ver_char
        # Variant
        set -l var_hex $parts[4]
        set -l var_byte (math "0x"(string sub --length 2 "$var_hex"))
        set -l variant
        if test $var_byte -ge 224    # 111xxxxx
            set variant "Microsoft (reserved)"
        else if test $var_byte -ge 192 # 110xxxxx
            set variant "Reserved (future)"
        else if test $var_byte -ge 128 # 10xxxxxx
            set variant "RFC 4122 (standard)"
        else
            set variant "NCS (backward compat)"
        end

        __uid_section "🔍" "UUID INSPECTION"
        __uid_kv "UUID"        (__uid_colorize_uuid $uid)
        __uid_kv "Version"     "$version ($(switch "$version"
            case 1; echo 'Time-based (MAC + timestamp)'
            case 2; echo 'DCE Security'
            case 3; echo 'Name-based (MD5)'
            case 4; echo 'Randomly generated'
            case 5; echo 'Name-based (SHA-1)'
            case 6; echo 'Reordered time (v1 compat)'
            case 7; echo 'Unix epoch time-ordered'
            case '*'; echo 'Unknown'
        end))"
        __uid_kv "Variant"    $variant
        __uid_kv "time_low"   $parts[1]
        __uid_kv "time_mid"   $parts[2]
        __uid_kv "time_hi+v"  $parts[3]
        __uid_kv "clock_seq"  $parts[4]
        __uid_kv "node"       $parts[5]

        # v1/v7 timestamp decode
        switch "$version"
            case 1
                if command -q python3
                    set -l ts_dec (python3 -c "
import datetime
parts = '$uid'.split('-')
t_hi  = int(parts[2][1:], 16)
t_mid = int(parts[1], 16)
t_low = int(parts[0], 16)
ts100ns = (t_hi << 48) | (t_mid << 32) | t_low
ts_us  = (ts100ns - 122192928000000000) // 10
dt     = datetime.datetime(1970,1,1) + datetime.timedelta(microseconds=ts_us)
print(dt.strftime('%Y-%m-%d %H:%M:%S UTC'))
" 2>/dev/null)
                    test -n "$ts_dec"; and __uid_kv "Timestamp" $ts_dec
                end
            case 7
                if command -q python3
                    set -l ts_dec (python3 -c "
import datetime
parts = '$uid'.split('-')
ts_ms  = (int(parts[0], 16) << 16) | int(parts[1], 16)
dt     = datetime.datetime.utcfromtimestamp(ts_ms / 1000)
print(dt.strftime('%Y-%m-%d %H:%M:%S.') + str(ts_ms % 1000).zfill(3) + ' UTC')
" 2>/dev/null)
                    test -n "$ts_dec"; and __uid_kv "Timestamp" $ts_dec
                end
        end
    end

    # ── History ────────────────────────────────────────────────────────────────
    set -l UID_HISTORY "$HOME/.local/share/ash/uuid-history.log"

    function __uid_log --argument-names type value
        mkdir -p (dirname "$UID_HISTORY")
        printf "%s\t%s\t%s\n" \
            (date +"%Y-%m-%d %H:%M:%S") $type $value >> "$UID_HISTORY"
    end

    # ── Clipboard ──────────────────────────────────────────────────────────────
    function __uid_clip --argument-names val
        if command -q wl-copy
            echo -n "$val" | wl-copy; return 0
        else if command -q xclip
            echo -n "$val" | xclip -selection clipboard; return 0
        end
        return 1
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  ARGUMENT PARSING
    # ══════════════════════════════════════════════════════════════════════════
    set -l options \
        'h/help' \
        'v/version' \
        'q/quiet' \
        'n/no-banner' \
        't/type=' \
        '1/v1' \
        '3/v3' \
        '4/v4' \
        '5/v5' \
        '7/v7' \
        'u/ulid' \
        'N/nanoid' \
        'k/ksuid' \
        's/short' \
        'S/snowflake' \
        'X/nil' \
        'M/max' \
        'count=' \
        'l/length=' \
        'a/alphabet=' \
        'C/no-color' \
        'c/clipboard' \
        'U/uppercase' \
        'L/lowercase' \
        'b/braces' \
        'B/no-dashes' \
        'I/inspect=' \
        'H/history' \
        'A/all' \
        'ns/namespace=' \
        'nm/name=' \
        'mi/machine=' \
        'dc/datacenter='

    argparse $options -- $argv 2>/dev/null
    or begin
        __uid_err "Invalid arguments. Use --help for usage."
        return 1
    end

    __uid_colors

    # ── Version ────────────────────────────────────────────────────────────────
    if set -q _flag_version
        printf "%s🆔 gen_uuid%s  %sv5.0.0%s  %s(ASH Dotfiles Omega)%s\n" \
            $UID_ACCENT $UID_RESET $UID_GREEN $UID_RESET $UID_SURFACE $UID_RESET
        return 0
    end

    # ── Help ───────────────────────────────────────────────────────────────────
    if set -q _flag_help
        __uid_banner
        printf "%sUSAGE%s\n  gen_uuid [OPTIONS]\n\n" $UID_ACCENT $UID_RESET

        __uid_section "🆔" "UUID VERSIONS"
        __uid_kv "--v1"           "UUID v1 (time + MAC address)"
        __uid_kv "--v3"           "UUID v3 (name-based, MD5)"
        __uid_kv "--v4"           "UUID v4 (random)  ← default"
        __uid_kv "--v5"           "UUID v5 (name-based, SHA-1)"
        __uid_kv "--v7"           "UUID v7 (Unix epoch, time-ordered)"
        __uid_kv "--nil"          "Nil UUID (all zeros)"
        __uid_kv "--max"          "Max UUID (all f's)"

        __uid_section "🔤" "OTHER ID FORMATS"
        __uid_kv "--ulid"           "ULID — sortable 26-char ID"
        __uid_kv "--nanoid"         "NanoID — URL-safe compact ID"
        __uid_kv "--ksuid"          "KSUID — K-sortable unique ID"
        __uid_kv "--short"          "Short alphanumeric ID"
        __uid_kv "--snowflake"      "Snowflake ID (Twitter-style)"
        __uid_kv "--all"            "Show all formats at once"

        __uid_section "⚙️" "OPTIONS"
        __uid_kv "--count=N"          "Generate N identifiers"
        __uid_kv "-l, --length=N"      "Length (NanoID/short)"
        __uid_kv "-a, --alphabet=CHARS" "Alphabet (NanoID)"
        __uid_kv "--namespace=NS"      "v3/v5 namespace: dns url oid x500"
        __uid_kv "--name=NAME"         "v3/v5 name string"
        __uid_kv "--machine=N"         "Snowflake machine ID"
        __uid_kv "--datacenter=N"      "Snowflake datacenter ID"

        __uid_section "🎨" "FORMAT FLAGS"
        __uid_kv "-U, --uppercase"     "Uppercase output"
        __uid_kv "-L, --lowercase"     "Lowercase output (default)"
        __uid_kv "-b, --braces"        "Wrap in {braces}"
        __uid_kv "-B, --no-dashes"     "Remove dashes from UUID"
        __uid_kv "-C, --no-color"      "Plain output"
        __uid_kv "-q, --quiet"         "Output ID only (pipe-safe)"

        __uid_section "🔧" "TOOLS"
        __uid_kv "-c, --clipboard"     "Copy to clipboard"
        __uid_kv "-I, --inspect=UUID"  "Inspect & parse a UUID"
        __uid_kv "-H, --history"       "Show generation history"
        __uid_kv "-n, --no-banner"     "Skip banner"

        __uid_section "💡" "EXAMPLES"
        printf "  %s# Random UUID v4%s\n"           $UID_SURFACE $UID_RESET
        printf "  gen_uuid\n\n"
        printf "  %s# 10 UUID v7s%s\n"              $UID_SURFACE $UID_RESET
        printf "  gen_uuid --v7 --count=10\n\n"
        printf "  %s# ULID%s\n"                     $UID_SURFACE $UID_RESET
        printf "  gen_uuid --ulid\n\n"
        printf "  %s# NanoID length 12%s\n"         $UID_SURFACE $UID_RESET
        printf "  gen_uuid --nanoid --length=12\n\n"
        printf "  %s# UUID v5 from URL%s\n"         $UID_SURFACE $UID_RESET
        printf "  gen_uuid --v5 --namespace=url --name=https://example.com\n\n"
        printf "  %s# Inspect UUID%s\n"             $UID_SURFACE $UID_RESET
        printf "  gen_uuid --inspect=550e8400-e29b-41d4-a716-446655440000\n\n"
        printf "  %s# All formats%s\n"              $UID_SURFACE $UID_RESET
        printf "  gen_uuid --all\n\n"
        echo
        return 0
    end

    # ── History display ────────────────────────────────────────────────────────
    if set -q _flag_history
        set -q _flag_no_banner; or __uid_banner
        __uid_section "📋" "GENERATION HISTORY (last 20)"
        if test -f "$UID_HISTORY"
            set -l n 0
            tail -20 "$UID_HISTORY" | while read -l ts type value
                set n (math $n + 1)
                printf "  %s%2d%s  %s%-12s%s  %s%-38s%s  %s%s%s\n" \
                    $UID_ACCENT $n $UID_RESET \
                    $UID_BLUE $type $UID_RESET \
                    $UID_CYAN $value $UID_RESET \
                    $UID_SURFACE $ts $UID_RESET
            end
        else
            __uid_inf "No history yet."
        end
        echo; return 0
    end

    # ── Inspect ────────────────────────────────────────────────────────────────
    if set -q _flag_inspect
        set -q _flag_no_banner; or __uid_banner
        __uid_inspect $_flag_inspect
        echo; return 0
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  ALL FORMATS MODE
    # ══════════════════════════════════════════════════════════════════════════
    if set -q _flag_all
        set -q _flag_no_banner; or __uid_banner
        __uid_section "🆔" "ALL ID FORMATS"

        function __uid_row --argument-names label val
            printf "  %s%-14s%s  " $UID_SURFACE $label $UID_RESET
            __uid_colorize_uuid $val
            echo
        end

        set -l v4  (__uid_v4)
        set -l v1  (__uid_v1)
        set -l v7  (__uid_v7)
        set -l ul  (__uid_ulid  2>/dev/null; or echo "(requires python3)")
        set -l nn  (__uid_nanoid 2>/dev/null; or echo "(requires python3)")
        set -l ks  (__uid_ksuid 2>/dev/null; or echo "(requires python3)")
        set -l sh  (__uid_short)
        set -l sf  (__uid_snowflake 2>/dev/null; or echo "(requires python3)")

        printf "\n"
        printf "  %sUUID v1%s      %s%s%s\n" $UID_SURFACE $UID_RESET $UID_SEG1 $v1 $UID_RESET
        printf "  %sUUID v4%s      " $UID_SURFACE $UID_RESET; __uid_colorize_uuid $v4; echo
        printf "  %sUUID v7%s      " $UID_SURFACE $UID_RESET; __uid_colorize_uuid $v7; echo
        printf "  %sUUID nil%s     %s%s%s\n" $UID_SURFACE $UID_RESET $UID_SURFACE (__uid_nil) $UID_RESET
        printf "  %sULID%s         %s%s%s\n" $UID_SURFACE $UID_RESET $UID_YELLOW $ul  $UID_RESET
        printf "  %sNanoID%s       %s%s%s\n" $UID_SURFACE $UID_RESET $UID_GREEN  $nn  $UID_RESET
        printf "  %sKSUID%s        %s%s%s\n" $UID_SURFACE $UID_RESET $UID_PEACH  $ks  $UID_RESET
        printf "  %sShort ID%s     %s%s%s\n" $UID_SURFACE $UID_RESET $UID_PINK   $sh  $UID_RESET
        printf "  %sSnowflake%s    %s%s%s\n" $UID_SURFACE $UID_RESET $UID_CYAN   $sf  $UID_RESET
        printf "\n"
        __uid_log "all" $v4
        return 0
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  DETERMINE TYPE & GENERATE
    # ══════════════════════════════════════════════════════════════════════════
    set -l uid_type "v4"
    set -q _flag_v1         && set uid_type "v1"
    set -q _flag_v3         && set uid_type "v3"
    set -q _flag_v4         && set uid_type "v4"
    set -q _flag_v5         && set uid_type "v5"
    set -q _flag_v7         && set uid_type "v7"
    set -q _flag_ulid       && set uid_type "ulid"
    set -q _flag_nanoid     && set uid_type "nanoid"
    set -q _flag_ksuid      && set uid_type "ksuid"
    set -q _flag_short      && set uid_type "short"
    set -q _flag_snowflake  && set uid_type "snowflake"
    set -q _flag_nil        && set uid_type "nil"
    set -q _flag_max        && set uid_type "max"
    set -q _flag_type       && set uid_type $_flag_type

    set -l count    (test -n "$_flag_count";   and echo $_flag_count;   or echo 1)
    set -l length   (test -n "$_flag_length";  and echo $_flag_length;  or echo 21)
    set -l alphabet (test -n "$_flag_alphabet"; and echo $_flag_alphabet; or echo "")
    set -l ns       (test -n "$_flag_namespace"; and echo $_flag_namespace; or echo "url")
    set -l nm       (test -n "$_flag_name";    and echo $_flag_name;    or echo "")
    set -l machine  (test -n "$_flag_machine"; and echo $_flag_machine; or echo 1)
    set -l dc       (test -n "$_flag_datacenter"; and echo $_flag_datacenter; or echo 1)

    set -q _flag_no_banner; or __uid_banner

    if not set -q _flag_quiet
        __uid_section "🆔" "GENERATING (type: $uid_type, count: $count)"
    end

    set -l generated
    set -l first_id ""

    for i in (seq $count)
        set -l id
        switch "$uid_type"
            case v1;       set id (__uid_v1)
            case v3;       set id (__uid_v3 $ns $nm)
            case v4;       set id (__uid_v4)
            case v5;       set id (__uid_v5 $ns $nm)
            case v7;       set id (__uid_v7)
            case ulid;     set id (__uid_ulid)
            case nanoid;   set id (__uid_nanoid $length $alphabet)
            case ksuid;    set id (__uid_ksuid)
            case short;    set id (__uid_short $length)
            case snowflake;set id (__uid_snowflake $machine $dc)
            case nil;      set id (__uid_nil)
            case max;      set id (__uid_max)
            case '*'
                __uid_err "Unknown type: $uid_type"
                return 1
        end

        # Check generation success
        if test $status -ne 0; or test -z "$id"
            __uid_err "Generation failed for type: $uid_type"
            return 1
        end

        # Format transformations
        set -q _flag_uppercase && set id (string upper "$id")
        set -q _flag_lowercase && set id (string lower "$id")
        set -q _flag_no_dashes && set id (string replace -a "-" "" "$id")
        set -q _flag_braces    && set id "{$id}"

        set -a generated $id
        test $i -eq 1; and set first_id $id

        # Output
        if set -q _flag_quiet
            echo "$id"
        else if test $count -gt 1
            printf "  %s%3d%s  " $UID_SURFACE $i $UID_RESET
            if set -q _flag_no_color; or set -q _flag_no_dashes; or set -q _flag_braces
                printf "%s%s%s\n" $UID_ACCENT $id $UID_RESET
            else
                __uid_colorize_uuid $id
                echo
            end
        else
            # Single ID — full display
            printf "\n  "
            if set -q _flag_no_color; or set -q _flag_no_dashes
                printf "%s%s%s" $UID_BOLD $id $UID_RESET
            else
                __uid_colorize_uuid $id
            end
            printf "\n"
        end

        __uid_log $uid_type "$id"
    end

    # ── Metadata ───────────────────────────────────────────────────────────────
    if not set -q _flag_quiet; and test $count -eq 1
        printf "\n"
        __uid_kv "Type"       $uid_type
        __uid_kv "Length"     (string length -- "$first_id")
        __uid_kv "Format"     (switch "$uid_type"
            case v1;        echo "8-4-4-4-12 hex (time+MAC)"
            case v3;        echo "8-4-4-4-12 hex (MD5 namespace)"
            case v4;        echo "8-4-4-4-12 hex (random)"
            case v5;        echo "8-4-4-4-12 hex (SHA-1 namespace)"
            case v7;        echo "8-4-4-4-12 hex (Unix epoch)"
            case ulid;      echo "26-char Crockford Base32"
            case nanoid;    echo "$length-char URL-safe"
            case ksuid;     echo "27-char Base62 (sortable)"
            case short;     echo "$length-char alphanumeric"
            case snowflake; echo "64-bit integer"
            case nil;       echo "All-zero UUID"
            case max;       echo "All-max UUID"
            case '*';       echo "custom"
        end)
        set -q _flag_braces   && __uid_kv "Wrapped"  "in {braces}"
        set -q _flag_no_dashes && __uid_kv "Dashes"   "removed"
    end

    # ── Clipboard ──────────────────────────────────────────────────────────────
    if set -q _flag_clipboard
        if __uid_clip $first_id
            set -q _flag_quiet; or __uid_ok "Copied to clipboard: $first_id"
        else
            set -q _flag_quiet; or __uid_wrn "Clipboard tool not found"
        end
    end

    # ── Footer ─────────────────────────────────────────────────────────────────
    if not set -q _flag_quiet
        printf "\n  %s%s%s\n" $UID_SURFACE (string repeat --count 54 "─") $UID_RESET
        printf "  %s🆔 ASH UUID Engine%s  %sv5.0%s  %s•%s  %sCryptographically secure%s\n" \
            $UID_ACCENT $UID_RESET \
            $UID_GREEN  $UID_RESET \
            $UID_SURFACE $UID_RESET \
            $UID_DIM     $UID_RESET
        echo
    end

    # ── Cleanup ────────────────────────────────────────────────────────────────
    functions --erase __uid_colors __uid_banner __uid_section
    functions --erase __uid_ok __uid_err __uid_inf __uid_wrn __uid_kv
    functions --erase __uid_randbytes __uid_randint __uid_timestamp_ms __uid_timestamp_ns
    functions --erase __uid_v1 __uid_v3 __uid_v4 __uid_v5 __uid_v7
    functions --erase __uid_ulid __uid_nanoid __uid_ksuid __uid_short __uid_snowflake
    functions --erase __uid_nil __uid_max __uid_colorize_uuid __uid_inspect
    functions --erase __uid_log __uid_clip __uid_row
end
