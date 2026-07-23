# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — bat Ultra Configuration                            ║
# ║  Syntax-highlighted cat replacement with themes, paging & ASH integration  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require bat ────────────────────────────────────────────────────────
command -q bat || command -q batcat || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_bat_loaded && exit 0
set --global _ash_bat_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_bat_log       "$HOME/.local/share/ash/logs/bat.log"
set --global _ash_bat_cache     "$HOME/.local/share/ash/cache/bat"
set --global _ash_bat_config    "$HOME/.config/bat/config"
set --global _ash_bat_themes    "$HOME/.config/bat/themes"
set --global _ash_bat_syntaxes  "$HOME/.config/bat/syntaxes"

mkdir -p (dirname $_ash_bat_log)  2>/dev/null
mkdir -p $_ash_bat_cache           2>/dev/null
mkdir -p $_ash_bat_themes          2>/dev/null
mkdir -p $_ash_bat_syntaxes        2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 BINARY DETECTION: bat vs batcat (Ubuntu/Debian naming)                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_bat_bin --description "Resolve correct bat binary name"
    command -q bat    && echo bat    && return
    command -q batcat && echo batcat && return
    echo bat
end

set --global _ash_bat_exe (__ash_bat_bin)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _bat_reset   (set_color normal)
set -g _bat_bold    (set_color --bold)
set -g _bat_cyan    (set_color cyan)
set -g _bat_green   (set_color green)
set -g _bat_yellow  (set_color yellow)
set -g _bat_red     (set_color red)
set -g _bat_dim     (set_color brblack)
set -g _bat_orange  (set_color FF9F43)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 DYNAMIC THEME: Sync with ASH theme engine                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_bat_resolve_theme --description "Map ASH theme variant to bat theme"
    set -l variant  (set -q ASH_THEME_VARIANT && echo $ASH_THEME_VARIANT || echo dark)
    set -l theme_name (set -q ASH_THEME_NAME && echo $ASH_THEME_NAME || echo "")

    # Map specific ASH themes to bat themes
    switch $theme_name
        case '*catppuccin*mocha*'  '*catppuccin-mocha*'
            echo "Catppuccin Mocha"
        case '*catppuccin*latte*'  '*catppuccin-latte*'
            echo "Catppuccin Latte"
        case '*catppuccin*frappe*' '*catppuccin-frappe*'
            echo "Catppuccin Frappe"
        case '*catppuccin*macchiato*' '*catppuccin-macchiato*'
            echo "Catppuccin Macchiato"
        case '*tokyonight*' '*tokyo-night*'
            echo "tokyonight_night"
        case '*gruvbox*dark*'
            echo "gruvbox-dark"
        case '*gruvbox*light*'
            echo "gruvbox-light"
        case '*nord*'
            echo "Nord"
        case '*dracula*'
            echo "Dracula"
        case '*onedark*' '*one-dark*'
            echo "OneHalfDark"
        case '*everforest*'
            echo "Everforest Dark Medium"
        case '*rosepine*' '*rose-pine*'
            echo "rose-pine"
        case '*kanagawa*'
            echo "kanagawa"
        case '*solarized*dark*'
            echo "Solarized (dark)"
        case '*solarized*light*'
            echo "Solarized (light)"
        case '*'
            # Fallback: use variant
            switch $variant
                case light
                    echo "Catppuccin Latte"
                case '*'
                    echo "Catppuccin Mocha"
            end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT CONFIGURATION                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Config file path ──────────────────────────────────────────────────────────
set --export BAT_CONFIG_PATH $_ash_bat_config

# ── Active theme ──────────────────────────────────────────────────────────────
set --export BAT_THEME (__ash_bat_resolve_theme)

# ── Pager configuration ───────────────────────────────────────────────────────
set --export BAT_PAGER "less --RAW-CONTROL-CHARS --quit-if-one-screen --mouse --wheel-lines=3"

# ── Style preset ─────────────────────────────────────────────────────────────
set --export BAT_STYLE "numbers,changes,header-filesize,header-filename,grid"

# ── Color output ──────────────────────────────────────────────────────────────
set --export COLORTERM truecolor

