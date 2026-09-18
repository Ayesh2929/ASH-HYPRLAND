#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin command dispatcher                  ║
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

plugin::help() {
cat <<'ASH_EOF'
ash plugin — plugin management

Usage:
  ash plugin <subcommand> [options]

Subcommands:
  backup             backup
  browse             browse
  create             create
  disable            disable
  enable             enable
  info               info
  install            install
  list               list
  publish            publish
  remove             remove
  search             search
  update             update
  update-all         update-all
  validate           validate
  help               Show this help

Run 'ash plugin <subcommand> --help' for details.
ASH_EOF
}

plugin::main() {
    local sub="${1:-help}"
    case "$sub" in
        help|--help|-h) plugin::help; return 0 ;;
        backup )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/backup.sh"
            plugin::backup "$@"
            ;;
        browse )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/browse.sh"
            plugin::browse "$@"
            ;;
        create )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/create.sh"
            plugin::create "$@"
            ;;
        disable )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/disable.sh"
            plugin::disable "$@"
            ;;
        enable )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/enable.sh"
            plugin::enable "$@"
            ;;
        info )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/info.sh"
            plugin::info "$@"
            ;;
        install )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/install.sh"
            plugin::install "$@"
            ;;
        list )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/list.sh"
            plugin::list "$@"
            ;;
        publish )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/publish.sh"
            plugin::publish "$@"
            ;;
        remove )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/remove.sh"
            plugin::remove "$@"
            ;;
        search )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/search.sh"
            plugin::search "$@"
            ;;
        update )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/update.sh"
            plugin::update "$@"
            ;;
        update-all )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/update-all.sh"
            plugin::update_all "$@"
            ;;
        validate )
            shift
            # shellcheck source=/dev/null
            source "${CMD_DIR}/validate.sh"
            plugin::validate "$@"
            ;;
        *) echo "ash plugin: unknown subcommand '$sub'" >&2; plugin::help >&2; return 2 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::main "$@"
fi

ash_cmd_plugin() {
    plugin::main "$@"
}

ash_cmd_p() {
    plugin::main "$@"
}
