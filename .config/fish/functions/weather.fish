# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WEATHER FUNCTION                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function weather -d "Show weather forecast"
    set -l c_info  (set_color 89b4fa)
    set -l c_ok    (set_color a6e3a1)
    set -l c_warn  (set_color f9e2af)
    set -l c_err   (set_color f38ba8)
    set -l c_reset (set_color normal)

    set -l location ""
    set -l format "full"

    # Parse arguments
    for arg in $argv
        switch $arg
            case --short -s
                set format "short"
            case --json -j
                set format "json"
            case --help -h
                echo "Usage: weather [location] [--short|-s] [--json|-j]"
                echo ""
                echo "Examples:"
                echo "  weather              # Auto-detect location"
                echo "  weather London       # Weather for London"
                echo "  weather 'New York'   # Weather for New York"
                echo "  weather --short      # One-line summary"
                return 0
            case '*'
                set location $arg
        end
    end

    # Check connectivity
    if not command -q curl
        echo -s $c_err"❌ curl not installed"$c_reset
        return 1
    end

    # Auto-detect location if not provided
    if test -z "$location"
        # Check cache
        if test -f ~/.cache/ash-dots/weather-location
            set location (cat ~/.cache/ash-dots/weather-location)
        end
    end

    set -l url "https://wttr.in"
    test -n "$location" && set url "https://wttr.in/$location"

    switch $format
        case short
            # One-line format
            set -l result (curl -s --max-time 10 "$url?format=3" 2>/dev/null)
            if test $status -eq 0 && test -n "$result"
                echo -s "🌤️  "$c_ok$result$c_reset
            else
                echo -s $c_err"❌ Weather unavailable"$c_reset
                return 1
            end

        case json
            curl -s --max-time 10 "$url?format=j1" 2>/dev/null | jq .

        case full
            # Full forecast display
            echo -s $c_info"🌤️ Fetching weather"(test -n "$location" && echo " for $location" || echo "")$c_reset"..."
            echo ""
            curl -s --max-time 15 "$url?FQpAn1" 2>/dev/null

            if test $status -ne 0
                echo -s $c_err"❌ Failed to fetch weather"$c_reset
                return 1
            end
    end
end

complete -c weather -s s -l short -d "Short format"
complete -c weather -s j -l json  -d "JSON format"
complete -c weather -s h -l help  -d "Show help"