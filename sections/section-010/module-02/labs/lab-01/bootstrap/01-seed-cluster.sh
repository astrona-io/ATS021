#!/usr/bin/env bash
# Starting state for the Pod Security Admission lab. Environment only: the
# Starfleet workloads without a securityContext, a privileged debug Deployment,
# and a starfleet namespace with no Pod Security labels. The learner fixes it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl apply -f "$DIR/manifests/privileged-debug.yaml"

for name in scout probe shuttle privileged-debug; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
