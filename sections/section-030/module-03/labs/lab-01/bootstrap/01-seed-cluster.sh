#!/usr/bin/env bash
# Starting state for the ValidatingAdmissionPolicy lab. Environment only: it
# creates the workloads (scout runs 8 replicas), the namespace labels and the
# replica-limits ConfigMap. It creates no policy and no binding.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl apply -f "$DIR/manifests/replica-limits.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=240s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
