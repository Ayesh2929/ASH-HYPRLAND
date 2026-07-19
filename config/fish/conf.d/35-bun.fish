# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Bun Ultra Configuration                            ║
# ║  All-in-one JS runtime, bundler, test runner & package manager             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_bun_loaded && exit 0
set --global _ash_bun_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_bun_log      "$HOME/.local/share/ash/logs/bun.log"
set --global _ash_bun_cache    "$HOME/.local/share/ash/cache/bun"

mkdir -p (dirname $_ash_bun_log) 2>/dev/null
mkdir -p $_ash_bun_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Find bun executable
function __ash_bun_find --description "Find bun executable"
    if command -q bun
        echo (command -v bun); return
    end
    for candidate in \
        "$HOME/.bun/bin/bun" \
        "$HOME/.local/bin/bun" \
        "/usr/local/bin/bun"
        test -x $candidate && echo $candidate && return
    end
    echo ""
end

set --global _ash_bun_bin (__ash_bun_find)

# Exit if bun not found
if test -z "$_ash_bun_bin"
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _bn_reset   (set_color normal)
set -g _bn_bold    (set_color --bold)
set -g _bn_cyan    (set_color cyan)
set -g _bn_green   (set_color green)
set -g _bn_yellow  (set_color yellow)
set -g _bn_red     (set_color red)
set -g _bn_blue    (set_color blue)
set -g _bn_purple  (set_color magenta)
set -g _bn_dim     (set_color brblack)
set -g _bn_pink    (set_color FBB8B8)   # Bun pink

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── BUN_INSTALL: Core installation directory ──────────────────────────────────
if test -z "$BUN_INSTALL"
    set --export BUN_INSTALL "$HOME/.bun"
end

# Add bun binaries to PATH
for bun_path in "$BUN_INSTALL/bin"
    if test -d $bun_path && not contains $bun_path $PATH
        fish_add_path --prepend --global $bun_path
    end
end

# ── Bun runtime flags ─────────────────────────────────────────────────────────
# Enable JSX transform
set --export BUN_JSX_RUNTIME "automatic"

# Bun config directory (XDG-aware)
set --export BUN_CONFIG_DIR "$HOME/.config/bun"
mkdir -p $BUN_CONFIG_DIR 2>/dev/null

# ── Shell completions ──────────────────────────────────────────────────────────
bun completions 2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 AUTO-DETECTION: Project detection                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_bun_detect_project --description "Detect if project uses bun"
    test -f bun.lockb   && return 0
    test -f bunfig.toml && return 0
    if test -f package.json && command -q jq
        set -l pm (jq -r '.packageManager // ""' package.json 2>/dev/null)
        string match -q 'bun*' $pm && return 0
    end
    return 1
end

function __ash_bun_on_dir_change --on-variable PWD \
    --description "Hint when entering a bun project"
    if __ash_bun_detect_project && not test -d node_modules
        echo ""
        echo $_bn_yellow"  🐰 bun project — run: bun install"$_bn_reset
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  ENHANCED BUN FUNCTIONS                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── bun-info: Rich bun environment dashboard ─────────────────────────────────
function bun-info --description "Show bun environment dashboard"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l pink   (set_color FBB8B8)

    echo ""
    echo $bold$pink"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$pink"  ║     🐰  Bun Runtime Dashboard                        ║"$reset
    echo $bold$pink"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    set -l ver (bun --version 2>/dev/null)
    set -l rev (bun --revision 2>/dev/null)

    echo "  "$bold"Version:     "$reset $cyan$ver$reset
    echo "  "$bold"Revision:    "$reset $dim$rev$reset
    echo "  "$bold"BUN_INSTALL: "$reset $dim$BUN_INSTALL$reset
    echo "  "$bold"Binary:      "$reset $dim$_ash_bun_bin$reset
    echo ""

    # Runtime info
    set -l node_compat (bun --version 2>/dev/null && echo "Node.js compatible")
    echo "  "$bold"Capabilities:"$reset
    echo "    "$green"✓"$reset" JavaScript/TypeScript runtime"
    echo "    "$green"✓"$reset" Package manager (npm/yarn/pnpm compat)"
    echo "    "$green"✓"$reset" Bundler (bun build)"
    echo "    "$green"✓"$reset" Test runner (bun test)"
    echo "    "$green"✓"$reset" Script runner (bun run)"
    echo "    "$green"✓"$reset" Shell (bun shell / bun --shell)"
    echo ""

    # Project detection
    if __ash_bun_detect_project
        echo "  "$green"🐰 bun project detected"$reset
        if test -f package.json && command -q jq
            set -l name (jq -r '.name // "?"' package.json 2>/dev/null)
            set -l ver  (jq -r '.version // "?"' package.json 2>/dev/null)
            echo "  "$bold"Package: "$reset $cyan$name$reset" v"$ver
        end
        test -f bunfig.toml && echo "  "$bold"Config:  "$reset $dim"bunfig.toml found"$reset
    end

    echo ""
