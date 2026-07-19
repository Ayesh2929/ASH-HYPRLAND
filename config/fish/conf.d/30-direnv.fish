# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — direnv Ultra Configuration                         ║
# ║  Per-directory environments with smart hooks, templates & ASH integration  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Require direnv ─────────────────────────────────────────────────────
command -q direnv || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_direnv_loaded && exit 0
set --global _ash_direnv_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_direnv_log      "$HOME/.local/share/ash/logs/direnv.log"
set --global _ash_direnv_lib_dir  "$HOME/.config/direnv/lib"
set --global _ash_direnv_allow_dir "$HOME/.local/share/direnv/allow"

mkdir -p (dirname $_ash_direnv_log) 2>/dev/null
mkdir -p $_ash_direnv_lib_dir      2>/dev/null
mkdir -p $_ash_direnv_allow_dir    2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _de_reset   (set_color normal)
set -g _de_bold    (set_color --bold)
set -g _de_cyan    (set_color cyan)
set -g _de_green   (set_color green)
set -g _de_yellow  (set_color yellow)
set -g _de_red     (set_color red)
set -g _de_blue    (set_color blue)
set -g _de_dim     (set_color brblack)
set -g _de_purple  (set_color magenta)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  DIRENV CONFIGURATION                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# XDG-compliant config directory
set --export DIRENV_CONFIG "$HOME/.config/direnv"

# Log level: trace | debug | info | warn | error
set --export DIRENV_LOG_FORMAT ""   # Empty = silent (no clutter)

# Warn timeout for slow .envrc files
set --export DIRENV_WARN_TIMEOUT "5s"

# ── Create direnv.toml if missing ─────────────────────────────────────────────
if not test -f "$DIRENV_CONFIG/direnv.toml"
    mkdir -p $DIRENV_CONFIG
    printf '[global]\nwarn_timeout = "5s"\nhide_env_diff = false\n\n[whitelist]\n# prefix = ["/home/user/projects"]\n' \
        > "$DIRENV_CONFIG/direnv.toml"
end

# ── Write stdlib extensions if missing ────────────────────────────────────────
if not test -f "$_ash_direnv_lib_dir/ash.sh"
    echo '# ── ASH direnv stdlib extensions ─────────────────────────────────────────────

# use_node: Auto-switch Node version from .nvmrc
use_node() {
    local version="${1:-}"
    if [ -f .nvmrc ] && [ -z "$version" ]; then
        version=$(cat .nvmrc | tr -d \'[:space:]\')
    fi
    if [ -n "$version" ] && command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --use-on-cd --shell bash)"
        fnm use "$version" 2>/dev/null || fnm install "$version"
    fi
}

# use_python: Auto-activate Python venv
use_python() {
    local version="${1:-3}"
    local venv_dir="${2:-.venv}"

    if [ ! -d "$venv_dir" ]; then
        log_status "Creating venv: $venv_dir (python$version)"
        python${version} -m venv "$venv_dir"
    fi

    if [ -f "$venv_dir/bin/activate" ]; then
        source "$venv_dir/bin/activate"
        log_status "Activated: $venv_dir ($(python --version 2>&1))"
    fi
}

# use_ruby: Switch Ruby version
use_ruby() {
    local version="${1:-}"
    if command -v rbenv >/dev/null 2>&1; then
        rbenv local "$version" 2>/dev/null
        eval "$(rbenv init - bash)"
    fi
}

# dotenv_ifexists: Load .env only if it exists (no error if missing)
dotenv_ifexists() {
    local file="${1:-.env}"
    [ -f "$file" ] && dotenv "$file"
}

# require_tool: Assert a tool is installed
require_tool() {
    local tool="$1"
    local message="${2:-}"
    if ! command -v "$tool" >/dev/null 2>&1; then
        log_error "Required tool not found: $tool ${message}"
        return 1
    fi
    log_status "✓ $tool found"
}

# env_if_missing: Set env var only if not already set
env_if_missing() {
    local var="$1"
    local val="$2"
    if [ -z "${!var:-}" ]; then
        export "${var}=${val}"
    fi
}

