# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⏰  TIMESTAMP TOOLKIT — ASH DOTFILES v5.0 OMEGA                           ║
# ║  Unix • ISO8601 • RFC2822 • Human • Relative • Time Math • Multi-TZ        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function timestamp \
    --description "⏰ Full-featured timestamp toolkit — convert, format, parse & calculate"

    # ── Colors ─────────────────────────────────────────────────────────────────
    function __ts_colors
        set -g TS_RESET   \e'[0m'
        set -g TS_BOLD    \e'[1m'
        set -g TS_DIM     \e'[2m'
        set -g TS_ITALIC  \e'[3m'
        set -g TS_ACCENT  \e'[38;2;249;226;175m'   # Catppuccin Yellow
        set -g TS_GREEN   \e'[38;2;166;227;161m'
        set -g TS_RED     \e'[38;2;243;139;168m'
        set -g TS_YELLOW  \e'[38;2;249;226;175m'
        set -g TS_BLUE    \e'[38;2;137;180;250m'
        set -g TS_CYAN    \e'[38;2;137;220;235m'
        set -g TS_PINK    \e'[38;2;245;194;231m'
        set -g TS_PEACH   \e'[38;2;250;179;135m'
        set -g TS_MAUVE   \e'[38;2;203;166;247m'
        set -g TS_TEAL    \e'[38;2;148;226;213m'
        set -g TS_SURFACE \e'[38;2;88;91;112m'
        set -g TS_OVERLAY \e'[38;2;108;112;134m'
    end

    # ── Helpers ────────────────────────────────────────────────────────────────
    function __ts_banner
        echo
        printf "%s╔══════════════════════════════════════════════════════╗%s\n" $TS_ACCENT $TS_RESET
        printf "%s║%s  %s⏰ TIMESTAMP TOOLKIT%s  %s•%s  %sASH DOTFILES v5.0%s       %s║%s\n" \
            $TS_ACCENT $TS_RESET \
            $TS_BOLD $TS_RESET \
            $TS_SURFACE $TS_RESET \
            $TS_DIM $TS_RESET \
            $TS_ACCENT $TS_RESET
        printf "%s╚══════════════════════════════════════════════════════╝%s\n" $TS_ACCENT $TS_RESET
        echo
    end

    function __ts_section --argument-names icon title
        printf "\n  %s%s%s  %s%s%s\n" $TS_ACCENT $icon $TS_RESET $TS_BOLD $title $TS_RESET
        printf "  %s%s%s\n" $TS_SURFACE (string repeat --count 52 "─") $TS_RESET
    end

    function __ts_ok  --argument-names msg; printf "  %s✓%s  %s\n" $TS_GREEN  $TS_RESET $msg; end
    function __ts_err --argument-names msg; printf "  %s✗%s  %s%s%s\n" $TS_RED $TS_RESET $TS_RED $msg $TS_RESET; end
    function __ts_inf --argument-names msg; printf "  %s●%s  %s\n" $TS_BLUE   $TS_RESET $msg; end
    function __ts_wrn --argument-names msg; printf "  %s⚠%s  %s%s%s\n" $TS_YELLOW $TS_RESET $TS_YELLOW $msg $TS_RESET; end
    function __ts_kv  --argument-names k v
        printf "  %s%-24s%s  %s%s%s\n" $TS_SURFACE $k $TS_RESET $TS_CYAN $v $TS_RESET
    end
    function __ts_kv2  --argument-names k v   # Accented value
        printf "  %s%-24s%s  %s%s%s\n" $TS_SURFACE $k $TS_RESET $TS_YELLOW $v $TS_RESET
    end

    # ── Python timestamp helper ────────────────────────────────────────────────
    function __ts_has_python
        command -q python3
    end

    function __ts_py --argument-names code
        python3 -c "$code" 2>/dev/null
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  CORE TIMESTAMP FUNCTIONS
    # ══════════════════════════════════════════════════════════════════════════

    # ── Current Unix timestamp ─────────────────────────────────────────────────
    function __ts_now_unix
        date +%s
    end

    function __ts_now_unix_ms
        date +%s%3N 2>/dev/null; or math (date +%s) \* 1000
    end

    function __ts_now_unix_ns
        date +%s%N 2>/dev/null; or math (date +%s) \* 1000000000
    end

    # ── Format a Unix timestamp ────────────────────────────────────────────────
    function __ts_format --argument-names unix_ts fmt tz
        test -z "$unix_ts"; and set unix_ts (__ts_now_unix)
        test -z "$fmt";     and set fmt "+%Y-%m-%dT%H:%M:%S%z"
        test -z "$tz";      and set tz (date +%Z)

        if command -q python3
            python3 -c "
from datetime import datetime, timezone
import sys
try:
    dt = datetime.fromtimestamp(int('$unix_ts'))
    print(dt.strftime('$fmt'))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
        else
            date -d "@$unix_ts" "$fmt" 2>/dev/null; \
                or date -r $unix_ts "$fmt" 2>/dev/null  # macOS fallback
        end
    end

    # ── Parse date string to Unix timestamp ───────────────────────────────────
    function __ts_parse --argument-names datestr
        if command -q python3
            python3 -c "
