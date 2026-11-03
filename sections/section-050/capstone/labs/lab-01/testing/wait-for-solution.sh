#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the check
# Task, the finished Pipeline and the Role exist, the policy is Ready and
# Kyverno rejects a tag-only image in starfleet-prod.
set -uo pipefail

for i in $(seq 1 30); do
  finally="$(kubectl -n pipelines get pipeline release-gate -o jsonpath='{.spec.finally[0].name}' 2>/dev/null)"
  if kubectl -n pipelines get task check-release >/dev/null 2>&1 \
    && [ -n "$finally" ] \
    && [ "$(kubectl auth can-i create deployments -n starfleet --as=system:serviceaccount:pipelines:pipeline-runner 2>/dev/null)" = "yes" ] \
    && [ "$(kubectl auth can-i create deployments -n outpost --as=system:serviceaccount:pipelines:pipeline-runner 2>/dev/null)" = "no" ]; then
    break
  fi
  sleep 3
done

for i in $(seq 1 60); do
  ready="$(kubectl get clusterpolicy trusted-images -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  if [ "$ready" = "True" ] \
    && ! kubectl -n starfleet-prod create deployment wait-probe --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] The Pipeline, the Role and the image policy are ready."
    sleep 5
    exit 0
  fi
  sleep 3
done
echo "[testing] The solution objects did not work in time." >&2
exit 1