# layout_poetry: Poetry virtual environment layout
layout_poetry() {
    if ! command -v poetry >/dev/null 2>&1; then
        log_error "poetry not found"
        return 1
    fi

    local pyproject="$PWD/pyproject.toml"
    if [ ! -f "$pyproject" ]; then
        log_error "pyproject.toml not found"
        return 1
    fi

    local venv
    venv="$(poetry env info --path 2>/dev/null)"
    if [ -z "$venv" ]; then
        log_status "Creating poetry environment..."
        poetry install --quiet
        venv="$(poetry env info --path)"
    fi

    export VIRTUAL_ENV="$venv"
    export POETRY_ACTIVE=1
    PATH_add "$venv/bin"
    log_status "Poetry env: $venv"
}

# layout_pdm: PDM virtual environment layout
layout_pdm() {
    if ! command -v pdm >/dev/null 2>&1; then
        log_error "pdm not found"
        return 1
    fi

    local venv
    venv="$(pdm venv in-project 2>/dev/null || pdm info --python 2>/dev/null | head -1)"
    if [ -d ".venv" ]; then
        export VIRTUAL_ENV="$PWD/.venv"
        PATH_add "$PWD/.venv/bin"
    fi
}

# layout_uv: uv virtual environment layout
layout_uv() {
    if ! command -v uv >/dev/null 2>&1; then
        log_error "uv not found"
        return 1
    fi

    if [ ! -d ".venv" ]; then
        log_status "Creating uv environment..."
        uv venv 2>/dev/null
    fi

    export VIRTUAL_ENV="$PWD/.venv"
    PATH_add "$PWD/.venv/bin"
    log_status "uv env: $VIRTUAL_ENV"
}

# layout_bun: Bun project layout
layout_bun() {
    if ! command -v bun >/dev/null 2>&1; then
        log_error "bun not found"
        return 1
    fi
    PATH_add "$PWD/node_modules/.bin"
    log_status "Bun layout active"
}

# watch_file_pattern: Watch for file pattern changes
watch_file_pattern() {
    local pattern="$1"
    for f in $pattern; do
        [ -f "$f" ] && watch_file "$f"
    done
}' > "$_ash_direnv_lib_dir/ash.sh"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZE DIRENV HOOK                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core hook — runs direnv on every prompt
direnv hook fish | source

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📡 SMART HOOKS: Enhanced direnv events                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── On direnv load: Emit ASH event ───────────────────────────────────────────
function __ash_direnv_on_load --on-event direnv_loaded \
    --description "Handle direnv load event"
    set -l envrc_path $argv[1]
    echo "["(date '+%H:%M:%S')"] loaded: $envrc_path" >> $_ash_direnv_log 2>/dev/null

    # Emit ASH event for other components
    emit ash_direnv_loaded $envrc_path
end

