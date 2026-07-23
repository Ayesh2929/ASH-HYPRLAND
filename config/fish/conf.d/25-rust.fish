# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Rust Ultra Configuration                           ║
# ║  rustup, cargo, cross-compilation, toolchains & full ecosystem setup       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_rust_loaded && exit 0
set --global _ash_rust_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_rust_log      "$HOME/.local/share/ash/logs/rust.log"
set --global _ash_rust_cache    "$HOME/.local/share/ash/cache/rust"

mkdir -p (dirname $_ash_rust_log) 2>/dev/null
mkdir -p $_ash_rust_cache 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Exit early if rustup/cargo not available
if not command -q rustup && not command -q cargo
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _rust_reset   (set_color normal)
set -g _rust_bold    (set_color --bold)
set -g _rust_orange  (set_color FF6600)
set -g _rust_cyan    (set_color cyan)
set -g _rust_green   (set_color green)
set -g _rust_yellow  (set_color yellow)
set -g _rust_red     (set_color red)
set -g _rust_blue    (set_color blue)
set -g _rust_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Core Rust paths ───────────────────────────────────────────────────────────
set --export RUSTUP_HOME  "$HOME/.rustup"
set --export CARGO_HOME   "$HOME/.cargo"

# Add cargo bin to PATH (primary)
if not contains "$CARGO_HOME/bin" $PATH
    fish_add_path --prepend --global "$CARGO_HOME/bin"
end

# ── Cargo configuration ───────────────────────────────────────────────────────
# Faster linker (mold if available, lld fallback)
if command -q mold
    set --export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER mold
    set --export RUSTFLAGS "-C link-arg=-fuse-ld=mold"
else if command -q clang
    set --export RUSTFLAGS "-C link-arg=-fuse-ld=lld"
end

# Incremental compilation (faster rebuilds)
set --export CARGO_INCREMENTAL 1

# Parallel codegen units (tune for build speed)
set --export RUSTC_WRAPPER ""   # Will be set to sccache if available

# sccache: compiler cache for faster rebuilds
if command -q sccache
    set --export RUSTC_WRAPPER sccache
    set --export SCCACHE_CACHE_SIZE "10G"
    set --export SCCACHE_DIR "$HOME/.cache/sccache"
end

# Backtrace on panic (dev comfort)
set --export RUST_BACKTRACE 1

# Colored cargo output
set --export CARGO_TERM_COLOR always

# ── rustup configuration ──────────────────────────────────────────────────────
set --export RUSTUP_DIST_SERVER  "https://static.rust-lang.org"
set --export RUSTUP_UPDATE_ROOT  "https://static.rust-lang.org/rustup"

# ── Cross-compilation targets (common) ───────────────────────────────────────
set --global _ash_rust_common_targets \
    "x86_64-unknown-linux-gnu" \
    "x86_64-unknown-linux-musl" \
    "aarch64-unknown-linux-gnu" \
    "aarch64-unknown-linux-musl" \
    "x86_64-pc-windows-msvc" \
    "x86_64-apple-darwin" \
    "aarch64-apple-darwin" \
    "wasm32-unknown-unknown" \
    "wasm32-wasi"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 AUTO-TOOLCHAIN: Detect project toolchain on directory change            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_rust_auto_toolchain --on-variable PWD \
    --description "Auto-switch Rust toolchain based on rust-toolchain.toml"

    command -q rustup || return

    # Walk up for rust-toolchain.toml / rust-toolchain
    set -l dir (pwd)
    set -l found ""

    while test "$dir" != "/"
        if test -f "$dir/rust-toolchain.toml" || test -f "$dir/rust-toolchain"
            set found $dir
            break
        end
        set dir (dirname $dir)
    end

    test -z "$found" && return

    # rustup handles this automatically with rust-toolchain files
    # Just validate it's loadable
    set -l toolchain ""
    if test -f "$found/rust-toolchain.toml" && command -q toml2json
        set toolchain (toml2json "$found/rust-toolchain.toml" 2>/dev/null | jq -r '.toolchain.channel // empty')
    else if test -f "$found/rust-toolchain"
        set toolchain (string trim < "$found/rust-toolchain")
    end

    test -z "$toolchain" && return

    # Cache: only notify if toolchain changed
    set -l cache "$_ash_rust_cache/current-toolchain"
    if test -f $cache && test (cat $cache) = "$toolchain"
        return
    end

    echo $toolchain > $cache
    echo $_rust_dim"  🦀 Rust toolchain: "$_rust_orange$toolchain$_rust_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  CARGO SUBCOMMAND WRAPPERS                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── cargo-b: Smart build with timing ────────────────────────────────────────
