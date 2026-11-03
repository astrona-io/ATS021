#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until all three
# rules are enforced (limits, latest tag, replicas).
set -uo pipefail

# server_create <manifest on stdin>: runs all admission, stores nothing.
server_create() {
  kubectl -n starfleet create --dry-run=server -o name -f - >/dev/null 2>&1
}

no_limits_pod() {
  cat <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: wait-limits
  labels:
    app: wait
spec:
  containers:
    - name: wait
      image: curlimages/curl:8.22.0
YAML
}

latest_pod() {
  cat <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: wait-latest
  labels:
    app: wait
spec:
  containers:
    - name: wait
      image: curlimages/curl:latest
      resources:
        limits:
          cpu: 100m
          memory: 64Mi
YAML
}

# A Deployment with 6 replicas, limits and a pinned tag: only the replica rule
# can refuse it.
six_replicas() {
  cat <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wait-replicas
spec:
  replicas: 6
  selector:
    matchLabels:
      app: wait
  template:
    metadata:
      labels:
        app: wait
    spec:
      containers:
        - name: wait
          image: curlimages/curl:8.22.0
          resources:
            limits:
              cpu: 100m
              memory: 64Mi
YAML
}

for i in $(seq 1 60); do
  limits_rejected=0; latest_rejected=0; replicas_rejected=0
  no_limits_pod | server_create || limits_rejected=1
  latest_pod | server_create || latest_rejected=1
  six_replicas | server_create || replicas_rejected=1
  if [ "$limits_rejected$latest_rejected$replicas_rejected" = "111" ]; then
    echo "[testing] All three rules are enforced."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] The rules were not enforced in time." >&2
exit 1
