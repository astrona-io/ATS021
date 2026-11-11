#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATEKEEPER_VERSION="v3.23.1"

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

kubectl apply -f "$DIR/manifests/start.yaml"
kubectl -n outpost rollout status deployment/drifter --timeout=180s
kubectl -n outpost get pods -l app=drifter -o json > "$DIR/original-pods.json"
kubectl apply -f "$DIR/manifests/template.yaml"
for attempt in $(seq 1 60); do
  if kubectl get crd/k8sdisallowedtags.constraints.gatekeeper.sh >/dev/null 2>&1; then break; fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sdisallowedtags.constraints.gatekeeper.sh --timeout=120s
