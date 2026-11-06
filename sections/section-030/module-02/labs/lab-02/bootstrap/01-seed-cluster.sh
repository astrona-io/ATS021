#!/usr/bin/env bash
# Starting state for the Gatekeeper and Helm lab. Environment only: it
# installs Gatekeeper, creates the workloads, copies the probe chart to the
# terminal and installs the chart as release `probe` (revision 1). The chart
# breaks both rules the learner writes later (one replica, no `team` label on
# the pod template). That fault is the material; it is not fixed here. It
# creates no ConstraintTemplate and no Constraint.
set -euo pipefail

GATEKEEPER_VERSION="v3.23.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.astrona/bin:$PATH"

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
for name in scout shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

echo "[lab] Copying the probe chart to ~/resources/probe and installing revision 1..."
mkdir -p "$HOME/resources"
rm -rf "$HOME/resources/probe"
cp -R "$DIR/resources/probe" "$HOME/resources/probe"
helm install probe "$HOME/resources/probe" -n starfleet --wait=watcher --timeout 180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[lab] Ready."
