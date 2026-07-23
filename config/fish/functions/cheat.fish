#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 CHEAT.FISH — Interactive Cheatsheet System                              ║
# ║  ASH Dotfiles v5.0 OMEGA • Ultra-Grade Function                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE:
#   cheat <topic>              — Show cheatsheet for topic
#   cheat -l / --list          — List all available cheatsheets
#   cheat -s / --search <term> — Search across all cheatsheets
#   cheat -i / --interactive   — FZF interactive mode
#   cheat -e / --edit <topic>  — Edit/create personal cheatsheet
#   cheat -c / --copy <topic>  — Copy cheatsheet to clipboard
#   cheat -u / --update        — Update cheat databases
#   cheat --tldr <topic>       — Show tldr page
#   cheat --man <topic>        — Open man with bat pager
#   cheat --eg <topic>         — Show eg examples
#   cheat --web <topic>        — Open in browser (cheat.sh)
#   cheat --cache              — Show cache info
#   cheat --clear-cache        — Clear local cache

# ─── Constants ────────────────────────────────────────────────────────────────

set -l __CHEAT_VERSION "5.0.0"
set -l __CHEAT_CACHE_DIR "$HOME/.cache/ash/cheat"
set -l __CHEAT_USER_DIR "$HOME/.local/share/ash/cheat"
set -l __CHEAT_BUILTIN_DIR "$HOME/.config/ash/cheat/sheets"
set -l __CHEAT_URL "https://cheat.sh"
set -l __CHEAT_TIMEOUT 8

# ─── Color Palette ─────────────────────────────────────────────────────────────

set -l CLR_RESET   (set_color normal)
set -l CLR_BOLD    (set_color --bold)
set -l CLR_DIM     (set_color brblack)
set -l CLR_RED     (set_color red)
set -l CLR_GREEN   (set_color green)
set -l CLR_YELLOW  (set_color yellow)
set -l CLR_BLUE     (set_color blue)
set -l CLR_CYAN     (set_color cyan)
set -l CLR_MAGENTA (set_color magenta)
set -l CLR_WHITE   (set_color white)
set -l CLR_BRED     (set_color brred)
set -l CLR_BGREEN   (set_color brgreen)
set -l CLR_BYELLOW (set_color bryellow)
set -l CLR_BBLUE   (set_color brblue)
set -l CLR_BCYAN   (set_color brcyan)
set -l CLR_BMAGENTA (set_color brmagenta)

# ─── Icons ─────────────────────────────────────────────────────────────────────

set -l ICO_CHEAT   "📖"
set -l ICO_SEARCH  "🔍"
set -l ICO_EDIT    "✏️ "
set -l ICO_COPY    "📋"
set -l ICO_UPDATE  "🔄"
set -l ICO_WEB     "🌐"
set -l ICO_OK      "✅"
set -l ICO_ERR     "❌"
set -l ICO_WARN    "⚠️ "
set -l ICO_TIP     "💡"
set -l ICO_LIST    "📜"
set -l ICO_CACHE   "💾"
set -l ICO_BUILTIN "🔧"
set -l ICO_USER    "👤"
set -l ICO_NET     "🌍"

# ─── Helper: Banner ────────────────────────────────────────────────────────────

function __cheat_banner
    echo ""
    echo $CLR_BBLUE"╔══════════════════════════════════════════════════╗"$CLR_RESET
    echo $CLR_BBLUE"║  "$CLR_BCYAN"📖  ASH CHEAT v$__CHEAT_VERSION — Ultra Cheatsheet System  "$CLR_BBLUE"║"$CLR_RESET
    echo $CLR_BBLUE"╚══════════════════════════════════════════════════╝"$CLR_RESET
    echo ""
end

# ─── Helper: Section Header ────────────────────────────────────────────────────

function __cheat_section -a label
    set -l width 50
    set -l line (string repeat -n $width "─")
    echo ""
    echo $CLR_BBLUE"┌─ "$CLR_BYELLOW"$label "$CLR_BBLUE$line$CLR_RESET
end

# ─── Helper: Print Helpers ─────────────────────────────────────────────────────

function __cheat_ok    -a msg; echo $CLR_BGREEN"  $ICO_OK  $msg"$CLR_RESET; end
function __cheat_err   -a msg; echo $CLR_BRED"  $ICO_ERR  $msg"$CLR_RESET >&2; end
function __cheat_warn  -a msg; echo $CLR_BYELLOW"  $ICO_WARN $msg"$CLR_RESET; end
function __cheat_tip   -a msg; echo $CLR_BCYAN"  $ICO_TIP  $msg"$CLR_RESET; end
function __cheat_info  -a msg; echo $CLR_BBLUE"  ℹ️   $msg"$CLR_RESET; end
function __cheat_dim   -a msg; echo $CLR_DIM"       $msg"$CLR_RESET; end

# ─── Helper: Dependency Check ──────────────────────────────────────────────────

function __cheat_deps
    set -l missing
    for dep in curl fzf bat
        if not command -q $dep
            set -a missing $dep
        end
    end
    if test (count $missing) -gt 0
        __cheat_warn "Optional deps missing: "(string join ", " $missing)
        __cheat_tip  "Install for enhanced experience"
    end
    return 0
end

# ─── Helper: Ensure Dirs ───────────────────────────────────────────────────────

function __cheat_ensure_dirs
    for d in $__CHEAT_CACHE_DIR $__CHEAT_USER_DIR $__CHEAT_BUILTIN_DIR
        if not test -d $d
            mkdir -p $d
        end
    end
end

# ─── Helper: Cache Path ────────────────────────────────────────────────────────

function __cheat_cache_path -a topic
    echo "$__CHEAT_CACHE_DIR/"(string replace -a "/" "_" $topic)".txt"
end

# ─── Helper: Is Cache Fresh ────────────────────────────────────────────────────

function __cheat_cache_fresh -a path
    if not test -f $path
        return 1
    end
    # Cache is fresh if modified within last 24 hours (86400 seconds)
    set -l now (date +%s)
    set -l mtime (stat -c %Y $path 2>/dev/null; or stat -f %m $path 2>/dev/null)
    if test -z "$mtime"
        return 1
    end
    set -l age (math $now - $mtime)
    if test $age -lt 86400
        return 0
    end
    return 1
end

# ─── Helper: Pager ─────────────────────────────────────────────────────────────

function __cheat_pager -a file
    if command -q bat
        bat --style=full \
            --color=always \
            --paging=auto \
            --theme="$(set -q BAT_THEME; and echo $BAT_THEME; or echo 'TwoDark')" \
            $file
    else if command -q less
        less -R $file
    else
        cat $file
    end
end

# ─── Helper: Pager String ──────────────────────────────────────────────────────

function __cheat_pager_str -a content -a lang
    if command -q bat
        echo $content | bat \
            --style=full \
            --color=always \
            --paging=auto \
            --language=$lang \
            --theme="$(set -q BAT_THEME; and echo $BAT_THEME; or echo 'TwoDark')"
    else
        echo $content | less -R
    end
end

# ─── Helper: Clipboard ─────────────────────────────────────────────────────────

function __cheat_to_clipboard -a content
    if command -q wl-copy
        echo $content | wl-copy
        __cheat_ok "Copied to Wayland clipboard"
        return 0
    else if command -q xclip
        echo $content | xclip -selection clipboard
        __cheat_ok "Copied to X11 clipboard"
        return 0
    else if command -q xsel
        echo $content | xsel --clipboard --input
        __cheat_ok "Copied to clipboard"
        return 0
    else
        __cheat_err "No clipboard tool found (wl-copy/xclip/xsel)"
        return 1
    end