# ── Write config file if missing ──────────────────────────────────────────────
if not test -f $_ash_bat_config
    mkdir -p (dirname $_ash_bat_config) 2>/dev/null
    printf '# ── bat Configuration — ASH DOTFILES v5.0 ──────────────────────\n\n--theme="%s"\n--style="%s"\n--italic-text=always\n--decorations=always\n--color=always\n--tabs=4\n--wrap=auto\n--terminal-width=220\n--map-syntax="*.conf:INI"\n--map-syntax="*.env:Bourne Again Shell (bash)"\n--map-syntax="*.fish:Fish"\n--map-syntax="*.jsonc:JSON"\n--map-syntax="*.rasi:CSS"\n--map-syntax="Dockerfile*:Dockerfile"\n--map-syntax="*.lock:TOML"\n--map-syntax="justfile:Makefile"\n--map-syntax="Justfile:Makefile"\n' \
        (__ash_bat_resolve_theme) "numbers,changes,header-filesize,header-filename,grid" \
        > $_ash_bat_config
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐱 BAT WRAPPER: Smart cat replacement                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── cat: Transparent bat override ─────────────────────────────────────────────
function cat --wraps=$_ash_bat_exe --description "bat-powered cat replacement"
    # Pass-through for pipes and redirects
    if not isatty stdout
        command cat $argv
        return
    end

    # Single file with forced language detection
    if test (count $argv) -eq 1 && string match -q '*' $argv[1]
        # Detect special file types by name
        switch (basename $argv[1])
            case Dockerfile
                $_ash_bat_exe --language=Dockerfile $argv
                return
            case Makefile GNUmakefile
                $_ash_bat_exe --language=Makefile $argv
                return
            case justfile Justfile
                $_ash_bat_exe --language=Makefile $argv
                return
            case '*.env' '.env' '.env.*'
                $_ash_bat_exe --language=bash $argv
                return
        end
    end

    $_ash_bat_exe $argv
end

# ── bat: Enhanced bat with smart defaults ─────────────────────────────────────
function bat --wraps=$_ash_bat_exe --description "Syntax-highlighted file viewer"
    $_ash_bat_exe $argv
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  SPECIALIZED BAT VIEWERS                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── bcat: Plain bat (no decorations) ─────────────────────────────────────────
function bcat --description "bat without decorations (plain output)"
    $_ash_bat_exe \
        --style=plain \
        --color=always \
        --paging=never \
        $argv
end

# ─── bless: bat as pager (for manual scrolling) ───────────────────────────────
function bless --description "bat as pager for scrollable output"
    $_ash_bat_exe \
        --style=numbers,changes,header-filename,grid \
        --color=always \
        --paging=always \
        $argv
end

# ─── bhead: Show first N lines with bat ───────────────────────────────────────
function bhead --description "Show first N lines with bat syntax highlighting"
    set -l n    $argv[1]
    set -l file $argv[2]

    if test -z "$file"
        set file $n
        set n 30
    end

    $_ash_bat_exe \
        --style=numbers,changes,header-filename \
        --color=always \
        --paging=never \
        --line-range "1:$n" \
        $file
end

# ─── btail: Show last N lines with bat ────────────────────────────────────────
function btail --description "Show last N lines with bat syntax highlighting"
    set -l n    $argv[1]
    set -l file $argv[2]

    if test -z "$file"
        set file $n
        set n 30
    end

    set -l total (wc -l < $file 2>/dev/null; or echo 100)
    set -l start (math "max(1, $total - $n)")

    $_ash_bat_exe \
        --style=numbers,changes,header-filename \
        --color=always \
        --paging=never \
        --line-range "$start:" \
        $file
end

# ─── brange: Show line range ───────────────────────────────────────────────────
function brange --description "Show specific line range with bat"
    set -l start $argv[1]
    set -l end   $argv[2]
    set -l file  $argv[3]

    if test -z "$file"
        echo "  Usage: brange <start> <end> <file>"
        return 1
    end

    $_ash_bat_exe \
        --style=numbers,changes,header-filename \
        --color=always \
        --highlight-line "$start:$end" \
        --line-range "$start:$end" \
        $file
end