from datetime import datetime
import sys
s = '$datestr'
formats = [
    '%Y-%m-%dT%H:%M:%S%z',
    '%Y-%m-%dT%H:%M:%S',
    '%Y-%m-%d %H:%M:%S',
    '%Y-%m-%d',
    '%d/%m/%Y %H:%M:%S',
    '%d/%m/%Y',
    '%m/%d/%Y',
    '%Y%m%d%H%M%S',
    '%Y%m%d',
    '%a, %d %b %Y %H:%M:%S %z',  # RFC 2822
]
for fmt in formats:
    try:
        dt = datetime.strptime(s, fmt)
        print(int(dt.timestamp()))
        sys.exit(0)
    except ValueError:
        continue
print('ERROR', file=sys.stderr)
sys.exit(1)
" 2>/dev/null
        else
            date -d "$datestr" +%s 2>/dev/null
        end
    end

    # ── Human-readable relative time ───────────────────────────────────────────
    function __ts_relative --argument-names unix_ts
        set -l now  (__ts_now_unix)
        set -l diff (math "abs($now - $unix_ts)")
        set -l past (test $unix_ts -lt $now; and echo true; or echo false)
        set -l label

        if test $diff -lt 5
            set label "just now"
        else if test $diff -lt 60
            set label "$diff seconds"
        else if test $diff -lt 3600
            set -l mins (math "round($diff / 60)")
            set label "$mins minute"(test $mins -gt 1; and echo "s")
        else if test $diff -lt 86400
            set -l hrs (math "round($diff / 3600)")
            set label "$hrs hour"(test $hrs -gt 1; and echo "s")
        else if test $diff -lt 604800
            set -l days (math "round($diff / 86400)")
            set label "$days day"(test $days -gt 1; and echo "s")
        else if test $diff -lt 2592000
            set -l weeks (math "round($diff / 604800)")
            set label "$weeks week"(test $weeks -gt 1; and echo "s")
        else if test $diff -lt 31536000
            set -l months (math "round($diff / 2592000)")
            set label "$months month"(test $months -gt 1; and echo "s")
        else
            set -l years (math "round($diff / 31536000)")
            set label "$years year"(test $years -gt 1; and echo "s")
        end

        if test "$label" = "just now"
            echo "just now"
        else if test "$past" = "true"
            echo "$label ago"
        else
            echo "in $label"
        end
    end

    # ── Calendar display for a month ──────────────────────────────────────────
    function __ts_calendar --argument-names year month
        test -z "$year";  and set year  (date +%Y)
        test -z "$month"; and set month (date +%-m)
        set -l today_d (date +%-d)
        set -l today_m (date +%-m)
        set -l today_y (date +%Y)

        if command -q python3
            python3 -c "
import calendar
from datetime import date
cal = calendar.TextCalendar(calendar.MONDAY)
today = date.today()
year, month = $year, $month
print()
# Header
month_name = calendar.month_name[month]
header = f'{month_name} {year}'
print(f'  \033[1;38;2;249;226;175m{header:^26}\033[0m')
print(f'  \033[38;2;88;91;112m Mo Tu We Th Fr Sa Su\033[0m')
for week in cal.monthdayscalendar(year, month):
    line = '  '
    for day in week:
        if day == 0:
            line += '   '
        elif day == today.day and month == today.month and year == today.year:
            line += f'\033[1;38;2;243;139;168m{day:3}\033[0m'
        elif calendar.weekday(year, month, day) >= 5:
            line += f'\033[38;2;203;166;247m{day:3}\033[0m'
        else:
            line += f'\033[38;2;166;227;161m{day:3}\033[0m'
    print(line)
print()
" 2>/dev/null
        else
            cal $month $year
        end
    end

    # ── Timezone list ──────────────────────────────────────────────────────────
    function __ts_list_timezones
        if command -q python3
            python3 -c "
import subprocess, sys
try:
    result = subprocess.run(['timedatectl', 'list-timezones'], capture_output=True, text=True)
    for tz in result.stdout.strip().split('\n')[:50]:
        print(tz)
    print('... (truncated)')
except:
    import zoneinfo
    zones = sorted(zoneinfo.available_timezones())
    for z in zones[:50]:
        print(z)
