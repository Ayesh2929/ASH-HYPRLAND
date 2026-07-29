# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ☸️   KUBECTL — FISH COMPLETIONS v5.0 OMEGA                                 ║
# ║  Ultra Premium • Dynamic Resources • Live Contexts • Multi-Cluster         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Fast guard ─────────────────────────────────────────────────────────────────
function __kubectl_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            get describe delete create apply edit patch label annotate \
            expose scale autoscale rollout rolling-update run set \
            logs exec attach port-forward proxy cp top diff \
            explain api-resources api-versions cluster-info \
            config kustomize wait auth debug events \
            plugin version completion cordon uncordon drain taint \
            certificate approve deny replace convert cp \
            --help -h --version
            return 1
        end
    end
    return 0
end

function __kubectl_sub_is --argument-names sub
    contains -- "$sub" (commandline -poc)
end

function __kubectl_pos --argument-names n
    # Return nth positional token (1-indexed, after 'kubectl')
    set -l tokens (commandline -poc)
    set -l pos 0
    for t in $tokens[2..]
        if not string match -qr '^-' $t
            set pos (math $pos + 1)
            if test $pos -eq $n
                echo $t
                return
            end
        end
    end
end

function __kubectl_seen_flag --argument-names flag
    contains -- "$flag" (commandline -poc)
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── Contexts ───────────────────────────────────────────────────────────────────
function __kubectl_contexts
    kubectl config get-contexts -o name 2>/dev/null | sort
end

function __kubectl_contexts_with_desc
    kubectl config get-contexts --no-headers 2>/dev/null | \
        awk '{
            current = ($1 == "*") ? "★ " : "  "
            ctx     = ($1 == "*") ? $2 : $1
            cluster = ($1 == "*") ? $3 : $3
            printf "%s\t%s%s\n", ctx, current, cluster
        }'
end

# ── Namespaces ─────────────────────────────────────────────────────────────────
function __kubectl_namespaces
    kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
        | sort
end

# ── Resource types ─────────────────────────────────────────────────────────────
function __kubectl_resource_types
    kubectl api-resources --verbs=get --output=name 2>/dev/null | sort
end

function __kubectl_resource_types_with_short
    kubectl api-resources --verbs=get --output=wide --no-headers 2>/dev/null | \
        awk '{
            name  = $1
            short = $2
            kind  = $NF
            if (short != "") printf "%s\t%s (%s)\n", name, kind, short
            else             printf "%s\t%s\n", name, kind
        }' | sort
end

# ── Resources of a given type ──────────────────────────────────────────────────
function __kubectl_resources --argument-names type
    set -l ns_flag ""
    __kubectl_seen_flag -A; or __kubectl_seen_flag --all-namespaces
    and set ns_flag "--all-namespaces"

    set -l ns_arg ""
    for i in (seq (count (commandline -poc)))
        set -l t (commandline -poc)[$i]
        if contains -- "$t" -n --namespace
            set ns_arg "--namespace="(commandline -poc)[(math $i + 1)]
        end
    end

    kubectl get $type $ns_flag $ns_arg \
        --no-headers -o custom-columns="NAME:.metadata.name,NS:.metadata.namespace" \
        2>/dev/null | awk '{printf "%s\t%s\n", $1, $2}'
end

# ── Pods ───────────────────────────────────────────────────────────────────────
function __kubectl_pods
    kubectl get pods --no-headers \
        -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName" \
        2>/dev/null | awk '{printf "%s\t%s on %s\n", $1, $2, $3}'
end

# ── Pod containers ─────────────────────────────────────────────────────────────
function __kubectl_containers --argument-names pod
    test -z "$pod"; and return
    kubectl get pod "$pod" \
        -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}' 2>/dev/null
    kubectl get pod "$pod" \
        -o jsonpath='{range .spec.initContainers[*]}{.name}{"\n"}{end}' 2>/dev/null
end

# ── Nodes ──────────────────────────────────────────────────────────────────────
function __kubectl_nodes
    kubectl get nodes --no-headers \
        -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLES:.metadata.labels.kubernetes\\.io/role" \
        2>/dev/null | awk '{printf "%s\t%s\n", $1, $2}'
end

# ── Deployments ────────────────────────────────────────────────────────────────
function __kubectl_deployments
    kubectl get deployments --no-headers \
        -o custom-columns="NAME:.metadata.name,READY:.status.readyReplicas,NS:.metadata.namespace" \
        2>/dev/null | awk '{printf "%s\t%s/%s ready\n", $1, $2, $3}'
