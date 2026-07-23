# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Conda/Mamba Ultra Configuration                   ║
# ║  Smart conda/mamba/micromamba with ASH integration & performance hooks     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_conda_loaded && exit 0
set --global _ash_conda_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 DETECTION: Find conda/mamba/micromamba installation                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Determine backend priority ────────────────────────────────────────────────
# micromamba → mamba → conda (micromamba is fastest)

function __ash_conda_detect_backend --description "Detect best available conda backend"
    # micromamba: fastest, standalone binary
    if command -q micromamba
        echo "micromamba"
        return
    end

    # mamba: faster conda replacement
    for conda_root in \
        "$HOME/mambaforge" \
        "$HOME/miniforge3" \
        "$HOME/opt/mambaforge" \
        "/opt/mambaforge" \
        "/opt/miniforge3"
        if test -x "$conda_root/bin/mamba"
            echo "mamba"
            set --global _ash_conda_root $conda_root
            return
        end
    end

    # conda: standard installation
    for conda_root in \
        "$HOME/miniconda3" \
        "$HOME/anaconda3" \
        "$HOME/miniforge3" \
        "$HOME/.conda" \
        "$HOME/opt/miniconda3" \
        "$HOME/opt/anaconda3" \
        "/opt/miniconda3" \
        "/opt/anaconda3" \
        "/opt/conda"
        if test -x "$conda_root/bin/conda"
            echo "conda"
            set --global _ash_conda_root $conda_root
            return
        end
    end

    # Check CONDA_EXE env (set by some installers)
    if test -n "$CONDA_EXE" && test -x "$CONDA_EXE"
        echo "conda"
        set --global _ash_conda_root (dirname (dirname $CONDA_EXE))
        return
    end

    echo "none"
end

set --global _ash_conda_backend (__ash_conda_detect_backend)

# Exit early if no conda found
if test "$_ash_conda_backend" = none
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _conda_reset   (set_color normal)
set -g _conda_bold    (set_color --bold)
set -g _conda_cyan    (set_color cyan)
set -g _conda_green   (set_color green)
set -g _conda_yellow  (set_color yellow)
set -g _conda_red     (set_color red)
set -g _conda_blue    (set_color blue)
set -g _conda_purple  (set_color magenta)
set -g _conda_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  CONFIGURATION                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Auto-activate base environment on shell start (false = lazy loading)
set --global _ash_conda_auto_activate false

# Show conda env name in prompt (handled by starship, so off by default)
set --global _ash_conda_show_env true

# Suppress conda's default prompt modification (we use starship)
set --export CONDA_CHANGEPS1 false

# Default channel priority
set --export CONDA_CHANNEL_PRIORITY strict

# Enable conda-libmamba-solver if available (faster dependency resolution)
set --export CONDA_SOLVER libmamba

# Paths for project-local envs
set --global _ash_conda_project_env ".venv .conda env"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION: micromamba                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_conda_init_micromamba --description "Initialize micromamba"
    # Find micromamba root
    set -l mm_root
    for candidate in \
        "$HOME/.local/share/mamba" \
        "$HOME/micromamba" \
        "$HOME/.mamba" \
        "/opt/micromamba"
        if test -d $candidate
            set mm_root $candidate
            break
        end
    end

    # micromamba shell init — sets up activate/deactivate etc.
    if test -n "$mm_root"
        set --export MAMBA_ROOT_PREFIX $mm_root
    else
        set --export MAMBA_ROOT_PREFIX "$HOME/micromamba"
    end

    # Initialize micromamba for fish
    micromamba shell hook --shell fish 2>/dev/null | source

    # Create alias so 'conda' works with micromamba
    function conda --wraps=micromamba --description "conda → micromamba alias"
        micromamba $argv
    end
    function mamba --wraps=micromamba --description "mamba → micromamba alias"
        micromamba $argv
    end

    set --global _ash_conda_root $MAMBA_ROOT_PREFIX
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀 INITIALIZATION: mamba / conda                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_conda_init_standard --description "Initialize mamba or conda"
    set -l conda_bin "$_ash_conda_root/bin/conda"
    set -l mamba_bin "$_ash_conda_root/bin/mamba"

    # Source conda's fish integration
    if test -f "$_ash_conda_root/etc/profile.d/conda.sh"
        # Adapt conda.sh for fish using conda's built-in fish support
        eval $_ash_conda_root/bin/conda "shell.fish" "hook" 2>/dev/null | source
    else if test -f "$_ash_conda_root/etc/fish/conf.d/conda.fish"
        source "$_ash_conda_root/etc/fish/conf.d/conda.fish" 2>/dev/null
    end

    # Also source mamba if available
    if test -f "$_ash_conda_root/etc/fish/conf.d/mamba.fish"
        source "$_ash_conda_root/etc/fish/conf.d/mamba.fish" 2>/dev/null
    else if test -x $mamba_bin
        eval $mamba_bin "shell.fish" "hook" 2>/dev/null | source
    end

    # Add conda bin to PATH if not already there
    if not contains "$_ash_conda_root/bin" $PATH
        fish_add_path --prepend --global "$_ash_conda_root/bin"
    end
