# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Atuin Ultra Configuration                          ║
# ║  Magical shell history with sync, analytics, fuzzy search & ASH theming   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require atuin ──────────────────────────────────────────────────────
command -q atuin || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_atuin_loaded && exit 0
set --global _ash_atuin_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_atuin_config_dir  "$HOME/.config/atuin"
set --global _ash_atuin_data_dir    "$HOME/.local/share/atuin"
set --global _ash_atuin_log         "$HOME/.local/share/ash/logs/atuin.log"
set --global _ash_atuin_cache       "$HOME/.local/share/ash/cache/atuin"
set --global _ash_atuin_config_file "$HOME/.config/atuin/config.toml"

mkdir -p $_ash_atuin_config_dir 2>/dev/null
mkdir -p $_ash_atuin_data_dir   2>/dev/null
mkdir -p (dirname $_ash_atuin_log) 2>/dev/null
mkdir -p $_ash_atuin_cache      2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _at_reset   (set_color normal)
set -g _at_bold    (set_color --bold)
set -g _at_cyan    (set_color cyan)
set -g _at_green   (set_color green)
set -g _at_yellow  (set_color yellow)
set -g _at_red     (set_color red)
set -g _at_purple  (set_color magenta)
set -g _at_blue    (set_color blue)
set -g _at_dim     (set_color brblack)
set -g _at_orange  (set_color FF9F43)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ATUIN CONFIGURATION GENERATION                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_atuin_write_config --description "Generate optimal atuin config.toml"
    test -f $_ash_atuin_config_file && return 0

    # Read ASH theme accent color for UI theming
    set -l accent (set -q ASH_THEME_ACCENT && echo $ASH_THEME_ACCENT || echo "#cba6f7")

    printf "%s\n" \
        '# ╔══════════════════════════════════════════════════════════════════════════════╗' \
        '# ║  Atuin Configuration — ASH DOTFILES v5.0                                   ║' \
        '# ╚══════════════════════════════════════════════════════════════════════════════╝' \
        '' \
        '# ── Core Settings ─────────────────────────────────────────────────────────────' \
        'db_path   = "~/.local/share/atuin/history.db"' \
        'key_path  = "~/.local/share/atuin/key"' \
        'session_path = "~/.local/share/atuin/session"' \
        '' \
        '# Store exit codes (0 = success, non-0 = failure)' \
        'history_filter = []' \
        '' \
        '# Dialect for date parsing' \
        'dialect = "uk"' \
        '' \
        '# Update checks' \
        'auto_sync  = true' \
        'update_check = false' \
        '' \
        '# ── Display Settings ──────────────────────────────────────────────────────────' \
        '[ui]' \
        '# Style options: "auto" | "full" | "compact"' \
        'style = "full"' \
        '' \
        '# Search mode: "prefix" | "fulltext" | "fuzzy" | "skim"' \
        'search_mode = "fuzzy"' \
        '' \
        '# Filter mode: "global" | "host" | "session" | "directory"' \
        'filter_mode = "global"' \
        '' \
        '# Filter mode when pressing Up key' \
        'filter_mode_shell_up_key_binding = "directory"' \
        '' \
        '# Show preview of selected command' \
        'show_preview = true' \
        '' \
        '# Show help text' \
        'show_help = true' \
        '' \
        '# Show tabs for filtering' \
        'show_tabs = true' \
        '' \
        '# Inline height (0 = fullscreen)' \
        'inline_height = 30' \
        '' \
        '# Invert display (history at bottom)' \
        'invert = false' \
        '' \
        '# Exit immediately on selection (no re-edit)' \
        'exit_mode = "return-query"' \
        '' \
        '# Maximum length of history preview' \
        'max_preview_height = 4' \
        '' \
        '# ── Sync Settings ─────────────────────────────────────────────────────────────' \
        '[sync]' \
        '# Sync frequency' \
        'sync_frequency = "10m"' \
        '' \
        '# Enable sync (set ATUIN_SYNC_ADDRESS for self-hosted)' \
        '# sync_address = "https://api.atuin.sh"' \
        '' \
        '# ── Stats Settings ────────────────────────────────────────────────────────────' \
        '[stats]' \
        '# Commands to ignore in stats' \
        'common_prefix = ["sudo", "time", "watch", "env"]' \
        'common_subcommands = ["git", "cargo", "npm", "pnpm", "yarn", "docker", "kubectl", "brew"]' \
        '' \
        '# ── Key Bindings ──────────────────────────────────────────────────────────────' \
        '[keys]' \
        '# Ctrl-R → full history search' \
        '# Up     → directory-scoped history' \
        '# These are set in shell integration below' > $_ash_atuin_config_file

    echo "[$_at_green"✓"$_at_reset] atuin config created: $_ash_atuin_config_file"
