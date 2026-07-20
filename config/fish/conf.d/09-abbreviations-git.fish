#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██╗████████╗     █████╗ ██████╗ ██████╗ ██████╗ ███████╗██╗   ██╗   ║
# ║  ██╔════╝ ██║╚══██╔══╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██║   ██║   ║
# ║  ██║  ███╗██║   ██║       ███████║██████╔╝██████╔╝██████╔╝█████╗  ██║   ██║   ║
# ║  ██║   ██║██║   ██║       ██╔══██║██╔══██╗██╔══██╗██╔══██╗██╔══╝  ╚██╗ ██╔╝   ║
# ║  ╚██████╔╝██║   ██║       ██║  ██║██████╔╝██████╔╝██║  ██║███████╗ ╚████╔╝    ║
# ║   ╚═════╝ ╚═╝   ╚═╝       ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝  ╚═══╝    ║
# ║                                                                                  ║
# ║   🌿 GIT ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                               ║
# ║   Expand-in-place • Visible in history • Discoverable • Memorable               ║
# ║                                                                                  ║
# ║   ℹ️  Abbreviations expand when you press SPACE or ENTER                        ║
# ║   ℹ️  They appear EXPANDED in history — unlike aliases                          ║
# ║   ℹ️  Use abbr -s to list all current abbreviations                             ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_git_initialized && exit 0
set -g __ash_abbr_git_initialized 1

command -sq git || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔤 ROOT — The git command itself
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a g    "git"
abbr -a gi   "git init"
abbr -a gini "git init --initial-branch=main"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 STATUS — Repository state
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gs    "git status --short --branch"
abbr -a gss   "git status"
abbr -a gsv   "git status --verbose"
abbr -a gsu   "git status --short --branch --untracked-files=all"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ➕ STAGING — Add files to index
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a ga    "git add"
abbr -a gaa   "git add --all"
abbr -a gap   "git add --patch"
abbr -a gai   "git add --interactive"
abbr -a gau   "git add --update"
abbr -a gan   "git add --intent-to-add"
abbr -a gad   "git add ."

# ── Restore / unstage ─────────────────────────────────────────────────────────
abbr -a grs   "git restore"
abbr -a grss  "git restore --staged"
abbr -a grsa  "git restore --staged --worktree ."
abbr -a grh   "git reset HEAD"
abbr -a grhh  "git reset HEAD --hard"
abbr -a grhm  "git reset HEAD --mixed"
abbr -a grhs  "git reset HEAD --soft"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 💾 COMMIT — Create commits
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gc    "git commit --verbose"
abbr -a gcm   "git commit --message"
abbr -a gca   "git commit --all --verbose"
abbr -a gcam  "git commit --all --message"
abbr -a gcamn "git commit --all --message --no-verify"
abbr -a gce   "git commit --allow-empty --message"

# ── Amend ─────────────────────────────────────────────────────────────────────
abbr -a gcane "git commit --amend --no-edit"
abbr -a gcaane "git commit --all --amend --no-edit"
abbr -a gcam! "git commit --amend"
abbr -a gcan! "git commit --amend --no-edit --no-verify"

# ── Fixup / Squash ────────────────────────────────────────────────────────────
abbr -a gcf   "git commit --fixup"
abbr -a gcs   "git commit --squash"

# ── WIP commit ────────────────────────────────────────────────────────────────
abbr -a gcwip "git commit --all --message='🚧 WIP: work in progress [skip ci]'"
abbr -a gcundo "git reset HEAD~1 --soft"

# ── Conventional Commits ──────────────────────────────────────────────────────
abbr -a gcfeat  "git commit --message 'feat: '"
abbr -a gcfix   "git commit --message 'fix: '"
abbr -a gcdocs  "git commit --message 'docs: '"
abbr -a gcstyle "git commit --message 'style: '"
abbr -a gcref   "git commit --message 'refactor: '"
abbr -a gcperf  "git commit --message 'perf: '"
abbr -a gctest  "git commit --message 'test: '"
abbr -a gcbuild "git commit --message 'build: '"
abbr -a gcci    "git commit --message 'ci: '"
abbr -a gcchore "git commit --message 'chore: '"
abbr -a gcrev   "git commit --message 'revert: '"
abbr -a gcsec   "git commit --message 'security: '"
abbr -a gcbreak "git commit --message 'feat!: BREAKING CHANGE: '"
abbr -a gctyp   "git commit --message 'typo: '"
abbr -a gcdep   "git commit --message 'deps: bump '"
abbr -a gcrel   "git commit --message 'release: v'"
abbr -a gcmig   "git commit --message 'migration: '"
abbr -a gcconf  "git commit --message 'config: '"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌿 BRANCH — Create, switch, delete
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gb    "git branch"
abbr -a gba   "git branch --all --verbose --verbose"
abbr -a gbd   "git branch --delete"
abbr -a gbD   "git branch --delete --force"
abbr -a gbm   "git branch --move"
abbr -a gbr   "git branch --remote --verbose"
abbr -a gbl   "git branch --list --verbose"

