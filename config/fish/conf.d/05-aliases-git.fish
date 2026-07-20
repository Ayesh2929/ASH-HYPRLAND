#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██╗████████╗     █████╗ ██╗     ██╗ █████╗ ███████╗███████╗███████╗  ║
# ║  ██╔════╝ ██║╚══██╔══╝    ██╔══██╗██║     ██║██╔══██╗██╔════╝██╔════╝██╔════╝  ║
# ║  ██║  ███╗██║   ██║       ███████║██║     ██║███████║███████╗█████╗  ███████╗  ║
# ║  ██║   ██║██║   ██║       ██╔══██║██║     ██║██╔══██║╚════██║██╔══╝  ╚════██║  ║
# ║  ╚██████╔╝██║   ██║       ██║  ██║███████╗██║██║  ██║███████║███████╗███████║  ║
# ║   ╚═════╝ ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝  ║
# ║                                                                                  ║
# ║   🌿 GIT ALIASES — ASH Dotfiles v5.0 OMEGA                                     ║
# ║   Complete Git workflow • Conventional commits • Advanced operations             ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_aliases_git_initialized && exit 0
set -g __ash_aliases_git_initialized 1

# Bail if git isn't installed
command -sq git || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔤 CORE SHORTCUTS — Single-letter + common combos
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias g       "git"
alias gs      "git status \
                 --short \
                 --branch"
alias gss     "git status"                          # Full status
alias gd      "git diff"
alias gds     "git diff \
                 --staged"
alias gdw     "git diff \
                 --word-diff"                       # Word-level diff
alias gdt     "git diff \
                 --stat"                            # Diff summary
alias gdc     "git diff \
                 --cached"                          # Staged diff (alias)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ➕ STAGING — Add, restore, reset
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias ga      "git add"
alias gaa     "git add \
                 --all"
alias gap     "git add \
                 --patch"                           # Interactive staging
alias gai     "git add \
                 --interactive"                     # Full interactive mode
alias gau     "git add \
                 --update"                          # Stage modified/deleted only
alias gan     "git add \
                 --intent-to-add"                   # Mark untracked for tracking

alias grs     "git restore"
alias grss    "git restore \
                 --staged"                          # Unstage
alias grsa    "git restore \
                 --staged \
                 --worktree"                        # Unstage + discard

alias grh     "git reset HEAD"
alias grhh    "git reset HEAD \
                 --hard"                            # Hard reset to HEAD
alias grhs    "git reset HEAD \
                 --soft"                            # Soft reset to HEAD
alias grhm    "git reset HEAD \
                 --mixed"                           # Mixed reset (default)

alias gcp     "git checkout \
                 --patch"                           # Interactive checkout


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 COMMIT — Standard + Conventional Commits
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gc      "git commit \
                 --verbose"
alias gcm     "git commit \
                 --message"
alias gca     "git commit \
                 --all \
                 --verbose"
alias gcam    "git commit \
                 --all \
                 --message"
alias gcamn   "git commit \
                 --all \
                 --message \
                 --no-verify"                       # Skip hooks
alias gcane   "git commit \
                 --amend \
                 --no-edit"                         # Amend without editing msg
alias gcaane  "git commit \
                 --all \
                 --amend \
                 --no-edit"                         # Amend all without editing
alias gcam!   "git commit \
                 --amend"                           # Amend with edit
alias gcf     "git commit \
                 --fixup"                           # Fixup commit for rebase
alias gcs     "git commit \
                 --squash"                          # Squash commit for rebase
alias gcwip   "git commit \
                 --all \
                 --message='🚧 WIP: work in progress [skip ci]'"
alias gcundo  "git reset HEAD~1 \
                 --soft"                            # Undo last commit (keep changes)

# ── Conventional Commits shortcuts ────────────────────────────────────────────
# Format: <type>(<scope>): <description>
alias gcfeat  "git commit \
                 --message 'feat: '"
alias gcfix   "git commit \
                 --message 'fix: '"
alias gcdocs  "git commit \
                 --message 'docs: '"
alias gcstyle "git commit \
                 --message 'style: '"
