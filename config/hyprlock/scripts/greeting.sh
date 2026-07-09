#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HYPRLOCK SCRIPT: GREETING                       ║
# ║  Context-intelligent personalization — time, weather, occasion, poetry     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DESCRIPTION                                                                 │
# │  Full-featured greeting engine for all hyprlock greeting widget variants.   │
# │  Supports 8 greeting modes, 10+ languages, haiku database, quote database,  │
# │  occasion detection, productivity integration, and weather mood mapping.    │
# │                                                                              │
# │  USAGE                                                                       │
# │    greeting.sh                      Time-aware greeting (default)           │
# │    greeting.sh --time-aware         "Good evening, Ash  🌆"                │
# │    greeting.sh --sub                Context sub-line for time band          │
# │    greeting.sh --quote              Quote of the day (day-seeded)           │
# │    greeting.sh --quote-author       Attribution for current quote           │
# │    greeting.sh --weather-mood       Weather-matched greeting                │
# │    greeting.sh --occasion           Calendar special day greeting           │
# │    greeting.sh --occasion-sub       Occasion flavor sub-text                │
# │    greeting.sh --haiku-12           Haiku lines 1+2 (5+7 syllables)        │
# │    greeting.sh --haiku-3            Haiku line 3 (5 syllables)             │
# │    greeting.sh --multilang          Current rotation language greeting      │
# │    greeting.sh --lang-label         Language name display                   │
# │    greeting.sh --short              Short greeting (no name, no emoji)      │
# │    greeting.sh --productivity       Pomodoro/focus/task context             │
# │    greeting.sh --name-only          Just the configured username            │
# │                                                                              │
# │  CONFIGURATION (via ash config / colors.conf injection)                     │
# │    $HL_USER_NAME         Display name (default: $USER)                      │
# │    $HL_BIRTHDAY          MM-DD format (e.g. "01-15")                        │
# │    $HL_GREETING_LANGS    Comma-separated language codes                      │
# │    $HL_SHOW_HINT         Boolean for keyboard hint label                    │
# └─────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

readonly SCRIPT_NAME="greeting"
readonly SCRIPT_VERSION="5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 01 — CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── User identity ─────────────────────────────────────────────────────────────
readonly USER_NAME="${HL_USER_NAME:-${USER:-$(whoami 2>/dev/null || echo "friend")}}"
readonly BIRTHDAY="${HL_BIRTHDAY:-}"

# ── Language configuration ────────────────────────────────────────────────────
readonly GREETING_LANGS="${HL_GREETING_LANGS:-en,ja,fr,de,es,ko,zh,pt,it,ar}"

# ── Cache paths ───────────────────────────────────────────────────────────────
readonly CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock"
readonly LANG_INDEX_FILE="${CACHE_ROOT}/lang-index.txt"
readonly HINT_SHOWN_FILE="${CACHE_ROOT}/hint-shown"
readonly WEATHER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/weather/current.json"
readonly POMO_STATE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/state/pomodoro.json"
readonly TODO_FILE="${HOME}/.local/share/ash/todo.txt"
readonly TODOIST_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ash/state/todoist-count.txt"

# ── Time band boundaries (24h hours) ─────────────────────────────────────────
readonly HOUR_DAWN=5        # 05:00 – early morning
readonly HOUR_MORNING=9     # 09:00 – mid-morning
readonly HOUR_NOON=12       # 12:00 – midday
readonly HOUR_AFTERNOON=14  # 14:00 – afternoon
readonly HOUR_EVENING=18    # 18:00 – evening
readonly HOUR_NIGHT=22      # 22:00 – late night
# Before 05:00 = owl hours (working very late / early)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 02 — TIME BAND DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Get current hour (0–23) ───────────────────────────────────────────────────
_current_hour() {
    date +%-H
}

