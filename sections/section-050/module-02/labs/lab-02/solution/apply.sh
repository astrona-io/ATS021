#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/solution/template.yaml"
for attempt in $(seq 1 60); do
  if kubectl get crd k8sallowedregistries.constraints.gatekeeper.sh >/dev/null 2>&1; then break; fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8sallowedregistries.constraints.gatekeeper.sh --timeout=120s
kubectl apply -f "$DIR/solution/constraint.yaml"
for attempt in $(seq 1 60); do
  result="$(kubectl -n starfleet run registry-ready --image=nginx:latest --dry-run=server -o name 2>&1)" && result=''
  if [[ "$result" == *'[ghcr-only]'* && "$result" == *'denied the request'* ]]; then exit 0; fi
  sleep 2
done
echo 'Registry constraint did not begin enforcing' >&2
exit 1