end

# ── Services ───────────────────────────────────────────────────────────────────
function __kubectl_services
    kubectl get services --no-headers \
        -o custom-columns="NAME:.metadata.name,TYPE:.spec.type,PORT:.spec.ports[0].port" \
        2>/dev/null | awk '{printf "%s\t%s :%s\n", $1, $2, $3}'
end

# ── ConfigMaps ─────────────────────────────────────────────────────────────────
function __kubectl_configmaps
    kubectl get configmaps --no-headers -o name 2>/dev/null | sed 's|configmap/||'
end

# ── Secrets ────────────────────────────────────────────────────────────────────
function __kubectl_secrets
    kubectl get secrets --no-headers \
        -o custom-columns="NAME:.metadata.name,TYPE:.type" \
        2>/dev/null | awk '{printf "%s\t%s\n", $1, $2}'
end

# ── Jobs ───────────────────────────────────────────────────────────────────────
function __kubectl_jobs
    kubectl get jobs --no-headers -o name 2>/dev/null | sed 's|job.batch/||'
end

# ── CronJobs ───────────────────────────────────────────────────────────────────
function __kubectl_cronjobs
    kubectl get cronjobs --no-headers \
        -o custom-columns="NAME:.metadata.name,SCHEDULE:.spec.schedule" \
        2>/dev/null | awk '{printf "%s\t%s\n", $1, $2}'
end

# ── Ingresses ──────────────────────────────────────────────────────────────────
function __kubectl_ingresses
    kubectl get ingress --no-headers \
        -o custom-columns="NAME:.metadata.name,HOSTS:.spec.rules[0].host" \
        2>/dev/null | awk '{printf "%s\t%s\n", $1, $2}'
end

# ── PVCs ───────────────────────────────────────────────────────────────────────
function __kubectl_pvcs
    kubectl get pvc --no-headers \
        -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,SIZE:.spec.resources.requests.storage" \
        2>/dev/null | awk '{printf "%s\t%s %s\n", $1, $2, $3}'
end

# ── PVs ────────────────────────────────────────────────────────────────────────
function __kubectl_pvs
    kubectl get pv --no-headers \
        -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,SIZE:.spec.capacity.storage" \
        2>/dev/null | awk '{printf "%s\t%s %s\n", $1, $2, $3}'
end

# ── StatefulSets ───────────────────────────────────────────────────────────────
function __kubectl_statefulsets
    kubectl get statefulsets --no-headers -o name 2>/dev/null | sed 's|statefulset.apps/||'
end

# ── DaemonSets ─────────────────────────────────────────────────────────────────
function __kubectl_daemonsets
    kubectl get daemonsets --no-headers -o name 2>/dev/null | sed 's|daemonset.apps/||'
end

# ── ReplicaSets ────────────────────────────────────────────────────────────────
function __kubectl_replicasets
    kubectl get replicasets --no-headers -o name 2>/dev/null | sed 's|replicaset.apps/||'
end

# ── Service accounts ──────────────────────────────────────────────────────────
function __kubectl_serviceaccounts
    kubectl get serviceaccounts --no-headers -o name 2>/dev/null | sed 's|serviceaccount/||'
end

# ── Roles & ClusterRoles ──────────────────────────────────────────────────────
function __kubectl_roles
    kubectl get roles --no-headers -o name 2>/dev/null | sed 's|role.rbac.authorization.k8s.io/||'
end

function __kubectl_clusterroles
    kubectl get clusterroles --no-headers -o name 2>/dev/null | \
        sed 's|clusterrole.rbac.authorization.k8s.io/||' | grep -v '^system:'
end

# ── Images (from pods) ────────────────────────────────────────────────────────
function __kubectl_images
    kubectl get pods -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' \
        2>/dev/null | tr ' ' '\n' | sort -u
end

# ── Labels ────────────────────────────────────────────────────────────────────
function __kubectl_labels --argument-names type
    test -z "$type"; and set type pods
    kubectl get $type --show-labels --no-headers 2>/dev/null | \
        awk '{print $NF}' | tr ',' '\n' | sort -u
end

