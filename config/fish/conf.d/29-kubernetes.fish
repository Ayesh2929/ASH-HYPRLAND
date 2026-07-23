# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🐟 ASH DOTFILES v5.0 — Kubernetes Ultra Configuration                     ║
# ║  kubectl, helm, k9s, kustomize, context switching & full k8s ecosystem     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Guard: Only load in interactive sessions ─────────────────────────────────
status is-interactive || exit 0

# ── Guard: Prevent double-loading ────────────────────────────────────────────
set --query _ash_k8s_loaded && exit 0
set --global _ash_k8s_loaded 1

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 DETECTION                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

if not command -q kubectl
    exit 0
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📁 PATHS & CONSTANTS                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set --global _ash_k8s_log       "$HOME/.local/share/ash/logs/k8s.log"
set --global _ash_k8s_cache     "$HOME/.local/share/ash/cache/k8s"
set --global _ash_k8s_cache_ttl 15   # seconds (k8s state changes fast)

mkdir -p (dirname $_ash_k8s_log) 2>/dev/null
mkdir -p $_ash_k8s_cache 2>/dev/null

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨 COLORS & UI                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -g _k8s_reset   (set_color normal)
set -g _k8s_bold    (set_color --bold)
set -g _k8s_blue    (set_color 326CE5)   # Kubernetes blue
set -g _k8s_cyan    (set_color cyan)
set -g _k8s_green   (set_color green)
set -g _k8s_yellow  (set_color yellow)
set -g _k8s_red     (set_color red)
set -g _k8s_purple  (set_color magenta)
set -g _k8s_dim     (set_color brblack)
set -g _k8s_white   (set_color white)

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚙️  ENVIRONMENT SETUP                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# KUBECONFIG — merge multiple configs
set -l _kube_configs "$HOME/.kube/config"
for extra_cfg in \
    "$HOME/.kube/configs/*.yaml" \
    "$HOME/.kube/configs/*.yml" \
    "$HOME/.kube/custom.yaml"
    for f in $extra_cfg
        test -f $f && set _kube_configs "$_kube_configs:$f"
    end
end
set --export KUBECONFIG $_kube_configs

# kubectl default namespace
set --export KUBECTL_NAMESPACE "default"

# Disable kube-ps1 (we use starship)
set --export KUBE_PS1_ENABLED off

# stern (multi-pod log streaming)
if command -q stern
    set --export STERN_SINCE "1h"
end

# Helm
if command -q helm
    set --export HELM_CACHE_HOME  "$HOME/.cache/helm"
    set --export HELM_CONFIG_HOME "$HOME/.config/helm"
    set --export HELM_DATA_HOME   "$HOME/.local/share/helm"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎯 KUBECTL PLUGIN: kubectx/kubens fallback                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Use kubectx/kubens if available, else pure Fish implementations

function __k8s_contexts --description "List kubectl contexts"
    kubectl config get-contexts -o name 2>/dev/null
end

function __k8s_namespaces --description "List namespaces in current context"
    kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | \
        string split ' ' | string replace ' ' '\n'
end

function __k8s_current_context --description "Get current kubectl context"
    kubectl config current-context 2>/dev/null
end

function __k8s_current_namespace --description "Get current namespace"
    kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄 CONTEXT & NAMESPACE MANAGEMENT                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── kctx: Switch kubectl context ─────────────────────────────────────────────
