#!/usr/bin/env bash
# Starting state for the image policy lab. Environment only: it installs
# Kyverno, waits until the webhooks answer, and creates the namespaces and the
# registry policy in Audit mode. It does not fix the policy.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done
kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s

# Policy admission must be ready before the learner can create a ClusterPolicy.
# Resource webhooks are registered when matching policies exist.
ready=0
for attempt in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done
[ "$ready" -eq 1 ] || { echo "ERROR: Kyverno policy webhook was not registered" >&2; exit 1; }

kubectl apply -f "$DIR/manifests/lab-start.yaml"
# The policy webhook may need a moment after it is registered; retry the apply.
applied=0
for i in $(seq 1 30); do
  if kubectl apply -f "$DIR/manifests/policy-start.yaml" 2>/dev/null; then
    applied=1
    break
  fi
  sleep 5
done
[ "$applied" -eq 1 ] || { echo "[lab] The policy could not be applied." >&2; exit 1; }
for i in $(seq 1 30); do
  ready="$(kubectl get clusterpolicy allowed-registries -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$ready" = "True" ] && break
  sleep 3
done
echo "[lab] Ready."