# ── Kubeconfig files ──────────────────────────────────────────────────────────
function __kubectl_kubeconfigs
    # Base config
    test -f ~/.kube/config; and echo ~/.kube/config
    # Subconfigs
    test -d ~/.kube/configs; and find ~/.kube/configs -type f 2>/dev/null
    # KUBECONFIG env var
    test -n "$KUBECONFIG"; and for f in (string split ":" "$KUBECONFIG"); test -f "$f"; and echo "$f"; end
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l kube_commands \
    "get\t📋 Display resources" \
    "describe\t📖 Show detailed info" \
    "create\t✨ Create resource" \
    "apply\t✅ Apply config" \
    "delete\t🗑️  Delete resources" \
    "edit\t✏️  Edit resource in editor" \
    "patch\t🔧 Update resource fields" \
    "replace\t🔄 Replace resource" \
    "label\t🏷️  Label resources" \
    "annotate\t📝 Annotate resources" \
    "expose\t🔌 Expose as service" \
    "scale\t📈 Scale a resource" \
    "autoscale\t⚖️  Autoscale resource" \
    "rollout\t🔄 Manage rollouts" \
    "run\t🚀 Run image in cluster" \
    "set\t⚙️  Set fields on resources" \
    "exec\t🖥️  Execute in container" \
    "attach\t🔗 Attach to container" \
    "logs\t📜 Print container logs" \
    "port-forward\t🔌 Forward ports" \
    "proxy\t🌐 Run proxy to API server" \
    "cp\t📋 Copy files to/from container" \
    "top\t📊 Display resource usage" \
    "diff\t🔍 Diff live vs file" \
    "explain\t📚 Resource documentation" \
    "api-resources\t📦 List API resources" \
    "api-versions\t📌 List API versions" \
    "cluster-info\t🏥 Cluster info" \
    "config\t⚙️  kubeconfig management" \
    "kustomize\t🎨 Build kustomization" \
    "wait\t⏳ Wait for resource condition" \
    "auth\t🔒 Inspect authorization" \
    "debug\t🐛 Create debug session" \
    "events\t📡 List events" \
    "plugin\t🔌 Plugin management" \
    "cordon\t🚧 Mark node as unschedulable" \
    "uncordon\t✅ Mark node as schedulable" \
    "drain\t💧 Drain node for maintenance" \
    "taint\t🏷️  Taint/untaint nodes" \
    "certificate\t🔐 Certificate operations" \
    "completion\t🐟 Shell completion" \
    "version\t📌 Print version"

complete -c kubectl -f -n __kubectl_no_subcommand -a "$kube_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
complete -c kubectl -l help              -s h  -d "Help for command"              -f
complete -c kubectl -l version               -d "Print version"                  -f
complete -c kubectl -l namespace         -s n  -d "Target namespace"             -f \
    -a "(__kubectl_namespaces)"
complete -c kubectl -l all-namespaces    -s A  -d "All namespaces"               -f
complete -c kubectl -l context               -d "kubeconfig context"             -f \
    -a "(__kubectl_contexts)"
complete -c kubectl -l cluster               -d "Cluster from kubeconfig"        -f
complete -c kubectl -l user                  -d "kubeconfig user"                -f
complete -c kubectl -l kubeconfig            -d "Path to kubeconfig"             -F \
    -a "(__kubectl_kubeconfigs)"
complete -c kubectl -l server            -s s  -d "API server URL"               -f
complete -c kubectl -l token                 -d "Bearer token for auth"          -f
complete -c kubectl -l as                    -d "Impersonate as user"            -f
complete -c kubectl -l as-group              -d "Impersonate group"              -f
complete -c kubectl -l as-uid               -d "Impersonate UID"                 -f
complete -c kubectl -l cache-dir             -d "Cache dir"                      -F
complete -c kubectl -l certificate-authority -d "CA certificate path"           -F
complete -c kubectl -l client-certificate    -d "Client certificate path"       -F
complete -c kubectl -l client-key            -d "Client key path"               -F
complete -c kubectl -l insecure-skip-tls-verify -d "Skip TLS verification"      -f
complete -c kubectl -l tls-server-name       -d "TLS server name"               -f
complete -c kubectl -l timeout               -d "Request timeout"               -f \
    -a "0\tNo timeout 30s\t30 seconds 1m\t1 minute 5m\t5 minutes"
complete -c kubectl -l request-timeout       -d "Request timeout (alias)"       -f
complete -c kubectl -l output            -s o  -d "Output format"               -f \
    -a "json\tJSON yaml\tYAML name\tNames only wide\tExtra columns \
        jsonpath=\tJSONPath custom-columns=\tCustom cols go-template=\tGo template \
        template=\tTemplate table\tTable"
complete -c kubectl -l v -l log-backtrace-at -d "Verbosity level (0-9)"         -f \
    -a "0 1 2 3 4 5 6 7 8 9"
