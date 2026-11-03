#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml" 2>&1 | grep -v '^Warning: kyverno.io/v1 ClusterPolicy is deprecated' || true

# The Constraint needs a few seconds before it enforces. A pod with both limits
# and the latest tag is refused only by Gatekeeper.
for i in $(seq 1 60); do
  if ! cat <<'YAML' | kubectl -n starfleet create --dry-run=server -o name -f - >/dev/null 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: apply-probe
spec:
  containers:
    - name: apply-probe
      image: curlimages/curl:latest
      resources:
        limits:
          cpu: 100m
          memory: 64Mi
YAML
  then
    break
  fi
  sleep 3
done

# Fix the two existing workloads: beacon (latest tag) and scout (8 replicas).
kubectl -n starfleet set image deployment/beacon beacon=curlimages/curl:8.22.0
kubectl -n starfleet rollout status deployment/beacon --timeout=180s
for i in $(seq 1 30); do
  if kubectl -n starfleet scale deployment/scout --replicas=5; then
    break
  fi
  sleep 3
done
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[solution] Applied."