# ── Classify current time into named band ────────────────────────────────────
# Returns: "owl" | "dawn" | "morning" | "noon" | "afternoon" | "evening" | "night"
_time_band() {
    local hour
    hour=$(_current_hour)

    if [[ $hour -ge $HOUR_NIGHT || $hour -lt $HOUR_DAWN ]]; then
        if [[ $hour -ge $HOUR_NIGHT ]]; then
            echo "night"
        else
            echo "owl"
        fi
    elif [[ $hour -ge $HOUR_EVENING ]]; then
        echo "evening"
    elif [[ $hour -ge $HOUR_AFTERNOON ]]; then
        echo "afternoon"
    elif [[ $hour -ge $HOUR_NOON ]]; then
        echo "noon"
    elif [[ $hour -ge $HOUR_MORNING ]]; then
        echo "morning"
    else
        echo "dawn"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 03 — TIME-AWARE GREETING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Primary greeting by time band ────────────────────────────────────────────
output_time_aware() {
    local band
    band=$(_time_band)

    case "$band" in
        owl)        echo "Working late, ${USER_NAME}?  🦉" ;;
        dawn)       echo "Good morning, ${USER_NAME}  🌅" ;;
        morning)    echo "Good morning, ${USER_NAME}  ☀️"  ;;
        noon)       echo "Good afternoon, ${USER_NAME}  🌤️" ;;
        afternoon)  echo "Good afternoon, ${USER_NAME}  ☀️" ;;
        evening)    echo "Good evening, ${USER_NAME}  🌆" ;;
        night)      echo "Good night, ${USER_NAME}  🌙" ;;
        *)          echo "Hello, ${USER_NAME}  ✨" ;;
    esac
}

# ── Context sub-line by time band ────────────────────────────────────────────
output_sub() {
    local band
    band=$(_time_band)

    case "$band" in
        owl)        echo "The world is quiet now  🌌" ;;
        dawn)       echo "Rise and shine  ✨" ;;
        morning)    echo "Hope your day goes well  🌿" ;;
        noon)       echo "Halfway through the day  ⚡" ;;
        afternoon)  echo "Keep up the momentum  🎯" ;;
        evening)    echo "Time to wind down  🍵" ;;
        night)      echo "Sweet dreams await  💤" ;;
        *)          echo "Welcome back  ✨" ;;
    esac
}

# ── Short greeting (no emoji, no name — for minimal layouts) ─────────────────
output_short() {
    local band
    band=$(_time_band)

    case "$band" in
        owl|night)  echo "Good night." ;;
        dawn|morning) echo "Good morning." ;;
        noon|afternoon) echo "Good afternoon." ;;
        evening)    echo "Good evening." ;;
        *)          echo "Welcome back." ;;
    esac
}