complete -c kubectl -l warnings-as-errors     -d "Exit non-zero on warnings"    -f
complete -c kubectl -l field-manager          -d "Manager name for field mgmt"  -f
complete -c kubectl -l selector          -s l  -d "Label selector"              -f \
    -a "(__kubectl_labels)"
complete -c kubectl -l field-selector         -d "Field selector"               -f

# ══════════════════════════════════════════════════════════════════════════════
#  GET
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is get; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_resource_types_with_short)"

# Resource-specific name completions
for res in pods pod po
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_pods)"
end
for res in deployments deployment deploy
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_deployments)"
end
for res in services service svc
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_services)"
end
for res in nodes node no
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_nodes)"
end
for res in configmaps configmap cm
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_configmaps)"
end
for res in secrets secret
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_secrets)"
end
for res in ingresses ingress ing
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_ingresses)"
end
for res in pvc persistentvolumeclaims
    complete -c kubectl -n "__kubectl_sub_is get; and __kubectl_seen_flag $res" \
        -f -a "(__kubectl_pvcs)"
end

# GET flags
complete -c kubectl -n "__kubectl_sub_is get" \
    -l watch             -s w  -d "Watch for changes"                       -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l watch-only             -d "Watch only, don't list first"             -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l show-labels            -d "Show labels column"                       -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l label-columns     -L   -d "Extra label columns"                      -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l no-headers             -d "Don't print headers"                      -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l sort-by                -d "Sort by JSONPath expression"              -f \
    -a ".metadata.name .metadata.creationTimestamp .status.phase"
complete -c kubectl -n "__kubectl_sub_is get" \
    -l ignore-not-found       -d "Treat not found as no error"              -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l chunk-size             -d "Pagination chunk size"                    -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l field-selector         -d "Filter by field" -f \
    -a "status.phase=Running status.phase=Pending metadata.namespace="
complete -c kubectl -n "__kubectl_sub_is get" \
    -l show-managed-fields    -d "Show managed fields"                      -f
complete -c kubectl -n "__kubectl_sub_is get" \
    -l subresource            -d "Subresource: status/scale"                -f \
    -a "status scale"

# ══════════════════════════════════════════════════════════════════════════════
#  DESCRIBE
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is describe; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_resource_types_with_short)"

complete -c kubectl -n "__kubectl_sub_is describe" \
    -l show-events        -d "Show events related to resource"              -f

# ══════════════════════════════════════════════════════════════════════════════
#  LOGS
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is logs; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_pods)"

# Container completion (after pod name)
complete -c kubectl -n "__kubectl_sub_is logs; and test (count (commandline -poc)) -ge 3; and not __kubectl_seen_flag -c --container" \
    -s c -l container     -d "Container name" -f \
    -a "(__kubectl_containers (__kubectl_pos 1))"

complete -c kubectl -n "__kubectl_sub_is logs" \
    -s f -l follow        -d "Stream logs"                                  -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l previous      -s p -d "Print logs from previous instance"            -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l since              -d "Show logs newer than duration" -f \
    -a "1m\t1 minute 5m\t5 minutes 1h\t1 hour 24h\t24 hours 7d\t7 days"
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l since-time         -d "Show logs since RFC3339 timestamp"            -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l tail               -d "Lines of recent log to show" -f \
    -a "10 20 50 100 500 1000 -1"
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l timestamps         -d "Include RFC3339 timestamps"                   -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l all-containers     -d "All containers in pod"                        -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l ignore-errors      -d "Ignore errors retrieving logs"                -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l max-log-requests   -d "Max parallel log requests"                    -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l prefix             -d "Prefix with pod and container name"           -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -l insecure-skip-tls-verify-backend -d "Skip backend TLS"              -f
complete -c kubectl -n "__kubectl_sub_is logs" \
    -s l -l selector      -d "Selector (label query)"                       -f

# ══════════════════════════════════════════════════════════════════════════════
#  EXEC
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is exec; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_pods)"

complete -c kubectl -n "__kubectl_sub_is exec" \
    -s c -l container     -d "Container name" -f \
    -a "(__kubectl_containers (__kubectl_pos 1))"
complete -c kubectl -n "__kubectl_sub_is exec" \
    -s i -l stdin         -d "Keep stdin open"                              -f
complete -c kubectl -n "__kubectl_sub_is exec" \
    -s t -l tty           -d "Allocate TTY"                                 -f
complete -c kubectl -n "__kubectl_sub_is exec" \
    -l quiet          -s q -d "Suppress informational messages"             -f

