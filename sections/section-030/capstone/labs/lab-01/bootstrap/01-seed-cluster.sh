#!/usr/bin/env bash
# Starting state for the capstone. Environment only: it installs Kyverno and
# Gatekeeper, waits until both webhooks answer, creates the workloads and
# applies the working K8sDisallowedTags template. It creates no ClusterPolicy,
# no Constraint and no ValidatingAdmissionPolicy.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
GATEKEEPER_VERSION="v3.23.1"
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

echo "[lab] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

# The Gatekeeper webhook needs its certificate before it answers.
for i in $(seq 1 60); do
  ca="$(kubectl get validatingwebhookconfiguration gatekeeper-validating-webhook-configuration -o jsonpath='{.webhooks[0].clientConfig.caBundle}' 2>/dev/null || true)"
  if [ -n "$ca" ]; then
    break
  fi
  sleep 2
done

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle beacon; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

kubectl apply -f "$DIR/manifests/disallowed-tags-template.yaml"
kubectl wait --for=jsonpath='{.status.created}'=true constrainttemplate/k8sdisallowedtags --timeout=120s
for i in $(seq 1 60); do
  if kubectl get crd k8sdisallowedtags.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sdisallowedtags.constraints.gatekeeper.sh --timeout=60s
echo "[lab] Ready."
