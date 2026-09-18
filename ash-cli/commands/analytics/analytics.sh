#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — analytics command dispatcher                  ║
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

analytics::help() {
cat <<'ASH_EOF'
ash analytics — analytics management

Usage:
  ash analytics <subcommand> [options]

Subcommands:
  command-stats      command-stats
  dashboard          dashboard
  export-report      export-report
  performance-stats  performance-stats
  theme-stats        theme-stats
  help               Show this help

Run 'ash analytics <subcommand> --help' for details.
ASH_EOF
}

analytics::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) analytics::help; return 0 ;;
        command-stats )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/command-stats.sh"
            analytics::command_stats "$@"
            ;;
        dashboard )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/dashboard.sh"
            analytics::dashboard "$@"
            ;;
        export-report )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/export-report.sh"
            analytics::export_report "$@"
            ;;
        performance-stats )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/performance-stats.sh"
            analytics::performance_stats "$@"
            ;;
        theme-stats )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/theme-stats.sh"
            analytics::theme_stats "$@"
            ;;
        *) echo "ash analytics: unknown subcommand '$sub'" >&2; analytics::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analytics::main "$@"
fi

ash_cmd_analytics() {
    analytics::main "$@"
}

ash_cmd_stats() {
    analytics::main "$@"
}
