#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  🛤️  PATH CONSTRUCTION ENGINE                                                   ║
# ║                                                                                  ║
# ║  01-path.fish — Builds the complete $PATH in priority order                    ║
# ║  Depends on: 00-xdg.fish (XDG vars must be set first)                         ║
# ║                                                                                  ║
# ║  Strategy:                                                                       ║
# ║    • fish_add_path → idempotent, deduplicating, persistent via fish_user_paths ║
# ║    • Entries ordered by priority: user > ash > tools > system                  ║
# ║    • Conditional: only add paths for installed tools                            ║
# ║    • Never pollutes PATH with non-existent directories                          ║
# ║                                                                                  ║
# ║  ASH Dotfiles v5.0 OMEGA                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_path_initialized && exit 0
set -g __ash_path_initialized 1

# ── Require XDG foundation ────────────────────────────────────────────────────
set -q XDG_DATA_HOME || begin
    echo "⚠️  [01-path] XDG not initialized — ensure 00-xdg.fish loads first" >&2
    exit 1
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 HELPER — Conditional path adder
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# fish_add_path already checks dir existence but we add explicit logging
# for the ASH doctor to detect path issues.

function __ash_add_path
    # Usage: __ash_add_path [--append] <dir>
    set -l flag    "--prepend"
    set -l dir     $argv[-1]
    test "$argv[1]" = "--append" && set flag "--append"

    if test -d "$dir"
        fish_add_path $flag --path "$dir"
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🥇 TIER 1 — Highest priority (user-controlled binaries)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Listed in REVERSE priority (prepend adds to front, so last-listed = highest)

# ASH CLI binary — must be reachable as `ash` everywhere
__ash_add_path "$ASH_BIN"

# Personal scripts — ~/bin and ~/.local/bin
__ash_add_path "$HOME/bin"
__ash_add_path "$HOME/.local/bin"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🥈 TIER 2 — Language runtime binaries
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Rust / Cargo ──────────────────────────────────────────────────────────────
__ash_add_path "$CARGO_HOME/bin"

# ── Go ────────────────────────────────────────────────────────────────────────
__ash_add_path "$GOPATH/bin"
# System Go install (distro-managed)
for __go_sys in /usr/local/go/bin /usr/lib/go/bin
    __ash_add_path --append $__go_sys
end

# ── Python ────────────────────────────────────────────────────────────────────
# pyenv shims (must precede system python)
if test -d $PYENV_ROOT
    __ash_add_path "$PYENV_ROOT/bin"
    __ash_add_path "$PYENV_ROOT/shims"
    # Initialize pyenv if not already done by pam/systemd
    command -sq pyenv && not set -q PYENV_SHELL \
        && pyenv init - fish | source
end
# pip user installs
__ash_add_path "$HOME/.local/lib/python3/site-packages/bin" 2>/dev/null
for __py_ver in 3.13 3.12 3.11 3.10 3.9
    __ash_add_path --append "$HOME/.local/lib/python$__py_ver/site-packages/bin"
end
# pipx executables
__ash_add_path "$PIPX_HOME/bin"

# ── Node / JavaScript ─────────────────────────────────────────────────────────
__ash_add_path "$PNPM_HOME"
__ash_add_path "$BUN_INSTALL/bin"
__ash_add_path "$DENO_INSTALL/bin"
__ash_add_path "$NPM_CONFIG_PREFIX/bin"
# fnm (Fast Node Manager)
if command -sq fnm
    fnm env --use-on-cd | source
end
# nvm lazy init (heavy — only init if .nvmrc present in project tree)
# Full nvm init in conf.d/24-nvm.fish

# ── Ruby / Gems ───────────────────────────────────────────────────────────────
__ash_add_path "$GEM_HOME/bin"
if command -sq rbenv
    __ash_add_path "$HOME/.rbenv/bin"
    rbenv init - fish | source
end

# ── Java / JVM ecosystem ──────────────────────────────────────────────────────
# JAVA_HOME detection (check common paths)
if not set -q JAVA_HOME
    for __java_path in \
        /usr/lib/jvm/default \
        /usr/lib/jvm/java-21-openjdk \
        /usr/lib/jvm/java-17-openjdk \
        /usr/lib/jvm/java-11-openjdk \
        /usr/local/opt/openjdk  # macOS Homebrew fallback
        if test -d $__java_path
            set -gx JAVA_HOME $__java_path
            break
        end
    end