end

# Generate config if missing
__ash_atuin_write_config 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Initialize atuin shell integration
atuin init fish \
    --disable-up-arrow \
    2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  KEY BINDINGS — Ultra configured                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Ctrl-R: Full history search (global) ──────────────────────────────────────
function _atuin_search_global \
    --description "Atuin history search — global scope"
    atuin search \
        --filter-mode global \
        --search-mode fuzzy \
        --interactive \
        $argv
end

# ── Ctrl-H: Directory-scoped history ──────────────────────────────────────────
function _atuin_search_dir \
    --description "Atuin history search — current directory"
    set -l query (commandline)
    atuin search \
        --filter-mode directory \
        --search-mode fuzzy \
        --interactive \
        --query "$query" \
        $argv
end

# ── Ctrl-G: Session history ────────────────────────────────────────────────────
function _atuin_search_session \
    --description "Atuin history search — current session"
    atuin search \
        --filter-mode session \
        --search-mode fuzzy \
        --interactive \
        $argv
end

# ── Alt-H: Host history ────────────────────────────────────────────────────────
function _atuin_search_host \
    --description "Atuin history search — current host"
    atuin search \
        --filter-mode host \
        --search-mode fuzzy \
        --interactive \
        $argv
end

# Bind keys (Fish-style)
if bind --silent \cr _atuin_search_global 2>/dev/null
    bind --silent --mode insert \cr _atuin_search_global 2>/dev/null
end

# Directory history
bind --silent \ch _atuin_search_dir 2>/dev/null
bind --silent --mode insert \ch _atuin_search_dir 2>/dev/null

# Session history
bind --silent \cg _atuin_search_session 2>/dev/null
bind --silent --mode insert \cg _atuin_search_session 2>/dev/null

# Host history
bind --silent \eh _atuin_search_host 2>/dev/null

# ── Up arrow: Directory-context history (ergonomic) ───────────────────────────
# Uncomment to enable up-arrow atuin (conflicts with fish default):
# bind --silent \e\[A _atuin_search_dir 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME INTEGRATION: Sync atuin colors with ASH theme                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_atuin_sync_theme --description "Sync atuin UI colors with ASH theme"
    set -l state_file "$HOME/.local/share/ash/state/current-theme.json"
    test -f $state_file || return

    command -q jq || return

    set -l bg      (jq -r '.colors.base    // "#1e1e2e"' $state_file 2>/dev/null)
    set -l fg      (jq -r '.colors.text    // "#cdd6f4"' $state_file 2>/dev/null)
    set -l accent  (jq -r '.colors.mauve   // "#cba6f7"' $state_file 2>/dev/null)
    set -l green   (jq -r '.colors.green   // "#a6e3a1"' $state_file 2>/dev/null)
    set -l red     (jq -r '.colors.red     // "#f38ba8"' $state_file 2>/dev/null)
    set -l yellow  (jq -r '.colors.yellow  // "#f9e2af"' $state_file 2>/dev/null)
    set -l surface (jq -r '.colors.surface0 // "#313244"' $state_file 2>/dev/null)

    # Write theme-aware atuin config section
    set -l theme_section "\n[ui]\nbg_color       = \"$bg\"\nfg_color       = \"$fg\"\nselection_bg   = \"$surface\"\nselection_fg   = \"$fg\"\npreview_bg     = \"$bg\"\npreview_fg     = \"$fg\"\nborder_color   = \"$accent\"\nquery_color    = \"$fg\"\nhighlight_color = \"$accent\"\n"

    echo $theme_section >> $_ash_atuin_config_file 2>/dev/null