end

# ── Run the right initializer ─────────────────────────────────────────────────
switch $_ash_conda_backend
    case micromamba
        __ash_conda_init_micromamba
    case mamba conda
        __ash_conda_init_standard
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 AUTO-DETECT: Project environment activation                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_conda_auto_env --on-variable PWD \
    --description "Auto-activate project conda environment on directory change"

    # Skip if in conda base and no project env exists
    set -l activated 0

    # Check for .conda-env file (project-specific env spec)
    if test -f ".conda-env"
        set -l env_name (cat .conda-env | string trim)
        if test -n "$env_name" && test "$CONDA_DEFAULT_ENV" != "$env_name"
            conda activate $env_name 2>/dev/null
            and set activated 1
            and __ash_conda_notify_activate $env_name
        end
        return
    end

    # Check for local environment directories
    for env_dir in $_ash_conda_project_env
        if test -d "$env_dir" && test -f "$env_dir/conda-meta/history"
            if test "$CONDA_DEFAULT_ENV" != (realpath $env_dir 2>/dev/null)
                conda activate (realpath $env_dir) 2>/dev/null
                and set activated 1
                and __ash_conda_notify_activate $env_dir
            end
            return
        end
    end

    # Check environment.yml
    if test -f "environment.yml" || test -f "environment.yaml"
        # Don't auto-activate, but hint to user
        if test -z "$CONDA_DEFAULT_ENV" || test "$CONDA_DEFAULT_ENV" = base
            set -l env_name (
                command -q yq && yq '.name' environment.yml 2>/dev/null ||
                grep '^name:' environment.yml 2>/dev/null | awk '{print $2}'
            )
            if test -n "$env_name"
                echo ""
                echo $_conda_yellow"  💡 Found environment.yml: "$_conda_cyan"$env_name"$_conda_reset
                echo $_conda_dim"     Run: conda-env-create   or   conda activate $env_name"$_conda_reset
                echo ""
            end
        end
    end
end

function __ash_conda_notify_activate --description "Notify when conda env auto-activates"
    set -l env $argv[1]
    # Minimal inline notification (no popup, just echo)
    echo $_conda_dim"  🐍 conda: "$_conda_cyan$env$_conda_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  ENHANCED CONDA FUNCTIONS                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── conda-envs: Rich environment listing ────────────────────────────────────
function conda-envs --description "List all conda environments with rich info"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)
    set -l red    (set_color red)

    echo ""
    echo $bold$cyan"  ╔═══════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🐍  Conda Environments                            ║"$reset
    echo $bold$cyan"  ╚═══════════════════════════════════════════════════════╝"$reset
    echo ""
    printf "  $bold%-22s  %-10s  %-8s  %s$reset\n" "Name" "Python" "Packages" "Path"
    printf "  $dim%s$reset\n" "────────────────────────────────────────────────────────────"

    set -l current $CONDA_DEFAULT_ENV

    conda env list --json 2>/dev/null |
    command -q python3 && python3 -c "
import json, sys, subprocess, os
data = json.load(sys.stdin)
envs = data.get('envs', [])
for path in envs:
    name = os.path.basename(path)
    if name == 'base' or path.endswith('base'):
        name = 'base'
    # Get Python version
    py_bin = os.path.join(path, 'bin', 'python')
    if os.path.exists(py_bin):
        try:
            v = subprocess.check_output([py_bin, '--version'], stderr=subprocess.STDOUT).decode().strip().split()[1]
        except:
            v = '?'
    else:
        v = 'N/A'
    # Count packages
    meta = os.path.join(path, 'conda-meta')
    pkgs = len([f for f in os.listdir(meta) if f.endswith('.json')]) if os.path.isdir(meta) else 0
    print(f'{name}\t{v}\t{pkgs}\t{path}')
