# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Node Version Manager Ultra Configuration           ║
# ║  nvm/fnm/volta/mise with auto-switching, caching & full ecosystem support  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_nvm_loaded && exit 0
set --global _ash_nvm_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_nvm_cache_dir   "$HOME/.local/share/ash/cache/nvm"
set --global _ash_nvm_state_file  "$HOME/.local/share/ash/state/node.json"
set --global _ash_nvm_log         "$HOME/.local/share/ash/logs/nvm.log"
set --global _ash_nvm_cache_ttl   300   # 5 minutes

# Common Node version file names (checked in order)
set --global _ash_node_version_files \
    ".nvmrc" \
    ".node-version" \
    ".tool-versions" \
    "package.json"

mkdir -p $_ash_nvm_cache_dir 2>/dev/null
mkdir -p (dirname $_ash_nvm_state_file) 2>/dev/null
mkdir -p (dirname $_ash_nvm_log) 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _nvm_reset   (set_color normal)
set -g _nvm_bold    (set_color --bold)
set -g _nvm_cyan    (set_color cyan)
set -g _nvm_green   (set_color green)
set -g _nvm_yellow  (set_color yellow)
set -g _nvm_red     (set_color red)
set -g _nvm_blue    (set_color blue)
set -g _nvm_purple  (set_color magenta)
set -g _nvm_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 BACKEND DETECTION: fnm → volta → mise → nvm → n                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_nvm_detect_backend --description "Detect best available Node version manager"
    # fnm: fastest, written in Rust
    if command -q fnm
        echo "fnm"; return
    end

    # volta: JS toolchain manager
    if command -q volta
        echo "volta"; return
    end

    # mise: universal version manager (replaces asdf)
    if command -q mise && mise plugin list 2>/dev/null | grep -q node
        echo "mise"; return
    end

    # asdf: universal version manager
    if command -q asdf && asdf plugin list 2>/dev/null | grep -q nodejs
        echo "asdf"; return
    end

    # nvm (fish-nvm plugin)
    if functions -q nvm
        echo "nvm-fish"; return
    end

    # nvm (bash-based, via nvm.fish wrapper)
    if test -f "$NVM_DIR/nvm.sh"
        echo "nvm"; return
    end
    if test -f "$HOME/.nvm/nvm.sh"
        echo "nvm"; return
    end

    # n: simple node version manager
    if command -q n
        echo "n"; return
    end

    # System node (no version manager)
    if command -q node
        echo "system"; return
    end

    echo "none"
end

set --global _ash_nvm_backend (__ash_nvm_detect_backend)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 BACKEND INITIALIZERS                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── fnm: Fast Node Manager ───────────────────────────────────────────────────
function __ash_nvm_init_fnm --description "Initialize fnm"
    # Core init with shell integration
    fnm env \
        --use-on-cd \
        --shell fish \
        --version-file-strategy recursive \
        --cwd \
        2>/dev/null | source

    # Performance: enable completions
    fnm completions --shell fish 2>/dev/null | source

    # Export FNM_DIR
    set --export FNM_DIR "$HOME/.local/share/fnm"

    # Log
    echo "[fnm] initialized ver="(fnm --version 2>/dev/null) >> $_ash_nvm_log 2>/dev/null
end

# ─── volta: JS Toolchain Manager ─────────────────────────────────────────────
function __ash_nvm_init_volta --description "Initialize Volta"
    set --export VOLTA_HOME "$HOME/.volta"

    if not contains "$VOLTA_HOME/bin" $PATH
        fish_add_path --prepend --global "$VOLTA_HOME/bin"
    end

    echo "[volta] initialized ver="(volta --version 2>/dev/null) >> $_ash_nvm_log 2>/dev/null
end

# ─── mise: Universal Version Manager ─────────────────────────────────────────
function __ash_nvm_init_mise --description "Initialize mise for Node"
    mise activate fish 2>/dev/null | source
    echo "[mise] initialized ver="(mise --version 2>/dev/null) >> $_ash_nvm_log 2>/dev/null
end

# ─── asdf: Universal Version Manager ─────────────────────────────────────────
function __ash_nvm_init_asdf --description "Initialize asdf for Node"
    # Source asdf
    for asdf_dir in \
        "$HOME/.asdf" \
        "/opt/asdf" \
        "/usr/local/asdf" \
        (brew --prefix asdf 2>/dev/null)"/libexec"

        if test -f "$asdf_dir/asdf.fish"
            source "$asdf_dir/asdf.fish"
            break
        end
    end

    echo "[asdf] initialized" >> $_ash_nvm_log 2>/dev/null