end

# ─── Hook: Refresh on ASH theme change ───────────────────────────────────────
function __ash_atuin_on_theme_change --on-event ash_theme_changed \
    --description "Refresh atuin theme on ASH theme change"
    __ash_atuin_sync_theme
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 STATISTICS & ANALYTICS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── atuin-stats-rich: Rich statistics dashboard ─────────────────────────────
function atuin-stats-rich --description "Show rich Atuin history statistics"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l blue   (set_color blue)
    set -l purple (set_color magenta)
    set -l orange (set_color FF9F43)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     📊  Atuin History Analytics                      ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    # Total count
    set -l total (atuin history list --count 2>/dev/null)
    echo "  "$bold"Total commands:    "$reset $cyan$total$reset
    echo ""

    # Top commands
    echo "  "$bold"🏆 Top Commands:"$reset
    echo "  "$dim"──────────────────────────────────────────────────"$reset
    atuin stats 2>/dev/null | head -15 | while read -l line
        echo "  "$dim$line$reset
    end
    echo ""

    # Failure rate
    set -l failures (atuin history list --format "{exit}" 2>/dev/null | grep -c '^[^0]' 2>/dev/null)
    if test -n "$failures" && test -n "$total" && test "$total" -gt 0
        set -l failure_rate (math --scale 1 "$failures * 100 / $total")
        echo "  "$bold"Exit 0:   "$reset $green(math $total - $failures)" commands"$reset
        echo "  "$bold"Non-zero: "$reset $yellow$failures" commands ($failure_rate%)"$reset
        echo ""
    end

    # Database info
    set -l db_size (du -sh "$_ash_atuin_data_dir/history.db" 2>/dev/null | awk '{print $1}')
    echo "  "$bold"Database: "$reset $dim$db_size$reset" — $_ash_atuin_data_dir/history.db"
    echo ""
end

# ─── atuin-top: Show top N commands ───────────────────────────────────────────
function atuin-top --description "Show top N most-used commands"
    set -l n $argv[1]
    test -z "$n" && set n 20

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  🏆 Top $n Commands"$reset
    echo ""
    printf "  $bold%-6s  %-12s  %s$reset\n" "Count" "Exit" "Command"
    printf "  $dim%s$reset\n" "──────────────────────────────────────────────────"

    atuin history list \
        --format "{time}\t{exit}\t{command}" 2>/dev/null | \
        awk -F'\t' '{cmd=$3; gsub(/^ +| +$/, "", cmd); cmds[cmd]++; exits[cmd]+=$2} END {
            for (c in cmds) printf "%d\t%d\t%s\n", cmds[c], exits[c], c
        }' | sort -rn | head -$n | \
        while read -l count exits cmd
            set -l exit_color $dim
            test "$exits" = 0 && set exit_color $green
            test "$exits" -gt 0 2>/dev/null && set exit_color $_at_yellow
            printf "  $cyan%-6s$reset  $exit_color%-12s$reset  %s\n" $count "exit:$exits" $cmd
        end
    echo ""
end

