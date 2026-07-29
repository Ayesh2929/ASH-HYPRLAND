#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ☸️   FZF_KUBECTL.FISH  ·  ASH Dotfiles v5.0 OMEGA                               ║
# ║  Ultra Interactive Kubernetes Manager                                            ║
# ║  Contexts · Pods · Services · Deployments · Logs · Exec · Port-forward · Apply  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# FUNCTIONS:
#   fzf_kubectl              — K8s dashboard / main menu
#   fzf_kubectl_context      — Context / namespace switcher
#   fzf_kubectl_pod          — Pod browser (logs/exec/delete/describe)
#   fzf_kubectl_deploy       — Deployment manager
#   fzf_kubectl_service      — Service browser + port-forward
#   fzf_kubectl_resource     — Generic resource browser
#   fzf_kubectl_apply        — Apply manifests interactively
#   fzf_kubectl_logs         — Pod log browser
#   fzf_kubectl_exec         — Exec into pod
#
# KEYBINDS:
#   Ctrl+Alt+K   — K8s dashboard
#   Ctrl+Alt+N   — Namespace switcher

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __FK_VERSION "5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  PALETTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g _R  (set_color normal)
set -g _B  (set_color --bold)
set -g _D  (set_color brblack)
set -g _W  (set_color white)
set -g _RE (set_color brred)
set -g _GR (set_color brgreen)
set -g _YE (set_color bryellow)
set -g _BL (set_color brblue)
set -g _CY (set_color brcyan)
set -g _MG (set_color brmagenta)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  INTERNAL UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fk_ok   -a m; echo "$_GR  ✔  $m$_R"; end
function __fk_err  -a m; echo "$_RE  ✘  $m$_R" >&2; end
function __fk_warn -a m; echo "$_YE  ⚠  $m$_R"; end
function __fk_tip  -a m; echo "$_CY  ›  $m$_R"; end
function __fk_info -a m; echo "$_BL  ℹ  $m$_R"; end

function __fk_require_fzf
    command -q fzf; and return 0
    __fk_err "fzf required — install: paru -S fzf"
    return 1
end

function __fk_require_kubectl
    command -q kubectl; or begin
        __fk_err "kubectl not found"
        __fk_tip  "Install: paru -S kubectl"
        return 1
    end
    kubectl cluster-info --request-timeout=3s >/dev/null 2>&1; or begin
        __fk_warn "Cluster unreachable — using cached data"
    end
end

# ── current context / namespace ───────────────────────────────────────────────

function __fk_ctx
    kubectl config current-context 2>/dev/null; or echo "none"
end

function __fk_ns
    kubectl config view --minify \
        --output 'jsonpath={..namespace}' 2>/dev/null; or echo "default"
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  FZF BASE OPTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -g __FK_FZF_OPTS \
    "--border=rounded" \
    "--height=88%" \
    "--layout=reverse" \
    "--info=inline" \
    "--ansi" \
    "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8" \
    "--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8" \
    "--color=info:#cba6ac,prompt:#89b4fa,pointer:#f5c2e7" \
    "--color=marker:#a6e3a1,spinner:#f5c2e7,header:#89dceb" \
    "--pointer=❯" \
    "--marker=●" \
    "--bind=ctrl-/:toggle-preview" \
    "--bind=ctrl-u:preview-page-up" \
    "--bind=ctrl-d:preview-page-down" \
    "--bind=ctrl-a:select-all"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  STATUS COLORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fk_phase_icon -a phase
    switch $phase
        case Running;   echo "🟢"
        case Succeeded; echo "✅"
        case Failed;    echo "🔴"
        case Pending;   echo "🟡"
        case Unknown;   echo "⚫"
        case '*';       echo "🔵"
    end
end

