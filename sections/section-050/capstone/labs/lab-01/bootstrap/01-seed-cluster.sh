#!/usr/bin/env bash
# Starting state for the capstone. Environment only: it installs Tekton
# Pipelines and Kyverno, waits until both webhooks answer, and applies the
# lab start. It creates no check Task and does not fix the Pipeline, the
# service account or the image policy.
set -euo pipefail

TEKTON_VERSION="v1.17.0"
KYVERNO_VERSION="v1.19.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Tekton Pipelines ${TEKTON_VERSION}..."
kubectl apply -f "https://infra.tekton.dev/tekton-releases/pipeline/previous/${TEKTON_VERSION}/release.yaml"
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-controller --timeout=300s
kubectl -n tekton-pipelines rollout status deployment/tekton-pipelines-webhook --timeout=300s

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

# Both webhooks validate objects; retry until they answer.
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
  ready="$(kubectl get clusterpolicy trusted-images -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$ready" = "True" ] && break
  sleep 3
done
kubectl -n pipelines get task deploy-release report-outcome
kubectl -n pipelines get pipeline release-gate
echo "[lab] Ready."