# ─── atuin-failures: Show failed commands ─────────────────────────────────────
function atuin-failures --description "Show recently failed commands"
    set -l n $argv[1]
    test -z "$n" && set n 20

    echo ""
    echo $_at_bold$_at_red"  ✗ Recent Failed Commands (exit ≠ 0)"$_at_reset
    echo ""
    printf "  $_at_bold%-20s  %-6s  %s$_at_reset\n" "Time" "Exit" "Command"
    printf "  $_at_dim%s$_at_reset\n" "──────────────────────────────────────────────────"

    atuin history list \
        --format "{time}\t{exit}\t{command}" 2>/dev/null | \
        awk -F'\t' '$2 != "0" {print}' | \
        tail -$n | \
        while read -l time exit_code cmd
            printf "  $_at_dim%-20s$_at_reset  $_at_red%-6s$_at_reset  %s\n" \
                $time $exit_code $cmd
        end
    echo ""
end

# ─── atuin-timeline: Commands by hour of day ──────────────────────────────────
function atuin-timeline --description "Show command activity timeline by hour"
    echo ""
    echo $_at_bold$_at_cyan"  🕐 Activity Timeline (commands per hour)"$_at_reset
    echo ""

    atuin history list --format "{time}" 2>/dev/null | \
        grep -oE '[0-9]{2}:[0-9]{2}' | \
        cut -d: -f1 | \
        sort | uniq -c | \
        while read -l count hour
            set -l bar_len (math --scale 0 "$count / 10")
            test $bar_len -lt 1 && set bar_len 1
            set -l bar (string repeat -n $bar_len "█")
            printf "  $_at_cyan%s:00$_at_reset  $_at_green%-30s$_at_reset  $_at_dim%s$_at_reset\n" \
                $hour $bar $count
        end
    echo ""
end

# ─── atuin-search-smart: Enhanced search with filters ─────────────────────────
function atuin-search-smart --description "Smart atuin search with extra filters"
    set -l query   $argv[1]
    set -l filter  $argv[2]   # global | host | session | directory
    set -l mode    $argv[3]   # fuzzy | prefix | fulltext

    test -z "$filter" && set filter global
    test -z "$mode"   && set mode   fuzzy

    if test -z "$query"
        read -P "  Search query: " query
    end

    atuin search \
        --filter-mode $filter \
        --search-mode $mode \
        --query "$query" \
        --interactive
end

# ─── atuin-export: Export history to various formats ──────────────────────────
function atuin-export --description "Export Atuin history to file"
    set -l format $argv[1]
    set -l output $argv[2]

    test -z "$format" && set format tsv
    test -z "$output" && set output "atuin-history-"(date +%Y%m%d)

    echo ""
    echo $_at_cyan"  📤 Exporting history ($format)..."$_at_reset

    switch $format
        case tsv
            atuin history list \
                --format "{time}\t{exit}\t{duration}\t{host}\t{command}" \
                2>/dev/null > "$output.tsv"
            echo $_at_green"  ✓ Exported: $output.tsv"$_at_reset

        case json
            atuin history list \
                --format '{"time":"{time}","exit":{exit},"duration":{duration},"host":"{host}","command":"{command}"}' \
                2>/dev/null | jq -s . > "$output.json" 2>/dev/null \
            or atuin history list \
                --format '{"time":"{time}","exit":{exit},"command":"{command}"}' \
                2>/dev/null > "$output.jsonl"
            echo $_at_green"  ✓ Exported: $output.json"$_at_reset

        case plain txt
            atuin history list --format "{command}" 2>/dev/null > "$output.txt"
            echo $_at_green"  ✓ Exported: $output.txt"$_at_reset

        case zsh-compat bash-compat
            # Compatible with zsh/bash HISTFILE
            atuin history list --format ": $(date +%s):0;{command}" \
                2>/dev/null > "$output.hist"
            echo $_at_green"  ✓ Exported (zsh/bash compat): $output.hist"$_at_reset

        case '*'
            echo "  Usage: atuin-export [tsv|json|plain|zsh-compat] [output-file]"
            return 1
    end
    echo ""
end

