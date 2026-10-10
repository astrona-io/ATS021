#!/usr/bin/env bash
# Environment prep for the "Validate, Mutate And Generate With Kyverno"
# playground (`ats-021-playground-030-01`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. installs Kyverno 1.19.1 from its release manifest,
#   2. waits until the admission, background, reports and cleanup controllers
#      are ready and the webhooks answer,
#   3. applies the Starfleet workloads.
# No ClusterPolicy and no PolicyException are created.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done

# The webhooks are registered by the admission controller after it starts.
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the Starfleet workloads..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
for d in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[playground] Ready."
