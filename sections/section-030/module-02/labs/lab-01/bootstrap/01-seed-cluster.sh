#!/usr/bin/env bash
# Starting state for the Gatekeeper lab. Environment only: it installs
# Gatekeeper, creates the workloads and applies the broken ConstraintTemplate.
# It creates no Constraint and no working template.
set -euo pipefail

GATEKEEPER_VERSION="v3.23.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

# The webhook needs its certificate before it answers.
for i in $(seq 1 60); do
  ca="$(kubectl get validatingwebhookconfiguration gatekeeper-validating-webhook-configuration -o jsonpath='{.webhooks[0].clientConfig.caBundle}' 2>/dev/null || true)"
  if [ -n "$ca" ]; then
    break
  fi
  sleep 2
done

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

kubectl apply -f "$DIR/manifests/disallowed-tags-template.yaml"
echo "[lab] Ready."
