#!/bin/bash
set -euo pipefail

grim -g "$(slurp)" - | tesseract - - | wl-copy
notify-send "OCR Complete" "Text copied to clipboard"