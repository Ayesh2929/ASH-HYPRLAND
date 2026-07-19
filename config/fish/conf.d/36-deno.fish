# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Deno Ultra Configuration                           ║
# ║  Secure TypeScript runtime with stdlib, LSP, workspace & full ecosystem    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_deno_loaded && exit 0
set --global _ash_deno_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_deno_log    "$HOME/.local/share/ash/logs/deno.log"
set --global _ash_deno_cache  "$HOME/.local/share/ash/cache/deno"

mkdir -p (dirname $_ash_deno_log) 2>/dev/null
mkdir -p $_ash_deno_cache         2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_deno_find --description "Find deno executable"
    if command -q deno
        echo (command -v deno); return
    end
    for candidate in \
        "$HOME/.deno/bin/deno" \
        "$HOME/.local/bin/deno" \
        "/usr/local/bin/deno"
        test -x $candidate && echo $candidate && return
    end
    echo ""
end

set --global _ash_deno_bin (__ash_deno_find)

test -z "$_ash_deno_bin" && exit 0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _dn_reset   (set_color normal)
set -g _dn_bold    (set_color --bold)
set -g _dn_cyan    (set_color cyan)
set -g _dn_green   (set_color green)
set -g _dn_yellow  (set_color yellow)
set -g _dn_red     (set_color red)
set -g _dn_blue    (set_color blue)
set -g _dn_purple  (set_color magenta)
set -g _dn_dim     (set_color brblack)
set -g _dn_dino    (set_color 70C0B1)   # Deno teal

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core paths ────────────────────────────────────────────────────────────────
set --export DENO_INSTALL      "$HOME/.deno"
set --export DENO_DIR          "$HOME/.cache/deno"
set --export DENO_INSTALL_ROOT "$HOME/.deno"

# Add deno to PATH
fish_add_path --prepend --global "$DENO_INSTALL/bin"

# ── Security defaults ─────────────────────────────────────────────────────────
# Deno is secure by default — explicit permission flags are required
# These env vars set default behaviour for common tasks

# No auto-update checks (faster startup)
set --export DENO_NO_UPDATE_CHECK 1

# Colorized output
set --export NO_COLOR 0

# V8 flags for performance
set --export DENO_V8_FLAGS "--max-old-space-size=4096"

# ── Shell completions ──────────────────────────────────────────────────────────
deno completions fish 2>/dev/null | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 AUTO-DETECTION: Deno project detection on directory change               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_deno_detect_project --description "Detect if directory is a Deno project"
    test -f deno.json     && return 0
    test -f deno.jsonc    && return 0
    test -f deno.lock     && return 0
    test -f import_map.json && return 0
    return 1
end

function __ash_deno_on_dir_change --on-variable PWD \
    --description "Hint on entering a Deno project"
    __ash_deno_detect_project || return

    set -l cache_key (echo (pwd) | md5sum | awk '{print $1}')
    set -l cache_file "$_ash_deno_cache/hint-$cache_key"
    test -f $cache_file && return

    touch $cache_file
    echo $_dn_dim"  🦕 Deno project detected"$_dn_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  CORE DENO WRAPPERS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── deno-run: Run with sensible permission flags ─────────────────────────────
function deno-run --description "Run Deno script with common permission presets"
    set -l preset $argv[1]
    set -l script $argv[2]

    if test -z "$script"
        set script $preset
        set preset "net-read"
    end

    set -l perms
    switch $preset
        case full unsafe
            set perms "--allow-all"
        case net-read
            set perms "--allow-net --allow-read --allow-env"
        case net
            set perms "--allow-net"
        case read
            set perms "--allow-read --allow-env"
        case write
            set perms "--allow-read --allow-write --allow-env"
        case sys
            set perms "--allow-sys --allow-env --allow-read"
        case run
            set perms "--allow-run --allow-read --allow-env"
        case server web
            set perms "--allow-net --allow-read --allow-write --allow-env --allow-sys"
        case '*'
            # Treat first arg as script
            set script $preset
            set perms "--allow-net --allow-read --allow-env"
    end

    echo ""
    echo $_dn_dino"  🦕 deno run $perms $script"$_dn_reset
    echo ""
    deno run $perms $script $argv[3..-1]
end

# ─── deno-watch: Run with watch mode ─────────────────────────────────────────
function deno-watch --description "Run Deno script in watch mode"
    set -l script $argv[1]
    test -z "$script" && set script "main.ts"

    echo $_dn_cyan"  👁  deno run --watch $script"$_dn_reset
    deno run \
        --watch \
        --allow-net \
        --allow-read \
        --allow-write \
        --allow-env \
        $script $argv[2..-1]