alias gcref   "git commit \
                 --message 'refactor: '"
alias gcperf  "git commit \
                 --message 'perf: '"
alias gctest  "git commit \
                 --message 'test: '"
alias gcbuild "git commit \
                 --message 'build: '"
alias gcci    "git commit \
                 --message 'ci: '"
alias gcchore "git commit \
                 --message 'chore: '"
alias gcrev   "git commit \
                 --message 'revert: '"
alias gcsec   "git commit \
                 --message 'security: '"
alias gcbreak "git commit \
                 --message 'feat!: '"              # Breaking change


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌿 BRANCH — Create, switch, delete, list
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gb      "git branch"
alias gba     "git branch \
                 --all \
                 --verbose \
                 --verbose"                         # Verbose: shows remote & upstream
alias gbd     "git branch \
                 --delete"
alias gbD     "git branch \
                 --delete \
                 --force"
alias gbm     "git branch \
                 --move"                            # Rename branch
alias gbcopy  "git branch \
                 --copy"                            # Copy branch
alias gbl     "git branch \
                 --list \
                 --verbose"
alias gbr     "git branch \
                 --remote \
                 --verbose"                         # Remote branches only
alias gbset   "git branch \
                 --set-upstream-to"                 # Set upstream tracking
alias gbunset "git branch \
                 --unset-upstream"

# Switch
alias gsw     "git switch"
alias gswc    "git switch \
                 --create"                          # Create + switch
alias gswm    "git switch main 2>/dev/null || git switch master"
alias gswd    "git switch dev 2>/dev/null || git switch develop"
alias gswp    "git switch -"                        # Previous branch

# Checkout (legacy but still useful)
alias gco     "git checkout"
alias gcob    "git checkout \
                 -b"                                # Create + checkout
alias gcom    "git checkout main 2>/dev/null || git checkout master"
alias gcod    "git checkout dev 2>/dev/null || git checkout develop"
alias gcop    "git checkout -"                      # Previous branch


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔀 MERGE, REBASE & CHERRY-PICK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Merge
alias gm      "git merge"
alias gmom    "git merge origin/main"
alias gmod    "git merge origin/dev"
alias gmnf    "git merge \
                 --no-ff"                           # Always create merge commit
alias gmff    "git merge \
                 --ff-only"                         # Fast-forward only
alias gmsq    "git merge \
                 --squash"                          # Squash merge
alias gmabort "git merge \
                 --abort"
alias gmcont  "git merge \
                 --continue"

# Rebase
alias grb     "git rebase"
alias grbi    "git rebase \
                 --interactive"
alias grbm    "git rebase main"
alias grbd    "git rebase dev"
alias grbom   "git rebase origin/main"
alias grbabort "git rebase \
                  --abort"
alias grbcont "git rebase \
                 --continue"
alias grbskip "git rebase \
                 --skip"
alias grbedit "git rebase \
                 --edit-todo"                       # Edit rebase todo

# Autosquash (use with gcf/gcs commits)
alias grbias  "GIT_SEQUENCE_EDITOR=: git rebase \
                 --interactive \
                 --autosquash"

# Cherry-pick
alias gcpc    "git cherry-pick"
alias gcpca   "git cherry-pick \
                 --abort"
alias gcpcc   "git cherry-pick \
                 --continue"
alias gcpcn   "git cherry-pick \
                 --no-commit"                       # Cherry-pick without commit


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📡 REMOTE — Fetch, pull, push
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Fetch
alias gf      "git fetch \
                 --all \
                 --prune \
                 --prune-tags"
alias gfo     "git fetch origin"
alias gfu     "git fetch upstream"

# Pull
alias gl      "git pull"
alias glom    "git pull origin main"
alias glod    "git pull origin dev"
alias glr     "git pull \
                 --rebase"                          # Pull with rebase
alias glra    "git pull \
                 --rebase \
                 --autostash"                       # Auto-stash before pull
alias glu     "git pull upstream"
alias glum    "git pull upstream main"

# Push
alias gp      "git push"
alias gpf     "git push \
                 --force-with-lease"                # Safe force push
