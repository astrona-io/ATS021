#!/usr/bin/env bash
# Starting state for the Kyverno lab. Environment only: it installs Kyverno,
# waits until the webhooks answer, and creates the workloads. It creates no
# ClusterPolicy.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done
kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s

# The admission controller registers its webhook configurations after it starts.
for name in kyverno-policy-validating-webhook-cfg kyverno-resource-validating-webhook-cfg kyverno-resource-mutating-webhook-cfg; do
  for i in $(seq 1 60); do
    if kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration 2>/dev/null | grep -q "$name"; then
      break
    fi
    sleep 2
  done
done

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