end

# ─── deno-test-smart: Smart test runner ──────────────────────────────────────
function deno-test-smart --description "Run Deno tests with smart options"
    set -l mode $argv[1]
    test -z "$mode" && set mode run

    switch $mode
        case watch
            deno test --watch --allow-all $argv[2..-1]
        case coverage cov
            mkdir -p coverage
            deno test \
                --allow-all \
                --coverage=coverage \
                $argv[2..-1]
            deno coverage coverage --lcov > coverage/lcov.info 2>/dev/null
            echo ""
            echo $_dn_green"  ✓ Coverage: coverage/lcov.info"$_dn_reset
        case filter
            set -l pattern $argv[2]
            deno test --allow-all --filter "$pattern" $argv[3..-1]
        case '*'
            deno test --allow-all $argv[2..-1]
    end
end

# ─── deno-bench: Run benchmarks ───────────────────────────────────────────────
function deno-bench --description "Run Deno benchmarks"
    set -l filter $argv[1]
    echo ""
    echo $_dn_cyan"  📊 deno bench"$_dn_reset
    echo ""

    if test -n "$filter"
        deno bench --allow-all --filter "$filter" $argv[2..-1]
    else
        deno bench --allow-all $argv[2..-1]
    end
end

# ─── deno-compile: Compile to standalone binary ────────────────────────────────
function deno-compile --description "Compile Deno script to standalone binary"
    set -l script $argv[1]
    set -l output $argv[2]
    set -l target $argv[3]

    if test -z "$script"
        echo "  Usage: deno-compile <script.ts> [output-name] [target]"
        echo ""
        echo "  Targets:"
        echo "    x86_64-unknown-linux-gnu"
        echo "    aarch64-unknown-linux-gnu"
        echo "    x86_64-pc-windows-msvc"
        echo "    x86_64-apple-darwin"
        echo "    aarch64-apple-darwin"
        return 1
    end

    test -z "$output" && set output (string replace -r '\.(ts|js|tsx|jsx)$' '' $script)

    set -l compile_cmd deno compile \
        --allow-all \
        --output $output

    test -n "$target" && set compile_cmd $compile_cmd --target $target

    echo ""
    echo $_dn_cyan"  🏗️  Compiling: $script → $output"$_dn_reset
    test -n "$target" && echo "  Target: $target"
    echo ""

    set -l ts (date +%s)
    eval $compile_cmd $script $argv[4..-1]
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)

    if test $rc -eq 0
        set -l bin_size (du -sh $output 2>/dev/null | awk '{print $1}')
        echo ""
        echo $_dn_green"  ✓ Compiled: $output ($bin_size) in $elapsed"s$_dn_reset
    else
        echo $_dn_red"  ✗ Compilation failed"$_dn_reset
    end
    echo ""
    return $rc
end

# ─── deno-fmt-check: Format and lint ──────────────────────────────────────────
function deno-fmt-check --description "Format, lint and type-check Deno project"
    echo ""
    echo $_dn_cyan"  🔍 Deno fmt + lint + check..."$_dn_reset
    echo ""

    set -l errors 0

    deno fmt $argv 2>/dev/null
    and echo $_dn_green"  ✓ fmt"$_dn_reset || begin; echo $_dn_red"  ✗ fmt"$_dn_reset; set errors (math $errors + 1); end

    deno lint $argv 2>/dev/null
    and echo $_dn_green"  ✓ lint"$_dn_reset || begin; echo $_dn_yellow"  ⚠ lint issues"$_dn_reset; set errors (math $errors + 1); end

    deno check $argv 2>/dev/null
    and echo $_dn_green"  ✓ type check"$_dn_reset || begin; echo $_dn_red"  ✗ type errors"$_dn_reset; set errors (math $errors + 1); end

    echo ""
    test $errors -eq 0 \
        && echo $_dn_green"  ✓ All checks passed"$_dn_reset \
        || echo $_dn_yellow"  ⚠ $errors check(s) failed"$_dn_reset
    echo ""
    return $errors
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📦 DEPENDENCY MANAGEMENT                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── deno-add: Add dependency to deno.json ────────────────────────────────────
function deno-add --description "Add dependency to deno.json imports"
    set -l pkg $argv[1]

    if test -z "$pkg"
        echo "  Usage: deno-add <package>"
        echo "  Examples:"
        echo "    deno-add @std/http"
        echo "    deno-add npm:express"
        echo "    deno-add jsr:@hono/hono"
        return 1
    end

    deno add $pkg $argv[2..-1]
    and echo $_dn_green"  ✓ Added: $pkg"$_dn_reset
end

