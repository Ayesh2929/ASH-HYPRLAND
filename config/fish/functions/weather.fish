# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — weather Ultra                                      ║
# ║  Rich terminal weather: current, forecast, radar & ASH integration         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function weather --description "Rich terminal weather with forecasts and alerts"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)
    set -l WHITE  (set_color white)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 CONSTANTS                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _cache_dir  "$HOME/.local/share/ash/cache/weather"
    set -l _cache_ttl  1800   # 30 minutes
    set -l _wttr_base  "https://wttr.in"
    set -l _open_base  "https://api.open-meteo.com/v1"
    set -l _geo_base   "https://nominatim.openstreetmap.org"

    mkdir -p $_cache_dir 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _location  ""
    set -l _mode      current    # current | forecast | hourly | minimal | json | radar
    set -l _days      3
    set -l _units     metric     # metric | imperial
    set -l _lang      "en"
    set -l _force     0          # force cache refresh
    set -l _compact   0

    # ── Help ──────────────────────────────────────────────────────────────────
    function __wx_help --description "Print weather help"
        echo ""
        echo $BOLD$CYAN"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$CYAN"  ║     🌤️   weather — Terminal Weather Dashboard         ║"$R
        echo $BOLD$CYAN"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  weather [location] [mode] [options]"
        echo ""
        echo "  $BOLD Modes:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "(none)"       "Current weather" \
            "forecast"     "3-day forecast" \
            "hourly"       "24-hour forecast" \
            "minimal"      "Compact one-liner" \
            "moon"         "Moon phase"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "--days <N>"   "Forecast days (1-7, default: 3)" \
            "--imperial"   "Use imperial units (°F, mph)" \
            "--metric"     "Use metric units (°C, km/h, default)" \
            "--force, -f"  "Force cache refresh" \
            "--compact"    "Compact output" \
            "--help, -h"   "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" \
            "weather                   # Auto-detect location" \
            "weather London            # Current weather in London" \
            "weather Tokyo forecast    # 3-day forecast" \
            "weather NYC hourly        # 24-hour forecast" \
            "weather --imperial        # Use Fahrenheit" \
            "weather Paris --days 5    # 5-day forecast" \
            "weather minimal           # One-liner format"
        echo ""
    end

    # ── Parse arguments ────────────────────────────────────────────────────────
    set -l _i 1
    while test $_i -le (count $argv)
        set -l arg $argv[$_i]
        switch $arg
            case --help -h help;         __wx_help; return 0
            case forecast;               set _mode forecast
            case hourly;                 set _mode hourly
            case minimal compact;        set _mode minimal; set _compact 1
            case moon;                   set _mode moon
            case --imperial -f;          set _units imperial
            case --metric;               set _units metric
            case --force -r refresh;     set _force 1
            case --compact;              set _compact 1
            case --days=*
                set _days (string replace '--days=' '' $arg)
            case --days
                set _i (math $_i + 1); set _days $argv[$_i]
            case '*'
                # Accumulate location words
                if test -z "$_location"
                    set _location $arg
                else
                    set _location "$_location $arg"
                end
        end
        set _i (math $_i + 1)
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌡️  UNIT HELPERS                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __wx_temp --description "Format temperature"
        set -l celsius $argv[1]
        if test "$_units" = imperial
            math --scale 0 "$celsius * 9 / 5 + 32" | read -l f
            echo "$f°F"
        else
            echo "$celsius°C"
        end
    end

    function __wx_wind --description "Format wind speed"
        set -l kmh $argv[1]
        if test "$_units" = imperial
            math --scale 0 "$kmh * 0.621371" | read -l mph
            echo "$mph mph"
        else
            echo "$kmh km/h"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌈 WEATHER CONDITION ICONS & COLORS                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __wx_wmo_info --description "Get icon and description for WMO weather code"
        set -l code $argv[1]

        switch $code
            case 0;             echo "☀️   Clear sky"
            case 1;             echo "🌤️   Mainly clear"
            case 2;             echo "⛅   Partly cloudy"
            case 3;             echo "☁️   Overcast"
            case 45 48;         echo "🌫️   Foggy"
            case 51 53 55;      echo "🌦️   Drizzle"
            case 61 63 65;      echo "🌧️   Rain"
            case 71 73 75;      echo "🌨️   Snow"
            case 77;            echo "🌨️   Snow grains"
            case 80 81 82;      echo "🌦️   Rain showers"
            case 85 86;         echo "🌨️   Snow showers"
            case 95;            echo "⛈️   Thunderstorm"
            case 96 99;         echo "⛈️   Thunderstorm + hail"
            case '*'
                echo "🌡️   Unknown ($code)"
        end
    end

    function __wx_condition_color --description "Get color for weather condition"
        set -l code $argv[1]
        switch $code
            case 0 1;   echo $YELLOW   # sunny
            case 2 3;   echo $DIM      # cloudy
            case 45 48; echo $DIM      # fog
            case 51 53 55 61 63 65 80 81 82
                echo $BLUE             # rain
            case 71 73 75 77 85 86
                echo $WHITE            # snow
            case 95 96 99
                echo $PURPLE           # thunder
            case '*';   echo $R
        end
    end

    function __wx_uv_label --description "UV index label"
        set -l uv $argv[1]
        if test $uv -le 2
            echo $GREEN"Low$R"
        else if test $uv -le 5
            echo $YELLOW"Moderate$R"
        else if test $uv -le 7
            echo $ORANGE"High$R"
        else if test $uv -le 10
            echo $RED"Very High$R"
        else
            echo $PURPLE"Extreme$R"
        end
    end

    function __wx_aqi_label --description "Air quality label"
        set -l aqi $argv[1]
        if test $aqi -le 50
            echo $GREEN"Good$R"
        else if test $aqi -le 100
            echo $YELLOW"Moderate$R"
        else if test $aqi -le 150
            echo $ORANGE"Unhealthy (Sensitive)$R"
        else if test $aqi -le 200
            echo $RED"Unhealthy$R"
        else
            echo $PURPLE"Hazardous$R"
        end
    end

    function __wx_wind_dir --description "Wind direction from degrees"
        set -l deg $argv[1]
        if test $deg -lt 22
            echo "N"
        else if test $deg -lt 67
            echo "NE"
        else if test $deg -lt 112
            echo "E"
        else if test $deg -lt 157
            echo "SE"
        else if test $deg -lt 202
            echo "S"
        else if test $deg -lt 247
            echo "SW"
        else if test $deg -lt 292
            echo "W"
        else if test $deg -lt 337
            echo "NW"
        else
            echo "N"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌐 DATA FETCHING                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Check network ─────────────────────────────────────────────────────────
    if not ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
        printf "  $RED✗$R  No internet connection\n"
        return 1
    end

    # ── Check curl ────────────────────────────────────────────────────────────
    if not command -q curl
        printf "  $RED✗$R  curl required\n"
        return 1
    end

    # ── Build cache key ────────────────────────────────────────────────────────
    set -l _cache_key (string lower (string replace -a ' ' '-' "$_location-$_mode-$_days-$_units"))
    set -l _cache_file "$_cache_dir/$_cache_key.json"

    # ── Use wttr.in for easy display modes ────────────────────────────────────
    function __wx_wttr --description "Fetch from wttr.in"
        set -l loc (string replace -a ' ' '+' "$_location")
        set -l url "$_wttr_base"
        test -n "$loc" && set url "$url/$loc"

        set -l format_flag ""
        switch $_mode
            case minimal
                set format_flag "?format=4"
            case moon
                set format_flag "?format=%m"
            case '*'
                set format_flag "?format=j1"
        end

        curl -s --max-time 8 "${url}${format_flag}" 2>/dev/null
    end

    # ── Auto-detect location via IP ────────────────────────────────────────────
    function __wx_detect_location --description "Auto-detect location"
        set -l cache_file "$_cache_dir/auto-location.json"

        if test -f $cache_file
            set -l age (math (date +%s) - (stat -c %Y $cache_file 2>/dev/null; or echo 0))
            if test $age -lt 86400   # 24 hours
                cat $cache_file
                return
            end
        end

        # Try multiple IP geolocation services
        set -l result ""
        for service in \
            "https://ipapi.co/json" \
            "https://ip-api.com/json"
            set result (curl -s --max-time 5 $service 2>/dev/null)
            test -n "$result" && break
        end

        test -n "$result" && echo $result > $cache_file 2>/dev/null
        echo $result
    end

    # ── Get coordinates from location name ─────────────────────────────────────
    function __wx_geocode --description "Geocode location name to lat/lon"
        set -l loc $argv[1]
        set -l url "$_geo_base/search?q=$(string replace -a ' ' '+' $loc)&format=json&limit=1"
        curl -s --max-time 5 \
            -H "User-Agent: ASH-Dotfiles-Weather/5.0" \
            $url 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌤️  RENDER MODES                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Minimal one-liner ─────────────────────────────────────────────────────
    if test "$_mode" = minimal
        set -l wttr_data (__wx_wttr)
        if test -n "$wttr_data"
            printf "  %s\n" $wttr_data
        else
            printf "  $RED✗$R  Weather data unavailable\n"
        end
        functions --erase __wx_help __wx_temp __wx_wind __wx_wmo_info \
            __wx_condition_color __wx_uv_label __wx_aqi_label \
            __wx_wind_dir __wx_wttr __wx_detect_location __wx_geocode 2>/dev/null
        return 0
    end

    # ── Moon phase ────────────────────────────────────────────────────────────
    if test "$_mode" = moon
        set -l moon_data (__wx_wttr)
        printf "\n  $BOLD$CYAN  Moon Phase$R\n\n"
        printf "  %s\n\n" $moon_data
        functions --erase __wx_help __wx_temp __wx_wind __wx_wmo_info \
            __wx_condition_color __wx_uv_label __wx_aqi_label \
            __wx_wind_dir __wx_wttr __wx_detect_location __wx_geocode 2>/dev/null
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📡 FETCH WEATHER DATA                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    printf "  $DIM  Fetching weather data...$R\r"

    # ── Get location data ──────────────────────────────────────────────────────
    set -l lat ""
    set -l lon ""
    set -l city_name ""
    set -l country ""

    if test -z "$_location"
        # Auto-detect
        set -l geo_data (__wx_detect_location)
        if test -n "$geo_data" && command -q jq
            set lat (echo $geo_data | jq -r '.latitude // .lat // empty' 2>/dev/null)
            set lon (echo $geo_data | jq -r '.longitude // .lon // empty' 2>/dev/null)
            set city_name (echo $geo_data | jq -r '.city // .cityName // "Unknown"' 2>/dev/null)
            set country  (echo $geo_data | jq -r '.country_name // .country // "Unknown"' 2>/dev/null)
        end
    else
        # Geocode provided location
        set -l geo_data (__wx_geocode "$_location")
        if test -n "$geo_data" && command -q jq
            set lat (echo $geo_data | jq -r '.[0].lat // empty' 2>/dev/null)
            set lon (echo $geo_data | jq -r '.[0].lon // empty' 2>/dev/null)
            set city_name (echo $geo_data | jq -r '.[0].display_name // empty' 2>/dev/null | \
                awk -F, '{print $1}')
            set country  (echo $geo_data | jq -r '.[0].display_name // empty' 2>/dev/null | \
                awk -F, '{print $NF}' | string trim)
        end
        test -z "$city_name" && set city_name $_location
    end

    if test -z "$lat" || test -z "$lon"
        printf "  $RED✗$R  Could not determine location\n"
        printf "  $DIM  Try: weather <city name>$R\n"
        return 1
    end

    # ── Fetch from open-meteo ──────────────────────────────────────────────────
    set -l wx_url "$_open_base/forecast?\
latitude=$lat&longitude=$lon&\
current=temperature_2m,relative_humidity_2m,apparent_temperature,\
precipitation,weather_code,surface_pressure,wind_speed_10m,\
wind_direction_10m,wind_gusts_10m,cloud_cover,visibility,uv_index&\
hourly=temperature_2m,precipitation_probability,weather_code,\
wind_speed_10m&\
daily=temperature_2m_max,temperature_2m_min,weather_code,\
sunrise,sunset,precipitation_sum,precipitation_probability_max,\
wind_speed_10m_max,uv_index_max&\
timezone=auto&forecast_days=$_days&\
wind_speed_unit=(test $_units = imperial && echo mph || echo kmh)&\
temperature_unit=(test $_units = imperial && echo fahrenheit || echo celsius)"

    set -l wx_data ""

    # Check cache
    if test -f $_cache_file && test $_force -eq 0
        set -l age (math (date +%s) - (stat -c %Y $_cache_file 2>/dev/null; or echo 0))
        if test $age -lt $_cache_ttl
            set wx_data (cat $_cache_file)
        end
    end

    if test -z "$wx_data"
        set wx_data (curl -s --max-time 10 $wx_url 2>/dev/null)
        test -n "$wx_data" && echo $wx_data > $_cache_file 2>/dev/null
    end

    if test -z "$wx_data" || not command -q jq
        # Fallback to wttr.in for display
        printf "  $YELLOW⚠$R  Using wttr.in (open-meteo unavailable)\n\n"
        set -l loc (string replace -a ' ' '+' "$_location")
        curl -s --max-time 10 "$_wttr_base/$loc?1" 2>/dev/null
        return $status
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 PARSE WEATHER DATA                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Current conditions
    set -l cur_temp     (echo $wx_data | jq -r '.current.temperature_2m     // "?"' 2>/dev/null)
    set -l cur_feels    (echo $wx_data | jq -r '.current.apparent_temperature // "?"' 2>/dev/null)
    set -l cur_humidity (echo $wx_data | jq -r '.current.relative_humidity_2m // "?"' 2>/dev/null)
    set -l cur_precip   (echo $wx_data | jq -r '.current.precipitation        // "?"' 2>/dev/null)
    set -l cur_code     (echo $wx_data | jq -r '.current.weather_code         // 0'   2>/dev/null)
    set -l cur_pressure (echo $wx_data | jq -r '.current.surface_pressure      // "?"' 2>/dev/null)
    set -l cur_wind     (echo $wx_data | jq -r '.current.wind_speed_10m        // "?"' 2>/dev/null)
    set -l cur_wdir     (echo $wx_data | jq -r '.current.wind_direction_10m    // 0'   2>/dev/null)
    set -l cur_gusts    (echo $wx_data | jq -r '.current.wind_gusts_10m        // "?"' 2>/dev/null)
    set -l cur_cloud    (echo $wx_data | jq -r '.current.cloud_cover           // "?"' 2>/dev/null)
    set -l cur_vis      (echo $wx_data | jq -r '.current.visibility            // "?"' 2>/dev/null)
    set -l cur_uv       (echo $wx_data | jq -r '.current.uv_index             // "?"' 2>/dev/null)
    set -l cur_time     (echo $wx_data | jq -r '.current.time                  // ""'  2>/dev/null)
    set -l timezone     (echo $wx_data | jq -r '.timezone                       // "UTC"' 2>/dev/null)

    # Today's summary
    set -l today_max    (echo $wx_data | jq -r '.daily.temperature_2m_max[0]  // "?"' 2>/dev/null)
    set -l today_min    (echo $wx_data | jq -r '.daily.temperature_2m_min[0]  // "?"' 2>/dev/null)
    set -l today_uv     (echo $wx_data | jq -r '.daily.uv_index_max[0]        // "?"' 2>/dev/null)
    set -l today_precip (echo $wx_data | jq -r '.daily.precipitation_sum[0]   // "?"' 2>/dev/null)
    set -l today_rain   (echo $wx_data | jq -r '.daily.precipitation_probability_max[0] // "?"' 2>/dev/null)
    set -l today_rise   (echo $wx_data | jq -r '.daily.sunrise[0]             // "?"' 2>/dev/null)
    set -l today_set    (echo $wx_data | jq -r '.daily.sunset[0]              // "?"' 2>/dev/null)

    # Format sunrise/sunset
    set -l sunrise  (string replace -r 'T' ' ' $today_rise | awk '{print $2}' | cut -c1-5)
    set -l sunset   (string replace -r 'T' ' ' $today_set  | awk '{print $2}' | cut -c1-5)

    # Condition info
    set -l condition_info (__wx_wmo_info $cur_code)
    set -l cond_icon (echo $condition_info | awk '{print $1}')
    set -l cond_text (echo $condition_info | awk '{$1=""; print $0}' | string trim)
    set -l cond_color (__wx_condition_color $cur_code)

    set -l wind_dir_str (__wx_wind_dir $cur_wdir)
    set -l temp_unit (test $_units = imperial && echo "°F" || echo "°C")
    set -l speed_unit (test $_units = imperial && echo "mph" || echo "km/h")

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  CURRENT WEATHER DISPLAY                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    printf "\r  "  # Clear "Fetching..." line
    printf "\n"

    # ── Header ────────────────────────────────────────────────────────────────
    printf "  $BOLD$CYAN╔══════════════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$CYAN║  🌤️   Weather: %-50s║$R\n" \
        (string sub --length 50 "$city_name, $country")
    printf "  $BOLD$CYAN║  %-64s║$R\n" \
        "  $DIM$timezone  ·  Updated: $(date '+%H:%M')$R"
    printf "  $BOLD$CYAN╠══════════════════════════════════════════════════════════════╣$R\n"

    # ── Temperature (large) ───────────────────────────────────────────────────
    printf "  $BOLD$CYAN║$R\n"
    printf "  $BOLD$CYAN║$R  %s$BOLD%s %-4s%s$R  $cond_color%-20s$R  $DIM(feels like %s%s)$R\n" \
        $cond_icon \
        $BOLD (string split '.' $cur_temp)[1] $temp_unit \
        $cond_text \
        (string split '.' $cur_feels)[1] $temp_unit

    printf "  $BOLD$CYAN║$R  $DIM  High: $YELLOW%s%s$R  $DIM·  Low: $BLUE%s%s$R  $DIM·  Humidity: $CYAN%s%%%R\n" \
        (string split '.' $today_max)[1] $temp_unit \
        (string split '.' $today_min)[1] $temp_unit \
        $cur_humidity

    printf "  $BOLD$CYAN║$R\n"
    printf "  $BOLD$CYAN╠══════════════════════════════════════════════════════════════╣$R\n"

    # ── Details grid ─────────────────────────────────────────────────────────
    printf "  $BOLD$CYAN║$R\n"
    printf "  $BOLD$CYAN║$R  $BOLD  Details$R\n"
    printf "  $BOLD$CYAN║$R\n"

    # Row 1
    printf "  $BOLD$CYAN║$R  $BOLD  Wind       $R$CYAN%-15s$R $DIM|$R " "$cur_wind $speed_unit $wind_dir_str"
    printf "  $BOLD Gusts     $R$CYAN%s $speed_unit$R\n" (string split '.' $cur_gusts)[1]

    # Row 2
    printf "  $BOLD$CYAN║$R  $BOLD  Humidity   $R$CYAN%-15s$R $DIM|$R " "$cur_humidity%"
    printf "  $BOLD Pressure  $R$CYAN%s hPa$R\n" (string split '.' $cur_pressure)[1]

    # Row 3
    printf "  $BOLD$CYAN║$R  $BOLD  Cloud cover$R$CYAN%-15s$R $DIM|$R " "$cur_cloud%"
    printf "  $BOLD UV Index  $R%s\n" (__wx_uv_label (string split '.' $cur_uv)[1])

    # Row 4
    printf "  $BOLD$CYAN║$R  $BOLD  Rain today $R$CYAN%-15s$R $DIM|$R " "$today_rain% chance"
    printf "  $BOLD Precip    $R$CYAN%s mm$R\n" (string split '.' $today_precip)[1]

    # Row 5: sunrise/sunset
    printf "  $BOLD$CYAN║$R  $BOLD  Sunrise    $R$YELLOW%-15s$R $DIM|$R " "🌅 $sunrise"
    printf "  $BOLD Sunset    $R$ORANGE%s$R\n" "🌇 $sunset"

    printf "  $BOLD$CYAN║$R\n"
    printf "  $BOLD$CYAN╚══════════════════════════════════════════════════════════════╝$R\n"

    # ── Stop here if current-only mode ────────────────────────────────────────
    if test "$_mode" = current
        printf "\n  $DIM  Run: weather forecast   for %d-day forecast$R\n\n" $_days
        functions --erase __wx_help __wx_temp __wx_wind __wx_wmo_info \
            __wx_condition_color __wx_uv_label __wx_aqi_label \
            __wx_wind_dir __wx_wttr __wx_detect_location __wx_geocode 2>/dev/null
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📅 FORECAST DISPLAY                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = forecast
        printf "\n  $BOLD$PURPLE  📅 %d-Day Forecast$R\n\n" $_days
        printf "  $BOLD$PURPLE%-12s  %-4s  %-4s  %-20s  %-10s  %-10s  %s$R\n" \
            "DATE" "MAX" "MIN" "CONDITION" "PRECIP" "RAIN%" "UV"
        printf "  $DIM%s$R\n" (string repeat -n 75 "─")

        echo $wx_data | jq -r '
            .daily |
            [.time, .temperature_2m_max, .temperature_2m_min, .weather_code,
             .precipitation_sum, .precipitation_probability_max, .uv_index_max] |
            transpose[] |
            @tsv
        ' 2>/dev/null | while read -l line
            set -l parts (string split \t $line)
            set -l date     $parts[1]
            set -l max_t    (string split '.' $parts[2])[1]
            set -l min_t    (string split '.' $parts[3])[1]
            set -l code     $parts[4]
            set -l precip   (string split '.' $parts[5])[1]
            set -l rain_pct $parts[6]
            set -l uv       (string split '.' $parts[7])[1]

            set -l info (__wx_wmo_info $code)
            set -l icon (echo $info | awk '{print $1}')
            set -l desc (echo $info | awk '{$1=""; print $0}' | string trim | string sub --length 16)
            set -l ccol (__wx_condition_color $code)

            # Day of week
            set -l day_name (date -d $date '+%a %b %-d' 2>/dev/null; \
                or date -jf '%Y-%m-%d' $date '+%a %b %-d' 2>/dev/null; \
                or echo $date)

            printf "  $DIM%-12s$R  $YELLOW%-4s$R  $BLUE%-4s$R  %s$ccol%-20s$R  $CYAN%-3s mm$R  $BLUE%-5s%%$R  %s\n" \
                $day_name "$max_t°" "$min_t°" $icon $desc $precip $rain_pct \
                (__wx_uv_label $uv)
        end
        printf "\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏰ HOURLY DISPLAY                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$_mode" = hourly
        printf "\n  $BOLD$PURPLE  ⏰ 24-Hour Forecast$R\n\n"
        printf "  $BOLD$PURPLE%-8s  %-6s  %-20s  %-10s  %s$R\n" \
            "TIME" "TEMP" "CONDITION" "WIND" "RAIN%"
        printf "  $DIM%s$R\n" (string repeat -n 60 "─")

        echo $wx_data | jq -r '
            .hourly |
            [.time, .temperature_2m, .weather_code,
             .wind_speed_10m, .precipitation_probability] |
            transpose[0:24][] |
            @tsv
        ' 2>/dev/null | while read -l line
            set -l parts (string split \t $line)
            set -l time_str $parts[1]
            set -l temp     (string split '.' $parts[2])[1]
            set -l code     $parts[3]
            set -l wind     (string split '.' $parts[4])[1]
            set -l rain_pct $parts[5]

            # Format time
            set -l hour (string replace -r 'T' ' ' $time_str | awk '{print $2}' | cut -c1-5)

            set -l info (__wx_wmo_info $code)
            set -l icon (echo $info | awk '{print $1}')
            set -l desc (echo $info | awk '{$1=""; print $0}' | string trim | string sub --length 16)
            set -l ccol (__wx_condition_color $code)

            # Rain probability color
            set -l rain_col $DIM
            test $rain_pct -gt 60 2>/dev/null && set rain_col $BLUE
            test $rain_pct -gt 80 2>/dev/null && set rain_col $CYAN

            printf "  $CYAN%-8s$R  $YELLOW%s°$R      %s$ccol%-18s$R  $DIM%-6s km/h$R  $rain_col%s%%$R\n" \
                $hour $temp $icon $desc $wind $rain_pct
        end
        printf "\n"
    end

    # ── Footer tip ─────────────────────────────────────────────────────────────
    printf "  $DIM  Data: open-meteo.com  ·  Cache: %dm  ·  Location: %s, %s$R\n\n" \
        (math $_cache_ttl / 60) $city_name $country

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __wx_help __wx_temp __wx_wind __wx_wmo_info \
        __wx_condition_color __wx_uv_label __wx_aqi_label \
        __wx_wind_dir __wx_wttr __wx_detect_location __wx_geocode 2>/dev/null

end