# After '--': command completions
complete -c kubectl -n "__kubectl_sub_is exec; and __kubectl_seen_flag --" \
    -f -a "bash sh /bin/bash /bin/sh fish zsh" -d "Shell"
complete -c kubectl -n "__kubectl_sub_is exec; and __kubectl_seen_flag --" \
    -f -a "(__fish_complete_command)"

# ══════════════════════════════════════════════════════════════════════════════
#  APPLY
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is apply" \
    -s f -l filename      -d "Filename/dir/URL"                             -F
complete -c kubectl -n "__kubectl_sub_is apply" \
    -s k -l kustomize     -d "Kustomize dir"                               -F
complete -c kubectl -n "__kubectl_sub_is apply" \
    -s R -l recursive     -d "Recurse into directories"                    -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l dry-run            -d "Dry run mode" -f \
    -a "none\tActually apply client\tClient-side server\tServer-side"
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l force              -d "Force apply"                                  -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l grace-period       -d "Grace period for deletion"                   -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l overwrite          -d "Overwrite local changes"                      -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l prune              -d "Delete resources not in config"               -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l prune-allowlist    -d "Allowlist for pruning"                        -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l server-side        -d "Use server-side apply"                        -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l field-manager      -d "Field manager name"                          -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l force-conflicts    -d "Force apply despite conflicts"                -f
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l validate           -d "Validate resource" -f \
    -a "strict\tStrict warn\tWarn ignore\tIgnore true false"
complete -c kubectl -n "__kubectl_sub_is apply" \
    -l selector       -s l -d "Label selector"                              -f

# ══════════════════════════════════════════════════════════════════════════════
#  DELETE
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is delete; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_resource_types_with_short)"

complete -c kubectl -n "__kubectl_sub_is delete" \
    -s f -l filename      -d "Filename/dir/URL"                             -F
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l force              -d "Force immediate deletion"                     -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l grace-period       -d "Grace period (seconds)"                      -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l cascade            -d "Cascade deletion" -f \
    -a "background\tBackground foreground\tForeground orphan\tOrphan"
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l now                -d "Signal immediate shutdown"                    -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l wait               -d "Wait until deleted"                           -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l ignore-not-found   -d "Ignore not found"                             -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -s R -l recursive     -d "Recurse directories"                         -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -s l -l selector      -d "Label selector"                               -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l all                -d "Delete all in namespace"                      -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -s A -l all-namespaces -d "All namespaces"                              -f
complete -c kubectl -n "__kubectl_sub_is delete" \
    -l dry-run            -d "Dry run" -f \
    -a "none client server"

# ══════════════════════════════════════════════════════════════════════════════
#  CREATE
# ══════════════════════════════════════════════════════════════════════════════

set -l create_sub \
    "clusterrole\t🔐 Create ClusterRole" \
    "clusterrolebinding\t🔗 Create ClusterRoleBinding" \
    "configmap\t⚙️  Create ConfigMap" \
    "cronjob\t⏰ Create CronJob" \
    "deployment\t🚀 Create Deployment" \
    "ingress\t🌐 Create Ingress" \
    "job\t⚙️  Create Job" \
    "namespace\t🗂️  Create Namespace" \
    "poddisruptionbudget\t🛡️  Create PodDisruptionBudget" \
    "priorityclass\t📊 Create PriorityClass" \
    "quota\t📐 Create ResourceQuota" \
    "role\t🔑 Create Role" \
    "rolebinding\t🔗 Create RoleBinding" \
    "secret\t🔒 Create Secret" \
    "service\t🔌 Create Service" \
    "serviceaccount\t👤 Create ServiceAccount" \
    "token\t🎫 Create Token"

complete -c kubectl -n "__kubectl_sub_is create; and not __kubectl_seen_flag \
    clusterrole clusterrolebinding configmap cronjob deployment ingress \
    job namespace poddisruptionbudget priorityclass quota role rolebinding \
    secret service serviceaccount token" \
    -f -a "$create_sub"

# create -f <file>
complete -c kubectl -n "__kubectl_sub_is create" \
    -s f -l filename      -d "Filename/dir/URL"                             -F
complete -c kubectl -n "__kubectl_sub_is create" \
    -l dry-run            -d "Dry run" -f -a "none client server"
complete -c kubectl -n "__kubectl_sub_is create" \
    -s R -l recursive     -d "Recurse directories"                         -f
complete -c kubectl -n "__kubectl_sub_is create" \
    -l save-config        -d "Save config in annotation"                   -f
complete -c kubectl -n "__kubectl_sub_is create" \
    -l validate           -d "Validate before creating" -f \
    -a "strict warn ignore"

