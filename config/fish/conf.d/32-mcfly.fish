# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — McFly Ultra Configuration                          ║
# ║  AI-powered shell history with neural network ranking & ASH theme sync     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require mcfly ──────────────────────────────────────────────────────
command -q mcfly || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_mcfly_loaded && exit 0
set --global _ash_mcfly_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_mcfly_log       "$HOME/.local/share/ash/logs/mcfly.log"
set --global _ash_mcfly_cache     "$HOME/.local/share/ash/cache/mcfly"
set --global _ash_mcfly_db        "$HOME/.local/share/mcfly/history.db"
set --global _ash_mcfly_state     "$HOME/.local/share/ash/state/mcfly.json"

mkdir -p (dirname $_ash_mcfly_log)  2>/dev/null
mkdir -p $_ash_mcfly_cache          2>/dev/null
mkdir -p (dirname $_ash_mcfly_db)   2>/dev/null
mkdir -p (dirname $_ash_mcfly_state) 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _mf_reset   (set_color normal)
set -g _mf_bold    (set_color --bold)
set -g _mf_cyan    (set_color cyan)
set -g _mf_green   (set_color green)
set -g _mf_yellow  (set_color yellow)
set -g _mf_red     (set_color red)
set -g _mf_blue    (set_color blue)
set -g _mf_purple  (set_color magenta)
set -g _mf_dim     (set_color brblack)
set -g _mf_orange  (set_color FF9F43)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  MCFLY ENVIRONMENT CONFIGURATION                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core database path ────────────────────────────────────────────────────────
set --export MCFLY_HISTFILE       "$HOME/.local/share/mcfly/history.db"

# ── AI/Neural network settings ────────────────────────────────────────────────
# Fuzzy matching: 0=exact 1=lenient 2=ultra-lenient
set --export MCFLY_FUZZY          2

# Number of results shown in search UI
set --export MCFLY_RESULTS        30

# Results sorting mode: "rank" (neural) | "last_run" | "cmd"
set --export MCFLY_RESULTS_SORT   "rank"

# ── Interface settings ────────────────────────────────────────────────────────
# Show full command without truncation
set --export MCFLY_SHOW_FULL_COMMAND 1

# Disable the McFly welcome prompt
set --export MCFLY_DISABLE_MENU   0

# Keyboard shortcuts
set --export MCFLY_KEY_SCHEME     "vim"   # vim | emacs

# ── Theme sync with ASH ───────────────────────────────────────────────────────
function __ash_mcfly_resolve_theme --description "Resolve McFly theme from ASH variant"
    set -l variant (set -q ASH_THEME_VARIANT && echo $ASH_THEME_VARIANT || echo dark)
    switch $variant
        case light
            echo "light"
        case '*'
            echo "dark"
    end
end

set --export MCFLY_LIGHT (test (__ash_mcfly_resolve_theme) = light && echo true || echo false)

# ── Privacy settings ──────────────────────────────────────────────────────────
# Delete failed commands automatically
set --export MCFLY_DELETE_WITHOUT_CONFIRM 0

# Commands to never record (patterns)
set --export MCFLY_HISTORY_LIMIT  10000

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

mcfly init fish 2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  KEY BINDINGS — Ultra configured                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Ctrl-R: McFly neural history search ───────────────────────────────────────
function _mcfly_search_enhanced --description "McFly search with enhanced context"
    set -l query (commandline 2>/dev/null)

    # Pass current directory context to McFly for better ranking
    set --local MCFLY_DIR $PWD

    mcfly search --query "$query" 2>/dev/null
end

# Override default Ctrl-R binding
bind --silent \cr _mcfly_search_enhanced 2>/dev/null
bind --silent --mode insert \cr _mcfly_search_enhanced 2>/dev/null

# ── Ctrl-Alt-R: McFly with global scope ───────────────────────────────────────
function _mcfly_search_global --description "McFly global search (ignore directory)"
    mcfly search 2>/dev/null
end