# ─── bdiff: Bat-powered diff viewer ───────────────────────────────────────────
function bdiff --description "Side-by-side diff with bat highlighting"
    set -l file1 $argv[1]
    set -l file2 $argv[2]

    if test -z "$file1" || test -z "$file2"
        echo "  Usage: bdiff <file1> <file2>"
        return 1
    end

    # Use delta if available (best experience)
    if command -q delta
        diff -u $file1 $file2 | delta \
            --side-by-side \
            --line-numbers \
            --syntax-theme $BAT_THEME 2>/dev/null
        return
    end

    # Use difft if available
    if command -q difft
        difft $file1 $file2
        return
    end

    # Fallback: bat for each file side by side
    echo ""
    echo $_bat_bold$_bat_cyan"  ◀ $file1"$_bat_reset
    echo ""
    $_ash_bat_exe --style=numbers,changes --color=always $file1
    echo ""
    echo $_bat_bold$_bat_orange"  ▶ $file2"$_bat_reset
    echo ""
    $_ash_bat_exe --style=numbers,changes --color=always $file2
end

# ─── bjson: Pretty JSON with bat ──────────────────────────────────────────────
function bjson --description "Pretty-print and highlight JSON with bat"
    set -l input $argv[1]

    if test -z "$input"
        # Read from stdin
        if command -q jq
            command cat | jq '.' | $_ash_bat_exe --language=json --style=plain --color=always
        else
            command cat | $_ash_bat_exe --language=json --color=always
        end
        return
    end

    if test -f $input
        if command -q jq
            jq '.' $input | $_ash_bat_exe --language=json --style=numbers,header-filename --color=always
        else
            $_ash_bat_exe --language=json $input
        end
    else
        # Treat as JSON string
        echo $input | command -q jq && jq '.' || cat | \
            $_ash_bat_exe --language=json --style=plain --color=always
    end
end

# ─── byaml: YAML viewer ───────────────────────────────────────────────────────
function byaml --description "View YAML/TOML files with bat"
    $_ash_bat_exe --language=yaml --style=numbers,changes,header-filename $argv
end

# ─── bmd: Markdown viewer ─────────────────────────────────────────────────────
function bmd --description "View Markdown with bat syntax highlighting"
    if command -q glow
        glow $argv
        return
    end
    $_ash_bat_exe --language=markdown --style=plain --color=always $argv
end

# ─── benv: View .env files with bat ──────────────────────────────────────────
function benv --description "View .env files with bat (masking secrets)"
    set -l file $argv[1]
    test -z "$file" && set file ".env"

    if not test -f $file
        echo $_bat_red"  ✗ Not found: $file"$_bat_reset
        return 1
    end

    # Show with bat but mask secret values
    while read -l line
        # Skip comments and empty lines
        if string match -q '#*' $line || test -z "$line"
            echo $line
            continue
        end

        set -l key (string split --max 1 '=' $line)[1]
        set -l val (string split --max 1 '=' $line)[2]

        set -l masked_val $val
        for pattern in PASSWORD SECRET KEY TOKEN PASS PRIVATE CREDENTIAL AUTH CERT
            if string match -qi "*$pattern*" $key
                set masked_val (string repeat -n (string length $val) "●")
                break
            end
        end

        echo "$key=$masked_val"
    end < $file | $_ash_bat_exe --language=bash --style=numbers,header-filename --color=always
end

# ─── blog: Smart log viewer with bat ──────────────────────────────────────────
function blog --description "View log files with bat syntax highlighting"
    set -l file  $argv[1]
    set -l lines $argv[2]
    test -z "$lines" && set lines 100

    if test -z "$file"
        echo "  Usage: blog <logfile> [last-n-lines]"
        return 1
    end

    $_ash_bat_exe \
        --language=log \
        --style=numbers,header-filename \
        --color=always \
        --paging=always \
        --line-range "1:$lines" \
        $file 2>/dev/null || \
    $_ash_bat_exe \
        --style=numbers,header-filename \
        --color=always \
        --paging=always \
        $file
end

# ─── bman: Man pages via bat ──────────────────────────────────────────────────
function bman --description "View man pages with bat syntax highlighting"
    set -l page $argv[1]
    test -z "$page" && begin; echo "  Usage: bman <command>"; return 1; end

    man $page | $_ash_bat_exe \
        --language=man \
        --style=plain \
        --color=always \
        --paging=always \
        2>/dev/null || man $page
end