function kctx --description "Switch or list kubectl contexts"
    set -l context $argv[1]

    if command -q kubectx && test -z "$context"
        kubectx
        return
    end

    if test -z "$context"
        # Interactive fuzzy picker
        if command -q fzf
            set context (
                kubectl config get-contexts \
                    --output=name 2>/dev/null |
                fzf --ansi \
                    --border-label "  ☸  Select Kubernetes Context " \
                    --border rounded \
                    --prompt "  ☸  " \
                    --pointer "▶" \
                    --marker "✓" \
                    --preview 'kubectl config view --context={} 2>/dev/null | bat --language=yaml --style=plain --color=always 2>/dev/null || cat' \
                    --preview-window 'right:50%:border-rounded:wrap' \
                    --header "  Current: $(kubectl config current-context 2>/dev/null)  " \
                    --header-first
            )
            test -z "$context" && return 0
        else
            # Plain listing
            echo ""
            set -l current (__k8s_current_context)
            echo $_k8s_bold$_k8s_blue"  ☸  Kubernetes Contexts"$_k8s_reset
            echo ""
            kubectl config get-contexts 2>/dev/null | while read -l line
                if string match -q "$current*" $line
                    echo "  "$_k8s_green"▶ "$line$_k8s_reset
                else
                    echo "    "$_k8s_dim$line$_k8s_reset
                end
            end
            echo ""
            echo "  Usage: kctx <context-name>"
            return
        end
    end

    # Switch context
    kubectl config use-context $context
    and begin
        echo $_k8s_green"  ✓ Context: $context"$_k8s_reset
        # Invalidate namespace cache
        rm -f "$_ash_k8s_cache/namespaces" 2>/dev/null
    end
end

# ─── kns: Switch kubectl namespace ────────────────────────────────────────────
function kns --description "Switch or list kubectl namespaces"
    set -l ns $argv[1]

    if command -q kubens && test -z "$ns"
        kubens
        return
    end

    if test -z "$ns"
        if command -q fzf
            set ns (
                kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | \
                string split ' ' |
                tr ' ' '\n' |
                fzf --ansi \
                    --border-label "  ☸  Select Namespace " \
                    --border rounded \
                    --prompt "  🏷  " \
                    --pointer "▶" \
                    --preview 'kubectl get all -n {} 2>/dev/null | head -30' \
                    --preview-window 'right:50%:border-rounded:wrap' \
                    --header "  Current: $(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)  "
            )
            test -z "$ns" && return 0
        else
            kubectl get namespaces 2>/dev/null
            echo ""
            echo "  Usage: kns <namespace>"
            return
        end
    end

    # Switch namespace in current context
    kubectl config set-context --current --namespace=$ns
    and echo $_k8s_green"  ✓ Namespace: $ns"$_k8s_reset
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📊 RESOURCE DASHBOARDS                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function __k8s_header --description "Print k8s section header"
    set -l title $argv[1]
    set -l ctx   (__k8s_current_context)
    set -l ns    (__k8s_current_namespace)
    test -z "$ns" && set ns default

    echo ""
    echo $_k8s_bold$_k8s_blue"  ╔══════════════════════════════════════════════════════╗"$_k8s_reset
    echo $_k8s_bold$_k8s_blue"  ║  $_k8s_white$title"$_k8s_reset
    echo $_k8s_bold$_k8s_blue"  ║  "$_k8s_dim"ctx: "$_k8s_cyan$ctx$_k8s_dim"  ns: "$_k8s_cyan$ns$_k8s_blue"  ║"$_k8s_reset
    echo $_k8s_bold$_k8s_blue"  ╚══════════════════════════════════════════════════════╝"$_k8s_reset
    echo ""
end

