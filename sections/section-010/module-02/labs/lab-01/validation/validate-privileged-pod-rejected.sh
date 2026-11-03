#!/usr/bin/env bash
# Check: behaviour. The API server rejects a privileged pod in starfleet and
# admits a pod that has the four restricted settings. Both are server-side
# dry runs, so nothing is created.
set -uo pipefail

fail=0

privileged_output="$(kubectl apply --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-privileged
  namespace: starfleet
spec:
  containers:
    - name: debug
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      securityContext:
        privileged: true
YAML
)"
privileged_status=$?
if [ "$privileged_status" -eq 0 ] || ! echo "$privileged_output" | grep -q 'violates PodSecurity'; then
  echo "FAIL: the API server did not reject a privileged pod in starfleet with a PodSecurity error"
  fail=1
fi

compliant_output="$(kubectl apply --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: grader-compliant
  namespace: starfleet
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: probe
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
YAML
)"
compliant_status=$?
if [ "$compliant_status" -ne 0 ]; then
  echo "FAIL: the API server rejected a pod that meets restricted: $compliant_output"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the privileged pod is rejected and the restricted pod is accepted"
fi
exit "$fail"