# ─── atuin-import: Import history from shell files ────────────────────────────
function atuin-import --description "Import shell history into Atuin"
    set -l source $argv[1]
    test -z "$source" && set source auto

    echo ""
    echo $_at_cyan"  📥 Importing history from: $source"$_at_reset
    echo ""

    switch $source
        case auto
            atuin import auto
        case bash
            atuin import bash
        case zsh
            atuin import zsh
        case fish
            atuin import fish
        case '*'
            # Import from a specific file
            if test -f $source
                atuin import bash --file $source 2>/dev/null \
                    or atuin import zsh --file $source
            else
                echo $_at_red"  ✗ Unknown source: $source"$_at_reset
                return 1
            end
    end

    and begin
        echo ""
        echo $_at_green"  ✓ History imported"$_at_reset
        echo "  Total: "(atuin history list --count 2>/dev/null)" commands"
        echo ""
    end
end

# ─── atuin-sync-status: Show sync status ──────────────────────────────────────
function atuin-sync-status --description "Show Atuin sync status"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ☁  Atuin Sync Status"$reset
    echo ""

    # Check if logged in
    if atuin account info 2>/dev/null | grep -q "Username"
        set -l username (atuin account info 2>/dev/null | grep "Username" | awk '{print $2}')
        echo "  "$bold"Account:  "$reset $green$username$reset
        echo "  "$bold"Status:   "$reset $green"logged in"$reset

        # Last sync
        set -l last_sync (atuin sync --status 2>/dev/null | head -1)
        test -n "$last_sync" && echo "  "$bold"Last sync:"$reset $dim$last_sync$reset
    else
        echo "  "$yellow"Not logged in (cloud sync disabled)"$reset
        echo "  Run: atuin login"
    end

    echo ""
    echo "  "$bold"Local DB: "$reset $dim$_ash_atuin_data_dir/history.db$reset
    set -l count (atuin history list --count 2>/dev/null)
    echo "  "$bold"Records:  "$reset $cyan$count$reset
    echo ""
end

# ─── atuin-clean: Clean old history entries ────────────────────────────────────
function atuin-clean --description "Clean Atuin history entries"
    set -l action $argv[1]

    switch $action
        case duplicates
            echo $_at_yellow"  Removing duplicate commands..."$_at_reset
            # Keep only unique command+exit combinations
            echo $_at_dim"  Note: Use 'atuin search' for manual cleanup"$_at_reset

        case failures
            echo ""
            echo $_at_yellow"  ⚠ This will remove all failed command history"$_at_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            # atuin doesn't have direct delete by filter yet, show count
            set -l fail_count (atuin history list --format "{exit}" 2>/dev/null | \
                grep -c '^[^0]' 2>/dev/null)
            echo "  Failed commands: $fail_count (manual cleanup required)"

        case optimize
            echo $_at_cyan"  🔧 Optimizing Atuin database..."$_at_reset
            # SQLite vacuum via sqlite3 if available
            if command -q sqlite3
                set -l db "$_ash_atuin_data_dir/history.db"
                set -l before (du -sh $db | awk '{print $1}')
                sqlite3 $db "VACUUM;" 2>/dev/null
                set -l after (du -sh $db | awk '{print $1}')
                echo $_at_green"  ✓ Optimized: $before → $after"$_at_reset
            else
                echo $_at_dim"  (sqlite3 not available for VACUUM)"$_at_reset
            end

        case '*'
            echo "  Usage: atuin-clean [duplicates|failures|optimize]"
    end
end

# ─── atuin-search-fzf: Hybrid atuin+fzf search ────────────────────────────────
function atuin-search-fzf --description "Hybrid Atuin history search via fzf"
    command -q fzf || begin
        atuin search --interactive
        return
    end

    set -l selected (
        atuin history list \
            --format "{time}  [{exit}]  {command}" \
            --reverse 2>/dev/null |
        fzf --ansi \
            --no-sort \
            --border-label "  📜 Atuin History " \
            --border rounded \
            --prompt "  🔍 " \
            --pointer "▶" \
            --marker "✓" \
            --preview 'echo {}' \
            --preview-window 'down:2:wrap:border-rounded' \
            --bind 'ctrl-y:execute-silent(echo -n {3..} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)+abort' \
            --header '  Enter:execute  Ctrl-Y:copy  Ctrl-/:preview  ' \
            --height '70%' \
        | awk '{print $3}'
    )

    if test -n "$selected"
        commandline -r $selected
    end