alias gpF     "git push \
                 --force"                           # Dangerous force push
alias gpo     "git push origin"
alias gpom    "git push origin main"
alias gpsup   "git push \
                 --set-upstream origin \
                 (git branch --show-current)"       # Push + set upstream
alias gpd     "git push \
                 --delete origin"                   # Delete remote branch
alias gpt     "git push \
                 --tags"                            # Push all tags
alias gpnt    "git push \
                 --no-tags"                         # Push without tags

# Remote management
alias gr      "git remote"
alias gra     "git remote add"
alias grv     "git remote \
                 --verbose"
alias grrm    "git remote remove"
alias grrn    "git remote rename"
alias grset   "git remote set-url"
alias grup    "git remote update \
                 --prune"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 STASH — Save and restore work in progress
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gst     "git stash \
                 push"
alias gstm    "git stash \
                 push \
                 --message"                         # Stash with message
alias gstu    "git stash \
                 push \
                 --include-untracked"               # Include untracked
alias gsta    "git stash \
                 push \
                 --all"                             # Include ignored files too
alias gstp    "git stash \
                 pop"
alias gstap   "git stash \
                 apply"                             # Apply without removing
alias gstd    "git stash \
                 drop"
alias gstl    "git stash \
                 list"
alias gsts    "git stash \
                 show \
                 --patch"                           # Show stash diff
alias gstc    "git stash \
                 clear"                             # Remove all stashes
alias gstb    "git stash branch"                   # Create branch from stash


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏷️  TAGS — Version tagging
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gt      "git tag"
alias gta     "git tag \
                 --annotate"                        # Annotated tag
alias gts     "git tag \
                 --sign"                            # Signed tag
alias gtl     "git tag \
                 --list \
                 --sort=-version:refname"           # List tags sorted by version
alias gtd     "git tag \
                 --delete"
alias gtrd    "git push origin \
                 --delete"                          # Delete remote tag
alias gtp     "git push origin \
                 --tags"                            # Push all tags
alias gtpt    "git push origin"                     # Push specific tag
alias gtv     "git tag \
                 | sort \
                 --version-sort"                    # Version-sorted tags


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📜 LOG — Beautiful git history
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Default: pretty one-line graph
alias glog    "git log \
                 --oneline \
                 --decorate \
                 --graph \
                 --all"

# Full log with stats
alias glogs   "git log \
                 --stat \
                 --decorate \
                 --graph"

# Detailed log with patch
alias glogp   "git log \
                 --patch \
                 --decorate"

# Author-filtered log
alias gloga   "git log \
                 --oneline \
                 --decorate \
                 --graph \
                 --all \
                 --author"

# Recent commits (last 10)
alias glr10   "git log \
                 --oneline \
                 --decorate \
                 -10"

# File history
alias glogf   "git log \
                 --follow \
                 --patch"                           # Single file history

# Fancy log (uses git-extras if available)
alias glogg   "git log \
                 --graph \
                 --pretty=format:'%C(bold red)%h%C(reset) %C(bold yellow)%d%C(reset) %s %C(bold green)(%cr)%C(reset) %C(cyan)<%an>%C(reset)' \
                 --abbrev-commit \
                 --all"

# Contributors
alias gcontrib "git shortlog \
                  --summary \
                  --numbered \
                  --email"

# Blame with ignore whitespace
alias gblame  "git blame \
                 --show-email \
                 --ignore-whitespace"

# What changed since tag
alias gchanged "git log \
                  --oneline \
                  (git describe --tags --abbrev=0)..HEAD"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔎 SEARCH — Find commits, strings, files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gg      "git grep \
                 --line-number \
                 --heading \
                 --break"
alias ggg     "git grep \
                 --line-number \
                 --heading \
                 --break \
                 --ignore-case"
alias gfind   "git log \
                 --all \
                 --full-history \
                 --"                                # Find file in history
alias gpickaxe "git log \
                  --all \
                  --oneline \
                  --pickaxe-all \
                  -S"                               # Find string in history
