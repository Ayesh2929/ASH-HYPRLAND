#!/usr/bin/env bash
# ASH script template — copy to create a new helper
set -euo pipefail
IFS=$'\n\t'
# Template for new ASH scripts:
# 1. Copy this file to scripts/your-feature/your-script.sh
# 2. Implement main() below
# 3. Add --help and --dry-run handling

usage() {
    cat <<'EOF'
Usage: script.sh [--help] [--dry-run] [args...]

ASH script template — replace with your script's documentation.
EOF
}

main() {
    while (( $# )); do
        case "$1" in
            --help|-h) usage; exit 0 ;;
            --dry-run) echo "[dry-run] would run"; exit 0 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    echo "script.sh template — implement your logic here (args: $*)"
}

main "$@"
