#!/usr/bin/env bash
# Install Tekton and seed the supporting resources for this independent task.
set -euo pipefail

TEKTON_VERSION="v1.17.0"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Tekton Pipelines ${TEKTON_VERSION}..."
kubectl apply -f "https://infra.tekton.dev/tekton-releases/pipeline/previous/${TEKTON_VERSION}/release.yaml"
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-controller --timeout=300s
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-webhook --timeout=300s

# The webhook validates Tekton objects; retry until it answers.
echo "[lab] Applying the lab start..."
applied=0
for i in $(seq 1 30); do
  if kubectl apply -f "$DIR/manifests/lab-start.yaml"; then
    applied=1
    break
  fi
  sleep 5
done
[ "$applied" -eq 1 ] || { echo "[lab] The lab start could not be applied." >&2; exit 1; }
kubectl -n pipelines get task deploy-release report-outcome
kubectl -n pipelines get pipeline release-gate
echo "[lab] Ready."