# ─── On direnv unload: Cleanup ────────────────────────────────────────────────
function __ash_direnv_on_unload --on-event direnv_unloaded \
    --description "Handle direnv unload event"
    echo "["(date '+%H:%M:%S')"] unloaded" >> $_ash_direnv_log 2>/dev/null
    emit ash_direnv_unloaded
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── direnv-new: Create .envrc from template ──────────────────────────────────
function direnv-new --description "Create a new .envrc file from template"
    set -l type $argv[1]

    if test -f .envrc
        echo $_de_yellow"  ⚠  .envrc already exists"$_de_reset
        read -P "  Overwrite? [y/N] " confirm
        string match -qi 'y*' $confirm || return 0
    end

    if test -z "$type"
        set type (
            printf \
                "basic\tBasic shell environment\n" \
                "node\tNode.js + npm/pnpm project\n" \
                "python\tPython virtual environment\n" \
                "python-poetry\tPython Poetry project\n" \
                "python-uv\tPython uv project\n" \
                "rust\tRust/Cargo project\n" \
                "go\tGo module project\n" \
                "docker\tDocker development environment\n" \
                "aws\tAWS CLI profile setup\n" \
                "terraform\tTerraform workspace\n" \
                "kubernetes\tKubernetes context setup\n" \
                "mono\tMonorepo / multi-language\n" |
            fzf --ansi \
                --border-label "  📋 .envrc Template " \
                --border rounded \
                --prompt "  " \
                --pointer "▶" \
                --no-multi \
                --header '  Enter:create  ' \
            | awk '{print $1}'
        )
        test -z "$type" && return 0
    end

    set -l project_name (basename $PWD)

    switch $type
        case basic
            printf '# ── %s Environment ───────────────────────────────────────\n# Generated by ASH direnv — %s\n\n# Project root\nexport PROJECT_ROOT="$PWD"\nexport PROJECT_NAME="%s"\n\n# Add local bin to PATH\nPATH_add bin\nPATH_add scripts\n\n# Load .env if present\ndotenv_ifexists ".env"\n' \
                $project_name (date '+%Y-%m-%d') $project_name > .envrc

        case node nodejs
            printf '# ── Node.js Environment ─────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\nexport NODE_ENV="development"\n\n# Local node_modules bin\nPATH_add node_modules/.bin\n\n# Use .nvmrc if present\nuse node\n\n# Load .env files\ndotenv_ifexists ".env.local"\ndotenv_ifexists ".env"\n\n# Require essential tools\nrequire_tool node\nrequire_tool pnpm\n' \
                (date '+%Y-%m-%d') > .envrc

        case python
            printf '# ── Python Environment ───────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\n\n# Activate virtual environment\nlayout python3\n\n# Or use specific Python version:\n# use python 3.12\n\n# Load .env\ndotenv_ifexists ".env"\n\n# Require Python\nrequire_tool python3\n' \
                (date '+%Y-%m-%d') > .envrc

        case python-poetry
            printf '# ── Poetry Environment ───────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\n\n# Poetry virtual environment\nlayout poetry\n\n# Load .env\ndotenv_ifexists ".env"\n\nexport PYTHONDONTWRITEBYTECODE=1\nexport PYTHONUNBUFFERED=1\n' \
                (date '+%Y-%m-%d') > .envrc

        case python-uv
            printf '# ── uv Environment ───────────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\n\n# uv virtual environment\nlayout uv\n\n# Load .env\ndotenv_ifexists ".env"\n\nexport PYTHONDONTWRITEBYTECODE=1\nexport PYTHONUNBUFFERED=1\n' \
                (date '+%Y-%m-%d') > .envrc

        case rust
            printf '# ── Rust Environment ─────────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\n\n# Cargo env\nexport CARGO_HOME="$HOME/.cargo"\nexport RUST_BACKTRACE=1\nexport CARGO_TERM_COLOR=always\nexport RUSTFLAGS="-C link-arg=-fuse-ld=mold"\n\n# sccache if available\nif command -v sccache >/dev/null; then\n  export RUSTC_WRAPPER=sccache\nfi\n\nrequire_tool cargo\n' \
                (date '+%Y-%m-%d') > .envrc

        case go golang
            printf '# ── Go Environment ───────────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\n\n# Go settings\nexport GOPATH="$HOME/go"\nexport GOBIN="$GOPATH/bin"\nexport CGO_ENABLED=1\nexport GOPROXY="https://proxy.golang.org,direct"\n\nPATH_add "$GOPATH/bin"\nPATH_add "bin"\n\nrequire_tool go\n' \
                (date '+%Y-%m-%d') > .envrc

        case docker
            printf '# ── Docker Environment ───────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\nexport COMPOSE_PROJECT_NAME="%s"\nexport COMPOSE_FILE="docker-compose.yml"\nexport DOCKER_BUILDKIT=1\nexport COMPOSE_DOCKER_CLI_BUILD=1\n\n# Registry settings\nexport REGISTRY="ghcr.io"\nexport IMAGE_NAME="%s"\nexport IMAGE_TAG="$(git rev-parse --short HEAD 2>/dev/null || echo latest)"\n\ndotenv_ifexists ".env"\nrequire_tool docker\n' \
                (date '+%Y-%m-%d') $project_name $project_name > .envrc

        case aws
            printf '# ── AWS Environment ──────────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport AWS_PROFILE="default"\nexport AWS_REGION="us-east-1"\nexport AWS_DEFAULT_REGION="$AWS_REGION"\n\n# Uncomment to override:\n# export AWS_ACCESS_KEY_ID=""\n# export AWS_SECRET_ACCESS_KEY=""\n\ndotenv_ifexists ".env.aws"\nrequire_tool aws\n' \
                (date '+%Y-%m-%d') > .envrc

        case terraform
            printf '# ── Terraform Environment ────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport PROJECT_ROOT="$PWD"\nexport TF_WORKSPACE="dev"\nexport TF_VAR_project="%s"\nexport TF_VAR_environment="$TF_WORKSPACE"\n\n# Disable checkpoint\nexport CHECKPOINT_DISABLE=1\n\n# AWS backend (if used)\nexport AWS_PROFILE="terraform"\nexport AWS_REGION="us-east-1"\n\ndotenv_ifexists ".env.terraform"\ndotenv_ifexists ".env"\nrequire_tool terraform\n' \
                (date '+%Y-%m-%d') $project_name > .envrc

        case kubernetes
            printf '# ── Kubernetes Environment ───────────────────────────────\n# Generated by ASH direnv — %s\n\nexport KUBECONFIG="$HOME/.kube/config"\nexport KUBECTL_NAMESPACE="default"\n\n# Context switching\n# export KUBE_CONTEXT="my-cluster"\n# kubectl config use-context "$KUBE_CONTEXT"\n\nrequire_tool kubectl\n' \
                (date '+%Y-%m-%d') > .envrc

        case mono monorepo
            printf '# ── Monorepo Environment ─────────────────────────────────\n# Generated by ASH direnv — %s\n\nexport MONOREPO_ROOT="$PWD"\nexport PROJECT_NAME="%s"\n\n# Add all bin directories\nPATH_add bin\nPATH_add scripts\nPATH_add node_modules/.bin\n\n# Load shared .env\ndotenv_ifexists ".env"\ndotenv_ifexists ".env.local"\n\n# Node\nexport NODE_ENV="development"\nuse node\n\n# Python (if used)\n# layout python3\n\n# Tool requirements\nrequire_tool node\n' \
                (date '+%Y-%m-%d') $project_name > .envrc

        case '*'
            echo $_de_red"  ✗ Unknown template: $type"$_de_reset
            return 1
    end

    echo $_de_green"  ✓ .envrc created ($type)"$_de_reset

    # Auto-allow and load
    direnv allow .
    and echo $_de_green"  ✓ .envrc allowed and loaded"$_de_reset
