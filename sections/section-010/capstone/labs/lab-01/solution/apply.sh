#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl delete clusterrolebinding orbit-ci-deployer-admin

kubectl -n orbit patch deployment beacon -p '{
  "spec": {"template": {"spec": {
    "securityContext": {
      "runAsNonRoot": true,
      "runAsUser": 100,
      "seccompProfile": {"type": "RuntimeDefault"}
    },
    "containers": [{
      "name": "beacon",
      "securityContext": {
        "allowPrivilegeEscalation": false,
        "capabilities": {"drop": ["ALL"]}
      }
    }]
  }}}
}'
kubectl -n orbit rollout status deployment/beacon --timeout=180s

kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied."
