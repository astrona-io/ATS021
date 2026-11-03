#!/usr/bin/env bash
# Check: a pod with CPU and memory limits is accepted in starfleet, and outpost is not affected.
set -uo pipefail

fail=0
exhausted=0

# server_create <namespace> <manifest on stdin>
# Sends the object to the API server with --dry-run=server, so all admission
# webhooks run and nothing is stored. Prints the combined output; the exit code
# is kubectl's.
server_create() {
  kubectl create -n "$1" --dry-run=server -o json -f - 2>&1
}

# expect_rejected <description> <namespace> <manifest>
# Retries for about 45 seconds, because Kyverno needs a few seconds to
# register a new policy in its webhooks.
expect_rejected() {
  local description="$1" namespace="$2" manifest="$3" tries=15
  # After one request used up all its retries, later requests try only once.
  [ "$exhausted" -eq 1 ] && tries=1
  for _ in $(seq 1 "$tries"); do
    if ! printf "%s" "$manifest" | server_create "$namespace" >/dev/null; then
      return 0
    fi
    [ "$tries" -gt 1 ] && sleep 3
  done
  exhausted=1
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

# expect_accepted <description> <namespace> <manifest>
expect_accepted() {
  local description="$1" namespace="$2" manifest="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(printf "%s" "$manifest" | server_create "$namespace")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf "%s" "$out" | tail -3)"
  fail=1
}


pod_manifest() {
  # pod_manifest <name> <resources yaml, indented 8 spaces> [extra labels]
  local name="$1" resources="$2" labels="${3:-}"
  cat <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    app: grader
$labels
spec:
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
$resources
YAML
}
BOTH="      resources:
        limits:
          cpu: 50m
          memory: 32Mi"
NONE=""


expect_accepted "a pod with CPU and memory limits in starfleet" starfleet "$(pod_manifest grader-good "$BOTH")"
expect_accepted "a pod with no limits in outpost" outpost "$(pod_manifest grader-outpost "$NONE")"
if [ "$fail" -eq 0 ]; then
  echo "PASS: good pods are accepted and the rule is limited to starfleet"
fi
exit "$fail"
