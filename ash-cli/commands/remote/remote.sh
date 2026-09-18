#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — remote command dispatcher                  ║
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

remote::help() {
cat <<'ASH_EOF'
ash remote — remote management

Usage:
  ash remote <subcommand> [options]

Subcommands:
  apply-theme        apply-theme
  connect            connect
  sync-config        sync-config
  help               Show this help

Run 'ash remote <subcommand> --help' for details.
ASH_EOF
}

remote::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) remote::help; return 0 ;;
        apply-theme )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/apply-theme.sh"
            remote::apply_theme "$@"
            ;;
        connect )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/connect.sh"
            remote::connect "$@"
            ;;
        sync-config )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/sync-config.sh"
            remote::sync_config "$@"
            ;;
        *) echo "ash remote: unknown subcommand '$sub'" >&2; remote::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote::main "$@"
fi

ash_cmd_remote() {
    remote::main "$@"
}
