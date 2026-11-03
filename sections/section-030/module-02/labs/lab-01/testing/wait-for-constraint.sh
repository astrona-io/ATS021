#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# deny constraint refuses a pod that uses the latest tag.
set -uo pipefail

for i in $(seq 1 60); do
  if ! kubectl -n starfleet run wait-probe --image=curlimages/curl:latest --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Gatekeeper enforces the constraint."
    exit 0
  fi
  sleep 3
done
echo "[testing] Gatekeeper did not enforce the constraint in time." >&2
exit 1