# ─── deno-outdated: Check for outdated deps ───────────────────────────────────
function deno-outdated --description "Check for outdated Deno dependencies"
    echo ""
    echo $_dn_cyan"  🔍 Checking for outdated dependencies..."$_dn_reset
    echo ""

    deno outdated $argv
end

# ─── deno-cache-warm: Cache all imports ────────────────────────────────────────
function deno-cache-warm --description "Pre-cache all project dependencies"
    set -l entry $argv[1]

    # Auto-detect entry
    if test -z "$entry"
        for candidate in main.ts mod.ts index.ts src/main.ts src/index.ts
            if test -f $candidate
                set entry $candidate
                break
            end
        end
    end

    if test -z "$entry"
        echo $_dn_red"  ✗ No entry file found"$_dn_reset
        return 1
    end

    echo ""
    echo $_dn_cyan"  📦 Caching dependencies: $entry"$_dn_reset
    deno cache $entry $argv[2..-1]
    and echo $_dn_green"  ✓ Cache warmed"$_dn_reset
    echo ""
end

# ─── deno-info-rich: Rich Deno info dashboard ─────────────────────────────────
function deno-info-rich --description "Show rich Deno environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)
    set -l dino   (set_color 70C0B1)

    echo ""
    echo $bold$dino"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$dino"  ║     🦕  Deno Development Environment                 ║"$reset
    echo $bold$dino"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:      "$reset $cyan(deno --version 2>/dev/null | head -1)$reset
    echo "  "$bold"DENO_DIR:     "$reset $dim$DENO_DIR$reset
    echo "  "$bold"DENO_INSTALL: "$reset $dim$DENO_INSTALL$reset
    echo ""

    # Cache info
    set -l cache_size (du -sh $DENO_DIR 2>/dev/null | awk '{print $1}')
    test -n "$cache_size" && echo "  "$bold"Cache size:   "$reset $cyan$cache_size$reset
    echo ""

    # Project detection
    if __ash_deno_detect_project
        echo "  "$green"✓ Deno project detected"$reset
        for cfg in deno.json deno.jsonc
            if test -f $cfg && command -q jq
                set -l name    (jq -r '.name    // ""' $cfg 2>/dev/null)
                set -l version (jq -r '.version // ""' $cfg 2>/dev/null)
                test -n "$name"    && echo "  "$bold"Name:         "$reset $cyan$name$reset
                test -n "$version" && echo "  "$bold"Version:      "$reset $version
            end
        end
        test -f deno.lock     && echo "  "$green"  ✓ deno.lock found"$reset
        test -f import_map.json && echo "  "$green"  ✓ import_map.json found"$reset
    end

    echo ""

    # Available subcommands
    echo "  "$bold"Capabilities:"$reset
    for cap in "run — Secure script runner" \
               "test — Built-in test runner" \
               "bench — Benchmarking" \
               "compile — Standalone binary" \
               "bundle — Module bundler" \
               "fmt — Auto-formatter" \
               "lint — Linter" \
               "check — Type checker" \
               "doc — Documentation generator" \
               "jupyter — Jupyter kernel" \
               "serve — HTTP server"
        echo "    "$dim"• "$reset$cap
    end
    echo ""
end

