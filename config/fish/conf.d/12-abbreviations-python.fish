#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██████╗ ██╗   ██╗████████╗██╗  ██╗ ██████╗ ███╗   ██╗                        ║
# ║  ██╔══██╗╚██╗ ██╔╝╚══██╔══╝██║  ██║██╔═══██╗████╗  ██║                        ║
# ║  ██████╔╝ ╚████╔╝    ██║   ███████║██║   ██║██╔██╗ ██║                        ║
# ║  ██╔═══╝   ╚██╔╝     ██║   ██╔══██║██║   ██║██║╚██╗██║                        ║
# ║  ██║        ██║      ██║   ██║  ██║╚██████╔╝██║ ╚████║                        ║
# ║  ╚═╝        ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝                        ║
# ║                                                                                  ║
# ║   🐍 PYTHON ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                            ║
# ║   Python • pip • venv • uv • poetry • ruff • mypy • pytest • jupyter           ║
# ║                                                                                  ║
# ║   Philosophy:                                                                    ║
# ║     • Abbreviations expand on SPACE/ENTER — fully visible in history            ║
# ║     • Only load abbreviations for INSTALLED tools (conditional guards)          ║
# ║     • Group by workflow: environment → packages → testing → quality → dev       ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_python_initialized && exit 0
set -g __ash_abbr_python_initialized 1

# Skip if no Python available
command -sq python3 || command -sq python || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐍 PYTHON INTERPRETER — Core runtime
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a py       "python3"
abbr -a py2      "python2"
abbr -a py3      "python3"
abbr -a python   "python3"
abbr -a ipy      "python3 -c 'import IPython; IPython.start_ipython()' 2>/dev/null || python3"

# ── Quick execution ───────────────────────────────────────────────────────────
abbr -a pyrun    "python3"
abbr -a pyr      "python3"
abbr -a pyc      "python3 -c"                      # Run inline code
abbr -a pym      "python3 -m"                      # Run module
abbr -a pyi      "python3 -i"                      # Interactive after script
abbr -a pycheck  "python3 -m py_compile"           # Syntax check only
abbr -a pydis    "python3 -m dis"                  # Disassemble bytecode
abbr -a pytimeit "python3 -m timeit"               # Micro-benchmarking
abbr -a pyprof   "python3 -m cProfile -s cumulative"  # Profile script
abbr -a pydoc    "python3 -m pydoc"                # Built-in docs
abbr -a pyhttp   "python3 -m http.server 8000"     # Quick HTTP server
abbr -a pyjson   "python3 -m json.tool"            # Pretty-print JSON
abbr -a pysmtp   "python3 -m smtpd -n -c DebuggingServer localhost:1025"  # Debug SMTP

# ── Version info ──────────────────────────────────────────────────────────────
abbr -a pyver    "python3 --version"
abbr -a pyvers   "python3 -c 'import sys; print(sys.version)'"
abbr -a pypath   "python3 -c 'import sys; [print(p) for p in sys.path]'"
abbr -a pywhere  "python3 -c 'import sys; print(sys.executable)'"
abbr -a pysite   "python3 -c 'import site; print(site.getsitepackages())'"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏗️  VIRTUAL ENVIRONMENTS — venv, virtualenv, conda
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── venv (stdlib) ─────────────────────────────────────────────────────────────
abbr -a venv     "python3 -m venv .venv"
abbr -a venv3    "python3 -m venv .venv"
abbr -a mkvenv   "python3 -m venv .venv && source .venv/bin/activate.fish && echo '✅ venv activated'"
abbr -a mkenv    "python3 -m venv .venv && source .venv/bin/activate.fish"
abbr -a activate "source .venv/bin/activate.fish"
abbr -a act      "source .venv/bin/activate.fish"
abbr -a deact    "deactivate"
abbr -a rmvenv   "rm -rf .venv && echo '🗑️  .venv removed'"

# Named venv shortcuts
abbr -a mkvenv3  "python3 -m venv .venv3"
abbr -a mkvenvd  "python3 -m venv .venv --system-site-packages"  # With system packages

# Virtualenv (if installed)
if command -sq virtualenv
    abbr -a venv!  "virtualenv .venv"
    abbr -a venvp  "virtualenv .venv --python"     # Specify Python: venvp python3.11
end

