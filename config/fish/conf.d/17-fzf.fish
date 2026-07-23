# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — FZF Ultra Configuration                            ║
# ║  Fuzzy finder with Catppuccin theming, advanced previews & keybinds        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require fzf ───────────────────────────────────────────────────────
command -q fzf || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_fzf_loaded && exit 0
set --global _ash_fzf_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 THEME: Dynamic color sync with ASH theme engine                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_fzf_get_colors --description "Generate FZF colors from current ASH theme"
    # Try to read from ASH theme state
    set -l state_file "$HOME/.local/share/ash/state/current-theme.json"
    set -l colors_file "$HOME/.config/ash/cache/fzf-colors.conf"

    # Fast path: use cached colors if fresh (< 5s old)
    if test -f $colors_file
        set -l cache_age (math (date +%s) - (stat -c %Y $colors_file 2>/dev/null; or echo 0))
        if test $cache_age -lt 5
            cat $colors_file
            return
        end
    end

    # Default: Catppuccin Mocha palette
    set -l bg      "#1e1e2e"
    set -l bg_alt  "#313244"
    set -l fg      "#cdd6f4"
    set -l fg_alt  "#a6adc8"
    set -l accent  "#cba6f7"
    set -l green   "#a6e3a1"
    set -l yellow  "#f9e2af"
    set -l red     "#f38ba8"
    set -l cyan    "#89dceb"
    set -l blue    "#89b4fa"

    # Try to source dynamic colors from ASH theme engine
    if test -f $state_file && command -q jq
        set -l theme_colors (jq -r '
            .colors |
            "bg=\(.base // "#1e1e2e")\n"         +
            "bg_alt=\(.surface0 // "#313244")\n"  +
            "fg=\(.text // "#cdd6f4")\n"          +
            "fg_alt=\(.subtext1 // "#a6adc8")\n"  +
            "accent=\(.mauve // "#cba6f7")\n"     +
            "green=\(.green // "#a6e3a1")\n"      +
            "yellow=\(.yellow // "#f9e2af")\n"    +
            "red=\(.red // "#f38ba8")\n"          +
            "cyan=\(.sky // "#89dceb")\n"         +
            "blue=\(.blue // "#89b4fa")"
        ' $state_file 2>/dev/null)

        for pair in $theme_colors
            set -l key (string split --max 1 = $pair)[1]
            set -l val (string split --max 1 = $pair)[2]
            switch $key
                case bg;      set bg      $val
                case bg_alt;  set bg_alt  $val
                case fg;      set fg      $val
                case fg_alt;  set fg_alt  $val
                case accent;  set accent  $val
                case green;   set green   $val
                case yellow;  set yellow  $val
                case red;     set red     $val
                case cyan;    set cyan    $val
                case blue;    set blue    $val
            end
        end
    end

    set -l color_string \
        "bg:$bg,bg+:$bg_alt,"\
        "fg:$fg,fg+:$fg,"\
        "hl:$accent,hl+:$accent,"\
        "info:$yellow,"\
        "prompt:$blue,"\
        "pointer:$accent,"\
        "marker:$green,"\
        "spinner:$cyan,"\
        "header:$fg_alt,"\
        "border:$bg_alt,"\
        "label:$fg_alt,"\
        "query:$fg,"\
        "gutter:$bg"

    set -l result (string join '' $color_string)

    # Cache result
    echo $result > $colors_file 2>/dev/null

    echo $result
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 PREVIEW COMMANDS                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Unified preview command: auto-detects file type and picks best previewer
set -l __fzf_preview_cmd '
    file="$1"
    if [ -d "$file" ]; then
        if command -v eza >/dev/null 2>&1; then
            eza --tree --level=2 --icons --color=always "$file" 2>/dev/null
        else
            ls -la --color=always "$file" 2>/dev/null
        fi
    elif [ -f "$file" ]; then
        mime=$(file --mime-type -b "$file" 2>/dev/null)
        case "$mime" in
            image/*)
                if command -v chafa >/dev/null 2>&1; then
                    chafa --size=80x40 --colors=256 "$file" 2>/dev/null
                elif command -v viu >/dev/null 2>&1; then
                    viu -t -w 80 "$file" 2>/dev/null
                else
                    file "$file"
                fi
                ;;
            video/*)
                if command -v ffprobe >/dev/null 2>&1; then
                    ffprobe -v quiet -print_format json -show_streams "$file" 2>/dev/null | python3 -m json.tool
                else
                    file "$file"
                fi
                ;;
            application/pdf)
                if command -v pdftotext >/dev/null 2>&1; then
                    pdftotext -l 3 "$file" - 2>/dev/null | head -100
                else
                    file "$file"
                fi
                ;;
            application/zip|application/x-tar|application/x-bzip2|application/gzip)
                if command -v bsdtar >/dev/null 2>&1; then
                    bsdtar -tf "$file" 2>/dev/null | head -50
                fi
                ;;
            *)
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers,changes,header \
                        --line-range=:300 "$file" 2>/dev/null
                else
                    head -300 "$file" 2>/dev/null
                fi
                ;;
        esac
    else
        echo "No preview available"
    fi
'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  CORE FZF DEFAULT OPTIONS                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -l _fzf_colors (__ash_fzf_get_colors)

set --export FZF_DEFAULT_OPTS "\
    --ansi \
    --cycle \
    --reverse \
    --border rounded \
    --border-label '' \
    --padding 1,2 \
    --margin 2,4 \
    --info inline-right \
    --prompt '  ' \
    --pointer '▶' \
    --marker '✓' \
    --separator '─' \
    --scrollbar '│' \
    --ellipsis '…' \
    --height 70% \
    --min-height 20 \
    --tabstop 4 \
    --multi \
    --color '$_fzf_colors' \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-u:preview-page-up' \
    --bind 'ctrl-d:preview-page-down' \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-x:deselect-all' \
    --bind 'ctrl-t:toggle-all' \
    --bind 'ctrl-y:execute-silent(echo -n {+} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
    --bind 'ctrl-e:execute(nvim {+} </dev/tty >/dev/tty 2>&1)' \
    --bind 'ctrl-o:execute-silent(xdg-open {})' \
    --bind 'f2:toggle-preview-wrap' \
    --bind 'f3:toggle-sort' \
    --bind 'pgup:preview-page-up' \
    --bind 'pgdn:preview-page-down' \
    --bind 'shift-up:preview-up' \
    --bind 'shift-down:preview-down' \
    --bind 'alt-up:prev-history' \
    --bind 'alt-down:next-history' \
    --bind '?:toggle-preview' \
    --bind 'start:reload-sync(true)+clear-query' \
    --header-first \
"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 FILE FINDING: fd or find fallback                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

if command -q fd
    set --export FZF_DEFAULT_COMMAND \
        'fd --type f --hidden --follow --exclude .git --exclude node_modules \
             --exclude .cache --exclude __pycache__ --exclude target \
             --exclude .next --exclude dist --color always 2>/dev/null'

    set --export FZF_ALT_C_COMMAND \
        'fd --type d --hidden --follow --exclude .git --exclude node_modules \
             --exclude .cache --exclude __pycache__ --color always 2>/dev/null'
else
    set --export FZF_DEFAULT_COMMAND \
        'find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" \
                -not -path "*/.cache/*" 2>/dev/null'

    set --export FZF_ALT_C_COMMAND \
        'find . -type d -not -path "*/.git/*" -not -path "*/node_modules/*" \
                2>/dev/null'
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📂 CTRL-T: File picker with rich preview                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --export FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

set --export FZF_CTRL_T_OPTS "\
    --preview 'bash -c '"'"'$__fzf_preview_cmd'"'"' _ {}' \
    --preview-window 'right:55%:border-rounded:wrap' \
    --border-label '  Files ' \
    --header '  ctrl-e:nvim  ctrl-o:open  ctrl-y:copy  ctrl-/:preview  ' \
    --bind 'ctrl-e:execute(nvim {+} </dev/tty >/dev/tty)' \
    --bind 'enter:accept' \
"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📂 ALT-C: Directory picker with tree preview                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --export FZF_ALT_C_OPTS "\
    --preview 'bash -c '"'"'$__fzf_preview_cmd'"'"' _ {}' \
    --preview-window 'right:50%:border-rounded' \
    --border-label '  Directories ' \
    --header '  Enter:cd  ctrl-o:open  ctrl-y:copy path  ' \
"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📜 CTRL-R: History picker — smart deduplication                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --export FZF_CTRL_R_OPTS "\
    --preview 'echo -e \"Command:\n\n\" && echo {}' \
    --preview-window 'down:3:wrap:hidden' \
    --border-label '  History ' \
    --header '  Enter:run  ctrl-e:edit  ctrl-y:copy  ctrl-/:preview  ' \
    --scheme history \
    --no-multi \
    --bind 'ctrl-y:execute-silent(echo -n {} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)+abort' \
    --bind 'ctrl-e:execute(echo -n {} | nvim -c \"set filetype=sh\" - </dev/tty >/dev/tty)' \
"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔑 KEY BINDINGS SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Source official fzf fish keybindings if plugin is installed
if functions -q fzf_key_bindings
    fzf_key_bindings
end

# Check for fzf.fish plugin (PatrickF1/fzf.fish)
if functions -q _fzf_search_current_dir
    # fzf.fish plugin is loaded — configure it
    set --global fzf_preview_dir_cmd "eza --all --color=always --icons --level=2 --tree"
    set --global fzf_fd_opts "--hidden --exclude=.git --exclude=node_modules"
    set --global fzf_history_opts "--with-nth=4.." "--preview-window=down:3:wrap"

    # Key bindings for fzf.fish plugin
    # Ctrl-F: files   Ctrl-R: history   Ctrl-L: git log   Ctrl-V: variables
    fzf_configure_bindings \
        --directory=\cf \
        --history=\cr \
        --git_log=\cl \
        --git_status=\cs \
        --variables=\cv \
        --processes=\cp
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 ADVANCED FZF FUNCTIONS                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── fzf-git: Git-aware fuzzy finder ─────────────────────────────────────────

function fzf_git_status --description "Fuzzy search git status files"
    command -q git || return 1
    git -C . rev-parse 2>/dev/null || begin; echo "Not a git repo"; return 1; end

    set -l selected (
        git -c color.status=always status --short |
        fzf --ansi --multi \
            --border-label '  Git Status ' \
            --preview 'git diff --color=always -- {-1} | head -200' \
            --preview-window 'right:55%:wrap:border-rounded' \
            --header '  enter:select  ctrl-r:restore  ctrl-a:add  ctrl-d:diff  ' \
            --bind 'ctrl-a:execute(git add {-1})+reload(git -c color.status=always status --short)' \
            --bind 'ctrl-r:execute(git restore {-1})+reload(git -c color.status=always status --short)' \
            --bind 'ctrl-d:execute(git diff {-1} | less -R)' \
        | awk '{print $NF}'
    )
    test -n "$selected" && echo $selected
end

# ─── fzf-process: Interactive process killer ─────────────────────────────────

function fzf_kill_process --description "Fuzzy search and kill processes"
    set -l signal $argv[1]
    test -z "$signal" && set signal SIGTERM

    set -l pid (
        ps aux |
        tail -n +2 |
        fzf --multi \
            --border-label "  Kill Process ($signal) " \
            --header '  enter:kill  ctrl-k:SIGKILL  ctrl-9:SIGKILL  ' \
            --preview 'ps -p {2} -o pid,ppid,user,stat,vsz,rss,time,command 2>/dev/null' \
            --preview-window 'down:4:wrap:border-rounded' \
            --bind "ctrl-k:execute(kill -9 {2})+reload(ps aux | tail -n +2)" \
        | awk '{print $2}'
    )

    if test -n "$pid"
        for p in $pid
            kill -s $signal $p 2>/dev/null
            and echo "  Sent $signal to PID $p"
            or echo "  Failed to kill PID $p"
        end
    end
end

# ─── fzf-cd: Smart directory jump with preview ───────────────────────────────

function fzf_cd --description "Fuzzy directory navigation with tree preview"
    set -l selected

    if command -q fd
        set selected (
            fd --type d --hidden --follow \
               --exclude .git --exclude node_modules \
               --exclude .cache --color always 2>/dev/null |
            fzf --ansi \
                --border-label '  Navigate ' \
                --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}' \
                --preview-window 'right:50%:border-rounded' \
                --header '  Enter:cd  ctrl-o:open in files  '
        )
    else
        set selected (
            find . -type d -not -path '*/.git/*' 2>/dev/null |
            fzf --border-label '  Navigate ' \
                --preview 'ls -la {}' \
                --preview-window 'right:50%:border-rounded'
        )
    end

    test -n "$selected" && cd $selected
end

# ─── fzf-edit: Multi-file editor picker ──────────────────────────────────────

function fzf_edit --description "Fuzzy file search and open in editor"
    set -l editor (set -q VISUAL; and echo $VISUAL; or set -q EDITOR; and echo $EDITOR; or echo nvim)

    set -l selected (
        eval $FZF_DEFAULT_COMMAND |
        fzf --ansi --multi \
            --border-label '  Edit Files ' \
            --preview 'bash -c "
                if command -v bat >/dev/null; then
                    bat --color=always --style=numbers,changes --line-range=:200 {} 2>/dev/null
                else
                    cat {}
                fi
            "' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header "  Enter:open in $editor  ctrl-e:split edit  "
    )

    test -n "$selected" && $editor $selected
end

# ─── fzf-ripgrep: Live interactive grep ──────────────────────────────────────

function fzf_rg --description "Interactive ripgrep with live results"
    command -q rg || begin; echo "ripgrep not installed"; return 1; end

    set -l initial_query $argv[1]
    set -l rg_cmd "rg --column --line-number --no-heading --color=always --smart-case"

    set -l result (
        FZF_DEFAULT_COMMAND="$rg_cmd -- '$initial_query' ." \
        fzf --ansi \
            --disabled \
            --query "$initial_query" \
            --border-label '  Live Search ' \
            --header '  Type to search  Enter:open  ctrl-o:open in browser  ' \
            --preview 'bash -c "
                file=$(echo {} | cut -d: -f1)
                line=$(echo {} | cut -d: -f2)
                if command -v bat >/dev/null; then
                    bat --color=always --style=numbers,changes \
                        --highlight-line $line \
                        --line-range $(math $line - 5):$(math $line + 30) \
                        \"$file\" 2>/dev/null
                else
                    sed -n \"$((line-5)),$((line+30))p\" \"$file\"
                fi
            "' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --bind "change:reload($rg_cmd -- {q} . 2>/dev/null || true)" \
            --bind "ctrl-o:execute-silent(xdg-open {1} 2>/dev/null)" \
            --delimiter :
    )

    if test -n "$result"
        set -l file (echo $result | cut -d: -f1)
        set -l line (echo $result | cut -d: -f2)
        set -l editor (set -q VISUAL; and echo $VISUAL; or echo nvim)
        $editor +"$line" $file
    end
end

# ─── fzf-ssh: Smart SSH connection picker ────────────────────────────────────

function fzf_ssh --description "Fuzzy SSH host selector with connection info"
    set -l hosts (
        # Parse SSH config hosts
        cat ~/.ssh/config ~/.ssh/config.d/*.conf 2>/dev/null |
        grep -i "^Host " | awk '{print $2}' | grep -v '\*' |

        # Also pull from known_hosts
        cat ~/.ssh/known_hosts 2>/dev/null |
        grep -v '^\[' | cut -d' ' -f1 | cut -d, -f1 |
        sort -u
    )

    set -l selected (
        echo $hosts |
        tr ' ' '\n' | sort -u |
        fzf --border-label '  SSH Connect ' \
            --preview 'ssh -G {} 2>/dev/null | grep -E "hostname|user|port|identityfile" | head -10' \
            --preview-window 'right:40%:border-rounded' \
            --header '  Enter:connect  '
    )

    test -n "$selected" && ssh $selected
end

# ─── fzf-docker: Docker container manager ────────────────────────────────────

function fzf_docker --description "Fuzzy Docker container management"
    command -q docker || begin; echo "Docker not installed"; return 1; end

    set -l action $argv[1]
    test -z "$action" && set action exec

    set -l container (
        docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" |
        tail -n +2 |
        fzf --border-label '  Docker Containers ' \
            --header-lines 0 \
            --preview 'docker inspect {1} | python3 -m json.tool | head -50' \
            --preview-window 'right:50%:border-rounded' \
            --header "  Enter:$action  ctrl-l:logs  ctrl-k:kill  ctrl-s:stop  " \
            --bind 'ctrl-l:execute(docker logs -f {1} | less -R)' \
            --bind 'ctrl-k:execute(docker kill {1})+reload(docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" | tail -n +2)' \
            --bind 'ctrl-s:execute(docker stop {1})+reload(docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" | tail -n +2)' \
        | awk '{print $1}'
    )

    if test -n "$container"
        switch $action
            case exec
                docker exec -it $container sh -c 'bash 2>/dev/null || sh'
            case logs
                docker logs -f $container
            case stop
                docker stop $container
            case kill
                docker kill $container
            case '*'
                docker $action $container
        end
    end
end

# ─── fzf-env: Environment variable browser ───────────────────────────────────

function fzf_env --description "Fuzzy browse and copy environment variables"
    set -l selected (
        env | sort |
        fzf --border-label '  Environment ' \
            --preview 'echo {} | tr "=" "\n" | tail -n +2' \
            --preview-window 'down:3:wrap:border-rounded' \
            --header '  Enter:copy value  ctrl-e:copy key=value  ' \
            --bind 'ctrl-e:execute-silent(echo {} | wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null)' \
    )

    if test -n "$selected"
        set -l val (echo $selected | cut -d= -f2-)
        echo -n $val | wl-copy 2>/dev/null; or echo -n $val | xclip -selection clipboard 2>/dev/null
        echo "Copied: $val"
    end
end

# ─── fzf-tldr: Interactive tldr pages ────────────────────────────────────────

function fzf_tldr --description "Fuzzy search tldr command pages"
    command -q tldr || begin; echo "tldr not installed (npm i -g tldr)"; return 1; end

    set -l cmd (
        tldr --list 2>/dev/null |
        fzf --border-label '  TLDR Pages ' \
            --preview 'tldr --color {} 2>/dev/null' \
            --preview-window 'right:60%:border-rounded:wrap' \
            --header '  Enter:select and copy  ctrl-o:open  '
    )

    test -n "$cmd" && echo $cmd
end

# ─── fzf-man: Interactive man page search ────────────────────────────────────

function fzf_man --description "Fuzzy search man pages"
    set -l page (
        man -k . 2>/dev/null |
        sort |
        fzf --border-label '  Man Pages ' \
            --preview 'man {1} 2>/dev/null | head -80' \
            --preview-window 'right:55%:border-rounded:wrap' \
            --header '  Enter:open page  ' \
        | awk '{print $1}'
    )

    test -n "$page" && man $page
end

# ─── fzf-theme: ASH theme picker via fzf ─────────────────────────────────────

function fzf_ash_theme --description "Pick and apply ASH theme with preview"
    command -q ash || begin; echo "ASH CLI not found"; return 1; end

    set -l themes_dir "$HOME/.config/ash/themes"
    test -d $themes_dir || return 1

    set -l selected (
        find $themes_dir -name "*.conf" -o -name "theme.conf" 2>/dev/null |
        xargs -I{} dirname {} |
        sort -u |
        xargs -I{} basename {} |
        fzf --border-label '  ASH Themes ' \
            --preview 'cat "$HOME/.config/ash/themes/{}/colors.json" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "No preview"' \
            --preview-window 'right:40%:border-rounded' \
            --header '  Enter:apply  ctrl-p:preview only  '
    )

    test -n "$selected" && ash theme apply $selected
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  KEY BINDINGS                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Only bind if NOT using fzf.fish plugin (to avoid conflicts)
if not functions -q _fzf_search_current_dir
    # Ctrl-F → file picker
    bind \cf fzf_edit

    # Ctrl-G → git status
    bind \cg fzf_git_status

    # Alt-K → kill process
    bind \ek 'fzf_kill_process'

    # Alt-C → cd (override default if needed)
    bind \ec fzf_cd

    # Alt-E → env browser
    bind \ee fzf_env

    # Alt-M → man pages
    bind \em fzf_man

    # Alt-T → ASH theme picker
    bind \et fzf_ash_theme
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔃 THEME SYNC: Auto-refresh FZF colors on ASH theme change                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_fzf_on_theme_change --on-event ash_theme_changed \
    --description "Refresh FZF colors when ASH theme changes"

    # Invalidate color cache
    rm -f "$HOME/.config/ash/cache/fzf-colors.conf" 2>/dev/null

    # Recompute and export
    set -l new_colors (__ash_fzf_get_colors)
    set --global --export FZF_DEFAULT_OPTS (
        string replace --regex -- '--color [^ ]+' "--color $new_colors" $FZF_DEFAULT_OPTS
    )
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 ABBREVIATIONS for FZF functions                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add fzcd    'fzf_cd'
abbr --add fzed    'fzf_edit'
abbr --add fzrg    'fzf_rg'
abbr --add fzgit   'fzf_git_status'
abbr --add fzkill  'fzf_kill_process'
abbr --add fzssh   'fzf_ssh'
abbr --add fzdck   'fzf_docker'
abbr --add fzenv   'fzf_env'
abbr --add fzman   'fzf_man'
abbr --add fztldr  'fzf_tldr'
abbr --add fztheme 'fzf_ash_theme'