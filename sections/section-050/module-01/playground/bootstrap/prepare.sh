#!/usr/bin/env bash
# Environment prep for the "Gate A Tekton Pipeline On A Compliance Check"
# playground (`ats-021-playground-050-01`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. installs Tekton Pipelines 1.17.0 from its release manifest,
#   2. waits until the controller and webhook are ready,
#   3. applies the `pipelines` namespace, the `pipeline-runner` service
#      account and its Role in `starfleet`, the `deploy-release` Task, the
#      platform policy file and the two releases.
# No check Task and no Pipeline are created.
set -euo pipefail

TEKTON_VERSION="v1.17.0"

echo "[playground] Installing Tekton Pipelines ${TEKTON_VERSION}..."
kubectl apply -f "https://infra.tekton.dev/tekton-releases/pipeline/previous/${TEKTON_VERSION}/release.yaml"
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-controller --timeout=300s
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-webhook --timeout=300s

# The webhook validates Tekton objects; retry until it answers.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the pipeline setup..."
for i in $(seq 1 30); do
  if kubectl apply -f "$SCRIPT_DIR/../manifests/pipeline-setup.yaml"; then
    break
  fi
  sleep 5
done
kubectl -n pipelines get task deploy-release
echo "[playground] Ready."
