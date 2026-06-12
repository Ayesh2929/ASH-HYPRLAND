#!/bin/bash
set -euo pipefail

get_location() {
    curl -sf "https://ipapi.co/json/" | jq -r '.latitude, .longitude, .city, .country_name' 2>/dev/null
}

set_location() {
    local lat="${1:-}"
    local lon="${2:-}"
    [[ -z "$lat" || -z "$lon" ]] && { echo "Usage: geolocation.sh set <lat> <lon>"; return 1; }
    
    mkdir -p ~/.config/hypr/env.d
    echo "ASH_LAT=$lat" > ~/.config/hypr/env.d/location.conf
    echo "ASH_LON=$lon" >> ~/.config/hypr/env.d/location.conf
    echo "Location set: $lat, $lon"
}

main() {
    case "${1:-}" in
        get) get_location ;;
        set) set_location "${2:-}" "${3:-}" ;;
        *) echo "Usage: geolocation.sh [get|set]"; exit 1 ;;
    esac
}

main "$@"