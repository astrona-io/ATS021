#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALL_COSIGN=true bash "$SCRIPT_DIR/01-install-tools.sh"
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
kubectl apply -f https://infra.tekton.dev/tekton-releases/pipeline/previous/v1.17.0/release.yaml
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-controller --timeout=300s
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-webhook --timeout=300s
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.19.1/install.yaml
for controller in admission background reports cleanup; do
  kubectl -n kyverno rollout status "deployment/kyverno-$controller-controller" --timeout=300s
done
kubectl apply -f "$SCRIPT_DIR/../manifests/lab-start.yaml"
for attempt in $(seq 1 30); do
  if kubectl apply -f "$SCRIPT_DIR/../manifests/pipeline-setup.yaml"; then break; fi
  sleep 5
done
kubectl -n pipelines get task deploy-inventory
kubectl -n pipelines wait --for=condition=Ready pod/evidence-reader --timeout=180s
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
# Inventory generation requires image downloads but no vulnerability database.
# Download the database for terminal exercises; pipeline steps use their own cache.
trivy image --download-db-only
mkdir -p /tmp/ats021-050-03-keys
cp "$SCRIPT_DIR/../manifests/audit-signing.pub" /tmp/ats021-050-03-keys/audit-signing.pub
