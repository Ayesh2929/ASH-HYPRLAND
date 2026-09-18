#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store command dispatcher                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${CMD_DIR}/../../lib"
ROOT_DIR="$(cd "${CMD_DIR}/../../.." && pwd)"

for _lib in colors logger utils; do
    [[ -r "${LIB_DIR}/${_lib}.sh" ]] && source "${LIB_DIR}/${_lib}.sh"
done
unset _lib

store::help() {
cat <<'ASH_EOF'
ash store — store management

Usage:
  ash store <subcommand> [options]

Subcommands:
  browse             browse
  download           download
  rate               rate
  search             search
  trending           trending
  upload             upload
  help               Show this help

Run 'ash store <subcommand> --help' for details.
ASH_EOF
}

store::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) store::help; return 0 ;;
        browse )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/browse.sh"
            store::browse "$@"
            ;;
        download )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/download.sh"
            store::download "$@"
            ;;
        rate )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/rate.sh"
            store::rate "$@"
            ;;
        search )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/search.sh"
            store::search "$@"
            ;;
        trending )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/trending.sh"
            store::trending "$@"
            ;;
        upload )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/upload.sh"
            store::upload "$@"
            ;;
        *) echo "ash store: unknown subcommand '$sub'" >&2; store::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::main "$@"
fi

ash_cmd_store() {
    store::main "$@"
}
