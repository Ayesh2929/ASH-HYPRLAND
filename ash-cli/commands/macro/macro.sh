#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — macro command dispatcher                  ║
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

macro::help() {
cat <<'ASH_EOF'
ash macro — macro management

Usage:
  ash macro <subcommand> [options]

Subcommands:
  delete             delete
  edit               edit
  list               list
  play               play
  record             record
  help               Show this help

Run 'ash macro <subcommand> --help' for details.
ASH_EOF
}

macro::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) macro::help; return 0 ;;
        delete )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/delete.sh"
            macro::delete "$@"
            ;;
        edit )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/edit.sh"
            macro::edit "$@"
            ;;
        list )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/list.sh"
            macro::list "$@"
            ;;
        play )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/play.sh"
            macro::play "$@"
            ;;
        record )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/record.sh"
            macro::record "$@"
            ;;
        *) echo "ash macro: unknown subcommand '$sub'" >&2; macro::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    macro::main "$@"
fi

ash_cmd_macro() {
    macro::main "$@"
}