end

# ─── atuin-alias: Show commands that could be aliases ─────────────────────────
function atuin-alias-suggest --description "Suggest shell aliases from frequent commands"
    set -l n $argv[1]
    test -z "$n" && set n 20

    echo ""
    echo $_at_bold$_at_cyan"  💡 Alias Suggestions (from top $n commands)"$_at_reset
    echo ""
    echo "  "$_at_dim"Commands you run most — consider aliasing them:"$_at_reset
    echo ""

    atuin history list \
        --format "{command}" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -$n | \
        grep -v '^.*\(cd\|ls\|git\|cat\|echo\)' | \
        while read -l count cmd
            # Only suggest multi-word commands
            set -l words (count (string split ' ' $cmd))
            if test $words -gt 2 && test $count -gt 10
                set -l alias_name (string split ' ' $cmd)[1](string split ' ' $cmd)[2] | string lower | string replace -a '-' ''
                printf "  abbr --add $_at_cyan%-20s$_at_reset '%s'  $_at_dim# used %s times$_at_reset\n" \
                    (string sub --length 15 $alias_name) $cmd $count
            end
        end
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔔 PROMPT INTEGRATION: Show last exit code & duration                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── on-post-exec: Track command timing ───────────────────────────────────────
function __ash_atuin_preexec --on-event fish_preexec \
    --description "Track command execution start time"
    set --global _ash_atuin_cmd_start (date +%s%N 2>/dev/null; or date +%s)
end

function __ash_atuin_postcmd --on-event fish_postexec \
    --description "Log timing for custom analytics"
    set -l exit_code $status
    set -l cmd $argv[1]

    if set -q _ash_atuin_cmd_start
        set -l now (date +%s%N 2>/dev/null; or date +%s)
        set -l duration (math --scale 0 "($now - $_ash_atuin_cmd_start) / 1000000")
        set --erase _ash_atuin_cmd_start

        # Log slow commands (> 5 seconds)
        if test $duration -gt 5000
            echo "["(date '+%H:%M:%S')"] slow($duration"ms") exit=$exit_code: $cmd" \
                >> $_ash_atuin_log 2>/dev/null
        end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core
abbr --add at      'atuin'
abbr --add ath     'atuin history'
abbr --add athl    'atuin history list'
abbr --add athc    'atuin history list --count'
abbr --add ats     'atuin search --interactive'
abbr --add atsg    'atuin search --filter-mode global --interactive'
abbr --add atsd    'atuin search --filter-mode directory --interactive'
abbr --add atss    'atuin search --filter-mode session --interactive'
abbr --add atsh    'atuin search --filter-mode host --interactive'

# Stats & Analytics
abbr --add atstat  'atuin-stats-rich'
abbr --add attop   'atuin-top'
abbr --add atfail  'atuin-failures'
abbr --add attime  'atuin-timeline'
abbr --add atalias 'atuin-alias-suggest'

# Management
abbr --add atexp   'atuin-export'
abbr --add atimp   'atuin-import'
abbr --add atsync  'atuin sync'
abbr --add atsyncst 'atuin-sync-status'
abbr --add atclean 'atuin-clean optimize'
abbr --add atcfg   "nvim $_ash_atuin_config_file"
abbr --add atfzf   'atuin-search-fzf'
abbr --add atsmart 'atuin-search-smart'

# Account
abbr --add atlogin  'atuin login'
abbr --add atlogout 'atuin logout'
abbr --add atinfo   'atuin account info'
abbr --add atregist 'atuin register'