# ── conda / mamba ─────────────────────────────────────────────────────────────
if command -sq conda
    abbr -a ca     "conda activate"
    abbr -a cda    "conda deactivate"
    abbr -a ccr    "conda create --name"
    abbr -a ccrp   "conda create --name $argv --python"
    abbr -a crm    "conda remove --name"
    abbr -a cls    "conda env list"
    abbr -a cinfo  "conda info"
    abbr -a cclean "conda clean --all --yes"
    abbr -a cupdate "conda update --all --yes"
    abbr -a cinstall "conda install"
    abbr -a csearch "conda search"
    abbr -a cexport "conda env export > environment.yml"
    abbr -a cimport "conda env create --file environment.yml"
    abbr -a cfreeze "conda list --explicit > requirements-conda.txt"
end

if command -sq mamba
    abbr -a ma     "mamba activate"
    abbr -a mi     "mamba install"
    abbr -a mcr    "mamba create --name"
    abbr -a mcrp   "mamba create --name $argv --python"
    abbr -a mls    "mamba env list"
    abbr -a mupdate "mamba update --all --yes"
end

# ── pyenv — Python version management ─────────────────────────────────────────
if command -sq pyenv
    abbr -a pyen   "pyenv"
    abbr -a pyenl  "pyenv versions"
    abbr -a pyenla "pyenv install --list"
    abbr -a pyeni  "pyenv install"
    abbr -a pyenr  "pyenv uninstall"
    abbr -a pyeng  "pyenv global"
    abbr -a pyenlo "pyenv local"
    abbr -a pyens  "pyenv shell"
    abbr -a pyenv-update "pyenv update"
    abbr -a pyenv-latest "pyenv install (pyenv install --list | grep -E '^\s+3\.' | tail -1 | string trim)"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 PACKAGE MANAGEMENT — pip, pip3, pipx
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── pip ───────────────────────────────────────────────────────────────────────
abbr -a pip      "pip3"
abbr -a pipi     "pip3 install"
abbr -a pipie    "pip3 install --editable ."        # Editable install
abbr -a pipidev  "pip3 install --editable '.[dev]'" # With dev extras
abbr -a pipiu    "pip3 install --upgrade"
abbr -a pipur    "pip3 install --requirement requirements.txt"
abbr -a pipurd   "pip3 install --requirement requirements-dev.txt"
abbr -a pipura   "pip3 install --requirement requirements.txt --requirement requirements-dev.txt"
abbr -a pipu!    "pip3 install --upgrade pip setuptools wheel"
abbr -a pipr     "pip3 uninstall --yes"
abbr -a pipra    "pip3 uninstall --yes -r requirements.txt"
abbr -a pipl     "pip3 list"
abbr -a piplou   "pip3 list --outdated"
abbr -a pipls    "pip3 list --format=columns"
abbr -a pipup    "pip3 list --outdated --format=json | python3 -c \
                  'import json,sys; [print(p[\"name\"]) for p in json.load(sys.stdin)]' \
                  | xargs pip3 install --upgrade"   # Upgrade all outdated
abbr -a pipf     "pip3 show"
abbr -a pipcheck "pip3 check"                       # Verify dependencies
abbr -a pipver   "pip3 --version"
abbr -a pipconf  "pip3 config list"

# Freeze / requirements
abbr -a freeze   "pip3 freeze"
abbr -a freezer  "pip3 freeze > requirements.txt && echo '✅ requirements.txt updated'"
abbr -a freezerd "pip3 freeze > requirements-dev.txt"
abbr -a pipreqs  "pipreqs . --force 2>/dev/null || pip3 freeze > requirements.txt"
abbr -a pipgrep  "pip3 list | grep --ignore-case"

