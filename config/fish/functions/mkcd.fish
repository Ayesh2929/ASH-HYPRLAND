# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — mkcd Ultra                                         ║
# ║  Smart mkdir + cd: templates, projects, git init, env & full scaffolding   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function mkcd --description "Smart mkdir + cd with project scaffolding"

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🎨 COLORS                                                              ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l R      (set_color normal)
    set -l BOLD   (set_color --bold)
    set -l DIM    (set_color brblack)
    set -l GREEN  (set_color green)
    set -l YELLOW (set_color yellow)
    set -l RED    (set_color red)
    set -l CYAN   (set_color cyan)
    set -l BLUE   (set_color blue)
    set -l PURPLE (set_color magenta)
    set -l ORANGE (set_color FF9F43)

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  🔍 ARGUMENT PARSING                                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _dir      ""
    set -l _template ""   # python | node | rust | go | java | web | api | lib
    set -l _git      0
    set -l _env      0
    set -l _venv     0
    set -l _readme   0
    set -l _verbose  0
    set -l _dry_run  0
    set -l _parents  1   # -p by default
    set -l _mode     ""  # permissions
    set -l _open     0   # open in editor after

    # ── Help ──────────────────────────────────────────────────────────────────
    function __mkcd_help --description "Print mkcd help"
        echo ""
        echo $BOLD$PURPLE"  ╔══════════════════════════════════════════════════════╗"$R
        echo $BOLD$PURPLE"  ║     📁  mkcd — Smart mkdir + cd                      ║"$R
        echo $BOLD$PURPLE"  ╚══════════════════════════════════════════════════════╝"$R
        echo ""
        echo "  $BOLD Usage:$R  mkcd <directory> [options]"
        echo ""
        echo "  $BOLD Templates:$R  (--template=<name>)"
        printf "    $CYAN%-14s$R  %s\n" "python"   "Python project (pyproject.toml, venv, .gitignore)"
        printf "    $CYAN%-14s$R  %s\n" "node"     "Node.js project (package.json, .nvmrc)"
        printf "    $CYAN%-14s$R  %s\n" "rust"     "Rust project (Cargo.toml via cargo new)"
        printf "    $CYAN%-14s$R  %s\n" "go"       "Go module project (go.mod, main.go)"
        printf "    $CYAN%-14s$R  %s\n" "web"      "Static web (index.html, CSS, JS structure)"
        printf "    $CYAN%-14s$R  %s\n" "api"      "REST API (src/, tests/, Dockerfile)"
        printf "    $CYAN%-14s$R  %s\n" "lib"      "Generic library structure"
        printf "    $CYAN%-14s$R  %s\n" "data"     "Data science (notebooks/, data/, src/)"
        printf "    $CYAN%-14s$R  %s\n" "ml"       "Machine learning project"
        printf "    $CYAN%-14s$R  %s\n" "dotfiles" "Dotfiles structure"
        echo ""
        echo "  $BOLD Options:$R"
        printf "    $YELLOW%-18s$R  %s\n" "--git, -g"          "Initialize git repository"
        printf "    $YELLOW%-18s$R  %s\n" "--env, -e"          "Create .env + .env.example"
        printf "    $YELLOW%-18s$R  %s\n" "--venv"             "Create Python virtual environment"
        printf "    $YELLOW%-18s$R  %s\n" "--readme, -r"       "Generate README.md"
        printf "    $YELLOW%-18s$R  %s\n" "--open, -o"         "Open in editor (nvim) after"
        printf "    $YELLOW%-18s$R  %s\n" "--template=<name>"  "Apply project template"
        printf "    $YELLOW%-18s$R  %s\n" "--mode=<perm>"      "Set directory permissions"
        printf "    $YELLOW%-18s$R  %s\n" "--dry-run, -n"      "Preview without creating"
        printf "    $YELLOW%-18s$R  %s\n" "--verbose, -v"      "Show all created files"
        printf "    $YELLOW%-18s$R  %s\n" "--help, -h"         "Show this help"
        echo ""
        echo "  $BOLD Examples:$R"
        printf "    $DIM%s$R\n" "mkcd my-project                              # Simple mkdir + cd"
        printf "    $DIM%s$R\n" "mkcd my-api --template=api --git --env       # API project"
        printf "    $DIM%s$R\n" "mkcd scraper --template=python --venv --git  # Python + venv"
        printf "    $DIM%s$R\n" "mkcd site --template=web --readme            # Static website"
        printf "    $DIM%s$R\n" "mkcd ~/projects/foo --git --open             # New git project"
        printf "    $DIM%s$R\n" "mkcd a/b/c/d                                 # Deep path (auto -p)"
        echo ""
    end

    # ── Parse arguments ────────────────────────────────────────────────────────
    for arg in $argv
        switch $arg
            case --help -h help;         __mkcd_help; return 0
            case --git -g;               set _git     1
            case --env -e;               set _env     1
            case --venv;                 set _venv    1
            case --readme -r;            set _readme  1
            case --verbose -v;           set _verbose 1
            case --dry-run -n;           set _dry_run 1
            case --open -o;              set _open    1
            case --no-parents;           set _parents 0
            case --template=*
                set _template (string replace '--template=' '' $arg)
            case --mode=*
                set _mode (string replace '--mode=' '' $arg)
            case -t=*
                set _template (string replace '-t=' '' $arg)
            case '*'
                test -z "$_dir" && set _dir $arg
        end
    end

    # ── Auto-detect template from directory name ────────────────────────────
    if test -z "$_template" && test -n "$_dir"
        set -l base (basename $_dir | string lower)
        switch $base
            case '*-api*' '*api-*' '*api'
                test -z "$_template" && set _template api
            case '*-web*' '*-site*' '*website*'
                test -z "$_template" && set _template web
            case '*-py*' '*-python*' '*-script*'
                test -z "$_template" && set _template python
            case '*-rs*' '*-rust*'
                test -z "$_template" && set _template rust
            case '*-go*' '*-golang*'
                test -z "$_template" && set _template go
            case '*-ml*' '*-model*' '*-ai*'
                test -z "$_template" && set _template ml
        end
    end

    # ── Validate ──────────────────────────────────────────────────────────────
    if test -z "$_dir"
        # Interactive: prompt for directory name
        if command -q fzf
            echo ""
            read -P "  $CYAN📁 Directory name:$R " _dir
            test -z "$_dir" && begin
                echo "  $RED✗$R  Directory name required"
                return 1
            end
        else
            echo "  $RED✗$R  Usage: mkcd <directory>"
            return 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📋 OUTPUT HELPERS                                                      ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    function __mk_ok --description "Print success file creation"
        test $_verbose -eq 1 && \
            printf "    $GREEN✓$R  %s\n" $argv[1]
    end

    function __mk_info --description "Print info"
        printf "  $CYAN›$R  %s\n" $argv[1]
    end

    function __mk_dry --description "Print dry-run action"
        printf "  $YELLOW[DRY]$R  %s\n" $argv[1]
    end

    function __mk_write --description "Write file with content (respects dry-run)"
        set -l file $argv[1]
        set -l content $argv[2..-1]

        if test $_dry_run -eq 1
            __mk_dry "create file: $file"
            return
        end

        mkdir -p (dirname $file) 2>/dev/null
        printf '%s\n' $content > $file 2>/dev/null
        __mk_ok $file
    end

    function __mk_dir --description "Create directory (respects dry-run)"
        if test $_dry_run -eq 1
            __mk_dry "mkdir: $argv[1]"
            return
        end
        mkdir -p $argv[1] 2>/dev/null
        __mk_ok (string replace $PWD '.' $argv[1])"/"
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📁 CORE: Create and enter directory                                    ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _abs_dir (realpath --no-symlinks "$_dir" 2>/dev/null; or echo "$_dir")

    # ── Expand ~ ──────────────────────────────────────────────────────────────
    set _dir (string replace '~' $HOME $_dir)

    # ── Check existence ────────────────────────────────────────────────────────
    if test -e $_dir && test -z "$_template" && test $_git -eq 0
        # Already exists and no extra setup — just cd
        if test -d $_dir
            printf "\n  $YELLOW⚠$R  Directory exists — entering: $CYAN$_dir$R\n\n"
            cd $_dir
            return 0
        else
            printf "  $RED✗$R  Path exists but is not a directory: $_dir\n"
            return 1
        end
    end

    # ── Banner ────────────────────────────────────────────────────────────────
    printf "\n"
    printf "  $BOLD$CYAN📁 mkcd: $_dir$R"
    test -n "$_template" && printf "  $DIM[template: $_template]$R"
    printf "\n\n"

    # ── Create base directory ─────────────────────────────────────────────────
    if test $_dry_run -eq 1
        __mk_dry "mkdir -p $_dir"
    else
        if test $_parents -eq 1
            mkdir -p "$_dir" 2>/dev/null
        else
            mkdir "$_dir" 2>/dev/null
        end

        if test $status -ne 0
            printf "  $RED✗$R  Failed to create directory: $_dir\n"
            return 1
        end

        # Set permissions if specified
        if test -n "$_mode"
            chmod $_mode "$_dir" 2>/dev/null
            __mk_info "Permissions set: $_mode"
        end
    end

    printf "  $GREEN✓$R  $BOLD%s$R\n" (string replace $HOME '~' $_dir)

    # ── Enter directory ────────────────────────────────────────────────────────
    if test $_dry_run -eq 0
        cd "$_dir" 2>/dev/null
        if test $status -ne 0
            printf "  $RED✗$R  Could not enter directory\n"
            return 1
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📂 TEMPLATES                                                           ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    set -l _proj_name (basename $_dir)

    switch $_template

        # ── Python ────────────────────────────────────────────────────────────
        case python py
            __mk_info "Python project template"

            # Directory structure
            for d in src/$_proj_name tests docs
                __mk_dir $d
            end

            # pyproject.toml
            __mk_write "pyproject.toml" \
