# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — thefuck Ultra Configuration                        ║
# ║  Magnificent command corrector with instant mode, rules & ASH integration  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require thefuck ────────────────────────────────────────────────────
command -q thefuck || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_thefuck_loaded && exit 0
set --global _ash_thefuck_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_tf_log        "$HOME/.local/share/ash/logs/thefuck.log"
set --global _ash_tf_cache      "$HOME/.local/share/ash/cache/thefuck"
set --global _ash_tf_settings   "$HOME/.config/thefuck/settings.py"
set --global _ash_tf_rules_dir  "$HOME/.config/thefuck/rules"
set --global _ash_tf_stats      "$HOME/.local/share/ash/state/thefuck-stats.json"

mkdir -p (dirname $_ash_tf_log) 2>/dev/null
mkdir -p $_ash_tf_cache         2>/dev/null
mkdir -p $_ash_tf_rules_dir     2>/dev/null
mkdir -p (dirname $_ash_tf_stats) 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _tf_reset   (set_color normal)
set -g _tf_bold    (set_color --bold)
set -g _tf_cyan    (set_color cyan)
set -g _tf_green   (set_color green)
set -g _tf_yellow  (set_color yellow)
set -g _tf_red     (set_color red)
set -g _tf_blue    (set_color blue)
set -g _tf_purple  (set_color magenta)
set -g _tf_dim     (set_color brblack)
set -g _tf_orange  (set_color FF6B35)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  THEFUCK SETTINGS GENERATION                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_tf_write_settings --description "Generate optimized thefuck settings.py"
    test -f $_ash_tf_settings && return 0

    mkdir -p (dirname $_ash_tf_settings) 2>/dev/null

    echo "# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  thefuck settings — ASH DOTFILES v5.0                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

from thefuck.const import DEFAULT_PRIORITY

# ── Performance ───────────────────────────────────────────────────────────────
# Instant mode: watch commands as they run (fastest response)
instant_mode            = True

# Require confirmation before running fix (safer)
require_confirmation    = False

# Timeout for rule evaluation (seconds)
rules_timeout           = 2

# Wait this many seconds before showing fix
wait_command            = 0

# Cache fixes for repeated mistakes
# True = cache, False = always re-evaluate
use_cache               = True

# ── Rules Configuration ───────────────────────────────────────────────────────
# Explicitly enable only the rules you want (faster than enable_all)
rules = [
    # Shell & navigation
    'cd_mkdir',          # cd to non-existent dir → mkdir + cd
    'cd_parent',         # cd.. (no space) → cd ..

    # Git rules (most common)
    'git_add',           # forgot to git add
    'git_add_force',     # git add with --force needed
    'git_branch_0flag',  # branch flag typos
    'git_branch_delete', # wrong branch delete syntax
    'git_branch_exists', # branch already exists
    'git_checkout',      # branch name typos
    'git_commit_amend',  # forgot --amend
    'git_diff_no_index', # diff for untracked files
    'git_fix_stash',     # stash command mistakes
    'git_flag_after_filename',
    'git_not_command',   # git typos (git statis → git status)
    'git_pull',          # pull without remote
    'git_pull_clone',    # pull on empty dir
    'git_push',          # push without remote
    'git_push_pull',     # need to pull before push
    'git_push_without_commits',
    'git_rebase_no_changes',
    'git_rm_local_modifications',
    'git_rm_recursive',
    'git_remote_seturl_add',
    'git_stash',         # stash pop failures
    'git_tag',           # tag annotation missing
    'git_two_dashes',    # single vs double dash
    'git_merge',

    # Package managers
    'npm_missing_script',
    'npm_wrong_command',
    'pip_unknown_command',
    'python_command',    # python → python3

    # Docker
    'docker_login',
    'docker_not_command',

    # System commands
    'chmod_x',           # forgot to chmod +x before running
    'cp_omitting_directory',
    'dry',               # repeated command (dry run artifacts)
    'fix_alt_space',     # Alt+Space vs regular space
    'fix_file',          # file not found fixes
    'has_exists_script', # ./script.sh exists, needs chmod
    'lsof',              # port in use errors
    'man_no_space',      # man command typos
    'mkdir_p',           # mkdir without -p
    'mv_no_dest',        # mv missing destination
    'no_such_file',      # file path fixes
    'open',              # xdg-open typos
    'python_module_error',
    'quotation_marks',   # mismatched quotes
    'rm_dir',            # rm on directory without -r
    'sl_ls',             # sl → ls typo
    'ssh_known_hosts',   # host key verification
    'sudo',              # forgot sudo
    'sudo_command_from_user_path',
    'systemctl',         # systemctl typos
    'tar',               # tar extraction/compression flags
    'touch',             # touch with dirs
    'tsuru_login',
    'vagrant_up',
]