" 2>/dev/null | while read -l line
        set -l parts (string split \t $line)
        set -l name    $parts[1]
        set -l pyver   $parts[2]
        set -l pkgs    $parts[3]
        set -l path    $parts[4]

        set -l active_marker ""
        if test "$name" = "$current" || test "$path" = "$CONDA_PREFIX"
            set active_marker $green" ←"$reset
        end

        set -l py_color $cyan
        test "$pyver" = "N/A" && set py_color $dim

        printf "  %-22s  $py_color%-10s$reset  $dim%-8s$reset  %s%s\n" \
            $name $pyver $pkgs $dim$path$reset $active_marker
    end

    echo ""
    echo "  "$dim"Backend: $_ash_conda_backend  |  Root: $_ash_conda_root"$reset
    echo ""
end

# ─── conda-new: Create environment with smart defaults ────────────────────────
function conda-new --description "Create a new conda environment with defaults"
    set -l name    $argv[1]
    set -l python  $argv[2]

    if test -z "$name"
        read -P "  Environment name: " name
    end
    if test -z "$name"
        echo $_conda_red"  ✗ Name required"$_conda_reset
        return 1
    end
    if test -z "$python"
        read -P "  Python version [3.12]: " python
        test -z "$python" && set python "3.12"
    end

    echo ""
    echo $_conda_cyan"  🐍 Creating environment: $name (Python $python)"$_conda_reset
    echo ""

    # Collect additional packages
    read -P "  Additional packages (space-separated, or Enter for none): " extras

    set -l create_cmd conda create -n $name python=$python -y

    if test -n "$extras"
        set -l pkg_list (string split ' ' $extras)
        set create_cmd $create_cmd $pkg_list
    end

    eval $create_cmd

    if test $status -eq 0
        echo ""
        echo $_conda_green"  ✓ Environment created: $name"$_conda_reset
        echo ""
        read -P "  Activate now? [Y/n] " activate_now
        if not string match -qi 'n*' $activate_now
            conda activate $name
        end
    else
        echo $_conda_red"  ✗ Failed to create environment"$_conda_reset
        return 1
    end
end

# ─── conda-clone: Clone an environment ───────────────────────────────────────
function conda-clone --description "Clone a conda environment"
    set -l source $argv[1]
    set -l dest   $argv[2]

    if test -z "$source"
        echo "  Usage: conda-clone <source-env> <new-name>"
        return 1
    end
    if test -z "$dest"
        read -P "  New environment name: " dest
    end

    echo ""
    echo $_conda_cyan"  🔄 Cloning $source → $dest"$_conda_reset
    conda create -n $dest --clone $source -y
    and echo $_conda_green"  ✓ Cloned successfully"$_conda_reset
    or  echo $_conda_red"  ✗ Clone failed"$_conda_reset
end

# ─── conda-delete: Remove environment with confirmation ───────────────────────
function conda-delete --description "Delete a conda environment (with confirmation)"
    set -l name $argv[1]

    if test -z "$name"
        echo "  Usage: conda-delete <env-name>"
        return 1
    end
    if test "$name" = base
        echo $_conda_red"  ✗ Cannot delete base environment"$_conda_reset
        return 1
    end

    echo ""
    echo $_conda_yellow"  ⚠ Delete environment: $name"$_conda_reset
    read -P "  Confirm? [y/N] " confirm

    if string match -qi 'y*' $confirm
        conda deactivate 2>/dev/null
        conda remove -n $name --all -y
        and echo $_conda_green"  ✓ Deleted: $name"$_conda_reset
        or  echo $_conda_red"  ✗ Failed to delete: $name"$_conda_reset
    else
        echo $_conda_dim"  Cancelled"$_conda_reset
    end
end