end

# ─── nvm-fish: Fish-native NVM wrapper ───────────────────────────────────────
function __ash_nvm_init_nvm_fish --description "Initialize nvm-fish plugin"
    # Already loaded via fisher/plug — just set NVM_DIR
    set --export NVM_DIR "$HOME/.nvm"
    echo "[nvm-fish] initialized" >> $_ash_nvm_log 2>/dev/null
end

# ─── nvm: Standard bash-based NVM via wrapper ────────────────────────────────
function __ash_nvm_init_nvm --description "Initialize standard nvm"
    set --export NVM_DIR (test -n "$NVM_DIR" && echo $NVM_DIR || echo "$HOME/.nvm")

    # bass wrapper for bash scripts (if available)
    if functions -q bass
        function nvm --wraps=nvm --description "Node Version Manager via bass"
            bass source "$NVM_DIR/nvm.sh" --no-use \; nvm $argv
        end
    else
        # Pure fish nvm wrapper
        function nvm --description "Node Version Manager (fish wrapper)"
            set -l nvm_cmd $argv[1]
            set -l nvm_args $argv[2..-1]

            switch $nvm_cmd
                case use
                    set -l ver $nvm_args[1]
                    set -l node_path "$NVM_DIR/versions/node/$ver/bin"
                    if test -d $node_path
                        fish_add_path --prepend --global $node_path
                        set --global NVM_BIN $node_path
                        set --global NVM_INC "$NVM_DIR/versions/node/$ver/include/node"
                        echo $_nvm_green"  ✓ Now using node $ver"$_nvm_reset
                    else
                        echo $_nvm_red"  ✗ Node $ver not installed. Run: nvm install $ver"$_nvm_reset
                    end
                case install
                    bash -c "source $NVM_DIR/nvm.sh && nvm install $nvm_args"
                case ls list
                    bash -c "source $NVM_DIR/nvm.sh && nvm ls $nvm_args"
                case current
                    node --version 2>/dev/null; or echo "none"
                case '*'
                    bash -c "source $NVM_DIR/nvm.sh && nvm $nvm_cmd $nvm_args"
            end
        end
    end

    echo "[nvm] initialized NVM_DIR=$NVM_DIR" >> $_ash_nvm_log 2>/dev/null
end

# ─── n: Simple Node version manager ──────────────────────────────────────────
function __ash_nvm_init_n --description "Initialize n"
    set --export N_PREFIX "$HOME/.n"
    fish_add_path --prepend --global "$N_PREFIX/bin"
    echo "[n] initialized N_PREFIX=$N_PREFIX" >> $_ash_nvm_log 2>/dev/null
end

# ── Run the right initializer ─────────────────────────────────────────────────
switch $_ash_nvm_backend
    case fnm
        __ash_nvm_init_fnm
    case volta
        __ash_nvm_init_volta
    case mise
        __ash_nvm_init_mise
    case asdf
        __ash_nvm_init_asdf
    case nvm-fish
        __ash_nvm_init_nvm_fish
    case nvm
        __ash_nvm_init_nvm
    case n
        __ash_nvm_init_n
    case system
        # System node — nothing to init
        echo "[system] using system node" >> $_ash_nvm_log 2>/dev/null
    case none
        # No node version manager found — exit silently
        exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 AUTO-SWITCHING: Detect .nvmrc / .node-version on directory change       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_nvm_resolve_version --description "Resolve required Node version from project files"
    # Walk up directory tree looking for version files
    set -l dir (pwd)

    while test "$dir" != "/"
        # .nvmrc
        if test -f "$dir/.nvmrc"
            string trim < "$dir/.nvmrc"
            return
        end

        # .node-version
        if test -f "$dir/.node-version"
            string trim < "$dir/.node-version"
            return
        end

        # .tool-versions (asdf/mise format)
        if test -f "$dir/.tool-versions"
            set -l ver (grep '^node\s' "$dir/.tool-versions" 2>/dev/null | awk '{print $2}')
            test -n "$ver" && echo $ver && return
        end

        # package.json → engines.node
        if test -f "$dir/package.json" && command -q jq
            set -l engine_ver (jq -r '.engines.node // empty' "$dir/package.json" 2>/dev/null)
            if test -n "$engine_ver"
                # Strip semver ranges to get plain version
                echo $engine_ver | string replace -r '[^0-9\.].*$' '' | string replace -r '^\^|^~|^>=?|^<=?' ''
                return
            end
        end

        set dir (dirname $dir)
    end

    echo ""
