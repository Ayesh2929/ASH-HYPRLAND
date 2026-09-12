#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║   ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗                   ║
# ║  ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║                   ║
# ║  ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████║██║                   ║
# ║  ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║                   ║
# ║  ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗              ║
# ║   ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝              ║
# ║                                                                                  ║
# ║  ████████╗ ██████╗  ██████╗ ██╗     ███████╗                                    ║
# ║  ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝                                    ║
# ║     ██║   ██║   ██║██║   ██║██║     ███████╗                                    ║
# ║     ██║   ██║   ██║██║   ██║██║     ╚════██║                                    ║
# ║     ██║   ╚██████╔╝╚██████╔╝███████╗███████║                                    ║
# ║     ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝                                    ║
# ║                                                                                  ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  ASH CLI v5.0 OMEGA  ─  DOCTOR CHECK: OPTIONAL TOOLS                            ║
# ║  Nice-to-have utilities that enhance the ASH experience                         ║
# ║                                                                                  ║
# ║  Author    : ash-dotfiles                                                        ║
# ║  License   : MIT                                                                 ║
# ║  Sections  : productivity • ai/ml • cloud • monitoring • creative • misc        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_CHECK_TOOLS_OPTIONAL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_CHECK_TOOLS_OPTIONAL_LOADED=1

# Sourced as a library by _common.sh, so shell options are only
# tightened when this file is EXECUTED directly. A sourced file that
# sets -e/-u rewrites the options of whoever loaded it — the first
# module would make the whole doctor process abort on any non-zero
# status or unset variable.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  INTERNAL COUNTERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g  _OPT_INSTALLED=0
declare -g  _OPT_MISSING=0
declare -ga _OPT_SUGGESTIONS=()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  PROBE HELPER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# _probe_opt binary display package ver_flag description
_probe_opt() {
    local binary="$1"
    local display="${2:-$1}"
    local package="${3:-$1}"
    local ver_flag="${4:---version}"
    local description="${5:-}"

    if command -v "$binary" &>/dev/null; then
        local ver
        ver="$("$binary" $ver_flag 2>&1 | head -1 | \
               grep -oP '[\d]+\.[\d.]+' | head -1 || echo 'installed')"

        local desc_suffix=""
        [[ -n "$description" ]] && desc_suffix="  $(printf '\033[38;2;108;112;134m')— ${description}$(printf '\033[0m')"

        _check_report $CHECK_PASS \
            "$display" \
            "v${ver}${desc_suffix}"
        (( _OPT_INSTALLED++ )) || true
    else
        local hint=""
        [[ -n "$description" ]] && hint="$description  •  "
        _check_report $CHECK_INFO \
            "$display" \
            "not installed" \
            "${hint}paru -S $package"
        _OPT_SUGGESTIONS+=("$package")
        (( _OPT_MISSING++ )) || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 01 — PRODUCTIVITY & WORKFLOW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_productivity() {
    _check_header "📋 Productivity & Workflow"

    _probe_opt "zoxide"       "Zoxide"             "zoxide"              "--version"  "smarter cd command"
    _probe_opt "atuin"        "Atuin"              "atuin"               "--version"  "magic shell history"
    _probe_opt "mcfly"        "McFly"              "mcfly"               "--version"  "smart Ctrl+R history"
    _probe_opt "thefuck"      "TheFuck"            "thefuck"             "--version"  "auto-correct console commands"
    _probe_opt "direnv"       "direnv"             "direnv"              "--version"  "per-directory env vars"
    _probe_opt "navi"         "Navi"               "navi"                "--version"  "interactive cheatsheet"
    _probe_opt "cheat"        "cheat"              "cheat"               "--version"  "CLI cheatsheet viewer"
    _probe_opt "tldr"         "tldr"               "tldr"                "--version"  "simplified man pages"
    _probe_opt "tealdeer"     "Tealdeer"           "tealdeer"            "--version"  "fast tldr in Rust"
    _probe_opt "pueue"        "Pueue"              "pueue"               "--version"  "async task queue"
    _probe_opt "task"         "Taskwarrior"        "task"                "--version"  "task management CLI"
    _probe_opt "calcurse"     "Calcurse"           "calcurse"            "--version"  "TUI calendar"
    _probe_opt "khal"         "Khal"               "khal"                "--version"  "CalDAV calendar CLI"
    _probe_opt "vit"          "VIT"                "vit"                 "--version"  "Taskwarrior TUI"
    _probe_opt "todo.sh"      "todo.sh"            "todotxt"             "--version"  "simple todo.txt manager"
    _probe_opt "nb"           "nb"                 "nb"                  "--version"  "notes + bookmarks CLI"
    _probe_opt "joplin"       "Joplin CLI"         "joplin"              "--version"  "Markdown note taking"
    _probe_opt "obsidian"     "Obsidian"           "obsidian"            "--version"  "knowledge base app"
    _probe_opt "zk"           "Zk"                 "zk"                  "--version"  "Zettelkasten notes"
    _probe_opt "espanso"      "Espanso"            "espanso"             "--version"  "text expander"
    _probe_opt "xdotool"      "xdotool"            "xdotool"             "--version"  "X11 input automation"
    _probe_opt "ydotool"      "ydotool"            "ydotool"             "--version"  "Wayland input automation"
    _probe_opt "wtype"        "wtype"              "wtype"               "--version"  "Wayland keyboard input"
    _probe_opt "copyq"        "CopyQ"              "copyq"               "--version"  "advanced clipboard manager"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 02 — AI / ML TOOLS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_ai() {
    _check_header "🤖 AI & Machine Learning"

    _probe_opt "ollama"       "Ollama"             "ollama"              "--version"  "local LLM runner (llama3/mistral)"
    _probe_opt "aichat"       "AIChat"             "aichat"              "--version"  "multi-provider AI CLI"
    _probe_opt "llm"          "llm  (Simon Wilson)" "llm"                "--version"  "CLI for GPT/Claude/Gemini"
    _probe_opt "sgpt"         "Shell-GPT"          "shell-gpt"           "--version"  "OpenAI in shell"
    _probe_opt "mods"         "Mods"               "mods"                "--version"  "AI for command line"
    _probe_opt "fabric"       "Fabric"             "fabric"              "--version"  "AI workflow framework"
    _probe_opt "tgpt"         "tgpt"               "tgpt"                "--version"  "AI chatbot in terminal"
    _probe_opt "gpt4all"      "GPT4All"            "gpt4all"             "--version"  "local AI app"
    _probe_opt "whisper"      "Whisper"            "whisper"             "--version"  "OpenAI speech-to-text"
    _probe_opt "stable-diffusion" "Stable Diffusion" "stable-diffusion" "--version"  "image generation"
    _probe_opt "nvtop"        "nvtop"              "nvtop"               "--version"  "GPU monitor (CUDA/ROCm)"
    _probe_opt "amdgpu_top"   "amdgpu_top"         "amdgpu_top"          "--version"  "AMD GPU monitor TUI"
    _probe_opt "rocminfo"     "ROCm Info"          "rocm-core"           ""           "AMD compute platform"

    # ── Ollama model check ───────────────────────────────────────────────────────
    if command -v ollama &>/dev/null && pgrep -x ollama &>/dev/null; then
        local model_count
        model_count="$(ollama list 2>/dev/null | tail -n +2 | wc -l || echo 0)"
        if (( model_count > 0 )); then
            _check_report $CHECK_PASS \
                "  Ollama models" \
                "${model_count} model(s) downloaded"
            while IFS= read -r model_line; do
                [[ -z "$model_line" ]] && continue
                local mname msize
                mname="$(printf '%s' "$model_line" | awk '{print $1}')"
                msize="$(printf '%s' "$model_line" | awk '{print $3,$4}')"
                _check_report $CHECK_INFO \
                    "    └─ ${mname}" \
                    "$msize"
            done < <(ollama list 2>/dev/null | tail -n +2 | head -10)
        else
            _check_report $CHECK_INFO \
                "  Ollama models" \
                "No models pulled yet — try: ollama pull llama3.2"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 03 — MODERN CLI REPLACEMENTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_modern_cli() {
    _check_header "⚡ Modern CLI Replacements"

    _probe_opt "eza"          "eza"                "eza"                 "--version"  "modern ls with icons"
    _probe_opt "bat"          "bat"                "bat"                 "--version"  "cat with syntax highlighting"
    _probe_opt "fd"           "fd"                 "fd"                  "--version"  "faster find"
    _probe_opt "rg"           "ripgrep"            "ripgrep"             "--version"  "faster grep"
    _probe_opt "sd"           "sd"                 "sd"                  "--version"  "intuitive sed replacement"
    _probe_opt "delta"        "delta"              "git-delta"           "--version"  "better git diff"
    _probe_opt "difftastic"   "Difftastic"         "difftastic"          "--version"  "structural diff"
    _probe_opt "dust"         "dust"               "dust"                "--version"  "intuitive du"
    _probe_opt "duf"          "duf"                "duf"                 "--version"  "better df"
    _probe_opt "procs"        "procs"              "procs"               "--version"  "modern ps"
    _probe_opt "bandwhich"    "bandwhich"          "bandwhich"           "--version"  "network utilization TUI"
    _probe_opt "bottom"       "bottom  (btm)"      "bottom"              "--version"  "system monitor"
    _probe_opt "hyperfine"    "Hyperfine"          "hyperfine"           "--version"  "benchmarking tool"
    _probe_opt "tokei"        "Tokei"              "tokei"               "--version"  "code statistics"
    _probe_opt "watchexec"    "Watchexec"          "watchexec"           "--version"  "run on file change"
    _probe_opt "just"         "Just"               "just"                "--version"  "command runner"
    _probe_opt "xh"           "xh"                 "xh"                  "--version"  "friendly HTTP client"
    _probe_opt "curlie"       "Curlie"             "curlie"              "--version"  "curl + httpie"
    _probe_opt "dog"          "dog"                "dog"                 "--version"  "DNS client (dig alt)"
    _probe_opt "gping"        "gping"              "gping"               "--version"  "ping with graph"
    _probe_opt "mtr"          "mtr"                "mtr"                 "--version"  "traceroute + ping"
    _probe_opt "grex"         "Grex"               "grex"                "--version"  "regex generator"
    _probe_opt "ouch"         "Ouch"               "ouch"                "--version"  "compress/decompress"
    _probe_opt "zstd"         "Zstd"               "zstd"                "--version"  "fast compression"
    _probe_opt "xcp"          "xcp"                "xcp"                 "--version"  "extended cp"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 04 — CLOUD & DEVOPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_cloud() {
    _check_header "☁️  Cloud & DevOps"

    _probe_opt "aws"          "AWS CLI"            "aws-cli"             "--version"  "Amazon Web Services CLI"
    _probe_opt "gcloud"       "Google Cloud CLI"   "google-cloud-cli"    "--version"  "GCP CLI"
    _probe_opt "az"           "Azure CLI"          "azure-cli"           "--version"  "Microsoft Azure CLI"
    _probe_opt "doctl"        "DigitalOcean CLI"   "doctl"               "--version"  "DigitalOcean CLI"
    _probe_opt "fly"          "Fly.io CLI"         "flyctl"              "--version"  "Fly.io deployments"
    _probe_opt "vercel"       "Vercel CLI"         "vercel"              "--version"  "Vercel deployments"
    _probe_opt "netlify"      "Netlify CLI"        "netlify-cli"         "--version"  "Netlify deployments"
    _probe_opt "kubectl"      "kubectl"            "kubectl"             "version --client" "Kubernetes CLI"
    _probe_opt "helm"         "Helm"               "helm"                "--version"  "Kubernetes package manager"
    _probe_opt "k9s"          "K9s"                "k9s"                 "--version"  "Kubernetes TUI"
    _probe_opt "kubectx"      "Kubectx"            "kubectx"             "--version"  "switch kubectl contexts"
    _probe_opt "kind"         "Kind"               "kind"                "--version"  "K8s in Docker"
    _probe_opt "minikube"     "Minikube"           "minikube"            "--version"  "local Kubernetes"
    _probe_opt "terraform"    "Terraform"          "terraform"           "--version"  "infrastructure as code"
    _probe_opt "ansible"      "Ansible"            "ansible"             "--version"  "config management"
    _probe_opt "packer"       "Packer"             "packer"              "--version"  "machine image builder"
    _probe_opt "vagrant"      "Vagrant"            "vagrant"             "--version"  "VM workflow"
    _probe_opt "pulumi"       "Pulumi"             "pulumi"              "--version"  "cloud infrastructure SDK"
    _probe_opt "act"          "Act  (GitHub Actions)" "act"              "--version"  "run GH Actions locally"
    _probe_opt "gh"           "GitHub CLI"         "github-cli"          "--version"  "GitHub from terminal"
    _probe_opt "glab"         "GitLab CLI"         "glab"                "--version"  "GitLab from terminal"
    _probe_opt "goreleaser"   "GoReleaser"         "goreleaser"          "--version"  "Go release automation"
    _probe_opt "docker"       "Docker"             "docker"              "--version"  "container runtime"
    _probe_opt "podman"       "Podman"             "podman"              "--version"  "rootless containers"
    _probe_opt "dive"         "Dive"               "dive"                "--version"  "Docker image explorer"
    _probe_opt "lazydocker"   "LazyDocker"         "lazydocker"          "--version"  "Docker TUI"
    _probe_opt "ctop"         "ctop"               "ctop"                "--version"  "container top"
    _probe_opt "skaffold"     "Skaffold"           "skaffold"            "--version"  "K8s dev workflow"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 05 — MONITORING & DIAGNOSTICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_monitoring() {
    _check_header "📊 Monitoring & Diagnostics"

    _probe_opt "btop"         "btop"               "btop"                "--version"  "beautiful system monitor"
    _probe_opt "htop"         "htop"               "htop"                "--version"  "interactive process viewer"
    _probe_opt "glances"      "Glances"            "glances"             "--version"  "cross-platform monitor"
    _probe_opt "bpytop"       "bpytop"             "bpytop"              "--version"  "Python resource monitor"
    _probe_opt "iotop"        "iotop"              "iotop"               "--version"  "I/O monitor"
    _probe_opt "nethogs"      "NetHogs"            "nethogs"             "--version"  "per-process bandwidth"
    _probe_opt "nload"        "nload"              "nload"               "--version"  "network traffic monitor"
    _probe_opt "iftop"        "iftop"              "iftop"               "--version"  "bandwidth usage monitor"
    _probe_opt "ncdu"         "ncdu"               "ncdu"                "--version"  "disk usage analyzer"
    _probe_opt "dstat"        "dstat"              "dstat"               "--version"  "system resource stats"
    _probe_opt "sysstat"      "sysstat  (iostat)"  "sysstat"             "--version"  "system statistics"
    _probe_opt "lm_sensors"   "lm-sensors"         "lm_sensors"          "--version"  "hardware monitoring"
    _probe_opt "sensors"      "sensors"            "lm_sensors"          "--version"  "read hardware sensors"
    _probe_opt "powertop"     "PowerTOP"           "powertop"            "--version"  "power consumption analysis"
    _probe_opt "s-tui"        "s-tui"              "s-tui"               "--version"  "stress terminal UI"
    _probe_opt "stress-ng"    "stress-ng"          "stress-ng"           "--version"  "CPU/RAM stress test"
    _probe_opt "sysbench"     "Sysbench"           "sysbench"            "--version"  "system performance benchmark"
    _probe_opt "fio"          "fio"                "fio"                 "--version"  "storage I/O benchmark"
    _probe_opt "smartctl"     "smartmontools"      "smartmontools"       "--version"  "drive health S.M.A.R.T."
    _probe_opt "journalctl"   "journalctl"         "systemd"             "--version"  "systemd journal viewer"
    _probe_opt "lnav"         "lnav"               "lnav"                "--version"  "log file navigator"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 06 — CREATIVE & MEDIA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_creative() {
    _check_header "🎨 Creative & Media"

    _probe_opt "cava"         "CAVA"               "cava"                "--version"  "audio visualizer"
    _probe_opt "mpd"          "MPD"                "mpd"                 "--version"  "music player daemon"
    _probe_opt "ncmpcpp"      "ncmpcpp"            "ncmpcpp"             "--version"  "MPD TUI client"
    _probe_opt "mpc"          "mpc"                "mpc"                 "--version"  "MPD CLI client"
    _probe_opt "mpvc"         "mpvc"               "mpvc"                "--version"  "mpv IPC client"
    _probe_opt "yt-dlp"       "yt-dlp"             "yt-dlp"              "--version"  "YouTube/media downloader"
    _probe_opt "spotdl"       "spotdl"             "python-spotdl"       "--version"  "Spotify downloader"
    _probe_opt "spicetify"    "Spicetify"          "spicetify-cli"       "-v"         "Spotify customizer"
    _probe_opt "picard"       "MusicBrainz Picard" "picard"              "--version"  "music tagger"
    _probe_opt "gimp"         "GIMP"               "gimp"                "--version"  "image editor"
    _probe_opt "inkscape"     "Inkscape"           "inkscape"            "--version"  "vector graphics"
    _probe_opt "krita"        "Krita"              "krita"               "--version"  "digital painting"
    _probe_opt "darktable"    "Darktable"          "darktable"           "--version"  "photo darkroom"
    _probe_opt "rawtherapee"  "RawTherapee"        "rawtherapee"         "--version"  "RAW photo editor"
    _probe_opt "blender"      "Blender"            "blender"             "--version"  "3D creation suite"
    _probe_opt "obs"          "OBS Studio"         "obs-studio"          "--version"  "streaming/recording"
    _probe_opt "kdenlive"     "Kdenlive"           "kdenlive"            "--version"  "video editor"
    _probe_opt "shotcut"      "Shotcut"            "shotcut"             "--version"  "video editor"
    _probe_opt "audacity"     "Audacity"           "audacity"            "--version"  "audio editor"
    _probe_opt "ardour"       "Ardour"             "ardour"              "--version"  "DAW"
    _probe_opt "reaper"       "REAPER"             "reaper"              "--version"  "DAW (proprietary)"
    _probe_opt "lmms"         "LMMS"               "lmms"                "--version"  "music production"
    _probe_opt "flameshot"    "Flameshot"          "flameshot"           "--version"  "screenshot tool"
    _probe_opt "peek"         "Peek"               "peek"                "--version"  "GIF recorder"
    _probe_opt "vokoscreenNG" "VokoscreenNG"       "vokoscreen-ng"       "--version"  "screencast"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 07 — BROWSERS & COMMUNICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_browsers() {
    _check_header "🌐 Browsers & Communication"

    _probe_opt "firefox"      "Firefox"            "firefox"             "--version"  "web browser"
    _probe_opt "chromium"     "Chromium"           "chromium"            "--version"  "web browser"
    _probe_opt "google-chrome-stable" "Google Chrome" "google-chrome"   "--version"  "web browser"
    _probe_opt "brave"        "Brave Browser"      "brave-bin"           "--version"  "privacy browser"
    _probe_opt "qutebrowser"  "Qutebrowser"        "qutebrowser"         "--version"  "keyboard-driven browser"
    _probe_opt "nyxt"         "Nyxt"               "nyxt"                "--version"  "hackable Lisp browser"
    _probe_opt "lynx"         "Lynx"               "lynx"                "--version"  "text-mode browser"
    _probe_opt "w3m"          "w3m"                "w3m"                 "--version"  "text-mode browser"
    _probe_opt "discord"      "Discord"            "discord"             "--version"  "voice/text chat"
    _probe_opt "vesktop"      "Vesktop"            "vesktop"             "--version"  "Discord client (Vencord)"
    _probe_opt "element-desktop" "Element"         "element-desktop"     "--version"  "Matrix client"
    _probe_opt "signal-desktop" "Signal"           "signal-desktop"      "--version"  "encrypted messaging"
    _probe_opt "telegram-desktop" "Telegram"       "telegram-desktop"    "--version"  "messaging"
    _probe_opt "slack"        "Slack"              "slack-desktop"       "--version"  "team messaging"
    _probe_opt "thunderbird"  "Thunderbird"        "thunderbird"         "--version"  "email client"
    _probe_opt "neomutt"      "NeoMutt"            "neomutt"             "--version"  "terminal email client"
    _probe_opt "aerc"         "Aerc"               "aerc"                "--version"  "email in terminal"
    _probe_opt "weechat"      "WeeChat"            "weechat"             "--version"  "IRC/Matrix client"
    _probe_opt "irssi"        "Irssi"              "irssi"               "--version"  "IRC client"
    _probe_opt "newsboat"     "Newsboat"           "newsboat"            "--version"  "RSS/Atom reader"
    _probe_opt "miniflux"     "Miniflux"           "miniflux"            "--version"  "RSS reader"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 08 — DOCUMENT & OFFICE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_documents() {
    _check_header "📄 Documents & Office"

    _probe_opt "zathura"      "Zathura"            "zathura"             "--version"  "keyboard-driven PDF viewer"
    _probe_opt "evince"       "Evince"             "evince"              "--version"  "GNOME document viewer"
    _probe_opt "okular"       "Okular"             "okular"              "--version"  "KDE document viewer"
    _probe_opt "sioyek"       "Sioyek"             "sioyek"              "--version"  "research PDF viewer"
    _probe_opt "pandoc"       "Pandoc"             "pandoc"              "--version"  "universal document converter"
    _probe_opt "libreoffice"  "LibreOffice"        "libreoffice-fresh"   "--version"  "office suite"
    _probe_opt "onlyoffice"   "OnlyOffice"         "onlyoffice-desktopeditors" "--version" "MS-compatible office"
    _probe_opt "calibre"      "Calibre"            "calibre"             "--version"  "ebook manager"
    _probe_opt "foliate"      "Foliate"            "foliate"             "--version"  "ebook reader"
    _probe_opt "ghostscript"  "Ghostscript"        "ghostscript"         "--version"  "PostScript/PDF interpreter"
    _probe_opt "gs"           "gs  (Ghostscript)"  "ghostscript"         "--version"  "PDF manipulation"
    _probe_opt "pdfgrep"      "pdfgrep"            "pdfgrep"             "--version"  "grep for PDFs"
    _probe_opt "ocrmypdf"     "OCRmyPDF"           "ocrmypdf"            "--version"  "add OCR to PDFs"
    _probe_opt "tesseract"    "Tesseract OCR"      "tesseract"           "--version"  "OCR engine"
    _probe_opt "typst"        "Typst"              "typst"               "--version"  "modern typesetting"
    _probe_opt "tectonic"     "Tectonic"           "tectonic"            "--version"  "modern LaTeX compiler"
    _probe_opt "latex"        "LaTeX"              "texlive-core"        "--version"  "document typesetting"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  SECTION 09 — MISC ENHANCEMENTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_misc() {
    _check_header "🌟 Misc Enhancements"

    _probe_opt "lolcat"       "lolcat"             "lolcat"              "--version"  "rainbow output"
    _probe_opt "cowsay"       "cowsay"             "cowsay"              "--version"  "talking cow"
    _probe_opt "figlet"       "FIGlet"             "figlet"              "--version"  "ASCII art text"
    _probe_opt "toilet"       "TOIlet"             "toilet"              "--version"  "color ASCII art text"
    _probe_opt "fortune"      "Fortune"            "fortune-mod"         "--version"  "random quote"
    _probe_opt "pipes.sh"     "pipes.sh"           "pipes.sh"            "--version"  "animated pipes screensaver"
    _probe_opt "cmatrix"      "CMatrix"            "cmatrix"             "--version"  "Matrix rain terminal"
    _probe_opt "asciinema"    "Asciinema"          "asciinema"           "--version"  "terminal session recorder"
    _probe_opt "agg"          "Asciinema GIF"      "agg"                 "--version"  "asciinema to GIF"
    _probe_opt "glow"         "Glow"               "glow"                "--version"  "Markdown viewer TUI"
    _probe_opt "mdcat"        "mdcat"              "mdcat"               "--version"  "Markdown renderer"
    _probe_opt "rich"         "Rich  (Python)"     "python-rich"         "--version"  "rich text for terminal"
    _probe_opt "wtf"          "WTF Dashboard"      "wtfutil"             "--version"  "personal info dashboard"
    _probe_opt "peaclock"     "Peaclock"           "peaclock"            "--version"  "terminal clock"
    _probe_opt "tty-clock"    "tty-clock"          "tty-clock"           "--version"  "terminal clock"
    _probe_opt "cbonsai"      "cbonsai"            "cbonsai"             "--version"  "bonsai tree animation"
    _probe_opt "unimatrix"    "Unimatrix"          "unimatrix"           "--version"  "Matrix simulation"
    _probe_opt "nyancat"      "Nyancat"            "nyancat"             "--version"  "Nyan cat terminal"
    _probe_opt "sl"           "sl  (steam train)"  "sl"                  "--version"  "train runs when typo ls"
    _probe_opt "onefetch"     "Onefetch"           "onefetch"            "--version"  "git repo info tool"
    _probe_opt "wpm"          "wpm  (typing speed)" "wpm"                "--version"  "typing speed test"
    _probe_opt "genact"       "Genact"             "genact"              "--version"  "fake activity generator"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  FINAL SCORE REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_chk_opt_score_report() {
    local total=$(( _OPT_INSTALLED + _OPT_MISSING ))
    local score_pct=0
    (( total > 0 )) && score_pct=$(( _OPT_INSTALLED * 100 / total ))

    # Build ASCII progress bar
    local bar_width=40
    local filled=$(( score_pct * bar_width / 100 ))
    local empty=$(( bar_width - filled ))

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done

    local score_color
    if   (( score_pct >= 80 )); then score_color='\033[38;2;166;227;161m'
    elif (( score_pct >= 50 )); then score_color='\033[38;2;249;226;175m'
    else                             score_color='\033[38;2;243;139;168m'
    fi

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;116;199;236m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  🌟  OPTIONAL TOOLS SCORE REPORT                         ║\n'
        printf '  ╠══════════════════════════════════════════════════════════╣\n'
        printf '  ║  %s%s\033[0m\033[1;38;2;116;199;236m  %3d%%  ║\n' \
            "$score_color" "$bar" "$score_pct"
        printf '  ║  \033[38;2;166;227;161m✓ %-4d installed\033[38;2;116;199;236m  •  ' \
            "$_OPT_INSTALLED"
        printf '\033[38;2;108;112;134m○ %-4d not installed\033[38;2;116;199;236m  •  ' \
            "$_OPT_MISSING"
        printf '%-4d total  ║\n' "$total"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n  OPTIONAL TOOLS: %d/%d installed (%d%%)\n' \
            "$_OPT_INSTALLED" "$total" "$score_pct"
    fi

    # ── Top 5 recommended installs ────────────────────────────────────────────────
    local top_recommendations=(
        "ollama:🤖 Local AI (llama3/mistral)"
        "eza:📁 Beautiful ls replacement"
        "bat:🦇 Syntax-highlighted cat"
        "atuin:📜 Magic shell history"
        "lazydocker:🐳 Docker TUI"
    )

    if (( _OPT_MISSING > 0 )); then
        printf '\n'
        if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
            printf '\033[1;38;2;203;166;247m  💡 TOP RECOMMENDATIONS:\033[0m\n'
        else
            printf '  RECOMMENDATIONS:\n'
        fi

        for rec in "${top_recommendations[@]}"; do
            IFS=':' read -r pkg desc <<< "$rec"
            if ! command -v "${pkg%% *}" &>/dev/null; then
                if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
                    printf '  \033[38;2;116;199;236m→\033[0m  %-18s \033[38;2;108;112;134m%s\033[0m\n' \
                        "$pkg" "$desc"
                else
                    printf '  → %-18s %s\n' "$pkg" "$desc"
                fi
            fi
        done
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN ENTRY POINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_check_tools_optional() {
    local mode="${1:-full}"

    _CHECK_PASS_COUNT=0;  _CHECK_WARN_COUNT=0
    _CHECK_FAIL_COUNT=0;  _CHECK_SKIP_COUNT=0
    _CHECK_FAILURES=();   _CHECK_WARNINGS=()
    _OPT_INSTALLED=0;     _OPT_MISSING=0
    _OPT_SUGGESTIONS=()

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\n\033[1;38;2;116;199;236m'
        printf '╔══════════════════════════════════════════════════════════╗\n'
        printf '║  🌟  ASH DOCTOR — OPTIONAL TOOLS CHECK                   ║\n'
        printf '╠══════════════════════════════════════════════════════════╣\n'
        printf '║  productivity • AI/ML • modern-cli • cloud • monitoring  ║\n'
        printf '╚══════════════════════════════════════════════════════════╝\033[0m\n'
    else
        printf '\n=== ASH DOCTOR — OPTIONAL TOOLS CHECK ===\n'
    fi

    case "$mode" in
        quick)
            _chk_opt_modern_cli
            _chk_opt_productivity
            ;;
        ai)       _chk_opt_ai         ;;
        cloud)    _chk_opt_cloud      ;;
        creative) _chk_opt_creative   ;;
        full|*)
            _chk_opt_productivity
            _chk_opt_ai
            _chk_opt_modern_cli
            _chk_opt_cloud
            _chk_opt_monitoring
            _chk_opt_creative
            _chk_opt_browsers
            _chk_opt_documents
            _chk_opt_misc
            ;;
    esac

    _chk_opt_score_report
    _ash_check_system_summary
}

ash_check_tools_optional_quick() {
    local installed=0 total=0
    local -a spot_check=( "eza" "bat" "fd" "rg" "fzf" "zoxide" "btop" "lazygit" )
    for b in "${spot_check[@]}"; do
        (( total++ )) || true
        command -v "$b" &>/dev/null && (( installed++ )) || true
    done
    local pct=$(( installed * 100 / total ))
    if (( pct >= 75 )); then
        ash_log_success "Optional tools: ${installed}/${total} (${pct}%) core extras installed"
    else
        ash_log_info "Optional tools: ${installed}/${total} (${pct}%) — run 'ash doctor full --optional'"
    fi
}
