#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                  ║
# ║  ██╗  ██╗ █████╗ ███████╗                                                      ║
# ║  ██║ ██╔╝██╔══██╗██╔════╝                                                      ║
# ║  █████╔╝ ╚█████╔╝███████╗                                                      ║
# ║  ██╔═██╗ ██╔══██╗╚════██║                                                      ║
# ║  ██║  ██╗╚█████╔╝███████║                                                      ║
# ║  ╚═╝  ╚═╝ ╚════╝ ╚══════╝                                                      ║
# ║                                                                                  ║
# ║   ☸️  KUBERNETES ABBREVIATIONS — ASH Dotfiles v5.0 OMEGA                        ║
# ║   kubectl • helm • k9s • flux • argocd • istio • cert-manager • krew           ║
# ║   Operators • Service Mesh • GitOps • Policy • Monitoring • Networking           ║
# ║                                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

status is-interactive || exit 0
set -q __ash_abbr_k8s_initialized && exit 0
set -g __ash_abbr_k8s_initialized 1

command -sq kubectl || command -sq helm || command -sq k9s || exit 0


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ☸️  KUBECTL — Core Kubernetes client
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq kubectl
    abbr -a k       "kubectl"
    abbr -a kk      "kubectl"

    # ── GET Resources ─────────────────────────────────────────────────────────

    # Pods
    abbr -a kgp     "kubectl get pods"
    abbr -a kgpa    "kubectl get pods --all-namespaces"
    abbr -a kgpaw   "kubectl get pods --all-namespaces --output=wide"
    abbr -a kgpw    "kubectl get pods --watch"
    abbr -a kgpwA   "kubectl get pods --all-namespaces --watch"
    abbr -a kgpn    "kubectl get pods --namespace"
    abbr -a kgpo    "kubectl get pods --output=wide"
    abbr -a kgpoj   "kubectl get pods --output=json | jq"
    abbr -a kgpoy   "kubectl get pods --output=yaml"
    abbr -a kgprun  "kubectl get pods --field-selector=status.phase=Running"
    abbr -a kgppend "kubectl get pods --field-selector=status.phase=Pending"
    abbr -a kgpfail "kubectl get pods --field-selector=status.phase=Failed"
    abbr -a kgpevict "kubectl get pods --field-selector=reason=Evicted"
    abbr -a kgpnotrun "kubectl get pods --field-selector=status.phase!=Running"
    abbr -a kgpimg  "kubectl get pods --output=jsonpath='{range .items[*]}{.metadata.name}{\"\t\"}{.spec.containers[*].image}{\"\n\"}{end}'"

    # Deployments
    abbr -a kgd     "kubectl get deployments"
    abbr -a kgda    "kubectl get deployments --all-namespaces"
    abbr -a kgdw    "kubectl get deployments --watch"
    abbr -a kgdo    "kubectl get deployments --output=wide"
    abbr -a kgdoj   "kubectl get deployments --output=json | jq"
    abbr -a kgdoy   "kubectl get deployments --output=yaml"

    # Services
    abbr -a kgsvc   "kubectl get services"
    abbr -a kgsvca  "kubectl get services --all-namespaces"
    abbr -a kgsvco  "kubectl get services --output=wide"
    abbr -a kgsvcoj "kubectl get services --output=json | jq"

    # StatefulSets
    abbr -a kgss    "kubectl get statefulsets"
    abbr -a kgssa   "kubectl get statefulsets --all-namespaces"
    abbr -a kgssw   "kubectl get statefulsets --watch"

    # DaemonSets
    abbr -a kgds    "kubectl get daemonsets"
    abbr -a kgdsa   "kubectl get daemonsets --all-namespaces"

    # ReplicaSets
    abbr -a kgrs    "kubectl get replicasets"
    abbr -a kgrsa   "kubectl get replicasets --all-namespaces"

    # Nodes
    abbr -a kgn     "kubectl get nodes"
    abbr -a kgno    "kubectl get nodes --output=wide"
    abbr -a kgnc    "kubectl get nodes --output=custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,CPU:.status.capacity.cpu,MEM:.status.capacity.memory"
    abbr -a kgnlbl  "kubectl get nodes --show-labels"
    abbr -a kgntaint "kubectl get nodes --output=json | jq '.items[].spec.taints'"

    # Namespaces
    abbr -a kgns    "kubectl get namespaces"
    abbr -a kgnsa   "kubectl get namespaces --show-labels"

    # ConfigMaps & Secrets
    abbr -a kgcm    "kubectl get configmaps"
    abbr -a kgcma   "kubectl get configmaps --all-namespaces"
    abbr -a kgcmoy  "kubectl get configmap --output=yaml"
    abbr -a kgsec   "kubectl get secrets"
    abbr -a kgseca  "kubectl get secrets --all-namespaces"
    abbr -a kgsecoj "kubectl get secret --output=json | jq"
    abbr -a kgsecy  "kubectl get secret --output=yaml"
    abbr -a kgsecdec "kubectl get secret --output=json | jq '.data | map_values(@base64d)'"

    # Ingress & Networking
    abbr -a kging   "kubectl get ingress --all-namespaces"
    abbr -a kgingo  "kubectl get ingress --output=wide"
    abbr -a kgnetpol "kubectl get networkpolicies --all-namespaces"
    abbr -a kgsvcac "kubectl get serviceaccounts"
    abbr -a kgep    "kubectl get endpoints"
    abbr -a kgepa   "kubectl get endpoints --all-namespaces"

    # Storage
    abbr -a kgpvc   "kubectl get persistentvolumeclaims --all-namespaces"
    abbr -a kgpv    "kubectl get persistentvolumes"
    abbr -a kgsc    "kubectl get storageclasses"

    # RBAC
    abbr -a kgrb    "kubectl get rolebindings --all-namespaces"
    abbr -a kgcrb   "kubectl get clusterrolebindings"
    abbr -a kgr     "kubectl get roles --all-namespaces"
    abbr -a kgcr    "kubectl get clusterroles"
    abbr -a kgsa    "kubectl get serviceaccounts"

    # Jobs & CronJobs
    abbr -a kgj     "kubectl get jobs --all-namespaces"
    abbr -a kgjw    "kubectl get jobs --watch"
    abbr -a kgcj    "kubectl get cronjobs --all-namespaces"

    # HPA / VPA / PDB
    abbr -a kghpa   "kubectl get hpa --all-namespaces"
    abbr -a kgpdb   "kubectl get poddisruptionbudgets --all-namespaces"

    # Events
    abbr -a kgev    "kubectl get events --sort-by='.lastTimestamp'"
    abbr -a kgeva   "kubectl get events --all-namespaces --sort-by='.lastTimestamp'"
    abbr -a kgevw   "kubectl get events --watch"
    abbr -a kgevwarn "kubectl get events --field-selector=type=Warning"
    abbr -a kgevwarna "kubectl get events --all-namespaces --field-selector=type=Warning"

    # All resources
    abbr -a kgall   "kubectl get all --all-namespaces"
    abbr -a kgallw  "kubectl get all --all-namespaces --output=wide"

    # ── DESCRIBE Resources ────────────────────────────────────────────────────
    abbr -a kd      "kubectl describe"
    abbr -a kdp     "kubectl describe pod"
    abbr -a kdn     "kubectl describe node"
    abbr -a kdsvc   "kubectl describe service"
    abbr -a kdd     "kubectl describe deployment"
    abbr -a kdss    "kubectl describe statefulset"
    abbr -a kdds    "kubectl describe daemonset"
    abbr -a kdrs    "kubectl describe replicaset"
    abbr -a kdcm    "kubectl describe configmap"
    abbr -a kdsec   "kubectl describe secret"
    abbr -a kding   "kubectl describe ingress"
    abbr -a kdpvc   "kubectl describe persistentvolumeclaim"
    abbr -a kdpv    "kubectl describe persistentvolume"
    abbr -a kdhpa   "kubectl describe hpa"
    abbr -a kdns    "kubectl describe namespace"
    abbr -a kdsa    "kubectl describe serviceaccount"
    abbr -a kdrb    "kubectl describe rolebinding"
    abbr -a kdcj    "kubectl describe cronjob"
    abbr -a kdj     "kubectl describe job"
    abbr -a kdpdb   "kubectl describe poddisruptionbudget"

    # ── LOGS ──────────────────────────────────────────────────────────────────
    abbr -a kl      "kubectl logs --follow --timestamps"
    abbr -a klt     "kubectl logs --follow --timestamps --tail=100"
    abbr -a klt50   "kubectl logs --follow --timestamps --tail=50"
    abbr -a klp     "kubectl logs --follow --timestamps --previous"
    abbr -a kla     "kubectl logs --follow --timestamps --all-containers"
    abbr -a klat    "kubectl logs --follow --timestamps --all-containers --tail=100"
    abbr -a kls     "kubectl logs --follow --since=1h"
    abbr -a kls5    "kubectl logs --follow --since=5m"
    abbr -a kls30   "kubectl logs --follow --since=30m"
    abbr -a klgrep  "kubectl logs --follow --timestamps --all-containers | grep"
    abbr -a klj     "kubectl logs --follow --all-containers | jq"
    abbr -a klmax   "kubectl logs --follow --timestamps --tail=1000 --limit-bytes=10000000"
    abbr -a klsince "kubectl logs --since"

    # ── EXEC into containers ──────────────────────────────────────────────────
    abbr -a ke      "kubectl exec --stdin --tty"
    abbr -a kesh    "kubectl exec --stdin --tty -- sh"
    abbr -a kebash  "kubectl exec --stdin --tty -- bash"
    abbr -a kefish  "kubectl exec --stdin --tty -- fish"
    abbr -a kezsh   "kubectl exec --stdin --tty -- zsh"
    abbr -a kecmd   "kubectl exec --stdin --tty -- "

    # ── APPLY / CREATE / DELETE ───────────────────────────────────────────────
    abbr -a ka      "kubectl apply --filename"
    abbr -a kar     "kubectl apply --recursive --filename"
    abbr -a kak     "kubectl apply --kustomize"
    abbr -a kass    "kubectl apply --server-side --filename"
    abbr -a kadry   "kubectl apply --dry-run=client --filename"
    abbr -a kasrv   "kubectl apply --dry-run=server --filename"
    abbr -a kaurl   "kubectl apply --filename"

    abbr -a kcr     "kubectl create"
    abbr -a kcrns   "kubectl create namespace"
    abbr -a kcrsec  "kubectl create secret generic"
    abbr -a kcrsecd "kubectl create secret docker-registry"
    abbr -a kcrtls  "kubectl create secret tls"
    abbr -a kcrcm   "kubectl create configmap"
    abbr -a kcrsa   "kubectl create serviceaccount"
    abbr -a kcrjob  "kubectl create job"
    abbr -a kcrdep  "kubectl create deployment"
    abbr -a kcrtoken "kubectl create token"

    abbr -a kdel    "kubectl delete"
    abbr -a kdelf   "kubectl delete --filename"
    abbr -a kdelk   "kubectl delete --kustomize"
    abbr -a kdelnow "kubectl delete --grace-period=0 --force"
    abbr -a kdelp   "kubectl delete pod --grace-period=0 --force"
    abbr -a kdelns  "kubectl delete namespace"
    abbr -a kdelj   "kubectl delete job"
    abbr -a kdeld   "kubectl delete deployment"
    abbr -a kdelsvc "kubectl delete service"
    abbr -a kdelcm  "kubectl delete configmap"
    abbr -a kdelsec "kubectl delete secret"
    abbr -a kdelall "kubectl delete all --all"

    # ── PATCH / EDIT / LABEL ──────────────────────────────────────────────────
    abbr -a kpatch  "kubectl patch"
    abbr -a kpatchj "kubectl patch --patch"
    abbr -a kedit   "kubectl edit"
    abbr -a keditd  "kubectl edit deployment"
    abbr -a kedits  "kubectl edit service"
    abbr -a keditcm "kubectl edit configmap"
    abbr -a keditss "kubectl edit statefulset"
    abbr -a klabel  "kubectl label"
    abbr -a klabeln "kubectl label nodes"
    abbr -a klabelp "kubectl label pods"
    abbr -a kanno   "kubectl annotate"
    abbr -a ktaint  "kubectl taint"
    abbr -a ktaintn "kubectl taint nodes"
    abbr -a kuntaint "kubectl taint nodes --all"

    # ── SCALE & ROLLOUT ───────────────────────────────────────────────────────
    abbr -a kscale  "kubectl scale"
    abbr -a kscaled "kubectl scale deployment"
    abbr -a kscaless "kubectl scale statefulset"
    abbr -a kscale0 "kubectl scale deployment --replicas=0"
    abbr -a kscale1 "kubectl scale deployment --replicas=1"

    abbr -a kroll   "kubectl rollout"
    abbr -a krollst "kubectl rollout status"
    abbr -a krollstd "kubectl rollout status deployment"
    abbr -a krollh  "kubectl rollout history"
    abbr -a krollu  "kubectl rollout undo"
    abbr -a krollud "kubectl rollout undo deployment"
    abbr -a krollud2 "kubectl rollout undo deployment --to-revision=2"
    abbr -a krollr  "kubectl rollout restart"
    abbr -a krollrd "kubectl rollout restart deployment"
    abbr -a krollrss "kubectl rollout restart statefulset"
    abbr -a krollra "kubectl rollout restart deployment --all"
    abbr -a krollpause "kubectl rollout pause deployment"
    abbr -a krollresume "kubectl rollout resume deployment"

    # ── CONTEXT & NAMESPACE ───────────────────────────────────────────────────
    abbr -a kctx    "kubectl config use-context"
    abbr -a kctxl   "kubectl config get-contexts"
    abbr -a kctxc   "kubectl config current-context"
    abbr -a kctxd   "kubectl config delete-context"
    abbr -a kctxrn  "kubectl config rename-context"
    abbr -a kcfg    "kubectl config view"
    abbr -a kcfgm   "kubectl config view --minify"
    abbr -a kcfgset "kubectl config set"
    abbr -a kcfgget "kubectl config get"
    abbr -a kns     "kubectl config set-context --current --namespace"
    abbr -a knsget  "kubectl config view --minify --output='jsonpath={..namespace}'"
    abbr -a knsl    "kubectl get namespaces"

    # kubectx / kubens (faster context/namespace switching)
    command -sq kubectx && abbr -a kctx "kubectx"
    command -sq kubens  && abbr -a kns  "kubens"

    # ── PORT FORWARD ──────────────────────────────────────────────────────────
    abbr -a kpf     "kubectl port-forward"
    abbr -a kpfp    "kubectl port-forward pod"
    abbr -a kpfs    "kubectl port-forward service"
    abbr -a kpfd    "kubectl port-forward deployment"
    abbr -a kpf80   "kubectl port-forward --address=0.0.0.0 svc"
    abbr -a kpf8080 "kubectl port-forward --address=0.0.0.0 svc 8080:80"
    abbr -a kpf3000 "kubectl port-forward --address=0.0.0.0 svc 3000:3000"
    abbr -a kpf9090 "kubectl port-forward --address=0.0.0.0 svc 9090:9090"  # Prometheus
    abbr -a kpf5601 "kubectl port-forward --address=0.0.0.0 svc 5601:5601"  # Kibana
    abbr -a kpf3100 "kubectl port-forward --address=0.0.0.0 svc 3100:3100"  # Grafana/Loki

    # ── TOP (resource usage) ──────────────────────────────────────────────────
    abbr -a ktop    "kubectl top"
    abbr -a ktopp   "kubectl top pods --all-namespaces"
    abbr -a ktoppa  "kubectl top pods --all-namespaces --sort-by=memory"
    abbr -a ktopn   "kubectl top nodes"
    abbr -a ktopns  "kubectl top nodes --sort-by=memory"
    abbr -a ktoppc  "kubectl top pods --all-namespaces --sort-by=cpu"

    # ── AUTH & RBAC ───────────────────────────────────────────────────────────
    abbr -a kwho    "kubectl auth whoami"
    abbr -a kcan    "kubectl auth can-i"
    abbr -a kcana   "kubectl auth can-i --list"
    abbr -a kcanall "kubectl auth can-i --list --all-namespaces"
    abbr -a kcreconcile "kubectl auth reconcile --filename"

    # ── CLUSTER INFO ──────────────────────────────────────────────────────────
    abbr -a kinfo   "kubectl cluster-info"
    abbr -a kinfod  "kubectl cluster-info dump"
    abbr -a kver    "kubectl version"
    abbr -a kverc   "kubectl version --client"
    abbr -a kapi    "kubectl api-resources"
    abbr -a kapiv   "kubectl api-versions"
    abbr -a kexpl   "kubectl explain"

    # ── DIFF & DRY RUN ────────────────────────────────────────────────────────
    abbr -a kdiff   "kubectl diff --filename"
    abbr -a kdiffall "kubectl diff --recursive --filename"

    # ── CORDON / DRAIN / UNCORDON ─────────────────────────────────────────────
    abbr -a kcord   "kubectl cordon"
    abbr -a kuncord "kubectl uncordon"
    abbr -a kdrain  "kubectl drain --ignore-daemonsets --delete-emissary-data"
    abbr -a kdrainf "kubectl drain --ignore-daemonsets --delete-emissary-data --force"

    # ── COPY ──────────────────────────────────────────────────────────────────
    abbr -a kcp     "kubectl cp"

    # ── PROXY ─────────────────────────────────────────────────────────────────
    abbr -a kproxy  "kubectl proxy --port=8001"
    abbr -a kproxy0 "kubectl proxy --port=8001 --address=0.0.0.0"

    # ── GENERATE ──────────────────────────────────────────────────────────────
    abbr -a kgen    "kubectl create --dry-run=client --output=yaml"
    abbr -a kgend   "kubectl create deployment --dry-run=client --output=yaml"
    abbr -a kgensvc "kubectl create service clusterip --dry-run=client --output=yaml"
    abbr -a kgencm  "kubectl create configmap --dry-run=client --output=yaml"
    abbr -a kgensec "kubectl create secret generic --dry-run=client --output=yaml"
    abbr -a kgenns  "kubectl create namespace --dry-run=client --output=yaml"
    abbr -a kgenjob "kubectl create job --dry-run=client --output=yaml"

    # ── DEBUG ─────────────────────────────────────────────────────────────────
    abbr -a kdebug   "kubectl run debug-pod \
                        --image=nicolaka/netshoot \
                        --restart=Never \
                        --rm \
                        --stdin \
                        --tty \
                        -- bash"
    abbr -a kdebugns "kubectl debug \
                        --it \
                        --image=nicolaka/netshoot \
                        --target"
    abbr -a kdebugn  "kubectl debug node"
    abbr -a kdbgnode "kubectl debug node --it --image=ubuntu"
    abbr -a kephem   "kubectl run ephemeral \
                        --image=busybox \
                        --restart=Never \
                        --rm \
                        --stdin \
                        --tty \
                        -- sh"

    # ── WAIT ──────────────────────────────────────────────────────────────────
    abbr -a kwait   "kubectl wait"
    abbr -a kwaitr  "kubectl wait --for=condition=Ready pod"
    abbr -a kwaita  "kubectl wait --for=condition=Available deployment"
    abbr -a kwaitc  "kubectl wait --for=condition=Complete job"
    abbr -a kwaitd  "kubectl wait --for=delete pod"

    # ── PLUGINS / KREW ────────────────────────────────────────────────────────
    if command -sq krew || test -d "$HOME/.krew"
        abbr -a krewup  "kubectl krew update"
        abbr -a krewupg "kubectl krew upgrade"
        abbr -a krewls  "kubectl krew list"
        abbr -a krewsrch "kubectl krew search"
        abbr -a krewi   "kubectl krew install"
        abbr -a krewr   "kubectl krew uninstall"
        abbr -a krewinfo "kubectl krew info"

        # Popular kubectl plugins
        command -sq kubectl-lineage && abbr -a klineage "kubectl lineage"
        command -sq kubectl-neat && abbr -a kneat "kubectl neat"
        command -sq kubectl-images && abbr -a kimages "kubectl images"
        command -sq kubectl-df-pv && abbr -a kdfpv "kubectl df-pv"
        command -sq kubectl-resource-capacity && abbr -a kcap "kubectl resource-capacity"
        command -sq kubectl-view-secret && abbr -a kvsec "kubectl view-secret"
        command -sq kubectl-viewnode && abbr -a kvnode "kubectl viewnode"
        command -sq kubectl-node-shell && abbr -a knodesh "kubectl node-shell"
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🗺️  HELM — Kubernetes Package Manager (extended)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq helm
    abbr -a h       "helm"

    # ── Release management ────────────────────────────────────────────────────
    abbr -a hl      "helm list --all-namespaces"
    abbr -a hla     "helm list --all --all-namespaces"
    abbr -a hlf     "helm list --failed --all-namespaces"
    abbr -a hls     "helm list --superseded --all-namespaces"
    abbr -a hlpend  "helm list --pending --all-namespaces"
    abbr -a hloj    "helm list --all-namespaces --output=json | jq"
    abbr -a hloy    "helm list --all-namespaces --output=yaml"

    # ── Install / Upgrade / Uninstall ─────────────────────────────────────────
    abbr -a hi      "helm install"
    abbr -a hiw     "helm install --wait"
    abbr -a hiwto   "helm install --wait --timeout=10m"
    abbr -a hicrd   "helm install --skip-crds"

    abbr -a hu      "helm upgrade --install"
    abbr -a huw     "helm upgrade --install --wait"
    abbr -a huwto   "helm upgrade --install --wait --timeout=10m"
    abbr -a hur     "helm upgrade --install --reset-values"
    abbr -a hura    "helm upgrade --install --reuse-values"
    abbr -a huatom  "helm upgrade --install --atomic"
    abbr -a huclean "helm upgrade --install --cleanup-on-fail"
    abbr -a huforce "helm upgrade --install --force"

    abbr -a hr      "helm uninstall"
    abbr -a hrns    "helm uninstall --namespace"
    abbr -a hrall   "helm uninstall (helm list --short --all-namespaces 2>/dev/null) 2>/dev/null"
    abbr -a hrkd    "helm uninstall --keep-history"

    abbr -a hrb     "helm rollback"
    abbr -a hrb1    "helm rollback 1"
    abbr -a hrbw    "helm rollback --wait"

    # ── Status & History ──────────────────────────────────────────────────────
    abbr -a hst     "helm status"
    abbr -a hstoj   "helm status --output=json | jq"
    abbr -a hh      "helm history"
    abbr -a hhls    "helm history --max=5"
    abbr -a hhoj    "helm history --output=json | jq"

    # ── Get ───────────────────────────────────────────────────────────────────
    abbr -a hget    "helm get"
    abbr -a hgetv   "helm get values"
    abbr -a hgeta   "helm get all"
    abbr -a hgetm   "helm get manifest"
    abbr -a hgeth   "helm get hooks"
    abbr -a hgetnotes "helm get notes"
    abbr -a hgetval "helm get values --all"

    # ── Values ────────────────────────────────────────────────────────────────
    abbr -a hval    "helm show values"
    abbr -a hvals   "helm show values 2>/dev/null | bat --language yaml"
    abbr -a hchart  "helm show chart"
    abbr -a hreadme "helm show readme"
    abbr -a hshall  "helm show all"

    # ── Repository ────────────────────────────────────────────────────────────
    abbr -a hrep    "helm repo"
    abbr -a hrepa   "helm repo add"
    abbr -a hrepup  "helm repo update"
    abbr -a hrepl   "helm repo list"
    abbr -a hreprm  "helm repo remove"
    abbr -a hrepidx "helm repo index"

    # Common repos
    abbr -a hrep-stable  "helm repo add stable https://charts.helm.sh/stable"
    abbr -a hrep-bitnami "helm repo add bitnami https://charts.bitnami.com/bitnami"
    abbr -a hrep-ingress "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
    abbr -a hrep-cert    "helm repo add cert-manager https://charts.jetstack.io"
    abbr -a hrep-prom    "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
    abbr -a hrep-grafana "helm repo add grafana https://grafana.github.io/helm-charts"
    abbr -a hrep-argo    "helm repo add argo https://argoproj.github.io/argo-helm"
    abbr -a hrep-flux    "helm repo add fluxcd https://charts.fluxcd.io"
    abbr -a hrep-istio   "helm repo add istio https://istio-release.storage.googleapis.com/charts"
    abbr -a hrep-aws     "helm repo add eks https://aws.github.io/eks-charts"
    abbr -a hrep-jetstack "helm repo add jetstack https://charts.jetstack.io"

    # ── Search ────────────────────────────────────────────────────────────────
    abbr -a hs      "helm search repo"
    abbr -a hsh     "helm search hub"
    abbr -a hsa     "helm search repo --versions"
    abbr -a hsoj    "helm search repo --output=json | jq"

    # ── Template & Diff ───────────────────────────────────────────────────────
    abbr -a htemp   "helm template"
    abbr -a htempd  "helm template . --debug"
    abbr -a htempy  "helm template . | bat --language yaml"
    abbr -a hdiff   "helm diff upgrade 2>/dev/null || echo 'Install helm-diff plugin'"
    abbr -a hdiffr  "helm diff revision"

    # ── Lint & Validate ───────────────────────────────────────────────────────
    abbr -a hlint   "helm lint"
    abbr -a hlints  "helm lint --strict"
    abbr -a hvalid  "helm lint && helm template . | kubectl apply --dry-run=client --filename -"

    # ── Dry run ───────────────────────────────────────────────────────────────
    abbr -a hdry    "helm upgrade --install --dry-run --debug"
    abbr -a hdrycsrv "helm upgrade --install --dry-run=server"
    abbr -a hdryt   "helm template . | kubectl apply --dry-run=client --filename -"

    # ── Package & Publish ─────────────────────────────────────────────────────
    abbr -a hpack   "helm package"
    abbr -a hpackd  "helm package --destination"
    abbr -a hpush   "helm push"

    # ── Env & Version ─────────────────────────────────────────────────────────
    abbr -a henv    "helm env"
    abbr -a hver    "helm version"
    abbr -a hverc   "helm version --client"
    abbr -a hcomp   "helm completion fish | source"

    # ── Plugins ───────────────────────────────────────────────────────────────
    abbr -a hplug   "helm plugin list"
    abbr -a hplugi  "helm plugin install"
    abbr -a hplugu  "helm plugin update"
    abbr -a hplugr  "helm plugin uninstall"

    # ── Secrets (helm-secrets plugin) ─────────────────────────────────────────
    abbr -a hsec    "helm secrets"
    abbr -a hsecd   "helm secrets decrypt"
    abbr -a hsece   "helm secrets encrypt"
    abbr -a hsecview "helm secrets view"
    abbr -a hsecedit "helm secrets edit"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🌊 FLUX — GitOps Continuous Delivery
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq flux
    abbr -a fx      "flux"
    abbr -a fxchk   "flux check"
    abbr -a fxpre   "flux check --pre"
    abbr -a fxinst  "flux install"
    abbr -a fxunst  "flux uninstall"
    abbr -a fxbs    "flux bootstrap"
    abbr -a fxbsgh  "flux bootstrap github"
    abbr -a fxbsgl  "flux bootstrap gitlab"
    abbr -a fxsync  "flux reconcile"
    abbr -a fxsyncs "flux reconcile source git"
    abbr -a fxsynck "flux reconcile kustomization"
    abbr -a fxsynch "flux reconcile helmrelease"
    abbr -a fxsyncall "flux reconcile source --all"
    abbr -a fxgls   "flux get sources git"
    abbr -a fxgls-all "flux get sources git --all-namespaces"
    abbr -a fxgls-helm "flux get sources helm"
    abbr -a fxgls-oci  "flux get sources oci"
    abbr -a fxgks   "flux get kustomizations"
    abbr -a fxgksa  "flux get kustomizations --all-namespaces"
    abbr -a fxghr   "flux get helmreleases"
    abbr -a fxghra  "flux get helmreleases --all-namespaces"
    abbr -a fxgimg  "flux get images"
    abbr -a fxsusp  "flux suspend"
    abbr -a fxsuspk "flux suspend kustomization"
    abbr -a fxsusph "flux suspend helmrelease"
    abbr -a fxresume "flux resume"
    abbr -a fxresumek "flux resume kustomization"
    abbr -a fxresumeh "flux resume helmrelease"
    abbr -a fxlogs  "flux logs"
    abbr -a fxlogsf "flux logs --follow"
    abbr -a fxlogsall "flux logs --all-namespaces"
    abbr -a fxver   "flux version"
    abbr -a fxenv   "flux envs"
    abbr -a fxexport "flux export"
    abbr -a fxcomp  "flux completion fish | source"
    abbr -a fxtrace "flux trace"
    abbr -a fxdiff  "flux diff kustomization"
    abbr -a fxpush  "flux push artifact"
    abbr -a fxpull  "flux pull artifact"
    abbr -a fxtag   "flux tag artifact"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐙 ARGOCD — GitOps Continuous Delivery
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq argocd
    abbr -a argo    "argocd"
    abbr -a argols  "argocd app list"
    abbr -a argog   "argocd app get"
    abbr -a argosync "argocd app sync"
    abbr -a argosynca "argocd app sync --all"
    abbr -a argostatus "argocd app status"
    abbr -a argodiff "argocd app diff"
    abbr -a argohistory "argocd app history"
    abbr -a argorollback "argocd app rollback"
    abbr -a argodel "argocd app delete"
    abbr -a argocr  "argocd app create"
    abbr -a argowait "argocd app wait"
    abbr -a argologs "argocd app logs"
    abbr -a argoset "argocd app set"
    abbr -a argounset "argocd app unset"
    abbr -a argopatch "argocd app patch"
    abbr -a argoproj "argocd proj list"
    abbr -a argorepo "argocd repo list"
    abbr -a argocluster "argocd cluster list"
    abbr -a argologin "argocd login"
    abbr -a argoctx  "argocd context"
    abbr -a argover  "argocd version"
    abbr -a argocomp "argocd completion fish | source"
    abbr -a argoacc  "argocd account list"
    abbr -a argopwd  "argocd account update-password"
    abbr -a argotoken "argocd account generate-token"
    abbr -a argoapp-manifest "argocd app manifests"
    abbr -a argoapp-resources "argocd app resources"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🕸️  ISTIO — Service Mesh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq istioctl
    abbr -a istio   "istioctl"
    abbr -a istiocheck "istioctl x precheck"
    abbr -a istioinst "istioctl install"
    abbr -a istiover "istioctl version"
    abbr -a istvs   "istioctl proxy-status"
    abbr -a istvsc  "istioctl proxy-config"
    abbr -a istvscd "istioctl proxy-config cluster"
    abbr -a istvsce "istioctl proxy-config endpoint"
    abbr -a istiolan "istioctl analyze"
    abbr -a istiolanall "istioctl analyze --all-namespaces"
    abbr -a istiodash "istioctl dashboard"
    abbr -a istiodashk "istioctl dashboard kiali"
    abbr -a istiodashg "istioctl dashboard grafana"
    abbr -a istiodashjg "istioctl dashboard jaeger"
    abbr -a istiomt  "istioctl create-remote-secret"
    abbr -a istioinj "istioctl inject --filename"
    abbr -a istiobug "istioctl bug-report"
    abbr -a istioexp "istioctl experimental"
    abbr -a istioverify "istioctl verify-install"
    abbr -a istiounst "istioctl uninstall --purge"
    abbr -a istiomesh "istioctl x workload"
    abbr -a istiocomp "istioctl completion fish | source"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔒 CERT-MANAGER — TLS certificate automation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq cmctl
    abbr -a cmctl   "cmctl"
    abbr -a cmls    "cmctl inspect secret"
    abbr -a cmstat  "cmctl status certificate"
    abbr -a cmrenew "cmctl renew"
    abbr -a cmrenewa "cmctl renew --all"
    abbr -a cmcheck "cmctl check api"
    abbr -a cmver   "cmctl version"
    abbr -a cmexp   "cmctl experimental"
    abbr -a cmconv  "cmctl convert"
    abbr -a cminspect "cmctl inspect"
