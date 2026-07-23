#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗   ██╗███████╗████████╗                                            ║
# ║  ██╔══██╗██║   ██║██╔════╝╚══██╔══╝                                            ║
# ║  ██████╔╝██║   ██║███████╗   ██║                                               ║
# ║  ██╔══██╗██║   ██║╚════██║   ██║                                               ║
# ║  ██║  ██║╚██████╔╝███████║   ██║                                               ║
# ║  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝                                               ║
# ║                                                                                  ║
# ║   🦀 RUST ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                              ║
# ║   cargo • rustup • clippy • rustfmt • cargo-watch • criterion • miri • nextest  ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_rust_initialized && exit 0
set -g __ash_abbr_rust_initialized 1

command -sq cargo || command -sq rustup || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🦀 CARGO — Package manager & build tool
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Build ─────────────────────────────────────────────────────────────────────
abbr -a cb      "cargo build"
abbr -a cbr     "cargo build --release"
abbr -a cball   "cargo build --all-features"
abbr -a cballr  "cargo build --all-features --release"
abbr -a cbno    "cargo build --no-default-features"
abbr -a cbt     "cargo build --target"
abbr -a cbw     "cargo build --workspace"
abbr -a cbv     "cargo build --verbose"
abbr -a cbtimes "cargo build --timings"            # Build time profiling
abbr -a cbmsg   "cargo build --message-format=json | jq"

# ── Run ───────────────────────────────────────────────────────────────────────
abbr -a cr      "cargo run"
abbr -a crr     "cargo run --release"
abbr -a crall   "cargo run --all-features"
abbr -a crallr  "cargo run --all-features --release"
abbr -a crno    "cargo run --no-default-features"
abbr -a crq     "cargo run --quiet"
abbr -a crqr    "cargo run --quiet --release"
abbr -a crv     "cargo run --verbose"

# ── Check (fast compile check without linking) ────────────────────────────────
abbr -a cc      "cargo check"
abbr -a ccall   "cargo check --all-features"
abbr -a ccw     "cargo check --workspace"
abbr -a ccno    "cargo check --no-default-features"
abbr -a cct     "cargo check --target"
abbr -a ccv     "cargo check --verbose"

# ── Test ──────────────────────────────────────────────────────────────────────
abbr -a ct      "cargo test"
abbr -a ctr     "cargo test --release"
abbr -a ctall   "cargo test --all-features"
abbr -a ctw     "cargo test --workspace"
abbr -a ctno    "cargo test --no-default-features"
abbr -a ctv     "cargo test --verbose"
abbr -a ctnn    "cargo test -- --nocapture"        # Show println! output
abbr -a ctnnr   "cargo test --release -- --nocapture"
abbr -a ctls    "cargo test -- --list"             # List all tests
abbr -a ctone   "cargo test -- --test-threads=1"  # Sequential testing
abbr -a ctdoc   "cargo test --doc"                 # Doctests only
abbr -a ctint   "cargo test --test"                # Integration tests only
abbr -a ctunit  "cargo test --lib"                 # Unit tests only
abbr -a ctben   "cargo test --bench"               # Benchmark tests
abbr -a ctfail  "cargo test 2>&1 | grep FAILED"   # Show only failures

# ── Benchmark ─────────────────────────────────────────────────────────────────
abbr -a cben    "cargo bench"
abbr -a cbenall "cargo bench --all-features"
abbr -a cbenb   "cargo bench --bench"

# ── Clippy — Linter ───────────────────────────────────────────────────────────
abbr -a ccl     "cargo clippy"
abbr -a cclall  "cargo clippy --all-targets --all-features"
abbr -a cclw    "cargo clippy --workspace"
abbr -a cclfix  "cargo clippy --fix"
abbr -a cclfixall "cargo clippy --fix --allow-staged --all-targets --all-features"
abbr -a cclpedantic "cargo clippy -- -D warnings \
                      -W clippy::pedantic \
                      -W clippy::nursery \
                      -W clippy::unwrap_used \
                      -W clippy::expect_used"
abbr -a cclci   "cargo clippy --all-targets --all-features -- -D warnings"  # CI strict
abbr -a cclwarn "cargo clippy -- -W clippy::all"
abbr -a cclcats "cargo clippy -- -W clippy::cargo"  # Cargo-specific lints
abbr -a cclperf "cargo clippy -- -W clippy::perf"
abbr -a cclcorr "cargo clippy -- -W clippy::correctness"

# ── Format ────────────────────────────────────────────────────────────────────
abbr -a cfmt    "cargo fmt"
abbr -a cfmtall "cargo fmt --all"
abbr -a cfmtc   "cargo fmt --check"
abbr -a cfmtca  "cargo fmt --all --check"
abbr -a cfmtv   "cargo fmt --verbose"
abbr -a cfmtdiff "cargo fmt -- --emit=diff"

