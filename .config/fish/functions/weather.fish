# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WEATHER FISH FUNCTION                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function weather -d "Show weather for location (default: auto-detect)"
    set -l c_info  (set_color 89b4fa)
    set -l c_err   (set_color f38ba8)
    set -l c_reset (set_color normal)

    set -l location ""
    set -l format   "full"

    for arg in $argv
        switch $arg
            case --short -s
                set format short
            case --json -j
                set format json
            case --help -h
                echo "Usage: weather [location] [--short] [--json]"
                return 0
            case '*'
                set location $arg
        end
    end

    if not command -q curl
        echo -e "  $c_err✗$c_reset curl not installed"
        return 1
    end

    set -l url "https://wttr.in"
    test -n "$location" && set url "https://wttr.in/$location"

    switch $format
        case short
            set -l result (curl -s --max-time 8 "$url?format=3" 2>/dev/null)
            and echo "🌤️  $result"
            or echo -e "  $c_err✗$c_reset Weather unavailable"

        case json
            curl -s --max-time 10 "$url?format=j1" 2>/dev/null | python3 -m json.tool

        case full
            echo -e "  $c_info→$c_reset Fetching weather"(test -n "$location" && echo " for $location" || echo "...")"$c_reset"
            curl -s --max-time 15 "$url?FQpAn1" 2>/dev/null
            or echo -e "  $c_err✗$c_reset Could not fetch weather"
    end
end

complete -c weather -s s -l short -d "One-line summary"
complete -c weather -s j -l json  -d "JSON output"
complete -c weather -s h -l help  -d "Show help"