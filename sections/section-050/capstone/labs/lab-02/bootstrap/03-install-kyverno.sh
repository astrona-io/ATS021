#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.19.1/install.yaml
kubectl wait --for=condition=Established crd/imagevalidatingpolicies.policies.kyverno.io --timeout=120s
for controller in admission background reports cleanup; do
  kubectl -n kyverno rollout status "deployment/kyverno-$controller-controller" --timeout=300s
done

# Wait for ready webhook endpoints without creating any policy or graded evidence.
kubectl -n kyverno wait --for=jsonpath='{.subsets[0].addresses[0].ip}' endpoints/kyverno-svc --timeout=120s