# ── Switch (modern) ───────────────────────────────────────────────────────────
abbr -a gsw   "git switch"
abbr -a gswc  "git switch --create"
abbr -a gswm  "git switch main"
abbr -a gswd  "git switch dev"
abbr -a gswp  "git switch -"
abbr -a gswu  "git switch --guess"

# ── Checkout (classic) ────────────────────────────────────────────────────────
abbr -a gco   "git checkout"
abbr -a gcob  "git checkout -b"
abbr -a gcom  "git checkout main"
abbr -a gcod  "git checkout dev"
abbr -a gcop  "git checkout -"
abbr -a gcoB  "git checkout -B"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔀 MERGE — Integrate branches
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gm    "git merge"
abbr -a gmom  "git merge origin/main"
abbr -a gmod  "git merge origin/dev"
abbr -a gmnf  "git merge --no-ff"
abbr -a gmff  "git merge --ff-only"
abbr -a gmsq  "git merge --squash"
abbr -a gmab  "git merge --abort"
abbr -a gmco  "git merge --continue"
abbr -a gmom! "git merge origin/main --no-ff --no-edit"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔄 REBASE — Linear history
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a grb   "git rebase"
abbr -a grbi  "git rebase --interactive"
abbr -a grbm  "git rebase main"
abbr -a grbd  "git rebase dev"
abbr -a grbom "git rebase origin/main"
abbr -a grbab "git rebase --abort"
abbr -a grbco "git rebase --continue"
abbr -a grbsk "git rebase --skip"
abbr -a grbas "GIT_SEQUENCE_EDITOR=: git rebase --interactive --autosquash"
abbr -a grbot "git rebase --onto"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🍒 CHERRY-PICK — Apply specific commits
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gcp   "git cherry-pick"
abbr -a gcpn  "git cherry-pick --no-commit"
abbr -a gcpa  "git cherry-pick --abort"
abbr -a gcpc  "git cherry-pick --continue"
abbr -a gcpe  "git cherry-pick --edit"
abbr -a gcps  "git cherry-pick --signoff"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📡 REMOTE — Sync with remotes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Fetch ─────────────────────────────────────────────────────────────────────
abbr -a gf    "git fetch --all --prune --prune-tags"
abbr -a gfo   "git fetch origin"
abbr -a gfu   "git fetch upstream"
abbr -a gfom  "git fetch origin main"

# ── Pull ──────────────────────────────────────────────────────────────────────
abbr -a gl    "git pull"
abbr -a glom  "git pull origin main"
abbr -a glod  "git pull origin dev"
abbr -a glr   "git pull --rebase"
abbr -a glra  "git pull --rebase --autostash"
abbr -a glu   "git pull upstream"
abbr -a glum  "git pull upstream main"
abbr -a glff  "git pull --ff-only"

# ── Push ──────────────────────────────────────────────────────────────────────
abbr -a gp    "git push"
abbr -a gpf   "git push --force-with-lease"
abbr -a gpF   "git push --force"
abbr -a gpo   "git push origin"
abbr -a gpom  "git push origin main"
abbr -a gpsup "git push --set-upstream origin (git branch --show-current)"
abbr -a gpd   "git push --delete origin"
abbr -a gpt   "git push --tags"
abbr -a gpnt  "git push --no-tags"
abbr -a gpa   "git push --all"