end

# ─── bun-scripts: Show available scripts ──────────────────────────────────────
function bun-scripts --description "Show all available bun scripts"
    if not test -f package.json
        echo $_bn_red"  ✗ No package.json found"$_bn_reset
        return 1
    end

    echo ""
    echo $_bn_bold$_bn_pink"  📜 bun scripts"$_bn_reset
    echo ""

    command -q jq || begin; cat package.json; return; end

    jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' \
        package.json 2>/dev/null | \
    while read -l line
        set -l parts (string split \t $line)
        printf "  $_bn_cyan%-22s$_bn_reset  $_bn_dim%s$_bn_reset\n" $parts[1] $parts[2]
    end
    echo ""
end

# ─── bun-run-smart: Fuzzy script runner ───────────────────────────────────────
function bun-run-smart --description "Run bun script via fuzzy picker"
    set -l script $argv[1]

    if test -z "$script"
        if command -q fzf && test -f package.json && command -q jq
            set script (
                jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' \
                    package.json 2>/dev/null |
                fzf --ansi \
                    --border-label "  🐰 bun scripts " \
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
            bun-scripts
            read -P "  Script: " script
        end
    end

    test -z "$script" && return 1
    echo ""
    echo $_bn_cyan"  🐰 bun run $script"$_bn_reset
    echo ""
    bun run $script $argv[2..-1]
end

# ─── bun-build-smart: Smart bundler invocation ────────────────────────────────
function bun-build-smart --description "Build with bun bundler with smart defaults"
    set -l entry   $argv[1]
    set -l outdir  $argv[2]
    set -l target  $argv[3]

    test -z "$outdir" && set outdir "dist"
    test -z "$target" && set target "browser"

    # Auto-detect entry if not provided
    if test -z "$entry"
        for candidate in \
            "src/index.ts" "src/index.tsx" "src/index.js" \
            "index.ts" "index.tsx" "index.js" "src/main.ts"
            if test -f $candidate
                set entry $candidate
                break
            end
        end
    end

    if test -z "$entry"
        echo $_bn_red"  ✗ No entry file found"$_bn_reset
        echo "  Usage: bun-build-smart [entry] [outdir] [target]"
        return 1
    end

    echo ""
    echo $_bn_cyan"  🏗️  bun build: $entry → $outdir/ (target: $target)"$_bn_reset
    echo ""

    set -l ts (date +%s)

    bun build $entry \
        --outdir $outdir \
        --target $target \
        --minify \
        --sourcemap=external \
        $argv[4..-1]

    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)

    echo ""
    if test $rc -eq 0
        echo $_bn_green"  ✓ Build complete ($elapsed"s")"$_bn_reset
        # Show output files
        if test -d $outdir
            find $outdir -type f 2>/dev/null | while read -l f
                set -l size (du -sh $f 2>/dev/null | awk '{print $1}')
                echo "    "$_bn_dim$f" ($size)"$_bn_reset
            end
        end
    else
        echo $_bn_red"  ✗ Build failed ($elapsed"s")"$_bn_reset
    end
    echo ""
    return $rc
end