end

function __ash_nvm_auto_switch --on-variable PWD \
    --description "Auto-switch Node version on directory change"

    # Skip for backends that handle this natively
    switch $_ash_nvm_backend
        case fnm mise
            # These handle --use-on-cd natively
            return
        case volta
            # Volta handles project switching automatically
            return
    end

    set -l required (__ash_nvm_resolve_version)
    test -z "$required" && return

    set -l current (node --version 2>/dev/null | string replace 'v' '')

    # Normalize: strip 'v' prefix
    set -l required_clean (string replace 'v' '' $required)

    # Skip if already on correct version
    if test "$current" = "$required_clean"
        return
    end

    # Cache lookup: avoid re-switching for same dir
    set -l cache_key (echo (pwd) | md5sum | awk '{print $1}')
    set -l cache_file "$_ash_nvm_cache_dir/$cache_key"

    if test -f $cache_file
        set -l cached (cat $cache_file)
        if test "$cached" = "$required_clean"
            return
        end
    end

    # Perform the switch
    switch $_ash_nvm_backend
        case nvm nvm-fish
            nvm use $required 2>/dev/null
            and echo $required_clean > $cache_file
            and echo $_nvm_green"  ⬢ Node "$_nvm_cyan$required$_nvm_reset" (auto)"
        case asdf
            asdf shell nodejs $required 2>/dev/null
            and echo $required_clean > $cache_file
            and echo $_nvm_green"  ⬢ Node "$_nvm_cyan$required$_nvm_reset" (asdf auto)"
        case n
            n $required 2>/dev/null
            and echo $required_clean > $cache_file
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  NODE ECOSYSTEM SETUP                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Global npm prefix (avoid sudo) ───────────────────────────────────────────
if command -q node
    set --export NPM_CONFIG_PREFIX "$HOME/.npm-global"
    fish_add_path --append --global "$HOME/.npm-global/bin"

    # npm cache dir
    set --export NPM_CONFIG_CACHE "$HOME/.cache/npm"

    # pnpm home
    if command -q pnpm; or test -d "$HOME/.local/share/pnpm"
        set --export PNPM_HOME "$HOME/.local/share/pnpm"
        fish_add_path --prepend --global $PNPM_HOME
    end

    # Bun
    if test -d "$HOME/.bun"
        set --export BUN_INSTALL "$HOME/.bun"
        fish_add_path --prepend --global "$HOME/.bun/bin"
    end

    # Deno
    if test -d "$HOME/.deno"
        set --export DENO_INSTALL "$HOME/.deno"
        fish_add_path --prepend --global "$HOME/.deno/bin"
    end

    # Yarn Berry
    if command -q yarn
        set --export YARN_GLOBAL_FOLDER "$HOME/.yarn"
    end

    # corepack (manages yarn/pnpm versions)
    set --export COREPACK_ENABLE_STRICT 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── node-info: Rich Node.js environment info ─────────────────────────────────
function node-info --description "Show complete Node.js environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     ⬢  Node.js Environment                          ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""
    echo "  "$bold"Backend:   "$reset $_ash_nvm_backend
    echo "  "$bold"Node:      "$reset $cyan(node --version 2>/dev/null; or echo "not found")$reset
    echo "  "$bold"npm:       "$reset $dim(npm --version 2>/dev/null; or echo "not found")$reset
    echo "  "$bold"Path:      "$reset $dim(command -v node 2>/dev/null)$reset
    echo ""

    # Package managers
    echo "  "$bold"Package Managers:"$reset
    for pm in npm pnpm yarn bun deno
        if command -q $pm
            set -l ver ($pm --version 2>/dev/null)
            printf "    $green%-8s$reset %s\n" $pm $dim$ver$reset
        end
    end
    echo ""

    # Version manager info
    switch $_ash_nvm_backend
        case fnm
            echo "  "$bold"fnm versions:"$reset
            fnm list 2>/dev/null | while read -l line
                echo "    "$dim$line$reset
            end
        case nvm nvm-fish
            echo "  "$bold"nvm versions:"$reset
            nvm ls 2>/dev/null | head -10 | while read -l line
                echo "    "$dim$line$reset
            end
        case volta
            echo "  "$bold"Volta toolchain:"$reset
            volta list 2>/dev/null | while read -l line
                echo "    "$dim$line$reset
            end
    end

    echo ""
    # Project context
    set -l proj_ver (__ash_nvm_resolve_version)
    if test -n "$proj_ver"
        echo "  "$bold"Project requires: "$reset $yellow$proj_ver$reset
    end

    # Global packages
    if command -q npm
        set -l glob_count (npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l)
        echo "  "$bold"Global packages: "$reset $cyan$glob_count$reset
    end

    echo ""
