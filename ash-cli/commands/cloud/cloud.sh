#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — cloud command dispatcher                  ║
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

cloud::help() {
cat <<'ASH_EOF'
ash cloud — cloud management

Usage:
  ash cloud <subcommand> [options]

Subcommands:
  configure          configure
  status             status
  sync-down          sync-down
  sync-up            sync-up
  help               Show this help

Run 'ash cloud <subcommand> --help' for details.
ASH_EOF
}

cloud::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) cloud::help; return 0 ;;
        configure )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/configure.sh"
            cloud::configure "$@"
            ;;
        status )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/status.sh"
            cloud::status "$@"
            ;;
        sync-down )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/sync-down.sh"
            cloud::sync_down "$@"
            ;;
        sync-up )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/sync-up.sh"
            cloud::sync_up "$@"
            ;;
        *) echo "ash cloud: unknown subcommand '$sub'" >&2; cloud::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cloud::main "$@"
fi

ash_cmd_cloud() {
    cloud::main "$@"
}