bind --silent \e\cr _mcfly_search_global 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME INTEGRATION                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_mcfly_on_theme_change --on-event ash_theme_changed \
    --description "Sync McFly theme with ASH theme changes"
    set -l new_theme (__ash_mcfly_resolve_theme)

    switch $new_theme
        case light
            set --export MCFLY_LIGHT true
        case '*'
            set --export MCFLY_LIGHT false
    end

    echo "["(date '+%H:%M:%S')"] theme synced: $new_theme" >> $_ash_mcfly_log 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 STATISTICS & ANALYTICS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function mcfly-info --description "Show McFly system information and statistics"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l orange (set_color FF9F43)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     🧠  McFly Neural History Dashboard               ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:       "$reset $dim(mcfly --version 2>/dev/null)$reset
    echo "  "$bold"Database:      "$reset $dim$MCFLY_HISTFILE$reset
    echo "  "$bold"Fuzzy level:   "$reset $cyan$MCFLY_FUZZY$reset" (0=exact, 2=ultra-lenient)"
    echo "  "$bold"Results shown: "$reset $cyan$MCFLY_RESULTS$reset
    echo "  "$bold"Sort mode:     "$reset $cyan$MCFLY_RESULTS_SORT$reset
    echo "  "$bold"Theme:         "$reset (__ash_mcfly_resolve_theme)
    echo "  "$bold"Key scheme:    "$reset $cyan$MCFLY_KEY_SCHEME$reset
    echo ""

    # Database stats via sqlite3
    if command -q sqlite3 && test -f $MCFLY_HISTFILE
        set -l total (sqlite3 $MCFLY_HISTFILE \
            "SELECT COUNT(*) FROM commands;" 2>/dev/null)
        set -l unique_cmds (sqlite3 $MCFLY_HISTFILE \
            "SELECT COUNT(DISTINCT cmd) FROM commands;" 2>/dev/null)
        set -l success_rate (sqlite3 $MCFLY_HISTFILE \
            "SELECT ROUND(100.0 * SUM(CASE WHEN exit_code=0 THEN 1 ELSE 0 END) / COUNT(*), 1) FROM commands;" 2>/dev/null)
        set -l db_size (du -sh $MCFLY_HISTFILE 2>/dev/null | awk '{print $1}')

        echo "  "$bold"Total commands:  "$reset $cyan$total$reset
        echo "  "$bold"Unique commands: "$reset $cyan$unique_cmds$reset
        echo "  "$bold"Success rate:    "$reset $green$success_rate"%"$reset
        echo "  "$bold"Database size:   "$reset $dim$db_size$reset
        echo ""
    end
end

# ─── mcfly-top: Show top commands by selection count ──────────────────────────
function mcfly-top --description "Show most selected McFly commands"
    set -l n $argv[1]
    test -z "$n" && set n 25

    command -q sqlite3 && test -f $MCFLY_HISTFILE || begin
        echo $_mf_red"  ✗ sqlite3 required or database not found"$_mf_reset
        return 1
    end

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  🏆 Top $n McFly Commands (by neural rank)"$reset
    echo ""
    printf "  $bold%-8s  %-8s  %s$reset\n" "Selected" "Run" "Command"
    printf "  $dim%s$reset\n" "──────────────────────────────────────────────────────"

    sqlite3 -separator "\t" $MCFLY_HISTFILE \
        "SELECT selected_count, run_count, cmd
         FROM commands
         WHERE cmd NOT LIKE 'mcfly%'
         ORDER BY selected_count DESC, run_count DESC
         LIMIT $n;" 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $cyan%-8s$reset  $dim%-8s$reset  %s\n" \
            $parts[1] $parts[2] $parts[3]
    end
    echo ""
end

# ─── mcfly-fails: Show commands with highest failure rate ─────────────────────
function mcfly-fails --description "Show commands with highest failure rates"
    set -l n $argv[1]
    test -z "$n" && set n 20

    command -q sqlite3 && test -f $MCFLY_HISTFILE || return 1

    echo ""
    echo $_mf_bold$_mf_red"  ✗ High-Failure Commands"$_mf_reset
    echo ""

    sqlite3 -separator $'\t' $MCFLY_HISTFILE \
        "SELECT
            cmd,
            COUNT(*) as total,
            SUM(CASE WHEN exit_code != 0 THEN 1 ELSE 0 END) as failures,
            ROUND(100.0 * SUM(CASE WHEN exit_code != 0 THEN 1 ELSE 0 END) / COUNT(*), 1) as fail_rate
         FROM commands
         WHERE run_count > 2
         GROUP BY cmd
         HAVING fail_rate > 20
         ORDER BY fail_rate DESC
         LIMIT $n;" 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_mf_red%-6s%%$_mf_reset  $_mf_dim%-6s runs$_mf_reset  %s\n" \
            $parts[4] $parts[2] $parts[1]
    end
    echo ""
end

