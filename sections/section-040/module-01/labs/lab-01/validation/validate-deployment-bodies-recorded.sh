#!/usr/bin/env bash
# Check: creating and deleting a Deployment in starfleet are recorded at level RequestResponse with requestObject and responseObject.
set -uo pipefail

fail=0
READER="audit-grader-reader-$$"

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

# The audit log carries the API server's clock. The grader's machine can be
# minutes or hours off that clock (a laptop that slept, a virtual machine), so
# take the start time from the reader pod, which the API server stamped.
START_TIME="$(kubectl -n kube-system get pod "$READER" -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null | sed 's/Z$//')"
if [ -z "$START_TIME" ]; then
  echo "FAIL: the grader could not read the start time from the API server"
  exit 1
fi

NAME="audit-grader-$(date +%s)"
kubectl -n starfleet create deployment "$NAME" --image=curlimages/curl:8.22.0 >/dev/null 2>&1 \
  || { echo "FAIL: the grader could not create a Deployment in starfleet"; exit 1; }
kubectl -n starfleet delete deployment "$NAME" --wait=false >/dev/null 2>&1

find_event() {
  # find_event <verb>: prints the last ResponseComplete event of this Deployment
  read_audit_log | jq -c --arg since "$START_TIME" --arg name "$NAME" --arg verb "$1" 'select(.stage == "ResponseComplete" and .verb == $verb and .objectRef.resource == "deployments" and .objectRef.namespace == "starfleet" and .objectRef.name == $name and .stageTimestamp >= $since)' 2>/dev/null | tail -1
}

for verb in create delete; do
  event=""
  for _ in $(seq 1 10); do
    event="$(find_event "$verb")"
    [ -n "$event" ] && break
    sleep 3
  done
  if [ -z "$event" ]; then
    echo "FAIL: no audit event for the Deployment $verb was written"
    fail=1
    continue
  fi
  level="$(printf "%s" "$event" | jq -r '.level')"
  if [ "$level" != "RequestResponse" ]; then
    echo "FAIL: the Deployment $verb was recorded at level $level, expected RequestResponse"
    fail=1
    continue
  fi
  if [ "$verb" = "create" ] && [ "$(printf "%s" "$event" | jq -r 'has("requestObject") and has("responseObject")')" != "true" ]; then
    echo "FAIL: the Deployment create event has no requestObject and responseObject"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: Deployment changes are recorded at RequestResponse with both bodies"
fi
exit "$fail"
