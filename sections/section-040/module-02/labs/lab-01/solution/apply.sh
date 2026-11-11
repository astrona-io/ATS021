#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
# It reads the three evidence sources like the learner does and writes the
# answers to the ConfigMap `auditor-answers`.
set -euo pipefail

if [ -n "${ASTRONA_CONTAINER_ENGINE:-}" ]; then
  RUNTIME="$ASTRONA_CONTAINER_ENGINE"
elif command -v podman >/dev/null 2>&1 && podman ps >/dev/null 2>&1; then
  RUNTIME=podman
else
  RUNTIME=docker
fi
NODE="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')"

# Wait until the reports and the audit results hold the violations.
for i in $(seq 1 60); do
  if [ "$(kubectl get k8srequiredlabels deployments-need-owner -o jsonpath='{.status.violations}' 2>/dev/null | jq 'length' 2>/dev/null || echo 0)" -ge 2 ] \
     && kubectl get policyreport -A -o json | jq -e '[.items[] | select(.scope.kind == "Deployment") | .results[]? | select(.result == "fail")] | length >= 3' >/dev/null; then
    break
  fi
  sleep 5
done

failing_deployments() {
  kubectl get policyreport -A -o json \
    | jq -r --arg policy "$1" '.items[] | .scope as $s | select($s.kind == "Deployment") | select(any(.results[]?; .policy == $policy and .result == "fail")) | "\($s.namespace)/\($s.name)"' \
    | sort -u | paste -sd, -
}

owner_violations="$(kubectl get k8srequiredlabels deployments-need-owner -o json \
  | jq -r '.status.violations[] | select(.kind == "Deployment") | "\(.namespace)/\(.name)"' | sort -u | paste -sd, -)"

scaled_by="$($RUNTIME exec "$NODE" cat /var/log/kubernetes/audit/audit.log \
  | jq -r 'select(.stage == "ResponseComplete" and .verb == "patch" and .objectRef.resource == "deployments" and .objectRef.subresource == "scale" and .objectRef.namespace == "starfleet" and .objectRef.name == "relay" and .responseStatus.code == 200) | .user.username' \
  | tail -1)"

kubectl -n starfleet create configmap auditor-answers \
  --from-literal=require-limits="$(failing_deployments require-limits)" \
  --from-literal=disallow-latest-tag="$(failing_deployments disallow-latest-tag)" \
  --from-literal=owner-label="$owner_violations" \
  --from-literal=relay-scaled-by="$scaled_by" \
  --from-literal=source-for-who-scaled=audit-log
echo "[solution] Applied."