end

# ─── direnv-edit: Edit .envrc in editor ───────────────────────────────────────
function direnv-edit --description "Edit .envrc in EDITOR and re-allow"
    set -l envrc $argv[1]
    test -z "$envrc" && set envrc ".envrc"

    if not test -f $envrc
        echo $_de_yellow"  No .envrc found. Creating..."$_de_reset
        direnv-new
        return
    end

    set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)
    $editor $envrc

    # Re-allow after editing
    if test -f $envrc
        direnv allow $envrc
        direnv reload
        echo $_de_green"  ✓ .envrc saved and reloaded"$_de_reset
    end
end

# ─── direnv-status: Rich direnv status ────────────────────────────────────────
function direnv-status --description "Show rich direnv status"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     📋  direnv Status                                ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Version:   "$reset $dim(direnv --version)$reset
    echo "  "$bold"Config:    "$reset $dim$DIRENV_CONFIG$reset
    echo ""

    # Current .envrc
    if test -f .envrc
        echo "  "$bold"Current .envrc:"$reset
        set -l allowed (direnv status 2>/dev/null | grep "Found RC" | head -1)
        if string match -q '*allowed*' $allowed
            echo "  "$green"  ✓ .envrc allowed"$reset
        else
            echo "  "$yellow"  ⚠ .envrc not allowed (run: direnv allow)"$reset
        end
        echo ""
        echo "  "$bold"Content:"$reset
        cat .envrc | while read -l line
            echo "    "$dim$line$reset
        end
    else
        echo "  "$dim"No .envrc in current directory"$reset
    end

    echo ""

    # Loaded environment
    if test -n "$DIRENV_DIR"
        echo "  "$bold"Loaded from: "$reset $dim$DIRENV_DIR$reset
        echo "  "$bold"Env changes: "$reset
        direnv status 2>/dev/null | grep -E "^export" | head -10 | while read -l line
            echo "    "$dim$line$reset
        end
    end

    echo ""
end

# ─── direnv-tree: Show .envrc hierarchy ───────────────────────────────────────
function direnv-tree --description "Show .envrc files in directory tree"
    set -l root $argv[1]
    test -z "$root" && set root $PWD

    echo ""
    echo $_de_cyan"  📁 .envrc files under: $root"$_de_reset
    echo ""

    find $root -name ".envrc" -not -path "*/.git/*" 2>/dev/null | sort | \
    while read -l envrc_path
        set -l relative (string replace $root '' $envrc_path)
        set -l allowed_marker ""
        direnv status 2>/dev/null | grep -q "$envrc_path" && \
            set allowed_marker $_de_green" (allowed)"$_de_reset || \
            set allowed_marker $_de_yellow" (blocked)"$_de_reset

        echo "  "$_de_dim$relative$_de_reset$allowed_marker
    end
    echo ""