# ─── bwatch: Watch file with bat re-rendering ─────────────────────────────────
function bwatch --description "Watch and re-render file with bat on change"
    set -l file $argv[1]

    if test -z "$file"
        echo "  Usage: bwatch <file>"
        return 1
    end

    if command -q entr
        echo $file | entr -c bash -c "$_ash_bat_exe --style=numbers,changes --color=always $file"
    else
        # Fallback: manual watch loop
        while true
            clear
            $_ash_bat_exe --style=numbers,changes --color=always $file 2>/dev/null
            sleep 2
        end
    end
end

# ─── bgrep: Grep with bat context highlighting ────────────────────────────────
function bgrep --description "Grep with bat syntax highlighted context"
    set -l pattern $argv[1]
    set -l file    $argv[2]

    if test -z "$pattern"
        echo "  Usage: bgrep <pattern> [file]"
        return 1
    end

    if test -n "$file"
        # Show matching lines with context using bat
        command -q rg && \
            rg --line-number --no-heading "$pattern" $file | \
            while read -l match
                set -l line (echo $match | cut -d: -f1)
                set -l ctx_start (math "max(1, $line - 3)")
                set -l ctx_end   (math "$line + 3")
                $_ash_bat_exe --style=numbers \
                    --color=always \
                    --highlight-line $line \
                    --line-range "$ctx_start:$ctx_end" \
                    --paging=never \
                    $file
                echo ""
            end || \
            grep -n "$pattern" $file | \
            $_ash_bat_exe --language=log --style=plain --color=always
    else
        command -q rg && rg --color=always "$pattern" || grep --color=always "$pattern" .
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 THEME MANAGEMENT                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── bat-theme-ls: List all available themes ──────────────────────────────────
function bat-theme-ls --description "List all bat themes with previews"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🎨  bat Themes                                   ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    set -l active $BAT_THEME

    $_ash_bat_exe --list-themes 2>/dev/null | while read -l theme
        set -l active_marker ""
        test "$theme" = "$active" && set active_marker $green"  ← active"$reset
        echo "  "$dim"•"$reset" $theme$active_marker"
    end
    echo ""
    echo "  Current: "$cyan$active$reset
    echo ""
end

# ─── bat-theme-preview: Preview a theme ───────────────────────────────────────
function bat-theme-preview --description "Preview bat themes with sample code"
    set -l theme $argv[1]
    set -l file  $argv[2]

    # Create sample file for preview
    set -l sample_file (mktemp --suffix=.py)
    printf '# Python sample — ASH bat theme preview\nimport json\nfrom typing import Optional\n\ndef greet(name: str, times: int = 1) -> Optional[str]:\n    """Greet someone with syntax highlighting demo."""\n    if not name:\n        return None  # Early return\n    \n    result = []\n    for i in range(times):\n        result.append(f"Hello, {name}! ({i+1}/{times})")\n    \n    return "\\n".join(result)\n\nif __name__ == "__main__":\n    print(greet("World", 3))\n    data = {"key": [1, 2, 3], "flag": True}\n    print(json.dumps(data, indent=2))\n' \
        > $sample_file

    test -n "$file" && set sample_file $file

    if test -z "$theme"
        # Interactive theme picker with live preview
        if command -q fzf
            set theme (
                $_ash_bat_exe --list-themes 2>/dev/null |
                fzf --ansi \
                    --no-sort \
                    --border-label "  🎨 bat Theme Picker " \
                    --border rounded \
                    --prompt "  🎨 " \
                    --pointer "▶" \
                    --preview "$_ash_bat_exe --theme={} --style=numbers,changes --color=always $sample_file 2>/dev/null" \
                    --preview-window 'right:65%:border-rounded:wrap' \
                    --header "  Current: $BAT_THEME  Enter:apply  " \
                    --header-first
            )
            test -z "$theme" && begin; rm -f $sample_file; return 0; end
        else
            bat-theme-ls
            read -P "  Theme name: " theme
        end
    end

    rm -f $sample_file

    if test -n "$theme"
        echo ""
        echo $_bat_cyan"  🎨 Applying theme: $theme"$_bat_reset
        bat-theme-set $theme
    end
end

