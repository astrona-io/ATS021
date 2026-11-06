#!/usr/bin/env bash
# Install the controller and seed an ungated Pipeline, never the answer.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
kubectl apply -f https://infra.tekton.dev/tekton-releases/pipeline/previous/v1.17.0/release.yaml
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-controller --timeout=300s
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-webhook --timeout=300s
applied=0
for attempt in $(seq 1 30); do
  if kubectl apply -f "$SCRIPT_DIR/../manifests/lab-start.yaml"; then
    applied=1
    break
  fi
  sleep 5
done
[ "$applied" -eq 1 ] || exit 1
kubectl -n pipelines wait --for=condition=Ready pod/release-scan-reader --timeout=180s
# Task steps download their own database. Check connectivity during bootstrap
# and provide a terminal cache for manual investigation.
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
trivy image --download-db-only