# create secret subtypes
complete -c kubectl -n "__kubectl_sub_is create; and __kubectl_seen_flag secret" \
    -f -a "generic\tGeneric secret docker-registry\tDocker registry tls\tTLS cert+key"

# create service subtypes
complete -c kubectl -n "__kubectl_sub_is create; and __kubectl_seen_flag service" \
    -f -a "clusterip\tClusterIP nodeport\tNodePort loadbalancer\tLoadBalancer externalname\tExternalName"

# ══════════════════════════════════════════════════════════════════════════════
#  ROLLOUT
# ══════════════════════════════════════════════════════════════════════════════

set -l rollout_sub \
    "history\t📜 View rollout history" \
    "pause\t⏸️  Pause rollout" \
    "restart\t🔄 Restart a rollout" \
    "resume\t▶️  Resume a paused rollout" \
    "status\t📊 Show rollout status" \
    "undo\t↩️  Rollback"

complete -c kubectl -n "__kubectl_sub_is rollout; and not __kubectl_seen_flag \
    history pause restart resume status undo" \
    -f -a "$rollout_sub"

for rollout_cmd in history pause restart resume status undo
    complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag $rollout_cmd" \
        -f -a "(__kubectl_deployments)" -d "Deployment"
    complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag $rollout_cmd" \
        -f -a "(__kubectl_statefulsets)" -d "StatefulSet"
    complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag $rollout_cmd" \
        -f -a "(__kubectl_daemonsets)" -d "DaemonSet"
end

complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag undo" \
    -l to-revision        -d "Rollback to revision"                         -f

complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag history" \
    -l revision           -d "Specific revision"                            -f

complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag status" \
    -s w -l watch         -d "Watch rollout progress"                       -f
complete -c kubectl -n "__kubectl_sub_is rollout; and __kubectl_seen_flag status" \
    -l timeout            -d "Timeout for rollout"                          -f

# ══════════════════════════════════════════════════════════════════════════════
#  SCALE
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is scale" \
    -f -a "deployment statefulset replicaset"
complete -c kubectl -n "__kubectl_sub_is scale; and __kubectl_seen_flag deployment" \
    -f -a "(__kubectl_deployments)"
complete -c kubectl -n "__kubectl_sub_is scale; and __kubectl_seen_flag statefulset" \
    -f -a "(__kubectl_statefulsets)"
complete -c kubectl -n "__kubectl_sub_is scale; and __kubectl_seen_flag replicaset" \
    -f -a "(__kubectl_replicasets)"

complete -c kubectl -n "__kubectl_sub_is scale" \
    -l replicas           -d "Target number of replicas"                    -f
complete -c kubectl -n "__kubectl_sub_is scale" \
    -l current-replicas   -d "Precondition: current replicas"               -f
complete -c kubectl -n "__kubectl_sub_is scale" \
    -l resource-version   -d "Precondition: resource version"               -f
complete -c kubectl -n "__kubectl_sub_is scale" \
    -l timeout            -d "Wait timeout"                                 -f

# ══════════════════════════════════════════════════════════════════════════════
#  PORT-FORWARD
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is port-forward; and test (count (commandline -poc)) -le 2" \
    -f -a "(__kubectl_pods)"

complete -c kubectl -n "__kubectl_sub_is port-forward" \
    -l address            -d "Listen addresses" -f \
    -a "localhost 0.0.0.0 127.0.0.1"
complete -c kubectl -n "__kubectl_sub_is port-forward" \
    -l pod-running-timeout -d "Timeout for pod running"                    -f

# ══════════════════════════════════════════════════════════════════════════════
#  TOP
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is top; and not __kubectl_seen_flag pod pods node nodes" \
    -f -a "pod\tPod resource usage pods\tPods node\tNode resource usage nodes\tNodes"

complete -c kubectl -n "__kubectl_sub_is top; and __kubectl_seen_flag pod pods" \
    -f -a "(__kubectl_pods)"
complete -c kubectl -n "__kubectl_sub_is top; and __kubectl_seen_flag node nodes" \
    -f -a "(__kubectl_nodes)"

complete -c kubectl -n "__kubectl_sub_is top" \
    -l containers         -d "Show container resource usage"                -f
complete -c kubectl -n "__kubectl_sub_is top" \
    -l no-headers         -d "No header row"                                -f
complete -c kubectl -n "__kubectl_sub_is top" \
    -l sort-by            -d "Sort by: cpu or memory"                       -f \
    -a "cpu\tCPU usage memory\tMemory usage"
