# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — pnpm Ultra Configuration                           ║
# ║  Performant Node package manager with workspace, catalogs & full ecosystem  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_pnpm_loaded && exit 0
set --global _ash_pnpm_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_pnpm_log      "$HOME/.local/share/ash/logs/pnpm.log"
set --global _ash_pnpm_cache    "$HOME/.local/share/ash/cache/pnpm"

mkdir -p (dirname $_ash_pnpm_log) 2>/dev/null
mkdir -p $_ash_pnpm_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION & SETUP                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Detect pnpm via multiple methods
function __ash_pnpm_find --description "Find pnpm executable"
    # Direct command
    if command -q pnpm
        echo (command -v pnpm)
        return
    end

    # PNPM_HOME
    if test -n "$PNPM_HOME" && test -x "$PNPM_HOME/pnpm"
        echo "$PNPM_HOME/pnpm"
        return
    end

    # Common locations
    for candidate in \
        "$HOME/.local/share/pnpm/pnpm" \
        "$HOME/.pnpm/pnpm" \
        "/usr/local/bin/pnpm" \
        (node -e "process.stdout.write(require('child_process').execSync('npm root -g').toString().trim())" 2>/dev/null)"/pnpm/.bin/pnpm"
        if test -x $candidate
            echo $candidate
            return
        end
    end

    echo ""
end

set --global _ash_pnpm_bin (__ash_pnpm_find)

# Exit if pnpm not found
if test -z "$_ash_pnpm_bin"
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _pn_reset   (set_color normal)
set -g _pn_bold    (set_color --bold)
set -g _pn_cyan    (set_color cyan)
set -g _pn_green   (set_color green)
set -g _pn_yellow  (set_color yellow)
set -g _pn_red     (set_color red)
set -g _pn_blue    (set_color blue)
set -g _pn_purple  (set_color magenta)
set -g _pn_dim     (set_color brblack)
set -g _pn_orange  (set_color F69220)   # pnpm orange

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── PNPM_HOME: Global store location ──────────────────────────────────────────
if test -z "$PNPM_HOME"
    set --export PNPM_HOME "$HOME/.local/share/pnpm"
end

# Add pnpm global binaries to PATH
if not contains $PNPM_HOME $PATH
    fish_add_path --prepend --global $PNPM_HOME
end

# ── Store configuration ────────────────────────────────────────────────────────
# Content-addressable store path (shared across projects)
set --export PNPM_STORE_DIR "$HOME/.local/share/pnpm-store"

# ── Corepack integration ───────────────────────────────────────────────────────
set --export COREPACK_ENABLE_STRICT 0

# ── Shell completions ──────────────────────────────────────────────────────────
# Generate pnpm completions for fish
pnpm completion fish 2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 AUTO-DETECTION: Project package manager detection                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_pnpm_detect_project --description "Detect if project uses pnpm"
    # Check for pnpm-specific files
    test -f pnpm-lock.yaml  && return 0
    test -f .pnpmfile.cjs   && return 0
    test -f pnpm-workspace.yaml && return 0

    # Check packageManager field in package.json
    if test -f package.json && command -q jq
        set -l pm (jq -r '.packageManager // ""' package.json 2>/dev/null)
        string match -q 'pnpm*' $pm && return 0
    end

    return 1
end

# ─── Auto-detect on directory change ─────────────────────────────────────────
function __ash_pnpm_on_dir_change --on-variable PWD \
    --description "Hint when entering a pnpm project"
    if __ash_pnpm_detect_project
        # Verify node_modules are up to date
        if test -f pnpm-lock.yaml && not test -d node_modules
            echo ""
            echo $_pn_yellow"  💡 pnpm project — run: pnpm install"$_pn_reset
        end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  ENHANCED PNPM FUNCTIONS                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── pnpm-info: Rich pnpm environment dashboard ───────────────────────────────