# ─── mcfly-clean: Database maintenance ────────────────────────────────────────
function mcfly-clean --description "Clean and optimize McFly database"
    set -l action $argv[1]
    test -z "$action" && set action optimize

    switch $action
        case optimize vacuum
            command -q sqlite3 || begin
                echo $_mf_red"  ✗ sqlite3 required"$_mf_reset
                return 1
            end
            set -l before (du -sh $MCFLY_HISTFILE 2>/dev/null | awk '{print $1}')
            sqlite3 $MCFLY_HISTFILE "VACUUM; ANALYZE;" 2>/dev/null
            set -l after (du -sh $MCFLY_HISTFILE 2>/dev/null | awk '{print $1}')
            echo $_mf_green"  ✓ Optimized: $before → $after"$_mf_reset

        case failures
            echo $_mf_yellow"  ⚠  Removing failed commands from history..."$_mf_reset
            read -P "  Confirm? [y/N] " confirm
            string match -qi 'y*' $confirm || return 0
            command -q sqlite3 && \
                sqlite3 $MCFLY_HISTFILE \
                    "DELETE FROM commands WHERE exit_code != 0;" 2>/dev/null
            echo $_mf_green"  ✓ Failed commands removed"$_mf_reset

        case old
            set -l days $argv[2]
            test -z "$days" && set days 365
            echo $_mf_yellow"  Removing commands older than $days days..."$_mf_reset
            command -q sqlite3 && \
                sqlite3 $MCFLY_HISTFILE \
                    "DELETE FROM commands WHERE when_run < datetime('now', '-$days days');" 2>/dev/null
            echo $_mf_green"  ✓ Old commands removed"$_mf_reset

        case '*'
            echo "  Usage: mcfly-clean [optimize|failures|old [days]]"
    end
end

# ─── mcfly-train: Boost command neural rank ────────────────────────────────────
function mcfly-train --description "Manually boost McFly rank for a command"
    set -l cmd $argv[1]

    if test -z "$cmd"
        echo "  Usage: mcfly-train <command>"
        echo "  This manually increases the neural rank for a command"
        return 1
    end

    # McFly uses the 'add --exit 0' mechanism to reinforce ranking
    mcfly add --exit 0 -- $cmd 2>/dev/null
    and echo $_mf_green"  ✓ Rank boosted for: $cmd"$_mf_reset
    or  echo $_mf_yellow"  ⚠ Use 'mcfly add' directly for manual training"$_mf_reset
end

# ─── mcfly-export: Export history ─────────────────────────────────────────────
function mcfly-export --description "Export McFly history to plain text"
    set -l output $argv[1]
    test -z "$output" && set output "mcfly-history-"(date +%Y%m%d)".txt"

    command -q sqlite3 && test -f $MCFLY_HISTFILE || begin
        echo $_mf_red"  ✗ sqlite3 or database not found"$_mf_reset
        return 1
    end

    sqlite3 $MCFLY_HISTFILE \
        "SELECT cmd FROM commands ORDER BY when_run ASC;" 2>/dev/null > $output

    set -l count (wc -l < $output | string trim)
    echo $_mf_green"  ✓ Exported $count commands → $output"$_mf_reset
end

# ─── mcfly-switch: Toggle between mcfly and atuin ─────────────────────────────
function mcfly-switch --description "Switch between McFly and Atuin for Ctrl-R"
    set -l tool $argv[1]

    if test -z "$tool"
        echo ""
        echo $_mf_cyan"  🔀 History search backends:"$_mf_reset
        echo "    mcfly  — Neural network AI ranking"
        echo "    atuin  — Sync + fuzzy, no AI"
        echo ""
        echo "  Usage: mcfly-switch [mcfly|atuin]"
        return
    end

    switch $tool
        case mcfly
            bind --silent \cr _mcfly_search_enhanced 2>/dev/null
            bind --silent --mode insert \cr _mcfly_search_enhanced 2>/dev/null
            echo $_mf_green"  ✓ Ctrl-R → McFly (neural)"$_mf_reset

        case atuin
            if functions -q _atuin_search_global
                bind --silent \cr _atuin_search_global 2>/dev/null
                bind --silent --mode insert \cr _atuin_search_global 2>/dev/null
                echo $_mf_green"  ✓ Ctrl-R → Atuin (sync + fuzzy)"$_mf_reset
            else
                echo $_mf_yellow"  ⚠  Atuin not loaded"$_mf_reset
            end

        case fzf
            if command -q fzf
                function _fzf_history_bind
                    set -l selected (
                        history | fzf --tac --no-sort \
                            --border-label "  📜 Fish History " \
                            --border rounded \
                            --prompt "  🔍 "
                    )
                    commandline -r $selected
                end
                bind --silent \cr _fzf_history_bind 2>/dev/null
                echo $_mf_green"  ✓ Ctrl-R → fzf (plain fuzzy)"$_mf_reset
            end

        case '*'
            echo "  Usage: mcfly-switch [mcfly|atuin|fzf]"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add mf      'mcfly'
abbr --add mfs     'mcfly search'
abbr --add mfinfo  'mcfly-info'
abbr --add mftop   'mcfly-top'
abbr --add mffail  'mcfly-fails'
abbr --add mfclean 'mcfly-clean optimize'
abbr --add mfvac   'mcfly-clean vacuum'
abbr --add mftrain 'mcfly-train'
abbr --add mfexp   'mcfly-export'
abbr --add mfsw    'mcfly-switch'
abbr --add mfdb    "sqlite3 $_ash_mcfly_db"