# ─── conda-export: Export environment to YAML ────────────────────────────────
function conda-export --description "Export current conda environment to YAML"
    set -l env_name (test -n "$argv[1]" && echo $argv[1] || echo $CONDA_DEFAULT_ENV)
    set -l output   $argv[2]

    if test -z "$env_name"
        echo $_conda_red"  ✗ No active environment"$_conda_reset
        return 1
    end

    # Default output filename
    if test -z "$output"
        set output "environment.yml"
    end

    echo ""
    echo $_conda_cyan"  📦 Exporting: $env_name → $output"$_conda_reset

    # Full export (includes build strings)
    conda env export -n $env_name > $output

    # Also create cross-platform version (no build strings)
    set -l nobuilds_output (string replace '.yml' '-nobuilds.yml' $output | string replace '.yaml' '-nobuilds.yaml' $output)
    conda env export -n $env_name --no-builds > $nobuilds_output 2>/dev/null

    # Also create history-based (minimal) export
    set -l history_output (string replace '.yml' '-minimal.yml' $output | string replace '.yaml' '-minimal.yaml' $output)
    conda env export -n $env_name --from-history > $history_output 2>/dev/null

    echo $_conda_green"  ✓ Full export:          $output"$_conda_reset
    echo $_conda_green"  ✓ No-builds export:     $nobuilds_output"$_conda_reset
    echo $_conda_green"  ✓ Minimal (history):    $history_output"$_conda_reset
    echo ""
end

# ─── conda-restore: Create env from YAML ─────────────────────────────────────
function conda-restore --description "Create conda environment from YAML file"
    set -l yaml $argv[1]
    test -z "$yaml" && set yaml "environment.yml"

    if not test -f $yaml
        # Search for any environment file
        for candidate in environment.yml environment.yaml conda.yml conda.yaml
            if test -f $candidate
                set yaml $candidate
                break
            end
        end
    end

    if not test -f $yaml
        echo $_conda_red"  ✗ No environment file found"$_conda_reset
        return 1
    end

    echo ""
    echo $_conda_cyan"  📦 Restoring from: $yaml"$_conda_reset
    echo ""

    conda env create -f $yaml
    and begin
        set -l env_name (grep '^name:' $yaml | awk '{print $2}')
        echo ""
        echo $_conda_green"  ✓ Environment restored"$_conda_reset
        test -n "$env_name" && echo "  Activate with: conda activate $env_name"
        echo ""
    end
    or echo $_conda_red"  ✗ Failed to restore environment"$_conda_reset
end

# ─── conda-update-all: Update everything in current env ──────────────────────
function conda-update-all --description "Update all packages in current conda environment"
    if test -z "$CONDA_DEFAULT_ENV"
        echo $_conda_red"  ✗ No active conda environment"$_conda_reset
        return 1
    end

    echo ""
    echo $_conda_cyan"  🔄 Updating all packages in: $CONDA_DEFAULT_ENV"$_conda_reset
    echo ""

    # Update conda first
    conda update -n base conda -y 2>/dev/null

    # Update all packages in current env
    conda update --all -y

    # Update pip packages too
    if command -q pip
        echo ""
        echo $_conda_cyan"  🔄 Updating pip packages..."$_conda_reset
        pip list --outdated --format=columns 2>/dev/null |
        tail -n +3 | awk '{print $1}' |
        xargs -r pip install --upgrade 2>/dev/null
    end

    echo ""
    echo $_conda_green"  ✓ All packages updated"$_conda_reset
    echo ""
end

# ─── conda-clean: Thorough cache cleanup ─────────────────────────────────────
function conda-clean --description "Clean conda cache, packages, and tarballs"
    echo ""
    echo $_conda_cyan"  🧹 Cleaning conda cache..."$_conda_reset

    # Show size before
    set -l before_size (du -sh "$_ash_conda_root/pkgs" 2>/dev/null | awk '{print $1}')

    conda clean --all -y

    set -l after_size (du -sh "$_ash_conda_root/pkgs" 2>/dev/null | awk '{print $1}')

    echo ""
    echo $_conda_green"  ✓ Cache cleaned"$_conda_reset
    test -n "$before_size" && echo "  "$_conda_dim"Before: $before_size  →  After: $after_size"$_conda_reset
    echo ""
end