# ─── bat-theme-set: Apply a theme ─────────────────────────────────────────────
function bat-theme-set --description "Set bat theme and update config"
    set -l theme $argv[1]

    if test -z "$theme"
        bat-theme-preview
        return
    end

    # Validate theme exists
    if not $_ash_bat_exe --list-themes 2>/dev/null | grep -qF "$theme"
        echo $_bat_red"  ✗ Theme not found: $theme"$_bat_reset
        echo "  Run: bat-theme-ls"
        return 1
    end

    # Update environment
    set --export BAT_THEME $theme

    # Update config file
    if test -f $_ash_bat_config
        sed -i "s|^--theme=.*|--theme=\"$theme\"|" $_ash_bat_config 2>/dev/null || \
            echo "--theme=\"$theme\"" >> $_ash_bat_config
    end

    echo $_bat_green"  ✓ bat theme: $theme"$_bat_reset
end

# ─── bat-cache: Manage bat cache ──────────────────────────────────────────────
function bat-cache --description "Manage bat theme and syntax cache"
    set -l action $argv[1]
    test -z "$action" && set action build

    switch $action
        case build
            echo $_bat_cyan"  🔨 Building bat cache..."$_bat_reset
            $_ash_bat_exe cache --build 2>/dev/null
            and echo $_bat_green"  ✓ Cache built"$_bat_reset

        case clear clean
            echo $_bat_yellow"  🧹 Clearing bat cache..."$_bat_reset
            $_ash_bat_exe cache --clear 2>/dev/null
            and echo $_bat_green"  ✓ Cache cleared"$_bat_reset

        case rebuild
            $_ash_bat_exe cache --clear 2>/dev/null
            $_ash_bat_exe cache --build 2>/dev/null
            and echo $_bat_green"  ✓ Cache rebuilt"$_bat_reset

        case '*'
            echo "  Usage: bat-cache [build|clear|rebuild]"
    end
end