# ── Name only ─────────────────────────────────────────────────────────────────
output_name_only() {
    echo "$USER_NAME"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 04 — QUOTE OF THE DAY SYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 60-entry curated quote database.
# Selection seeded by day-of-year → same quote all day, different each dawn.
# Format: "Quote text||Attribution"

readonly -a QUOTE_DB=(
    "The journey of a thousand miles begins with one step.||Lao Tzu"
    "Simplicity is the ultimate sophistication.||Leonardo da Vinci"
    "In the middle of difficulty lies opportunity.||Albert Einstein"
    "It does not matter how slowly you go as long as you do not stop.||Confucius"
    "The best way to predict the future is to create it.||Peter Drucker"
    "Strive not to be a success, but rather to be of value.||Albert Einstein"
    "The only way to do great work is to love what you do.||Steve Jobs"
    "Innovation distinguishes between a leader and a follower.||Steve Jobs"
    "Life is what happens when you're busy making other plans.||John Lennon"
    "The future belongs to those who believe in the beauty of their dreams.||Eleanor Roosevelt"
    "It is during our darkest moments that we must focus to see the light.||Aristotle"
    "Spread love everywhere you go.||Mother Teresa"
    "When you reach the end of your rope, tie a knot and hang on.||Franklin D. Roosevelt"
    "Always remember that you are absolutely unique.||Margaret Mead"
    "Do not go where the path may lead, go instead where there is no path.||Ralph Waldo Emerson"
    "You will face many defeats in life, but never let yourself be defeated.||Maya Angelou"
    "In the end, it's not the years in your life that count. It's the life in your years.||Abraham Lincoln"
    "Never let the fear of striking out keep you from playing the game.||Babe Ruth"
    "Life is either a daring adventure or nothing at all.||Helen Keller"
    "Many of life's failures are people who did not realize how close they were to success.||Thomas A. Edison"
    "You have brains in your head. You have feet in your shoes.||Dr. Seuss"
    "If life were predictable it would cease to be life.||Eleanor Roosevelt"
    "If you look at what you have in life, you'll always have more.||Oprah Winfrey"
    "If you want to live a happy life, tie it to a goal, not to people or things.||Albert Einstein"
    "Never let the fear of striking out keep you from playing the game.||Babe Ruth"
    "Money and success don't change people; they merely amplify what is already there.||Will Smith"
    "Your time is limited, so don't waste it living someone else's life.||Steve Jobs"
    "Not how long, but how well you have lived is the main thing.||Seneca"
    "If life were predictable it would cease to be life, and be without flavor.||Eleanor Roosevelt"
    "The whole secret of a successful life is to find out what is one's destiny to do.||Henry Ford"
    "Consistency is the true foundation of trust.||Roy T. Bennett"
    "Push yourself, because no one else is going to do it for you.||Unknown"
    "Great things never come from comfort zones.||Unknown"
    "Dream it. Wish it. Do it.||Unknown"
    "Success doesn't just find you. You have to go out and get it.||Unknown"
    "The harder you work for something, the greater you'll feel when you achieve it.||Unknown"
    "Don't stop when you're tired. Stop when you're done.||Unknown"
    "Wake up with determination. Go to bed with satisfaction.||Unknown"
    "Little things make big days.||Unknown"
    "It's going to be hard, but hard does not mean impossible.||Unknown"
    "Don't wait for opportunity. Create it.||Unknown"
    "Sometimes we're tested not to show our weaknesses, but to discover our strengths.||Unknown"
    "The key to success is to focus on goals, not obstacles.||Unknown"
    "Dream bigger. Do bigger.||Unknown"
    "You don't have to be great to start, but you have to start to be great.||Zig Ziglar"
    "Act as if what you do makes a difference. It does.||William James"
    "Success is not final, failure is not fatal: it is the courage to continue.||Winston Churchill"
    "Never bend your head. Always hold it high.||Helen Keller"
    "What lies behind you and what lies in front of you is tiny compared to what lies inside of you.||Ralph Waldo Emerson"
    "With the right mindset, we can't lose — we either win or learn.||Unknown"
    "Be so good they can't ignore you.||Steve Martin"
    "I am not a product of my circumstances. I am a product of my decisions.||Stephen Covey"
    "Every child is an artist. The problem is how to remain an artist once we grow up.||Pablo Picasso"
    "You can never cross the ocean until you have the courage to lose sight of the shore.||Christopher Columbus"
    "I've learned that people will forget what you said, but never how you made them feel.||Maya Angelou"
    "Whether you think you can or you think you can't, you're right.||Henry Ford"
    "Definiteness of purpose is the starting point of all achievement.||W. Clement Stone"
    "We must balance conspicuous consumption with conscious capitalism.||Kevin Kruse"
    "Life is not measured by the number of breaths we take, but by the moments that take our breath away.||Maya Angelou"
    "If you want to achieve excellence, you can get there today. As of this second, quit doing less-than-excellent work.||Thomas J. Watson"
    "All our dreams can come true, if we have the courage to pursue them.||Walt Disney"
)

# ── Get today's quote index (seeded by day of year) ──────────────────────────
_quote_index() {
    local doy
    doy=$(date +%-j)
    echo $(( doy % ${#QUOTE_DB[@]} ))
}

# ── Output quote text ────────────────────────────────────────────────────────
output_quote() {
    local idx
    idx=$(_quote_index)
    local entry="${QUOTE_DB[$idx]}"
    # Extract quote (before ||)
    echo "${entry%%||*}"
}

# ── Output quote author ───────────────────────────────────────────────────────
output_quote_author() {
    local idx
    idx=$(_quote_index)
    local entry="${QUOTE_DB[$idx]}"
    # Extract author (after ||)
    local author="${entry##*||}"
    echo "— ${author}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 05 — WEATHER MOOD GREETING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Read weather condition code from ash cache ────────────────────────────────
_get_weather_code() {
    [[ -f "$WEATHER_CACHE" ]] || echo "1000" && return 0
    grep -oP '"code":\s*\K[0-9]+' "$WEATHER_CACHE" 2>/dev/null | head -1 || echo "1000"
}

# ── Read temperature from cache ───────────────────────────────────────────────
_get_weather_temp() {
    [[ -f "$WEATHER_CACHE" ]] || echo "20" && return 0
    grep -oP '"temp_c":\s*\K[-0-9.]+' "$WEATHER_CACHE" 2>/dev/null | head -1 || echo "20"
}

# ── Map weather code + temperature to mood greeting ───────────────────────────
output_weather_mood() {
    local code temp_raw temp_int
    code=$(_get_weather_code)
    temp_raw=$(_get_weather_temp)
    temp_int=$(printf "%.0f" "${temp_raw:-20}" 2>/dev/null || echo "20")

    # Extreme temperature overrides condition-based greeting
    if [[ $temp_int -ge 35 ]]; then
        echo "Stay cool out there, ${USER_NAME}  🧊"
        return 0
    fi
    if [[ $temp_int -le -5 ]]; then
        echo "Bundle up, ${USER_NAME}  🧣❄️"
        return 0
    fi
    if [[ $temp_int -le 5 ]]; then
        echo "It's cold outside, ${USER_NAME}  🥶"
        return 0
    fi

    # Condition-based greetings
    case "$code" in
        1000)                     echo "Beautiful day out there, ${USER_NAME}  🌞" ;;
        1003)                     echo "A little sun, a little cloud  🌤️" ;;
        1006|1009)                echo "Cozy indoor weather, ${USER_NAME}  ☕" ;;
        1030|1135|1147)           echo "Mysterious morning, ${USER_NAME}  🌫️" ;;
        1063|1150|1153|1180|1183) echo "A drizzly one today  🌧️" ;;
        1186|1189|1192|1195)      echo "Perfect day to stay in, ${USER_NAME}  🌧️" ;;
        1198|1201|1240|1243|1246) echo "Heavy rain out there  ☔" ;;
        1087|1273|1276)           echo "Wild weather tonight, ${USER_NAME}  ⚡" ;;
        1066|1210|1213)           echo "Light snow day  ❄️" ;;
        1219|1222|1225)           echo "Snow day, ${USER_NAME}!  ❄️☃️" ;;
        1114|1117)                echo "Blizzard outside — stay warm  🌨️" ;;
        1069|1204|1207|1249|1252) echo "Sleet and ice — careful out there  🧊" ;;
        *)
            # Fall back to temperature-based mood
            if [[ $temp_int -ge 25 ]]; then
                echo "Warm and wonderful today  ☀️"
            elif [[ $temp_int -ge 15 ]]; then
                echo "A pleasant day, ${USER_NAME}  🌿"
            else
                echo "Cool and fresh out there  🍃"
            fi
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 06 — OCCASION DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Check for Thanksgiving (4th Thursday of November, US) ─────────────────────
_is_thanksgiving() {
    local month day year weekday
    month=$(date +%-m)
    day=$(date +%-d)
    year=$(date +%Y)

    [[ $month -ne 11 ]] && echo "0" && return 0

    # 4th Thursday: find day of first Thursday, then +21
    # Day 1's weekday (0=Sun, 1=Mon... 4=Thu)
    local first_weekday
    first_weekday=$(date -d "${year}-11-01" +%w 2>/dev/null || date -j -f "%Y-%m-%d" "${year}-11-01" +%w 2>/dev/null || echo "0")
    # Days to first Thursday from Nov 1
    local days_to_thu=$(( (4 - first_weekday + 7) % 7 ))
    local first_thu=$(( 1 + days_to_thu ))
    local fourth_thu=$(( first_thu + 21 ))

    [[ $day -eq $fourth_thu ]] && echo "1" || echo "0"
}

