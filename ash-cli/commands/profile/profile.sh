#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — profile command dispatcher                  ║
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

profile::help() {
cat <<'ASH_EOF'
ash profile — profile management

Usage:
  ash profile <subcommand> [options]

Subcommands:
  create             create
  delete             delete
  export             export
  import             import
  list               list
  switch             switch
  help               Show this help

Run 'ash profile <subcommand> --help' for details.
ASH_EOF
}

profile::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) profile::help; return 0 ;;
        create )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/create.sh"
            profile::create "$@"
            ;;
        delete )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/delete.sh"
            profile::delete "$@"
            ;;
        export )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/export.sh"
            profile::export "$@"
            ;;
        import )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/import.sh"
            profile::import "$@"
            ;;
        list )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/list.sh"
            profile::list "$@"
            ;;
        switch )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/switch.sh"
            profile::switch "$@"
            ;;
        *) echo "ash profile: unknown subcommand '$sub'" >&2; profile::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    profile::main "$@"
fi

ash_cmd_profile() {
    profile::main "$@"
}

ash_cmd_prof() {
    profile::main "$@"
}
