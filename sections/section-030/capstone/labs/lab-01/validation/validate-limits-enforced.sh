#!/usr/bin/env bash
# Check: pods and Deployments in starfleet without both limits are rejected;
# outpost is not affected.
set -uo pipefail

fail=0
exhausted=0

# server_create <namespace> <manifest>: runs all admission, stores nothing.
server_create() {
  printf "%s" "$2" | kubectl create -n "$1" --dry-run=server -o name -f - 2>&1
}

# expect_rejected <description> <namespace> <manifest>
# Retries for about 45 seconds, because the engines need a few seconds to load
# a new rule. After one request used up its retries, later ones try only once.
expect_rejected() {
  local description="$1" namespace="$2" manifest="$3" tries=15
  [ "$exhausted" -eq 1 ] && tries=1
  for _ in $(seq 1 "$tries"); do
    if ! server_create "$namespace" "$manifest" >/dev/null; then
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
    if out="$(server_create "$namespace" "$manifest")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf "%s" "$out" | tail -3)"
  fail=1
}

# pod_manifest <name> <app label> <image> <with limits: yes|no>
pod_manifest() {
  local name="$1" app="$2" image="$3" limits="$4"
  cat <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    app: $app
spec:
  containers:
    - name: test
      image: $image
      command: ["sh", "-c", "sleep 3600"]
YAML
  if [ "$limits" = "yes" ]; then
    cat <<YAML
      resources:
        limits:
          cpu: 50m
          memory: 32Mi
YAML
  fi
}

# deploy_manifest <name> <replicas> <with limits: yes|no>
# The image is pinned, so only the limits rule or the replica rule can refuse it.
deploy_manifest() {
  local name="$1" replicas="$2" limits="$3"
  cat <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
    spec:
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
YAML
  if [ "$limits" = "yes" ]; then
    cat <<YAML
          resources:
            limits:
              cpu: 50m
              memory: 32Mi
YAML
  fi
}

expect_rejected "a pod with no limits in starfleet" starfleet "$(pod_manifest grader-none grader "curlimages/curl:8.22.0" no)"
expect_rejected "a Deployment with no limits in starfleet" starfleet "$(deploy_manifest grader-deploy 1 no)"
expect_accepted "a pod with both limits in starfleet" starfleet "$(pod_manifest grader-good grader "curlimages/curl:8.22.0" yes)"
expect_accepted "a pod with no limits in outpost" outpost "$(pod_manifest grader-outpost grader "curlimages/curl:8.22.0" no)"

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet requires both limits, outpost is not affected"
fi
exit "$fail"
