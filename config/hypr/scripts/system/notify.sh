#!/bin/bash
set -euo pipefail

notify-send "${1:-Notification}" "${2:-}" "${3:-}"