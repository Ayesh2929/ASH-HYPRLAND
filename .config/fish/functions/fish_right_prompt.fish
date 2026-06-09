# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH RIGHT PROMPT                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

function fish_right_prompt
    # Skip if starship is active
    command -q starship && return

    set -l c_muted   (set_color 7f849c)
    set -l c_time    (set_color fab387)
    set -l c_venv    (set_color f9e2af)
    set -l c_git     (set_color cba6f7)
    set -l c_reset   (set_color normal)

    set -l parts ""

    # ── Current time ──────────────────────────────────────────────────────────
    set parts $parts$c_muted(date "+%H:%M:%S")$c_reset

    # ── Nix shell indicator ───────────────────────────────────────────────────
    if test -n "$IN_NIX_SHELL"
        set parts $parts" "$c_venv"❄ nix"$c_reset
    end

    # ── Kubernetes context ────────────────────────────────────────────────────
    if command -q kubectl
        set -l kube_ctx (kubectl config current-context 2>/dev/null)
        if test -n "$kube_ctx"
            set parts $parts" "$c_git"⎈ "(string shorten -m 15 $kube_ctx)$c_reset
        end
    end

    echo -s $parts
end