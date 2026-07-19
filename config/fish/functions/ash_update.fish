# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ash_update Ultra                                   ║
# ║  Complete update orchestration: dotfiles, system, plugins, themes & tools  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash_update --description "ASH ultra update orchestrator"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 PATHS & CONSTANTS                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _ash_root        "$HOME/.config/ash"
    set -l _ash_dotfiles    "$HOME/.config"
    set -l _log_dir         "$HOME/.local/share/ash/logs"
    set -l _log_file        "$_log_dir/update-"(date +%Y%m%d-%H%M%S)".log"
    set -l _state_dir       "$HOME/.local/share/ash/state"
    set -l _cache_dir       "$HOME/.local/share/ash/cache"
    set -l _update_record   "$_state_dir/last-update.json"
    set -l _lock_file       "/tmp/ash-update.lock"
    set -l _backup_dir      "$HOME/.ash-backups/pre-update-"(date +%Y%m%d%H%M%S)
    set -l _start_time      (date +%s)

    mkdir -p $_log_dir $_state_dir 2>/dev/null

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS & UI                                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 PROGRESS TRACKING                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -g _upd_total    0
    set -g _upd_success  0
    set -g _upd_failed   0
    set -g _upd_skipped  0
    set -g _upd_results  # list of "step:status:message:elapsed"

    # ── Progress bar renderer ─────────────────────────────────────────────────
    function __upd_bar --description "Render animated progress bar"
        set -l pct   $argv[1]
        set -l width $argv[2]
        test -z "$width" && set width 30

        set -l filled (math --scale 0 "min($pct, 100) * $width / 100")
        set -l empty  (math $width - $filled)

        set -l bar_color $GREEN
        test $pct -lt 50 && set bar_color $CYAN
        test $pct -lt 25 && set bar_color $YELLOW

        printf "%s%s%s%s  %s%3d%%%s" \
            $bar_color \
            (string repeat -n $filled "█") \
            $DIM \
            (string repeat -n $empty  "░") \
            $bar_color $pct $R
    end

    # ── Spinner frames ─────────────────────────────────────────────────────────
    set -g _spin_frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
    set -g _spin_idx    1

    function __spin_next --description "Get next spinner frame"
        set -l frame $_spin_frames[$_spin_idx]
        set -g _spin_idx (math ($_spin_idx % (count $_spin_frames)) + 1)
        echo $frame
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📝 LOGGING                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __upd_log --description "Write to update log"
        set -l ts  (date '+%H:%M:%S')
        set -l lvl $argv[1]
        set -l msg (string join ' ' $argv[2..-1])
        printf "[%s][%-5s] %s\n" $ts $lvl $msg >> $_log_file 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 STEP RENDERER                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __upd_step_start --description "Announce an update step"
        set -l icon  $argv[1]
        set -l title $argv[2]
        set -l desc  $argv[3]

        set -g _upd_total (math $_upd_total + 1)
        set -g _step_start_ts (date +%s)

        printf "\n  %s  $BOLD$CYAN%-30s$R  $DIM%s$R\n" $icon $title $desc
        printf "  $DIM%s$R\n" (string repeat -n 60 "─")
        __upd_log INFO "START: $title"
    end

    function __upd_step_ok --description "Mark step as successful"
        set -l msg $argv[1]
        set -l elapsed (math (date +%s) - $_step_start_ts)
        set -g _upd_success (math $_upd_success + 1)
        printf "  $GREEN✓$R  %s $DIM(%ds)$R\n" $msg $elapsed
        __upd_log OK "$msg ($elapsed""s)"
        set --append _upd_results "ok:$msg:$elapsed"
    end

    function __upd_step_fail --description "Mark step as failed"
        set -l msg $argv[1]
        set -l elapsed (math (date +%s) - $_step_start_ts)
        set -g _upd_failed (math $_upd_failed + 1)
        printf "  $RED✗$R  %s $DIM(%ds)$R\n" $msg $elapsed
        __upd_log ERR "$msg ($elapsed""s)"
        set --append _upd_results "fail:$msg:$elapsed"
    end

    function __upd_step_skip --description "Mark step as skipped"
        set -l msg $argv[1]
        set -g _upd_skipped (math $_upd_skipped + 1)
        printf "  $DIM○$R  $DIM%s (skipped)$R\n" $msg
        __upd_log SKIP $msg
        set --append _upd_results "skip:$msg:0"
    end

    function __upd_substep --description "Print a sub-step result"
        set -l status $argv[1]   # ok | fail | info
        set -l msg    $argv[2]
        switch $status
            case ok
                printf "     $GREEN›$R  %s\n" $msg
            case fail
                printf "     $RED›$R  %s\n" $msg
            case warn
                printf "     $YELLOW›$R  %s\n" $msg
            case '*'
                printf "     $DIM›$R  $DIM%s$R\n" $msg
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _do_system    0
    set -l _do_dotfiles  0
    set -l _do_plugins   0
    set -l _do_themes    0
    set -l _do_nvim      0
    set -l _do_fish      0
    set -l _do_flatpak   0
    set -l _do_cargo     0
    set -l _do_npm       0
    set -l _do_pip       0
    set -l _do_all       0
    set -l _dry_run      0
    set -l _no_snapshot  0
    set -l _no_restart   0
    set -l _quiet        0
    set -l _verbose      0
    set -l _check_only   0
    set -l _rollback     0
    set -l _force        0

    if test (count $argv) -eq 0
        set _do_all 1
    end

    for arg in $argv
        switch $arg
            case system;              set _do_system   1
            case dotfiles;            set _do_dotfiles 1
            case plugins;             set _do_plugins  1
            case themes;              set _do_themes   1
            case nvim neovim;         set _do_nvim     1
            case fish;                set _do_fish     1
            case flatpak;             set _do_flatpak  1
            case cargo rust;          set _do_cargo    1
            case npm node;            set _do_npm      1
            case pip python;          set _do_pip      1
            case all;                 set _do_all      1
            case --dry-run -n;        set _dry_run     1
            case --no-snapshot;       set _no_snapshot 1
            case --no-restart;        set _no_restart  1
            case -q --quiet;          set _quiet       1
            case -v --verbose;        set _verbose     1
            case --check -c check;    set _check_only  1
            case --rollback rollback; set _rollback    1
            case --force -f;          set _force       1
            case --help -h help
                __upd_print_help
                return 0
        end
    end

    # Expand "all" flag
    if test $_do_all -eq 1
        set _do_system   1
        set _do_dotfiles 1
        set _do_plugins  1
        set _do_themes  1
        set _do_nvim     1
        set _do_fish     1
        set _do_flatpak  1
        set _do_cargo    1
        set _do_npm      1
        set _do_pip      1
    end

    # ── Help ──────────────────────────────────────────────────────────────────
    function __upd_print_help --description "Print help message"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🔄  ash_update — Update Orchestrator              ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ash_update [targets...] [options]"
        echo ""
        echo "  $BOLD Targets:$R"
        printf "    $CYAN%-15s$R  %s\n" "all"       "Update everything (default)"
        printf "    $CYAN%-15s$R  %s\n" "system"    "System packages (pacman/apt/dnf/etc)"
        printf "    $CYAN%-15s$R  %s\n" "dotfiles"  "ASH dotfiles from git"
        printf "    $CYAN%-15s$R  %s\n" "plugins"   "ASH plugins"
        printf "    $CYAN%-15s$R  %s\n" "themes"    "ASH theme presets"
        printf "    $CYAN%-15s$R  %s\n" "nvim"      "Neovim plugins (Lazy.nvim)"
        printf "    $CYAN%-15s$R  %s\n" "fish"      "Fish plugins (fisher/plug)"
        printf "    $CYAN%-15s$R  %s\n" "flatpak"   "Flatpak applications"
        printf "    $CYAN%-15s$R  %s\n" "cargo"     "Cargo (Rust) packages"
        printf "    $CYAN%-15s$R  %s\n" "npm"       "Global npm packages"
        printf "    $CYAN%-15s$R  %s\n" "pip"       "Python pip packages"
        printf "    $CYAN%-15s$R  %s\n" "check"     "Check for updates (no install)"
        printf "    $CYAN%-15s$R  %s\n" "rollback"  "Rollback last update"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $YELLOW%-17s$R  %s\n" "--dry-run, -n"    "Preview without applying"
        printf "    $YELLOW%-17s$R  %s\n" "--no-snapshot"    "Skip pre-update snapshot"
        printf "    $YELLOW%-17s$R  %s\n" "--no-restart"     "Skip service restarts"
        printf "    $YELLOW%-17s$R  %s\n" "--force, -f"      "Force update (ignore caches)"
        printf "    $YELLOW%-17s$R  %s\n" "--quiet, -q"      "Minimal output"
        printf "    $YELLOW%-17s$R  %s\n" "--verbose, -v"    "Verbose output"
        printf "    $YELLOW%-17s$R  %s\n" "--check, -c"      "Check only (no install)"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" "ash_update                    # Update everything"
        printf "    $DIM%s$R\n" "ash_update system plugins      # Update system + plugins"
        printf "    $DIM%s$R\n" "ash_update --dry-run           # Preview all updates"
        printf "    $DIM%s$R\n" "ash_update check               # Check for updates only"
        printf "    $DIM%s$R\n" "ash_update rollback            # Rollback last update"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔒 LOCK FILE: Prevent concurrent updates                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test -f $_lock_file
        set -l lock_pid (cat $_lock_file 2>/dev/null)
        if kill -0 $lock_pid 2>/dev/null
            echo ""
            echo "  $YELLOW⚠$R  Another ash_update is running (PID: $lock_pid)"
            echo "  $DIM  Remove lock: rm $_lock_file$R"
            return 1
        end
        rm -f $_lock_file
    end
    echo $fish_pid > $_lock_file

    # ── Ensure lock is removed on exit ────────────────────────────────────────
    function __upd_cleanup --on-event fish_exit
        rm -f $_lock_file 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖥  HEADER BANNER                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_quiet -eq 0
        printf "\n"
        printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════════════╗$R\n"
        printf "  $BOLD$PURPLE║  🔄  ASH DOTFILES v5.0 — Update Orchestrator                ║$R\n"
        printf "  $BOLD$PURPLE║  %-62s║$R\n" \
            (test $_dry_run   -eq 1 && echo "  DRY RUN MODE — no changes will be made" || \
             test $_check_only -eq 1 && echo "  CHECK MODE — reporting available updates only" || \
             echo "  "date '+%A, %B %-d %Y  %H:%M:%S')
        printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════════════╝$R\n"
        printf "\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 CHECK MODE: Report available updates                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_check_only -eq 1
        printf "  $BOLD$CYAN📋 Checking for available updates...$R\n\n"

        # System packages
        function __check_system_updates --description "Check system package updates"
            if command -q checkupdates
                set -l updates (checkupdates 2>/dev/null | wc -l | string trim)
                echo "  $CYAN $R  System (pacman):  $YELLOW$updates$R packages available"
            else if command -q apt
                set -l updates (apt list --upgradable 2>/dev/null | tail -n +2 | wc -l | string trim)
                echo "  $CYAN $R  System (apt):     $YELLOW$updates$R packages available"
            else if command -q dnf
                set -l updates (dnf check-update --quiet 2>/dev/null | wc -l | string trim)
                echo "  $CYAN $R  System (dnf):     $YELLOW$updates$R packages available"
            end
        end
        __check_system_updates

        # Dotfiles git status
        if test -d "$HOME/.config/ash/.git"
            set -l behind (
                cd "$HOME/.config/ash" 2>/dev/null
                git fetch --quiet 2>/dev/null
                git rev-list HEAD..@{u} 2>/dev/null | wc -l | string trim
            )
            echo "  $CYAN$R  Dotfiles (git):   $YELLOW$behind$R commits behind"
        end

        # Neovim plugins
        if test -f "$HOME/.config/nvim/lazy-lock.json" && command -q nvim
            echo "  $CYAN$R  Neovim plugins:   $DIM(run 'nvim --headless +LazySync +qa')$R"
        end

        # Flatpak
        if command -q flatpak
            set -l fp_updates (flatpak remote-ls --updates 2>/dev/null | wc -l | string trim)
            echo "  $CYAN$R  Flatpak:          $YELLOW$fp_updates$R applications available"
        end

        # Cargo (cargo-install-update)
        if command -q cargo-install-update
            set -l cargo_updates (cargo install-update --list 2>/dev/null | grep -c '\bYes\b')
            echo "  $CYAN🦀$R  Cargo packages:   $YELLOW$cargo_updates$R outdated"
        end

        printf "\n  $DIM📝 Log: $_log_file$R\n\n"
        rm -f $_lock_file
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔀 ROLLBACK MODE                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_rollback -eq 1
        printf "\n  $BOLD$YELLOW⏮  Rolling back last update...$R\n\n"

        if not test -f $_update_record
            printf "  $RED✗$R  No update record found at: $_update_record\n"
            rm -f $_lock_file
            return 1
        end

        set -l last_backup ""
        command -q jq && set -l last_backup \
            (jq -r '.backup_path // ""' $_update_record 2>/dev/null)

        if test -n "$last_backup" && test -d "$last_backup"
            printf "  $CYAN ›$R  Restoring from: $last_backup\n"
            read -P "  Confirm rollback? [y/N] " confirm
            if string match -qi 'y*' $confirm
                # Restore dotfiles backup
                cp -r "$last_backup/." "$HOME/.config/" 2>/dev/null
                printf "  $GREEN✓$R  Rollback complete\n"
                printf "  $DIM  Reload shell to apply: exec fish$R\n"
            else
                printf "  $DIM  Rollback cancelled$R\n"
            end
        else
            printf "  $YELLOW⚠$R  No backup found — cannot rollback automatically\n"
            printf "  $DIM  Use ASH snapshot: ash snapshot restore$R\n"
        end

        rm -f $_lock_file
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📸 PRE-UPDATE SNAPSHOT                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_no_snapshot -eq 0 && test $_dry_run -eq 0
        __upd_step_start "📸" "Pre-update Snapshot" "Creating safety snapshot"

        if command -q ash
            ash snapshot create --message "pre-update-"(date +%Y%m%d) \
                2>/dev/null >/dev/null
            and __upd_step_ok "Snapshot created"
            or  __upd_step_fail "Snapshot failed (continuing anyway)"
        else
            # Minimal backup: copy key config files
            mkdir -p "$_backup_dir/nvim" "$_backup_dir/fish" 2>/dev/null
            cp -r "$HOME/.config/nvim/lazy-lock.json" \
                  "$_backup_dir/nvim/" 2>/dev/null
            cp -r "$HOME/.config/fish/conf.d" \
                  "$_backup_dir/fish/" 2>/dev/null
            __upd_step_ok "Minimal backup created: $_backup_dir"
        end

        # Record backup path
        printf '{"timestamp":"%s","backup_path":"%s","components":[]}' \
            (date -u +%Y-%m-%dT%H:%M:%SZ) "$_backup_dir" \
            > $_update_record 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: System Packages                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_system -eq 1
        __upd_step_start "" "System Packages" "Updating OS packages"

        if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: would update system packages"
        else
            # Detect package manager
            if command -q paru
                paru -Syu --noconfirm 2>>$_log_file
                and __upd_step_ok "paru: system updated"
                or  __upd_step_fail "paru: update failed"

            else if command -q yay
                yay -Syu --noconfirm 2>>$_log_file
                and __upd_step_ok "yay: system updated"
                or  __upd_step_fail "yay: update failed"

            else if command -q pacman
                sudo pacman -Syu --noconfirm 2>>$_log_file
                and __upd_step_ok "pacman: system updated"
                or  __upd_step_fail "pacman: update failed"

            else if command -q apt
                sudo apt update 2>>$_log_file && \
                sudo apt upgrade -y 2>>$_log_file && \
                sudo apt autoremove -y 2>>$_log_file
                and __upd_step_ok "apt: system updated"
                or  __upd_step_fail "apt: update failed"

            else if command -q dnf
                sudo dnf upgrade -y 2>>$_log_file
                and __upd_step_ok "dnf: system updated"
                or  __upd_step_fail "dnf: update failed"

            else if command -q zypper
                sudo zypper update -y 2>>$_log_file
                and __upd_step_ok "zypper: system updated"
                or  __upd_step_fail "zypper: update failed"

            else if command -q xbps-install
                sudo xbps-install -Su 2>>$_log_file
                and __upd_step_ok "xbps: system updated"
                or  __upd_step_fail "xbps: update failed"

            else if command -q nix
                nix-env -u '*' 2>>$_log_file
                and __upd_step_ok "nix: packages updated"
                or  __upd_step_fail "nix: update failed"

            else if command -q brew
                brew update 2>>$_log_file && brew upgrade 2>>$_log_file
                and __upd_step_ok "brew: packages updated"
                or  __upd_step_fail "brew: update failed"

            else
                __upd_step_skip "No supported package manager found"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: ASH Dotfiles (git pull)                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_dotfiles -eq 1
        __upd_step_start "" "ASH Dotfiles" "Pulling latest from git"

        set -l dotfiles_root "$HOME/.config/ash"
        test -d $dotfiles_root || set dotfiles_root "$HOME/.dotfiles"
        test -d $dotfiles_root || set dotfiles_root "$HOME/dotfiles"

        if not test -d "$dotfiles_root/.git"
            __upd_step_skip "Dotfiles not a git repo (manual install)"
        else if test $_dry_run -eq 1
            set -l behind (
                cd $dotfiles_root 2>/dev/null
                git fetch --quiet 2>/dev/null
                git rev-list HEAD..@{u} 2>/dev/null | wc -l | string trim
            )
            __upd_step_ok "DRY-RUN: $behind commits available"
        else
            cd $dotfiles_root 2>/dev/null

            # Stash any local changes
            set -l stashed 0
            if git diff --quiet 2>/dev/null | count | grep -q '^0'
                true
            else
                git stash push --message "ash-update-stash-"(date +%s) \
                    2>>$_log_file && set stashed 1
                __upd_substep info "Local changes stashed"
            end

            # Pull
            git pull --rebase --autostash 2>>$_log_file
            set -l pull_rc $status

            # Show what changed
            if test $pull_rc -eq 0
                set -l changed_files (
                    git diff HEAD@{1} HEAD --name-only 2>/dev/null | wc -l | string trim
                )
                set -l new_commits (
                    git log HEAD@{1}..HEAD --oneline 2>/dev/null | wc -l | string trim
                )
                __upd_substep ok "$new_commits commits merged, $changed_files files changed"

                # Show recent commits
                if test $_verbose -eq 1
                    git log HEAD@{1}..HEAD --oneline --color=always 2>/dev/null | \
                    while read -l line
                        __upd_substep info $line
                    end
                end

                # Restore stash
                test $stashed -eq 1 && git stash pop 2>/dev/null && \
                    __upd_substep ok "Local changes restored"

                __upd_step_ok "Dotfiles updated ($new_commits commits)"
            else
                __upd_step_fail "Git pull failed (check log: $_log_file)"
                test $stashed -eq 1 && git stash pop 2>/dev/null
            end

            cd - >/dev/null 2>&1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: ASH Plugins                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_plugins -eq 1
        __upd_step_start "🔌" "ASH Plugins" "Updating installed plugins"

        set -l plugins_dir "$HOME/.config/ash/plugins"

        if not test -d $plugins_dir
            __upd_step_skip "Plugin directory not found"
        else if test $_dry_run -eq 1
            set -l count (count $plugins_dir/core/*/ $plugins_dir/integrations/*/ 2>/dev/null)
            __upd_step_ok "DRY-RUN: $count plugins would be updated"
        else
            set -l updated 0
            set -l failed  0

            # Update each git-managed plugin
            for plugin_dir in \
                $plugins_dir/core/*/ \
                $plugins_dir/integrations/*/ \
                $plugins_dir/community/*/
                test -d "$plugin_dir/.git" || continue

                set -l pname (basename $plugin_dir)
                cd $plugin_dir 2>/dev/null

                git pull --quiet 2>>$_log_file
                if test $status -eq 0
                    set updated (math $updated + 1)
                    __upd_substep ok $pname
                else
                    set failed (math $failed + 1)
                    __upd_substep fail $pname
                end
                cd - >/dev/null 2>&1
            end

            if test $failed -eq 0
                __upd_step_ok "Plugins: $updated updated"
            else
                __upd_step_fail "Plugins: $updated updated, $failed failed"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: ASH Themes                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_themes -eq 1
        __upd_step_start "🎨" "ASH Themes" "Refreshing theme presets"

        if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: themes would be refreshed"
        else
            # Re-sync theme cache
            rm -rf "$_cache_dir/theme" 2>/dev/null
            mkdir -p "$_cache_dir/theme" 2>/dev/null

            # Re-run theme sync
            if functions -q ash_theme_sync
                ash_theme_sync --quiet 2>/dev/null
                __upd_substep ok "Theme colors synced"
            end

            # Update theme store index if online
            if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
                command -q ash && ash theme store-download --index 2>/dev/null && \
                    __upd_substep ok "Theme store index refreshed"
            end

            __upd_step_ok "Themes refreshed"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Neovim Plugins (Lazy.nvim)                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_nvim -eq 1
        __upd_step_start "" "Neovim Plugins" "Updating via Lazy.nvim + Mason"

        if not command -q nvim
            __upd_step_skip "Neovim not installed"
        else if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: Neovim plugins would be synced"
        else
            # Backup lazy-lock before update
            set -l lazy_lock "$HOME/.config/nvim/lazy-lock.json"
            test -f $lazy_lock && cp $lazy_lock "$_backup_dir/lazy-lock.json.bak" 2>/dev/null

            printf "     $DIM› Syncing Lazy.nvim (this may take 30-60s)...$R\n"

            nvim --headless \
                "+Lazy! sync" \
                "+qa" \
                2>>$_log_file
            set -l lazy_rc $status

            if test $lazy_rc -eq 0
                __upd_substep ok "Lazy.nvim plugins synced"

                # Mason update
                printf "     $DIM› Updating Mason packages...$R\n"
                nvim --headless "+MasonUpdate" "+qa" 2>>$_log_file
                and __upd_substep ok "Mason packages updated"
                or  __upd_substep warn "Mason update had warnings"

                # Count updated plugins
                set -l plugin_count (
                    test -f $lazy_lock && command -q jq && \
                    jq 'keys | length' $lazy_lock 2>/dev/null || echo "?"
                )
                __upd_step_ok "Neovim: $plugin_count plugins synced"
            else
                __upd_step_fail "Lazy.nvim sync failed (check: $HOME/.local/state/nvim/lazy*.log)"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Fish Plugins                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_fish -eq 1
        __upd_step_start "🐟" "Fish Plugins" "Updating shell plugins"

        if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: Fish plugins would be updated"
        else
            # Fisher
            if functions -q fisher
                fisher update 2>>$_log_file
                and __upd_substep ok "fisher: plugins updated"
                or  __upd_substep warn "fisher: some updates failed"
                __upd_step_ok "Fish (fisher) updated"

            # Plug.fish
            else if functions -q plug
                plug update 2>>$_log_file
                and __upd_substep ok "plug: plugins updated"
                __upd_step_ok "Fish (plug) updated"

            else
                __upd_step_skip "No Fish plugin manager found"
            end

            # Regenerate completions
            fish_update_completions 2>/dev/null && \
                __upd_substep ok "Completions regenerated"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Flatpak Applications                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_flatpak -eq 1
        __upd_step_start "" "Flatpak Apps" "Updating Flatpak applications"

        if not command -q flatpak
            __upd_step_skip "Flatpak not installed"
        else if test $_dry_run -eq 1
            set -l updates (flatpak remote-ls --updates 2>/dev/null | wc -l | string trim)
            __upd_step_ok "DRY-RUN: $updates Flatpak apps would be updated"
        else
            flatpak update -y 2>>$_log_file
            and begin
                set -l updated (flatpak list 2>/dev/null | wc -l | string trim)
                __upd_step_ok "Flatpak: applications updated"
            end
            or __upd_step_fail "Flatpak: update failed"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Cargo (Rust) packages                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_cargo -eq 1
        __upd_step_start "🦀" "Cargo Packages" "Updating Rust tools"

        if not command -q cargo
            __upd_step_skip "Cargo not installed"
        else if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: Cargo packages would be updated"
        else
            # Use cargo-install-update if available (fast)
            if command -q cargo-install-update
                cargo install-update --all 2>>$_log_file
                and __upd_step_ok "Cargo packages updated (cargo-install-update)"
                or  __upd_step_fail "Cargo update failed"

            else
                # Manual: re-install key tools
                set -l cargo_tools \
                    cargo-update \
                    bat \
                    eza \
                    fd-find \
                    ripgrep \
                    zoxide \
                    starship \
                    bottom \
                    tokei \
                    delta

                set -l updated 0
                set -l failed  0

                for tool in $cargo_tools
                    if cargo install --list 2>/dev/null | grep -q "^$tool "
                        cargo install $tool 2>>$_log_file >/dev/null
                        if test $status -eq 0
                            set updated (math $updated + 1)
                            __upd_substep ok $tool
                        else
                            set failed (math $failed + 1)
                            __upd_substep fail $tool
                        end
                    end
                end

                test $failed -eq 0 \
                    && __upd_step_ok "Cargo: $updated tools updated" \
                    || __upd_step_fail "Cargo: $updated updated, $failed failed"
            end

            # Update rustup too
            if command -q rustup
                rustup update stable 2>>$_log_file >/dev/null
                and __upd_substep ok "rustup: stable toolchain updated"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Global npm packages                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_npm -eq 1
        __upd_step_start "⬢" "npm Packages" "Updating global Node.js tools"

        if not command -q npm
            __upd_step_skip "npm not installed"
        else if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: npm globals would be updated"
        else
            npm update -g 2>>$_log_file >/dev/null
            and __upd_step_ok "npm global packages updated"
            or  __upd_step_fail "npm update failed"

            # pnpm global
            if command -q pnpm
                pnpm update -g 2>>$_log_file >/dev/null
                and __upd_substep ok "pnpm: globals updated"
            end

            # Bun upgrade
            if command -q bun
                bun upgrade 2>>$_log_file >/dev/null
                and __upd_substep ok "bun: upgraded"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 UPDATE: Python pip packages                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_do_pip -eq 1
        __upd_step_start "🐍" "Python Packages" "Updating pip packages"

        if not command -q pip || not command -q pip3
            __upd_step_skip "pip not installed"
        else if test $_dry_run -eq 1
            __upd_step_ok "DRY-RUN: pip packages would be updated"
        else
            set -l pip_exe (command -q pip3 && echo pip3 || echo pip)

            # Use pip-review if available
            if command -q pip-review
                pip-review --auto 2>>$_log_file >/dev/null
                and __upd_step_ok "pip: packages updated (pip-review)"
                or  __upd_step_fail "pip-review failed"
            else
                # Manual: update outdated
                set -l outdated (
                    $pip_exe list --outdated --format=columns 2>/dev/null | \
                    tail -n +3 | awk '{print $1}'
                )

                if test (count $outdated) -gt 0
                    $pip_exe install --upgrade $outdated 2>>$_log_file >/dev/null
                    and __upd_step_ok "pip: "(count $outdated)" packages updated"
                    or  __upd_step_fail "pip: update failed"
                else
                    __upd_step_ok "pip: all packages up to date"
                end
            end

            # pipx
            if command -q pipx
                pipx upgrade-all 2>>$_log_file >/dev/null
                and __upd_substep ok "pipx: tools upgraded"
            end
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🏁 POST-UPDATE: Reload & Sync                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_dry_run -eq 0 && test $_no_restart -eq 0
        __upd_step_start "🔃" "Post-Update Sync" "Reloading shell environment"

        # Sync ASH theme
        if functions -q ash_theme_sync
            ash_theme_sync --quiet 2>/dev/null
            __upd_substep ok "ASH theme synced"
        end

        # Reload Fish completions
        fish_update_completions 2>/dev/null >/dev/null
        __upd_substep ok "Fish completions refreshed"

        # Clear caches
        rm -rf "$_cache_dir/completions" 2>/dev/null
        mkdir -p "$_cache_dir/completions" 2>/dev/null
        __upd_substep ok "Completion caches cleared"

        # Notify running Neovim instances
        for sock in "$XDG_RUNTIME_DIR/nvim."*".sock"
            test -S $sock || continue
            nvim --server $sock \
                --remote-send \
                "<cmd>lua if pcall(require,'ash') then require('ash').reload() end<cr>" \
                2>/dev/null
        end

        # System notify if enabled
        if command -q notify-send && set -q ASH_NOTIFICATIONS
            notify-send \
                --app-name="ASH Dotfiles" \
                --icon="system-software-update" \
                "Update Complete" \
                "✅ ASH updated successfully" \
                2>/dev/null
        end

        __upd_step_ok "Post-update sync complete"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📝 RECORD UPDATE                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_dry_run -eq 0
        set -l end_time (date +%s)
        set -l total_elapsed (math $end_time - $_start_time)

        printf '{"timestamp":"%s","elapsed":%d,"success":%d,"failed":%d,"skipped":%d,"backup_path":"%s","log":"%s"}' \
            (date -u +%Y-%m-%dT%H:%M:%SZ) \
            $total_elapsed \
            $_upd_success \
            $_upd_failed \
            $_upd_skipped \
            "$_backup_dir" \
            "$_log_file" \
            > $_update_record 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 FINAL SUMMARY                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _end_time     (date +%s)
    set -l _total_elapsed (math $_end_time - $_start_time)

    printf "\n"
    printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$PURPLE║     📊  Update Summary                               ║$R\n"
    printf "  $BOLD$PURPLE╠══════════════════════════════════════════════════════╣$R\n"
    printf "  $BOLD$PURPLE║$R  $GREEN%-4s steps succeeded$R%29s$PURPLE║$R\n" \
        $_upd_success ""
    printf "  $BOLD$PURPLE║$R  $RED%-4s steps failed$R%31s$PURPLE║$R\n" \
        $_upd_failed ""
    printf "  $BOLD$PURPLE║$R  $DIM%-4s steps skipped$R%30s$PURPLE║$R\n" \
        $_upd_skipped ""
    printf "  $BOLD$PURPLE║$R  $DIM⏱  Total time: %ds$R%31s$PURPLE║$R\n" \
        $_total_elapsed ""
    printf "  $BOLD$PURPLE║$R  $DIM📝 Log: %-46s$R$PURPLE║$R\n" \
        (string sub --length 46 $_log_file)
    printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n"

    if test $_dry_run -eq 1
        printf "\n  $YELLOW⚠  DRY-RUN: No changes were made$R\n"
    else if test $_upd_failed -eq 0
        printf "\n  $GREEN✓  All updates applied successfully!$R\n"
        printf "  $DIM  Reload shell: exec fish$R\n"
    else
        printf "\n  $YELLOW⚠  Some updates failed — check log: $_log_file$R\n"
    end
    printf "\n"

    # ── Cleanup ───────────────────────────────────────────────────────────────
    rm -f $_lock_file 2>/dev/null
    functions --erase __upd_bar __upd_log __upd_step_start __upd_step_ok \
        __upd_step_fail __upd_step_skip __upd_substep __upd_cleanup \
        __upd_print_help __check_system_updates __spin_next 2>/dev/null
    set --erase _upd_total _upd_success _upd_failed _upd_skipped _upd_results \
        _spin_frames _spin_idx _step_start_ts 2>/dev/null

    return (test $_upd_failed -eq 0 && echo 0 || echo 1)

end
