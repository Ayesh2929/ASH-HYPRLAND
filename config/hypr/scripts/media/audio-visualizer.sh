#!/bin/bash
set -euo pipefail

case "${1:-}" in
    start) cava -p ~/.config/cava/config ;;
    stop) pkill -f cava ;;
    config)
        mkdir -p ~/.config/cava
        cat > ~/.config/cava/config << 'EOF'
[general]
framerate = 60
bars = 30
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 20
EOF
        echo "Config created"
        ;;
    *) echo "Usage: audio-visualizer.sh [start|stop|config]"; exit 1 ;;
esac