function pnpm-info --description "Show pnpm environment dashboard"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l orange (set_color F69220)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     📦  pnpm Dashboard                               ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:    "$reset $cyan(pnpm --version 2>/dev/null)$reset
    echo "  "$bold"PNPM_HOME:  "$reset $dim$PNPM_HOME$reset
    echo "  "$bold"Store:      "$reset $dim$PNPM_STORE_DIR$reset
    echo ""

    # Store size
    set -l store_size (du -sh $PNPM_STORE_DIR 2>/dev/null | awk '{print $1}')
    test -n "$store_size" && \
        echo "  "$bold"Store size: "$reset $cyan$store_size$reset
    echo ""

    # Project detection
    if __ash_pnpm_detect_project
        echo "  "$green"✓ pnpm project detected"$reset
        if test -f package.json && command -q jq
            set -l name    (jq -r '.name    // "?"' package.json 2>/dev/null)
            set -l version (jq -r '.version // "?"' package.json 2>/dev/null)
            set -l pm      (jq -r '.packageManager // ""' package.json 2>/dev/null)
            echo "  "$bold"Name:    "$reset $cyan$name$reset" v"$version
            test -n "$pm" && echo "  "$bold"Manager: "$reset $dim$pm$reset
        end

        # Workspace?
        if test -f pnpm-workspace.yaml
            set -l ws_count (grep -c 'packages:' pnpm-workspace.yaml 2>/dev/null)
            echo "  "$bold"Workspace: "$reset $green"yes"$reset
        end
    end

    echo ""

    # Global packages
    set -l global_count (pnpm list -g --depth=0 --parseable 2>/dev/null | wc -l | string trim)
    echo "  "$bold"Global packages: "$reset $cyan$global_count$reset
    echo ""
end

# ─── pnpm-scripts: Show all available scripts ─────────────────────────────────
function pnpm-scripts --description "Show all available pnpm scripts with descriptions"
    if not test -f package.json
        echo $_pn_red"  ✗ No package.json found"$_pn_reset
        return 1
    end

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)
    set -l orange (set_color F69220)

    echo ""
    echo $bold$orange"  📜 pnpm scripts"$reset
    echo ""

    command -q jq || begin
        cat package.json
        return
    end

    jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' \
        package.json 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        set -l script_name $parts[1]
        set -l script_cmd  $parts[2]
        printf "  $cyan%-20s$reset  $dim%s$reset\n" $script_name $script_cmd
    end
    echo ""
end

# ─── pnpm-run-smart: Run script with fuzzy picker ─────────────────────────────
function pnpm-run-smart --description "Run pnpm script via interactive fuzzy picker"
    set -l script $argv[1]

    if test -z "$script"
        if command -q fzf && test -f package.json && command -q jq
            set script (
                jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' \
                    package.json 2>/dev/null |
                fzf --ansi \
                    --border-label "  📦 pnpm scripts " \
                    --border rounded \
                    --prompt "  ▶ " \
                    --pointer "▶" \
                    --preview 'echo "Script: {1}\n\nCommand: {2..}"' \
                    --preview-window 'down:3:border-rounded:wrap' \
                    --header '  Enter:run  ' \
                | awk '{print $1}'
            )
            test -z "$script" && return 0
        else
            pnpm-scripts
            echo ""
            read -P "  Script to run: " script
        end
    end

    test -z "$script" && return 1

    echo ""
    echo $_pn_cyan"  ▶ pnpm run $script"$_pn_reset
    echo ""
    pnpm run $script $argv[2..-1]
end

# ─── pnpm-upgrade-interactive: Interactive package upgrader ───────────────────
function pnpm-upgrade-interactive --description "Interactively upgrade pnpm packages"
    if not test -f package.json
        echo $_pn_red"  ✗ No package.json found"$_pn_reset
        return 1
    end

    echo ""
    echo $_pn_cyan"  🔄 Checking for outdated packages..."$_pn_reset
    echo ""

    # Get outdated packages
    set -l outdated (pnpm outdated --format json 2>/dev/null)

    if test -z "$outdated" || test "$outdated" = "{}"
        echo $_pn_green"  ✓ All packages are up to date!"$_pn_reset
        echo ""
        return
    end

    if command -q fzf && command -q jq
        # Interactive selection
        set -l selected (
            echo $outdated | jq -r '
                to_entries[] |
                "\(.key)\t\(.value.current // "?")\t→\t\(.value.latest // "?")"
            ' 2>/dev/null |
            fzf --ansi \
                --border-label "  📦 Outdated Packages " \
                --border rounded \
                --prompt "  ⬆  " \
                --pointer "▶" \
                --marker "✓" \
                --multi \
                --header '  Tab:multi-select  Enter:upgrade  ' \
            | awk '{print $1}'
        )

        if test -n "$selected"
            for pkg in $selected
                echo $_pn_cyan"  ⬆ Upgrading: $pkg"$_pn_reset
                pnpm update $pkg --latest
            end
            echo $_pn_green"  ✓ Upgrade complete"$_pn_reset
        end
    else
        pnpm update --interactive --latest
    end
