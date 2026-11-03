#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until all three
# policies are Ready and Kyverno rejects a pod image from another registry.
set -uo pipefail

for i in $(seq 1 60); do
  ready="$(kubectl get clusterpolicy allowed-registries image-tags require-digest -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{" "}{end}' 2>/dev/null)"
  [ "$ready" = "True True True " ] && break
  sleep 3
done

for i in $(seq 1 60); do
  if ! kubectl -n starfleet create deployment wait-probe --image=docker.io/library/nginx:1.27.0 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Kyverno enforces the policies."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] Kyverno did not enforce the policies in time." >&2
exit 1