function cargo-b --wraps='cargo build' --description "cargo build with timing info"
    set -l ts (date +%s)
    cargo build $argv
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)
    echo $_rust_dim"  ⏱  Build time: "$elapsed"s"$_rust_reset
    return $rc
end

# ─── cargo-br: Release build ──────────────────────────────────────────────────
function cargo-br --description "cargo build --release with timing"
    set -l ts (date +%s)
    cargo build --release $argv
    set -l rc $status
    set -l elapsed (math (date +%s) - $ts)
    echo $_rust_dim"  ⏱  Release build: "$elapsed"s"$_rust_reset
    return $rc
end

# ─── cargo-w: Watch mode (requires cargo-watch) ────────────────────────────────
function cargo-w --description "cargo watch — rebuild on file change"
    command -q cargo-watch || begin
        echo $_rust_yellow"  Installing cargo-watch..."$_rust_reset
        cargo install cargo-watch
    end
    cargo watch -x "build" $argv
end

# ─── cargo-wr: Watch + run ────────────────────────────────────────────────────
function cargo-wr --description "cargo watch --exec run"
    command -q cargo-watch || cargo install cargo-watch
    cargo watch -x run $argv
end

# ─── cargo-wt: Watch + test ───────────────────────────────────────────────────
function cargo-wt --description "cargo watch --exec test"
    command -q cargo-watch || cargo install cargo-watch
    cargo watch -x test $argv
end

# ─── cargo-expand-fn: Expand a specific macro/function ────────────────────────
function cargo-expand-fn --description "Expand Rust macros for a specific item"
    command -q cargo-expand || cargo install cargo-expand
    cargo expand $argv
end

# ─── cargo-size: Show binary size breakdown ───────────────────────────────────
function cargo-size --description "Show Rust binary size breakdown"
    command -q cargo-bloat || cargo install cargo-bloat

    echo ""
    echo $_rust_cyan"  📦 Binary size analysis..."$_rust_reset
    echo ""
    cargo bloat --release --crates $argv
    echo ""
end

# ─── cargo-asm: Show generated assembly ────────────────────────────────────────
function cargo-asm --description "Show generated assembly for a function"
    command -q cargo-show-asm || cargo install cargo-show-asm
    cargo asm $argv
end

# ─── cargo-udeps: Find unused dependencies ────────────────────────────────────
function cargo-udeps --description "Find unused Cargo dependencies"
    command -q cargo-udeps || begin
        echo $_rust_yellow"  Installing cargo-udeps (requires nightly)..."$_rust_reset
        cargo install cargo-udeps
    end
    cargo +nightly udeps $argv
end

# ─── cargo-audit-full: Security audit ────────────────────────────────────────
function cargo-audit-full --description "Run full cargo security audit"
    command -q cargo-audit || cargo install cargo-audit

    echo ""
    echo $_rust_cyan"  🔒 Running security audit..."$_rust_reset
    echo ""
    cargo audit $argv
end

# ─── cargo-tarpaulin: Code coverage ──────────────────────────────────────────
function cargo-cov --description "Run code coverage with tarpaulin"
    command -q cargo-tarpaulin || begin
        echo $_rust_yellow"  Installing cargo-tarpaulin..."$_rust_reset
        cargo install cargo-tarpaulin
    end
    cargo tarpaulin --out Html --output-dir target/coverage $argv
    and begin
        echo ""
        echo $_rust_green"  ✓ Coverage report: target/coverage/tarpaulin-report.html"$_rust_reset
        command -q xdg-open && xdg-open target/coverage/tarpaulin-report.html 2>/dev/null
    end
end

# ─── cargo-flame: Flamegraph profiling ────────────────────────────────────────
function cargo-flame --description "Generate flamegraph for cargo binary"
    command -q cargo-flamegraph || begin
        echo $_rust_yellow"  Installing cargo-flamegraph..."$_rust_reset
        cargo install flamegraph
    end
    cargo flamegraph $argv
    and begin
        echo $_rust_green"  ✓ Flamegraph: flamegraph.svg"$_rust_reset
        command -q xdg-open && xdg-open flamegraph.svg 2>/dev/null
    end
end

