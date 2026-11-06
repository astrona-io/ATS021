#!/usr/bin/env bash
# Check: a Deployment with one replica is refused in starfleet, a Deployment
# with two replicas is accepted there, and a one-replica Deployment is still
# accepted in outpost. Every grader Deployment carries the team label on its
# pod template, so the replica rule is the only reason for a refusal.
# The grader uses --dry-run=server, so every admission webhook runs and
# nothing is stored.
set -uo pipefail

fail=0

# deployment_yaml <namespace> <replicas>
deployment_yaml() {
  local namespace="$1" replicas="$2"
  cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grader-deployment
  namespace: ${namespace}
  labels:
    team: grader
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: grader-deployment
  template:
    metadata:
      labels:
        app: grader-deployment
        team: grader
    spec:
      containers:
        - name: grader
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
EOF
}

# expect_rejected <description> <namespace> <replicas>
# Retries for about 60 seconds, because Gatekeeper needs a few seconds to load a new constraint.
expect_rejected() {
  local description="$1" namespace="$2" replicas="$3"
  for _ in $(seq 1 20); do
    if ! deployment_yaml "$namespace" "$replicas" | kubectl apply --dry-run=server -f - >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

# expect_accepted <description> <namespace> <replicas>
expect_accepted() {
  local description="$1" namespace="$2" replicas="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(deployment_yaml "$namespace" "$replicas" | kubectl apply --dry-run=server -f - 2>&1)"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -2)"
  fail=1
}

expect_rejected "a Deployment with 1 replica in starfleet" starfleet 1
expect_accepted "a Deployment with 2 replicas in starfleet" starfleet 2
expect_accepted "a Deployment with 1 replica in outpost" outpost 1

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet refuses one-replica Deployments, two replicas and outpost are accepted"
fi
exit "$fail"
