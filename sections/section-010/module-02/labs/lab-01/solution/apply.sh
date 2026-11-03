#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet delete deployment privileged-debug

patch_workload() {
  local workload="$1"
  local user_id="$2"
  kubectl -n starfleet patch deployment "$workload" -p "{
    \"spec\": {\"template\": {\"spec\": {
      \"securityContext\": {
        \"runAsNonRoot\": true,
        \"runAsUser\": ${user_id},
        \"seccompProfile\": {\"type\": \"RuntimeDefault\"}
      },
      \"containers\": [{
        \"name\": \"${workload}\",
        \"securityContext\": {
          \"allowPrivilegeEscalation\": false,
          \"capabilities\": {\"drop\": [\"ALL\"]}
        }
      }]
    }}}
  }"
}

patch_workload scout 100
patch_workload probe 65532
patch_workload shuttle 100

for workload in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/${workload}" --timeout=180s
done

kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied."