# ─── bun-test-smart: Test runner with watch and coverage ──────────────────────
function bun-test-smart --description "Run bun tests with smart options"
    set -l mode $argv[1]
    test -z "$mode" && set mode run

    switch $mode
        case watch
            echo $_bn_cyan"  🧪 bun test --watch"$_bn_reset
            bun test --watch $argv[2..-1]

        case coverage cov
            echo $_bn_cyan"  🧪 bun test --coverage"$_bn_reset
            bun test --coverage $argv[2..-1]

        case bail
            echo $_bn_cyan"  🧪 bun test --bail"$_bn_reset
            bun test --bail $argv[2..-1]

        case filter
            set -l pattern $argv[2]
            if test -z "$pattern" && command -q fzf
                # Find test files
                set pattern (
                    find . \
                        -name "*.test.ts" \
                        -o -name "*.test.tsx" \
                        -o -name "*.spec.ts" \
                        -o -name "*.test.js" \
                        2>/dev/null | grep -v node_modules |
                    fzf --border-label "  🧪 Select Test File " \
                        --border rounded \
                        --prompt "  " \
                        --no-multi
                )
                test -z "$pattern" && return 0
            end
            bun test $pattern $argv[3..-1]

        case '*' run
            echo $_bn_cyan"  🧪 bun test"$_bn_reset
            bun test $argv[2..-1]
    end
end

# ─── bun-upgrade-all: Upgrade all dependencies ────────────────────────────────
function bun-upgrade-all --description "Upgrade all bun project dependencies"
    if not test -f package.json
        echo $_bn_red"  ✗ No package.json found"$_bn_reset
        return 1
    end

    echo ""
    echo $_bn_cyan"  🔄 Upgrading all dependencies..."$_bn_reset
    echo ""

    # Check outdated first
    bun outdated 2>/dev/null

    echo ""
    read -P "  Upgrade all to latest? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    bun update --latest
    and echo $_bn_green"  ✓ All packages upgraded"$_bn_reset
    echo ""
end

# ─── bun-clean: Clean bun project artifacts ───────────────────────────────────
function bun-clean --description "Clean bun project artifacts and cache"
    echo ""
    echo $_bn_yellow"  🧹 Cleaning bun project..."$_bn_reset
    echo ""

    set -l removed 0

    for artifact in node_modules dist build out .next .nuxt .svelte-kit
        if test -d $artifact
            set -l size (du -sh $artifact 2>/dev/null | awk '{print $1}')
            rm -rf $artifact
            echo $_bn_green"  ✓ $artifact removed ($size)"$_bn_reset
            set removed (math $removed + 1)
        end
    end

    # Bun cache
    read -P "  Clean bun global cache? [y/N] " clean_cache
    if string match -qi 'y*' $clean_cache
        bun pm cache rm 2>/dev/null
        and echo $_bn_green"  ✓ Cache cleared"$_bn_reset
    end

    echo ""
    echo $_bn_green"  ✓ Cleaned $removed artifact(s)"$_bn_reset
    echo ""
end

# ─── bun-repl: Launch enhanced bun REPL ──────────────────────────────────────
function bun-repl --description "Launch bun REPL with enhanced features"
    set -l mode $argv[1]

    switch $mode
        case ts typescript
            echo $_bn_cyan"  🐰 Bun TypeScript REPL"$_bn_reset
            bun repl --ts
        case '*'
            echo $_bn_cyan"  🐰 Bun JavaScript REPL"$_bn_reset
            bun repl
    end
end

# ─── bun-shell: Run shell commands via bun shell ─────────────────────────────
function bun-sh --description "Run a command via bun shell (cross-platform)"
    if test (count $argv) -eq 0
        echo "  Usage: bun-sh <command>"
        echo "  Example: bun-sh 'echo hello && ls'"
        return 1
    end
    bun --shell (string join ' ' $argv)
end