# ─── bat-info: bat environment dashboard ──────────────────────────────────────
function bat-info --description "Show bat environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)
    set -l orange (set_color FF9F43)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     🦇  bat Environment Dashboard                    ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Binary:    "$reset $dim$_ash_bat_exe$reset
    echo "  "$bold"Version:   "$reset $cyan($_ash_bat_exe --version 2>/dev/null)$reset
    echo "  "$bold"Theme:     "$reset $cyan$BAT_THEME$reset
    echo "  "$bold"Config:    "$reset $dim$_ash_bat_config$reset
    echo "  "$bold"Themes dir:"$reset $dim$_ash_bat_themes$reset
    echo "  "$bold"Style:     "$reset $dim$BAT_STYLE$reset
    echo ""

    set -l theme_count ($_ash_bat_exe --list-themes 2>/dev/null | wc -l | string trim)
    set -l syntax_count ($_ash_bat_exe --list-languages 2>/dev/null | wc -l | string trim)

    echo "  "$bold"Themes:    "$reset $cyan$theme_count$reset
    echo "  "$bold"Syntaxes:  "$reset $cyan$syntax_count$reset
    echo ""

    # Custom themes/syntaxes
    set -l custom_themes (count $_ash_bat_themes/*.tmTheme $_ash_bat_themes/*.TextMate 2>/dev/null)
    test $custom_themes -gt 0 && echo "  "$bold"Custom themes: "$reset $cyan$custom_themes$reset
    echo ""
end

# ─── bat-add-theme: Install a custom bat theme ────────────────────────────────
function bat-add-theme --description "Install a custom TextMate theme for bat"
    set -l theme_url  $argv[1]
    set -l theme_name $argv[2]

    if test -z "$theme_url"
        echo "  Usage: bat-add-theme <url-or-file> [name]"
        echo ""
        echo "  Popular themes:"
        echo "    Catppuccin: https://raw.githubusercontent.com/catppuccin/bat/main/themes/"
        echo "    Tokyo Night: https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/bat/"
        return 1
    end

    # Download or copy theme
    if string match -q 'http*' $theme_url
        test -z "$theme_name" && set theme_name (basename $theme_url)
        set -l dest "$_ash_bat_themes/$theme_name"

        curl -fsSL $theme_url -o $dest 2>/dev/null
        and begin
            bat-cache build
            echo $_bat_green"  ✓ Theme installed: $theme_name"$_bat_reset
        end
    else if test -f $theme_url
        test -z "$theme_name" && set theme_name (basename $theme_url)
        cp $theme_url "$_ash_bat_themes/$theme_name"
        bat-cache build
        echo $_bat_green"  ✓ Theme installed: $theme_name"$_bat_reset
    else
        echo $_bat_red"  ✗ Theme not found: $theme_url"$_bat_reset
        return 1
    end
end

# ─── bat-install-catppuccin: Install Catppuccin themes ────────────────────────
function bat-install-catppuccin --description "Install all Catppuccin bat themes"
    set -l base_url "https://raw.githubusercontent.com/catppuccin/bat/main/themes"
    set -l variants mocha latte frappe macchiato

    echo ""
    echo $_bat_cyan"  🐱 Installing Catppuccin bat themes..."$_bat_reset
    echo ""

    for variant in $variants
        set -l filename "Catppuccin $variant.tmTheme"
        set -l url "$base_url/Catppuccin%20"(string capitalize $variant)".tmTheme"
        set -l dest "$_ash_bat_themes/$filename"

        curl -fsSL $url -o $dest 2>/dev/null
        and echo $_bat_green"  ✓ $filename"$_bat_reset \
        or  echo $_bat_yellow"  ⚠ Failed: $filename"$_bat_reset
    end

    bat-cache build
    echo ""
    echo $_bat_green"  ✓ Catppuccin themes installed"$_bat_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔃 THEME SYNC EVENT HANDLER                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_bat_on_theme_change --on-event ash_theme_changed \
    --description "Sync bat theme on ASH theme change"
    set -l new_theme (__ash_bat_resolve_theme)
    bat-theme-set $new_theme 2>/dev/null
end

# ── Tool integrations: use bat as pager for other tools ───────────────────────

# man: use bat as pager
if $_ash_bat_exe --version &>/dev/null
    set --export MANPAGER "sh -c 'col -bx | $_ash_bat_exe -l man -p'"
    set --export MANROFFOPT "-c"
end

# fzf: use bat for preview (picked up by fzf config)
if command -q fzf
    set --export FZF_BAT_PREVIEW_COMMAND "$_ash_bat_exe --color=always --style=numbers,changes --line-range=:300 {}"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core viewing
abbr --add b       "$_ash_bat_exe"
abbr --add bc      'bcat'
abbr --add bl      'bless'
abbr --add bh      'bhead'
abbr --add bt      'btail'
abbr --add br      'brange'
abbr --add bd      'bdiff'
abbr --add bj      'bjson'
abbr --add by      'byaml'
abbr --add bm      'bmd'
abbr --add be      'benv'
abbr --add blg     'blog'
abbr --add bman    'bman'
abbr --add bw      'bwatch'
abbr --add bg      'bgrep'

# Theme management
abbr --add bthls   'bat-theme-ls'
abbr --add bthp    'bat-theme-preview'
abbr --add bths    'bat-theme-set'
abbr --add bthcat  'bat-install-catppuccin'
abbr --add bthadd  'bat-add-theme'

# Cache & Info
abbr --add bcache  'bat-cache'
abbr --add binfo   'bat-info'
abbr --add bls     "$_ash_bat_exe --list-languages"
abbr --add bver    "$_ash_bat_exe --version"

# Language-forced viewing
abbr --add bpy     "$_ash_bat_exe --language=python"
abbr --add brs     "$_ash_bat_exe --language=rust"
abbr --add bgo     "$_ash_bat_exe --language=go"
abbr --add bts     "$_ash_bat_exe --language=typescript"
abbr --add bsh     "$_ash_bat_exe --language=bash"
abbr --add bsql    "$_ash_bat_exe --language=sql"
abbr --add bdkr    "$_ash_bat_exe --language=Dockerfile"
abbr --add bnix    "$_ash_bat_exe --language=nix"
abbr --add bloc    "$_ash_bat_exe --language=log"
abbr --add bcss    "$_ash_bat_exe --language=css"
abbr --add bhtml   "$_ash_bat_exe --language=html"
abbr --add bxml    "$_ash_bat_exe --language=xml"
abbr --add btoml   "$_ash_bat_exe --language=TOML"
abbr --add bini    "$_ash_bat_exe --language=INI"