#!/usr/bin/env bash
# Check: the probe Deployment that Helm manages in starfleet runs at least two
# replicas, all of them ready, with the team label on the pod template and on
# every running pod. It fails on the start state (one replica, no pod label).
set -uo pipefail

fail=0

release_name="$(kubectl -n starfleet get deployment probe -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' 2>/dev/null || true)"
if [ "$release_name" != "probe" ]; then
  echo "FAIL: the Deployment probe in starfleet must be managed by the Helm release probe (annotation meta.helm.sh/release-name), got ${release_name:-none}"
  fail=1
fi

replicas="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.replicas}' 2>/dev/null || true)"
if [ -z "$replicas" ] || [ "$replicas" -lt 2 ]; then
  echo "FAIL: the Deployment probe must have at least 2 replicas, got ${replicas:-none}"
  fail=1
fi

template_label="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.metadata.labels.team}' 2>/dev/null || true)"
if [ -z "$template_label" ]; then
  echo "FAIL: the pod template of the Deployment probe has no team label; the label on the Deployment itself is not enough"
  fail=1
fi

ready=""
for _ in $(seq 1 20); do
  ready="$(kubectl -n starfleet get deployment probe -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
  [ -n "$ready" ] && [ -n "$replicas" ] && [ "$ready" = "$replicas" ] && break
  sleep 3
done
if [ -z "$ready" ] || [ "$ready" != "$replicas" ]; then
  echo "FAIL: the Deployment probe has ${ready:-0} of ${replicas:-?} replicas ready; read the events of its newest ReplicaSet"
  fail=1
fi

pods_json="$(kubectl -n starfleet get pods -l app.kubernetes.io/instance=probe -o json 2>/dev/null)"
pod_count="$(printf '%s' "$pods_json" | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ -z "$pod_count" ] || [ "$pod_count" -lt 2 ]; then
  echo "FAIL: expected at least 2 probe pods in starfleet, found ${pod_count:-0}"
  fail=1
fi

unlabelled="$(printf '%s' "$pods_json" | jq -r '[.items[] | select(.metadata.deletionTimestamp == null) | select((.metadata.labels.team // "") == "") | .metadata.name] | join(" ")')"
if [ -n "$unlabelled" ]; then
  echo "FAIL: these probe pods have no team label: $unlabelled"
  fail=1
fi

not_ready="$(printf '%s' "$pods_json" | jq -r '[.items[] | select(.metadata.deletionTimestamp == null) | select(([.status.conditions[]? | select(.type == "Ready" and .status == "True")] | length) == 0) | .metadata.name] | join(" ")')"
if [ -n "$not_ready" ]; then
  echo "FAIL: these probe pods are not ready: $not_ready"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the probe release runs $replicas ready pods, all with the team label"
fi
exit "$fail"