# ─── bun-init-smart: Initialize project with best practices ───────────────────
function bun-init-smart --description "Initialize a new bun project"
    set -l name $argv[1]
    set -l type $argv[2]   # app | lib | api | fullstack

    test -z "$name" && set name (basename $PWD)
    test -z "$type" && set type app

    echo ""
    echo $_bn_bold$_bn_pink"  ╔══════════════════════════════════════╗"$_bn_reset
    echo $_bn_bold$_bn_pink"  ║  🐰 Bun Project: $name"$_bn_reset
    echo $_bn_bold$_bn_pink"  ╚══════════════════════════════════════╝"$_bn_reset
    echo ""

    # Init with bun
    bun init --yes 2>/dev/null

    # Write bunfig.toml
    cat > bunfig.toml << 'TOML'
# ── Bun Configuration ────────────────────────────────────────────────────────
[install]
# Save exact versions
exact = true

# Auto-install peer dependencies
peer = true

# Production: true in CI
production = false

[install.cache]
# Cache directory
dir = "~/.bun/install/cache"

# Disable cache in CI
disable = false

[test]
# Test timeout (ms)
timeout = 10000

# Coverage
coverage = true
coverageReporter = ["text", "lcov"]

[run]
# Shell for bun run
shell = "bun"
TOML

    echo $_bn_green"  ✓ bunfig.toml created"$_bn_reset

    # Add packageManager field
    set -l bun_ver (bun --version 2>/dev/null)
    if command -q jq && test -f package.json
        jq --arg pm "bun@$bun_ver" '.packageManager = $pm' package.json \
            > /tmp/pkg.json 2>/dev/null && mv /tmp/pkg.json package.json
    end

    switch $type
        case api server
            # Install hono (fast bun-optimized web framework)
            echo $_bn_cyan"  Installing hono..."$_bn_reset
            bun add hono 2>/dev/null

            cat > src/index.ts << 'TS'
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { cors } from 'hono/cors'

const app = new Hono()

app.use('*', logger())
app.use('*', cors())

app.get('/', (c) => c.json({ message: 'Hello from Bun + Hono!' }))
app.get('/health', (c) => c.json({ status: 'ok', ts: Date.now() }))

export default {
    port: process.env.PORT ?? 3000,
    fetch: app.fetch,
}
TS
            echo $_bn_green"  ✓ Hono API template created"$_bn_reset

        case lib library
            # Library setup
            mkdir -p src tests
            cat > src/index.ts << 'TS'
export * from './lib'
TS
            cat > src/lib.ts << 'TS'
export function hello(name: string): string {
    return `Hello, ${name}!`
}
TS

        case '*' app
            # Default app
            true
    end

    # Write .gitignore
    printf 'node_modules/\ndist/\nbuild/\n.env\n.env.local\nbun.lockb\n*.bak\n' \
        > .gitignore
    echo $_bn_green"  ✓ .gitignore created"$_bn_reset

    echo ""
    echo $_bn_green"  ✓ Project initialized: $name ($type)"$_bn_reset
    echo "  "$_bn_dim"Run: bun dev"$_bn_reset
    echo ""
end

# ─── bun-bench: Run performance benchmarks ────────────────────────────────────
function bun-bench --description "Run bun vs node performance comparison"
    set -l script $argv[1]

    if test -z "$script"
        echo "  Usage: bun-bench <script.js>"
        echo ""
        echo "  Quick benchmark example:"
        echo "    echo 'console.log(1+1)' | bun-bench /dev/stdin"
        return 1
    end

    echo ""
    echo $_bn_cyan"  ⚡ Benchmarking: $script"$_bn_reset
    echo ""

    # Bun timing
    set -l bun_start (date +%s%N 2>/dev/null; or date +%s000000000)
    bun run $script 2>/dev/null
    set -l bun_end (date +%s%N 2>/dev/null; or date +%s000000000)
    set -l bun_ms (math --scale 2 "($bun_end - $bun_start) / 1000000")

    # Node timing (if available)
    if command -q node
        set -l node_start (date +%s%N 2>/dev/null; or date +%s000000000)
        node $script 2>/dev/null
        set -l node_end (date +%s%N 2>/dev/null; or date +%s000000000)
        set -l node_ms (math --scale 2 "($node_end - $node_start) / 1000000")

        echo ""
        printf "  $_bn_cyan%-12s$_bn_reset  %sms\n" "bun:"  $bun_ms
        printf "  $_bn_dim%-12s$_bn_reset  %sms\n"  "node:" $node_ms

        set -l speedup (math --scale 1 "$node_ms / $bun_ms")
        echo ""
        echo "  "$_bn_green"⚡ bun is "$speedup"x faster than node"$_bn_reset
    else
        echo ""
        printf "  $_bn_cyan%-12s$_bn_reset  %sms\n" "bun:" $bun_ms
    end
    echo ""
