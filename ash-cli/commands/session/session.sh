#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — session command dispatcher                  ║
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

session::help() {
cat <<'ASH_EOF'
ash session — session management

Usage:
  ash session <subcommand> [options]

Subcommands:
  delete             delete
  list               list
  restore            restore
  save               save
  help               Show this help

Run 'ash session <subcommand> --help' for details.
ASH_EOF
}

session::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) session::help; return 0 ;;
        delete )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/delete.sh"
            session::delete "$@"
            ;;
        list )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/list.sh"
            session::list "$@"
            ;;
        restore )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/restore.sh"
            session::restore "$@"
            ;;
        save )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/save.sh"
            session::save "$@"
            ;;
        *) echo "ash session: unknown subcommand '$sub'" >&2; session::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    session::main "$@"
fi

ash_cmd_session() {
    session::main "$@"
}

ash_cmd_sess() {
    session::main "$@"
}
