# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Go Ultra Configuration                             ║
# ║  Go toolchain, modules, multiple versions, workspace & full ecosystem       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_go_loaded && exit 0
set --global _ash_go_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_go_log      "$HOME/.local/share/ash/logs/go.log"
set --global _ash_go_cache    "$HOME/.local/share/ash/cache/go"

mkdir -p (dirname $_ash_go_log) 2>/dev/null
mkdir -p $_ash_go_cache 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION: Find Go installation                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_go_detect_root --description "Find Go installation root"
    # Check common installation paths
    for candidate in \
        "$HOME/go" \
        "$HOME/.local/go" \
        "/usr/local/go" \
        "/opt/go" \
        "/usr/lib/go" \
        (command -v go 2>/dev/null | xargs -r dirname | xargs -r dirname 2>/dev/null)

        if test -x "$candidate/bin/go"
            echo $candidate
            return 0
        end
    end

    # mise / asdf managed
    if command -q mise
        set -l mise_go (mise which go 2>/dev/null | xargs -r dirname | xargs -r dirname 2>/dev/null)
        test -n "$mise_go" && echo $mise_go && return 0
    end

    # goenv
    if command -q goenv
        echo (goenv root 2>/dev/null)
        return 0
    end

    echo ""
    return 1
end

# Exit early if Go not found
if not command -q go
    set -l go_root (__ash_go_detect_root)
    if test -z "$go_root"
        exit 0
    end
    fish_add_path --prepend --global "$go_root/bin"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _go_reset   (set_color normal)
set -g _go_bold    (set_color --bold)
set -g _go_teal    (set_color 00ADD8)
set -g _go_cyan    (set_color cyan)
set -g _go_green   (set_color green)
set -g _go_yellow  (set_color yellow)
set -g _go_red     (set_color red)
set -g _go_dim     (set_color brblack)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── GOPATH: single workspace ──────────────────────────────────────────────────
set --export GOPATH  "$HOME/go"
set --export GOBIN   "$GOPATH/bin"
set --export GOCACHE "$HOME/.cache/go-build"
set --export GOMODCACHE "$GOPATH/pkg/mod"

# ── Go environment ────────────────────────────────────────────────────────────
set --export GOTELEMETRY off           # Disable telemetry
set --export GOPRIVATE  ""             # Private module patterns
set --export GONOPROXY  ""             # Bypass proxy for these
set --export GONOSUMCHECK ""           # Skip checksum for these
set --export GOFLAGS    ""             # Default go flags

# Module proxy (use direct for speed in dev)
set --export GOPROXY    "https://proxy.golang.org,direct"
set --export GONOSUMDB  ""
set --export GONOSUMCHECK ""

# CGO configuration
set --export CGO_ENABLED 1

# ── Add Go binaries to PATH ───────────────────────────────────────────────────
for go_bin in "$GOBIN" "$GOPATH/bin" "/usr/local/go/bin"
    if test -d $go_bin && not contains $go_bin $PATH
        fish_add_path --append --global $go_bin
    end
end

# goenv support
if command -q goenv
    set --export GOENV_ROOT "$HOME/.goenv"
    fish_add_path --prepend --global "$GOENV_ROOT/bin"
    goenv init - fish 2>/dev/null | source
end

# mise support
if command -q mise && mise plugin list 2>/dev/null | grep -q golang
    # mise handles path management
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 AUTO-SWITCHING: Detect go.work / go.mod version                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __ash_go_resolve_version --description "Resolve required Go version from project files"
    set -l dir (pwd)

    while test "$dir" != "/"
        # .go-version (goenv)
        if test -f "$dir/.go-version"
            string trim < "$dir/.go-version"
            return
        end

        # .tool-versions (asdf/mise)
        if test -f "$dir/.tool-versions"
            set -l ver (grep '^golang\s\|^go\s' "$dir/.tool-versions" 2>/dev/null | awk '{print $2}')
            test -n "$ver" && echo $ver && return
        end

        # go.mod go directive
        if test -f "$dir/go.mod"
            set -l ver (grep '^go ' "$dir/go.mod" | awk '{print $2}')
            test -n "$ver" && echo $ver && return
        end

        set dir (dirname $dir)
    end
    echo ""
