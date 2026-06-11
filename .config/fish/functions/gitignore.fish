# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — GITIGNORE GENERATOR                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function gitignore -d "Generate .gitignore from gitignore.io"
    if test (count $argv) -eq 0
        echo "Usage: gitignore [lang1] [lang2] ..."
        echo "Example: gitignore python django linux"
        echo ""
        echo "List all: gitignore --list"
        return 0
    end

    if test "$argv[1]" = "--list" -o "$argv[1]" = "-l"
        curl -sL "https://www.toptal.com/developers/gitignore/api/list" 2>/dev/null \
            | tr ',' '\n' | column
        return 0
    end

    set -l types (string join "," $argv)
    set -l url   "https://www.toptal.com/developers/gitignore/api/$types"

    set -l c_ok    (set_color a6e3a1)
    set -l c_info  (set_color 89b4fa)
    set -l c_reset (set_color normal)

    echo -e "  $c_info→$c_reset Fetching .gitignore for: $types"

    set -l content (curl -sL --max-time 10 "$url" 2>/dev/null)

    if test $status -ne 0 -o -z "$content"
        echo "Failed to fetch gitignore template"
        return 1
    end

    echo $content | head -10
    echo "..."
    echo ""
    read -P "  Save to .gitignore? [Y/n]: " confirm

    if test (string lower "$confirm") != "n"
        echo $content > .gitignore
        echo -e "  $c_ok✓$c_reset Saved to .gitignore"
    end
end

complete -c gitignore -x -d "Language/framework name"
complete -c gitignore -l list -d "List all templates"