# ── Remote management ─────────────────────────────────────────────────────────
abbr -a gr    "git remote"
abbr -a grv   "git remote --verbose"
abbr -a gra   "git remote add"
abbr -a grao  "git remote add origin"
abbr -a grau  "git remote add upstream"
abbr -a grrm  "git remote remove"
abbr -a grrn  "git remote rename"
abbr -a grset "git remote set-url"
abbr -a grup  "git remote update --prune"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 STASH — Temporary work storage
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gst   "git stash push"
abbr -a gstm  "git stash push --message"
abbr -a gstu  "git stash push --include-untracked"
abbr -a gsta  "git stash push --all"
abbr -a gstp  "git stash pop"
abbr -a gstap "git stash apply"
abbr -a gstd  "git stash drop"
abbr -a gstl  "git stash list"
abbr -a gsts  "git stash show --patch"
abbr -a gstc  "git stash clear"
abbr -a gstb  "git stash branch"
abbr -a gst0  "git stash show --patch stash@{0}"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏷️  TAGS — Version marking
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gt    "git tag"
abbr -a gta   "git tag --annotate"
abbr -a gts   "git tag --sign"
abbr -a gtl   "git tag --list --sort=-version:refname"
abbr -a gtd   "git tag --delete"
abbr -a gtp   "git push origin --tags"
abbr -a gtlv  "git tag --list --sort=-version:refname | head -10"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📜 LOG — View history
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a glog  "git log --oneline --decorate --graph --all"
abbr -a glogs "git log --stat --decorate --graph"
abbr -a glogp "git log --patch --decorate"
abbr -a glogf "git log --follow --patch"
abbr -a glog1 "git log --oneline --decorate -1"
abbr -a glog5 "git log --oneline --decorate -5"
abbr -a glog10 "git log --oneline --decorate -10"
abbr -a glogm "git log --oneline --decorate --graph --all --author=(git config user.email)"
abbr -a glogd "git log --oneline --decorate --graph --all --since='1 day ago'"
abbr -a glogw "git log --oneline --decorate --graph --all --since='1 week ago'"

# ── Diff ──────────────────────────────────────────────────────────────────────
abbr -a gd    "git diff"
abbr -a gds   "git diff --staged"
abbr -a gdw   "git diff --word-diff"
abbr -a gdt   "git diff --stat"
abbr -a gdm   "git diff main"
abbr -a gdom  "git diff origin/main"

# ── Blame ─────────────────────────────────────────────────────────────────────
abbr -a gbl   "git blame --show-email --ignore-whitespace"

# ── Show ──────────────────────────────────────────────────────────────────────
abbr -a gshow  "git show"
abbr -a gshown "git show --name-only"
abbr -a gshows "git show --stat"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 SEARCH — Find content in history
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gg    "git grep --line-number --heading --break"
abbr -a ggg   "git grep --line-number --heading --break --ignore-case"
abbr -a gbis  "git bisect"
abbr -a gbisg "git bisect good"
abbr -a gbisb "git bisect bad"
abbr -a gbisr "git bisect reset"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 REPOSITORY — Init, clone, worktree
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a gcl   "git clone --recurse-submodules --jobs=4"
abbr -a gcls  "git clone --depth=1"
abbr -a gclb  "git clone --single-branch --branch"

# ── Worktrees ─────────────────────────────────────────────────────────────────
abbr -a gwt   "git worktree"
abbr -a gwta  "git worktree add"
abbr -a gwtl  "git worktree list"
abbr -a gwtrm "git worktree remove"

# ── Submodules ────────────────────────────────────────────────────────────────
abbr -a gsub  "git submodule update --init --recursive"
abbr -a gsubu "git submodule update --remote --recursive"
abbr -a gsubs "git submodule status"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 MAINTENANCE — Cleanup & optimization
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
abbr -a ggc   "git gc --aggressive --prune=now"
abbr -a gprune "git remote prune origin"
abbr -a gclean "git clean --dry-run"
abbr -a gcleanf "git clean --force --directories"
abbr -a guntrack "git rm --cached"
abbr -a grl   "git reflog --date=relative"

# ── Info ──────────────────────────────────────────────────────────────────────
abbr -a ginfo  "git remote show origin"
abbr -a gbranch "git branch --show-current"
abbr -a ghead  "git rev-parse HEAD"
abbr -a gheads "git rev-parse --short HEAD"
abbr -a gdesc  "git describe --tags --long"
abbr -a gdir   "git rev-parse --show-toplevel"
abbr -a gcfg   "git config --list --show-origin"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🤝 GITHUB CLI — gh abbreviations
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq gh
    abbr -a ghpr   "gh pr create --web"
    abbr -a ghprl  "gh pr list"
    abbr -a ghprv  "gh pr view --web"
    abbr -a ghprc  "gh pr checkout"
    abbr -a ghprs  "gh pr status"
    abbr -a ghprm  "gh pr merge"
    abbr -a ghiss  "gh issue create --web"
    abbr -a ghissl "gh issue list"
    abbr -a ghissv "gh issue view --web"
    abbr -a ghrepo "gh repo view --web"
    abbr -a ghfork "gh repo fork --clone"
    abbr -a ghrun  "gh run list"
    abbr -a ghrunw "gh run watch"
    abbr -a ghnot  "gh notification list"
    abbr -a ghrel  "gh release create"
    abbr -a ghrell "gh release list"
    abbr -a ghgist "gh gist create"
    abbr -a ghclone "gh repo clone"
end