#!/usr/bin/env bash
# Starting state for the audit logging lab. Environment only: it creates the
# Starfleet workloads and the deck-cleaner CronJob. API server audit logging
# stays off; the learner turns it on.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[lab] Ready."
