#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
cp "$DIR/solution/namespacedmutatingpolicy-default-team.yaml" /tmp/kyverno-team-test/policy.yaml
kyverno apply /tmp/kyverno-team-test/policy.yaml --resource /tmp/kyverno-team-test/pods.yaml
kyverno test /tmp/kyverno-team-test --require-tests
kubectl apply -f /tmp/kyverno-team-test/policy.yaml
# Wait for policy registration with actual admission, before creating proof Pods.
for attempt in $(seq 1 60); do
  admitted="$(kubectl create --dry-run=server -f "$DIR/manifests/pod-scout-default.yaml" -o json)"
  if [ "$(printf '%s' "$admitted" | jq -r '.metadata.labels.team')" = unassigned ]; then break; fi
  if [ "$attempt" -eq 60 ]; then echo "Policy did not become active" >&2; exit 1; fi
  sleep 2
done
kubectl delete pod scout-default scout-labelled -n starfleet --ignore-not-found --wait=true
kubectl create -f "$DIR/manifests/pod-scout-default.yaml"
kubectl create -f "$DIR/manifests/pod-scout-labelled.yaml"
kubectl label pod scout-default -n starfleet team=navigation --overwrite
kubectl annotate pod scout-default -n starfleet proof=retained --overwrite