end

# cert-manager kubectl plugin
abbr -a kcert   "kubectl cert-manager 2>/dev/null || echo 'Install kubectl cert-manager plugin'"
abbr -a kcertls "kubectl get certificates --all-namespaces"
abbr -a kcertissuer "kubectl get issuers --all-namespaces"
abbr -a kcertclissuer "kubectl get clusterissuers"
abbr -a kcertorder "kubectl get orders --all-namespaces"
abbr -a kcertchallenge "kubectl get challenges --all-namespaces"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 MONITORING — Prometheus, Grafana, Loki
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Prometheus port-forward shortcuts
abbr -a kprom   "kubectl port-forward --namespace monitoring svc/prometheus-operated 9090:9090"
abbr -a kgrafana "kubectl port-forward --namespace monitoring svc/grafana 3000:3000"
abbr -a kalertmgr "kubectl port-forward --namespace monitoring svc/alertmanager-operated 9093:9093"
abbr -a kloki   "kubectl port-forward --namespace monitoring svc/loki 3100:3100"
abbr -a kjaeger "kubectl port-forward --namespace istio-system svc/tracing 16686:80"
abbr -a kkiali  "kubectl port-forward --namespace istio-system svc/kiali 20001:20001"

# Prometheus CLI
if command -sq promtool
    abbr -a promcheck "promtool check config"
    abbr -a promrules "promtool check rules"
    abbr -a promtest  "promtool test rules"
    abbr -a promquery "promtool query"