end
set -q JAVA_HOME && __ash_add_path "$JAVA_HOME/bin"
__ash_add_path "$GRADLE_USER_HOME/bin"

# ── Haskell / GHCup ──────────────────────────────────────────────────────────
__ash_add_path "$XDG_DATA_HOME/ghcup/bin"
__ash_add_path "$HOME/.cabal/bin"

# ── Lua / LuaRocks ───────────────────────────────────────────────────────────
__ash_add_path "$LUAROCKS_HOME/bin"
# Lua language server
__ash_add_path "$HOME/.local/lib/lua-language-server/bin"

# ── Zig ───────────────────────────────────────────────────────────────────────
test -d "$XDG_DATA_HOME/zig" && __ash_add_path "$XDG_DATA_HOME/zig"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🥉 TIER 3 — DevOps & cloud tool binaries
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Kubernetes tools ──────────────────────────────────────────────────────────
__ash_add_path "$HOME/.krew/bin"                       # kubectl plugins via krew
__ash_add_path "$XDG_DATA_HOME/kube/plugins"           # custom kubectl plugins

# ── Terraform ─────────────────────────────────────────────────────────────────
__ash_add_path "$HOME/.tfenv/bin"                      # tfenv
__ash_add_path "$HOME/.tgenv/bin"                      # terragrunt env

# ── Google Cloud SDK ──────────────────────────────────────────────────────────
for __gcloud_path in \
    "$CLOUDSDK_CONFIG/../bin" \
    "$HOME/.local/share/google-cloud-sdk/bin" \
    "/opt/google-cloud-sdk/bin"
    if test -d $__gcloud_path
        __ash_add_path $__gcloud_path
        # Source gcloud completions if available
        set -l __gcloud_comp "$__gcloud_path/../completion.fish.inc"
        test -f $__gcloud_comp && source $__gcloud_comp
        break
    end
end

# ── Hashicorp Vault / Consul ──────────────────────────────────────────────────
__ash_add_path "$XDG_DATA_HOME/vault/bin"
__ash_add_path "$XDG_DATA_HOME/consul/bin"

# ── Helm ──────────────────────────────────────────────────────────────────────
__ash_add_path "$XDG_DATA_HOME/helm/bin"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏅 TIER 4 — System package manager paths (appended — lowest user priority)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Flatpak ───────────────────────────────────────────────────────────────────
__ash_add_path --append "/var/lib/flatpak/exports/bin"
__ash_add_path --append "$XDG_DATA_HOME/flatpak/exports/bin"

# ── Snap ──────────────────────────────────────────────────────────────────────
__ash_add_path --append "/snap/bin"

# ── Homebrew (Linux) ──────────────────────────────────────────────────────────
for __brew_path in /home/linuxbrew/.linuxbrew/bin /usr/local/bin
    if test -d $__brew_path && test -x "$__brew_path/brew"
        __ash_add_path --append $__brew_path
        set -gx HOMEBREW_PREFIX (string replace "/bin" "" $__brew_path)
        set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
        set -gx HOMEBREW_NO_ANALYTICS 1
        set -gx HOMEBREW_NO_AUTO_UPDATE 1
        break
    end
end

# ── Nix package manager ───────────────────────────────────────────────────────
if test -e "$HOME/.nix-profile/etc/profile.d/nix.sh"
    # Source nix environment in a bash subshell and extract vars
    set -l __nix_path (bash -c ". $HOME/.nix-profile/etc/profile.d/nix.sh && echo \$PATH" 2>/dev/null)
    if test -n "$__nix_path"
        for __nix_dir in (string split : $__nix_path)
            test -d $__nix_dir && __ash_add_path --append $__nix_dir
        end
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 MANPATH — Manual pages for user-installed tools
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Fish doesn't manage MANPATH — set it explicitly for XDG compliance

set -l __man_paths \
    "$HOME/.local/share/man" \
    "$CARGO_HOME/share/man" \
    "$GOPATH/share/man" \
    "/usr/local/share/man" \
    "/usr/share/man"

set -gx MANPATH ""
for __mpath in $__man_paths
    test -d $__mpath && set -gx MANPATH "$MANPATH:$__mpath"
end
set -gx MANPATH (string trim --chars=: $MANPATH)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
functions --erase __ash_add_path

set -e __go_sys __java_path __py_ver __gcloud_path __gcloud_comp
set -e __brew_path __nix_path __nix_dir __mpath __man_paths