complete -c kubectl -n "__kubectl_sub_is top" \
    -l use-protocol-buffers -d "Use protocol buffers"                       -f

# ══════════════════════════════════════════════════════════════════════════════
#  CONFIG
# ══════════════════════════════════════════════════════════════════════════════

set -l config_sub \
    "current-context\t📍 Show current context" \
    "delete-cluster\t🗑️  Delete cluster" \
    "delete-context\t🗑️  Delete context" \
    "delete-user\t🗑️  Delete user" \
    "get-clusters\t📋 List clusters" \
    "get-contexts\t📋 List contexts" \
    "get-users\t📋 List users" \
    "rename-context\t✏️  Rename context" \
    "set\t⚙️  Set config value" \
    "set-cluster\t🏗️  Set cluster config" \
    "set-context\t🎯 Set context config" \
    "set-credentials\t🔑 Set user credentials" \
    "unset\t🗑️  Unset config value" \
    "use-context\t🔄 Switch context" \
    "view\t👁️  Display config"

complete -c kubectl -n "__kubectl_sub_is config; and not __kubectl_seen_flag \
    current-context delete-cluster delete-context delete-user get-clusters \
    get-contexts get-users rename-context set set-cluster set-context \
    set-credentials unset use-context view" \
    -f -a "$config_sub"

complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag use-context" \
    -f -a "(__kubectl_contexts_with_desc)"
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag delete-context rename-context" \
    -f -a "(__kubectl_contexts)"
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag set-context" \
    -f -a "(__kubectl_contexts)"
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag set-context" \
    -l cluster            -d "Cluster for context"                          -f
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag set-context" \
    -l user               -d "User for context"                             -f
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag set-context" \
    -l namespace          -d "Namespace for context"                        -f \
    -a "(__kubectl_namespaces)"
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag view" \
    -l flatten            -d "Flatten config for use as kubeconfig"         -f
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag view" \
    -l merge              -d "Merge flag"                                   -f
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag view" \
    -l minify             -d "Remove unused info"                           -f
complete -c kubectl -n "__kubectl_sub_is config; and __kubectl_seen_flag view" \
    -l raw                -d "Display raw byte data"                        -f

# ══════════════════════════════════════════════════════════════════════════════
#  EXPLAIN
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is explain" \
    -f -a "(__kubectl_resource_types)"

complete -c kubectl -n "__kubectl_sub_is explain" \
    -l api-version        -d "Limit to specific API version"                -f
complete -c kubectl -n "__kubectl_sub_is explain" \
    -l recursive          -d "Print all fields recursively"                 -f
complete -c kubectl -n "__kubectl_sub_is explain" \
    -l output             -d "Output format" -f \
    -a "plaintext\tPlain text plaintext-openapiv2\tOpenAPI v2 format"

# ══════════════════════════════════════════════════════════════════════════════
#  LABEL / ANNOTATE
# ══════════════════════════════════════════════════════════════════════════════

for sub in label annotate
    complete -c kubectl -n "__kubectl_sub_is $sub; and test (count (commandline -poc)) -le 2" \
        -f -a "(__kubectl_resource_types_with_short)"

    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l all                -d "Select all resources"                      -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l overwrite          -d "Overwrite existing"                        -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l resource-version   -d "Precondition resource version"             -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -s l -l selector      -d "Label selector"                            -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l local              -d "Dry run locally"                           -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l list               -d "List labels/annotations"                   -f
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -s R -l recursive     -d "Process directories recursively"          -f
end

# ══════════════════════════════════════════════════════════════════════════════
#  CORDON / UNCORDON / DRAIN / TAINT
# ══════════════════════════════════════════════════════════════════════════════

for sub in cordon uncordon
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -f -a "(__kubectl_nodes)"
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -l dry-run            -d "Dry run" -f -a "none client server"
    complete -c kubectl -n "__kubectl_sub_is $sub" \
        -s l -l selector      -d "Label selector"                            -f
end

complete -c kubectl -n "__kubectl_sub_is drain" \
    -f -a "(__kubectl_nodes)"
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l delete-emptydir-data     -d "Delete pods using emptyDir"              -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l disable-eviction         -d "Force drain using delete"                -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l dry-run                  -d "Dry run" -f -a "none client server"
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l force                    -d "Force drain unmanaged pods"              -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l grace-period             -d "Eviction grace period"                  -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l ignore-daemonsets        -d "Ignore DaemonSet pods"                  -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l pod-selector             -d "Pod selector"                           -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -s l -l selector            -d "Node selector"                          -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l skip-wait-for-delete-timeout -d "Skip wait timeout"                  -f
complete -c kubectl -n "__kubectl_sub_is drain" \
    -l timeout                  -d "Drain timeout"                          -f