end

# ─── bun-pm-info: Package manager compatibility info ──────────────────────────
function bun-pm-info --description "Show bun package manager cache and store info"
    echo ""
    echo $_bn_bold$_bn_pink"  🏪 Bun Package Manager"$_bn_reset
    echo ""

    echo "  "$_bn_bold"Cache:"$_bn_reset
    set -l cache_dir "$BUN_INSTALL/install/cache"
    if test -d $cache_dir
        set -l cache_size (du -sh $cache_dir 2>/dev/null | awk '{print $1}')
        echo "    "$_bn_dim"Path: "$cache_dir$_bn_reset
        echo "    "$_bn_cyan"Size: "$cache_size$_bn_reset
    end

    echo ""
    echo "  "$_bn_bold"Global packages:"$_bn_reset
    bun pm ls -g 2>/dev/null | head -20 | while read -l line
        echo "    "$_bn_dim$line$_bn_reset
    end
    echo ""
end

# ─── bun-x: Execute package binaries ──────────────────────────────────────────
function bun-x --description "Execute a package binary via bun (bunx)"
    if test (count $argv) -eq 0
        echo "  Usage: bun-x <package> [args...]"
        echo "  Example: bun-x create-next-app@latest my-app"
        return 1
    end
    bunx $argv
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETIONS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __bun_scripts --description "List bun scripts for completion"
    test -f package.json || return
    command -q jq && \
        jq -r '.scripts // {} | keys[]' package.json 2>/dev/null
end

function __bun_test_files --description "List test files for completion"
    find . -name "*.test.ts" -o -name "*.test.tsx" \
           -o -name "*.spec.ts" -o -name "*.test.js" \
           2>/dev/null | grep -v node_modules | string replace './' ''
end

complete -c bun-run-smart   -f -a '(__bun_scripts)'    -d "Bun script"
complete -c bun-test-smart  -f -a 'watch coverage bail filter run' -d "Test mode"
complete -c bun-build-smart -n 'test (count (commandline -opc)) -eq 2' \
    -f -a "browser bun node" -d "Build target"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core bun
abbr --add b      'bun'
abbr --add bi     'bun install'
abbr --add ba     'bun add'
abbr --add bad    'bun add -d'
abbr --add bag    'bun add -g'
abbr --add brm    'bun remove'
abbr --add bup    'bun update'
abbr --add brun   'bun-run-smart'
abbr --add bst    'bun start'
abbr --add bdev   'bun dev'
abbr --add bbld   'bun-build-smart'
abbr --add btest  'bun-test-smart'
abbr --add btw    'bun-test-smart watch'
abbr --add btcov  'bun-test-smart coverage'

# Bunx
abbr --add bx     'bunx'
abbr --add bxn    'bunx --bun'

# Info & Maintenance
abbr --add binfo  'bun-info'
abbr --add bscr   'bun-scripts'
abbr --add bclean 'bun-clean'
abbr --add bupall 'bun-upgrade-all'
abbr --add boutd  'bun outdated'
abbr --add bpm    'bun-pm-info'
abbr --add bcache 'bun pm cache rm'
abbr --add brepl  'bun-repl'
abbr --add bsh    'bun-sh'
abbr --add bbench 'bun-bench'
abbr --add binit  'bun-init-smart'

# Lock file
abbr --add block  'bun install --frozen-lockfile'
abbr --add bunlock 'rm -f bun.lockb && bun install'

# Global
abbr --add bgl    'bun pm ls -g'
abbr --add bgadd  'bun add -g'
abbr --add bgrm   'bun remove -g'
abbr --add bgup   'bun update -g'

# Upgrade bun itself
abbr --add bupgrd 'bun upgrade'
abbr --add bver   'bun --version'