"[build-system]
requires = [\"setuptools>=68\", \"wheel\"]
build-backend = \"setuptools.backends.legacy:build\"

[project]
name = \"$_proj_name\"
version = \"0.1.0\"
description = \"\"
requires-python = \">=3.11\"
dependencies = []

[project.optional-dependencies]
dev = [\"pytest\", \"black\", \"ruff\", \"mypy\"]

[tool.ruff]
line-length = 100
target-version = \"py311\"

[tool.black]
line-length = 100

[tool.mypy]
python_version = \"3.11\"
strict = true

[tool.pytest.ini_options]
testpaths = [\"tests\"]"

            # Main module
            __mk_write "src/$_proj_name/__init__.py" \
"\"\"\"$_proj_name — Python package.\"\"\"

__version__ = \"0.1.0\""

            # Tests
            __mk_write "tests/__init__.py" ""
            __mk_write "tests/test_main.py" \
"\"\"\"Tests for $_proj_name.\"\"\"
import pytest


def test_example() -> None:
    assert 1 + 1 == 2"

            # .gitignore
            __mk_write ".gitignore" \
"__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/
.env
.ruff_cache/
.mypy_cache/
.pytest_cache/
dist/
build/
*.so
.DS_Store"

            # Makefile
            __mk_write "Makefile" \
"PYTHON := python3
PKG := $_proj_name

.PHONY: install dev test lint fmt type-check clean

install:
	\$(PYTHON) -m pip install .

dev:
	\$(PYTHON) -m pip install -e '.[dev]'

test:
	\$(PYTHON) -m pytest -v --tb=short

lint:
	\$(PYTHON) -m ruff check .

fmt:
	\$(PYTHON) -m black .
	\$(PYTHON) -m ruff check --fix .

type-check:
	\$(PYTHON) -m mypy src/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .ruff_cache .mypy_cache dist/ build/"

            set _readme 1
            set _env    1
            test $_venv -eq 0 && set _venv 1

        # ── Node.js ───────────────────────────────────────────────────────────
        case node nodejs js ts typescript
            __mk_info "Node.js project template"

            for d in src tests public
                __mk_dir $d
            end

            # .nvmrc
            __mk_write ".nvmrc" (node --version 2>/dev/null | string replace 'v' '' || echo "20")

            # package.json
            __mk_write "package.json" \
"{
  \"name\": \"$_proj_name\",
  \"version\": \"0.1.0\",
  \"description\": \"\",
  \"type\": \"module\",
  \"main\": \"dist/index.js\",
  \"scripts\": {
    \"dev\": \"tsx watch src/index.ts\",
    \"build\": \"tsc\",
    \"start\": \"node dist/index.js\",
    \"test\": \"vitest\",
    \"lint\": \"eslint src/\",
    \"fmt\": \"prettier --write .\"
  },
  \"devDependencies\": {
    \"typescript\": \"^5.0.0\",
    \"tsx\": \"^4.0.0\",
    \"vitest\": \"^1.0.0\"
  },
  \"packageManager\": \"pnpm@9.0.0\"
}"

            # tsconfig.json
            __mk_write "tsconfig.json" \