# ── Get current occasion if any ───────────────────────────────────────────────
# Returns: "occasion_key" or empty string
_detect_occasion() {
    local month day
    month=$(date +%-m)
    day=$(date +%-d)
    local md
    md=$(printf "%02d-%02d" "$month" "$day")

    # User birthday
    if [[ -n "$BIRTHDAY" && "$md" == "$BIRTHDAY" ]]; then
        echo "birthday"
        return 0
    fi

    # Fixed-date occasions
    case "$md" in
        12-24) echo "christmas_eve" && return 0 ;;
        12-25) echo "christmas" && return 0 ;;
        12-26) echo "boxing_day" && return 0 ;;
        12-31) echo "new_years_eve" && return 0 ;;
        01-01) echo "new_years" && return 0 ;;
        02-14) echo "valentines" && return 0 ;;
        03-08) echo "intl_womens_day" && return 0 ;;
        04-01) echo "april_fools" && return 0 ;;
        04-22) echo "earth_day" && return 0 ;;
        05-04) echo "star_wars" && return 0 ;;
        10-31) echo "halloween" && return 0 ;;
        11-11) echo "remembrance" && return 0 ;;
    esac

    # Variable-date occasions
    local is_thanks
    is_thanks=$(_is_thanksgiving)
    [[ "$is_thanks" == "1" ]] && echo "thanksgiving" && return 0

    echo ""
}

