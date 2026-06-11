# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH PATH CONFIGURATION                      ║
# ║           PATH additions (loaded second, after 00-env.fish)               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# 📁 USER PATH (highest priority)
# ═══════════════════════════════════════════════════════════════════════════════

# User binaries — highest priority
fish_add_path --prepend "$HOME/.local/bin"

# ASH dotfiles bin
fish_add_path --prepend "$HOME/.dotfiles/bin"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 DEVELOPMENT TOOLS
# ═══════════════════════════════════════════════════════════════════════════════

# Rust (cargo)
if test -d "$HOME/.cargo/bin"
    fish_add_path "$HOME/.cargo/bin"
    set -gx CARGO_HOME "$HOME/.cargo"
    set -gx RUSTUP_HOME "$HOME/.rustup"
end

# Go
if test -d "$HOME/go/bin"
    fish_add_path "$HOME/go/bin"
    set -gx GOPATH "$HOME/go"
    set -gx GOBIN  "$HOME/go/bin"
end

# Node.js (nvm-managed)
if test -d "$HOME/.nvm"
    set -gx NVM_DIR "$HOME/.nvm"
    # NVM integration handled by nvm.fish plugin
end

# Python user installs
if test -d "$HOME/.local/lib"
    for pybin in $HOME/.local/lib/python*/site-packages/bin
        test -d $pybin && fish_add_path $pybin
    end
end

# Ruby (rbenv)
if test -d "$HOME/.rbenv/bin"
    fish_add_path "$HOME/.rbenv/bin"
    status is-interactive && rbenv init - fish | source 2>/dev/null
end

# Java (SDKMAN managed)
if test -d "$HOME/.sdkman/bin"
    fish_add_path "$HOME/.sdkman/bin"
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🐧 SYSTEM PATHS
# ═══════════════════════════════════════════════════════════════════════════════

# Snap
test -d /snap/bin && fish_add_path /snap/bin

# Flatpak
test -d /var/lib/flatpak/exports/bin && fish_add_path /var/lib/flatpak/exports/bin
test -d "$HOME/.local/share/flatpak/exports/bin" && fish_add_path "$HOME/.local/share/flatpak/exports/bin"

# ═══════════════════════════════════════════════════════════════════════════════
# 🧹 DEDUP PATH
# ═══════════════════════════════════════════════════════════════════════════════

# Remove duplicates from PATH (fish handles this, but be explicit)
set -gx PATH (string split : $PATH | uniq | string join :)