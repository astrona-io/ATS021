#!/usr/bin/env bash
# Environment prep for the "Admit Only Trusted Images" playground
# (`ats-021-playground-050-02`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. installs Kyverno 1.19.1 and Gatekeeper 3.23.1 from their release
#      manifests (Gatekeeper's controller manager trimmed to one replica to
#      save memory),
#   2. waits until both admission webhooks are ready,
#   3. applies the `starfleet` and `starfleet-prod` namespaces and `scout`.
# No image policy is created.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
GATEKEEPER_VERSION="v3.23.1"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[playground] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system scale deployment gatekeeper-controller-manager --replicas=1
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the namespaces and scout..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[playground] Ready."