# ── pipx — isolated CLI tool installation ─────────────────────────────────────
if command -sq pipx
    abbr -a px     "pipx"
    abbr -a pxi    "pipx install"
    abbr -a pxr    "pipx uninstall"
    abbr -a pxl    "pipx list"
    abbr -a pxu    "pipx upgrade"
    abbr -a pxua   "pipx upgrade-all"
    abbr -a pxrun  "pipx run"
    abbr -a pxinj  "pipx inject"
    abbr -a pxreinst "pipx reinstall-all"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ UV — Ultra-fast Python package & project manager (Rust-powered)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq uv
    # ── Project management ────────────────────────────────────────────────────
    abbr -a uvinit  "uv init"
    abbr -a uvnew   "uv init"
    abbr -a uvsync  "uv sync"
    abbr -a uvsyncd "uv sync --dev"
    abbr -a uvlock  "uv lock"
    abbr -a uvlockup "uv lock --upgrade"
    abbr -a uvlockupd "uv lock --upgrade-package"

    # ── Packages ──────────────────────────────────────────────────────────────
    abbr -a uva     "uv add"
    abbr -a uvad    "uv add --dev"
    abbr -a uvao    "uv add --optional"
    abbr -a uvr     "uv remove"
    abbr -a uvrd    "uv remove --dev"
    abbr -a uvup    "uv add --upgrade"
    abbr -a uvupd   "uv add --upgrade-package"

    # ── Run ───────────────────────────────────────────────────────────────────
    abbr -a uvrun   "uv run"
    abbr -a uvpy    "uv run python"
    abbr -a uvpyc   "uv run python -c"
    abbr -a uvexec  "uv run"
    abbr -a uvtool  "uvx"                          # Run ephemeral tool

    # ── Venv ──────────────────────────────────────────────────────────────────
    abbr -a uvvenv  "uv venv"
    abbr -a uvvenvp "uv venv --python"             # uvvenvp 3.12

    # ── Python version management ─────────────────────────────────────────────
    abbr -a uvpyi   "uv python install"
    abbr -a uvpyl   "uv python list"
    abbr -a uvpyls  "uv python list --all-versions"
    abbr -a uvpyr   "uv python uninstall"
    abbr -a uvpypin "uv python pin"

    # ── pip compatibility mode ────────────────────────────────────────────────
    abbr -a uvpi    "uv pip install"
    abbr -a uvpie   "uv pip install --editable ."
    abbr -a uvpur   "uv pip install --requirement requirements.txt"
    abbr -a uvpupg  "uv pip install --upgrade"
    abbr -a uvprm   "uv pip uninstall"
    abbr -a uvpls   "uv pip list"
    abbr -a uvpf    "uv pip show"
    abbr -a uvpchk  "uv pip check"
    abbr -a uvpfreeze "uv pip freeze"
    abbr -a uvpcomp "uv pip compile requirements.in"

    # ── Cache ─────────────────────────────────────────────────────────────────
    abbr -a uvcclean "uv cache clean"
    abbr -a uvcsz    "uv cache dir"
    abbr -a uvcls    "uv cache list"

    # ── Info ──────────────────────────────────────────────────────────────────
    abbr -a uvver   "uv --version"
    abbr -a uvself  "uv self update"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📖 POETRY — Python dependency & packaging
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq poetry
    # ── Project ───────────────────────────────────────────────────────────────
    abbr -a po     "poetry"
    abbr -a ponew  "poetry new"
    abbr -a poinit "poetry init"
    abbr -a posync "poetry install"
    abbr -a posyncd "poetry install --with dev"
    abbr -a polock "poetry lock"
    abbr -a polocknu "poetry lock --no-update"
    abbr -a poupdate "poetry update"

    # ── Dependencies ──────────────────────────────────────────────────────────
    abbr -a poadd  "poetry add"
    abbr -a poaddd "poetry add --group dev"
    abbr -a poaddr "poetry add --group runtime"
    abbr -a poaddp "poetry add --optional"
    abbr -a porm   "poetry remove"
    abbr -a pormd  "poetry remove --group dev"

    # ── Run & Shell ───────────────────────────────────────────────────────────
    abbr -a porun  "poetry run"
    abbr -a popy   "poetry run python"
    abbr -a posh   "poetry shell"
    abbr -a poexec "poetry run"

    # ── Info ──────────────────────────────────────────────────────────────────
    abbr -a pols   "poetry show"
    abbr -a polst  "poetry show --tree"
    abbr -a polso  "poetry show --outdated"
    abbr -a pover  "poetry --version"
    abbr -a poenv  "poetry env info"
    abbr -a poenvl "poetry env list"
    abbr -a poenvrm "poetry env remove"
    abbr -a poconf "poetry config --list"

    # ── Build & Publish ───────────────────────────────────────────────────────
    abbr -a pobuild "poetry build"
    abbr -a popub  "poetry publish"
    abbr -a popubb "poetry publish --build"
    abbr -a popypi "poetry publish --repository pypi"
    abbr -a potest "poetry publish --repository testpypi"

    # ── Check ─────────────────────────────────────────────────────────────────
    abbr -a pochk  "poetry check"
    abbr -a poexp  "poetry export --format=requirements.txt --output=requirements.txt"
    abbr -a poexpd "poetry export --format=requirements.txt --with=dev --output=requirements-dev.txt"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧪 TESTING — pytest, hypothesis, coverage
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq pytest
    abbr -a pt     "pytest"
    abbr -a ptv    "pytest --verbose"
    abbr -a ptvv   "pytest --verbose --verbose"
    abbr -a pts    "pytest --no-header --quiet"
    abbr -a ptf    "pytest --failed-first"
    abbr -a ptlf   "pytest --last-failed"
    abbr -a ptlfo  "pytest --last-failed --no-header"
    abbr -a ptx    "pytest --exitfirst"            # Stop on first failure
    abbr -a ptxv   "pytest --exitfirst --verbose"
    abbr -a ptk    "pytest --keyword"             # Filter by keyword
    abbr -a ptm    "pytest --mark"                # Filter by mark
    abbr -a ptd    "pytest --doctest-modules"     # Test docstrings
    abbr -a ptpdb  "pytest --pdb"                 # Drop to pdb on failure
    abbr -a ptdbg  "pytest --pdb --pdbcls=IPython.terminal.debugger:Pdb"
    abbr -a ptp    "pytest --numprocesses=auto"   # Parallel (pytest-xdist)
    abbr -a ptpa   "pytest --numprocesses=auto --dist=loadfile"
    abbr -a ptrnd  "pytest --randomly-seed=random"  # Random order
    abbr -a ptcov  "pytest --cov=. --cov-report=term-missing --cov-report=html"
    abbr -a ptcovx "pytest --cov=. --cov-report=xml"
    abbr -a ptwarn "pytest --warnings=error"      # Treat warnings as errors
    abbr -a ptstrict "pytest --strict-markers --strict-config"
    abbr -a ptci   "pytest --tb=short -q"         # CI-friendly output
    abbr -a ptwatch "ptw --runner 'pytest --tb=short'"  # pytest-watch
    abbr -a ptprofile "pytest --profile"          # pytest-profiling
    abbr -a ptrep  "pytest --html=test-report.html --self-contained-html"
    abbr -a ptdep  "pytest --show-capture=no -p no:warnings"  # Fast quiet

    # Specific test patterns
    abbr -a ptunit "pytest tests/unit"
    abbr -a ptint  "pytest tests/integration"
    abbr -a pte2e  "pytest tests/e2e"