end

# ─── pnpm-clean: Deep clean project artifacts ─────────────────────────────────
function pnpm-clean --description "Deep clean pnpm project artifacts"
    echo ""
    echo $_pn_yellow"  🧹 Cleaning pnpm project..."$_pn_reset
    echo ""

    set -l removed 0

    # node_modules
    if test -d node_modules
        set -l size (du -sh node_modules 2>/dev/null | awk '{print $1}')
        rm -rf node_modules
        echo $_pn_green"  ✓ node_modules removed ($size)"$_pn_reset
        set removed (math $removed + 1)
    end

    # Workspace node_modules
    if test -f pnpm-workspace.yaml && command -q find
        find . -name node_modules -not -path "*/\.*" -type d 2>/dev/null | \
        while read -l dir
            set -l size (du -sh $dir 2>/dev/null | awk '{print $1}')
            rm -rf $dir
            echo $_pn_green"  ✓ $dir ($size)"$_pn_reset
            set removed (math $removed + 1)
        end
    end

    # Build directories
    for build_dir in dist build out .next .nuxt .svelte-kit
        if test -d $build_dir
            set -l size (du -sh $build_dir 2>/dev/null | awk '{print $1}')
            rm -rf $build_dir
            echo $_pn_green"  ✓ $build_dir removed ($size)"$_pn_reset
            set removed (math $removed + 1)
        end
    end

    # pnpm cache
    read -P "  Clean pnpm store cache? [y/N] " clean_store
    if string match -qi 'y*' $clean_store
        pnpm store prune 2>/dev/null
        echo $_pn_green"  ✓ Store pruned"$_pn_reset
    end

    echo ""
    echo $_pn_green"  ✓ Cleaned $removed artifact(s)"$_pn_reset
    echo ""
end

# ─── pnpm-workspace-info: Workspace overview ──────────────────────────────────
function pnpm-workspace-info --description "Show pnpm workspace package information"
    if not test -f pnpm-workspace.yaml
        echo $_pn_yellow"  ℹ  Not a pnpm workspace (no pnpm-workspace.yaml)"$_pn_reset
        return
    end

    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)
    set -l orange (set_color F69220)

    echo ""
    echo $bold$orange"  🗂️  pnpm Workspace"$reset
    echo ""

    # List workspace packages
    pnpm ls -r --depth 0 --parseable 2>/dev/null | \
    while read -l pkg_path
        test -f "$pkg_path/package.json" || continue

        if command -q jq
            set -l name    (jq -r '.name    // "unknown"' "$pkg_path/package.json" 2>/dev/null)
            set -l version (jq -r '.version // "0.0.0"'   "$pkg_path/package.json" 2>/dev/null)
            set -l desc    (jq -r '.description // ""'     "$pkg_path/package.json" 2>/dev/null)
            set -l relative (string replace $PWD '.' $pkg_path)
            printf "  $cyan%-30s$reset $dim%-10s$reset  %s\n" $name $version $dim$desc$reset
        else
            echo "  "$dim$pkg_path$reset
        end
    end
    echo ""
end

# ─── pnpm-why-smart: Interactive pnpm why ─────────────────────────────────────
function pnpm-why-smart --description "Explain why a package is installed (interactive)"
    set -l pkg $argv[1]

    if test -z "$pkg"
        if command -q fzf && test -d node_modules
            set pkg (
                ls node_modules 2>/dev/null |
                grep -v '^\.' |
                fzf --border-label "  📦 Select Package " \
                    --border rounded \
                    --prompt "  🔍 " \
                    --preview 'cat node_modules/{}/package.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20' \
                    --preview-window 'right:40%:border-rounded'
            )
            test -z "$pkg" && return 0
        else
            echo "  Usage: pnpm-why-smart <package>"
            return 1
        end
    end

    echo ""
    echo $_pn_cyan"  🔍 Why is '$pkg' installed?"$_pn_reset
    echo ""
    pnpm why $pkg
