#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — migrate command dispatcher                  ║
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

migrate::help() {
cat <<'ASH_EOF'
ash migrate — migrate management

Usage:
  ash migrate <subcommand> [options]

Subcommands:
  from-hyde          from-hyde
  from-hyprdots      from-hyprdots
  from-ml4w          from-ml4w
  help               Show this help

Run 'ash migrate <subcommand> --help' for details.
ASH_EOF
}

migrate::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) migrate::help; return 0 ;;
        from-hyde )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/from-hyde.sh"
            migrate::from_hyde "$@"
            ;;
        from-hyprdots )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/from-hyprdots.sh"
            migrate::from_hyprdots "$@"
            ;;
        from-ml4w )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/from-ml4w.sh"
            migrate::from_ml4w "$@"
            ;;
        *) echo "ash migrate: unknown subcommand '$sub'" >&2; migrate::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate::main "$@"
fi

ash_cmd_migrate() {
    migrate::main "$@"
}

ash_cmd_mig() {
    migrate::main "$@"
}