end

# ── Coverage ──────────────────────────────────────────────────────────────────
if command -sq coverage
    abbr -a cov    "coverage run --source=. -m pytest"
    abbr -a covr   "coverage report --show-missing"
    abbr -a covh   "coverage html && xdg-open htmlcov/index.html"
    abbr -a covx   "coverage xml"
    abbr -a cove   "coverage erase"
    abbr -a covc   "coverage combine"
end

# ── tox ───────────────────────────────────────────────────────────────────────
if command -sq tox
    abbr -a tx     "tox"
    abbr -a txl    "tox --listenvs"
    abbr -a txr    "tox --recreate"
    abbr -a txp    "tox --parallel"
    abbr -a txe    "tox --envlist"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 CODE QUALITY — ruff, black, isort, flake8, mypy, pylint
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── ruff — ultra-fast linter & formatter (Rust) ───────────────────────────────
if command -sq ruff
    abbr -a rf     "ruff"
    abbr -a rfl    "ruff check ."
    abbr -a rfla   "ruff check . --select ALL"
    abbr -a rffix  "ruff check . --fix"
    abbr -a rffixa "ruff check . --fix --unsafe-fixes"
    abbr -a rffmt  "ruff format ."
    abbr -a rffmtc "ruff format . --check"         # Check only, don't write
    abbr -a rffmtd "ruff format . --diff"          # Show diff
    abbr -a rfci   "ruff check . --output-format=github"  # GitHub Actions
    abbr -a rfsel  "ruff check . --select"         # Specific rules
    abbr -a rfign  "ruff check . --ignore"         # Ignore rules
    abbr -a rfstat "ruff check . --statistics"     # Rule frequency stats
    abbr -a rfexpl "ruff rule"                     # Explain a rule: rfexpl E501
    abbr -a rfconf "ruff check . --show-settings"
    abbr -a rfwatch "ruff check . --watch"         # Watch mode
    abbr -a rfclean "ruff clean"                   # Clear cache