"{
  \"compilerOptions\": {
    \"target\": \"ES2022\",
    \"module\": \"ESNext\",
    \"moduleResolution\": \"bundler\",
    \"strict\": true,
    \"outDir\": \"dist\",
    \"rootDir\": \"src\",
    \"declaration\": true,
    \"skipLibCheck\": true
  },
  \"include\": [\"src/**/*\"],
  \"exclude\": [\"node_modules\", \"dist\"]
}"

            # Main file
            __mk_write "src/index.ts" \
"export function main(): void {
  console.log('Hello from $_proj_name!')
}

main()"

            # .gitignore
            __mk_write ".gitignore" \
"node_modules/
dist/
.env
.env.local
*.log
.DS_Store
coverage/"

            set _readme 1
            set _env    1

        # ── Rust ──────────────────────────────────────────────────────────────
        case rust rs
            __mk_info "Rust project template"

            if command -q cargo
                if test $_dry_run -eq 0
                    # cargo new creates the project — we need to be one level up
                    cd ..
                    cargo new --bin $_proj_name 2>/dev/null
                    cd $_proj_name 2>/dev/null
                else
                    __mk_dry "cargo new --bin $_proj_name"
                end
            else
                for d in src tests
                    __mk_dir $d
                end
                __mk_write "Cargo.toml" \