# ── Excluded rules (too aggressive or slow) ───────────────────────────────────
exclude_rules = [
    'no_such_file',      # can be too aggressive
]

# ── Environment ───────────────────────────────────────────────────────────────
# Shell for running corrections
shells_logger   = None
priority        = {}

# ── Aliases ───────────────────────────────────────────────────────────────────
# Commands to avoid correcting
# history_limit = 2000" > $_ash_tf_settings

    echo "["(date '+%H:%M:%S')"] settings created" >> $_ash_tf_log 2>/dev/null
end

# Generate settings if missing
__ash_tf_write_settings

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION — Instant mode optimized                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize thefuck alias with instant mode
thefuck --alias fuck 2>/dev/null | source

# Also create common alias shortcuts
thefuck --alias fix  2>/dev/null | source
thefuck --alias f    2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  KEY BINDINGS — Double-Escape to invoke thefuck                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Double-Escape: Instant correction ────────────────────────────────────────
function __ash_tf_bind_escape --description "Run thefuck on double-escape"
    set -l prev_cmd (history | head -1)
    if test -n "$prev_cmd"
        echo ""
        echo $_tf_orange"  🤬 → fixing: $prev_cmd"$_tf_reset
        fuck
    end
end

# Double-Escape binding
function fish_user_key_bindings_thefuck
    bind --silent \e\e __ash_tf_bind_escape 2>/dev/null
end

# ── Alt-F: Instant fix binding ────────────────────────────────────────────────
bind --silent \ef 'fuck' 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 STATISTICS: Track correction history                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_tf_track --on-event ash_command_corrected \
    --description "Track thefuck correction statistics"
    set -l original  $argv[1]
    set -l corrected $argv[2]

    echo "["(date '+%H:%M:%S')"] $original → $corrected" >> $_ash_tf_log 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── tf-info: Show thefuck system info ────────────────────────────────────────