" 2>/dev/null
        else if test -d /usr/share/zoneinfo
            find /usr/share/zoneinfo -type f | \
                string replace "/usr/share/zoneinfo/" "" | sort | head -50
            echo "... (truncated, use --tz-search=TERM)"
        end
    end

    # ── World clock ────────────────────────────────────────────────────────────
    function __ts_world_clock
        set -l zones \
            "UTC:UTC" \
            "Americas/New_York:New York" \
            "America/Los_Angeles:Los Angeles" \
            "America/Chicago:Chicago" \
            "America/Sao_Paulo:São Paulo" \
            "Europe/London:London" \
            "Europe/Paris:Paris" \
            "Europe/Berlin:Berlin" \
            "Europe/Moscow:Moscow" \
            "Asia/Dubai:Dubai" \
            "Asia/Kolkata:Mumbai" \
            "Asia/Shanghai:Shanghai" \
            "Asia/Tokyo:Tokyo" \
            "Australia/Sydney:Sydney"

        set -l now_unix (__ts_now_unix)

        printf "\n  %s%s%s\n\n" $TS_BOLD "🌍  World Clock  —  "(date -u +"%Y-%m-%d %H:%M:%S UTC") $TS_RESET

        for entry in $zones
            set -l tz   (string split ":" $entry)[1]
            set -l name (string split ":" $entry)[2]
            if command -q python3
                set -l formatted (python3 -c "
from datetime import datetime
import zoneinfo
try:
    dt = datetime.fromtimestamp($now_unix, tz=zoneinfo.ZoneInfo('$tz'))
    print(dt.strftime('%H:%M:%S  %Z'))
except:
    print('n/a')
" 2>/dev/null)
                # Color weekends differently
                set -l dow (python3 -c "
from datetime import datetime
import zoneinfo
try:
    dt = datetime.fromtimestamp($now_unix, tz=zoneinfo.ZoneInfo('$tz'))
    print(dt.weekday())
except:
    print(0)
" 2>/dev/null)
                if test $dow -ge 5
                    printf "  %s%-18s%s  %s%s%s\n" \
                        $TS_MAUVE $name $TS_RESET \
                        $TS_YELLOW $formatted $TS_RESET
                else if test "$tz" = "UTC"
                    printf "  %s%-18s%s  %s%s%s\n" \
                        $TS_ACCENT $name $TS_RESET \
                        $TS_GREEN $formatted $TS_RESET
                else
                    printf "  %s%-18s%s  %s%s%s\n" \
                        $TS_SURFACE $name $TS_RESET \
                        $TS_CYAN $formatted $TS_RESET
                end
            else
                set -l t (TZ=$tz date +"%H:%M:%S %Z" 2>/dev/null)
                printf "  %s%-18s%s  %s%s%s\n" \
                    $TS_SURFACE $name $TS_RESET \
                    $TS_CYAN $t $TS_RESET
            end
        end
        echo
    end

    # ── Time arithmetic ────────────────────────────────────────────────────────
    function __ts_add --argument-names unix_ts amount unit
        if command -q python3
            python3 -c "
from datetime import datetime, timedelta
import sys
try:
    dt = datetime.fromtimestamp(int('$unix_ts'))
    n  = int('$amount')
    u  = '$unit'
    if u in ('s', 'sec', 'second', 'seconds'):
        dt2 = dt + timedelta(seconds=n)
    elif u in ('m', 'min', 'minute', 'minutes'):
        dt2 = dt + timedelta(minutes=n)
    elif u in ('h', 'hr', 'hour', 'hours'):
        dt2 = dt + timedelta(hours=n)
    elif u in ('d', 'day', 'days'):
        dt2 = dt + timedelta(days=n)
    elif u in ('w', 'week', 'weeks'):
        dt2 = dt + timedelta(weeks=n)
    elif u in ('mo', 'month', 'months'):
        # Approximate
        dt2 = dt + timedelta(days=n*30)
    elif u in ('y', 'year', 'years'):
        dt2 = dt + timedelta(days=n*365)
    else:
        dt2 = dt + timedelta(seconds=n)
    print(int(dt2.timestamp()))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
        else
            # Seconds-only fallback
            switch "$unit"
                case m min minute minutes; set amount (math "$amount * 60")
                case h hr hour hours;      set amount (math "$amount * 3600")
                case d day days;           set amount (math "$amount * 86400")
                case w week weeks;         set amount (math "$amount * 604800")
            end
            math $unix_ts + $amount
        end
    end

    function __ts_diff --argument-names ts1 ts2
        math "abs($ts2 - $ts1)"
    end

    function __ts_diff_human --argument-names secs
        set -l days  (math "floor($secs / 86400)")
        set -l rem   (math "$secs % 86400")
        set -l hours (math "floor($rem / 3600)")
        set -l rem2  (math "$rem % 3600")
        set -l mins  (math "floor($rem2 / 60)")
        set -l secs2 (math "$rem2 % 60")

        set -l out ""
        test $days  -gt 0 && set out "$out${days}d "
        test $hours -gt 0 && set out "$out${hours}h "
        test $mins  -gt 0 && set out "$out${mins}m "
        test $secs2 -gt 0 && set out "$out${secs2}s"
        echo (string trim "$out")
    end

    # ── Business days calculation ──────────────────────────────────────────────
    function __ts_business_days --argument-names ts1 ts2
        if command -q python3
            python3 -c "
from datetime import date, timedelta
import sys
d1 = date.fromtimestamp(int('$ts1'))
d2 = date.fromtimestamp(int('$ts2'))
if d2 < d1:
    d1, d2 = d2, d1
days = 0
current = d1
while current <= d2:
    if current.weekday() < 5:  # Mon-Fri
        days += 1
    current += timedelta(days=1)
print(days)
" 2>/dev/null
        else
            echo "n/a"
        end
    end

    # ── Week number / ISO week ─────────────────────────────────────────────────
    function __ts_week_info --argument-names unix_ts
        if command -q python3
            python3 -c "
from datetime import datetime
dt   = datetime.fromtimestamp(int('$unix_ts'))
iso  = dt.isocalendar()
print(f'{iso[0]},{iso[1]},{iso[2]}')   # year, week, weekday
" 2>/dev/null
        else
            set -l w (date -d "@$unix_ts" +"%Y,%V,%u" 2>/dev/null)
            echo "$w"
        end
    end

    # ── Countdown timer ────────────────────────────────────────────────────────
    function __ts_countdown --argument-names target_unix
        set -l now (__ts_now_unix)
        set -l diff (math $target_unix - $now)
        if test $diff -le 0
            printf "%s%s%s  %s\n" $TS_RED "⏰" $TS_RESET "That time has passed!"
            return
        end
        set -l count_date (date -d "@$target_unix" "+%Y-%m-%d %H:%M:%S" 2>/dev/null; or date -r $target_unix "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        printf "\n  %sCountdown to%s  %s%s%s\n\n" \
            $TS_SURFACE $TS_RESET \
            $TS_YELLOW "$count_date" \
            $TS_RESET
        set -l days  (math "floor($diff / 86400)")
        set -l hours (math "floor(($diff % 86400) / 3600)")
        set -l mins  (math "floor(($diff % 3600) / 60)")
        set -l secs  (math "$diff % 60")
        printf "  %s%s%s %s days%s  %s%s%s %s hours%s  %s%s%s %s minutes%s  %s%s%s %s seconds%s\n\n" \
            $TS_BOLD $TS_YELLOW $days $TS_RESET $TS_SURFACE \
            $TS_BOLD $TS_CYAN $hours $TS_RESET $TS_SURFACE \
            $TS_BOLD $TS_GREEN $mins  $TS_RESET $TS_SURFACE \
            $TS_BOLD $TS_PINK $secs  $TS_RESET $TS_SURFACE
    end

    # ── Full display of a timestamp ────────────────────────────────────────────
    function __ts_full_display --argument-names unix_ts
        test -z "$unix_ts"; and set unix_ts (__ts_now_unix)

        set -l unix_ms  (math "$unix_ts * 1000")
        set -l iso8601  (__ts_py "from datetime import datetime; dt=datetime.fromtimestamp($unix_ts); print(dt.strftime('%Y-%m-%dT%H:%M:%S'))")
        set -l iso_utc  (__ts_py "from datetime import datetime,timezone; dt=datetime.fromtimestamp($unix_ts,tz=timezone.utc); print(dt.strftime('%Y-%m-%dT%H:%M:%SZ'))")
        set -l rfc2822  (__ts_py "from datetime import datetime; dt=datetime.fromtimestamp($unix_ts); print(dt.strftime('%a, %d %b %Y %H:%M:%S %z'))")
        set -l rfc3339  (__ts_py "from datetime import datetime,timezone; dt=datetime.fromtimestamp($unix_ts,tz=timezone.utc); print(dt.isoformat())")
        set -l human    (__ts_py "from datetime import datetime; dt=datetime.fromtimestamp($unix_ts); print(dt.strftime('%A, %B %-d, %Y at %-I:%M:%S %p'))")
        set -l relative (__ts_relative $unix_ts)
        set -l week_raw (__ts_week_info $unix_ts)
        set -l iso_week (string split "," $week_raw)[2]
        set -l iso_year (string split "," $week_raw)[1]
        set -l weekday  (string split "," $week_raw)[3]
        set -l dow_name (__ts_py "
from datetime import datetime
import calendar
dt = datetime.fromtimestamp($unix_ts)
print(calendar.day_name[dt.weekday()])
")
        set -l month_name (__ts_py "
from datetime import datetime
import calendar
dt = datetime.fromtimestamp($unix_ts)
print(calendar.month_name[dt.month])
")
        set -l day_of_year (__ts_py "
from datetime import datetime
dt = datetime.fromtimestamp($unix_ts)
print(dt.timetuple().tm_yday)
")
        set -l leap (__ts_py "
from datetime import datetime
import calendar
dt = datetime.fromtimestamp($unix_ts)
print('Yes' if calendar.isleap(dt.year) else 'No')
")
        set -l is_weekend (__ts_py "
from datetime import datetime
dt = datetime.fromtimestamp($unix_ts)
print('Yes' if dt.weekday() >= 5 else 'No')
")
        set -l quarter (__ts_py "
from datetime import datetime
dt = datetime.fromtimestamp($unix_ts)
print((dt.month - 1) // 3 + 1)
")

        # ── Display card ───────────────────────────────────────────────────────
        printf "\n  %s┌────────────────────────────────────────────────────────┐%s\n" \
            $TS_ACCENT $TS_RESET
        printf "  %s│%s  %s%-54s%s%s│%s\n" \
            $TS_ACCENT $TS_RESET \
            $TS_BOLD $human $TS_RESET \
            $TS_ACCENT $TS_RESET
        printf "  %s│%s  %s%-54s%s%s│%s\n" \
            $TS_ACCENT $TS_RESET \
            $TS_DIM "$relative" $TS_RESET \
            $TS_ACCENT $TS_RESET
        printf "  %s└────────────────────────────────────────────────────────┘%s\n" \
            $TS_ACCENT $TS_RESET

        __ts_section "📋" "ALL FORMATS"
        __ts_kv2 "Unix"          $unix_ts
        __ts_kv2 "Unix (ms)"     $unix_ms
        __ts_kv "ISO 8601"       $iso8601
        __ts_kv "ISO 8601 UTC"   $iso_utc
        __ts_kv "RFC 3339"       $rfc3339
        __ts_kv "RFC 2822"       $rfc2822

        __ts_section "📅" "DATE DETAILS"
        __ts_kv "Day of week"    "$dow_name ($weekday/7)"
        __ts_kv "Month"          $month_name
        __ts_kv "Quarter"        "Q$quarter"
        __ts_kv "Day of year"    $day_of_year
        __ts_kv "ISO week"       "W$iso_week ($iso_year)"
        __ts_kv "Leap year"      $leap
        __ts_kv "Weekend"        $is_weekend
        __ts_kv "Local timezone" (date +%Z)
        __ts_kv "UTC offset"     (__ts_py "from datetime import datetime,timezone; import time; offset = -time.timezone/3600; print(f'+{offset:.0f}:00' if offset >= 0 else f'{offset:.0f}:00')")
    end

    # ── Stopwatch-style live clock ─────────────────────────────────────────────
    function __ts_liveclock
        printf "\n  %sLive Clock%s  %s(Ctrl+C to stop)%s\n\n" \
            $TS_BOLD $TS_RESET $TS_SURFACE $TS_RESET
        while true
            set -l now (__ts_now_unix)
            set -l local_t (date +"%H:%M:%S")
            set -l local_d (date +"%Y-%m-%d")
            set -l utc_t   (date -u +"%H:%M:%S")
            set -l tz      (date +%Z)
            printf "\r  %s%s%s  %s%s  %s%s%s  %s│%s  UTC %s%s%s  %sUnix %s%s%s  " \
                $TS_BOLD $local_d $TS_RESET \
                $TS_YELLOW $local_t $TS_RESET \
                $TS_SURFACE $tz $TS_RESET \
                $TS_OVERLAY $TS_RESET \
                $TS_CYAN $utc_t $TS_RESET \
                $TS_SURFACE $TS_GREEN $now $TS_RESET
            sleep 1
        end
    end

    # ── History ────────────────────────────────────────────────────────────────
    set -l TS_HISTORY "$HOME/.local/share/ash/timestamp-history.log"

    function __ts_log --argument-names action value
        mkdir -p (dirname "$TS_HISTORY")
        printf "%s\t%s\t%s\n" (date +%s) $action $value >> "$TS_HISTORY"
    end

    # ── Clipboard ──────────────────────────────────────────────────────────────
    function __ts_clip --argument-names val
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
        'c/clipboard' \
        'u/unix' \
        'U/unix-ms' \
        'N/unix-ns' \
        'i/iso' \
        'I/iso-utc' \
        'r/rfc2822' \
        'R/rfc3339' \
        'H/human' \
        'e/relative' \
        'f/format=' \
        'F/from=' \
        'T/tz=' \
        't/to-tz=' \
        'a/add=' \
        'A/unit=' \
        's/sub=' \
        'd/diff=' \
        'D/from-ts=' \
        'p/parse=' \
        'C/calendar' \
        'Y/year=' \
        'M/month=' \
        'w/world' \
        'k/countdown=' \
        'K/live' \
        'b/business' \
        'W/week' \
        'Q/quarter' \
        'x/history' \
        'Z/tz-list' \
        'z/tz-search=' \
        'S/stats'

    argparse $options -- $argv 2>/dev/null
    or begin
        __ts_err "Invalid arguments. Use --help for usage."
        return 1
    end

    __ts_colors

    # ── Version ────────────────────────────────────────────────────────────────
    if set -q _flag_version
        printf "%s⏰ timestamp%s  %sv5.0.0%s  %s(ASH Dotfiles Omega)%s\n" \
            $TS_ACCENT $TS_RESET $TS_GREEN $TS_RESET $TS_SURFACE $TS_RESET
        return 0
    end

    # ── Help ───────────────────────────────────────────────────────────────────
    if set -q _flag_help
        __ts_banner
        printf "%sUSAGE%s\n  timestamp [OPTIONS]\n\n" $TS_ACCENT $TS_RESET

        __ts_section "🕐" "CURRENT TIME"
        __ts_kv "--unix"         "Unix timestamp (seconds)"
        __ts_kv "--unix-ms"      "Unix timestamp (milliseconds)"
        __ts_kv "--unix-ns"      "Unix timestamp (nanoseconds)"
        __ts_kv "--iso"          "ISO 8601 local"
        __ts_kv "--iso-utc"      "ISO 8601 UTC"
        __ts_kv "--rfc2822"      "RFC 2822 (email format)"
        __ts_kv "--rfc3339"      "RFC 3339"
        __ts_kv "--human"        "Human readable (long)"
        __ts_kv "--relative"     "Relative time (X ago / in X)"
        __ts_kv "-f, --format=FMT" "Custom strftime format"

        __ts_section "🔄" "CONVERSION"
        __ts_kv "-F, --from=TIMESTAMP"  "Input Unix timestamp or date string"
        __ts_kv "-T, --tz=TIMEZONE"     "Output timezone (e.g. America/New_York)"
        __ts_kv "-p, --parse=DATESTR"   "Parse date string to Unix timestamp"

        __ts_section "➕" "TIME ARITHMETIC"
        __ts_kv "-a, --add=N"            "Add N units to timestamp"
        __ts_kv "-A, --unit=UNIT"        "Unit: s m h d w mo y"
        __ts_kv "-s, --sub=N"            "Subtract N units"
        __ts_kv "-d, --diff=TS"          "Time difference between two timestamps"
        __ts_kv "-D, --from-ts=TS"       "First timestamp for diff"
        __ts_kv "-b, --business"         "Show business days in diff"

        __ts_section "📅" "CALENDAR & INFO"
        __ts_kv "-C, --calendar"         "Show month calendar"
        __ts_kv "-Y, --year=YYYY"        "Year for calendar"
        __ts_kv "-M, --month=MM"         "Month for calendar"
        __ts_kv "-W, --week"             "Show ISO week number"
        __ts_kv "-Q, --quarter"          "Show quarter"
        __ts_kv "-w, --world"            "World clock"
        __ts_kv "-k, --countdown=TS"     "Countdown to timestamp"
        __ts_kv "-K, --live"             "Live clock (real-time)"
        __ts_kv "-S, --stats"            "Full timestamp breakdown"
        __ts_kv "-Z, --tz-list"          "List available timezones"
        __ts_kv "-z, --tz-search=TERM"   "Search timezones"

        __ts_section "📤" "OUTPUT"
        __ts_kv "-q, --quiet"     "Bare output (pipe-safe)"
        __ts_kv "-n, --no-banner" "Skip banner"
        __ts_kv "-c, --clipboard" "Copy result to clipboard"
        __ts_kv "-x, --history"   "Show history"

        __ts_section "💡" "EXAMPLES"
        printf "  %s# Current Unix timestamp%s\n"            $TS_SURFACE $TS_RESET
        printf "  timestamp --unix\n\n"
        printf "  %s# Full breakdown%s\n"                    $TS_SURFACE $TS_RESET
        printf "  timestamp --stats\n\n"
        printf "  %s# Convert Unix to human%s\n"             $TS_SURFACE $TS_RESET
        printf "  timestamp --from=1700000000 --human\n\n"
        printf "  %s# Add 30 days%s\n"                       $TS_SURFACE $TS_RESET
        printf "  timestamp --add=30 --unit=d\n\n"
        printf "  %s# Diff between two timestamps%s\n"       $TS_SURFACE $TS_RESET
        printf "  timestamp --diff=1700000000 --from-ts=1710000000\n\n"
        printf "  %s# World clock%s\n"                       $TS_SURFACE $TS_RESET
        printf "  timestamp --world\n\n"
        printf "  %s# Calendar for March 2025%s\n"           $TS_SURFACE $TS_RESET
        printf "  timestamp --calendar --year=2025 --month=3\n\n"
        printf "  %s# Parse date string%s\n"                 $TS_SURFACE $TS_RESET
        printf "  timestamp --parse='2025-06-15 14:30:00'\n\n"
        printf "  %s# Custom format%s\n"                     $TS_SURFACE $TS_RESET
        printf "  timestamp --format='%%d/%%m/%%Y %%H:%%M'\n\n"
        echo
        return 0
    end

    # ── History ────────────────────────────────────────────────────────────────
    if set -q _flag_history
        set -q _flag_no_banner; or __ts_banner
        __ts_section "📋" "HISTORY (last 20)"
        if test -f "$TS_HISTORY"
            set -l n 0
            tail -20 "$TS_HISTORY" | while read -l unix action value
                set n (math $n + 1)
                printf "  %s%2d%s  %s%-16s%s  %s%-20s%s  %s%s%s\n" \
                    $TS_ACCENT $n $TS_RESET \
                    $TS_BLUE $action $TS_RESET \
                    $TS_YELLOW $value $TS_RESET \
                    $TS_SURFACE (__ts_format $unix "+%Y-%m-%d %H:%M:%S") $TS_RESET
            end
        else
            __ts_inf "No history yet."
        end
        echo; return 0
    end

    # ── Base timestamp ─────────────────────────────────────────────────────────
    set -l base_ts (__ts_now_unix)

    if set -q _flag_from
        set -l raw $_flag_from
        if string match -qr '^\d+$' -- "$raw"
            set base_ts $raw
        else
            set base_ts (__ts_parse $raw)
            if test $status -ne 0; or test -z "$base_ts"
                __ts_err "Could not parse: $raw"
                return 1
            end
        end
    end

    # ── Parse date string ──────────────────────────────────────────────────────
    if set -q _flag_parse
        set -l parsed (__ts_parse $_flag_parse)
        if test $status -eq 0; and test -n "$parsed"
            if set -q _flag_quiet
                echo "$parsed"
            else
                set -q _flag_no_banner; or __ts_banner
                __ts_section "🔍" "PARSE DATE STRING"
                __ts_kv "Input"   $_flag_parse
                __ts_kv2 "Unix"   $parsed
                __ts_kv "ISO"     (__ts_format $parsed "+%Y-%m-%dT%H:%M:%S")
                __ts_kv "Human"   (__ts_format $parsed "+%A, %B %-d, %Y at %-I:%M:%S %p")
                __ts_kv "Relative" (__ts_relative $parsed)
            end
            set -q _flag_clipboard; and __ts_clip $parsed; and set -q _flag_quiet; or __ts_ok "Copied"
            __ts_log "parse" $parsed
        else
            __ts_err "Could not parse: $_flag_parse"
            return 1
        end
        echo; return 0
    end

    # ── Time arithmetic ────────────────────────────────────────────────────────
    if set -q _flag_add; or set -q _flag_sub
        set -q _flag_no_banner; or __ts_banner
        __ts_section "➕" "TIME ARITHMETIC"
        set -l amount $_flag_add
        set -l unit   (test -n "$_flag_unit"; and echo $_flag_unit; or echo "s")
        set -l sign   "+"

        if set -q _flag_sub
            set amount $_flag_sub
            set sign "-"
        end

        __ts_kv "Base"    (__ts_format $base_ts "+%Y-%m-%d %H:%M:%S")
        __ts_kv "Add"     "$sign$amount $unit"

        set -l result_ts
        if set -q _flag_sub
            set result_ts (__ts_add $base_ts (math -$amount) $unit)
        else
            set result_ts (__ts_add $base_ts $amount $unit)
        end

        if test -z "$result_ts"
            __ts_err "Arithmetic failed."; return 1
        end

        __ts_kv "Result"  (__ts_format $result_ts "+%Y-%m-%d %H:%M:%S")
        __ts_kv2 "Unix"   $result_ts
        __ts_kv "Relative" (__ts_relative $result_ts)

        if set -q _flag_clipboard
            __ts_clip $result_ts; and __ts_ok "Copied: $result_ts"
        end
        __ts_log "add" $result_ts
        echo; return 0
    end

    # ── Diff ───────────────────────────────────────────────────────────────────
    if set -q _flag_diff
        set -q _flag_no_banner; or __ts_banner
        __ts_section "↔️" "TIME DIFFERENCE"
        set -l ts1 (test -n "$_flag_from_ts"; and echo $_flag_from_ts; or echo (__ts_now_unix))
        set -l ts2 $_flag_diff

        __ts_kv "From" (__ts_format $ts1 "+%Y-%m-%d %H:%M:%S")
        __ts_kv "To"   (__ts_format $ts2 "+%Y-%m-%d %H:%M:%S")

        set -l diff_secs (__ts_diff $ts1 $ts2)
        set -l diff_hr   (__ts_diff_human $diff_secs)

        printf "\n"
        __ts_kv2 "Difference"    $diff_hr
        __ts_kv  "Total seconds" $diff_secs
        __ts_kv  "Total minutes" (math "round($diff_secs / 60)")
        __ts_kv  "Total hours"   (math "round($diff_secs / 3600)")
        __ts_kv  "Total days"    (math "round($diff_secs / 86400)")
        __ts_kv  "Total weeks"   (math "round($diff_secs / 604800)")

        if set -q _flag_business
            set -l bdays (__ts_business_days $ts1 $ts2)
            __ts_kv "Business days" $bdays
        end
        echo; return 0
    end

    # ── Calendar ───────────────────────────────────────────────────────────────
    if set -q _flag_calendar
        set -l year  (test -n "$_flag_year";  and echo $_flag_year;  or echo (date +%Y))
        set -l month (test -n "$_flag_month"; and echo $_flag_month; or echo (date +%-m))
        set -q _flag_no_banner; or __ts_banner
        __ts_section "📅" "CALENDAR"
        __ts_calendar $year $month
        return 0
    end

    # ── World clock ────────────────────────────────────────────────────────────
    if set -q _flag_world
        set -q _flag_no_banner; or __ts_banner
        __ts_section "🌍" "WORLD CLOCK"
        __ts_world_clock
        return 0
    end

    # ── Live clock ─────────────────────────────────────────────────────────────
    if set -q _flag_live
        set -q _flag_no_banner; or __ts_banner
        __ts_liveclock
        return 0
    end

    # ── Countdown ──────────────────────────────────────────────────────────────
    if set -q _flag_countdown
        set -q _flag_no_banner; or __ts_banner
        __ts_section "⏳" "COUNTDOWN"
        __ts_countdown $_flag_countdown
        return 0
    end

    # ── Timezone list / search ─────────────────────────────────────────────────
    if set -q _flag_tz_list
        set -q _flag_no_banner; or __ts_banner
        __ts_section "🌐" "AVAILABLE TIMEZONES (first 50)"
        __ts_list_timezones | while read -l tz
            printf "  %s%s%s\n" $TS_CYAN "$tz" $TS_RESET
        end
        echo; return 0
    end

    if set -q _flag_tz_search
        set -q _flag_no_banner; or __ts_banner
        __ts_section "🔍" "TIMEZONE SEARCH: $_flag_tz_search"
        __ts_list_timezones | grep -i -- "$_flag_tz_search" | while read -l tz
            printf "  %s%s%s\n" $TS_CYAN "$tz" $TS_RESET
        end
        echo; return 0
    end

    # ── Single format output (quiet / pipe mode) ───────────────────────────────
    if set -q _flag_quiet
        set -l out
        if set -q _flag_unix;     set out (__ts_now_unix)
        else if set -q _flag_unix_ms;  set out (__ts_now_unix_ms)
        else if set -q _flag_unix_ns;  set out (__ts_now_unix_ns)
        else if set -q _flag_iso;      set out (date "+%Y-%m-%dT%H:%M:%S")
        else if set -q _flag_iso_utc;  set out (date -u "+%Y-%m-%dT%H:%M:%SZ")
        else if set -q _flag_rfc2822;  set out (date "+%a, %d %b %Y %H:%M:%S %z")
        else if set -q _flag_rfc3339;  set out (date -u "+%Y-%m-%dT%H:%M:%SZ")
        else if set -q _flag_human;    set out (date "+%A, %B %-d, %Y at %-I:%M:%S %p")
        else if set -q _flag_relative; set out (__ts_relative $base_ts)
        else if set -q _flag_format;   set out (date "$_flag_format")
        else;                          set out (__ts_now_unix)
        end
        echo "$out"
        if set -q _flag_clipboard; __ts_clip "$out"; end
        return 0
    end

    # ══════════════════════════════════════════════════════════════════════════
    #  FULL / DEFAULT DISPLAY
    # ══════════════════════════════════════════════════════════════════════════
    set -q _flag_no_banner; or __ts_banner

    # Single format flags
    if set -q _flag_unix; or set -q _flag_unix_ms; or set -q _flag_unix_ns; \
        or set -q _flag_iso; or set -q _flag_iso_utc; or set -q _flag_rfc2822; \
        or set -q _flag_rfc3339; or set -q _flag_human; or set -q _flag_relative; \
        or set -q _flag_format; or set -q _flag_week; or set -q _flag_quarter

        __ts_section "🕐" "TIMESTAMP"
        set -l result ""
        set -l label  ""

        if set -q _flag_unix
            set result (__ts_now_unix)
            set label  "Unix (seconds)"
        else if set -q _flag_unix_ms
            set result (__ts_now_unix_ms)
            set label  "Unix (ms)"
        else if set -q _flag_unix_ns
            set result (__ts_now_unix_ns)
            set label  "Unix (ns)"
        else if set -q _flag_iso
            set result (date "+%Y-%m-%dT%H:%M:%S")
            set label  "ISO 8601"
        else if set -q _flag_iso_utc
            set result (date -u "+%Y-%m-%dT%H:%M:%SZ")
            set label  "ISO 8601 UTC"
        else if set -q _flag_rfc2822
            set result (date "+%a, %d %b %Y %H:%M:%S %z")
            set label  "RFC 2822"
        else if set -q _flag_rfc3339
            set result (date -u "+%Y-%m-%dT%H:%M:%SZ")
            set label  "RFC 3339"
        else if set -q _flag_human
            set result (date "+%A, %B %-d, %Y at %-I:%M:%S %p")
            set label  "Human"
        else if set -q _flag_relative
            set result (__ts_relative $base_ts)
            set label  "Relative"
        else if set -q _flag_format
            set result (date "$_flag_format")
            set label  "Custom format"
        else if set -q _flag_week
            set -l wi (__ts_week_info $base_ts)
            set result "Week "(string split "," $wi)[2]" of "(string split "," $wi)[1]
            set label  "ISO Week"
        else if set -q _flag_quarter
            set result (__ts_py "from datetime import datetime; dt=datetime.fromtimestamp($base_ts); print(f'Q{(dt.month-1)//3+1} {dt.year}')")
            set label  "Quarter"
        end

        printf "\n"
        __ts_kv $label "$result"
        printf "\n"

        if set -q _flag_clipboard
            __ts_clip "$result"; and __ts_ok "Copied to clipboard"
        end
        __ts_log $label "$result"

    else
        # ── Default: full stats display ────────────────────────────────────────
        __ts_full_display $base_ts

        if set -q _flag_clipboard
            __ts_clip $base_ts; and __ts_ok "Copied Unix timestamp to clipboard"
        end
        __ts_log "full" $base_ts
    end

    # ── Footer ─────────────────────────────────────────────────────────────────
    printf "\n  %s%s%s\n" $TS_SURFACE (string repeat --count 54 "─") $TS_RESET
    printf "  %s⏰ ASH Timestamp Engine%s  %sv5.0%s  %s•%s  %s$(date +%Z)%s\n" \
        $TS_ACCENT $TS_RESET \
        $TS_GREEN  $TS_RESET \
        $TS_SURFACE $TS_RESET \
        $TS_DIM (date +%Z) $TS_RESET
    echo

    # ── Cleanup ────────────────────────────────────────────────────────────────
    functions --erase __ts_colors __ts_banner __ts_section
    functions --erase __ts_ok __ts_err __ts_inf __ts_wrn __ts_kv __ts_kv2
    functions --erase __ts_has_python __ts_py
    functions --erase __ts_now_unix __ts_now_unix_ms __ts_now_unix_ns
    functions --erase __ts_format __ts_parse __ts_relative
    functions --erase __ts_calendar __ts_list_timezones __ts_world_clock
    functions --erase __ts_add __ts_diff __ts_diff_human
    functions --erase __ts_business_days __ts_week_info
    functions --erase __ts_countdown __ts_liveclock
    functions --erase __ts_full_display __ts_log __ts_clip
end