end

# ─── Builtin Cheatsheets ───────────────────────────────────────────────────────

function __cheat_get_builtin -a topic
    switch $topic

        # ── git ──────────────────────────────────────────────────────────────
        case git
            echo "# 🔀 Git Cheatsheet
═══════════════════════════════════════════════════════

## 📁 Repository Setup
  git init                          # Initialize repo
  git clone <url>                   # Clone remote repo
  git clone --depth 1 <url>         # Shallow clone (faster)
  git clone -b <branch> <url>       # Clone specific branch

## 📸 Staging & Commits
  git add .                         # Stage all changes
  git add -p                        # Interactively stage hunks
  git commit -m \"message\"           # Commit with message
  git commit --amend                # Amend last commit
  git commit --amend --no-edit      # Amend without editing message
  git commit -S -m \"message\"        # Signed commit (GPG)

## 🌿 Branches
  git branch                        # List local branches
  git branch -a                     # List all branches
  git branch <name>                 # Create branch
  git checkout -b <name>            # Create & switch branch
  git switch <name>                 # Switch branch (modern)
  git switch -c <name>              # Create & switch (modern)
  git branch -d <name>              # Delete branch (safe)
  git branch -D <name>              # Force delete branch

## 🔀 Merging & Rebasing
  git merge <branch>                # Merge branch
  git merge --no-ff <branch>        # Merge with merge commit
  git rebase <branch>               # Rebase onto branch
  git rebase -i HEAD~3              # Interactive rebase (last 3)
  git rebase --abort                # Abort rebase
  git rebase --continue             # Continue after conflict

## 🌐 Remote Operations
  git remote -v                     # Show remotes
  git remote add origin <url>       # Add remote
  git fetch origin                  # Fetch from origin
  git pull origin <branch>          # Pull from branch
  git pull --rebase origin <branch> # Pull with rebase
  git push origin <branch>          # Push branch
  git push -u origin <branch>       # Push & set upstream
  git push --force-with-lease       # Safe force push

## 🔍 Inspection
  git log --oneline --graph --all   # Visual log
  git log -p <file>                 # File change history
  git diff                          # Unstaged changes
  git diff --staged                 # Staged changes
  git diff <branch1>..<branch2>     # Branch diff
  git show <commit>                 # Show commit
  git blame <file>                  # Line-by-line blame
  git bisect start                  # Binary search for bug

## 💾 Stashing
  git stash                         # Stash changes
  git stash push -m \"name\"          # Named stash
  git stash list                    # List stashes
  git stash pop                     # Apply & remove stash
  git stash apply stash@{0}         # Apply specific stash
  git stash drop stash@{0}          # Remove stash

## ↩️  Undoing
  git restore <file>                # Discard working changes
  git restore --staged <file>       # Unstage file
  git reset HEAD~1                  # Undo last commit (keep changes)
  git reset --hard HEAD~1           # Undo last commit (discard)
  git revert <commit>               # Create revert commit
  git clean -fd                     # Remove untracked files/dirs

## 🏷️  Tags
  git tag                           # List tags
  git tag v1.0.0                    # Lightweight tag
  git tag -a v1.0.0 -m \"Release\"   # Annotated tag
  git push origin --tags            # Push all tags
  git push origin v1.0.0            # Push specific tag

## 🛠️  Config
  git config --global user.name \"Name\"
  git config --global user.email \"email\"
  git config --global core.editor nvim
  git config --list                 # Show all config
  git config --global alias.lg \"log --oneline --graph --all\"

## 🛠️  Power Tips
  git cherry-pick <commit>          # Apply specific commit
  git shortlog -sn                  # Contributor summary
  git reflog                        # All HEAD movements
  git worktree add ../branch <branch>  # Multiple worktrees
  git submodule update --init --recursive"

        # ── fish ─────────────────────────────────────────────────────────────
        case fish
            echo "# 🐟 Fish Shell Cheatsheet
═══════════════════════════════════════════════════════

## 🔤 Variables
  set var value                     # Set local variable
  set -g var value                  # Set global variable
  set -x var value                  # Set & export
  set -e var                        # Erase variable
  set -q var                        # Check if set (0=set)
  echo \$var                         # Use variable
  echo \$var[1]                       # Array index (1-based)
  echo (count \$array)               # Array length

## 🔁 Loops
  for i in (seq 1 10)
      echo \$i
  end

  for file in *.txt
      echo \$file
  end

  while test \$i -lt 10
      set i (math \$i + 1)
  end

## 🔀 Conditionals
  if test -f file.txt
      echo \"exists\"
  else if test -d dir/
      echo \"is directory\"
  else
      echo \"not found\"
  end

  switch \$var
      case \"hello\"
          echo \"greeting\"
      case \"bye\" \"farewell\"
          echo \"parting\"
      case '*'
          echo \"default\"
  end

## ⚡ Functions
  function greet -a name
      -d \"Greet someone\"
      echo \"Hello, \$name!\"
  end

  function add --argument-names x y
      math \$x + \$y
  end

## 🔧 String Ops
  string length \"hello\"             # 5
  string upper \"hello\"              # HELLO
  string lower \"HELLO\"              # hello
  string sub -s 2 -l 3 \"hello\"     # ell
  string replace \"foo\" \"bar\" \"foobar\" # barbar
  string split \":\" \"a:b:c\"          # a b c
  string join \",\" a b c             # a,b,c
  string match -r '\\d+' \"abc123\"    # 123
  string trim \"  hello  \"           # hello

## 📂 Path Ops
  path basename /foo/bar.txt        # bar.txt
  path dirname /foo/bar.txt         # /foo
  path extension /foo/bar.txt       # .txt
  path exists /foo/bar.txt          # 0 if exists

## 🔍 Process / Command
  command -q nvim                   # Check if cmd exists
  status is-interactive             # Check interactive
  status is-login                   # Check login shell
  fish_pid                          # Current shell PID
  jobs                              # Background jobs

## 🎨 Prompt & UI
  set fish_greeting \"\" \"\"            # Disable greeting
  set -g fish_prompt_pwd_dir_length 3
  fish_config                       # Browser config UI

## ⌨️  Key Bindings (default)
  Alt+←  / Alt+→    Word navigation
  Ctrl+A / Ctrl+E   Start / End of line
  Ctrl+W            Delete word back
  Alt+D             Delete word forward
  Ctrl+R            History search
  Alt+↑             History token search
  Ctrl+L            Clear screen
  Tab               Completion / accept suggestion
  Alt+Enter         Newline (multiline edit)

## 💡 Tips
  type -a <cmd>                     # Show all cmd locations
  functions <name>                  # Show function body
  builtin <cmd>                     # Force builtin
  abbr -a gp 'git push'            # Abbreviations
  funcsave <name>                   # Save function to disk
  fish_update_completions           # Update completions"

        # ── docker ───────────────────────────────────────────────────────────
        case docker
            echo "# 🐳 Docker Cheatsheet
═══════════════════════════════════════════════════════

## 🖼️  Images
  docker images                     # List images
  docker pull ubuntu:22.04          # Pull image
  docker build -t myapp:1.0 .       # Build image
  docker build --no-cache -t app .  # Build without cache
  docker rmi <image>                # Remove image
  docker image prune -a             # Remove unused images
  docker save -o app.tar myapp      # Export image
  docker load -i app.tar            # Import image
  docker inspect <image>            # Image details