# ── Documentation ─────────────────────────────────────────────────────────────
abbr -a cdoc    "cargo doc"
abbr -a cdoco   "cargo doc --open"
abbr -a cdocnd  "cargo doc --no-deps"
abbr -a cdocndo "cargo doc --no-deps --open"
abbr -a cdocall "cargo doc --all-features"
abbr -a cdocw   "cargo doc --workspace"
abbr -a cdocpv  "cargo doc --document-private-items"

# ── Dependency management ─────────────────────────────────────────────────────
abbr -a cadd    "cargo add"
abbr -a caddd   "cargo add --dev"
abbr -a caddb   "cargo add --build"
abbr -a caddf   "cargo add --features"
abbr -a caddno  "cargo add --no-default-features"
abbr -a crm     "cargo remove"
abbr -a cup     "cargo update"
abbr -a cupw    "cargo update --workspace"
abbr -a cupp    "cargo update --precise"           # Pin to specific version

# ── Package info & search ─────────────────────────────────────────────────────
abbr -a cs      "cargo search"
abbr -a ci      "cargo info 2>/dev/null || cargo search"
abbr -a cshow   "cargo show 2>/dev/null || cargo search"
abbr -a ctree   "cargo tree"
abbr -a ctreei  "cargo tree --invert"              # What depends on this?
abbr -a ctreef  "cargo tree --format '{p} {f}'"   # Show features
abbr -a ctreee  "cargo tree --edges all"           # All edge types
abbr -a ctreedup "cargo tree --duplicates"         # Find version conflicts
abbr -a cmeta   "cargo metadata --format-version=1 | jq"
abbr -a cout    "cargo outdated 2>/dev/null || cargo update --dry-run"

# ── Install & uninstall ───────────────────────────────────────────────────────
abbr -a cinst   "cargo install"
abbr -a cinstf  "cargo install --force"
abbr -a cinstg  "cargo install --git"
abbr -a cinstp  "cargo install --path ."
abbr -a cunst   "cargo uninstall"
abbr -a cinstls "cargo install --list"

# ── Project creation ──────────────────────────────────────────────────────────
abbr -a cnew    "cargo new"
abbr -a cnewb   "cargo new --bin"
abbr -a cnewl   "cargo new --lib"
abbr -a cnewve  "cargo new --vcs none"             # No git init
abbr -a cinit   "cargo init"
abbr -a cinitb  "cargo init --bin"
abbr -a cinitl  "cargo init --lib"

# ── Workspace ─────────────────────────────────────────────────────────────────
abbr -a cws     "cargo workspace 2>/dev/null || cargo metadata --no-deps"
abbr -a cwb     "cargo build --workspace"
abbr -a cwt     "cargo test --workspace"
abbr -a cwcl    "cargo clippy --workspace"
abbr -a cwfmt   "cargo fmt --all"
abbr -a cwdoc   "cargo doc --workspace"

# ── Clean ─────────────────────────────────────────────────────────────────────
abbr -a cclean  "cargo clean"
abbr -a ccleanr "cargo clean --release"
abbr -a ccleand "cargo clean --doc"

