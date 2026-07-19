# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — fish_title Ultra                                   ║
# ║  Dynamic terminal title with context, git, tools & ASH integration         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function fish_title --description "ASH dynamic terminal title"

    # ── Helper: safe truncate ─────────────────────────────────────────────────
    function __title_trunc --description "Truncate string to max length"
        set -l str $argv[1]
        set -l max $argv[2]
        test -z "$max" && set max 40
        set -l len (string length $str)
        if test $len -gt $max
            echo (string sub --length $max $str)"…"
        else
            echo $str
        end
    end

    # ── Get current command ────────────────────────────────────────────────────
    set -l cmd (status current-command)
    set -l is_running 0
    test -n "$cmd" && test "$cmd" != fish && set is_running 1

    # ── Current directory ─────────────────────────────────────────────────────
    set -l cwd (pwd)
    set -l short_cwd (string replace $HOME "~" $cwd)

    # Smart path: show only last 2-3 components
    set -l cwd_parts (string split '/' $short_cwd)
    set -l cwd_count (count $cwd_parts)

    set -l display_cwd $short_cwd
    if test $cwd_count -gt 3
        set display_cwd "…/"(string join '/' $cwd_parts[-2..-1])
    end

    # ── Git context ───────────────────────────────────────────────────────────
    function __title_git --description "Get git repo name"
        command -q git || return
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        test -z "$root" && return
        set -l branch (git branch --show-current 2>/dev/null)
        set -l repo   (basename $root)
        test -n "$branch" && echo "$repo:$branch" || echo $repo
    end

    set -l git_info (__title_git)

    # ── SSH context ───────────────────────────────────────────────────────────
    set -l ssh_prefix ""
    if set -q SSH_CONNECTION; or set -q SSH_CLIENT
        set ssh_prefix "[SSH: "(hostname -s 2>/dev/null)"] "
    end

    # ── Cloud context ─────────────────────────────────────────────────────────
    function __title_cloud --description "Get active cloud context indicator"
        set -l parts
        set -q AWS_PROFILE              && test -n "$AWS_PROFILE"              && \
            set --append parts "AWS:$AWS_PROFILE"
        set -q CLOUDSDK_CORE_PROJECT    && test -n "$CLOUDSDK_CORE_PROJECT"    && \
            set --append parts "GCP:$CLOUDSDK_CORE_PROJECT"
        set -q AZURE_DEFAULTS_GROUP     && test -n "$AZURE_DEFAULTS_GROUP"     && \
            set --append parts "AZ:$AZURE_DEFAULTS_GROUP"
        test (count $parts) -gt 0 && echo "["(string join "|" $parts)"] "
    end

    set -l cloud_ctx (__title_cloud)

    # ── Virtual environment context ────────────────────────────────────────────
    function __title_venv --description "Get active virtual env"
        if set -q VIRTUAL_ENV
            echo "("(basename $VIRTUAL_ENV)") "
            return
        end
        if set -q CONDA_DEFAULT_ENV && test "$CONDA_DEFAULT_ENV" != ""
            test "$CONDA_DEFAULT_ENV" != base && \
                echo "(conda:$CONDA_DEFAULT_ENV) "
        end
    end

    set -l venv_ctx (__title_venv)

    # ── ASH mode ──────────────────────────────────────────────────────────────
    function __title_ash_mode --description "Get ASH mode icon"
        set -l state "$HOME/.local/share/ash/state/current-mode.json"
        test -f $state || return

        command -q jq || return
        set -l mode (jq -r '.mode // empty' $state 2>/dev/null)
        test -z "$mode" || test "$mode" = default && return

        set -l icon
        switch $mode
            case game;    set icon "🎮 "
            case work;    set icon "💼 "
            case focus;   set icon "🎯 "
            case cinema;  set icon "🎬 "
            case stream;  set icon "📡 "
            case battery; set icon "🔋 "
            case privacy; set icon "🔒 "
            case present; set icon "📊 "
            case '*';     set icon "⚡ "
        end
        echo $icon
    end

    set -l ash_mode_icon (__title_ash_mode)

    # ── Kubernetes context ─────────────────────────────────────────────────────
    function __title_kube --description "Get kubernetes context for title"
        set -q SHOW_KUBE    || return
        command -q kubectl  || return
        set -l ctx (kubectl config current-context 2>/dev/null)
        test -n "$ctx" && echo "☸ $ctx | "
    end

    set -l kube_ctx (__title_kube)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🖨️  RENDER TITLE                                                        ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    if test $is_running -eq 1
        # ── Running command: show command + minimal context ────────────────────
        set -l short_cmd (__title_trunc $cmd 30)

        if test -n "$git_info"
            printf "%s%s ❯ %s │ %s" \
                $ssh_prefix $ash_mode_icon $short_cmd $git_info
        else
            printf "%s%s ❯ %s │ %s" \
                $ssh_prefix $ash_mode_icon $short_cmd $display_cwd
        end
    else
        # ── Idle: full context ────────────────────────────────────────────────
        set -l title_parts

        # SSH prefix
        test -n "$ssh_prefix" && set --append title_parts $ssh_prefix

        # ASH mode icon
        test -n "$ash_mode_icon" && set --append title_parts $ash_mode_icon

        # Cloud context
        test -n "$cloud_ctx" && set --append title_parts $cloud_ctx

        # Kube context
        test -n "$kube_ctx" && set --append title_parts $kube_ctx

        # Virtual env
        test -n "$venv_ctx" && set --append title_parts $venv_ctx

        # Git info or directory
        if test -n "$git_info"
            set --append title_parts " $git_info"
            set --append title_parts " │ $display_cwd"
        else
            set --append title_parts "  $display_cwd"
        end

        # Hostname (always show)
        set --append title_parts " — "(whoami)"@"(hostname -s 2>/dev/null)

        printf "%s" (string join "" $title_parts)
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __title_trunc __title_git __title_cloud \
        __title_venv __title_ash_mode __title_kube 2>/dev/null

end