## 🚀 Containers
  docker run nginx                  # Run container
  docker run -d nginx               # Run detached
  docker run -it ubuntu bash        # Interactive shell
  docker run -p 8080:80 nginx       # Port mapping
  docker run -v /host:/container nginx  # Volume mount
  docker run --name myapp nginx     # Named container
  docker run --rm nginx             # Auto-remove on exit
  docker run -e ENV_VAR=val nginx   # Environment var
  docker run --cpus=\"1.5\" nginx     # CPU limit
  docker run --memory=\"512m\" nginx  # Memory limit

## 📋 Container Management
  docker ps                         # Running containers
  docker ps -a                      # All containers
  docker start <container>          # Start container
  docker stop <container>           # Stop (graceful)
  docker kill <container>           # Kill immediately
  docker restart <container>        # Restart
  docker rm <container>             # Remove container
  docker container prune            # Remove stopped

## 🔧 Container Ops
  docker exec -it <ctr> bash        # Shell into container
  docker exec <ctr> ls /app         # Run command
  docker logs <container>           # View logs
  docker logs -f <container>        # Follow logs
  docker logs --tail 100 <ctr>      # Last 100 lines
  docker cp <ctr>:/path ./local     # Copy from container
  docker cp ./local <ctr>:/path     # Copy to container
  docker diff <container>           # Changed files
  docker top <container>            # Running processes
  docker stats                      # Resource stats
  docker stats --no-stream          # One-shot stats

## 📦 Volumes
  docker volume create mydata       # Create volume
  docker volume ls                  # List volumes
  docker volume inspect mydata      # Volume details
  docker volume rm mydata           # Remove volume
  docker volume prune               # Remove unused

## 🌐 Networks
  docker network ls                 # List networks
  docker network create mynet       # Create network
  docker network connect mynet <ctr># Connect container
  docker run --network mynet nginx  # Use network
  docker network inspect mynet      # Network details
  docker network prune              # Remove unused

## 🏗️  Docker Compose
  docker compose up                 # Start services
  docker compose up -d              # Start detached
  docker compose up --build         # Rebuild & start
  docker compose down               # Stop & remove
  docker compose down -v            # Remove with volumes
  docker compose ps                 # List services
  docker compose logs -f            # Follow all logs
  docker compose exec app bash      # Shell into service
  docker compose pull               # Pull all images
  docker compose build              # Build all images
  docker compose restart <service>  # Restart service

## 🗑️  Cleanup
  docker system prune               # Remove unused all
  docker system prune -a --volumes  # Nuclear cleanup
  docker system df                  # Disk usage