# ── Get occasion greeting ─────────────────────────────────────────────────────
output_occasion() {
    local occasion
    occasion=$(_detect_occasion)

    if [[ -z "$occasion" ]]; then
        # No special day — fall back to time-aware
        output_time_aware
        return 0
    fi

    case "$occasion" in
        birthday)         echo "Happy Birthday, ${USER_NAME}!  🎂🎉" ;;
        christmas_eve)    echo "Christmas Eve, ${USER_NAME}!  🎄✨" ;;
        christmas)        echo "Merry Christmas, ${USER_NAME}!  🎅🎁" ;;
        boxing_day)       echo "Happy Boxing Day, ${USER_NAME}!  📦" ;;
        new_years_eve)    echo "Almost there, ${USER_NAME}!  🥂✨" ;;
        new_years)        echo "Happy New Year, ${USER_NAME}!  🎆🎊" ;;
        valentines)       echo "Happy Valentine's Day, ${USER_NAME}!  ❤️" ;;
        intl_womens_day)  echo "Happy International Women's Day!  💜" ;;
        april_fools)      echo "Watch your back today, ${USER_NAME}  😂" ;;
        earth_day)        echo "Happy Earth Day!  🌍💚" ;;
        star_wars)        echo "May the Force be with you, ${USER_NAME}  ⚔️" ;;
        halloween)        echo "Happy Halloween, ${USER_NAME}!  🎃👻" ;;
        remembrance)      echo "Lest we forget  🌹" ;;
        thanksgiving)     echo "Happy Thanksgiving, ${USER_NAME}!  🦃🍂" ;;
        *)                output_time_aware ;;
    esac
}

# ── Get occasion sub-line ─────────────────────────────────────────────────────
output_occasion_sub() {
    local occasion
    occasion=$(_detect_occasion)

    [[ -z "$occasion" ]] && output_sub && return 0

    case "$occasion" in
        birthday)         echo "Hope it's a wonderful one!  🎈" ;;
        christmas_eve)    echo "Santa's almost here  🦌" ;;
        christmas)        echo "Wishing you peace and joy  🕊️" ;;
        new_years_eve)    echo "The year ends, a new one begins  🌟" ;;
        new_years)        echo "New year, new possibilities  🚀" ;;
        valentines)       echo "Spread a little love today  💌" ;;
        april_fools)      echo "Think before you click anything today 😏" ;;
        halloween)        echo "Don't eat all the candy at once  🍬" ;;
        thanksgiving)     echo "Gratitude is always in season  🍁" ;;
        star_wars)        echo "In a galaxy far, far away…  ✨" ;;
        *)                output_sub ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 07 — HAIKU DATABASE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 32 original haiku organized by season for contextual weighting.
# Each entry: "LINE_1_2||LINE_3"  (5+7 syllables || 5 syllables)
# Seasonal weighting: current month biases toward matching season.
# Format: "SEASON:line1 / line2||line3"

