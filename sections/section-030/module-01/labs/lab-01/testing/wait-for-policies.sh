#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# policies are Ready and Kyverno has registered them in its webhooks. A pod
# without limits must be rejected and a pod without a team label must get one.
set -uo pipefail

for i in $(seq 1 60); do
  ready="$(kubectl get clusterpolicy require-limits add-team-label default-deny-networkpolicy -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{" "}{end}' 2>/dev/null)"
  if [ "$ready" = "True True True " ]; then
    break
  fi
  sleep 3
done

for i in $(seq 1 60); do
  if ! kubectl -n starfleet run wait-probe --image=curlimages/curl:8.22.0 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Kyverno enforces the policies."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] Kyverno did not enforce the policies in time." >&2
exit 1
