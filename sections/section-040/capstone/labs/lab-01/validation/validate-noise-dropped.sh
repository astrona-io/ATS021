#!/usr/bin/env bash
# Check: after the grader starts, the log holds normal events but no health check requests and no RequestReceived stage.
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

# Read the Secret so the log has at least one event to find, then give the
# kubelet time to send its health probes (the livez probe runs every 10 seconds).
kubectl -n starfleet get secret scout-db-credentials -o name >/dev/null 2>&1
sleep 25

recent="$(read_audit_log | jq -c --arg since "$START_TIME" 'select(.stageTimestamp >= $since)' 2>/dev/null)"
total="$(printf "%s\n" "$recent" | grep -c '"auditID"')"
if [ "${total:-0}" -lt 1 ]; then
  echo "FAIL: no audit event was written in the last seconds. The policy records nothing."
  exit 1
fi

health="$(printf "%s\n" "$recent" | jq -r 'select(.requestURI | test("^/(healthz|livez|readyz)")) | .requestURI' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$health" -gt 0 ]; then
  echo "FAIL: $health health check requests (/healthz, /livez, /readyz) were recorded. Drop them with a level None rule."
  fail=1
fi
received="$(printf "%s\n" "$recent" | jq -r 'select(.stage == "RequestReceived") | .auditID' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$received" -gt 0 ]; then
  echo "FAIL: $received events of the RequestReceived stage were recorded. Skip the stage with omitStages."
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: health checks and the RequestReceived stage are not recorded"
fi
exit "$fail"
