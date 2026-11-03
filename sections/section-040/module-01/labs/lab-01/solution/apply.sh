#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
# It turns on API server audit logging on the control plane node, then waits
# for the deck-cleaner CronJob to delete `probe` and records the evidence.
set -euo pipefail

if command -v podman >/dev/null 2>&1 && podman ps >/dev/null 2>&1; then
  RUNTIME=podman
else
  RUNTIME=docker
fi
NODE="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')"
MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml

$RUNTIME exec "$NODE" mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
$RUNTIME exec -i "$NODE" sh -c 'cat > /etc/kubernetes/audit/audit-policy.yaml' <<'POLICY'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    nonResourceURLs: ["/healthz*", "/livez*", "/readyz*", "/version"]
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
  - level: RequestResponse
    resources:
      - group: "apps"
        resources: ["deployments"]
  - level: None
    verbs: ["get", "list", "watch"]
  - level: Metadata
POLICY

$RUNTIME exec "$NODE" cp "$MANIFEST" /tmp/kube-apiserver.yaml
$RUNTIME exec "$NODE" sed -i \
  -e '/^    - kube-apiserver$/a\    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml\n    - --audit-log-path=/var/log/kubernetes/audit/audit.log\n    - --audit-log-maxage=1\n    - --audit-log-maxbackup=1\n    - --audit-log-maxsize=10' \
  -e '/^    volumeMounts:$/a\    - mountPath: /etc/kubernetes/audit\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/kubernetes/audit\n      name: audit-log' \
  -e '/^  volumes:$/a\  - hostPath:\n      path: /etc/kubernetes/audit\n      type: Directory\n    name: audit-policy\n  - hostPath:\n      path: /var/log/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-log' \
  /tmp/kube-apiserver.yaml
$RUNTIME exec "$NODE" mv /tmp/kube-apiserver.yaml "$MANIFEST"

echo "[solution] Waiting for the API server to restart with audit logging..."
sleep 20
for i in $(seq 1 60); do
  if kubectl --request-timeout=5s get --raw=/readyz >/dev/null 2>&1 \
     && kubectl --request-timeout=5s -n kube-system get pod "kube-apiserver-${NODE}" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null | grep -q -- '--audit-log-path'; then
    break
  fi
  sleep 5
done

echo "[solution] Waiting for a deletion of probe by the deck-cleaner CronJob (up to 5 minutes)..."
event=""
for i in $(seq 1 60); do
  event="$($RUNTIME exec "$NODE" cat /var/log/kubernetes/audit/audit.log 2>/dev/null \
    | jq -c 'select(.stage == "ResponseComplete" and .verb == "delete" and .objectRef.resource == "deployments" and .objectRef.namespace == "starfleet" and .objectRef.name == "probe" and .responseStatus.code == 200)' \
    | tail -1)"
  [ -n "$event" ] && break
  sleep 5
done
[ -n "$event" ] || { echo "[solution] No deletion of probe found in the audit log." >&2; exit 1; }

kubectl -n starfleet create configmap probe-deletion \
  --from-literal=user="$(printf "%s" "$event" | jq -r '.user.username')" \
  --from-literal=auditID="$(printf "%s" "$event" | jq -r '.auditID')"
echo "[solution] Applied."