end

# ── black — opinionated formatter ─────────────────────────────────────────────
if command -sq black
    abbr -a bl     "black ."
    abbr -a blc    "black . --check"               # Check only
    abbr -a bld    "black . --diff"                # Show diff
    abbr -a blq    "black . --quiet"               # Quiet mode
    abbr -a blf    "black"                         # Format specific file
    abbr -a blll   "black . --line-length 100"     # Custom line length
end

# ── isort — import sorter ─────────────────────────────────────────────────────
if command -sq isort
    abbr -a iso    "isort ."
    abbr -a isoc   "isort . --check-only"
    abbr -a isod   "isort . --diff"
    abbr -a isobl  "isort . --profile black"       # Black-compatible
end

# ── mypy — static type checker ────────────────────────────────────────────────
if command -sq mypy
    abbr -a mypy   "mypy ."
    abbr -a mypys  "mypy . --strict"
    abbr -a mypyp  "mypy . --pretty"
    abbr -a mypyc  "mypy . --ignore-missing-imports"
    abbr -a mypyq  "mypy . --quiet"
    abbr -a mypyjunit "mypy . --junit-xml=mypy-report.xml"
    abbr -a mypycache "mypy . --no-incremental"    # Ignore cache
end

# ── pyright / pylance ─────────────────────────────────────────────────────────
if command -sq pyright
    abbr -a pyr    "pyright"
    abbr -a pyrs   "pyright --strict"
    abbr -a pyrw   "pyright --watch"
    abbr -a pyrv   "pyright --version"
end

# ── pylint ────────────────────────────────────────────────────────────────────
if command -sq pylint
    abbr -a pyl    "pylint"
    abbr -a pyld   "pylint . --disable=C,R"        # Errors + warnings only
    abbr -a pylf   "pylint --output-format=colorized"
    abbr -a pylr   "pylint --reports=yes"
end

# ── flake8 ────────────────────────────────────────────────────────────────────
if command -sq flake8
    abbr -a fl8    "flake8 ."
    abbr -a fl8s   "flake8 . --statistics"
    abbr -a fl8c   "flake8 . --count"
end

# ── bandit — security linter ──────────────────────────────────────────────────
if command -sq bandit
    abbr -a ban    "bandit --recursive ."
    abbr -a banl   "bandit --recursive . --level low"
    abbr -a banh   "bandit --recursive . --level high"
    abbr -a banf   "bandit --recursive . --format json | jq"
end

# ── safety — dependency vulnerability scanner ─────────────────────────────────
if command -sq safety
    abbr -a safe   "safety check"
    abbr -a safef  "safety check --full-report"
    abbr -a safej  "safety check --json | jq"
end

# ── vulture — dead code finder ────────────────────────────────────────────────
if command -sq vulture
    abbr -a vult   "vulture ."
    abbr -a vultm  "vulture . --min-confidence 80"
end

# ── pre-commit ────────────────────────────────────────────────────────────────
if command -sq pre-commit
    abbr -a pco    "pre-commit"
    abbr -a pcoi   "pre-commit install"
    abbr -a pcoru  "pre-commit run"
    abbr -a pcora  "pre-commit run --all-files"
    abbr -a pcou   "pre-commit autoupdate"
    abbr -a pcoc   "pre-commit clean"
    abbr -a pcov   "pre-commit validate-config"
    abbr -a pcohs  "pre-commit run --hook-stage"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 BUILD & PACKAGING — setuptools, build, twine
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a pybuild  "python3 -m build"
abbr -a pybuildw "python3 -m build --wheel"
abbr -a pybuilds "python3 -m build --sdist"