"[package]
name = \"$_proj_name\"
version = \"0.1.0\"
edition = \"2021\"

[dependencies]

[dev-dependencies]
"
                __mk_write "src/main.rs" \
"fn main() {
    println!(\"Hello from $_proj_name!\");
}"
            end

            # .cargo/config.toml
            __mk_dir ".cargo"
            __mk_write ".cargo/config.toml" \
"[build]
jobs = 4

[target.x86_64-unknown-linux-gnu]
linker = \"clang\"
rustflags = [\"-C\", \"link-arg=-fuse-ld=mold\"]

[net]
git-fetch-with-cli = true"

            # rust-toolchain.toml
            __mk_write "rust-toolchain.toml" \
"[toolchain]
channel = \"stable\"
components = [\"rustfmt\", \"clippy\", \"rust-src\", \"rust-analyzer\"]"

            # .rustfmt.toml
            __mk_write ".rustfmt.toml" \
"edition = \"2021\"
max_width = 100
use_small_heuristics = \"Max\""

            set _readme 1

        # ── Go ────────────────────────────────────────────────────────────────
        case go golang
            __mk_info "Go project template"

            for d in cmd/$_proj_name internal pkg
                __mk_dir $d
            end

            # go.mod
            set -l go_module "github.com/$USER/$_proj_name"
            __mk_write "go.mod" \
"module $go_module

go 1.22

require ()
"

            # main.go
            __mk_write "cmd/$_proj_name/main.go" \
"package main

import (
	\"fmt\"
	\"os\"
)

func main() {
	fmt.Println(\"Hello from $_proj_name!\")
	os.Exit(0)
}"

            # Makefile
            __mk_write "Makefile" \
"BINARY  := $_proj_name
MODULE  := $go_module

.PHONY: build run test lint fmt tidy clean

build:
	go build -ldflags=\"-s -w\" -o bin/\$(BINARY) ./cmd/\$(BINARY)/

run:
	go run ./cmd/\$(BINARY)/

test:
	go test -v -race ./...

lint:
	golangci-lint run ./...

fmt:
	gofumpt -l -w .

tidy:
	go mod tidy

clean:
	rm -rf bin/"

            # .gitignore
            __mk_write ".gitignore" \
"bin/
*.exe
*.test
*.out
coverage.txt
.env
.DS_Store"

            set _readme 1

        # ── Web / Static site ─────────────────────────────────────────────────
        case web static site
            __mk_info "Static web project template"

            for d in assets/css assets/js assets/img
                __mk_dir $d
            end

            # index.html
            __mk_write "index.html" \
"<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <meta name=\"description\" content=\"$_proj_name\">
  <title>$_proj_name</title>
  <link rel=\"stylesheet\" href=\"assets/css/main.css\">
</head>
<body>
  <main>
    <h1>$_proj_name</h1>
    <p>Hello, World!</p>
  </main>
  <script type=\"module\" src=\"assets/js/main.js\"></script>
</body>
</html>"

            # CSS
            __mk_write "assets/css/main.css" \
"*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #1e1e2e;
  --fg: #cdd6f4;
  --accent: #cba6f7;
  --font: system-ui, sans-serif;
}

body {
  background: var(--bg);
  color: var(--fg);
  font-family: var(--font);
  min-height: 100vh;
  display: grid;
  place-items: center;
}

h1 { color: var(--accent); }"

            # JS
            __mk_write "assets/js/main.js" \
"'use strict'

console.log('$_proj_name loaded')
"

            set _readme 1

        # ── API ───────────────────────────────────────────────────────────────
        case api rest
            __mk_info "REST API project template"

            for d in src/routes src/middleware src/models tests docs
                __mk_dir $d
            end

            # docker-compose.yml
            __mk_write "docker-compose.yml" \
"services:
  api:
    build: .
    ports:
      - \"8080:8080\"
    environment:
      - PORT=8080
    env_file: .env
    volumes:
      - .:/app

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: \${DB_NAME:-$_proj_name}
      POSTGRES_USER: \${DB_USER:-user}
      POSTGRES_PASSWORD: \${DB_PASS:-password}
    ports:
      - \"5432:5432\""

            # Dockerfile
            __mk_write "Dockerfile" \
"FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
EXPOSE 8080
CMD [\"node\", \"src/index.js\"]"

            # .env.example
            __mk_write ".env.example" \
"PORT=8080
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$_proj_name
DB_USER=user
DB_PASS=password
JWT_SECRET=change-me-in-production
API_KEY=your-api-key-here"

            set _readme 1
            set _env    1
            set _git    1

        # ── Data Science ──────────────────────────────────────────────────────
        case data data-science ds
            __mk_info "Data science project template"

            for d in data/raw data/processed data/external notebooks src reports
                __mk_dir $d
            end

            __mk_write "notebooks/.gitkeep" ""
            __mk_write "data/raw/.gitkeep"  ""

            # requirements.txt
            __mk_write "requirements.txt" \
"# Core data science stack
numpy>=1.26
pandas>=2.0
scikit-learn>=1.3
matplotlib>=3.7
seaborn>=0.12
jupyter>=1.0
ipython>=8.0
scipy>=1.11

# Dev tools
black
ruff
pytest"

            set _readme 1
            set _env    1
            set _venv   1

        # ── Machine Learning ──────────────────────────────────────────────────
        case ml machine-learning ai
            __mk_info "Machine learning project template"

            for d in data/raw data/processed models experiments notebooks src tests
                __mk_dir $d
            end

            __mk_write "requirements.txt" \
"# ML framework
torch>=2.0
torchvision>=0.15
torchaudio>=2.0

# Data processing
numpy>=1.26
pandas>=2.0
scikit-learn>=1.3

# Experiment tracking
mlflow>=2.0
wandb

# Visualization
matplotlib>=3.7
plotly>=5.0

# Dev
black
ruff
pytest
jupyter"

            __mk_write "src/train.py" \
"\"\"\"Training entry point.\"\"\"

import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=\"Train model\")
    parser.add_argument(\"--config\", default=\"config.yaml\")
    parser.add_argument(\"--epochs\", type=int, default=10)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(f\"Training with config: {args.config}\")


if __name__ == \"__main__\":
    main()"

            set _readme 1
            set _env    1
            set _venv   1

        # ── Dotfiles ──────────────────────────────────────────────────────────
        case dotfiles dots
            __mk_info "Dotfiles project template"

            for d in config/fish config/nvim config/hypr scripts docs
                __mk_dir $d
            end

            __mk_write "install.sh" \
"#!/usr/bin/env bash
# Dotfiles install script
set -euo pipefail

DOTFILES_DIR=\$(cd \$(dirname \${BASH_SOURCE[0]}) && pwd)
echo \"Installing dotfiles from \$DOTFILES_DIR\"

# Symlink configs
for item in config/*; do
  name=\$(basename \"\$item\")
  target=\"\$HOME/.config/\$name\"
  ln -sfn \"\$DOTFILES_DIR/\$item\" \"\$target\"
  echo \"  ✓ ~/.config/\$name\"
done

echo \"Done!\""

            command -q chmod && chmod +x "install.sh" 2>/dev/null

            set _readme 1
            set _git    1

        # ── Generic library ───────────────────────────────────────────────────
        case lib library
            __mk_info "Library project template"

            for d in src tests examples docs
                __mk_dir $d
            end

            set _readme 1
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  ➕ OPTIONAL ADDITIONS                                                  ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    # ── Git initialization ────────────────────────────────────────────────────
    if test $_git -eq 1
        if test $_dry_run -eq 1
            __mk_dry "git init"
        else if not test -d ".git"
            git init --quiet 2>/dev/null
            and begin
                printf "  $GREEN✓$R  git initialized (%s)\n" \
                    (git branch --show-current 2>/dev/null || echo "main")
            end

            # Initial commit
            git add -A 2>/dev/null
            git commit --quiet -m "🎉 Initial commit — $_proj_name" 2>/dev/null
            and printf "  $GREEN✓$R  Initial commit\n"
        end
    end

    # ── .env files ────────────────────────────────────────────────────────────
    if test $_env -eq 1
        if not test -f ".env.example"
            __mk_write ".env.example" \
"# Environment variables for $_proj_name
# Copy this file: cp .env.example .env
# Never commit .env to version control

APP_ENV=development
DEBUG=true
LOG_LEVEL=info
"
        end

        if not test -f ".env"
            if test $_dry_run -eq 0
                cp ".env.example" ".env" 2>/dev/null
                printf "  $GREEN✓$R  .env created from .env.example\n"
            else
                __mk_dry "cp .env.example .env"
            end
        end

        # Ensure .env is in .gitignore
        if test -f ".gitignore" && not grep -q '^\.env$' .gitignore 2>/dev/null
            echo ".env" >> .gitignore 2>/dev/null
            printf "  $GREEN✓$R  .env added to .gitignore\n"
        end
    end

    # ── README.md ─────────────────────────────────────────────────────────────
    if test $_readme -eq 1 && not test -f "README.md"
        set -l template_badge ""
        test -n "$_template" && set template_badge "  ![Template]($template)"

        __mk_write "README.md" \
"# $_proj_name

> Brief description of $_proj_name

## ✨ Features

- Feature 1
- Feature 2
- Feature 3

## 🚀 Quick Start

\`\`\`bash
# Clone the repository
git clone https://github.com/$USER/$_proj_name

# Enter directory
cd $_proj_name
\`\`\`

## 📋 Prerequisites

- List dependencies here

## 🛠️ Installation

\`\`\`bash
# Install instructions
\`\`\`

## 📖 Usage

\`\`\`bash
# Usage examples
\`\`\`

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

MIT — see [LICENSE](LICENSE)

---

*Generated by ASH DOTFILES v5.0* ⚡"

        printf "  $GREEN✓$R  README.md generated\n"
    end

    # ── Python virtual environment ─────────────────────────────────────────────
    if test $_venv -eq 1 && test "$_template" = python \
       || test $_venv -eq 1 && (test "$_template" = data || test "$_template" = ml \
          || test "$_template" = data-science || test "$_template" = ml)

        if test $_dry_run -eq 1
            __mk_dry "python3 -m venv .venv"
        else if command -q python3
            printf "  $CYAN›$R  Creating virtual environment...\n"

            # Prefer uv if available (10-100x faster)
            if command -q uv
                uv venv 2>/dev/null
                and printf "  $GREEN✓$R  .venv created (uv)\n"
            else
                python3 -m venv .venv 2>/dev/null
                and printf "  $GREEN✓$R  .venv created\n"
            end

            # Write .python-version
            set -l py_ver (python3 --version 2>/dev/null | awk '{print $2}')
            echo $py_ver > .python-version 2>/dev/null

            # Install requirements if present
            if test -f requirements.txt
                if command -q uv
                    uv pip install -r requirements.txt 2>/dev/null >/dev/null
                    and printf "  $GREEN✓$R  Requirements installed (uv)\n"
                else
                    .venv/bin/pip install -r requirements.txt --quiet 2>/dev/null
                    and printf "  $GREEN✓$R  Requirements installed\n"
                end
            end

            # Create .conda-env marker for direnv
            echo $_proj_name > .conda-env 2>/dev/null

            # Activate hint
            printf "  $DIM  Activate: source .venv/bin/activate.fish$R\n"

            # Auto-activate for this session
            if test -f ".venv/bin/activate.fish"
                source ".venv/bin/activate.fish" 2>/dev/null
                printf "  $GREEN✓$R  Virtual environment activated\n"
            end
        else
            printf "  $YELLOW⚠$R  python3 not found — skipping venv\n"
        end
    end

    # ╔══════════════════════════════════════════════════════════════════════════╗
    # ║  📊 SUMMARY                                                             ║
    # ╚══════════════════════════════════════════════════════════════════════════╝

    printf "\n"
    printf "  $BOLD$PURPLE╔══════════════════════════════════════════════════════╗$R\n"
    printf "  $BOLD$PURPLE║  📁  Created: %-46s║$R\n" \
        (string replace "$HOME" "~" $_dir | string sub --length 46)
    test -n "$_template" && \
        printf "  $BOLD$PURPLE║  📋  Template: %-45s║$R\n" $_template
    printf "  $BOLD$PURPLE║  📍  Location: %-45s║$R\n" \
        (string replace "$HOME" "~" (pwd) | string sub --length 45)
    test -n "$_template" && \
        printf "  $BOLD$PURPLE║  📄  Files: %-48s║$R\n" \
            (find . -type f ! -path "./.git/*" 2>/dev/null | wc -l | string trim)" created"
    printf "  $BOLD$PURPLE╚══════════════════════════════════════════════════════╝$R\n"
    printf "\n"

    # ── Next steps hint ───────────────────────────────────────────────────────
    if test -n "$_template"
        printf "  $BOLD$CYAN💡 Next steps:$R\n"
        switch $_template
            case python py
                printf "    $DIM$ source .venv/bin/activate.fish$R\n"
                printf "    $DIM$ pip install -e '.[dev]'$R\n"
            case node nodejs
                printf "    $DIM$ pnpm install$R\n"
                printf "    $DIM$ pnpm dev$R\n"
            case rust rs
                printf "    $DIM$ cargo build$R\n"
                printf "    $DIM$ cargo run$R\n"
            case go golang
                printf "    $DIM$ go mod tidy$R\n"
                printf "    $DIM$ make run$R\n"
            case web static
                printf "    $DIM$ python3 -m http.server 3000$R\n"
            case api
                printf "    $DIM$ cp .env.example .env$R\n"
                printf "    $DIM$ docker compose up$R\n"
            case data ml
                printf "    $DIM$ source .venv/bin/activate.fish$R\n"
                printf "    $DIM$ jupyter lab$R\n"
        end
    else
        printf "  $DIM  You are now in: %s$R\n" (string replace $HOME '~' (pwd))
    end
    printf "\n"

    # ── Open in editor ────────────────────────────────────────────────────────
    if test $_open -eq 1 && test $_dry_run -eq 0
        set -l editor (set -q VISUAL && echo $VISUAL || set -q EDITOR && echo $EDITOR || echo nvim)
        printf "  $CYAN›$R  Opening in $editor...\n\n"
        $editor .
    end

    # ── Zoxide: add to database ────────────────────────────────────────────────
    command -q zoxide && zoxide add (pwd) 2>/dev/null

    # ── Cleanup ───────────────────────────────────────────────────────────────
    functions --erase __mkcd_help __mk_ok __mk_info __mk_dry __mk_write __mk_dir 2>/dev/null

end