end

# ─── pnpm-store-stats: Show store statistics ──────────────────────────────────
function pnpm-store-stats --description "Show pnpm content-addressable store statistics"
    echo ""
    echo $_pn_bold$_pn_orange"  🏪 pnpm Store Statistics"$_pn_reset
    echo ""

    set -l store_path (pnpm store path 2>/dev/null)
    echo "  "$_pn_bold"Path:   "$_pn_reset $_pn_dim$store_path$_pn_reset

    if test -n "$store_path" && test -d "$store_path"
        set -l total_size (du -sh $store_path 2>/dev/null | awk '{print $1}')
        set -l file_count (find $store_path -type f 2>/dev/null | wc -l | string trim)
        echo "  "$_pn_bold"Size:   "$_pn_reset $_pn_cyan$total_size$_pn_reset
        echo "  "$_pn_bold"Files:  "$_pn_reset $_pn_cyan$file_count$_pn_reset
    end

    echo ""
    echo "  "$_pn_bold"Running store prune check..."$_pn_reset
    pnpm store status 2>/dev/null
    echo ""
end

# ─── pnpm-link-smart: Smart package linking ───────────────────────────────────
function pnpm-link-smart --description "Link a local package or to workspace"
    set -l action $argv[1]
    set -l target $argv[2]

    switch $action
        case global
            echo $_pn_cyan"  🔗 Linking to global pnpm..."$_pn_reset
            pnpm link --global
            and echo $_pn_green"  ✓ Linked globally"$_pn_reset

        case from
            test -z "$target" && begin; echo "  Usage: pnpm-link-smart from <package>"; return 1; end
            pnpm link $target
            and echo $_pn_green"  ✓ Linked: $target"$_pn_reset

        case unlink
            pnpm unlink 2>/dev/null
            and echo $_pn_yellow"  ✓ Unlinked"$_pn_reset

        case '*'
            echo "  Usage: pnpm-link-smart [global|from <pkg>|unlink]"
    end
end

# ─── pnpm-audit-fix: Security audit + auto-fix ────────────────────────────────
function pnpm-audit-fix --description "Run pnpm security audit and attempt fixes"
    echo ""
    echo $_pn_cyan"  🔒 Running pnpm security audit..."$_pn_reset
    echo ""

    pnpm audit 2>/dev/null
    set -l audit_rc $status

    if test $audit_rc -ne 0
        echo ""
        read -P "  Attempt automatic fixes? [y/N] " fix_now
        if string match -qi 'y*' $fix_now
            pnpm audit --fix 2>/dev/null
            and echo $_pn_green"  ✓ Fixes applied"$_pn_reset
            or  echo $_pn_yellow"  ⚠  Some vulnerabilities require manual fixes"$_pn_reset
        end
    else
        echo $_pn_green"  ✓ No vulnerabilities found"$_pn_reset
    end
    echo ""
end