# ─── deno-new: Scaffold a new Deno project ────────────────────────────────────
function deno-new --description "Scaffold a new Deno project"
    set -l name $argv[1]
    set -l type $argv[2]   # cli | server | lib | fresh | workspace

    test -z "$name" && set name (basename $PWD)
    test -z "$type" && set type server

    echo ""
    echo $_dn_bold$_dn_dino"  ╔══════════════════════════════════════╗"$_dn_reset
    echo $_dn_bold$_dn_dino"  ║  🦕 Deno Project: $name"$_dn_reset
    echo $_dn_bold$_dn_dino"  ╚══════════════════════════════════════╝"$_dn_reset
    echo ""

    switch $type
        case fresh
            deno run -A -r https://fresh.deno.dev $name
            return

        case workspace
            mkdir -p $name
            cd $name
            printf '{\n  "workspace": ["./packages/*"]\n}\n' > deno.json
            mkdir -p packages
            echo $_dn_green"  ✓ Workspace initialized"$_dn_reset

        case server api
            mkdir -p $name/src $name/tests
            cd $name

            # deno.json
            printf '{\n  "name": "%s",\n  "version": "0.1.0",\n  "tasks": {\n    "dev": "deno run --allow-net --allow-read --allow-env --watch src/main.ts",\n    "start": "deno run --allow-net --allow-read --allow-env src/main.ts",\n    "test": "deno test --allow-all",\n    "fmt": "deno fmt",\n    "lint": "deno lint",\n    "check": "deno check src/main.ts"\n  },\n  "imports": {\n    "@std/http": "jsr:@std/http@^1.0.0",\n    "@std/path": "jsr:@std/path@^1.0.0"\n  },\n  "compilerOptions": {\n    "strict": true\n  }\n}\n' \
                $name > deno.json

            # Main server
            printf 'import { serve } from "@std/http";\n\nconst handler = (req: Request): Response => {\n  const url = new URL(req.url);\n\n  if (url.pathname === "/health") {\n    return Response.json({ status: "ok", ts: Date.now() });\n  }\n\n  return Response.json({ message: "Hello from Deno!" });\n};\n\nconst port = Number(Deno.env.get("PORT") ?? 8000);\nconsole.log(`🦕 Server running on http://localhost:${port}`);\nawait serve(handler, { port });\n' \
                > src/main.ts

            # Test file
            printf 'import { assertEquals } from "jsr:@std/assert";\n\nDeno.test("health endpoint", async () => {\n  // Add your tests here\n  assertEquals(1 + 1, 2);\n});\n' \
                > tests/main_test.ts

        case cli
            mkdir -p $name/src
            cd $name

            printf '{\n  "name": "%s",\n  "version": "0.1.0",\n  "tasks": {\n    "run": "deno run --allow-read --allow-env src/cli.ts",\n    "compile": "deno compile --allow-read --allow-env --output bin/%s src/cli.ts",\n    "test": "deno test --allow-all",\n    "fmt": "deno fmt",\n    "lint": "deno lint"\n  }\n}\n' \
                $name $name > deno.json

            printf 'import { parseArgs } from "jsr:@std/cli/parse-args";\n\nconst args = parseArgs(Deno.args, {\n  string: ["name"],\n  boolean: ["help", "version"],\n  default: { name: "World" },\n});\n\nif (args.help) {\n  console.log("Usage: %s [--name <name>]");\n  Deno.exit(0);\n}\n\nconsole.log(`Hello, ${args.name}!`);\n' \
                $name > src/cli.ts

        case lib library
            mkdir -p $name/src $name/tests
            cd $name

            printf '{\n  "name": "@%s/%s",\n  "version": "0.1.0",\n  "exports": "./mod.ts",\n  "tasks": {\n    "test": "deno test --allow-all",\n    "fmt": "deno fmt",\n    "lint": "deno lint",\n    "check": "deno check mod.ts"\n  }\n}\n' \
                $USER $name > deno.json

            printf '/**\n * %s — Deno library\n * @module\n */\n\nexport * from "./src/lib.ts";\n' \
                $name > mod.ts

            printf '/**\n * Core library functions\n */\n\n/**\n * Greet someone\n * @param name - The name to greet\n * @returns Greeting string\n */\nexport function hello(name: string): string {\n  return `Hello, ${name}!`;\n}\n' \
                > src/lib.ts

            printf 'import { assertEquals } from "jsr:@std/assert";\nimport { hello } from "../mod.ts";\n\nDeno.test("hello()", () => {\n  assertEquals(hello("Deno"), "Hello, Deno!");\n});\n' \
                > tests/lib_test.ts
    end

    # .gitignore
    printf '.env\n.env.local\ncoverage/\ndist/\n' > .gitignore

    echo $_dn_green"  ✓ Project created: $name ($type)"$_dn_reset
    echo "  "$_dn_dim"Run: deno task dev"$_dn_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add d       'deno'
abbr --add dr      'deno-run'
abbr --add drun    'deno run --allow-all'
abbr --add dw      'deno-watch'
abbr --add dt      'deno-test-smart'
abbr --add dtw     'deno-test-smart watch'
abbr --add dtcov   'deno-test-smart coverage'
abbr --add dbench  'deno-bench'
abbr --add dcomp   'deno-compile'
abbr --add dfmt    'deno fmt'
abbr --add dlint   'deno lint'
abbr --add dcheck  'deno check'
abbr --add dall    'deno-fmt-check'
abbr --add dadd    'deno-add'
abbr --add dout    'deno-outdated'
abbr --add dcache  'deno-cache-warm'
abbr --add dinfo   'deno-info-rich'
abbr --add dnew    'deno-new'
abbr --add dtask   'deno task'
abbr --add dtasks  'deno task --list'
abbr --add ddoc    'deno doc'
abbr --add dupgrade 'deno upgrade'
abbr --add dver    'deno --version'
abbr --add drepl   'deno repl --allow-all'
abbr --add djup    'deno jupyter --unstable'
abbr --add djsr    'deno add'
abbr --add dnpm    'deno add npm:'