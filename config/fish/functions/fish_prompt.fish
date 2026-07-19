# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_prompt Ultra                                  ║
# ║  Dynamic multi-segment prompt with git, toolchain, jobs & ASH integration  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_prompt --description "ASH ultra multi-segment prompt"

    # ── Capture exit code FIRST (before anything else runs) ───────────────────
    set -l last_status $status
    set -l last_pipestatus $pipestatus

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLOR RESOLUTION                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_c --description "Resolve color from ASH theme"
        set -l key "ASH_COLOR_"(string upper $argv[1])
        set -l fallback $argv[2]
        if set -q $key
            set_color (string replace '#' '' $$key) 2>/dev/null && return
        end
        set_color $fallback 2>/dev/null
    end

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)

    set -l COL_USER    (__pr_c mauve   magenta)
    set -l COL_ROOT    (__pr_c red     red)
    set -l COL_HOST    (__pr_c blue    blue)
    set -l COL_DIR     (__pr_c blue    blue)
    set -l COL_GIT     (__pr_c mauve   magenta)
    set -l COL_GIT_OK  (__pr_c green   green)
    set -l COL_GIT_MOD (__pr_c yellow  yellow)
    set -l COL_GIT_BAD (__pr_c red     red)
    set -l COL_OK      (__pr_c green   green)
    set -l COL_ERR     (__pr_c red     red)
    set -l COL_JOBS    (__pr_c peach   FF9F43)
    set -l COL_VENV    (__pr_c teal    94e2d5)
    set -l COL_CONDA   (__pr_c green   green)
    set -l COL_NODE    (__pr_c green   green)
    set -l COL_RUST    (__pr_c peach   FF9F43)
    set -l COL_GO      (__pr_c sky     89dceb)
    set -l COL_JAVA    (__pr_c yellow  yellow)
    set -l COL_NHOST   (__pr_c red     red)
    set -l COL_KUBE    (__pr_c blue    blue)
    set -l COL_DOCKER  (__pr_c sky     89dceb)
    set -l COL_ASH     (__pr_c lavender b4befe)
    set -l COL_PRIV    (__pr_c red     red)
    set -l COL_SUDO    (__pr_c red     red)
    set -l COL_TIME    (__pr_c subtext0 a6adc8)
    set -l COL_CHAR_OK (__pr_c green   green)
    set -l COL_CHAR_ERR (__pr_c red    red)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📍 SEGMENTS COLLECTION                                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l prompt_parts

    # ── Segment builder ───────────────────────────────────────────────────────
    function __seg --description "Add a colored segment to prompt parts"
        set -l color $argv[1]
        set -l icon  $argv[2]
        set -l text  $argv[3]
        set -l extra $argv[4]   # optional: extra text in dim

        set -g _seg_parts $color"$icon $text"(test -n "$extra" && echo " $DIM$extra$R")$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔱 SEGMENT: SSH / Remote indicator                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
        set --append prompt_parts \
            $COL_NHOST" SSH"$DIM"@"$COL_NHOST(hostname -s 2>/dev/null)$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  👤 SEGMENT: User@Host (only when relevant)                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l show_user 0

    # Show user if: root, SSH, or USER differs from default
    if test (id -u) -eq 0
        set --append prompt_parts $BOLD$COL_ROOT" ROOT"$R
        set show_user 1
    else if set -q SSH_CONNECTION
        set --append prompt_parts \
            $COL_USER(id -un)$DIM"@"$COL_HOST(hostname -s 2>/dev/null)$R
        set show_user 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 SEGMENT: Current Directory                                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_dir --description "Format current directory"
        set -l cwd (pwd)
        set -l home $HOME

        # Shorten home
        set cwd (string replace $home "~" $cwd)

        # Git root shortening: show repo/...relative-path
        if command -q git
            set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
            if test -n "$git_root"
                set -l git_name (basename $git_root)
                set -l rel_path (string replace $git_root "" $cwd)
                if test -z "$rel_path"
                    echo " $git_name"
                else
                    echo " $git_name$DIM$rel_path$COL_DIR"
                end
                return
            end
        end

        # Smart truncation
        set -l parts (string split '/' $cwd)
        set -l count (count $parts)

        if test $count -le 4
            echo $cwd
            return
        end

        # Show: ~/…/parent/current
        set -l last2 $parts[-2..-1]
        echo "~/$DIM…$COL_DIR/"(string join '/' $last2)
    end

    set --append prompt_parts $BOLD$COL_DIR"  "(__pr_dir)$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║   SEGMENT: Git Status                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_git --description "Git status segment"
        command -q git || return
        set -l git_dir (git rev-parse --git-dir 2>/dev/null)
        test -z "$git_dir" && return

        # Branch / detached HEAD / bisect / merge / rebase state
        set -l branch ""
        set -l state  ""

        if test -f "$git_dir/BISECT_LOG"
            set state " BISECT"
        else if test -f "$git_dir/MERGE_HEAD"
            set state " MERGE"
        else if test -d "$git_dir/rebase-merge" -o -d "$git_dir/rebase-apply"
            set state " REBASE"
            set -l rb_head "$git_dir/rebase-merge/head-name"
            test -f $rb_head && set branch (cat $rb_head | sed 's|refs/heads/||')
        else if test -f "$git_dir/CHERRY_PICK_HEAD"
            set state " CHERRY"
        else if test -f "$git_dir/REVERT_HEAD"
            set state " REVERT"
        end

        # Branch name
        if test -z "$branch"
            set branch (git branch --show-current 2>/dev/null)
            if test -z "$branch"
                set branch $DIM(git rev-parse --short HEAD 2>/dev/null)$COL_GIT
                set branch "  $branch"
            end
        end

        # Upstream divergence
        set -l ahead  (git rev-list @{u}..HEAD 2>/dev/null | wc -l | string trim)
        set -l behind (git rev-list HEAD..@{u} 2>/dev/null | wc -l | string trim)

        set -l upstream ""
        test "$ahead"  -gt 0 2>/dev/null && set upstream "$upstream$COL_GIT_OK⬆$ahead$COL_GIT"
        test "$behind" -gt 0 2>/dev/null && set upstream "$upstream$COL_GIT_BAD⬇$behind$COL_GIT"

        # Working tree status (porcelain v2 for speed)
        set -l st (git status --porcelain 2>/dev/null)
        set -l staged    (echo $st | grep -c '^[MADRC]')
        set -l modified  (echo $st | grep -c '^.[MADRC]')
        set -l untracked (echo $st | grep -c '^??')
        set -l conflicted (echo $st | grep -c '^(DD|AU|UD|UA|DU|AA|UU)')
        set -l stashed   (git stash list 2>/dev/null | wc -l | string trim)

        # Status icons
        set -l icons ""
        test "$staged"    -gt 0 2>/dev/null && set icons "$icons$COL_GIT_OK●$staged "
        test "$modified"  -gt 0 2>/dev/null && set icons "$icons$COL_GIT_MOD✎$modified "
        test "$untracked" -gt 0 2>/dev/null && set icons "$icons$DIM?$untracked "
        test "$conflicted" -gt 0 2>/dev/null && set icons "$icons$COL_GIT_BAD!$conflicted "
        test "$stashed"   -gt 0 2>/dev/null && set icons "$icons$DIM⚑$stashed "

        # Determine color
        set -l git_color $COL_GIT_OK
        test $modified  -gt 0 2>/dev/null && set git_color $COL_GIT_MOD
        test $conflicted -gt 0 2>/dev/null && set git_color $COL_GIT_BAD

        printf "%s %s%s%s%s%s%s" \
            $git_color \
            "  $branch" \
            (test -n "$state"    && echo "$COL_GIT_BAD$state") \
            (test -n "$upstream" && echo " $upstream") \
            (test -n "$icons"    && echo " $icons") \
            $R ""
    end

    set -l _git_seg (__pr_git)
    test -n "$_git_seg" && set --append prompt_parts $_git_seg

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🐍 SEGMENT: Python Virtual Environment                                 ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if set -q VIRTUAL_ENV
        set -l venv_name (basename $VIRTUAL_ENV)
        # Strip common suffixes
        set venv_name (string replace -r '^\.(venv|env)$' 'venv' $venv_name)
        set --append prompt_parts $COL_VENV"  $venv_name"$R
    else if set -q CONDA_DEFAULT_ENV && test "$CONDA_DEFAULT_ENV" != ""
        test "$CONDA_DEFAULT_ENV" != base && \
            set --append prompt_parts $COL_CONDA"  $CONDA_DEFAULT_ENV"$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⬢  SEGMENT: Node.js version (only in JS projects)                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_node --description "Node.js version segment"
        # Only show in Node project directories
        set -l is_node_project 0
        for marker in package.json .nvmrc .node-version
            if test -f $marker
                set is_node_project 1
                break
            end
        end
        test $is_node_project -eq 0 && return

        # Get version from node or fnm
        set -l node_ver ""
        if command -q node
            set node_ver (node --version 2>/dev/null | string replace 'v' '')
        else if command -q fnm
            set node_ver (fnm current 2>/dev/null | string replace 'v' '')
        end

        test -n "$node_ver" && echo "⬢ $node_ver"
    end

    set -l _node_seg (__pr_node)
    test -n "$_node_seg" && set --append prompt_parts $COL_NODE"  $_node_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🦀 SEGMENT: Rust toolchain (in Cargo projects)                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_rust --description "Rust toolchain segment"
        test -f Cargo.toml || return
        command -q rustc || return

        set -l toolchain ""

        if test -f rust-toolchain.toml && command -q toml2json
            set toolchain (toml2json rust-toolchain.toml 2>/dev/null | \
                jq -r '.toolchain.channel // empty' 2>/dev/null)
        else if test -f rust-toolchain
            set toolchain (string trim < rust-toolchain)
        end

        if test -z "$toolchain"
            set toolchain (rustup show active-toolchain 2>/dev/null | awk '{print $1}' | \
                string replace -r '-.*' '')
        end

        test -n "$toolchain" && echo "🦀 $toolchain"
    end

    set -l _rust_seg (__pr_rust)
    test -n "$_rust_seg" && set --append prompt_parts $COL_RUST"  $_rust_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🐹 SEGMENT: Go version (in Go projects)                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_go --description "Go version segment"
        test -f go.mod || test -f go.work || return
        command -q go || return
        set -l ver (go version 2>/dev/null | awk '{print $3}' | string replace 'go' '')
        test -n "$ver" && echo " $ver"
    end

    set -l _go_seg (__pr_go)
    test -n "$_go_seg" && set --append prompt_parts $COL_GO"  $_go_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ☕ SEGMENT: Java version (in Java projects)                            ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_java --description "Java version segment"
        for marker in pom.xml build.gradle build.gradle.kts .sdkmanrc
            test -f $marker || continue
            command -q java || return
            set -l ver (java -version 2>&1 | head -1 | \
                grep -oP '\d+\.\d+\.[\d_]+' | head -1)
            test -n "$ver" && echo " $ver"
            return
        end
    end

    set -l _java_seg (__pr_java)
    test -n "$_java_seg" && set --append prompt_parts $COL_JAVA"  $_java_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ☸️  SEGMENT: Kubernetes context                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_kube --description "Kubernetes context segment"
        # Only show if kubectl used recently or SHOW_KUBE is set
        set -q KUBECONFIG || return
        set -q SHOW_KUBE  || return

        command -q kubectl || return

        set -l ctx (kubectl config current-context 2>/dev/null)
        set -l ns  (kubectl config view --minify --output jsonpath='{..namespace}' 2>/dev/null)
        test -z "$ns" && set ns default

        test -n "$ctx" && echo "  $ctx $DIM($ns)"
    end

    set -l _kube_seg (__pr_kube)
    test -n "$_kube_seg" && set --append prompt_parts $COL_KUBE$_kube_seg$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🐳 SEGMENT: Docker context                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_docker --description "Docker context segment"
        set -q SHOW_DOCKER || return
        command -q docker  || return

        set -l ctx (docker context show 2>/dev/null)
        test -n "$ctx" && test "$ctx" != default && \
            echo "  $ctx"
    end

    set -l _docker_seg (__pr_docker)
    test -n "$_docker_seg" && set --append prompt_parts $COL_DOCKER$_docker_seg$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎭 SEGMENT: ASH Mode indicator                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_ash_mode --description "ASH mode segment"
        set -l state "$HOME/.local/share/ash/state/current-mode.json"
        set -l mode ""

        if command -q jq && test -f $state
            set mode (jq -r '.mode // empty' $state 2>/dev/null)
        end

        test -z "$mode" || test "$mode" = default && return

        # Mode icons
        set -l mode_icon ""
        switch $mode
            case game;    set mode_icon "🎮"
            case work;    set mode_icon "💼"
            case focus;   set mode_icon "🎯"
            case cinema;  set mode_icon "🎬"
            case stream;  set mode_icon "📡"
            case battery; set mode_icon "🔋"
            case privacy; set mode_icon "🔒"
            case present; set mode_icon "📊"
            case '*';     set mode_icon "⚡"
        end

        echo "$mode_icon $mode"
    end

    set -l _ash_mode_seg (__pr_ash_mode)
    test -n "$_ash_mode_seg" && set --append prompt_parts $COL_ASH"  $_ash_mode_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔐 SEGMENT: Sudo active                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if sudo -n true 2>/dev/null
        set --append prompt_parts $COL_SUDO"  sudo"$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⚙️  SEGMENT: Background jobs                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l job_count (jobs | wc -l | string trim)
    if test "$job_count" -gt 0
        set --append prompt_parts $COL_JOBS"  $job_count"$R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ⏱️  SEGMENT: Last command duration                                     ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_duration --description "Format command duration"
        set -q CMD_DURATION || return
        set -l ms $CMD_DURATION

        # Only show if > 2 seconds
        test $ms -lt 2000 && return

        if test $ms -lt 60000
            printf "%.1fs" (math "$ms / 1000")
        else if test $ms -lt 3600000
            printf "%dm%ds" (math --scale 0 "$ms / 60000") (math --scale 0 "($ms % 60000) / 1000")
        else
            printf "%dh%dm" (math --scale 0 "$ms / 3600000") (math --scale 0 "($ms % 3600000) / 60000")
        end
    end

    set -l _dur_seg (__pr_duration)
    test -n "$_dur_seg" && set --append prompt_parts $DIM"  ⏱ $_dur_seg"$R

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 PROMPT CHARACTER: Dynamic based on context                          ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __pr_char --description "Render prompt character"
        set -l stat $argv[1]

        # Determine prompt character based on context
        set -l char "❯"
        set -l char_color $COL_CHAR_OK

        # Root: different character
        if test (id -u) -eq 0
            set char "#"
            set char_color $COL_ROOT
        end

        # Error: red character
        if test $stat -ne 0
            set char_color $COL_CHAR_ERR
        end

        # Vi mode indicator (via $fish_bind_mode)
        set -q fish_bind_mode || set -g fish_bind_mode insert

        switch $fish_bind_mode
            case insert
                set char "❯"
            case visual
                set char "V"
                set char_color $COL_ASH
            case default normal
                set char "❮"
                set char_color (__pr_c mauve magenta)
            case replace replace_one
                set char "R"
                set char_color $COL_GIT_MOD
        end

        # Pipestatus (multiline pipe failures)
        if set -q last_pipestatus && test (count $last_pipestatus) -gt 1
            set -l any_fail 0
            for s in $last_pipestatus
                test $s -ne 0 && set any_fail 1
            end
            test $any_fail -eq 1 && set char_color $COL_CHAR_ERR
        end

        printf "%s%s%s%s " $BOLD $char_color $char $R
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  RENDER PROMPT                                                       ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # Choose separator style based on width
    set -l separator $DIM" ❙ "$R
    set -q ASH_PROMPT_SEPARATOR && set separator $ASH_PROMPT_SEPARATOR

    # Build line 1: segments
    set -l line1 (string join $separator $prompt_parts)

    # Choose single-line vs multi-line based on terminal width
    set -l term_cols (tput cols 2>/dev/null; or echo 80)
    set -l line1_len (string length --visible $line1 2>/dev/null; or echo 40)

    if test $line1_len -gt (math $term_cols - 5)
        # Multi-line prompt
        printf "\n%s\n" $line1
        __pr_char $last_status
    else
        # Single-line prompt
        printf "\n%s\n" $line1
        __pr_char $last_status
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __pr_c __pr_dir __pr_git __pr_node __pr_rust \
        __pr_go __pr_java __pr_kube __pr_docker __pr_ash_mode \
        __pr_duration __pr_char __seg 2>/dev/null

end