function __fk_phase_color -a phase
    switch $phase
        case Running;   echo $_GR
        case Succeeded; echo $_GR
        case Failed;    echo $_RE
        case Pending;   echo $_YE
        case '*';       echo $_D
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  DASHBOARD HEADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fk_dashboard_header
    set -l ctx (__fk_ctx)
    set -l ns  (__fk_ns)

    set -l pods_total   (kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l | string trim)
    set -l pods_running (kubectl get pods -n $ns --no-headers 2>/dev/null | \
        grep -c Running; or echo 0)
    set -l deploys  (kubectl get deployments -n $ns --no-headers 2>/dev/null | wc -l | string trim)
    set -l services (kubectl get services    -n $ns --no-headers 2>/dev/null | wc -l | string trim)
    set -l nodes    (kubectl get nodes       --no-headers 2>/dev/null | wc -l | string trim)

    echo ""
    echo "$_BL  ╔═════════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  ☸️   $_CY$_B Kubernetes Dashboard$_R  ·  $_D v$__FK_VERSION · ASH OMEGA$_R         $_BL║$_R"
    echo "$_BL  ╠═════════════════════════════════════════════════════════════════╣$_R"
    printf "$_BL  ║$_R  🔑 Context: $_CY%-20s$_R  📋 NS: $_MG%-14s$_R  🖥  Nodes: $_GR%s$_R  $_BL║$_R\n" \
        (string shorten -m 20 $ctx) (string shorten -m 14 $ns) $nodes
    printf "$_BL  ║$_R  🟢 Pods: $_GR%s$_R/$_D%s$_R  📦 Deploys: $_YE%s$_R  🌐 Services: $_BL%s$_R         $_BL║$_R\n" \
        $pods_running $pods_total $deploys $services
    echo "$_BL  ╚═════════════════════════════════════════════════════════════════╝$_R"
    echo ""
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CORE — fzf_kubectl
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl --description "☸️  Kubernetes management dashboard"
    __fk_require_fzf;     or return 1
    __fk_require_kubectl; or return 1

    __fk_dashboard_header

    set -l sections \
        "🔑  Contexts / Namespace — switch cluster or ns" \
        "🟢  Pods          — logs/exec/delete/describe" \
        "📦  Deployments   — scale/rollout/restart" \
        "🌐  Services      — port-forward/describe" \
        "🗂️   Resources     — generic browser (all types)" \
        "📄  Apply Manifest — apply/diff/delete" \
        "⚡  Quick kubectl  — raw command" \
        "📋  Events        — cluster events"

    set -l choice (printf '%s\n' $sections | fzf \
        $__FK_FZF_OPTS \
        --no-preview \
        --prompt "  ☸️  K8s ❯ " \
        --header "  Ctx: (__fk_ctx)  NS: (__fk_ns)  |  Esc=exit")

    test -z "$choice"; and return 0

    switch $choice
        case "*Contexts*";     fzf_kubectl_context
        case "*Pods*";         fzf_kubectl_pod
        case "*Deployments*";  fzf_kubectl_deploy
        case "*Services*";     fzf_kubectl_service
        case "*Resources*";    fzf_kubectl_resource
        case "*Apply*";        fzf_kubectl_apply
        case "*Quick*"
            set -l cmd (read -P "  ⚡ kubectl ")
            test -n "$cmd"; and eval kubectl $cmd
        case "*Events*"
            kubectl get events -n (__fk_ns) \
                --sort-by='.lastTimestamp' 2>/dev/null \
                | bat --style=plain --color=always --language=log 2>/dev/null \
                | less -R
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  CONTEXT / NAMESPACE SWITCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_context --description "☸️  Switch K8s context / namespace"
    __fk_require_fzf; or return 1

    set -l current_ctx (__fk_ctx)
    set -l current_ns  (__fk_ns)

    set -l mode (printf "🔑 Switch context\n📋 Switch namespace\n🔍 Show current context details" \
        | fzf --prompt "  🔑 Mode ❯ " \
              --height=25% --layout=reverse --border=rounded --no-preview)

    test -z "$mode"; and return 0

    switch $mode
        case "*context*"
            set -l ctx (kubectl config get-contexts --no-headers 2>/dev/null \
                | awk '{
                    current = ($1 == "*") ? "★ " : "  "
                    ctx = ($1 == "*") ? $2 : $1
                    cluster = ($1 == "*") ? $3 : $2
                    user = ($1 == "*") ? $4 : $3
                    printf "%s %-32s %-24s %s\n", current, ctx, cluster, user
                }' \
                | fzf \
                    $__FK_FZF_OPTS \
                    --no-multi \
                    --prompt "  🔑 Context ❯ " \
                    --header "  ★=current  |  Enter=switch" \
                    --no-preview \
                    | awk '{print ($1 == "★") ? $2 : $1}')

            if test -n "$ctx"
                kubectl config use-context $ctx
                and __fk_ok "Switched to context: $_CY$ctx$_R"
            end

        case "*namespace*"
            set -l ns (kubectl get namespaces --no-headers 2>/dev/null \
                | awk '{print $1, $2, $3}' \
                | fzf \
                    $__FK_FZF_OPTS \
                    --no-multi \
                    --prompt "  📋 Namespace ❯ " \
                    --header "  Current: $current_ns" \
                    --preview '
                        ns=$(echo {} | awk "{print \$1}")
                        kubectl get all -n "$ns" 2>/dev/null | head -30
                    ' \
                    --preview-window "right:50%:wrap" \
                    | awk '{print $1}')

            if test -n "$ns"
                kubectl config set-context --current --namespace=$ns
                and __fk_ok "Switched to namespace: $_CY$ns$_R"
            end

        case "*details*"
            kubectl config view --minify | bat --style=full --color=always \
                --language=yaml 2>/dev/null; or kubectl config view --minify | less
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  POD MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_pod --description "☸️  Interactive pod manager"
    __fk_require_fzf; or return 1

    set -l ns (test -n "$argv[1]"; and echo $argv[1]; or echo (__fk_ns))

    set -l result (kubectl get pods -n $ns \
        --no-headers 2>/dev/null \
        | awk '{
            phase = $3
            col = (phase == "Running") ? "\033[92m" : \
                  (phase == "Pending") ? "\033[93m" : \
                  (phase == "Failed")  ? "\033[91m" : "\033[90m"
            icon = (phase == "Running") ? "🟢" : \
                   (phase == "Pending") ? "🟡" : \
                   (phase == "Failed")  ? "🔴" : "⚫"
            printf "%s \033[97m%-44s\033[0m %s%-10s\033[0m \033[90m%-8s  %s\033[0m\n",
                icon, $1, col, $3, $4, $5
        }' \
        | fzf \
            $__FK_FZF_OPTS \
            --multi \
            --prompt "  🟢 Pods [$ns] ❯ " \
            --header "  Enter=action  Ctrl+L=logs  Ctrl+E=exec  Ctrl+D=delete  Ctrl+/=preview" \
            --preview "
                pod=\$(echo {} | awk '{print \$2}')
                kubectl describe pod \"\$pod\" -n $ns 2>/dev/null | head -60
            " \
            --preview-window "right:52%:wrap" \
            --expect "enter,ctrl-l,ctrl-e,ctrl-d,ctrl-p,esc")

    test -z "$result"; and return 0

    set -l key  (echo $result | head -1)
    set -l lines (echo $result | tail -n +2)
    set -l pod  (echo $lines | head -1 | awk '{print $2}')

    test -z "$pod"; and return 0

    switch $key
        case "enter" ""
            set -l actions \
                "📜  Logs" \
                "📜  Logs (follow)" \
                "🖥️   Exec shell" \
                "🔍  Describe" \
                "📋  Get YAML" \
                "🌐  Port-forward" \
                "🗑️   Delete pod" \
                "↩️   Cancel"

            set -l act (printf '%s\n' $actions | fzf \
                --prompt "  ⚡ $pod ❯ " \
                --height=40% --layout=reverse --border=rounded --no-preview)
            test -z "$act"; and return 0

            switch $act
                case "*Logs*" "*follow*"
                    set -l f (string match -q "*follow*" $act; and echo "-f"; or echo "")
                    # Multi-container check
                    set -l containers (kubectl get pod $pod -n $ns \
                        -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' ')
                    set -l ctr ""
                    if test (count $containers) -gt 1
                        set ctr (printf '%s\n' $containers | fzf \
                            --prompt "  📦 Container ❯ " \
                            --height=25% --layout=reverse --border=rounded --no-preview)
                        test -n "$ctr"; and set ctr "-c $ctr"
                    end
                    eval kubectl logs $f --tail=100 $ctr $pod -n $ns

                case "*Exec*"
                    fzf_kubectl_exec $pod $ns

                case "*Describe*"
                    kubectl describe pod $pod -n $ns \
                        | bat --style=plain --color=always --language=yaml 2>/dev/null \
                        | less -R

                case "*YAML*"
                    kubectl get pod $pod -n $ns -o yaml \
                        | bat --style=full --color=always --language=yaml 2>/dev/null \
                        | less -R

                case "*Port-forward*"
                    set -l ports (read -P "  🔌 local:remote port [8080:80]: ")
                    test -z "$ports"; and set ports "8080:80"
                    kubectl port-forward pod/$pod -n $ns $ports

                case "*Delete*"
                    set -l confirm (read -P "  🗑️  Delete pod '$pod'? [y/N] ")
                    test "$confirm" = "y" -o "$confirm" = "Y"
                        and kubectl delete pod $pod -n $ns
                        and __fk_ok "Deleted: $pod"
            end

        case "ctrl-l"
            fzf_kubectl_logs $pod $ns

        case "ctrl-e"
            fzf_kubectl_exec $pod $ns

        case "ctrl-d"
            set -l pids (echo $lines | string split '\n' | awk '{print $2}' | grep -v '^$')
            set -l n (count $pids)
            set -l confirm (read -P "  🗑️  Delete $n pod(s)? [y/N] ")
            if test "$confirm" = "y" -o "$confirm" = "Y"
                for p in $pids
                    kubectl delete pod $p -n $ns
                    and __fk_ok "Deleted: $p"
                end
            end

        case "ctrl-p"
            set -l ports (read -P "  🔌 Ports [8080:80]: ")
            test -z "$ports"; and set ports "8080:80"
            __fk_info "Port-forwarding $pod: $ports"
            kubectl port-forward pod/$pod -n $ns $ports
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  DEPLOYMENT MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_deploy --description "☸️  Deployment manager"
    __fk_require_fzf; or return 1

    set -l ns (test -n "$argv[1]"; and echo $argv[1]; or echo (__fk_ns))

    set -l result (kubectl get deployments -n $ns --no-headers 2>/dev/null \
        | awk '{
            ready = $2; desired = $3; uptodate = $4
            col = (ready == desired && desired > 0) ? "\033[92m" : "\033[91m"
            icon = (ready == desired && desired > 0) ? "🟢" : "🔴"
            printf "%s \033[97m%-36s\033[0m %s%-10s\033[0m \033[90m%-10s %-10s %s\033[0m\n",
                icon, $1, col, $2"/"$3, $4, $5, $6
        }' \
        | fzf \
            $__FK_FZF_OPTS \
            --prompt "  📦 Deployments [$ns] ❯ " \
            --header "  Enter=action  Ctrl+R=restart  Ctrl+/=preview" \
            --preview "
                deploy=\$(echo {} | awk '{print \$2}')
                kubectl describe deployment \"\$deploy\" -n $ns 2>/dev/null | head -50
            " \
            --preview-window "right:52%:wrap" \
            --expect "enter,ctrl-r,esc")

    test -z "$result"; and return 0

    set -l key    (echo $result | head -1)
    set -l line   (echo $result | tail -1)
    set -l deploy (echo $line | awk '{print $2}')

    test -z "$deploy"; and return 0

    switch $key
        case "enter" ""
            set -l actions \
                "🔄  Restart deployment" \
                "⚖️   Scale replicas" \
                "📜  Rollout history" \
                "↩️   Rollback (undo)" \
                "🔍  Describe" \
                "📋  Get YAML" \
                "🗑️   Delete"

            set -l act (printf '%s\n' $actions | fzf \
                --prompt "  📦 $deploy ❯ " \
                --height=40% --layout=reverse --border=rounded --no-preview)
            test -z "$act"; and return 0

            switch $act
                case "*Restart*"
                    kubectl rollout restart deployment/$deploy -n $ns
                    and __fk_ok "Restarted: $deploy"
                case "*Scale*"
                    set -l current (kubectl get deployment $deploy -n $ns \
                        -o jsonpath='{.spec.replicas}' 2>/dev/null)
                    set -l n (read -P "  ⚖️  Replicas (current: $current): ")
                    test -n "$n"
                        and kubectl scale deployment/$deploy --replicas=$n -n $ns
                        and __fk_ok "Scaled to $n replicas"
                case "*history*"
                    kubectl rollout history deployment/$deploy -n $ns
                case "*Rollback*"
                    set -l confirm (read -P "  ↩️  Rollback $deploy? [y/N] ")
                    test "$confirm" = "y" -o "$confirm" = "Y"
                        and kubectl rollout undo deployment/$deploy -n $ns
                        and __fk_ok "Rolled back: $deploy"
                case "*Describe*"
                    kubectl describe deployment $deploy -n $ns \
                        | bat --style=plain --color=always --language=yaml 2>/dev/null \
                        | less -R
                case "*YAML*"
                    kubectl get deployment $deploy -n $ns -o yaml \
                        | bat --style=full --color=always --language=yaml 2>/dev/null \
                        | less -R
                case "*Delete*"
                    set -l confirm (read -P "  🗑️  Delete deployment '$deploy'? [y/N] ")
                    test "$confirm" = "y" -o "$confirm" = "Y"
                        and kubectl delete deployment $deploy -n $ns
                        and __fk_ok "Deleted: $deploy"
            end

        case "ctrl-r"
            kubectl rollout restart deployment/$deploy -n $ns
            and __fk_ok "Restarted: $deploy"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  SERVICE BROWSER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_service --description "☸️  Service browser + port-forward"
    __fk_require_fzf; or return 1

    set -l ns (test -n "$argv[1]"; and echo $argv[1]; or echo (__fk_ns))

    set -l result (kubectl get services -n $ns --no-headers 2>/dev/null \
        | fzf \
            $__FK_FZF_OPTS \
            --prompt "  🌐 Services [$ns] ❯ " \
            --header "  Enter=action  Ctrl+F=port-forward  Ctrl+/=preview" \
            --preview "
                svc=\$(echo {} | awk '{print \$1}')
                kubectl describe service \"\$svc\" -n $ns 2>/dev/null | head -40
            " \
            --preview-window "right:52%:wrap" \
            --expect "enter,ctrl-f,esc")

    test -z "$result"; and return 0

    set -l key (echo $result | head -1)
    set -l svc (echo $result | tail -1 | awk '{print $1}')

    test -z "$svc"; and return 0

    switch $key
        case "enter" ""
            set -l act (printf "🌐 Port-forward\n🔍 Describe\n📋 Get YAML\n🗑️  Delete" \
                | fzf --prompt "  🌐 $svc ❯ " \
                      --height=25% --layout=reverse --border=rounded --no-preview)
            switch $act
                case "*Port-forward*"
                    set -l ports (read -P "  🔌 Ports [local:svc-port]: ")
                    test -n "$ports"
                        and kubectl port-forward svc/$svc -n $ns $ports
                case "*Describe*"
                    kubectl describe service $svc -n $ns \
                        | bat --style=plain --color=always --language=yaml 2>/dev/null \
                        | less -R
                case "*YAML*"
                    kubectl get service $svc -n $ns -o yaml \
                        | bat --style=full --color=always --language=yaml 2>/dev/null \
                        | less -R
                case "*Delete*"
                    set -l confirm (read -P "  🗑️  Delete service '$svc'? [y/N] ")
                    test "$confirm" = "y" -o "$confirm" = "Y"
                        and kubectl delete service $svc -n $ns
                        and __fk_ok "Deleted: $svc"
            end

        case "ctrl-f"
            set -l ports (read -P "  🔌 Ports [8080:80]: ")
            test -z "$ports"; and set ports "8080:80"
            __fk_info "Port-forwarding svc/$svc: $ports"
            kubectl port-forward svc/$svc -n $ns $ports
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  GENERIC RESOURCE BROWSER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_resource --description "☸️  Generic K8s resource browser"
    __fk_require_fzf; or return 1

    set -l ns (test -n "$argv[1]"; and echo $argv[1]; or echo (__fk_ns))

    set -l resource_types \
        "pods" "deployments" "services" "replicasets" \
        "statefulsets" "daemonsets" "configmaps" "secrets" \
        "ingresses" "persistentvolumeclaims" "jobs" "cronjobs" \
        "nodes" "namespaces" "persistentvolumes" "storageclasses" \
        "serviceaccounts" "roles" "rolebindings" "networkpolicies"

    set -l rtype (printf '%s\n' $resource_types | fzf \
        --prompt "  🗂️  Resource type ❯ " \
        --height=50% --layout=reverse --border=rounded \
        --no-preview \
        --header "  Select resource type")

    test -z "$rtype"; and return 0

    set -l ns_flag (contains $rtype nodes namespaces persistentvolumes storageclasses \
        and echo ""; or echo "-n $ns")

    set -l result (eval kubectl get $rtype $ns_flag --no-headers 2>/dev/null \
        | fzf \
            $__FK_FZF_OPTS \
            --prompt "  🗂️  $rtype ❯ " \
            --header "  Enter=describe  Ctrl+Y=yaml  Ctrl+X=delete  Ctrl+/=preview" \
            --preview "
                name=\$(echo {} | awk '{print \$1}')
                kubectl describe $rtype \"\$name\" $ns_flag 2>/dev/null | head -60
            " \
            --preview-window "right:52%:wrap" \
            --expect "enter,ctrl-y,ctrl-x,esc")

    test -z "$result"; and return 0
    set -l key  (echo $result | head -1)
    set -l name (echo $result | tail -1 | awk '{print $1}')
    test -z "$name"; and return 0

    switch $key
        case "enter" ""
            eval kubectl describe $rtype $name $ns_flag \
                | bat --style=plain --color=always --language=yaml 2>/dev/null \
                | less -R
        case "ctrl-y"
            eval kubectl get $rtype $name $ns_flag -o yaml \
                | bat --style=full --color=always --language=yaml 2>/dev/null \
                | less -R
        case "ctrl-x"
            set -l confirm (read -P "  🗑️  Delete $rtype '$name'? [y/N] ")
            test "$confirm" = "y" -o "$confirm" = "Y"
                and eval kubectl delete $rtype $name $ns_flag
                and __fk_ok "Deleted: $name"
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  APPLY MANIFEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_apply --description "☸️  Apply/delete K8s manifests"
    __fk_require_fzf; or return 1

    set -l manifests (fd -e yml -e yaml . 2>/dev/null; \
        or find . -name '*.yml' -o -name '*.yaml' 2>/dev/null)

    if test (count $manifests) -eq 0
        __fk_warn "No YAML manifests found in current directory"
        set -l file (read -P "  📄 Manifest path: ")
        test -z "$file"; and return 0
        set manifests $file
    end

    set -l result (printf '%s\n' $manifests | fzf \
        $__FK_FZF_OPTS \
        --multi \
        --prompt "  📄 Manifest ❯ " \
        --header "  Enter=apply  Ctrl+D=diff  Ctrl+X=delete  Ctrl+/=preview" \
        --preview 'bat --style=full --color=always --language=yaml {} 2>/dev/null || cat {}' \
        --preview-window "right:55%:wrap" \
        --expect "enter,ctrl-d,ctrl-x,esc")

    test -z "$result"; and return 0

    set -l key   (echo $result | head -1)
    set -l files (echo $result | tail -n +2 | string split '\n' | grep -v '^$')

    for f in $files
        switch $key
            case "enter" ""
                kubectl apply -f $f
                and __fk_ok "Applied: $f"
            case "ctrl-d"
                kubectl diff -f $f 2>/dev/null \
                    | bat --style=plain --color=always --language=diff 2>/dev/null \
                    | less -R
            case "ctrl-x"
                set -l confirm (read -P "  🗑️  Delete resources in '$f'? [y/N] ")
                test "$confirm" = "y" -o "$confirm" = "Y"
                    and kubectl delete -f $f
                    and __fk_ok "Deleted resources: $f"
        end
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  LOG BROWSER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_logs --description "☸️  K8s pod log browser"
    set -l pod $argv[1]
    set -l ns  (test -n "$argv[2]"; and echo $argv[2]; or echo (__fk_ns))

    if test -z "$pod"
        set pod (kubectl get pods -n $ns --no-headers 2>/dev/null \
            | awk '{print $1, $3}' \
            | fzf $__FK_FZF_OPTS --prompt "  📜 Pod ❯ " --no-preview --no-multi \
            | awk '{print $1}')
        test -z "$pod"; and return 0
    end

    set -l containers (kubectl get pod $pod -n $ns \
        -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' ')

    set -l ctr ""
    if test (count $containers) -gt 1
        set ctr (printf '%s\n' $containers | fzf \
            --prompt "  📦 Container ❯ " \
            --height=25% --layout=reverse --border=rounded --no-preview)
        test -z "$ctr"; and return 0
        set ctr "-c $ctr"
    end

    set -l mode (printf "Follow\nTail 100\nTail 500\nSince 1h\nAll" | fzf \
        --prompt "  📜 Mode ❯ " \
        --height=25% --layout=reverse --border=rounded --no-preview \
        --header "  $pod")

    test -z "$mode"; and return 0

    switch $mode
        case "Follow"
            eval kubectl logs -f --tail=50 $ctr $pod -n $ns
        case "Tail 100"
            eval kubectl logs --tail=100 $ctr $pod -n $ns 2>&1 \
                | bat --style=plain --color=always --language=log 2>/dev/null \
                | less -R
        case "Tail 500"
            eval kubectl logs --tail=500 $ctr $pod -n $ns 2>&1 | less -R
        case "*1h*"
            eval kubectl logs --since=1h $ctr $pod -n $ns 2>&1 | less -R
        case "All"
            eval kubectl logs $ctr $pod -n $ns 2>&1 | less -R
    end
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  EXEC INTO POD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_exec --description "☸️  Exec into K8s pod"
    set -l pod $argv[1]
    set -l ns  (test -n "$argv[2]"; and echo $argv[2]; or echo (__fk_ns))

    if test -z "$pod"
        set pod (kubectl get pods -n $ns --no-headers 2>/dev/null \
            | grep Running \
            | fzf $__FK_FZF_OPTS --prompt "  🖥️  Exec ❯ " --no-preview --no-multi \
            | awk '{print $1}')
        test -z "$pod"; and return 0
    end

    set -l containers (kubectl get pod $pod -n $ns \
        -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' ')

    set -l ctr $containers[1]
    if test (count $containers) -gt 1
        set ctr (printf '%s\n' $containers | fzf \
            --prompt "  📦 Container ❯ " \
            --height=25% --layout=reverse --border=rounded --no-preview)
        test -z "$ctr"; and return 0
    end

    set -l shell (printf "sh\nbash\nzsh\nfish" | fzf \
        --prompt "  🐚 Shell ❯ " \
        --height=20% --layout=reverse --border=rounded --no-preview)
    test -z "$shell"; and set shell sh

    kubectl exec -it $pod -n $ns -c $ctr -- $shell
end

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  KEY BINDINGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function __fk_bind_keys
    bind \e\ck fzf_kubectl
    bind \e\cn fzf_kubectl_context

    if bind -M insert >/dev/null 2>&1
        bind -M insert \e\ck fzf_kubectl
        bind -M insert \e\cn fzf_kubectl_context
    end
end

status is-interactive; and __fk_bind_keys

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# §  HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function fzf_kubectl_help
    echo ""
    echo "$_BL  ╔══════════════════════════════════════════════════════════════╗$_R"
    echo "$_BL  ║$_R  ☸️   $_CY$_B fzf_kubectl$_R · $_D v$__FK_VERSION · ASH Dotfiles OMEGA$_R      $_BL║$_R"
    echo "$_BL  ╚══════════════════════════════════════════════════════════════╝$_R"
    echo ""
    printf "  $_YE%-38s$_R %s\n" "FUNCTION"                  "DESCRIPTION"
    printf "  $_D%s$_R\n" (string repeat -n 66 '─')
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl"               "Full K8s dashboard"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_context"       "Context/namespace switcher"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_pod [ns]"      "Pod browser + actions"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_deploy [ns]"   "Deployment manager"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_service [ns]"  "Service + port-forward"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_resource [ns]" "Generic resource browser"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_apply"         "Apply/diff/delete manifests"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_logs [pod] [ns]" "Pod log browser"
    printf "  $_GR%-38s$_R %s\n" "fzf_kubectl_exec [pod] [ns]" "Exec into pod"
    echo ""
    printf "  $_CY%-20s$_R %s\n" "Ctrl+Alt+K"  "K8s dashboard"
    printf "  $_CY%-20s$_R %s\n" "Ctrl+Alt+N"  "Context switcher"
    echo ""
end