end

# ─── node-switch: Switch Node version with smart backend dispatch ─────────────
function node-switch --description "Switch Node.js version"
    set -l version $argv[1]

    if test -z "$version"
        # Interactive picker
        switch $_ash_nvm_backend
            case fnm
                set version (fnm list 2>/dev/null | \
                    string replace -r '^\* ' '' | \
                    string trim | \
                    fzf --border-label '  Node Versions ' \
                        --border rounded \
                        --prompt '  ⬢ ' \
                        --preview 'echo "Node {}"' \
                        --header '  Enter:switch  ' 2>/dev/null)
            case nvm nvm-fish
                set version (nvm ls 2>/dev/null | \
                    grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | \
                    fzf --border-label '  Node Versions ' \
                        --border rounded \
                        --prompt '  ⬢ ' 2>/dev/null | \
                    string replace 'v' '')
            case '*'
                echo "  Usage: node-switch <version>"
                return 1
        end
        test -z "$version" && return 0
    end

    echo ""
    echo $_nvm_cyan"  ⬢ Switching to Node $version..."$_nvm_reset

    switch $_ash_nvm_backend
        case fnm
            fnm use $version 2>/dev/null
            or fnm install $version
        case nvm nvm-fish
            nvm use $version 2>/dev/null
            or nvm install $version
        case volta
            volta install node@$version
        case mise
            mise use --global node@$version
        case asdf
            asdf install nodejs $version
            and asdf global nodejs $version
        case n
            n $version
    end

    echo ""
    echo $_nvm_green"  ✓ Node "(node --version 2>/dev/null)$_nvm_reset
end

# ─── node-install-lts: Install latest LTS ─────────────────────────────────────
function node-install-lts --description "Install latest Node.js LTS release"
    echo ""
    echo $_nvm_cyan"  ⬢ Installing Node.js LTS..."$_nvm_reset
    echo ""

    switch $_ash_nvm_backend
        case fnm
            fnm install --lts
            and fnm use lts-latest 2>/dev/null
        case nvm nvm-fish
            nvm install --lts
            and nvm use --lts
        case volta
            volta install node@lts
        case mise
            mise use --global node@lts
        case asdf
            set -l lts (asdf latest nodejs 2>/dev/null)
            asdf install nodejs $lts
            and asdf global nodejs $lts
        case n
            n lts
    end

    echo ""
    echo $_nvm_green"  ✓ LTS installed: "(node --version 2>/dev/null)$_nvm_reset
    echo ""
end

# ─── node-install-latest: Install latest Node.js ──────────────────────────────
function node-install-latest --description "Install latest Node.js release"
    echo ""
    echo $_nvm_cyan"  ⬢ Installing Node.js latest..."$_nvm_reset
    echo ""

    switch $_ash_nvm_backend
        case fnm
            fnm install latest
            and fnm use latest
        case nvm nvm-fish
            nvm install node
            and nvm use node
        case volta
            volta install node@latest
        case mise
            mise use --global node@latest
        case n
            n latest
    end

    echo $_nvm_green"  ✓ Latest installed: "(node --version 2>/dev/null)$_nvm_reset
end

# ─── node-list: List installed Node versions ──────────────────────────────────
function node-list --description "List all installed Node.js versions"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ⬢ Installed Node.js Versions ($_ash_nvm_backend)"$reset
    echo ""

    switch $_ash_nvm_backend
        case fnm
            fnm list 2>/dev/null | while read -l line
                if string match -q '* *' $line
                    echo $green"  → "$reset$bold(string replace '* ' '' $line)$reset" (current)"
                else
                    echo "    "$dim$line$reset
                end
            end
        case nvm nvm-fish
            nvm ls 2>/dev/null | while read -l line
                echo "  "$dim$line$reset
            end
        case volta
            volta list 2>/dev/null | while read -l line
                echo "  "$dim$line$reset
            end
        case mise
            mise ls node 2>/dev/null | while read -l line
                echo "  "$dim$line$reset
            end
        case asdf
            asdf list nodejs 2>/dev/null | while read -l line
                echo "  "$dim$line$reset
            end
        case system
            echo "  "$green"system: "(node --version 2>/dev/null)$reset
    end
    echo ""
end

