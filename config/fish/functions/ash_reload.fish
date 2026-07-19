# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — ash_reload Ultra                                   ║
# ║  Smart shell reload: configs, completions, themes & live env sync          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function ash_reload --description "ASH smart shell environment reload"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l PURPLE (set_color magenta)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏱️  TIMING                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _ts_start (date +%s%N 2>/dev/null; or date +%s000000000)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _full    0   # Full exec (replace shell process)
    set -l _theme   0   # Theme-only reload
    set -l _config  0   # Config-only reload
    set -l _env     0   # Environment-only reload
    set -l _comp    0   # Completions-only reload
    set -l _quiet   0
    set -l _verbose 0
    set -l _list    0

    for arg in $argv
        switch $arg
            case --full -f full;          set _full    1
            case --theme -t theme;        set _theme   1
            case --config -c config;      set _config  1
            case --env -e env;            set _env     1
            case --completions comp;      set _comp    1
            case --quiet -q;              set _quiet   1
            case --verbose -v;            set _verbose 1
            case --list -l list;          set _list    1
            case --help -h help
                __rld_help
                return 0
        end
    end

    # Default: reload everything (soft)
    if test $_full -eq 0 && test $_theme -eq 0 \
    && test $_config -eq 0 && test $_env -eq 0 \
    && test $_comp -eq 0
        set _config 1
        set _theme  1
        set _env    1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELPERS                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __rld_help --description "Print help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     🔃  ash_reload — Shell Reload System             ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  ash_reload [target] [options]"
        echo ""
        echo "  $BOLD Targets:$R"
        printf "    $CYAN%-18s$R  %s\n" "(none)"       "Soft reload: config + theme + env"
        printf "    $CYAN%-18s$R  %s\n" "--full, -f"   "Hard reload: replace shell process (exec fish)"
        printf "    $CYAN%-18s$R  %s\n" "--theme, -t"  "Reload theme colors only"
        printf "    $CYAN%-18s$R  %s\n" "--config, -c" "Reload Fish config files"
        printf "    $CYAN%-18s$R  %s\n" "--env, -e"    "Reload environment variables"
        printf "    $CYAN%-18s$R  %s\n" "--completions" "Rebuild completions only"
        printf "    $CYAN%-18s$R  %s\n" "--list, -l"   "List all config files that would be sourced"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $CYAN%-18s$R  %s\n" "--quiet, -q"   "Suppress output"
        printf "    $CYAN%-18s$R  %s\n" "--verbose, -v" "Show each file sourced"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" "ash_reload              # Standard soft reload"
        printf "    $DIM%s$R\n" "ash_reload --full       # Full exec fish (clear state)"
        printf "    $DIM%s$R\n" "ash_reload --theme      # Re-apply current theme"
        printf "    $DIM%s$R\n" "ash_reload --config -v  # Verbose config reload"
        echo ""
    end

    function __rld_ok --description "Print success line"
        test $_quiet -eq 1 && return
        printf "  $GREEN✓$R  %s\n" $argv[1]
    end

    function __rld_skip --description "Print skip line"
        test $_quiet -eq 1 && return
        printf "  $DIM○  %s$R\n" $argv[1]
    end

    function __rld_fail --description "Print fail line"
        printf "  $RED✗$R  %s\n" $argv[1] >&2
    end

    function __rld_info --description "Print info line"
        test $_quiet -eq 1 && return
        printf "  $DIM›$R  $DIM%s$R\n" $argv[1]
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 LIST MODE                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_list -eq 1
        echo ""
        echo $BOLD$CYAN"  📋 Fish Config Files (reload order):"$R
        echo ""

        printf "  $BOLD$CYAN%-50s  %-12s$R\n" "File" "Status"
        printf "  $DIM%s$R\n" (string repeat -n 65 "─")

        # config.fish
        set -l main_config "$HOME/.config/fish/config.fish"
        printf "  %-50s  %s\n" $main_config \
            (test -f $main_config && echo $GREEN"✓ exists"$R || echo $RED"✗ missing"$R)

        # conf.d files
        for f in (ls "$HOME/.config/fish/conf.d/"*.fish 2>/dev/null | sort)
            set -l rel (string replace "$HOME/" "~/" $f)
            set -l size (du -sh $f 2>/dev/null | awk '{print $1}')
            printf "  %-50s  $DIM%s$R\n" $rel $size
        end

        # Local overrides
        for f in "$HOME/.config/fish/local.d/"*.fish 2>/dev/null
            test -f $f || continue
            printf "  $YELLOW%-50s$R  $YELLOW%s$R\n" \
                (string replace "$HOME/" "~/" $f) "local"
        end

        echo ""
        return 0
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔄 FULL RELOAD: exec fish (replace process)                            ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_full -eq 1
        test $_quiet -eq 0 && begin
            printf "\n  $BOLD$CYAN🔃 Full reload (exec fish)...$R\n"
            printf "  $DIM  Shell process will be replaced$R\n\n"
        end
        exec fish
        return  # Never reached
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎯 SOFT RELOAD BANNER                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    test $_quiet -eq 0 && begin
        printf "\n  $BOLD$CYAN🔃 ASH Shell Reload$R  $DIM—  "(date '+%H:%M:%S')$R"\n\n"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📄 CONFIG RELOAD: Source Fish config files                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_config -eq 1
        set -l sourced 0
        set -l failed  0

        # Source config.fish
        set -l main_cfg "$HOME/.config/fish/config.fish"
        if test -f $main_cfg
            source $main_cfg 2>/dev/null
            and begin
                set sourced (math $sourced + 1)
                test $_verbose -eq 1 && __rld_info "config.fish"
            end
            or begin
                set failed (math $failed + 1)
                __rld_fail "config.fish (error)"
            end
        end

        # Source conf.d files in order
        for f in (ls "$HOME/.config/fish/conf.d/"*.fish 2>/dev/null | sort)
            test -f $f || continue

            source $f 2>/dev/null
            if test $status -eq 0
                set sourced (math $sourced + 1)
                test $_verbose -eq 1 && __rld_info (basename $f)
            else
                set failed (math $failed + 1)
                test $_verbose -eq 1 && __rld_fail (basename $f)
            end
        end

        # Local overrides
        for f in "$HOME/.config/fish/local.d/"*.fish 2>/dev/null
            test -f $f || continue
            source $f 2>/dev/null
            set sourced (math $sourced + 1)
            test $_verbose -eq 1 && __rld_info (basename $f)" (local)"
        end

        if test $failed -eq 0
            __rld_ok "$sourced config files sourced"
        else
            __rld_fail "$sourced sourced, $failed failed"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 THEME RELOAD: Re-sync colors across all components                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_theme -eq 1
        if functions -q ash_theme_sync
            ash_theme_sync --quiet 2>/dev/null
            __rld_ok "Theme synced: $ASH_THEME_NAME"
        else
            # Manual: source theme cache
            set -l theme_cache "$HOME/.local/share/ash/cache/theme/colors.fish"
            if test -f $theme_cache
                source $theme_cache 2>/dev/null
                __rld_ok "Theme colors loaded from cache"
            else
                __rld_skip "Theme cache not found (run: ash theme apply <name>)"
            end
        end

        # Re-apply Fish syntax highlighting
        if functions -q __ash_theme_set_fish_colors
            __ash_theme_set_fish_colors 2>/dev/null
            test $_verbose -eq 1 && __rld_info "Fish syntax highlighting updated"
        end

        # Re-apply terminal palette
        if functions -q __ash_theme_set_terminal_palette
            __ash_theme_set_terminal_palette 2>/dev/null
            test $_verbose -eq 1 && __rld_info "Terminal palette updated"
        end

        # Sync fzf colors
        if set -q FZF_DEFAULT_OPTS && functions -q __ash_fzf_get_colors
            set --export BAT_THEME (set -q BAT_THEME && echo $BAT_THEME || echo "Catppuccin Mocha")
            test $_verbose -eq 1 && __rld_info "fzf colors updated"
        end

        # Emit theme changed event
        emit ash_theme_changed $ASH_THEME_NAME 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🌍 ENV RELOAD: Refresh environment variables                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_env -eq 1
        set -l env_count 0

        # Source environment.d files
        for env_file in \
            "$HOME/.config/environment.d/"*.conf \
            "$HOME/.config/fish/env.d/"*.fish
            test -f $env_file || continue

            switch (string match -r '\.[^.]+$' $env_file)
                case .fish
                    source $env_file 2>/dev/null
                case .conf
                    # Parse KEY=VALUE format
                    while read -l line
                        string match -q '#*' $line && continue
                        string match -q '' $line && continue
                        set -l key (string split '=' $line)[1]
                        set -l val (string split '=' $line | tail -1)
                        set --export $key $val 2>/dev/null
                    end < $env_file
            end

            set env_count (math $env_count + 1)
            test $_verbose -eq 1 && __rld_info (basename $env_file)
        end

        # Refresh PATH from fish_user_paths
        set -e PATH
        set -l new_path \
            $fish_user_paths \
            "/usr/local/bin" \
            "/usr/bin" \
            "/bin" \
            "/usr/sbin" \
            "/sbin"
        set --export PATH $new_path
        set env_count (math $env_count + 1)

        # Re-detect tool environments
        # Cargo
        test -d "$HOME/.cargo/bin" && \
            fish_add_path --global --prepend "$HOME/.cargo/bin"

        # Go
        test -d "$HOME/go/bin" && \
            fish_add_path --global --append "$HOME/go/bin"

        # Node/pnpm
        test -n "$PNPM_HOME" && \
            fish_add_path --global --prepend "$PNPM_HOME"

        # Local bin
        test -d "$HOME/.local/bin" && \
            fish_add_path --global --prepend "$HOME/.local/bin"

        __rld_ok "Environment variables refreshed"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ✅ COMPLETIONS RELOAD                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_comp -eq 1 || test $_config -eq 1
        # Clear completion cache
        rm -rf "$HOME/.local/share/ash/cache/completions" 2>/dev/null
        mkdir -p "$HOME/.local/share/ash/cache/completions" 2>/dev/null

        # Rebuild fish completions
        fish_update_completions 2>/dev/null >/dev/null
        __rld_ok "Completions rebuilt"

        # Source fresh completions if ash installed
        if test -f "$HOME/.config/fish/completions/ash.fish"
            source "$HOME/.config/fish/completions/ash.fish" 2>/dev/null
            test $_verbose -eq 1 && __rld_info "ASH completions reloaded"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔔 LIVE SESSIONS: Notify running Neovim                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $_theme -eq 1 && command -q nvim
        set -l notified 0
        for sock in \
            "$XDG_RUNTIME_DIR/nvim."*".sock" \
            "$HOME/.local/share/nvim/server-"*".sock" \
            2>/dev/null
            test -S $sock || continue
            nvim --server $sock \
                --remote-send \
                "<cmd>lua if pcall(require,'ash') then require('ash').sync_theme() end<cr>" \
                2>/dev/null
            set notified (math $notified + 1)
        end
        test $notified -gt 0 && test $_verbose -eq 1 && \
            __rld_info "Neovim notified ($notified instances)"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏱️  TIMING & SUMMARY                                                   ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _ts_end (date +%s%N 2>/dev/null; or date +%s000000000)
    set -l _elapsed_ms (math --scale 1 "($_ts_end - $_ts_start) / 1000000" 2>/dev/null; or echo "?")

    test $_quiet -eq 0 && printf "\n  $DIM⏱ Reload complete in %sms$R\n\n" $_elapsed_ms

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __rld_help __rld_ok __rld_skip __rld_fail __rld_info 2>/dev/null

end

# ── Alias: 'reload' also works ────────────────────────────────────────────────
function reload --wraps=ash_reload --description "Alias: ash_reload"
    ash_reload $argv
end