end

# Loki CLI
command -sq logcli && begin
    abbr -a logls   "logcli labels"
    abbr -a logq    "logcli query"
    abbr -a logt    "logcli tail"
    abbr -a logsrch "logcli series"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 TERRAFORM (Infrastructure as Code) — Extended for K8s
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq terraform
    abbr -a tf      "terraform"
    abbr -a tfi     "terraform init"
    abbr -a tfiu    "terraform init -upgrade"
    abbr -a tfir    "terraform init -reconfigure"
    abbr -a tfp     "terraform plan"
    abbr -a tfpout  "terraform plan --out=tfplan"
    abbr -a tfpd    "terraform plan --destroy"
    abbr -a tfa     "terraform apply"
    abbr -a tfaa    "terraform apply --auto-approve"
    abbr -a tfaplan "terraform apply tfplan"
    abbr -a tfd     "terraform destroy"
    abbr -a tfda    "terraform destroy --auto-approve"
    abbr -a tfv     "terraform validate"
    abbr -a tffmt   "terraform fmt"
    abbr -a tffmtr  "terraform fmt --recursive"
    abbr -a tffmtc  "terraform fmt --check --recursive"
    abbr -a tfls    "terraform state list"
    abbr -a tfssh   "terraform state show"
    abbr -a tfsmv   "terraform state mv"
    abbr -a tfsrm   "terraform state rm"
    abbr -a tfspull "terraform state pull"
    abbr -a tfspush "terraform state push"
    abbr -a tfsrefresh "terraform state refresh"
    abbr -a tfout   "terraform output"
    abbr -a tfoutj  "terraform output --json | jq"
    abbr -a tfimp   "terraform import"
    abbr -a tfref   "terraform refresh"
    abbr -a tfws    "terraform workspace"
    abbr -a tfwsl   "terraform workspace list"
    abbr -a tfwsn   "terraform workspace new"
    abbr -a tfwss   "terraform workspace select"
    abbr -a tfwsdel "terraform workspace delete"
    abbr -a tfver   "terraform version"
    abbr -a tflog   "TF_LOG=DEBUG terraform"
    abbr -a tflogi  "TF_LOG=INFO terraform"
    abbr -a tfunlock "terraform force-unlock"
    abbr -a tfgraph "terraform graph | dot -Tsvg > graph.svg && xdg-open graph.svg"

    # tfenv (Terraform version manager)
    command -sq tfenv && begin
        abbr -a tfe     "tfenv"
        abbr -a tfei    "tfenv install"
        abbr -a tfeil   "tfenv install latest"
        abbr -a tfeu    "tfenv use"
        abbr -a tfeul   "tfenv use latest"
        abbr -a tfel    "tfenv list"
        abbr -a tfela   "tfenv list-remote"
        abbr -a tfepin  "tfenv pin"
    end
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔌 KUBESEAL — Sealed Secrets
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq kubeseal && begin
    abbr -a kseal   "kubeseal"
    abbr -a ksealf  "kubeseal --format=yaml"
    abbr -a ksealfn "kubeseal --format=yaml --filename"
    abbr -a ksealcert "kubeseal --fetch-cert"
    abbr -a ksealrot "kubeseal --re-encrypt --format=yaml"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🛡️  OPA / GATEKEEPER — Policy as Code
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -sq opa && begin
    abbr -a opa     "opa"
    abbr -a opaeval "opa eval"
    abbr -a opatest "opa test"
    abbr -a oparun  "opa run"
    abbr -a opafmt  "opa fmt"
    abbr -a opachk  "opa check"
    abbr -a opabuild "opa build"
    abbr -a opainsp "opa inspect"