# ─── pnpm-init-smart: Smart project initialization ────────────────────────────
function pnpm-init-smart --description "Initialize a new pnpm project with best practices"
    set -l name    $argv[1]
    set -l type    $argv[2]   # app | lib | workspace | monorepo

    test -z "$name"  && set name (basename $PWD)
    test -z "$type"  && set type app

    echo ""
    echo $_pn_bold$_pn_orange"  ╔══════════════════════════════════════╗"$_pn_reset
    echo $_pn_bold$_pn_orange"  ║  📦 pnpm Project: $name"$_pn_reset
    echo $_pn_bold$_pn_orange"  ╚══════════════════════════════════════╝"$_pn_reset
    echo ""

    # Init package.json
    pnpm init 2>/dev/null

    # Set packageManager field
    set -l pnpm_ver (pnpm --version 2>/dev/null)
    command -q jq && \
        jq --arg pm "pnpm@$pnpm_ver" '.packageManager = $pm' package.json \
        > /tmp/pkg.json 2>/dev/null && mv /tmp/pkg.json package.json

    # Write .npmrc
    printf "# pnpm configuration\nsave-exact=true\nauto-install-peers=true\nstrict-peer-dependencies=false\nresolution-mode=highest\nsharedWorkspaceLockfile=true\n" \
        > .npmrc
    echo $_pn_green"  ✓ .npmrc created"$_pn_reset

    switch $type
        case workspace monorepo
            # Create workspace config
            printf 'packages:\n  - "packages/*"\n  - "apps/*"\n  - "tools/*"\n' \
                > pnpm-workspace.yaml
            mkdir -p packages apps tools
            echo $_pn_green"  ✓ pnpm-workspace.yaml created"$_pn_reset
            echo $_pn_green"  ✓ packages/ apps/ tools/ created"$_pn_reset

        case lib library
            # Library-specific setup
            command -q jq && \
                jq '. + {"main": "dist/index.js", "types": "dist/index.d.ts", "files": ["dist"]}' \
                    package.json > /tmp/pkg.json 2>/dev/null && mv /tmp/pkg.json package.json

        case '*' app
            # App defaults
            true
    end

    # Write node version
    node --version 2>/dev/null | string replace 'v' '' > .nvmrc
    echo $_pn_green"  ✓ .nvmrc created"$_pn_reset

    echo ""
    echo $_pn_green"  ✓ Project initialized: $name ($type)"$_pn_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ DYNAMIC COMPLETIONS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __pnpm_scripts --description "List pnpm scripts for completion"
    test -f package.json || return
    command -q jq && \
        jq -r '.scripts // {} | keys[]' package.json 2>/dev/null
end

function __pnpm_packages --description "List installed packages for completion"
    test -d node_modules && ls node_modules 2>/dev/null | grep -v '^\.'
end

function __pnpm_workspaces --description "List workspace packages for completion"
    pnpm ls -r --depth 0 --parseable 2>/dev/null | \
        xargs -I{} basename {} 2>/dev/null
end

complete -c pnpm-run-smart   -f -a '(__pnpm_scripts)'    -d "pnpm script"
complete -c pnpm-why-smart   -f -a '(__pnpm_packages)'   -d "Installed package"
complete -c pnpm-link-smart  -f -a "global from unlink"  -d "Link action"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core pnpm
abbr --add p      'pnpm'
abbr --add pi     'pnpm install'
abbr --add pa     'pnpm add'
abbr --add pad    'pnpm add -D'
abbr --add pag    'pnpm add -g'
abbr --add prm    'pnpm remove'
abbr --add pup    'pnpm update'
abbr --add pupl   'pnpm update --latest'
abbr --add prun   'pnpm-run-smart'
abbr --add pst    'pnpm start'
abbr --add pdev   'pnpm dev'
abbr --add pbld   'pnpm build'
abbr --add ptest  'pnpm test'
abbr --add plint  'pnpm lint'
abbr --add pfmt   'pnpm format'
abbr --add ptsc   'pnpm typecheck'

# pnpm dlx (execute)
abbr --add px     'pnpm dlx'
abbr --add pdlx   'pnpm dlx'
abbr --add pexec  'pnpm exec'

# Workspace
abbr --add pws    'pnpm-workspace-info'
abbr --add pwsr   'pnpm -r'           # recursive workspace run
abbr --add pwsf   'pnpm --filter'     # filter specific package
abbr --add pwsra  'pnpm run -r'

# Maintenance
abbr --add pinfo  'pnpm-info'
abbr --add pscr   'pnpm-scripts'
abbr --add pout   'pnpm outdated'
abbr --add pupi   'pnpm-upgrade-interactive'
abbr --add pclean 'pnpm-clean'
abbr --add paudit 'pnpm-audit-fix'
abbr --add pstore 'pnpm-store-stats'
abbr --add pprune 'pnpm store prune'
abbr --add pwhy   'pnpm-why-smart'
abbr --add plink  'pnpm-link-smart'
abbr --add pinit  'pnpm-init-smart'

# Lock file
abbr --add plock  'pnpm install --frozen-lockfile'
abbr --add punlock 'rm -f pnpm-lock.yaml && pnpm install'

# Global
abbr --add pgl    'pnpm list -g --depth=0'
abbr --add pga    'pnpm add -g'
abbr --add pgrm   'pnpm remove -g'
abbr --add pgup   'pnpm update -g'