# ─── npm-global-list: Rich global packages table ─────────────────────────────
function npm-global-list --description "List globally installed npm packages"
    command -q npm || return 1

    set -l reset (set_color normal)
    set -l bold  (set_color --bold)
    set -l cyan  (set_color cyan)
    set -l dim   (set_color brblack)

    echo ""
    echo $bold$cyan"  📦 Global npm Packages"$reset
    echo ""
    printf "  $bold%-30s  %-12s  %s$reset\n" "Package" "Version" "Description"
    printf "  $dim%s$reset\n" "──────────────────────────────────────────────────────"

    npm list -g --depth=0 --json 2>/dev/null |
    command -q jq && jq -r '
        .dependencies // {} |
        to_entries[] |
        [.key, (.value.version // "?"), (.value.description // "")] |
        @tsv
    ' | while read -l line
        set -l parts (string split \t $line)
        printf "  %-30s  $cyan%-12s$reset  $dim%s$reset\n" $parts[1] $parts[2] $parts[3]
    end

    echo ""
end

# ─── npm-clean: Deep clean node_modules ──────────────────────────────────────
function npm-clean --description "Deep clean node_modules, cache & lock files"
    echo ""
    echo $_nvm_yellow"  🧹 Cleaning Node.js artifacts..."$_nvm_reset
    echo ""

    set -l removed 0

    # Remove node_modules
    if test -d node_modules
        set -l size (du -sh node_modules 2>/dev/null | awk '{print $1}')
        rm -rf node_modules
        echo $_nvm_green"  ✓ Removed node_modules ($size)"$_nvm_reset
        set removed (math $removed + 1)
    end

    # Remove lock files (optional)
    read -P "  Remove lock files? [y/N] " rm_lock
    if string match -qi 'y*' $rm_lock
        for lockfile in package-lock.json yarn.lock pnpm-lock.yaml bun.lockb
            if test -f $lockfile
                rm -f $lockfile
                echo $_nvm_green"  ✓ Removed $lockfile"$_nvm_reset
                set removed (math $removed + 1)
            end
        end
    end

    # Clean npm cache
    command -q npm && npm cache clean --force 2>/dev/null
    echo $_nvm_green"  ✓ npm cache cleaned"$_nvm_reset

    echo ""
    echo $_nvm_green"  ✓ Cleaned $removed artifact(s)"$_nvm_reset
    echo ""
end

# ─── npm-outdated-rich: Rich outdated packages view ───────────────────────────
function npm-outdated-rich --description "Show outdated npm packages with rich display"
    command -q npm || return 1

    echo ""
    echo $_nvm_cyan"  📦 Checking for outdated packages..."$_nvm_reset
    echo ""

    set -l output (npm outdated --json 2>/dev/null)
    if test -z "$output" || test "$output" = "{}"
        echo $_nvm_green"  ✓ All packages are up to date!"$_nvm_reset
        echo ""
        return
    end

    printf "  $_nvm_bold%-30s  %-12s  %-12s  %s$_nvm_reset\n" \
        "Package" "Current" "Latest" "Type"
    printf "  $_nvm_dim%s$_nvm_reset\n" \
        "──────────────────────────────────────────────────────────"

    echo $output | command -q jq && jq -r '
        to_entries[] |
        [.key, (.value.current // "?"), (.value.latest // "?"), (.value.type // "?")] |
        @tsv
    ' | while read -l line
        set -l parts (string split \t $line)
        set -l type_color $_nvm_dim
        test "$parts[4]" = dependencies && set type_color $_nvm_yellow
        test "$parts[4]" = devDependencies && set type_color $_nvm_blue

        printf "  %-30s  $_nvm_red%-12s$_nvm_reset  $_nvm_green%-12s$_nvm_reset  %s%s$_nvm_reset\n" \
            $parts[1] $parts[2] $parts[3] $type_color $parts[4]
    end
    echo ""
end

# ─── node-project-init: Smart project initializer ────────────────────────────
function node-project-init --description "Initialize a Node.js project with best practices"
    set -l name    $argv[1]
    set -l manager $argv[2]

    test -z "$name"    && set name    (basename $PWD)
    test -z "$manager" && set manager "pnpm"

    echo ""
    echo $_nvm_bold$_nvm_cyan"  ╔══════════════════════════════════════╗"$_nvm_reset
    echo $_nvm_bold$_nvm_cyan"  ║  ⬢  Node.js Project: $name"$_nvm_reset
    echo $_nvm_bold$_nvm_cyan"  ╚══════════════════════════════════════╝"$_nvm_reset
    echo ""

    # Write .nvmrc with current node version
    node --version 2>/dev/null | string replace 'v' '' > .nvmrc
    echo $_nvm_green"  ✓ .nvmrc → "(cat .nvmrc)$_nvm_reset

    # Init package.json
    switch $manager
        case pnpm
            command -q pnpm && pnpm init
        case yarn
            command -q yarn && yarn init -y
        case bun
            command -q bun && bun init
        case '*'
            npm init -y
    end

    # Write recommended .npmrc / .pnpmfile
    echo "save-exact=true\nengine-strict=true" > .npmrc
    echo $_nvm_green"  ✓ .npmrc created"$_nvm_reset

    # .node-version for volta compatibility
    node --version 2>/dev/null > .node-version
    echo $_nvm_green"  ✓ .node-version created"$_nvm_reset

    echo ""
    echo $_nvm_green"  ✓ Project initialized: $name"$_nvm_reset
    echo ""
end

# ─── pnpm-workspace: Create pnpm monorepo workspace ─────────────────────────
function pnpm-workspace --description "Initialize a pnpm monorepo workspace"
    command -q pnpm || begin; echo "pnpm not installed"; return 1; end

    echo ""
    echo $_nvm_cyan"  📦 Creating pnpm monorepo workspace..."$_nvm_reset

    # workspace config
    printf 'packages:\n  - "packages/*"\n  - "apps/*"\n' > pnpm-workspace.yaml
    mkdir -p packages apps

    # root package.json
    printf '{\n  "name": "%s",\n  "private": true,\n  "engines": {"node": ">=%s"}\n}\n' \
        (basename $PWD) (node --version | string replace 'v' '') > package.json

    echo $_nvm_green"  ✓ pnpm-workspace.yaml created"$_nvm_reset
    echo $_nvm_green"  ✓ packages/ and apps/ directories created"$_nvm_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Node version management
abbr --add nls    'node-list'
abbr --add nsw    'node-switch'
abbr --add nlts   'node-install-lts'
abbr --add nlat   'node-install-latest'
abbr --add ninfo  'node-info'
abbr --add ninit  'node-project-init'

# npm
abbr --add ni     'npm install'
abbr --add nid    'npm install --save-dev'
abbr --add nig    'npm install -g'
abbr --add nrm    'npm remove'
abbr --add nup    'npm update'
abbr --add nout   'npm-outdated-rich'
abbr --add ngl    'npm-global-list'
abbr --add nrun   'npm run'
abbr --add nst    'npm start'
abbr --add ntest  'npm test'
abbr --add nbld   'npm run build'
abbr --add ndev   'npm run dev'
abbr --add nlint  'npm run lint'
abbr --add nclean 'npm-clean'
abbr --add nci    'npm ci'
abbr --add nau    'npm audit'
abbr --add nauf   'npm audit fix'

# pnpm
abbr --add pi     'pnpm install'
abbr --add pid    'pnpm install -D'
abbr --add pig    'pnpm add -g'
abbr --add prm    'pnpm remove'
abbr --add pup    'pnpm update'
abbr --add prun   'pnpm run'
abbr --add pst    'pnpm start'
abbr --add ptest  'pnpm test'
abbr --add pbld   'pnpm build'
abbr --add pdev   'pnpm dev'
abbr --add pdlx   'pnpm dlx'
abbr --add px     'pnpm dlx'
abbr --add pwspc  'pnpm-workspace'

# yarn
abbr --add ya     'yarn add'
abbr --add yad    'yarn add -D'
abbr --add yag    'yarn global add'
abbr --add yrm    'yarn remove'
abbr --add yup    'yarn upgrade'
abbr --add yrun   'yarn run'
abbr --add yst    'yarn start'
abbr --add ytest  'yarn test'
abbr --add ybld   'yarn build'
abbr --add ydev   'yarn dev'
abbr --add ydlx   'yarn dlx'

# bun
abbr --add ba     'bun add'
abbr --add bad    'bun add -d'
abbr --add brm    'bun remove'
abbr --add brun   'bun run'
abbr --add bst    'bun start'
abbr --add btest  'bun test'
abbr --add bbld   'bun build'
abbr --add bdev   'bun dev'
abbr --add bx     'bunx'

# fnm specific
abbr --add fnmls  'fnm list'
abbr --add fnmuse 'fnm use'
abbr --add fnminst 'fnm install'
abbr --add fnmrm  'fnm uninstall'
abbr --add fnmlts 'fnm install --lts'