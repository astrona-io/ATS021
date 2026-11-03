#!/usr/bin/env bash
# Check: a real read of the Secret scout-db-credentials is in the log at level Metadata, with no requestObject and no responseObject.
set -uo pipefail

fail=0
READER="audit-grader-reader-$$"
START_TIME="$(date -u +%Y-%m-%dT%H:%M:%S)"

cleanup() {
  kubectl -n kube-system delete pod "$READER" --ignore-not-found --wait=false >/dev/null 2>&1
}
trap cleanup EXIT

# start_reader: runs a short-lived pod on the control plane node that mounts
# the node directory /var/log/kubernetes/audit read-only. It lets the grader
# read the audit log with kubectl alone, without access to the node shell.
start_reader() {
  kubectl -n kube-system delete pod "$READER" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl apply -f - >/dev/null <<YAML || return 1
apiVersion: v1
kind: Pod
metadata:
  name: $READER
  namespace: kube-system
spec:
  nodeSelector:
    node-role.kubernetes.io/control-plane: ""
  tolerations:
    - operator: Exists
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
  containers:
    - name: reader
      image: curlimages/curl:8.22.0
      imagePullPolicy: IfNotPresent
      securityContext:
        runAsUser: 0
      command: ["sh", "-c", "sleep 600"]
      volumeMounts:
        - name: audit
          mountPath: /audit
          readOnly: true
  volumes:
    - name: audit
      hostPath:
        path: /var/log/kubernetes/audit
        type: DirectoryOrCreate
YAML
  kubectl -n kube-system wait --for=condition=Ready "pod/$READER" --timeout=120s >/dev/null 2>&1
}

# read_audit_log: prints the whole audit log, one JSON event per line.
read_audit_log() {
  kubectl -n kube-system exec "$READER" -- cat /audit/audit.log 2>/dev/null
}

if ! start_reader; then
  echo "FAIL: the grader could not read the control plane node (is the API server ready?)"
  exit 1
fi

kubectl -n starfleet get secret scout-db-credentials -o name >/dev/null 2>&1 \
  || { echo "FAIL: the Secret scout-db-credentials in starfleet cannot be read"; exit 1; }

event=""
for _ in $(seq 1 10); do
  event="$(read_audit_log | jq -c --arg since "$START_TIME" 'select(.stage == "ResponseComplete" and .verb == "get" and .objectRef.resource == "secrets" and .objectRef.namespace == "starfleet" and .objectRef.name == "scout-db-credentials" and .user.username == "kubernetes-admin" and .stageTimestamp >= $since)' 2>/dev/null | tail -1)"
  [ -n "$event" ] && break
  sleep 3
done

if [ -z "$event" ]; then
  echo "FAIL: no audit event for the Secret read was written. The policy records no Secret requests."
  exit 1
fi
level="$(printf "%s" "$event" | jq -r '.level')"
has_bodies="$(printf "%s" "$event" | jq -r 'has("requestObject") or has("responseObject")')"
if [ "$level" != "Metadata" ]; then
  echo "FAIL: the Secret read was recorded at level $level, expected Metadata"
  fail=1
fi
if [ "$has_bodies" != "false" ]; then
  echo "FAIL: the Secret event holds a request or response body, which can leak the Secret data"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: Secret reads are recorded at Metadata level without bodies"
fi
exit "$fail"