# ─── k8s-info: Full cluster overview ──────────────────────────────────────────
function k8s-info --description "Show complete Kubernetes cluster information"
    __k8s_header "☸  Kubernetes Cluster Overview                     "

    set -l ctx (__k8s_current_context)
    set -l ns  (__k8s_current_namespace)
    test -z "$ns" && set ns default

    echo "  "$_k8s_bold"Context:   "$_k8s_reset $_k8s_blue$ctx$_k8s_reset
    echo "  "$_k8s_bold"Namespace: "$_k8s_reset $_k8s_cyan$ns$_k8s_reset

    # Server version
    set -l server_ver (kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')
    echo "  "$_k8s_bold"Server:    "$_k8s_reset $_k8s_dim$server_ver$_k8s_reset
    echo ""

    # Node summary
    echo "  "$_k8s_bold"Nodes:"$_k8s_reset
    kubectl get nodes \
        --no-headers \
        -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLES:.metadata.labels.kubernetes\.io/role,VERSION:.status.nodeInfo.kubeletVersion,CPU:.status.capacity.cpu,MEM:.status.capacity.memory' \
        2>/dev/null | while read -l line
            set -l parts (string split ' ' $line | string split --no-empty ' ')
            if string match -q '*Ready*' $line
                echo "    "$_k8s_green"✓ "$line$_k8s_reset
            else
                echo "    "$_k8s_red"✗ "$line$_k8s_reset
            end
    end
    echo ""

    # Resource counts
    echo "  "$_k8s_bold"Resources ($ns):"$_k8s_reset
    for resource in pods deployments services configmaps secrets
        set -l count (kubectl get $resource -n $ns --no-headers 2>/dev/null | wc -l | string trim)
        printf "    $_k8s_cyan%-20s$_k8s_reset %s\n" $resource $count
    end
    echo ""
end

# ─── kpods: Rich pod listing ──────────────────────────────────────────────────
function kpods --description "Rich pod listing with status colors"
    set -l ns   $argv[1]
    set -l flag ""

    if test "$ns" = all || test "$ns" = -A
        set flag "--all-namespaces"
    else if test -n "$ns"
        set flag "-n $ns"
    end

    __k8s_header "🫛  Pods"

    kubectl get pods $flag \
        -o wide \
        --no-headers 2>/dev/null | \
    while read -l line
        if string match -q '*Running*' $line
            echo "  "$_k8s_green"● "$line$_k8s_reset
        else if string match -q '*Completed*' $line
            echo "  "$_k8s_cyan"✓ "$line$_k8s_reset
        else if string match -q '*Error*' $line || string match -q '*CrashLoop*' $line
            echo "  "$_k8s_red"✗ "$line$_k8s_reset
        else if string match -q '*Pending*' $line || string match -q '*Init*' $line
            echo "  "$_k8s_yellow"⏳ "$line$_k8s_reset
        else
            echo "  "$_k8s_dim"○ "$line$_k8s_reset
        end
    end
    echo ""
end

# ─── ksvcs: Services listing ──────────────────────────────────────────────────
function ksvcs --description "List Kubernetes services"
    __k8s_header "🔌  Services"
    kubectl get services -o wide 2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_k8s_bold$_k8s_blue$line$_k8s_reset
        else
            echo "  "$line
        end
    end
    echo ""
end

# ─── kdeps: Deployments listing ───────────────────────────────────────────────
function kdeps --description "List Kubernetes deployments with availability"
    __k8s_header "🚀  Deployments"
    kubectl get deployments -o wide 2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_k8s_bold$_k8s_blue$line$_k8s_reset
        else
            # Check ready/desired ratio
            set -l parts (string split -n ' ' $line)
            set -l ready   $parts[2]
            set -l desired (string split '/' $ready)[2]
            set -l actual  (string split '/' $ready)[1]

            if test "$actual" = "$desired"
                echo "  "$_k8s_green"✓ "$line$_k8s_reset
            else
                echo "  "$_k8s_yellow"⚠ "$line$_k8s_reset
            end
        end
    end
    echo ""
end

# ─── kall: Show all resources in namespace ────────────────────────────────────
function kall --description "Show all resources in current namespace"
    set -l ns $argv[1]
    test -z "$ns" && set ns (__k8s_current_namespace)
    test -z "$ns" && set ns default

    __k8s_header "📋  All Resources (namespace: $ns)"

    for resource in pods deployments replicasets statefulsets daemonsets \
        services ingresses configmaps secrets pvc jobs cronjobs \
        serviceaccounts roles rolebindings
        set -l count (kubectl get $resource -n $ns --no-headers 2>/dev/null | wc -l | string trim)
        if test $count -gt 0
            echo "  "$_k8s_bold$_k8s_cyan"┌─ $resource ($count)"$_k8s_reset
            kubectl get $resource -n $ns --no-headers 2>/dev/null | head -5 | \
                while read -l line
                    echo "  "$_k8s_dim"│ "$_k8s_reset$line
                end
            echo ""
        end
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍 SMART RESOURCE OPERATIONS                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── kexec: Interactive pod exec ──────────────────────────────────────────────
function kexec --description "Interactive exec into Kubernetes pod"
    set -l pod $argv[1]
    set -l container $argv[2]
    set -l ns   (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$pod"
        set pod (
            kubectl get pods -n $ns --no-headers 2>/dev/null |
            grep Running |
            fzf --ansi \
                --border-label "  ☸  Select Pod " \
                --border rounded \
                --prompt "  🫛  " \
                --pointer "▶" \
                --preview 'kubectl describe pod {1} -n '"$ns"' 2>/dev/null | head -40' \
                --preview-window 'right:45%:border-rounded:wrap' \
                --header '  Enter:exec  Ctrl-L:logs  Ctrl-D:describe  ' \
                --bind 'ctrl-l:execute(kubectl logs -f {1} -n '"$ns"' | less -R)' \
                --bind 'ctrl-d:execute(kubectl describe pod {1} -n '"$ns"' | less)' \
            | awk '{print $1}'
        )
        test -z "$pod" && return 0
    end

    # Determine containers if not specified
    if test -z "$container"
        set -l containers (kubectl get pod $pod -n $ns \
            -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | string split ' ')

        if test (count $containers) -gt 1 && command -q fzf
            set container (
                printf '%s\n' $containers |
                fzf --border-label "  🐳 Select Container " \
                    --border rounded \
                    --prompt "  " \
                    --no-multi
            )
        else if test (count $containers) -eq 1
            set container $containers[1]
        end
    end

    set -l container_flag ""
    test -n "$container" && set container_flag "-c $container"

    echo $_k8s_cyan"  ☸ Exec: $pod"(test -n "$container" && echo " [$container]")$_k8s_reset

    # Try shells in preference order
    for sh in bash zsh fish sh
        kubectl exec -it $pod -n $ns $container_flag -- \
            sh -c "command -v $sh && exec $sh" 2>/dev/null && return
    end
end

# ─── klogs: Smart pod log streaming ──────────────────────────────────────────
function klogs --description "Smart Kubernetes pod log streaming"
    set -l pod  $argv[1]
    set -l tail $argv[2]
    set -l ns   (__k8s_current_namespace)
    test -z "$ns"   && set ns default
    test -z "$tail" && set tail 100

    if test -z "$pod"
        set pod (
            kubectl get pods -n $ns --no-headers 2>/dev/null |
            fzf --ansi \
                --border-label "  📋 Select Pod for Logs " \
                --border rounded \
                --prompt "  🫛  " \
                --pointer "▶" \
                --multi \
                --header '  Enter:tail  Tab:multi (stern)  ' \
                --preview 'kubectl logs --tail=20 {1} -n '"$ns"' 2>/dev/null' \
                --preview-window 'down:40%:border-rounded:wrap' \
            | awk '{print $1}'
        )
        test -z "$pod" && return 0
    end

    # Multi-pod streaming with stern
    set -l pod_count (count $pod)
    if test $pod_count -gt 1 && command -q stern
        echo $_k8s_cyan"  📋 Streaming logs from $pod_count pods via stern..."$_k8s_reset
        stern -n $ns (string join '|' $pod) $argv[3..-1]
        return
    end

    # Single pod
    kubectl logs -f --tail=$tail -n $ns $pod $argv[3..-1]
end

# ─── kdesc: Smart describe resource ───────────────────────────────────────────
function kdesc --description "Describe a Kubernetes resource (interactive)"
    set -l resource_type $argv[1]
    set -l resource_name $argv[2]
    set -l ns            (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$resource_type"
        set resource_type (
            printf 'pod\ndeployment\nservice\ningress\nconfigmap\nsecret\nstatefulset\ndaemonset\njob\ncronjob\nnode\npersistentvolumeclaim\n' |
            fzf --border-label "  ☸  Resource Type " \
                --border rounded \
                --prompt "  📋 " \
                --no-multi
        )
        test -z "$resource_type" && return 0
    end

    if test -z "$resource_name"
        set resource_name (
            kubectl get $resource_type -n $ns --no-headers 2>/dev/null |
            fzf --border-label "  ☸  Select $resource_type " \
                --border rounded \
                --prompt "  " \
                --preview "kubectl describe $resource_type {1} -n $ns 2>/dev/null | head -50" \
                --preview-window 'right:55%:border-rounded:wrap' \
            | awk '{print $1}'
        )
        test -z "$resource_name" && return 0
    end

    kubectl describe $resource_type $resource_name -n $ns 2>/dev/null | \
        command -q bat && bat --language=yaml --style=plain || less
end

# ─── kedit: Edit resource in EDITOR ───────────────────────────────────────────
function kedit --description "Edit a Kubernetes resource"
    set -l resource_type $argv[1]
    set -l resource_name $argv[2]
    set -l ns            (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$resource_type" || test -z "$resource_name"
        echo "  Usage: kedit <resource-type> <name>"
        return 1
    end

    KUBE_EDITOR="${EDITOR:-nvim}" kubectl edit $resource_type $resource_name -n $ns
end

# ─── kscale: Scale deployment interactively ────────────────────────────────────
function kscale --description "Scale a Kubernetes deployment"
    set -l deploy  $argv[1]
    set -l replicas $argv[2]
    set -l ns      (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$deploy"
        set deploy (
            kubectl get deployments -n $ns --no-headers 2>/dev/null |
            fzf --border-label "  🔧 Scale Deployment " \
                --border rounded \
                --prompt "  🚀 " \
                --preview 'kubectl get deployment {1} -n '"$ns"' -o yaml 2>/dev/null | grep "replicas:" | head -5' \
                --preview-window 'down:3:border-rounded' \
            | awk '{print $1}'
        )
        test -z "$deploy" && return 0
    end

    if test -z "$replicas"
        set -l current (kubectl get deployment $deploy -n $ns \
            -o jsonpath='{.spec.replicas}' 2>/dev/null)
        read -P "  Replicas (current: $current): " replicas
    end

    test -z "$replicas" && return 1

    kubectl scale deployment $deploy --replicas=$replicas -n $ns
    and echo $_k8s_green"  ✓ $deploy scaled to $replicas replica(s)"$_k8s_reset
end

# ─── krestart: Rolling restart deployment ─────────────────────────────────────
function krestart --description "Rolling restart a Kubernetes deployment"
    set -l deploy $argv[1]
    set -l ns     (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$deploy"
        set deploy (
            kubectl get deployments -n $ns --no-headers 2>/dev/null |
            fzf --border-label "  🔄 Restart Deployment " \
                --border rounded \
                --prompt "  🚀 " \
                --multi \
                --header '  Tab:multi  Enter:restart  ' \
            | awk '{print $1}'
        )
        test -z "$deploy" && return 0
    end

    for d in $deploy
        kubectl rollout restart deployment/$d -n $ns
        and echo $_k8s_green"  ✓ Restarting: $d"$_k8s_reset
    end
end

# ─── kwatch: Watch resources with auto-refresh ────────────────────────────────
function kwatch --description "Watch Kubernetes resources with auto-refresh"
    set -l resource $argv[1]
    test -z "$resource" && set resource "pods"

    kubectl get $resource --watch $argv[2..-1]
end

# ─── krollout: Manage deployment rollouts ─────────────────────────────────────
function krollout --description "Manage Kubernetes deployment rollouts"
    set -l action $argv[1]
    set -l deploy $argv[2]
    set -l ns     (__k8s_current_namespace)
    test -z "$ns" && set ns default

    switch $action
        case status
            kubectl rollout status deployment/$deploy -n $ns
        case history
            kubectl rollout history deployment/$deploy -n $ns
        case undo
            kubectl rollout undo deployment/$deploy -n $ns
            and echo $_k8s_green"  ✓ Rollback complete"$_k8s_reset
        case pause
            kubectl rollout pause deployment/$deploy -n $ns
        case resume
            kubectl rollout resume deployment/$deploy -n $ns
        case '*'
            echo "  Usage: krollout <status|history|undo|pause|resume> <deployment>"
    end
end

# ─── kport: Port-forward with interactive picker ──────────────────────────────
function kport --description "Port-forward to a Kubernetes pod/service"
    set -l local_port  $argv[1]
    set -l remote_port $argv[2]
    set -l target      $argv[3]
    set -l ns          (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$target"
        set target (
            begin
                kubectl get pods    -n $ns --no-headers 2>/dev/null | awk '{print "pod/"$1}'
                kubectl get services -n $ns --no-headers 2>/dev/null | awk '{print "svc/"$1}'
            end |
            fzf --border-label "  🔌 Port Forward " \
                --border rounded \
                --prompt "  " \
                --preview 'kubectl describe {} -n '"$ns"' 2>/dev/null | grep -A5 "Ports:" | head -10' \
                --preview-window 'down:5:border-rounded'
        )
        test -z "$target" && return 0
    end

    if test -z "$local_port"
        read -P "  Local port:  " local_port
        read -P "  Remote port: " remote_port
    end

    test -z "$remote_port" && set remote_port $local_port

    echo $_k8s_cyan"  🔌 Forwarding localhost:$local_port → $target:$remote_port"$_k8s_reset
    kubectl port-forward $target $local_port:$remote_port -n $ns
end

# ─── kapply: Apply manifests with diff preview ────────────────────────────────
function kapply --description "Apply Kubernetes manifests with diff preview"
    set -l manifest $argv[1]
    test -z "$manifest" && set manifest "."

    echo ""
    echo $_k8s_cyan"  📋 Previewing changes..."$_k8s_reset
    echo ""

    # Show diff first
    kubectl diff -f $manifest 2>/dev/null | \
        command -q bat && bat --language=diff --style=plain --color=always || cat

    echo ""
    read -P "  Apply changes? [y/N] " confirm
    string match -qi 'y*' $confirm || return 0

    kubectl apply -f $manifest $argv[2..-1]
    and echo $_k8s_green"  ✓ Manifests applied"$_k8s_reset
end

# ─── kdelete-pod: Delete pod (restart it) ─────────────────────────────────────
function kdelete-pod --description "Delete a pod to force recreation"
    set -l pod $argv[1]
    set -l ns  (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$pod"
        set pod (
            kubectl get pods -n $ns --no-headers 2>/dev/null |
            fzf --border-label "  🗑  Delete Pod (force restart) " \
                --border rounded \
                --prompt "  🫛  " \
                --multi \
                --header '  Tab:multi  Enter:delete  '
        )
        test -z "$pod" && return 0
    end

    for p in $pod
        kubectl delete pod $p -n $ns
        and echo $_k8s_green"  ✓ Deleted: $p"$_k8s_reset
    end
end

# ─── kget-secret: Decode and show secret values ───────────────────────────────
function kget-secret --description "Decode and display Kubernetes secret"
    set -l secret $argv[1]
    set -l ns     (__k8s_current_namespace)
    test -z "$ns" && set ns default

    if test -z "$secret"
        set secret (
            kubectl get secrets -n $ns --no-headers 2>/dev/null |
            fzf --border-label "  🔐 Select Secret " \
                --border rounded \
                --prompt "  🔑 " \
            | awk '{print $1}'
        )
        test -z "$secret" && return 0
    end

    echo ""
    echo $_k8s_bold$_k8s_yellow"  🔐 Secret: $secret"$_k8s_reset
    echo ""

    kubectl get secret $secret -n $ns \
        -o jsonpath='{.data}' 2>/dev/null | \
        command -q python3 && python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
for k, v in data.items():
    try:
        decoded = base64.b64decode(v).decode('utf-8', errors='replace')
    except:
        decoded = '(binary)'
    print(f'  {k}:')
    print(f'    {decoded}')
    print()
" || echo "  (python3 required for decoding)"
end

# ─── kresource-usage: Show pod resource usage ─────────────────────────────────
function kresource-usage --description "Show Kubernetes resource usage"
    set -l type $argv[1]
    test -z "$type" && set type pods

    __k8s_header "📊  Resource Usage"

    switch $type
        case pods
            kubectl top pods --sort-by=cpu 2>/dev/null
        case nodes
            kubectl top nodes --sort-by=cpu 2>/dev/null
        case '*'
            echo "  Usage: kresource-usage [pods|nodes]"
    end
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⛵ HELM OPERATIONS                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function hls --description "List Helm releases"
    __k8s_header "⛵  Helm Releases"

    helm list --all-namespaces \
        --output table 2>/dev/null | \
    while read -l line
        if string match -q 'NAME*' $line
            echo "  "$_k8s_bold$_k8s_blue$line$_k8s_reset
        else if string match -q '*deployed*' $line
            echo "  "$_k8s_green$line$_k8s_reset
        else if string match -q '*failed*' $line
            echo "  "$_k8s_red$line$_k8s_reset
        else
            echo "  "$_k8s_dim$line$_k8s_reset
        end
    end
    echo ""
end

function hup --description "Helm upgrade --install (upsert)"
    set -l release $argv[1]
    set -l chart   $argv[2]

    if test -z "$release" || test -z "$chart"
        echo "  Usage: hup <release> <chart> [--values values.yaml] [--set key=val]"
        return 1
    end

    echo ""
    echo $_k8s_cyan"  ⛵ Upgrading/installing: $release from $chart"$_k8s_reset
    echo ""

    helm upgrade --install \
        --atomic \
        --wait \
        --timeout 5m \
        $release $chart $argv[3..-1]

    and echo $_k8s_green"  ✓ Release deployed: $release"$_k8s_reset
end

function htemplate --description "Render Helm templates locally"
    set -l release $argv[1]
    set -l chart   $argv[2]
    test -z "$release" && set release "release"
    test -z "$chart"   && set chart   "."

    helm template $release $chart $argv[3..-1] | \
        command -q bat && bat --language=yaml --style=plain --color=always || cat
end

function hdiff --description "Diff Helm release values"
    command -q helm-diff || begin
        echo $_k8s_yellow"  Installing helm-diff plugin..."$_k8s_reset
        helm plugin install https://github.com/databus23/helm-diff
    end
    helm diff upgrade $argv
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔧 K8S UTILITIES                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ─── k9s launcher ─────────────────────────────────────────────────────────────
function k9 --description "Launch k9s Kubernetes TUI"
    if command -q k9s
        k9s $argv
    else
        echo $_k8s_yellow"  💡 Install k9s: https://k9scli.io"$_k8s_reset
    end
end

# ─── kstern: Multi-pod log streaming ──────────────────────────────────────────
function kstern --description "Stream logs from multiple pods via stern"
    command -q stern || begin
        echo $_k8s_yellow"  💡 Install stern: https://github.com/stern/stern"$_k8s_reset
        return 1
    end
    stern $argv
end

# ─── kns-create: Create namespace ─────────────────────────────────────────────
function kns-create --description "Create a Kubernetes namespace"
    set -l name $argv[1]
    test -z "$name" && read -P "  Namespace name: " name
    test -z "$name" && return 1

    kubectl create namespace $name
    and begin
        kubectl config set-context --current --namespace=$name
        echo $_k8s_green"  ✓ Created and switched to namespace: $name"$_k8s_reset
    end
end

# ─── kclean-evicted: Remove evicted pods ──────────────────────────────────────
function kclean-evicted --description "Remove all evicted pods"
    echo ""
    echo $_k8s_yellow"  🧹 Removing evicted pods..."$_k8s_reset

    kubectl get pods -A --field-selector=status.phase=Failed \
        --no-headers 2>/dev/null | \
        while read -l ns pod rest
            kubectl delete pod $pod -n $ns 2>/dev/null
            and echo "    "$_k8s_green"✓ "$pod" ($ns)"$_k8s_reset
        end

    echo ""
end

# ─── kcopy: Copy files to/from pods ───────────────────────────────────────────
function kcopy --description "Copy files to/from Kubernetes pods"
    set -l src $argv[1]
    set -l dst $argv[2]

    if test -z "$src" || test -z "$dst"
        echo "  Usage: kcopy <src> <dst>"
        echo "  Example: kcopy pod/my-pod:/app/data ./local-data"
        return 1
    end

    kubectl cp $src $dst
    and echo $_k8s_green"  ✓ Copy complete"$_k8s_reset
end

# ─── kget-all-ns: Get resource across all namespaces ──────────────────────────
function kget-all-ns --description "Get a resource type across all namespaces"
    set -l resource $argv[1]
    test -z "$resource" && set resource pods

    kubectl get $resource --all-namespaces -o wide 2>/dev/null
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅ COMPLETIONS                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# kubectl auto-completions (official)
kubectl completion fish 2>/dev/null | source

# Helm completions
command -q helm && helm completion fish 2>/dev/null | source

# Context/namespace completions for our functions
complete -c kctx -f -a '(__k8s_contexts)'   -d "Kubernetes context"
complete -c kns  -f -a '(__k8s_namespaces)' -d "Kubernetes namespace"

for fn in kpods ksvcs kdeps kall klogs kexec kdesc krestart kscale kdelete-pod kget-secret
    complete -c $fn -n 'test (count (commandline -opc)) -eq 1' \
        -f -a '(__k8s_namespaces)' -d "Namespace"
end

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⌨️  ABBREVIATIONS                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# kubectl core
abbr --add k      'kubectl'
abbr --add kg     'kubectl get'
abbr --add kgp    'kubectl get pods'
abbr --add kgpa   'kubectl get pods -A'
abbr --add kgpw   'kubectl get pods -w'
abbr --add kgs    'kubectl get services'
abbr --add kgd    'kubectl get deployments'
abbr --add kgn    'kubectl get nodes'
abbr --add kgns   'kubectl get namespaces'
abbr --add kgcm   'kubectl get configmaps'
abbr --add kgsec  'kubectl get secrets'
abbr --add kging  'kubectl get ingress'
abbr --add kgpv   'kubectl get pv'
abbr --add kgpvc  'kubectl get pvc'
abbr --add kgsts  'kubectl get statefulsets'
abbr --add kgds   'kubectl get daemonsets'
abbr --add kgj    'kubectl get jobs'
abbr --add kgcj   'kubectl get cronjobs'
abbr --add kgsa   'kubectl get serviceaccounts'

abbr --add ka     'kubectl apply -f'
abbr --add kd     'kubectl delete'
abbr --add kdp    'kubectl delete pod'
abbr --add kdf    'kubectl delete -f'
abbr --add ke     'kubectl edit'
abbr --add kr     'kubectl replace -f'

abbr --add kl     'kubectl logs'
abbr --add klf    'kubectl logs -f'
abbr --add klt    'kubectl logs --tail=100'

# Context/Namespace
abbr --add kc     'kctx'
abbr --add kn     'kns'
abbr --add kcur   '__k8s_current_context'
abbr --add kcns   '__k8s_current_namespace'

# Interactive commands
abbr --add kex    'kexec'
abbr --add klogs  'klogs'
abbr --add kdesc  'kdesc'
abbr --add kwatch 'kwatch'
abbr --add kport  'kport'
abbr --add kapply 'kapply'
abbr --add kscl   'kscale'
abbr --add krest  'krestart'
abbr --add kroll  'krollout'
abbr --add kpods  'kpods'
abbr --add kdeps  'kdeps'
abbr --add ksvcs  'ksvcs'
abbr --add kall   'kall'
abbr --add kinfo  'k8s-info'
abbr --add ktop   'kresource-usage'
abbr --add ksec   'kget-secret'
abbr --add kcp    'kcopy'
abbr --add kevict 'kclean-evicted'
abbr --add knsc   'kns-create'

# Helm
abbr --add h      'helm'
abbr --add hls    'hls'
abbr --add hup    'hup'
abbr --add hdl    'helm delete'
abbr --add hget   'helm get values'
abbr --add hrepo  'helm repo'
abbr --add hrepa  'helm repo add'
abbr --add hrepu  'helm repo update'
abbr --add hsrch  'helm search repo'
abbr --add htmpl  'htemplate'
abbr --add hdiff  'hdiff'
abbr --add htest  'helm test'
abbr --add hrb    'helm rollback'
abbr --add hhist  'helm history'

# k9s
abbr --add k9     'k9'
abbr --add kstern 'kstern'