# ─── cargo-fix-all: Fix + clippy ──────────────────────────────────────────────
function cargo-fix-all --description "Run cargo fix and clippy --fix"
    echo ""
    echo $_rust_cyan"  🔧 Running cargo fix + clippy..."$_rust_reset
    echo ""
    cargo fix --allow-dirty --allow-staged $argv
    cargo clippy --fix --allow-dirty --allow-staged $argv
    cargo fmt $argv
    echo ""
    echo $_rust_green"  ✓ All fixes applied"$_rust_reset
    echo ""
end

# ─── cargo-doc-open: Build and open docs ─────────────────────────────────────
function cargo-doc-open --description "Build and open Rust documentation"
    cargo doc --no-deps --open $argv
end

# ─── cargo-cross: Cross-compilation helper ────────────────────────────────────
function cargo-cross --description "Cross-compile Rust binary"
    set -l target $argv[1]
    set -l rest   $argv[2..-1]

    if test -z "$target"
        echo ""
        echo $_rust_cyan"  🎯 Available cross-compilation targets:"$_rust_reset
        echo ""
        for t in $_ash_rust_common_targets
            set -l installed ""
            rustup target list --installed 2>/dev/null | grep -q $t && set installed $_rust_green" ✓"$_rust_reset
            echo "  $installed $t"
        end
        echo ""
        echo "  Usage: cargo-cross <target> [cargo args...]"
        return 1
    end

    # Install target if missing
    if not rustup target list --installed 2>/dev/null | grep -q $target
        echo $_rust_yellow"  Installing target: $target"$_rust_reset
        rustup target add $target
    end

    # Use cross tool if available (Docker-based cross-compilation)
    if command -q cross
        echo $_rust_cyan"  🎯 Cross-compiling for $target (using 'cross')..."$_rust_reset
        cross build --target $target --release $rest
    else
        echo $_rust_cyan"  🎯 Cross-compiling for $target..."$_rust_reset
        cargo build --target $target --release $rest
    end
end

# ─── rust-info: Rich Rust environment info ────────────────────────────────────
function rust-info --description "Show complete Rust environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l orange (set_color FF6600)

    echo ""
    echo $bold$orange"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$orange"  ║     🦀  Rust Development Environment                 ║"$reset
    echo $bold$orange"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    # Core versions
    echo "  "$bold"rustc:     "$reset $cyan(rustc --version 2>/dev/null)$reset
    echo "  "$bold"cargo:     "$reset $dim(cargo --version 2>/dev/null)$reset
    echo "  "$bold"rustup:    "$reset $dim(rustup --version 2>/dev/null)$reset
    echo ""

    # Active toolchain
    echo "  "$bold"Toolchain: "$reset $orange(rustup show active-toolchain 2>/dev/null | awk '{print $1}')$reset

    # Installed toolchains
    echo ""
    echo "  "$bold"Installed Toolchains:"$reset
    rustup toolchain list 2>/dev/null | while read -l line
        set -l marker ""
        string match -q '*(default)*' $line && set marker $green" ← default"$reset
        echo "    "$dim(string replace ' (default)' '' $line)$reset$marker
    end

    # Installed targets
    echo ""
    echo "  "$bold"Installed Targets:"$reset
    rustup target list --installed 2>/dev/null | while read -l t
        echo "    "$dim"• "$reset$t
    end

    # Installed components
    echo ""
    echo "  "$bold"Components:"$reset
    rustup component list --installed 2>/dev/null | while read -l c
        echo "    "$green"✓ "$reset$dim$c$reset
    end

    # Cargo tools
    echo ""
    echo "  "$bold"Cargo Tools:"$reset
    set -l tools \
        cargo-watch cargo-edit cargo-expand cargo-bloat cargo-udeps \
        cargo-audit cargo-tarpaulin cargo-flamegraph cargo-nextest \
        cargo-release cargo-criterion sccache mold cross
    for tool in $tools
        if command -q $tool
            echo "    "$green"✓ "$reset$tool
        end
    end

    # Paths
    echo ""
    echo "  "$bold"CARGO_HOME:  "$reset $dim$CARGO_HOME$reset
    echo "  "$bold"RUSTUP_HOME: "$reset $dim$RUSTUP_HOME$reset

    if command -q sccache
        echo ""
        echo "  "$bold"sccache stats:"$reset
        sccache --show-stats 2>/dev/null | head -5 | while read -l line
            echo "    "$dim$line$reset
        end
    end

    echo ""
end

