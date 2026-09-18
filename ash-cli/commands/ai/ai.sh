#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ai command dispatcher                  ║
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

ai::help() {
cat <<'ASH_EOF'
ash ai — ai management

Usage:
  ash ai <subcommand> [options]

Subcommands:
  chat               chat
  explain            explain
  fix-issue          fix-issue
  optimize-config    optimize-config
  suggest-theme      suggest-theme
  help               Show this help

Run 'ash ai <subcommand> --help' for details.
ASH_EOF
}

ai::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) ai::help; return 0 ;;
        chat )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/chat.sh"
            ai::chat "$@"
            ;;
        explain )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/explain.sh"
            ai::explain "$@"
            ;;
        fix-issue )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/fix-issue.sh"
            ai::fix_issue "$@"
            ;;
        optimize-config )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/optimize-config.sh"
            ai::optimize_config "$@"
            ;;
        suggest-theme )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/suggest-theme.sh"
            ai::suggest_theme "$@"
            ;;
        *) echo "ash ai: unknown subcommand '$sub'" >&2; ai::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ai::main "$@"
fi

ash_cmd_ai() {
    ai::main "$@"
}