end

# ─── direnv-allow-all: Allow all .envrc in tree ───────────────────────────────
function direnv-allow-all --description "Allow all .envrc files under a directory"
    set -l root $argv[1]
    test -z "$root" && set root $PWD

    echo ""
    echo $_de_yellow"  ⚠  Allowing ALL .envrc files under $root"$_de_reset
    read -P "  Confirm? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    find $root -name ".envrc" -not -path "*/.git/*" 2>/dev/null | \
    while read -l envrc_path
        direnv allow (dirname $envrc_path)
        and echo $_de_green"  ✓ Allowed: $envrc_path"$_de_reset
    end
    echo ""
end

# ─── direnv-block: Block/revoke a .envrc ──────────────────────────────────────
function direnv-block --description "Block/revoke direnv access to current directory"
    set -l path $argv[1]
    test -z "$path" && set path $PWD

    direnv deny $path
    and echo $_de_yellow"  ⚠ .envrc blocked: $path"$_de_reset
end

# ─── direnv-diff: Show diff of loaded env vs clean ────────────────────────────
function direnv-diff --description "Show what env vars direnv adds/modifies"
    direnv exec / env 2>/dev/null > /tmp/direnv-base-env
    env > /tmp/direnv-current-env

    if command -q diff
        diff /tmp/direnv-base-env /tmp/direnv-current-env | \
            grep '^[<>]' | sort | \
            while read -l line
                if string match -q '>*' $line
                    echo $_de_green"  + "(string replace '> ' '' $line)$_de_reset
                else
                    echo $_de_red"  - "(string replace '< ' '' $line)$_de_reset
                end
            end
    end
    rm -f /tmp/direnv-base-env /tmp/direnv-current-env
end

# ─── direnv-reload: Force reload .envrc ───────────────────────────────────────
function direnv-reload --description "Force reload current .envrc"
    if test -f .envrc
        direnv reload
        echo $_de_green"  ✓ .envrc reloaded"$_de_reset
    else
        echo $_de_dim"  No .envrc in current directory"$_de_reset
    end
end

# ─── .env manager: Manage .env files ──────────────────────────────────────────
function dotenv-edit --description "Edit .env file with secret masking"
    set -l file $argv[1]
    test -z "$file" && set file ".env"

    if not test -f $file
        echo $_de_yellow"  Creating: $file"$_de_reset
        printf '# ── Environment Variables ────────────────────────────\n# Auto-loaded by direnv\n\n# APP_ENV=development\n# DATABASE_URL=\n# API_KEY=\n' \
            > $file
        echo "  ⚠  Add $file to .gitignore!"
    end

    set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)
    $editor $file
end

function dotenv-show --description "Show .env contents (mask secrets)"
    set -l file $argv[1]
    test -z "$file" && set file ".env"

    if not test -f $file
        echo $_de_red"  ✗ Not found: $file"$_de_reset
        return 1
    end

    echo ""
    echo $_de_bold$_de_cyan"  📋 $file"$_de_reset
    echo ""

    while read -l line
        # Skip comments and empty lines
        string match -q '#*' $line && begin; echo "  "$_de_dim$line$_de_reset; continue; end
        string match -q '' $line   && begin; echo ""; continue; end

        # Split key=value
        set -l key (string split --max 1 '=' $line)[1]
        set -l val (string split --max 1 '=' $line)[2]

        # Mask secrets
        set -l masked_val $val
        for pattern in PASSWORD SECRET KEY TOKEN PASS PRIVATE CREDENTIAL AUTH
            if string match -qi "*$pattern*" $key
                set masked_val (string repeat -n (string length $val) '*')
                break
            end
        end

        printf "  $_de_cyan%-30s$_de_reset $_de_dim%s$_de_reset\n" "$key=" $masked_val
    end < $file
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add da      'direnv allow'
abbr --add db      'direnv-block'
abbr --add dr      'direnv-reload'
abbr --add ds      'direnv-status'
abbr --add dn      'direnv-new'
abbr --add de      'direnv-edit'
abbr --add dd      'direnv-diff'
abbr --add dt      'direnv-tree'
abbr --add daa     'direnv-allow-all'
abbr --add dedit   'dotenv-edit'
abbr --add dshow   'dotenv-show'
abbr --add envshow 'dotenv-show'
abbr --add envedit 'dotenv-edit'