# ─── rust-new: Create new Rust project with structure ─────────────────────────
function rust-new --description "Create a new Rust project with best-practice structure"
    set -l name $argv[1]
    set -l type $argv[2]   # bin | lib | workspace

    if test -z "$name"
        read -P "  Project name: " name
    end
    if test -z "$name"
        echo $_rust_red"  ✗ Name required"$_rust_reset; return 1
    end
    test -z "$type" && set type bin

    echo ""
    echo $_rust_orange"  🦀 Creating Rust project: $name ($type)"$_rust_reset
    echo ""

    switch $type
        case bin
            cargo new --bin $name
        case lib
            cargo new --lib $name
        case workspace
            mkdir -p $name
            printf '[workspace]\nmembers = []\nresolver = "2"\n\n[workspace.package]\nversion = "0.1.0"\nedition = "2021"\n\n[profile.release]\nopt-level = 3\nlto = true\ncodegen-units = 1\nstrip = true\n' \
                > "$name/Cargo.toml"
            mkdir -p "$name/.cargo"
            printf '[build]\njobs = %d\n\n[net]\ngit-fetch-with-cli = true\n' \
                (nproc 2>/dev/null; or echo 4) > "$name/.cargo/config.toml"
        case '*'
            echo $_rust_red"  ✗ Unknown type: $type"$_rust_reset; return 1
    end

    if test $status -eq 0 && test $type != workspace
        cd $name

        # .cargo/config.toml with mold linker
        mkdir -p .cargo
        printf '[build]\njobs = %d\n\n[target.x86_64-unknown-linux-gnu]\nlinker = "clang"\nrustflags = ["-C", "link-arg=-fuse-ld=mold"]\n\n[net]\ngit-fetch-with-cli = true\n' \
            (nproc 2>/dev/null; or echo 4) > .cargo/config.toml

        # rust-toolchain.toml
        printf '[toolchain]\nchannel = "stable"\ncomponents = ["rustfmt", "clippy", "rust-src", "rust-analyzer"]\n' \
            > rust-toolchain.toml

        # .clippy.toml
        printf 'msrv = "1.70.0"\n' > .clippy.toml

        # .rustfmt.toml
        printf 'edition = "2021"\nmax_width = 100\nuse_small_heuristics = "Max"\n' > .rustfmt.toml

        echo $_rust_green"  ✓ .cargo/config.toml   (mold linker)"$_rust_reset
        echo $_rust_green"  ✓ rust-toolchain.toml"$_rust_reset
        echo $_rust_green"  ✓ .clippy.toml"$_rust_reset
        echo $_rust_green"  ✓ .rustfmt.toml"$_rust_reset
    end

    echo ""
    echo $_rust_green"  ✓ Project created: $name"$_rust_reset
    echo ""
end

# ─── rust-toolchain-install: Install common toolchains ────────────────────────
function rust-toolchain-install --description "Install common Rust toolchains and components"
    set -l channel $argv[1]
    test -z "$channel" && set channel stable

    echo ""
    echo $_rust_cyan"  🦀 Installing Rust toolchain: $channel"$_rust_reset
    echo ""

    # Install toolchain
    rustup toolchain install $channel

    # Install essential components
    for component in rustfmt clippy rust-src rust-analyzer llvm-tools-preview
        rustup component add $component --toolchain $channel 2>/dev/null
        and echo $_rust_green"  ✓ $component"$_rust_reset
        or  echo $_rust_yellow"  ⚠ $component (unavailable)"$_rust_reset
    end

    echo ""
    echo $_rust_green"  ✓ Toolchain $channel ready"$_rust_reset
    echo ""
end

# ─── rust-update: Update everything ───────────────────────────────────────────
function rust-update --description "Update rustup, toolchains and cargo packages"
    echo ""
    echo $_rust_cyan"  🔄 Updating Rust ecosystem..."$_rust_reset
    echo ""

    # Update rustup itself
    rustup self update 2>/dev/null
    echo $_rust_green"  ✓ rustup updated"$_rust_reset

    # Update all toolchains
    rustup update
    echo $_rust_green"  ✓ Toolchains updated"$_rust_reset

    # Update cargo-installed tools
    if command -q cargo-install-update
        echo ""
        echo $_rust_cyan"  🔄 Updating cargo tools..."$_rust_reset
        cargo install-update -a
    end

    echo ""
    echo $_rust_green"  ✓ Rust ecosystem updated"$_rust_reset
    echo ""
end