# ─── conda-info-rich: Rich conda system info ─────────────────────────────────
function conda-info-rich --description "Show detailed conda system information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l green  (set_color green)
    set -l yellow (set_color yellow)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$cyan"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$cyan"  ║     🐍  Conda System Information                     ║"$reset
    echo $bold$cyan"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Backend:      "$reset $_ash_conda_backend
    echo "  "$bold"Root:         "$reset $dim$_ash_conda_root$reset

    set -l conda_ver (conda --version 2>/dev/null | awk '{print $2}')
    echo "  "$bold"Conda ver:    "$reset $cyan$conda_ver$reset

    if command -q mamba
        set -l mamba_ver (mamba --version 2>/dev/null | head -1 | awk '{print $2}')
        echo "  "$bold"Mamba ver:    "$reset $cyan$mamba_ver$reset
    end
    if command -q micromamba
        set -l mm_ver (micromamba --version 2>/dev/null)
        echo "  "$bold"μmamba ver:   "$reset $cyan$mm_ver$reset
    end

    echo ""
    echo "  "$bold"Active env:   "$reset (test -n "$CONDA_DEFAULT_ENV" && echo $green$CONDA_DEFAULT_ENV$reset || echo $dim"none"$reset)
    echo "  "$bold"Prefix:       "$reset $dim$CONDA_PREFIX$reset

    set -l env_count (conda env list 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    echo "  "$bold"Environments: "$reset $cyan$env_count$reset

    echo ""
    echo "  "$bold"Channels:"$reset
    conda config --show channels 2>/dev/null | grep '  -' | while read -l ch
        echo "    "$dim$ch$reset
    end

    echo ""
    echo "  "$bold"Solver:       "$reset $dim(conda config --show solver 2>/dev/null | awk '{print $2}')$reset
    echo ""

    # Disk usage
    set -l pkgs_size (du -sh "$_ash_conda_root/pkgs" 2>/dev/null | awk '{print $1}')
    set -l envs_size (du -sh "$_ash_conda_root/envs" 2>/dev/null | awk '{print $1}')
    echo "  "$bold"Disk Usage:"$reset
    test -n "$pkgs_size" && echo "    Packages:     "$cyan$pkgs_size$reset
    test -n "$envs_size" && echo "    Environments: "$cyan$envs_size$reset
    echo ""
end

# ─── conda-search-smart: Search with version info ────────────────────────────
function conda-search-smart --description "Search conda packages with version info"
    set -l query $argv[1]
    set -l channel $argv[2]

    if test -z "$query"
        echo "  Usage: conda-search-smart <package> [channel]"
        return 1
    end

    echo ""
    echo $_conda_cyan"  🔍 Searching: $query"$_conda_reset
    echo ""

    if test -n "$channel"
        conda search -c $channel $query 2>/dev/null | tail -20
    else
        conda search $query 2>/dev/null | tail -20
    end
end

# ─── conda-diff: Compare two environments ────────────────────────────────────
function conda-diff --description "Compare packages between two conda environments"
    set -l env1 $argv[1]
    set -l env2 $argv[2]

    if test -z "$env1" || test -z "$env2"
        echo "  Usage: conda-diff <env1> <env2>"
        return 1
    end

    set -l tmp1 (mktemp)
    set -l tmp2 (mktemp)

    conda list -n $env1 --export > $tmp1 2>/dev/null
    conda list -n $env2 --export > $tmp2 2>/dev/null

    echo ""
    echo $_conda_cyan"  📊 Differences: $env1 vs $env2"$_conda_reset
    echo ""

    if command -q diff && command -q colordiff
        colordiff $tmp1 $tmp2
    else if command -q diff
        diff --color=auto $tmp1 $tmp2
    else
        diff $tmp1 $tmp2
    end

    rm -f $tmp1 $tmp2
end

# ─── conda-pip-sync: Sync pip requirements into conda env ────────────────────
function conda-pip-sync --description "Install pip requirements.txt into active conda env"
    set -l req_file $argv[1]
    test -z "$req_file" && set req_file "requirements.txt"

    if test -z "$CONDA_DEFAULT_ENV"
        echo $_conda_red"  ✗ No active conda environment"$_conda_reset
        return 1
    end

    if not test -f $req_file
        echo $_conda_red"  ✗ Not found: $req_file"$_conda_reset
        return 1
    end

    echo ""
    echo $_conda_cyan"  📦 Installing $req_file into: $CONDA_DEFAULT_ENV"$_conda_reset
    pip install -r $req_file
    and echo $_conda_green"  ✓ Requirements installed"$_conda_reset
    or  echo $_conda_red"  ✗ Some packages failed"$_conda_reset
end

# ─── conda-jupyter: Launch Jupyter in current env ────────────────────────────
function conda-jupyter --description "Launch Jupyter Lab/Notebook in current conda env"
    set -l type $argv[1]
    test -z "$type" && set type lab

    if test -z "$CONDA_DEFAULT_ENV"
        echo $_conda_red"  ✗ No active conda environment"$_conda_reset
        return 1
    end

    echo $_conda_cyan"  🚀 Starting Jupyter $type in: $CONDA_DEFAULT_ENV"$_conda_reset

    switch $type
        case lab
            command -q jupyter-lab && jupyter lab || jupyter notebook
        case notebook
            jupyter notebook
        case '*'
            echo "  Usage: conda-jupyter [lab|notebook]"
            return 1
    end
end

# ─── conda-project-init: Initialize project with conda env ───────────────────
function conda-project-init --description "Initialize a new project with conda environment"
    set -l project_name $argv[1]
    test -z "$project_name" && set project_name (basename $PWD)

    set -l python_ver $argv[2]
    test -z "$python_ver" && set python_ver "3.12"

    echo ""
    echo $_conda_cyan"  🚀 Initializing conda project: $project_name (Python $python_ver)"$_conda_reset
    echo ""

    # Create environment
    conda create -n $project_name python=$python_ver -y || return 1

    # Activate
    conda activate $project_name || return 1

    # Install common dev tools
    read -P "  Install dev tools (pytest/black/ruff/mypy)? [Y/n] " install_dev
    if not string match -qi 'n*' $install_dev
        pip install pytest black ruff mypy ipython --quiet
    end

    # Create environment.yml
    conda env export --from-history > environment.yml
    echo "  ✓ environment.yml created"

    # Create .conda-env marker
    echo $project_name > .conda-env
    echo "  ✓ .conda-env marker created"

    # Create .gitignore entry
    if test -f .gitignore
        grep -q '__pycache__' .gitignore || echo -e "\n__pycache__/\n*.pyc\n.venv/\n.conda/" >> .gitignore
    end

    echo ""
    echo $_conda_green"  ✓ Project initialized: $project_name"$_conda_reset
    echo ""
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 ASH THEME INTEGRATION: Conda env in prompt color                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_conda_on_theme_change --on-event ash_theme_changed \
    --description "Refresh conda prompt colors on ASH theme change"
    # Starship handles this automatically via the conda module
    # Trigger a prompt redraw
    commandline -f repaint 2>/dev/null
end

function __ash_conda_env_prompt --description "Return colored conda env indicator for prompt"
    test -z "$CONDA_DEFAULT_ENV" && return
    test "$CONDA_DEFAULT_ENV" = base && return

    set -l color (set -q ASH_COLOR_GREEN; and echo $ASH_COLOR_GREEN; or echo green)
    printf '%s🐍 %s%s' (set_color $color 2>/dev/null; or echo "") $CONDA_DEFAULT_ENV (set_color normal)
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETIONS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_conda_env_list --description "List conda env names for completions"
    conda env list 2>/dev/null | grep -v '^#' | grep -v '^$' | awk '{print $1}'
end

# Complete conda-new, conda-delete, conda-clone etc. with env names
for fn in conda-delete conda-clone conda-export conda-diff
    complete -c $fn -f -a '(__ash_conda_env_list)' -d "Conda environment"
end

# complete for conda activate (wraps conda's own)
complete -c conda -n '__fish_seen_subcommand_from activate' \
    -f -a '(__ash_conda_env_list)' -d "Conda environment"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

abbr --add ca     'conda activate'
abbr --add cda    'conda deactivate'
abbr --add cel    'conda-envs'
abbr --add cnew   'conda-new'
abbr --add cclone 'conda-clone'
abbr --add cdel   'conda-delete'
abbr --add cex    'conda-export'
abbr --add cres   'conda-restore'
abbr --add cupd   'conda-update-all'
abbr --add cclean 'conda-clean'
abbr --add cinfo  'conda-info-rich'
abbr --add csrch  'conda-search-smart'
abbr --add cdiff  'conda-diff'
abbr --add cpip   'conda-pip-sync'
abbr --add cjup   'conda-jupyter'
abbr --add cinit  'conda-project-init'
abbr --add cbase  'conda activate base'
abbr --add clist  'conda list'
abbr --add cinst  'conda install'
abbr --add cremv  'conda remove'
abbr --add crun   'conda run'
abbr --add cconf  'conda config --show'
abbr --add cchan  'conda config --show channels'
abbr --add mmlist 'micromamba env list'
abbr --add mmact  'micromamba activate'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 AUTO-ACTIVATE BASE (if configured)                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

if test "$_ash_conda_auto_activate" = true
    if test -z "$CONDA_DEFAULT_ENV"
        conda activate base 2>/dev/null
    end
end