#!/bin/bash
set -euo pipefail

urgency="${3:-normal}"
expire="${4:-5000}"

notify-send -u "$urgency" -t "$expire" "${1:-Notification}" "${2:-}"