end

# Kyverno
command -sq kyverno && begin
    abbr -a kyv     "kyverno"
    abbr -a kyvapply "kyverno apply"
    abbr -a kyvtest "kyverno test"
    abbr -a kyvval  "kyverno validate"
    abbr -a kyvver  "kyverno version"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🏗️  CLUSTER PROVISIONING — eksctl, gcloud, az
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── eksctl (AWS EKS) ──────────────────────────────────────────────────────────
command -sq eksctl && begin
    abbr -a eks     "eksctl"
    abbr -a ekscr   "eksctl create cluster"
    abbr -a eksls   "eksctl get clusters"
    abbr -a eksdel  "eksctl delete cluster"
    abbr -a eksng   "eksctl get nodegroup"
    abbr -a ekscfg  "eksctl utils write-kubeconfig"
    abbr -a eksup   "eksctl upgrade cluster"
    abbr -a eksupng "eksctl upgrade nodegroup"
    abbr -a eksscale "eksctl scale nodegroup"
    abbr -a eksver  "eksctl version"
end

# ── gcloud / GKE ──────────────────────────────────────────────────────────────
command -sq gcloud && begin
    abbr -a gcls    "gcloud container clusters list"
    abbr -a gcget   "gcloud container clusters get-credentials"
    abbr -a gccr    "gcloud container clusters create"
    abbr -a gcdel   "gcloud container clusters delete"
    abbr -a gcup    "gcloud container clusters upgrade"
    abbr -a gcnp    "gcloud container node-pools list"
    abbr -a gcnpadd "gcloud container node-pools create"
    abbr -a gcnpdel "gcloud container node-pools delete"