alias gbisect "git bisect"
alias gbstart "git bisect start"
alias gbgood  "git bisect good"
alias gbbad   "git bisect bad"
alias gbreset "git bisect reset"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 REPOSITORY — Init, clone, worktree
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias ginit   "git init"
alias ginitm  "git init \
                 --initial-branch=main"             # init with main branch

alias gcl     "git clone \
                 --recurse-submodules \
                 --jobs=4"
alias gcls    "git clone \
                 --depth=1"                         # Shallow clone
alias gclb    "git clone \
                 --single-branch \
                 --branch"                          # Clone specific branch

# Worktrees
alias gwt     "git worktree"
alias gwta    "git worktree add"
alias gwtl    "git worktree list"
alias gwtrm   "git worktree remove"
alias gwtpr   "git worktree prune"

# Submodules
alias gsub    "git submodule"
alias gsubi   "git submodule \
                 update \
                 --init \
                 --recursive"
alias gsubup  "git submodule \
                 update \
                 --remote \
                 --recursive"
alias gsubst  "git submodule \
                 status"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 MAINTENANCE & CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gclean  "git clean \
                 --dry-run"                         # Preview clean
alias gcleanf "git clean \
                 --force \
                 --directories \
                 --exclude=.env"                    # Clean untracked (keep .env)
alias gcleanx "git clean \
                 --force \
                 --directories \
                 --exclude=.env \
                 -x"                                # Also clean ignored files

alias ggc     "git gc \
                 --aggressive \
                 --prune=now"                       # Garbage collect + prune
alias gprune  "git remote prune origin"             # Prune stale remote refs
alias gfetch-prune "git fetch \
                      --all \
                      --prune \
                      --prune-tags"

# Count objects
alias gcount  "git count-objects \
                 --human-readable \
                 --verbose"

# File tracking
alias gtrack  "git ls-files"
alias guntrack "git rm \
                  --cached"                         # Stop tracking (keep file)
alias gignored "git ls-files \
                  --ignored \
                  --exclude-standard \
                  --others"                         # Show ignored files


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 INFO & INSPECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias ginfo   "git remote show origin"
alias gurl    "git remote get-url origin"
alias gbranch "git branch \
                 --show-current"                    # Current branch name only
alias ghead   "git rev-parse HEAD"                  # Current commit hash
alias gheads  "git rev-parse --short HEAD"          # Short hash
alias gdesc   "git describe \
                 --tags \
                 --long"                            # Human-readable version
alias groot   "cd (git rev-parse --show-toplevel)"  # cd to repo root
alias gdir    "git rev-parse \
                 --show-toplevel"                   # Print repo root
alias gconfig "git config \
                 --list \
                 --show-origin"                     # All git config with source

# Show file at specific commit
alias gshow   "git show"
alias gshowo  "git show \
                 --name-only"                       # Files changed in commit

# Reflog
alias grl     "git reflog \
                 --date=relative"
alias grla    "git reflog \
                 --all \
                 --date=relative"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔏 SIGNING & SECURITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gcms    "git commit \
                 --gpg-sign \
                 --verbose \
                 --message"                         # GPG signed commit
alias gverify "git verify-commit HEAD"              # Verify GPG signature
alias gverifyt "git verify-tag"                     # Verify tag signature


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤝 GITHUB CLI INTEGRATION — gh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq gh
    alias ghpr    "gh pr create \
                     --web"                         # Create PR in browser
    alias ghprl   "gh pr list"
    alias ghprv   "gh pr view \
                     --web"
    alias ghprc   "gh pr checkout"
    alias ghprs   "gh pr status"
    alias ghprrv  "gh pr review"
    alias ghprm   "gh pr merge"
    alias ghiss   "gh issue create \
                     --web"
    alias ghissl  "gh issue list"
    alias ghissv  "gh issue view \
                     --web"
    alias ghrepo  "gh repo view \
                     --web"
    alias ghfork  "gh repo fork \
                     --clone"
    alias ghrun   "gh run list"
    alias ghrunw  "gh run watch"
    alias ghact   "gh actions"
    alias ghnot   "gh notification list"
    alias ghrel   "gh release create"
    alias ghrell  "gh release list"
end