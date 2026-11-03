#!/usr/bin/env bash
# Check: relay-scaled-by names the user.username of the successful scale of relay in the live audit log, and source-for-who-scaled is audit-log.
set -uo pipefail

fail=0

# normalize: sorts a comma or space separated list and removes duplicates
normalize() {
  printf "%s" "$1" | tr ", " "

" | sed "/^\$/d" | sort -u | paste -sd, -
}
# answer_of <key>: prints the value of a key in the ConfigMap auditor-answers
answer_of() {
  kubectl -n starfleet get configmap auditor-answers -o "jsonpath={.data.$1}" 2>/dev/null
}
# check_list <key> <live list>
check_list() {
  local key="$1" live="$2" given
  given="$(normalize "$(answer_of "$key")")"
  if [ -z "$live" ]; then
    echo "FAIL: the cluster reports no objects for $key. The violating workloads must stay as they are."
    fail=1
  elif [ "$given" != "$live" ]; then
    echo "FAIL: $key is [$given] but the live evidence lists [$live]"
    fail=1
  fi
}

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
if ! kubectl -n starfleet get configmap auditor-answers >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap auditor-answers does not exist in starfleet"
  exit 1
fi
live_user="$(read_audit_log | jq -r 'select(.stage == "ResponseComplete" and .verb == "patch" and .objectRef.resource == "deployments" and .objectRef.subresource == "scale" and .objectRef.namespace == "starfleet" and .objectRef.name == "relay" and .responseStatus.code == 200) | .user.username' 2>/dev/null | tail -1)"
if [ -z "$live_user" ]; then
  echo "FAIL: the audit log holds no successful scale of relay. Audit logging must stay on."
  exit 1
fi
given_user="$(answer_of relay-scaled-by)"
if [ "$given_user" != "$live_user" ]; then
  echo "FAIL: relay-scaled-by is '$given_user' but the audit log shows '$live_user'"
  fail=1
fi
given_source="$(answer_of source-for-who-scaled)"
if [ "$given_source" != "audit-log" ]; then
  echo "FAIL: source-for-who-scaled is '$given_source'. Use one of policy-report, constraint-status or audit-log."
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the audit answers match the live audit log"
fi
exit "$fail"
