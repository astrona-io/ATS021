#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the check
# Task and the finished Pipeline exist and the Role of pipeline-runner is bound.
set -uo pipefail

for i in $(seq 1 30); do
  finally="$(kubectl -n pipelines get pipeline release-gate -o jsonpath='{.spec.finally[0].name}' 2>/dev/null)"
  if kubectl -n pipelines get task check-release >/dev/null 2>&1 \
    && [ -n "$finally" ] \
    && kubectl -n starfleet get rolebinding >/dev/null 2>&1 \
    && [ "$(kubectl auth can-i create deployments -n starfleet --as=system:serviceaccount:pipelines:pipeline-runner 2>/dev/null)" = "yes" ]; then
    echo "[testing] The Pipeline, the check Task and the Role are ready."
    exit 0
  fi
  sleep 3
done
echo "[testing] The solution objects did not appear in time." >&2
exit 1