# ── Misc ──────────────────────────────────────────────────────────────────────
abbr -a cver    "cargo --version"
abbr -a cverb   "cargo version --verbose"
abbr -a cenv    "cargo env"
abbr -a clock   "cargo generate-lockfile"
abbr -a clocku  "cargo update --aggressive"
abbr -a cpkg    "cargo package"
abbr -a cpkgl   "cargo package --list"
abbr -a cpub    "cargo publish"
abbr -a cpubd   "cargo publish --dry-run"
abbr -a cpubno  "cargo publish --no-verify"
abbr -a cown    "cargo owner"
abbr -a clogin  "cargo login"
abbr -a clogout "cargo logout"
abbr -a cyank   "cargo yank"
abbr -a ccfg    "cargo config get"
abbr -a cfeat   "cargo features 2>/dev/null || cargo metadata --format-version=1 | jq '.packages[].features'"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 👀 CARGO WATCH — Auto-rebuild on file changes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-watch || cargo install --list 2>/dev/null | grep -q cargo-watch
    abbr -a cw      "cargo watch"
    abbr -a cwcheck "cargo watch --exec check"
    abbr -a cwrun   "cargo watch --exec run"
    abbr -a cwtest  "cargo watch --exec test"
    abbr -a cwcl    "cargo watch --exec clippy"
    abbr -a cwbuild "cargo watch --exec build"
    abbr -a cwfmt   "cargo watch --exec 'fmt --check'"
    abbr -a cwci    "cargo watch --exec 'clippy --all-targets -- -D warnings' --exec test"
    abbr -a cwq     "cargo watch --quiet"
    abbr -a cwclear "cargo watch --clear"
    abbr -a cwi     "cargo watch --ignore"
    abbr -a cwx     "cargo watch --exec"
    abbr -a cwrun0  "cargo watch --exec 'run -- 0.0.0.0:8080'"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 CARGO NEXTEST — Next-gen test runner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-nextest || cargo install --list 2>/dev/null | grep -q cargo-nextest
    abbr -a cnxt    "cargo nextest run"
    abbr -a cnxtall "cargo nextest run --all-features"
    abbr -a cnxtw   "cargo nextest run --workspace"
    abbr -a cnxtci  "cargo nextest run --profile ci"
    abbr -a cnxtls  "cargo nextest list"
    abbr -a cnxtf   "cargo nextest run --failure-output immediate"
    abbr -a cnxtq   "cargo nextest run --status-level none"
    abbr -a cnxtr   "cargo nextest run --release"
    abbr -a cnxtone "cargo nextest run --test-threads 1"
    abbr -a cnxtret "cargo nextest run --retries 3"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔬 MIRI — Undefined Behavior detector
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-miri || rustup component list --installed 2>/dev/null | grep -q miri
    abbr -a cmiri   "cargo miri test"
    abbr -a cmirirun "cargo miri run"
    abbr -a cmiriall "cargo miri test --all-features"
    abbr -a cmirisetup "rustup component add miri"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 CARGO CRITERION — Benchmarking framework
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a ccrit   "cargo bench --bench"
abbr -a ccritb  "cargo criterion 2>/dev/null || cargo bench"
abbr -a ccritop "open target/criterion/report/index.html 2>/dev/null || \
                 xdg-open target/criterion/report/index.html"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔬 CARGO EXPAND — Macro expansion viewer
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-expand || cargo install --list 2>/dev/null | grep -q cargo-expand
    abbr -a cexp    "cargo expand"
    abbr -a cexpall "cargo expand --all-features"
    abbr -a cexpt   "cargo expand --test"
    abbr -a cexpb   "cargo expand --bin"
    abbr -a cexpl   "cargo expand --lib"
    abbr -a cexpraw "cargo expand --ugly"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 CARGO DIST — Binary distribution
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-dist || cargo install --list 2>/dev/null | grep -q cargo-dist
    abbr -a cdist   "cargo dist"
    abbr -a cdistb  "cargo dist build"
    abbr -a cdistpl "cargo dist plan"
    abbr -a cdistpub "cargo dist publish"
    abbr -a cdistinit "cargo dist init"
    abbr -a cdistman "cargo dist manifest"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔐 CARGO AUDIT — Security vulnerability scanner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cargo-audit || cargo install --list 2>/dev/null | grep -q cargo-audit
    abbr -a caud    "cargo audit"
    abbr -a caudf   "cargo audit fix"
    abbr -a caudfb  "cargo audit fix --breaking"
    abbr -a caudu   "cargo audit --update-db"
    abbr -a caudj   "cargo audit --format=json | jq"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎛️  RUSTUP — Toolchain management
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq rustup
    abbr -a ru      "rustup"
    abbr -a ruup    "rustup update"
    abbr -a ruupd   "rustup update && cargo install-update --all 2>/dev/null"
    abbr -a rustup-update "rustup update"
    abbr -a ruls    "rustup toolchain list"
    abbr -a ruinst  "rustup toolchain install"
    abbr -a ruunst  "rustup toolchain uninstall"
    abbr -a rudf    "rustup default"
    abbr -a rudfst  "rustup default stable"
    abbr -a rudfnt  "rustup default nightly"
    abbr -a ruover  "rustup override"
    abbr -a ruoverl "rustup override list"
    abbr -a ruovers "rustup override set"
    abbr -a ruoverun "rustup override unset"
    abbr -a rucomp  "rustup component"
    abbr -a rucompl "rustup component list --installed"
    abbr -a rucompa "rustup component add"
    abbr -a rucompr "rustup component remove"
    abbr -a rushow  "rustup show"
    abbr -a rushome "rustup show home"
    abbr -a rutarget "rustup target"
    abbr -a rutargetls "rustup target list"
    abbr -a rutargetadd "rustup target add"
    abbr -a rutargetrm "rustup target remove"
    abbr -a rudoc   "rustup doc"
    abbr -a rudocbook "rustup doc --book"
    abbr -a rudocstd "rustup doc --std"
    abbr -a rudocrn "rustup doc --reference"
    abbr -a ruver   "rustup --version"
    abbr -a ruman   "rustup man"
    abbr -a ruset   "rustup set"
    abbr -a ruself  "rustup self"
    abbr -a ruselfup "rustup self update"
    abbr -a ruselfun "rustup self uninstall"

    # Common component additions
    abbr -a ru-rust-src    "rustup component add rust-src"
    abbr -a ru-rust-analyzer "rustup component add rust-analyzer"
    abbr -a ru-clippy      "rustup component add clippy"
    abbr -a ru-fmt         "rustup component add rustfmt"
    abbr -a ru-miri        "rustup component add miri"
    abbr -a ru-llvm-tools  "rustup component add llvm-tools-preview"

    # Cross-compilation targets (common)
    abbr -a ru-wasm    "rustup target add wasm32-unknown-unknown"
    abbr -a ru-wasm-wasi "rustup target add wasm32-wasi"
    abbr -a ru-arm64   "rustup target add aarch64-unknown-linux-gnu"
    abbr -a ru-musl    "rustup target add x86_64-unknown-linux-musl"
    abbr -a ru-win64   "rustup target add x86_64-pc-windows-gnu"
    abbr -a ru-macos   "rustup target add aarch64-apple-darwin"

    # Toolchain shortcuts
    abbr -a ru-nightly "rustup run nightly"
    abbr -a ru-stable  "rustup run stable"
    abbr -a ru-beta    "rustup run beta"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 WASM — WebAssembly tooling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq wasm-pack && begin
    abbr -a wpackb  "wasm-pack build"
    abbr -a wpackt  "wasm-pack test"
    abbr -a wpackp  "wasm-pack publish"
    abbr -a wpackbn "wasm-pack build --target nodejs"
    abbr -a wpackbw "wasm-pack build --target web"
    abbr -a wpackbd "wasm-pack build --dev"
    abbr -a wpackbr "wasm-pack build --release"
    abbr -a wpacklg "wasm-pack build --target bundler"
