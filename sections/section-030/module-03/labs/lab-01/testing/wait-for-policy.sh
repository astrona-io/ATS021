#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the API
# server enforces the policy (a Deployment with 6 replicas is refused in
# starfleet).
set -uo pipefail

for i in $(seq 1 60); do
  if ! kubectl -n starfleet create deployment wait-probe --image=curlimages/curl:8.22.0 --replicas=6 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] The API server enforces the policy."
    sleep 3
    exit 0
  fi
  sleep 3
done
echo "[testing] The policy was not enforced in time." >&2
exit 1