end

# ── az / AKS ──────────────────────────────────────────────────────────────────
command -sq az && begin
    abbr -a azaks   "az aks"
    abbr -a azaksls "az aks list --output=table"
    abbr -a azakscfg "az aks get-credentials"
    abbr -a azakscr "az aks create"
    abbr -a azaksdel "az aks delete"
    abbr -a azaksup "az aks upgrade"
    abbr -a azaksscale "az aks scale"
    abbr -a azaksnp  "az aks nodepool list"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎛️  K9S — Kubernetes TUI (extended)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq k9s
    abbr -a k9      "k9s"
    abbr -a k9ns    "k9s --namespace"
    abbr -a k9ctx   "k9s --context"
    abbr -a k9all   "k9s --all-namespaces"
    abbr -a k9ro    "k9s --readonly"
    abbr -a k9log   "k9s --logLevel=debug"
    abbr -a k9head  "k9s --headless"
    abbr -a k9cmd   "k9s --command"
    abbr -a k9skin  "k9s --skin"
    abbr -a k9ver   "k9s version"
    abbr -a k9info  "k9s info"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 TRIVY — Security scanner for K8s
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -sq trivy
    abbr -a trivy   "trivy"
    abbr -a trivyi  "trivy image"
    abbr -a trivyfs "trivy filesystem ."
    abbr -a trivyr  "trivy repository"
    abbr -a trivyk8s "trivy k8s"
    abbr -a trivyk8sa "trivy k8s --report=all cluster"
    abbr -a trivyk8ss "trivy k8s --report=summary cluster"
    abbr -a trivyconfig "trivy config ."
    abbr -a trivysecret "trivy filesystem . --scanners secret"
    abbr -a trivylicense "trivy filesystem . --scanners license"
    abbr -a trivysb "trivy image --format=spdx-json --output=sbom.json"
    abbr -a trivyupd "trivy image --download-db-only"
    abbr -a trivyserver "trivy server"
    abbr -a trivyver "trivy --version"