end

command -sq wasmtime && begin
    abbr -a wtime   "wasmtime"
    abbr -a wtimev  "wasmtime --version"
    abbr -a wtimer  "wasmtime run"
    abbr -a wtimecomp "wasmtime compile"
end

command -sq wasmer && begin
    abbr -a wasmer  "wasmer"
    abbr -a wasmerr "wasmer run"
    abbr -a wasmerinst "wasmer install"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📈 PROFILING & ANALYSIS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq cargo-flamegraph || cargo install --list 2>/dev/null | grep -q flamegraph && begin
    abbr -a cflame  "cargo flamegraph"
    abbr -a cflameb "cargo flamegraph --bench"
    abbr -a cflamet "cargo flamegraph --test"
end

# cargo-llvm-cov (code coverage)
if cargo install --list 2>/dev/null | grep -q llvm-cov
    abbr -a ccov    "cargo llvm-cov"
    abbr -a ccovt   "cargo llvm-cov test"
    abbr -a ccovr   "cargo llvm-cov report"
    abbr -a ccovh   "cargo llvm-cov --html && xdg-open target/llvm-cov/html/index.html"
    abbr -a ccovlcov "cargo llvm-cov --lcov --output-path lcov.info"
    abbr -a ccovci  "cargo llvm-cov --cobertura --output-path coverage.xml"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 CARGO MAKE / JUST — Task runners
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq cargo-make && begin
    abbr -a cmk     "cargo make"
    abbr -a cmkls   "cargo make --list-all-steps"
    abbr -a cmkci   "cargo make ci"
    abbr -a cmkdev  "cargo make dev"
    abbr -a cmktest "cargo make test"
    abbr -a cmkfmt  "cargo make fmt"
    abbr -a cmklint "cargo make lint"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 RUST ANALYZER — LSP & tooling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq rust-analyzer && begin
    abbr -a ra      "rust-analyzer"
    abbr -a raver   "rust-analyzer --version"
    abbr -a radiag  "rust-analyzer diagnostics"
    abbr -a rasym   "rust-analyzer symbols"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 FULL CI WORKFLOW — One-liner quality gates
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a rustci   "cargo fmt --check && \
                  cargo clippy --all-targets --all-features -- -D warnings && \
                  cargo test --all-features && \
                  echo '✅ Rust CI passed'"

abbr -a rustfull "cargo fmt --all && \
                  cargo clippy --all-targets --all-features --fix --allow-staged && \
                  cargo test --all-features --workspace && \
                  cargo doc --all-features --no-deps && \
                  echo '✅ Full Rust quality check complete'"

abbr -a rustinfo "echo '🦀 Rust:' (rustc --version) && \
                  echo '📦 Cargo:' (cargo --version) && \
                  echo '🔧 rustup:' (rustup --version 2>/dev/null) && \
                  echo '🌍 Targets:' && rustup target list --installed"