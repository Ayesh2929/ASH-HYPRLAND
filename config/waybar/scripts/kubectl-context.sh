#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Waybar Script: Kubernetes Context               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# Check kubectl exists
if ! command -v kubectl &>/dev/null || [[ ! -f "${KUBECONFIG:-$HOME/.kube/config}" ]]; then
    echo '{}'
    exit 0
fi

CTX=$(kubectl config current-context 2>/dev/null || echo "none")
NS=$( kubectl config view --minify \
        --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")
NS="${NS:-default}"

# Get cluster server
SERVER=$(kubectl config view --minify \
    --output 'jsonpath={.clusters[0].cluster.server}' 2>/dev/null | \
    sed 's|https*://||; s|:[0-9]*$||' || echo "unknown")

# Color-code by environment type
CSS="default"
[[ "${CTX,,}" =~ prod    ]] && CSS="production"
[[ "${CTX,,}" =~ staging ]] && CSS="staging"
[[ "${CTX,,}" =~ dev     ]] && CSS="development"
[[ "${CTX,,}" =~ local|minikube|kind|k3s ]] && CSS="local"

# Node and pod count (quick check)
NODES=$(kubectl get nodes  --no-headers 2>/dev/null | wc -l || echo "?")
PODS=$(  kubectl get pods  --no-headers -A 2>/dev/null | wc -l || echo "?")

# Truncate context name for display
CTX_SHORT="$CTX"
[[ ${#CTX_SHORT} -gt 20 ]] && CTX_SHORT="${CTX_SHORT:0:19}…"

TOOLTIP="󸀀 Kubernetes\n\n"
TOOLTIP+="Context:   ${CTX}\n"
TOOLTIP+="Namespace: ${NS}\n"
TOOLTIP+="Server:    ${SERVER}\n"
TOOLTIP+="Nodes:     ${NODES}\n"
TOOLTIP+="Pods:      ${PODS}\n"
TOOLTIP+="\nLeft: k9s  Right: list contexts"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/\\/\\\\/g; s/"/\\"/g')
CTX_SHORT=$(echo "$CTX_SHORT" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"text":"󸀀 %s","tooltip":"%s","class":"%s"}\n' \
    "$CTX_SHORT" "$TOOLTIP" "$CSS"