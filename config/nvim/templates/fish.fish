#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🐠 FUNCTION/SCRIPT NAME — ASH DOTFILES v5.0 OMEGA                             ║
# ║  Description  : Brief description of what this function does                   ║
# ║  Author       : ash                                                             ║
# ║  Created      : 2024-01-01                                                      ║
# ║  Usage        : function_name [OPTIONS] <arguments>                            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# DESCRIPTION:
#   Longer description of the function's purpose and how it integrates
#   with the ASH dotfiles ecosystem.
#
# OPTIONS:
#   -h / --help      Print this help message
#   -v / --verbose   Enable verbose output
#   -n / --dry-run   Show what would happen without doing it
#
# EXAMPLES:
#   function_name --verbose input
#   function_name --dry-run output

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 COLOURS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -l COL_RED   (set_color red)
set -l COL_GRN   (set_color green)
set -l COL_YLW   (set_color yellow)
set -l COL_BLU   (set_color blue)
set -l COL_MAG   (set_color magenta)
set -l COL_CYN   (set_color cyan)
set -l COL_BLD   (set_color --bold)
set -l COL_DIM   (set_color --dim)
set -l COL_RST   (set_color normal)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📢 LOGGING HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function _log_info
    echo "$COL_BLU[INFO]$COL_RST  $argv" >&2
end

function _log_ok
    echo "$COL_GRN[ OK ]$COL_RST  $argv" >&2
end

function _log_warn
    echo "$COL_YLW[WARN]$COL_RST  $argv" >&2
end

function _log_error
    echo "$COL_RED[ERR ]$COL_RST  $argv" >&2
end

function _log_debug
    if set -q _flag_verbose
        echo "$COL_DIM[DBG ]  $argv$COL_RST" >&2
    end
end

function _log_step
    echo "$COL_MAG$COL_BLD  ➜  $COL_RST$argv" >&2
end

function _log_die
    _log_error $argv
    return 1
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check required commands are available
function _require
    for cmd in $argv
        if not command -q $cmd
            _log_die "Required command not found: $cmd"
        end
    end
    _log_debug "Dependencies satisfied: $argv"
end

# Run a command (honouring --dry-run)
function _run
    if set -q _flag_dry_run
        _log_info "[DRY-RUN] $argv"
        return 0
    end
    _log_debug "Running: $argv"
    $argv
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📖 HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function _usage
    echo "
$COL_BLD(status current-command)$COL_RST — Description

$COL_BLD"USAGE:$COL_RST
  (status current-command) [OPTIONS] <input>

$COL_BLD"OPTIONS:$COL_RST
  $COL_GRN-h / --help$COL_RST         Print this help
  $COL_GRN-v / --verbose$COL_RST      Verbose output
  $COL_GRN-n / --dry-run$COL_RST      Dry-run mode
  $COL_GRN-o / --output$COL_RST FILE  Output file

$COL_BLD"EXAMPLES:$COL_RST
  (status current-command) --verbose input.txt
  (status current-command) --dry-run --output result.txt input.txt
"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 MAIN FUNCTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function function_name
    # ── Argument parsing ──────────────────────────────────────────────────────────
    argparse \
        'h/help' \
        'v/verbose' \
        'n/dry-run' \
        'o/output=' \
        -- $argv
    or return 1

    if set -q _flag_help
        _usage
        return 0
    end

    # ── Validate positional arguments ─────────────────────────────────────────────
    if test (count $argv) -lt 1
        _log_die "Missing required argument: <input>  (use --help)"
    end

    set -l input_file $argv[1]

    if not test -f $input_file
        _log_die "Input file not found: $input_file"
    end

    # ── Check dependencies ────────────────────────────────────────────────────────
    _require cat grep sed

    # ── Core logic ────────────────────────────────────────────────────────────────
    _log_info "Starting function_name"

    if set -q _flag_dry_run
        _log_warn "DRY-RUN mode — no changes will be made"
    end

    _log_debug "Input:  $input_file"
    _log_debug "Output: $(set -q _flag_output; and echo $_flag_output; or echo stdout)"

    _log_step "Processing $input_file…"

    # Create temp file
    set -l tmpfile (mktemp)

    # Do work
    _run cat $input_file > $tmpfile

    # ── Output ────────────────────────────────────────────────────────────────────
    if set -q _flag_output
        _run cp -- $tmpfile $_flag_output
        _log_ok "Written to $_flag_output"
    else
        cat $tmpfile
    end

    rm -f $tmpfile
    _log_ok "Done."
    return 0
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔌 ENTRY POINT (when executed as a script, not sourced)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if status is-login; or status is-interactive
    # Sourced as a function — register for completion
else
    # Executed directly as a script
    function_name $argv
    exit $status
end