readonly -a HAIKU_DB=(
    # Spring (March–May)
    "spring:Cherry blossoms fall / Petals drift on morning breeze||All things start again"
    "spring:Rain on new green leaves / The earth drinks deeply and sighs||Life begins its rush"
    "spring:First light through pink clouds / Sparrows return to bare branch||Season turns once more"
    "spring:Mud between my toes / The garden wakes from long sleep||Seeds know what they are"
    "spring:One more cup of tea / Before the buds become leaves||Winter slowly bows"
    "spring:Quiet Sunday morn / Sunlight pools on wooden floor||Nowhere else to be"
    "spring:Plum blossoms open / Before the last frost has thawed||Courage in the cold"
    # Summer (June–August)
    "summer:Cicadas at noon / Their song fills the heavy air||Heat has no hurry"
    "summer:Long days stretch ahead / The hammock holds all my weight||Summer asks nothing"
    "summer:Storm clouds on the ridge / Before the first lightning strikes||We sit very still"
    "summer:Morning glory blooms / Opens to the rising sun||Closes by midnight"
    "summer:Salt wind off the sea / Children chase the breaking waves||Footprints in the sand"
    "summer:Fireflies at dusk / Rising from the tall wet grass||Brief and beautiful"
    "summer:Last light holds so long / We forget that night will come||Then suddenly dark"
    # Autumn (September–November)
    "autumn:Red leaves on still pond / Their reflection burns so bright||Water holds the fire"
    "autumn:Cold fog in the valley / The mountain keeps its secrets||We learn to wonder"
    "autumn:Harvest moon rising / Through the amber of old oak||The year counts its gifts"
    "autumn:Geese cross the gray sky / Their calls fade into distance||The garden sleeps now"
    "autumn:First fire of the year / Smoke rises from chimney pots||Come in, you are home"
    "autumn:Empty cup cooling / Morning without urgency||Enough is enough"
    "autumn:Wind strips the last leaf / Bare branch against pale gray sky||Now we see the birds"
    # Winter (December–February)
    "winter:Snow before sunrise / Silence thicker than the dark||Even breath slows down"
    "winter:Ice on the window / Patterns no one planned or made||Chance is beautiful"
    "winter:Short days, long shadows / The cat sleeps near the warm vent||Wisdom in small things"
    "winter:Candle in the dark / Its warmth enough for one hand||That is sufficient"
    "winter:Bare trees trace the sky / Their lines like ink on white cloth||Winter calligraphy"
    "winter:Steam above the cup / Rising and then disappearing||Nothing lasts and yet"
    "winter:Stars so cold and bright / They seem to burn without warmth||We reach anyway"
    # All-season / Universal
    "all:Each breath a new chance / The cursor blinks and waits here||Begin where you are"
    "all:System running well / Fans quiet as held breathing||The machine is calm"
    "all:Dawn or dusk or noon / The keyboard waits patiently||Words find their own time"
    "all:One more line of code / Then the test suite passes green||Small victories count"
    "all:Log files scroll past / Each line a moment now gone||Only now is real"
)

# ── Get current season ────────────────────────────────────────────────────────
_current_season() {
    local month
    month=$(date +%-m)
    case $month in
        3|4|5)   echo "spring" ;;
        6|7|8)   echo "summer" ;;
        9|10|11) echo "autumn" ;;
        *)       echo "winter" ;;
    esac
}