complete -c kubectl -n "__kubectl_sub_is taint" \
    -f -a "(__kubectl_nodes)"
complete -c kubectl -n "__kubectl_sub_is taint" \
    -l all                    -d "Select all nodes"                         -f
complete -c kubectl -n "__kubectl_sub_is taint" \
    -l overwrite              -d "Overwrite existing taint"                 -f
complete -c kubectl -n "__kubectl_sub_is taint" \
    -l validate               -d "Validate taints"                         -f

# ══════════════════════════════════════════════════════════════════════════════
#  DEBUG
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is debug" \
    -f -a "(__kubectl_pods)"

complete -c kubectl -n "__kubectl_sub_is debug" \
    -l attach                 -d "Attach to container"                      -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -s c -l container         -d "Container name"                           -f \
    -a "(__kubectl_containers (__kubectl_pos 1))"
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l copy-to                -d "Create copy of pod"                       -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l env                    -d "Environment variables"                    -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l image                  -d "Debug container image"                    -f \
    -a "busybox:latest alpine:latest ubuntu:latest nicolaka/netshoot\tNetshoot"
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l image-pull-policy      -d "Image pull policy"                        -f \
    -a "Always IfNotPresent Never"
complete -c kubectl -n "__kubectl_sub_is debug" \
    -s i -l stdin             -d "Keep stdin open"                          -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -s t -l tty               -d "Allocate TTY"                             -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l profile                -d "Debug profile"                            -f \
    -a "legacy\tLegacy general\tGeneral baseline\tBaseline netadmin\tNetwork admin restricted\tRestricted"
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l replace                -d "Replace existing ephemeral container"     -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l same-node              -d "Schedule on same node"                    -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l set-image              -d "Change container image"                   -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l share-processes        -d "Share process namespace"                  -f
complete -c kubectl -n "__kubectl_sub_is debug" \
    -l target                 -d "Target container"                         -f

# ══════════════════════════════════════════════════════════════════════════════
#  WAIT
# ══════════════════════════════════════════════════════════════════════════════

complete -c kubectl -n "__kubectl_sub_is wait" \
    -f -a "(__kubectl_resource_types_with_short)"

complete -c kubectl -n "__kubectl_sub_is wait" \
    -l for                    -d "Condition to wait for"                    -f \
    -a "condition=Ready condition=Available condition=Complete \
        condition=Succeeded condition=Failed delete jsonpath="
complete -c kubectl -n "__kubectl_sub_is wait" \
    -l timeout                -d "Wait timeout"                             -f \
    -a "30s 1m 5m 10m 30m"
complete -c kubectl -n "__kubectl_sub_is wait" \
    -l all                    -d "Wait on all resources"                    -f
complete -c kubectl -n "__kubectl_sub_is wait" \
    -l all-namespaces         -d "All namespaces"                           -f
complete -c kubectl -n "__kubectl_sub_is wait" \
    -s l -l selector          -d "Label selector"                           -f
complete -c kubectl -n "__kubectl_sub_is wait" \
    -s R -l recursive         -d "Recurse directories"                     -f

# ══════════════════════════════════════════════════════════════════════════════
#  AUTH
# ══════════════════════════════════════════════════════════════════════════════

set -l auth_sub \
    "can-i\t🔐 Check permissions" \
    "reconcile\t🔄 Reconcile RBAC rules" \
    "whoami\t👤 Print current user"

complete -c kubectl -n "__kubectl_sub_is auth; and not __kubectl_seen_flag can-i reconcile whoami" \
    -f -a "$auth_sub"

complete -c kubectl -n "__kubectl_sub_is auth; and __kubectl_seen_flag can-i" \
    -l list               -d "List all allowed actions"                     -f
complete -c kubectl -n "__kubectl_sub_is auth; and __kubectl_seen_flag can-i" \
    -l all-namespaces     -d "Check all namespaces"                         -f
complete -c kubectl -n "__kubectl_sub_is auth; and __kubectl_seen_flag can-i" \
    -l quiet          -s q -d "Suppress output"                             -f
complete -c kubectl -n "__kubectl_sub_is auth; and __kubectl_seen_flag can-i" \
    -l subresource        -d "Subresource (e.g. status)"                    -f \
    -a "status scale log exec portforward"
