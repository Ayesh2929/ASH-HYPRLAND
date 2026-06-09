# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MKCD FUNCTION                                ║
# ║           Create directory and cd into it                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function mkcd -d "Create directory and cd into it"
    if test -z "$argv"
        echo "Usage: mkcd <directory> [<directory2> ...]"
        return 1
    end

    set -l c_ok    (set_color a6e3a1)
    set -l c_err   (set_color f38ba8)
    set -l c_info  (set_color 89b4fa)
    set -l c_reset (set_color normal)

    # Handle multiple directories — cd into last one
    for dir in $argv
        if test -d "$dir"
            echo -s $c_info"📁 Directory exists: $dir"$c_reset
        else
            mkdir -p "$dir"
            if test $status -eq 0
                echo -s $c_ok"✅ Created: $dir"$c_reset
            else
                echo -s $c_err"❌ Failed to create: $dir"$c_reset
                return 1
            end
        end
    end

    # CD into the last directory
    set -l target $argv[-1]
    cd "$target"
    echo -s $c_ok"📂 Now in: "(pwd)$c_reset
end

complete -c mkcd -F