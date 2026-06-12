#!/bin/bash
set -euo pipefail

SCHEDULE_FILE="${HOME}/.config/hypr/wallpaper-schedule.conf"

create_schedule() {
    cat > "$SCHEDULE_FILE" << 'EOF'
# Wallpaper Schedule
# Format: HH:MM category

06:00 dawn
08:00 morning
12:00 afternoon
17:00 sunset
20:00 evening
23:00 night
EOF
    echo "Created default schedule at $SCHEDULE_FILE"
}

run_scheduler() {
    [[ -f "$SCHEDULE_FILE" ]] || create_schedule
    
    while true; do
        current_time=$(date +%H:%M)
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            sched_time=$(echo "$line" | awk '{print $1}')
            category=$(echo "$line" | awk '{print $2}')
            if [[ "$current_time" == "$sched_time" ]]; then
                ~/.config/hypr/scripts/theme/smart-wallpaper.sh apply
            fi
        done < "$SCHEDULE_FILE"
        sleep 60
    done
}

main() {
    case "${1:-}" in
        create) create_schedule ;;
        run) run_scheduler ;;
        *) echo "Usage: wallpaper-scheduler.sh [create|run]"; exit 1 ;;
    esac
}

main "$@"