end


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 K8S POWER WORKFLOWS — One-liner cluster operations
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Restart all deployments in a namespace
abbr -a k8s-restart-ns "kubectl rollout restart deployment --all --namespace"

# Get all images in cluster
abbr -a k8s-images "kubectl get pods --all-namespaces \
                    --output=jsonpath='{range .items[*]}{.spec.containers[*].image}{\"\n\"}{end}' \
                    | sort | uniq"

# Get all failing pods
abbr -a k8s-failing "kubectl get pods --all-namespaces \
                     --field-selector=status.phase!=Running,status.phase!=Succeeded \
                     --output=wide"

# Delete all evicted pods
abbr -a k8s-del-evicted "kubectl get pods --all-namespaces --output=json \
                          | jq '.items[] | select(.status.reason==\"Evicted\") \
                          | \"kubectl delete pod \" + .metadata.name + \" -n \" + .metadata.namespace' \
                          | xargs -I {} sh -c {}"

# Get resource usage sorted
abbr -a k8s-top-pods "kubectl top pods --all-namespaces --sort-by=memory"
abbr -a k8s-top-nodes "kubectl top nodes --sort-by=memory"

# Copy kubeconfig
abbr -a k8s-cp-config "cp $KUBECONFIG /tmp/kubeconfig-backup.yaml && echo '✅ Kubeconfig backed up'"

# Cluster health summary
abbr -a k8s-health "echo '🔍 Nodes:' && kubectl get nodes && \
                    echo '\n🚦 Failing Pods:' && \
                    kubectl get pods --all-namespaces --field-selector=status.phase=Failed && \
                    echo '\n⚠️  Warning Events:' && \
                    kubectl get events --all-namespaces --field-selector=type=Warning | tail -10"

# Namespace resource summary
abbr -a k8s-ns-summary "kubectl api-resources --verbs=list --namespaced -o name \
                         | xargs -n 1 kubectl get --show-kind --ignore-not-found \
                         --namespace"