## 📝 Dockerfile Tips
  FROM ubuntu:22.04                 # Base image
  RUN apt-get update && apt-get install -y curl  # Install
  COPY . /app                       # Copy files
  WORKDIR /app                      # Set workdir
  ENV NODE_ENV=production           # Set env var
  EXPOSE 3000                       # Document port
  USER node                         # Switch user
  CMD [\"node\", \"index.js\"]          # Default command
  ENTRYPOINT [\"docker-entrypoint.sh\"]  # Entry point
  HEALTHCHECK CMD curl -f http://localhost/ || exit 1"

        # ── vim/neovim ───────────────────────────────────────────────────────
        case vim nvim neovim
            echo "# 📝 Neovim Cheatsheet
═══════════════════════════════════════════════════════

## 🗺️  Modes
  i / I           Insert mode (before / start of line)
  a / A           Append (after cursor / end of line)
  o / O           New line below / above
  v / V / Ctrl+v  Visual / Visual Line / Visual Block
  R               Replace mode
  :               Command mode
  Esc / Ctrl+[    Back to Normal

## 🔀 Navigation
  h j k l         Left / Down / Up / Right
  w / W           Next word start (word / WORD)
  b / B           Prev word start
  e / E           Next word end
  0 / ^           Line start / first non-blank
  \$ / g_          Line end / last non-blank
  gg / G          File start / end
  <N>G / :<N>     Go to line N
  Ctrl+d / Ctrl+u Scroll half page down / up
  Ctrl+f / Ctrl+b Scroll full page down / up
  H / M / L       Screen top / middle / bottom
  % / [{ / ]}     Match bracket / open / close
  zz / zt / zb    Center / top / bottom cursor

## ✂️  Editing
  x / X           Delete char / before cursor
  dd / D          Delete line / to end
  cc / C          Change line / to end
  yy / Y          Yank line
  p / P           Paste after / before
  u / Ctrl+r      Undo / Redo
  . (dot)         Repeat last change
  ~ / g~ / gu / gU  Toggle / change case
  >> / <<         Indent / dedent
  = / ==          Auto-indent / auto-indent line
  J               Join lines

## 🔍 Search & Replace
  /<pattern>      Search forward
  ?<pattern>      Search backward
  n / N           Next / prev match
  * / #           Search word under cursor
  :%s/foo/bar/g   Replace all in file
  :%s/foo/bar/gc  Replace with confirm
  :s/foo/bar/g    Replace in line

## 🪟 Windows & Tabs
  Ctrl+w s / v    Split horizontal / vertical
  Ctrl+w h/j/k/l  Navigate splits
  Ctrl+w H/J/K/L  Move window
  Ctrl+w =        Equal sizes
  Ctrl+w _  /  |  Max height / width
  :tabnew         New tab
  gt / gT         Next / prev tab

## 📁 Files & Buffers
  :e <file>       Open file
  :w              Save
  :wa             Save all
  :q / :qa        Quit / quit all
  :wq / :x        Save & quit
  :bn / :bp       Next / prev buffer
  :bd             Delete buffer
  :ls             List buffers

## 💡 Marks & Jumps
  ma              Set mark 'a'
  `a              Jump to mark 'a'
  Ctrl+o / Ctrl+i Jump back / forward
  gi              Go to last insert position

## 🔌 ASH Neovim Keymaps (Leader = Space)
  <leader>ff      Find files (Telescope)
  <leader>fg      Live grep
  <leader>fb      Find buffers
  <leader>fh      Help tags
  <leader>e       Toggle neo-tree
  <leader>gg      Open Lazygit
  <leader>xx      Trouble diagnostics
  <leader>ca      Code action (LSP)
  gd              Go to definition
  gr              References
  K               Hover documentation
  <leader>rn      Rename symbol
  <leader>cf      Format file
  <leader>db      Toggle breakpoint (DAP)
  <leader>dc      Continue (DAP)
  <C-\\>           Toggle terminal"

        # ── systemd ──────────────────────────────────────────────────────────
        case systemd systemctl
            echo "# ⚙️  Systemd Cheatsheet
═══════════════════════════════════════════════════════

## 🔧 Service Control
  systemctl start <unit>            # Start unit
  systemctl stop <unit>             # Stop unit
  systemctl restart <unit>          # Restart unit
  systemctl reload <unit>           # Reload config
  systemctl enable <unit>           # Enable at boot
  systemctl disable <unit>          # Disable at boot
  systemctl enable --now <unit>     # Enable & start
  systemctl disable --now <unit>    # Disable & stop
  systemctl mask <unit>             # Prevent starting
  systemctl unmask <unit>           # Unmask

## 🔍 Status & Info
  systemctl status <unit>           # Unit status
  systemctl is-active <unit>        # Is running?
  systemctl is-enabled <unit>       # Is enabled?
  systemctl list-units              # List active units
  systemctl list-units --all        # List all units
  systemctl list-unit-files         # List unit files
  systemctl list-timers             # List timers
  systemctl list-dependencies <unit># Show dependencies

## 👤 User Services (--user)
  systemctl --user start <unit>     # Start user unit
  systemctl --user enable <unit>    # Enable user unit
  systemctl --user status <unit>    # User unit status
  systemctl --user daemon-reload    # Reload user units
  systemctl --user list-units       # List user units

## 📋 Logs (journald)
  journalctl -u <unit>              # Unit logs
  journalctl -u <unit> -f           # Follow logs
  journalctl -u <unit> -n 50        # Last 50 lines
  journalctl -u <unit> --since today# Since today
  journalctl -u <unit> -p err       # Errors only
  journalctl --user -u <unit>       # User unit logs
  journalctl -b                     # Boot logs
  journalctl -b -1                  # Last boot
  journalctl --disk-usage           # Log disk usage
  journalctl --vacuum-time=7d       # Keep 7 days only
  journalctl -f                     # Follow all logs

## 🔄 Daemon & Config
  systemctl daemon-reload           # Reload unit files
  systemctl daemon-reexec           # Reexecute systemd
  systemctl reset-failed            # Reset failed state
  systemctl edit <unit>             # Edit unit (override)
  systemctl cat <unit>              # Show unit file
  systemctl show <unit>             # Show unit properties

## ⚡ Timers
  systemctl list-timers --all       # All timers
  systemd-analyze calendar 'daily'  # Test calendar expr
  systemd-run --on-calendar='*-*-* 09:00:00' <cmd>

## 🔬 Analysis
  systemd-analyze                   # Boot time
  systemd-analyze blame             # Slowest units
  systemd-analyze critical-chain    # Critical path
  systemd-analyze plot > boot.svg   # Boot graph
  systemd-analyze verify <unit>     # Verify unit

## 💡 Unit File Locations
  /etc/systemd/system/              # System units
  /usr/lib/systemd/system/          # Package units
  ~/.config/systemd/user/           # User units
  /etc/systemd/system/<unit>.d/     # Override drop-ins"

        # ── ssh ──────────────────────────────────────────────────────────────
        case ssh
            echo "# 🔐 SSH Cheatsheet
═══════════════════════════════════════════════════════

## 🔌 Connecting
  ssh user@host                     # Basic connect
  ssh user@host -p 2222             # Custom port
  ssh -i ~/.ssh/key.pem user@host   # Specific key
  ssh -A user@host                  # Agent forwarding
  ssh -X user@host                  # X11 forwarding
  ssh -v user@host                  # Verbose (debug)
  ssh -J jump@proxy user@host       # Jump host (ProxyJump)

## 🔑 Key Management
  ssh-keygen -t ed25519 -C \"email\"  # Generate ED25519 key
  ssh-keygen -t rsa -b 4096         # Generate RSA key
  ssh-copy-id user@host             # Copy public key
  ssh-copy-id -i key.pub user@host  # Copy specific key
  ssh-add ~/.ssh/key                # Add key to agent
  ssh-add -l                        # List loaded keys
  ssh-add -D                        # Remove all keys
  eval (ssh-agent -c)               # Start agent (fish)

## 📁 Config File (~/.ssh/config)
  Host myserver
      HostName 192.168.1.10
      User john
      Port 2222
      IdentityFile ~/.ssh/id_ed25519
      ForwardAgent yes
      ServerAliveInterval 60

## 🌐 Port Forwarding / Tunnels
  ssh -L 8080:localhost:80 user@host   # Local forward
  ssh -R 8080:localhost:80 user@host   # Remote forward
  ssh -D 1080 user@host                # SOCKS proxy
  ssh -N -L 5432:db:5432 user@host     # Background tunnel

## 📤 File Transfer
  scp file.txt user@host:/path/     # Upload file
  scp user@host:/path/file.txt .    # Download file
  scp -r ./dir user@host:/path/     # Upload directory
  rsync -avz ./dir user@host:/path/ # Sync with rsync
  rsync -avz --progress --delete ./dir user@host:/path/

## 🛡️  Security Hardening (sshd_config)
  PasswordAuthentication no
  PermitRootLogin no
  PubkeyAuthentication yes
  AuthorizedKeysFile .ssh/authorized_keys
  MaxAuthTries 3
  Protocol 2
  AllowUsers deploy admin

## 💡 Tips
  ssh -o StrictHostKeyChecking=no user@host  # Skip verification
  ssh-keyscan host >> ~/.ssh/known_hosts     # Add to known hosts
  ssh -o ConnectTimeout=5 user@host          # Set timeout
  ssh -q user@host 'command'                 # Quiet remote cmd
  cat ~/.ssh/id_ed25519.pub                  # Show public key"

        # ── curl ─────────────────────────────────────────────────────────────
        case curl http
            echo "# 🌐 curl Cheatsheet
═══════════════════════════════════════════════════════

## 🔍 Basic Requests
  curl <url>                        # GET request
  curl -o file.html <url>           # Save to file
  curl -O <url>                     # Save with remote filename
  curl -L <url>                     # Follow redirects
  curl -s <url>                     # Silent (no progress)
  curl -v <url>                     # Verbose (debug headers)
  curl -I <url>                     # HEAD request only
  curl -i <url>                     # Include response headers

## 📤 Sending Data
  curl -X POST <url>                # POST request
  curl -d 'key=value' <url>         # POST form data
  curl -d @file.txt <url>           # POST file contents
  curl -F 'file=@photo.jpg' <url>   # Upload file (multipart)

## 📝 JSON APIs
  curl -X POST <url> \\
      -H 'Content-Type: application/json' \\
      -d '{\"key\": \"value\"}'

  curl -X PUT <url> \\
      -H 'Authorization: Bearer TOKEN' \\
      -H 'Content-Type: application/json' \\
      -d '{\"status\": \"active\"}'

## 🔐 Authentication
  curl -u user:pass <url>           # Basic auth
  curl -H 'Authorization: Bearer TOKEN' <url>  # Bearer
  curl --cert cert.pem --key key.pem <url>      # Client cert

## ⚡ Performance & Control
  curl --max-time 10 <url>          # Timeout (seconds)
  curl --retry 3 <url>              # Retry on fail
  curl --retry-delay 2 <url>        # Delay between retries
  curl -C - -O <url>                # Resume download
  curl --limit-rate 100k <url>      # Rate limit

## 🌐 Proxy & Network
  curl -x socks5://127.0.0.1:1080 <url>  # SOCKS5 proxy
  curl -x http://proxy:8080 <url>         # HTTP proxy
  curl --interface eth0 <url>             # Specific interface
  curl -4 <url>                           # Force IPv4
  curl -6 <url>                           # Force IPv6

## 💡 Pretty JSON Output
  curl -s <url> | jq .              # With jq
  curl -s <url> | python -m json.tool  # Python fallback

## 📦 Common Patterns
  # Test REST API health
  curl -sf <url>/health && echo 'OK'

  # Download & execute installer
  curl -fsSL <url> | sh

  # POST JSON and show status code
  curl -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{}' <url>"

        # ── ripgrep ──────────────────────────────────────────────────────────
        case rg ripgrep grep
            echo "# 🔍 ripgrep (rg) Cheatsheet
═══════════════════════════════════════════════════════

## 🔍 Basic Search
  rg 'pattern'                      # Search in cwd
  rg 'pattern' path/                # Search in path
  rg 'pattern' file.txt             # Search in file
  rg -i 'pattern'                   # Case insensitive
  rg -w 'word'                      # Whole word match
  rg -l 'pattern'                   # Files with match (list only)
  rg -c 'pattern'                   # Count matches per file
  rg -n 'pattern'                   # Show line numbers
  rg -N 'pattern'                   # No line numbers

## 🔤 Regex
  rg '\d+'                          # Digits
  rg '^\s*#'                        # Lines starting with #
  rg 'foo|bar'                      # Alternation
  rg '(?i)CaSe'                     # Inline case insensitive
  rg -P 'look(?=ahead)'             # PCRE2 lookahead
  rg -F 'literal.string'            # Fixed string (no regex)

## 📁 File Control
  rg 'pattern' -g '*.ts'            # Only .ts files
  rg 'pattern' -g '!node_modules'   # Exclude dir
  rg 'pattern' -g '!*.lock'         # Exclude files
  rg 'pattern' --type ts            # By file type
  rg 'pattern' --type-not json      # Exclude type
  rg --type-list                    # List known types
  rg 'pattern' -u                   # Include .gitignore'd
  rg 'pattern' -uu                  # Include hidden
  rg 'pattern' -uuu                 # Include binary

## 📋 Output Format
  rg 'pattern' -A 3                 # 3 lines after
  rg 'pattern' -B 3                 # 3 lines before
  rg 'pattern' -C 3                 # 3 lines context
  rg 'pattern' --json               # JSON output
  rg 'pattern' -r 'replacement'     # Replace in output
  rg 'pattern' -o                   # Only matching part
  rg 'pattern' --column             # Show column number
  rg 'pattern' -H                   # Always show filename
  rg 'pattern' --no-filename        # Never show filename
  rg 'pattern' --color always | less -R  # Colored pager

## ⚡ Performance
  rg 'pattern' -j4                  # 4 worker threads
  rg 'pattern' --mmap               # Use memory maps
  rg 'pattern' -z                   # Search gzip/zip

## 💡 Real World Examples
  # Find all TODOs in code
  rg 'TODO|FIXME|HACK|NOTE' --type ts

  # Find large files referencing pattern
  rg -l 'import React' --type tsx

  # Replace across files (dry run)
  rg 'oldName' -r 'newName' -l

  # Find function definitions
  rg '^(export )?(async )?function \\w+'

  # Search in git tracked files only
  git grep -l '' | xargs rg 'pattern'"

        # ── python ───────────────────────────────────────────────────────────
        case python python3 py
            echo "# 🐍 Python Cheatsheet
═══════════════════════════════════════════════════════

## 📦 Package Management (pip / uv)
  pip install package               # Install package
  pip install -r requirements.txt   # Install from file
  pip install -e .                  # Editable install
  pip list                          # List packages
  pip freeze > requirements.txt     # Export requirements
  pip show package                  # Package info
  pip uninstall package             # Remove package

  uv venv .venv                     # Create venv (fast)
  uv pip install package            # Install (fast)
  uv pip sync requirements.txt      # Sync deps

## 🏗️  Virtual Environments
  python -m venv .venv              # Create venv
  source .venv/bin/activate.fish    # Activate (fish)
  deactivate                        # Deactivate
  which python                      # Verify venv python

## 🔧 Common Built-ins
  type(x)                           # Get type
  len(x)                            # Length
  range(start, stop, step)          # Range
  enumerate(iterable)               # Index + value
  zip(a, b)                         # Parallel iteration
  map(fn, iterable)                 # Map function
  filter(fn, iterable)              # Filter
  sorted(iterable, key=fn)          # Sort
  reversed(iterable)                # Reverse
  any(iterable) / all(iterable)     # Boolean checks
  isinstance(x, type)               # Type check

## 📝 String
  f'Hello {name}'                   # f-string
  f'{value:.2f}'                    # Format float
  f'{value:>10}'                    # Right align
  'sep'.join(['a', 'b'])            # Join
  text.split(',')                   # Split
  text.strip()                      # Strip whitespace
  text.replace('a', 'b')            # Replace
  text.startswith('foo')            # Check prefix

## 📋 List / Dict / Set
  [x*2 for x in range(10)]         # List comprehension
  {k: v for k, v in items}         # Dict comprehension
  {x for x in iterable}            # Set comprehension
  x = [*a, *b]                     # Merge lists
  d = {**d1, **d2}                  # Merge dicts

## 🚀 Async
  import asyncio
  async def main():
      result = await some_coroutine()
  asyncio.run(main())

## 🛠️  Useful Stdlib
  import os, sys, re, json, pathlib, subprocess
  from pathlib import Path
  from datetime import datetime, timedelta
  from collections import defaultdict, Counter
  from itertools import chain, product, combinations
  from functools import partial, lru_cache, reduce

## 💡 One-liners
  python -c 'import sys; print(sys.version)'
  python -m http.server 8080        # Quick HTTP server
  python -m json.tool < data.json   # Format JSON
  python -m timeit 'x = [i*2 for i in range(1000)]'"

        # ── eza / ls ─────────────────────────────────────────────────────────
        case eza ls files
            echo "# 📁 eza (ls) Cheatsheet
═══════════════════════════════════════════════════════

## 📋 Listing
  eza                               # List (default)
  eza -l                            # Long format
  eza -la                           # Long + hidden
  eza -T                            # Tree view
  eza -T -L 3                       # Tree depth 3
  eza -lT                           # Long tree
  eza -lah                          # Human-readable sizes
  eza -R                            # Recursive
  eza -1                            # One per line

## 🎨 Metadata
  eza -l --git                      # Git status column
  eza -l --git-ignore               # Ignore git ignored
  eza --icons                       # File type icons
  eza -l --extended                 # Extended attributes
  eza -l --octal-permissions        # Octal permissions
  eza --time-style iso              # ISO timestamp
  eza -l --inode                    # Show inode number
  eza -l --blocks                   # Show filesystem blocks

## 🔀 Sorting
  eza --sort name                   # By name (default)
  eza --sort size                   # By size
  eza --sort time                   # By modified time
  eza --sort ext                    # By extension
  eza -r                            # Reverse order
  eza -s size                       # Short: sort by size

## 🔍 Filtering
  eza --group-directories-first     # Dirs at top
  eza -D                            # Directories only
  eza -f                            # Files only
  eza -I '*.pyc'                    # Ignore pattern
  eza --ignore-glob '*.log|*.pyc'   # Multiple ignore

## 🔁 Aliases (ASH defaults)
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git'
  alias la='eza -la --icons --git'
  alias lt='eza -T --icons -L 2'
  alias llt='eza -lT --icons --git'
  alias lsize='eza -lah --sort size'
  alias lmod='eza -lah --sort time'"

        # ── fzf ──────────────────────────────────────────────────────────────
        case fzf
            echo "# 🔍 fzf Cheatsheet
═══════════════════════════════════════════════════════

## ⌨️  Key Bindings
  Ctrl+J / Ctrl+K   Navigate up/down
  Tab               Multi-select
  Shift+Tab         Deselect
  Ctrl+A            Select all
  Enter             Accept selection
  Ctrl+C / Esc      Cancel
  Ctrl+R            History search (fish)
  Alt+C             Directory jump (fish)
  Ctrl+T            File search (fish)

## 🔍 Query Syntax
  hello             Fuzzy match
  'hello            Exact match
  ^hello            Prefix match
  hello\$            Suffix match
  !hello            Inverse match
  !'hello           Inverse exact
  hello world       AND condition
  hello | world     OR condition

## 🎛️  Flags
  --multi / -m          Multi-select (Tab)
  --preview 'cmd {}'    Preview window
  --preview-window up   Preview position
  --header 'text'       Header text
  --prompt '❯ '         Custom prompt
  --border              Border around list
  --height 40%          Height
  --reverse             Reverse list order
  --sort / --no-sort    Enable/disable sorting
  --ansi                Parse ANSI colors
  --query 'initial'     Initial query

## 💡 Common Patterns
  # File search with preview
  fzf --preview 'bat --color=always {}'

  # Directory jump
  cd (find . -type d | fzf)

  # Kill process
  kill (ps aux | fzf | awk '{print \$2}')

  # Git checkout branch
  git checkout (git branch | fzf | string trim)

  # Edit file
  nvim (fzf --preview 'bat --color=always {}')

  # Search history
  history | fzf --tac | fish_commandline_set

## 🔧 Environment Variables
  FZF_DEFAULT_OPTS='--border --height 40% --reverse'
  FZF_DEFAULT_COMMAND='fd --type f --hidden'
  FZF_CTRL_T_COMMAND='fd --type f'
  FZF_ALT_C_COMMAND='fd --type d'"

        # ── tmux ─────────────────────────────────────────────────────────────
        case tmux
            echo "# 📺 tmux Cheatsheet (prefix = Ctrl+b)
═══════════════════════════════════════════════════════

## 🗂️  Sessions
  tmux                              # New session
  tmux new -s name                  # Named session
  tmux ls                           # List sessions
  tmux a                            # Attach last
  tmux a -t name                    # Attach by name
  tmux kill-session -t name         # Kill session
  prefix \$                          # Rename session
  prefix d                          # Detach

## 🪟 Windows (Tabs)
  prefix c                          # New window
  prefix ,                          # Rename window
  prefix w                          # List windows
  prefix n / p                      # Next / prev window
  prefix 0-9                        # Switch by number
  prefix &                          # Kill window

## ⬛ Panes (Splits)
  prefix %                          # Vertical split
  prefix \"                          # Horizontal split
  prefix arrow                      # Navigate panes
  prefix o                          # Cycle panes
  prefix q                          # Show pane numbers
  prefix x                          # Kill pane
  prefix z                          # Toggle zoom (fullscreen)
  prefix !                          # Break pane to window
  prefix Ctrl+arrow                 # Resize pane
  prefix Space                      # Cycle layouts

## 📋 Copy Mode (prefix [)
  prefix [                          # Enter copy mode
  q / Esc                           # Exit copy mode
  Space                             # Start selection
  Enter                             # Copy selection
  prefix ]                          # Paste
  /                                 # Search forward
  ?                                 # Search backward
  g / G                             # Top / bottom

## 🔧 Config & Commands
  prefix :                          # Command mode
  prefix r                          # Reload config
  tmux source ~/.config/tmux/tmux.conf  # Reload config
  tmux show-options -g              # Global options
  tmux list-keys                    # All keybindings"

        # ── kubernetes ───────────────────────────────────────────────────────
        case k8s kubernetes kubectl
            echo "# ☸️  kubectl Cheatsheet
═══════════════════════════════════════════════════════

## 🏷️  Contexts & Namespaces
  kubectl config get-contexts       # List contexts
  kubectl config use-context <ctx>  # Switch context
  kubectl config current-context    # Current context
  kubectl get ns                    # List namespaces
  kubectl config set-context --current --namespace=<ns>

## 📋 Get Resources
  kubectl get pods                  # List pods
  kubectl get pods -A               # All namespaces
  kubectl get pods -o wide          # With node/IP
  kubectl get pods -w               # Watch
  kubectl get all                   # All resources
  kubectl get events --sort-by='.lastTimestamp'
  kubectl get nodes                 # Cluster nodes
  kubectl get svc                   # Services
  kubectl get deploy                # Deployments
  kubectl get ing                   # Ingresses
  kubectl get pvc                   # Persistent volumes
  kubectl get cm                    # ConfigMaps
  kubectl get secret                # Secrets

## 🔍 Describe & Inspect
  kubectl describe pod <name>       # Detailed info
  kubectl describe node <name>      # Node details
  kubectl get pod <name> -o yaml    # YAML output
  kubectl get pod <name> -o json | jq .

## 📋 Logs
  kubectl logs <pod>                # Pod logs
  kubectl logs <pod> -f             # Follow
  kubectl logs <pod> -c <container> # Specific container
  kubectl logs <pod> --previous     # Previous container
  kubectl logs <pod> --tail=100     # Last 100 lines
  kubectl logs -l app=myapp         # By label

## 🚀 Operations
  kubectl apply -f file.yaml        # Apply manifest
  kubectl apply -f ./dir/           # Apply directory
  kubectl delete -f file.yaml       # Delete from manifest
  kubectl delete pod <name>         # Delete pod
  kubectl delete pod <name> --force # Force delete
  kubectl scale deploy <name> --replicas=3
  kubectl rollout restart deploy/<name>
  kubectl rollout status deploy/<name>
  kubectl rollout undo deploy/<name>

## 🔧 Debug
  kubectl exec -it <pod> -- bash    # Shell into pod
  kubectl exec <pod> -- ls /app     # Run command
  kubectl port-forward pod/<name> 8080:80
  kubectl port-forward svc/<name> 8080:80
  kubectl cp pod:/path ./local      # Copy from pod
  kubectl top pods                  # Resource usage
  kubectl top nodes                 # Node resources

## 🏷️  Labels & Selectors
  kubectl get pods -l app=myapp     # By label
  kubectl get pods -l 'env in (prod,staging)'
  kubectl label pod <name> env=prod # Add label
  kubectl annotate pod <name> desc='test'

## 💡 Useful Aliases (ASH)
  alias k=kubectl
  alias kgp='kubectl get pods'
  alias kgs='kubectl get svc'
  alias kgn='kubectl get nodes'
  alias kdp='kubectl describe pod'
  alias kl='kubectl logs -f'"

        # ── regex ────────────────────────────────────────────────────────────
        case regex regexp re
            echo "# 🔤 Regex Quick Reference
═══════════════════════════════════════════════════════

## 📌 Anchors
  ^         Start of string/line
  \$         End of string/line
  \\b         Word boundary
  \\B         Not word boundary
  \\A         Start of string only
  \\Z         End of string only

## 🔤 Character Classes
  .         Any char (except newline)
  \\d / \\D   Digit / Non-digit
  \\w / \\W   Word char [a-zA-Z0-9_] / Non-word
  \\s / \\S   Whitespace / Non-whitespace
  [abc]     Any of: a, b, c
  [^abc]    None of: a, b, c
  [a-z]     Range a through z
  [a-zA-Z] Letters

## 🔁 Quantifiers
  *         0 or more (greedy)
  +         1 or more (greedy)
  ?         0 or 1 (greedy)
  {3}       Exactly 3
  {3,}      3 or more
  {3,6}     Between 3 and 6
  *?        0 or more (lazy)
  +?        1 or more (lazy)

## 👁️  Groups & Lookaheads
  (abc)     Capturing group
  (?:abc)   Non-capturing group
  (?P<n>x)  Named group
  (?=abc)   Positive lookahead
  (?!abc)   Negative lookahead
  (?<=abc)  Positive lookbehind
  (?<!abc)  Negative lookbehind

## 🔄 Alternation
  cat|dog                           # cat or dog
  (cat|dog)s                        # cats or dogs

## 💡 Common Patterns
  Email:    ^[\\w.+-]+@[\\w-]+\\.[\\w.]+\$
  URL:      https?://[\\w-.]+(:\\d+)?(/\\S*)?
  IPv4:     (\\d{1,3}\\.){3}\\d{1,3}
  Phone:    [+]?[(]?\\d{3}[)]?[-\\s.]?\\d{3}[-\\s.]?\\d{4}
  Date:     \\d{4}-\\d{2}-\\d{2}
  Hex:      #[0-9a-fA-F]{3,6}
  Version:  \\d+\\.\\d+\\.\\d+
  Slug:     [a-z0-9]+(?:-[a-z0-9]+)*"

        # ── default (unknown) ─────────────────────────────────────────────────
        case '*'
            return 1
    end
    return 0
end

# ─── Fetch from cheat.sh ───────────────────────────────────────────────────────

function __cheat_fetch_web -a topic
    set -l cache_path (__cheat_cache_path $topic)

    # Check cache first
    if __cheat_cache_fresh $cache_path
        cat $cache_path
        return 0
    end

    if not command -q curl
        __cheat_err "curl required for web fetch"
        return 1
    end

    __cheat_info "Fetching from cheat.sh..."

    set -l content (curl -s \
        --max-time $__CHEAT_TIMEOUT \
        --user-agent "ash-dotfiles/5.0 (fish)" \
        "$__CHEAT_URL/$topic?style=rrt")

    if test $status -ne 0 -o -z "$content"
        __cheat_err "Failed to fetch from cheat.sh"
        return 1
    end

    # Save to cache
    echo $content > $cache_path
    echo $content
    return 0
end

# ─── Fetch from tldr ──────────────────────────────────────────────────────────

function __cheat_tldr -a topic
    if command -q tldr
        tldr $topic
        return $status
    else if command -q curl
        __cheat_info "Fetching tldr page..."
        curl -s --max-time $__CHEAT_TIMEOUT \
            "https://raw.githubusercontent.com/tldr-pages/tldr/main/pages/common/$topic.md" \
            | bat --language=md --style=full --color=always 2>/dev/null; \
            or cat
    else
        __cheat_err "tldr not installed. Install: paru -S tldr"
        return 1
    end
end

# ─── List Available Cheatsheets ────────────────────────────────────────────────

function __cheat_list
    __cheat_section "$ICO_LIST  Available Cheatsheets"
    echo ""

    set -l builtin_topics git fish docker vim nvim neovim \
        systemd systemctl ssh curl http rg ripgrep grep \
        python python3 py eza ls files fzf tmux \
        k8s kubernetes kubectl regex regexp re

    set -l unique_topics git fish docker neovim systemd ssh curl \
        ripgrep python eza fzf tmux kubectl regex

    echo $CLR_BBLUE"  $ICO_BUILTIN BUILTIN SHEETS"$CLR_RESET
    echo $CLR_DIM"  ─────────────────────────────"$CLR_RESET
    for t in $unique_topics
        printf "  $CLR_BGREEN%-20s$CLR_RESET $CLR_DIM%s$CLR_RESET\n" $t "→ cheat $t"
    end

    echo ""
    echo $CLR_BBLUE"  $ICO_USER USER SHEETS"$CLR_RESET
    echo $CLR_DIM"  ─────────────────────────────"$CLR_RESET
    if test (count $__CHEAT_USER_DIR/*.md 2>/dev/null) -gt 0
        for f in $__CHEAT_USER_DIR/*.md
            set -l name (basename $f .md)
            printf "  $CLR_BYELLOW%-20s$CLR_RESET $CLR_DIM%s$CLR_RESET\n" $name "→ cheat $name"
        end
    else
        echo $CLR_DIM"  (none — create with: cheat -e <topic>)"$CLR_RESET
    end

    echo ""
    echo $CLR_BBLUE"  $ICO_NET ONLINE (via cheat.sh)"$CLR_RESET
    echo $CLR_DIM"  Anything not found locally → fetched automatically"$CLR_RESET

    echo ""
    echo $CLR_DIM"  $ICO_TIP Run 'cheat -i' for interactive search"$CLR_RESET
    echo ""
end

# ─── Search Across Sheets ──────────────────────────────────────────────────────

function __cheat_search -a term
    if test -z "$term"
        __cheat_err "Search term required"
        return 1
    end

    __cheat_section "$ICO_SEARCH  Search: '$term'"
    echo ""

    set -l found_any 0

    # Search builtin sheets
    set -l builtin_topics git fish docker neovim systemd ssh curl ripgrep python eza fzf tmux kubectl regex

    for topic in $builtin_topics
        set -l content (__cheat_get_builtin $topic 2>/dev/null)
        if test $status -eq 0
            set -l matches (echo $content | grep -in "$term" 2>/dev/null)
            if test -n "$matches"
                echo $CLR_BYELLOW"  ◆ $topic:"$CLR_RESET
                echo $matches | head -5 | while read -l line
                    echo $CLR_DIM"    $line"$CLR_RESET
                end
                set found_any 1
            end
        end
    end

    # Search user sheets
    for f in $__CHEAT_USER_DIR/*.md 2>/dev/null
        if test -f $f
            set -l matches (grep -in "$term" $f 2>/dev/null)
            if test -n "$matches"
                set -l name (basename $f .md)
                echo $CLR_BYELLOW"  ◆ [user] $name:"$CLR_RESET
                echo $matches | head -5 | while read -l line
                    echo $CLR_DIM"    $line"$CLR_RESET
                end
                set found_any 1
            end
        end
    end

    if test $found_any -eq 0
        __cheat_warn "No matches found for '$term'"
        __cheat_tip  "Try: cheat --web $term"
    end
    echo ""
end

# ─── Interactive Mode (FZF) ────────────────────────────────────────────────────

function __cheat_interactive
    if not command -q fzf
        __cheat_err "fzf required for interactive mode"
        __cheat_tip  "Install: paru -S fzf"
        return 1
    end

    set -l topics git fish docker neovim systemd ssh curl ripgrep python eza fzf tmux kubectl regex

    # Add user sheets
    for f in $__CHEAT_USER_DIR/*.md 2>/dev/null
        if test -f $f
            set -a topics "[user] "(basename $f .md)
        end
    end

    set -l selected (printf '%s\n' $topics | fzf \
        --prompt "  📖 Cheatsheet ❯ " \
        --header "Tab to select | Enter to view | Ctrl+C to exit" \
        --preview 'ash-cheat-preview {}' \
        --preview-window 'right:60%:wrap' \
        --color 'header:italic:blue,prompt:cyan,pointer:magenta' \
        --border rounded \
        --height 80% \
        --reverse)

    if test -n "$selected"
        set -l topic (string replace -r '^\[user\] ' '' $selected)
        cheat $topic
    end
end

# ─── Edit User Sheet ──────────────────────────────────────────────────────────

function __cheat_edit -a topic
    if test -z "$topic"
        __cheat_err "Topic required"
        return 1
    end

    __cheat_ensure_dirs
    set -l sheet_path "$__CHEAT_USER_DIR/$topic.md"

    if not test -f $sheet_path
        echo "# 📖 $topic Cheatsheet" > $sheet_path
        echo "" >> $sheet_path
        echo "## Section 1" >> $sheet_path
        echo "  command                  # description" >> $sheet_path
        __cheat_info "Created new sheet: $sheet_path"
    end

    set -l editor (set -q VISUAL; and echo $VISUAL; or set -q EDITOR; and echo $EDITOR; or echo nvim)
    $editor $sheet_path

    __cheat_ok "Saved: $sheet_path"
end

# ─── Copy Sheet ───────────────────────────────────────────────────────────────

function __cheat_copy -a topic
    if test -z "$topic"
        __cheat_err "Topic required"
        return 1
    end

    set -l content (__cheat_get_builtin $topic 2>/dev/null)
    if test $status -ne 0
        # Try user sheet
        set -l sheet_path "$__CHEAT_USER_DIR/$topic.md"
        if test -f $sheet_path
            set content (cat $sheet_path)
        else
            __cheat_err "Sheet not found: $topic"
            return 1
        end
    end

    __cheat_to_clipboard $content
end

# ─── Update (pull fresh from web) ─────────────────────────────────────────────

function __cheat_update
    __cheat_section "$ICO_UPDATE  Updating Cheat Databases"
    echo ""

    # Clear old cache
    if test -d $__CHEAT_CACHE_DIR
        rm -f $__CHEAT_CACHE_DIR/*.txt
        __cheat_ok "Cleared web cache"
    end

    # Update tldr if available
    if command -q tldr
        __cheat_info "Updating tldr..."
        tldr --update
        __cheat_ok "tldr updated"
    end

    # Update cheat (the tool) if installed
    if command -q cheat
        __cheat_info "Updating cheat community sheets..."
        cheat --init 2>/dev/null; or true
        __cheat_ok "cheat updated"
    end

    __cheat_ok "Update complete"
    echo ""
end

# ─── Cache Info ───────────────────────────────────────────────────────────────

function __cheat_cache_info
    __cheat_section "$ICO_CACHE  Cache Information"
    echo ""

    if test -d $__CHEAT_CACHE_DIR
        set -l count (count $__CHEAT_CACHE_DIR/*.txt 2>/dev/null)
        set -l size (du -sh $__CHEAT_CACHE_DIR 2>/dev/null | cut -f1)
        printf "  %-20s %s\n" "Location:" $CLR_BCYAN$__CHEAT_CACHE_DIR$CLR_RESET
        printf "  %-20s %s\n" "Cached sheets:" $CLR_BGREEN"$count"$CLR_RESET
        printf "  %-20s %s\n" "Total size:" $CLR_BYELLOW"$size"$CLR_RESET
    else
        __cheat_dim "Cache empty (no web fetches yet)"
    end

    echo ""
end

# ─── Help Screen ──────────────────────────────────────────────────────────────

function __cheat_help
    __cheat_banner
    echo $CLR_BYELLOW"  USAGE"$CLR_RESET
    echo $CLR_DIM"  ─────────────────────────────────────────────"$CLR_RESET
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat <topic>" "Show cheatsheet"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -l / --list" "List available sheets"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -s / --search <term>" "Search all sheets"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -i / --interactive" "FZF picker"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -e / --edit <topic>" "Edit/create user sheet"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -c / --copy <topic>" "Copy to clipboard"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat -u / --update" "Update databases"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat --tldr <topic>" "Show tldr page"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat --man <topic>" "Man page with bat"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat --web <topic>" "Open cheat.sh in browser"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat --cache" "Cache info"
    printf "  $CLR_BGREEN%-35s$CLR_RESET %s\n" "cheat --clear-cache" "Clear web cache"
    echo ""
    echo $CLR_BYELLOW"  BUILTIN SHEETS"$CLR_RESET
    echo $CLR_DIM"  ─────────────────────────────────────────────"$CLR_RESET
    echo $CLR_DIM"  git fish docker neovim systemd ssh curl ripgrep"$CLR_RESET
    echo $CLR_DIM"  python eza fzf tmux kubectl regex"$CLR_RESET
    echo ""
    echo $CLR_BYELLOW"  EXAMPLES"$CLR_RESET
    echo $CLR_DIM"  ─────────────────────────────────────────────"$CLR_RESET
    echo $CLR_DIM"  cheat git"$CLR_RESET
    echo $CLR_DIM"  cheat -s 'port forward'"$CLR_RESET
    echo $CLR_DIM"  cheat -i"$CLR_RESET
    echo $CLR_DIM"  cheat --tldr tar"$CLR_RESET
    echo $CLR_DIM"  cheat --web python/list-comprehension"$CLR_RESET
    echo ""
end

# ═══════════════════════════════════════════════════════════════════════════════
# ─── MAIN FUNCTION ─────────────────────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════

function cheat
    __cheat_ensure_dirs

    # ── No args ───────────────────────────────────────────────────────────────
    if test (count $argv) -eq 0
        __cheat_help
        return 0
    end

    # ── Parse flags ───────────────────────────────────────────────────────────
    switch $argv[1]

        case -h --help
            __cheat_help

        case -l --list
            __cheat_list

        case -s --search
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --search <term>"
                return 1
            end
            __cheat_search $argv[2]

        case -i --interactive
            __cheat_interactive

        case -e --edit
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --edit <topic>"
                return 1
            end
            __cheat_edit $argv[2]

        case -c --copy
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --copy <topic>"
                return 1
            end
            __cheat_copy $argv[2]

        case -u --update
            __cheat_update

        case --tldr
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --tldr <topic>"
                return 1
            end
            __cheat_tldr $argv[2]

        case --man
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --man <topic>"
                return 1
            end
            if command -q bat
                man $argv[2] | bat --style=plain --paging=always
            else
                man $argv[2]
            end

        case --web
            if test (count $argv) -lt 2
                __cheat_err "Usage: cheat --web <topic>"
                return 1
            end
            set -l url "$__CHEAT_URL/$argv[2]"
            if command -q xdg-open
                xdg-open $url
            else
                echo $CLR_BCYAN"  🌐 $url"$CLR_RESET
            end

        case --cache
            __cheat_cache_info

        case --clear-cache
            rm -f $__CHEAT_CACHE_DIR/*.txt
            __cheat_ok "Cache cleared"

        case --version
            echo $CLR_BCYAN"  📖 ASH Cheat v$__CHEAT_VERSION"$CLR_RESET

        case '*'
            set -l topic $argv[1]

            # 1. Try user sheet
            set -l user_sheet "$__CHEAT_USER_DIR/$topic.md"
            if test -f $user_sheet
                echo ""
                echo $CLR_BBLUE"  $ICO_USER User Sheet: $topic"$CLR_RESET
                echo $CLR_DIM"  ─────────────────────────────"$CLR_RESET
                __cheat_pager $user_sheet
                return 0
            end

            # 2. Try builtin
            set -l builtin_content (__cheat_get_builtin $topic 2>/dev/null)
            if test $status -eq 0
                echo ""
                echo $CLR_BBLUE"  $ICO_BUILTIN Built-in: $topic"$CLR_RESET
                echo $CLR_DIM"  ─────────────────────────────"$CLR_RESET
                echo $builtin_content | bat \
                    --style=plain \
                    --color=always \
                    --paging=auto \
                    --language=md \
                    --theme="$(set -q BAT_THEME; and echo $BAT_THEME; or echo 'TwoDark')" 2>/dev/null
                    or echo $builtin_content | less -R
                return 0
            end

            # 3. Try installed cheat tool
            if command -q cheat
                cheat $topic
                return $status
            end

            # 4. Try tldr as fallback
            if command -q tldr
                __cheat_info "Not found locally → trying tldr..."
                tldr $topic
                and return 0
            end

            # 5. Fetch from web
            __cheat_info "Not found locally → fetching from cheat.sh..."
            set -l web_content (__cheat_fetch_web $topic)
            if test $status -eq 0 -a -n "$web_content"
                echo ""
                echo $CLR_BBLUE"  $ICO_NET Web: $topic (cheat.sh)"$CLR_RESET
                echo $CLR_DIM"  ─────────────────────────────"$CLR_RESET
                echo $web_content | bat \
                    --style=plain \
                    --color=always \
                    --paging=auto \
                    --theme="$(set -q BAT_THEME; and echo $BAT_THEME; or echo 'TwoDark')" 2>/dev/null
                    or echo $web_content | less -R
                return 0
            end

            __cheat_err "No cheatsheet found for: '$topic'"
            __cheat_tip  "Available: cheat --list"
            __cheat_tip  "Online:    cheat --web $topic"
            __cheat_tip  "Create:    cheat --edit $topic"
            return 1
    end
end
