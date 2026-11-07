#!/usr/bin/env bash
# Check: the ConfigMap auditor-answers in starfleet holds deleted-by and deletion-audit-id of a real, successful deletion of the Deployment beacon, made by the service account of the deck-cleaner CronJob.
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

answer_user="$(kubectl -n starfleet get configmap auditor-answers -o jsonpath='{.data.deleted-by}' 2>/dev/null)"
answer_id="$(kubectl -n starfleet get configmap auditor-answers -o jsonpath='{.data.deletion-audit-id}' 2>/dev/null)"
if [ -z "$answer_user" ] || [ -z "$answer_id" ]; then
  echo "FAIL: the ConfigMap auditor-answers in starfleet needs the keys deleted-by and deletion-audit-id"
  exit 1
fi

event="$(read_audit_log | jq -c --arg id "$answer_id" 'select(.auditID == $id and .stage == "ResponseComplete")' 2>/dev/null | tail -1)"
if [ -z "$event" ]; then
  echo "FAIL: the audit log has no completed event with auditID $answer_id"
  exit 1
fi
if [ "$(printf "%s" "$event" | jq -r '.verb + " " + .objectRef.resource + " " + .objectRef.namespace + "/" + .objectRef.name + " " + (.responseStatus.code|tostring)')" != "delete deployments starfleet/beacon 200" ]; then
  echo "FAIL: auditID $answer_id is not a successful deletion of the Deployment beacon in starfleet"
  fail=1
fi

cronjob_account="$(kubectl -n outpost get cronjob deck-cleaner -o jsonpath='{.spec.jobTemplate.spec.template.spec.serviceAccountName}' 2>/dev/null)"
expected_user="system:serviceaccount:outpost:${cronjob_account}"
log_user="$(printf "%s" "$event" | jq -r '.user.username')"
if [ "$log_user" != "$expected_user" ]; then
  echo "FAIL: the deletion event is by $log_user. The deck-cleaner CronJob runs as $expected_user, so the evidence is not its deletion."
  fail=1
fi
if [ "$answer_user" != "$log_user" ]; then
  echo "FAIL: the answer deleted-by names '$answer_user', but the audit event shows '$log_user'"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the answer names the real caller and audit ID of a deletion of beacon"
fi
exit "$fail"