# ─── rust-clean-all: Deep clean cargo cache ───────────────────────────────────
function rust-clean-all --description "Deep clean cargo registry and target directories"
    echo ""
    echo $_rust_yellow"  🧹 Cleaning Rust build artifacts..."$_rust_reset
    echo ""

    # Clean current project
    if test -f Cargo.toml
        set -l size (du -sh target 2>/dev/null | awk '{print $1}')
        cargo clean
        echo $_rust_green"  ✓ target/ cleaned ($size)"$_rust_reset
    end

    # Clean cargo registry (cached sources)
    read -P "  Clean cargo registry cache? [y/N] " clean_reg
    if string match -qi 'y*' $clean_reg
        set -l reg_size (du -sh "$CARGO_HOME/registry" 2>/dev/null | awk '{print $1}')
        rm -rf "$CARGO_HOME/registry/cache" 2>/dev/null
        rm -rf "$CARGO_HOME/registry/src"   2>/dev/null
        echo $_rust_green"  ✓ Registry cache cleaned ($reg_size)"$_rust_reset
    end

    # sccache stats reset
    if command -q sccache
        sccache --stop-server 2>/dev/null
        echo $_rust_green"  ✓ sccache stopped"$_rust_reset
    end

    echo ""
end

# ─── cargo-deps-tree: Show dependency tree ────────────────────────────────────
function cargo-deps-tree --description "Show cargo dependency tree"
    # cargo tree is built-in since 1.44
    cargo tree $argv
end

# ─── cargo-bench-compare: Compare benchmarks ──────────────────────────────────
function cargo-bench-compare --description "Run cargo benchmarks and save results"
    set -l name $argv[1]
    test -z "$name" && set name (date +%Y%m%d-%H%M%S)

    mkdir -p target/bench-results
    cargo bench $argv[2..-1] 2>&1 | tee "target/bench-results/$name.txt"
    echo ""
    echo $_rust_green"  ✓ Results saved: target/bench-results/$name.txt"$_rust_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETIONS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_rust_toolchains --description "List installed rustup toolchains"
    rustup toolchain list 2>/dev/null | awk '{print $1}'
end

function __ash_rust_targets --description "List installed rustup targets"
    rustup target list --installed 2>/dev/null
end

complete -c cargo-cross -f -a '(__ash_rust_targets)'  -d "Cross-compile target"
complete -c node-switch  -f -a '(__ash_rust_toolchains)' -d "Toolchain"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# rustup
abbr --add ru     'rustup'
abbr --add ruup   'rust-update'
abbr --add rutc   'rustup toolchain'
abbr --add rutcls 'rustup toolchain list'
abbr --add rutci  'rust-toolchain-install'
abbr --add rutgt  'rustup target'
abbr --add rutgls 'rustup target list --installed'
abbr --add rutga  'rustup target add'
abbr --add rucmp  'rustup component add'
abbr --add rushow 'rustup show'
abbr --add ruinfo 'rust-info'

# cargo core
abbr --add cb     'cargo build'
abbr --add cbr    'cargo build --release'
abbr --add cr     'cargo run'
abbr --add crr    'cargo run --release'
abbr --add ct     'cargo test'
abbr --add ctr    'cargo test --release'
abbr --add cc     'cargo check'
abbr --add cclp   'cargo clippy'
abbr --add cclpf  'cargo clippy --fix'
abbr --add cfmt   'cargo fmt'
abbr --add cfmtc  'cargo fmt --check'
abbr --add cdoc   'cargo doc --no-deps'
abbr --add cdoco  'cargo-doc-open'
abbr --add cbench 'cargo bench'
abbr --add cclean 'cargo clean'
abbr --add cupdt  'cargo update'
abbr --add cadd   'cargo add'
abbr --add crm    'cargo remove'
abbr --add ctree  'cargo-deps-tree'
abbr --add cinst  'cargo install'
abbr --add cuinst 'cargo uninstall'
abbr --add csrch  'cargo search'

# cargo extended
abbr --add cbw    'cargo-b'
abbr --add cbrw   'cargo-br'
abbr --add cwatch 'cargo-w'
abbr --add cwrun  'cargo-wr'
abbr --add cwtest 'cargo-wt'
abbr --add cexp   'cargo-expand-fn'
abbr --add cblot  'cargo-size'
abbr --add caud   'cargo-audit-full'
abbr --add ccov   'cargo-cov'
abbr --add cflame 'cargo-flame'
abbr --add cfix   'cargo-fix-all'
abbr --add cxbld  'cargo-cross'
abbr --add cudep  'cargo-udeps'
abbr --add cnew   'rust-new'
abbr --add rclean 'rust-clean-all'