if command -sq twine
    abbr -a twine  "twine"
    abbr -a twinec "twine check dist/*"
    abbr -a twineu "twine upload dist/*"
    abbr -a twinet "twine upload --repository testpypi dist/*"
    abbr -a twinev "twine upload --verbose dist/*"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📓 JUPYTER — Notebook & lab
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq jupyter
    abbr -a jup    "jupyter"
    abbr -a jupnb  "jupyter notebook"
    abbr -a juplab "jupyter lab"
    abbr -a jupcon "jupyter console"
    abbr -a jupkern "jupyter kernelspec list"
    abbr -a jupconv "jupyter nbconvert"
    abbr -a jupconvhtml "jupyter nbconvert --to html"
    abbr -a jupconvpdf "jupyter nbconvert --to pdf"
    abbr -a jupconvpy "jupyter nbconvert --to script"
    abbr -a jupexec "jupyter nbconvert --to notebook --execute"
    abbr -a jupclear "jupyter nbconvert --ClearOutputPreprocessor.enabled=True --to notebook --inplace"
    abbr -a juplist "jupyter server list"
    abbr -a jupstop "jupyter server stop"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌐 WEB FRAMEWORKS — FastAPI, Django, Flask
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── FastAPI / uvicorn ─────────────────────────────────────────────────────────
abbr -a uvicorn  "uvicorn"
abbr -a uvidev   "uvicorn main:app --reload --host 0.0.0.0 --port 8000"
abbr -a uviprod  "uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4"
abbr -a gunicorn "gunicorn"
abbr -a gunidev  "gunicorn main:app -k uvicorn.workers.UvicornWorker --reload"
abbr -a guniprod "gunicorn main:app -k uvicorn.workers.UvicornWorker --workers 4"

# ── Django ────────────────────────────────────────────────────────────────────
abbr -a dj       "python3 manage.py"
abbr -a djrun    "python3 manage.py runserver"
abbr -a djrun0   "python3 manage.py runserver 0.0.0.0:8000"
abbr -a djmig    "python3 manage.py migrate"
abbr -a djmigmk  "python3 manage.py makemigrations"
abbr -a djmigsh  "python3 manage.py showmigrations"
abbr -a djmigfk  "python3 manage.py migrate --fake"
abbr -a djsh     "python3 manage.py shell"
abbr -a djshp    "python3 manage.py shell_plus"   # django-extensions
abbr -a djsu     "python3 manage.py createsuperuser"
abbr -a djcol    "python3 manage.py collectstatic --noinput"
abbr -a djtest   "python3 manage.py test"
abbr -a djcheck  "python3 manage.py check --deploy"
abbr -a djdbsh   "python3 manage.py dbshell"
abbr -a djfix    "python3 manage.py loaddata"
abbr -a djdump   "python3 manage.py dumpdata"
abbr -a djstatic "python3 manage.py findstatic"
abbr -a djurls   "python3 manage.py show_urls 2>/dev/null || python3 manage.py url_patterns"
abbr -a djsec    "python3 manage.py check --list-tags"
abbr -a djapp    "python3 manage.py startapp"
abbr -a djproj   "django-admin startproject"

# ── Flask ─────────────────────────────────────────────────────────────────────
abbr -a flrun    "flask run --debug"
abbr -a flrun0   "flask run --debug --host 0.0.0.0"
abbr -a flsh     "flask shell"
abbr -a fldb     "flask db"
abbr -a fldbmig  "flask db migrate"
abbr -a fldbup   "flask db upgrade"
abbr -a fldbdown "flask db downgrade"
abbr -a fldbinit "flask db init"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 DATA SCIENCE — pandas, numpy quick launchers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a pyds     "python3 -c 'import pandas as pd; import numpy as np; print(\"pandas\", pd.__version__, \"| numpy\", np.__version__)'"
abbr -a pypd     "python3 -c 'import pandas as pd'"
abbr -a pynp     "python3 -c 'import numpy as np'"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 CLEANUP — Cache & compiled files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a pyclean  "find . -type f -name '*.pyc' -delete && \
                  find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null; \
                  find . -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null; \
                  find . -type d -name '.pytest_cache' -exec rm -rf {} + 2>/dev/null; \
                  find . -type d -name '.mypy_cache' -exec rm -rf {} + 2>/dev/null; \
                  find . -type d -name '.ruff_cache' -exec rm -rf {} + 2>/dev/null; \
                  echo '✅ Python caches cleaned'"

abbr -a pyinfo   "python3 -c '
import sys, platform, sysconfig
print(f\"Python: {sys.version}\")
print(f\"Platform: {platform.platform()}\")
print(f\"Prefix: {sys.prefix}\")
print(f\"Venv: {sys.prefix != sys.base_prefix}\")
'"