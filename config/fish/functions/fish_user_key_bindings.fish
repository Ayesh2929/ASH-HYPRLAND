# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_user_key_bindings Ultra                       ║
# ║  Complete keybind system: vi + emacs + fzf + ASH + productivity bindings   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_user_key_bindings --description "ASH ultra keyboard bindings"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎛️  CONFIGURATION FLAGS                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Set key binding mode: vi | emacs | default
    set -l bind_mode (set -q ASH_KEY_MODE && echo $ASH_KEY_MODE || echo vi)

    # Enable/disable optional binding groups
    set -l enable_fzf    (set -q ASH_BINDS_FZF    && echo $ASH_BINDS_FZF    || echo 1)
    set -l enable_skim   (set -q ASH_BINDS_SKIM   && echo $ASH_BINDS_SKIM   || echo 0)
    set -l enable_zoxide (set -q ASH_BINDS_ZOXIDE && echo $ASH_BINDS_ZOXIDE || echo 1)
    set -l enable_atuin  (set -q ASH_BINDS_ATUIN  && echo $ASH_BINDS_ATUIN  || echo 1)
    set -l enable_mcfly  (set -q ASH_BINDS_MCFLY  && echo $ASH_BINDS_MCFLY  || echo 0)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔧 HELPER: safe bind wrapper                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __bind --description "Bind key in all relevant modes"
        set -l modes $argv[1]   # "all" | "insert" | "normal" | "visual"
        set -l key   $argv[2]
        set -l cmd   $argv[3..-1]

        switch $modes
            case all
                bind --silent $key $cmd 2>/dev/null
                bind --silent --mode insert  $key $cmd 2>/dev/null
                bind --silent --mode default $key $cmd 2>/dev/null
                bind --silent --mode visual  $key $cmd 2>/dev/null
            case insert
                bind --silent $key $cmd 2>/dev/null
                bind --silent --mode insert $key $cmd 2>/dev/null
            case normal
                bind --silent --mode default $key $cmd 2>/dev/null
            case visual
                bind --silent --mode visual  $key $cmd 2>/dev/null
            case '*'
                bind --silent $key $cmd 2>/dev/null
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⌨️  BASE BINDINGS: Apply fish defaults first                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    switch $bind_mode
        case vi
            # Initialize vi bindings as base
            fish_vi_key_bindings --no-erase 2>/dev/null \
                || fish_vi_key_bindings 2>/dev/null

            # Set initial insert mode
            set --global fish_bind_mode insert

        case emacs
            fish_default_key_bindings

        case default '*'
            fish_default_key_bindings
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🚀 FZF KEY BINDINGS                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$enable_fzf" = 1 && command -q fzf

        # ── Official fzf.fish integration ─────────────────────────────────────
        if functions -q _fzf_search_current_dir
            # PatrickF1/fzf.fish plugin — configure it
            fzf_configure_bindings \
                --directory=\cf \
                --history=\cr \
                --git_log=\cl \
                --git_status=\cs \
                --variables=\cv \
                --processes=\cp 2>/dev/null
        else
            # Manual fzf bindings

            # Ctrl-R → history search (respect atuin/mcfly priority)
            if test "$enable_atuin" = 1 && functions -q _atuin_search_global
                __bind insert \cr '_atuin_search_global'
            else if test "$enable_mcfly" = 1 && command -q mcfly
                __bind insert \cr 'mcfly search'
            else
                # Native fzf history
                function __fzf_history_binding --description "fzf history search"
                    set -l query (commandline)
                    set -l selected (
                        history | fzf --tac --no-sort \
                            --query "$query" \
                            --border-label "  📜 History " \
                            --border rounded \
                            --prompt "  🔍 " \
                            --pointer "▶" \
                            --preview 'echo {}' \
                            --preview-window 'down:2:wrap:border-rounded' \
                            --bind 'ctrl-/:toggle-preview' \
                            --height 40%
                    )
                    if test -n "$selected"
                        commandline --replace -- $selected
                    end
                    commandline -f repaint
                end
                __bind insert \cr '__fzf_history_binding'
            end

            # Ctrl-T → file picker
            function __fzf_file_binding --description "fzf file search"
                set -l selected (
                    fd --type f --hidden --follow \
                        --exclude .git --exclude node_modules \
                        --color always 2>/dev/null |
                    fzf --ansi --multi \
                        --border-label "  📁 Files " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --marker "✓" \
                        --preview 'bat --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}' \
                        --preview-window 'right:50%:border-rounded' \
                        --bind 'ctrl-/:toggle-preview' \
                        --height 70%
                )
                if test -n "$selected"
                    commandline --insert -- (string join ' ' (string escape $selected))
                end
                commandline -f repaint
            end
            __bind insert \ct '__fzf_file_binding'

            # Alt-C → directory jump
            function __fzf_dir_binding --description "fzf directory search"
                set -l selected (
                    fd --type d --hidden --follow \
                        --exclude .git --exclude node_modules \
                        --color always 2>/dev/null |
                    fzf --ansi \
                        --border-label "  📁 Directories " \
                        --border rounded \
                        --prompt "  📂 " \
                        --pointer "▶" \
                        --preview 'eza --icons --color=always --group-directories-first -la {} 2>/dev/null || ls -la {}' \
                        --preview-window 'right:50%:border-rounded' \
                        --height 60%
                )
                if test -n "$selected"
                    cd $selected
                    commandline -f repaint
                end
            end
            __bind insert \ec '__fzf_dir_binding'
        end

        # ── Extra fzf bindings (always) ────────────────────────────────────────

        # Ctrl-G → git status browser
        function __fzf_git_status --description "fzf git status browser"
            command -q git || return
            git rev-parse --is-inside-work-tree 2>/dev/null | grep -q true || return

            set -l selected (
                git -c color.status=always status --short 2>/dev/null |
                fzf --ansi --multi \
                    --border-label "   Git Status " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --marker "✓" \
                    --preview 'git diff --color=always -- {-1} 2>/dev/null | head -100' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --header '  Ctrl-A:add  Ctrl-R:restore  Ctrl-D:diff  ' \
                    --bind 'ctrl-a:execute(git add {-1})+reload(git -c color.status=always status --short)' \
                    --bind 'ctrl-r:execute(git restore {-1})+reload(git -c color.status=always status --short)' \
                    --bind 'ctrl-d:execute(git diff {-1} | bat --language=diff --style=plain || less)' \
                    --height 70% |
                awk '{print $NF}'
            )
            test -n "$selected" && commandline --insert -- $selected
            commandline -f repaint
        end
        __bind insert \cg '__fzf_git_status'

        # Ctrl-K → kill process picker
        function __fzf_kill --description "fzf process killer"
            set -l selected (
                ps aux | tail -n +2 |
                fzf --ansi --multi \
                    --border-label "  💀 Kill Process " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --marker "✓" \
                    --preview 'echo {} | awk "{print \$2}" | xargs ps -p 2>/dev/null' \
                    --preview-window 'down:3:border-rounded' \
                    --header '  Enter:SIGTERM  Ctrl-K:SIGKILL  ' \
                    --bind 'ctrl-k:execute(echo {} | awk "{print \$2}" | xargs kill -9)+reload(ps aux | tail -n +2)' \
                    --height 60% |
                awk '{print $2}'
            )
            if test -n "$selected"
                echo $selected | xargs kill 2>/dev/null
                commandline -f repaint
            end
        end
        __bind insert \ck '__fzf_kill'

        # Alt-E → edit with fzf+nvim
        function __fzf_edit --description "fzf file picker → open in editor"
            set -l editor (set -q VISUAL && echo $VISUAL || echo nvim)
            set -l selected (
                fd --type f --hidden --follow \
                    --exclude .git --exclude node_modules \
                    --color always 2>/dev/null |
                fzf --ansi --multi \
                    --border-label "  ✏️  Edit File " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --height 70%
            )
            test -n "$selected" && $editor $selected
            commandline -f repaint
        end
        __bind insert \ee '__fzf_edit'

        # Ctrl-N → navigate with fzf (zoxide-aware)
        function __fzf_nav --description "fzf directory navigator"
            if test "$enable_zoxide" = 1 && command -q zoxide
                set -l selected (
                    zoxide query --list --score 2>/dev/null |
                    fzf --ansi --no-sort \
                        --border-label "  🚀 Jump To " \
                        --border rounded \
                        --prompt "  " \
                        --pointer "▶" \
                        --preview 'eza --icons --color=always -la {2} 2>/dev/null | head -20' \
                        --preview-window 'right:50%:border-rounded' \
                        --height 50% |
                    awk '{print $2}'
                )
                test -n "$selected" && z $selected
            else
                __fzf_dir_binding
            end
            commandline -f repaint
        end
        __bind insert \cn '__fzf_nav'

        # Ctrl-\ → environment variable browser
        function __fzf_env --description "fzf env var browser"
            set -l selected (
                env | sort |
                fzf --border-label "  🔧 Env Variables " \
                    --border rounded \
                    --prompt "  " \
                    --preview 'echo {} | tr "=" "\n" | tail -n+2 | fold -w 80' \
                    --preview-window 'down:3:wrap:border-rounded' \
                    --height 50% |
                cut -d= -f1
            )
            test -n "$selected" && commandline --insert -- "$$selected"
            commandline -f repaint
        end
        __bind insert \\ '__fzf_env'

        # Alt-S → SSH host picker
        function __fzf_ssh --description "fzf SSH host picker"
            set -l selected (
                begin
                    cat ~/.ssh/config ~/.ssh/config.d/*.conf 2>/dev/null | \
                        grep -i '^Host ' | awk '{print $2}' | grep -v '\*'
                    cat ~/.ssh/known_hosts 2>/dev/null | \
                        grep -v '^\[' | cut -d' ' -f1 | cut -d, -f1
                end | sort -u |
                fzf --border-label "  🔌 SSH Hosts " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --preview 'ssh -G {} 2>/dev/null | grep -E "hostname|user|port" | head -5' \
                    --preview-window 'right:35%:border-rounded' \
                    --height 40%
            )
            test -n "$selected" && commandline --replace "ssh $selected"
            commandline -f repaint
        end
        __bind insert \es '__fzf_ssh'

        # Alt-D → Docker container picker
        function __fzf_docker --description "fzf Docker container selector"
            command -q docker || return
            set -l selected (
                docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null |
                fzf --ansi \
                    --border-label "  🐳 Docker Containers " \
                    --border rounded \
                    --prompt "  " \
                    --pointer "▶" \
                    --preview 'docker inspect {1} 2>/dev/null | python3 -m json.tool | head -30' \
                    --preview-window 'right:45%:border-rounded' \
                    --height 50% |
                awk '{print $1}'
            )
            test -n "$selected" && commandline --insert -- $selected
            commandline -f repaint
        end
        __bind insert \ed '__fzf_docker'

        # Alt-M → man page picker
        function __fzf_man --description "fzf man page browser"
            set -l selected (
                man -k . 2>/dev/null | sort |
                fzf --border-label "  📖 Man Pages " \
                    --border rounded \
                    --prompt "  " \
                    --preview 'man {1} 2>/dev/null | head -80' \
                    --preview-window 'right:55%:border-rounded:wrap' \
                    --height 60% |
                awk '{print $1}'
            )
            test -n "$selected" && man $selected
            commandline -f repaint
        end
        __bind insert \em '__fzf_man'
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⚡ ZOXIDE BINDINGS                                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$enable_zoxide" = 1 && command -q zoxide

        # Alt-Z → interactive zoxide jump
        function __zoxide_jump_binding --description "Interactive zoxide jump"
            if functions -q zi
                zi
            else
                z (
                    zoxide query --list 2>/dev/null |
                    fzf --border-label "  🚀 Zoxide " \
                        --border rounded \
                        --prompt "  " \
                        --preview 'eza --icons --color=always -la {} 2>/dev/null' \
                        --preview-window 'right:50%:border-rounded' \
                        --height 50%
                )
            end
            commandline -f repaint
        end
        __bind insert \ez '__zoxide_jump_binding'
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📝 EDITING BINDINGS — Both insert & normal modes                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Ctrl-A/E → line start/end (emacs-style in vi insert) ─────────────────
    __bind insert \ca 'beginning-of-line'
    __bind insert \ce 'end-of-line'

    # ── Ctrl-W → delete word backwards ────────────────────────────────────────
    __bind insert \cw 'backward-kill-word'

    # ── Ctrl-U → kill to beginning of line ────────────────────────────────────
    __bind insert \cu 'backward-kill-line'

    # ── Ctrl-K → kill to end of line (override if fzf not grabbing it) ────────
    # Already bound to kill-process fzf — skip if fzf enabled
    test "$enable_fzf" = 0 && __bind insert \ck 'kill-line'

    # ── Alt-D → delete word forward ────────────────────────────────────────────
    test "$enable_fzf" = 0 && __bind insert \ed 'kill-word'

    # ── Ctrl-Y → yank (paste last killed text) ────────────────────────────────
    __bind insert \cy 'yank'

    # ── Alt-. → insert last argument ──────────────────────────────────────────
    function __insert_last_arg --description "Insert last argument from history"
        set -l last_cmd (history | head -1)
        set -l last_arg (string split ' ' $last_cmd)[-1]
        commandline --insert -- " $last_arg"
    end
    __bind insert \e. '__insert_last_arg'

    # ── Ctrl-Backspace → delete whole word backwards ───────────────────────────
    __bind insert \e\[3\;5~ 'kill-word'
    __bind insert \b 'backward-kill-word'

    # ── Alt-B / Alt-F → word navigation ───────────────────────────────────────
    __bind insert \eb 'backward-word'
    __bind insert \ef 'forward-word'

    # ── Alt-U / Alt-L → upper/lowercase word ──────────────────────────────────
    function __upcase_word --description "Uppercase current word"
        set -l pos  (commandline --cursor)
        set -l line (commandline)
        # Simple: send to nvim macro... or use fish expand
        commandline -f upcase-word 2>/dev/null
    end
    __bind insert \eu 'upcase-word'
    __bind insert \el 'downcase-word'

    # ── Ctrl-X Ctrl-E → open commandline in editor ────────────────────────────
    function __edit_commandline --description "Edit current commandline in editor"
        set -l editor (set -q VISUAL && echo $VISUAL || echo nvim)
        set -l tmpfile (mktemp --suffix=.fish)
        commandline > $tmpfile
        $editor $tmpfile
        commandline --replace -- (cat $tmpfile)
        rm -f $tmpfile
        commandline -f repaint
    end
    __bind insert \cx\ce '__edit_commandline'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔀 HISTORY NAVIGATION BINDINGS                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Up/Down with prefix search ────────────────────────────────────────────
    __bind all \e\[A 'history-prefix-search-backward'
    __bind all \e\[B 'history-prefix-search-forward'
    __bind all \eOA  'history-prefix-search-backward'
    __bind all \eOB  'history-prefix-search-forward'

    # Vi normal mode: j/k for history with prefix
    if test "$bind_mode" = vi
        bind --silent --mode default k 'history-prefix-search-backward' 2>/dev/null
        bind --silent --mode default j 'history-prefix-search-forward'  2>/dev/null
    end

    # ── Alt-P / Alt-N → explicit history prev/next ────────────────────────────
    __bind insert \ep 'history-prefix-search-backward'
    __bind insert \en 'history-prefix-search-forward'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 CLIPBOARD BINDINGS                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Ctrl-Y → copy commandline to system clipboard
    function __copy_commandline --description "Copy commandline to clipboard"
        set -l content (commandline)
        test -z "$content" && return

        if command -q wl-copy
            echo -n $content | wl-copy 2>/dev/null
            and echo "  Copied to clipboard (Wayland)"
        else if command -q xclip
            echo -n $content | xclip -selection clipboard 2>/dev/null
            and echo "  Copied to clipboard (X11)"
        else if command -q pbcopy
            echo -n $content | pbcopy 2>/dev/null
        end
        commandline -f repaint
    end
    __bind insert \cy '__copy_commandline'

    # Ctrl-V → paste from clipboard into commandline
    function __paste_clipboard --description "Paste from clipboard into commandline"
        set -l content ""
        if command -q wl-paste
            set content (wl-paste --no-newline 2>/dev/null)
        else if command -q xclip
            set content (xclip -selection clipboard -o 2>/dev/null)
        else if command -q pbpaste
            set content (pbpaste 2>/dev/null)
        end

        test -n "$content" && commandline --insert -- $content
        commandline -f repaint
    end
    __bind insert \cv '__paste_clipboard'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  💬 COMMAND INSERTION BINDINGS                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Ctrl-Z → smart background/foreground ─────────────────────────────────
    function __smart_ctrl_z --description "Smart Ctrl-Z: fg if backgrounded, else bg"
        if test (commandline | string trim) = ""
            # Nothing typed: bring back last job
            fg 2>/dev/null
        else
            commandline -f accept-autosuggestion
        end
    end
    __bind insert \cz '__smart_ctrl_z'

    # ── Alt-R → reload fish config ─────────────────────────────────────────────
    function __reload_config --description "Reload fish configuration"
        source ~/.config/fish/config.fish 2>/dev/null
        for f in ~/.config/fish/conf.d/*.fish
            source $f 2>/dev/null
        end
        echo "  Fish config reloaded"
        commandline -f repaint
    end
    __bind insert \er '__reload_config'

    # ── Alt-W → show current directory tree ──────────────────────────────────
    function __show_tree --description "Show directory tree"
        echo ""
        if command -q eza
            eza --tree --level=2 --icons --color=always 2>/dev/null
        else
            find . -maxdepth 2 -print 2>/dev/null | head -40
        end
        commandline -f repaint
    end
    __bind insert \ew '__show_tree'

    # ── Ctrl-/ → toggle inline autosuggestion ────────────────────────────────
    __bind insert \c/ 'toggle-comment'

    # ── Escape (insert mode) → accept suggestion or enter normal mode ─────────
    if test "$bind_mode" = vi
        # Already handled by vi bindings — Escape → normal mode
        # But also accept autosuggestion with right arrow
        __bind insert \e\[C 'forward-char'
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🛠️  ASH-SPECIFIC BINDINGS                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Alt-T → open ASH theme picker ─────────────────────────────────────────
    function __ash_theme_binding --description "Open ASH theme picker"
        commandline --replace -- "ash theme pick"
        commandline -f execute
    end
    __bind insert \et '__ash_theme_binding'

    # ── Alt-A → run ASH doctor ────────────────────────────────────────────────
    function __ash_doctor_binding --description "Run ASH doctor"
        commandline --replace -- "ash doctor quick"
        commandline -f execute
    end
    # Note: \ea might conflict; use F-key instead
    bind --silent \e\[21~ __ash_doctor_binding 2>/dev/null   # F10

    # ── F1 → ASH help ─────────────────────────────────────────────────────────
    function __ash_help_binding --description "Show ASH help"
        commandline --replace -- "ash --help"
        commandline -f execute
    end
    bind --silent \e\[11~ '__ash_help_binding' 2>/dev/null   # F1
    bind --silent \eOP    '__ash_help_binding' 2>/dev/null   # F1 (alternative)

    # ── F2 → toggle ASH mode ──────────────────────────────────────────────────
    function __ash_mode_binding --description "Open ASH mode selector"
        commandline --replace -- "ash mode list"
        commandline -f execute
    end
    bind --silent \e\[12~ '__ash_mode_binding' 2>/dev/null   # F2
    bind --silent \eOQ    '__ash_mode_binding' 2>/dev/null   # F2

    # ── F3 → ASH snapshot create ──────────────────────────────────────────────
    function __ash_snapshot_binding --description "Create ASH snapshot"
        commandline --replace -- "ash snapshot create"
        commandline -f execute
    end
    bind --silent \e\[13~ '__ash_snapshot_binding' 2>/dev/null  # F3
    bind --silent \eOR    '__ash_snapshot_binding' 2>/dev/null  # F3

    # ── F4 → open current directory in nvim ───────────────────────────────────
    function __nvim_here_binding --description "Open nvim in current directory"
        commandline --replace -- "nvim ."
        commandline -f execute
    end
    bind --silent \e\[14~ '__nvim_here_binding' 2>/dev/null     # F4
    bind --silent \eOS    '__nvim_here_binding' 2>/dev/null     # F4

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 SMART COMPLETION BINDINGS                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Tab → smart expand + complete ────────────────────────────────────────
    # (fish handles this natively — we just ensure it's set)
    bind --silent \t 'complete' 2>/dev/null

    # ── Shift-Tab → previous completion ─────────────────────────────────────
    bind --silent \e\[Z 'complete-and-search' 2>/dev/null

    # ── Ctrl-Space → accept autosuggestion word-by-word ──────────────────────
    function __accept_suggestion_word --description "Accept one word of autosuggestion"
        commandline -f forward-word
    end
    bind --silent \e\  '__accept_suggestion_word' 2>/dev/null

    # ── Right arrow → full autosuggestion accept ─────────────────────────────
    __bind insert \e\[C 'forward-char'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 VI NORMAL MODE EXTRA BINDINGS                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test "$bind_mode" = vi

        # ── Leader key sequences (,) ───────────────────────────────────────────
        # ,f → fzf file
        # ,g → git status fzf
        # ,d → directory fzf
        # ,h → history fzf

        function __vi_leader_f --description "Vi leader: fzf files"
            test "$enable_fzf" = 1 && __fzf_file_binding
        end
        function __vi_leader_g --description "Vi leader: git fzf"
            test "$enable_fzf" = 1 && __fzf_git_status
        end
        function __vi_leader_d --description "Vi leader: dir fzf"
            test "$enable_fzf" = 1 && __fzf_dir_binding
        end

        bind --silent --mode default ',f' '__vi_leader_f' 2>/dev/null
        bind --silent --mode default ',g' '__vi_leader_g' 2>/dev/null
        bind --silent --mode default ',d' '__vi_leader_d' 2>/dev/null

        # ── Yank line to clipboard in normal mode ──────────────────────────────
        function __vi_yank_line --description "Yank line to system clipboard"
            set -l line (commandline)
            if command -q wl-copy
                echo -n $line | wl-copy 2>/dev/null
            else if command -q xclip
                echo -n $line | xclip -selection clipboard 2>/dev/null
            end
            commandline -f repaint
        end
        bind --silent --mode default 'Y' '__vi_yank_line' 2>/dev/null

        # ── gg / G → beginning / end of history ───────────────────────────────
        bind --silent --mode default 'gg' 'history-prefix-search-backward' 2>/dev/null
        bind --silent --mode default 'G'  'history-prefix-search-forward'  2>/dev/null

        # ── u → undo ──────────────────────────────────────────────────────────
        bind --silent --mode default 'u' 'undo' 2>/dev/null

        # ── Ctrl-R in normal mode → redo ──────────────────────────────────────
        bind --silent --mode default \cr 'redo' 2>/dev/null

        # ── / → search history (fzf or prefix) ───────────────────────────────
        if test "$enable_atuin" = 1 && functions -q _atuin_search_global
            bind --silent --mode default '/' '_atuin_search_global' 2>/dev/null
        else if test "$enable_fzf" = 1
            bind --silent --mode default '/' '__fzf_history_binding' 2>/dev/null
        end

        # ── ci" cs' etc → handled by fish-shell-vim plugin if installed ───────

        # ── gf → open file under cursor ──────────────────────────────────────
        function __vi_gf --description "Open file under cursor in editor"
            set -l word (commandline -t)
            test -f $word && begin
                set -l editor (set -q VISUAL && echo $VISUAL || echo nvim)
                $editor $word
            end
        end
        bind --silent --mode default 'gf' '__vi_gf' 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔔 NOTIFICATION BINDINGS                                               ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Ctrl-B → send desktop notification when done ─────────────────────────
    function __notify_done --description "Run command and notify on completion"
        set -l cmd (commandline)
        test -z "$cmd" && return

        commandline --replace -- "begin; $cmd; end; and notify-send '✅ Done' '$cmd' || notify-send '❌ Failed' '$cmd'"
        commandline -f execute
    end
    __bind insert \cb '__notify_done'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖥️  TERMINAL CONTROL BINDINGS                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Ctrl-L → clear screen (keep commandline) ─────────────────────────────
    function __clear_screen --description "Clear screen and redraw prompt"
        clear
        commandline -f repaint
    end
    __bind all \cl '__clear_screen'

    # ── Ctrl-Q → quote commandline ────────────────────────────────────────────
    function __quote_commandline --description "Wrap commandline in quotes"
        set -l content (commandline)
        commandline --replace -- (string escape $content)
    end
    __bind insert \cq '__quote_commandline'

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🧹 CLEANUP                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    functions --erase __bind 2>/dev/null

end
