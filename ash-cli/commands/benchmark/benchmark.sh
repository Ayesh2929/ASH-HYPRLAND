#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — benchmark command dispatcher                  ║
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

benchmark::help() {
cat <<'ASH_EOF'
ash benchmark — benchmark management

Usage:
  ash benchmark <subcommand> [options]

Subcommands:
  memory             memory
  report             report
  startup            startup
  theme-apply        theme-apply
  help               Show this help

Run 'ash benchmark <subcommand> --help' for details.
ASH_EOF
}

benchmark::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) benchmark::help; return 0 ;;
        memory )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/memory.sh"
            benchmark::memory "$@"
            ;;
        report )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/report.sh"
            benchmark::report "$@"
            ;;
        startup )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/startup.sh"
            benchmark::startup "$@"
            ;;
        theme-apply )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/theme-apply.sh"
            benchmark::theme_apply "$@"
            ;;
        *) echo "ash benchmark: unknown subcommand '$sub'" >&2; benchmark::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    benchmark::main "$@"
fi

ash_cmd_benchmark() {
    benchmark::main "$@"
}

ash_cmd_bench() {
    benchmark::main "$@"
}
