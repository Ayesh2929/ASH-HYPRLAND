#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Snapshot Command Dispatcher                     ║
# ║                                                                              ║
# ║  USAGE:                                                                      ║
# ║    ash snapshot <subcommand> [options]                                       ║
# ║                                                                              ║
# ║  SUBCOMMANDS:                                                                ║
# ║    create   [name] [--tag TAG] [--desc DESC]   Create a new snapshot        ║
# ║    restore  <id>   [--dry-run] [--force]        Restore from snapshot       ║
# ║    list     [--json] [--pinned] [--tag TAG]     List all snapshots          ║
# ║    delete   <id>   [--force]                    Delete a snapshot           ║
# ║    diff     <id1> [id2]                         Diff two snapshots          ║
# ║    export   <id>   [--output PATH] [--encrypt]  Export snapshot archive     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'

# ── Source Libraries ───────────────────────────────────────────────────────────
_SNAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SNAP_DIR}/../../lib"

source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logger.sh"
source "${_LIB_DIR}/utils.sh"

# ── Bootstrap ──────────────────────────────────────────────────────────────────
utils::bootstrap_dirs
utils::require "tar" "jq"

# ── Help ───────────────────────────────────────────────────────────────────────
snapshot::help() {
    local w
    w=$(tput cols 2>/dev/null || echo 80)

    ash_banner \
        "${ICO_SNAPSHOT}  ASH SNAPSHOT SYSTEM" \
        "Atomic configuration snapshots with diff, export & restore" \
        "${w}"

    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash snapshot${RST} <subcommand> [options]

${BOLD}${ASH_PRIMARY}SUBCOMMANDS${RST}
  ${SNAP_COLOR_ID}create${RST}   [name] [options]    ${ASH_MUTED}Create a new configuration snapshot${RST}
  ${SNAP_COLOR_ID}restore${RST}  <id>   [options]    ${ASH_MUTED}Restore dotfiles from a snapshot${RST}
  ${SNAP_COLOR_ID}list${RST}     [options]            ${ASH_MUTED}Browse and filter all snapshots${RST}
  ${SNAP_COLOR_ID}delete${RST}   <id>   [options]    ${ASH_MUTED}Permanently remove a snapshot${RST}
  ${SNAP_COLOR_ID}diff${RST}     <id> [id2]          ${ASH_MUTED}Compare snapshots or vs current${RST}
  ${SNAP_COLOR_ID}export${RST}   <id>   [options]    ${ASH_MUTED}Export snapshot as portable archive${RST}

${BOLD}${ASH_PRIMARY}GLOBAL OPTIONS${RST}
  ${ASH_MUTED}--help, -h${RST}              Show this help message
  ${ASH_MUTED}--debug${RST}                 Enable debug output
  ${ASH_MUTED}--no-color${RST}              Disable colored output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${FG_BBLACK}# Create a named snapshot before major changes${RST}
  ${ASH_ACCENT}ash snapshot create${RST} "before-catppuccin" --tag stable

  ${FG_BBLACK}# List all pinned snapshots${RST}
  ${ASH_ACCENT}ash snapshot list${RST} --pinned

  ${FG_BBLACK}# Preview restore without applying changes${RST}
  ${ASH_ACCENT}ash snapshot restore${RST} snap-20241215-143022-a3f1 --dry-run

  ${FG_BBLACK}# Diff current config against a snapshot${RST}
  ${ASH_ACCENT}ash snapshot diff${RST} snap-20241215-143022-a3f1

  ${FG_BBLACK}# Export encrypted archive${RST}
  ${ASH_ACCENT}ash snapshot export${RST} snap-20241215-143022-a3f1 --encrypt

${BOLD}${ASH_PRIMARY}STORAGE${RST}
  ${ASH_MUTED}Snapshot directory: ${SNAP_COLOR_DATE}${ASH_SNAPSHOT_DIR}${RST}
  ${ASH_MUTED}Index file:         ${SNAP_COLOR_DATE}${ASH_SNAPSHOT_INDEX}${RST}

EOF
}

# ── Dispatcher ─────────────────────────────────────────────────────────────────
snapshot::main() {
    # Global flags
    while [[ "${1:-}" == --* ]]; do
        case "$1" in
            --debug)    ASH_LOG_LEVEL="DEBUG"; shift ;;
            --no-color) ASH_COLOR_SUPPORT=false; shift ;;
            --help|-h)  snapshot::help; return 0 ;;
            *)          break ;;
        esac
    done

    local subcmd="${1:-help}"
    shift || true

    case "${subcmd}" in
        create)   source "${_SNAP_DIR}/create.sh";  snapshot::create  "$@" ;;
        restore)  source "${_SNAP_DIR}/restore.sh"; snapshot::restore "$@" ;;
        list|ls)  source "${_SNAP_DIR}/list.sh";    snapshot::list    "$@" ;;
        delete|rm) source "${_SNAP_DIR}/delete.sh"; snapshot::delete  "$@" ;;
        diff)     source "${_SNAP_DIR}/diff.sh";    snapshot::diff    "$@" ;;
        export)   source "${_SNAP_DIR}/export.sh";  snapshot::export  "$@" ;;
        help|--help|-h) snapshot::help ;;
        *)
            log::error "Unknown subcommand: '${subcmd}'"
            log::info  "Run 'ash snapshot --help' for usage"
            return 1
            ;;
    esac
}

# Executing this file directly still works; sourcing it — which is how the
# dispatcher loads it — must only define the entry point. The unconditional
# `snapshot::main "$@"` that used to sit here ran the entire command at source time.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    snapshot::main "$@"
fi

# ── Dispatcher entry point ────────────────────────────────────────────────────
# The ash dispatcher sources this file and calls ash_cmd_<category>. Without
# this function the command reported "Command function not found" after already
# having run itself once at source time.
ash_cmd_snapshot() {
    snapshot::main "$@"
}
