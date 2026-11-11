#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl delete clusterpolicy --all
kubectl get namespace outpost >/dev/null 2>&1 || kubectl create namespace outpost
kubectl apply -f "$DIR/testing/template.yaml"
for attempt in $(seq 1 60); do
  if kubectl get crd k8sallowedregistries.constraints.gatekeeper.sh >/dev/null 2>&1; then break; fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sallowedregistries.constraints.gatekeeper.sh --timeout=120s
kubectl apply -f "$DIR/testing/constraint.yaml"
for attempt in $(seq 1 60); do
  result="$(kubectl -n starfleet run registry-ready --image=nginx:latest --dry-run=server -o name 2>&1)" && result=''
  if [[ "$result" == *'[ghcr-only]'* && "$result" == *'denied the request'* ]]; then break; fi
  sleep 2
done

python3 "$DIR/testing/check-registry.py"