# ── Select today's haiku (season-weighted, day-seeded) ───────────────────────
_select_haiku() {
    local season
    season=$(_current_season)
    local doy
    doy=$(date +%-j)

    # Build list: same-season + all-season entries
    local -a candidates=()
    local entry
    for entry in "${HAIKU_DB[@]}"; do
        local entry_season="${entry%%:*}"
        if [[ "$entry_season" == "$season" || "$entry_season" == "all" ]]; then
            candidates+=("${entry#*:}")
        fi
    done

    # Select by day-of-year seed
    local idx=$(( doy % ${#candidates[@]} ))
    echo "${candidates[$idx]}"
}

# ── Output haiku lines 1+2 ───────────────────────────────────────────────────
output_haiku_12() {
    local haiku
    haiku=$(_select_haiku)
    local lines12="${haiku%%||*}"
    echo "${lines12}"
}

# ── Output haiku line 3 ───────────────────────────────────────────────────────
output_haiku_3() {
    local haiku
    haiku=$(_select_haiku)
    echo "${haiku##*||}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 08 — MULTI-LANGUAGE GREETING SYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Language greeting database ────────────────────────────────────────────────
# Format: "lang_code|language_name|morning|afternoon|evening|night"
# Greetings use {name} placeholder — replaced with USER_NAME at runtime.
declare -A LANG_GREETINGS_MORNING=(
    [en]="Good morning, {name}"
    [ja]="おはようございます、{name}"
    [fr]="Bonjour, {name}"
    [de]="Guten Morgen, {name}"
    [es]="Buenos días, {name}"
    [ko]="좋은 아침이에요, {name}"
    [zh]="早上好，{name}"
    [pt]="Bom dia, {name}"
    [it]="Buongiorno, {name}"
    [ar]="صباح الخير، {name}"
    [ru]="Доброе утро, {name}"
    [hi]="सुप्रभात, {name}"
    [nl]="Goedemorgen, {name}"
    [sv]="God morgon, {name}"
    [pl]="Dzień dobry, {name}"
)

declare -A LANG_GREETINGS_AFTERNOON=(
    [en]="Good afternoon, {name}"
    [ja]="こんにちは、{name}"
    [fr]="Bon après-midi, {name}"
    [de]="Guten Tag, {name}"
    [es]="Buenas tardes, {name}"
    [ko]="안녕하세요, {name}"
    [zh]="下午好，{name}"
    [pt]="Boa tarde, {name}"
    [it]="Buon pomeriggio, {name}"
    [ar]="مساء الخير، {name}"
    [ru]="Добрый день, {name}"
    [hi]="नमस्ते, {name}"
    [nl]="Goedemiddag, {name}"
    [sv]="God eftermiddag, {name}"
    [pl]="Dzień dobry, {name}"
)

declare -A LANG_GREETINGS_EVENING=(
    [en]="Good evening, {name}"
    [ja]="こんばんは、{name}"
    [fr]="Bonsoir, {name}"
    [de]="Guten Abend, {name}"
    [es]="Buenas noches, {name}"
    [ko]="좋은 저녁이에요, {name}"
    [zh]="晚上好，{name}"
    [pt]="Boa noite, {name}"
    [it]="Buonasera, {name}"
    [ar]="مساء الخير، {name}"
    [ru]="Добрый вечер, {name}"
    [hi]="शुभ संध्या, {name}"
    [nl]="Goedenavond, {name}"
    [sv]="God kväll, {name}"
    [pl]="Dobry wieczór, {name}"
)

declare -A LANG_NAMES=(
    [en]="English"     [ja]="日本語"    [fr]="Français"
    [de]="Deutsch"     [es]="Español"  [ko]="한국어"
    [zh]="中文"         [pt]="Português" [it]="Italiano"
    [ar]="العربية"     [ru]="Русский"  [hi]="हिन्दी"
    [nl]="Nederlands"  [sv]="Svenska"  [pl]="Polski"
)

# ── Get current language from rotation index ──────────────────────────────────
_get_current_lang() {
    local langs_str="${GREETING_LANGS}"
    IFS=',' read -ra langs <<< "$langs_str"

    # Read index from cache file
    local idx=0
    if [[ -f "$LANG_INDEX_FILE" ]]; then
        local cached_idx
        cached_idx=$(cat "$LANG_INDEX_FILE" 2>/dev/null | tr -d '[:space:]')
        [[ "$cached_idx" =~ ^[0-9]+$ ]] && idx="$cached_idx"
    fi

    # Clamp to valid range
    local lang_count=${#langs[@]}
    idx=$(( idx % lang_count ))

    echo "${langs[$idx]}"
}

# ── Advance language index (called on each lock session) ─────────────────────
_advance_lang_index() {
    local langs_str="${GREETING_LANGS}"
    IFS=',' read -ra langs <<< "$langs_str"
    local lang_count=${#langs[@]}

    local current=0
    [[ -f "$LANG_INDEX_FILE" ]] && current=$(cat "$LANG_INDEX_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
    [[ "$current" =~ ^[0-9]+$ ]] || current=0

    local next=$(( (current + 1) % lang_count ))
    mkdir -p "$(dirname "$LANG_INDEX_FILE")"
    echo "$next" > "$LANG_INDEX_FILE"
}

# ── Output multi-language greeting ────────────────────────────────────────────
output_multilang() {
    local lang
    lang=$(_get_current_lang)
    local band
    band=$(_time_band)

    local template=""
    case "$band" in
        dawn|morning)
            template="${LANG_GREETINGS_MORNING[$lang]:-${LANG_GREETINGS_MORNING[en]}}"
            ;;
        noon|afternoon)
            template="${LANG_GREETINGS_AFTERNOON[$lang]:-${LANG_GREETINGS_AFTERNOON[en]}}"
            ;;
        evening|night|owl)
            template="${LANG_GREETINGS_EVENING[$lang]:-${LANG_GREETINGS_EVENING[en]}}"
            ;;
        *)
            template="${LANG_GREETINGS_MORNING[$lang]:-${LANG_GREETINGS_MORNING[en]}}"
            ;;
    esac

    # Replace {name} placeholder
    echo "${template//\{name\}/$USER_NAME}"
}

# ── Output language label ─────────────────────────────────────────────────────
output_lang_label() {
    local lang
    lang=$(_get_current_lang)
    local lang_name="${LANG_NAMES[$lang]:-$lang}"
    echo "$(echo "$lang" | tr '[:lower:]' '[:upper:]')  •  ${lang_name}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 09 — PRODUCTIVITY GREETING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

output_productivity() {
    # Check pomodoro plugin state
    if [[ -f "$POMO_STATE" ]]; then
        local session phase
        session=$(grep -oP '"session":\s*\K[0-9]+' "$POMO_STATE" 2>/dev/null || echo "0")
        phase=$(grep -oP '"phase":\s*"\K[^"]+' "$POMO_STATE" 2>/dev/null || echo "idle")

        case "$phase" in
            work)
                echo "🍅 Focus session ${session}  •  Stay in the zone, ${USER_NAME}"
                return 0
                ;;
            break)
                echo "☕ Break time, ${USER_NAME}  •  You earned it"
                return 0
                ;;
            long)
                echo "🌿 Long break  •  Recharge fully, ${USER_NAME}"
                return 0
                ;;
        esac
    fi

    # Check task count
    local task_count=0
    if [[ -f "$TODOIST_CACHE" ]]; then
        task_count=$(cat "$TODOIST_CACHE" 2>/dev/null | tr -d '[:space:]')
        [[ "$task_count" =~ ^[0-9]+$ ]] || task_count=0
    elif [[ -f "$TODO_FILE" ]]; then
        task_count=$(grep -c "^- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0")
    fi

    if [[ $task_count -gt 0 ]]; then
        echo "󰄱 ${task_count} tasks pending  •  Good luck, ${USER_NAME}!"
    else
        # All clear — fall back to time-aware
        output_time_aware
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 10 — MAIN DISPATCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local mode="${1:-}"

    # ── Ensure cache directory exists ────────────────────────────────────────
    mkdir -p "$CACHE_ROOT"

    # ── Route to appropriate output function ─────────────────────────────────
    case "$mode" in
        ""|--time-aware)       output_time_aware     ;;
        --sub)                 output_sub            ;;
        --short)               output_short          ;;
        --name-only)           output_name_only      ;;
        --quote)               output_quote          ;;
        --quote-author)        output_quote_author   ;;
        --weather-mood)        output_weather_mood   ;;
        --occasion)            output_occasion       ;;
        --occasion-sub)        output_occasion_sub   ;;
        --haiku-12)            output_haiku_12       ;;
        --haiku-3)             output_haiku_3        ;;
        --multilang)           output_multilang      ;;
        --lang-label)          output_lang_label     ;;
        --advance-lang)
            # Called by on-unlock.sh hook to rotate language
            _advance_lang_index
            ;;
        --mark-hint-shown)
            # Called after first successful unlock
            touch "$HINT_SHOWN_FILE"
            ;;
        --productivity)        output_productivity   ;;
        --version)
            echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
            ;;
        --help|-h)
            echo "Usage: greeting.sh [--time-aware|--sub|--short|--quote|--quote-author|--weather-mood|--occasion|--occasion-sub|--haiku-12|--haiku-3|--multilang|--lang-label|--productivity|--name-only]"
            ;;
        *)
            echo "greeting: unknown flag: $mode" >&2
            output_time_aware
            ;;
    esac
}

main "$@"