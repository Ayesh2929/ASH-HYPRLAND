# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH PROMPT                                  ║
# ║           Beautiful multi-line prompt with git, virtual env, status        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fish_prompt
    # ── Save last status ──────────────────────────────────────────────────────
    set -l last_status $status
    set -l last_duration $CMD_DURATION

    # ── Colors (from theme or defaults) ───────────────────────────────────────
    set -l col_base     (set_color -o $fish_color_user 2>/dev/null; or set_color -o 9980FA)
    set -l col_path     (set_color $fish_color_cwd 2>/dev/null; or set_color 89b4fa)
    set -l col_git      (set_color cba6f7)
    set -l col_ok       (set_color a6e3a1)
    set -l col_err      (set_color f38ba8)
    set -l col_time     (set_color fab387)
    set -l col_venv     (set_color f9e2af)
    set -l col_sudo     (set_color f38ba8)
    set -l col_muted    (set_color 7f849c)
    set -l col_reset    (set_color normal)
    set -l col_bold     (set_color -o normal)

    # ── Check Starship ─────────────────────────────────────────────────────────
    # If starship is configured, it handles the prompt
    # This function serves as a beautiful fallback
    if command -q starship
        return
    end

    # ── User & Host ────────────────────────────────────────────────────────────
    set -l user_str ""
    if test "$USER" = "root"
        set user_str (set_color -o f38ba8)"⚡ ROOT"$col_reset
    else
        set user_str $col_base(string upper $USER)$col_reset
    end

    # Show hostname if SSH
    set -l host_str ""
    if test -n "$SSH_CONNECTION"
        set host_str $col_muted"@"(hostname -s)$col_reset
    end

    # ── Path ───────────────────────────────────────────────────────────────────
    set -l cwd (prompt_pwd --full-length-dirs=3)
    # Shorten home dir
    set cwd (string replace -r "^$HOME" "~" $cwd)

    set -l path_str $col_path$cwd$col_reset

    # ── Git Information ────────────────────────────────────────────────────────
    set -l git_str ""
    if command -q git
        set -l git_branch (git branch --show-current 2>/dev/null)
        if test -n "$git_branch"
            # Get git status
            set -l git_status (git status --porcelain 2>/dev/null)
            set -l git_ahead  (git rev-list HEAD...@{upstream} --count 2>/dev/null)
            set -l git_behind (git rev-list @{upstream}...HEAD --count 2>/dev/null)

            # State icons
            set -l state_icon ""
            if test -n "$git_status"
                set -l modified  (echo $git_status | grep -c "^.M" 2>/dev/null; or echo 0)
                set -l staged    (echo $git_status | grep -c "^[AM]" 2>/dev/null; or echo 0)
                set -l untracked (echo $git_status | grep -c "^?" 2>/dev/null; or echo 0)

                if test $staged -gt 0
                    set state_icon "●"  # staged
                else if test $modified -gt 0
                    set state_icon "✎"  # modified
                else
                    set state_icon "?"  # untracked
                end
            end

            # Divergence
            set -l diverge_str ""
            if test -n "$git_ahead" && test "$git_ahead" -gt 0 2>/dev/null
                set diverge_str "↑$git_ahead"
            end
            if test -n "$git_behind" && test "$git_behind" -gt 0 2>/dev/null
                set diverge_str "$diverge_str↓$git_behind"
            end

            # Branch color based on state
            set -l branch_col $col_git
            if test -n "$git_status"
                set branch_col (set_color fab387)
            end

            set git_str " "$col_muted"on "$branch_col"⎇ $git_branch"
            test -n "$state_icon" && set git_str "$git_str $state_icon"
            test -n "$diverge_str" && set git_str "$git_str $diverge_str"
            set git_str "$git_str"$col_reset
        end
    end

    # ── Virtual Environment ────────────────────────────────────────────────────
    set -l venv_str ""
    if test -n "$VIRTUAL_ENV"
        set -l venv_name (basename $VIRTUAL_ENV)
        set venv_str " "$col_venv"($venv_name)"$col_reset
    else if test -n "$CONDA_DEFAULT_ENV" && test "$CONDA_DEFAULT_ENV" != "base"
        set venv_str " "$col_venv"(conda:$CONDA_DEFAULT_ENV)"$col_reset
    end

    # ── Duration ───────────────────────────────────────────────────────────────
    set -l duration_str ""
    if test -n "$last_duration" && test "$last_duration" -gt 3000
        set -l secs (math --scale=1 "$last_duration / 1000")
        set duration_str " "$col_time"⏱ $secs"s$col_reset
    end

    # ── Status Indicator ───────────────────────────────────────────────────────
    set -l status_str ""
    if test $last_status -ne 0
        set status_str " "$col_err"✗ $last_status"$col_reset
    end

    # ── Jobs Indicator ─────────────────────────────────────────────────────────
    set -l jobs_str ""
    set -l job_count (jobs | wc -l | string trim)
    if test "$job_count" -gt 0
        set jobs_str " "$col_muted"⚙ $job_count"$col_reset
    end

    # ── Sudo Indicator ─────────────────────────────────────────────────────────
    set -l sudo_str ""
    if sudo -n true 2>/dev/null
        set sudo_str " "$col_sudo"⚡"$col_reset
    end

    # ── Build Prompt Lines ─────────────────────────────────────────────────────
    set -l line1 ""
    set -l line2 ""

    # Line 1: ╭─ user@host path git venv duration
    set line1 $col_muted"╭─"$col_reset" "$user_str$host_str" "$col_muted"in"$col_reset" "$path_str$git_str$venv_str$duration_str$status_str$jobs_str$sudo_str

    # Line 2: ╰─ prompt character
    set -l prompt_char "❯"
    set -l prompt_col $col_ok

    if test $last_status -ne 0
        set prompt_col $col_err
        set prompt_char "✗"
    end

    if test "$USER" = "root"
        set prompt_char "#"
        set prompt_col $col_sudo
    end

    set line2 $col_muted"╰─"$col_reset$prompt_col$prompt_char$col_reset" "

    # ── Output ─────────────────────────────────────────────────────────────────
    echo ""
    echo -s $line1
    echo -sn $line2
end