function tf-info --description "Show thefuck configuration and statistics"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l orange (set_color FF6B35)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     🤬  thefuck Dashboard                            ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:     "$reset $dim(thefuck --version 2>/dev/null)$reset
    echo "  "$bold"Settings:    "$reset $dim$_ash_tf_settings$reset
    echo "  "$bold"Rules dir:   "$reset $dim$_ash_tf_rules_dir$reset
    echo "  "$bold"Instant mode:"$reset $green"enabled"$reset
    echo ""

    # Count enabled rules
    set -l rule_count (thefuck --list-rules 2>/dev/null | wc -l | string trim)
    echo "  "$bold"Active rules: "$reset $cyan$rule_count$reset

    # Corrections from log
    if test -f $_ash_tf_log
        set -l correction_count (wc -l < $_ash_tf_log | string trim)
        echo "  "$bold"Corrections:  "$reset $cyan$correction_count" total"$reset
    end

    echo ""

    # Custom rules
    if test -d $_ash_tf_rules_dir
        set -l custom (count $_ash_tf_rules_dir/*.py 2>/dev/null)
        test $custom -gt 0 && \
            echo "  "$bold"Custom rules: "$reset $cyan$custom$reset
    end
    echo ""
end

# ─── tf-rules: List all available rules ───────────────────────────────────────
function tf-rules --description "List all available thefuck rules"
    set -l filter $argv[1]

    echo ""
    echo $_tf_bold$_tf_cyan"  📋 thefuck Rules"$_tf_reset
    echo ""

    thefuck --list-rules 2>/dev/null | \
        if test -n "$filter"
            grep -i $filter
        else
            cat
        end | \
        while read -l rule
            echo "  "$_tf_dim"• "$_tf_reset$rule
        end
    echo ""
end

# ─── tf-logs: Show correction history ─────────────────────────────────────────
function tf-logs --description "Show thefuck correction history"
    set -l n $argv[1]
    test -z "$n" && set n 30

    if not test -f $_ash_tf_log
        echo $_tf_dim"  No corrections logged yet"$_tf_reset
        return
    end

    echo ""
    echo $_tf_bold$_tf_orange"  📜 Recent Corrections (last $n)"$_tf_reset
    echo ""

    tail -$n $_ash_tf_log | while read -l line
        echo "  "$_tf_dim$line$_tf_reset
    end
    echo ""
end

# ─── tf-new-rule: Scaffold a custom rule ──────────────────────────────────────
function tf-new-rule --description "Scaffold a new custom thefuck rule"
    set -l name $argv[1]

    if test -z "$name"
        read -P "  Rule name (e.g. my_fix): " name
    end
    test -z "$name" && return 1

    set -l rule_file "$_ash_tf_rules_dir/$name.py"

    if test -f $rule_file
        echo $_tf_yellow"  ⚠  Rule already exists: $rule_file"$_tf_reset
        return 1
    end

    cat > $rule_file << PYEOF
# ── thefuck custom rule: $name ─────────────────────────────────────────────
# Generated by ASH DOTFILES v5.0 — (date '+%Y-%m-%d')

from thefuck.shells.fish import Fish


def match(command):
    \"""Return True if this rule should handle the command.\"""
    # Example: return 'permission denied' in command.stderr.lower()
    return False


def get_new_command(command):
    \"""Return the corrected command string.\"""
    # Example: return 'sudo ' + command.script
    return command.script


# Optional: only run on specific commands
# enabled_by_default = True
# priority = DEFAULT_PRIORITY
# requires_output   = True   # Set True if match() needs stderr/stdout
PYEOF

    echo $_tf_green"  ✓ Rule created: $rule_file"$_tf_reset
    echo ""

    # Open in editor
    set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)
    read -P "  Open in $editor? [Y/n] " open_now
    string match -qi 'n*' $open_now || $editor $rule_file
end

# ─── tf-test-rule: Test a rule against a command ──────────────────────────────
function tf-test-rule --description "Test thefuck rule against a command"
    set -l rule $argv[1]
    set -l cmd  $argv[2]

    if test -z "$rule" || test -z "$cmd"
        echo "  Usage: tf-test-rule <rule-name> <command>"
        return 1
    end

    echo ""
    echo $_tf_cyan"  🧪 Testing rule '$rule' against: $cmd"$_tf_reset
    echo ""

    thefuck --rule $rule "$cmd" 2>/dev/null
    or echo $_tf_yellow"  Rule did not match"$_tf_reset
    echo ""
end

# ─── tf-fix-interactive: Interactive correction picker ────────────────────────
function tf-fix-interactive --description "Interactive thefuck correction with fzf"
    set -l prev_cmd (history | head -1)

    if test -z "$prev_cmd"
        echo $_tf_dim"  No previous command found"$_tf_reset
        return
    end

    echo ""
    echo $_tf_orange"  🤬 Previous: $prev_cmd"$_tf_reset
    echo ""

    if command -q fzf
        # Get all possible corrections
        set -l corrections (thefuck "$prev_cmd" --no-confirm 2>/dev/null | head -20)

        if test -z "$corrections"
            echo $_tf_dim"  No corrections available"$_tf_reset
            return
        end

        set -l selected (
            echo $corrections | tr ' ' '\n' |
            fzf --ansi \
                --border-label "  🤬 Pick Correction " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
                --header "  Original: $prev_cmd  " \
                --header-first \
                --no-multi
        )

        test -n "$selected" && eval $selected
    else
        fuck
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add tf      'fuck'
abbr --add tff     'tf-fix-interactive'
abbr --add tfinfo  'tf-info'
abbr --add tfrules 'tf-rules'
abbr --add tflogs  'tf-logs'
abbr --add tfnew   'tf-new-rule'
abbr --add tftest  'tf-test-rule'
abbr --add tfedit  "nvim $_ash_tf_settings"