end

function __ash_go_auto_switch --on-variable PWD \
    --description "Notify about Go version requirements on directory change"

    set -l required (__ash_go_resolve_version)
    test -z "$required" && return

    set -l current (go version 2>/dev/null | awk '{print $3}' | string replace 'go' '')

    test "$current" = "$required" && return

    set -l cache_key (echo (pwd) | md5sum | awk '{print $1}')
    set -l cache_file "$_ash_go_cache/ver-$cache_key"

    if test -f $cache_file && test (cat $cache_file) = "$required"
        return
    end

    echo $required > $cache_file
    echo $_go_dim"  🐹 Go project requires: go "$_go_teal$required$_go_reset" (current: $current)"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛠️  PUBLIC FUNCTIONS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── go-info: Rich Go environment information ─────────────────────────────────
function go-info --description "Show complete Go environment information"
    set -l reset  (set_color normal)
    set -l bold   (set_color --bold)
    set -l cyan   (set_color cyan)
    set -l teal   (set_color 00ADD8)
    set -l green  (set_color green)
    set -l dim    (set_color brblack)

    echo ""
    echo $bold$teal"  ╔══════════════════════════════════════════════════════╗"$reset
    echo $bold$teal"  ║     🐹  Go Development Environment                   ║"$reset
    echo $bold$teal"  ╚══════════════════════════════════════════════════════╝"$reset
    echo ""

    echo "  "$bold"Go:        "$reset $cyan(go version 2>/dev/null | awk '{print $3, $4}')$reset
    echo "  "$bold"GOPATH:    "$reset $dim$GOPATH$reset
    echo "  "$bold"GOBIN:     "$reset $dim$GOBIN$reset
    echo "  "$bold"GOCACHE:   "$reset $dim$GOCACHE$reset
    echo "  "$bold"GOMODCACHE:"$reset $dim$GOMODCACHE$reset
    echo "  "$bold"GOPROXY:   "$reset $dim$GOPROXY$reset
    echo "  "$bold"CGO:       "$reset (test "$CGO_ENABLED" = 1 && echo $green"enabled"$reset || echo $dim"disabled"$reset)
    echo ""

    # Project info
    if test -f go.mod
        echo "  "$bold"Module:    "$reset $green(grep '^module' go.mod | awk '{print $2}')$reset
        echo "  "$bold"Go req:    "$reset (grep '^go ' go.mod | awk '{print $2}')
        echo ""
    end

    # Workspace
    if test -f go.work
        echo "  "$bold"Workspace: "$reset $green"go.work detected"$reset
        grep '^use' go.work | while read -l line
            echo "    "$dim$line$reset
        end
        echo ""
    end

    # Installed tools
    echo "  "$bold"Go Tools:"$reset
    set -l tools \
        golangci-lint gofumpt goimports gopls dlv \
        govulncheck goreleaser air mockgen \
        swag buf protoc-gen-go
    for tool in $tools
        if command -q $tool
            echo "    "$green"✓ "$reset$tool
        end
    end

    # GOPATH bin count
    set -l bin_count (count $GOBIN/* 2>/dev/null)
    echo ""
    echo "  "$bold"GOBIN tools: "$reset $cyan$bin_count$reset
    echo ""
end

# ─── go-new: Create a new Go module/project ───────────────────────────────────
function go-new --description "Create a new Go project with best-practice structure"
    set -l name   $argv[1]
    set -l module $argv[2]
    set -l type   $argv[3]   # cmd | lib | web | cli | grpc

    if test -z "$name"
        read -P "  Project name: " name
    end
    test -z "$name" && begin; echo $_go_red"  ✗ Name required"$_go_reset; return 1; end

    if test -z "$module"
        read -P "  Module path (e.g. github.com/user/$name): " module
        test -z "$module" && set module "github.com/$USER/$name"
    end

    test -z "$type" && set type cmd

    echo ""
    echo $_go_teal"  🐹 Creating Go project: $name ($module)"$_go_reset
    echo ""

    mkdir -p $name
    cd $name

    # Initialize module
    go mod init $module

    switch $type
        case cmd
            mkdir -p cmd/$name internal pkg
            printf 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("Hello from %s!")\n}\n' $name \
                > "cmd/$name/main.go"

        case lib
            mkdir -p internal pkg
            printf 'package %s\n\n// Package %s provides ...\npackage %s\n' \
                (string replace '-' '' $name) $name (string replace '-' '' $name) \
                > "$name.go"

        case web
            mkdir -p cmd/$name internal/handler internal/middleware pkg static templates
            printf 'package main\n\nimport (\n\t"fmt"\n\t"net/http"\n)\n\nfunc main() {\n\thttp.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {\n\t\tfmt.Fprintln(w, "Hello!")\n\t})\n\thttp.ListenAndServe(":8080", nil)\n}\n' \
                > "cmd/$name/main.go"

        case cli
            mkdir -p cmd/$name internal pkg
            printf 'package main\n\nimport (\n\t"fmt"\n\t"os"\n)\n\nfunc main() {\n\tif len(os.Args) < 2 {\n\t\tfmt.Fprintln(os.Stderr, "Usage: %s <command>")\n\t\tos.Exit(1)\n\t}\n\tfmt.Println("Hello from %s!")\n}\n' $name $name \
                > "cmd/$name/main.go"
    end

    # .gitignore
    printf '%s\n\n# Go\n*.exe\n*.test\n*.out\ncoverage.txt\ndist/\n' \
        "# Binaries" > .gitignore

    # Makefile
    printf 'BINARY = %s\nMODULE = %s\n\n.PHONY: build run test lint fmt clean tidy\n\nbuild:\n\tgo build -ldflags="-s -w" -o bin/$(BINARY) ./cmd/$(BINARY)/\n\nrun:\n\tgo run ./cmd/$(BINARY)/\n\ntest:\n\tgo test -v -race -coverprofile=coverage.txt ./...\n\nlint:\n\tgolangci-lint run ./...\n\nfmt:\n\tgofumpt -l -w .\n\tgoimports -l -w .\n\ntidy:\n\tgo mod tidy\n\nclean:\n\trm -rf bin/ coverage.txt\n' \
        $name $module > Makefile

    # go.sum tidy
    go mod tidy 2>/dev/null

    echo $_go_green"  ✓ Module:    $module"$_go_reset
    echo $_go_green"  ✓ Structure: $type layout"$_go_reset
    echo $_go_green"  ✓ Makefile:  make build|run|test|lint|fmt"$_go_reset
    echo ""
end

# ─── go-install-tools: Install common Go development tools ────────────────────
function go-install-tools --description "Install common Go development tools"
    set -l tools \
        "golang.org/x/tools/gopls@latest\tLanguage server" \
        "github.com/go-delve/delve/cmd/dlv@latest\tDebugger" \
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest\tLinter" \
        "mvdan.cc/gofumpt@latest\tFormatter (stricter gofmt)" \
        "golang.org/x/tools/cmd/goimports@latest\tImport organizer" \
        "golang.org/x/vuln/cmd/govulncheck@latest\tVulnerability checker" \
        "github.com/air-verse/air@latest\tHot reloader" \
        "github.com/goreleaser/goreleaser@latest\tRelease automation" \
        "github.com/vektra/mockery/v2@latest\tMock generator"

    echo ""
    echo $_go_teal"  🐹 Installing Go development tools..."$_go_reset
    echo ""

    for tool_entry in $tools
        set -l parts (string split \t $tool_entry)
        set -l pkg   $parts[1]
        set -l desc  $parts[2]
        set -l name  (string split '@' $pkg)[1] | string split '/'[-1]

        printf "  %-20s %s\n" $name $_go_dim$desc$_go_reset

        go install $pkg 2>/dev/null
        and echo $_go_green"    ✓ installed"$_go_reset
        or  echo $_go_yellow"    ⚠ failed (may require specific Go version)"$_go_reset
    end

    echo ""
    echo $_go_green"  ✓ Tools installation complete"$_go_reset
    echo ""
end

# ─── go-lint: Run golangci-lint with nice output ──────────────────────────────
function go-lint --description "Run golangci-lint with best configuration"
    if not command -q golangci-lint
        echo $_go_yellow"  Installing golangci-lint..."$_go_reset
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    end

    echo ""
    echo $_go_teal"  🔍 Running golangci-lint..."$_go_reset
    echo ""
    golangci-lint run --color always $argv
end

# ─── go-test-full: Comprehensive test run ────────────────────────────────────
function go-test-full --description "Run Go tests with race detection and coverage"
    echo ""
    echo $_go_teal"  🧪 Running full test suite..."$_go_reset
    echo ""

    go test \
        -v \
        -race \
        -count=1 \
        -coverprofile=coverage.out \
        -covermode=atomic \
        ./... $argv

    set -l rc $status

    if test $rc -eq 0
        # Generate HTML coverage report
        go tool cover -html=coverage.out -o coverage.html 2>/dev/null
        set -l coverage (go tool cover -func=coverage.out 2>/dev/null | tail -1 | awk '{print $3}')
        echo ""
        echo $_go_green"  ✓ All tests passed"$_go_reset
        echo "  Coverage: "$_go_cyan$coverage$_go_reset
        echo "  Report:   "$_go_dim"coverage.html"$_go_reset
    else
        echo ""
        echo $_go_red"  ✗ Tests failed"$_go_reset
    end
    echo ""
    return $rc
end

# ─── go-bench: Run benchmarks with comparison ────────────────────────────────
function go-bench --description "Run Go benchmarks"
    set -l name $argv[1]
    test -z "$name" && set name "."

    echo ""
    echo $_go_teal"  📊 Running benchmarks..."$_go_reset
    echo ""

    go test -bench=$name -benchmem -benchtime=3s ./... $argv[2..-1]
end

# ─── go-vuln: Run vulnerability check ────────────────────────────────────────
function go-vuln --description "Run govulncheck to find vulnerabilities"
    if not command -q govulncheck
        echo $_go_yellow"  Installing govulncheck..."$_go_reset
        go install golang.org/x/vuln/cmd/govulncheck@latest
    end

    echo ""
    echo $_go_teal"  🔒 Checking for vulnerabilities..."$_go_reset
    echo ""
    govulncheck ./... $argv
end

# ─── go-air: Hot reload development server ────────────────────────────────────
function go-air --description "Start hot-reload dev server with air"
    if not command -q air
        echo $_go_yellow"  Installing air..."$_go_reset
        go install github.com/air-verse/air@latest
    end

    # Create .air.toml if missing
    if not test -f .air.toml
        air init 2>/dev/null
        echo $_go_green"  ✓ .air.toml created"$_go_reset
    end

    echo $_go_teal"  🔥 Starting hot-reload..."$_go_reset
    air $argv
end

# ─── go-work: Go workspace management ────────────────────────────────────────
function go-work --description "Manage Go workspaces"
    set -l cmd $argv[1]

    switch $cmd
        case init
            go work init $argv[2..-1]
            echo $_go_green"  ✓ go.work initialized"$_go_reset

        case add
            go work use $argv[2..-1]
            echo $_go_green"  ✓ Added to workspace"$_go_reset

        case sync
            go work sync
            echo $_go_green"  ✓ Workspace synced"$_go_reset

        case edit
            $EDITOR go.work 2>/dev/null || nvim go.work

        case info
            if test -f go.work
                echo ""
                echo $_go_teal"  🔧 Go Workspace"$_go_reset
                echo ""
                cat go.work
                echo ""
            else
                echo $_go_yellow"  No go.work found in current directory"$_go_reset
            end

        case '*'
            echo "  Usage: go-work <init|add|sync|edit|info> [args...]"
    end
end

# ─── go-profile: CPU/memory profiling ────────────────────────────────────────
function go-profile --description "Profile Go binary (CPU and memory)"
    set -l type $argv[1]   # cpu | mem | trace
    test -z "$type" && set type cpu

    echo ""
    echo $_go_teal"  📊 Profiling: $type"$_go_reset
    echo ""

    switch $type
        case cpu
            go test -cpuprofile=cpu.prof -bench=. ./...
            go tool pprof -http=:6060 cpu.prof 2>/dev/null &
            echo $_go_green"  ✓ Profile server: http://localhost:6060"$_go_reset

        case mem
            go test -memprofile=mem.prof -bench=. ./...
            go tool pprof -http=:6061 mem.prof 2>/dev/null &
            echo $_go_green"  ✓ Profile server: http://localhost:6061"$_go_reset

        case trace
            go test -trace=trace.out ./...
            go tool trace trace.out 2>/dev/null
    end
    echo ""
end

# ─── go-clean-all: Clean all Go caches ───────────────────────────────────────
function go-clean-all --description "Clean Go build cache and module cache"
    echo ""
    echo $_go_yellow"  🧹 Cleaning Go caches..."$_go_reset
    echo ""

    set -l build_size (du -sh $GOCACHE 2>/dev/null | awk '{print $1}')
    go clean -cache
    echo $_go_green"  ✓ Build cache cleaned ($build_size)"$_go_reset

    read -P "  Clean module cache? [y/N] " clean_mod
    if string match -qi 'y*' $clean_mod
        set -l mod_size (du -sh $GOMODCACHE 2>/dev/null | awk '{print $1}')
        go clean -modcache
        echo $_go_green"  ✓ Module cache cleaned ($mod_size)"$_go_reset
    end

    echo ""
end

# ─── go-upgrade: Upgrade all dependencies ────────────────────────────────────
function go-upgrade --description "Upgrade all Go dependencies to latest"
    echo ""
    echo $_go_teal"  🔄 Upgrading Go dependencies..."$_go_reset
    echo ""

    go get -u ./...
    go mod tidy
    go mod verify

    echo ""
    echo $_go_green"  ✓ Dependencies upgraded"$_go_reset
    echo ""
end

# ─── go-doc-serve: Serve Go documentation locally ────────────────────────────
function go-doc-serve --description "Serve Go documentation on localhost"
    set -l port $argv[1]
    test -z "$port" && set port 6060

    if not command -q godoc
        echo $_go_yellow"  Installing godoc..."$_go_reset
        go install golang.org/x/tools/cmd/godoc@latest
    end

    echo $_go_teal"  📖 Serving docs at http://localhost:$port"$_go_reset
    godoc -http=:$port
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Core go commands
abbr --add gb     'go build ./...'
abbr --add gbv    'go build -v ./...'
abbr --add gr     'go run .'
abbr --add gt     'go test ./...'
abbr --add gtv    'go test -v ./...'
abbr --add gtf    'go-test-full'
abbr --add gbench 'go-bench'
abbr --add gc     'go clean'
abbr --add gca    'go-clean-all'
abbr --add gget   'go get'
abbr --add ginst  'go install'
abbr --add gtidy  'go mod tidy'
abbr --add gmodup 'go-upgrade'
abbr --add gmodv  'go mod verify'
abbr --add gmodg  'go mod graph'
abbr --add gmodw  'go mod why'
abbr --add gfmt   'gofumpt -l -w .'
abbr --add gimp   'goimports -l -w .'
abbr --add gvet   'go vet ./...'
abbr --add glint  'go-lint'
abbr --add gvuln  'go-vuln'
abbr --add gdoc   'go doc'
abbr --add gdocs  'go-doc-serve'
abbr --add ginfo  'go-info'

# Project management
abbr --add gnew   'go-new'
abbr --add gtools 'go-install-tools'
abbr --add gair   'go-air'
abbr --add gwork  'go-work'
abbr --add gprof  'go-profile'

# go env
abbr --add genv   'go env'
abbr --add gpath  'echo $GOPATH'
abbr --add gbin   'echo $GOBIN'
abbr --add glsbin 'ls -la $GOBIN'