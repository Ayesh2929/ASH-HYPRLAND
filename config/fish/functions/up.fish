# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — up Ultra                                           ║
# ║  Navigate up N levels, to named dir, git root, project root & smart jump  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function up --description "Smart directory traversal: levels, names, markers & git root"

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
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 HELP                                                                ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __up_help --description "Print up help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     ⬆️   up — Smart Directory Traversal               ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  up [n | name | flag]"
        echo ""
        echo "  $BOLD Arguments:$R"
        printf "    $CYAN%-18s$R  %s\n" \
            "(none)"      "Go up 1 directory (cd ..)" \
            "N"           "Go up N levels" \
            "name"        "Go up to directory named 'name'" \
            "partial"     "Go up to dir matching partial name" \
            "--git, -g"   "Jump to git repository root" \
            "--root, -r"  "Jump to project root (git/Cargo/go.mod/etc)" \
            "--home, -H"  "Go to home directory" \
            "--list, -l"  "List parent directories" \
            "--pick, -p"  "Interactive parent picker (fzf)" \
            "--help, -h"  "Show this help"
        echo ""
        echo "  $BOLD Project root markers:$R"
        printf "    $DIM%s$R\n" \
            ".git  Cargo.toml  go.mod  pyproject.toml  package.json" \
            "flake.nix  Makefile  justfile  Dockerfile  .editorconfig" \
            "pom.xml  build.gradle  composer.json  mix.exs  pubspec.yaml"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%-30s$R  %s\n" \
            "up"           "go up 1 level" \
            "up 3"         "go up 3 levels" \
            "up projects"  "go up to dir named 'projects'" \
            "up proj"      "go up to dir matching 'proj'" \
            "up --git"     "go to git root" \
            "up --root"    "go to project root" \
            "up --list"    "list parent dirs" \
            "up --pick"    "fuzzy pick parent dir"
        echo ""
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 HELPERS                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __up_go --description "Change to directory with feedback"
        set -l target $argv[1]
        set -l reason $argv[2]

        if not test -d $target
            printf "  $RED✗$R  Not a directory: $target\n"
            return 1
        end

        set -l old_pwd $PWD
        cd $target 2>/dev/null
        set -l rc $status

        if test $rc -eq 0
            # Format the path nicely
            set -l display (string replace $HOME '~' $PWD)
            printf "  $GREEN↑$R  $BOLD$CYAN%s$R" $display
            test -n "$reason" && printf "  $DIM(%s)$R" $reason
            printf "\n"

            # Update zoxide
            command -q zoxide && zoxide add (pwd) 2>/dev/null
        else
            printf "  $RED✗$R  Cannot enter: $target\n"
        end

        return $rc
    end

    function __up_list_parents --description "List all parent directories"
        echo ""
        echo $BOLD$CYAN"  ⬆️  Parent Directories:"$R
        echo ""

        set -l dir (pwd)
        set -l idx 0

        while test "$dir" != "/"
            set dir (dirname $dir)
            set idx (math $idx + 1)
            set -l display (string replace $HOME '~' $dir)

            # Check for project markers
            set -l markers ""
            for m in .git Cargo.toml go.mod package.json pyproject.toml \
                      flake.nix Makefile justfile
                test -e "$dir/$m" && set markers "$markers $DIM$m$R"
            end

            printf "  $CYAN%2d$R  $BOLD%-40s$R%s\n" \
                $idx $display $markers
        end
        echo ""
    end

    function __up_find_root --description "Find project root directory"
        set -l dir (pwd)
        set -l markers \
            ".git" \
            "Cargo.toml" \
            "go.mod" \
            "pyproject.toml" \
            "package.json" \
            "flake.nix" \
            "Makefile" \
            "justfile" \
            "Justfile" \
            "Dockerfile" \
            ".editorconfig" \
            "pom.xml" \
            "build.gradle" \
            "build.gradle.kts" \
            "composer.json" \
            "mix.exs" \
            "pubspec.yaml" \
            "deno.json" \
            "bun.lockb" \
            "CMakeLists.txt" \
            ".project" \
            "setup.py" \
            "setup.cfg"

        set -l candidates
        set -l marker_found

        while test "$dir" != "/"
            for marker in $markers
                if test -e "$dir/$marker"
                    set --append candidates $dir
                    set --append marker_found $marker
                    break
                end
            end
            set dir (dirname $dir)
        end

        # Return deepest root (outermost project boundary)
        if test (count $candidates) -gt 0
            echo $candidates[-1]
            echo $marker_found[-1]
        end
    end

    function __up_find_git --description "Find git root"
        command -q git || return 1
        git rev-parse --show-toplevel 2>/dev/null
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING & DISPATCH                                         ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── No args: go up 1 ──────────────────────────────────────────────────────
    if test (count $argv) -eq 0
        if test "$PWD" = "/"
            printf "  $YELLOW⚠$R  Already at root\n"
            return 0
        end
        __up_go (dirname $PWD)
        return $status
    end

    set -l arg $argv[1]

    switch $arg

        # ── Help ──────────────────────────────────────────────────────────────
        case --help -h help
            __up_help

        # ── Home ──────────────────────────────────────────────────────────────
        case --home -H
            __up_go $HOME "home"

        # ── Git root ──────────────────────────────────────────────────────────
        case --git -g
            set -l git_root (__up_find_git)
            if test -n "$git_root"
                if test "$git_root" = "$PWD"
                    printf "  $YELLOW⚠$R  Already at git root: $CYAN%s$R\n" \
                        (string replace $HOME '~' $git_root)
                else
                    __up_go $git_root "git root"
                end
            else
                printf "  $RED✗$R  Not in a git repository\n"
                return 1
            end

        # ── Project root ──────────────────────────────────────────────────────
        case --root -r
            set -l result (__up_find_root)
            set -l root_dir (echo $result | head -1)
            set -l root_marker (echo $result | tail -1)

            if test -n "$root_dir"
                if test "$root_dir" = "$PWD"
                    printf "  $YELLOW⚠$R  Already at project root: $CYAN%s$R  $DIM(%s)$R\n" \
                        (string replace $HOME '~' $root_dir) $root_marker
                else
                    __up_go $root_dir "project root: $root_marker"
                end
            else
                # Fallback to git root
                set -l git_root (__up_find_git)
                if test -n "$git_root"
                    __up_go $git_root "git root"
                else
                    printf "  $YELLOW⚠$R  No project root found — going to home\n"
                    __up_go $HOME
                end
            end

        # ── Interactive picker ────────────────────────────────────────────────
        case --pick -p
            if not command -q fzf
                __up_list_parents
                return 0
            end

            # Build parent list with metadata
            set -l dir (pwd)
            set -l parents
            set -l parent_labels

            while test "$dir" != "/"
                set dir (dirname $dir)
                set -l display (string replace $HOME '~' $dir)

                # Find markers
                set -l has_markers ""
                for m in .git Cargo.toml go.mod package.json pyproject.toml \
                          flake.nix Makefile justfile Dockerfile
                    test -e "$dir/$m" && set has_markers "$has_markers $m"
                end

                set --append parents $dir
                set --append parent_labels "$display$has_markers"
            end

            # Also add home
            set --append parents $HOME
            set --append parent_labels "~ (home)"

            set -l selected (
                printf '%s\n' $parent_labels |
                fzf --ansi \
                    --no-sort \
                    --border-label "  ⬆️  Navigate Up " \
                    --border rounded \
                    --prompt "  📁 " \
                    --pointer "▶" \
                    --preview '
                        dir=$(echo {} | awk "{print \$1}" | sed "s|^~|'"$HOME"'|")
                        if command -v eza >/dev/null; then
                            eza --icons --color=always --group-directories-first -la "$dir" 2>/dev/null | head -20
                        else
                            ls -la "$dir" 2>/dev/null | head -20
                        fi
                    ' \
                    --preview-window 'right:50%:border-rounded' \
                    --header "  Current: $(string replace $HOME '~' $PWD)  " \
                    --header-first \
                    --height 60% \
                    --bind 'ctrl-/:toggle-preview'
            )

            if test -n "$selected"
                set -l target (echo $selected | awk '{print $1}' | string replace '~' $HOME)
                __up_go $target "interactive"
            end

        # ── List parents ──────────────────────────────────────────────────────
        case --list -l
            __up_list_parents

        # ── Numeric: go up N levels ───────────────────────────────────────────
        case '' '*'
            # Check if purely numeric
            if string match -qr '^\d+$' $arg
                set -l n $arg
                test $n -eq 0 && return 0

                set -l target (pwd)
                set -l actual 0

                for i in (seq $n)
                    if test "$target" = "/"
                        break
                    end
                    set target (dirname $target)
                    set actual (math $actual + 1)
                end

                if test $actual -lt $n && test "$target" = "/"
                    printf "  $YELLOW⚠$R  Only $actual levels available — stopping at /\n"
                end

                __up_go $target "$actual levels"

            # String: find parent directory by name (exact or partial)
            else
                set -l search (string lower $arg)
                set -l dir (pwd)
                set -l found ""
                set -l levels 0

                while test "$dir" != "/"
                    set dir (dirname $dir)
                    set levels (math $levels + 1)
                    set -l dir_name (string lower (basename $dir))

                    # Exact match first
                    if test "$dir_name" = "$search"
                        set found $dir
                        break
                    end
                end

                # If no exact match, try partial
                if test -z "$found"
                    set dir (pwd)
                    set levels 0
                    while test "$dir" != "/"
                        set dir (dirname $dir)
                        set levels (math $levels + 1)
                        set -l dir_name (string lower (basename $dir))
                        if string match -q "*$search*" $dir_name
                            set found $dir
                            break
                        end
                    end
                end

                if test -n "$found"
                    __up_go $found "matched '$arg' ($levels level(s))"
                else
                    printf "  $RED✗$R  No parent directory matching '$arg'\n"
                    printf "  $DIM  Run: up --list   to see all parents$R\n"
                    printf "  $DIM  Run: up --pick   for interactive selection$R\n"
                    return 1
                end
            end
    end

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __up_help __up_go __up_list_parents \
        __up_find_root __up_find_git 2>/dev/null

end
